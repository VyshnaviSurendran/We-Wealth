import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.core.dependencies import get_current_user, get_household_member
from src.db.session import get_db
from src.models.household import Household, HouseholdInvitation, HouseholdMember
from src.models.user import User
from src.schemas.household import (
    HouseholdCreate,
    HouseholdMemberRead,
    HouseholdMemberUpdate,
    HouseholdRead,
    HouseholdUpdate,
    InvitationCreate,
    InvitationRead,
)
from src.services import household_service

router = APIRouter(prefix="/households", tags=["households"])
invitations_router = APIRouter(prefix="/invitations", tags=["households"])


@router.post("", response_model=HouseholdRead, status_code=201)
def create_household(
    payload: HouseholdCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Household:
    return household_service.create_household(db, current_user, payload)


@router.get("", response_model=list[HouseholdRead])
def list_households(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
) -> list[Household]:
    return household_service.list_user_households(db, current_user)


@router.get("/{household_id}", response_model=HouseholdRead)
def get_household(
    household_id: uuid.UUID,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Household:
    return household_service.get_household_or_404(db, household_id)


@router.patch("/{household_id}", response_model=HouseholdRead)
def update_household(
    household_id: uuid.UUID,
    payload: HouseholdUpdate,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Household:
    household = household_service.get_household_or_404(db, household_id)
    return household_service.update_household(db, household, payload)


@router.post("/{household_id}/invitations", response_model=InvitationRead, status_code=201)
def invite_partner(
    household_id: uuid.UUID,
    payload: InvitationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> HouseholdInvitation:
    household = household_service.get_household_or_404(db, household_id)
    return household_service.invite_partner(db, household, current_user, payload)


@router.get("/{household_id}/members", response_model=list[HouseholdMemberRead])
def list_members(
    household_id: uuid.UUID,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[HouseholdMember]:
    return household_service.list_members(db, household_id)


@router.patch("/{household_id}/members/{member_id}", response_model=HouseholdMemberRead)
def update_member(
    household_id: uuid.UUID,
    member_id: uuid.UUID,
    payload: HouseholdMemberUpdate,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> HouseholdMember:
    return household_service.update_member(
        db, household_id, member_id, payload.role, payload.status
    )


@invitations_router.post("/{invitation_id}/accept", response_model=HouseholdMemberRead)
def accept_invitation(
    invitation_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HouseholdMember:
    return household_service.accept_invitation(db, invitation_id, current_user)
