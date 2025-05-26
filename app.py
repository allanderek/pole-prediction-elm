import bottle
import os
import jwt
import contextlib
import datetime
import hashlib
import binascii
import re
import json
import sys
from functools import wraps
import sqlite3
import inspect
import base64
import hmac
from datetime import datetime, timezone




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

@contextlib.contextmanager
def db_transaction():
    """Context manager for SQLite database transactions."""
    db = sqlite3.connect(config['dbFilepath'])  # Replace with your actual DB file path
    db.row_factory = sqlite3.Row  # Enable dictionary-like access

    try:
        yield db
        db.commit()
    except sqlite3.IntegrityError as e:
        db.rollback()
        bottle.response.status = 500
        raise bottle.HTTPError(500, f"Database integrity error: {str(e)}")
    except bottle.HTTPError:
        db.rollback()
        raise
    except bottle.HTTPResponse as e:
        db.commit()
        raise
    except Exception as e:
        db.rollback()
        bottle.response.status = 500
        raise bottle.HTTPError(500, f"Database error: {str(e)}")
    finally:
        db.close()


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

## Note, no longer a decorator
def require_admin(db):
    user_id = get_user_id_from_cookie()
    if not user_id:
        bottle.response.status = 401
        return {"error": "Authentication required"}
            
    if not db:
        bottle.response.status = 500
        return {"error": "Database connection error"}
            
    # Check if user is admin
    query = "SELECT admin FROM users WHERE id = ?"
    result = db.execute(query, (user_id,)).fetchone()
    
    if not result or result['admin'] != 1:
        bottle.response.status = 403
        return {"error": "Admin privileges required"}

    return user_id
            

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
def serve_index(path=None):
    with db_transaction() as db:
        user = None
        user_id = get_user_id_from_cookie()
        if user_id:
            query = "SELECT id, username, fullname, password, admin FROM users WHERE id = ?"
            user = db.execute(query, (user_id,)).fetchone()

        
        user_flags = {}
        if user:
            user_flags = {
                'user': {
                    "id": user["id"],
                    "username": user["username"],
                    "fullname": user["fullname"],
                    "admin": bool(user["admin"])  # Ensure this is a proper boolean
                }
            }
        
        user_flags_json = json.dumps(user_flags)

        index_html = f"""<!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Pole Prediction</title>
                    <link rel="icon" type="image/svg" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48' viewBox='0 0 16 16'><text x='0' y='14'>🏎️</text></svg>"/>
                    <script src="https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"></script>
                    <link rel="preconnect" href="https://fonts.googleapis.com">
                    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Rajdhani:wght@400;700;900&display=swap" rel="stylesheet">
                    <link rel="stylesheet" href="/static/styles.css">
                    <script src="/static/custom-elements.js"></script>
                    <script src="/static/main.js"></script>
                </head>
                <body>
                    <h1>Pole Prediction</h1>
                    <script> 
                        const user_flags = {user_flags_json};
                        const flags = {{ "flags" : {{ "now": Date.now(), ...user_flags }} }}; 
                        var app = Elm.Main.init(flags); 
                        app.ports.native_alert.subscribe(function (message) {{ 
                            alert(message); 
                        }});
                    </script>
                </body>
                </html>"""
        return index_html

# Authentication routes
@app.route('/api/login', method='POST')
def login():
    with db_transaction() as db:
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
def get_current_user(user_id):
    with db_transaction() as db:
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


# Protected API routes
@app.route('/api/protected-resource', methods=['GET'])
@require_auth
def protected_resource(user_id):
    return {'status': 'ok', 'data': 'This is protected data', 'user_id': user_id}


@app.route('/api/formula-one/season-events/<season>', method='GET')
def get_formula_one_events(season):
    with db_transaction() as db:
        query = """ select * from formula_one_events_view
    where season = :season
    ;"""
        rows = db.execute(query, { 'season': season}).fetchall()
        bottle.response.content_type = 'application/json'
        return json.dumps([ dict(row) for row in rows ])
        
