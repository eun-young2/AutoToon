# tagging_gpt_fastapi.py

from fastapi import FastAPI, APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from transformers import ElectraTokenizer, ElectraForSequenceClassification
import torch
import pickle
from openai import OpenAI
import os
from dotenv import load_dotenv
from databases import Database
from sqlalchemy import Table, Column, Integer, String, MetaData, DateTime, select, text, func, ForeignKey
from datetime import date, datetime
from pathlib import Path

from backend.database import engine_sync, Base, get_db, ASYNC_DATABASE_URL

# ✅ .env에서 OpenAI 키 로드
load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise RuntimeError("환경변수 OPENAI_API_KEY를 설정하세요.")
client = OpenAI(api_key=OPENAI_API_KEY)

# ✅ 모델 경로 설정
BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "koelectra-tagging-model"
LABEL_ENCODER_PATH = MODEL_DIR / "label_binarizer.pkl"

# ─── 데이터베이스(비동기) 연결 ─────────────────────────────
# ASYNC_DATABASE_URL 은 app/db.py 에서 f-string 으로 생성된 URL입니다.
database = Database(ASYNC_DATABASE_URL)
metadata = MetaData()

# ✅ tb_diary 테이블 정의
tb_diary = Table(
    "tb_diary",
    metadata,
    Column("diary_num", Integer, primary_key=True),
    Column("user_id", String(100), ForeignKey("tb_user.user_id"), nullable=False),
    Column("content", String),
    Column("created_at", DateTime, default=datetime.utcnow)
)

# ✅ 테이블 정의
tb_basic_question = Table(
    "tb_basic_question",
    metadata,
    Column("question_num", Integer, primary_key=True),
    Column("question", String),
    Column("created_at", DateTime, default=datetime.utcnow)
)

tb_user = Table(
    "tb_user",
    metadata,
    Column("user_id",       String(100),   primary_key=True),
    Column("user_name",     String(100),   nullable=False),
    Column("user_nick",     String(100),   nullable=False),
    Column("user_gender",   Integer,       nullable=False),
    Column("user_age_range",String(20),    nullable=True),
    Column("created_at",    DateTime,      nullable=False, default=datetime.utcnow),
    Column("credit",        Integer,       nullable=False, default=0),
    Column("correction_tape_item", Integer,nullable=False, default=0),
    Column("diary_item",    Integer,       nullable=False, default=0),
)

# ─── Pydantic 모델 정의 ───────────────────────────────────
class TaggingRequest(BaseModel):
    pass

class UserCheckRequest(BaseModel):
    user_id: str

class UserCheckResponse(BaseModel):
    user_id: str
    status: str        # "new_today" or "existing"
    joined_at: datetime | None

class GenerateQuestionRequest(BaseModel):
    user_id: str

# ✅ 모델 및 토크나이저 불러오기
if MODEL_DIR.is_dir():
    # 로컬 경로에서 직접 불러오기
    model = ElectraForSequenceClassification.from_pretrained(str(MODEL_DIR))
    tokenizer = ElectraTokenizer.from_pretrained(str(MODEL_DIR))
else:
    # (선택) Hugging Face Hub private repo 에서 불러오기 (토큰이 필요함)
    # model = ElectraForSequenceClassification.from_pretrained(
    #     "YOUR_HF_USERNAME/koelectra-tagging-model",
    #     use_auth_token=HF_TOKEN
    # )
    # tokenizer = ElectraTokenizer.from_pretrained(
    #     "YOUR_HF_USERNAME/koelectra-tagging-model",
    #     use_auth_token=HF_TOKEN
    # )
    raise FileNotFoundError(f"Cannot find local model directory: {MODEL_DIR}")

with open(LABEL_ENCODER_PATH, "rb") as f:
    mlb = pickle.load(f)

# ─── 1) APIRouter 생성 및 엔드포인트 정의 ───────────────────────────
router = APIRouter(
    prefix="/tagging",      # 모든 경로가 /tagging/** 로 시작
    tags=["tagging"]
)

@router.get("/show-dbs")
async def show_databases():
    query = text("SHOW DATABASES;")
    rows = await database.fetch_all(query)
    return [row[0] for row in rows]

