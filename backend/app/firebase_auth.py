import logging
from .services.firebase_service import verify_id_token


def verify_firebase_token(token: str):
    """Verify Firebase ID token using firebase service."""
    try:
        return verify_id_token(token)
    except Exception as exc:
        logging.exception("Failed to verify Firebase token: %s", exc)
        return None
