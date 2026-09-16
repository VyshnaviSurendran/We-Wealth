import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from src.utils.enums import ExpenseStatus, Visibility


class ExpenseCreate(BaseModel):
    account_id: uuid.UUID
    paid_by_user_id: uuid.UUID
    category_id: uuid.UUID | None = None
    title: str = Field(min_length=1, max_length=150)
    amount: Decimal = Field(gt=0)
    expense_date: date
    due_date: date | None = None
    status: ExpenseStatus = ExpenseStatus.PAID
    visibility: Visibility = Visibility.SHARED
    notes: str | None = None


class ExpenseUpdate(BaseModel):
    account_id: uuid.UUID | None = None
    category_id: uuid.UUID | None = None
    title: str | None = Field(default=None, min_length=1, max_length=150)
    amount: Decimal | None = Field(default=None, gt=0)
    expense_date: date | None = None
    due_date: date | None = None
    visibility: Visibility | None = None
    notes: str | None = None


class ExpenseRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    account_id: uuid.UUID
    paid_by_user_id: uuid.UUID
    category_id: uuid.UUID | None
    title: str
    amount: Decimal
    expense_date: date
    due_date: date | None
    status: ExpenseStatus
    visibility: Visibility
    notes: str | None
    created_by: uuid.UUID


class MarkExpensePaidRequest(BaseModel):
    account_id: uuid.UUID | None = None
    expense_date: date | None = None
