import uuid
from datetime import date
from decimal import Decimal
from enum import Enum

from pydantic import BaseModel


class TransactionType(str, Enum):
    INCOME = "INCOME"
    EXPENSE = "EXPENSE"
    TRANSFER_IN = "TRANSFER_IN"
    TRANSFER_OUT = "TRANSFER_OUT"


class TransactionRead(BaseModel):
    id: uuid.UUID
    transaction_type: TransactionType
    title: str
    amount: Decimal
    transaction_date: date
    status: str | None = None
