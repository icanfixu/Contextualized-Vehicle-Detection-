import os
from ultralytics import YOLO

MODEL_PATH = os.getenv("MODEL_PATH", "weights/best.pt")


class ModelManager:
    """
    Singleton that owns the YOLO model for the entire app lifetime.
    Loaded once on startup via FastAPI lifespan — never per-request.
    """

    _model: YOLO | None = None

    @classmethod
    def load(cls) -> None:
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(
                f"Model weights not found at '{MODEL_PATH}'. "
                "Set MODEL_PATH or place best.pt inside weights/."
            )
        print(f"[ModelManager] Loading {MODEL_PATH} …")
        cls._model = YOLO(MODEL_PATH)
        print("[ModelManager] Model ready.")

    @classmethod
    def unload(cls) -> None:
        cls._model = None

    @classmethod
    def get(cls) -> YOLO:
        if cls._model is None:
            raise RuntimeError("Model not loaded. Check startup logs.")
        return cls._model

    @classmethod
    def class_names(cls) -> dict[int, str]:
        return cls.get().names   # {0: "car", 1: "truck", …}

    @classmethod
    def is_loaded(cls) -> bool:
        return cls._model is not None
