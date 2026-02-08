
from fastapi import APIRouter, UploadFile, File, Body
from typing import Any, Optional

from fastapi import HTTPException, Depends, Query, Form
from httpx import Request
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from sqlalchemy.orm import Session

from src.dependencies import get_db
from src.main import logger
from src.models.event import Event
from src.models.split import Split
from src.models.transaction import Transaction
from src.utils import extract_data_from_image, generate_embedding, generate_sql, generate_rag_chunk, get_offset_limit, \
    parse_date_range

router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"]
)

class SplitResponse(BaseModel):
    id: int
    payee: str
    amount: float
    is_settled: bool

    class Config:
        from_attributes = True

class TransactionResponse(BaseModel):
    id: int
    txn_type: str
    amount: float
    payee: str
    category: str
    transaction_date: Any
    transaction_time: Optional[str]
    source_app: str
    upi_transaction_id: Optional[str]
    bank_account: Optional[str]
    notes: Optional[str]
    splits: list[SplitResponse]

    class Config:
        from_attributes = True

# Add this near your other classes
class SplitUpdateSchema(BaseModel):
    id: int
    payee: Optional[str] = None
    amount: Optional[float] = None
    is_settled: Optional[bool] = None
    notes: Optional[str] = None

@router.post("/upload-receipt")
async def upload_receipt(
        file: UploadFile = File(...),
        db: Session = Depends(get_db)
):

    try:
        content = await file.read()
        data = extract_data_from_image(content)

        # Check if transaction already exists to avoid crashing
        existing_txn = db.query(Transaction).filter(Transaction.upi_transaction_id == data.get('upi_id')).first()
        if existing_txn:
            return {"status": "skipped", "message": "Transaction already exists."}

        # Generate RAG chunk
        vector = generate_rag_chunk(data)

        new_transaction = Transaction(
            txn_type=data['txn_type'],
            amount=data['amount'],
            payee=data['payee'],
            category=data['category'],
            transaction_date=data['transaction_date'],
            transaction_time=data.get('transaction_time'),  # Save the time
            source_app=data['app_name'],
            upi_transaction_id=data.get('upi_id'),  # Save the ID
            bank_account=data.get('bank_account'),  # Save the Bank
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
            logger.error(f"Duplicate Transaction ID detected: {data['upi_id']}")
            return {"status": "error", "message": "Duplicate Transaction ID detected"}

    except Exception as e:
        logger.error(e, exc_info=True)
        return {"status": "error", "message": f"Error uploading receipt: {str(e)}"}

@router.get("/", response_model=list[TransactionResponse])
async def get_transactions(
        prompt: str = Query(None, description="Natural language search query"),
        date_range: str = Query(None, description="Date range in YYYY-MM-DD format"),
        lim: int = Query(50, ge=-1),
        page: int = Query(1, ge=1),
        db: Session = Depends(get_db)
):
    offset_val, actual_limit = get_offset_limit(page, lim)

    # IF NO PROMPT PROVIDED, RETURN TRANSACTIONS BASED ON DATE RANGE

    if prompt is None:
        try:
            if date_range is None:
                result = db.query(Transaction).order_by(Transaction.transaction_date.desc()).offset(offset_val).limit(actual_limit).all()
            else:
                start_date, end_date = parse_date_range(date_range)
                logger.info(f"Fetching transactions between {start_date} and {end_date}")

                result = (db.query(Transaction)
                          .filter(Transaction.transaction_date >= start_date, Transaction.transaction_date <= end_date)
                          .order_by(Transaction.transaction_date.desc())
                          .offset(offset_val)
                          .limit(actual_limit)
                          .all())

            return result

        except Exception as e:
            logger.error(f"Error getting transactions: {e}", exc_info=True)
            raise HTTPException(status_code=400, detail=f"Error getting transactions: {e}")

    # IF PROMPT IS PROVIDED, GENERATE SQL QUERY

    try:
        generated_sql = generate_sql(prompt, lim, page)
        logger.info(f"Generated SQL query: {generated_sql}")

    except Exception as e:
        logger.error(f"Error generating SQL query: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail="Could not generate SQL query.")

    # 1. EMBED THE PROMPT (For semantic search)
    # We always generate this because the LLM might decide to use it.
    query_vector = generate_embedding(prompt)

    # 4. EXECUTE THE SQL
    try:
        # We bind the vector and pagination params safely
        stmt = text(generated_sql)
        result = db.execute(stmt, {
            "query_vector": str(query_vector),  # pgvector expects string representation or list
            "limit": actual_limit,
            "offset": offset_val
        })

        # SQLAlchemy rows are accessible by column name.
        # We assume the generated SQL selects 'id' (which 'SELECT *' does).
        rows = result.fetchall()

        if not rows:
            return []

        # Extract the IDs from the raw result preserving order
        txn_ids = [row.id for row in rows]

        # 3. RE-FETCH WITH ORM (Hydration)
        # Now we fetch the full objects including the 'splits' relationship
        # We use .filter(Transaction.id.in_(txn_ids))
        from sqlalchemy.orm import selectinload

        orm_results = (
            db.query(Transaction)
            .options(selectinload(Transaction.splits))  # Optimize fetching splits
            .filter(Transaction.id.in_(txn_ids))
            .all()
        )

        # 4. RESTORE ORDER
        # The IN clause does not guarantee order, so we sort them back
        # to match the semantic search/SQL order
        txn_map = {txn.id: txn for txn in orm_results}
        ordered_results = [txn_map[txn_id] for txn_id in txn_ids if txn_id in txn_map]

        return ordered_results

    except Exception as e:
        # If the LLM wrote bad SQL, this will catch it
        print(f"SQL Error: {e}")
        logger.error(f"Error executing SQL query: Query: {generated_sql} {e}", exc_info=True)
        raise HTTPException(status_code=400, detail="Could not interpret search query.")

@router.put("/split")
async def update_split(
        split_data: SplitUpdateSchema,  # Use the schema here
        db: Session = Depends(get_db)
):
    print(f"RECEIVED DATA: {split_data}")  # This will now print!

    try:
        # Access fields using dot notation: split_data.id
        split_obj = db.query(Split).filter(Split.id == split_data.id).first()

        if not split_obj:
            logger.error(f"Split {split_data.id} not found")
            return {"status": "error", "message": "Split not found"}

        # Handle Settlement Logic
        if split_data.is_settled:
            txn = split_obj.transaction
            txn.amount -= split_obj.amount
            # OPTIONAL: You likely want to mark the split as settled in DB too?
            split_obj.is_settled = True
            db.commit()
            logger.info(f"Transaction amount updated for split {split_obj.id}")
            return {"status": "success", "message": "Split settled successfully"}

        # Handle General Update
        # Convert schema to dict, excluding fields that weren't sent (nulls)
        update_data = split_data.model_dump(exclude_unset=True)

        for key, value in update_data.items():
            if hasattr(split_obj, key):
                setattr(split_obj, key, value)

        db.commit()
        logger.info(f"Split {split_obj.id} updated successfully")
        return {"status": "success", "message": "Split updated successfully"}

    except Exception as e:
        logger.error(e, exc_info=True)
        return {"status": "error", "message": f"Error updating split: {str(e)}"}


@router.put("/{txn_id}")
async def update_transaction(
        txn_id: int,
        transaction: dict[str, Any],
        db: Session = Depends(get_db)
):

    try:
        txn = db.query(Transaction).filter(Transaction.id == txn_id).first()
        if txn:
            for key, value in transaction.items():
                if hasattr(txn, key) and value is not None:
                    setattr(txn, key, value)

            # Regenerate embedding if relevant fields are updated
            txn.embedding = generate_rag_chunk(txn.__dict__)

            db.commit()
            logger.info(f"Transaction {txn_id} updated successfully")
            return {"status": "success", "message": "Transaction updated successfully"}
        else:
            logger.error(f"Transaction {txn_id} not found")
            return {"status": "error", "message": "Transaction not found"}
    except Exception as e:
        logger.error(e, exc_info=True)
        return {"status": "error", "message": "Error updating transaction"}


@router.post("/")
async def create_transaction(transaction: dict[str, Any], db: Session = Depends(get_db)):
    try:
        new_transaction = Transaction(**transaction)

        # Generate embedding
        new_transaction.embedding = generate_rag_chunk(transaction)

        db.add(new_transaction)
        db.commit()
        db.refresh(new_transaction)
        logger.info(f"Transaction {new_transaction.id} created successfully")

        return {"status": "success", "message": "Transaction created successfully", "id": new_transaction.id}

    except Exception as e:
        logger.error(e, exc_info=True)
        return {"status": "error", "message": f"Error creating transaction: {str(e)}"}

@router.delete("/{txn_id}")
async def delete_transaction(txn_id: int, db: Session = Depends(get_db)):
    try:
        txn = db.query(Transaction).filter(Transaction.id == txn_id).first()
        if txn:
            db.delete(txn)
            db.commit()
            logger.info(f"Transaction {txn_id} deleted successfully")
            return {"status": "success", "message": "Transaction deleted successfully"}
        else:
            logger.error(f"Transaction {txn_id} not found")
            return {"status": "error", "message": "Transaction not found"}

    except Exception as e:
        logger.error(e, exc_info=True)
        return {"status": "error", "message": f"Error deleting transaction: {str(e)}"}

@router.post("/split")
async def add_split(split: dict[str, Any], db: Session = Depends(get_db)):
    try:
        txn = db.query(Transaction).filter(Transaction.id == split['txn_id']).first()
        if txn:
            new_split = Split(
                payee=split['payee'],
                amount=split['amount'],
                is_settled=split['is_settled']
            )
            new_split.transaction_id = txn.id
            db.add(new_split)
            db.commit()
            db.refresh(new_split)

            logger.info(f"Split {new_split.id} added to transaction {split['txn_id']} successfully")
            return {"status": "success", "message": "Split added successfully"}
        else:
            logger.error(f"Transaction {split['txn_id']} not found")
            return {"status": "error", "message": "Transaction not found"}
    except Exception as e:
        logger.error(e, exc_info=True)
        return {"status": "error", "message": f"Error adding split: {str(e)}"}

@router.delete("/split/{split_id}")
async def delete_split(split_id: int, db: Session = Depends(get_db)):
    try:
        split_obj = db.query(Split).filter(Split.id == split_id).first()
        if split_obj:
            db.delete(split_obj)
            db.commit()
            logger.info(f"Split {split_id} deleted successfully")
            return {"status": "success", "message": "Split deleted successfully"}
        else:
            logger.error(f"Split {split_id} not found")
            return {"status": "error", "message": "Split not found"}

    except Exception as e:
        logger.error(e, exc_info=True)
        return {"status": "error", "message": f"Error deleting split: {str(e)}"}