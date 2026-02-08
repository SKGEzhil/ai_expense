from fastapi import FastAPI
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi import Request
from src.database import Base, engine
from src.logger import logger
from src.routes.transactions import router as transactions_router
from src.routes.events import router as events_router

app = FastAPI()


async def log_request_middleware(request: Request, call_next):
    # Only log for relevant routes to avoid cluttering
    if request.url.path.startswith("/transactions"):
        # We must read the body and then re-set it
        body = await request.body()
        try:
            # Decode for printing
            body_str = body.decode()
            print(f"\n--- INCOMING REQUEST ---")
            print(f"Method: {request.method}")
            print(f"URL: {request.url}")
            print(f"Body: {body_str}")
            print(f"------------------------\n")
        except Exception as e:
            print(f"Could not log body: {e}")

        # This is the magic part: we create a new request object with the
        # original body because the stream was consumed by await request.body()
        async def receive():
            return {"type": "http.request", "body": body}

        request._receive = receive

    response = await call_next(request)
    return response


# Add it to your app
app.add_middleware(BaseHTTPMiddleware, dispatch=log_request_middleware)

app.include_router(transactions_router)
app.include_router(events_router)

logger.info("Server started successfully!")
