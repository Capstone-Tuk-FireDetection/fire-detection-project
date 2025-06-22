from flask import Blueprint, jsonify, request

from ..services.user_service import add_user, authenticate_user

user_account_bp = Blueprint('user_account', __name__)


@user_account_bp.route('/api/register', methods=['POST'])
def register():
    data = request.get_json(silent=True) or {}
    email = data.get('email')
    password = data.get('password')
    role = data.get('role', '일반')
    if not email or not password:
        return jsonify({'error': 'email and password required'}), 400
    try:
        add_user(email, password, role)
        return jsonify({'message': 'User registered'}), 201
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    except Exception as exc:
        return jsonify({'error': str(exc)}), 500


@user_account_bp.route('/api/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'error': 'email and password required'}), 400
    user = authenticate_user(email, password)
    if not user:
        return jsonify({'error': 'Invalid credentials'}), 401
    return jsonify({'message': 'Login successful', 'role': user['role']})
