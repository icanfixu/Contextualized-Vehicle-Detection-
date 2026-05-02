from fastapi import APIRouter, File, Query, UploadFile
from app.models.schemas import (
    DetectionSummary,
    ImageDetectionResponse,
    VideoDetectionResponse,
)
from app.controllers.detect_controller import DetectController

router = APIRouter(prefix="/detect", tags=["Detection"])


@router.post(
    "/image",
    response_model=ImageDetectionResponse,
    summary="Detect vehicles in a single image",
)
async def detect_image(
    file: UploadFile = File(..., description="JPEG / PNG / WEBP / BMP image"),
    confidence: float = Query(0.25, ge=0.01, le=1.0, description="Min confidence threshold"),
    iou: float       = Query(0.45, ge=0.01, le=1.0, description="NMS IoU threshold"),
    save_annotated: bool = Query(True, description="Return URL of the annotated image"),
):
    """
    Upload a single image and receive bounding-box detections for every
    vehicle found. Set **save_annotated=true** to get a drawable image URL back.
    """
    return await DetectController.detect_image(file, confidence, iou, save_annotated)


@router.post(
    "/batch",
    response_model=list[ImageDetectionResponse],
    summary="Detect vehicles in up to 10 images at once",
)
async def detect_batch(
    files: list[UploadFile] = File(..., description="Up to 10 images"),
    confidence: float = Query(0.25, ge=0.01, le=1.0),
    iou: float        = Query(0.45, ge=0.01, le=1.0),
    save_annotated: bool = Query(True),
):
    """Process multiple images in a single request. Max 10 files per call."""
    return await DetectController.detect_batch(files, confidence, iou, save_annotated)


@router.post(
    "/video",
    response_model=VideoDetectionResponse,
    summary="Detect vehicles in a video",
)
async def detect_video(
    file: UploadFile = File(..., description="MP4 / AVI / MOV video"),
    confidence: float = Query(0.25, ge=0.01, le=1.0),
    iou: float        = Query(0.45, ge=0.01, le=1.0),
    save_annotated: bool = Query(True, description="Save annotated video and return URL"),
    max_frames: int   = Query(0, ge=0, description="Max frames to process (0 = all)"),
):
    """
    Upload a video and receive per-frame detections.
    Use **max_frames** to limit processing for quick previews.
    """
    return await DetectController.detect_video(
        file, confidence, iou, save_annotated, max_frames
    )


@router.post(
    "/summary",
    response_model=DetectionSummary,
    summary="Vehicle count summary (no coordinates)",
)
async def detect_summary(
    file: UploadFile = File(...),
    confidence: float = Query(0.25, ge=0.01, le=1.0),
    iou: float        = Query(0.45, ge=0.01, le=1.0),
):
    """
    Lightweight endpoint — returns only total detections and per-class counts.
    No bounding boxes, no annotated image. Ideal for dashboards.
    """
    return await DetectController.detection_summary(file, confidence, iou)
