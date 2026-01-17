from typing import List

from sqlalchemy import Column, Integer, String, Float, Date, Text
from sqlalchemy.orm import relationship, Mapped

from src.database import Base
from src.models.transaction import Transaction


class Event(Base):
    __tablename__ = "events"
    id = Column(Integer, primary_key=True, index=True)
    event_name = Column(String, nullable=False)
    event_notes = Column(Text, nullable=True)

    # List of transactions
    transactions: Mapped[List["Transaction"]] = relationship("Transaction", back_populates="event")


