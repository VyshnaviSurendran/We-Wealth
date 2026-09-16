import uuid

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from src.models.account import Account
from src.schemas.account import AccountCreate, AccountUpdate
from src.utils.enums import AccountType


def create_account(db: Session, household_id: uuid.UUID, payload: AccountCreate) -> Account:
    account = Account(
        household_id=household_id,
        owner_user_id=payload.owner_user_id,
        name=payload.name,
        account_type=payload.account_type,
        opening_balance=payload.opening_balance,
        is_shared=payload.is_shared,
    )
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


def list_accounts(
    db: Session,
    household_id: uuid.UUID,
    account_type: AccountType | None = None,
    owner_user_id: uuid.UUID | None = None,
    is_shared: bool | None = None,
    is_active: bool | None = None,
) -> list[Account]:
    query = db.query(Account).filter(Account.household_id == household_id)
    if account_type is not None:
        query = query.filter(Account.account_type == account_type)
    if owner_user_id is not None:
        query = query.filter(Account.owner_user_id == owner_user_id)
    if is_shared is not None:
        query = query.filter(Account.is_shared == is_shared)
    if is_active is not None:
        query = query.filter(Account.is_active == is_active)
    return query.all()


def get_account_or_404(db: Session, account_id: uuid.UUID) -> Account:
    account = db.get(Account, account_id)
    if account is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Account not found")
    return account


def update_account(db: Session, account: Account, payload: AccountUpdate) -> Account:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(account, field, value)
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


def archive_account(db: Session, account: Account) -> Account:
    account.is_active = False
    db.add(account)
    db.commit()
    db.refresh(account)
    return account
