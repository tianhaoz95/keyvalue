# Tasks

- [ ] **Admin Authorization & Management**
  - [ ] Update `app/firestore.rules`:
    - [ ] Add `match /admins/{uid}` rule that denies all public access (Admin SDK only).
    - [ ] Update `match /feedbacks/{feedbackId}` to allow `read` and `delete` only if the user is the owner OR if their UID exists in the `/admins/` collection using `exists()`.
  - [ ] Create `scripts/manage_admins.py`:
    - [ ] Implement `add_admin(email)` to look up UID via Firebase Auth and create a document in the `admins` collection.
    - [ ] Implement `remove_admin(email)` to delete the corresponding document from the `admins` collection.
  - [ ] Update `GEMINI.md` with a new "Admin Management" section detailing how to run the script using the `admin-sdk.json`.

- [ ] **Contextual Feedback (Screen Tracking)**
  - [ ] Update `submitFeedback` in `app/lib/providers/advisor_provider.dart` to accept a `screenName` parameter.
  - [ ] Update all `BetterFeedback` triggers in the following screens to pass the current screen name:
    - [ ] `LoginScreen` ("LOGIN")
    - [ ] `RegisterScreen` ("REGISTER")
    - [ ] `DashboardScreen` ("DASHBOARD")
    - [ ] `CustomerDetailScreen` ("CUSTOMER_DETAIL")
  - [ ] Update `dash/lib/models/feedback_item.dart` to include the `screenName` field.
  - [ ] Update `dash/lib/widgets/feedback_detail_sidebar.dart` to display the source screen in the details view.
