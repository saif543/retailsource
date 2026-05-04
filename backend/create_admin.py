"""
Run once to create the admin user:
  python create_admin.py
"""
import mysql.connector
import bcrypt
from config import DB_CONFIG

ADMIN_EMAIL    = 'ksaif253546@gmail.com'
ADMIN_PASSWORD = '123456'
ADMIN_NAME     = 'Super Admin'
ADMIN_PHONE    = '01733333333'

db = mysql.connector.connect(**DB_CONFIG)
cur = db.cursor()

cur.execute('DELETE FROM users WHERE email = %s', (ADMIN_EMAIL,))
pw_hash = bcrypt.hashpw(ADMIN_PASSWORD.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
cur.execute(
    'INSERT INTO users (name, email, phone, password_hash, role) VALUES (%s, %s, %s, %s, %s)',
    (ADMIN_NAME, ADMIN_EMAIL, ADMIN_PHONE, pw_hash, 'admin')
)
db.commit()
print(f'Admin created: {ADMIN_EMAIL} / {ADMIN_PASSWORD}')

cur.close()
db.close()
