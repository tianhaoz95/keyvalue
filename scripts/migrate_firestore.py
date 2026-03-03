import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os

def migrate_data():
    # Use service account key file
    cred_path = 'admin-sdk.json'
    if not os.path.exists(cred_path):
        print(f"Error: {cred_path} not found in the current directory.")
        return

    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Error initializing Firebase with {cred_path}: {e}")
        return

    db = firestore.client()

    print(f"Starting migration from 'cpas' to 'advisors' using {cred_path}...")

    # 1. Get all CPAs
    cpas_ref = db.collection('cpas')
    cpas = list(cpas_ref.stream())

    if not cpas:
        print("No data found in 'cpas' collection.")
        return

    count = 0
    for cpa_doc in cpas:
        cpa_id = cpa_doc.id
        cpa_data = cpa_doc.to_dict()
        
        print(f"Migrating Advisor: {cpa_id} ({cpa_data.get('name', 'N/A')})")

        # 2. Copy CPA to Advisor
        db.collection('advisors').document(cpa_id).set(cpa_data)

        # 3. Migrate Customers subcollection
        customers_ref = cpas_ref.document(cpa_id).collection('customers')
        customers = list(customers_ref.stream())

        for customer_doc in customers:
            customer_id = customer_doc.id
            customer_data = customer_doc.to_dict()
            
            # Copy Customer to new path
            new_customer_ref = db.collection('advisors').document(cpa_id).collection('customers').document(customer_id)
            new_customer_ref.set(customer_data)

            # 4. Migrate Engagements subcollection
            engagements_ref = customers_ref.document(customer_id).collection('engagements')
            engagements = list(engagements_ref.stream())

            for eng_doc in engagements:
                eng_id = eng_doc.id
                eng_data = eng_doc.to_dict()
                
                # Copy Engagement to new path
                new_eng_ref = new_customer_ref.collection('engagements').document(eng_id)
                new_eng_ref.set(eng_data)

        count += 1

    print(f"Migration complete. Total advisors migrated: {count}")
    print("Note: Old 'cpas' collection was NOT deleted. Please verify data before manual deletion.")

if __name__ == "__main__":
    migrate_data()
