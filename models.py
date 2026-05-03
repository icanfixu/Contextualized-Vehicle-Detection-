from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    id         = Column(Integer, primary_key=True, index=True)
    name       = Column(String, nullable=False)
    email      = Column(String, unique=True, index=True, nullable=False)
    password   = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    detections = relationship("Detection", back_populates="user")

class Detection(Base):
    __tablename__ = "detections"
    id                = Column(Integer, primary_key=True, index=True)
    user_id           = Column(Integer, ForeignKey("users.id"), nullable=False)
    image_filename    = Column(String, nullable=False)
    result_filename   = Column(String, nullable=False)
    total_objects     = Column(Integer, default=0)
    class_counts      = Column(String, default="{}")
    congestion_score  = Column(Integer, default=0)       # Feature 2
    congestion_level  = Column(String, default="Low")    # Feature 2
    created_at        = Column(DateTime, default=datetime.utcnow)
    user              = relationship("User", back_populates="detections")
