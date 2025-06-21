from functools import wraps
from flask import request, jsonify

from .firebase_auth import verify_firebase_token


def firebase_auth_required(func):
    """Decorator to validate Firebase ID token from Authorization header."""

    @wraps(func)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Unauthorized"}), 401
        token = auth_header.split(" ", 1)[1].strip()
        try:
            decoded_token = verify_firebase_token(token)
        except Exception:
            decoded_token = None
        if not decoded_token:
            return jsonify({"error": "Unauthorized"}), 401

        request.user = decoded_token
        return func(*args, **kwargs)

    return wrapper
