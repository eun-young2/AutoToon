# app/crud/style_crud.py

from sqlalchemy.orm import Session
from backend.models.style_model import Style

def get_style_by_id(db: Session, style_id: int) -> Style | None:
    """
    style_id를 기준으로 tb_style 테이블에서 해당 Style 객체를 반환합니다.
    """
    return db.query(Style).filter(Style.style_id == style_id).first()

def update_style_prompt_hint(db: Session, style_id: int, prompt_hint: str) -> Style | None:
    """
    tb_style 테이블의 prompt_hint 컬럼을 새 값으로 갱신하고 갱신된 Style 객체를 반환합니다.
    """
    style = db.query(Style).filter(Style.style_id == style_id).first()
    if not style:
        return None
    style.prompt_hint = prompt_hint
    db.commit()
    db.refresh(style)
    return style
