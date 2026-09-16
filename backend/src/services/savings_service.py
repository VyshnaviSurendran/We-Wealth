import uuid
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from src.models.savings_goal import SavingsGoal
from src.schemas.savings_goal import SavingsGoalCreate, SavingsGoalUpdate
from src.utils.enums import SavingsGoalStatus


def create_savings_goal(
    db: Session, household_id: uuid.UUID, payload: SavingsGoalCreate
) -> SavingsGoal:
    goal = SavingsGoal(household_id=household_id, **payload.model_dump())
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal


def list_savings_goals(db: Session, household_id: uuid.UUID) -> list[SavingsGoal]:
    return db.query(SavingsGoal).filter(SavingsGoal.household_id == household_id).all()


def get_savings_goal_or_404(db: Session, goal_id: uuid.UUID) -> SavingsGoal:
    goal = db.get(SavingsGoal, goal_id)
    if goal is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Savings goal not found")
    return goal


def update_savings_goal(
    db: Session, goal: SavingsGoal, payload: SavingsGoalUpdate
) -> SavingsGoal:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(goal, field, value)
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal


def contribute_to_goal(db: Session, goal: SavingsGoal, amount: Decimal) -> SavingsGoal:
    new_amount = goal.current_amount + amount
    if new_amount < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Contribution would make current_amount negative",
        )

    goal.current_amount = new_amount
    if goal.current_amount >= goal.target_amount:
        goal.status = SavingsGoalStatus.COMPLETED
    elif goal.status == SavingsGoalStatus.COMPLETED:
        goal.status = SavingsGoalStatus.ACTIVE

    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal
