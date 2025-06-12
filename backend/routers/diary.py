# app/routes/diary.py

import random
import asyncio
import json
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse, JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, extract, select
from typing import List, Optional, AsyncGenerator
from datetime import datetime

from backend.database import get_db, SessionLocal
from backend.models.diary_model import Diary
from backend.models.user import User
from backend.models.style_model import Style
from backend.models.toon_model import Toon
from backend.models.tmi_model import TMI

from backend.schemas.diary_schema import (
    DiaryCreateRequest,
    DiaryUpdateRequest,
    DiaryResponse,
    DiaryDateListResponse,
    ToonResponse,
    MonthlyEmotionStatsItem,
    MonthlyEmotionStatsResponse,
)
from backend.services.gpt_service import analyze_emotion_and_generate_prompt
from backend.services.colab_sd_service import request_images_from_model
from backend.utils.image_utils import save_generated_images
from backend.crud.diary_crud import create_toon_for_diary

router = APIRouter(prefix="/diaries", tags=["diaries"])


# ─────────────────────────────────────────────────────────────────────
# 1) 새 일기 생성 + 이미지까지 한 번에 처리 (POST /diaries/)
@router.post(
    "/",
    response_model=DiaryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="새 일기 생성 (텍스트 + 이미지 생성까지 한 번에)",
    description=(
        "새 일기를 생성한 뒤\n"
        "1) GPT 호출 → 감정/프롬프트 생성\n"
        "2) 이미지를 Colab에 요청 → 4컷 생성\n"
        "3) 썸네일(1컷 50%) + 병합 이미지(2×2) 생성\n"
        "4) Toon 테이블에 썸네일·병합 경로 저장\n"
        "5) 최종 응답 반환"
    )
)
def create_diary(
    diary_in: DiaryCreateRequest,
    db: Session = Depends(get_db)
):
    # 1) DB에 일기 저장 (emotion_tag, prompt_result는 이후 업데이트)
    now = datetime.utcnow()
    db_diary = Diary(
        user_id       = diary_in.user_id,
        style_id      = diary_in.style_id,
        diary_date    = diary_in.diary_date,
        content       = diary_in.content,
        created_at    = now,
        emotion_tag   = None,
        prompt_result = None,
        img_count     = 0,
    )
    db.add(db_diary)
    db.commit()
    db.refresh(db_diary)

    # 2) DB에서 사용자 정보 조회 (성별, 나이대)
    user = db.query(User).filter(User.user_id == diary_in.user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="유효하지 않은 user_id")

    # user_gender: 0 → 남자, 1 → 여자
    gender = "boy" if user.user_gender == 0 else "girl"
    age_group = user.user_age_range

    # DB에 저장된 user_age_range를 그대로 사용
    age_group = user.user_age_range

    # 3) DB에서 스타일 정보 조회
    style_record = db.query(Style).filter(Style.style_id == diary_in.style_id).first()
    if not style_record:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="유효하지 않은 style_id")
    # 원하는 style_id → style_name 매핑
    #  2 → "mj painterly"
    #  4 → "toonic 2.5D"
    if diary_in.style_id == 2:
        style_name = "mj painterly"
    elif diary_in.style_id == 4:
        style_name = "toonic 2.5D"
    else:
        # 만약 다른 ID가 들어올 가능성이 있다면 기본값 설정
        style_name = "toonic 2.5D"  # (혹은 임의의 default)

    # 4) GPT 호출 → emotion_tag + 4개 프롬프트 생성
    result_text, emotion_tag, prompts = analyze_emotion_and_generate_prompt(
        content    = diary_in.content,
        gender     = gender,
        age_group  = age_group,
        style_name = style_name
    )

    # 5) DB 업데이트 (emotion_tag, prompt_result)
    db_diary.emotion_tag   = emotion_tag
    db_diary.prompt_result = "\n".join(prompts)
    db.commit()
    db.refresh(db_diary)

    # 6) 이미지 생성 요청 (Colab FastAPI에 /generate로 POST)
    try:
        image_paths = request_images_from_model(
            diary_num   = db_diary.diary_num,                          
            prompts     = prompts,
            style_id    = diary_in.style_id,
            user_id     = str(diary_in.user_id),
            diary_date  = diary_in.diary_date.strftime("%Y-%m-%d")
        )
    except Exception as e:
        # 이미지 생성이 완전히 실패하면 여기로 떨어짐
        # 이 경우에는 “일기/프롬프트 저장까지”는 남아 있지만, 이미지는 없음
        # 필요하면 별도 로깅하거나 client에게 경고를 전달할 수 있음
        print(f"[Warning] create_diary - 이미지 생성 실패: {e}")
        image_paths = []

    thumb_path = None
    merged_path = None
    toon_record = None

    # 7) image_paths가 4개 이상이면 → 썸네일/병합 생성 + Toon 테이블 저장 + img_count 업데이트
    if image_paths and len(image_paths) >= 4:
        try:
            # 7-1) 썸네일(첫 번째 이미지 50%) + 병합(2×2) 생성
            thumb_path, merged_path = save_generated_images(
                image_paths = image_paths,
                diary_date  = db_diary.diary_date.strftime("%Y-%m-%d"),
                user_id     = db_diary.user_id
            )
            # 7-2) Diary 모델에도 thumb_path·merged_path 칼럼이 있으면 저장
            if hasattr(db_diary, "thumb_path"):
                db_diary.thumb_path = thumb_path
            if hasattr(db_diary, "merged_path"):
                db_diary.merged_path = merged_path

            # 7-3) img_count = 1로 세팅 (처음 생성이므로)
            db_diary.img_count = 1

            db.commit()
            db.refresh(db_diary)
        except Exception as e:
            print(f"[Warning] save_generated_images 중 오류: {e}")

        try:
            # 7-4) Toon 테이블에 썸네일+병합 경로 레코드 생성
            toon_record = create_toon_for_diary(
                db          = db,
                diary_id    = db_diary.diary_num,
                thumb_path  = thumb_path,
                merged_path = merged_path
            )
            print(f"[DEBUG] create_toon_for_diary: toon_num={toon_record.toon_num} 저장됨.")
        except Exception as e:
            print(f"[Warning] create_toon_for_diary 중 오류: {e}")

    # 8) 최종 응답: 일기 + GPT 결과 + 이미지 경로 + Toon 레코드 ID + img_count
    response_payload = {
        "diary_num":     db_diary.diary_num,
        "user_id":       db_diary.user_id,
        "style_id":      db_diary.style_id,
        "diary_date":    db_diary.diary_date,
        "content":       db_diary.content,
        "emotion_tag":   db_diary.emotion_tag,
        "prompt_result": db_diary.prompt_result,
        "created_at":    db_diary.created_at,
        "img_count":     db_diary.img_count,
    }

    # (선택) thumb_path·merged_path 칼럼이 Diary 모델에 있으면 응답에 포함
    if thumb_path is not None:
        response_payload["thumb_path"] = thumb_path
    if merged_path is not None:
        response_payload["merged_path"] = merged_path

    # (선택) Toon 레코드가 생성되었다면, toon_num도 같이 넘김
    if toon_record is not None:
        response_payload["toon_num"] = toon_record.toon_num

    return response_payload


