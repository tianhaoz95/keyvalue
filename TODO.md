# Tasks

- [ ] **AI Chat for Draft Improvement**
  - [ ] Add `refineDraft` to `ChatContext` enum in `app/lib/services/chat_provider.dart`.
  - [ ] Implement `generateDraftRefinementResponse` in `AiService` to handle conversational draft improvement.
  - [ ] Update `_buildDraftReviewSidebar` in `app/lib/screens/customer_detail_screen.dart` to include a `KeyValueChatView`.
  - [ ] Add logic to update the `_reviewDraftController` when the AI suggests a new version of the draft.
  - [ ] Add a "REFINEMENT" tab or section in the review sidebar to toggle between the raw draft and the chat.

- [ ] **Fix Initial Loading Screen Logo**
  - [ ] Update `app/web/index.html` to ensure the logo is rendered black on a white background.
  - [ ] Use `assets/images/logo_cropped.png` if it matches the home page logo better than `logo_512.png`.
  - [ ] Apply CSS to the `#loading` div to ensure it takes up the full viewport with a solid white background.

- [ ] **Remove Blue Linear Progress Bar**
  - [ ] Investigate if the blue bar is coming from the Flutter engine initialization (Web).
  - [ ] Add CSS to `app/web/index.html` to hide any default loading elements that might be injected by the engine.
  - [ ] Check `app/lib/widgets/loading_overlay.dart` to ensure it doesn't accidentally use a `LinearProgressIndicator` with a blue theme.

- [ ] **Pivot Target Audience to Small Businesses**
  - [ ] Update `app/lib/l10n/app_en.arb`:
    - Rename "CPA" to "Business Owner" or "Advisor".
    - Rename "Firm Name" to "Business Name".
    - Update "Portfolio" wording to "Client List" or similar.
  - [ ] Update hardcoded strings in `app/lib/main.dart` (app title).
  - [ ] Update `AiService` prompts in `app/lib/services/ai_service.dart` to use "Small Business Advisor" instead of "CPA".
  - [ ] Update documentation: `GEMINI.md`, `README.md`, and `TODO-next.md`.
  - [ ] Refactor internal class names like `CpaProvider` and `Cpa` to `AdvisorProvider` and `Advisor` for better alignment (if requested).
