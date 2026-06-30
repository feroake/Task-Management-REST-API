# Task Management REST API

A production-ready REST API for task management built with **FastAPI**, **SQLAlchemy**, **PostgreSQL**, and **JWT authentication**.

## Features

- **User Authentication** — Register, login, JWT access tokens, bcrypt password hashing
- **Task CRUD** — Create, read, update, delete, and mark tasks as complete
- **Advanced Querying** — Filter by status/priority, search by title, sort by any field, pagination
- **Ownership Enforcement** — Users can only access their own tasks (IDOR-safe)
- **Structured Logging** — JSON logs with request IDs for distributed tracing
- **API Versioning** — `/api/v1/` prefix from day one
- **OpenAPI Documentation** — Interactive Swagger UI at `/docs`
- **Docker Support** — Multi-stage Dockerfile and docker-compose with PostgreSQL
- **CI/CD Ready** — GitHub Actions workflow for lint, test, and build
- **Test Coverage >90%** — Integration tests with SQLite in-memory database

## Technology Stack

| Component          | Technology                              |
| ------------------ | --------------------------------------- |
| API Framework      | FastAPI                                 |
| ORM                | SQLAlchemy 2.0 (async)                  |
| Database           | PostgreSQL (production) / SQLite (tests) |
| Migrations         | Alembic                                 |
| Validation         | Pydantic v2                             |
| Authentication     | JWT (python-jose) + bcrypt              |
| Logging            | structlog (structured JSON)             |
| Testing            | pytest + httpx                          |
| Containerization   | Docker + docker-compose                 |
| CI/CD              | GitHub Actions                          |

## Project Structure

```
task_management/
├── app/
│   ├── main.py              # FastAPI app factory
│   ├── core/                # Config, security, DB, exceptions, logging
│   ├── models/              # SQLAlchemy ORM models
│   ├── schemas/             # Pydantic request/response schemas
│   ├── repositories/        # Data access layer (Repository Pattern)
│   ├── services/            # Business logic layer
│   └── api/                 # API routes, dependencies, middleware
│       └── v1/              # Version 1 API
├── alembic/                 # Database migrations
├── tests/                   # Test suite
├── Dockerfile               # Multi-stage production build
├── docker-compose.yml       # App + PostgreSQL stack
├── pyproject.toml           # Dependencies and tool config
└── .github/workflows/       # CI/CD pipeline
```

**Architecture**: Clean Architecture with strict layer separation:
```
api/ → services/ → repositories/ → models/
  └─────────────→ schemas/ (DTOs)
  └─────────────→ core/ (cross-cutting)
```

## Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL 16+ (or Docker)
- pip

### Local Development

```bash
# 1. Clone and enter the project
cd task_management

# 2. Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\activate   # Windows

# 3. Install dependencies
pip install -e ".[dev]"

# 4. Configure environment
cp .env.example .env
# Edit .env with your database credentials and a secure JWT_SECRET_KEY

# 5. Run database migrations
alembic upgrade head

# 6. Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API is now running at **http://localhost:8000**. Interactive docs at **http://localhost:8000/docs**.

### Docker

```bash
# Start everything (API + PostgreSQL)
docker compose up --build

# Run migrations in the container
docker compose exec api alembic upgrade head

# Stop
docker compose down

# Stop and delete volumes
docker compose down -v
```

## API Reference

### Authentication

| Method | Endpoint                 | Description      | Auth Required |
| ------ | ------------------------ | ---------------- | ------------- |
| POST   | `/api/v1/auth/register`  | Register a user  | No            |
| POST   | `/api/v1/auth/login`     | Login, get token | No            |

### Tasks

| Method | Endpoint                           | Description            | Auth Required |
| ------ | ---------------------------------- | ---------------------- | ------------- |
| GET    | `/api/v1/tasks`                    | List tasks (paginated) | Yes           |
| POST   | `/api/v1/tasks`                    | Create a task          | Yes           |
| GET    | `/api/v1/tasks/{id}`               | Get task by ID         | Yes           |
| PUT    | `/api/v1/tasks/{id}`               | Update a task          | Yes           |
| DELETE | `/api/v1/tasks/{id}`               | Delete a task          | Yes           |
| PATCH  | `/api/v1/tasks/{id}/complete`      | Mark task as done      | Yes           |

### Health

| Method | Endpoint   | Description            |
| ------ | ---------- | ---------------------- |
| GET    | `/health`  | Health check (no auth) |

### Example Requests

#### Register a User

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "securepass123"}'
```

