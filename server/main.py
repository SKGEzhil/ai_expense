import os
import json
from typing import Optional, Any

from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, Query, Form
import google.generativeai as genai
import dotenv

# --- DATABASE IMPORTS ---
from sqlalchemy import create_engine, Column, Integer, String, Float, Date, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pgvector.sqlalchemy import Vector
from geopy.geocoders import Nominatim

geolocator = Nominatim(user_agent="my_expense_tracker_v1")

dotenv.load_dotenv()

# --- CONFIGURATION ---
DATABASE_URL = os.environ.get("DATABASE_URL")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

# --- SETUP DATABASE ---
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, primary_key=True, index=True)
    txn_type = Column(String, nullable=False) # DEBIT or CREDIT
    amount = Column(Float, nullable=False)

    payee = Column(String)

    category = Column(String)
    transaction_date = Column(Date)

    # NEW: Store specific time (e.g., "08:27:00")
    transaction_time = Column(String, nullable=True)

    source_app = Column(String)

    # NEW: Critical for de-duplication. Stores "600148787794"
    upi_transaction_id = Column(String, unique=True, index=True)

    # NEW: Stores "State Bank of India ....3362"
    bank_account = Column(String, nullable=True)

    notes = Column(Text, nullable=True)
    embedding = Column(Vector(3072))

    latitude = Column(Float, nullable=True)  # <--- NEW
    longitude = Column(Float, nullable=True)  # <--- NEW
    location_name = Column(String, nullable=True)  # <--- NEW


Base.metadata.create_all(bind=engine)

# --- SETUP AI ---
genai.configure(api_key=GEMINI_API_KEY)
app = FastAPI()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# --- 1. EXTRACTION (Gemini 2.5 Flash Lite) ---
def extract_data_from_image(image_bytes):
    model = genai.GenerativeModel('gemini-2.5-flash-lite')

    prompt = """
    Analyze this payment screenshot. Extract the following in JSON:
    
    1. 'txn_type': "DEBIT" or "CREDIT",
    2. 'amount': (float) The main transaction amount.
    3. 'payee': (string) The other party name, who receiver or sent money (e.g., "Zomato", "Karur Vysya Bank", "Self transfer", "Person Name").
    4. 'category': (string) One of [Food, Travel, Utilities, Transfer, Shopping, Other].
    5. 'date': (string) YYYY-MM-DD.
    6. 'time': (string) HH:MM AM/PM format.
    7. 'app_name': (string) e.g., Google Pay, PhonePe, Whatsapp Pay, PayTm.
    8. 'upi_id': (string) The numeric UPI Transaction ID / Ref No (usually 12 digits).
    9. 'bank': (string) The bank name money was debited from (e.g., "State Bank of India").
    10. 'notes': (string) Any additional notes or comments if available. Or else leave it blank.

    Example: 
    {"amount": 1.0, "merchant": "Self transfer", "category": "Transfer", "date": "2026-01-01", "time": "8:27 am", "app_name": "Google Pay", "upi_id": "600148787794", "bank": "State Bank of India"}
    """

    try:
        response = model.generate_content([prompt, {"mime_type": "image/jpeg", "data": image_bytes}])
        clean_json = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_json)
    except Exception as e:
        print(f"Extraction Error: {e}")
        return None


# --- 2. EMBEDDING (Gemini Embedding 001) ---
def generate_embedding(text):
    # Using the latest embedding model
    result = genai.embed_content(
        model="models/gemini-embedding-001",
        content=text,
        task_type="retrieval_document"
    )
    # Returns a 3072-dimensional vector
    return result['embedding']


# --- API ENDPOINT ---
from sqlalchemy.exc import IntegrityError

from sqlalchemy.exc import IntegrityError


