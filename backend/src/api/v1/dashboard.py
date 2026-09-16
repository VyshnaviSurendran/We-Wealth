import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.core.dependencies import get_household_member
from src.db.session import get_db
from src.models.household import HouseholdMember
from src.schemas.dashboard import DashboardSummary
from src.services import dashboard_service

router = APIRouter(prefix="/households/{household_id}/dashboard", tags=["dashboard"])


@router.get("/summary", response_model=DashboardSummary)
def get_summary(
    household_id: uuid.UUID,
    db: Session = Depends(get_db),
    _member: HouseholdMember = Depends(get_household_member),
) -> dict:
    return dashboard_service.get_dashboard_summary(db, household_id)
