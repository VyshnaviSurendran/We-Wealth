import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from src.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from src.utils.enums import RecurringBillStatus, RecurringFrequency, Visibility


class RecurringBill(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "recurring_bills"

    household_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("households.id"), nullable=False
    )
    account_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("accounts.id"), nullable=True
    )
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True
    )
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    frequency: Mapped[RecurringFrequency] = mapped_column(
        default=RecurringFrequency.MONTHLY, nullable=False
    )
    next_due_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[RecurringBillStatus] = mapped_column(
        default=RecurringBillStatus.ACTIVE, nullable=False
    )
    visibility: Mapped[Visibility] = mapped_column(default=Visibility.SHARED, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
