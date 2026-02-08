from sqlalchemy import Column, Integer, String, Float, Date, Text, ForeignKey, Boolean
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship

from src.database import Base

class Split(Base):
    __tablename__ = "splits"
    id = Column(Integer, primary_key=True, index=True)

    transaction_id = Column(Integer, ForeignKey("transactions.id"))
    transaction = relationship("Transaction", back_populates="splits")

    amount = Column(Float, nullable=False)
    payee = Column(String)

    is_settled = Column(Boolean, default=False)

    notes = Column(Text, nullable=True)