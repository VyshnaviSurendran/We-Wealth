import uuid
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from src.models.account import Account
from src.models.expense import Expense
from src.models.income import Income
from src.models.transfer import Transfer
from src.utils.enums import ExpenseStatus, IncomeStatus


def _sum(db: Session, stmt) -> Decimal:
    result = db.execute(stmt).scalar()
    return result if result is not None else Decimal("0.00")


def get_received_income(db: Session, account_id: uuid.UUID) -> Decimal:
    stmt = select(func.coalesce(func.sum(Income.amount), 0)).where(
        Income.account_id == account_id, Income.status == IncomeStatus.RECEIVED
    )
    return _sum(db, stmt)


def get_paid_expenses(db: Session, account_id: uuid.UUID) -> Decimal:
    stmt = select(func.coalesce(func.sum(Expense.amount), 0)).where(
        Expense.account_id == account_id, Expense.status == ExpenseStatus.PAID
    )
    return _sum(db, stmt)


def get_pending_expenses(db: Session, account_id: uuid.UUID) -> Decimal:
    stmt = select(func.coalesce(func.sum(Expense.amount), 0)).where(
        Expense.account_id == account_id, Expense.status == ExpenseStatus.PENDING
    )
    return _sum(db, stmt)


def get_transfers_in(db: Session, account_id: uuid.UUID) -> Decimal:
    stmt = select(func.coalesce(func.sum(Transfer.amount), 0)).where(
        Transfer.to_account_id == account_id
    )
    return _sum(db, stmt)


def get_transfers_out(db: Session, account_id: uuid.UUID) -> Decimal:
    stmt = select(func.coalesce(func.sum(Transfer.amount), 0)).where(
        Transfer.from_account_id == account_id
    )
    return _sum(db, stmt)


def get_actual_balance(db: Session, account: Account) -> Decimal:
    return (
        account.opening_balance
        + get_received_income(db, account.id)
        + get_transfers_in(db, account.id)
        - get_paid_expenses(db, account.id)
        - get_transfers_out(db, account.id)
    )


def get_account_balance_detail(db: Session, account: Account) -> dict[str, Decimal]:
    actual_balance = get_actual_balance(db, account)
    pending_amount = get_pending_expenses(db, account.id)
    return {
        "actual_balance": actual_balance,
        "pending_amount": pending_amount,
        "safe_available_balance": actual_balance - pending_amount,
    }
