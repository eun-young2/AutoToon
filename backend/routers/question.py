# api/question_router.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Any

from crud.question_crud import get_random_question
from backend.database import get_db  # 세션을 생성해 주는 의존성
from backend.schemas.question_schema import QuestionOut  # Pydantic 스키마

router = APIRouter(prefix="/questions", tags=["questions"])

@router.get("/random-one", response_model=QuestionOut)
def read_random_question(db: Session = Depends(get_db)) -> Any:
    """
    GET /questions/random-one
    tb_basic_question 테이블에서 랜덤 질문 1개를 가져와서 리턴
    """
    question_obj = get_random_question(db)
    if not question_obj:
        raise HTTPException(status_code=404, detail="질문이 없습니다.")
    return question_obj
