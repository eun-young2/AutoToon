# models/question_model.py

from sqlalchemy import Column, Integer, String, TIMESTAMP
from backend.database import Base  

class BasicQuestion(Base):
    __tablename__ = "tb_basic_question"

    question_num = Column(Integer, primary_key=True, index=True)
    question     = Column(String(100), nullable=False)
    created_at   = Column(TIMESTAMP, nullable=False)
