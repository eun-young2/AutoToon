# backend/schemas.py
from pydantic import BaseModel, constr, conint
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date


class UserCreate(BaseModel):
    """
    회원가입 요청 시 들어오는 JSON 바디를 검증합니다.
    Flutter에서 JSON으로 아래 필드들을 보낼 때, 최소/최대 길이 등을 자동으로 체크합니다.
    """
    user_id: constr(min_length=1, max_length=100)
    user_name: constr(min_length=1, max_length=100)
    user_nick: constr(min_length=1, max_length=100)
    user_gender: conint(ge=0, le=1)        # 0 또는 1만 허용
    user_age_range: constr(min_length=2, max_length=20)


class UserResponse(BaseModel):
    user_id: str
    user_name: Optional[str]
    user_nick: Optional[str]
    user_gender: Optional[int]
    user_age_range: Optional[str]
    created_at: Optional[datetime]
    credit: int
    correction_tape_item: int
    diary_item: int

    class Config:
        orm_mode = True

class UserUpdateRequest(BaseModel):
    credit: Optional[int] = None
    correction_tape_item: Optional[int] = None
    diary_item: Optional[int] = None

    class Config:
        schema_extra = {
            "example": {
                "credit": 200,
                "correction_tape_item": 3,
                "diary_item": 1
            }
        }

class AttendanceCheckResponse(BaseModel):
    is_new_attendance: bool   # 오늘 처음 출석했는지 여부
    streak: int               # 연속 출석 일수
    reward: int               # 이번 출석으로 받은 크레딧 보상
    total_days: int           # 총 누적 출석 일수
    current_credit: int       # 업데이트된 유저의 전체 크레딧

    class Config:
        orm_mode = True