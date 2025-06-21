from flask import Blueprint, jsonify
from ..auth import firebase_auth_required

stream_bp = Blueprint('stream', __name__)

@stream_bp.route('/api/stream/<device_id>')
@firebase_auth_required
def stream_device(device_id):
    # Placeholder for streaming functionality
    return jsonify({'device_id': device_id, 'stream_url': f'http://example.com/{device_id}'})
