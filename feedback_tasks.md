# Pending Feedback Tasks

## 🤖 Persistent AI Configuration
- [x] Save AI capability and experiment feature selections in the user profile (Firestore) so that they do not reset on re-open.
    - [x] Update `Advisor` model in `app/lib/models/advisor.dart` to include:
        - `aiCapability` (String, default: 'pro')
        - `isExpressiveAiEnabled` (bool, default: true)
        - `isMultimodalAiEnabled` (bool, default: false)
    - [x] Update `AdvisorProvider` in `app/lib/providers/advisor_provider.dart` to fetch and store these settings from/to the `currentAdvisor` profile.
    - [x] Migrate existing `shared_preferences` logic to Firestore in `AdvisorProvider`.
    - [x] Ensure `AdvisorRepository` and `LocalAdvisorRepository` correctly persist the new fields.

## 📐 UI Polishing: Sidebar Cleanup
- [x] Remove the divider/separator in all sidebars between the title/header and the content body for a cleaner look.
    - [x] **App Sidebars** (`app/lib/screens/dashboard_screen.dart`):
        - [x] Remove `Divider` in `_buildAiOnboardingSidebar`.
        - [x] Remove `Divider` in `_buildManualAddSidebar`.
        - [x] Remove `Divider` in `_buildSettingsSidebar`.
    - [x] **Dash Sidebars**:
        - [x] Remove `Divider` in `dash/lib/widgets/feedback_detail_sidebar.dart`.
        - [x] Remove `Divider` in `dash/lib/screens/feedback_list_screen.dart` (`_buildFilterSidebar`).
    - [x] **Onboarding Sidebar** (`app/lib/screens/register_screen.dart`):
        - [x] Remove `Divider` in the legal sidebar.
