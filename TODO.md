# Tasks

- [x] **Feedback Button on Registration**
  - [x] Add an `AppBar` to `app/lib/screens/register_screen.dart`.
  - [x] Integrate `BetterFeedback` button in the `AppBar` actions.

- [x] **Fix Settings Sidebar Toggle Colors**
  - [x] Update `SwitchListTile` widgets in `app/lib/screens/dashboard_screen.dart`.
  - [x] Explicitly set `activeThumbColor`, `activeTrackColor`, `inactiveThumbColor`, and `inactiveTrackColor` to maintain Indigo/Black/Grey consistency.

- [x] **Fix Feedback Collector Input Theme**
  - [x] Update `FeedbackThemeData` in `app/lib/main.dart` with a `colorScheme`.
  - [x] Override `colorScheme` to ensure focused/active underlines are strictly black.

- [x] **Inline Date Picker in Sidebar**
  - [x] Refactor `_buildAddScheduleSidebar` in `app/lib/screens/customer_detail_screen.dart`.
  - [x] Replace pop-up date picker buttons with inline `CalendarDatePicker`.
  - [x] Manage the state for both Start and End date selections within the sidebar.

- [x] **Client Page Header Refinement**
  - [x] Modify `AppBar` actions in `app/lib/screens/customer_detail_screen.dart`.
  - [x] Remove the `hasActiveDraft` check to ensure the "Generate Draft" button is always visible.
  - [x] Swap positions: Move "Generate Draft" to the left of the "Feedback" button.

- [x] **Style Draft Deletion Dialog**
  - [x] Update the `AlertDialog` in `_buildDraftReviewSidebar`.
  - [x] Ensure buttons are in a `Row` and correctly aligned.
  - [x] Align with the app's 16dp rounding and Indigo/Black palette.

- [x] **Collapsible Engagement Schedules**
  - [x] Refactor "ENGAGEMENT SCHEDULES" section in `app/lib/screens/customer_detail_screen.dart`.
  - [x] Wrap the schedules list in an `ExpansionTile` (initially expanded: true).
  - [x] Ensure the "ADD" button remains accessible in the header.
