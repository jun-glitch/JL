# birds/services/identify.py
from __future__ import annotations

from typing import List, Dict, Optional
import json
import re

from django.conf import settings

from openai import OpenAI

from .wikimedia import fetch_wikimedia_image_url


# -----------------------------
# 1) 개발/장애 대비: fallback mock
# -----------------------------
def mock_top5_candidates() -> List[Dict]:
    """
    GPT 호출 실패/키 미설정/네트워크 문제 등일 때 임시로 반환.
    (개발 중 파이프라인이 끊기지 않도록 유지)
    """
    return [
        {"rank": 1, "common_name_ko": "세가락도요", "scientific_name": "Calidris alba", "short_description": "작은 도요새. 겨울엔 회백색.", "confidence": 0.20},
        {"rank": 2, "common_name_ko": "청다리도요사촌", "scientific_name": "Tringa guttifer", "short_description": "중형 도요새. 다리가 길다.", "confidence": 0.20},
        {"rank": 3, "common_name_ko": "알락꼬리마도요", "scientific_name": "Numenius phaeopus", "short_description": "긴 부리로 갯벌을 찾는다.", "confidence": 0.20},
        {"rank": 4, "common_name_ko": "흰물떼새", "scientific_name": "Charadrius alexandrinus", "short_description": "모래사장 주변에서 관찰.", "confidence": 0.20},
        {"rank": 5, "common_name_ko": "꼬마물떼새", "scientific_name": "Charadrius dubius", "short_description": "작은 체구, 노란 눈테.", "confidence": 0.20},
    ]


# -----------------------------
# 2) 공용 유틸: 위키 이미지 붙이기
# -----------------------------
def build_candidates_with_images(candidates: List[Dict]) -> List[Dict]:
    """
    후보 각각에 위키 대표 이미지 URL을 붙여 프론트에서 바로 사용할 수 있게 반환.
    - scientific_name 우선, 없으면 common_name_ko로 검색
    """
    results = []
    for c in candidates:
        q = (c.get("scientific_name") or "").strip() or (c.get("common_name_ko") or "").strip()
        c["wikimedia_image_url"] = fetch_wikimedia_image_url(q) if q else ""
        results.append(c)
    return results


# -----------------------------
# 3) GPT Vision 호출 (Supabase public URL 기반)
# -----------------------------
def gpt_top5_candidates(image_url: str) -> List[Dict]:
    """
    Supabase public URL(외부 접근 가능)을 GPT Vision 모델에 전달해 Top5 후보를 생성합니다.

    반환 스키마(각 item):
    - rank: 1..5
    - common_name_ko: str (가능하면 한국어 국명)
    - scientific_name: str (학명, 가능하면)
    - short_description: str (한국어, 관찰 포인트 중심)
    - confidence: 0..1 (후보 간 상대적 신뢰도, 합이 1일 필요는 없음)
    """
    api_key = getattr(settings, "OPENAI_API_KEY", None) or getattr(settings, "OPENAI_KEY", None)
    if not api_key:
        # 키가 없으면 개발 편의를 위해 mock
        candidates = mock_top5_candidates()
        return build_candidates_with_images(candidates)

    model = getattr(settings, "OPENAI_MODEL", None) or "gpt-4o-mini"

    client = OpenAI(api_key=api_key)

    # 모델에게 "반드시 JSON"으로만 답하게 하는 프롬프트
    # (Structured Outputs를 쓰면 더 단단해지지만, 현재는 파일 하나만 교체 요청이라
    # 依存성 최소화 + 파싱 복원력 높은 방식으로 구성)
    system_text = (
        "You are a bird identification assistant.\n"
        "Given a single bird photo, return EXACTLY 5 candidate species.\n"
        "Return output ONLY as JSON (no markdown, no commentary).\n"
        "Prefer Korean common names (common_name_ko) when possible.\n"
        "Provide scientific_name if you can; otherwise empty string.\n"
        "short_description must be Korean and focus on visible cues (bill, plumage, size, habitat cues).\n"
        "confidence should be a float between 0 and 1.\n"
        "Do not include any additional keys.\n"
    )

    user_text = (
        "Identify this bird photo.\n"
        "Return JSON with this exact schema:\n"
        "{\n"
        '  "candidates": [\n'
        '    {"rank": 1, "common_name_ko": "...", "scientific_name": "...", "short_description": "...", "confidence": 0.0},\n'
        '    ... exactly 5 items ...\n'
        "  ]\n"
        "}\n"
        "Rules:\n"
        "- ranks must be 1..5\n"
        "- confidence must be 0..1\n"
    )

    try:
        resp = client.responses.create(
            model=model,
            input=[
                {"role": "system", "content": system_text},
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": user_text},
                        {"type": "input_image", "image_url": image_url},
                    ],
                },
            ],
        )

        # Responses API 텍스트 취득 (SDK 버전에 따라 output_text가 있거나 없을 수 있어 방어)
        text = getattr(resp, "output_text", None)
        if not text:
            # fallback: output 구조에서 text를 찾아봄
            text = _extract_text_from_responses_output(resp)

        data = _safe_json_loads(text)
        candidates = data.get("candidates") if isinstance(data, dict) else None
        candidates = _normalize_candidates(candidates)

        # 위키 이미지 추가
        return build_candidates_with_images(candidates)

    except Exception:
        # 실서비스라면 로깅 권장. 지금은 파이프가 안 끊기게 fallback.
        candidates = mock_top5_candidates()
        return build_candidates_with_images(candidates)


