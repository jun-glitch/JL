from __future__ import annotations

from typing import List
from pydantic import BaseModel, Field

from django.conf import settings
from openai import OpenAI


# Top5 후보
class Candidate(BaseModel):
    rank: int = Field(ge=1, le=5)
    common_name_ko: str
    scientific_name: str = ""
    short_description: str = ""

class IdentifyResult(BaseModel):
    candidates: List[Candidate] = Field(min_length=5, max_length=5)

# 2) GPT 호출 함수
"""
def get_top5_candidates_from_gpt(image_url: str) -> List[dict]:
    print('get top5 candidate from gpt 진입')
    try:

        client = OpenAI(api_key=getattr(settings, "OPENAI_API_KEY", None) or None)

        model = getattr(settings, "OPENAI_MODEL", "gpt-4o-mini")

        response = client.responses.parse(
            model=model,
            input=[
                {
                    "role": "system",
                    "content": (
                        "You are a bird identification assistant.\n"
                        "Given one bird photo, return EXACTLY 5 candidate species.\n"
                        "Return Korean common name when possible.\n"
                    ),
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": "Identify this bird and give top 5 candidates."},
                        {"type": "input_image", "image_url": image_url},
                    ],
                },
            ],
            text_format=IdentifyResult,
            stream=True
        )

        parsed: IdentifyResult = response.output_parsed

        # views.py와 호환되도록 dict list로 변환
        out = []
        for c in parsed.candidates:
            out.append(
                {
                    "rank": c.rank,
                    "common_name_ko": c.common_name_ko,
                    "scientific_name": c.scientific_name,
                    "short_description": c.short_description,
                }
            )
        return out
    except Exception as e:
        print(f'{str(e)}')
        return []
"""
def get_top5_candidates_from_gpt(image_url: str) -> List[dict]:
    client = OpenAI(api_key=getattr(settings, "OPENAI_API_KEY", None))
    model = getattr(settings, "OPENAI_MODEL", "gpt-4o-mini")

    try:
        # beta.chat.completions.parse 를 사용하는 것이 정석입니다.
        response = client.beta.chat.completions.parse(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a bird identification assistant. "
                        "Given one bird photo, return EXACTLY 5 candidate species. "
                        "Return Korean common name when possible."
                    ),
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Identify this bird and give top 5 candidates."},
                        {"type": "image_url", "image_url": {"url": image_url}},
                    ],
                },
            ],
            response_format=IdentifyResult, # text_format 아님
        )

        # 2. 결과 추출 부분 수정
        # .parse()를 쓰면 결과는 choices[0].message.parsed 에 들어있습니다.
        parsed = response.choices[0].message.parsed

        if not parsed:
            return []

        out = []
        for c in parsed.candidates:
            out.append({
                "rank": c.rank,
                "common_name_ko": c.common_name_ko,
                "scientific_name": c.scientific_name,
                "short_description": c.short_description,
            })
        return out

    except Exception as e:
        print(f"GPT 호출 중 상세 에러: {e}")
        raise e

def identify_with_gpt(base64_image: str, mime_type: str = "image/jpeg") -> List[dict]:
    print('identify with gpt 진입')
    if not base64_image:
        print('identify with gpt base64 image None')
        return []

    data_url = f"data:{mime_type};base64,{base64_image}"
    return get_top5_candidates_from_gpt(data_url)
