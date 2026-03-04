# Tasks

- [ ] **Favicon Synchronization**
  - [ ] Copy `app/web/favicon.png` to `dash/web/favicon.png`.
  - [ ] Ensure `dash/web/index.html` correctly references the new favicon.

- [ ] **Remember Me for Dashboard**
  - [ ] Add `shared_preferences: ^2.5.2` to `dash/pubspec.yaml`.
  - [ ] Update `AdminProvider` in `dash/lib/providers/admin_provider.dart` to handle login persistence.
  - [ ] Add a "Remember me" checkbox to `LoginScreen` in `dash/lib/screens/login_screen.dart`.

- [ ] **Search Functionality for Feedback**
  - [ ] Implement a searchable `AppBar` or a dedicated search bar in `dash/lib/screens/feedback_list_screen.dart`.
  - [ ] Add real-time filtering logic to the feedback list based on advisor name or feedback text.

- [ ] **Feedback Status Management**
  - [ ] Update `FeedbackItem` model in `dash/lib/models/feedback_item.dart` to include a `status` field (open, inProgress, resolved, backlog).
  - [ ] Default status to `open` in `app/lib/providers/advisor_provider.dart` during submission.
  - [ ] Add `updateFeedbackStatus(feedbackId, status)` to `AdminProvider`.
  - [ ] Add a status selection dropdown or button group in `dash/lib/widgets/feedback_detail_sidebar.dart`.
  - [ ] Add status badges (colored chips) to the feedback list in `FeedbackListScreen`.
