import firebase_admin
from firebase_admin import credentials, firestore
import os

def fetch_feedback_tasks():
    # Initialize Firebase
    cred_path = 'admin-sdk.json'
    if not os.path.exists(cred_path):
        print(f"Error: {cred_path} not found.")
        return

    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        return

    db = firestore.client()
    print("Fetching unresolved feedback from Firestore...")

    # Query feedbacks where status is not 'resolved'
    # Note: Firestore does not support 'not equal' well across all fields without indexes, 
    # so we fetch all and filter in Python for simplicity in this script.
    feedbacks_ref = db.collection('feedbacks')
    docs = feedbacks_ref.stream()

    tasks = []
    for doc in docs:
        data = doc.to_dict()
        status = data.get('status', 'open')
        
        if status != 'resolved':
            text = data.get('text', 'No content').replace('\n', ' ')
            tasks.append(f"- [ ] {text}")

    if not tasks:
        print("No unresolved feedback found.")
        return

    # Write to feedback_tasks.md
    output_path = 'feedback_tasks.md'
    with open(output_path, 'w') as f:
        f.write("# Pending Feedback Tasks\n\n")
        f.write("\n".join(tasks))
        f.write("\n")

    print(f"Successfully generated {len(tasks)} tasks in {output_path}")

if __name__ == "__main__":
    fetch_feedback_tasks()
