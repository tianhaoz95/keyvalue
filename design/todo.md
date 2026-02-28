# Tasks

## Branding & Assets
- [x] **Implement App Logo**
    - [x] Use `magick` to crop and resize `branding/logo_raw_design.png`.
        - Suggestion: Create a 512x512 rounded icon for Android/iOS.
        - Suggestion: Create a smaller version (e.g., 120x120) for in-app headers.
    - [x] Place generated assets in `app/assets/images/`.
    - [x] Update `pubspec.yaml` to include new assets.
    - [x] Replace the text-based firm name in `DashboardScreen` and `LoginScreen` with the new logo where appropriate.

## UI Refactoring
- [x] **Move Settings to a Separate Screen**
    - [x] Create `app/lib/screens/settings_screen.dart`.
    - [x] Implement the following features in `SettingsScreen`:
        - Edit CPA Profile (Name, Firm Name).
        - Logout functionality.
        - Delete Account functionality.
    - [x] Replace `PopupMenuButton` in `DashboardScreen` appBar with a single settings icon leading to the new screen.
    - [x] Style the settings screen to match the "Premium Professional" aesthetic (Indigo/Amber).

## Feature Enhancement
- [x] **Manual Check-in Generation**
    - [x] **Logic**: Add a method `generateManualDraft(Customer customer)` to `CpaProvider`.
        - It should call `_aiService.generateDraftMessage(customer)`.
        - Create a new `Engagement` with `status: draft`.
        - Update customer's `hasActiveDraft` to `true`.
    - [x] **UI**: Add a "Generate Check-in" button to the `CustomerDetailScreen` (e.g., in the Profile or History tab).
    - [x] **State Management**: Ensure the button is disabled if `hasActiveDraft` is already true.
    - [x] **Feedback**: Use `LoadingOverlay` with a message like "AI Generating Custom Draft..." while the process is running.
