# Tasks

- [x] **Fix Gemini Model Error**
    - *Issue*: Tapping on draft generation fails with a retirement error for Gemini 1.5.
    - *Technical Subtasks*:
        - [x] Update `AiService._effectiveModel` in `app/lib/services/ai_service.dart` to use `gemini-2.0-flash`.
        - [x] Test draft generation for both "Guest Mode" and "Firebase Mode".
        - [x] Update `AiService` error handling to provide more user-friendly messages when AI generation fails.

- [x] **Add Sorting Options for Clients**
    - *Goal*: Allow CPAs to prioritize clients by name or urgency (next contact date).
    - *Technical Subtasks*:
        - [x] Define `CustomerSortOption` enum in `app/lib/models/customer.dart`.
        - [x] Add `_currentSortOption` state to `_DashboardScreenState` in `app/lib/screens/dashboard_screen.dart`.
        - [x] Implement sorting logic in the `build` method of `DashboardScreen` for `filteredCustomers`.
        - [x] Add a `PopupMenuButton` in the `DashboardScreen` AppBar to toggle sorting.
        - [x] Persist sorting preference using `shared_preferences`.

- [x] **AI-Driven Customer Onboarding (Conversation)**
    - *Goal*: Streamline client setup by talking to an AI agent instead of manual data entry.
    - *Technical Subtasks*:
        - [x] Create `app/lib/screens/ai_onboarding_screen.dart` with a chat-like interface.
        - [x] Enhance `AiService` with a new method `processOnboardingConversation(List<ChatMessage> history)` that returns a structured suggestion for a `Customer` profile.
        - [x] Add a "Discover via AI" button to the `DashboardScreen`.
        - [x] Implement a flow where the AI asks for: Name, Email, Occupation, and Key Engagement Guidelines.
        - [x] Integrate with a "Review & Create" dialog to confirm the AI-extracted data.

- [x] **Expand Customer Profile Fields**
    - *Goal*: Capture more professional and contact details.
    - *Technical Subtasks*:
        - [x] Update `Customer` model in `app/lib/models/customer.dart` to include occupation, phoneNumber, and address.
        - [x] Update `Customer.fromMap`, `toMap`, and `copyWith` methods.
        - [x] Regenerate Hive adapters.
        - [x] Update `CustomerDetailScreen` UI to display these new fields.
        - [x] Add input fields for these new attributes in the `Add Customer` dialog.
        - [x] Update `AiService` prompts to utilize these new fields.
