-- Add email column to users, make password nullable, and create user_oauth_accounts table.
-- SQLite does not support ALTER COLUMN, so we use copy-drop-create-copy to modify the users table.
-- We also cannot use ALTER TABLE ... RENAME TO because other tables in the schema have
-- check constraints with double-quoted string literals which fail re-parsing on rename.

BEGIN TRANSACTION;

CREATE TABLE users_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fullname TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    email TEXT,
    password TEXT,
    admin integer default 0
);

INSERT INTO users_new (id, fullname, username, email, password, admin)
    SELECT id, fullname, username, NULL, password, admin FROM users;

DROP TABLE users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fullname TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    email TEXT,
    password TEXT,
    admin integer default 0
);

INSERT INTO users (id, fullname, username, email, password, admin)
    SELECT id, fullname, username, email, password, admin FROM users_new;

DROP TABLE users_new;

-- Table linking users to OAuth provider accounts.
-- A user can have multiple OAuth accounts (e.g. Google + GitHub).
-- One OAuth account maps to exactly one user.
CREATE TABLE user_oauth_accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    provider_user_id TEXT NOT NULL,
    email TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, provider_user_id)
);

CREATE INDEX idx_oauth_user_id ON user_oauth_accounts(user_id);

COMMIT;
