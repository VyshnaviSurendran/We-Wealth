import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.core.dependencies import (
    get_current_user,
    get_household_member,
    require_household_membership,
)
from src.db.session import get_db
from src.models.household import HouseholdMember
from src.models.savings_goal import SavingsGoal
from src.models.user import User
from src.schemas.savings_goal import (
    SavingsContributionCreate,
    SavingsGoalCreate,
    SavingsGoalRead,
    SavingsGoalUpdate,
)
from src.services import savings_service

router = APIRouter(tags=["savings"])


@router.post(
    "/households/{household_id}/savings-goals",
    response_model=SavingsGoalRead,
    status_code=201,
)
def create_savings_goal(
    household_id: uuid.UUID,
    payload: SavingsGoalCreate,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> SavingsGoal:
    return savings_service.create_savings_goal(db, household_id, payload)


@router.get("/households/{household_id}/savings-goals", response_model=list[SavingsGoalRead])
def list_savings_goals(
    household_id: uuid.UUID,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[SavingsGoal]:
    return savings_service.list_savings_goals(db, household_id)


@router.get("/savings-goals/{goal_id}", response_model=SavingsGoalRead)
def get_savings_goal(
    goal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SavingsGoal:
    goal = savings_service.get_savings_goal_or_404(db, goal_id)
    require_household_membership(db, current_user.id, goal.household_id)
    return goal


@router.patch("/savings-goals/{goal_id}", response_model=SavingsGoalRead)
def update_savings_goal(
    goal_id: uuid.UUID,
    payload: SavingsGoalUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SavingsGoal:
    goal = savings_service.get_savings_goal_or_404(db, goal_id)
    require_household_membership(db, current_user.id, goal.household_id)
    return savings_service.update_savings_goal(db, goal, payload)


@router.post("/savings-goals/{goal_id}/contributions", response_model=SavingsGoalRead)
def contribute_to_goal(
    goal_id: uuid.UUID,
    payload: SavingsContributionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SavingsGoal:
    goal = savings_service.get_savings_goal_or_404(db, goal_id)
    require_household_membership(db, current_user.id, goal.household_id)
    return savings_service.contribute_to_goal(db, goal, payload.amount)
