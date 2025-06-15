# app/models/toon_model.py
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from backend.database import Base
from sqlalchemy.sql import func

class Toon(Base):
    __tablename__ = "tb_toon"

    toon_num    = Column(Integer, primary_key=True, index=True)
    diary_num   = Column(Integer, ForeignKey("tb_diary.diary_num"), nullable=False)
    thumb_path  = Column(String(255), nullable=False)   # ← 추가
    merged_path = Column(String(255), nullable=False)   # ← 추가
    created_at  = Column(DateTime, DateTime(timezone=True), nullable=False, server_default=func.now())

    diary = relationship("Diary", back_populates="toons")
