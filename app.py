from fastapi import FastAPI, Request, HTTPException, Depends, Response, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, field_validator
from typing import Optional
import uvicorn
import os
import jwt
import contextlib
import datetime
import hashlib
import binascii
import re
import json
import sys
import secrets
from functools import wraps
import sqlite3
import inspect
import base64
import hmac
from authlib.integrations.requests_client import OAuth2Session

# Global config variable
config = {}

# Create FastAPI app
app = FastAPI()

# Make sure the static directory exists and mount it
os.makedirs("./static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")


# JWT and cookie configuration constants
COOKIE_NAME = "auth_token"
COOKIE_MAX_DAYS = 360
COOKIE_MAX_AGE = COOKIE_MAX_DAYS * 24 * 60 * 60  # 360 days in seconds

# Google OAuth URLs
GOOGLE_AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"

# In-memory store for OAuth state parameters (prevents CSRF)
oauth_states: dict = {}


@contextlib.contextmanager
def db_transaction():
    """Context manager for SQLite database transactions."""
    db = sqlite3.connect(config["dbFilepath"])
    db.row_factory = sqlite3.Row  # Enable dictionary-like access

    try:
        yield db
        db.commit()
    except sqlite3.IntegrityError as e:
        db.rollback()
        raise HTTPException(
            status_code=500, detail=f"Database integrity error: {str(e)}"
        )
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    finally:
        db.close()


# Extract user_id from cookie
def get_user_id_from_cookie(request: Request) -> Optional[int]:
    """Extract user_id from JWT cookie"""
    token = request.cookies.get(COOKIE_NAME)
    if not token:
        return None

    try:
        payload = jwt.decode(
            token, config["jwtSecret"], algorithms=[config.get("jwtAlgorithm", "HS256")]
        )
        return payload.get("user_id")
    except jwt.PyJWTError:
        return None


# FastAPI dependencies for authentication
def get_current_user_id(request: Request) -> int:
    """FastAPI dependency for required authentication"""
    user_id = get_user_id_from_cookie(request)
    if not user_id:
        raise HTTPException(status_code=401, detail="Authentication required")
    return user_id


def get_optional_user_id(request: Request) -> Optional[int]:
    """FastAPI dependency for optional authentication"""
    return get_user_id_from_cookie(request)


def require_admin_user(request: Request) -> int:
    """FastAPI dependency for admin authentication"""
    user_id = get_user_id_from_cookie(request)
    if not user_id:
        raise HTTPException(status_code=401, detail="Authentication required")

    with db_transaction() as db:
        query = "SELECT admin FROM users WHERE id = ?"
        result = db.execute(query, (user_id,)).fetchone()

        if not result or result["admin"] != 1:
            raise HTTPException(status_code=403, detail="Admin privileges required")

    return user_id


def verify_password(stored_password, provided_password):
    # Split the encoded hash into its components using $ as separator
    parts = stored_password.split("$")
    if len(parts) != 4:
        print(
            f"Invalid hash format, expected 4 parts but got {len(parts)}: {stored_password}"
        )
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
        "sha256",
        provided_password.encode("utf-8"),
        salt.encode("utf-8"),
        iterations,
        len(stored_hash_bytes),
    )

    # Compare the computed hash with the stored hash (constant-time comparison)
    return hmac.compare_digest(computed_hash, stored_hash_bytes)


def hash_password(password: str) -> str:
    """Hash a password using PBKDF2-SHA256, matching the format used by verify_password."""
    salt = binascii.hexlify(os.urandom(16)).decode("utf-8")
    iterations = 260000
    computed_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        iterations,
    )
    hash_base64 = base64.b64encode(computed_hash).decode("utf-8")
    return f"pdkdf2_sha256${salt}${iterations}${hash_base64}"


def set_auth_cookie(response: Response, user_id: int):
    """Create JWT token and set authentication cookie"""
    payload = {
        "user_id": user_id,
        "exp": datetime.datetime.now(datetime.UTC)
        + datetime.timedelta(days=COOKIE_MAX_DAYS),
    }
    token = jwt.encode(
        payload, config["jwtSecret"], algorithm=config.get("jwtAlgorithm", "HS256")
    )

    # Set HTTP-Only secure cookie
    secure_cookie = not config.get("debug", False)
    response.set_cookie(
        COOKIE_NAME,
        token,
        httponly=True,
        secure=secure_cookie,
        samesite="lax",
        max_age=COOKIE_MAX_AGE,
        path="/",
    )


def get_current_user(db, user_id):
    """Get current user from database"""
    query = "SELECT id, username, fullname, admin FROM users WHERE id = ?"
    user = db.execute(query, (user_id,)).fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": user["id"],
        "username": user["username"],
        "fullname": user["fullname"],
        "admin": bool(user["admin"]),
    }


