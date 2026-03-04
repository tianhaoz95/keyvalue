# Tasks

- [x] **Feedback-to-Task Automation**
  - [x] Create `scripts/fetch_feedback_tasks.py`:
    - [x] Initialize Firebase Admin SDK using `admin-sdk.json`.
    - [x] Query the `feedbacks` collection for all documents where `status` is not `resolved`.
    - [x] Format output as a Markdown task list.
    - [x] Save output to `feedback_tasks.md` in the root directory.
  - [x] Update `GEMINI.md` with instructions for generating the task list.

- [x] **Advanced Dashboard Filtering**
  - [x] Update `FeedbackListScreen` state in `dash/lib/screens/feedback_list_screen.dart`:
    - [x] Add `Set<String> _selectedStatuses` (default to all).
    - [x] Add `DateTimeRange? _dateRangeFilter`.
    - [x] Add `String _advisorEmailFilter`.
  - [x] Add a "Filter" `IconButton` next to the search bar.
  - [x] Implement a `_buildFilterSidebar` that slides in from the right.
  - [x] Refactor the `StreamBuilder` logic to apply all active filters locally.
  - [x] Ensure the "Transparent Scrim" style is used for the filter sidebar.
