from fastapi import FastAPI

# FastAPI 인스턴스 생성
app = FastAPI()

# 루트 엔드포인트(GET /) 정의
@app.get("/")
async def root():
    return {"message": "Hello, FastAPI!"}
