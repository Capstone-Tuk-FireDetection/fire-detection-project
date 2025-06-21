from flask import Blueprint, jsonify
from datetime import datetime

status_bp = Blueprint('status', __name__)


@status_bp.route('/api/system-status', methods=['GET'])
def system_status():
    """Return a simple system status payload."""
    devices = [
        {'device_id': 'A', 'status': 'online'},
        {'device_id': 'B', 'status': 'online'},
        {'device_id': 'C', 'status': 'offline'},
    ]
    return jsonify({
        'server': 'online',
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'devices': devices,
    })
