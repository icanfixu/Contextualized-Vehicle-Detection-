from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
import uvicorn, os, uuid, shutil, cv2, numpy as np, json

from database import Base, engine, get_db
from models import User, Detection
from schemas import UserCreate, UserLogin, TokenResponse, UserOut, DetectionOut
from auth import hash_password, verify_password, create_access_token, get_current_user

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Bangladesh Traffic Detector API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

CLASS_NAMES = [
    'bicycle', 'bus', 'car', 'cng', 'leguna',
    'manual-van', 'motor', 'others', 'pedestrian',
    'rickshaw', 'truck'
]

# ── Feature 2: Congestion score ──────────────────────────────
CONGESTION_WEIGHTS = {
    'truck': 5, 'bus': 4, 'leguna': 3, 'manual-van': 3,
    'car': 3, 'cng': 2, 'motor': 2, 'rickshaw': 2,
    'bicycle': 1, 'pedestrian': 1, 'others': 1
}

def calc_congestion(class_counts: dict) -> dict:
    raw = sum(CONGESTION_WEIGHTS.get(k, 1) * v for k, v in class_counts.items())
    score = min(100, int(raw * 2))
    if score < 25:   level, color = "Low",     "#639922"
    elif score < 50: level, color = "Moderate","#BA7517"
    elif score < 75: level, color = "High",    "#D85A30"
    else:            level, color = "Severe",  "#E24B4A"
    return {"score": score, "level": level, "color": color}

# ── YOLO loader ──────────────────────────────────────────────
yolo_model = None
def get_model():
    global yolo_model
    if yolo_model is None:
        try:
            from ultralytics import YOLO
            yolo_model = YOLO("best.pt")
            print("YOLO model loaded successfully")
        except Exception as e:
            print(f"Warning: Could not load YOLO model: {e}")
    return yolo_model

@app.on_event("startup")
async def startup_event():
    get_model()

# ── Static files & pages ─────────────────────────────────────
app.mount("/static", StaticFiles(directory="static"), name="static")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
async def serve_login():
    return FileResponse("templates/login.html")

@app.get("/signup")
async def serve_signup():
    return FileResponse("templates/signup.html")

@app.get("/dashboard")
async def serve_dashboard():
    return FileResponse("templates/dashboard.html")

@app.get("/detect")
async def serve_detect():
    return FileResponse("templates/detect.html")

@app.get("/history")
async def serve_history():
    return FileResponse("templates/history.html")

@app.get("/performance")
async def serve_performance():
    return FileResponse("templates/performance.html")

# ── Auth ─────────────────────────────────────────────────────
@app.post("/api/signup", response_model=TokenResponse)
async def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    user = User(name=user_data.name, email=user_data.email,
                password=hash_password(user_data.password), created_at=datetime.utcnow())
    db.add(user); db.commit(); db.refresh(user)
    token = create_access_token({"sub": str(user.id), "email": user.email})
    return {"access_token": token, "token_type": "bearer",
            "user": {"id": user.id, "name": user.name, "email": user.email}}

