from fastapi import APIRouter
from app.models.schemas import HealthResponse
from app.controllers.health_controller import HealthController

router = APIRouter()


@router.get("/health", response_model=HealthResponse, summary="Health check")
def health():
    """Returns API status and whether the detection model is ready."""
    return HealthController.get_status()
