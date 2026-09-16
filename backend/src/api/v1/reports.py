import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from src.core.dependencies import get_household_member
from src.db.session import get_db
from src.models.household import HouseholdMember
from src.schemas.dashboard import MonthlyReport
from src.services import dashboard_service

router = APIRouter(prefix="/households/{household_id}/reports", tags=["reports"])


@router.get("/monthly", response_model=MonthlyReport)
def get_monthly_report(
    household_id: uuid.UUID,
    year: int = Query(default_factory=lambda: date.today().year),
    month: int = Query(default_factory=lambda: date.today().month, ge=1, le=12),
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> dict:
    return dashboard_service.get_monthly_report(db, household_id, year, month)