@app.route('/api/formula-one/event-sessions/<event_id>', method='GET')
def get_formula_one_sessions_by_event(event_id):
    with db_transaction() as db:
        query = """select 
        s.id, 
        e.season,
        s.event,
        s.name, 
        s.half_points, 
        s.start_time, 
        s.cancelled, 
        s.fastest_lap
    from formula_one_sessions s
    join formula_one_events e on s.event = e.id
    where s.event = :event_id
    order BY s.start_time
    ;"""
        rows = db.execute(query, { 'event_id': event_id}).fetchall()
        bottle.response.content_type = 'application/json'
        return json.dumps([ dict(row) for row in rows ])

@app.route('/api/formula-one/session-entrants/<session_id>', method='GET')
def get_formula_one_session_entrants(session_id):
    with db_transaction() as db:
        query = """select
        e.id,
        e.number,
        e.driver,
        e.team,
        e.session,
        coalesce(e.participating, 0) as participating,
        e.rank,
        d.name as driver_name,
        t.fullname as team_full_name,
        t.shortname as team_short_name,
        coalesce(t.color, '#000000') as team_primary_color,
        coalesce(t.secondary_color, '#000000') as team_secondary_color
    from formula_one_entrants e
    join drivers d on e.driver = d.id
    join formula_one_teams t on e.team = t.id
    where e.session = :session_id
    order by e.rank desc, e.number
    ;"""
        rows = db.execute(query, {'session_id': session_id}).fetchall()
        bottle.response.content_type = 'application/json'
        return json.dumps([ dict(row) for row in rows ])


@app.route('/api/formula-one/session-leaderboard/<session_id>', method='GET')
def get_formula_one_session_leaderboard(session_id):
    with db_transaction() as db:
        user_id = get_user_id_from_cookie()
        return get_formula_one_session_scored_predictions(db, user_id, session_id)

def get_formula_one_session_scored_predictions(db, user_id, session_id):
    # Get the session details to check start time
    session = db.execute(
        "select start_time, name from formula_one_sessions where id = ?",
        (session_id,)
    ).fetchone()
    
    if not session:
        bottle.response.status = 404
        return {'error': 'Session not found'}
    
    # Check if predictions are still allowed (before session start)
    session_started = is_db_time_earlier_than_now(session['start_time'])
    where_clause_suffix = "and formula_one_prediction_lines.user = :user_id" if not session_started else ""


    query = f"""with 
    all_predictions as (
        select 
            user,
            session,
            entrant,
            position,
            fastest_lap
        from formula_one_prediction_lines
        where formula_one_prediction_lines.session = :session_id {where_clause_suffix}
    ),
    session_results as (
        select 
            entrant,
            position,
            fastest_lap
        from formula_one_prediction_lines
        where (user is null or user = "")
        and session = :session_id
    )
select 
    coalesce(ap.user, '') as user_id,
    coalesce(u.fullname, 'Official Result') as user_name,
    ap.position as predicted_position,
    sr.position as actual_position,
    fe.id,
    fe.number,
    d.name as driver_name,
    t.fullname as team_full_name,
    t.shortname as team_short_name,
    coalesce(t.color, '#000000') as team_primary_color,
    coalesce(t.secondary_color, '#000000') as team_secondary_color,
    case 
        when sr.position is null or ap.user is null or ap.user = "" then 0
        when ap.position <= 10 and sr.position <= 10 then
            case 
                when ap.position = sr.position then 4
                when abs(ap.position - sr.position) = 1 then 2
                else 1
            end
        else 0
    end + 
    case 
        when sr.position is null or ap.user is null or ap.user = "" then 0
        when s.fastest_lap = 1 
        and ap.fastest_lap = 1
        and sr.fastest_lap = 1
        and sr.position <= 10 then 1
        else 0
    end as score
from all_predictions ap
left join users u on ap.user = u.id
left join session_results sr on ap.entrant = sr.entrant
join formula_one_entrants fe on ap.entrant = fe.id
join drivers d on fe.driver = d.id
join formula_one_teams t on fe.team = t.id
join formula_one_sessions s on ap.session = s.id
order by 
    case when ap.user is null or ap.user = "" then 0 else 1 end,
    user_name,
    ap.position
;"""
    rows = db.execute(query, {'session_id': session_id, 'user_id': user_id}).fetchall()

    return json.dumps([ dict(row) for row in rows])

