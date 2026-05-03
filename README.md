# Bangladesh Traffic Detector 🚗

YOLOv8-powered web app for detecting vehicles and pedestrians in Bangladeshi traffic. Built with FastAPI + vanilla HTML/CSS/JS.

## All Features Included

| Feature | Description |
|---|---|
| ✅ Auth (JWT) | Signup / Login with secure JWT tokens |
| ✅ Detection | Upload image → YOLOv8 → bounding boxes drawn |
| ✅ Confidence slider | Adjust detection threshold (0.10–0.90) |
| ✅ Congestion score | Auto-calculates Low / Moderate / High / Severe |
| ✅ Dashboard | Stats heatmap + recent scans |
| ✅ History | Full detection table with download & delete |
| ✅ Performance | Per-class AP50, Precision, Recall charts |
| ✅ Download | Download annotated result images |

## 11 Classes
bicycle, bus, car, CNG, leguna, manual-van, motor, others, pedestrian, rickshaw, truck

## Project Structure
```
├── main.py            # FastAPI app — all routes & detection logic
├── auth.py            # JWT auth, password hashing
├── models.py          # SQLAlchemy DB models
├── schemas.py         # Pydantic schemas
├── database.py        # DB connection setup
├── best.pt            # YOLOv8 trained weights ← ADD THIS
├── requirements.txt
├── Procfile
├── static/            # Static assets (CSS/JS if any)
├── uploads/           # Saved detection images (auto-created)
└── templates/
    ├── login.html
    ├── signup.html
    ├── dashboard.html
    ├── detect.html
    ├── history.html
    └── performance.html
```

## Local Setup

```bash
# 1. Create virtual environment
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Add your model weights
# Copy best.pt into the project root folder

# 4. Run the app
python main.py

# Open http://localhost:8000
```

## Deploy to Render (Free)

1. Push this repo to GitHub
2. Go to https://render.com → New → Web Service
3. Connect your GitHub repo
4. Set:
   - **Build command:** `pip install -r requirements.txt`
   - **Start command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add environment variable: `SECRET_KEY` → any long random string
6. Upload `best.pt` via Render shell or Git LFS
7. Deploy!

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `SECRET_KEY` | JWT signing secret | hardcoded (change in prod!) |
| `DATABASE_URL` | PostgreSQL URL | SQLite locally |

## Model Info
- Architecture: YOLOv8s  
- Dataset: Bangladeshi traffic (CSE499A)  
- mAP50: 52.4%  
- Classes: 11  
- Epochs: 49  
