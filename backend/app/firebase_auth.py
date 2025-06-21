import logging
from .services.firebase_service import verify_id_token, initialize_firebase


def verify_firebase_token(token: str):
    """Verify Firebase ID token using firebase service."""
    try:
        return verify_id_token(token)
    except Exception as exc:
        logging.exception("Failed to verify Firebase token: %s", exc)
        return None


def initialize_firebase_auth() -> None:
    """Initialize Firebase application for authentication."""
    try:
        initialize_firebase()
    except Exception as exc:
        logging.exception("Failed to initialize Firebase: %s", exc)
