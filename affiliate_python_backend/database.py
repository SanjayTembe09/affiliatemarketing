import mysql.connector.pooling
import os
from dotenv import load_dotenv

load_dotenv()

dbconfig = {
    "host": os.getenv("DB_HOST", "87.106.214.100"),
    "user": os.getenv("DB_USER", "happyuser"),
    "password": os.getenv("DB_PASSWORD", "HappyUser@2025"),
    "database": os.getenv("DB_NAME", "nano_influencer")
}

# Create a connection pool to safely handle concurrent API requests
db_pool = mysql.connector.pooling.MySQLConnectionPool(
    pool_name="mypool",
    pool_size=5,
    pool_reset_session=True,
    **dbconfig
)

def get_db():
    connection = db_pool.get_connection()
    return connection