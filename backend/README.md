# Fire Detection Backend

This directory contains the Flask API used by the fire detection system. It receives images, runs the PyTorch model and communicates with Firebase for authentication and notifications.

## Environment Variables
Create a `.env` file in the project root and set the location of your Firebase credentials:

```env
GOOGLE_APPLICATION_CREDENTIALS=backend/firebase-adminsdk.json
```

## Installation
Install Python dependencies with:

```bash
pip install -r requirements.txt
```

## Running the Server
Start the Flask app using:

```bash
python run.py
```

## User Authentication

The backend now provides simple JSON based authentication. Use the following
endpoints to register and log in users:

* `POST /api/register` with JSON `{"email": "user@example.com", "password": "pw", "role": "일반"}`
* `POST /api/login` with JSON `{"email": "user@example.com", "password": "pw"}`

Successful login returns the user's role.

