# Proactive Engagement App (KeyValue)

A sophisticated Flutter application designed for advisors to proactively manage client relationships using generative AI (Gemini). The app acts as an "engine" that identifies client needs, suggests engagement drafts, and intelligently updates client profiles based on their responses.

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
│   ├── models/         # Immutable data models (Advisor, Customer, Engagement)
│   ├── providers/      # Business logic and state (AdvisorProvider)
│   ├── repositories/   # Data access layer for Firestore
│   ├── screens/        # Feature-specific UI screens
│   ├── services/       # External service wrappers (AiService)
│   ├── widgets/        # Reusable UI components (Timeline, Search, etc.)
│   ├── main.dart       # App entry point and theme configuration
│   └── theme.dart      # Custom professional UI theme (Indigo/Amber)
└── pubspec.yaml        # Project dependencies
dash/                   # Admin Dashboard site for viewing feedback and admin info
widget_catalog/         # Component gallery for developing and testing UI widgets
design/                 # Design system, UX reports, and task tracking
```

## 🔑 Core Features & Design Patterns

### 1. Proactive Discovery ("App-as-Engine")
The app doesn't just wait for user input. It periodically scans for clients due for contact and automatically generates personalized draft messages using Gemini. These appear in the **Urgent Reviews** section of the Dashboard.

### 2. Intelligence Hub (Closed-Loop AI)
When a client responds, the `AiService` extracts **Points of Interest** and generates a **Proposed Profile Update**. The **Intelligence Hub** presents a side-by-side diff, requiring advisor approval before updating the client's master record—ensuring AI utility with human oversight.

### 3. Relationship Timeline
Client history is visualized as a vertical timeline, differentiating between outbound messages (Sent), inbound responses (Received), and pending actions (Draft).

### 4. Admin Dashboard (External)
A dedicated administrative interface (`dash/`) for monitoring system health, reviewing user-submitted feedback, and managing global administrative information.

### 5. Professional Aesthetic
Designed with a "Premium Professional" feel using a deep Indigo (`#1A237E`) and Amber (`#FFA000`) palette, consistent 16dp rounding, and subtle Material 3 elevation.

### 6. Seamless Onboarding (Demo Mode)
Includes a functional **Demo Mode** that bypasses Firebase Auth, allowing users to explore the full AI-driven workflow using pre-populated `demo_user` data.

## 🛠️ Key Commands & Quality Assurance

- **Image Manipulation:** Use the `magick` command-line tool for cropping, resizing, or modifying image assets (e.g., logos).
- **Run App:** `flutter run`
- **Run Integration Tests:**
  1. Check for available devices: `flutter devices`
     - **1st preference:** Physical Android devices.
     - **2nd preference:** Running Android emulator.
  2. If no devices are running, list available emulators:
     `~/Android/Sdk/emulator/emulator -list-avds`
  3. Start an emulator:
     `~/Android/Sdk/emulator/emulator -avd Name_Of_Your_Device`
  4. Run the tests:
     `cd app && flutter test integration_test/auth_flow_test.dart`
- **Build APK:** `cd app && flutter build apk` (Ensures project integrity and buildability)

## 📦 App Distribution

After a feature development in `app/`, `dash/`, or `widget_catalog/`, and once builds and tests pass successfully, the application must be deployed to **Firebase App Distribution**.

### Deployment Steps

0. **Version Bump:** Before building or distributing, increase the version name and build number in the relevant `pubspec.yaml` (e.g., `1.1.2+5` becomes `1.1.3+6`).

1. **Environment Setup:** Load the required App IDs from your environment.
   ```bash
   source .env
   ```
   This ensures `FIREBASE_ANDROID_APP_ID` (for `app/`), `FIREBASE_ANDROID_DASH_ID` (for `dash/`), and `FIREBASE_ANDROID_CATALOG_ID` (for `widget_catalog/`) are set.

