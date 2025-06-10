from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.services.user_service import save_kakao_user_to_db
from backend.database import get_db
from backend.models.user import User
from backend.schemas.schemas import UserResponse, UserUpdateRequest, CreditIncrementRequest


router = APIRouter()

@router.post("/users/")
def create_user(kakao_user: dict, db: Session = Depends(get_db)):
    save_kakao_user_to_db(kakao_user, db)
    return {"msg": "user saved"}

@router.get("/users/")
def read_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return users

@router.get("/{user_id}")
def get_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/list")
def get_all_users(db: Session = Depends(get_db)):
    return db.query(User).all()

# ─── 여기에 추가 ─────────────────────────────────────────────
#  GET /users/{user_id} – DB에 저장된 한 명의 정보를 내려줌
@router.get("/users/{user_id}", response_model=UserResponse)
def read_user_by_id(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# ─── 여기서 추가 ────────────────────────────────────────
@router.patch("/users/{user_id}", response_model=UserResponse)
def update_user_credit_and_items(
    user_id: str,
    payload: UserUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    - credit, correction_tape_item, diary_item을 덮어쓸 수 있는 엔드포인트
    - payload에 들어오는 값을 해당 사용자 컬럼에 적용한 뒤, 업데이트된 전체 User 객체를 반환
    """
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 요청 payload에 credit이나 아이템 값이 있으면 덮어쓰기
    if payload.credit is not None:
        user.credit = payload.credit
    if payload.correction_tape_item is not None:
        user.correction_tape_item = payload.correction_tape_item
    if payload.diary_item is not None:
        user.diary_item = payload.diary_item

    try:
        db.commit()
        db.refresh(user)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"DB 업데이트 실패: {e}")

    return user

@router.post(
    "/users/{user_id}/credit",
    response_model=UserResponse,
    summary="특정 사용자의 credit에 amount만큼 더하기",
    description="body에 { amount: int } 만큼 해당 사용자 credit을 증가시킵니다. 증가 후의 업데이트된 User 객체를 반환합니다."
)
def increment_user_credit(
    user_id: str,
    payload: CreditIncrementRequest,
    db: Session = Depends(get_db),
):
    """
    - user_id에 해당하는 사용자를 찾아서, user.credit += payload.amount 한 뒤 저장합니다.
    - 성공 시, 업데이트된 User 객체를 그대로 반환합니다.
    """
    # 1) 존재 여부 확인
    user: User | None = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 2) 음수, 0금액 예외 처리 (선택사항)
    if payload.amount <= 0:
        raise HTTPException(status_code=400, detail="amount must be a positive integer")

    # 3) credit 증가
    user.credit = user.credit + payload.amount

    try:
        db.commit()
        db.refresh(user)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"DB 업데이트 실패: {e}")

    return user

@router.patch("/users/{user_id}", response_model=UserResponse)
def update_user_credit_and_items(
    user_id: str,
    payload: UserUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    - credit, correction_tape_item, diary_item을 덮어쓸 수 있는 엔드포인트
    """
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if payload.credit is not None:
        user.credit = payload.credit
    if payload.correction_tape_item is not None:
        user.correction_tape_item = payload.correction_tape_item
    if payload.diary_item is not None:
        user.diary_item = payload.diary_item

    try:
        db.commit()
        db.refresh(user)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"DB 업데이트 실패: {e}")

    return user