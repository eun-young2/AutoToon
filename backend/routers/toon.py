# app/routes/toon.py

from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session
from sqlalchemy import select
import asyncio

from backend.database import get_async_db, get_db  # get_db는 read_toon 용
from backend.schemas.toon_schema import ToonCreateRequest
from backend.models.toon_model import Toon
from backend.models.diary_model import Diary
from backend.services.colab_sd_service import request_images_from_model
from backend.utils.image_utils import save_generated_images

router = APIRouter(prefix="/toon", tags=["Toon"])

# ───────────────────────────────────────────────────────────────
# 1) 4컷 + 썸네일 + 병합 생성 & DB 저장
@router.post(
    "/add",
    status_code=status.HTTP_201_CREATED,
    summary="4컷·썸네일·병합 이미지 생성 및 저장"
)
async def create_toon(
    payload: ToonCreateRequest,
    db: AsyncSession = Depends(get_async_db)
):
    """
    1) payload 파싱
    2) diary_num 유효성 검사 (비동기 조회)
    3) Colab 서버에 4컷 이미지 요청 (여기서는 동기 함수라고 가정)
       → 만약 request_images_from_model이 매우 CPU/IO 바운드라면,
         asyncio.to_thread()나 run_in_threadpool()을 사용하세요.
    4) save_generated_images 실행 (마찬가지로 동기 함수라면 asyncio.to_thread로 래핑)
    5) AsyncSession 으로 tb_toon에 INSERT & commit
    6) 결과 반환
    """

    diary_num  = payload.diary_num
    prompts    = payload.prompts
    style_id   = payload.style_id
    user_id    = payload.user_id
    diary_date = payload.diary_date  # pydantic이 date 객체로 파싱

    # ── 1) diary_num 유효성 검사 (비동기) ──────────────────────────
    result = await db.execute(
        select(Diary).where(Diary.diary_num == diary_num)
    )
    diary_obj = result.scalars().first()
    if not diary_obj:
        raise HTTPException(status_code=404, detail="Invalid diary_num")

    # ── 2) Colab FastAPI 서버에 4컷 이미지 생성 요청 ───────────────
    try:
        # 만약 request_images_from_model이 동기 함수라면, 아래처럼 to_thread로 호출하세요:
        cut_paths: List[str] = await asyncio.to_thread(
            request_images_from_model,
            diary_num,
            prompts,
            style_id,
            user_id,
            diary_date.isoformat()
        )
        # 만약 이미 비동기 함수라면 그냥: cut_paths = await request_images_from_model(...)
    except NotImplementedError as nie:
        raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=str(nie))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Image generation failed: {e}")

    if len(cut_paths) < 4:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Expected 4 images, got {len(cut_paths)}"
        )

    # ── 3) 썸네일 & 병합 이미지 생성 (동기 함수라면 to_thread 감싸기) ─────
    try:
        thumb_path, merged_path = await asyncio.to_thread(
            save_generated_images,
            cut_paths,
            diary_date,
            user_id
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Thumbnail/merged generation failed: {e}")

    # ── 4) tb_toon에 INSERT & commit (비동기) ──────────────────────
    new_toon = Toon(
        diary_num   = diary_num,
        thumb_path  = thumb_path,
        merged_path = merged_path,
        created_at  = datetime.utcnow()
    )
    db.add(new_toon)
    try:
        await db.commit()
        await db.refresh(new_toon)
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Toon DB 저장 실패: {e}")

    # ── 5) 응답으로 저장된 toon_num, 썸네일/병합 경로, 생성 시각, cut_paths 반환 ─────
    return {
        "toon_num":    new_toon.toon_num,
        "diary_num":   diary_num,
        "thumb_path":  thumb_path,
        "merged_path": merged_path,
        "created_at":  new_toon.created_at,
        "cut_paths":   cut_paths
    }


# ───────────────────────────────────────────────────────────────
# 2) diary_num 으로 Toon 조회 (동기 DB 세션 사용)
@router.get(
    "/{diary_num}",
    summary="diary_num 으로 Toon 조회",
    response_model=List[str]
)
def read_toon(diary_num: int, db_sync = Depends(get_db)):
    """
    1) 로컬(동기) 세션에서 tb_toon 테이블 조회
    2) 해당 diary_num의 썸네일·병합 경로를 리스트로 반환
    """
    # get_db로 받은 세션이 Session 타입이므로, orm 방식으로 조회
    toon_obj = db_sync.query(Toon).filter(Toon.diary_num == diary_num).first()
    if not toon_obj:
        raise HTTPException(status_code=404, detail="Toon not found")

    return [toon_obj.thumb_path, toon_obj.merged_path]
