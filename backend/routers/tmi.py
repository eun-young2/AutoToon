# app/tmi.py

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from databases import Database
from sqlalchemy import Table, Column, Integer, String, DateTime, MetaData, select, func, create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os

# ─────────────────────────────────────────────────────────────────────────
# 0) DB 설정 (Databases + SQLAlchemy Core)
# ─────────────────────────────────────────────────────────────────────────
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL 환경 변수가 설정되지 않았습니다.")

database = Database(DATABASE_URL)
metadata = MetaData()

# ─────────────────────────────────────────────────────────────────────────
# 1) tb_tmi 테이블 정의 (Core 방식)
# ─────────────────────────────────────────────────────────────────────────
tb_tmi = Table(
    "tb_tmi",
    metadata,
    Column("tmi_num", Integer, primary_key=True, autoincrement=True),
    Column("field",   String(50),  nullable=False),
    Column("contents",String(100), nullable=False),
    Column("created_at", DateTime, default=datetime.now)
)

# ─────────────────────────────────────────────────────────────────────────
# 2) Pydantic 응답 모델
# ─────────────────────────────────────────────────────────────────────────
class TMIDatum(BaseModel):
    tmi_num:    int
    field:      str
    contents:   str

class RandomTMIResponse(BaseModel):
    items: list[TMIDatum]

# ─────────────────────────────────────────────────────────────────────────
# 3) APIRouter 생성
# ─────────────────────────────────────────────────────────────────────────
router = APIRouter(
    prefix="/tmi",
    tags=["tmi"]
)

# ─────────────────────────────────────────────────────────────────────────
# 4) DB 커넥트/해제 이벤트 (필요하면 main.py에 옮겨도 OK)
# ─────────────────────────────────────────────────────────────────────────
@router.on_event("startup")
async def connect_db():
    await database.connect()

@router.on_event("shutdown")
async def disconnect_db():
    await database.disconnect()

# ─────────────────────────────────────────────────────────────────────────
# 5) 랜덤 TMI 목록 조회 엔드포인트
# ─────────────────────────────────────────────────────────────────────────
@router.get("/random", response_model=RandomTMIResponse)
async def get_random_tmi(count: int = 1):
    """
    count: 가져올 랜덤 TMI 개수 (기본=1)
    - 쿼리예시: GET /tmi/random?count=5
    """
    if count < 1 or count > 20:
        # 너무 많은 개수를 요청하지 못하도록 제한(원하는 범위로 수정 가능)
        raise HTTPException(status_code=400, detail="count는 1~20 사이의 값이어야 합니다.")

    query = select(
        tb_tmi.c.tmi_num,
        tb_tmi.c.field,
        tb_tmi.c.contents
    ).order_by(func.rand()).limit(count)

    rows = await database.fetch_all(query)
    # rows: list of Row 객체

    # DB에 레코드가 하나도 없으면 빈 리스트를 반환
    items = [
        TMIDatum(
            tmi_num=row["tmi_num"],
            field=row["field"],
            contents=row["contents"]
        )
        for row in rows
    ]

    return RandomTMIResponse(items=items)
