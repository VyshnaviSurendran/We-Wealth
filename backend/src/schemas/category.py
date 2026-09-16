import uuid

from pydantic import BaseModel, ConfigDict, Field

from src.utils.enums import CategoryType


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    category_type: CategoryType
    is_shared: bool = True


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    is_shared: bool | None = None
    is_active: bool | None = None


class CategoryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    name: str
    category_type: CategoryType
    is_shared: bool
    is_active: bool
