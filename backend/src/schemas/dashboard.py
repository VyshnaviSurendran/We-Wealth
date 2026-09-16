import uuid
from decimal import Decimal

from pydantic import BaseModel

from src.schemas.account import AccountDetailRead


class DashboardSummary(BaseModel):
    household_id: uuid.UUID
    total_actual_balance: Decimal
    total_pending_amount: Decimal
    total_safe_available_balance: Decimal
    month_income_received: Decimal
    month_expenses_paid: Decimal
    month_pending_expenses: Decimal
    net_worth: Decimal
    accounts: list[AccountDetailRead]


class MonthlyReportEntry(BaseModel):
    category_name: str
    total_amount: Decimal


class MonthlyReport(BaseModel):
    household_id: uuid.UUID
    year: int
    month: int
    total_income: Decimal
    total_expense: Decimal
    net_savings: Decimal
    expense_by_category: list[MonthlyReportEntry]
    income_by_category: list[MonthlyReportEntry]
