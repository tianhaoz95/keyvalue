# Design Document: CPA Proactive Engagement App (Client-Centric)

## 1. Overview
The **CPA Proactive Engagement App** is a tool designed for accountants and CPAs to maintain high-value relationships with their clients through automated, AI-assisted outreach. The system generates personalized check-in messages based on customer profiles and engagement guidelines, allows CPAs to review them, and uses client responses to automatically update records and highlight key interests.

## 2. User Roles
- **CPA/Accountant**: Manages a portfolio of customers, sets engagement guidelines, reviews/sends AI-generated messages, and acts on AI-highlighted points of interest. All proactive and AI tasks are handled by the CPA's local app instance.
- **Customer (End-User)**: Receives engagement messages and provides updates via text or email (simulated in MVP).

## 3. System Architecture
### 3.1 Tech Stack
- **Frontend**: Flutter (Android, iOS, Web, Desktop)
- **Backend**: Firebase Authentication & Cloud Firestore (via Client Library)
- **AI Engine**: Google Gemini API (via Client-side Vertex AI SDK)
- **Scheduling**: Client-side task discovery (checks for due engagements on app launch/resume)

### 3.2 Data Model (Firestore)
The following structures are implemented and managed directly via the `cloud_firestore` client library.

#### `cpas` (Collection)
- `uid`: String (User ID from Firebase Auth)
- `name`: String
- `firmName`: String
- `email`: String

#### `customers` (Sub-collection of `cpas`)
- `customerId`: String
- `name`: String
- `email`: String
- `details`: String (Markdown - Customer background, tax history, etc.)
- `guidelines`: String (Markdown - CPA's specific rules for engaging this client)
- `engagementFrequencyDays`: int (e.g., 30 for monthly)
- `nextEngagementDate`: Timestamp (Used by client to trigger generation)
- `lastEngagementDate`: Timestamp

#### `engagements` (Sub-collection of `customers`)
- `engagementId`: String
- `status`: Enum (Draft, Pending Review, Sent, Received, Completed)
- `draftMessage`: String (AI Generated)
- `sentMessage`: String (Final sent version)
- `customerResponse`: String (Received from client)
- `pointsOfInterest`: List<String> (AI extracted based on guidelines)
- `updatedDetailsDiff`: String (AI suggested changes to customer details)
- `createdAt`: Timestamp

## 4. Core Workflows (Client-Managed)

### 4.1 Proactive Task Discovery (The "App-as-Engine")
1. **Trigger**: When the CPA opens the app or navigates to the dashboard.
2. **Filter**: The app queries `customers` where `nextEngagementDate` <= now and no `Draft` engagement exists.
3. **AI Task (Client-side)**:
   - The app calls Gemini API directly with context (Details + Guidelines).
   - **Instruction**: "Draft a warm, professional check-in message that aligns with the guidelines and references recent details."
4. **Output**: The app writes a new `engagement` record to Firestore with status `Draft`.
5. **UI Update**: The "Pending Reviews" list refreshes to show new drafts.

### 4.2 CPA Review & Send
1. CPA selects a draft in the app.
2. CPA can edit the markdown preview.
3. CPA clicks **Send**.
4. **Action**: The app updates the Firestore record to `Sent` and resets `nextEngagementDate` (Last Engagement + Frequency).

### 4.3 Response Processing & Intelligence
1. **Input**: CPA manually enters a response (MVP) or simulated via API.
2. **AI Analysis (Step 1 - Highlights)**:
   - The app sends the response and guidelines to Gemini.
   - **Result**: App updates `pointsOfInterest` in the engagement record via Firestore client.
3. **AI Analysis (Step 2 - Profile Update)**:
   - The app sends the response and current details to Gemini.
   - **Result**: App updates the `details` field in the `customers` record directly.

## 5. UI/UX Design (Flutter)
### 5.1 Main Dashboard
- **Urgent Actions**: List of clients requiring a new message draft or review.
- **Client List**: Searchable list with "Last Contact" and "Health" status.

### 5.2 Customer Detail View
- **Tab 1: Profile**: Markdown editor for `details`.
- **Tab 2: Guidelines**: Markdown editor for `guidelines`.
- **Tab 3: Engagement Log**: Scrollable history of all AI-generated drafts, sent messages, and responses.

### 5.3 Intelligence Hub
- When a response is received, the app displays a "Summary & Update" screen.
- CPA sees:
  - **Identified Needs**: (AI Points of Interest).
  - **Proposed Profile Update**: A side-by-side diff showing how the client profile will change.

## 6. Implementation Strategy
- **No Backend Logic**: All logic resides in Dart controllers/repositories.
- **Atomic Operations**: Use Firestore Transactions to ensure that when a message is "Sent," the `nextEngagementDate` is updated consistently.
- **Local Persistence**: Rely on Firestore's offline persistence for a seamless CPA experience in low-connectivity environments.
