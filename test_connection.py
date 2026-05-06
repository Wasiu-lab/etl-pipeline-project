from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os

# Load credentials from .env
load_dotenv()

# Build connection string
engine = create_engine(
    f"mysql+mysqlconnector://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
    f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)

# Test the connection
try:
    with engine.connect() as conn:
        result = conn.execute(text("SELECT DATABASE();"))
        print("✅ Connected to:", result.fetchone()[0])
except Exception as e:
    print("❌ Connection failed:", e)