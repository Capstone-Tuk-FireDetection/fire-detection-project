import os
from io import BytesIO
from typing import Any

import torch
from torchvision import transforms
from PIL import Image

# Path to the model weights
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, 'models', 'model.pth')

_model = None

# Basic image preprocessing. This is intentionally simple since the exact
# model architecture is unknown.
_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
])

def load_model() -> torch.nn.Module:
    """Load the PyTorch model from disk if not already loaded."""
    global _model
    if _model is None:
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(f"Model file not found at {MODEL_PATH}")
        _model = torch.load(MODEL_PATH, map_location=torch.device('cpu'))
        _model.eval()
    return _model


def predict(image_bytes: bytes) -> Any:
    """Run inference on the given image bytes and return the result."""
    model = load_model()
    image = Image.open(BytesIO(image_bytes)).convert('RGB')
    tensor = _transform(image).unsqueeze(0)  # add batch dimension
    with torch.no_grad():
        output = model(tensor)

    if isinstance(output, torch.Tensor):
        return output.squeeze(0).tolist()
    # Fallback for models that return non-Tensor outputs
    try:
        return output.tolist()
    except AttributeError:
        return output
