# Implementation Tasks: CPA Proactive Engagement App

This document outlines the features and improvements needed to bring the current implementation in line with the [Design Document](./design.md).

## 1. Dashboard Enhancements
- [ ] **Urgent Actions Section**: Add a "Pending Reviews" section at the top of the `DashboardScreen` that lists customers with engagements in `Draft` status.
- [ ] **Search Functionality**: Implement a search bar to filter the "Your Clients" list.
- [ ] **Client Health Status**: Add a visual indicator for client "Health" (e.g., green/yellow/red based on `lastEngagementDate` and `engagementFrequencyDays`).
- [ ] **Discovery Indicator**: Add a subtle UI element (e.g., a small spinner or "AI Thinking..." toast) when `_discoverProactiveTasks` is running.

## 2. Customer Detail & Editing
- [ ] **Markdown Editors**: Replace the static `MarkdownBody` in the "Profile" and "Guidelines" tabs with an editable text field that supports markdown (or a "View/Edit" toggle).
- [ ] **Engagement Log Detail**: Enhance the "History" tab to show more detail for each engagement, including the extracted `pointsOfInterest` and `updatedDetailsDiff`.

## 3. Intelligence Hub (Response Review)
- [ ] **Review Screen (Side-by-Side Diff)**: Instead of automatically updating the customer profile in `receiveResponse`, navigate to a new "Intelligence Hub" screen.
- [ ] **AI Highlights**: Display the "Identified Needs" (Points of Interest) extracted by Gemini.
- [ ] **Profile Update Approval**: Show a side-by-side diff of the current profile vs. the AI-proposed profile and require CPA approval before updating the `customers` record.

## 4. Onboarding & Demo
- [ ] **Functional Demo Mode**: Implement the `_enterDemoMode` method in `LoginScreen` to allow users to bypass Firebase Auth and explore the app using the `demo_user` logic in repositories.

## 5. UI/UX Polishing
- [ ] **Consistent Styling**: Ensure all cards and lists follow the design aesthetic (rounded corners, subtle shadows, consistent padding).
- [ ] **Interactive Feedback**: Add loading states for all AI operations (generating drafts, processing responses).
- [ ] **Navigation Improvements**: Ensure smooth transitions between the Dashboard, Detail View, and Intelligence Hub.
