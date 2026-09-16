import uuid
from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.core.dependencies import (
    get_current_user,
    get_household_member,
    require_household_membership,
)
from src.db.session import get_db
from src.models.account import Account
from src.models.household import HouseholdMember
from src.models.user import User
from src.schemas.account import AccountCreate, AccountDetailRead, AccountRead, AccountUpdate
from src.schemas.transaction import TransactionRead, TransactionType
from src.services import account_service, balance_service, transaction_service
from src.utils.enums import AccountType

router = APIRouter(tags=["accounts"])


def _to_detail(db: Session, account: Account) -> AccountDetailRead:
    detail = balance_service.get_account_balance_detail(db, account)
    return AccountDetailRead(
        **AccountRead.model_validate(account).model_dump(),
        **detail,
    )


@router.post(
    "/households/{household_id}/accounts", response_model=AccountRead, status_code=201
)
def create_account(
    household_id: uuid.UUID,
    payload: AccountCreate,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> Account:
    return account_service.create_account(db, household_id, payload)


@router.get("/households/{household_id}/accounts", response_model=list[AccountRead])
def list_accounts(
    household_id: uuid.UUID,
    account_type: AccountType | None = None,
    owner_user_id: uuid.UUID | None = None,
    is_shared: bool | None = None,
    is_active: bool | None = None,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> list[Account]:
    return account_service.list_accounts(
        db, household_id, account_type, owner_user_id, is_shared, is_active
    )


@router.get("/accounts/{account_id}", response_model=AccountDetailRead)
def get_account(
    account_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AccountDetailRead:
    account = account_service.get_account_or_404(db, account_id)
    require_household_membership(db, current_user.id, account.household_id)
    return _to_detail(db, account)


@router.patch("/accounts/{account_id}", response_model=AccountRead)
def update_account(
    account_id: uuid.UUID,
    payload: AccountUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Account:
    account = account_service.get_account_or_404(db, account_id)
    require_household_membership(db, current_user.id, account.household_id)
    return account_service.update_account(db, account, payload)


@router.delete("/accounts/{account_id}", response_model=AccountRead)
def archive_account(
    account_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Account:
    account = account_service.get_account_or_404(db, account_id)
    require_household_membership(db, current_user.id, account.household_id)
    return account_service.archive_account(db, account)


@router.get("/accounts/{account_id}/transactions", response_model=list[TransactionRead])
def get_account_transactions(
    account_id: uuid.UUID,
    from_date: date | None = None,
    to_date: date | None = None,
    transaction_type: TransactionType | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[TransactionRead]:
    account = account_service.get_account_or_404(db, account_id)
    require_household_membership(db, current_user.id, account.household_id)
    return transaction_service.get_account_transaction_history(
        db, account_id, from_date, to_date, transaction_type
    )
