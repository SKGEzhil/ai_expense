"""
Unit tests for utility functions in utils.py.
"""
import json
import pytest
from unittest.mock import patch, MagicMock


class TestGenerateRagChunk:
    """Tests for generate_rag_chunk function."""

    @pytest.mark.parametrize("txn_data, expected_phrases", [
        # Case 1: DEBIT Transaction
        (
                {
                    "txn_type": "DEBIT", "amount": 500.0, "payee": "Swiggy",
                    "bank_account": "HDFC Bank", "transaction_date": "2026-01-15",
                    "transaction_time": "1:30 PM", "notes": "Dinner order"
                },
                ["Paid", "500.0", "to Swiggy", "HDFC Bank"]
        ),

        # Case 2: CREDIT Transaction
        (
                {
                    "txn_type": "CREDIT", "amount": 1000.0, "payee": "John Doe",
                    "bank_account": "SBI", "transaction_date": "2026-01-14",
                    "transaction_time": "10:00 AM", "notes": "Reimbursement"
                },
                ["Received", "from John Doe"]
        ),

        # Case 3: Missing Notes Key
        (
                {
                    "txn_type": "DEBIT", "amount": 200.0, "payee": "Amazon",
                    "bank_account": "Axis Bank", "transaction_date": "2026-01-13",
                    "transaction_time": "3:00 PM"
                },
                ["Additional notes:"]  # Checks if code handles missing key gracefully
        ),

        # Case 4: Empty Notes String
        (
                {
                    "txn_type": "DEBIT", "amount": 50.0, "payee": "Coffee Shop",
                    "bank_account": "ICICI", "transaction_date": "2026-01-12",
                    "transaction_time": "9:00 AM", "notes": ""
                },
                []  # No specific text assertion needed (just ensures no crash)
        ),
    ])
    def test_generate_rag_chunk_scenarios(self, mock_embedding, txn_data, expected_phrases):
        """Test RAG chunk generation for various transaction types."""

        # We patch the embedding function just like before
        with patch('src.utils.generate_embedding', return_value=mock_embedding) as mock_embed:
            from src.utils import generate_rag_chunk

            # 1. Run the function
            result = generate_rag_chunk(txn_data)

            # 2. Get the actual string that was passed to the embedding function
            # call_args[0][0] retrieves the first positional argument of the first call
            generated_text = mock_embed.call_args[0][0]

            # 3. Dynamic Assertions: Check whatever phrases we expect for this specific case
            for phrase in expected_phrases:
                assert phrase in generated_text

            # 4. Common Assertion: Result should always be the mock embedding
            assert result == mock_embedding

    def test_generate_rag_chunk_narrative_format(self, mock_embedding):
        """Test that narrative follows expected format."""
        data = {
            "txn_type": "DEBIT",
            "amount": 750.0,
            "payee": "Flipkart",
            "bank_account": "Kotak",
            "transaction_date": "2026-01-10",
            "transaction_time": "5:45 PM",
            "notes": "Electronics purchase"
        }

        with patch('src.utils.generate_embedding', return_value=mock_embedding) as mock_embed:
            from src.utils import generate_rag_chunk

            generate_rag_chunk(data)

            call_args = mock_embed.call_args[0][0]
            # Expected format: "Paid 750.0 to Flipkart via Kotak on 2026-01-10 at 5:45 PM. Additional notes: Electronics purchase."
            expected_parts = [
                "Paid 750.0 to Flipkart",
                "via Kotak",
                "on 2026-01-10",
                "at 5:45 PM",
                "Additional notes: Electronics purchase"
            ]
            for part in expected_parts:
                assert part in call_args


class TestUtilsHelperFunctions:
    """Tests for any helper/utility functions."""

    def test_json_cleanup_in_extract(self):
        """Test that JSON cleanup properly handles various formats."""
        test_cases = [
            ('{"key": "value"}', {"key": "value"}),
            ('```json\n{"key": "value"}\n```', {"key": "value"}),
            ('```json{"key": "value"}```', {"key": "value"}),
        ]

        for raw_text, expected in test_cases:
            mock_response = MagicMock()
            mock_response.text = raw_text

            mock_model = MagicMock()
            mock_model.generate_content.return_value = mock_response

            with patch('google.generativeai.GenerativeModel', return_value=mock_model):
                from src.utils import extract_data_from_image

                result = extract_data_from_image(b"fake_bytes")

                assert result == expected, f"Failed for: {raw_text}"

    def test_sql_cleanup_in_generate_sql(self):
        """Test that SQL cleanup properly handles markdown wrappers."""
        test_cases = [
            "SELECT * FROM transactions",
            "```sql\nSELECT * FROM transactions\n```",
            "```sql SELECT * FROM transactions ```",
        ]

        expected = "SELECT * FROM transactions"

        for raw_sql in test_cases:
            mock_response = MagicMock()
            mock_response.text = raw_sql

            mock_model = MagicMock()
            mock_model.generate_content.return_value = mock_response

            with patch('google.generativeai.GenerativeModel', return_value=mock_model):
                from src.utils import generate_sql

                result = generate_sql("test", 10, 1)

                assert "```" not in result
                assert "SELECT" in result