# ─────────────────────────────────────────────────────────────────────
# 1) SSE 스트리밍 엔드포인트: 일기 생성 + TMI 스트리밍 + 이미지 생성 최종 응답
@router.post(
    "/stream",
    status_code=status.HTTP_201_CREATED,
    summary="새 일기 생성 + TMI 스트리밍 + 이미지 생성",
    description=(
        "1) 클라이언트가 일기를 보내면 DB에 저장\n"
        "2) GPT 분석으로 emotion_tag, prompts 생성 → DB 업데이트\n"
        "3) 백그라운드에서 이미지 생성 시작 → 완료 시 Toon 테이블에 저장\n"
        "4) 이미지 생성 완료 전까지, 5초 후부터 10초 간격으로 TMI 스트리밍\n"
        "5) 이미지 생성 완료 시점에 `event: image_done` + 최종 경로 JSON 전송\n"
    ),
    response_model=None  # 스트리밍 응답이므로 모델 스키마 없음
)
async def create_diary_with_tmi_stream(
    diary_in: DiaryCreateRequest,
    db: Session = Depends(get_db)
):
    """
    이 함수는 한 번의 HTTP 요청으로 **StreamingResponse**를 반환합니다.
    클라이언트는 이 스트림을 열어두고 TMI(텍스트)와 최종 이미지 URL을 순차적으로 받습니다.
    """
    # ── 1) 기본 일기 저장 & GPT 분석까지 동기적으로 처리 ───────────
    now = datetime.utcnow()
    db_diary = Diary(
        user_id       = diary_in.user_id,
        style_id      = diary_in.style_id,
        diary_date    = diary_in.diary_date,
        content       = diary_in.content,
        created_at    = now,
        emotion_tag   = None,
        prompt_result = None,
        img_count     = 0,
    )
    db.add(db_diary)
    db.commit()
    db.refresh(db_diary)

    # 사용자 & 스타일 조회
    user = db.query(User).filter(User.user_id == diary_in.user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="유효하지 않은 user_id")
    gender = "boy" if user.user_gender == 0 else "girl"
    age_group = user.user_age_range

    style_record = db.query(Style).filter(Style.style_id == diary_in.style_id).first()
    if not style_record:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="유효하지 않은 style_id")

    if diary_in.style_id == 2:
        style_name = "mj painterly"
    elif diary_in.style_id == 4:
        style_name = "toonic 2.5D"
    else:
        style_name = "toonic 2.5D"

    result_text, emotion_tag, prompts = analyze_emotion_and_generate_prompt(
        content    = diary_in.content,
        gender     = gender,
        age_group  = age_group,
        style_name = style_name
    )

    db_diary.emotion_tag   = emotion_tag
    db_diary.prompt_result = "\n".join(prompts)
    db.commit()
    db.refresh(db_diary)

    diary_num = db_diary.diary_num

    # ── 2) 백그라운드에서 이미지 생성 작업을 실행할 Task를 생성 ──────
    async def run_image_generation() -> List[str]:
        """
        1) request_images_from_model 호출 (to_thread로 비동기 래핑)
        2) save_generated_images 호출 → 썸네일, 병합 이미지 생성
        3) DB에 Toon 레코드 삽입 및 Diary.img_count 업데이트
        4) 최종 image_paths 반환
        """
        try:
            # 동기 함수 request_images_from_model은 to_thread로 감싸기
            image_paths: List[str] = await asyncio.to_thread(
                request_images_from_model,
                diary_num,
                prompts,
                diary_in.style_id,
                str(diary_in.user_id),
                diary_in.diary_date.strftime("%Y-%m-%d")
            )
            print(f"[DEBUG] request_images_from_model 성공: {image_paths}", flush=True)
        except Exception as e:
            # SSL 오류 등 네트워크 예외가 발생했을 때
            print(f"[ERROR] request_images_from_model 실패: {e}", flush=True)
            return []
        
        if not image_paths or len(image_paths) < 4:
            print(f"[WARNING] 예상된 4개 이미지보다 적음: {image_paths}", flush=True)
            return []

        # 썸네일/병합 생성 (to_thread 래퍼)
        try:
            thumb_path, merged_path = await asyncio.to_thread(
                save_generated_images,
                image_paths,
                diary_in.diary_date.strftime("%Y-%m-%d"),
                diary_in.user_id
            )
            print(f"[DEBUG] save_generated_images 성공: thumb={thumb_path}, merged={merged_path}", flush=True)
        except Exception as e:
            print(f"[ERROR] save_generated_images 실패: {e}", flush=True)
            return []

        # DB에 Toon 레코드 생성 (동기 세션)
        def sync_save_toon_and_update_diary():
            sync_db = SessionLocal()
            try:
                # Toon 테이블에 레코드 삽입
                new_toon = create_toon_for_diary(
                    db          = sync_db,
                    diary_id    = diary_num,
                    thumb_path  = thumb_path,
                    merged_path = merged_path
                )
                print(f"[DEBUG] Toon 레코드 저장: toon_num={new_toon.toon_num}", flush=True)

                # Diary 테이블에도 img_count만 1 증가 (일기 생성 시점 이후 첫 생성이므로)
                diary_obj = sync_db.query(Diary).filter(Diary.diary_num == diary_num).first()
                diary_obj.img_count = (diary_obj.img_count or 0) + 1
                sync_db.commit()
                print(f"[DEBUG] Diary img_count 업데이트 완료", flush=True)

            finally:
                sync_db.close()

        # 위 동기 저장 작업을 to_thread로 래핑
        await asyncio.to_thread(sync_save_toon_and_update_diary)
        return image_paths

    image_task = asyncio.create_task(run_image_generation())

    # ── 3) StreamingResponse의 제너레이터 정의 ───────────────────────
    async def event_generator() -> AsyncGenerator[str, None]:
        """
        - 이미지 생성 완료 전까지, 먼저 5초 후 안내 메시지 1회
        - 그 뒤로는 10초 간격으로 Random TMI 전송
        - 마지막에 'event: image_done' + JSON 데이터 전송
        """
        # 0) Diary 객체 생성 직후 payload 를 SSE 로 먼저 보낸다
        response_payload = {
            "diary_num":     db_diary.diary_num,
            "user_id":       db_diary.user_id,
            "style_id":      db_diary.style_id,
            "diary_date":    db_diary.diary_date,
            "content":       db_diary.content,
            "emotion_tag":   db_diary.emotion_tag,
            "prompt_result": db_diary.prompt_result,
            "created_at":    db_diary.created_at,
            "img_count":     db_diary.img_count,
            # thumb_path, merged_path, toon_num 도 여기에 포함 가능
        }
        yield f"event: diary_created\ndata: {json.dumps(response_payload, default=str)}\n\n"
        
        # 5-1) 첫 안내 메시지 즉시 전송
        first_msg = "열심히 그림을 그리고 있어요!"
        print(f"[STREAMING TMI] {first_msg}", flush=True)
        yield f"data: {first_msg}\n\n"

        # 5-2) 첫 안내 후 5초 대기
        await asyncio.sleep(5)

        # 5-3) 이미지 생성 완료 전까지, 10초 간격으로 Random TMI 전송
        while not image_task.done():
            sync_db = SessionLocal()
            try:
                total_tmi = sync_db.query(func.count(TMI.tmi_num)).scalar()
                if total_tmi and total_tmi > 0:
                    offset = random.randrange(total_tmi)
                    tmi_obj = sync_db.query(TMI).offset(offset).first()
                    data_str = tmi_obj.contents if tmi_obj else "TMI 없음"
                else:
                    data_str = "TMI 데이터가 없습니다."
            finally:
                sync_db.close()

            print(f"[STREAMING TMI] {data_str}", flush=True)
            yield f"data: {data_str}\n\n"
            await asyncio.sleep(10)

        # 5-4) 이미지 생성 완료 시점 → 최종 JSON 전송
        image_paths: List[str] = await image_task
        if not image_paths:
            image_json = {"cut_paths": []}
        else:
            image_json = {"cut_paths": image_paths}

        print(f"[STREAMING INFO] 이미지 생성 완료: {image_paths}", flush=True)
        # yield f"event: image_done\ndata: {image_json}\n\n"
        yield f"event: image_done\ndata: {json.dumps(image_json)}\n\n"

    # ── 6) StreamingResponse 반환 ───────────────────────────────────
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream"
    )


