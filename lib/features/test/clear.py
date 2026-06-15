import firebase_admin
from firebase_admin import credentials, db

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://dsx-can-default-rtdb.firebaseio.com'
})

db.reference('/can_messages').delete()
db.reference('/stats').delete()

print("Database cleared!")