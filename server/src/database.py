import os

import dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

dotenv.load_dotenv()

# --- CONFIGURATION ---
DATABASE_URL = os.environ.get("DATABASE_URL")

# --- SETUP DATABASE ---
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
