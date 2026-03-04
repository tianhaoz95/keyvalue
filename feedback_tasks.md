# Pending Feedback Tasks

## 1. Dashboard UI Refinement
- **Goal:** Clean up the Home Screen by removing unnecessary stats and simplifying section headers.
- **Status:** [x]
- **Subtasks:**
  - [x] **L10n Update:** Update `app/lib/l10n/app_en.arb` and `app/lib/l10n/app_zh.arb`.
    - Change `pendingActions` from "URGENT REVIEWS" to "REVIEWS".
    - Clear or remove `portfolioStats` string.
  - [x] **Dashboard Screen:** Modify `app/lib/screens/dashboard_screen.dart`.
    - Remove the `Text` widget displaying `l10n.portfolioStats`.
    - Adjust vertical padding to maintain professional spacing after removal.

## 2. Settings Sidebar Reorganization
- **Goal:** Prioritize financial/subscription information in the settings menu.
- **Status:** [x]
- **Subtasks:**
  - [x] **Reorder ListView:** Modify `_buildSettingsSidebar` in `app/lib/screens/dashboard_screen.dart`.
  - [x] **New Order:** Move `_buildPlanSelector` (Subscription) and `_buildBillingInfoCard` (Billing) blocks to be immediately after the Profile card and before the AI Capability selector.

## 3. In-place AI Insights & Regeneration
- **Goal:** Improve the UX of AI Analysis by keeping the context within the timeline and allowing easy regeneration.
- **Status:** [x]
- **Subtasks:**
  - [x] **State Management:** Add `_expandedInsightEngagementId` state to `EngagementTimeline` (or `CustomerDetailScreen`) to track which engagement is showing insights.
  - [x] **UI Implementation:** Modify `app/lib/widgets/engagement_timeline.dart`.
    - Instead of navigating to the Profile tab, tapping "VIEW AI INSIGHTS" should expand the `_buildAiInsightsSection` directly below the inbound snippet in the timeline.
  - [x] **Dismiss Logic:** When "DISMISS" is tapped, hide the insights section and restore the "VIEW AI INSIGHTS" button.
  - [x] **Regeneration:** Add a "REGENERATE" button to the insights section that triggers a re-analysis of the response.

## 4. Engagement History Management
- **Goal:** Give advisors full control over the engagement history by allowing manual deletions.
- **Status:** [x]
- **Subtasks:**
  - [x] **Delete Action:** Add a delete icon/button (e.g., `Icons.delete_outline`) to each engagement entry in `EngagementTimeline`.
  - [x] **Confirmation Flow:** Implement a standard confirmation dialog ("Are you sure you want to delete this engagement record?").
  - [x] **Backend Integration:** Call `provider.deleteEngagement` to remove the record from Firestore/Local storage and update the `hasActiveDraft` flag if a draft was deleted.
