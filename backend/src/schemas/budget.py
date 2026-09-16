import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from src.utils.enums import BudgetPeriodType, Visibility


class BudgetCreate(BaseModel):
    owner_user_id: uuid.UUID | None = None
    category_id: uuid.UUID | None = None
    amount: Decimal = Field(gt=0)
    period_type: BudgetPeriodType = BudgetPeriodType.MONTHLY
    start_date: date
    end_date: date | None = None
    visibility: Visibility = Visibility.SHARED


class BudgetUpdate(BaseModel):
    category_id: uuid.UUID | None = None
    amount: Decimal | None = Field(default=None, gt=0)
    period_type: BudgetPeriodType | None = None
    start_date: date | None = None
    end_date: date | None = None
    visibility: Visibility | None = None


class BudgetRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    owner_user_id: uuid.UUID | None
    category_id: uuid.UUID | None
    amount: Decimal
    period_type: BudgetPeriodType
    start_date: date
    end_date: date | None
    visibility: Visibility


class BudgetProgressRead(BudgetRead):
    spent_amount: Decimal
    remaining_amount: Decimal
