from flask import Blueprint, request, jsonify
from ..auth import firebase_auth_required
from ..services import ai_model

analyze_bp = Blueprint('analyze', __name__)

@analyze_bp.route('/api/analyze', methods=['POST'])
@firebase_auth_required
def analyze_image():
    """Analyze an uploaded image using the AI model."""
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    image_bytes = request.files['image'].read()
    try:
        result = ai_model.predict(image_bytes)
    except Exception as exc:
        return jsonify({'error': str(exc)}), 500

    return jsonify({'result': result})
