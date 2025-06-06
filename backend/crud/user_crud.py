# app/crud/user_crud.py

from sqlalchemy.orm import Session
from backend.models.user import User


def get_user_by_id(db: Session, user_id: str) -> User | None:
    """
    user_id(pk) 기준으로 tb_user 테이블에서 사용자 정보를 가져옵니다.
    """
    return db.query(User).filter(User.user_id == user_id).first()


def create_user(db: Session, user_data: dict) -> User:
    """
    tb_user 테이블에 신규 사용자 레코드를 생성할 때 사용하는 예시 함수입니다.
    (카카오 프로필 데이터를 받아서 저장할 때 사용할 수 있습니다.)
    """
    new_user = User(
        user_id=user_data["user_id"],
        user_name=user_data.get("user_name", ""),
        user_nick=user_data.get("user_nick", ""),
        user_gender=user_data.get("user_gender"),           # 예: 0 또는 1
        user_age_range=user_data.get("user_age_range"),     # 예: "20~29"
        # created_at는 기본값(datetime.utcnow)이 자동으로 들어갑니다.
        credit=user_data.get("credit", 0),
        correction_tape_item=user_data.get("correction_tape_item", 0),
        diary_item=user_data.get("diary_item", 0),
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user