@app.post("/upload-receipt")
async def upload_receipt(
        file: UploadFile = File(...),
        # loc: Optional[str] = Form(None),
        # lat: Optional[float] = Form(None),
        # long: Optional[float] = Form(None),
        db: Session = Depends(get_db)
):
    content = await file.read()
    data = extract_data_from_image(content)

    # print("LOCATION:", loc)

    # ... (Date logic same as before) ...

    # Check if transaction already exists to avoid crashing
    existing_txn = db.query(Transaction).filter(Transaction.upi_transaction_id == data.get('upi_id')).first()
    if existing_txn:
        return {"status": "skipped", "message": "Transaction already exists."}

    # Create Narrative including the new details
    action = "Paid" if data['txn_type'] == "DEBIT" else "Received"
    preposition = "to" if data['txn_type'] == "DEBIT" else "from"
    narrative = f"{action} {data['amount']} {preposition} {data['payee']} via {data['bank']} on {data['date']} at {data['time']}. Additional notes: {data.get('notes', '')}."
    vector = generate_embedding(narrative)

    new_transaction = Transaction(
        txn_type=data['txn_type'],
        amount=data['amount'],
        payee=data['payee'],
        category=data['category'],
        transaction_date=data['date'],
        transaction_time=data.get('time'),  # Save the time
        source_app=data['app_name'],
        upi_transaction_id=data.get('upi_id'),  # Save the ID
        bank_account=data.get('bank'),  # Save the Bank
        notes=data.get('notes'),
        embedding=vector
    )

    try:
        db.add(new_transaction)
        db.commit()
        db.refresh(new_transaction)

        return {
            "txn_type": new_transaction.txn_type,
            "amount": new_transaction.amount,
            "payee": new_transaction.payee,
            "category": new_transaction.category,
            "transaction_date": new_transaction.transaction_date,
            "transaction_time": new_transaction.transaction_time,
            "source_app": new_transaction.source_app,
            "upi_transaction_id": new_transaction.upi_transaction_id,
            "bank_account": new_transaction.bank_account,
            "notes": new_transaction.notes
        }

        # return {"status": "success", "id": new_transaction.id}
    except IntegrityError:
        db.rollback()
        return {"status": "error", "message": "Duplicate Transaction ID detected"}


from sqlalchemy import text  # Critical for running raw SQL
from datetime import date

@app.get("/transactions")
async def get_transactions(
        prompt: str = Query(..., description="Natural language search query"),
        lim: int = Query(10, ge=-1),
        page: int = Query(1, ge=1),
        db: Session = Depends(get_db)
):
    # 1. EMBED THE PROMPT (For semantic search)
    # We always generate this because the LLM might decide to use it.
    query_vector = generate_embedding(prompt)

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

        print(f"Generated SQL: {generated_sql}")  # For debugging

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail=f"LLM generation failed: {str(e)}")

    # 4. EXECUTE THE SQL
    try:
        # Calculate standard SQL offset
        offset_val = (page - 1) * lim

        if lim == -1:
            actual_limit = 10_000_000  # 10 Million
        else:
            actual_limit = lim

        # We bind the vector and pagination params safely
        stmt = text(generated_sql)
        result = db.execute(stmt, {
            "query_vector": str(query_vector),  # pgvector expects string representation or list
            "limit": actual_limit,
            "offset": offset_val
        })

        # 5. FORMAT OUTPUT
        rows = result.fetchall()
        # Convert row objects to dicts (Standard SQLAchemy rows aren't JSON serializable directly)
        keys = result.keys()
        # print([dict(zip(keys, row)) for row in rows])
        return [dict(zip(keys, row)) for row in rows]

    except Exception as e:
        # If the LLM wrote bad SQL, this will catch it
        print(f"SQL Error: {e}")
        raise HTTPException(status_code=400, detail="Could not interpret search query.")

@app.get("/transactions/all")
async def get_all_transactions(
        lim: int = Query(10, ge=-1),
        page: int = Query(1, ge=1),
        db: Session = Depends(get_db)
):
    offset_val = (page - 1) * lim
    if lim == -1:
        actual_limit = 10_000_000  # 10 Million
    else:
        actual_limit = lim

    result = db.execute(
        text("SELECT * FROM transactions LIMIT :limit OFFSET :offset"),
        {"limit": actual_limit, "offset": offset_val}
    )

    # 5. FORMAT OUTPUT
    rows = result.fetchall()
    # Convert row objects to dicts (Standard SQLAchemy rows aren't JSON serializable directly)
    keys = result.keys()
    # print([dict(zip(keys, row)) for row in rows])
    return [dict(zip(keys, row)) for row in rows]


@app.put("/transactions/{txn_id}")
async def update_transaction(
        txn_id: int,
        transaction: dict[str, Any],
        db: Session = Depends(get_db)
):
    txn = db.query(Transaction).filter(Transaction.id == txn_id).first()
    if txn:
        for key, value in transaction.items():
            if hasattr(txn, key) and value is not None:
                setattr(txn, key, value)
        db.commit()
        return {"status": "success", "message": "Transaction updated successfully"}
    else:
        return {"status": "error", "message": "Transaction not found"}

@app.post("/transactions")
async def create_transaction(transaction: dict[str, Any], db: Session = Depends(get_db)):
    new_transaction = Transaction(**transaction)
    db.add(new_transaction)
    db.commit()
    db.refresh(new_transaction)
    return new_transaction

@app.delete("/transactions/{txn_id}")
async def delete_transaction(txn_id: int, db: Session = Depends(get_db)):
    txn = db.query(Transaction).filter(Transaction.id == txn_id).first()
    if txn:
        db.delete(txn)
        db.commit()
        return {"status": "success", "message": "Transaction deleted successfully"}
    else:
        return {"status": "error", "message": "Transaction not found"}

# if __name__ == "__main__":
#     uvicorn.run(app, host="0.0.0.0", port=8000)