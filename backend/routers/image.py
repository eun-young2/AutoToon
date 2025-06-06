# app/routes/image.py

from fastapi import APIRouter, HTTPException

# Colab 전용 함수는 이미 NotImplementedError를 던지도록 수정했으므로, 여기에서 따로 import하지 않아도 됩니다.
# from app.services.colab_sd_service import generate_images_sd21
# from app.utils.image_utils import images_to_base64_list
# from app.schemas.image_schema import GenerateImageRequest, GenerateImageResponse

router = APIRouter(prefix="/generate", tags=["Image Generation"])

@router.post("", status_code=501)
async def generate_image_endpoint():
    """
    로컬에서는 절대 실행되지 않도록, 호출 시 501 Not Implemented만 리턴합니다.
    Colab 환경으로 넘어가서 실제 코랩 노트북(.ipynb) 안에서만 이미지 생성 기능을 쓰세요.
    """
    raise HTTPException(status_code=501, detail="이미지 생성은 Colab 환경에서만 지원됩니다.")
