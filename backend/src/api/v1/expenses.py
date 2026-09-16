import uuid
from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.core.dependencies import (
    get_current_user,
    get_household_member,
    require_household_membership,
)
from src.db.session import get_db
from src.models.expense import Expense
from src.models.household import HouseholdMember
from src.models.user import User
from src.schemas.expense import (
    ExpenseCreate,
    ExpenseRead,
    ExpenseUpdate,
    MarkExpensePaidRequest,
)
from src.services import transaction_service
from src.utils.enums import ExpenseStatus

router = APIRouter(tags=["expenses"])


@router.post(
    "/households/{household_id}/expenses", response_model=ExpenseRead, status_code=201
)
def create_expense(
    household_id: uuid.UUID,
    payload: ExpenseCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Expense:
    return transaction_service.create_expense(db, household_id, current_user.id, payload)


@router.get("/households/{household_id}/expenses", response_model=list[ExpenseRead])
def list_expenses(
    household_id: uuid.UUID,
    account_id: uuid.UUID | None = None,
    category_id: uuid.UUID | None = None,
    paid_by_user_id: uuid.UUID | None = None,
    status_filter: ExpenseStatus | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[Expense]:
    query = db.query(Expense).filter(Expense.household_id == household_id)
    if account_id is not None:
        query = query.filter(Expense.account_id == account_id)
    if category_id is not None:
        query = query.filter(Expense.category_id == category_id)
    if paid_by_user_id is not None:
        query = query.filter(Expense.paid_by_user_id == paid_by_user_id)
    if status_filter is not None:
        query = query.filter(Expense.status == status_filter)
    if from_date is not None:
        query = query.filter(Expense.expense_date >= from_date)
    if to_date is not None:
        query = query.filter(Expense.expense_date <= to_date)
    return query.order_by(Expense.expense_date.desc()).all()


@router.get("/expenses/{expense_id}", response_model=ExpenseRead)
def get_expense(
    expense_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Expense:
    expense = transaction_service.get_expense_or_404(db, expense_id)
    require_household_membership(db, current_user.id, expense.household_id)
    return expense


@router.patch("/expenses/{expense_id}", response_model=ExpenseRead)
def update_expense(
    expense_id: uuid.UUID,
    payload: ExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Expense:
    expense = transaction_service.get_expense_or_404(db, expense_id)
    require_household_membership(db, current_user.id, expense.household_id)
    return transaction_service.update_expense(db, expense, payload)


@router.post("/expenses/{expense_id}/pay", response_model=ExpenseRead)
def pay_expense(
    expense_id: uuid.UUID,
    payload: MarkExpensePaidRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Expense:
    expense = transaction_service.get_expense_or_404(db, expense_id)
    require_household_membership(db, current_user.id, expense.household_id)
    return transaction_service.mark_expense_paid(db, expense, payload)
