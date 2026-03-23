import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import sys
import argparse
import re
import os
from datetime import datetime

def normalize_phone(phone):
    # Strip all non-digit characters
    digits = re.sub(r'\D', '', phone)
    # If it's a 10-digit number, format as XXX-XXX-XXXX to match the app's generation logic
    if len(digits) == 10:
        return f"{digits[0:3]}-{digits[3:6]}-{digits[6:10]}"
    # If it has a leading 1 (US country code) and then 10 digits
    if len(digits) == 11 and digits[0] == '1':
        return f"{digits[1:4]}-{digits[4:7]}-{digits[7:11]}"
    return phone # Fallback to original if it doesn't match expected patterns

def simulate_response(advisor_phone, client_phone, response_text):
    # Normalize inputs to match the XXX-XXX-XXXX format saved in the DB
    advisor_phone = normalize_phone(advisor_phone)
    client_phone = normalize_phone(client_phone)
    
    print(f"Normalized Advisor Phone: {advisor_phone}")
    print(f"Normalized Client Phone: {client_phone}")

    # Initialize Firebase Admin SDK
    # Requires admin-sdk.json in the root directory for production
    try:
        if not firebase_admin._apps:
            if os.environ.get('FIRESTORE_EMULATOR_HOST'):
                # When using emulators, we can initialize with a dummy project ID
                # and no credentials if we want to bypass real Auth.
                print(f"Connecting to Firestore Emulator at {os.environ.get('FIRESTORE_EMULATOR_HOST')}")
                firebase_admin.initialize_app(options={'projectId': 'demo-keyvalue-app'})
            else:
                cred = credentials.Certificate('admin-sdk.json')
                firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Error initializing Firebase Admin: {e}")
        print("Make sure 'admin-sdk.json' exists in the root directory.")
        return

    db = firestore.client()

    # 1. Look up the advisor by their Twilio number (firmPhoneNumber)
    advisors_ref = db.collection('advisors')
    advisor_query = advisors_ref.where('firmPhoneNumber', '==', advisor_phone).limit(1).get()

    if not advisor_query:
        print(f"No advisor found with firm phone number {advisor_phone}")
        return

    advisor_doc = advisor_query[0]
    advisor_uid = advisor_doc.id
    print(f"Found advisor: {advisor_doc.to_dict().get('name')} (UID: {advisor_uid})")

    # 2. Look up the customer by phone number under this advisor
    customers_ref = advisors_ref.document(advisor_uid).collection('customers')
    customer_query = customers_ref.where('phoneNumber', '==', client_phone).limit(1).get()

    if not customer_query:
        print(f"No customer found with phone number {client_phone} for advisor {advisor_uid}")
        return

    customer_doc = customer_query[0]
    customer_id = customer_doc.id
    print(f"Found customer: {customer_doc.to_dict().get('name')} (ID: {customer_id})")

    # 3. Find the engagement with status 'sent' for this customer
    engagements_ref = customers_ref.document(customer_id).collection('engagements')
    
    # Query for the latest sent engagement
    query = engagements_ref.where('status', '==', 'sent').order_by('createdAt', direction=firestore.Query.DESCENDING).limit(1)
    docs = query.get()

    if not docs:
        print(f"No 'sent' engagement found for customer {customer_id}")
        return

    engagement_doc = docs[0]
    engagement_id = engagement_doc.id
    engagement_data = engagement_doc.to_dict()

    print(f"Found engagement: {engagement_id}")
    print(f"Original message: {engagement_data.get('sentMessage')}")
    print(f"Simulating response: {response_text}")

    # 4. Update the engagement status to 'received' and add the response
    engagements_ref.document(engagement_id).update({
        'status': 'received',
        'customerResponse': response_text,
        'receivedAt': firestore.SERVER_TIMESTAMP
    })

    print("Success: Engagement updated to 'received'.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Simulate a client SMS response.')
    parser.add_argument('--to', required=True, help='The Twilio phone number of the advisor (The "To" number)')
    parser.add_argument('--from', dest='client_from', required=True, help='The phone number of the client (The "From" number)')
    parser.add_argument('--msg', required=True, help='The response text from the client')
    parser.add_argument('--emulator', action='store_true', help='Use the local Firebase emulator instead of production')

    args = parser.parse_args()

    if args.emulator:
        os.environ['FIRESTORE_EMULATOR_HOST'] = '127.0.0.1:8080'

    simulate_response(args.to, args.client_from, args.msg)
