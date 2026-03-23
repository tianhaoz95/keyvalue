import firebase_admin
from firebase_admin import credentials, auth, firestore
import sys
import os

def init_firebase():
    cred_path = 'admin-sdk.json'
    if not os.path.exists(cred_path):
        print(f"Error: {cred_path} not found.")
        sys.exit(1)
    
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    return firestore.client()

def add_admin(email):
    db = init_firebase()
    try:
        user = auth.get_user_by_email(email)
        uid = user.uid
        
        # Add to admins collection
        db.collection('admins').document(uid).set({
            'email': email,
            'addedAt': firestore.SERVER_TIMESTAMP
        })
        print(f"Successfully added {email} (UID: {uid}) as administrator.")
    except auth.UserNotFoundError:
        print(f"Error: User with email {email} not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def remove_admin(email):
    db = init_firebase()
    try:
        user = auth.get_user_by_email(email)
        uid = user.uid
        
        # Remove from admins collection
        db.collection('admins').document(uid).delete()
        print(f"Successfully removed {email} (UID: {uid}) from administrators.")
    except auth.UserNotFoundError:
        print(f"Error: User with email {email} not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def list_admins():
    db = init_firebase()
    admins = db.collection('admins').stream()
    print("Current Administrators:")
    for admin in admins:
        data = admin.to_dict()
        print(f"- {data.get('email')} (UID: {admin.id})")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python manage_admins.py [add|remove|list] [email]")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "list":
        list_admins()
    elif len(sys.argv) < 3:
        print(f"Usage: python manage_admins.py {command} [email]")
        sys.exit(1)
    else:
        email = sys.argv[2]
        if command == "add":
            add_admin(email)
        elif command == "remove":
            remove_admin(email)
        else:
            print(f"Unknown command: {command}")
