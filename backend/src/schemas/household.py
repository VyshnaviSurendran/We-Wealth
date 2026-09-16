import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from src.utils.enums import HouseholdRole, MemberStatus


class HouseholdCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    currency: str = Field(default="INR", min_length=3, max_length=3)
    timezone: str = Field(default="Asia/Kolkata", max_length=64)


class HouseholdUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    currency: str | None = Field(default=None, min_length=3, max_length=3)
    timezone: str | None = Field(default=None, max_length=64)


class HouseholdRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    created_by: uuid.UUID
    currency: str
    timezone: str
    created_at: datetime


class InvitationCreate(BaseModel):
    email: EmailStr


class InvitationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    email: EmailStr
    status: MemberStatus
    created_at: datetime


class HouseholdMemberRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    user_id: uuid.UUID
    role: HouseholdRole
    status: MemberStatus


class HouseholdMemberUpdate(BaseModel):
    role: HouseholdRole | None = None
    status: MemberStatus | None = None
