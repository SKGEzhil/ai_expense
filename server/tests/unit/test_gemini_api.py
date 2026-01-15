"""
Unit tests for Gemini API connection and functions.
"""
import json
import os
import pytest
from unittest.mock import patch, MagicMock, Mock
from datetime import date


class TestGeminiAPIConfiguration:
    """Tests for Gemini API configuration."""

    def test_gemini_configure_called(self):
        """Test that genai.configure is called with API key."""
        with patch('google.generativeai.configure') as mock_configure:
            with patch.dict(os.environ, {"GEMINI_API_KEY": "test-key"}):
                import importlib
                import src.utils
                # Reload to trigger configuration
                importlib.reload(src.utils)
                # Note: configure is called at module load time

                # check that configure was called with the correct key
                mock_configure.assert_called_with(api_key="test-key")


class TestExtractDataFromImage:
    """Tests for extract_data_from_image function."""

    def test_extract_data_from_image_success(self, mock_gemini_response):
        """Test successful data extraction from image."""
        mock_response = MagicMock()
        mock_response.text = json.dumps(mock_gemini_response)

        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_response

        with patch('google.generativeai.GenerativeModel', return_value=mock_model):
            from src.utils import extract_data_from_image

            result = extract_data_from_image(b"fake_image_bytes")

            assert result is not None
            assert result["txn_type"] == "DEBIT"
            assert result["amount"] == 150.0
            assert result["payee"] == "Zomato"
            assert result["category"] == "Food"

    def test_extract_data_from_image_with_markdown_wrapper(self, mock_gemini_response):
        """Test extraction when response has markdown code blocks."""
        mock_response = MagicMock()
        mock_response.text = f"```json\n{json.dumps(mock_gemini_response)}\n```"

        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_response

        with patch('google.generativeai.GenerativeModel', return_value=mock_model):
            from src.utils import extract_data_from_image

            result = extract_data_from_image(b"fake_image_bytes")

            assert result is not None
            assert result["amount"] == 150.0

    def test_extract_data_from_image_api_error(self):
        """Test handling of API errors during extraction."""
        mock_model = MagicMock()
        mock_model.generate_content.side_effect = Exception("API Error")

        with patch('google.generativeai.GenerativeModel', return_value=mock_model):
            from src.utils import extract_data_from_image

            result = extract_data_from_image(b"fake_image_bytes")

            assert result is None

    def test_extract_data_from_image_invalid_json(self):
        """Test handling of invalid JSON response."""
        mock_response = MagicMock()
        mock_response.text = "not valid json"

        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_response

        with patch('google.generativeai.GenerativeModel', return_value=mock_model):
            from src.utils import extract_data_from_image

            result = extract_data_from_image(b"fake_image_bytes")

            assert result is None


class TestGenerateEmbedding:
    """Tests for generate_embedding function."""

    def test_generate_embedding_success(self, mock_embedding):
        """Test successful embedding generation."""
        mock_result = {'embedding': mock_embedding}

        with patch('google.generativeai.embed_content', return_value=mock_result):
            from src.utils import generate_embedding

            result = generate_embedding("Test text for embedding")

            assert result is not None
            assert len(result) == 3072
            assert result == mock_embedding

    def test_generate_embedding_api_error(self):
        """Test handling of API errors during embedding."""
        with patch('google.generativeai.embed_content', side_effect=Exception("API Error")):
            from src.utils import generate_embedding

            with pytest.raises(Exception):
                generate_embedding("Test text")


class TestGenerateSQL:
    """Tests for generate_sql function."""

    @pytest.mark.parametrize("gemini_output, expected_clean_sql", [
        # Case A: Clean SQL (Happy path)
        ("SELECT * FROM transactions", "SELECT * FROM transactions"),

        # Case B: Markdown Wrapper (The messier path)
        ("```sql\nSELECT * FROM transactions\n```", "SELECT * FROM transactions"),
    ])
    def test_generate_sql_handling(self, gemini_output, expected_clean_sql):
        """Test that SQL is correctly extracted regardless of how Gemini formats it."""

        # Setup the mock with the specific output for this case
        mock_response = MagicMock()
        mock_response.text = gemini_output

        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_response

        with patch('google.generativeai.GenerativeModel', return_value=mock_model):
            from src.utils import generate_sql

            # Run the function
            result = generate_sql("Show transactions", 10, 1)

            # Assertions
            assert result == expected_clean_sql
            assert "```" not in result

    def test_generate_sql_api_error(self):
        """Test handling of API errors during SQL generation."""
        mock_model = MagicMock()
        mock_model.generate_content.side_effect = Exception("API Error")

        with patch('google.generativeai.GenerativeModel', return_value=mock_model):
            from src.utils import generate_sql

            result = generate_sql("Show transactions", 10, 1)

            assert result is None
