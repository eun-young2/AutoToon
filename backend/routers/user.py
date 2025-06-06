from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from services.user_service import save_kakao_user_to_db
from database import get_db
from models.user import User

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