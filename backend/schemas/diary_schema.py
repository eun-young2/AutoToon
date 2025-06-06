# app/schemas/diary_schema.py
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime

# ── 일기 생성 요청 시 사용 ─────────────────────────────────────────
class DiaryCreateRequest(BaseModel):
    """
    클라이언트 → 서버: 새 일기 생성 요청 시 Body 스키마
    - content: 일기 내용 (문자열)
    - style_id: 사용자가 선택한 스타일 ID (정수)
    - diary_date: 일기 날짜 (YYYY-MM-DD 형식의 date)
    # 이제 emotion_tag, prompt_result 는 클라이언트가 보내지 않습니다.
    """
    content: str
    style_id: int
    diary_date: date
    # 필요하다면 user_id도 추가하세요 (예: 로그인 구현 시)
    user_id: Optional[int] = None  


# ── 일기 수정 요청 시 사용 ─────────────────────────────────────────
class DiaryUpdateRequest(BaseModel):
    """
    클라이언트 → 서버: 일기 부분 수정 요청 시 Body 스키마 (PATCH용)
    - content: (Optional) 수정할 일기 내용
    - style_id: (Optional) 수정할 스타일 ID
    # 감정(emotion_tag)과 prompt_result는 백엔드(GPT 작업)에서 자동으로 채워주므로
    # 사용자가 여기서는 수정하지 않습니다.
    """
    content: Optional[str] = None
    style_id: Optional[int] = None


# ── 일기 조회 시 응답 예시 ─────────────────────────────────────────
class DiaryResponse(BaseModel):
    """
    서버 → 클라이언트: 일기 조회 시 반환하는 스키마
    - diary_num: DB상의 기본 키 ID
    - user_id: 작성자 사용자 ID (정수 짐작)
    - style_id: 선택된 스타일 ID
    - diary_date: 일기 날짜 (YYYY-MM-DD)
    - content: 일기 내용
    - prompt_result: GPT가 생성해 준 4컷 프롬프트 결과
    - emotion_tag: GPT가 분석해 준 감정 태그
    - created_at: DB에 저장된 생성 시각 (Timestamp)
    """
    diary_num: int
    user_id: Optional[int] = None
    style_id: int
    diary_date: date
    content: str
    prompt_result: Optional[str] = None
    emotion_tag: Optional[str] = None
    created_at: datetime
    thumb_path: Optional[str] = None
    merged_path: Optional[str] = None
    toon_num: Optional[int] = None

    model_config = {"from_attributes": True}

# ── 4컷 이미지 URL(또는 경로) 정보 응답 ───────────────────────────
class ToonResponse(BaseModel):
    toon_num: int
    diary_num: int
    image_path: str
    created_at: datetime

    class Config:
        orm_mode = True


# ── 달력용: 작성된 날짜 목록 (yyyy-MM-dd 리스트) ───────────────────
class DiaryDateListResponse(BaseModel):
    dates: List[date]


# ── 월별 감정 통계 응답 예시 ───────────────────────────────────────
class MonthlyEmotionStatsItem(BaseModel):
    emotion_tag: str    # ex. "joy"
    count: int          # 해당 감정 개수
    ratio: float        # 전체 대비 비율 (0.0~1.0)

class MonthlyEmotionStatsResponse(BaseModel):
    year: int
    month: int
    total_count: int    # 해당 월 전체 일기 개수 (감정 태그가 없는 일기를 제외한 합계)
    stats: List[MonthlyEmotionStatsItem]
