# Tasks

- [x] **Feedback UI Theme Consistency**
  - [x] Update `FeedbackThemeData` in `app/lib/main.dart`.
  - [x] Set `activeColor` and `primaryColor` to black to fix purple underlines.
  - [x] Ensure the "Submit" button is styled with the app's black theme.

- [x] **Optimize Desktop Login Layout**
  - [x] Modify `app/lib/screens/login_screen.dart`.
  - [x] Increase `maxWidth` of the central `ConstrainedBox` from 450 to 550.

- [x] **Implement User Agreement & Privacy Notice**
  - [x] Generate professional legal templates for AI-driven advisor tools.
  - [x] Add a required "Terms of Service" checkbox to the registration dialog in `LoginScreen`.
  - [x] Add a "Privacy Notice" link/button at the bottom of the Settings sidebar in `DashboardScreen`.

- [x] **Experimental Feature: Multimodal AI Control**
  - [x] Add `isMultimodalAiEnabled` boolean to `AdvisorProvider` with persistence.
  - [x] Add a toggle in the Settings sidebar in `DashboardScreen`.
  - [x] Update `KeyValueChatView` in `app/lib/widgets/chat_view.dart` to conditionally hide mic/attachment buttons based on this toggle.

- [x] **Advanced Engagement Scheduling**
  - [x] Create `EngagementSchedule` class in `app/lib/models/customer.dart`.
  - [x] Update `Customer` model to hold `List<EngagementSchedule>`.
  - [x] Implement UI in `CustomerDetailScreen` (Guidelines tab) to add/remove multiple schedules.
  - [x] Refactor `calculateNextEngagementDate` to return the earliest valid date from all active schedules.

- [x] **Improve Review Draft Workflow**
  - [x] Convert the "SEND" button in `_buildDraftReviewSidebar` from an `ElevatedButton` to an `IconButton(Icons.send)`.
  - [x] Add a "Delete Draft" button (trash icon) to the review sidebar.
  - [x] Implement `deleteEngagement` in `AdvisorProvider` and repositories.

- [x] **UI Clarity Improvements**
  - [x] Update `_buildCustomerTile` in `DashboardScreen`.
  - [x] Prepend "Next:" or "Next Engagement:" to the date display in the client list.
