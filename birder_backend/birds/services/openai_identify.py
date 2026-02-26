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
WIKIMEDIA_API = "https://commons.wikimedia.org/w/api.php"

"""
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
            imageinfo = page.get("imageinfo")
            if imageinfo and imageinfo[0].get("url"):
                return imageinfo[0]["url"]
            
    except Exception:
        return ""
    
    return ""
"""

def fetch_wikimedia_image_url(query: str, timeout_sec: float = 3.0) -> str:
    query = (query or "").strip()
    if not query:
        print("[WIKI] empty query")
        return ""

    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": query,
        "gsrlimit": 1,
        "gsrnamespace": 6,   # ✅ File: namespace only (핵심)
        "prop": "imageinfo",
        "iiprop": "url",
    }
    headers = {"User-Agent": "Birder/1.0"}

    try:
        r = requests.get(WIKIMEDIA_API, params=params, headers=headers, timeout=timeout_sec)
        print("[WIKI] status:", r.status_code, "query:", repr(query))
        if r.status_code != 200:
            print("[WIKI] body:", r.text[:200])
        r.raise_for_status()

        data = r.json()
        pages = data.get("query", {}).get("pages", {})
        if not pages:
            print("[WIKI] no pages. keys:", list(data.keys()))
            return ""

        for _, page in pages.items():
            imageinfo = page.get("imageinfo")
            if imageinfo and imageinfo[0].get("url"):
                return imageinfo[0]["url"]

        print("[WIKI] pages found but no imageinfo(url). page keys sample:", list(next(iter(pages.values())).keys()))
        return ""

    except Exception as e:
        print("[WIKI] exception:", type(e).__name__, str(e))
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
    한 줄에 한 종
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


def _ensure_top5_from_allowed(
    out: List[dict],
    species_options: Optional[List[Dict[str, Any]]],
) -> List[dict]:
    """
    - allowed filter 후 5개 미만이 되는 경우 GPT가 임의로 생성해서 줄 수도 있어서 DB에서 filler로 채워 5개 보장
    - 이미 존재하는 species_code는 안 들어가게 조정
    - confidence는 매우 낮게(0.01) 채움.
    """
    if len(out) >= 5:
        return out[:5]

    if not species_options:
        return out

    used = {str(x.get("species_code") or "").strip() for x in out}
    fillers: List[dict] = []
    for o in species_options:
        code = str(o.get("species_code") or "").strip()
        if not code or code in used:
            continue
        fillers.append(
            {
                "rank": 0,  # 나중에 재랭크
                "species_code": code,
                "common_name_ko": str(o.get("common_name_ko") or "").strip(),
                "scientific_name": clean_scientific_name(str(o.get("scientific_name") or "").strip()),
                "confidence": 0.01,
                "wikimedia_image_url": "",
            }
        )
        if len(out) + len(fillers) >= 5:
            break

    merged = out + fillers
    return merged[:5]


def identify_with_gpt(
    base64_image: str,
    mime_type: str = "image/jpeg",
    species_options: Optional[List[Dict[str, Any]]] = None,
) -> List[dict]:
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
                "\nIMPORTANT (hard constraint):\n"
                "- You MUST choose candidates ONLY from the provided species list.\n"
                "- You MUST output species_code EXACTLY as shown in the list.\n"
                "- Do NOT invent species_code.\n"
                "- If uncertain, still pick the closest 5 from the list.\n"
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
        for c in parsed.candidates:
            out.append(
                {
                    "rank": int(c.rank),
                    "species_code": (c.species_code or "").strip(),
                    "common_name_ko": (c.common_name_ko or "").strip(),
                    "scientific_name": clean_scientific_name(c.scientific_name),
                    "confidence": float(c.confidence or 0.0),
                    "wikimedia_image_url": "",
                }
            )

        # rank 정렬
        out = [x for x in out if x["species_code"]]
        out.sort(key=lambda x: x["rank"])

        # 서버 측 최종 whitelist 필터
        if allowed_codes is not None:
            filtered = [x for x in out if x["species_code"] in allowed_codes]
            if len(filtered) < 5:
                print(f"[OpenAI] WARNING: filtered candidates < 5 (got {len(filtered)})")
            out = filtered

        # 5개 보장(프론트/뷰 안정성)
        out = _ensure_top5_from_allowed(out, species_options)

        # 최종 rank 1..5 재부여
        for i, x in enumerate(out, start=1):
            x["rank"] = i

        # Wikimedia 썸네일 (최종 5개에 대해서만)
        wiki_map = _fetch_wiki_in_parallel([x["scientific_name"] for x in out])
        for x in out:
            x["wikimedia_image_url"] = wiki_map.get(x["scientific_name"], "")

        print("[OpenAI] top5 candidates:")
        for x in out:
            print(
                f"  #{x['rank']} {x['common_name_ko']} | {x['scientific_name']} | code={x['species_code']} | conf={x['confidence']}"
            )

        return out

    except Exception as e:
        print(f"[OpenAI] exception: {e}")
        print(traceback.format_exc())
        raise