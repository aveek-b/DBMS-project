"""

Application Configuration

"""

import os

from dotenv import load_dotenv

load_dotenv()

class Config:

"""Base configuration class."""

SECRET_KEY = os.environ.get('SECRET_KEY') or
'your-secret-key-here-change-in-production'

# Oracle Database Configuration

ORACLE_USER = os.environ.get('ORACLE_USER', 'hostel_admin')

ORACLE_PASSWORD = os.environ.get('ORACLE_PASSWORD', 'password')

ORACLE_DSN = os.environ.get('ORACLE_DSN', 'localhost:1521/XEPDB1')

# Application Settings

ITEMS_PER_PAGE = 10

MAX_CONTENT_LENGTH = 16 * 1024 * 1024 # 16MB max file upload

# Session Configuration

SESSION_TYPE = 'filesystem'

PERMANENT_SESSION_LIFETIME = 3600 # 1 hour
