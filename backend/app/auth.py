from functools import wraps
from flask import request, jsonify
from .services.firebase_service import verify_id_token


def firebase_auth_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Unauthorized'}), 401
        token = auth_header.split(' ', 1)[1]
        decoded = verify_id_token(token)
        if not decoded:
            return jsonify({'error': 'Invalid token'}), 401
        request.user = decoded
        return func(*args, **kwargs)

    return wrapper
