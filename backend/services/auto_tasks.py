# app/services/auto_tasks.py

import os
import base64
import tempfile
import requests

from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend.crud.user_crud import get_user_by_id
from backend.crud.diary_crud import create_toon_records
from backend.crud.style_crud import get_style_by_id, update_style_prompt_hint
from backend.models.diary_model import Diary
from backend.services.gpt_service import analyze_emotion_and_generate_prompt
from dotenv import load_dotenv

load_dotenv()  # .env의 MODEL_SERVER_URL 등을 로드

def generate_emotion_and_image_and_save(
    diary_id: int,
    user_id: str,
    content: str,
    style_id: int,
):
    """
    1) TB_DIARY에서 diary 레코드 조회
    2) TB_USER에서 user_gender, user_age_range 조회
    3) GPT 호출 → (result, emotion_tag, prompt_list) 반환
    4) TB_DIARY.emotion_tag 업데이트
    5) TB_STYLE.prompt_hint = result 로 업데이트
    6) 외부 모델 서버에 prompt_list 보내서 4장 이미지(base64) 받기
    7) base64를 파일로 디코딩→저장 후 tb_toon에 저장
    """

    db: Session = SessionLocal()
    try:
        # (1) diary 레코드 조회
        diary: Diary = db.query(Diary).filter(Diary.diary_num == diary_id).first()
        if not diary:
            print(f"[Warning] Diary ID {diary_id}를 찾을 수 없습니다.")
            return

        # (2) 사용자 정보 조회
        user = get_user_by_id(db, user_id)
        if not user:
            print(f"[Warning] User ID {user_id}를 찾을 수 없습니다.")
            return

        # (3) GPT 호출: result(요약+프롬프트 합친 원본), emotion_tag, prompts(4개 영어 프롬프트 리스트) 반환
        #    gender는 "남성"/"여성", age_group은 "20대" 등의 문자열로 넘긴다고 가정
        gender = "남성" if user.user_gender == 1 else "여성"
        age_group = user.user_age_range or "알 수 없음"

        # 스타일 이름 조회: 우선 해당 style_id로 Style 객체를 가져옴
        style_obj = get_style_by_id(db, style_id)
        if not style_obj:
            print(f"[Warning] Style ID {style_id}를 찾을 수 없습니다.")
            return
        style_name = style_obj.style_name  # 예: "watercolor", "painterly", ...

        result, emotion_tag, prompt_list = analyze_emotion_and_generate_prompt(
            content=content,
            gender=gender,
            age_group=age_group,
            style_name=style_name
        )

        # (4) TB_DIARY 업데이트: emotion_tag만 저장
        diary.emotion_tag = emotion_tag or "평온"  # None일 경우 기본값 "평온"
        db.commit()
        db.refresh(diary)

        # (5) TB_STYLE.prompt_hint 업데이트: result(원본) 전체를 prompt_hint에 저장
        updated_style = update_style_prompt_hint(db, style_id, result)
        if not updated_style:
            print(f"[Error] Style ID {style_id}의 prompt_hint 업데이트에 실패했습니다.")
        # 만약 diary.prompt_result 컬럼에도 남기고 싶다면, 아래 두 줄을 추가:
        # diary.prompt_result = result
        # db.commit()

        # (6) 외부 모델 서버 호출
        MODEL_SERVER_URL = os.getenv("MODEL_SERVER_URL")
        if not MODEL_SERVER_URL:
            print("[Error] MODEL_SERVER_URL이 설정되지 않았습니다.")
            return

        payload = {
            "prompts": prompt_list,
            "style": style_name,   # 예: "watercolor", "painterly" 등
            "user_id": user_id,
            "diary_date": str(diary.diary_date)  # "YYYY-MM-DD"
        }

        try:
            res = requests.post(
                f"{MODEL_SERVER_URL}/generate",
                json=payload,
                timeout=(200, 1000)
            )
            res.raise_for_status()
        except Exception as exc:
            print(f"[Error] 모델 서버 호출 실패: {exc}")
            return

        data = res.json()
        images_b64 = data.get("images_base64", [])
        if len(images_b64) < 4:
            print(f"[Warning] base64 이미지 4개를 받지 못했습니다: {images_b64}")
            return

        # (7) base64 디코딩→파일 저장 → tb_toon에 경로 저장
        saved_paths = []
        for idx, img_b64 in enumerate(images_b64[:4], start=1):
            temp_dir = tempfile.gettempdir()
            filename = f"{user_id}_{diary.diary_date}_{idx}.png"
            file_path = os.path.join(temp_dir, filename)
            try:
                image_bytes = base64.b64decode(img_b64)
                with open(file_path, "wb") as f:
                    f.write(image_bytes)
                saved_paths.append(file_path)
            except Exception as e:
                print(f"[Error] base64 디코딩 또는 파일 저장 실패 ({filename}): {e}")

        if saved_paths:
            create_toon_records(db, diary_id=diary_id, image_paths=saved_paths)

    finally:
        db.close()