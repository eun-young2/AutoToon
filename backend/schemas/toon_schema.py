from pydantic import BaseModel
from typing import List
from datetime import date

class ToonCreateRequest(BaseModel):
    diary_num : int            # 일기 번호
    prompts   : List[str]      # 4개의 영어 프롬프트
    style_id     : int         # e.g. "watercolor"
    user_id   : str            # 사용자 ID (문자열 형태)
    diary_date: date           # "YYYY-MM-DD"
