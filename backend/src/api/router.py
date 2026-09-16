from fastapi import APIRouter

from src.api.v1 import (
    accounts,
    auth,
    budgets,
    categories,
    dashboard,
    expenses,
    households,
    incomes,
    recurring_bills,
    reports,
    savings,
    transfers,
    users,
)

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(households.router)
api_router.include_router(households.invitations_router)
api_router.include_router(accounts.router)
api_router.include_router(categories.router)
api_router.include_router(incomes.router)
api_router.include_router(expenses.router)
api_router.include_router(transfers.router)
api_router.include_router(savings.router)
api_router.include_router(budgets.router)
api_router.include_router(recurring_bills.router)
api_router.include_router(dashboard.router)
api_router.include_router(reports.router)
