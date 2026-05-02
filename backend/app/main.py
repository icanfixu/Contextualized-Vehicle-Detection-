import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.utils.model_manager import ModelManager
from app.views import detect_view, health_view, model_view


# ── Lifespan: load model once, release on shutdown ────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    ModelManager.load()
    yield
    ModelManager.unload()


# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Vehicle Detection API",
    description="YOLOv8-powered vehicle detection — upload images or videos, get annotated results.",
    version="1.0.0",
    lifespan=lifespan,
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten to your front-end origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Static outputs (annotated images / videos) ────────────────────────────────
os.makedirs("outputs", exist_ok=True)
app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")

# ── Views (routers) ───────────────────────────────────────────────────────────
app.include_router(health_view.router,  tags=["Health"])
app.include_router(model_view.router)
app.include_router(detect_view.router)
