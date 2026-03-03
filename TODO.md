# Tasks

- [x] **Modernize Registration Flow**
  - [x] Create `app/lib/screens/register_screen.dart` as a standalone page.
  - [x] Implement side-by-side or sidebar views within the registration page to display full legal documents.
  - [x] Enforce mandatory checkbox validation for "I agree to the User Agreement and Privacy Policy" before enabling the sign-up button.
  - [x] Update `LoginScreen` to navigate to the new registration page.

- [x] **Draft Professional Legal Content**
  - [x] Expand the **User Agreement** to include detailed clauses on:
    - Human-in-the-loop requirement for AI messages.
    - Disclaimer of AI-generated content accuracy.
    - Proper use of the "App-as-Engine" proactive features.
  - [x] Expand the **Privacy Policy** to include:
    - Detailed data handling for Firestore and Hive.
    - Specific mention of Google Gemini AI processing.
    - Twilio SMS integration and phone number data usage.
    - Advisor-client confidentiality standards.

- [x] **Login Screen Enhancements**
  - [x] Add a `Feedback` icon/button to the `LoginScreen` (top right or footer).
  - [x] Ensure guest users and prospective users can send feedback before logging in.

- [x] **Fix Feedback UI Colors**
  - [x] Update `FeedbackThemeData` in `app/lib/main.dart`.
  - [x] Investigate `lightTheme` properties used by `BetterFeedback` to override the purple underline.
  - [x] Ensure all inputs and buttons in the feedback overlay use strictly Black/Grey/White colors.

- [x] **Transition Dialogs to Sidebars**
  - [x] Implement a `_buildAddScheduleSidebar` in `CustomerDetailScreen`.
  - [x] Replace the pop-up schedule dialog with a right-aligned sliding sidebar.
  - [x] Ensure the sidebar provides a consistent user experience with the AI Refinement sidebar.

- [x] **Fix Deletion Confirmation Style**
  - [x] Update the `showDialog` logic in `_buildDraftReviewSidebar`.
  - [x] Style the `AlertDialog` with the app's professional palette:
    - White background, 16dp rounding.
    - Black primary buttons, grey text.
    - Remove any default pink or blue highlights.
