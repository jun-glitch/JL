from __future__ import annotations

import base64
import traceback
from typing import List, Dict, Any, Optional

from .openai_identify import identify_with_gpt


def encode_bytes_to_base64(image_bytes: bytes) -> str:
    if not image_bytes:
        return ""
    return base64.b64encode(image_bytes).decode("utf-8")


def normalize_candidates(candidates: Any) -> List[Dict[str, Any]]:
    """
    openai_identify.py에서 dict list로 오면:
      - rank 기준 정렬
      - 필드 타입 정규화
    """
    if not isinstance(candidates, list):
        return []

    out: List[Dict[str, Any]] = []
    for c in candidates:
        if not isinstance(c, dict):
            continue
        out.append(
            {
                "rank": int(c.get("rank") or 0),
                "species_code": str(c.get("species_code") or "").strip(),
                "common_name_ko": str(c.get("common_name_ko") or "").strip(),
                "scientific_name": str(c.get("scientific_name") or "").strip(),
                "confidence": float(c.get("confidence") or 0.0),
                "wikimedia_image_url": str(c.get("wikimedia_image_url") or ""),
            }
        )

    out = [x for x in out if x["species_code"]]
    out.sort(key=lambda x: x["rank"])
    return out


def _auto_get_supabase_client(supabase):
    if supabase is not None:
        return supabase
    try:
        from integrations.supabase_client import supabase  
        return supabase
    except Exception:
        return None


def fetch_species_options_all(
    supabase,
    page_size: int = 1000,
    max_rows: int = 2000,
) -> List[Dict[str, str]]:
    """
    species 테이블에서 전체(525종) 옵션
    - supabase range pagination 사용
    - 컬럼명: species_code, common_name, scientific_name
    """
    if supabase is None:
        return []

    options: List[Dict[str, str]] = []
    start = 0

    while True:
        end = start + page_size - 1
        res = (
            supabase.table("species")
            .select("species_code, common_name, scientific_name")
            .range(start, end)
            .execute()
        )
        rows = res.data or []

        for r in rows:
            code = str(r.get("species_code") or "").strip()
            if not code:
                continue
            options.append(
                {
                    "species_code": code,
                    "common_name_ko": str(r.get("common_name") or "").strip(),
                    "scientific_name": str(r.get("scientific_name") or "").strip(),
                }
            )

        if len(rows) < page_size:
            break

        start += page_size
        if start >= max_rows:
            break

    return options


def identify_bird(
    image_file,
    supabase=None,
    mime_type: str = "image/jpeg",
) -> List[Dict[str, Any]]:

    try:
        sb = _auto_get_supabase_client(supabase)
        if sb is None:
            # supabase 연결이 없으면 실패 처리(빈 리스트)
            print("[Identify] supabase client missing -> return []")
            return []

        try:
            image_file.seek(0)
        except Exception:
            pass

        image_bytes = image_file.read()

        try:
            image_file.seek(0)
        except Exception:
            pass

        base64_image = encode_bytes_to_base64(image_bytes)
        if not base64_image:
            print("[Identify] base64_image empty -> return []")
            return []

        mt = getattr(image_file, "content_type", None) or mime_type

        species_options = fetch_species_options_all(sb)
        if not species_options:
            print("[Identify] species_options empty -> return []")
            return []
        print(f"[Identify] species_options count={len(species_options)}")

        candidates = identify_with_gpt(
            base64_image=base64_image,
            mime_type=mt,
            species_options=species_options,
        )

        return normalize_candidates(candidates)

    except Exception as e:
        print(f"[Identify] exception in identify_bird: {e}")
        print(traceback.format_exc())
        return []