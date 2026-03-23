#!/bin/bash

# Ensure we are in the root directory
cd "$(dirname "$0")/.."

echo "Starting Firebase Emulators via Docker Compose..."
docker compose up -d

echo "Emulators are starting. You can access the UI at http://localhost:4000"
echo "To run the app with emulators, use: flutter run --dart-define=USE_EMULATOR=true"
