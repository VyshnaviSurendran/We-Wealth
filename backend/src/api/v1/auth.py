from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.core.dependencies import get_current_user
from src.db.session import get_db
from src.models.user import User
from src.schemas.auth import ChangePasswordRequest, LoginRequest, RegisterRequest, TokenResponse
from src.schemas.user import UserRead
from src.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserRead, status_code=201)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> User:
    return auth_service.register_user(db, payload)


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = auth_service.authenticate_user(db, payload)
    token = auth_service.build_token_for_user(user)
    return TokenResponse(access_token=token, user=UserRead.model_validate(user))


@router.get("/me", response_model=UserRead)
def get_me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.post("/change-password", status_code=204)
def change_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    auth_service.change_password(db, current_user, payload)
