import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from src.utils.enums import RecurringBillStatus, RecurringFrequency, Visibility


class RecurringBillCreate(BaseModel):
    account_id: uuid.UUID | None = None
    category_id: uuid.UUID | None = None
    title: str = Field(min_length=1, max_length=150)
    amount: Decimal = Field(gt=0)
    frequency: RecurringFrequency = RecurringFrequency.MONTHLY
    next_due_date: date
    visibility: Visibility = Visibility.SHARED
    notes: str | None = None


class RecurringBillUpdate(BaseModel):
    account_id: uuid.UUID | None = None
    category_id: uuid.UUID | None = None
    title: str | None = Field(default=None, min_length=1, max_length=150)
    amount: Decimal | None = Field(default=None, gt=0)
    frequency: RecurringFrequency | None = None
    next_due_date: date | None = None
    status: RecurringBillStatus | None = None
    visibility: Visibility | None = None
    notes: str | None = None


class RecurringBillRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    account_id: uuid.UUID | None
    category_id: uuid.UUID | None
    title: str
    amount: Decimal
    frequency: RecurringFrequency
    next_due_date: date
    status: RecurringBillStatus
    visibility: Visibility
    notes: str | None
