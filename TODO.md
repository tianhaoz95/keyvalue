# Tasks

- [x] **AI Chat for Draft Improvement**
  - [x] Add `refineDraft` to `ChatContext` enum in `app/lib/services/chat_provider.dart`.
  - [x] Implement `generateDraftRefinementResponse` in `AiService` to handle conversational draft improvement.
  - [x] Update `_buildDraftReviewSidebar` in `app/lib/screens/customer_detail_screen.dart` to include a `KeyValueChatView`.
  - [x] Add logic to update the `_reviewDraftController` when the AI suggests a new version of the draft.
  - [x] Add a "REFINEMENT" tab or section in the review sidebar to toggle between the raw draft and the chat.

- [x] **Fix Initial Loading Screen Logo**
  - [x] Update `app/web/index.html` to ensure the logo is rendered black on a white background.
  - [x] Use `assets/images/logo_cropped.png` if it matches the home page logo better than `logo_512.png`.
  - [x] Apply CSS to the `#loading` div to ensure it takes up the full viewport with a solid white background.

- [x] **Remove Blue Linear Progress Bar**
  - [x] Investigate if the blue bar is coming from the Flutter engine initialization (Web).
  - [x] Add CSS to `app/web/index.html` to hide any default loading elements that might be injected by the engine.
  - [x] Check `app/lib/widgets/loading_overlay.dart` to ensure it doesn't accidentally use a `LinearProgressIndicator` with a blue theme.

- [x] **Pivot Target Audience to Small Businesses**
  - [x] Update `app/lib/l10n/app_en.arb`:
    - Rename "CPA" to "Business Owner" or "Advisor".
    - Rename "Firm Name" to "Business Name".
    - Update "Portfolio" wording to "Client List" or similar.
  - [x] Update hardcoded strings in `app/lib/main.dart` (app title).
  - [x] Update `AiService` prompts in `app/lib/services/ai_service.dart` to use "Small Business Advisor" instead of "CPA".
  - [x] Update documentation: `GEMINI.md`, `README.md`, and `TODO-next.md`.
  - [x] Refactor internal class names like `CpaProvider` and `Cpa` to `AdvisorProvider` and `Advisor` for better alignment.