# Pydantic models for request validation
class LoginRequest(BaseModel):
    username: str
    password: str


class ProfileUpdateRequest(BaseModel):
    fullname: str


class RegisterRequest(BaseModel):
    username: str
    password: str
    email: Optional[str] = None
    fullname: Optional[str] = None


class FormulaPredictionRequest(BaseModel):
    positions: list[int]
    fastest_lap: Optional[int] = None

    @field_validator("positions")
    @classmethod
    def validate_positions_length(cls, v):
        if len(v) != 22:
            raise ValueError("Must have exactly 22 positions")
        return v


class FormulaOneSeasonPredictionRequest(BaseModel):
    teams: list[int]


class FormulaEPredictionRequest(BaseModel):
    pole: Optional[int] = None
    fam: Optional[int] = None
    sam: Optional[int] = None
    fl: Optional[int] = None
    hgc: Optional[int] = None
    first: Optional[int] = None
    second: Optional[int] = None
    third: Optional[int] = None
    fdnf: Optional[int] = None
    hst: Optional[int] = None
    safety_car: Optional[str] = None

    @field_validator("safety_car")
    @classmethod
    def validate_safety_car(cls, v):
        if v is not None and v not in ["yes", "no", ""]:
            raise ValueError('safety_car must be "yes", "no", or ""')
        return v


# Serve index.html for '/' and any path starting with '/app'
@app.get("/", response_class=HTMLResponse)
@app.get("/app", response_class=HTMLResponse)
@app.get("/app/{path:path}", response_class=HTMLResponse)
def serve_index(request: Request, path: str = None):
    with db_transaction() as db:
        user = None
        user_id = get_user_id_from_cookie(request)
        if user_id:
            query = (
                "SELECT id, username, fullname, password, admin FROM users WHERE id = ?"
            )
            user = db.execute(query, (user_id,)).fetchone()

        user_flags = {}
        if user:
            user_flags = {
                "user": {
                    "id": user["id"],
                    "username": user["username"],
                    "fullname": user["fullname"],
                    "admin": bool(user["admin"]),  # Ensure this is a proper boolean
                }
            }

        user_flags_json = json.dumps(user_flags)
        main_js_src = (
            "/static/main-debug.js" if config.get("debug", False) else "/static/main.js"
        )
        main_css_src = (
            "/static/styles.css"
            if config.get("debug", False)
            else "/static/styles.min.css"
        )

        index_html = f"""<!DOCTYPE html>
                <html lang="en-GB">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Pole Prediction</title>
                    <link rel="icon" type="image/svg" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48' viewBox='0 0 16 16'><text x='0' y='14'>🏎️</text></svg>"/>
                    <script src="https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"></script>
                    <link rel="preconnect" href="https://fonts.googleapis.com">
                    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Rajdhani:wght@400;700;900&display=swap" rel="stylesheet">
                    <link rel="stylesheet" href="{main_css_src}">
                    <script src="/static/custom-elements.js"></script>
                    <script src="{main_js_src}"></script>
                </head>
                <body>
                    <h1>Pole Prediction</h1>
                    <script> 
                        const safeLocalStorage = {{
                              getItem(key) {{
                                try {{
                                  return localStorage.getItem(key);
                                }} catch(e) {{
                                  return null;
                                }}
                              }},
                              setItem(key, value) {{
                                try {{
                                  localStorage.setItem(key, value);
                                }} catch(e) {{
                                  // 
                                }}
                              }},
                              removeItem(key, value) {{
                                try {{
                                  localStorage.removeItem(key, value);
                                }} catch(e) {{
                                  // 
                                }}
                              }}
                        }};

                        const user_flags = {user_flags_json};
                        const flags = {{ "flags" : {{ "now": Date.now(), ...user_flags }} }}; 
                        var app = Elm.Main.init(flags); 


                        app.ports.set_local_storage.subscribe(function (args) {{ 
                            safeLocalStorage.setItem(args.key, JSON.stringify(args.value)); 
                        }});

                        app.ports.clear_local_storage.subscribe(function (args) {{ 
                            safeLocalStorage.removeItem(args); 
                        }});


                        app.ports.native_alert.subscribe(function (message) {{ 
                            alert(message); 
                        }});

                        window.addEventListener('storage', function(event) {{
                            console.log('local storage event');
                            console.log(event);
                            if (event.key === 'user') {{
                                app.ports.local_storage_changed.send(
                                    {{ key: event.key,
                                      newValue: JSON.parse(event.newValue) }}
                                );
                            }}
                        }});
                    </script>
                </body>
                </html>"""
        return index_html


