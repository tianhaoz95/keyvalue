# Pending Feedback Tasks

## 🤖 Persistent AI Configuration
- [ ] Save AI capability and experiment feature selections in the user profile (Firestore) so that they do not reset on re-open.
    - [ ] Update `Advisor` model in `app/lib/models/advisor.dart` to include:
        - `aiCapability` (String, default: 'pro')
        - `isExpressiveAiEnabled` (bool, default: true)
        - `isMultimodalAiEnabled` (bool, default: false)
    - [ ] Update `AdvisorProvider` in `app/lib/providers/advisor_provider.dart` to fetch and store these settings from/to the `currentAdvisor` profile.
    - [ ] Migrate existing `shared_preferences` logic to Firestore in `AdvisorProvider`.
    - [ ] Ensure `AdvisorRepository` and `LocalAdvisorRepository` correctly persist the new fields.

## 📐 UI Polishing: Sidebar Cleanup
- [ ] Remove the divider/separator in all sidebars between the title/header and the content body for a cleaner look.
    - [ ] **App Sidebars** (`app/lib/screens/dashboard_screen.dart`):
        - [ ] Remove `Divider` in `_buildAiOnboardingSidebar`.
        - [ ] Remove `Divider` in `_buildManualAddSidebar`.
        - [ ] Remove `Divider` in `_buildSettingsSidebar`.
    - [ ] **Dash Sidebars**:
        - [ ] Remove `Divider` in `dash/lib/widgets/feedback_detail_sidebar.dart`.
        - [ ] Remove `Divider` in `dash/lib/screens/feedback_list_screen.dart` (`_buildFilterSidebar`).
    - [ ] **Onboarding Sidebar** (`app/lib/screens/register_screen.dart`):
        - [ ] Remove `Divider` in the legal sidebar.
