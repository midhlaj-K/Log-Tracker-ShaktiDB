"""
config.py
Application configuration for Log Tracker
"""

import os


class Config:
    """Base configuration."""

    # Flask
    SECRET_KEY = os.getenv("SECRET_KEY", "logtracker_secret_key")

    # PostgreSQL
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5433")
    DB_NAME = os.getenv("DB_NAME", "logtrack")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

    # Session
    SESSION_PERMANENT = False

    # Pagination
    LOGS_PER_PAGE = 25
    FILES_PER_PAGE = 20
    USERS_PER_PAGE = 20

    # Uploads
    MAX_CONTENT_LENGTH = 50 * 1024 * 1024  # 50 MB

    # Development
    DEBUG = True
