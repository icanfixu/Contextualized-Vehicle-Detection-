from fastapi import APIRouter
from app.models.schemas import ModelInfoResponse
from app.controllers.model_controller import ModelController

router = APIRouter(prefix="/model", tags=["Model"])


@router.get("/info", response_model=ModelInfoResponse, summary="Model metadata")
def model_info():
    """Class names, task type, input size and more about the loaded YOLOv8 model."""
    return ModelController.get_info()


@router.get("/classes", response_model=dict[int, str], summary="Detectable vehicle classes")
def model_classes():
    """Returns a mapping of class ID → label for every vehicle class the model knows."""
    return ModelController.get_classes()
