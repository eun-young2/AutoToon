# crud/question_crud.py

from sqlalchemy.orm import Session
from sqlalchemy import func
from backend.models.question_model import BasicQuestion

def get_random_question(db: Session) -> BasicQuestion | None:
    """
    MySQL의 ORDER BY RAND()를 사용해서 랜덤으로 질문 1개 가져오기
    """
    return (
        db.query(BasicQuestion)
          .order_by(func.rand())  # MySQL의 RAND() 함수 호출
          .limit(1)
          .first()
    )