# Authentication routes
@app.post("/api/login")
def login(login_data: LoginRequest, response: Response):
    with db_transaction() as db:
        username = login_data.username
        password = login_data.password

        if not username or not password:
            raise HTTPException(
                status_code=400, detail="Username and password required"
            )

        # Get user from database
        query = "SELECT id, username, fullname, password, admin FROM users WHERE username = ?"
        user = db.execute(query, (username,)).fetchone()

        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        if not user["password"]:
            raise HTTPException(
                status_code=401,
                detail="This account uses social login. Please log in with Google.",
            )

        if not verify_password(user["password"], password):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # Set authentication cookie
        set_auth_cookie(response, user["id"])

        return {
            "success": True,
            "message": "Login successful",
            "user": {
                "id": user["id"],
                "username": user["username"],
                "fullname": user["fullname"],
                "admin": bool(user["admin"]),
            },
        }


@app.post("/api/logout")
def logout(response: Response):
    response.delete_cookie(COOKIE_NAME, path="/")
    return {"success": True, "message": "Logged out successfully"}


@app.post("/api/register")
def register(register_data: RegisterRequest, response: Response):
    with db_transaction() as db:
        username = register_data.username.strip()
        password = register_data.password
        email = register_data.email.strip() if register_data.email else None
        fullname = (
            register_data.fullname.strip() if register_data.fullname else username
        )

        if not username or not password:
            raise HTTPException(
                status_code=400, detail="Username and password are required"
            )

        if db.execute(
            "SELECT id FROM users WHERE username = ?", (username,)
        ).fetchone():
            raise HTTPException(status_code=409, detail="Username already taken")

        if (
            email
            and db.execute("SELECT id FROM users WHERE email = ?", (email,)).fetchone()
        ):
            raise HTTPException(status_code=409, detail="Email already registered")

        hashed = hash_password(password)
        db.execute(
            "INSERT INTO users (username, fullname, email, password) VALUES (?, ?, ?, ?)",
            (username, fullname, email, hashed),
        )
        user_id = db.execute("SELECT last_insert_rowid()").fetchone()[0]

        set_auth_cookie(response, user_id)
        user = get_current_user(db, user_id)
        return {"success": True, "message": "Registration successful", "user": user}


def process_oauth_login(db, provider: str, user_info: dict) -> int:
    """Look up or create a user for the given OAuth provider account, return user_id."""
    provider_user_id = str(user_info.get("id") or user_info.get("sub", ""))
    email = user_info.get("email")
    display_name = (
        user_info.get("name") or user_info.get("given_name") or email or "User"
    )

    # If this OAuth account is already linked, return the existing user.
    existing_oauth = db.execute(
        "SELECT user_id FROM user_oauth_accounts WHERE provider = ? AND provider_user_id = ?",
        (provider, provider_user_id),
    ).fetchone()
    if existing_oauth:
        return existing_oauth["user_id"]

    # If an email was provided, check whether a user with that email already exists.
    user_id = None
    if email:
        existing_user = db.execute(
            "SELECT id FROM users WHERE email = ?", (email,)
        ).fetchone()
        if existing_user:
            user_id = existing_user["id"]

    # Otherwise create a brand-new user (no password — OAuth-only).
    if user_id is None:
        base_username = (
            email.split("@")[0] if email else display_name.lower().replace(" ", "_")
        )
        username = base_username
        counter = 1
        while db.execute(
            "SELECT id FROM users WHERE username = ?", (username,)
        ).fetchone():
            username = f"{base_username}{counter}"
            counter += 1

        db.execute(
            "INSERT INTO users (username, fullname, email, password) VALUES (?, ?, ?, NULL)",
            (username, display_name, email),
        )
        user_id = db.execute("SELECT last_insert_rowid()").fetchone()[0]

    # Link this OAuth account to the user.
    db.execute(
        "INSERT INTO user_oauth_accounts (user_id, provider, provider_user_id, email) VALUES (?, ?, ?, ?)",
        (user_id, provider, provider_user_id, email),
    )

    return user_id


@app.get("/api/auth/google/login")
def google_oauth_login():
    """Redirect the browser to Google's OAuth consent screen."""
    google_client_id = os.getenv("GOOGLE_CLIENT_ID")
    if not google_client_id:
        raise HTTPException(status_code=500, detail="Google OAuth is not configured")

    state = secrets.token_urlsafe(32)
    oauth = OAuth2Session(
        google_client_id,
        redirect_uri=f"{config['base_url']}/api/auth/google/callback",
        scope="openid email profile",
    )
    authorization_url, _ = oauth.create_authorization_url(
        GOOGLE_AUTHORIZE_URL, state=state
    )
    oauth_states[state] = True
    return RedirectResponse(url=authorization_url)


