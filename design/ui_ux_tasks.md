# UI/UX Implementation Tasks

This document contains a breakdown of implementation tasks to enhance the CPA Proactive Engagement App's user experience.

## 1. Dashboard Improvements

- [x] **Create `PendingReviewList` Widget**
  - Should display a horizontally scrollable list of clients with draft engagements.
  - Each item should show the client name and a "Review" button.
- [x] **Enhance `DashboardScreen` Layout**
  - Add `PendingReviewList` at the top of the body.
  - Implement a `SearchField` widget that filters the client list in real-time.
  - Update `ListTile` for customers to include a "Health" indicator (e.g., Green/Yellow/Red circle).

## 2. Intelligence Hub (Summary & Update)

- [x] **Create `IntelligenceHubScreen`**
  - This screen should be triggered after a customer response is received.
  - **Inputs**: Current `Customer` details and `Engagement` with AI-suggested updates.
  - **Layout**: 
    - Header: "Relationship Insights"
    - Section: "Points of Interest" (using `Wrap` and `Chip`).
    - Section: "Proposed Profile Update" (side-by-side or stacked diff).
    - Footer: "Approve Updates" button.
- [x] **Integrate `IntelligenceHubScreen` with `receiveResponse` flow**
  - Navigate to this screen from the relationship timeline when a response is ready for review.

## 3. Customer Detail & History

- [x] **Implement Inline Editing for `details` and `guidelines`**
  - Add an "Edit" toggle to `CustomerDetailScreen`.
  - Replace `MarkdownBody` with `TextField` (with markdown preview) when in edit mode.
  - Add a "Save" button that calls `provider.updateCustomer`.
- [x] **Create `EngagementTimeline` Widget**
  - Refactored the History tab into a relationship timeline with status icons and clear outbound/inbound visual cues.

## 4. Visual Identity & Polish

- [x] **Custom Theme Definition**
  - Created a new `AppTheme` class with a custom `ColorScheme`.
  - Professional palette: `Primary: #1A237E (Indigo 900)`, `Secondary: #FFA000 (Amber 700)`.
- [x] **Hero Transitions**
  - Added `Hero` widgets to the client avatars in the dashboard and detail screen.
- [x] **Micro-interactions & Aesthetics**
  - Added refined spacing, shadows, and consistent rounded corners (16dp).

## 5. Technical Tasks for UX

- [x] **Implement `LoadingOverlay`**
  - Created a global loading overlay for long-running AI tasks.
- [x] **Add "Undo" Snackbars**
  - Provided temporary "Undo" actions for critical profile updates.