def parse_sqlite_datetime(dt_str):
    # I think there is more to this here, including the 'Z' at the end
    return datetime.fromisoformat(dt_str.replace(' ', 'T'))

def is_db_time_earlier_than_now (db_time_str):
    # Parse the SQLite datetime string
    db_time = parse_sqlite_datetime(db_time_str)
    
    # Get the current time in UTC
    current_time = datetime.now(timezone.utc)
    
    # Compare times
    return db_time < current_time


@app.route('/api/formula-one/session-prediction/<session_id>', method='POST')
@require_auth
def save_formula_one_prediction(user_id, session_id):
    with db_transaction() as db:
        prediction_data = bottle.request.json
        
        # Validate we have all required data
        if not prediction_data.get('positions') or len(prediction_data['positions']) != 20:
            bottle.response.status = 400
            return {'error': 'Prediction must include positions for all 20 drivers'}
        
        # Get fastest lap prediction, could be None
        fastest_lap = prediction_data.get('fastest_lap')

        # Get the session details to check start time
        session = db.execute(
            "select start_time, name from formula_one_sessions where id = ?",
            (session_id,)
        ).fetchone()
        
        if not session:
            bottle.response.status = 404
            return {'error': 'Session not found'}
        
        # Check if predictions are still allowed (before session start)
        if is_db_time_earlier_than_now(session['start_time']):
            bottle.response.status = 403
            return {'error': f'Predictions for {session["name"]} are no longer accepted - session has started'}
        
        
        # First delete any existing predictions for this user and session
        db.execute(
            "delete from formula_one_prediction_lines where user = ? and session = ?",
            (user_id, session_id)
        )
        
        # Prepare batch insert data
        rows_to_insert = []
        
        for position, entrant_id in enumerate(prediction_data['positions'], start=1):
            # Only set fastest_lap to "true" if it's specified and matches this entrant
            is_fastest_lap = "true" if fastest_lap is not None and entrant_id == fastest_lap else "false"
            rows_to_insert.append({
                'user': user_id,
                'session': session_id,
                'fastest_lap': is_fastest_lap,
                'position': position,
                'entrant': entrant_id
            })
        
        # Perform batch insert
        query = """
        insert into formula_one_prediction_lines 
            (user, session, fastest_lap, position, entrant)
        values
            (:user, :session, :fastest_lap, :position, :entrant)
        """
        
        db.executemany(query, rows_to_insert)
        return {'status': 'success'}

@app.route('/api/formula-one/session-result/<session_id>', method='POST')
def save_formula_one_session_result(session_id):
    with db_transaction() as db:
        admin_user_id = require_admin(db)
        if hasattr(admin_user_id, 'error'):
            return admin_user_id 

        prediction_data = bottle.request.json
        
        # Validate we have all required data
        if not prediction_data.get('positions') or len(prediction_data['positions']) != 20:
            bottle.response.status = 400
            return {'error': 'Prediction must include positions for all 20 drivers'}
        
        # Get fastest lap prediction, could be None
        fastest_lap = prediction_data.get('fastest_lap')
        
        # First delete any existing predictions for this user and session
        db.execute(
                "delete from formula_one_prediction_lines where (user = '' or user is null) and session = :session_id",
                { "session_id": session_id }
        )
        
        # Prepare batch insert data
        rows_to_insert = []
        
        for position, entrant_id in enumerate(prediction_data['positions'], start=1):
            # Only set fastest_lap to "true" if it's specified and matches this entrant
            is_fastest_lap = "true" if fastest_lap is not None and entrant_id == fastest_lap else "false"
            rows_to_insert.append({
                'user': '',
                'session': session_id,
                'fastest_lap': is_fastest_lap,
                'position': position,
                'entrant': entrant_id
            })
        
        # Perform batch insert
        query = """
        insert into formula_one_prediction_lines 
            (user, session, fastest_lap, position, entrant)
        values
            (:user, :session, :fastest_lap, :position, :entrant)
        """
        
        db.executemany(query, rows_to_insert)
        # Now we wish to return the new session leaderboard 
        return get_formula_one_session_scored_predictions(db, admin_user_id, session_id)

