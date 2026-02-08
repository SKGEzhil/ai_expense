import json
import os
from datetime import date

import google.generativeai as genai

# --- SETUP AI ---
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
genai.configure(api_key=GEMINI_API_KEY)

def extract_data_from_image(image_bytes):
    model = genai.GenerativeModel('gemini-2.5-flash-lite')

    prompt = """
    Analyze this payment screenshot. Extract the following in JSON:

    1. 'txn_type': "DEBIT" or "CREDIT",
    2. 'amount': (float) The main transaction amount.
    3. 'payee': (string) The other party name, who receiver or sent money (e.g., "Zomato", "Karur Vysya Bank", "Self transfer", "Person Name").
    4. 'category': (string) One of [Food, Travel, Utilities, Transfer, Shopping, Other].
    5. 'transaction_date': (string) YYYY-MM-DD.
    6. 'transaction_time': (string) HH:MM AM/PM format.
    7. 'app_name': (string) e.g., Google Pay, PhonePe, Whatsapp Pay, PayTm.
    8. 'upi_id': (string) The numeric UPI Transaction ID / Ref No (usually 12 digits).
    9. 'bank_account': (string) The bank name money was debited from (e.g., "State Bank of India").
    10. 'notes': (string) Any additional notes or comments if available. Or else leave it blank.

    Example: 
    {"amount": 1.0, "merchant": "Self transfer", "category": "Transfer", "transaction_date": "2026-01-01", "transaction_time": "8:27 am", "app_name": "Google Pay", "upi_id": "600148787794", "bank_account": "State Bank of India"}
    """

    try:
        response = model.generate_content([prompt, {"mime_type": "image/jpeg", "data": image_bytes}])
        clean_json = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_json)
    except Exception as e:
        print(f"Extraction Error: {e}")
        return None

def generate_embedding(text):
    # Using the latest embedding model
    result = genai.embed_content(
        model="models/gemini-embedding-001",
        content=text,
        task_type="retrieval_document"
    )
    # Returns a 3072-dimensional vector
    return result['embedding']

def generate_sql(prompt, lim, page):
     # 2. PREPARE THE SYSTEM PROMPT
    # We pass 'today' so the LLM knows what "last week" or "last month" means.
    today_str = date.today().strftime("%Y-%m-%d")

    system_prompt = f"""
        You are a PostgreSQL expert. Convert the user's natural language request into a single raw SQL query.

        Table: transactions
        Schema:
            "column_name","data_type","is_nullable","column_default"
            "id","integer","NO","nextval('transactions_id_seq'::regclass)"
            "amount","double precision","NO",NULL
            "transaction_date","date","YES",NULL
            "embedding","USER-DEFINED","YES",NULL
            "category","character varying","YES",NULL
            "notes","text","YES",NULL
            "transaction_time","character varying","YES",NULL
            "source_app","character varying","YES",NULL
            "upi_transaction_id","character varying","YES",NULL
            "txn_type","character varying","YES",NULL
            "bank_account","character varying","YES",NULL
            "payee","character varying","YES",NULL

        Context:
        - Today is: {today_str}
        - The user wants page {page} with a limit of {lim}.

        Rules:
        1. STRICTLY return only the SQL query. No markdown, no explanations.
        2. Use the parameter ':query_vector' for semantic similarity if needed.
        3. Use the parameter ':limit' and ':offset' for pagination.
        4. For semantic search (vague queries like "something like food"), use: ORDER BY embedding <-> :query_vector
        5. For specific math (e.g. "highest amount"), use standard ORDER BY amount DESC.
        6. Always select all columns using 'SELECT *'.

        Example 1 ("Show me food expenses last month"):
        SELECT * FROM transactions 
        WHERE category ILIKE '%food%' 
        AND txn_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
        LIMIT :limit OFFSET :offset;

        Example 2 ("Expenses similar to 'gym'"):
        SELECT * FROM transactions 
        ORDER BY embedding <-> :query_vector
        LIMIT :limit OFFSET :offset;
        """
    # print("asking llm")
    # 3. ASK THE LLM TO GENERATE SQL
    model = genai.GenerativeModel('gemini-2.5-flash')
    # print("llm loaded")

    try:
        response = model.generate_content(f"{system_prompt}\nUser Request: \"{prompt}\"")
        generated_sql = response.text.replace("```sql", "").replace("```", "").strip()
        return generated_sql

    except Exception as e:
        print(f"SQL Generation Error: {e}")
        return None

def generate_rag_chunk(data: dict):
    action = "Paid" if data['txn_type'] == "DEBIT" else "Received"
    preposition = "to" if data['txn_type'] == "DEBIT" else "from"
    narrative = f"{action} {data['amount']} {preposition} {data['payee']} via {data['bank_account']} on {data['transaction_date']} at {data['transaction_time']}. Additional notes: {data.get('notes', '')}."
    return generate_embedding(narrative)

def get_offset_limit(page, lim):
    # Calculate standard SQL offset
    offset_val = (page - 1) * lim

    if lim == -1:
        actual_limit = 10_000_000  # 10 Million
    else:
        actual_limit = lim

    return offset_val, actual_limit

from datetime import datetime, date
from fastapi import HTTPException

def parse_date_range(date_range: str) -> tuple[date, date]:
    if not date_range:
        raise HTTPException(status_code=400, detail="date_range is required")

    parts = [p.strip() for p in date_range.split(",")]
    if len(parts) != 2:
        raise HTTPException(
            status_code=400,
            detail="date_range must contain two dates separated by a comma, format dd-mm-yyyy,dd-mm-yyyy"
        )

    try:
        start = datetime.strptime(parts[0], "%d-%m-%Y").date()
        end = datetime.strptime(parts[1], "%d-%m-%Y").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Dates must be in dd-mm-yyyy format")

    if start > end:
        raise HTTPException(status_code=400, detail="start date must be before or equal to end date")

    return start, end

