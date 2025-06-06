from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.database import get_db
from backend.models.style_model import Style

router = APIRouter()

@router.get("/list")
def get_all_styles(db: Session = Depends(get_db)):
    return db.query(Style).all()
