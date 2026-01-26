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
def get_top5_candidates_from_gpt(image_url: str) -> List[dict]:
    """
    Supabase public URL을 GPT로 전달하여
    Top5 후보를 JSON으로 받습니다.
    """
    client = OpenAI(api_key=getattr(settings, "OPENAI_API_KEY", None) or None)

    model = getattr(settings, "OPENAI_MODEL", "gpt-4o-2024-08-06")

    # Responses API: 이미지 입력은 content 배열에 input_image.
    # (OpenAI docs 형식) :contentReference[oaicite:8]{index=8}
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
        text_format=IdentifyResult,  # Pydantic 기반 Structured Outputs
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
