from app.models.schemas import HealthResponse
from app.utils.model_manager import ModelManager


class HealthController:

    @staticmethod
    def get_status() -> HealthResponse:
        return HealthResponse(
            status="ok",
            model_loaded=ModelManager.is_loaded(),
        )
