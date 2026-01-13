import requests

# 학명 검색이라 영어 위키미디어 사용 
WIKIMEDIA_API = "https://en.wikipedia.org/w/api.php"

def fetch_wikimedia_image_url(query: str) -> str:
    """
    예시:
    - query(예: 'Calidris alba')로 위키 검색
    - 대표 썸네일 URL 가져옴
    """
    try:
        params = {
            "action": "query",
            "format": "json",
            "prop": "pageimages",
            "piprop": "thumbnail",
            "pithumbsize": 800,
            "titles": query,
        }
        r = requests.get(WIKIMEDIA_API, params=params, timeout=5)
        r.raise_for_status()
        data = r.json()
        pages = data.get("query", {}).get("pages", {})
        for _, page in pages.items():
            thumb = page.get("thumbnail")
            if thumb and thumb.get("source"):
                return thumb["source"]
    except Exception:
        pass
    return ""
