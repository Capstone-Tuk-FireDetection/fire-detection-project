from flask import Blueprint, jsonify, request

logs_bp = Blueprint('logs', __name__)

# In-memory sample log data used for demonstration purposes
_DEVICE_LOGS = {
    'A': [
        {'date': '2024/12/04', 'time': '15:25', 'temp': '24\u00b0C'},
        {'date': '2025/01/04', 'time': '14:25', 'temp': '23\u00b0C'},
        {'date': '2025/02/03', 'time': '01:21', 'temp': '32\u00b0C'},
    ],
    'B': [
        {'date': '2025/02/03', 'time': '01:21', 'temp': '32\u00b0C'},
    ],
    'C': [],
}


@logs_bp.route('/api/logs', methods=['GET'])
def list_logs():
    """Return logs optionally filtered by device."""
    device = request.args.get('device')
    if device:
        logs = [
            {'device': device, **entry}
            for entry in _DEVICE_LOGS.get(device, [])
        ]
    else:
        logs = [
            {'device': dev, **entry}
            for dev, entries in _DEVICE_LOGS.items()
            for entry in entries
        ]
    return jsonify({'logs': logs})


@logs_bp.route('/api/logs', methods=['DELETE'])
def delete_logs():
    """Delete logs for a device or all logs."""
    device = request.args.get('device')
    if device:
        _DEVICE_LOGS.get(device, []).clear()
    else:
        for entries in _DEVICE_LOGS.values():
            entries.clear()
    return jsonify({'message': 'Logs deleted'})
