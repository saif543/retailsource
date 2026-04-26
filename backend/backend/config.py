import os
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'supplylink'),
}

JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'supplylink_jwt_secret_key_2026')