@app.get("/api/auth/google/callback")
def google_oauth_callback(
    request: Request,
    response: Response,
    code: Optional[str] = None,
    state: Optional[str] = None,
    error: Optional[str] = None,
):
    """Handle the redirect back from Google after the user consents."""
    if error:
        return RedirectResponse(url=f"{config['base_url']}/app/login")

    if not state or state not in oauth_states:
        raise HTTPException(status_code=400, detail="Invalid OAuth state")
    del oauth_states[state]

    google_client_id = os.getenv("GOOGLE_CLIENT_ID")
    google_client_secret = os.getenv("GOOGLE_CLIENT_SECRET")

    oauth = OAuth2Session(
        google_client_id,
        google_client_secret,
        redirect_uri=f"{config['base_url']}/api/auth/google/callback",
    )
    oauth.fetch_token(GOOGLE_TOKEN_URL, code=code)

    user_info_response = oauth.get(GOOGLE_USERINFO_URL)
    user_info = user_info_response.json()

    with db_transaction() as db:
        user_id = process_oauth_login(db, "google", user_info)

    redirect_response = RedirectResponse(url=f"{config['base_url']}/")
    set_auth_cookie(redirect_response, user_id)
    return redirect_response


@app.get("/api/me")
def get_me(user_id: int = Depends(get_current_user_id)):
    with db_transaction() as db:
        return get_current_user(db, user_id)


@app.post("/api/profile")
def update_profile(
    profile_data: ProfileUpdateRequest, user_id: int = Depends(get_current_user_id)
):
    with db_transaction() as db:
        fullname = profile_data.fullname

        if not fullname:
            raise HTTPException(
                status_code=400, detail="Full name is required and cannot be empty"
            )

        db.execute(
            "update users set fullname = :fullname where id = :user_id;",
            {"fullname": fullname, "user_id": user_id},
        )

        return get_current_user(db, user_id)


# Formula One API routes
@app.get("/api/formula-one/season-events/{season}")
def get_formula_one_events(season: str):
    with db_transaction() as db:
        query = """ select * from formula_one_events_view
    where season = :season
    ;"""
        rows = db.execute(query, {"season": season}).fetchall()
        return [dict(row) for row in rows]


@app.get("/api/formula-one/event-sessions/{event_id}")
def get_formula_one_sessions_by_event(event_id: int):
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
        rows = db.execute(query, {"event_id": event_id}).fetchall()
        return [dict(row) for row in rows]


@app.get("/api/formula-one/session-entrants/{session_id}")
def get_formula_one_session_entrants(session_id: int):
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
        rows = db.execute(query, {"session_id": session_id}).fetchall()
        return [dict(row) for row in rows]


@app.get("/api/formula-one/session-leaderboard/{session_id}")
def get_formula_one_session_leaderboard(
    session_id: int,
    request: Request,
    user_id: Optional[int] = Depends(get_optional_user_id),
):
    with db_transaction() as db:
        return get_formula_one_session_scored_predictions(db, user_id, session_id)


