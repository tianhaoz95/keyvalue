# Web On-Device AI Implementation Study

This report details how the KeyValue application can leverage on-device AI support for web users, mirroring the existing Android implementation.

## Overview

Web On-Device AI allows running Large Language Models (LLMs) directly within the user's browser. By utilizing the built-in capabilities of modern browsers (specifically Chrome's Gemini Nano integration), the application can provide near-instant AI responses without the latency or cost of cloud-based inference.

## Technical Foundation: Chrome Built-in AI

Google is integrating Gemini Nano directly into the Chrome desktop browser. This is accessed via the **Prompt API** (formerly known as the Model Execution API).

### 1. The Engine: Gemini Nano
Gemini Nano is Google's most efficient LLM, designed to run locally on devices with limited memory and compute power. In the browser, it is managed by Chrome's "Optimization Guide" component.

### 2. Browser Requirements
To enable this feature during its preview phase, the following is required:
- **Chrome Version**: 127 or higher (Dev or Canary channels currently).
- **Flags**:
    - `chrome://flags/#prompt-api-for-gemini-nano`: Set to **Enabled**.
    - `chrome://flags/#optimization-guide-on-device-model`: Set to **Enabled Control via Trial**.
- **Component**: `chrome://components` -> **Optimization Guide On Device Model** must be downloaded/updated.

## Implementation Architecture for KeyValue

### 1. Detection and Availability
The application must first check if the `window.ai` API is available and if the model is ready.

```javascript
// Conceptual JS detection
const canCreate = await window.ai.canCreateTextSession();
if (canCreate === "readily") {
  // Local AI is ready
}
```

### 2. Flutter Web Integration
Integration in Flutter is achieved through the `chrome_ai` package or direct JS interop (`dart:js_interop`).

- **Service Layer (`AiService`)**:
  - `prepareWebOnDevice()`: Initializes the browser session.
  - `getAiSource()`: Updated to check for `kIsWeb` and `window.ai` support.
- **Routing Logic**:
  - If Web On-Device is available: Route simple tasks (like outreach drafting) to the local model.
  - Fallback: Transparently route to `firebase_ai` cloud models if the local engine is unavailable or the task is too complex.

## Integration Strategy

### Step 1: Update `AiService`
Update the existing `AiService` to handle the web platform specifically:

```dart
// Conceptual snippet for AiService update
Future<void> prepareWebOnDevice() async {
  if (kIsWeb) {
    // Logic to check window.ai and warm up the session
    // Similar to how prepareOnDevice() works for Android
  }
}
```

### Step 2: Use Cases for Web On-Device
- **Message Drafting**: Instantly generating check-in messages for clients.
- **Sentiment Analysis**: Detecting tone in incoming client responses locally.
- **Data Summarization**: Summarizing long client backgrounds for the advisor dashboard.

## Benefits vs. Cloud AI

| Feature | Cloud AI (Firebase AI) | Web On-Device AI |
| :--- | :--- | :--- |
| **Latency** | ~1-3 seconds (network dependent) | < 100ms (near instant) |
| **Cost** | Token-based (Firebase Quota) | **Free** (Local processing) |
| **Privacy** | Data processed in cloud | Data remains in browser |
| **Availability**| Requires internet connection | Works offline once model is cached |
| **Complexity** | High-reasoning (Gemini 2.5 Flash) | Focused/Simple (Gemini Nano) |

## Current Limitations & Roadmap

- **Status**: Experimental. Chrome's Built-in AI is currently in an Origin Trial phase.
- **Platform Support**: Primarily limited to Desktop (Windows, macOS, Linux). Chrome on Android/iOS does not yet support the Prompt API.
- **Prompt Size**: Gemini Nano has a smaller context window than cloud models, making it unsuitable for massive profile analysis.

## Conclusion

Integrating Web On-Device AI into KeyValue will significantly enhance the "Proactive" nature of the app by providing instant draft suggestions as the advisor browses their client list. It aligns with our goals of privacy-first client management and infrastructure cost reduction.
