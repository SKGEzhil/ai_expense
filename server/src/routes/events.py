from typing import Any, List, Optional

from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy import Date
from sqlalchemy.orm import Session

from src.dependencies import get_db
from src.logger import logger
from src.models.event import Event
from src.models.transaction import Transaction
from pydantic import BaseModel

router = APIRouter(
    prefix="/events",
    tags=["Events"]
)

@router.post("/")
def create_event(
    event: dict[str, Any],
    db: Session = Depends(get_db)
):
    try:
        new_event = Event(
            event_name=event.get("event_name"),
            event_notes=event.get("event_notes")
        )

        db.add(new_event)
        db.commit()
        db.refresh(new_event)

        logger.info(f"Event {new_event.id} created successfully")
        return {
            "id": new_event.id,
            "event_name": new_event.event_name,
            "event_notes": new_event.event_notes
        }

    except Exception as e:
        logger.error(f"Error creating event: {str(e)}", exc_info=True)
        return {"message": f"Error creating event: {str(e)}"}

class TransactionResponse(BaseModel):
    id: int
    txn_type: str
    amount: float
    payee: str
    category: str
    transaction_date: Any
    transaction_time: str
    source_app: str
    upi_transaction_id: str
    bank_account: str
    notes: Optional[str]
    event_id: int

    class Config:
        from_attributes = True

class EventResponse(BaseModel):
    id: int
    event_name: str
    event_notes: Optional[str]

    transactions: List[TransactionResponse] = []

    class Config:
        from_attributes = True


@router.get("/{event_id}", response_model=EventResponse)
def get_event(
    event_id: int,
    db: Session = Depends(get_db)
):
    try:
        event = db.query(Event).filter(Event.id == event_id).first()
        if event:
            logger.info(f"Event {event_id} retrieved successfully")
            print(event.transactions.__dict__)
            return event
        else:
            logger.error(f"Event {event_id} not found")
            return {"message": "Event not found"}

    except Exception as e:
        logger.error(f"Error retrieving event: {str(e)}", exc_info=True)
        return {"message": f"Error retrieving event: {str(e)}"}

@router.get("/")
def get_all_events(
    db: Session = Depends(get_db)
):
    try:
        events = db.query(Event).all()
        return [event.__dict__ for event in events]

    except Exception as e:
        logger.error(f"Error retrieving all events: {str(e)}", exc_info=True)
        return {"message": f"Error retrieving all events: {str(e)}"}

@router.put("/")
def update_event(
    event: dict[str, Any],
    db: Session = Depends(get_db)
):
    try:
        event_id = event.get("id")
        event_name = event.get("event_name")
        event_notes = event.get("event_notes")
        db.query(Event).filter(Event.id == event_id).update({"event_name": event_name, "event_notes": event_notes})
        db.commit()
        logger.info(f"Event {event_id} updated successfully")
        return {"message": "Event updated successfully"}

    except Exception as e:
        logger.error(f"Error updating event: {str(e)}", exc_info=True)
        return {"message": f"Error updating event: {str(e)}"}


@router.delete("/{event_id}")
def delete_event(
    event_id: int,
    db: Session = Depends(get_db)
):
    try:
        event = db.query(Event).filter(Event.id == event_id).first()
        if event:
            db.delete(event)
            db.commit()
            logger.info(f"Event {event_id} deleted successfully")
            return {"message": "Event deleted successfully"}
        else:
            logger.error(f"Event {event_id} not found")
            return {"message": "Event not found"}
    except Exception as e:
        logger.error(f"Error deleting event: {str(e)}", exc_info=True)
        return {"message": f"Error deleting event: {str(e)}"}

from pydantic import BaseModel

class EventTransactionRequest(BaseModel):
    event_id: int
    txn_ids: List[int]

# Add transactions to an event
@router.post("/add_transactions")
def add_transactions(
    body: EventTransactionRequest,
    db: Session = Depends(get_db)
):
    try:
        event = db.query(Event).filter(Event.id == body.event_id).first()
        if event:
            for txn_id in body.txn_ids:
                txn = db.query(Transaction).filter(Transaction.id == txn_id).first()
                if txn:
                    txn.event_id = body.event_id
                    db.commit()
                    logger.info(f"Transaction {txn_id} added to event {body.event_id} successfully")
                else:
                    logger.error(f"Transaction {txn_id} not found")
                    return {"status": "error", "message": "Transaction not found"}
            return {"status": "success", "message": "Transactions added to event successfully"}
        else:
            logger.error(f"Event {body.event_id} not found")
            return {"status": "error", "message": "Event not found"}

    except Exception as e:
        logger.error(f"Error adding transactions to event: {str(e)}", exc_info=True)
        return {"status": "error", "message": f"Error adding transactions to event: {str(e)}"}

@router.post("/remove_transactions")
def remove_transactions(
    body: EventTransactionRequest,
    db: Session = Depends(get_db)
):
    try:
        event = db.query(Event).filter(Event.id == body.event_id).first()
        if event:
            for txn_id in body.txn_ids:
                txn = db.query(Transaction).filter(Transaction.id == txn_id).first()
                if txn:
                    txn.event_id = None
                    db.commit()
                    logger.info(f"Transaction {txn_id} removed from event {body.event_id} successfully")
                else:
                    logger.error(f"Transaction {txn_id} not found")
                    return {"status": "error", "message": "Transaction not found"}
            return {"status": "success", "message": "Transactions removed from event successfully"}
        else:
            logger.error(f"Event {body.event_id} not found")
            return {"status": "error", "message": "Event not found"}

    except Exception as e:
        logger.error(f"Error removing transactions from event: {str(e)}", exc_info=True)
        return {"status": "error", "message": f"Error removing transactions from event: {str(e)}"}