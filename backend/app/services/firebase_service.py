import os
from firebase_admin import credentials, initialize_app, auth, firestore

firebase_app = None
_db = None


def initialize_firebase():
    """Initialize Firebase app and Firestore client if not already initialized."""
    global firebase_app, _db
    if firebase_app is None:
        cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if not cred_path:
            raise RuntimeError('GOOGLE_APPLICATION_CREDENTIALS not set')
        cred = credentials.Certificate(cred_path)
        firebase_app = initialize_app(cred)
        _db = firestore.client()
    return firebase_app


def verify_id_token(id_token: str):
    """Verify a Firebase ID token and return the decoded data or None."""
    initialize_firebase()
    try:
        return auth.verify_id_token(id_token, app=firebase_app)
    except Exception:
        return None


def get_user_devices(uid: str):
    """Return a list of devices for the given user UID."""
    initialize_firebase()
    docs = (
        _db.collection("users")
        .document(uid)
        .collection("devices")
        .stream()
    )
    return [doc.to_dict() for doc in docs]


def add_user_device(uid: str, device_id: str, nickname: str) -> None:
    """Add a device under the specified user."""
    initialize_firebase()
    doc_ref = (
        _db.collection("users")
        .document(uid)
        .collection("devices")
        .document(device_id)
    )
    doc_ref.set({"device_id": device_id, "nickname": nickname})


def delete_user_device(uid: str, device_id: str) -> None:
    """Delete a user's device by its ID."""
    initialize_firebase()
    doc_ref = (
        _db.collection("users")
        .document(uid)
        .collection("devices")
        .document(device_id)
    )
    doc_ref.delete()
