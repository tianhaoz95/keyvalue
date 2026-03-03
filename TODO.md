# Tasks

- [ ] **Feedback Button on Registration**
  - [ ] Add an `AppBar` to `app/lib/screens/register_screen.dart`.
  - [ ] Integrate `BetterFeedback` button in the `AppBar` actions.

- [ ] **Fix Settings Sidebar Toggle Colors**
  - [ ] Update `SwitchListTile` widgets in `app/lib/screens/dashboard_screen.dart`.
  - [ ] Explicitly set `activeColor`, `activeTrackColor`, `inactiveThumbColor`, and `inactiveTrackColor` to maintain Indigo/Black/Grey consistency.

- [ ] **Fix Feedback Collector Input Theme**
  - [ ] Wrap `BetterFeedback` in `app/lib/main.dart` with a `Theme` widget if necessary.
  - [ ] Override `InputDecorationTheme` to ensure focused/active underlines are strictly black.

- [ ] **Inline Date Picker in Sidebar**
  - [ ] Refactor `_buildAddScheduleSidebar` in `app/lib/screens/customer_detail_screen.dart`.
  - [ ] Replace pop-up date picker buttons with inline `CalendarDatePicker` or a compact scrollable picker.
  - [ ] Manage the state for both Start and End date selections within the sidebar.

- [ ] **Client Page Header Refinement**
  - [ ] Modify `AppBar` actions in `app/lib/screens/customer_detail_screen.dart`.
  - [ ] Remove the `hasActiveDraft` check to ensure the "Generate Draft" button is always visible.
  - [ ] Swap positions: Move "Generate Draft" to the left of the "Feedback" button.

- [ ] **Style Draft Deletion Dialog**
  - [ ] Update the `AlertDialog` in `_buildDraftReviewSidebar`.
  - [ ] Ensure buttons are in a `Row` (default `actions` should suffice, but check for overflow or wrapping issues).
  - [ ] Align with the app's 16dp rounding and Indigo/Black palette.

- [ ] **Collapsible Engagement Schedules**
  - [ ] Refactor "ENGAGEMENT SCHEDULES" section in `app/lib/screens/customer_detail_screen.dart`.
  - [ ] Wrap the schedules list in an `ExpansionTile` (initially expanded: true).
  - [ ] Ensure the "ADD" button remains accessible in the header or expanded content.
