# app/models/diary_model.py

from sqlalchemy import Column, Integer, String, Text, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.database import Base

class Diary(Base):
    __tablename__ = "tb_diary"

    diary_num     = Column("diary_num", Integer, primary_key=True, index=True)
    user_id       = Column("user_id", String(100), ForeignKey("tb_user.user_id"), nullable=False)
    style_id      = Column("style_id", Integer, ForeignKey("tb_style.style_id"), nullable=False)
    diary_date    = Column("diary_date", Date, nullable=False)
    content       = Column("content", Text, nullable=False)
    emotion_tag   = Column("emotion_tag", String(20), nullable=True)
    prompt_result = Column("prompt_result", Text, nullable=True)
    created_at    = Column("created_at", DateTime, nullable=False)
    img_count     = Column("img_count", Integer, nullable=False, default=0)

    toons = relationship("Toon", back_populates="diary", cascade="all, delete-orphan")
    style = relationship("Style", back_populates="diaries") 
    user  = relationship("User",  back_populates="diaries")
