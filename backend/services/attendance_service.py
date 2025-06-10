# backend/services/attendance_service.py
from datetime import date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException
from backend.models.attendance import Attendance
from backend.models.user import User

def check_and_reward_attendance(user_id: str, db: Session):
    """
    1) tb_attendance에 오늘(date.today()) 레코드가 있는지 검사
      - 있으면: is_new=False → 기존 streak 조회 후 리턴
      - 없으면: is_new=True → 연속 출석(streak) 계산 → reward 결정 → tb_attendance 삽입 → tb_user.credit 업데이트 → 결과 반환
    """
    today = date.today()

    # 1) 이미 오늘 출석했는지 조회
    existing = db.query(Attendance).filter(
        Attendance.user_id == user_id,
        Attendance.date == today
    ).first()

    # 만약 유저가 존재하지 않는다면 404 에러
    user = db.query(User).filter(User.user_id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    # 2) 오늘 출석 레코드가 이미 존재하는 경우
    if existing:
        # 오늘 이미 출석함: 연속 출석일 계산만 수행하여 리턴
        # 과거 연속 출석일(streak)은 연속해서 date(today-1), date(today-2), ... 로 tb_attendance를 탐색해서 구한다.
        streak = _calculate_streak(user_id, today, db)
        total_days = db.query(func.count()).select_from(Attendance).filter(Attendance.user_id == user_id).scalar() or 0
        return {
            "is_new_attendance": False,
            "streak": streak,
            "reward": 0,
            "total_days": total_days,
            "current_credit": user.credit
        }

    # 3) 오늘 출석 레코드가 없는 경우 → 새로운 출석 처리
    #    (1) 어제 날짜에 출석했는지 확인 → 어제 날짜와 연속이면 streak = 과거 streak + 1, 아니면 1로 초기화
    yesterday = today - timedelta(days=1)
    yesterday_record = db.query(Attendance).filter(
        Attendance.user_id == user_id,
        Attendance.date == yesterday
    ).first()

    if yesterday_record:
        # 어제도 출석했었다면
        streak = _calculate_streak(user_id, yesterday, db) + 1
    else:
        # 어제 안 왔으면 새롭게 1일차
        streak = 1

    # 총 누적 출석 일수
    total_days = db.query(func.count()).select_from(Attendance).filter(Attendance.user_id == user_id).scalar() or 0
    total_days += 1

    # (2) 보상 크레딧 결정 로직
    reward = 10
    if streak == 5:
        reward = 30
    elif streak == 15:
        reward = 60
    elif streak == 30:
        reward = 90

    # (3) tb_attendance 삽입
    new_att = Attendance(user_id=user_id, date=today)
    db.add(new_att)

    # (4) tb_user.credit 업데이트
    user.credit = user.credit + reward

    # 트랜잭션 커밋
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"DB 커밋 실패: {e}")

    # 최신 유저 크레딧을 반영하여 refresh
    db.refresh(user)

    return {
        "is_new_attendance": True,
        "streak": streak,
        "reward": reward,
        "total_days": total_days,
        "current_credit": user.credit
    }


def _calculate_streak(user_id: str, reference_date: date, db: Session) -> int:
    """
    reference_date(예: today 또는 yesterday) 기준으로 '그 날짜까지의 연속 출석일'을 구해준다.
    예: 
      - 만약 reference_date가 2025-06-04이고,
        2025-06-03, 2025-06-02, 2025-06-01 이 모두 tb_attendance에 있다면 → 4 (2025-06-01~06-04 4일)
      - 중간에 하루라도 빠져있으면 끊기므로 그 시점까지 카운트
    """
    streak = 0
    current = reference_date
    while True:
        rec = db.query(Attendance).filter(
            Attendance.user_id == user_id,
            Attendance.date == current
        ).first()
        if rec:
            streak += 1
            # 하루 이전으로 이동
            current = current - timedelta(days=1)
        else:
            break
    return streak
