# schemas/question_schema.py

from pydantic import BaseModel
from datetime import datetime

class QuestionOut(BaseModel):
    question_num: int
    question: str
    created_at: datetime

    class Config:
        orm_mode = True
