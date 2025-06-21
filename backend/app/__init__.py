from flask import Flask
from .config import Config


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    from .routes.analyze import analyze_bp
    from .routes.device import device_bp
    from .routes.stream import stream_bp

    app.register_blueprint(analyze_bp)
    app.register_blueprint(device_bp)
    app.register_blueprint(stream_bp)

    return app
