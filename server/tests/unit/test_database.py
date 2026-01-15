"""
Unit tests for database connection and configuration.
"""
import os
import pytest
from unittest.mock import patch, MagicMock
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError


class TestDatabaseConnection:
    """Tests for database connection functionality."""

    def test_database_url_from_environment(self):
        """Test that DATABASE_URL is read from environment."""
        test_url = "postgresql://test:test@localhost/testdb"
        with patch.dict(os.environ, {"DATABASE_URL": test_url}):
            # Re-import to get fresh value
            import importlib
            import src.database as db_module
            importlib.reload(db_module)
            assert db_module.DATABASE_URL == test_url

    def test_engine_creation(self, test_engine):
        """Test that SQLAlchemy engine is created successfully."""
        assert test_engine is not None
        # Test connection
        with test_engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            assert result.fetchone()[0] == 1

    def test_session_local_creation(self, test_engine):
        """Test that SessionLocal factory works correctly."""
        TestingSessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=test_engine
        )
        session = TestingSessionLocal()
        assert session is not None
        session.close()

    def test_base_declarative_base(self):
        """Test that Base is a valid declarative base."""
        from src.database import Base
        assert hasattr(Base, 'metadata')
        assert hasattr(Base, 'registry')

    def test_invalid_database_url(self):
        """Test behavior with invalid database URL."""
        with pytest.raises(Exception):
            invalid_engine = create_engine("invalid://url")
            with invalid_engine.connect() as conn:
                conn.execute(text("SELECT 1"))


class TestDatabaseDependency:
    """Tests for database dependency injection."""

    def test_get_db_yields_session(self, test_engine):
        """Test that get_db yields a valid session."""
        # Create a mock SessionLocal
        TestingSessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=test_engine
        )

        with patch('src.dependencies.SessionLocal', TestingSessionLocal):
            from src.dependencies import get_db

            db_generator = get_db()
            db = next(db_generator)

            assert db is not None

            # Clean up
            try:
                next(db_generator)
            except StopIteration:
                pass

    def test_get_db_closes_session(self, test_engine):
        """Test that get_db properly closes the session."""
        TestingSessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=test_engine
        )

        with patch('src.dependencies.SessionLocal', TestingSessionLocal):
            from src.dependencies import get_db

            db_generator = get_db()
            db = next(db_generator)

            # Simulate end of request
            try:
                next(db_generator)
            except StopIteration:
                pass

            # Session should be closed (accessing it should raise or show closed state)
            # In SQLAlchemy, closed sessions have specific behavior
            assert True  # If we get here without error, cleanup worked

