import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from src.utils.enums import IncomeStatus, Visibility


class IncomeCreate(BaseModel):
    account_id: uuid.UUID
    owner_user_id: uuid.UUID
    category_id: uuid.UUID | None = None
    title: str = Field(min_length=1, max_length=150)
    amount: Decimal = Field(gt=0)
    income_date: date
    status: IncomeStatus = IncomeStatus.RECEIVED
    notes: str | None = None
    visibility: Visibility = Visibility.SHARED


class IncomeUpdate(BaseModel):
    account_id: uuid.UUID | None = None
    category_id: uuid.UUID | None = None
    title: str | None = Field(default=None, min_length=1, max_length=150)
    amount: Decimal | None = Field(default=None, gt=0)
    income_date: date | None = None
    status: IncomeStatus | None = None
    notes: str | None = None
    visibility: Visibility | None = None


class IncomeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    account_id: uuid.UUID
    owner_user_id: uuid.UUID
    category_id: uuid.UUID | None
    title: str
    amount: Decimal
    income_date: date
    status: IncomeStatus
    notes: str | None
    visibility: Visibility
    created_by: uuid.UUID
