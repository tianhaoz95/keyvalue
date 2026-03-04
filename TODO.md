# Tasks

- [x] **Admin Authorization & Management**
  - [x] Update `app/firestore.rules`:
    - [x] Add `match /admins/{uid}` rule that denies all public access (Admin SDK only).
    - [x] Update `match /feedbacks/{feedbackId}` to allow `read` and `delete` only if the user is the owner OR if their UID exists in the `/admins/` collection using `exists()`.
  - [x] Create `scripts/manage_admins.py`:
    - [x] Implement `add_admin(email)` to look up UID via Firebase Auth and create a document in the `admins` collection.
    - [x] Implement `remove_admin(email)` to delete the corresponding document from the `admins` collection.
  - [x] Update `GEMINI.md` with a new "Admin Management" section detailing how to run the script using the `admin-sdk.json`.

- [x] **Fix Feedback Deletion in Dash**
  - [x] Add `allow delete` permission to the `feedbacks` collection in `app/firestore.rules`.
  - [x] Verify the fix by deploying rules and testing the "DELETE" button in the Dashboard.

- [x] **Contextual Feedback (Screen Tracking)**
  - [x] Update `submitFeedback` in `app/lib/providers/advisor_provider.dart` to accept a `screenName` parameter.
  - [x] Update all `BetterFeedback` triggers in the following screens to pass the current screen name:
    - [x] `LoginScreen` ("LOGIN")
    - [x] `RegisterScreen` ("REGISTER")
    - [x] `DashboardScreen` ("DASHBOARD")
    - [x] `CustomerDetailScreen` ("CUSTOMER_DETAIL")
  - [x] Update `dash/lib/models/feedback_item.dart` to include the `screenName` field.
  - [x] Update `dash/lib/widgets/feedback_detail_sidebar.dart` to display the source screen in the details view.
