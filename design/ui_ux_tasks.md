# UI/UX Implementation Tasks

This document contains a breakdown of implementation tasks to enhance the CPA Proactive Engagement App's user experience.

## 1. Dashboard Improvements

- [ ] **Create `PendingReviewList` Widget**
  - Should display a horizontally scrollable list of clients with draft engagements.
  - Each item should show the client name and a "Review" button.
- [ ] **Enhance `DashboardScreen` Layout**
  - Add `PendingReviewList` at the top of the body.
  - Implement a `SearchField` widget that filters the client list in real-time.
  - Update `ListTile` for customers to include a "Health" indicator (e.g., Green/Yellow/Red circle).

## 2. Intelligence Hub (Summary & Update)

- [ ] **Create `IntelligenceHubScreen`**
  - This screen should be triggered after a customer response is received.
  - **Inputs**: Current `Customer` details and `Engagement` with AI-suggested updates.
  - **Layout**: 
    - Header: "Relationship Insights"
    - Section: "Points of Interest" (using `Wrap` and `Chip`).
    - Section: "Proposed Profile Update" (side-by-side or stacked diff).
    - Footer: "Approve Updates" button.
- [ ] **Integrate `IntelligenceHubScreen` with `receiveResponse` flow**
  - Navigate to this screen automatically once Gemini processing is complete.

## 3. Customer Detail & History

- [ ] **Implement Inline Editing for `details` and `guidelines`**
  - Add an "Edit" toggle to `CustomerDetailScreen`.
  - Replace `MarkdownBody` with `TextField` (with markdown preview) when in edit mode.
  - Add a "Save" button that calls `provider.updateCustomer`.
- [ ] **Create `EngagementTimeline` Widget**
  - Use `Timeline` or a custom `CustomPainter` to show a vertical line connecting engagement events.
  - Differentiate between "Outbound" (Sent) and "Inbound" (Received) using side-alignment.

## 4. Visual Identity & Polish

- [ ] **Custom Theme Definition**
  - Create a new `AppTheme` class with a custom `ColorScheme`.
  - Use a professional palette: `Primary: #1A237E (Indigo 900)`, `Secondary: #FFA000 (Amber 700)`.
  - Define custom `TextTheme` with clear hierarchy using "Roboto" or "Open Sans".
- [ ] **Hero Transitions**
  - Add `Hero` widgets to the client avatars in the dashboard and detail screen.
- [ ] **Lottie Animations (Optional but Recommended)**
  - Integrate a subtle Lottie animation for "AI Thinking" states.

## 5. Technical Tasks for UX

- [ ] **Implement `LoadingOverlay`**
  - Create a global loading overlay that can be triggered when long-running AI tasks are in progress.
- [ ] **Add "Undo" Snackbars**
  - For critical actions like "Approve Updates" or "Send Message," provide a temporary "Undo" snackbar for user confidence.
