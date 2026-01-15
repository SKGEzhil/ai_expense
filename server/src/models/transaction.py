from sqlalchemy import Column, Integer, String, Float, Date, Text
from pgvector.sqlalchemy import Vector

from src.database import Base

class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, primary_key=True, index=True)
    txn_type = Column(String, nullable=False) # DEBIT or CREDIT
    amount = Column(Float, nullable=False)

    payee = Column(String)

    category = Column(String)
    transaction_date = Column(Date)

    transaction_time = Column(String, nullable=True)

    source_app = Column(String)

    upi_transaction_id = Column(String, unique=True, index=True)

    bank_account = Column(String, nullable=True)

    notes = Column(Text, nullable=True)
    embedding = Column(Vector(3072))

    latitude = Column(Float, nullable=True)  # <--- NEW
    longitude = Column(Float, nullable=True)  # <--- NEW
    location_name = Column(String, nullable=True)  # <--- NEW
