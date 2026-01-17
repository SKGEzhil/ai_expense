
from fastapi import APIRouter, UploadFile, File
from typing import Any

from fastapi import HTTPException, Depends, Query, Form
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from sqlalchemy.orm import Session

from src.dependencies import get_db
from src.main import logger
from src.models.event import Event
from src.models.transaction import Transaction
from src.utils import extract_data_from_image, generate_embedding, generate_sql, generate_rag_chunk

router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"]
)

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

@router.get("/")
async def get_transactions(
        prompt: str = Query(..., description="Natural language search query"),
        lim: int = Query(10, ge=-1),
        page: int = Query(1, ge=1),
        db: Session = Depends(get_db)
):

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
        logger.error(f"Error executing SQL query: Query: {generated_sql} {e}", exc_info=True)
        raise HTTPException(status_code=400, detail="Could not interpret search query.")

@router.get("/all")
async def get_all_transactions(
        lim: int = Query(50, ge=-1),
        page: int = Query(1, ge=1),
        db: Session = Depends(get_db)
):
    try:
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

    except Exception as e:
        logger.error(f"Error fetching transactions: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail="Could not fetch all transactions.")


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
