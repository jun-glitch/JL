import requests

def normalize_area_from_latlon(lat: float, lon: float, timeout_sec: int = 5) -> str:
    """
    위경도 -> 행정구역 문자열로 정규화
    1차 목표: "시/도 + 시/군/구" 문자열 반환
    - 키 없이 가능한 Nominatim(OpenStreetMap) reverse geocoding 사용
    - 한국 주소가 기대와 다르게 내려오는 경우가 있으므로 fallback을 포함
    """
    
    # geocoding 논의 후에 변경 필요
    url = "https://nominatim.openstreetmap.org/reverse"
    params = {
        "format": "jsonv2",
        "lat": lat,
        "lon": lon,
        "zoom": 10,           
        "addressdetails": 1,
        "accept-language": "ko",
    }
    headers = {
        "User-Agent": "birder-app/0.1 (edu project)",
    }

    r = requests.get(url, params=params, headers=headers, timeout=timeout_sec)
    r.raise_for_status()
    data = r.json()

    addr = data.get("address", {}) or {}

    # 한국에서 많이 쓰는 키들
    province = (
        addr.get("state")
        or addr.get("province")
        or addr.get("region")
        or addr.get("ISO3166-2-lvl4")
    )
    city_or_county = (
        addr.get("city")
        or addr.get("county")
        or addr.get("municipality")
        or addr.get("town")
        or addr.get("borough")
    )

    # fallback -> 주소 저장되는 형태에 따라서 수정 필요 
    if not province or not city_or_county:
        display = data.get("display_name", "")
        parts = [p.strip() for p in display.split(",") if p.strip()]
        # 거꾸로 시도: ["중구","대구광역시","대한민국"] -> "대구광역시 중구"
        if len(parts) >= 2:
            # 한국은 보통 "구, 시" 순으로 나오기도 해서 뒤집어 합침
            a, b = parts[0], parts[1]
            # "중구" + "대구광역시" -> "대구광역시 중구"
            return f"{b} {a}".strip()

        return "UNKNOWN"

    return f"{province} {city_or_county}".strip()
