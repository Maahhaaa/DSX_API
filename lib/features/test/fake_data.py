import firebase_admin
from firebase_admin import credentials, db
import time
import random

# Init Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://dsx-can-default-rtdb.firebaseio.com'  
})

messages_ref = db.reference('/can_messages')
stats_ref    = db.reference('/stats')

LABELS = ['normal', 'normal', 'normal', 'dos', 'spoofing', 'fuzzy']
CAN_IDS = ['0x0', '0x39', '0x95', '0x1A4', '0x1AA', '0x1B0']

msg_count    = 0
dos_count    = 0
normal_count = 0
start_time   = time.time()

print("Pushing fake CAN data to Firebase...")

while True:
    label  = random.choice(LABELS)
    can_id = random.choice(CAN_IDS)

    # push one message
    messages_ref.push({
        'timestamp': time.time(),
        'can_id':    can_id,
        'dlc':       8,
        'byte1':     random.randint(0, 255),
        'byte2':     random.randint(0, 255),
        'byte3':     random.randint(0, 255),
        'byte4':     random.randint(0, 255),
        'byte5':     random.randint(0, 255),
        'byte6':     random.randint(0, 255),
        'byte7':     random.randint(0, 255),
        'byte8':     random.randint(0, 255),
        'time_diff': round(random.uniform(0.00001, 0.001), 6),
        'label':     label,
        'processed': True,
    })

    # update stats
    msg_count += 1
    elapsed    = time.time() - start_time
    frequency  = round(msg_count / elapsed, 2)

    if label != 'normal':
        dos_count += 1
    else:
        normal_count += 1

    stats_ref.set({
        'total_messages':    msg_count,
        'message_frequency': frequency,
        'dos_count':         dos_count,
        'normal_count':      normal_count,
        'last_alert':        label if label != 'normal' else None,
        'last_updated':      time.time(),
    })

    print(f"[{msg_count}] can_id={can_id} label={label} freq={frequency}Hz")

    time.sleep(0.5)  # push every 0.5s — change to 0.1 for faster