def get_formula_one_session_scored_predictions(db, user_id, session_id):
    # Get the session details to check start time
    session = db.execute(
        "select start_time, name from formula_one_sessions where id = ?", (session_id,)
    ).fetchone()

    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    # Check if predictions are still allowed (before session start)
    session_started = is_db_time_earlier_than_now(session["start_time"])
    where_clause_suffix = (
        "and formula_one_prediction_lines.user = :user_id"
        if not session_started
        else ""
    )

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
    ),
    concordant_pairs as (
        -- For each ordered pair (A predicted ahead of B) from a user's top-10,
        -- score +1 if A ended up genuinely ahead of B in results (top-10 aware).
        select
            a.user,
            sum(case
                when sr_a.position is not null and sr_a.position <= 10
                     and (sr_b.position is null or sr_b.position > sr_a.position) then 1
                else 0
            end) as concordant_score
        from all_predictions a
        join all_predictions b
            on a.user = b.user
            and a.entrant != b.entrant
            and a.position < b.position
            and a.position <= 10
            and b.position <= 10
        left join session_results sr_a on a.entrant = sr_a.entrant
        left join session_results sr_b on b.entrant = sr_b.entrant
        where a.user is not null and a.user != ""
        group by a.user
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
    end as score,
    coalesce(cp.concordant_score, 0) as concordant_score
from all_predictions ap
left join users u on ap.user = u.id
left join session_results sr on ap.entrant = sr.entrant
join formula_one_entrants fe on ap.entrant = fe.id
join drivers d on fe.driver = d.id
join formula_one_teams t on fe.team = t.id
join formula_one_sessions s on ap.session = s.id
left join concordant_pairs cp on ap.user = cp.user
order by
    case when ap.user is null or ap.user = "" then 0 else 1 end,
    user_name,
    ap.position
;"""
    rows = db.execute(query, {"session_id": session_id, "user_id": user_id}).fetchall()

    return [dict(row) for row in rows]


def parse_sqlite_datetime(dt_str):
    # I think there is more to this here, including the 'Z' at the end
    return datetime.datetime.fromisoformat(dt_str.replace(" ", "T"))


def is_db_time_earlier_than_now(db_time_str):
    # Parse the SQLite datetime string
    db_time = parse_sqlite_datetime(db_time_str)

    # Get the current time in UTC
    current_time = datetime.datetime.now(datetime.timezone.utc)

    # Compare times
    return db_time < current_time


@app.post("/api/formula-one/session-prediction/{session_id}")
def save_formula_one_prediction(
    session_id: int,
    prediction_data: FormulaPredictionRequest,
    user_id: int = Depends(get_current_user_id),
):
    with db_transaction() as db:
        # Get fastest lap prediction, could be None
        fastest_lap = prediction_data.fastest_lap

        # Get the session details to check start time
        session = db.execute(
            "select start_time, name from formula_one_sessions where id = ?",
            (session_id,),
        ).fetchone()

        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        # Check if predictions are still allowed (before session start)
        if is_db_time_earlier_than_now(session["start_time"]):
            raise HTTPException(
                status_code=403,
                detail=f"Predictions for {session['name']} are no longer accepted - session has started",
            )

        # First delete any existing predictions for this user and session
        db.execute(
            "delete from formula_one_prediction_lines where user = ? and session = ?",
            (user_id, session_id),
        )

        # Prepare batch insert data
        rows_to_insert = []

        for position, entrant_id in enumerate(prediction_data.positions, start=1):
            # Only set fastest_lap to "true" if it's specified and matches this entrant
            is_fastest_lap = (
                "true"
                if fastest_lap is not None and entrant_id == fastest_lap
                else "false"
            )
            rows_to_insert.append(
                {
                    "user": user_id,
                    "session": session_id,
                    "fastest_lap": is_fastest_lap,
                    "position": position,
                    "entrant": entrant_id,
                }
            )

        # Perform batch insert
        query = """
        insert into formula_one_prediction_lines
            (user, session, fastest_lap, position, entrant)
        values
            (:user, :session, :fastest_lap, :position, :entrant)
        """

        db.executemany(query, rows_to_insert)
        return {"status": "success"}


@app.post("/api/formula-one/session-result/{session_id}")
def save_formula_one_session_result(
    session_id: int,
    prediction_data: FormulaPredictionRequest,
    admin_user_id: int = Depends(require_admin_user),
):
    with db_transaction() as db:
        # Get fastest lap prediction, could be None
        fastest_lap = prediction_data.fastest_lap

        # First delete any existing predictions for this user and session
        db.execute(
            "delete from formula_one_prediction_lines where (user = '' or user is null) and session = :session_id",
            {"session_id": session_id},
        )

        # Prepare batch insert data
        rows_to_insert = []

        for position, entrant_id in enumerate(prediction_data.positions, start=1):
            # Only set fastest_lap to "true" if it's specified and matches this entrant
            is_fastest_lap = (
                "true"
                if fastest_lap is not None and entrant_id == fastest_lap
                else "false"
            )
            rows_to_insert.append(
                {
                    "user": "",
                    "session": session_id,
                    "fastest_lap": is_fastest_lap,
                    "position": position,
                    "entrant": entrant_id,
                }
            )

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


@app.get("/api/formula-one/leaderboard/{season}")
def get_formula_one_leaderboard(season: str):
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
        rows = db.execute(query, {"season": season}).fetchall()
        return {
            "columns": ["sprint-shootout", "sprint", "qualifying", "race", "total"],
            "rows": create_leaderboard_rows(rows),
        }


@app.get("/api/formula-one/constructor-standings/{season}")
def get_formula_one_constructor_standings(season: str):
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
        rows = db.execute(query, {"season": season}).fetchall()
        return {
            "columns": ["total"],
            "rows": create_leaderboard_rows(rows, id="team_id", name="team_name"),
        }


@app.get("/api/formula-one/driver-standings/{season}")
def get_formula_one_driver_standings(season: str):
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
        rows = db.execute(query, {"season": season}).fetchall()
        return {
            "columns": ["total"],
            "rows": create_leaderboard_rows(rows, id="driver_id", name="driver_name"),
        }


@app.get("/api/formula-one/season-teams/{season}")
def get_formula_one_season_teams(season: str):
    with db_transaction() as db:
        query = """
    select
        t.id,
        t.fullname,
        t.shortname,
        coalesce(t.color, '#000000') as color,
        coalesce(t.secondary_color, '#000000') as secondary_color
    from formula_one_teams t
    where t.season = :season
    order by (
        select max(e.rank) from formula_one_entrants e where e.team = t.id
    ) desc
    ;"""
        rows = db.execute(query, {"season": season}).fetchall()
        return [dict(row) for row in rows]


@app.post("/api/formula-one/season-prediction/{season}")
def save_formula_one_season_prediction(
    season: str,
    prediction_data: FormulaOneSeasonPredictionRequest,
    user_id: int = Depends(get_current_user_id),
):
    with db_transaction() as db:
        db.execute(
            "delete from formula_one_season_prediction_lines where user = :user_id and season = :season",
            {"user_id": user_id, "season": season},
        )
        rows_to_insert = [
            {"user": user_id, "season": season, "position": position, "team": team_id}
            for position, team_id in enumerate(prediction_data.teams, start=1)
        ]
        db.executemany(
            "insert into formula_one_season_prediction_lines (user, season, position, team) values (:user, :season, :position, :team)",
            rows_to_insert,
        )
        return {"status": "success"}


@app.get("/api/formula-one/season-leaderboard/{season}")
def get_formula_one_season_leaderboard(
    season: str,
    user_id: Optional[int] = Depends(get_optional_user_id),
):
    with db_transaction() as db:
        season_row = db.execute(
            "SELECT prediction_deadline FROM formula_one_seasons WHERE year = ?", (season,)
        ).fetchone()
        prediction_deadline = season_row["prediction_deadline"] if season_row else None
        deadline_passed = (
            prediction_deadline is None or is_db_time_earlier_than_now(prediction_deadline)
        )
        # Before the deadline only return the current user's own predictions
        user_filter_clause = "" if deadline_passed else "and lines.user = :user_id"
        if not deadline_passed and user_id is None:
            return {"prediction_deadline": prediction_deadline, "rows": []}
        query = f"""with
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
            where teams.season = :season {user_filter_clause}
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
                teams.color as team_color,
                teams.secondary_color as team_secondary_color,
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
                team_color,
                team_secondary_color,
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
        up.team as team_id,
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
        end as difference,
        coalesce(c.team_name, '') as actual_team_name,
        coalesce(c.team_color, '') as actual_team_primary_color,
        coalesce(c.team_secondary_color, '') as actual_team_secondary_color,
        coalesce(c.total, 0) as actual_total
    from user_predictions up
    left join constructors c on up.position = c.position
    order by up.user, up.position
    ;"""
        rows = db.execute(query, {"season": season, "user_id": user_id}).fetchall()
        return {
            "prediction_deadline": prediction_deadline,
            "rows": [dict(row) for row in rows],
        }


def create_leaderboard_rows(rows, id="user_id", name="user_fullname"):
    def make_row(d):
        return {
            "id": d[id],
            "name": d[name],
            "scores": list(
                [
                    s
                    for (field_name, s) in d.items()
                    if field_name != id and field_name != name
                ]
            ),
        }

    return [make_row(dict(row)) for row in rows]


@app.get("/api/formula-e/leaderboard/{season}")
def get_formula_e_leaderboard(season: str):
    rules_version = get_formula_e_points_version(season)
    with db_transaction() as db:
        if rules_version == 1:
            query = """with
            scored_predictions
            as ( select
                    users.id as user_id,
                    users.fullname as user_fullname,
                    case when predictions.first = results.first then 1 else 0 end as race_wins,
                    case when predictions.pole = results.pole then 1 else 0 end as poles,
                    case when predictions.second = results.second then 1 else 0 end as seconds,
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
                cast(coalesce(sum(race_wins), 0) as integer) as 'Race wins',
                cast(coalesce(sum(poles), 0) as integer) as 'Poles',
                cast(coalesce(sum(seconds), 0) as integer) as 'Seconds'
            from scored_predictions
            group by user_id
            order by sum(total) desc, sum(race_wins) desc, sum(poles + seconds) desc
        ;"""

            rows = db.execute(query, {"season": season}).fetchall()

            return {
                "columns": ["Total", "Race wins", "Poles", "Seconds"],
                "rows": create_leaderboard_rows(rows),
            }
        else:
            query = """with
            scored_predictions
            as ( select
                    users.id as user_id,
                    users.fullname as user_fullname,
                    case when predictions.first = results.first then 1 else 0 end as race_wins,
                    case when predictions.pole = results.pole then 1 else 0 end as poles,
                    case when predictions.second = results.second then 1 else 0 end as seconds,
                    case when predictions.third = results.third then 1 else 0 end as thirds,
                    case when predictions.pole = results.pole then 20 else 0 end +
                    case when predictions.fam = results.fam then 5 else 0 end + 
                    case when predictions.sam = results.sam then 5 else 0 end + 
                    case when predictions.fl = results.fl then 10 else 0 end +
                    case when predictions.hgc = results.hgc then 10 else 0 end +
                    case when predictions.first = results.first then 15 else 0 end +
                    case when predictions.first in (results.first, results.second, results.third) then 5 else 0 end +
                    case when predictions.second = results.second then 10 else 0 end +
                    case when predictions.second in (results.first, results.second, results.third) then 5 else 0 end +
                    case when predictions.third = results.third then 5 else 0 end +
                    case when predictions.third in (results.first, results.second, results.third) then 5 else 0 end +
                    case when predictions.fdnf = results.fdnf then 10 else 0 end +
                    case when predictions.hst = results.hst then 10 else 0 end +
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
                cast(coalesce(sum(race_wins), 0) as integer) as 'Race wins',
                cast(coalesce(sum(poles), 0) as integer) as 'Poles',
                cast(coalesce(sum(seconds), 0) as integer) as 'Seconds',
                cast(coalesce(sum(thirds), 0) as integer) as 'Thirds'
            from scored_predictions
            group by user_id
            order by sum(total) desc, sum(race_wins) desc, sum(poles) desc, sum(seconds) desc, sum(thirds) desc
        ;"""

            rows = db.execute(query, {"season": season}).fetchall()

            return {
                "columns": ["Total", "Race wins", "Poles", "Seconds", "Thirds"],
                "rows": create_leaderboard_rows(rows),
            }


@app.get("/api/formula-e/season-events/{season}")
def get_formula_e_events(season: str):
    with db_transaction() as db:
        query = """select * from races where season = :season ;"""
        rows = db.execute(query, {"season": season}).fetchall()
        return [dict(row) for row in rows]


@app.get("/api/formula-e/event-entrants/{race_id}")
def get_formula_e_event_entrants(race_id: int):
    with db_transaction() as db:
        query = """select
        e.id,
        e.number,
        e.driver,
        e.team,
        e.race,
        coalesce(e.participating, 0) as participating,
        d.name as driver_name,
        t.id as team_id,
        t.fullname as team_full_name,
        t.shortname as team_short_name,
        coalesce(t.color, '#000000') as team_primary_color
    from entrants e
    join drivers d on e.driver = d.id
    join teams t on e.team = t.id
    where e.race = :race_id
    order by t.shortname, e.number
    ;"""
        rows = db.execute(query, {"race_id": race_id}).fetchall()
        return [dict(row) for row in rows]


@app.get("/api/formula-e/race-predictions/{race_id}")
def get_formula_e_race_predictions(
    race_id: int,
    request: Request,
    user_id: Optional[int] = Depends(get_optional_user_id),
):
    with db_transaction() as db:
        return get_scored_formula_e_race_predictions(db, user_id, race_id)


def get_formula_e_points_version(season):
    if season in ["2022-23", "2023-24", "2024-25"]:
        return 1
    return 2


def get_scored_formula_e_race_predictions(db, user_id, race_id):
    # Get the race details to check start time
    race = db.execute(
        "select date, season, name from races where id = ?", (race_id,)
    ).fetchone()

    if not race:
        raise HTTPException(status_code=404, detail="Event not found")

    # Check if predictions are still allowed (before session start)
    session_started = is_db_time_earlier_than_now(race["date"])
    where_clause_suffix = (
        "and predictions.user = :user_id" if not session_started else ""
    )

    query = f"""select
    user as user_id,
    users.fullname as user_name, 
    pole,
    fam,
    sam,
    fl,
    hgc,
    first,
    second,
    third,
    fdnf,
    hst,
    safety_car
    from predictions
    join users on predictions.user = users.id
    where race = :race_id {where_clause_suffix}
    """
    prediction_rows = db.execute(
        query, {"race_id": race_id, "user_id": user_id}
    ).fetchall()

    if not session_started:
        result_row = None
    else:
        query = """select
        pole,
        fam,
        sam,
        fl,
        hgc,
        first,
        second,
        third,
        fdnf,
        hst,
        safety_car
        from results
        where race = :race_id
        """
        result_row = db.execute(query, {"race_id": race_id}).fetchone()

    rules_version = get_formula_e_points_version(race["season"])

    def transform_prediction(prediction):
        total = 0
        if result_row is not None:

            def check_prediction(key, points):
                guess = prediction[key]
                if guess and guess == result_row[key]:
                    return points
                return 0

            podium = [result_row["first"], result_row["second"], result_row["third"]]

            def check_podium(key, index, points):
                guess = prediction[key]
                if not guess:
                    return 0
                if guess == podium[index]:
                    return points + 5
                if guess in podium:
                    return 5
                return 0

            if rules_version == 1:
                total += check_prediction("pole", 10)
                total += check_prediction("fam", 10)
                total += check_prediction("fl", 10)
                total += check_prediction("hgc", 10)
                total += check_prediction("first", 20)
                total += check_prediction("second", 10)
                total += check_prediction("third", 10)
                total += check_prediction("fdnf", 10)
                if result_row["safety_car"] in ["yes", "no"]:
                    total += check_prediction("safety_car", 10)
            elif rules_version == 2:
                total += check_prediction("pole", 20)
                total += check_prediction("fam", 5)
                total += check_prediction("sam", 5)
                total += check_prediction("fl", 10)
                total += check_prediction("hgc", 10)
                total += check_podium("first", 0, 15)
                total += check_podium("second", 1, 10)
                total += check_podium("third", 2, 5)
                total += check_prediction("fdnf", 10)
                total += check_prediction("hst", 10)
                if result_row["safety_car"] in ["yes", "no"]:
                    total += check_prediction("safety_car", 10)
        prediction["score"] = total
        return prediction

    predictions = [transform_prediction(dict(row)) for row in prediction_rows]

    response_data = {
        "predictions": predictions,
        "result": dict(result_row) if result_row else None,
    }

    return response_data


@app.post("/api/formula-e/race-prediction/{race_id}")
def save_formula_e_race_prediction(
    race_id: int,
    prediction_data: FormulaEPredictionRequest,
    user_id: int = Depends(get_current_user_id),
):
    with db_transaction() as db:
        # Get the race details to check start time
        race = db.execute(
            "select date, name from races where id = ?", (race_id,)
        ).fetchone()

        if not race:
            raise HTTPException(status_code=404, detail="Event not found")

        # Check if predictions are still allowed (before session start)
        if is_db_time_earlier_than_now(race["date"]):
            raise HTTPException(
                status_code=403,
                detail=f"Predictions for {race['name']} are no longer accepted - session has started",
            )

        # First delete any existing prediction for this race
        db.execute(
            "delete from predictions where user = :user_id and race = :race_id",
            {"user_id": user_id, "race_id": race_id},
        )

        # Insert the new prediction
        query = """
        insert into predictions
            (user, race, pole, fam, sam, fl, hgc, first, second, third, fdnf, hst, safety_car)
        values
            (:user, :race, :pole, :fam, :sam, :fl, :hgc, :first, :second, :third, :fdnf, :hst, :safety_car)
        """

        db.execute(
            query,
            {
                "user": user_id,
                "race": race_id,
                "pole": prediction_data.pole,
                "fam": prediction_data.fam,
                "sam": prediction_data.sam,
                "fl": prediction_data.fl,
                "hgc": prediction_data.hgc,
                "first": prediction_data.first,
                "second": prediction_data.second,
                "third": prediction_data.third,
                "fdnf": prediction_data.fdnf,
                "hst": prediction_data.hst,
                "safety_car": prediction_data.safety_car,
            },
        )

        # Return the predictions for this race
        return get_scored_formula_e_race_predictions(db, user_id, race_id)


@app.post("/api/formula-e/race-result/{race_id}")
def save_formula_e_race_result(
    race_id: int,
    prediction_data: FormulaEPredictionRequest,
    admin_user_id: int = Depends(require_admin_user),
):
    with db_transaction() as db:
        # No validation, none of the fields are required because you can input a partial result
        # for example after qualifying.

        # First delete any existing result for this race
        db.execute("delete from results where race = :race_id", {"race_id": race_id})

        # Insert the new prediction
        query = """
        insert into results
            (race, pole, fam, sam, fl, hgc, first, second, third, fdnf, hst, safety_car)
        values
            (:race, :pole, :fam, :sam, :fl, :hgc, :first, :second, :third, :fdnf, :hst, :safety_car)
        """

        db.execute(
            query,
            {
                "race": race_id,
                "pole": prediction_data.pole,
                "fam": prediction_data.fam,
                "sam": prediction_data.sam,
                "fl": prediction_data.fl,
                "hgc": prediction_data.hgc,
                "first": prediction_data.first,
                "second": prediction_data.second,
                "third": prediction_data.third,
                "fdnf": prediction_data.fdnf,
                "hst": prediction_data.hst,
                "safety_car": prediction_data.safety_car,
            },
        )

        # Return the predictions for this race
        return get_scored_formula_e_race_predictions(db, admin_user_id, race_id)


def configure_app(config_dict):
    """Configure JWT and logging after config is loaded."""
    global config
    config = config_dict

    config["jwtSecret"] = os.getenv(config["jwtSecretVar"])
    config.setdefault("base_url", "https://dev.poleprediction.com")

    # Configure logging based on config
    if config.get("prettyLogging", False):
        import logging

        logging.basicConfig(
            level=logging.DEBUG if config.get("logLevel", 0) <= 0 else logging.INFO,
            format="%(asctime)s [%(levelname)s] %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        logger = logging.getLogger(__name__)
        logger.info(f"Starting application with config: {config['dbFilepath']}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python app.py <config_file.json>")
        sys.exit(1)

    config_file = sys.argv[1]
    try:
        with open(config_file, "r") as f:
            config_dict = json.load(f)
    except Exception as e:
        print(f"Error loading configuration: {e}")
        sys.exit(1)

    configure_app(config_dict)

    # Run the application with settings from config
    uvicorn.run(
        app,
        host="localhost",
        port=config.get("port", 8080),
        log_level="debug" if config.get("debug", False) else "info",
    )
