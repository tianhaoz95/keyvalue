# On-Device Firebase AI Logic Implementation (Android)

This report details how the KeyValue application implements on-device AI support for Android devices using Firebase AI Logic and Gemini Nano.

## Overview

The application utilizes a **hybrid AI architecture**. While primary inference can happen in the cloud for maximum capability, the app is configured to proactively prepare and use on-device models (Gemini Nano via AICore) to improve latency, reduce costs, and provide offline functionality for core tasks like message drafting.

## Technical Architecture

### 1. Flutter Service Layer (`AiService`)
The `AiService` class in `app/lib/services/ai_service.dart` serves as the primary interface for all AI operations.

- **Initialization**: When `AiService` is instantiated on an Android device, it automatically triggers `prepareOnDevice()`.
- **Method Channel**: Communication with native Android code is handled via a `MethodChannel` named `com.hejitech.keyvalue_app/ai_ondevice`.
- **Status Monitoring**: The service provides `checkOnDeviceStatus()` to allow the UI to display the readiness of the local AI engine.

### 2. Android Native Implementation (`MainActivity.kt`)
The native side handles the heavy lifting of model management using the Firebase AI On-Device SDK.

- **Dependency**: Uses `com.google.firebase:firebase-ai-ondevice`.
- **Model Preparation (`prepareModel`)**:
    - Checks the current status of the on-device model via `FirebaseAIOnDevice.checkStatus()`.
    - If the model is not present (`DOWNLOADABLE` or `NeedsDownload`), it triggers an asynchronous download using `FirebaseAIOnDevice.download()`.
    - Returns `DOWNLOADED` or `AVAILABLE` once ready.
- **Status Reporting (`checkStatus`)**: Directly queries the Firebase SDK to return the current state of the on-device model (e.g., `Ready`, `NeedsDownload`, `UnsupportedDevice`).

### 3. Build Configuration (`app/android/app/build.gradle.kts`)
The following dependencies are required for on-device support:

```kotlin
dependencies {
    // Hybrid On-Device Inference for Firebase AI Logic
    implementation("com.google.firebase:firebase-ai:17.10.0")
    implementation("com.google.firebase:firebase-ai-ondevice:16.0.0-beta01")
}
```

**Requirements**:
- **minSdk**: 26 (Android 8.0+) is required for these libraries, although Gemini Nano specifically requires newer hardware/OS versions (typically Android 14+ on supported devices like Pixel 8 or S24).

## AI Workflow

1.  **App Start**: `AdvisorProvider` initializes `AiService`.
2.  **Proactive Warmup**: `AiService` calls the native `prepareModel` method.
3.  **Background Download**: If the device supports Gemini Nano but doesn't have the model, AICore begins downloading it in the background.
4.  **Inference**:
    - When `generateDraftMessage` or other AI methods are called, the `firebase_ai` Flutter SDK (configured via Gradle) attempts to route the request to the on-device model if it is ready and the prompt is compatible.
    - If the on-device model is unavailable or fails, the SDK transparently falls back to the cloud-hosted Gemini model.
5.  **Offline Fallback**: `AiService` includes explicit `try-catch` logic to provide hardcoded or simplified drafts if both on-device and cloud inference fail (e.g., total offline state without model).

### 5. User Preference Toggle
Users can now manually choose to prioritize the on-device model even when cloud connectivity is available.

- **Location**: Settings Sidebar -> AI Capability section.
- **Availability**: The toggle ("Prefer Local AI") only appears if `checkOnDeviceStatus()` returns an `AVAILABLE` or `Ready` state.
- **Persistence**: The preference is stored in the `Advisor` master record in Firestore (or local Hive in guest mode) via the `preferOnDeviceAi` boolean field.
- **Impact**: When enabled, `AiService.getAiSource()` will return `AiSource.onDevice` as long as the model is available, bypassing the cloud fallback logic for supported tasks.

## Benefits of this Implementation
- **Performance**: Near-instant response times for text generation when running locally.
- **Cost Efficiency**: Zero-cost inference for common tasks, preserving Firebase quota for complex analytical tasks.
- **Privacy**: Local processing of client data for simple drafting.
- **Reliability**: Seamless transition between local and cloud models.