# -----------------------------
# 4) 파싱/정규화 유틸
# -----------------------------
def _extract_text_from_responses_output(resp) -> str:
    """
    resp.output[*].content[*].text 형태를 훑어 텍스트를 모읍니다.
    SDK/버전 차이를 방어하기 위한 보조 함수입니다.
    """
    try:
        chunks = []
        for item in resp.output:
            for c in getattr(item, "content", []) or []:
                if getattr(c, "type", None) in ("output_text", "text") and getattr(c, "text", None):
                    chunks.append(c.text)
        return "\n".join(chunks).strip()
    except Exception:
        return ""


def _safe_json_loads(text: str) -> dict:
    """
    모델이 실수로 앞/뒤에 설명을 붙이거나 ```json 블록을 붙여도 복구할 수 있게 파싱합니다.
    """
    if not text:
        return {}

    # ```json ... ``` 제거
    text = re.sub(r"```(?:json)?", "", text).replace("```", "").strip()

    # JSON 객체 부분만 뽑기 (가장 바깥 { ... } )
    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end != -1 and end > start:
        text = text[start : end + 1]

    try:
        return json.loads(text)
    except Exception:
        return {}


def _normalize_candidates(raw: Optional[list]) -> List[Dict]:
    """
    candidates를 항상 길이 5의 리스트로 정규화합니다.
    - 누락된 key는 기본값으로 채움
    - rank 정렬/재부여
    """
    if not isinstance(raw, list):
        raw = []

    cleaned = []
    for x in raw:
        if not isinstance(x, dict):
            continue
        cleaned.append(
            {
                "rank": int(x.get("rank") or 0),
                "common_name_ko": str(x.get("common_name_ko") or "").strip(),
                "scientific_name": str(x.get("scientific_name") or "").strip(),
                "short_description": str(x.get("short_description") or "").strip(),
                "confidence": float(x.get("confidence") or 0.0),
            }
        )

    # rank 기준 정렬
    cleaned.sort(key=lambda d: d.get("rank") or 999)

    # rank 1..5로 재부여 (혹시 모델이 이상한 rank를 줬을 때)
    cleaned = cleaned[:5]
    while len(cleaned) < 5:
        cleaned.append(
            {
                "rank": len(cleaned) + 1,
                "common_name_ko": "",
                "scientific_name": "",
                "short_description": "",
                "confidence": 0.0,
            }
        )

    for i, c in enumerate(cleaned, start=1):
        c["rank"] = i
        # confidence 범위 클램프
        if c["confidence"] < 0:
            c["confidence"] = 0.0
        if c["confidence"] > 1:
            c["confidence"] = 1.0

    return cleaned
