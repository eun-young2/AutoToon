# app/crud/diary_crud.py
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date
from typing import List, Optional

from backend.models.diary_model import Diary
from backend.models.toon_model import Toon

# ── 1) 일기 생성 ───────────────────────────────────────────────────────
def create_diary(
    db: Session,
    user_id: str,
    content: str,
    style_id: int,
    diary_date: date
) -> Diary:
    """
    1) Diary 객체를 생성해서 DB에 저장
    2) diary_id (diary_num) 반환
    """
    new_diary = Diary(
        user_id=user_id,
        content=content,
        style_id=style_id,
        diary_date=diary_date
    )
    db.add(new_diary)
    db.commit()
    db.refresh(new_diary)
    return new_diary


# ── 2) 일기 상세 조회 ─────────────────────────────────────────────────
def get_diary_by_id(db: Session, diary_id: int) -> Optional[Diary]:
    return db.query(Diary).filter(Diary.diary_num == diary_id).first()


# ── 3) 특정 사용자의 날짜별 일기 조회 (페이징 없이, 특정 날짜만) ────────────
def get_diary_by_user_and_date(db: Session, user_id: str, target_date: date) -> Optional[Diary]:
    return (
        db.query(Diary)
        .filter(Diary.user_id == user_id, Diary.diary_date == target_date)
        .first()
    )


# ── 4) 특정 사용자의 모든 일기 목록 조회 (일자 오름차순) ────────────────────
def get_all_diaries_by_user(db: Session, user_id: str) -> List[Diary]:
    return (
        db.query(Diary)
        .filter(Diary.user_id == user_id)
        .order_by(Diary.diary_date.asc())
        .all()
    )


# ── 5) 일기 수정 ───────────────────────────────────────────────────────
def update_diary(
    db: Session,
    diary_id: int,
    new_content: Optional[str] = None,
    new_style_id: Optional[int] = None
) -> Optional[Diary]:
    diary = db.query(Diary).filter(Diary.diary_num == diary_id).first()
    if not diary:
        return None
    if new_content is not None:
        diary.content = new_content
    if new_style_id is not None:
        diary.style_id = new_style_id
    db.commit()
    db.refresh(diary)
    return diary


# ── 6) 일기 삭제 ───────────────────────────────────────────────────────
def delete_diary(db: Session, diary_id: int) -> bool:
    diary = db.query(Diary).filter(Diary.diary_num == diary_id).first()
    if not diary:
        return False
    # (선택) 관련 tb_toon 레코드를 먼저 삭제하거나, CASCADE 설정이 되어 있다면 생략
    db.query(Toon).filter(Toon.diary_num == diary_id).delete()
    db.delete(diary)
    db.commit()
    return True


# ── 7) tb_toon 테이블에 4컷 이미지 경로 저장 ───────────────────────────────
def create_toon_for_diary(
    db: Session,
    diary_id: int,
    thumb_path: str,
    merged_path: str
) -> Toon:
    """
    - diary_id: tb_diary.diary_num
    - thumb_path: save_generated_images()가 반환한 썸네일 경로
    - merged_path: save_generated_images()가 반환한 병합 이미지 경로
    한 번에 코드 1개 레코드를 tb_toon에 저장 후 반환합니다.
    """
    toon = Toon(
        diary_num   = diary_id,
        thumb_path  = thumb_path,
        merged_path = merged_path
    )
    db.add(toon)
    db.commit()
    db.refresh(toon)
    return toon


# ── 8) 특정 일기에 대한 4컷 이미지 조회 ─────────────────────────────────
def get_toons_by_diary(db: Session, diary_id: int) -> List[Toon]:
    return db.query(Toon).filter(Toon.diary_num == diary_id).order_by(Toon.toon_num.asc()).all()


# ── 9) 달력용: 특정 달(연·월)에서 사용자가 작성한 날짜 목록 조회 ─────────────
def get_diary_dates_by_month(db: Session, user_id: str, year: int, month: int) -> List[date]:
    """
    e.g. year=2025, month=6 (6월)
    결과 예시: [date(2025,6,1), date(2025,6,3), date(2025,6,15), ...]
    """
    rows = (
        db.query(Diary.diary_date)
        .filter(
            Diary.user_id == user_id,
            func.year(Diary.diary_date) == year,
            func.month(Diary.diary_date) == month
        )
        .all()
    )
    # rows는 [(date1,), (date2,), ...] 형태이므로, date만 추출
    return [row[0] for row in rows]


# ── 10) 월별 감정 통계 조회 ─────────────────────────────────────────────
def get_monthly_emotion_stats(
    db: Session, user_id: str, year: int, month: int
) -> List[tuple[str, int]]:
    """
    결과 예시: [("기쁨", 5), ("슬픔", 2), ("우울", 3), ...]
    """
    rows = (
        db.query(Diary.emotion_tag, func.count(Diary.emotion_tag))
        .filter(
            Diary.user_id == user_id,
            func.year(Diary.diary_date) == year,
            func.month(Diary.diary_date) == month
        )
        .group_by(Diary.emotion_tag)
        .all()
    )
    # rows = [("기쁨", 5), ("슬픔", 2), ...]
    return rows
