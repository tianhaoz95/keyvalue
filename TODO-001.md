# Tasks

- [x] use firebase cli to fetch firestore config to local and modify it so that it secure where user information can only be access by user logged in with matching uid
    - [x] Run `firebase init firestore` in the `app/` directory.
    - [x] Configure `firestore.rules` to enforce:
        - `allow read, write: if request.auth != null && request.auth.uid == userId;` for user-specific collections.
    - [x] Deploy the updated rules using `firebase deploy --only firestore`.
- [x] for the sign in page, on desktop screen, it should have a margin on left and right to make it not too wide
    - [x] Identify the layout in `lib/screens/login_screen.dart`.
    - [x] Wrap the main column or `SingleChildScrollView` with a `ConstrainedBox` (e.g., `maxWidth: 450`).
    - [x] Ensure it remains centered on the screen.
- [x] add a forget password UI and logic with firebase auth
    - [x] Add a "Forgot Password?" `TextButton` below the password field in `LoginScreen`.
    - [x] Implement a dialog to collect the user's email if it's not already filled.
    - [x] Add a `sendPasswordResetEmail(String email)` method to `CpaProvider` or `CpaRepository`.
    - [x] Show a success/error snackbar after the request is sent.
