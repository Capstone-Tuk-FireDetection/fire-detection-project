import json
import os

# Path to users.json in backend directory
_USERS_FILE = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', 'users.json')
)


def _load_users() -> dict:
    """Load users from the JSON file, creating it with defaults if missing."""
    if not os.path.exists(_USERS_FILE):
        users = {
            'TUK@tukorea.ac.kr': {'pw': '123', 'role': '관리자'},
            'Tino@tukorea.ac.kr': {'pw': '123', 'role': '일반'},
        }
        _save_users(users)
        return users
    with open(_USERS_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def _save_users(users: dict) -> None:
    with open(_USERS_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, ensure_ascii=False, indent=2)


def add_user(email: str, password: str, role: str) -> None:
    users = _load_users()
    if email in users:
        raise ValueError('Email already exists')
    users[email] = {'pw': password, 'role': role}
    _save_users(users)


def authenticate_user(email: str, password: str):
    users = _load_users()
    user = users.get(email)
    if user and user.get('pw') == password:
        return user
    return None
