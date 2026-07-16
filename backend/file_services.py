"""
backend/file_service.py

File service layer.
"""

from backend.db import execute, execute_one


# ==========================================================
# Create
# ==========================================================

def create_file(

    created_by,
    owner,
    directory_id,
    file_name,
    extension,
    file_size

):

    return execute_one(

        """
        SELECT create_file(
            %s,%s,%s,%s,%s,%s
        )
        """,

        (

            created_by,
            owner,
            directory_id,
            file_name,
            extension,
            file_size

        )

    )


# ==========================================================
# Rename
# ==========================================================

def rename_file(

    user,
    fid,
    new_name,
    new_extension

):

    execute(

        """
        SELECT rename_file(
            %s,%s,%s,%s
        )
        """,

        (

            user,
            fid,
            new_name,
            new_extension

        )

    )


# ==========================================================
# Update
# ==========================================================

def update_file(

    user,
    fid,
    new_size

):

    execute(

        """
        SELECT update_file(
            %s,%s,%s
        )
        """,

        (

            user,
            fid,
            new_size

        )

    )


# ==========================================================
# Move
# ==========================================================

def move_file(

    user,
    fid,
    new_directory

):

    execute(

        """
        SELECT move_file(
            %s,%s,%s
        )
        """,

        (

            user,
            fid,
            new_directory

        )

    )


# ==========================================================
# Delete
# ==========================================================

def delete_file(

    user,
    fid

):

    execute(

        """
        SELECT delete_file(
            %s,%s
        )
        """,

        (

            user,
            fid

        )

    )


# ==========================================================
# Restore
# ==========================================================

def restore_file(

    user,
    fid

):

    execute(

        """
        SELECT restore_file(
            %s,%s
        )
        """,

        (

            user,
            fid

        )

    )


# ==========================================================
# List Files
# ==========================================================

def list_files(

    user

):

    return execute(

        """

        SELECT *

        FROM list_files(%s)

        """,

        (user,),

        fetch=True

    )


# ==========================================================
# Search
# ==========================================================

def search_files(

    user,

    keyword

):

    return execute(

        """

        SELECT *

        FROM search_files(%s,%s)

        """,

        (

            user,
            keyword

        ),

        fetch=True

    )


# ==========================================================
# Details
# ==========================================================

def get_file_details(

    user,

    fid

):

    return execute_one(

        """

        SELECT *

        FROM get_file_details(%s,%s)

        """,

        (

            user,
            fid

        )

    )
