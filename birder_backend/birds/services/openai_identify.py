from __future__ import annotations

import traceback
import re
from typing import List, Optional

from django.conf import settings
from pydantic import BaseModel, Field
from openai import OpenAI


# OpenAI 응답 스키마 
class Candidate(BaseModel):
    rank: int = Field(ge=1, le=5)
    common_name_ko: str
    scientific_name: str = ""
    confidence: float = Field(default=0.0,ge=0.0, le=1.0)

class IdentifyResult(BaseModel):
    candidates: List[Candidate] = Field(min_length=5, max_length=5)

# 정규화 과정
_SCI_PAREN_RE = re.compile(r"\(.*?\)")

# 괄호 제거, 공백 정리
def clean_scientific_name(name: str) -> str:
    name = (name or "").strip()
    name = _SCI_PAREN_RE.sub("", name)
    name = " ".join(name.split())
    return name

def identify_with_gpt(base64_image: str, mime_type: str = "image/jpeg") -> List[dict]:
    """
    base64_image: base64 문자열 (data: prefix 없이)
    mime_type: image/jpeg, image/png 등

    return: dict list (rank 1..5)  예)
      [
        {"rank": 1, "common_name_ko": "...", "scientific_name": "...", "confidence": 0.82},
        ...
      ]
    """
    if not base64_image:
        print("[OpenAI] base64_image empty -> return []")
        return []

    api_key = getattr(settings, "OPENAI_API_KEY", None)
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is missing in settings")

    model = getattr(settings, "OPENAI_MODEL", "gpt-4o-mini")
    client = OpenAI(api_key=api_key)

    data_url = f"data:{mime_type};base64,{base64_image}"

    try:
        resp = client.beta.chat.completions.parse(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a bird identification assistant.\n"
                        "Given ONE bird photo, return EXACTLY 5 candidate species.\n"
                        "Sort by similarity (best first).\n"
                        "Return Korean common name when possible.\n"
                        "Return scientific_name if you can.\n"
                        "Return confidence in [0,1].\n"
                        "Return JSON strictly matching the provided schema.\n"
                    ),
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Identify this bird and give top 5 candidates."},
                        {"type": "image_url", "image_url": {"url": data_url}},
                    ],
                },
            ],
            response_format=IdentifyResult,
        )

        parsed: Optional[IdentifyResult] = resp.choices[0].message.parsed
        if not parsed:
            print("모델이 JSON 스키마에 맞는 응답을 주지 않음)")
            return []

        out: List[dict] = []
        for c in parsed.candidates:
            out.append(
                {
                    "rank": int(c.rank),
                    "common_name_ko": (c.common_name_ko or "").strip(),
                    "scientific_name": clean_scientific_name(c.scientific_name),
                    "confidence": float(c.confidence or 0.0),
                }
            )

        # rank 정렬
        out.sort(key=lambda x: x["rank"])

        # 디버깅: Top5가 실제로 오는지 확인하기 위한 요약 출력
        print("[OpenAI] top5 candidates:")
        for x in out:
            print(
                f"  #{x['rank']} {x['common_name_ko']} | {x['scientific_name']} | conf={x['confidence']}"
            )

        return out

    except Exception as e:
        # 디버깅: f"{e}" + traceback
        print(f"[OpenAI] exception: {e}")
        print(traceback.format_exc())
        raise
