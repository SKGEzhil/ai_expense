from fastapi import FastAPI

from src.database import Base, engine
from src.logger import logger
from src.routes.transactions import router as transactions_router
from src.routes.events import router as events_router

app = FastAPI()

app.include_router(transactions_router)
app.include_router(events_router)

logger.info("Server started successfully!")