@router.on_event("startup")
async def startup():
    await database.connect()

@router.on_event("shutdown")
async def shutdown():
    await database.disconnect()

# ✅ 태그 예측 함수
def predict_tags(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding="max_length", max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
        probs = torch.sigmoid(outputs.logits)
        preds = (probs > 0.5).int().numpy()
        return mlb.inverse_transform(preds)[0]  # list of predicted tags

# ✅ GPT API로 질문 생성 함수
def generate_custom_question(base_question, tags):
    tag_text = ", ".join(tags)
    print("📌 GPT 호출 태그:", tag_text, flush=True)

    prompt = f"""
    아래는 사용자 일기에서 감지된 문체/말투/감정 태그입니다: [{tag_text}]
    아래 기본 질문을 이 문체에 맞게 자연스럽게 변형해 주세요.

    기본 질문: {base_question}
    """

    # ✅ OpenAI 객체 생성 (환경 변수에서 API 키 불러옴)
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

    # ✅ ChatCompletion 호출 (신규 방식)
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "당신은 사용자 문체에 맞춰 질문을 리디자인하는 도우미입니다."},
            {"role": "user", "content": prompt}
        ]
    )

    result = response.choices[0].message.content.strip()
    print("📌 GPT 응답:", result, flush=True)
    return result

# ✅ 엔드포인트 정의
@router.post("/generate-question")
async def generate_question(request: GenerateQuestionRequest):

    query_diary = (select(tb_diary.c.content).where(tb_diary.c.user_id == request.user_id).order_by(tb_diary.c.created_at.desc()).limit(2))
    row_diary = await database.fetch_one(query_diary)

    if row_diary is None:
        raise HTTPException(status_code=404, detail="최근 일기가 없습니다.")


    text = row_diary["content"]

    if len(text) < 100:
        raise HTTPException(status_code=400, detail="텍스트 길이가 너무 짧습니다.")
    
    tags = predict_tags(text)
    print("✅ 예측 태그:", tags)

    # ✅ DB에서 기본 질문 가져오기 (예: 첫 번째 질문만 사용)
    query = select(tb_basic_question).order_by(func.rand()).limit(2)
    row = await database.fetch_one(query)

    if row is None:
        raise HTTPException(status_code=404, detail="기본 질문이 없습니다.")

    base_question = row["question"]


    # ✅ GPT로 질문 재작성
    new_question = generate_custom_question(base_question, tags)

    return {
        "predicted_tags": tags,
        "base_question": base_question,
        "customized_question": new_question
    }

# 신규 회원, 기존 회원 분기 로직
@router.post("/check-user-status", response_model=UserCheckResponse)
async def check_user_status(request: UserCheckRequest):

    user_id_to_check = request.user_id

    # 1) 우선, 해당 user_id로 가입한 레코드(가입 시각) 조회
    #    SELECT user_id, created_at
    #    FROM tb_user
    #    WHERE user_id = :user_id_to_check
    query_find = (
        select(tb_user.c.user_id, tb_user.c.created_at)
        .where(tb_user.c.user_id == user_id_to_check)
        .limit(1)
    )

    row = await database.fetch_one(query_find)
    if row is None:
        # 해당 user_id 자체가 DB에 없으면 404로 처리
        raise HTTPException(status_code=404, detail="해당 사용자가 존재하지 않습니다.")

    joined_at: datetime = row["created_at"]

    # 2) joined_at 날짜 부분만 “YYYY-MM-DD” 로 비교
    #    파이썬에서 today_date 계산
    today_date = date.today()

    #     func.date(tb_user.c.created_at) == today_date
    # 대신, 이미 joined_at 을 파이썬 datetime으로 받아 왔으므로
    # joined_at.date() 와 비교해도 무방합니다.
    if joined_at.date() == today_date:
        # 오늘 가입한 회원이므로 “new_today”
        status = "new_today"
    else:
        # 오늘 이전에 가입한 기존 회원
        status = "existing"

    return {
        "user_id": user_id_to_check,
        "status": status,
        "joined_at": joined_at
    }