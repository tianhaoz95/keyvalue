# Tasks

- [x] **Feedback UI Theme Consistency**
  - [x] Update `app/lib/main.dart` to apply a custom `FeedbackThemeData` to the `BetterFeedback` widget.
  - [x] Use the app's professional palette (Indigo/Amber/Black) and ensure consistent 16dp rounding.
  - [x] Verify the feedback UI matches the "Premium Professional" aesthetic defined in `GEMINI.md`.

- [x] **Custom Web Initial Loading Screen**
  - [x] Modify `app/web/index.html` to replace the default blue loading bar with a custom centered loader.
  - [x] Implement a centered logo using `assets/images/logo_512.png`.
  - [x] Add a circular progress indicator below the logo using CSS or a lightweight SVG.
  - [x] Ensure the loading UI is removed cleanly once the Flutter engine is initialized via `flutter_bootstrap.js`.

- [x] **Optimize Review Draft UI**
  - [x] Modify `app/lib/screens/customer_detail_screen.dart` in the `_buildDraftReviewSidebar` method.
  - [x] Reduce the `maxLines` of the message draft `TextField` from 15 to 7 or 8 to save vertical space.
  - [x] Ensure the sidebar still provides enough context for the CPA to review the AI's reasoning.
