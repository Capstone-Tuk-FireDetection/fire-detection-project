from flask import Blueprint, jsonify, request
from ..auth import firebase_auth_required
from ..services.firebase_service import (
    get_user_devices,
    add_user_device,
    delete_user_device,
)

device_bp = Blueprint('device', __name__)

@device_bp.route('/api/devices', methods=['GET'])
@firebase_auth_required
def list_devices():
    try:
        uid = request.user['uid']
        devices = get_user_devices(uid)
        return jsonify({'devices': devices})
    except Exception as exc:
        return jsonify({'error': str(exc)}), 500


@device_bp.route('/api/devices', methods=['POST'])
@firebase_auth_required
def add_device():
    data = request.get_json(silent=True) or {}
    device_id = data.get('device_id')
    nickname = data.get('nickname')

    if not device_id or not nickname:
        return jsonify({'error': 'device_id and nickname required'}), 400

    try:
        uid = request.user['uid']
        add_user_device(uid, device_id, nickname)
        return jsonify({'message': 'Device added'}), 201
    except Exception as exc:
        return jsonify({'error': str(exc)}), 500


@device_bp.route('/api/devices/<device_id>', methods=['DELETE'])
@firebase_auth_required
def remove_device(device_id):
    try:
        uid = request.user['uid']
        delete_user_device(uid, device_id)
        return jsonify({'message': 'Device deleted'})
    except Exception as exc:
        return jsonify({'error': str(exc)}), 500
