import uuid
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from src.utils.enums import AccountType


class AccountCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    account_type: AccountType
    opening_balance: Decimal = Decimal("0.00")
    owner_user_id: uuid.UUID | None = None
    is_shared: bool = False


class AccountUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    owner_user_id: uuid.UUID | None = None
    is_shared: bool | None = None
    is_active: bool | None = None


class AccountRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    owner_user_id: uuid.UUID | None
    name: str
    account_type: AccountType
    opening_balance: Decimal
    is_shared: bool
    is_active: bool


class AccountDetailRead(AccountRead):
    actual_balance: Decimal
    pending_amount: Decimal
    safe_available_balance: Decimal
