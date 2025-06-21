"""Routes for streaming from ESP32-CAM."""

import os
import requests
from flask import Blueprint, jsonify, Response, stream_with_context
from ..auth import firebase_auth_required

stream_bp = Blueprint("stream", __name__)


@stream_bp.route("/api/stream-proxy", methods=["GET"])
@firebase_auth_required
def stream_proxy():
    """Proxy MJPEG stream from ESP32-CAM to the client."""
    stream_url = os.getenv("ESP32_STREAM_URL")
    if not stream_url:
        return jsonify({"error": "ESP32_STREAM_URL not set"}), 500

    try:
        upstream = requests.get(stream_url, stream=True)
        upstream.raise_for_status()
    except Exception as exc:  # requests.RequestException also covers HTTPError
        return jsonify({"error": str(exc)}), 502

    def generate():
        try:
            for chunk in upstream.iter_content(chunk_size=1024):
                if chunk:
                    yield chunk
        finally:
            upstream.close()

    # The ESP32 sometimes omits the boundary parameter. Use a fixed MIME type
    # expected by most MJPEG clients.
    content_type = "multipart/x-mixed-replace; boundary=frame"

    return Response(
        stream_with_context(generate()),
        content_type=content_type,
    )
