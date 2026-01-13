from typing import List, Dict
from .wikimedia import fetch_wikimedia_image_url

# 추후 Chat-GPT API 연동 시 실제 후보군 받아오는 함수로 대체 예정
def mock_top5_candidates() -> List[Dict]:
    """
    더미 Top5를 반환, Chat-GPT API 연동 전 임시용
    """
    return [
        {"rank": 1, "common_name_ko": "세가락도요", "scientific_name": "Calidris alba", "short_description": "작은 도요새. 겨울엔 회백색."},
        {"rank": 2, "common_name_ko": "청다리도요사촌", "scientific_name": "Tringa guttifer", "short_description": "중형 도요새. 다리가 길다."},
        {"rank": 3, "common_name_ko": "알락꼬리마도요", "scientific_name": "Numenius phaeopus", "short_description": "긴 부리로 갯벌을 찾는다."},
        {"rank": 4, "common_name_ko": "흰물떼새", "scientific_name": "Charadrius alexandrinus", "short_description": "모래사장 주변에서 관찰."},
        {"rank": 5, "common_name_ko": "꼬마물떼새", "scientific_name": "Charadrius dubius", "short_description": "작은 체구, 노란 눈테."},
    ]

def build_candidates_with_images(top5: List[Dict]) -> List[Dict]:
    """
    후보 각각에 위키 이미지 URL을 붙여서 프론트에서 바로 쓸 수 있게 반환
    """
    results = []
    for c in top5:
        q = c.get("scientific_name") or c.get("common_name_ko")
        c["wikimedia_image_url"] = fetch_wikimedia_image_url(q)
        results.append(c)
    return results