2. **Distribute:** Run the following command from the respective project root (`app/`, `dash/`, or `widget_catalog/`):
   ```bash
   # For 'app/'
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app $FIREBASE_ANDROID_APP_ID \
     --release-notes "Detailed description of the current feature or improvement" \
     --groups "dev"

   # For 'dash/'
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app $FIREBASE_ANDROID_DASH_ID \
     --release-notes "Detailed description of the current feature or improvement" \
     --groups "dev"

   # For 'widget_catalog/'
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app $FIREBASE_ANDROID_CATALOG_ID \
     --release-notes "Detailed description of the current feature or improvement" \
     --groups "dev"
   ```

Always replace the release notes with a clear description of the specific feature or improvement being released.

## 📱 SMS Testing & Simulation

The app is currently configured with a `FakeSmsService` to avoid Twilio costs during development.

### 1. Fake Twilio SMS API
Outgoing messages sent via `AdvisorProvider.sendEngagement` will be logged to the console using `developer.log`. You will see `SIMULATED SMS to [phone]: [message]` in your debug console.

### 2. Simulating Inbound Responses
To test the "Intelligence Hub" and profile update flow, use the Python simulation script to mimic a client response being written to Firestore (as a Cloud Function would do). The script identifies the correct record using both the advisor's Twilio number and the client's phone number.

**Usage:**
```bash
# 1. Set an "ADVISOR PHONE NUMBER" in the app's Billing settings (e.g., +15550001111)
# 2. Ensure your client has a phone number set (e.g., +15559998888)
# 3. Run the script:
python3 scripts/simulate_sms_response.py --to <ADVISOR_TWILIO_NUMBER> --from <CLIENT_PHONE_NUMBER> --msg "I'm interested in the new policy!"
```

**Requirements:**
- `admin-sdk.json` in the root directory.
- `firebase-admin` python package.

## 🛡️ Admin Management

Administrators have global access to review and delete user feedback via the Admin Dashboard (`dash/`).

### Manage Admins Script
Use the provided Python script to manage the administrative allowlist in Firestore.

**Requirements:**
- Python 3.x
- `firebase-admin` package (`pip install firebase-admin`)
- `admin-sdk.json` in the root directory

**Commands:**
```bash
# List all administrators
python3 scripts/manage_admins.py list

# Add a new administrator by email
python3 scripts/manage_admins.py add admin@example.com

# Remove an administrator by email
python3 scripts/manage_admins.py remove admin@example.com

# Generate a Markdown task list from unresolved feedback
python3 scripts/fetch_feedback_tasks.py
```

## 🌐 Web Deployment

The application can be deployed to Firebase Hosting for web access. **Do not deploy the application unless the user explicitly requests it.**

### 0. Version Bump
Before building or deploying, increase the version name and build number in the relevant `pubspec.yaml` (e.g., `1.1.2+5` becomes `1.1.3+6`).

### 1. Build for Web
From the `app/` directory, run:
```bash
flutter build web --release
```

### 2. Deploy to Firebase Hosting
The project uses two environments: **Staging** and **Production**. Environment aliases are configured in `app/.firebaserc`.

#### Staging Deployment
Used for testing new features before they go live. Each feature should be deployed to a **Preview Channel** for review.
**URL:** `https://keyvalue-staging.web.app` (Base URL for preview channels)
```bash
# Replace 'feature-name' with a descriptive name for the change
firebase hosting:channel:deploy feature-name --only staging
```

#### Production Deployment
The live environment for advisors.
**URL:** `https://keyvalue-app.web.app`
```bash
firebase deploy --only hosting:production
```
```

The configuration is managed in `app/firebase.json` and `app/.firebaserc`.

## 📝 Design Principles

- **Signal-to-Noise:** Prioritize urgent reviews and recent AI insights over historical data.
- **Trust via Transparency:** Always show the AI's reasoning (Points of Interest) alongside suggested changes.
- **Micro-interactions:** Use Hero transitions and subtle loading overlays (`LoadingOverlay`) to ensure the app feels responsive and "alive" during AI processing.
