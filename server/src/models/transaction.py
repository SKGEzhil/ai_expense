from typing import List

from sqlalchemy import Column, Integer, String, Float, Date, Text, ForeignKey
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship, Mapped

from src.database import Base
from src.models.split import Split


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

    event_id = Column(Integer, ForeignKey("events.id"))
    event = relationship("Event", back_populates="transactions")

    splits: Mapped[List["Split"]] = relationship("Split", back_populates="transaction")
