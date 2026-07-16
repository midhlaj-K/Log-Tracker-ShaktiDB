"""
backend/log_service.py

Audit log service layer.
"""

from backend.db import execute


# ==========================================================
# All Logs
# ==========================================================

def get_logs():

    return execute(

        """

        SELECT *

        FROM get_logs()

        """,

        fetch=True

    )


# ==========================================================
# Logs of One User
# ==========================================================

def get_user_logs(

    uid

):

    return execute(

        """

        SELECT *

        FROM get_user_logs(%s)

        """,

        (uid,),

        fetch=True

    )


# ==========================================================
# Logs by Action
# ==========================================================

def get_logs_by_action(

    action

):

    return execute(

        """

        SELECT *

        FROM get_logs_by_action(%s)

        """,

        (action,),

        fetch=True

    )


# ==========================================================
# Logs Between Dates
# ==========================================================

def get_logs_between_dates(

    start,

    end

):

    return execute(

        """

        SELECT *

        FROM get_logs_between_dates(%s,%s)

        """,

        (

            start,
            end

        ),

        fetch=True

    )


# ==========================================================
# Recent Activity
# ==========================================================

def recent_activity(

    limit=20

):

    return execute(

        """

        SELECT *

        FROM recent_activity(%s)

        """,

        (limit,),

        fetch=True

    )


# ==========================================================
# Deleted Files
# ==========================================================

def deleted_files():

    return execute(

        """

        SELECT *

        FROM deleted_files()

        """,

        fetch=True

    )
