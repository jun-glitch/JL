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

    out.sort(key=lambda x: x["rank"])
    return out


def fetch_species_options(supabase, limit: int = 300) -> List[Dict[str, str]]:
    """
    species 테이블에서 옵션 목록 가져오기.
    DB 컬럼명: species_code, common_name, scientific_name (없으면 제거)
    """
    res = (
        supabase.table("species")
        .select("species_code, common_name, scientific_name")
        .limit(limit)
        .execute()
    )
    rows = res.data or []

    options: List[Dict[str, str]] = []
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

    return options


def identify_bird(
    image_file,
    supabase=None,
    mime_type: str = "image/jpeg",
    species_limit: int = 300,
) -> List[Dict[str, Any]]:
    """
    views.py에서 업로드된 InMemoryUploadedFile/TemporaryUploadedFile을 받는 용도.
    ✅ supabase를 넘겨주면 species_options를 읽어서 'DB 종만' 후보로 제한합니다.
    """
    try:
        # 1) 업로드 파일 bytes 읽기 (포인터 복구 포함)
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

        # 2) species_options 준비 (supabase가 있을 때만)
        species_options: Optional[List[Dict[str, str]]] = None
        if supabase is not None:
            species_options = fetch_species_options(supabase, limit=species_limit)
            print(f"[Identify] species_options count={len(species_options)}")

        # 3) OpenAI 호출 (옵션 전달)
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