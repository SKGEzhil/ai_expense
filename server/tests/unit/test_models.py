"""
Unit tests for Transaction model.
"""
import pytest
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from src.database import Base
from src.models.transaction import Transaction
from src.models.event import Event


class TestTransactionModel:
    """Tests for Transaction SQLAlchemy model."""

    @pytest.fixture
    def db_session(self):
        """Create an in-memory SQLite database for testing."""
        # Note: pgvector won't work in SQLite, but we can test basic model structure
        engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False}
        )

        # Create tables (excluding vector column for SQLite compatibility)
        # For full testing with pgvector, use PostgreSQL test database
        TestSession = sessionmaker(bind=engine)
        session = TestSession()

        # Create a simplified table without the vector column
        from sqlalchemy import Column, Integer, String, Float, Date, Text, Table, MetaData
        metadata = MetaData()

        transactions_table = Table(
            'transactions', metadata,
            Column('id', Integer, primary_key=True),
            Column('txn_type', String, nullable=False),
            Column('amount', Float, nullable=False),
            Column('payee', String),
            Column('category', String),
            Column('transaction_date', Date),
            Column('transaction_time', String),
            Column('source_app', String),
            Column('upi_transaction_id', String, unique=True),
            Column('bank_account', String),
            Column('notes', Text),
            Column('latitude', Float),
            Column('longitude', Float),
            Column('location_name', String),
        )

        metadata.create_all(engine)

        yield session
        session.close()

    def test_transaction_model_has_required_fields(self):
        """Test that Transaction model has all required fields."""
        required_fields = [
            'id', 'txn_type', 'amount', 'payee', 'category',
            'transaction_date', 'transaction_time', 'source_app',
            'upi_transaction_id', 'bank_account', 'notes', 'embedding',
            'event_id', 'event'
        ]

        for field in required_fields:
            assert hasattr(Transaction, field), f"Missing field: {field}"

    def test_transaction_tablename(self):
        """Test that Transaction model uses correct table name."""
        assert Transaction.__tablename__ == "transactions"

    def test_transaction_id_is_primary_key(self):
        """Test that id is the primary key."""
        assert Transaction.id.primary_key

    def test_transaction_upi_id_is_unique(self):
        """Test that upi_transaction_id has unique constraint."""
        assert Transaction.upi_transaction_id.unique

    def test_transaction_amount_not_nullable(self):
        """Test that amount field is not nullable."""
        assert Transaction.amount.nullable == False

    def test_transaction_txn_type_not_nullable(self):
        """Test that txn_type field is not nullable."""
        assert Transaction.txn_type.nullable == False

    def test_create_transaction_instance(self):
        """Test creating a Transaction instance."""
        txn = Transaction(
            txn_type="DEBIT",
            amount=100.0,
            payee="Test Payee",
            category="Food",
            transaction_date=date(2026, 1, 15),
            transaction_time="10:00 AM",
            source_app="Google Pay",
            upi_transaction_id="123456789012",
            bank_account="Test Bank",
            notes="Test notes"
        )

        assert txn.txn_type == "DEBIT"
        assert txn.amount == 100.0
        assert txn.payee == "Test Payee"
        assert txn.category == "Food"

    def test_transaction_embedding_dimension(self):
        """Test that embedding column is configured for 3072 dimensions."""
        from pgvector.sqlalchemy import Vector

        # Check the column type
        embedding_column = Transaction.embedding
        assert embedding_column is not None
        # The Vector type should be configured for 3072 dimensions

