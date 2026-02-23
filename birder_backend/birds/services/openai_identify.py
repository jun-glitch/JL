from __future__ import annotations

import traceback
import re
from typing import List, Optional, Dict
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
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

# scientific_name 정규화 과정
_SCI_PAREN_RE = re.compile(r"\(.*?\)")

def clean_scientific_name(name: str) -> str:
    name = (name or "").strip()
    name = _SCI_PAREN_RE.sub("", name)
    name = " ".join(name.split())
    return name

# wikimedia 썸네일 가져오기
WIKIMEDIA_API = "https://en.wikipedia.org/w/api.php"
def fetch_wikimedia_image_url(query: str, timeout_sec: float = 2.0) -> str:
    """
    query: scientific_name 권장 
    실패하면 "" 반환
    """
    query = (query or "").strip()
    if not query:
        return ""

    try:
        params = {
            "action": "query",
            "format": "json",
            "prop": "pageimages",
            "piprop": "thumbnail",
            "pithumbsize": 800,
            "titles": query,
            "redirects": 1,  
        }
        r = requests.get(WIKIMEDIA_API, params=params, timeout=timeout_sec)
        r.raise_for_status()
        data = r.json()
        pages = data.get("query", {}).get("pages", {})
        for _, page in pages.items():
            thumb = page.get("thumbnail")
            if thumb and thumb.get("source"):
                return thumb["source"]
    except Exception:
        return ""

    return ""

def _fetch_wiki_in_parallel(scientific_names: List[str]) -> Dict[str, str]:
    unique = [n for n in dict.fromkeys(scientific_names) if n]  # 중복 제거 + 순서 유지
    if not unique:
        return {}

    result: Dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=min(5, len(unique))) as ex:
        fut_map = {ex.submit(fetch_wikimedia_image_url, n): n for n in unique}
        for fut in as_completed(fut_map):
            name = fut_map[fut]
            try:
                result[name] = fut.result() or ""
            except Exception:
                result[name] = ""
    return result

# OpenAI로 호출
def identify_with_gpt(base64_image: str, mime_type: str = "image/jpeg") -> List[dict]:
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
            print("[OpenAI] parsed is None (structured output failed)")
            try:
                print("[OpenAI] raw content:", resp.choices[0].message.content)
            except Exception:
                pass
            return []

        out: List[dict] = []
        sci_list: List[str] = []
        for c in parsed.candidates:
            sci = clean_scientific_name(c.scientific_name)
            sci_list.append(sci)
            out.append(
                {
                    "rank": int(c.rank),
                    "common_name_ko": (c.common_name_ko or "").strip(),
                    "scientific_name": clean_scientific_name(c.scientific_name),
                    "confidence": float(c.confidence or 0.0),
                    "wikimedia_image_url": "",
                }
            )

        # rank 정렬
        out.sort(key=lambda x: x["rank"])

        wiki_map = _fetch_wiki_in_parallel(sci_list)

        for x in out:
            x["wikimedia_image_url"] = wiki_map.get(x["scientific_name"], "")

        # 디버깅: Top5가 실제로 오는지 확인하기 위한 요약 출력
        print("[OpenAI] top5 candidates:")
        for x in out:
            print(
                f"  #{x['rank']} {x['common_name_ko']} | {x['scientific_name']} | conf={x['confidence']}"
            )

        return out

    except Exception as e:
        print(f"[OpenAI] exception: {e}")
        print(traceback.format_exc())
        raise
