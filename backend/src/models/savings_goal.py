import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from src.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from src.utils.enums import SavingsGoalStatus, Visibility


class SavingsGoal(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "savings_goals"

    household_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("households.id"), nullable=False
    )
    owner_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    target_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    current_amount: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), default=Decimal("0.00"), nullable=False
    )
    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    visibility: Mapped[Visibility] = mapped_column(default=Visibility.SHARED, nullable=False)
    status: Mapped[SavingsGoalStatus] = mapped_column(
        default=SavingsGoalStatus.ACTIVE, nullable=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
