# Tasks

- [ ] **Feedback UI Theme Consistency**
  - [ ] Update `app/lib/main.dart` to apply a custom `FeedbackThemeData` to the `BetterFeedback` widget.
  - [ ] Use the app's professional palette (Indigo/Amber/Black) and ensure consistent 16dp rounding.
  - [ ] Verify the feedback UI matches the "Premium Professional" aesthetic defined in `GEMINI.md`.

- [ ] **Custom Web Initial Loading Screen**
  - [ ] Modify `app/web/index.html` to replace the default blue loading bar with a custom centered loader.
  - [ ] Implement a centered logo using `assets/images/logo_512.png`.
  - [ ] Add a circular progress indicator below the logo using CSS or a lightweight SVG.
  - [ ] Ensure the loading UI is removed cleanly once the Flutter engine is initialized via `flutter_bootstrap.js`.

- [ ] **Optimize Review Draft UI**
  - [ ] Modify `app/lib/screens/customer_detail_screen.dart` in the `_buildDraftReviewSidebar` method.
  - [ ] Reduce the `maxLines` of the message draft `TextField` from 15 to 7 or 8 to save vertical space.
  - [ ] Ensure the sidebar still provides enough context for the CPA to review the AI's reasoning.
