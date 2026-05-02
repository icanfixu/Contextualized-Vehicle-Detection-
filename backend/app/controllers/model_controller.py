import os
from app.models.schemas import ModelInfoResponse
from app.utils.model_manager import ModelManager

MODEL_PATH = os.getenv("MODEL_PATH", "weights/best.pt")


class ModelController:

    @staticmethod
    def get_info() -> ModelInfoResponse:
        model = ModelManager.get()
        names = ModelManager.class_names()
        return ModelInfoResponse(
            model_path=MODEL_PATH,
            task=model.task,
            class_names=names,
            num_classes=len(names),
            input_size=640,
        )

    @staticmethod
    def get_classes() -> dict[int, str]:
        return ModelManager.class_names()
