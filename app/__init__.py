"""
Hostel Management System - Flask Application Factory
"""

from flask import Flask
from flask_login import LoginManager
from .config import Config

login_manager = LoginManager()
login_manager.login_view = 'auth.login'
login_manager.login_message_category = 'info'

def create_app(config_class=Config):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    login_manager.init_app(app)

    # Register blueprints
    from .routes.auth import auth_bp
    from .routes.student import student_bp
    from .routes.warden import warden_bp
    from .routes.admin import admin_bp
    from .routes.api import api_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(student_bp, url_prefix='/student')
    app.register_blueprint(warden_bp, url_prefix='/warden')
    app.register_blueprint(admin_bp, url_prefix='/admin')
    app.register_blueprint(api_bp, url_prefix='/api')

    # User loader for Flask-Login
    from .models.database import get_user_by_id

    @login_manager.user_loader
    def load_user(user_id):
        return get_user_by_id(int(user_id))

    return app