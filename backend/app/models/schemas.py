from pydantic import BaseModel, Field
from typing import Optional


# ── Shared primitives ─────────────────────────────────────────────────────────

class BoundingBox(BaseModel):
    x1: float
    y1: float
    x2: float
    y2: float
    width: float
    height: float


class Detection(BaseModel):
    label: str
    class_id: int
    confidence: float = Field(..., ge=0.0, le=1.0)
    bbox: BoundingBox


class ClassCount(BaseModel):
    label: str
    count: int


# ── Response schemas ──────────────────────────────────────────────────────────

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    version: str = "1.0.0"


class ModelInfoResponse(BaseModel):
    model_path: str
    task: str
    class_names: dict[int, str]
    num_classes: int
    input_size: int


class ImageDetectionResponse(BaseModel):
    filename: str
    image_width: int
    image_height: int
    total_detections: int
    detections: list[Detection]
    annotated_image_url: Optional[str] = None


class VideoDetectionResponse(BaseModel):
    filename: str
    total_frames: int
    fps: float
    total_detections: int
    detections_per_frame: list[list[Detection]]
    annotated_video_url: Optional[str] = None


class DetectionSummary(BaseModel):
    total_detections: int
    class_counts: list[ClassCount]
