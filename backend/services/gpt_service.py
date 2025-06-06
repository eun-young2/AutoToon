# app/services/gpt_service.py

import os, re, textwrap
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY")) 

EMOTIONS = ["joy", "excitement", "calm", "sadness", "anger"]

def analyze_emotion_and_generate_prompt(
        content: str,
        gender: str,
        age_group: str,
        style_name: str,
):
    """
    일기(content)를 바탕으로
      1) 대표 감정 태그 (기쁨/설렘/평온/슬픔/짜증 중 하나)
      2) 컷별(4개) 영어 프롬프트. 
         - 각 컷마다 ‘장면에 걸맞은 감정 어휘’를 포함할 것
         - 대표 감정과는 별개로, 컷마다 다채로운 감정 표현을 사용할 것
         - 최종 문장 끝에는 해당 컷의 감정 태그를 영어로 해시태그(#) 표시할 것
    를 반환합니다.
         - 여기서 ‘머리 스타일(hair style)’과 ‘의상(clothing)’은
    네 컷 모두 **동일하게 유지**해야 합니다.

      반환값:
        result_text : GPT가 리턴한 전체 텍스트
        emotion_tag : 대표 감정 태그 (한 개)
        prompts      : 컷별 영어 프롬프트 네 개(리스트)
    """
    must_include_cartoon = False
    if "painterly" in style_name.lower():
        must_include_cartoon = True
    else:
        must_include_cartoon = False

    if must_include_cartoon:
        style_rule = 'Because the style is a painterly variation, every prompt **must** contain the word "cartoon".'
    else:
        style_rule = 'Do **NOT** include the word "cartoon" in any prompt.'

    # system 메시지에 “감정 태그” 형식까지 분명히 지시
    system_prompt = "\n".join([
        "You are a scenario writer who creates 4-panel comic prompts from diary text.",
        style_rule,
        # Dominant Emotion 출력 방식 (영어 단어 하나)
        "When you output the dominant emotion, you must write exactly: Dominant Emotion: <joy/excitement/calm/sadness/anger>."
    ])
    
    # 사용자 프롬프트: 대표 감정 + 컷별 감정 표현 요청
    user_prompt = textwrap.dedent(f"""
        아래 일기를 읽고:
        1) 전체 감정을 보고, 아래 다섯 감정(joy, excitement, calm, sadness, anger) 중 하나만 골라
          첫 줄에 이렇게 출력해 주세요:
          Dominant Emotion: <영어 단어>

        2) 그다음, 실제 그림으로 쓰일 4개의 '영어 프롬프트'를 만들어 주세요. 
          - 각각의 프롬프트 앞에는 반드시 “{style_name}”을 붙여주세요.
          - 만약 style_name이 "toonic 2.5D"라면, 각 프롬프트에 반드시 “cartoon”이라는 단어를 포함해야 합니다.
          - 네 컷 모두 “머리 스타일(hair style)”과 “옷차림(clothing)”은 동일하게 유지해 주세요.
          - 각 프롬프트 끝에는 그 장면의 감정에 맞는 영어 해시태그를 #<emotion> 형태로 붙여 주세요.

          - 형식 예시:
            {style_name}, cartoon, front, a girl with short hair dancing, wearing a blue t-shirt, karaoke room background, joyful mood, surrounded by friends #joy

          - 또 다른 예시(한 줄):
            {style_name}, cartoon, side, a boy with short hair laughing, wearing a blue t-shirt, photo booth background, playful mood, posing with friends #joy

        조건:
        - style_name이 “toonic 2.5D”일 때, “cartoon”이라는 단어를 빼먹으면 안 됩니다.
        - 첫 줄(대표 감정)에는 영어 단어 하나만 쓰고, 두 번째 부분(4개 프롬프트)에서만 해시태그를 붙여 주세요.
        - gender/age_group 정보는 각 프롬프트 맨 앞에 “{age_group} {gender}” 형태로 꼭 포함해 주세요.

        일기 원문:
        \"\"\"{content}\"\"\"  
        """)

    rsp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": user_prompt}
        ],
        temperature=0.7
    )
    result = rsp.choices[0].message.content

    # ── (디버깅용) result_text 전체 출력 ────────────────────────────────
    print("---------- GPT 전체 응답 시작 ----------")
    print(result)
    print("----------  GPT 전체 응답 끝  ----------")
    # ────────────────────────────────────────────────────────────────────

    # ── “대표 감정 태그: <영어 단어>” 패턴만 꺼내오기 ──────────────────────────
    # 예시 응답(first line): "Dominant Emotion: joy"
    m = re.search(r"Dominant\s+Emotion\s*[:：]\s*([a-zA-Z]+)", result)
    if m:
        emotion_tag = m.group(1).strip().lower()
        if emotion_tag not in EMOTIONS:
            emotion_tag = None
    else:
        emotion_tag = None

    # ── 4컷 프롬프트(영어 텍스트)만 따로 뽑아오기 ────────────────────────────
    prompts = []
    for ln in result.splitlines():
        stripped = ln.strip()
        # 앞에 “- ” 로 시작하는 경우
        if stripped.startswith("-"):
            prompts.append(stripped.lstrip("- ").strip())
        # 또는 English 해시태그(#joy 등)가 포함된 줄을 저장
        elif "#" in stripped and any(word.lower() in stripped.lower() for word in EMOTIONS):
            prompts.append(stripped)

    # 여기서 prompts 리스트 길이가 4개가 아니면 나중에 재검토가 필요합니다.
    return result, emotion_tag, prompts
