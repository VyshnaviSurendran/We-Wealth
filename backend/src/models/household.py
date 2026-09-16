import uuid
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from src.utils.enums import HouseholdRole, MemberStatus

if TYPE_CHECKING:
    from src.models.user import User


class Household(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "households"

    name: Mapped[str] = mapped_column(String(150), nullable=False)
    created_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    currency: Mapped[str] = mapped_column(String(3), default="INR", nullable=False)
    timezone: Mapped[str] = mapped_column(String(64), default="Asia/Kolkata", nullable=False)

    members: Mapped[list["HouseholdMember"]] = relationship(
        back_populates="household", cascade="all, delete-orphan"
    )
    invitations: Mapped[list["HouseholdInvitation"]] = relationship(
        back_populates="household", cascade="all, delete-orphan"
    )


class HouseholdMember(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "household_members"

    household_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("households.id"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    role: Mapped[HouseholdRole] = mapped_column(
        default=HouseholdRole.MEMBER, nullable=False
    )
    status: Mapped[MemberStatus] = mapped_column(
        default=MemberStatus.ACTIVE, nullable=False
    )
    joined_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=True)

    household: Mapped["Household"] = relationship(back_populates="members")
    user: Mapped["User"] = relationship(back_populates="household_memberships")


class HouseholdInvitation(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "household_invitations"

    household_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("households.id"), nullable=False
    )
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    invited_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    status: Mapped[MemberStatus] = mapped_column(
        default=MemberStatus.INVITED, nullable=False
    )

    household: Mapped["Household"] = relationship(back_populates="invitations")
