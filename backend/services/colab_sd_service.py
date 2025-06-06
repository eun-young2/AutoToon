# app/services/colab_sd_service.py

import os
from dotenv import load_dotenv
load_dotenv()

import uuid
import requests
import base64
import io
from typing import List
from PIL import Image

from sqlalchemy.orm import Session
from backend.models.style_model import Style
from backend.database import SessionLocal

# ─────────────────────────────────────────────────────────────
#  이 함수는 로컬에서는 “Colab 환경”에만 호출되어야 합니다. 
#  따라서 .env 에 MODEL_SERVER_URL 이 설정되어 있지 않으면 예외를 던집니다.
# ─────────────────────────────────────────────────────────────

MODEL_SERVER_URL = os.getenv("MODEL_SERVER_URL", "").rstrip("/")

def request_images_from_model(
    diary_num: int,
    prompts: List[str],
    style_id: int,
    user_id: str,
    diary_date: str,
) -> List[str]:
    """
    1) diary_num: int         – 로컬 DB에서 받은 일기 PK
    2) prompts: List[str]     – GPT → 4개의 **영문** 프롬프트
    3) style_id: int         – tb_style 테이블의 정수 ID
    4) user_id: str          – 로컬 DB의 user_id (문자열)
    5) diary_date: str       – "YYYY-MM-DD" 형식
    
    반환값: List[str] – 4컷 이미지가 로컬에 저장된 파일 경로 리스트
    """
    # 1) MODEL_SERVER_URL이 없으면 예외
    if not MODEL_SERVER_URL:
        raise NotImplementedError(
            "request_images_from_model: MODEL_SERVER_URL이 설정되지 않았습니다. "
            "이 함수는 Colab 환경에서만 호출해야 합니다."
        )

    # 2) DB에서 style_key 조회 (style_id → Style)
    #    Style 모델에 “style_key” 컬럼(예: "watercolor", "cartoon" 등)이 반드시 있어야 합니다.
    db: Session = SessionLocal()
    style_obj = db.query(Style).filter(Style.style_id == style_id).first()
    db.close()
    if not style_obj:
        raise RuntimeError(f"request_images_from_model: 유효하지 않은 style_id: {style_id}")

    style_key = style_obj.style_key  # 예: "watercolor", "cartoon", ...

    # 3) Colab FastAPI 이미지 생성 서버에 POST 요청
    generate_url = f"{MODEL_SERVER_URL}/generate"
    payload = {
        "diary_num":  diary_num,
        "prompts":    prompts,
        "style_id":   style_id,
        "user_id":    user_id,
        "diary_date": diary_date
    }

    print("[DEBUG] Colab 요청 payload:", payload)
    print(f"[DEBUG] POST to → {generate_url}")

    try:
        response = requests.post(
            generate_url,
            json=payload,
            timeout=(200, 1000),
            verify=False
        )
        response.raise_for_status()
    except Exception as e:
        raise RuntimeError(f"request_images_from_model: 서버 호출 오류 → {e}")

    # 4) 응답 JSON에서 Base64 문자열 리스트 추출
    data = response.json()
    if "images_base64" not in data:
        raise RuntimeError(
            f"request_images_from_model: 응답 형식 오류, 'images_base64' 필드가 없습니다.\n응답 내용: {data}"
        )

    base64_list = data["images_base64"]
    if not isinstance(base64_list, list) or len(base64_list) < 4:
        raise RuntimeError(
            f"request_images_from_model: 'images_base64'가 4개 이상이어야 합니다. 실제 값: {len(base64_list)}"
        )

    # 5) Base64 디코딩 & 로컬 PNG로 저장
    saved_paths: List[str] = []
    tmp_dir = "/tmp/autotoon_images"
    os.makedirs(tmp_dir, exist_ok=True)

    for idx, b64_str in enumerate(base64_list[:4], start=1):
        try:
            img_data = base64.b64decode(b64_str)
            img = Image.open(io.BytesIO(img_data)).convert("RGB")
        except Exception as e:
            print(f"[Warning] Base64 디코딩 실패 (idx={idx}): {e}")
            continue

        filename = f"img_{user_id}_{diary_date.replace('-', '')}_{uuid.uuid4().hex}_{idx}.png"
        file_path = os.path.join(tmp_dir, filename)

        try:
            img.save(file_path, format="PNG")
        except Exception as e:
            print(f"[Warning] 이미지 저장 실패 (idx={idx}, 경로={file_path}): {e}")
            continue

        saved_paths.append(file_path)

    if len(saved_paths) < 4:
        raise RuntimeError("request_images_from_model: 이미지 저장에 실패했습니다. saved_paths 길이 < 4")

    return saved_paths
