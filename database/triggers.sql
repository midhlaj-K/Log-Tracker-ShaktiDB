-- ==========================================================
-- Trigger Functions
-- ==========================================================

-------------------------------------------------------------
-- Update updated_at Automatically
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_timestamp()

RETURNS TRIGGER

LANGUAGE plpgsql

AS
$$

BEGIN

    NEW.updated_at = CURRENT_TIMESTAMP;

    RETURN NEW;

END;

$$;



-------------------------------------------------------------
-- File Entry Trigger
-------------------------------------------------------------

CREATE TRIGGER trg_update_file_timestamp

BEFORE UPDATE

ON file_entry

FOR EACH ROW

EXECUTE FUNCTION update_timestamp();



-------------------------------------------------------------
-- Prevent Root Role Modification
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION protect_root()

RETURNS TRIGGER

LANGUAGE plpgsql

AS
$$

BEGIN

    IF OLD.role = 'root'
    AND NEW.role <> 'root' THEN

        RAISE EXCEPTION
        'Root role cannot be modified';

    END IF;

    RETURN NEW;

END;

$$;



CREATE TRIGGER trg_protect_root

BEFORE UPDATE

ON app_user

FOR EACH ROW

EXECUTE FUNCTION protect_root();



-------------------------------------------------------------
-- Prevent Root Deletion
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION prevent_root_delete()

RETURNS TRIGGER

LANGUAGE plpgsql

AS
$$

BEGIN

    IF OLD.role = 'root' THEN

        RAISE EXCEPTION
        'Root user cannot be deleted';

    END IF;

    RETURN OLD;

END;

$$;



CREATE TRIGGER trg_prevent_root_delete

BEFORE DELETE

ON app_user

FOR EACH ROW

EXECUTE FUNCTION prevent_root_delete();



-------------------------------------------------------------
-- Prevent Duplicate Files
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION validate_duplicate_file()

RETURNS TRIGGER

LANGUAGE plpgsql

AS
$$

BEGIN

    IF EXISTS (

        SELECT 1

        FROM file_entry

        WHERE

            directory_id = NEW.directory_id

            AND

            file_name = NEW.file_name

            AND

            extension = NEW.extension

            AND

            fid <> COALESCE(NEW.fid,-1)

            AND

            is_deleted = FALSE

    )

    THEN

        RAISE EXCEPTION
        'File already exists in this directory';

    END IF;

    RETURN NEW;

END;

$$;



CREATE TRIGGER trg_duplicate_file

BEFORE INSERT OR UPDATE

ON file_entry

FOR EACH ROW

EXECUTE FUNCTION validate_duplicate_file();
