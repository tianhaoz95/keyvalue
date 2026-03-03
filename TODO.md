# Tasks

- [ ] **Custom Collapsible Schedules Section**
  - [ ] Add `_isSchedulesExpanded` boolean state to `CustomerDetailScreen`.
  - [ ] Replace `ExpansionTile` in `_buildGuidelinesTab` with a custom `Row` header and `Visibility` widget.
  - [ ] Place an `IconButton` with `Icons.expand_more/less` next to the "ADD" button to control expansion.

- [ ] **End Date Toggle in Schedule Sidebar**
  - [ ] Add `_useAddScheduleEndDate` boolean state to `CustomerDetailScreen`.
  - [ ] Update `_buildAddScheduleSidebar` to include a `SwitchListTile` for "Set End Date".
  - [ ] Conditionally display the `CalendarDatePicker` for the end date based on the toggle.
  - [ ] Ensure the end date is passed as `null` if the toggle is off.

- [ ] **Allow Multiple Concurrent Drafts**
  - [ ] Refactor `generateManualDraft` in `AdvisorProvider.dart` to remove the `customer.hasActiveDraft` restriction.
  - [ ] Update `AppBar` actions in `CustomerDetailScreen` to remove the `!currentCustomer.hasActiveDraft` visibility condition.
  - [ ] (Optional) Review `discoverProactiveTasks` to ensure it doesn't create duplicate drafts for the same period if one already exists.

- [ ] **Transparent Sidebar Scrim**
  - [ ] Modify the "Scrim" `Container` color in `CustomerDetailScreen.build`.
  - [ ] Change `Colors.black26` to `Colors.transparent` to prevent background dimming while maintaining click-to-close functionality.
