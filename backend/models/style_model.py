# app/models/style_model.py

from sqlalchemy import Column, Integer, String, Text
from sqlalchemy.orm import relationship
from backend.database import Base

class Style(Base):
    __tablename__ = "tb_style"

    style_id    = Column("style_id", Integer, primary_key=True, index=True)
    style_name  = Column("style_name", String(50), nullable=False)
    style_key   = Column("style_key", String(20), nullable=False)  # ex) "watercolor"
    prompt_hint = Column("prompt_hint", Text,     nullable=True)

    # Diary와의 관계
    diaries = relationship("Diary", back_populates="style")
