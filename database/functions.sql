-- ==========================================================
-- Utility Functions
-- ==========================================================

CREATE OR REPLACE FUNCTION is_root(
    p_uid INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS
$$
BEGIN

    RETURN EXISTS (

        SELECT 1

        FROM app_user

        WHERE uid = p_uid
        AND role = 'root'

    );

END;
$$;


CREATE OR REPLACE FUNCTION is_admin(
    p_uid INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS
$$
BEGIN

    RETURN EXISTS (

        SELECT 1

        FROM app_user

        WHERE uid = p_uid
        AND role IN ('root','admin')

    );

END;
$$;


CREATE OR REPLACE FUNCTION is_owner(
    p_uid INT,
    p_fid INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS
$$
BEGIN

    RETURN EXISTS (

        SELECT 1

        FROM file_entry

        WHERE fid = p_fid
        AND owner = p_uid

    );

END;
$$;


-- ==========================================================
-- Logging
-- ==========================================================

CREATE OR REPLACE FUNCTION insert_log(

    p_user_id INT,

    p_action VARCHAR,

    p_target_type VARCHAR,

    p_target_id INT,

    p_details JSONB

)

RETURNS VOID

LANGUAGE plpgsql

AS

$$

BEGIN

    INSERT INTO audit_log(

        performed_by,

        action_type,

        target_type,

        target_id,

        details

    )

    VALUES(

        p_user_id,

        p_action,

        p_target_type,

        p_target_id,

        p_details

    );

END;

$$;


CREATE OR REPLACE FUNCTION get_logs()

RETURNS TABLE(

    lid INT,

    logged_at TIMESTAMP,

    username VARCHAR,

    role VARCHAR,

    action_type VARCHAR,

    target_type VARCHAR,

    target_id INT,

    details JSONB

)

LANGUAGE plpgsql

AS

$$

BEGIN

RETURN QUERY

SELECT

    l.lid,

    l.logged_at,

    u.username,

    u.role,

    l.action_type,

    l.target_type,

    l.target_id,

    l.details

FROM audit_log l

JOIN app_user u

ON l.performed_by = u.uid

ORDER BY l.logged_at DESC;

END;

$$;


CREATE OR REPLACE FUNCTION get_user_logs(

    p_uid INT

)

RETURNS TABLE(

    lid INT,

    logged_at TIMESTAMP,

    action_type VARCHAR,

    target_type VARCHAR,

    target_id INT,

    details JSONB

)

LANGUAGE plpgsql

AS

$$

BEGIN

RETURN QUERY

SELECT

    lid,

    logged_at,

    action_type,

    target_type,

    target_id,

    details

FROM audit_log

WHERE performed_by = p_uid

ORDER BY logged_at DESC;

END;

$$;


CREATE OR REPLACE FUNCTION get_logs_by_action(

    p_action VARCHAR

)

RETURNS TABLE(

    lid INT,

    logged_at TIMESTAMP,

    username VARCHAR,

    target_type VARCHAR,

    target_id INT,

    details JSONB

)

LANGUAGE plpgsql

AS

$$

BEGIN

RETURN QUERY

SELECT

    l.lid,

    l.logged_at,

    u.username,

    l.target_type,

    l.target_id,

    l.details

FROM audit_log l

JOIN app_user u

ON u.uid = l.performed_by

WHERE l.action_type = p_action

ORDER BY l.logged_at DESC;

END;

$$;


CREATE OR REPLACE FUNCTION get_logs_between_dates(

    p_start TIMESTAMP,

    p_end TIMESTAMP

)

RETURNS TABLE(

    lid INT,

    logged_at TIMESTAMP,

    username VARCHAR,

    action_type VARCHAR,

    details JSONB

)

LANGUAGE plpgsql

AS

$$

BEGIN

RETURN QUERY

SELECT

    l.lid,

    l.logged_at,

    u.username,

    l.action_type,

    l.details

FROM audit_log l

JOIN app_user u

ON u.uid = l.performed_by

WHERE l.logged_at BETWEEN p_start AND p_end

ORDER BY l.logged_at DESC;

END;

$$;

-- ==========================================================
-- Authentication
-- ==========================================================

CREATE OR REPLACE FUNCTION login_user(

    p_username VARCHAR

)

RETURNS TABLE(

    uid INT,

    username VARCHAR,

    password_hash TEXT,

    role VARCHAR,

    group_id INT

)

LANGUAGE plpgsql

AS

$$

BEGIN

RETURN QUERY

SELECT

    u.uid,

    u.username,

    u.password_hash,

    u.role,

    u.group_id

FROM app_user u

WHERE u.username = p_username;

END;

$$;


CREATE OR REPLACE FUNCTION log_login(

    p_uid INT

)

RETURNS VOID

LANGUAGE plpgsql

AS

$$

BEGIN

    PERFORM insert_log(

        p_uid,

        'login',

        'user',

        p_uid,

        jsonb_build_object(

            'event','User logged in'

        )

    );

END;

$$;


CREATE OR REPLACE FUNCTION log_logout(

    p_uid INT

)

RETURNS VOID

LANGUAGE plpgsql

AS

$$

BEGIN

    PERFORM insert_log(

        p_uid,

        'logout',

        'user',

        p_uid,

        jsonb_build_object(

            'event','User logged out'

        )

    );

END;

$$;

-- ==========================================================
-- User Management
-- ==========================================================

-- ----------------------------------------------------------
-- Create User
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION create_user(

    p_created_by INT,
    p_username VARCHAR,
    p_password_hash TEXT,
    p_role VARCHAR,
    p_group_id INT

)

RETURNS INT

LANGUAGE plpgsql

AS
$$

DECLARE

    new_uid INT;

BEGIN

    -- Only admins and root can create users

    IF NOT is_admin(p_created_by) THEN

        RAISE EXCEPTION 'Permission denied';

    END IF;


    -- Only root can create admins

    IF p_role = 'admin'
       AND NOT is_root(p_created_by) THEN

        RAISE EXCEPTION
        'Only root can create admins';

    END IF;


    INSERT INTO app_user(

        username,
        password_hash,
        role,
        group_id

    )

    VALUES(

        p_username,
        p_password_hash,
        p_role,
        p_group_id

    )

    RETURNING uid

    INTO new_uid;


    PERFORM insert_log(

        p_created_by,

        'created',

        'user',

        new_uid,

        jsonb_build_object(

            'username',p_username,

            'role',p_role,

            'group_id',p_group_id

        )

    );


    RETURN new_uid;

END;

$$;


-- ----------------------------------------------------------
-- Update User
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION update_user(

    p_updated_by INT,

    p_uid INT,

    p_username VARCHAR,

    p_group_id INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    old_username VARCHAR;

    old_group INT;

BEGIN

    IF NOT is_admin(p_updated_by) THEN

        RAISE EXCEPTION
        'Permission denied';

    END IF;


    SELECT

        username,
        group_id

    INTO

        old_username,
        old_group

    FROM app_user

    WHERE uid = p_uid;


    UPDATE app_user

    SET

        username = p_username,

        group_id = p_group_id

    WHERE uid = p_uid;


    PERFORM insert_log(

        p_updated_by,

        'updated',

        'user',

        p_uid,

        jsonb_build_object(

            'old_username',old_username,

            'new_username',p_username,

            'old_group',old_group,

            'new_group',p_group_id

        )

    );

END;

$$;


-- ----------------------------------------------------------
-- Change Password
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION change_password(

    p_uid INT,

    p_password_hash TEXT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

BEGIN

    UPDATE app_user

    SET password_hash = p_password_hash

    WHERE uid = p_uid;

END;

$$;


-- ----------------------------------------------------------
-- Promote Admin
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION promote_admin(

    p_root INT,

    p_uid INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

BEGIN

    IF NOT is_root(p_root) THEN

        RAISE EXCEPTION
        'Only root can promote admins';

    END IF;


    UPDATE app_user

    SET role='admin'

    WHERE uid=p_uid;


    PERFORM insert_log(

        p_root,

        'updated',

        'user',

        p_uid,

        jsonb_build_object(

            'old_role','user',

            'new_role','admin'

        )

    );

END;

$$;


-- ----------------------------------------------------------
-- Demote Admin
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION demote_admin(

    p_root INT,

    p_uid INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

BEGIN

    IF NOT is_root(p_root) THEN

        RAISE EXCEPTION
        'Only root can demote admins';

    END IF;


    UPDATE app_user

    SET role='user'

    WHERE uid=p_uid;


    PERFORM insert_log(

        p_root,

        'updated',

        'user',

        p_uid,

        jsonb_build_object(

            'old_role','admin',

            'new_role','user'

        )

    );

END;

$$;


-- ----------------------------------------------------------
-- Remove User
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION remove_user(

    p_removed_by INT,

    p_uid INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    target_role VARCHAR;

    target_name VARCHAR;

BEGIN

    SELECT

        role,
        username

    INTO

        target_role,
        target_name

    FROM app_user

    WHERE uid=p_uid;


    IF target_role='root' THEN

        RAISE EXCEPTION
        'Root cannot be removed';

    END IF;


    IF target_role='admin'
       AND NOT is_root(p_removed_by) THEN

        RAISE EXCEPTION
        'Only root can remove admins';

    END IF;


    IF target_role='user'
       AND NOT is_admin(p_removed_by) THEN

        RAISE EXCEPTION
        'Permission denied';

    END IF;


    DELETE

    FROM app_user

    WHERE uid=p_uid;


    PERFORM insert_log(

        p_removed_by,

        'deleted',

        'user',

        p_uid,

        jsonb_build_object(

            'username',target_name,

            'role',target_role

        )

    );

END;

$$;

-- ==========================================================
-- Directory Management
-- ==========================================================

-- ----------------------------------------------------------
-- Create Directory
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION create_directory(

    p_created_by INT,

    p_owner INT,

    p_directory_name VARCHAR,

    p_full_path VARCHAR,

    p_parent_directory INT

)

RETURNS INT

LANGUAGE plpgsql

AS
$$

DECLARE

    new_did INT;

BEGIN

    -- Permission Check

    IF NOT (

        is_root(p_created_by)

        OR

        is_admin(p_created_by)

        OR

        p_created_by = p_owner

    ) THEN

        RAISE EXCEPTION
        'Permission denied';

    END IF;


    INSERT INTO directory(

        directory_name,

        full_path,

        owner,

        parent_directory

    )

    VALUES(

        p_directory_name,

        p_full_path,

        p_owner,

        p_parent_directory

    )

    RETURNING did

    INTO new_did;


    PERFORM insert_log(

        p_created_by,

        'created',

        'directory',

        new_did,

        jsonb_build_object(

            'directory_name',p_directory_name,

            'path',p_full_path,

            'owner',p_owner

        )

    );


    RETURN new_did;

END;

$$;



-- ----------------------------------------------------------
-- Rename Directory
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION rename_directory(

    p_user INT,

    p_directory INT,

    p_new_name VARCHAR,

    p_new_path VARCHAR

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    old_name VARCHAR;

    old_path VARCHAR;

BEGIN

    SELECT

        directory_name,

        full_path

    INTO

        old_name,

        old_path

    FROM directory

    WHERE did = p_directory;


    UPDATE directory

    SET

        directory_name = p_new_name,

        full_path = p_new_path

    WHERE did = p_directory;


    PERFORM insert_log(

        p_user,

        'renamed',

        'directory',

        p_directory,

        jsonb_build_object(

            'old_name',old_name,

            'new_name',p_new_name,

            'old_path',old_path,

            'new_path',p_new_path

        )

    );

END;

$$;



-- ----------------------------------------------------------
-- Move Directory
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION move_directory(

    p_user INT,

    p_directory INT,

    p_new_parent INT,

    p_new_path VARCHAR

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    old_parent INT;

    old_path VARCHAR;

BEGIN

    SELECT

        parent_directory,

        full_path

    INTO

        old_parent,

        old_path

    FROM directory

    WHERE did = p_directory;


    UPDATE directory

    SET

        parent_directory = p_new_parent,

        full_path = p_new_path

    WHERE did = p_directory;


    PERFORM insert_log(

        p_user,

        'updated',

        'directory',

        p_directory,

        jsonb_build_object(

            'old_parent',old_parent,

            'new_parent',p_new_parent,

            'old_path',old_path,

            'new_path',p_new_path

        )

    );

END;

$$;



-- ----------------------------------------------------------
-- Delete Directory
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_directory(

    p_user INT,

    p_directory INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    dir_name VARCHAR;

    dir_path VARCHAR;

BEGIN

    SELECT

        directory_name,

        full_path

    INTO

        dir_name,

        dir_path

    FROM directory

    WHERE did = p_directory;


    DELETE

    FROM directory

    WHERE did = p_directory;


    PERFORM insert_log(

        p_user,

        'deleted',

        'directory',

        p_directory,

        jsonb_build_object(

            'directory_name',dir_name,

            'path',dir_path

        )

    );

END;

$$;



-- ----------------------------------------------------------
-- List Directories Accessible to User
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION list_directories(

    p_user INT

)

RETURNS TABLE(

    did INT,

    directory_name VARCHAR,

    full_path VARCHAR,

    owner INT,

    parent_directory INT

)

LANGUAGE plpgsql

AS
$$

BEGIN

    RETURN QUERY

    SELECT

        d.did,

        d.directory_name,

        d.full_path,

        d.owner,

        d.parent_directory

    FROM directory d

    WHERE

        is_root(p_user)

        OR

        d.owner = p_user

        OR

        (

            is_admin(p_user)

            AND

            d.owner IN (

                SELECT uid

                FROM app_user

                WHERE group_id = (

                    SELECT group_id

                    FROM app_user

                    WHERE uid = p_user

                )

            )

        )

    ORDER BY d.full_path;

END;

$$;

-- ==========================================================
-- File Management
-- Part 5.1
-- ==========================================================

-- ----------------------------------------------------------
-- Create File
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION create_file(

    p_created_by INT,

    p_owner INT,

    p_directory_id INT,

    p_file_name VARCHAR,

    p_extension VARCHAR,

    p_file_size BIGINT

)

RETURNS INT

LANGUAGE plpgsql

AS
$$

DECLARE

    new_fid INT;

BEGIN

    -- Root can create anywhere
    -- Admin can create for users
    -- User can create only for themselves

    IF NOT (

        is_root(p_created_by)

        OR

        is_admin(p_created_by)

        OR

        p_created_by = p_owner

    ) THEN

        RAISE EXCEPTION
        'Permission denied';

    END IF;


    -- Verify directory exists

    IF NOT EXISTS (

        SELECT 1

        FROM directory

        WHERE did = p_directory_id

    ) THEN

        RAISE EXCEPTION
        'Directory does not exist';

    END IF;


    INSERT INTO file_entry(

        file_name,

        extension,

        owner,

        directory_id,

        file_size

    )

    VALUES(

        p_file_name,

        p_extension,

        p_owner,

        p_directory_id,

        p_file_size

    )

    RETURNING fid

    INTO new_fid;


    PERFORM insert_log(

        p_created_by,

        'created',

        'file',

        new_fid,

        jsonb_build_object(

            'file_name',p_file_name,

            'extension',p_extension,

            'directory',p_directory_id,

            'owner',p_owner,

            'size',p_file_size

        )

    );


    RETURN new_fid;

END;

$$;



-- ----------------------------------------------------------
-- Rename File
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION rename_file(

    p_user INT,

    p_fid INT,

    p_new_name VARCHAR,

    p_new_extension VARCHAR

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    old_name VARCHAR;

    old_extension VARCHAR;

BEGIN

    -- Verify file exists

    IF NOT EXISTS (

        SELECT 1

        FROM file_entry

        WHERE fid = p_fid

    ) THEN

        RAISE EXCEPTION
        'File not found';

    END IF;


    -- Permission

    IF NOT (

        is_root(p_user)

        OR

        is_admin(p_user)

        OR

        is_owner(p_user,p_fid)

    ) THEN

        RAISE EXCEPTION
        'Permission denied';

    END IF;


    SELECT

        file_name,

        extension

    INTO

        old_name,

        old_extension

    FROM file_entry

    WHERE fid = p_fid;


    UPDATE file_entry

    SET

        file_name = p_new_name,

        extension = p_new_extension,

        updated_at = CURRENT_TIMESTAMP

    WHERE fid = p_fid;


    PERFORM insert_log(

        p_user,

        'renamed',

        'file',

        p_fid,

        jsonb_build_object(

            'old_name',old_name,

            'new_name',p_new_name,

            'old_extension',old_extension,

            'new_extension',p_new_extension

        )

    );

END;

$$;

-- ==========================================================
-- Update File Metadata
-- ==========================================================

CREATE OR REPLACE FUNCTION update_file(

    p_user INT,

    p_fid INT,

    p_file_size BIGINT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    old_size BIGINT;

BEGIN

    -- Check file exists

    IF NOT EXISTS (

        SELECT 1

        FROM file_entry

        WHERE fid = p_fid
        AND is_deleted = FALSE

    ) THEN

        RAISE EXCEPTION 'File not found';

    END IF;


    -- Permission check

    IF NOT (

        is_root(p_user)

        OR is_admin(p_user)

        OR is_owner(p_user,p_fid)

    ) THEN

        RAISE EXCEPTION 'Permission denied';

    END IF;


    SELECT file_size

    INTO old_size

    FROM file_entry

    WHERE fid = p_fid;


    UPDATE file_entry

    SET

        file_size = p_file_size,

        updated_at = CURRENT_TIMESTAMP

    WHERE fid = p_fid;


    PERFORM insert_log(

        p_user,

        'updated',

        'file',

        p_fid,

        jsonb_build_object(

            'old_size',old_size,

            'new_size',p_file_size

        )

    );

END;

$$;



-- ==========================================================
-- Move File
-- ==========================================================

CREATE OR REPLACE FUNCTION move_file(

    p_user INT,

    p_fid INT,

    p_new_directory INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    old_directory INT;

    file_name VARCHAR;

BEGIN

    -- File exists

    IF NOT EXISTS (

        SELECT 1

        FROM file_entry

        WHERE fid = p_fid
        AND is_deleted = FALSE

    ) THEN

        RAISE EXCEPTION 'File not found';

    END IF;


    -- Directory exists

    IF NOT EXISTS (

        SELECT 1

        FROM directory

        WHERE did = p_new_directory

    ) THEN

        RAISE EXCEPTION 'Destination directory not found';

    END IF;


    -- Permission

    IF NOT (

        is_root(p_user)

        OR is_admin(p_user)

        OR is_owner(p_user,p_fid)

    ) THEN

        RAISE EXCEPTION 'Permission denied';

    END IF;


    SELECT

        directory_id,

        file_name

    INTO

        old_directory,

        file_name

    FROM file_entry

    WHERE fid = p_fid;


    UPDATE file_entry

    SET

        directory_id = p_new_directory,

        updated_at = CURRENT_TIMESTAMP

    WHERE fid = p_fid;


    PERFORM insert_log(

        p_user,

        'updated',

        'file',

        p_fid,

        jsonb_build_object(

            'file_name',file_name,

            'old_directory',old_directory,

            'new_directory',p_new_directory

        )

    );

END;

$$;

-- ==========================================================
-- Delete File (Soft Delete)
-- ==========================================================

CREATE OR REPLACE FUNCTION delete_file(

    p_user INT,

    p_fid INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    v_file_name VARCHAR;

    v_directory INT;

BEGIN

    -- Verify file exists

    IF NOT EXISTS (

        SELECT 1

        FROM file_entry

        WHERE fid = p_fid
        AND is_deleted = FALSE

    ) THEN

        RAISE EXCEPTION
        'File not found';

    END IF;


    -- Permission

    IF NOT (

        is_root(p_user)

        OR

        is_admin(p_user)

        OR

        is_owner(p_user,p_fid)

    ) THEN

        RAISE EXCEPTION
        'Permission denied';

    END IF;


    SELECT

        file_name,

        directory_id

    INTO

        v_file_name,

        v_directory

    FROM file_entry

    WHERE fid = p_fid;


    UPDATE file_entry

    SET

        is_deleted = TRUE,

        updated_at = CURRENT_TIMESTAMP

    WHERE fid = p_fid;


    PERFORM insert_log(

        p_user,

        'deleted',

        'file',

        p_fid,

        jsonb_build_object(

            'file_name',v_file_name,

            'directory_id',v_directory,

            'deleted_at',CURRENT_TIMESTAMP

        )

    );

END;

$$;



-- ==========================================================
-- Restore File
-- ==========================================================

CREATE OR REPLACE FUNCTION restore_file(

    p_user INT,

    p_fid INT

)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

DECLARE

    v_file_name VARCHAR;

    v_directory INT;

BEGIN

    -- Verify deleted file exists

    IF NOT EXISTS (

        SELECT 1

        FROM file_entry

        WHERE fid = p_fid
        AND is_deleted = TRUE

    ) THEN

        RAISE EXCEPTION
        'Deleted file not found';

    END IF;


    -- Permission

    IF NOT (

        is_root(p_user)

        OR

        is_admin(p_user)

        OR

        is_owner(p_user,p_fid)

    ) THEN

        RAISE EXCEPTION
        'Permission denied';

    END IF;


    SELECT

        file_name,

        directory_id

    INTO

        v_file_name,

        v_directory

    FROM file_entry

    WHERE fid = p_fid;


    UPDATE file_entry

    SET

        is_deleted = FALSE,

        updated_at = CURRENT_TIMESTAMP

    WHERE fid = p_fid;


    PERFORM insert_log(

        p_user,

        'updated',

        'file',

        p_fid,

        jsonb_build_object(

            'operation','restore',

            'file_name',v_file_name,

            'directory_id',v_directory,

            'restored_at',CURRENT_TIMESTAMP

        )

    );

END;

$$;

-- ==========================================================
-- List Files Accessible to User
-- ==========================================================

CREATE OR REPLACE FUNCTION list_files(

    p_user INT

)

RETURNS TABLE(

    fid INT,

    file_name VARCHAR,

    extension VARCHAR,

    owner INT,

    directory_id INT,

    file_size BIGINT,

    created_at TIMESTAMP,

    updated_at TIMESTAMP

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    f.fid,

    f.file_name,

    f.extension,

    f.owner,

    f.directory_id,

    f.file_size,

    f.created_at,

    f.updated_at

FROM file_entry f

WHERE

    f.is_deleted = FALSE

    AND

    (

        is_root(p_user)

        OR

        f.owner = p_user

        OR

        (

            is_admin(p_user)

            AND

            f.owner IN (

                SELECT uid

                FROM app_user

                WHERE group_id = (

                    SELECT group_id

                    FROM app_user

                    WHERE uid = p_user

                )

            )

        )

    )

ORDER BY

    f.file_name;

END;

$$;



-- ==========================================================
-- Get File Details
-- ==========================================================

CREATE OR REPLACE FUNCTION get_file_details(

    p_user INT,

    p_fid INT

)

RETURNS TABLE(

    fid INT,

    file_name VARCHAR,

    extension VARCHAR,

    owner INT,

    directory_id INT,

    file_size BIGINT,

    created_at TIMESTAMP,

    updated_at TIMESTAMP,

    is_deleted BOOLEAN

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    f.fid,

    f.file_name,

    f.extension,

    f.owner,

    f.directory_id,

    f.file_size,

    f.created_at,

    f.updated_at,

    f.is_deleted

FROM file_entry f

WHERE

    f.fid = p_fid

    AND

    (

        is_root(p_user)

        OR

        f.owner = p_user

        OR

        (

            is_admin(p_user)

            AND

            f.owner IN (

                SELECT uid

                FROM app_user

                WHERE group_id = (

                    SELECT group_id

                    FROM app_user

                    WHERE uid = p_user

                )

            )

        )

    );

END;

$$;



-- ==========================================================
-- Search Files
-- ==========================================================

CREATE OR REPLACE FUNCTION search_files(

    p_user INT,

    p_keyword VARCHAR

)

RETURNS TABLE(

    fid INT,

    file_name VARCHAR,

    extension VARCHAR,

    owner INT,

    directory_id INT,

    file_size BIGINT

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    f.fid,

    f.file_name,

    f.extension,

    f.owner,

    f.directory_id,

    f.file_size

FROM file_entry f

WHERE

    f.is_deleted = FALSE

    AND

    (

        LOWER(f.file_name)

        LIKE

        LOWER('%' || p_keyword || '%')

    )

    AND

    (

        is_root(p_user)

        OR

        f.owner = p_user

        OR

        (

            is_admin(p_user)

            AND

            f.owner IN (

                SELECT uid

                FROM app_user

                WHERE group_id = (

                    SELECT group_id

                    FROM app_user

                    WHERE uid = p_user

                )

            )

        )

    )

ORDER BY

    f.file_name;

END;

$$;

-- ==========================================================
-- Dashboard Statistics
-- ==========================================================

CREATE OR REPLACE FUNCTION dashboard_stats()

RETURNS TABLE(

    total_users BIGINT,

    total_directories BIGINT,

    total_files BIGINT,

    total_logs BIGINT

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    (SELECT COUNT(*) FROM app_user),

    (SELECT COUNT(*) FROM directory),

    (SELECT COUNT(*)
        FROM file_entry
        WHERE is_deleted = FALSE),

    (SELECT COUNT(*) FROM audit_log);

END;

$$;



-- ==========================================================
-- Recent Activity
-- ==========================================================

CREATE OR REPLACE FUNCTION recent_activity(

    p_limit INT DEFAULT 20

)

RETURNS TABLE(

    lid INT,

    logged_at TIMESTAMP,

    username VARCHAR,

    action_type VARCHAR,

    target_type VARCHAR,

    target_id INT,

    details JSONB

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    l.lid,

    l.logged_at,

    u.username,

    l.action_type,

    l.target_type,

    l.target_id,

    l.details

FROM audit_log l

JOIN app_user u

ON u.uid = l.performed_by

ORDER BY l.logged_at DESC

LIMIT p_limit;

END;

$$;



-- ==========================================================
-- Number of Files Per User
-- ==========================================================

CREATE OR REPLACE FUNCTION file_count_by_user()

RETURNS TABLE(

    uid INT,

    username VARCHAR,

    file_count BIGINT

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    u.uid,

    u.username,

    COUNT(f.fid)

FROM app_user u

LEFT JOIN file_entry f

ON

    u.uid = f.owner

    AND

    f.is_deleted = FALSE

GROUP BY

    u.uid,

    u.username

ORDER BY

    COUNT(f.fid) DESC;

END;

$$;



-- ==========================================================
-- Number of Directories Per User
-- ==========================================================

CREATE OR REPLACE FUNCTION directory_count_by_user()

RETURNS TABLE(

    uid INT,

    username VARCHAR,

    directory_count BIGINT

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    u.uid,

    u.username,

    COUNT(d.did)

FROM app_user u

LEFT JOIN directory d

ON u.uid = d.owner

GROUP BY

    u.uid,

    u.username

ORDER BY

    COUNT(d.did) DESC;

END;

$$;



-- ==========================================================
-- User Statistics
-- ==========================================================

CREATE OR REPLACE FUNCTION user_statistics()

RETURNS TABLE(

    role VARCHAR,

    users BIGINT

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    role,

    COUNT(*)

FROM app_user

GROUP BY role

ORDER BY role;

END;

$$;



-- ==========================================================
-- Most Active Users
-- ==========================================================

CREATE OR REPLACE FUNCTION most_active_users(

    p_limit INT DEFAULT 10

)

RETURNS TABLE(

    uid INT,

    username VARCHAR,

    actions BIGINT

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    u.uid,

    u.username,

    COUNT(l.lid)

FROM app_user u

JOIN audit_log l

ON u.uid = l.performed_by

GROUP BY

    u.uid,

    u.username

ORDER BY

    COUNT(l.lid) DESC

LIMIT p_limit;

END;

$$;



-- ==========================================================
-- Recent Deleted Files
-- ==========================================================

CREATE OR REPLACE FUNCTION deleted_files()

RETURNS TABLE(

    fid INT,

    file_name VARCHAR,

    owner INT,

    updated_at TIMESTAMP

)

LANGUAGE plpgsql

AS
$$

BEGIN

RETURN QUERY

SELECT

    fid,

    file_name,

    owner,

    updated_at

FROM file_entry

WHERE is_deleted = TRUE

ORDER BY updated_at DESC;

END;

$$;


