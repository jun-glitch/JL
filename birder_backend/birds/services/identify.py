from __future__ import annotations

import base64
import traceback
from typing import List, Dict, Any

from .openai_identify import identify_with_gpt


def encode_bytes_to_base64(image_bytes: bytes) -> str:
    if not image_bytes:
        return ""
    return base64.b64encode(image_bytes).decode("utf-8")

# supabase에서 이미지 형태가 어떻게 오는지에 따라서 수정 필요 현재는 bytes로 넘어옴
def fetch_image_bytes_from_supabase(supabase, bucket: str, path: str) -> bytes:
    return supabase.storage.from_(bucket).download(path)

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
                "common_name_ko": str(c.get("common_name_ko") or "").strip(),
                "scientific_name": str(c.get("scientific_name") or "").strip(),
                "confidence": float(c.get("confidence") or 0.0),
            }
        )

    # rank 오름차순
    out.sort(key=lambda x: x["rank"])
    return out


def identify_bird_from_supabase(
    supabase,
    bucket: str,
    path: str,
    mime_type: str = "image/jpeg",
) -> List[Dict[str, Any]]:
    """
    Supabase 원본 이미지 → OpenAI Top5 후보 반환

    <디버깅>
    - Supabase 다운로드 bytes 길이 출력
    - OpenAI top5 출력 (openai_identify.py에서)
    - 예외 시 f"{e}" + traceback 출력
    """
    print("[Identify] enter identify_bird_from_supabase")
    print(f"[Identify] bucket={bucket} path={path} mime_type={mime_type}")

    try:
        image_bytes = fetch_image_bytes_from_supabase(supabase, bucket, path)
        print(f"[Identify] downloaded bytes={len(image_bytes) if image_bytes else 0}")

        base64_image = encode_bytes_to_base64(image_bytes)
        if not base64_image:
            print("[Identify] base64_image empty -> return []")
            return []

        candidates = identify_with_gpt(base64_image=base64_image, mime_type=mime_type)
        candidates = normalize_candidates(candidates)

        print(f"[Identify] candidates count={len(candidates)}")
        return candidates

    except Exception as e:
        # 디버깅: f"{e}" + traceback
        print(f"[Identify] exception: {e}")
        print(traceback.format_exc())
        return []
    
def identify_bird(image_file, mime_type: str = "image/jpeg"):
    """
    views.py에서 업로드된 InMemoryUploadedFile/TemporaryUploadedFile을 받는 용도.
    기존 identify_bird_from_supabase와 별개로, 업로드 파일을 바로 처리.
    """
    try:
        # 업로드 파일은 read()로 bytes를 얻을 수 있음
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

        # mime_type은 업로드 파일의 content_type 우선
        mt = getattr(image_file, "content_type", None) or mime_type

        candidates = identify_with_gpt(base64_image=base64_image, mime_type=mt)
        return normalize_candidates(candidates)

    except Exception as e:
        print(f"[Identify] exception in identify_bird: {e}")
        print(traceback.format_exc())
        return []