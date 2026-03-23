# Proactive Engagement App (KeyValue) - Future Features Roadmap

Based on an analysis of the high-level product design (`design.md`) and the current implementation state, the following 10 features have been identified to bridge existing gaps and extend the product's vision. They are ranked from High Impact to Low Impact.

## 1. Twilio SMS Integration (Real Delivery & Webhooks)
**Impact Rating:** High
**Details:** Transition from the current `FakeSmsService` stub to the actual `TwilioSmsService`. This requires implementing HTTP POST requests to the Twilio API for outbound messages. Crucially, it also requires developing a Firebase Cloud Function webhook to receive inbound SMS messages from clients, parse the sender/receiver numbers, and route the text into the correct `Customer`'s `engagements` sub-collection in Firestore.
**Reason:** Fulfills the core value proposition of an "automated, AI-assisted outreach" tool. Without real SMS capabilities, the app remains a simulation rather than a functional communication engine.

## 2. Stripe/RevenueCat Billing Integration & Provisioning
**Impact Rating:** High
**Details:** Wire up the existing mock "Subscription" and "Billing Information" UI in `settings_view.dart` to a live payment gateway (e.g., Stripe). Automate the provisioning of Twilio Virtual Phone Numbers when an advisor upgrades from "Starter" to "Pro" or "Enterprise".
**Reason:** Essential for monetization. The UI currently mocks the subscription states; implementing the backend ensures the business model outlined in the design document can be executed.

## 3. Push Notifications for Inbound Client Responses
**Impact Rating:** High
**Details:** Integrate Firebase Cloud Messaging (FCM) to send real-time push notifications to the advisor's mobile device and web dashboard when a client responds via SMS.
**Reason:** Proactive engagement requires prompt follow-ups. Since the AI autonomously handles initial drafts and categorizes inbound responses, immediately notifying the "human-in-the-loop" to review the Intelligence Hub guarantees timely relationship management and builds trust in the system.

## 4. Admin Dashboard Enhancements (Metrics & System Health)
**Impact Rating:** Medium-High
**Details:** Expand the separate `dash` Flutter web app. Currently, it primarily handles user feedback (`feedback_list_screen.dart`). It needs to be expanded to include global usage metrics, advisor account management, AI token/cost usage tracking, and Twilio error logs.
**Reason:** Explicitly required by `GEMINI.md` for monitoring system health and administrative oversight. A robust admin panel is critical for operating a SaaS platform securely and efficiently.

## 5. Analytics & Insights Dashboard for Advisors
**Impact Rating:** Medium-High
**Details:** Add a new view in the main app showing individual advisor metrics: engagement response rates, total clients contacted per month, AI suggestion approval vs. dismissal rates, and forecasted future engagements.
**Reason:** Advisors need to justify the value of the platform (and their subscription cost). Providing clear visibility into the volume of relationship maintenance the AI has automated solidifies the product's ROI.

## 6. Batch Engagement Review & Approval
**Impact Rating:** Medium
**Details:** Allow advisors to review, edit, and approve multiple "Urgent Reviews" drafts in a bulk, swipeable, or list-based interface, rather than clicking deep into each client's detail view individually.
**Reason:** Improves advisor efficiency significantly as their client roster grows. If an advisor has 50 check-ins due on the 1st of the month, batch processing scales the "App-as-Engine" concept smoothly.

## 7. Automated Contact Syncing (Google/Apple Contacts)
**Impact Rating:** Medium
**Details:** Integrate native device contacts or Google Workspace/Office 365 APIs to allow advisors to mass-import clients into the `Customer` model, automatically extracting names, emails, and phone numbers.
**Reason:** Reduces friction during onboarding. Currently, the onboarding relies on manual entry or the AI Sidebar chat, which can be tedious for importing an existing book of business of 100+ clients.

## 8. Custom Editable Base Guidelines & Firm-Wide Prompt Settings
**Impact Rating:** Medium-Low
**Details:** Provide a UI in the Settings view for advisors to define a global "Base Guideline" (e.g., tone constraints, mandatory compliance disclaimers, signature formatting) that prepends to all Gemini draft generation prompts, across all clients.
**Reason:** While individual client `guidelines` are implemented, firm-level settings provide better macro-control over the AI's output, improving brand consistency, reducing per-message editing time, and ensuring regulatory compliance.

## 9. Full Multimodal AI Input (Voice Notes)
**Impact Rating:** Low
**Details:** Fully activate the "Multimodal AI" toggle in settings by adding voice recording capabilities to the AI Sidebar. Advisors could dictate post-meeting notes ("I just met with John, update his profile to reflect he bought a new house") rather than typing.
**Reason:** A strong "wow" factor that leverages Gemini's multimodal capabilities to reduce advisor friction. However, since the text-based workflow currently exists and works, this is an enhancement rather than a blocker.

## 10. Rich Media Support in Engagements (MMS/PDFs)
**Impact Rating:** Low
**Details:** Support attaching files (PDFs, charts, images) to outgoing messages and handle inbound MMS from Twilio. Ensure the AI can parse and summarize inbound images using Gemini Vision.
**Reason:** Useful for advisors who need to send performance charts or documents. However, it introduces significant complexity around file storage, Twilio MMS pricing, and AI processing limits, making it a lower priority compared to perfecting text-based relationship management.
