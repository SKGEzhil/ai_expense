import os

import dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

dotenv.load_dotenv()

# --- CONFIGURATION ---
DATABASE_URL = os.environ.get("DATABASE_URL")

# --- SETUP DATABASE ---
if DATABASE_URL:
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
else:
    # Handle the case where we are just importing code but not running it
    engine = None
    SessionLocal = None

Base = declarative_base()