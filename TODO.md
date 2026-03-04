# Tasks

- [ ] **Feedback-to-Task Automation**
  - [ ] Create `scripts/fetch_feedback_tasks.py`:
    - [ ] Initialize Firebase Admin SDK using `admin-sdk.json`.
    - [ ] Query the `feedbacks` collection for all documents where `status` is not `resolved`.
    - [ ] Format output as a Markdown task list: `- [ ] {advisorName}: {text} (Status: {status}, Screen: {screenName})`.
    - [ ] Save output to `feedback_tasks.md` in the root directory.
  - [ ] Update `GEMINI.md` with instructions for generating the task list.

- [ ] **Advanced Dashboard Filtering**
  - [ ] Update `FeedbackListScreen` state in `dash/lib/screens/feedback_list_screen.dart`:
    - [ ] Add `Set<String> _selectedStatuses` (default to all).
    - [ ] Add `DateTimeRange? _dateRangeFilter`.
    - [ ] Add `String _advisorEmailFilter`.
  - [ ] Add a "Filter" `IconButton` next to the search bar.
  - [ ] Implement a `_buildFilterSidebar` that slides in from the right:
    - [ ] Multi-select chips for Status (Open, In Progress, Resolved, Backlog).
    - [ ] Date Range picker using `showDateRangePicker`.
    - [ ] TextField for Advisor Email.
  - [ ] Refactor the `StreamBuilder` logic to apply all active filters (search + status + date + email) locally to the feedback list.
  - [ ] Ensure the "Transparent Scrim" style from the style guide is used for the filter sidebar.
