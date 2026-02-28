# Design Document: CPA Proactive Engagement App (KeyValue)

## 1. Overview
The **CPA Proactive Engagement App** (KeyValue) is a tool designed for accountants and CPAs to maintain high-value relationships with their clients through automated, AI-assisted outreach. The system generates personalized check-in messages based on customer profiles and engagement guidelines, allows CPAs to review them, and uses client responses to automatically update records and highlight key interests using Google Gemini.

## 2. User Roles
- **CPA/Accountant**: Manages a portfolio of customers, sets engagement guidelines, reviews/sends AI-generated messages, and acts on AI-highlighted points of interest.
- **Customer (End-User)**: Receives engagement messages and provides updates (simulated in MVP by CPA manual entry).

## 3. System Architecture
### 3.1 Tech Stack
- **Frontend**: Flutter (Android, iOS)
- **Backend**: Firebase Authentication & Cloud Firestore
- **AI Intelligence**: Google Gemini 1.5 Flash (via `firebase_ai` package)
- **State Management**: Provider
- **Local Storage**: `shared_preferences` (for "Remember Me" session persistence)

### 3.2 Data Model (Firestore)
Managed via `cloud_firestore` and corresponding Dart models.

#### `cpas` (Collection)
- `uid`: String (Firebase Auth UID)
- `name`: String
- `firmName`: String
- `email`: String

#### `customers` (Sub-collection of `cpas`)
- `customerId`: String
- `name`: String
- `email`: String
- `details`: String (Markdown - Background, tax history, etc.)
- `guidelines`: String (Markdown - CPA's engagement rules)
- `engagementFrequencyDays`: int
- `nextEngagementDate`: Timestamp
- `lastEngagementDate`: Timestamp
- `hasActiveDraft`: bool (Internal flag for UI/discovery optimization)

#### `engagements` (Sub-collection of `customers`)
- `engagementId`: String
- `status`: Enum (draft, pendingReview, sent, received, completed)
- `draftMessage`: String (AI Generated)
- `sentMessage`: String (Final sent version)
- `customerResponse`: String (Received from client)
- `pointsOfInterest`: List<String> (AI extracted highlights)
- `updatedDetailsDiff`: String (AI suggested full profile state for review)
- `createdAt`: Timestamp

## 4. Core Workflows

### 4.1 Proactive Task Discovery ("App-as-Engine")
1. **Trigger**: When the app starts or a customer listener detects changes.
2. **Filter**: The app identifies customers where `nextEngagementDate` <= now and `hasActiveDraft` is false.
3. **AI Task**:
   - Call Gemini 1.5 Flash with `details` and `guidelines`.
   - **Instruction**: "Draft a warm, professional check-in message..."
4. **Output**: Write a new `engagement` record with status `draft`.
5. **UI Update**: The "Urgent Actions" section on the Dashboard refreshes.

### 4.2 CPA Review & Send
1. CPA selects a draft from the Dashboard.
2. CPA can edit the message.
3. CPA clicks **Send**.
4. **Action**: App updates engagement status to `sent` and resets `nextEngagementDate` (Now + Frequency).

### 4.3 Intelligence Hub (Response & Update)
1. **Input**: CPA manually enters client response into the app.
2. **AI Analysis**:
   - **Points of Interest**: Gemini extracts 3 key highlights based on guidelines.
   - **Profile Update**: Gemini generates a new version of the client's `details` markdown based on the response.
3. **Review**: The CPA enters the **Intelligence Hub** to see identified needs and a side-by-side diff of the profile changes.
4. **Approval**: CPA clicks **Approve**, which overwrites the customer's `details` field and marks the engagement `completed`.

## 5. UI/UX Design (Flutter)
### 5.1 Main Dashboard
- **Urgent Actions**: Horizontally scrollable list of pending drafts and received responses requiring review.
- **Client List**: Searchable list with contact history status.

### 5.2 Customer Detail View
- **Timeline**: A vertical visualization of the relationship history (Sent, Received, Draft).
- **Profile & Guidelines**: Direct markdown editing for client context.

### 5.3 Intelligence Hub
- Dedicated screen for processing client responses.
- Displays AI-extracted **Points of Interest**.
- Shows a side-by-side diff comparison between current and proposed client details.

## 6. Implementation Principles
- **Demo Mode**: Full functional workflow available via a `demo_user` bypass that uses mock data and deterministic AI responses.
- **Human-in-the-Loop**: AI never updates master records directly; all suggested drafts and profile changes require CPA approval.
- **Professional Aesthetic**: Custom theme using Indigo/Amber palette with rounded components (16dp) for a "Premium Enterprise" feel.
