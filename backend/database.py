import os
from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from dotenv import load_dotenv
from fastapi import Depends
from pathlib import Path

# .env 파일에서 환경변수 불러오기
load_dotenv()

# 환경변수에서 DB 접속 정보 읽기
DB_USER     = os.getenv("DB_USER")  
DB_PASSWORD = os.getenv("DB_PASSWORD") 
DB_HOST     = os.getenv("DB_HOST") 
DB_PORT     = os.getenv("DB_PORT") 
DB_NAME     = os.getenv("DB_NAME") 

SYNC_DATABASE_URL = (
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@"
    f"{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"
)

ASYNC_DATABASE_URL = (
    f"mysql+aiomysql://{DB_USER}:{DB_PASSWORD}@"
    f"{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"
)

# ─────────── 동기 엔진 및 세션 생성 ───────────
engine_sync = create_engine(
    SYNC_DATABASE_URL,
    echo=True,
    future=True,
)
SessionLocal = sessionmaker(
    bind=engine_sync,
    autoflush=False,
    autocommit=False,
)

# ─────────── 비동기 엔진 및 세션 생성 ───────────
engine_async = create_async_engine(
    ASYNC_DATABASE_URL,
    echo=True,
    future=True,
)
AsyncSessionLocal = sessionmaker(
    bind=engine_async,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)

# 베이스 클래스 생성 (모델들이 상속받음)
Base = declarative_base()


# ────────────────── 동기 DB 세션 종속성 ──────────────────
def get_db():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ────────────────── 비동기 DB 세션 종속성 ──────────────────
async def get_async_db():
    """
    비동기 방식(async/await)으로 DB 작업을 처리할 때 주입하는 세션.
    FastAPI 라우터에 Depends(get_async_db)로 사용.
    """
    async with AsyncSessionLocal() as session:
        yield session