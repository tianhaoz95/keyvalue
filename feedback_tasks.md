# Pending Feedback Tasks

- [x] **Docker Compose Testing Environment**
  - [x] Create `docker-compose.yml` in the root directory.
  - [x] Configure the Firebase Emulator Suite in `firebase.json` (Firestore, Auth).
  - [x] Update `app` and `dash` to conditionally connect to localhost emulators based on an environment flag (`--dart-define=USE_EMULATOR=true`).
  - [x] Add a `scripts/start_emulators.sh` convenience script.

- [x] **AI Response Visualization & Prompt Engineering**
  - [x] Audit `AiService` prompts and tool execution in `GlobalChatProvider`.
  - [x] Fix "I've handled those tasks for you" silence by including specific tool call summaries in the response.
  - [x] Implement `PREVIEW_DATA` logic to show illustrative UI (`EmbeddedClientCard`) when requested by the AI.

- [x] **Dashboard UI: Full-Width Dividers**
  - [x] Identify the feedback list implementation in `dash/lib/screens/feedback_list_screen.dart`.
  - [x] Remove horizontal padding from the `ListView` and apply it to `ListTile` content to achieve edge-to-edge dividers.

- [x] **Offline Firebase AI Support**
  - [x] Implemented a basic `try-catch` fallback in `AiService` to provide meaningful drafts during offline states.
  - [x] Established pattern for future on-device GenAI integration.
