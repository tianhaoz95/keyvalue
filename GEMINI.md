# CPA Proactive Engagement App (KeyValue)

A sophisticated Flutter application designed for CPAs to proactively manage client relationships using generative AI (Gemini). The app acts as an "engine" that identifies client needs, suggests engagement drafts, and intelligently updates client profiles based on their responses.

## 🚀 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend:** [Firebase](https://firebase.google.com/) (Authentication, Cloud Firestore)
- **AI Intelligence:** [Google Gemini](https://deepmind.google/technologies/gemini/) (via `firebase_ai`)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Local Storage:** `shared_preferences` (for "Remember Me" functionality)
- **Testing:** `integration_test` with `firebase_auth_mocks` and `fake_cloud_firestore`

## 🏗️ Project Structure

```text
app/
├── integration_test/   # Automated end-to-end and flow tests
├── lib/
│   ├── models/         # Immutable data models (Cpa, Customer, Engagement)
│   ├── providers/      # Business logic and state (CpaProvider)
│   ├── repositories/   # Data access layer for Firestore
│   ├── screens/        # Feature-specific UI screens
│   ├── services/       # External service wrappers (AiService)
│   ├── widgets/        # Reusable UI components (Timeline, Search, etc.)
│   ├── main.dart       # App entry point and theme configuration
│   └── theme.dart      # Custom professional UI theme (Indigo/Amber)
└── pubspec.yaml        # Project dependencies
design/                 # Design system, UX reports, and task tracking
```

## 🔑 Core Features & Design Patterns

### 1. Proactive Discovery ("App-as-Engine")
The app doesn't just wait for user input. It periodically scans for clients due for contact and automatically generates personalized draft messages using Gemini. These appear in the **Urgent Actions** section of the Dashboard.

### 2. Intelligence Hub (Closed-Loop AI)
When a client responds, the `AiService` extracts **Points of Interest** and generates a **Proposed Profile Update**. The **Intelligence Hub** presents a side-by-side diff, requiring CPA approval before updating the client's master record—ensuring AI utility with human oversight.

### 3. Relationship Timeline
Client history is visualized as a vertical timeline, differentiating between outbound messages (Sent), inbound responses (Received), and pending actions (Draft).

### 4. Professional Aesthetic
Designed with a "Premium Professional" feel using a deep Indigo (`#1A237E`) and Amber (`#FFA000`) palette, consistent 16dp rounding, and subtle Material 3 elevation.

### 5. Seamless Onboarding (Demo Mode)
Includes a functional **Demo Mode** that bypasses Firebase Auth, allowing users to explore the full AI-driven workflow using pre-populated `demo_user` data.

## 🛠️ Key Commands & Quality Assurance

All changes within the `./app` directory **must** pass the following validation steps before being considered complete:

- **Run App:** `flutter run`
- **Run Integration Tests:** `cd app && flutter test integration_test/auth_flow_test.dart`
- **Build APK:** `cd app && flutter build apk` (Ensures project integrity and buildability)

## 📝 Design Principles

- **Signal-to-Noise:** Prioritize urgent reviews and recent AI insights over historical data.
- **Trust via Transparency:** Always show the AI's reasoning (Points of Interest) alongside suggested changes.
- **Micro-interactions:** Use Hero transitions and subtle loading overlays (`LoadingOverlay`) to ensure the app feels responsive and "alive" during AI processing.
