import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from src.utils.enums import SavingsGoalStatus, Visibility


class SavingsGoalCreate(BaseModel):
    owner_user_id: uuid.UUID | None = None
    name: str = Field(min_length=1, max_length=150)
    target_amount: Decimal = Field(gt=0)
    current_amount: Decimal = Decimal("0.00")
    target_date: date | None = None
    visibility: Visibility = Visibility.SHARED
    notes: str | None = None


class SavingsGoalUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    target_amount: Decimal | None = Field(default=None, gt=0)
    target_date: date | None = None
    visibility: Visibility | None = None
    status: SavingsGoalStatus | None = None
    notes: str | None = None


class SavingsContributionCreate(BaseModel):
    amount: Decimal = Field(description="Positive to add, negative to withdraw")


class SavingsGoalRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    owner_user_id: uuid.UUID | None
    name: str
    target_amount: Decimal
    current_amount: Decimal
    target_date: date | None
    visibility: Visibility
    status: SavingsGoalStatus
    notes: str | None
