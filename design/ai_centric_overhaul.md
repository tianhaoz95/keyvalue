# AI-Centric UI/UX Overhaul Plan: "Intelligence-First" Architecture

## 1. Vision & Core Principles
The application is shifting from a traditional "App with AI features" to an "AI-driven engine with a visual interface." 

- **AI as the Primary Actor:** The AI Sidebar becomes the "Intelligence Hub." Users primarily interact through the AI to perform complex tasks.
- **Main Port as Context:** The main viewport (the center of the screen) serves as the "Live State" or "Visual Context" for the AI.
- **Contextual Awareness:** The AI automatically knows what is currently on screen (e.g., "I see you are looking at John Doe's profile").
- **Function Calling / Tool Use:** The AI can autonomously navigate the UI, update records, and generate drafts based on the current context.
- **Responsive Intelligence:** 
  - **Desktop:** AI actions update the Main Port in real-time.
  - **Mobile:** AI actions render embedded, interactive widgets directly within the chat stream.

---

## 2. Phase 1: Foundation & Global State
**Goal:** Establish a unified state that tracks the visual context and facilitates communication between the AI and the UI.

- [ ] **Global UI Context Provider:**
  - Create `lib/providers/ui_context_provider.dart`.
  - Track `currentView` (DASHBOARD, CUSTOMER_DETAIL, SETTINGS).
  - Track `activeCustomerId` (null if on Dashboard).
  - Track `isSidebarExpanded` (Desktop preference).
- [ ] **AI Context Synchronization:**
  - Update `AdvisorProvider` to include the `UiContext` in every AI prompt.
  - Ensure the AI understands its capabilities: "You are the primary interface. Use functions to manipulate the Main Port."

---

## 3. Phase 2: Universal Shell Implementation
**Goal:** Create a single top-level scaffold that houses the AI Sidebar and the Main Port.

- [ ] **The Universal Shell Widget:**
  - Create `lib/widgets/universal_shell.dart`.
  - Implement a `ResponsiveLayout` (Row for Desktop, Stack/Drawer for Mobile).
  - Move the `AppBar` logic here to ensure it is truly universal.
- [ ] **Unified AI Sidebar:**
  - Refactor `lib/widgets/chat_view.dart` to support "Multi-Context Mode."
  - The sidebar should no longer close when navigating; it remains active as the "persistent companion."
- [ ] **Navigation Refactor:**
  - `main.dart` should now point to `UniversalShell`.
  - Use a `Navigator` or a simple `Switch` inside the Main Port to swap between `DashboardView` and `CustomerDetailView`.

---

## 4. Phase 3: AI Tool Calling & Protocol
**Goal:** Enable the AI to "drive" the application via the Gemini API's function calling.

- [ ] **Define AI Toolset:**
  - `navigate_to_client(customerId)`: Changes the Main Port to show a specific client.
  - `list_clients(filter?)`: Navigates to the Dashboard with optional search/filter.
  - `update_client_info(customerId, fields)`: Updates Firestore and refreshes the Main Port.
  - `generate_outreach(customerId)`: Triggers a draft generation for a client.
- [ ] **AI Service Evolution:**
  - Update `lib/services/ai_service.dart` to register these tools with the Gemini model.
  - Implement the "Execution Engine" that maps AI function calls to `AdvisorProvider` methods.

---

## 5. Phase 4: Desktop vs. Mobile Orchestration
**Goal:** Handle the "Visual vs. Embedded" logic.

- [ ] **Desktop Execution:**
  - When the AI calls `navigate_to_client`, the `UniversalShell` updates the Main Port smoothly using a `Hero` transition or a slide animation.
- [ ] **Mobile Embedded Widgets:**
  - Implement "Action Cards" in the chat stream.
  - If the AI updates a client on mobile, instead of just saying "Updated," it renders a compact "Success Card" or an "Edit Form" directly in the chat bubble.
  - Create `lib/widgets/ai/embedded_client_card.dart`.

---

## 6. Phase 5: Feature Migration & Cleanup
**Goal:** Remove legacy sidebars and unify the experience.

- [ ] **Dashboard Migration:**
  - Refactor `DashboardScreen` into `DashboardView` (a stateless/stateful widget without its own scaffold).
  - Remove "Manual Add" sidebar; this is now handled by saying "I want to add a client" to the AI.
- [ ] **Customer Detail Migration:**
  - Refactor `CustomerDetailScreen` into `CustomerDetailView`.
  - Remove individual "AI Refinement" sidebars. The Universal AI Sidebar handles profile updates and draft refinements in-place.
- [ ] **Settings Integration:**
  - Move settings into an "Account" mode within the AI Sidebar or a dedicated "Settings Port."

---

## 7. Quality Assurance & Validation
- [ ] **Context Injection Test:** Verify that the AI correctly identifies the client on screen after a navigation event.
- [ ] **Tool Collision Test:** Ensure that if a user manually navigates, the AI Sidebar context updates immediately.
- [ ] **Mobile Performance:** Test the embedded widget rendering for lag or layout overflows.
- [ ] **Build Validation:** 
  - `flutter build web` (Desktop/Web Mode)
  - `flutter build apk` (Mobile Mode)
