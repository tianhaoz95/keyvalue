# Design Document: Proactive Engagement App (KeyValue)

## 1. Overview
The **Proactive Engagement App** (KeyValue) is a tool designed for modern business advisors to maintain high-value relationships with their clients through automated, AI-assisted outreach. The system generates personalized check-in messages based on customer profiles and engagement guidelines, allows advisors to review them, and uses client responses to automatically update records and highlight key interests using Google Gemini.

## 2. User Roles
- **Advisor**: Manages a list of clients, sets engagement guidelines, reviews/sends AI-generated messages, and acts on AI-highlighted points of interest.
- **Customer (End-User)**: Receives engagement messages and provides updates.

## 3. System Architecture
### 3.1 Tech Stack
- **Frontend**: Flutter (Web, Android, iOS)
- **Backend**: Firebase Authentication & Cloud Firestore
- **AI Intelligence**: Google Gemini 1.5 Flash (via `firebase_ai` package)
- **State Management**: Provider
- **Local Storage**: `shared_preferences` (for "Remember Me" session persistence)

### 3.2 Data Model (Firestore)
Managed via `cloud_firestore` and corresponding Dart models.

#### `advisors` (Collection)
- `uid`: String (Firebase Auth UID)
- `name`: String
- `firmName`: String
- `email`: String

#### `customers` (Sub-collection of `advisors`)
- `customerId`: String
- `name`: String
- `email`: String
- `details`: String (Markdown - Background, goals, etc.)
- `guidelines`: String (Markdown - Advisor's engagement rules)
- `engagementFrequencyDays`: int
- `nextEngagementDate`: Timestamp
- `lastEngagementDate`: Timestamp
- `hasActiveDraft`: bool (Internal flag for UI/discovery optimization)

#### `engagements` (Sub-collection of `customers`)
- `engagementId`: String
- `status`: Enum (draft, sent, received, completed)
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
5. **UI Update**: The "Urgent Reviews" section on the Dashboard refreshes.

### 4.2 Advisor Review & Send
1. Advisor selects a draft from the Dashboard.
2. Advisor can edit the message.
3. Advisor clicks **Send**.
4. **Action**: App updates engagement status to `sent` and resets `nextEngagementDate` (Now + Frequency).

### 4.3 Intelligence Hub (Response & Update)
1. **Input**: Advisor manually enters client response into the app (or received via Twilio).
2. **AI Analysis**:
   - **Points of Interest**: Gemini extracts 3 key highlights based on guidelines.
   - **Profile Update**: Gemini generates a new version of the client's `details` markdown based on the response.
3. **Review**: The advisor enters the **Intelligence Hub** to see identified needs and a side-by-side diff of the profile changes.
4. **Approval**: Advisor clicks **Approve**, which overwrites the customer's `details` field and marks the engagement `completed`.

## 5. UI/UX Design (Flutter)
### 5.1 Main Dashboard
- **Urgent Reviews**: Horizontally scrollable list of pending drafts and received responses requiring review.
- **Client List**: Searchable list with contact history status.

### 5.2 Customer Detail View
- **Timeline**: A vertical visualization of the relationship history (Sent, Received, Draft).
- **Profile & Guidelines**: Direct markdown editing for client context.
- **AI Refinement**: Interactive chat to refine message drafts, profiles, or rulesets.

### 5.3 Settings
- **Advisor Profile**: Edit name, firm name, and email.
- **AI Capability**: Toggle between Pro and Fast models.
- **Subscription**: Manage plans (Starter, Pro, Enterprise) and billing info.

## 6. Implementation Principles
- **Demo Mode**: Limited functional workflow available via "Continue as Guest" with AI features disabled to encourage registration.
- **Human-in-the-Loop**: AI never updates master records directly; all suggested drafts and profile changes require advisor approval.
- **Professional Aesthetic**: Custom theme using Indigo/Amber palette with rounded components (16dp) for a "Premium Professional" feel.
