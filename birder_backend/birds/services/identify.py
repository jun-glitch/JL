import base64
from typing import List, Dict, Any

from .openai_identify import identify_with_gpt

# 이미지 파일을 base64로 인코딩
def encode_image_to_base64(image_file) -> str:
    image_bytes = image_file.read()
    encoded = base64.b64encode(image_bytes).decode("utf-8")
    return encoded

# 정규화
def normalize_candidates(candidates: Any) -> List[Dict[str, Any]]:
    if not isinstance(candidates, list):
        print('candidate not list')
        return []

    cleaned = []

    for x in candidates:
        if not isinstance(x, dict):
            continue

        cleaned.append({
            "rank": int(x.get("rank") or 0),
            "common_name_ko": str(x.get("common_name_ko") or "").strip(),
            "scientific_name": str(x.get("scientific_name") or "").strip(),
            "short_description": str(x.get("short_description") or "").strip(),
            "confidence": float(x.get("confidence") or 0.0),
        })

    # rank 기준 정렬
    cleaned = sorted(cleaned, key=lambda c: c["rank"])

    return cleaned


def identify_bird(image_file) -> List[Dict[str, Any]]:
    print('identify bird 진입')
    try:
        base64_image = encode_image_to_base64(image_file)
        if not base64_image:
            print('identify bird base 64 image None')
            return []
        mime_type = getattr(image_file, "content_type", None) or "image/jpeg"
        candidates = identify_with_gpt(base64_image) ##
        print(candidates)
        return normalize_candidates(candidates)

    except Exception as e:
        print(f'{str(e)}')
        return []
