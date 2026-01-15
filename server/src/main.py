from fastapi import FastAPI

from src.database import Base, engine
from src.logger import logger
from src.routes.transactions import router

app = FastAPI()

app.include_router(router)

logger.info("Server started successfully!")
