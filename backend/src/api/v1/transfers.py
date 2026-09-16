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
from src.models.transfer import Transfer
from src.models.user import User
from src.schemas.transfer import TransferCreate, TransferRead
from src.services import transaction_service

router = APIRouter(tags=["transfers"])


@router.post(
    "/households/{household_id}/transfers", response_model=TransferRead, status_code=201
)
def create_transfer(
    household_id: uuid.UUID,
    payload: TransferCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Transfer:
    return transaction_service.create_transfer(db, household_id, current_user.id, payload)


@router.get("/households/{household_id}/transfers", response_model=list[TransferRead])
def list_transfers(
    household_id: uuid.UUID,
    account_id: uuid.UUID | None = None,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[Transfer]:
    query = db.query(Transfer).filter(Transfer.household_id == household_id)
    if account_id is not None:
        query = query.filter(
            (Transfer.from_account_id == account_id) | (Transfer.to_account_id == account_id)
        )
    return query.order_by(Transfer.transfer_date.desc()).all()


@router.get("/transfers/{transfer_id}", response_model=TransferRead)
def get_transfer(
    transfer_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Transfer:
    transfer = db.get(Transfer, transfer_id)
    if transfer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transfer not found")
    require_household_membership(db, current_user.id, transfer.household_id)
    return transfer
