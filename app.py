import bottle
import os
import jwt
import datetime
import hashlib
import binascii
import re
import json
import sys
from functools import wraps
import sqlite3
import inspect
import bottle_sqlite
import base64
import hmac




# Load configuration from command line argument
def load_config():
    if len(sys.argv) < 2:
        print("Usage: python app.py <config_file.json>")
        sys.exit(1)
    
    config_file = sys.argv[1]
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        return config
    except Exception as e:
        print(f"Error loading configuration: {e}")
        sys.exit(1)

# Load config
config = load_config()

app = bottle.Bottle()

# Add SQLite plugin with path from config
app.install(bottle_sqlite.SQLitePlugin(dbfile=config['dbFilepath']))

# Secret key for JWT from config
JWT_SECRET = config['jwtSecret']
JWT_ALGORITHM = "HS256"
COOKIE_NAME = "auth_token"
COOKIE_MAX_DAYS = 360
COOKIE_MAX_AGE = COOKIE_MAX_DAYS * 24 * 60 * 60  # 360 days in seconds


# Configure logging based on config
if config.get('prettyLogging', False):
    import logging
    logging.basicConfig(
        level=logging.DEBUG if config.get('logLevel', 0) <= 0 else logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    logger = logging.getLogger(__name__)
    logger.info(f"Starting application with config: {config['dbFilepath']}")

# Authentication decorator
def require_auth(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        user_id = get_user_id_from_cookie()
        if not user_id:
            bottle.response.status = 401
            return {"error": "Authentication required"}
        kwargs['user_id'] = user_id
        return func(*args, **kwargs)
    return wrapper

# Admin authentication decorator
def require_admin(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        user_id = get_user_id_from_cookie()
        if not user_id:
            bottle.response.status = 401
            return {"error": "Authentication required"}
            
        # Get db from kwargs if passed by SQLite plugin
        db = kwargs.get('db')
        if not db:
            bottle.response.status = 500
            return {"error": "Database connection error"}
            
        # Check if user is admin
        query = "SELECT admin FROM users WHERE id = ?"
        result = db.execute(query, (user_id,)).fetchone()
        
        if not result or result['admin'] != 1:
            bottle.response.status = 403
            return {"error": "Admin privileges required"}
            
        kwargs['user_id'] = user_id
        return func(*args, **kwargs)
    return wrapper

# Extract user_id from cookie
def get_user_id_from_cookie():
    token = bottle.request.get_cookie(COOKIE_NAME)
    if not token:
        return None
    
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload.get('user_id')
    except jwt.PyJWTError:
        return None


def verify_password(stored_password, provided_password):
    # Split the encoded hash into its components using $ as separator
    parts = stored_password.split('$')
    if len(parts) != 4:
        print(f"Invalid hash format, expected 4 parts but got {len(parts)}: {stored_password}")
        return False
    
    # Extract algorithm, salt, iterations, and hash
    algorithm = parts[0]
    if algorithm != "pdkdf2_sha256":  # Note: matches the hash format with "pd" not "pb"
        print(f"Invalid algorithm: {algorithm}")
        return False
    
    salt = parts[1]
    
    try:
        iterations = int(parts[2])
    except ValueError as e:
        print(f"Failed to parse iterations: {e}")
        return False
    
    stored_hash_base64 = parts[3]
    
    # Decode the stored hash from base64
    try:
        stored_hash_bytes = base64.b64decode(stored_hash_base64)
    except Exception as e:
        print(f"Failed to decode base64 hash: {e}")
        return False
    
    # Generate hash from the provided password using the same parameters
    # In Python, pbkdf2_hmac outputs binary, so we don't need to convert from hex
    computed_hash = hashlib.pbkdf2_hmac(
        'sha256',
        provided_password.encode('utf-8'),
        salt.encode('utf-8'),
        iterations,
        len(stored_hash_bytes)
    )
    
    # Compare the computed hash with the stored hash (constant-time comparison)
    return hmac.compare_digest(computed_hash, stored_hash_bytes)

# Serve static files from the 'static' directory
@app.route('/static/<filepath:path>')
def serve_static(filepath):
    return bottle.static_file(filepath, root='./static')

# Serve index.html for '/' and any path starting with '/app'
@app.route('/')
@app.route('/app')
@app.route('/app/<path:path>')
def serve_index(db, path=None):
    user = None
    user_id = get_user_id_from_cookie()
    if user_id:
        query = "SELECT id, username, fullname, password, admin FROM users WHERE id = ?"
        user = db.execute(query, (user_id,)).fetchone()

    flags_data = {}
    if user:
        flags_data['flags'] = {
            'user': {
                "id": user["id"],
                "username": user["username"],
                "fullname": user["fullname"],
                "admin": bool(user["admin"])  # Ensure this is a proper boolean
            }
        }
    
    flags_json = json.dumps(flags_data)

    index_html = f"""<!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Pole Prediction</title>
                <link rel="icon" type="image/svg" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48' viewBox='0 0 16 16'><text x='0' y='14'>🏎️</text></svg>"/>
                <link rel="stylesheet" href="/static/styles.css">
                <script src="/static/main.js"></script>
            </head>
            <body>
                <h1>Pole Prediction</h1>
                <script> var app = Elm.Main.init({flags_json}); </script>
            </body>
            </html>"""
    return index_html

# Authentication routes
@app.route('/api/login', method='POST')
def login(db):
    data = bottle.request.json
    
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        bottle.response.status = 400
        return {'success': False, 'message': 'Username and password required'}
    
    # Get user from database
    query = "SELECT id, username, fullname, password, admin FROM users WHERE username = ?"
    user = db.execute(query, (username,)).fetchone()
    
    if not user or not verify_password(user['password'], password):
        bottle.response.status = 401
        return {'success': False, 'message': 'Invalid credentials'}
    
    # Create JWT token with user_id embedded
    payload = {
        'user_id': user['id'],
        'exp': datetime.datetime.now(datetime.UTC) + datetime.timedelta(days=COOKIE_MAX_DAYS),
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    
    # Set HTTP-Only secure cookie
    secure_cookie = not config.get('debug', False)  # Don't require HTTPS in debug mode
    bottle.response.set_cookie(
        COOKIE_NAME, 
        token,
        httponly=True,     # Prevents JavaScript access
        secure=secure_cookie,  # Only sent over HTTPS (disabled in debug mode)
        samesite='strict', # Prevents CSRF
        max_age=COOKIE_MAX_AGE,
        path='/'           # Available across the entire domain
    )
    
    return {
        'success': True, 
        'message': 'Login successful',
        'user': {
            'id': user['id'],
            'username': user['username'],
            'fullname': user['fullname'],
            'admin': bool(user['admin'])
        }
    }

@app.route('/api/logout', method='POST')
def logout():
    bottle.response.delete_cookie(COOKIE_NAME, path='/')
    return {'success': True, 'message': 'Logged out successfully'}

@app.route('/api/me', method='GET')
@require_auth
def get_current_user(db, user_id):
    query = "SELECT id, username, fullname, admin FROM users WHERE id = ?"
    user = db.execute(query, (user_id,)).fetchone()
    
    if not user:
        bottle.response.status = 404
        return {'error': 'User not found'}
    
    return {
        'id': user['id'],
        'username': user['username'],
        'fullname': user['fullname'],
        'admin': bool(user['admin'])
    }

# Admin-only route example
@app.route('/api/admin/users', method='GET')
@require_admin
def list_users(db, user_id):
    users = db.execute("SELECT id, username, fullname, admin FROM users").fetchall()
    return {'users': [dict(user) for user in users]}

# Protected API routes
@app.route('/api/protected-resource', method=['GET'])
@require_auth
def protected_resource(user_id):
    return {'status': 'ok', 'data': 'This is protected data', 'user_id': user_id}



@app.route('/api/formula-one/leaderboard/<season>', method=['GET'])
def get_formula_one_leaderboard(db, season):
    query = """
with
    predictions as (select * from formula_one_prediction_lines where user != "" and position <= 10),
    results as (select * from formula_one_prediction_lines where user == ""),
    scored_lines as (
    select 
        users.id as user_id,
        users.fullname as user_fullname,
        sessions.name as session_name,
        case when predictions.position <= 10 and results.position <= 10 
            then
                case when predictions.position == results.position 
                    then 4 
                    else 
                        case when predictions.position + 1 == results.position  or predictions.position - 1 == results.position
                        then 2
                        else 1
                        end
                    end +
                case when sessions.fastest_lap == true and results.fastest_lap = "true" and predictions.fastest_lap = "true" 
                    then 1
                    else 0
                    end
            else
                0
            end
            as score
        from predictions
        inner join results on results.session == predictions.session and results.entrant == predictions.entrant
        inner join formula_one_sessions as sessions on predictions.session = sessions.id
        inner join formula_one_events as events on sessions.event == events.id and events.season == ?
        inner join users on predictions.user = users.id
    )
select 
    user_id,
    user_fullname,
    cast( coalesce( sum(
        case when session_name == "sprint-shootout" then score else 0 end
    ), 0) as integer) as sprint_shootout,
    cast( coalesce( sum(
        case when session_name == "sprint" then score else 0 end
    ), 0) as integer) as sprint,
    cast( coalesce( sum(
        case when session_name == "qualifying" then score else 0 end
    ), 0) as integer) as qualifying,
    cast( coalesce( sum(
        case when session_name == "race" then score else 0 end
    ), 0) as integer) as race,
    cast( coalesce( sum(score), 0) as integer) as total
from scored_lines
group by user_id
order by total desc
;
"""
    rows = db.execute(query, (season,)).fetchall()
    def make_row (d):
        return { 'userId': d['user_id'],
                'userName': d['user_fullname'],
                'scores': list([ s for (name, s) in d.items() if name != 'user_id' and name != 'user_fullname' ])
                }

    return { 'columns' : [ 'sprint-shootout', 'sprint', 'qualifying', 'race', 'total' ],
             'rows' : [ make_row(dict(row)) for row in rows ] 
            }

@app.route('/api/formula-e/leaderboard/<season>', method=['GET'])
def get_formula_e_leaderboard(db, season):
    query = """with
    scored_predictions
    as ( select
            users.id as user_id,
            users.fullname as user_fullname,
            case when predictions.first = results.first then 1 else 0 end as race_wins,
            case when predictions.pole = results.pole then 10 else 0 end +
            case when predictions.fam = results.fam then 10 else 0 end + 
            case when predictions.fl = results.fl then 10 else 0 end +
            case when predictions.hgc = results.hgc then 10 else 0 end +
            case when predictions.first = results.first then 20 else 0 end +
            case when predictions.second = results.second then 10 else 0 end +
            case when predictions.third = results.third then 10 else 0 end +
            case when predictions.fdnf = results.fdnf then 10 else 0 end +
            case when predictions.safety_car = results.safety_car then 10 else 0 end
            as total
         from predictions
         inner join races on predictions.race = races.id 
         join results on predictions.race = results.race
         join users on predictions.user = users.id
         where races.season = @season and races.cancelled = 0
        )
    select 
        user_id, 
        user_fullname,
        cast(coalesce(sum(total), 0) as integer) as 'Total score',
        cast(coalesce(sum(race_wins), 0) as integer) as 'Race wins'
    from scored_predictions
    group by user_id
    order by sum(total) desc, sum(race_wins) desc
;"""

    rows = db.execute(query, (season,)).fetchall()
    def make_row (d):
        return { 'userId': d['user_id'],
                'userName': d['user_fullname'],
                'scores': list([ s for (name, s) in d.items() if name != 'user_id' and name != 'user_fullname' ])
                }

    return { 'columns' : [ 'sprint-shootout', 'sprint', 'qualifying', 'race', 'total' ],
             'rows' : [ make_row(dict(row)) for row in rows ] 
            }





# Make sure the static directory exists
os.makedirs('./static', exist_ok=True)

if __name__ == '__main__':
    # Run the application with settings from config
    bottle.run(
        app, 
        host='localhost', 
        port=config.get('port', 8080), 
        debug=config.get('debug', False)
    )
