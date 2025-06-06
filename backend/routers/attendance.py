# backend/routers/attendance.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from services.attendance_service import check_and_reward_attendance
from database import get_db
from schemas import AttendanceCheckResponse

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.post("/check/{user_id}", response_model=AttendanceCheckResponse)
def attendance_check_endpoint(user_id: str, db: Session = Depends(get_db)):
    """
    - URL 예시: POST /attendance/check/4284707752
    - 헤더나 바디가 아니라 단순 path parameter로 user_id를 넘긴 경우 (인증이 따로 없다면)
    - 실제 운영 환경에서는 JWT나 OAuth 토큰을 받아서 user_id를 추출하는 로직을 넣으시는 것이 안전합니다.
    """
    try:
        result = check_and_reward_attendance(user_id, db)
        return result
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Attendance 처리 중 에러: {e}")
