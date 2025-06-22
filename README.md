# fire-detection-project

A full stack application for early fire detection using computer vision. It consists of a Python Flask backend, a Flutter mobile frontend and firmware for the hardware device.

## Project Overview
- **backend** - Flask API that analyzes images with a PyTorch model and sends notifications through Firebase.
- **frontend** - Flutter app that interacts with the backend and displays alerts.
- **firmware** - Microcontroller code that captures images and uploads them to the backend.

## Model Weights
The backend expects a PyTorch model file at `backend/models/model.pth`. These weights are not tracked in the repository. You can either train your own model using a fire image dataset or download a pre-trained version from the project's release page. After obtaining the file, place it in `backend/models/` before running the backend.

## Environment Variables
Create a `.env` file in the repository root with the location of your Firebase service account JSON file:

```env
GOOGLE_APPLICATION_CREDENTIALS=backend/firebase-adminsdk.json
ESP32_STREAM_URL=http://<esp32-ip>/stream
```

The backend loads this variable at start up.

## Running the Backend
Install the required packages and start the Flask server:

```bash
cd backend
pip install -r requirements.txt
python run.py
```

## Launching the Flutter Frontend
From another terminal run:

```bash
cd frontend
flutter pub get
flutter run
```

### Firebase Authentication

Some API endpoints require a Firebase ID token. The Flutter app now uses
`firebase_auth` to sign in. Make sure to configure Firebase for your project and
replace the placeholder values in `lib/firebase_options.dart` with your actual
settings. After logging in, API requests automatically include the
`Authorization: Bearer <token>` header.