@app.route('/api/formula-one/leaderboard/<season>', method='GET')
def get_formula_one_leaderboard(season):
    with db_transaction() as db:
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
            inner join formula_one_events as events on sessions.event == events.id and events.season == :season
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
        rows = db.execute(query, {'season': season}).fetchall()
        return { 'columns' : [ 'sprint-shootout', 'sprint', 'qualifying', 'race', 'total' ],
                 'rows' : create_leaderboard_rows(rows)
                }

@app.route('/api/formula-one/constructor-standings/<season>', method='GET')
def get_formula_one_constructor_standings(season):
    with db_transaction() as db:
        query = """with
        results as (
            select * from formula_one_prediction_lines where (user is null or user = "") and session in (
                select id from formula_one_sessions where event in (
                    select id from formula_one_events where season = :season
                )
            )
        ),
        -- Only process constructor standings if we have results
        scored_lines as (
            select 
                sessions.name as session_name,
                case 
                    when sessions.name = 'race' then
                        case 
                            when results.position = 1 then 25
                            when results.position = 2 then 18
                            when results.position = 3 then 15
                            when results.position = 4 then 12
                            when results.position = 5 then 10
                            when results.position = 6 then 8
                            when results.position = 7 then 6
                            when results.position = 8 then 4
                            when results.position = 9 then 2
                            when results.position = 10 then 1
                        else 0
                        end 
                    when sessions.name = 'sprint' then
                        case 
                            when results.position = 1 then 8
                            when results.position = 2 then 7
                            when results.position = 3 then 6
                            when results.position = 4 then 5
                            when results.position = 5 then 4
                            when results.position = 6 then 3
                            when results.position = 7 then 2
                            when results.position = 8 then 1
                        else 0
                        end 
                end
                +
                case when results.fastest_lap = 'true' and sessions.fastest_lap = 1 then 1 else 0 end
                    as score,
                teams.shortname as team_name,
                teams.id as team_id
            from results
            inner join formula_one_sessions as sessions on results.session = sessions.id
            inner join formula_one_events as events on sessions.event = events.id and events.season = :season
            inner join formula_one_entrants as entrants on results.entrant = entrants.id
            inner join formula_one_teams as teams on entrants.team = teams.id
            where (select count(*) from results) > 0  -- Only include if results exist
        )

    select 
        team_name,
        team_id,
        sum(score) as total
    from scored_lines
    group by team_id
    order by total desc
    ;"""
        rows = db.execute(query, {'season': season}).fetchall()
        return { 'columns' : [ 'total' ],
                 'rows' : create_leaderboard_rows(rows, id='team_id', name='team_name')
                }

@app.route('/api/formula-one/driver-standings/<season>', method='GET')
def get_formula_one_driver_standings(season):
    with db_transaction() as db:
        query = """with
        results as (
            select * from formula_one_prediction_lines where (user is null or user = "") and session in (
                select id from formula_one_sessions where event in (
                    select id from formula_one_events where season = :season
                )
            )
        ),
        scored_lines as (
            select 
                sessions.name as session_name,
                case 
                    when sessions.name = 'race' then
                        case 
                            when results.position = 1 then 25
                            when results.position = 2 then 18
                            when results.position = 3 then 15
                            when results.position = 4 then 12
                            when results.position = 5 then 10
                            when results.position = 6 then 8
                            when results.position = 7 then 6
                            when results.position = 8 then 4
                            when results.position = 9 then 2
                            when results.position = 10 then 1
                        else 0
                        end 
                    when sessions.name = 'sprint' then
                        case 
                            when results.position = 1 then 8
                            when results.position = 2 then 7
                            when results.position = 3 then 6
                            when results.position = 4 then 5
                            when results.position = 5 then 4
                            when results.position = 6 then 3
                            when results.position = 7 then 2
                            when results.position = 8 then 1
                        else 0
                        end 
                end
                +
                case when results.fastest_lap = 'true' and sessions.fastest_lap = 1 then 1 else 0 end
                    as score,
                drivers.name as driver_name,
                drivers.id as driver_id
            from results
            inner join formula_one_sessions as sessions on results.session = sessions.id
            inner join formula_one_events as events on sessions.event = events.id and events.season = :season
            inner join formula_one_entrants as entrants on results.entrant = entrants.id
            inner join drivers on entrants.driver = drivers.id
            where (select count(*) from results) > 0  -- Only include if results exist
        )

    select 
        driver_name,
        driver_id,
        sum(score) as total
    from scored_lines
    group by driver_id
    order by total desc
    ;"""
        rows = db.execute(query, {'season': season}).fetchall()
        return { 'columns' : [ 'total' ],
                 'rows' : create_leaderboard_rows(rows, id='driver_id', name='driver_name')
                }

