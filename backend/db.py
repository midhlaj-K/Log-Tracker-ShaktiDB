"""
backend/auth.py

Authentication service.
"""

from flask import session
from passlib.hash import bcrypt

from backend.db import execute_one, execute


def login(username, password):
    """
    Authenticate a user.

    Returns:
        True if login succeeds.
        False otherwise.
    """

    user = execute_one(

        "SELECT * FROM login_user(%s)",

        (username,)

    )

    if user is None:
        return False

    if not bcrypt.verify(
        password,
        user["password_hash"]
    ):
        return False

    session["uid"] = user["uid"]
    session["username"] = user["username"]
    session["role"] = user["role"]
    session["group_id"] = user["group_id"]

    execute(

        "SELECT log_login(%s)",

        (user["uid"],)

    )

    return True


def logout():
    """
    Logout current user.
    """

    uid = session.get("uid")

    if uid is not None:

        execute(

            "SELECT log_logout(%s)",

            (uid,)

        )

    session.clear()


def current_user():
    """
    Return current logged-in user.
    """

    if "uid" not in session:
        return None

    return {

        "uid": session["uid"],
        "username": session["username"],
        "role": session["role"],
        "group_id": session["group_id"]

    }


def is_logged_in():

    return "uid" in session


def is_root():

    return session.get("role") == "root"


def is_admin():

    return session.get("role") in ("root", "admin")


def is_user():

    return session.get("role") == "user"
