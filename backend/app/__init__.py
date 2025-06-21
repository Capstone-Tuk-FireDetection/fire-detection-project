from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv
import os

from .config import Config
from .firebase_auth import initialize_firebase_auth


def create_app():
    """Application factory for the Flask backend."""
    # Load environment variables from the project root `.env`
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    load_dotenv(os.path.join(base_dir, ".env"))

    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize Firebase authentication module
    initialize_firebase_auth()

    # Register API blueprints
    from .routes.analyze import analyze_bp
    from .routes.device import device_bp
    from .routes.stream import stream_bp
    from .routes.status import status_bp

    app.register_blueprint(analyze_bp)
    app.register_blueprint(device_bp)
    app.register_blueprint(stream_bp)
    app.register_blueprint(status_bp)

    # Enable Cross-Origin Resource Sharing
    CORS(app)

    return app
