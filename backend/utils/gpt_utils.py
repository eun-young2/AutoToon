# app/utils/gpt_utils.py

import os
import json
import openai
from dotenv import load_dotenv

# .env 파일을 로드하여 OPENAI_API_KEY 환경 변수를 불러옵니다.
load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")


def get_emotion_and_image_prompts(
    content: str,
    user_gender: int | None,
    user_age_range: str | None
) -> tuple[str, list[str]]:
    """
    GPT API를 호출하여
    1) 대표 감정을 '기쁨', '설렘', '평온', '슬픔', '짜증' 중 하나로 분류하고,
    2) 4컷 이미지를 생성하기 위한 영어 프롬프트 4개를 리스트로 반환합니다.

    반환값: (emotion_tag, prompt_list)
    """

    # 시스템 메시지: GPT가 맡을 역할과 분류 범위를 명확히 합니다.
    system_message = (
        "당신은 감정 분석 및 이미지 프롬프트 생성 전문가입니다. "
        "아래 일기 내용을 보고, 대표 감정을 '기쁨', '설렘', '평온', '슬픔', '짜증' 중 하나로 분류해주세요. "
        "그리고 4컷 이미지를 생성하기 위한 영어 프롬프트 4개를 JSON 형식으로 반환해주세요."
    )

    # 사용자 메시지: 일기 내용, 사용자 성별, 나이대 정보를 함께 전달하며,
    # JSON으로 응답하도록 요청합니다.
    user_message = f"""
사용자 성별: {('남성' if user_gender == 1 else '여성') if user_gender is not None else '알 수 없음'}
사용자 나이대: {user_age_range or '알 수 없음'}
일기 내용:
\"\"\"{content}\"\"\"

위 정보를 바탕으로 아래 형식(JSON)으로 응답해 주세요:
{{
    "emotion_tag": "<기쁨/설렘/평온/슬픔/짜증 중 하나>",
    "prompts": [
        "영어 프롬프트 1",
        "영어 프롬프트 2",
        "영어 프롬프트 3",
        "영어 프롬프트 4"
    ]
}}
"""

    # ChatCompletion API 호출
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4-mini",
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user",   "content": user_message}
            ],
            temperature=0.7,
            max_tokens=500,
            n=1
        )
    except Exception as e:
        print(f"[Error] GPT API 호출 실패: {e}")
        # 예외 발생 시 기본값 반환
        return "평온", []

    # GPT 응답에서 메시지 본문을 가져옵니다.
    assistant_content: str = response.choices[0].message.content.strip()

    # JSON 파싱 시 오류 처리
    try:
        parsed = json.loads(assistant_content)
        emotion_tag = parsed.get("emotion_tag", "").strip()
        prompts = parsed.get("prompts", [])
        if not isinstance(prompts, list):
            raise ValueError("`prompts` 필드가 리스트가 아닙니다.")
        return emotion_tag, prompts
    except (json.JSONDecodeError, ValueError) as e:
        print(f"[Error] GPT 응답 파싱 실패: {e}\n원본 응답: {assistant_content}")
        # 파싱에 실패하면 '평온'과 빈 프롬프트 리스트를 반환
        return "평온", []
