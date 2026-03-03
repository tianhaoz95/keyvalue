# Tasks

- [x] **Custom Collapsible Schedules Section**
  - [x] Add `_isSchedulesExpanded` boolean state to `CustomerDetailScreen`.
  - [x] Replace `ExpansionTile` in `_buildGuidelinesTab` with a custom `Row` header and `Visibility` widget.
  - [x] Place an `IconButton` with `Icons.expand_more/less` next to the "ADD" button to control expansion.

- [x] **End Date Toggle in Schedule Sidebar**
  - [x] Add `_useAddScheduleEndDate` boolean state to `CustomerDetailScreen`.
  - [x] Update `_buildAddScheduleSidebar` to include a `SwitchListTile` for "Set End Date".
  - [x] Conditionally display the `CalendarDatePicker` for the end date based on the toggle.
  - [x] Ensure the end date is passed as `null` if the toggle is off.

- [x] **Allow Multiple Concurrent Drafts**
  - [x] Refactor `generateManualDraft` in `AdvisorProvider.dart` to remove the `customer.hasActiveDraft` restriction.
  - [x] Update `AppBar` actions in `CustomerDetailScreen` to remove the `!currentCustomer.hasActiveDraft` visibility condition.

- [x] **Transparent Sidebar Scrim**
  - [x] Modify the "Scrim" `Container` color in `CustomerDetailScreen.build`.
  - [x] Change `Colors.black26` to `Colors.transparent` to prevent background dimming while maintaining click-to-close functionality.
