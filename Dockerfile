# Multi-stage Docker build for Task Management API
# Stage 1: Builder — installs dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files and install
COPY pyproject.toml ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --target=/app/deps \
    fastapi \
    "uvicorn[standard]" \
    "sqlalchemy[asyncio]>=2.0" \
    asyncpg \
    alembic \
    pydantic-settings \
    "python-jose[cryptography]" \
    bcrypt \
    python-multipart \
    structlog \
    python-dotenv \
    email-validator \
    psycopg2-binary


# Stage 2: Runtime — minimal production image
FROM python:3.12-slim AS runtime

WORKDIR /app

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy installed dependencies from builder
COPY --from=builder /app/deps /usr/local/lib/python3.12/site-packages/

# Copy application code
COPY app/ ./app/
COPY alembic.ini ./
COPY alembic/ ./alembic/

# Create directory for logs
RUN mkdir -p /app/logs && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
