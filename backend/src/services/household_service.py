import uuid
from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from src.models.category import Category
from src.models.household import Household, HouseholdInvitation, HouseholdMember
from src.models.user import User
from src.schemas.household import HouseholdCreate, HouseholdUpdate, InvitationCreate
from src.utils.enums import (
    DEFAULT_EXPENSE_CATEGORIES,
    DEFAULT_INCOME_CATEGORIES,
    CategoryType,
    HouseholdRole,
    MemberStatus,
)


def create_household(db: Session, current_user: User, payload: HouseholdCreate) -> Household:
    household = Household(
        name=payload.name,
        created_by=current_user.id,
        currency=payload.currency,
        timezone=payload.timezone,
    )
    db.add(household)
    db.flush()

    owner_membership = HouseholdMember(
        household_id=household.id,
        user_id=current_user.id,
        role=HouseholdRole.OWNER,
        status=MemberStatus.ACTIVE,
        joined_at=datetime.now(UTC),
    )
    db.add(owner_membership)

    for name in DEFAULT_EXPENSE_CATEGORIES:
        db.add(Category(household_id=household.id, name=name, category_type=CategoryType.EXPENSE))
    for name in DEFAULT_INCOME_CATEGORIES:
        db.add(Category(household_id=household.id, name=name, category_type=CategoryType.INCOME))

    db.commit()
    db.refresh(household)
    return household


def list_user_households(db: Session, current_user: User) -> list[Household]:
    return (
        db.query(Household)
        .join(HouseholdMember, HouseholdMember.household_id == Household.id)
        .filter(
            HouseholdMember.user_id == current_user.id,
            HouseholdMember.status == MemberStatus.ACTIVE,
        )
        .all()
    )


def get_household_or_404(db: Session, household_id: uuid.UUID) -> Household:
    household = db.get(Household, household_id)
    if household is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Household not found")
    return household


def update_household(
    db: Session, household: Household, payload: HouseholdUpdate
) -> Household:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(household, field, value)
    db.add(household)
    db.commit()
    db.refresh(household)
    return household


def invite_partner(
    db: Session, household: Household, current_user: User, payload: InvitationCreate
) -> HouseholdInvitation:
    invitation = HouseholdInvitation(
        household_id=household.id,
        email=payload.email,
        invited_by=current_user.id,
        status=MemberStatus.INVITED,
    )
    db.add(invitation)
    db.commit()
    db.refresh(invitation)
    return invitation


def accept_invitation(
    db: Session, invitation_id: uuid.UUID, current_user: User
) -> HouseholdMember:
    invitation = db.get(HouseholdInvitation, invitation_id)
    if invitation is None or invitation.status != MemberStatus.INVITED:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found"
        )
    if invitation.email.lower() != current_user.email.lower():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This invitation was not sent to your account",
        )

    existing_member = (
        db.query(HouseholdMember)
        .filter(
            HouseholdMember.household_id == invitation.household_id,
            HouseholdMember.user_id == current_user.id,
        )
        .first()
    )
    if existing_member is not None:
        existing_member.status = MemberStatus.ACTIVE
        existing_member.joined_at = datetime.now(UTC)
        member = existing_member
    else:
        member = HouseholdMember(
            household_id=invitation.household_id,
            user_id=current_user.id,
            role=HouseholdRole.MEMBER,
            status=MemberStatus.ACTIVE,
            joined_at=datetime.now(UTC),
        )
        db.add(member)

    invitation.status = MemberStatus.ACTIVE
    db.add(invitation)
    db.commit()
    db.refresh(member)
    return member


def list_members(db: Session, household_id: uuid.UUID) -> list[HouseholdMember]:
    return (
        db.query(HouseholdMember).filter(HouseholdMember.household_id == household_id).all()
    )


def update_member(
    db: Session,
    household_id: uuid.UUID,
    member_id: uuid.UUID,
    role: HouseholdRole | None,
    member_status: MemberStatus | None,
) -> HouseholdMember:
    member = (
        db.query(HouseholdMember)
        .filter(
            HouseholdMember.id == member_id, HouseholdMember.household_id == household_id
        )
        .first()
    )
    if member is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")

    if role is not None:
        member.role = role
    if member_status is not None:
        member.status = member_status

    db.add(member)
    db.commit()
    db.refresh(member)
    return member
