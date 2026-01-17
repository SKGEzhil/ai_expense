FROM python:3.12-slim AS base

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

# Build stage for testing
FROM base AS test
RUN pip install --no-cache-dir "pytest>=7.0" "pytest-cov>=4.0" "pytest-asyncio>=0.21" "httpx>=0.24"
CMD ["pytest"]

# Build stage for production
FROM base as prod
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