Response (201):
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "email": "user@example.com",
  "created_at": "2026-06-22T10:00:00Z",
  "updated_at": "2026-06-22T10:00:00Z"
}
```

#### Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "securepass123"}'
```

Response (200):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

#### Create a Task

```bash
TOKEN="your-jwt-token-here"

curl -X POST http://localhost:8000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Review pull request",
    "description": "Review the auth module PR",
    "priority": "high",
    "due_date": "2026-06-25T17:00:00Z"
  }'
```

Response (201):
```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "title": "Review pull request",
  "description": "Review the auth module PR",
  "status": "todo",
  "priority": "high",
  "due_date": "2026-06-25T17:00:00Z",
  "owner_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "created_at": "2026-06-22T10:05:00Z",
  "updated_at": "2026-06-22T10:05:00Z"
}
```

#### List Tasks with Filters

```bash
curl "http://localhost:8000/api/v1/tasks?status=todo&priority=high&search=review&sort_by=created_at&sort_order=desc&page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN"
```

Response (200):
```json
{
  "items": [ ... ],
  "total": 42,
  "page": 1,
  "page_size": 10,
  "pages": 5
}
```

## Query Parameters for `GET /api/v1/tasks`

| Parameter    | Type   | Default      | Description                          |
| ------------ | ------ | ------------ | ------------------------------------ |
| `status`     | string | —            | Filter: `todo`, `in_progress`, `done`|
| `priority`   | string | —            | Filter: `low`, `medium`, `high`      |
| `search`     | string | —            | Case-insensitive title search        |
| `sort_by`    | string | `created_at` | `created_at`, `updated_at`, `title`, `priority`, `status`, `due_date` |
| `sort_order` | string | `desc`       | `asc` or `desc`                      |
| `page`       | int    | `1`          | Page number (1-indexed)              |
| `page_size`  | int    | `20`         | Items per page (max 100)             |

## Environment Variables

| Variable                          | Default                              | Description                    |
| --------------------------------- | ------------------------------------ | ------------------------------ |
| `DATABASE_URL`                    | `postgresql+asyncpg://...`           | Database connection string     |
| `JWT_SECRET_KEY`                  | (change me)                          | Secret key for JWT signing     |
| `JWT_ALGORITHM`                   | `HS256`                              | JWT signing algorithm          |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `30`                                 | Token expiration in minutes    |
| `LOG_LEVEL`                       | `INFO`                               | Logging level                  |
| `DEBUG`                           | `false`                              | Enable debug mode              |
| `APP_NAME`                        | `Task Management API`                | Application name               |

## Running Tests

```bash
# Run all tests with coverage
pytest

# Run specific test file
pytest tests/test_auth.py -v

# Run with detailed coverage report
pytest --cov=app --cov-report=html
open htmlcov/index.html
```

Coverage is enforced at **>80%** (currently **94%**).

## Database Migrations

```bash
# Generate a new migration after model changes
alembic revision --autogenerate -m "description_of_change"

# Apply all pending migrations
alembic upgrade head

# Roll back one migration
alembic downgrade -1

# View migration history
alembic history
```

## Error Responses

All errors follow a consistent format:

```json
{
  "detail": "Human-readable error message"
}
```

| Status Code | Meaning                        |
| ----------- | ------------------------------ |
| 200         | Success                        |
| 201         | Created                        |
| 204         | No Content (successful delete) |
| 400         | Bad Request                    |
| 401         | Unauthorized (invalid/missing token) |
| 403         | Forbidden                      |
| 404         | Not Found                      |
| 409         | Conflict (duplicate resource)  |
| 422         | Validation Error               |
| 500         | Internal Server Error          |

## License

MIT
