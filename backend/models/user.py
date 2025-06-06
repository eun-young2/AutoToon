# app/models/user_model.py

from sqlalchemy import Column, String, Integer, TIMESTAMP
from sqlalchemy.orm import relationship
from backend.database import Base

class User(Base):
    __tablename__ = "tb_user"

    user_id        = Column("user_id", String(100), primary_key=True, index=True)
    user_name      = Column("user_name", String(100), nullable=False)
    user_nick      = Column("user_nick", String(100), nullable=False)
    user_gender    = Column("user_gender", Integer, nullable=False)
    user_age_range = Column("user_age_range", String(20),  nullable=True)
    created_at     = Column("created_at", TIMESTAMP,       nullable=False)
    credit         = Column("credit", Integer, default=0)
    correction_tape_item = Column("correction_tape_item", Integer, default=0)
    diary_item     = Column("diary_item", Integer, default=0)

    # Diary와의 일대다 관계
    diaries = relationship("Diary", back_populates="user")
