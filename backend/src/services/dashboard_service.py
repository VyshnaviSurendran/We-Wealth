import calendar
import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from src.models.account import Account
from src.models.category import Category
from src.models.expense import Expense
from src.models.income import Income
from src.services import balance_service
from src.utils.enums import ExpenseStatus, IncomeStatus


def get_dashboard_summary(db: Session, household_id: uuid.UUID) -> dict:
    accounts = (
        db.query(Account)
        .filter(Account.household_id == household_id, Account.is_active.is_(True))
        .all()
    )

    account_details = []
    total_actual_balance = Decimal("0.00")
    total_pending_amount = Decimal("0.00")

    for account in accounts:
        detail = balance_service.get_account_balance_detail(db, account)
        total_actual_balance += detail["actual_balance"]
        total_pending_amount += detail["pending_amount"]
        account_details.append({**account.__dict__, **detail})

    today = date.today()
    month_start = today.replace(day=1)
    month_end = today.replace(day=calendar.monthrange(today.year, today.month)[1])

    month_income_stmt = select(func.coalesce(func.sum(Income.amount), 0)).where(
        Income.household_id == household_id,
        Income.status == IncomeStatus.RECEIVED,
        Income.income_date >= month_start,
        Income.income_date <= month_end,
    )
    month_expense_stmt = select(func.coalesce(func.sum(Expense.amount), 0)).where(
        Expense.household_id == household_id,
        Expense.status == ExpenseStatus.PAID,
        Expense.expense_date >= month_start,
        Expense.expense_date <= month_end,
    )
    month_pending_stmt = select(func.coalesce(func.sum(Expense.amount), 0)).where(
        Expense.household_id == household_id,
        Expense.status == ExpenseStatus.PENDING,
    )

    month_income_received = db.execute(month_income_stmt).scalar() or Decimal("0.00")
    month_expenses_paid = db.execute(month_expense_stmt).scalar() or Decimal("0.00")
    month_pending_expenses = db.execute(month_pending_stmt).scalar() or Decimal("0.00")

    return {
        "household_id": household_id,
        "total_actual_balance": total_actual_balance,
        "total_pending_amount": total_pending_amount,
        "total_safe_available_balance": total_actual_balance - total_pending_amount,
        "month_income_received": month_income_received,
        "month_expenses_paid": month_expenses_paid,
        "month_pending_expenses": month_pending_expenses,
        "net_worth": total_actual_balance,
        "accounts": account_details,
    }


def get_monthly_report(db: Session, household_id: uuid.UUID, year: int, month: int) -> dict:
    month_start = date(year, month, 1)
    month_end = date(year, month, calendar.monthrange(year, month)[1])

    expense_by_category_stmt = (
        select(
            func.coalesce(Category.name, "Uncategorized").label("category_name"),
            func.coalesce(func.sum(Expense.amount), 0).label("total_amount"),
        )
        .select_from(Expense)
        .outerjoin(Category, Category.id == Expense.category_id)
        .where(
            Expense.household_id == household_id,
            Expense.status == ExpenseStatus.PAID,
            Expense.expense_date >= month_start,
            Expense.expense_date <= month_end,
        )
        .group_by(Category.name)
    )
    income_by_category_stmt = (
        select(
            func.coalesce(Category.name, "Uncategorized").label("category_name"),
            func.coalesce(func.sum(Income.amount), 0).label("total_amount"),
        )
        .select_from(Income)
        .outerjoin(Category, Category.id == Income.category_id)
        .where(
            Income.household_id == household_id,
            Income.status == IncomeStatus.RECEIVED,
            Income.income_date >= month_start,
            Income.income_date <= month_end,
        )
        .group_by(Category.name)
    )

    expense_by_category = [
        {"category_name": row.category_name, "total_amount": row.total_amount}
        for row in db.execute(expense_by_category_stmt).all()
    ]
    income_by_category = [
        {"category_name": row.category_name, "total_amount": row.total_amount}
        for row in db.execute(income_by_category_stmt).all()
    ]

    total_income = sum((row["total_amount"] for row in income_by_category), Decimal("0.00"))
    total_expense = sum((row["total_amount"] for row in expense_by_category), Decimal("0.00"))

    return {
        "household_id": household_id,
        "year": year,
        "month": month,
        "total_income": total_income,
        "total_expense": total_expense,
        "net_savings": total_income - total_expense,
        "expense_by_category": expense_by_category,
        "income_by_category": income_by_category,
    }
