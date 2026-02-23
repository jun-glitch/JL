from __future__ import annotations

import traceback
import re
from typing import List, Optional, Dict, Any
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
from django.conf import settings
from pydantic import BaseModel, Field
from openai import OpenAI


# ----------------- OpenAI 응답 스키마 -----------------
class Candidate(BaseModel):
    rank: int = Field(ge=1, le=5)
    species_code: str
    common_name_ko: str
    scientific_name: str = ""
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)

class IdentifyResult(BaseModel):
    candidates: List[Candidate] = Field(min_length=5, max_length=5)


# ----------------- scientific_name 정규화 -----------------
_SCI_PAREN_RE = re.compile(r"\(.*?\)")

def clean_scientific_name(name: str) -> str:
    name = (name or "").strip()
    name = _SCI_PAREN_RE.sub("", name)
    name = " ".join(name.split())
    return name


# ----------------- Wikimedia 썸네일 -----------------
WIKIMEDIA_API = "https://en.wikipedia.org/w/api.php"

def fetch_wikimedia_image_url(query: str, timeout_sec: float = 2.0) -> str:
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
    unique = [n for n in dict.fromkeys(scientific_names) if n]
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


# ----------------- DB 옵션 문자열 압축 -----------------
def _compress_species_options(species_options: List[Dict[str, Any]]) -> str:
    """
    토큰 절약용: 한 줄에 한 종
      species_code<TAB>common_name_ko<TAB>scientific_name
    """
    lines: List[str] = []
    for o in species_options:
        code = str(o.get("species_code") or "").strip()
        if not code:
            continue
        common = str(o.get("common_name_ko") or "").strip()
        sci = str(o.get("scientific_name") or "").strip()
        lines.append(f"{code}\t{common}\t{sci}")
    return "\n".join(lines)


def identify_with_gpt(
    base64_image: str,
    mime_type: str = "image/jpeg",
    species_options: Optional[List[Dict[str, Any]]] = None,
) -> List[dict]:
    """
    species_options가 주어지면:
      - OpenAI는 리스트 안의 species_code만 선택
      - 서버도 allowed_codes로 최종 필터링
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

    options_text = ""
    allowed_codes: Optional[set[str]] = None
    if species_options:
        options_text = _compress_species_options(species_options)
        allowed_codes = {str(o.get("species_code") or "").strip() for o in species_options}
        allowed_codes.discard("")

    try:
        system_text = (
            "You are a bird identification assistant.\n"
            "Given ONE bird photo, return EXACTLY 5 candidate species.\n"
            "Sort by similarity (best first).\n"
            "Return confidence in [0,1].\n"
            "Return JSON strictly matching the provided schema.\n"
        )

        if options_text:
            system_text += (
                "\nIMPORTANT:\n"
                "- You MUST choose candidates ONLY from the provided species list.\n"
                "- You MUST output species_code exactly as shown in the list.\n"
                "- If unsure, still pick the closest 5 from the list.\n"
            )

        user_content = [
            {"type": "text", "text": "Identify this bird and give top 5 candidates."},
            {"type": "image_url", "image_url": {"url": data_url}},
        ]

        if options_text:
            user_content.insert(
                1,
                {
                    "type": "text",
                    "text": (
                        "Choose ONLY from this species list.\n"
                        "Each line: species_code<TAB>common_name_ko<TAB>scientific_name\n\n"
                        f"{options_text}"
                    ),
                },
            )

        resp = client.beta.chat.completions.parse(
            model=model,
            messages=[
                {"role": "system", "content": system_text},
                {"role": "user", "content": user_content},
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
                    "species_code": (c.species_code or "").strip(),
                    "common_name_ko": (c.common_name_ko or "").strip(),
                    "scientific_name": sci,
                    "confidence": float(c.confidence or 0.0),
                    "wikimedia_image_url": "",
                }
            )

        out.sort(key=lambda x: x["rank"])

        if allowed_codes is not None:
            filtered = [x for x in out if x["species_code"] in allowed_codes]
            if len(filtered) < 5:
                print(f"[OpenAI] WARNING: filtered candidates < 5 (got {len(filtered)})")
            out = filtered

        wiki_map = _fetch_wiki_in_parallel([x["scientific_name"] for x in out])
        for x in out:
            x["wikimedia_image_url"] = wiki_map.get(x["scientific_name"], "")

        print("[OpenAI] top5 candidates:")
        for x in out:
            print(f"  #{x['rank']} {x['common_name_ko']} | {x['scientific_name']} | code={x['species_code']} | conf={x['confidence']}")

        return out

    except Exception as e:
        print(f"[OpenAI] exception: {e}")
        print(traceback.format_exc())
        raise