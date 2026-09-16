import uuid
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from src.models.account import Account
from src.models.expense import Expense
from src.models.income import Income
from src.models.transfer import Transfer
from src.schemas.expense import ExpenseCreate, ExpenseUpdate, MarkExpensePaidRequest
from src.schemas.income import IncomeCreate, IncomeUpdate
from src.schemas.transaction import TransactionRead, TransactionType
from src.schemas.transfer import TransferCreate
from src.utils.enums import ExpenseStatus


def create_income(
    db: Session, household_id: uuid.UUID, created_by: uuid.UUID, payload: IncomeCreate
) -> Income:
    income = Income(
        household_id=household_id,
        created_by=created_by,
        **payload.model_dump(),
    )
    db.add(income)
    db.commit()
    db.refresh(income)
    return income


def get_income_or_404(db: Session, income_id: uuid.UUID) -> Income:
    income = db.get(Income, income_id)
    if income is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Income not found")
    return income


def update_income(db: Session, income: Income, payload: IncomeUpdate) -> Income:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(income, field, value)
    db.add(income)
    db.commit()
    db.refresh(income)
    return income


def create_expense(
    db: Session, household_id: uuid.UUID, created_by: uuid.UUID, payload: ExpenseCreate
) -> Expense:
    expense = Expense(
        household_id=household_id,
        created_by=created_by,
        **payload.model_dump(),
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


def get_expense_or_404(db: Session, expense_id: uuid.UUID) -> Expense:
    expense = db.get(Expense, expense_id)
    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    return expense


def update_expense(db: Session, expense: Expense, payload: ExpenseUpdate) -> Expense:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(expense, field, value)
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


def mark_expense_paid(
    db: Session, expense: Expense, payload: MarkExpensePaidRequest
) -> Expense:
    if expense.status == ExpenseStatus.PAID:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Expense is already paid"
        )
    if expense.status == ExpenseStatus.CANCELLED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Cancelled expenses cannot be paid"
        )

    if payload.account_id is not None:
        expense.account_id = payload.account_id
    expense.expense_date = payload.expense_date or date.today()
    expense.status = ExpenseStatus.PAID

    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


def create_transfer(
    db: Session, household_id: uuid.UUID, created_by: uuid.UUID, payload: TransferCreate
) -> Transfer:
    from_account = db.get(Account, payload.from_account_id)
    to_account = db.get(Account, payload.to_account_id)

    if from_account is None or from_account.household_id != household_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Source account not found"
        )
    if to_account is None or to_account.household_id != household_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Destination account not found"
        )

    transfer = Transfer(household_id=household_id, created_by=created_by, **payload.model_dump())
    db.add(transfer)
    db.commit()
    db.refresh(transfer)
    return transfer


def get_account_transaction_history(
    db: Session,
    account_id: uuid.UUID,
    from_date: date | None = None,
    to_date: date | None = None,
    transaction_type: TransactionType | None = None,
) -> list[TransactionRead]:
    entries: list[TransactionRead] = []

    if transaction_type in (None, TransactionType.INCOME):
        query = db.query(Income).filter(Income.account_id == account_id)
        if from_date:
            query = query.filter(Income.income_date >= from_date)
        if to_date:
            query = query.filter(Income.income_date <= to_date)
        for income in query.all():
            entries.append(
                TransactionRead(
                    id=income.id,
                    transaction_type=TransactionType.INCOME,
                    title=income.title,
                    amount=income.amount,
                    transaction_date=income.income_date,
                    status=income.status.value,
                )
            )

    if transaction_type in (None, TransactionType.EXPENSE):
        query = db.query(Expense).filter(Expense.account_id == account_id)
        if from_date:
            query = query.filter(Expense.expense_date >= from_date)
        if to_date:
            query = query.filter(Expense.expense_date <= to_date)
        for expense in query.all():
            entries.append(
                TransactionRead(
                    id=expense.id,
                    transaction_type=TransactionType.EXPENSE,
                    title=expense.title,
                    amount=expense.amount,
                    transaction_date=expense.expense_date,
                    status=expense.status.value,
                )
            )

    if transaction_type in (None, TransactionType.TRANSFER_OUT):
        query = db.query(Transfer).filter(Transfer.from_account_id == account_id)
        if from_date:
            query = query.filter(Transfer.transfer_date >= from_date)
        if to_date:
            query = query.filter(Transfer.transfer_date <= to_date)
        for transfer in query.all():
            entries.append(
                TransactionRead(
                    id=transfer.id,
                    transaction_type=TransactionType.TRANSFER_OUT,
                    title="Transfer out",
                    amount=transfer.amount,
                    transaction_date=transfer.transfer_date,
                    status=None,
                )
            )

    if transaction_type in (None, TransactionType.TRANSFER_IN):
        query = db.query(Transfer).filter(Transfer.to_account_id == account_id)
        if from_date:
            query = query.filter(Transfer.transfer_date >= from_date)
        if to_date:
            query = query.filter(Transfer.transfer_date <= to_date)
        for transfer in query.all():
            entries.append(
                TransactionRead(
                    id=transfer.id,
                    transaction_type=TransactionType.TRANSFER_IN,
                    title="Transfer in",
                    amount=transfer.amount,
                    transaction_date=transfer.transfer_date,
                    status=None,
                )
            )

    entries.sort(key=lambda e: e.transaction_date, reverse=True)
    return entries
