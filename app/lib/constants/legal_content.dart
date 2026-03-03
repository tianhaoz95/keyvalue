class LegalContent {
  static const String userAgreement = '''
# KeyValue User Agreement

Effective Date: March 2, 2026

By using the KeyValue application ("the App"), you agree to the following terms and conditions. Please read them carefully.

### 1. PROACTIVE ENGAGEMENT & AI ASSISTANCE
KeyValue is an AI-powered tool designed to assist professional advisors in managing client relationships. The App acts as an intelligence engine, generating suggested outreach and profile updates.

### 2. HUMAN-IN-THE-LOOP REQUIREMENT
**CRITICAL:** You acknowledge and agree that all AI-generated content, including but not limited to message drafts, client insights, and profile updates, MUST be reviewed, edited, and approved by a human advisor before being sent or finalized. KeyValue is not a substitute for professional judgment.

### 3. ACCURACY DISCLAIMER
While KeyValue leverages advanced AI models (Google Gemini), we do not guarantee the accuracy, completeness, or reliability of any AI-generated outputs. AI can occasionally produce "hallucinations" or incorrect information. You are solely responsible for the factual accuracy of all communications sent through the App.

### 4. DATA OWNERSHIP & RESPONSIBILITY
You retain ownership of the client data you input. You are responsible for ensuring you have the legal right and necessary consents to process your clients' data through the App, in compliance with your local laws and professional standards.

### 5. PROPER USE
The "App-as-Engine" features are designed for professional relationship management. You agree not to use the App for spamming, harassment, or any activity that violates professional ethics or legal regulations.

### 6. LIMITATION OF LIABILITY
To the maximum extent permitted by law, KeyValue and its creators shall not be liable for any indirect, incidental, or consequential damages (including loss of data or business) arising from the use of AI-generated suggestions or any technical failures of the App.
''';

  static const String privacyPolicy = '''
# KeyValue Privacy Policy

Effective Date: March 2, 2026

KeyValue respects the privacy of advisors and their clients. This policy explains how we handle your data.

### 1. DATA COLLECTION & STORAGE
- **Advisor Profiles:** We collect your name, firm name, and email to manage your account.
- **Client Data:** We store client names, contact info, background details, and engagement history in Google Cloud Firestore (for registered users) or local Hive storage (for guest users).
- **Security:** We use industry-standard encryption and Firebase Security Rules to ensure that only you can access your clients' data.

### 2. AI PROCESSING (GOOGLE GEMINI)
KeyValue utilizes Google Gemini AI to analyze client responses and generate outreach drafts.
- Data sent to the AI includes client background info and engagement rules.
- This processing is handled securely through the `firebase_ai` infrastructure.
- Data is used solely to provide insights for your account and is not used to train global AI models without explicit enterprise-level agreements.

### 3. SMS INTEGRATION (TWILIO)
If you utilize SMS features, client phone numbers and message content will be processed via Twilio.
- Twilio acts as a sub-processor for the delivery of these messages.
- We do not share your client list with any third parties for marketing purposes.

### 4. DATA RETENTION
You can delete your account and all associated client data at any time through the Settings menu. Upon deletion, data is permanently removed from our active Firestore databases.

### 5. CONFIDENTIALITY STANDARDS
KeyValue is built to support advisors in regulated industries. We maintain strict internal access controls and ensure that client data is never exposed to other users of the App.
''';
}
