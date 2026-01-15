"""
Shared test fixtures and configuration for all tests.
"""
import os
import sys
from unittest.mock import MagicMock, patch

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from src.database import Base


# --- Test Database Setup ---
# Use SQLite for unit tests (in-memory)
TEST_DATABASE_URL = "sqlite:///:memory:"


@pytest.fixture(scope="function")
def test_engine():
    """Create a test database engine."""
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False}
    )
    return engine


@pytest.fixture(scope="function")
def test_db_session(test_engine):
    """Create a test database session."""
    # Create all tables
    Base.metadata.create_all(bind=test_engine)

    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    session = TestingSessionLocal()

    try:
        yield session
    finally:
        session.close()
        # Drop all tables after test
        Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def mock_gemini_response():
    """Mock response from Gemini API for image extraction."""
    return {
        "txn_type": "DEBIT",
        "amount": 150.0,
        "payee": "Zomato",
        "category": "Food",
        "transaction_date": "2026-01-15",
        "transaction_time": "12:30 PM",
        "app_name": "Google Pay",
        "upi_id": "123456789012",
        "bank_account": "State Bank of India",
        "notes": "Lunch order"
    }


@pytest.fixture
def mock_embedding():
    """Mock embedding vector (3072 dimensions)."""
    return [0.1] * 3072


@pytest.fixture
def sample_transaction_data():
    """Sample transaction data for testing."""
    return {
        "txn_type": "DEBIT",
        "amount": 100.0,
        "payee": "Amazon",
        "category": "Shopping",
        "transaction_date": "2026-01-15",
        "transaction_time": "10:00 AM",
        "source_app": "Google Pay",
        "upi_transaction_id": "999888777666",
        "bank_account": "HDFC Bank",
        "notes": "Test purchase"
    }


@pytest.fixture
def sample_image_bytes():
    """Sample image bytes for testing upload."""
    # Create a minimal valid JPEG header
    return b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'

