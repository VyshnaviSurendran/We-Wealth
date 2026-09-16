import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.dependencies import (
    get_current_user,
    get_household_member,
    require_household_membership,
)
from src.db.session import get_db
from src.models.household import HouseholdMember
from src.models.recurring_bill import RecurringBill
from src.models.user import User
from src.schemas.recurring_bill import (
    RecurringBillCreate,
    RecurringBillRead,
    RecurringBillUpdate,
)

router = APIRouter(tags=["recurring-bills"])


def _get_bill_or_404(db: Session, bill_id: uuid.UUID) -> RecurringBill:
    bill = db.get(RecurringBill, bill_id)
    if bill is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Recurring bill not found"
        )
    return bill


@router.post(
    "/households/{household_id}/recurring-bills",
    response_model=RecurringBillRead,
    status_code=201,
)
def create_recurring_bill(
    household_id: uuid.UUID,
    payload: RecurringBillCreate,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> RecurringBill:
    bill = RecurringBill(household_id=household_id, **payload.model_dump())
    db.add(bill)
    db.commit()
    db.refresh(bill)
    return bill


@router.get(
    "/households/{household_id}/recurring-bills", response_model=list[RecurringBillRead]
)
def list_recurring_bills(
    household_id: uuid.UUID,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[RecurringBill]:
    return db.query(RecurringBill).filter(RecurringBill.household_id == household_id).all()


@router.get("/recurring-bills/{bill_id}", response_model=RecurringBillRead)
def get_recurring_bill(
    bill_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> RecurringBill:
    bill = _get_bill_or_404(db, bill_id)
    require_household_membership(db, current_user.id, bill.household_id)
    return bill


@router.patch("/recurring-bills/{bill_id}", response_model=RecurringBillRead)
def update_recurring_bill(
    bill_id: uuid.UUID,
    payload: RecurringBillUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> RecurringBill:
    bill = _get_bill_or_404(db, bill_id)
    require_household_membership(db, current_user.id, bill.household_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(bill, field, value)
    db.add(bill)
    db.commit()
    db.refresh(bill)
    return bill