@app.route('/api/formula-one/season-leaderboard/<season>', method='GET')
def get_formula_one_season_leaderboard(season):
    with db_transaction() as db:
        query = """with
        -- First, get all the season predictions from users
        user_predictions as (
            select
                lines.user,
                users.fullname,
                lines.position,
                lines.team,
                teams.shortname as team_name,
                coalesce(teams.color, '#000000') as team_color,
                coalesce(teams.secondary_color, '#000000') as team_secondary_color
            from formula_one_season_prediction_lines as lines
            inner join users on lines.user = users.id
            inner join formula_one_teams as teams on lines.team = teams.id
            where teams.season = :season
        ),
        -- Only calculate constructor standings if results exist
        results as (
            select * from formula_one_prediction_lines where (user is null or user = "") and session in (
                select id from formula_one_sessions where event in (
                    select id from formula_one_events where season = :season
                )
            )
        ),
        -- Only process constructor standings if we have results
        scored_lines as (
            select 
                sessions.name as session_name,
                case 
                    when sessions.name = 'race' then
                        case 
                            when results.position = 1 then 25
                            when results.position = 2 then 18
                            when results.position = 3 then 15
                            when results.position = 4 then 12
                            when results.position = 5 then 10
                            when results.position = 6 then 8
                            when results.position = 7 then 6
                            when results.position = 8 then 4
                            when results.position = 9 then 2
                            when results.position = 10 then 1
                        else 0
                        end 
                    when sessions.name = 'sprint' then
                        case 
                            when results.position = 1 then 8
                            when results.position = 2 then 7
                            when results.position = 3 then 6
                            when results.position = 4 then 5
                            when results.position = 5 then 4
                            when results.position = 6 then 3
                            when results.position = 7 then 2
                            when results.position = 8 then 1
                        else 0
                        end 
                end
                +
                case when results.fastest_lap = 'true' and sessions.fastest_lap = 1 then 1 else 0 end
                    as score,
                teams.shortname as team_name,
                teams.id as team_id
            from results
            inner join formula_one_sessions as sessions on results.session = sessions.id
            inner join formula_one_events as events on sessions.event = events.id and events.season = :season
            inner join formula_one_entrants as entrants on results.entrant = entrants.id
            inner join formula_one_teams as teams on entrants.team = teams.id
            where (select count(*) from results) > 0  -- Only include if results exist
        ),
        -- Calculate constructor standings if we have results
        constructors as (
            select 
                row_number() over (order by sum(score) desc) as position,
                team_name,
                team_id,
                sum(score) as total
            from scored_lines
            group by team_id
            order by total desc
        )
    select
        up.user as user_id,
        up.fullname,
        up.position,
        up.team_name as team,
        up.team_color as team_primary_color,
        up.team_secondary_color,
        case 
            when (select count(*) from constructors) > 0 then  -- Check if we have results
                cast(coalesce(
                    (select max(0, c_actual.total - c_predicted.total)
                     from constructors c_actual
                     join constructors c_predicted on c_predicted.team_id = up.team
                     where c_actual.position = up.position),
                    0
                ) as integer)
            else 0
        end as difference
    from user_predictions up
    order by up.user, up.position
    ;"""
        rows = db.execute(query, {'season': season}).fetchall()
        return json.dumps([ dict(row) for row in rows])


