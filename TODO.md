# Tasks

- [ ] **Modernize Registration Flow**
  - [ ] Create `app/lib/screens/register_screen.dart` as a standalone page.
  - [ ] Implement side-by-side or sidebar views within the registration page to display full legal documents.
  - [ ] Enforce mandatory checkbox validation for "I agree to the User Agreement and Privacy Policy" before enabling the sign-up button.
  - [ ] Update `LoginScreen` to navigate to the new registration page.

- [ ] **Draft Professional Legal Content**
  - [ ] Expand the **User Agreement** to include detailed clauses on:
    - Human-in-the-loop requirement for AI messages.
    - Disclaimer of AI-generated content accuracy.
    - Proper use of the "App-as-Engine" proactive features.
  - [ ] Expand the **Privacy Policy** to include:
    - Detailed data handling for Firestore and Hive.
    - Specific mention of Google Gemini AI processing.
    - Twilio SMS integration and phone number data usage.
    - Advisor-client confidentiality standards.

- [ ] **Login Screen Enhancements**
  - [ ] Add a `Feedback` icon/button to the `LoginScreen` (top right or footer).
  - [ ] Ensure guest users and prospective users can send feedback before logging in.

- [ ] **Fix Feedback UI Colors**
  - [ ] Update `FeedbackThemeData` in `app/lib/main.dart`.
  - [ ] Investigate `lightTheme` properties used by `BetterFeedback` to override the purple underline.
  - [ ] Ensure all inputs and buttons in the feedback overlay use strictly Black/Grey/White colors.

- [ ] **Transition Dialogs to Sidebars**
  - [ ] Implement a `_buildAddScheduleSidebar` in `CustomerDetailScreen`.
  - [ ] Replace the pop-up schedule dialog with a right-aligned sliding sidebar.
  - [ ] Ensure the sidebar provides a consistent user experience with the AI Refinement sidebar.

- [ ] **Fix Deletion Confirmation Style**
  - [ ] Update the `showDialog` logic in `_buildDraftReviewSidebar`.
  - [ ] Style the `AlertDialog` with the app's professional palette:
    - White background, 16dp rounding.
    - Black primary buttons, grey text.
    - Remove any default pink or blue highlights.
