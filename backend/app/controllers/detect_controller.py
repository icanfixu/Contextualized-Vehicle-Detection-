import io
import os
import tempfile

import cv2
import numpy as np
from fastapi import HTTPException, UploadFile
from PIL import Image

from app.models.schemas import (
    ClassCount,
    DetectionSummary,
    ImageDetectionResponse,
    VideoDetectionResponse,
)
from app.utils.detection_utils import (
    parse_results,
    save_annotated_image,
    save_annotated_video,
)
from app.utils.model_manager import ModelManager

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/bmp"}
ALLOWED_VIDEO_TYPES = {"video/mp4", "video/avi", "video/quicktime", "video/x-msvideo"}
MAX_IMAGE_BYTES = 20 * 1024 * 1024   # 20 MB
MAX_VIDEO_BYTES = 200 * 1024 * 1024  # 200 MB


class DetectController:

    # ── helpers ───────────────────────────────────────────────────────────────

    @staticmethod
    def _validate_image(file: UploadFile, raw: bytes) -> None:
        if file.content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(
                status_code=415,
                detail=f"Unsupported image type '{file.content_type}'. "
                       f"Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}",
            )
        if len(raw) > MAX_IMAGE_BYTES:
            raise HTTPException(status_code=413, detail="Image exceeds 20 MB limit.")

    @staticmethod
    def _decode_image(raw: bytes) -> np.ndarray:
        try:
            return np.array(Image.open(io.BytesIO(raw)).convert("RGB"))
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"Could not decode image: {exc}")

    @staticmethod
    def _run_image_inference(
        np_img: np.ndarray,
        confidence: float,
        iou: float,
        filename: str,
        save_annotated: bool,
    ) -> ImageDetectionResponse:
        img_h, img_w = np_img.shape[:2]
        model        = ModelManager.get()
        class_names  = ModelManager.class_names()

        results = model.predict(source=np_img, conf=confidence, iou=iou, verbose=False)
        dets    = parse_results(results, class_names)
        flat    = dets[0] if dets else []

        annotated_url = None
        if save_annotated and results:
            annotated_url = save_annotated_image(results[0], filename)

        return ImageDetectionResponse(
            filename=filename,
            image_width=img_w,
            image_height=img_h,
            total_detections=len(flat),
            detections=flat,
            annotated_image_url=annotated_url,
        )

    # ── public methods ────────────────────────────────────────────────────────

    @classmethod
    async def detect_image(
        cls,
        file: UploadFile,
        confidence: float,
        iou: float,
        save_annotated: bool,
    ) -> ImageDetectionResponse:
        raw = await file.read()
        cls._validate_image(file, raw)
        np_img = cls._decode_image(raw)
        return cls._run_image_inference(
            np_img, confidence, iou, file.filename or "image.jpg", save_annotated
        )

    @classmethod
    async def detect_batch(
        cls,
        files: list[UploadFile],
        confidence: float,
        iou: float,
        save_annotated: bool,
    ) -> list[ImageDetectionResponse]:
        if len(files) > 10:
            raise HTTPException(status_code=400, detail="Maximum 10 images per batch.")

        responses: list[ImageDetectionResponse] = []
        for file in files:
            raw = await file.read()
            cls._validate_image(file, raw)
            np_img = cls._decode_image(raw)
            responses.append(
                cls._run_image_inference(
                    np_img, confidence, iou, file.filename or "img.jpg", save_annotated
                )
            )
        return responses

    @classmethod
    async def detect_video(
        cls,
        file: UploadFile,
        confidence: float,
        iou: float,
        save_annotated: bool,
        max_frames: int,
    ) -> VideoDetectionResponse:
        if file.content_type not in ALLOWED_VIDEO_TYPES:
            raise HTTPException(
                status_code=415,
                detail=f"Unsupported video type '{file.content_type}'. "
                       f"Allowed: {', '.join(ALLOWED_VIDEO_TYPES)}",
            )

        raw = await file.read()
        if len(raw) > MAX_VIDEO_BYTES:
            raise HTTPException(status_code=413, detail="Video exceeds 200 MB limit.")

        suffix = os.path.splitext(file.filename or "video.mp4")[1] or ".mp4"
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(raw)
            tmp_path = tmp.name

        try:
            cap = cv2.VideoCapture(tmp_path)
            if not cap.isOpened():
                raise HTTPException(status_code=400, detail="Could not open video file.")

            fps         = cap.get(cv2.CAP_PROP_FPS) or 25.0
            model       = ModelManager.get()
            class_names = ModelManager.class_names()
            all_dets:   list[list] = []
            ann_frames: list[np.ndarray] = []
            frame_idx = 0

            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                if max_frames > 0 and frame_idx >= max_frames:
                    break

                results = model.predict(source=frame, conf=confidence, iou=iou, verbose=False)
                dets    = parse_results(results, class_names)
                all_dets.append(dets[0] if dets else [])

                if save_annotated and results:
                    ann_frames.append(results[0].plot())

                frame_idx += 1

            cap.release()
        finally:
            os.unlink(tmp_path)

        annotated_url = None
        if save_annotated and ann_frames:
            annotated_url = save_annotated_video(ann_frames, fps, file.filename or "video.mp4")

        return VideoDetectionResponse(
            filename=file.filename or "video.mp4",
            total_frames=frame_idx,
            fps=fps,
            total_detections=sum(len(f) for f in all_dets),
            detections_per_frame=all_dets,
            annotated_video_url=annotated_url,
        )

    @classmethod
    async def detection_summary(
        cls,
        file: UploadFile,
        confidence: float,
        iou: float,
    ) -> DetectionSummary:
        raw = await file.read()
        cls._validate_image(file, raw)
        np_img = cls._decode_image(raw)

        model       = ModelManager.get()
        class_names = ModelManager.class_names()
        results     = model.predict(source=np_img, conf=confidence, iou=iou, verbose=False)
        flat        = (parse_results(results, class_names)[0] if results else [])

        counts: dict[str, int] = {}
        for d in flat:
            counts[d.label] = counts.get(d.label, 0) + 1

        return DetectionSummary(
            total_detections=len(flat),
            class_counts=[ClassCount(label=k, count=v) for k, v in sorted(counts.items())],
        )
