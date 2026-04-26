import mysql.connector
from config import DB_CONFIG


def get_db():
    """Create and return a database connection."""
    connection = mysql.connector.connect(**DB_CONFIG)
    return connection
