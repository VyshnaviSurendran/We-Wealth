# We Wealth

A couple-focused finance tracker: shared and personal expenses, income,
accounts/wallets, transfers, savings goals, budgets, and recurring bills.

## Structure

```
backend/   FastAPI backend (see backend/README.md for setup)
docs/      Requirements, database design, and API specification notes
```

## Quick start

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env
alembic upgrade head
uvicorn src.main:app --reload
```

Then open http://localhost:8000/docs for interactive API docs.
# We-Wealth
