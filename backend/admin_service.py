"""
backend/admin_service.py

Administrative service layer.
"""

from backend.db import execute, execute_one


# ==========================================================
# Create User
# ==========================================================

def create_user(

    created_by,
    username,
    password_hash,
    role,
    group_id

):

    return execute_one(

        """
        SELECT create_user(
            %s,%s,%s,%s,%s
        )
        """,

        (

            created_by,
            username,
            password_hash,
            role,
            group_id

        )

    )


# ==========================================================
# Update User
# ==========================================================

def update_user(

    updated_by,
    uid,
    username,
    group_id

):

    execute(

        """
        SELECT update_user(
            %s,%s,%s,%s
        )
        """,

        (

            updated_by,
            uid,
            username,
            group_id

        )

    )


# ==========================================================
# Change Password
# ==========================================================

def change_password(

    uid,
    password_hash

):

    execute(

        """
        SELECT change_password(
            %s,%s
        )
        """,

        (

            uid,
            password_hash

        )

    )


# ==========================================================
# Remove User
# ==========================================================

def remove_user(

    removed_by,
    uid

):

    execute(

        """
        SELECT remove_user(
            %s,%s
        )
        """,

        (

            removed_by,
            uid

        )

    )


# ==========================================================
# Promote User
# ==========================================================

def promote_admin(

    root_uid,
    uid

):

    execute(

        """
        SELECT promote_admin(
            %s,%s
        )
        """,

        (

            root_uid,
            uid

        )

    )


# ==========================================================
# Demote Admin
# ==========================================================

def demote_admin(

    root_uid,
    uid

):

    execute(

        """
        SELECT demote_admin(
            %s,%s
        )
        """,

        (

            root_uid,
            uid

        )

    )


# ==========================================================
# User Statistics
# ==========================================================

def user_statistics():

    return execute(

        """

        SELECT *

        FROM user_statistics()

        """,

        fetch=True

    )


# ==========================================================
# File Count
# ==========================================================

def file_count_by_user():

    return execute(

        """

        SELECT *

        FROM file_count_by_user()

        """,

        fetch=True

    )


# ==========================================================
# Directory Count
# ==========================================================

def directory_count_by_user():

    return execute(

        """

        SELECT *

        FROM directory_count_by_user()

        """,

        fetch=True

    )


# ==========================================================
# Dashboard
# ==========================================================

def dashboard_stats():

    return execute_one(

        """

        SELECT *

        FROM dashboard_stats()

        """

    )


# ==========================================================
# Most Active Users
# ==========================================================

def most_active_users(

    limit=10

):

    return execute(

        """

        SELECT *

        FROM most_active_users(%s)

        """,

        (limit,),

        fetch=True

    )
