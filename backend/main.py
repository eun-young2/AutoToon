from fastapi import FastAPI, HTTPException, Depends
from fastapi.responses import RedirectResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os
from dotenv import load_dotenv
from sqlalchemy.orm import Session
from database import get_db
from services.user_service import save_kakao_user_to_db
from backend.database import Base, engine_sync
import backend.models.user
import backend.models.style_model
import backend.models.diary_model
import backend.models.toon_model
import backend.models.tmi_model
from backend.routers.diary import router as diary_router
from backend.routers.user import router as user_router
from backend.routers.style import router as style_router
from backend.routers.toon import router as toon_router
from backend.tagging_gpt_fastapi import router as tagging_router
from backend.routers.tmi import router as tmi_router

load_dotenv()
print("💡 KAKAO_REDIRECT_URI =", os.getenv("KAKAO_REDIRECT_URI"))
print("▶ (debug) main.py 로드된 MODEL_SERVER_URL:", os.getenv("MODEL_SERVER_URL"))

# 테이블 생성 (앱이 시작될 때 한 번만)
Base.metadata.create_all(bind=engine_sync)

app = FastAPI()

# CORS 설정 (필요하다면)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

KAKAO_CLIENT_ID = os.getenv("KAKAO_CLIENT_ID")
KAKAO_CLIENT_SECRET = os.getenv("KAKAO_CLIENT_SECRET")
KAKAO_REDIRECT_URI = os.getenv("KAKAO_REDIRECT_URI")

@app.get("/login/kakao")
def login_kakao():
    redirect_url = (
        f"https://kauth.kakao.com/oauth/authorize?"
        f"client_id={KAKAO_CLIENT_ID}"
        f"&redirect_uri={KAKAO_REDIRECT_URI}"
        f"&response_type=code"
    )
    return RedirectResponse(redirect_url)

@app.get("/auth/kakao/callback")
async def kakao_callback(code: str, db: Session = Depends(get_db)):
    token_url = "https://kauth.kakao.com/oauth/token"
    data = {
        "grant_type": "authorization_code",
        "client_id": KAKAO_CLIENT_ID,
        "redirect_uri": KAKAO_REDIRECT_URI,
        "code": code,
    }
    if KAKAO_CLIENT_SECRET:
        data["client_secret"] = KAKAO_CLIENT_SECRET

    async with httpx.AsyncClient() as client:
        token_resp = await client.post(token_url, data=data)
        if token_resp.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to get token")
        token_json = token_resp.json()
        access_token = token_json["access_token"]

        user_info_url = "https://kapi.kakao.com/v2/user/me"
        headers = {"Authorization": f"Bearer {access_token}"}
        user_resp = await client.get(user_info_url, headers=headers)
        user_json = user_resp.json()

    # 사용자 정보 DB 저장 (웹/앱 공통)
    try:
        save_kakao_user_to_db(user_json, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB 저장 실패: {e}")
    
    # 4) Flutter 로 JSON 응답
    # return JSONResponse({
    #     "id":        user_json["id"],
    #     "nickname":  user_json["properties"]["nickname"],
    #     "access_token": access_token
    # })

    # --- [웹 테스트용: 실제 배포시 반드시 삭제!] ---
    # 닉네임을 쿼리 파라미터로 전달하여 Flutter 웹에서 로그인 상태로 인식
    # return RedirectResponse(
    #     url=f"http://10.0.2.2:3000/main?nickname={user_json['properties']['nickname']}"
    # )
    nickname = user_json["properties"]["nickname"]
    
    return RedirectResponse(
        url=f"autotoon://login-success?nickname={nickname}&token={access_token}"
    )

    # --- [앱(모바일)용: 실제 배포시 사용, 위 코드 삭제/주석처리!] ---
    # return RedirectResponse(url="myapp://main")  # 앱 딥링크 등으로 이동 (예시)

app.include_router(diary_router)
app.include_router(
    user_router,
    prefix="/user",
    tags=["User"]
)
app.include_router(
    style_router,
    prefix="/style",
    tags=["Style"]
)
app.include_router(toon_router)    
app.include_router(tagging_router)
app.include_router(tmi_router)

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)