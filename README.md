# KeyValue App

A Flutter application for CPA engagement management.

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
