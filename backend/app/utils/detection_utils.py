import uuid
import os
import cv2
import numpy as np
from ultralytics.engine.results import Results

from app.models.schemas import Detection, BoundingBox

OUTPUTS_DIR = "outputs"
os.makedirs(OUTPUTS_DIR, exist_ok=True)


def parse_results(results: list[Results], class_names: dict[int, str]) -> list[list[Detection]]:
    """Convert ultralytics Results into our Detection schema, per frame."""
    all_frames: list[list[Detection]] = []

    for result in results:
        frame: list[Detection] = []
        if result.boxes is not None:
            for box in result.boxes:
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                cls_id = int(box.cls[0].item())
                conf   = float(box.conf[0].item())
                frame.append(
                    Detection(
                        label=class_names.get(cls_id, str(cls_id)),
                        class_id=cls_id,
                        confidence=round(conf, 4),
                        bbox=BoundingBox(
                            x1=round(x1, 2), y1=round(y1, 2),
                            x2=round(x2, 2), y2=round(y2, 2),
                            width=round(x2 - x1, 2),
                            height=round(y2 - y1, 2),
                        ),
                    )
                )
        all_frames.append(frame)

    return all_frames


def save_annotated_image(result: Results, original_filename: str) -> str:
    """Draw boxes and save to outputs/. Returns the /outputs/<file> URL."""
    stem     = os.path.splitext(original_filename)[0]
    out_name = f"{stem}_{uuid.uuid4().hex[:8]}.jpg"
    out_path = os.path.join(OUTPUTS_DIR, out_name)
    cv2.imwrite(out_path, result.plot())
    return f"/outputs/{out_name}"


def save_annotated_video(
    frames: list[np.ndarray], fps: float, original_filename: str
) -> str:
    """Write annotated frames to MP4 and return the URL."""
    if not frames:
        raise ValueError("No frames to write.")
    h, w     = frames[0].shape[:2]
    stem     = os.path.splitext(original_filename)[0]
    out_name = f"{stem}_{uuid.uuid4().hex[:8]}.mp4"
    out_path = os.path.join(OUTPUTS_DIR, out_name)
    writer   = cv2.VideoWriter(out_path, cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))
    for frame in frames:
        writer.write(frame)
    writer.release()
    return f"/outputs/{out_name}"
