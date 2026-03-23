# KeyValue App

A Flutter application for Small Business Advisor proactive engagement management.

## Getting Started

To run the application, navigate to the `app` directory:

```bash
cd app
flutter pub get
flutter run
```

## Running Tests

### Integration Tests

The integration tests verify the end-to-end user flow, including authentication and dashboard access.

To run the integration tests on your machine:

```bash
cd app
flutter test integration_test/auth_flow_test.dart
```

Note: Integration tests require a connected device (emulator, simulator, or physical device).

## Testing with Emulator Backend

To test the web application locally with the Firebase Emulator backend:

1. Start the emulators using the provided script (requires Docker):
   ```bash
   ./scripts/start_emulators.sh
   ```

2. Run the web application with the emulator flag enabled:
   ```bash
   cd app
   flutter run -d chrome --dart-define=USE_EMULATOR=true
   ```

Note: The emulator UI can be accessed at `http://localhost:4000`.
