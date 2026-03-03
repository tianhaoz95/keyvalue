# Tasks

- [ ] **Feedback UI Theme Consistency**
  - [ ] Update `FeedbackThemeData` in `app/lib/main.dart`.
  - [ ] Set `activeColor` and `primaryColor` to black to fix purple underlines.
  - [ ] Ensure the "Submit" button is styled with the app's black theme.

- [ ] **Optimize Desktop Login Layout**
  - [ ] Modify `app/lib/screens/login_screen.dart`.
  - [ ] Increase `maxWidth` of the central `ConstrainedBox` from 450 to 550.

- [ ] **Implement User Agreement & Privacy Notice**
  - [ ] Generate professional legal templates for AI-driven advisor tools.
  - [ ] Add a required "Terms of Service" checkbox to the registration dialog in `LoginScreen`.
  - [ ] Add a "Privacy Notice" link/button at the bottom of the Settings sidebar in `DashboardScreen`.

- [ ] **Experimental Feature: Multimodal AI Control**
  - [ ] Add `isMultimodalAiEnabled` boolean to `AdvisorProvider` with persistence.
  - [ ] Add a toggle in the Settings sidebar in `DashboardScreen`.
  - [ ] Update `KeyValueChatView` in `app/lib/widgets/chat_view.dart` to conditionally hide mic/attachment buttons based on this toggle.

- [ ] **Advanced Engagement Scheduling**
  - [ ] Create `EngagementSchedule` class in `app/lib/models/customer.dart`.
  - [ ] Update `Customer` model to hold `List<EngagementSchedule>`.
  - [ ] Implement UI in `CustomerDetailScreen` (Guidelines tab) to add/remove multiple schedules.
  - [ ] Refactor `calculateNextEngagementDate` to return the earliest valid date from all active schedules.

- [ ] **Improve Review Draft Workflow**
  - [ ] Convert the "SEND" button in `_buildDraftReviewSidebar` from an `ElevatedButton` to an `IconButton(Icons.send)`.
  - [ ] Add a "Delete Draft" button (trash icon) to the review sidebar.
  - [ ] Implement `deleteEngagement` in `AdvisorProvider` and repositories.

- [ ] **UI Clarity Improvements**
  - [ ] Update `_buildCustomerTile` in `DashboardScreen`.
  - [ ] Prepend "Next:" or "Next Engagement:" to the date display in the client list.
