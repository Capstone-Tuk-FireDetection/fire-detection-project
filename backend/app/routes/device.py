from flask import Blueprint, jsonify, request
from ..auth import firebase_auth_required
from ..services.firebase_service import get_user_devices

device_bp = Blueprint('device', __name__)

@device_bp.route('/api/devices', methods=['GET'])
@firebase_auth_required
def list_devices():
    uid = request.user['uid']
    devices = get_user_devices(uid)
    return jsonify({'devices': devices})
