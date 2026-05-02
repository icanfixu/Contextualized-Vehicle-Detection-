# 🚗 Vehicle Detection API

YOLOv8-powered vehicle detection with a clean **MVC architecture**.

---

## Project Structure

```
vehicle-detection-api/
├── app/
│   ├── main.py                        # App factory — wires CORS, static files, views
│   │
│   ├── models/                        # M — data shapes (Pydantic schemas)
│   │   └── schemas.py                 #   BoundingBox, Detection, all response models
│   │
│   ├── controllers/                   # C — business logic (no HTTP, no I/O)
│   │   ├── health_controller.py       #   system status
│   │   ├── model_controller.py        #   model metadata & class list
│   │   └── detect_controller.py       #   image / batch / video / summary logic
│   │
│   ├── views/                         # V — thin HTTP layer (routes only)
│   │   ├── health_view.py             #   GET  /health
│   │   ├── model_view.py              #   GET  /model/info  /model/classes
│   │   └── detect_view.py             #   POST /detect/image /batch /video /summary
│   │
│   └── utils/
│       ├── model_manager.py           # YOLO singleton (load once on startup)
│       └── detection_utils.py         # result parsing, annotated file saving
│
├── weights/
│   └── best.pt                        # ← your trained YOLOv8 weights
├── outputs/                           # annotated images/videos (auto-created)
├── requirements.txt
└── README.md
```

### Layer responsibilities

| Layer | Folder | Rule |
|-------|--------|------|
| **Model** | `models/` | Defines data shapes — no logic, no I/O |
| **Controller** | `controllers/` | All business logic — no FastAPI imports, no HTTP status codes |
| **View** | `views/` | Route declarations only — delegate immediately to a controller |

---

## Setup

```bash
python -m venv venv
source venv/bin/activate       # Windows: venv\Scripts\activate

pip install -r requirements.txt

mkdir -p weights
cp /path/to/best.pt weights/best.pt

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Custom model path:
```bash
MODEL_PATH=runs/detect/train/weights/best.pt uvicorn app.main:app --reload
```

---

## API Routes

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Server + model status |
| `GET` | `/model/info` | Task, class names, input size |
| `GET` | `/model/classes` | `{ 0: "car", 1: "truck", … }` |
| `POST` | `/detect/image` | Single image → detections + annotated URL |
| `POST` | `/detect/batch` | Up to 10 images at once |
| `POST` | `/detect/video` | Frame-by-frame video detection |
| `POST` | `/detect/summary` | Class counts only (no bbox coords) |

All detection routes accept query params:
- `confidence` (default `0.25`) — min confidence to keep a detection
- `iou` (default `0.45`) — NMS IoU threshold
- `save_annotated` (default `true`) — save and return annotated output URL

---

## Interactive Docs

- **Swagger UI** → http://localhost:8000/docs
- **ReDoc**      → http://localhost:8000/redoc

---

## Frontend Example

```js
const form = new FormData();
form.append("file", imageFile);

const res  = await fetch("http://localhost:8000/detect/image?confidence=0.3", {
  method: "POST",
  body: form,
});
const data = await res.json();

// Draw the annotated image
document.querySelector("img").src = `http://localhost:8000${data.annotated_image_url}`;

// Iterate detections
data.detections.forEach(d => {
  console.log(d.label, d.confidence, d.bbox);
});
```