# ─────────────────────────────────────────────────────────────────────
# (선택) 완료된 이미지 경로를 별도로 조회하는 GET 엔드포인트
#    (이미지는 Toon 테이블에 저장되어 있으므로, 필요하다면 클라이언트가 나중에 호출)
# ─────────────────────────────────────────────────────────────────────
@router.get(
    "/{diary_id}/images",
    response_model=ToonResponse,
    summary="특정 일기의 최종 썸네일/병합 이미지 경로 조회",
    description="이미지 생성이 완료된 뒤, 저장된 thumb_path와 merged_path를 반환합니다."
)
def get_diary_images(diary_id: int, db: Session = Depends(get_db)):
    # Diary가 아니라 Toon 테이블에서 임의로 하나만 꺼내도 되지만,
    # 여기서는 diary_id 기준으로 첫 번째 Toon 레코드를 조회합니다.
    toon_obj = db.query(Toon).filter(Toon.diary_num == diary_id).order_by(Toon.toon_num.asc()).first()
    if not toon_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="아직 이미지가 생성되지 않았습니다.")

    return ToonResponse(
        toon_num   = toon_obj.toon_num,
        diary_num  = toon_obj.diary_num,
        image_path = toon_obj.merged_path,    # merged_path 반환 (또는 thumb_path)
        created_at = toon_obj.created_at
    )


