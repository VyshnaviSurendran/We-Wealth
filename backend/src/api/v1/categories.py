import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.dependencies import (
    get_current_user,
    get_household_member,
    require_household_membership,
)
from src.db.session import get_db
from src.models.category import Category
from src.models.household import HouseholdMember
from src.models.user import User
from src.schemas.category import CategoryCreate, CategoryRead, CategoryUpdate
from src.utils.enums import CategoryType

router = APIRouter(tags=["categories"])


def _get_category_or_404(db: Session, category_id: uuid.UUID) -> Category:
    category = db.get(Category, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    return category


@router.post(
    "/households/{household_id}/categories", response_model=CategoryRead, status_code=201
)
def create_category(
    household_id: uuid.UUID,
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Category:
    category = Category(household_id=household_id, **payload.model_dump())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.get("/households/{household_id}/categories", response_model=list[CategoryRead])
def list_categories(
    household_id: uuid.UUID,
    category_type: CategoryType | None = None,
    is_active: bool | None = None,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[Category]:
    query = db.query(Category).filter(Category.household_id == household_id)
    if category_type is not None:
        query = query.filter(Category.category_type == category_type)
    if is_active is not None:
        query = query.filter(Category.is_active == is_active)
    return query.all()


@router.patch("/categories/{category_id}", response_model=CategoryRead)
def update_category(
    category_id: uuid.UUID,
    payload: CategoryUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Category:
    category = _get_category_or_404(db, category_id)
    require_household_membership(db, current_user.id, category.household_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(category, field, value)
    db.add(category)
    db.commit()
    db.refresh(category)
    return category
