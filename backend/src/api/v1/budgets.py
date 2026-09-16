import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.dependencies import (
    get_current_user,
    get_household_member,
    require_household_membership,
)
from src.db.session import get_db
from src.models.budget import Budget
from src.models.household import HouseholdMember
from src.models.user import User
from src.schemas.budget import BudgetCreate, BudgetRead, BudgetUpdate

router = APIRouter(tags=["budgets"])


def _get_budget_or_404(db: Session, budget_id: uuid.UUID) -> Budget:
    budget = db.get(Budget, budget_id)
    if budget is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Budget not found")
    return budget


@router.post("/households/{household_id}/budgets", response_model=BudgetRead, status_code=201)
def create_budget(
    household_id: uuid.UUID,
    payload: BudgetCreate,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Budget:
    budget = Budget(household_id=household_id, **payload.model_dump())
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget


@router.get("/households/{household_id}/budgets", response_model=list[BudgetRead])
def list_budgets(
    household_id: uuid.UUID,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[Budget]:
    return db.query(Budget).filter(Budget.household_id == household_id).all()


@router.get("/budgets/{budget_id}", response_model=BudgetRead)
def get_budget(
    budget_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Budget:
    budget = _get_budget_or_404(db, budget_id)
    require_household_membership(db, current_user.id, budget.household_id)
    return budget


@router.patch("/budgets/{budget_id}", response_model=BudgetRead)
def update_budget(
    budget_id: uuid.UUID,
    payload: BudgetUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Budget:
    budget = _get_budget_or_404(db, budget_id)
    require_household_membership(db, current_user.id, budget.household_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(budget, field, value)
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget
