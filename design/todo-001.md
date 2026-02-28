# Tasks

- [ ] **Fix Gemini Model Error**
    - *Issue*: Tapping on draft generation fails with a retirement error for Gemini 1.5.
    - *Technical Subtasks*:
        - [ ] Update `AiService._effectiveModel` in `app/lib/services/ai_service.dart` to use `gemini-1.5-flash` (verify if a specific version like `gemini-1.5-flash-latest` or `gemini-2.0-flash` is required by the current `firebase_ai` SDK).
        - [ ] Test draft generation for both "Guest Mode" (should be unaffected as it uses hardcoded strings) and "Firebase Mode".
        - [ ] Update `AiService` error handling to provide more user-friendly messages when AI generation fails.

- [ ] **Add Sorting Options for Clients**
    - *Goal*: Allow CPAs to prioritize clients by name or urgency (next contact date).
    - *Technical Subtasks*:
        - [ ] Define `CustomerSortOption` enum in `app/lib/models/customer.dart`.
        - [ ] Add `_currentSortOption` state to `_DashboardScreenState` in `app/lib/screens/dashboard_screen.dart`.
        - [ ] Implement sorting logic in the `build` method of `DashboardScreen` for `filteredCustomers`.
        - [ ] Add a `PopupMenuButton` in the `DashboardScreen` AppBar or a row of `FilterChip` widgets above the client list to toggle sorting.
        - [ ] Persist sorting preference using `shared_preferences`.

- [ ] **AI-Driven Customer Onboarding (Conversation)**
    - *Goal*: Streamline client setup by talking to an AI agent instead of manual data entry.
    - *Technical Subtasks*:
        - [ ] Create `app/lib/screens/ai_onboarding_screen.dart` with a chat-like interface.
        - [ ] Enhance `AiService` with a new method `processOnboardingConversation(List<ChatMessage> history)` that returns a structured suggestion for a `Customer` profile.
        - [ ] Add a "Discover via AI" button to the `DashboardScreen` (possibly next to the Add FAB).
        - [ ] Implement a flow where the AI asks for: Name, Email, Occupation, and Key Engagement Guidelines.
        - [ ] Integrate with `IntelligenceHubScreen` or a similar side-by-side "Review & Create" UI to confirm the AI-extracted data.

- [ ] **Expand Customer Profile Fields**
    - *Goal*: Capture more professional and contact details.
    - *Technical Subtasks*:
        - [ ] Update `Customer` model in `app/lib/models/customer.dart` to include:
            - `occupation` (String)
            - `phoneNumber` (String)
            - `address` (String)
            - `tags` (List<String>)
        - [ ] Update `Customer.fromMap`, `toMap`, and `copyWith` methods.
        - [ ] Increment Hive `@HiveType` version or handle field migration in `customer.g.dart` (run `dart run build_runner build`).
        - [ ] Update `CustomerDetailScreen` UI to display these new fields in a structured "Contact Info" section.
        - [ ] Add input fields for these new attributes in the `Add Customer` dialog in `DashboardScreen`.
        - [ ] Update `AiService` prompts (draft generation and profile updates) to utilize these new fields for better personalization.