def create_leaderboard_rows(rows, id='user_id', name='user_fullname'):
    def make_row (d):
        return { 'id': d[id],
                'name': d[name],
                'scores': list([ s for (field_name, s) in d.items() if field_name != id and field_name != name])
                }
    return [ make_row(dict(row)) for row in rows ]

@app.route('/api/formula-e/leaderboard/<season>', method='GET')
def get_formula_e_leaderboard(season):
    with db_transaction() as db:
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
             where races.season = :season and races.cancelled = 0
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

        rows = db.execute(query, {'season': season}).fetchall()

        return { 'columns' : [ 'Total', 'Race wins'],
                 'rows' : create_leaderboard_rows(rows)
                }

@app.route('/api/formula-e/season-events/<season>', method='GET')
def get_formula_one_events(season):
    with db_transaction() as db:
        query = """select * from races where season = :season ;"""
        rows = db.execute(query, { 'season': season}).fetchall()
        bottle.response.content_type = 'application/json'
        return json.dumps([ dict(row) for row in rows ])

@app.route('/api/formula-e/event-entrants/<race_id>', method='GET')
def get_formula_e_event_entrants(race_id):
    with db_transaction() as db:
        query = """select
        e.id,
        e.number,
        e.driver,
        e.team,
        e.race,
        coalesce(e.participating, 0) as participating,
        d.name as driver_name,
        t.fullname as team_full_name,
        t.shortname as team_short_name,
        coalesce(t.color, '#000000') as team_primary_color
    from entrants e
    join drivers d on e.driver = d.id
    join teams t on e.team = t.id
    where e.race = :race_id
    order by t.shortname, e.number
    ;"""
        rows = db.execute(query, {'race_id': race_id}).fetchall()
        bottle.response.content_type = 'application/json'
        return json.dumps([ dict(row) for row in rows ])

@app.route('/api/formula-e/race-predictions/<race_id>', method='GET')
def get_formula_e_race_predictions(race_id):
    with db_transaction() as db:
        user_id = get_user_id_from_cookie()
        return get_scored_formula_e_race_predictions(db, user_id, race_id)

def get_scored_formula_e_race_predictions(db, user_id, race_id):
    # Get the race details to check start time
    race = db.execute(
        "select date, name from races where id = ?",
        (race_id,)
    ).fetchone()
    
    if not race:
        bottle.response.status = 404
        return {'error': 'Event not found'}

    # Check if predictions are still allowed (before session start)
    session_started =  is_db_time_earlier_than_now(race['date'])
    where_clause_suffix = "and predictions.user = :user_id" if not session_started else ""

    query = f"""select
    user as user_id,
    users.fullname as user_name, 
    pole,
    fam,
    fl,
    hgc,
    first,
    second,
    third,
    fdnf,
    safety_car
    from predictions
    join users on predictions.user = users.id
    where race = :race_id {where_clause_suffix}
    """
    prediction_rows = db.execute(query, {'race_id': race_id, 'user_id': user_id}).fetchall()


    if not session_started:
        result_row = None
    else:
        query = """select
        pole,
        fam,
        fl,
        hgc,
        first,
        second,
        third,
        fdnf,
        safety_car
        from results
        where race = :race_id
        """
        result_row = db.execute(query, {'race_id': race_id}).fetchone()

    def transform_prediction(prediction):
        if result_row is not None:
            total = 0
            for key in ['pole', 'fam', 'fl', 'hgc','second', 'third', 'fdnf']:
                if prediction[key] == result_row[key]:
                    total += 10
            if prediction['first'] == result_row['first']:
                total += 20
            if prediction['safety_car'] == result_row['safety_car'] and prediction['safety_car'] in ['yes', 'no']:
                total += 10
            prediction['score'] = total
        else:
            prediction['score'] = 0
        return prediction

    predictions = [ transform_prediction(dict(row)) for row in prediction_rows ]    

    response_data = { 
        'predictions' : predictions,
        'result' : dict(result_row) if result_row else None
        }


    bottle.response.content_type = 'application/json'
    return json.dumps(response_data)

