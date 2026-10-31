import os
from firebase_admin import credentials, firestore, initialize_app

# 1. Dapatkan direktori folder 'python' saat ini
current_dir = os.path.dirname(os.path.abspath(__file__))

# 2. Naik satu tingkat ke folder utama (Visura), lalu masuk ke folder 'data'
cred_path = os.path.join(current_dir, "..", "data", "serviceAccountKey.json")

if not os.path.exists(cred_path):
  raise FileNotFoundError(
      f"File serviceAccountKey.json tidak ditemukan di: {cred_path}"
  )

cred = credentials.Certificate(cred_path)
firebase_app = initialize_app(cred)

db = firestore.client()