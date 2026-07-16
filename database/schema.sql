-- ==========================================================
-- Log Tracker Database Schema
-- ShaktiDB / PostgreSQL
-- ==========================================================


-- ==========================================================
-- Access Groups
-- ==========================================================

CREATE TABLE access_group (

    gid SERIAL PRIMARY KEY,

    group_name VARCHAR(30) UNIQUE NOT NULL

);



-- ==========================================================
-- Users
-- ==========================================================

CREATE TABLE app_user (

    uid SERIAL PRIMARY KEY,

    username VARCHAR(30) UNIQUE NOT NULL,

    password_hash TEXT NOT NULL,

    role VARCHAR(10) NOT NULL
        CHECK (role IN ('root','admin','user')),

    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    group_id INT,

    FOREIGN KEY (group_id)
        REFERENCES access_group(gid)
        ON DELETE SET NULL

);



-- ==========================================================
-- Directories
-- ==========================================================

CREATE TABLE directory (

    did SERIAL PRIMARY KEY,

    directory_name VARCHAR(100) NOT NULL,

    full_path VARCHAR(255) UNIQUE NOT NULL,

    owner INT NOT NULL,

    parent_directory INT,

    FOREIGN KEY (owner)
        REFERENCES app_user(uid)
        ON DELETE CASCADE,

    FOREIGN KEY (parent_directory)
        REFERENCES directory(did)
        ON DELETE CASCADE

);



-- ==========================================================
-- Files
-- ==========================================================

CREATE TABLE file_entry (

    fid SERIAL PRIMARY KEY,

    file_name VARCHAR(100) NOT NULL,

    extension VARCHAR(15),

    owner INT NOT NULL,

    directory_id INT NOT NULL,

    file_size BIGINT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    is_deleted BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (owner)
        REFERENCES app_user(uid)
        ON DELETE CASCADE,

    FOREIGN KEY (directory_id)
        REFERENCES directory(did)
        ON DELETE CASCADE

);



-- ==========================================================
-- Audit Logs
-- ==========================================================

CREATE TABLE audit_log (

    lid SERIAL PRIMARY KEY,

    logged_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    performed_by INT NOT NULL,

    action_type VARCHAR(20) NOT NULL
    CHECK (

        action_type IN (

            'login',

            'logout',

            'created',

            'updated',

            'renamed',

            'deleted',

            'viewlog',

            'adduser',

            'removeuser',

            'addadmin',

            'removeadmin'

        )

    ),

    target_type VARCHAR(20),

    target_id INT,

    details JSONB NOT NULL,

    FOREIGN KEY (performed_by)
        REFERENCES app_user(uid)
        ON DELETE CASCADE

);
CREATE INDEX idx_user_username
ON app_user(username);

CREATE INDEX idx_file_owner
ON file_entry(owner);

CREATE INDEX idx_directory_owner
ON directory(owner);

CREATE INDEX idx_log_user
ON audit_log(performed_by);

CREATE INDEX idx_log_action
ON audit_log(action_type);

CREATE INDEX idx_log_time
ON audit_log(logged_at);

CREATE INDEX idx_log_target
ON audit_log(target_type, target_id);

CREATE INDEX idx_log_details
ON audit_log
USING GIN(details);