@app.route('/api/formula-e/race-prediction/<race_id>', method='POST')
@require_auth
def save_formula_e_race_prediction(user_id, race_id):
    with db_transaction() as db:

        prediction_data = bottle.request.json
        
        # Validate we have all required fields
        required_fields = ['pole', 'fam', 'fl', 'hgc', 'first', 'second', 'third', 'fdnf', 'safety_car']
        missing_fields = [field for field in required_fields if field not in prediction_data]
        
        if missing_fields:
            bottle.response.status = 400
            return {'error': f'Prediction missing required fields: {", ".join(missing_fields)}'}
        
        # Validate safety_car is either "yes" or "no"
        if prediction_data['safety_car'] not in ["yes", "no"]:
            bottle.response.status = 400
            return {'error': 'safety_car must be either "yes" or "no"'}

        # Get the race details to check start time
        race = db.execute(
            "select date, name from races where id = ?",
            (race_id,)
        ).fetchone()
        
        if not race:
            bottle.response.status = 404
            return {'error': 'Event not found'}

        # Check if predictions are still allowed (before session start)
        if is_db_time_earlier_than_now(race['date']):
            bottle.response.status = 403
            return {'error': f'Predictions for {race["name"]} are no longer accepted - session has started'}
        
        # First delete any existing prediction for this race
        db.execute(
                "delete from predictions where user = :user_id and race = :race_id",
                {"user_id": user_id, "race_id": race_id}
        )
        
        # Insert the new prediction
        query = """
        insert into predictions
            (user, race, pole, fam, fl, hgc, first, second, third, fdnf, safety_car)
        values
            (:user, :race, :pole, :fam, :fl, :hgc, :first, :second, :third, :fdnf, :safety_car)
        """
        
        db.execute(query, {
            'user': user_id,
            'race': race_id,
            'pole': prediction_data['pole'],
            'fam': prediction_data['fam'],
            'fl': prediction_data['fl'],
            'hgc': prediction_data['hgc'],
            'first': prediction_data['first'],
            'second': prediction_data['second'],
            'third': prediction_data['third'],
            'fdnf': prediction_data['fdnf'],
            'safety_car': prediction_data['safety_car']
        })
        
        # Return the predictions for this race, even if that is only the current user's prediction
        # Arguably, it must be otherwise we wouldn't be allowing them to save it, so we could probably
        # save work here by just returning the new prediction.
        return get_scored_formula_e_race_predictions(db, user_id, race_id)

@app.route('/api/formula-e/race-result/<race_id>', method='POST')
def save_formula_e_race_result(race_id):
    with db_transaction() as db:
        admin_user_id = require_admin(db)
        if hasattr(admin_user_id, 'error'):
            return admin_user_id 

        prediction_data = bottle.request.json
       
        # No validation, none of the fields are required because you can input a partial result
        # for example after qualifying.
        
        # First delete any existing result for this race
        db.execute(
            "delete from results where race = :race_id",
            {"race_id": race_id}
        )
        
        # Insert the new prediction
        query = """
        insert into results
            (race, pole, fam, fl, hgc, first, second, third, fdnf, safety_car)
        values
            (:race, :pole, :fam, :fl, :hgc, :first, :second, :third, :fdnf, :safety_car)
        """
        
        db.execute(query, {
            'race': race_id,
            'pole': prediction_data['pole'],
            'fam': prediction_data['fam'],
            'fl': prediction_data['fl'],
            'hgc': prediction_data['hgc'],
            'first': prediction_data['first'],
            'second': prediction_data['second'],
            'third': prediction_data['third'],
            'fdnf': prediction_data['fdnf'],
            'safety_car': prediction_data['safety_car']
        })
        
        # Return the predictions for this race
        return get_scored_formula_e_race_predictions(db, admin_user_id, race_id)



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