# ─────────────────────────────────────────────────────────────────────
# 2) 모든 일기 조회 (GET /diaries/)
@router.get(
    "/",
    response_model=List[DiaryResponse],
    summary="모든 일기 조회",
    description="DB에 저장된 모든 일기를 생성 시각 내림차순으로 반환합니다.",
)
def read_diaries(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    diaries = (
        db.query(Diary)
        .order_by(Diary.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    result_list = []
    for d in diaries:
        toon_obj = db.query(Toon).filter(Toon.diary_num == d.diary_num).order_by(Toon.toon_num.asc()).first()

        item = {
            "diary_num":     d.diary_num,
            "user_id":       d.user_id,
            "style_id":      d.style_id,
            "diary_date":    d.diary_date,
            "content":       d.content,
            "emotion_tag":   d.emotion_tag,
            "prompt_result": d.prompt_result,
            "created_at":    d.created_at,
            "img_count":     d.img_count,
            "img_count":     d.img_count,
            "thumb_path":    None,
            "merged_path":   None,
            "toon_num":      None,
        }

        if toon_obj:
            item["thumb_path"]  = toon_obj.thumb_path
            item["merged_path"] = toon_obj.merged_path
            item["toon_num"]    = toon_obj.toon_num

        result_list.append(item)
    return result_list

# ─────────────────────────────────────────────────────────────────────
# 특정 유저 + (선택) 특정 날짜 일기 조회  (GET /diaries/user/{user_id})
@router.get(
    "/user/{user_id}",
    response_model=List[DiaryResponse],
    summary="특정 사용자 일기 조회 (날짜 필터 선택)",
    description="""
        - `user_id`로 필터링한 뒤 생성 시각 내림차순으로 반환합니다.  
        - `date`(YYYY-MM-DD)를 쿼리 파라미터로 주면 **그 날짜 일기만** 돌려줍니다.
    """,
)
def read_user_diaries(
    user_id: int,
    date: Optional[str] = None,        # ← YYYY-MM-DD 형식
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    # ── 1) 기본 쿼리 (userId 필터) ─────────────────────────────
    q = (
        db.query(Diary)
          .filter(Diary.user_id == user_id)
    )

    # ── 2) 날짜 파라미터가 넘어오면 YYYY-MM-DD 비교 ──────────
    if date:
        # 문자열 → datetime.date
        try:
            from datetime import datetime
            target = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="date 형식은 YYYY-MM-DD 여야 합니다.")
        
        # Diary.diary_date 가 DateTime 컬럼일 경우, DATE()로 자르고 비교
        q = q.filter(func.date(Diary.diary_date) == target)

    # ── 3) 정렬·페이징 후 조회 ────────────────────────────────
    diaries = (
        q.order_by(Diary.created_at.desc())
         .offset(skip)
         .limit(limit)
         .all()
    )

    # ── 4) Toon 정보까지 포함해 응답 형태 맞추기 ────────────────
    result_list: list[dict] = []
    for d in diaries:
        toon_obj = (
            db.query(Toon)
              .filter(Toon.diary_num == d.diary_num)
              .order_by(Toon.toon_num.asc())
              .first()
        )

        item = {
            "diary_num":     d.diary_num,
            "user_id":       d.user_id,
            "style_id":      d.style_id,
            "diary_date":    d.diary_date,
            "content":       d.content,
            "emotion_tag":   d.emotion_tag,
            "prompt_result": d.prompt_result,
            "created_at":    d.created_at,
            "img_count":     d.img_count,
            "thumb_path":    None,
            "merged_path":   None,
            "toon_num":      None,
        }

        if toon_obj:
            item["thumb_path"]  = toon_obj.thumb_path
            item["merged_path"] = toon_obj.merged_path
            item["toon_num"]    = toon_obj.toon_num

        result_list.append(item)

    def _to_json_safe(obj: dict) -> dict:
        for k in ("diary_date", "created_at"):
            if obj.get(k) is not None:
                obj[k] = obj[k].isoformat()          # date → 문자열
        return obj

    safe_payload = [_to_json_safe(i) for i in result_list]

    return JSONResponse(
        content=safe_payload,
        media_type="application/json; charset=utf-8",
    )

# ─────────────────────────────────────────────────────────────────────
# 6) user_id별: 해당 월에 작성된 날짜 목록 조회
@router.get(
    "/{user_id}/dates/{year}/{month}",
    response_model=DiaryDateListResponse,
    summary="user_id별: 월별 작성된 날짜 목록 조회",
    description="특정 user_id가 지정한 연도·월에 작성한 일기들의 날짜(중복 없이)만 반환합니다.",
)
def get_user_monthly_dates(
    user_id: int, 
    year: int, 
    month: int, 
    db: Session = Depends(get_db)
):
    from sqlalchemy import extract

    # 1) user_id가 존재하는지 확인 (선택 사항)
    # user_exists = db.query(User).filter(User.user_id == user_id).first()
    # if not user_exists:
    #     raise HTTPException(status_code=404, detail="User not found")

    # 2) 해당 user_id, year, month에 작성된 Diary.diary_date를 중복 없이 조회
    rows = (
        db.query(Diary.diary_date)
        .filter(Diary.user_id == user_id)
        .filter(extract("year", Diary.diary_date) == year)
        .filter(extract("month", Diary.diary_date) == month)
        .distinct()
        .order_by(Diary.diary_date.asc())
        .all()
    )
    date_list = [row[0] for row in rows]
    return DiaryDateListResponse(dates=date_list)


# ─────────────────────────────────────────────────────────────────────
# 7) user_id별: 월별 감정 통계 조회
@router.get(
    "/{user_id}/stats/{year}/{month}",
    response_model=MonthlyEmotionStatsResponse,
    summary="user_id별: 월별 감정 통계 조회 (개수 + 비율, 한글→영어 치환)",
    description="특정 user_id가 지정한 연도·월에 작성한 일기들의 감정 통계(개수+비율)를 반환합니다.",
)
def get_user_monthly_emotion_stats(
    user_id: int,
    year: int,
    month: int,
    db: Session = Depends(get_db)
):
    # ── 1) emotion_tag별 개수 조회 ────────────────────────────────────────
    query = (
        db.query(
            Diary.emotion_tag,
            func.count(Diary.diary_num).label("count")
        )
        .filter(Diary.user_id == user_id)
        .filter(extract("year", Diary.diary_date) == year)
        .filter(extract("month", Diary.diary_date) == month)
        .filter(Diary.emotion_tag.isnot(None))  
        .group_by(Diary.emotion_tag)
        .all()
    )

    # 한글 태그 → 영어 태그 매핑 딕셔너리
    KO_TO_EN = {
        "기쁨": "joy",
        "슬픔": "sadness",
        "평온": "calm",
        "설렘": "excitement",
        "짜증": "anger",
    }

    # ── 2) 한글 태그를 영어로 치환하면서 새로운 리스트에 담기 ─────────────────
    #    원본 query 결과는 [("기쁨", 5), ("joy", 2), ...] 형태일 수 있습니다.
    #    만약 이미 영어("joy" 등)라면 그대로 두고, 한글이면 KO_TO_EN로 변환합니다.
    tag_count_list: List[tuple[str, int]] = []
    for raw_tag, cnt in query:
        if raw_tag in KO_TO_EN:
            tag_en = KO_TO_EN[raw_tag]
        else:
            tag_en = raw_tag  # 이미 영어로 저장된 경우
        tag_count_list.append((tag_en, cnt))

    # ── 3) total_count 계산 (모든 감정 태그가 있는 일기 합계) ────────────────
    total_count = sum(cnt for _, cnt in tag_count_list)

    # ── 4) stats_list 생성 (ratio 계산 포함) ───────────────────────────────
    stats_list: List[MonthlyEmotionStatsItem] = []
    for tag_en, cnt in tag_count_list:
        # 전체 일기가 0이면 ratio=0.0 처리
        ratio = int((cnt / total_count) * 100) if total_count > 0 else 0
        stats_list.append(
            MonthlyEmotionStatsItem(
                emotion_tag=tag_en,
                count=cnt,
                ratio=ratio
            )
        )

    # ── 5) 응답 반환 ───────────────────────────────────────────────────────
    return MonthlyEmotionStatsResponse(
        year=year,
        month=month,
        total_count=total_count,
        stats=stats_list
    )


# ─────────────────────────────────────────────────────────────────────
# 3) 특정 일기 조회 (GET /diaries/{diary_id})
@router.get(
    "/{diary_id}",
    response_model=DiaryResponse,
    summary="특정 일기 조회",
    description="ID에 해당하는 일기를 반환합니다. (썸네일/병합 및 toon_num 포함)",
)
def read_diary(diary_id: int, db: Session = Depends(get_db)):
    # 1) 일기 자체 조회
    d = db.query(Diary).filter(Diary.diary_num == diary_id).first()
    if not d:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="일기를 찾을 수 없습니다.")
    
    # 2) tb_toon에서 해당 diary_id의 Toon 레코드가 있는지 조회
    #    (toon이 여러 개일 가능성은 보통 없다고 가정하고 첫 번째만 사용)
    toon_obj = db.query(Toon).filter(Toon.diary_num == diary_id).order_by(Toon.toon_num.asc()).first()

    # 3) 응답 페이로드 조립
    resp = {
        "diary_num":     d.diary_num,
        "user_id":       d.user_id,
        "style_id":      d.style_id,
        "diary_date":    d.diary_date,
        "content":       d.content,
        "emotion_tag":   d.emotion_tag,
        "prompt_result": d.prompt_result,
        "created_at":    d.created_at,
        "thumb_path":    None,
        "merged_path":   None,
        "toon_num":      None,
    }
    if toon_obj:
        resp["thumb_path"]  = toon_obj.thumb_path
        resp["merged_path"] = toon_obj.merged_path
        resp["toon_num"]    = toon_obj.toon_num

    for k in ("diary_date", "created_at"):
        if resp.get(k) is not None:
            resp[k] = resp[k].isoformat()

    return JSONResponse(
        content=resp,
        media_type="application/json; charset=utf-8",
    )



# ─────────────────────────────────────────────────────────────────────
# 4) 일기 부분 수정 + 이미지 재생성까지 한 번에 처리 (PATCH /diaries/{diary_id})
@router.patch(
    "/{diary_id}",
    response_model=DiaryResponse,
    summary="일기 부분 수정 (텍스트 + 이미지 재생성)",
    description="""
        ID에 해당하는 일기를 수정한 뒤, 
        **무조건** GPT를 다시 호출하여 감정/프롬프트 재생성 → 이미지 재생성 → 썸네일/병합 → Toon 테이블 갱신까지 실행합니다.
        (이미지 생성 오류가 나도, 텍스트/감정 태그 업데이트는 반영하고 정상 200 리턴)
    """,
)
def update_diary(
    diary_id: int,
    diary_in: DiaryUpdateRequest,
    db: Session = Depends(get_db),
) -> DiaryResponse:
    # 1) 기존 일기 조회
    db_diary = db.query(Diary).filter(Diary.diary_num == diary_id).first()
    if not db_diary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diary not found")

    # 2) payload에 들어온 값이 있으면 덮어쓰기 (content, style_id)
    if diary_in.content is not None:
        db_diary.content = diary_in.content
    if diary_in.style_id is not None:
        db_diary.style_id = diary_in.style_id

    # 3) 사용자 정보 조회 (gender, age_group)
    user = db.query(User).filter(User.user_id == db_diary.user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    gender = "boy" if user.user_gender == 0 else "girl"
    age_group = user.user_age_range

    # 4) 스타일 정보 조회 (style_name)
    style = db.query(Style).filter(Style.style_id == db_diary.style_id).first()
    if not style:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Style not found")
    # 원하는 style_id → style_name 매핑 (create_diary와 동일)
    if db_diary.style_id == 2:
        style_name = "mj painterly"
    elif db_diary.style_id == 4:
        style_name = "toonic 2.5D"
    else:
        style_name = "toonic 2.5D" 

    # 5) GPT 호출 → emotion_tag, prompts 생성
    result_text, emotion_tag, prompts = analyze_emotion_and_generate_prompt(
        content    = db_diary.content,
        gender     = gender,
        age_group  = age_group,
        style_name = style_name,
    )

    # 6) DB 업데이트 (emotion_tag, prompt_result)
    db_diary.emotion_tag   = emotion_tag
    db_diary.prompt_result = "\n".join(prompts)
    db.commit()
    db.refresh(db_diary)

    # 7) “이미지 생성 → 썸네일/병합 → Toon 저장” 단계에서 문제가 생겨도, 
    #    텍스트 업데이트(감정/프롬프트)만큼은 100% 반영하고 200 리턴해야 한다.
    thumb_path   = None
    merged_path  = None
    toon_num_out = None

    try:
        # 7-1) Colab FastAPI로 이미지 생성 요청
        image_paths: List[str] = request_images_from_model(
            diary_num   = db_diary.diary_num,
            prompts     = prompts,
            style_id    = db_diary.style_id,
            user_id     = str(db_diary.user_id),
            diary_date  = db_diary.diary_date.strftime("%Y-%m-%d"),
        )

        # 7-2) image_paths가 4개 이상이면 → 썸네일/병합 생성 + img_count 증가 + Toon 저장
        if image_paths and len(image_paths) >= 4:
            # (a) 썸네일/병합
            thumb_path, merged_path = save_generated_images(
                image_paths = image_paths,
                diary_date  = db_diary.diary_date.strftime("%Y-%m-%d"),
                user_id     = db_diary.user_id,
            )

            # (b) img_count += 1
            db_diary.img_count = (db_diary.img_count or 0) + 1

            # (c) Toon 레코드를 새 세션으로 생성 (혹은 같은 세션으로 생성해도 무방)
            new_db = SessionLocal()
            try:
                toon_obj = create_toon_for_diary(
                    db          = new_db,
                    diary_id    = db_diary.diary_num,
                    thumb_path  = thumb_path,
                    merged_path = merged_path
                )
                toon_num_out = toon_obj.toon_num
            finally:
                new_db.close()

            # (d) 변경된 img_count와 thumb/merged만 반영하여 main 세션 커밋
            if hasattr(db_diary, "thumb_path"):
                db_diary.thumb_path = thumb_path
            if hasattr(db_diary, "merged_path"):
                db_diary.merged_path = merged_path

            db.commit()
            db.refresh(db_diary)

    except Exception as e:
        # 이미지 생성 또는 저장 과정에서 실패하더라도, 
        # 텍스트/감정 태그 업데이트는 이미 반영된 상태
        print(f"[Warning] update_diary 이미지/Toon 생성 중 예외: {e}")

    # 8) 최종 응답 Payload 작성 (thumb_path, merged_path, toon_num, img_count)
    response_payload = {
        "diary_num":     db_diary.diary_num,
        "user_id":       db_diary.user_id,
        "style_id":      db_diary.style_id,
        "diary_date":    db_diary.diary_date,
        "content":       db_diary.content,
        "emotion_tag":   db_diary.emotion_tag,
        "prompt_result": db_diary.prompt_result,
        "created_at":    db_diary.created_at,
        "img_count":     db_diary.img_count,   # 현재까지 이미지 생성 횟수
        "thumb_path":    thumb_path,
        "merged_path":   merged_path,
        "toon_num":      toon_num_out,
    }
    return response_payload


# ─────────────────────────────────────────────────────────────────────
@router.patch(
    "/{diary_id}/stream",
    summary="일기 수정 + TMI 스트리밍 + 이미지 재생성",
    description=(
        "1) 해당 일기를 수정하고 GPT 재호출 → 감정/프롬프트 업데이트\n"
        "2) 백그라운드에서 이미지 재생성 시작\n"
        "3) 이미 생성이 완료될 때까지 주기적으로 TMI를 스트리밍\n"
        "4) 완료 시 `event: image_done` + 최종 이미지 경로 전송\n"
    ),
    status_code=status.HTTP_200_OK,
    response_model=None  # StreamingResponse 이므로 별도 스키마 없음
)
async def update_diary_with_tmi_stream(
    diary_id: int,
    diary_in: DiaryUpdateRequest,
    db: Session = Depends(get_db)
):
    """
    * 이 엔드포인트는 StreamingResponse를 반환합니다.
    * 클라이언트는 SSE(EventSource) 방식으로 TMI를 받다가, 이미지 생성 완료 시점을 알려주는 이벤트와 이미지를 함께 받습니다.
    """
    # ── 1) 기존 일기 조회 (동기) ───────────────────────────────────
    db_diary = db.query(Diary).filter(Diary.diary_num == diary_id).first()
    if not db_diary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diary not found")

    # ── 2) content, style_id 수정 (동기) ────────────────────────────
    if diary_in.content is not None:
        db_diary.content = diary_in.content
    if diary_in.style_id is not None:
        db_diary.style_id = diary_in.style_id

    # ── 3) 사용자 정보 조회 (gender, age_group) ─────────────────────
    user = db.query(User).filter(User.user_id == db_diary.user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    gender = "boy" if user.user_gender == 0 else "girl"
    age_group = user.user_age_range

    # ── 4) 스타일 정보 조회 (style_name 매핑) ───────────────────────
    style = db.query(Style).filter(Style.style_id == db_diary.style_id).first()
    if not style:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Style not found")
    if db_diary.style_id == 2:
        style_name = "mj painterly"
    elif db_diary.style_id == 4:
        style_name = "toonic 2.5D"
    else:
        style_name = "toonic 2.5D"

    # ── 5) GPT 호출 → emotion_tag + 4개 프롬프트 생성 (동기) ────────────
    result_text, emotion_tag, prompts = analyze_emotion_and_generate_prompt(
        content    = db_diary.content,
        gender     = gender,
        age_group  = age_group,
        style_name = style_name
    )

    # ── 6) DB 업데이트 (emotion_tag, prompt_result) ─────────────────
    db_diary.emotion_tag   = emotion_tag
    db_diary.prompt_result = "\n".join(prompts)
    db.commit()
    db.refresh(db_diary)

    # ── 7) 백그라운드 이미지 재생성 Task 정의 ───────────────────────
    async def run_image_regeneration() -> List[str]:
        """
        1) request_images_from_model 호출 (to_thread로 비동기 래핑)
        2) 4컷 이상 받으면 save_generated_images 호출 (to_thread)
        3) DB에 Toon 레코드 생성 및 Diary img_count/paths 업데이트 (별도 동기 세션)
        4) 최종 image_paths 반환
        """
        try:
            image_paths: List[str] = await asyncio.to_thread(
                request_images_from_model,
                db_diary.diary_num,
                prompts,
                db_diary.style_id,
                str(db_diary.user_id),
                db_diary.diary_date.strftime("%Y-%m-%d")
            )
            print(f"[DEBUG] request_images_from_model 성공: {image_paths}", flush=True)
        except Exception as e:
            print(f"[ERROR] request_images_from_model 실패: {e}", flush=True)
            return []

        if not image_paths or len(image_paths) < 4:
            print(f"[WARNING] 이미지가 4개 미만 생성됨: {image_paths}", flush=True)
            return []

        try:
            thumb, merged = await asyncio.to_thread(
                save_generated_images,
                image_paths,
                db_diary.diary_date.strftime("%Y-%m-%d"),
                db_diary.user_id
            )
            print(f"[DEBUG] save_generated_images 성공: thumb={thumb}, merged={merged}", flush=True)
        except Exception as e:
            print(f"[ERROR] save_generated_images 실패: {e}", flush=True)
            return image_paths

        # 동기 세션으로 DB 저장 작업
        def sync_save_toon_and_update_diary():
            sync_db = SessionLocal()
            try:
                # 3-1) Toon 테이블에 레코드 삽입
                new_toon = create_toon_for_diary(
                    db          = sync_db,
                    diary_id    = db_diary.diary_num,
                    thumb_path  = thumb,
                    merged_path = merged
                )
                print(f"[DEBUG] Toon 레코드 저장: toon_num={new_toon.toon_num}", flush=True)

                # 3-2) Diary 테이블에도 thumb_path, merged_path, img_count 업데이트
                diary_obj = sync_db.query(Diary).filter(Diary.diary_num == db_diary.diary_num).first()
                diar_thumb_attr = hasattr(diary_obj, "thumb_path")
                diar_merged_attr = hasattr(diary_obj, "merged_path")

                if diar_thumb_attr:
                    diary_obj.thumb_path = thumb
                if diar_merged_attr:
                    diary_obj.merged_path = merged

                diary_obj.img_count = (diary_obj.img_count or 0) + 1
                sync_db.commit()
                print(f"[DEBUG] Diary 업데이트 완료: thumb_path, merged_path, img_count", flush=True)

            finally:
                sync_db.close()

        await asyncio.to_thread(sync_save_toon_and_update_diary)
        return image_paths

    image_task = asyncio.create_task(run_image_regeneration())

    # ── 8) StreamingResponse 제너레이터 정의 ───────────────────────
    async def event_generator() -> AsyncGenerator[str, None]:
        """
        * 0~5초 동안 짧은 메시지 1회: "작업 시작 중..."
        * 5~처음 15초(5~15초) 동안 10초 간격 메시지 1~2회
        * 그 이후 10초 간격 TMI 스트리밍
        * 최종 이미지 생성 완료 후 "event: image_done" 전송
        """
        # 1) 즉시 첫 메시지 1회
        first_msg = "열심히 그림을 그리고 있어요!"
        print(f"[STREAMING TMI] {first_msg}", flush=True)
        yield f"data: {first_msg}\n\n"

        # 2) 5초 대기
        await asyncio.sleep(5)

        # 3) 이미지 생성 완료 전까지, 10초 간격으로 TMI 스트리밍
        while not image_task.done():
            # (랜덤 TMI 한 건 조회 로직은 동일)
            sync_db = SessionLocal()
            try:
                total_tmi = sync_db.query(func.count(TMI.tmi_num)).scalar()
                if total_tmi and total_tmi > 0:
                    offset = random.randrange(total_tmi)
                    tmi_obj = sync_db.query(TMI).offset(offset).first()
                    data_str = tmi_obj.contents if tmi_obj else "TMI 없음"
                else:
                    data_str = "TMI 데이터가 없습니다."
            finally:
                sync_db.close()

            print(f"[STREAMING TMI] {data_str}", flush=True)
            yield f"data: {data_str}\n\n"
            await asyncio.sleep(10)

        # 4) 이미지 생성 완료 시점에 최종 JSON 전송
        image_paths: List[str] = await image_task
        if not image_paths:
            image_json = {"cut_paths": []}
        else:
            image_json = {"cut_paths": image_paths}

        print(f"[STREAMING INFO] 이미지 생성 완료: {image_paths}", flush=True)
        yield f"event: image_done\ndata: {image_json}\n\n"

    # ── 9) StreamingResponse 반환 ───────────────────────────────────
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream"
    )

# ─────────────────────────────────────────────────────────────────────
# 추가: 완료된 이미지 경로만 조회하는 GET 엔드포인트
# ─────────────────────────────────────────────────────────────────────
@router.get(
    "/{diary_id}/images",
    response_model=ToonResponse,
    summary="특정 일기의 최종 썸네일/병합 이미지 경로 조회",
    description="이미지 생성이 완료된 뒤, 저장된 thumb_path와 merged_path를 반환합니다."
)
def get_diary_images(diary_id: int, db: Session = Depends(get_db)):
    diary = db.query(Diary).filter(Diary.diary_num == diary_id).first()
    if not diary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diary not found")

    # thumb_path, merged_path가 아직 None이라면 “생성이 안 된 상태”
    if not getattr(diary, "thumb_path", None) or not getattr(diary, "merged_path", None):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="이미지가 아직 생성되지 않았습니다.")

    return ToonResponse(
        toon_num = diary.diary_num,         # Diary PK 대신 식별용으로 리턴
        diary_num = diary.diary_num,
        image_path = diary.merged_path,     # merged_path를 우선 리턴 (원한다면 thumb_path로 교체 가능)
        created_at = diary.created_at       # 이미 생성 시각(일기 생성 시각과 동일)
    )


# ─────────────────────────────────────────────────────────────────────
# 5) 일기 삭제 (DELETE /diaries/{diary_id})
@router.delete(
    "/{diary_id}",
    response_model=dict,
    summary="일기 삭제",
    description="ID에 해당하는 일기를 삭제합니다.",
)
def delete_diary(diary_id: int, db: Session = Depends(get_db)):
    diary = db.query(Diary).filter(Diary.diary_num == diary_id).first()
    if not diary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="일기를 찾을 수 없습니다.")
    db.delete(diary)
    db.commit()
    return {"detail": f"{diary_id}번 일기가 삭제되었습니다."}