# We Wealth — Backend

FastAPI backend for a couple-focused shared expense and finance tracker.

## Stack

- Python 3.12, FastAPI, SQLAlchemy 2, Alembic, Pydantic v2
- PostgreSQL
- JWT auth (python-jose), Argon2 password hashing (passlib)
- pytest, ruff

## Local setup (without Docker)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

cp .env.example .env
# edit .env with your local Postgres credentials

# apply migrations
alembic upgrade head

# run the dev server
uvicorn src.main:app --reload
```

API docs: http://localhost:8000/docs

## Local setup (Docker Compose)

```bash
cp .env.example .env
docker compose up --build
```

This starts Postgres on host port `5433` and the API on `http://localhost:8000`.
Migrations run automatically on container start.

## Database migrations

```bash
# create a new migration after changing models
alembic revision --autogenerate -m "describe change"

# apply migrations
alembic upgrade head

# roll back one migration
alembic downgrade -1
```

## Tests

```bash
pytest
```

## Lint

```bash
ruff check .
```

## Project layout

```
src/
  core/       # settings, security (JWT + password hashing), auth dependencies
  db/         # SQLAlchemy engine/session, declarative base
  models/     # SQLAlchemy ORM models
  schemas/    # Pydantic request/response models
  services/   # business logic (balance calculations, household/account/
              # transaction/savings/dashboard rules)
  api/v1/     # FastAPI routers, one per resource
  utils/      # shared enums and constants
alembic/      # migrations
```

## Core business rules

- **Actual balance** = opening balance + received income + transfers in − paid
  expenses − transfers out.
- **Pending balance** = sum of unpaid (`PENDING`) expenses tied to an account.
- **Safe available balance** = actual balance − pending balance.
- Transfers move money between accounts and are never counted as expenses or
  income.
- Savings goals are targets/allocations, not separate pots of money — money
  sitting in a savings account is already counted via that account's balance,
  so goal `current_amount` is not added again when computing net worth.
- Every income/expense/savings goal/budget/recurring bill has a `visibility`
  of `SHARED` or `PERSONAL`.
