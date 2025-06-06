from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from dotenv import load_dotenv
import os

# .env 파일에서 환경변수 불러오기
load_dotenv()

# 환경변수에서 DB 접속 정보 읽기
# DB_USER = os.getenv("DB_USER")
# DB_PASSWORD = os.getenv("DB_PASSWORD")
# DB_HOST = os.getenv("DB_HOST")
# DB_PORT = os.getenv("DB_PORT")
# DB_NAME = os.getenv("DB_NAME")

# SQLAlchemy DB 접속 URL 생성
# SQLALCHEMY_DATABASE_URL = (
#     f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
# )

DATABASE_URL = os.getenv("DATABASE_URL")
print("DATABASE_URL:", DATABASE_URL) # 디버깅용 출력
# 엔진 생성 (커넥션 풀 관리)
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # 연결 끊김 방지용 옵션
    pool_recycle=3600,
    echo=False
)

# 세션 클래스 생성 (autocommit, autoflush 설정)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 베이스 클래스 생성 (모델들이 상속받음)
Base = declarative_base()

# Dependency로 사용할 DB 세션 함수
def get_db():
    db = SessionLocal()
    try:
        yield db  # 세션을 yield로 반환 (FastAPI 의존성 주입용)
    finally:
        db.close()  # 요청 종료 시 세션 종료
