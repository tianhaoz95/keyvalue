# Tasks

- [x] **Favicon Synchronization**
  - [x] Copy `app/web/favicon.png` to `dash/web/favicon.png`.
  - [x] Ensure `dash/web/index.html` correctly references the new favicon.

- [x] **Remember Me for Dashboard**
  - [x] Add `shared_preferences: ^2.5.2` to `dash/pubspec.yaml`.
  - [x] Update `AdminProvider` in `dash/lib/providers/admin_provider.dart` to handle login persistence.
  - [x] Add a "Remember me" checkbox to `LoginScreen` in `dash/lib/screens/login_screen.dart`.

- [x] **Search Functionality for Feedback**
  - [x] Implement a searchable `AppBar` or a dedicated search bar in `dash/lib/screens/feedback_list_screen.dart`.
  - [x] Add real-time filtering logic to the feedback list based on advisor name or feedback text.

- [x] **Feedback Status Management**
  - [x] Update `FeedbackItem` model in `dash/lib/models/feedback_item.dart` to include a `status` field (open, inProgress, resolved, backlog).
  - [x] Default status to `open` in `app/lib/providers/advisor_provider.dart` during submission.
  - [x] Add `updateFeedbackStatus(feedbackId, status)` to `AdminProvider`.
  - [x] Add a status selection dropdown or button group in `dash/lib/widgets/feedback_detail_sidebar.dart`.
  - [x] Add status badges (colored chips) to the feedback list in `FeedbackListScreen`.