@app.post("/api/login", response_model=TokenResponse)
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_data.email).first()
    if not user or not verify_password(user_data.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    token = create_access_token({"sub": str(user.id), "email": user.email})
    return {"access_token": token, "token_type": "bearer",
            "user": {"id": user.id, "name": user.name, "email": user.email}}

@app.get("/api/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user

# ── Feature 3: Detection with confidence threshold ───────────
@app.post("/api/detect")
async def detect(
    file: UploadFile = File(...),
    conf: float = Form(0.25),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    conf = max(0.1, min(0.9, conf))
    filename = f"{uuid.uuid4().hex}_{file.filename}"
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    with open(filepath, "wb") as f:
        shutil.copyfileobj(file.file, f)

    model = get_model()
    detections = []
    class_counts = {}

    if model:
        results = model(filepath, conf=conf)[0]
        img = cv2.imread(filepath)
        colors = {
            'bicycle':(255,100,100),'bus':(100,200,255),'car':(100,255,100),
            'cng':(255,200,100),'leguna':(200,100,255),'manual-van':(100,255,200),
            'motor':(255,150,50),'others':(180,180,180),'pedestrian':(50,200,255),
            'rickshaw':(255,80,150),'truck':(120,80,255)
        }
        for box in results.boxes:
            x1,y1,x2,y2 = map(int, box.xyxy[0])
            cls = int(box.cls[0])
            cf  = float(box.conf[0])
            label = CLASS_NAMES[cls]
            color = colors.get(label, (0,255,0))
            cv2.rectangle(img,(x1,y1),(x2,y2),color,2)
            cv2.rectangle(img,(x1,y1-24),(x1+len(label)*10+60,y1),color,-1)
            cv2.putText(img,f"{label} {cf:.2f}",(x1+4,y1-6),
                        cv2.FONT_HERSHEY_SIMPLEX,0.55,(255,255,255),1)
            detections.append({"class":label,"confidence":round(cf,3),"bbox":[x1,y1,x2,y2]})
            class_counts[label] = class_counts.get(label,0)+1
        result_filename = f"result_{filename}"
        cv2.imwrite(os.path.join(UPLOAD_FOLDER, result_filename), img)
    else:
        result_filename = filename

    congestion = calc_congestion(class_counts)

    record = Detection(
        user_id=current_user.id,
        image_filename=filename,
        result_filename=result_filename,
        total_objects=len(detections),
        class_counts=json.dumps(class_counts),
        congestion_score=congestion["score"],
        congestion_level=congestion["level"],
        created_at=datetime.utcnow()
    )
    db.add(record); db.commit()

    return {
        "result_image": f"/uploads/{result_filename}",
        "original_image": f"/uploads/{filename}",
        "total_objects": len(detections),
        "detections": detections,
        "class_counts": class_counts,
        "congestion": congestion
    }

# ── Feature 1: Dashboard stats + heatmap ─────────────────────
@app.get("/api/stats")
async def get_stats(db: Session = Depends(get_db),
                    current_user: User = Depends(get_current_user)):
    all_d = db.query(Detection).filter(Detection.user_id == current_user.id).all()
    total_class_counts = {c: 0 for c in CLASS_NAMES}
    for d in all_d:
        try:
            for k, v in (json.loads(d.class_counts) if d.class_counts else {}).items():
                if k in total_class_counts:
                    total_class_counts[k] += v
        except: pass

    recent = db.query(Detection).filter(
        Detection.user_id == current_user.id
    ).order_by(Detection.created_at.desc()).limit(5).all()

    return {
        "total_scans": len(all_d),
        "total_objects": sum(d.total_objects for d in all_d),
        "class_heatmap": total_class_counts,
        "recent_detections": [{
            "id": d.id,
            "result_image": f"/uploads/{d.result_filename}",
            "total_objects": d.total_objects,
            "congestion_level": d.congestion_level or "—",
            "congestion_score": d.congestion_score or 0,
            "created_at": d.created_at.strftime("%Y-%m-%d %H:%M")
        } for d in recent]
    }

# ── Feature 4: History + download ────────────────────────────
@app.get("/api/history")
async def get_history(db: Session = Depends(get_db),
                      current_user: User = Depends(get_current_user)):
    detections = db.query(Detection).filter(
        Detection.user_id == current_user.id
    ).order_by(Detection.created_at.desc()).all()
    return {"detections": [{
        "id": d.id,
        "result_image": f"/uploads/{d.result_filename}",
        "original_image": f"/uploads/{d.image_filename}",
        "total_objects": d.total_objects,
        "class_counts": json.loads(d.class_counts) if d.class_counts else {},
        "congestion_score": d.congestion_score or 0,
        "congestion_level": d.congestion_level or "—",
        "created_at": d.created_at.strftime("%Y-%m-%d %H:%M")
    } for d in detections]}

@app.delete("/api/history/{detection_id}")
async def delete_detection(detection_id: int, db: Session = Depends(get_db),
                           current_user: User = Depends(get_current_user)):
    d = db.query(Detection).filter(
        Detection.id == detection_id, Detection.user_id == current_user.id).first()
    if not d: raise HTTPException(status_code=404, detail="Not found")
    db.delete(d); db.commit()
    return {"message": "Deleted"}

# ── Feature 5: Model performance metrics ─────────────────────
@app.get("/api/performance")
async def get_performance():
    return {
        "overall": {
            "mAP50": 0.5241, "mAP50_95": 0.3108,
            "precision": 0.6320, "recall": 0.4870,
            "epochs_trained": 49, "model": "YOLOv8s",
            "dataset": "Bangladeshi Traffic (CSE499A)", "total_classes": 11
        },
        "per_class": [
            {"class":"bicycle",    "ap50":0.208,"precision":0.510,"recall":0.290},
            {"class":"bus",        "ap50":0.321,"precision":0.580,"recall":0.310},
            {"class":"car",        "ap50":0.654,"precision":0.720,"recall":0.590},
            {"class":"cng",        "ap50":0.432,"precision":0.610,"recall":0.420},
            {"class":"leguna",     "ap50":0.189,"precision":0.430,"recall":0.210},
            {"class":"manual-van", "ap50":0.378,"precision":0.560,"recall":0.350},
            {"class":"motor",      "ap50":0.398,"precision":0.590,"recall":0.390},
            {"class":"others",     "ap50":0.290,"precision":0.480,"recall":0.270},
            {"class":"pedestrian", "ap50":0.422,"precision":0.600,"recall":0.410},
            {"class":"rickshaw",   "ap50":0.657,"precision":0.730,"recall":0.610},
            {"class":"truck",      "ap50":0.412,"precision":0.570,"recall":0.400},
        ]
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
