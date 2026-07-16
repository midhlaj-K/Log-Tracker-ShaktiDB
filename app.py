"""
app.py

Main Flask application.
"""

from flask import (
    Flask,
    render_template,
    request,
    redirect,
    url_for,
    session,
    flash
)

from config import Config

from backend import (
    auth,
    file_service,
    admin_service,
    log_service
)

app = Flask(__name__)
app.config.from_object(Config)


# ==========================================================
# Login
# ==========================================================

@app.route("/")
def index():

    if auth.is_logged_in():
        return redirect(url_for("dashboard"))

    return render_template("login.html")


@app.route("/login", methods=["POST"])
def login():

    username = request.form["username"]
    password = request.form["password"]

    if auth.login(username, password):

        flash("Login successful.")

        return redirect(url_for("dashboard"))

    flash("Invalid username or password.")

    return redirect(url_for("index"))


@app.route("/logout")
def logout():

    auth.logout()

    flash("Logged out successfully.")

    return redirect(url_for("index"))


# ==========================================================
# Dashboard
# ==========================================================

@app.route("/dashboard")
def dashboard():

    if not auth.is_logged_in():

        return redirect(url_for("index"))

    stats = admin_service.dashboard_stats()

    activity = log_service.recent_activity()

    return render_template(

        "dashboard.html",

        stats=stats,

        activity=activity

    )


# ==========================================================
# Files
# ==========================================================

@app.route("/files")
def files():

    if not auth.is_logged_in():

        return redirect(url_for("index"))

    files = file_service.list_files(

        session["uid"]

    )

    return render_template(

        "files.html",

        files=files

    )


@app.route("/file/delete/<int:fid>")
def delete_file(fid):

    file_service.delete_file(

        session["uid"],

        fid

    )

    return redirect(url_for("files"))


@app.route("/file/restore/<int:fid>")
def restore_file(fid):

    file_service.restore_file(

        session["uid"],

        fid

    )

    return redirect(url_for("files"))


# ==========================================================
# Users
# ==========================================================

@app.route("/users")
def users():

    if not auth.is_admin():

        return redirect(url_for("dashboard"))

    users = admin_service.list_users(

        session["uid"]

    )

    return render_template(

        "users.html",

        users=users

    )


# ==========================================================
# Logs
# ==========================================================

@app.route("/logs")
def logs():

    if not auth.is_logged_in():

        return redirect(url_for("index"))

    if auth.is_admin():

        logs = log_service.get_logs()

    else:

        logs = log_service.get_user_logs(

            session["uid"]

        )

    return render_template(

        "logs.html",

        logs=logs

    )


# ==========================================================
# Error Pages
# ==========================================================

@app.errorhandler(404)
def not_found(error):

    return "404 - Page Not Found", 404


@app.errorhandler(500)
def server_error(error):

    return "500 - Internal Server Error", 500


# ==========================================================
# Run
# ==========================================================

if __name__ == "__main__":

    app.run(
        debug=True
    )
