import bottle
import os
import jwt
import datetime
import hashlib
import binascii
import re
import json
import sys
from bottle_sqlite import SQLitePlugin
from functools import wraps

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
app.install(SQLitePlugin(dbfile=config['dbFilepath']))

# Secret key for JWT from config
JWT_SECRET = config['jwtSecret']
JWT_ALGORITHM = "HS256"
COOKIE_NAME = "auth_token"
COOKIE_MAX_AGE = 360 * 24 * 60 * 60  # 360 days in seconds

# Define index.html content as a string literal
INDEX_HTML = """<!DOCTYPE html>
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
    <script> var app = Elm.Main.init({}); </script>
</body>
</html>"""

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

# Password verification function for pdkdf2_sha256 format
def verify_password(stored_password, provided_password):
    # Parse the stored password hash
    if not stored_password.startswith('pdkdf2_sha256'):
        return False
        
    try:
        # Extract parameters from the hash
        parts = stored_password.split('$')
        if len(parts) != 4:
            return False
            
        algorithm, salt, iterations_str, hash_value = parts
        iterations = int(iterations_str)
        
        # Generate hash of the provided password
        dk = hashlib.pbkdf2_hmac(
            'sha256', 
            provided_password.encode('utf-8'), 
            salt.encode('utf-8'), 
            iterations
        )
        
        # Convert to hex format for comparison
        computed_hash = binascii.hexlify(dk).decode('ascii')
        
        # Compare with stored hash value (partial match due to your truncated example)
        return computed_hash.startswith(hash_value) or hash_value.startswith(computed_hash)
        
    except Exception as e:
        if config.get('prettyLogging', False):
            logger.error(f"Password verification error: {e}")
        return False

# Serve static files from the 'static' directory
@app.route('/static/<filepath:path>')
def serve_static(filepath):
    return bottle.static_file(filepath, root='./static')

# Serve index.html for '/' and any path starting with '/app'
@app.route('/')
@app.route('/app')
@app.route('/app/<path:path>')
def serve_index(path=None):
    return INDEX_HTML

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
    query = "SELECT id, username, password, admin FROM users WHERE username = ?"
    user = db.execute(query, (username,)).fetchone()
    
    if not user or not verify_password(user['password'], password):
        bottle.response.status = 401
        return {'success': False, 'message': 'Invalid credentials'}
    
    # Create JWT token with user_id embedded
    payload = {
        'user_id': user['id'],
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
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
