from pydantic import BaseModel
from typing import List, Optional

class GenerateImageRequest(BaseModel):
    """
    /routes/image.py의 엔드포인트에서 받을 요청 바디 스키마
    """
    prompts: List[str]
    num_inference_steps: Optional[int] = 20
    guidance_scale: Optional[float] = 7.5


class GenerateImageResponse(BaseModel):
    """
    이미지 생성 후 반환할 JSON 스키마
    """
    images_base64: List[str]
