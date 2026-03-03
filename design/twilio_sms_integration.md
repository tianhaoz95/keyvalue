# Twilio SMS Integration Research Report

## Objective
To integrate Twilio SMS capabilities into the KeyValue app for sending proactive engagement messages and automatically attaching client responses to their respective profiles in Firestore.

## 1. Sending SMS Messages
To send SMS messages securely from the Flutter app:
- **Architecture**: Flutter App -> Firebase Cloud Function -> Twilio REST API.
- **Security**: Never embed Twilio API credentials directly in the Flutter app. Use Cloud Functions to interact with Twilio's API using environment variables for `Account SID` and `Auth Token`.
- **Implementation**:
    1. Create a `sendSms` HTTPS-callable Cloud Function.
    2. Use the `twilio` Node.js library.
    3. The function should record the outbound message in the client's `engagements` subcollection in Firestore with a status of `sent`.

## 2. Receiving and Attaching Responses
To automatically capture client responses:
- **Webhook Setup**: Configure a Twilio Webhook for the dedicated phone number.
- **Webhook Target**: Point the webhook to a public HTTPS Firebase Cloud Function (e.g., `onSmsReceived`).
- **Data Flow**:
    1. Client responds to an SMS.
    2. Twilio sends a POST request to the `onSmsReceived` Cloud Function.
    3. The function parses the `From` (phone number) and `Body` (message text).
    4. **Lookup**: The function queries the `customers` subcollection across all advisors to find the customer associated with the `From` phone number.
    5. **Attachment**: Once the customer is identified, the function:
        - Creates a new `Engagement` document in that customer's `engagements` subcollection.
        - Sets the `status` to `received`.
        - Sets the `customerResponse` field to the message body.
        - (Optional) Triggers the AI logic to extract "Points of Interest" and suggest profile updates.

## 3. Real-time Updates in Flutter
- The app already uses Firestore `snapshots()` to listen for changes in the `engagements` subcollection.
- When the Cloud Function writes the incoming response, the Flutter UI will update automatically, showing the new message in the client's Relationship Timeline.

## 4. Key Components
- **Twilio Phone Number**: Required for sending and receiving SMS.
- **Firebase Cloud Functions**: To bridge Twilio and Firestore securely.
- **Firestore Schema**: Customer documents must include a validated `phoneNumber` field for reliable lookup.

## 5. Next Steps
1. Provision a Twilio account and phone number.
2. Implement the `sendSms` and `onSmsReceived` Cloud Functions.
3. Update the `Customer` model to include a required `phoneNumber` field.
4. Update the `AdvisorProvider` to call the `sendSms` function when an advisor clicks "Send".
