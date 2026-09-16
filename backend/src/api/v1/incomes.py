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
from src.models.household import HouseholdMember
from src.models.income import Income
from src.models.user import User
from src.schemas.income import IncomeCreate, IncomeRead, IncomeUpdate
from src.services import transaction_service
from src.utils.enums import IncomeStatus

router = APIRouter(tags=["incomes"])


@router.post("/households/{household_id}/incomes", response_model=IncomeRead, status_code=201)
def create_income(
    household_id: uuid.UUID,
    payload: IncomeCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Income:
    return transaction_service.create_income(db, household_id, current_user.id, payload)


@router.get("/households/{household_id}/incomes", response_model=list[IncomeRead])
def list_incomes(
    household_id: uuid.UUID,
    account_id: uuid.UUID | None = None,
    owner_user_id: uuid.UUID | None = None,
    status_filter: IncomeStatus | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[Income]:
    query = db.query(Income).filter(Income.household_id == household_id)
    if account_id is not None:
        query = query.filter(Income.account_id == account_id)
    if owner_user_id is not None:
        query = query.filter(Income.owner_user_id == owner_user_id)
    if status_filter is not None:
        query = query.filter(Income.status == status_filter)
    if from_date is not None:
        query = query.filter(Income.income_date >= from_date)
    if to_date is not None:
        query = query.filter(Income.income_date <= to_date)
    return query.order_by(Income.income_date.desc()).all()


@router.get("/incomes/{income_id}", response_model=IncomeRead)
def get_income(
    income_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Income:
    income = transaction_service.get_income_or_404(db, income_id)
    require_household_membership(db, current_user.id, income.household_id)
    return income


@router.patch("/incomes/{income_id}", response_model=IncomeRead)
def update_income(
    income_id: uuid.UUID,
    payload: IncomeUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Income:
    income = transaction_service.get_income_or_404(db, income_id)
    require_household_membership(db, current_user.id, income.household_id)
    return transaction_service.update_income(db, income, payload)
