import os
from urllib.parse import quote

def get_public_url(bucket: str, path: str) -> str:
    """
    Supabase Storage public bucket의 객체 URL을 생성합니다.

    규칙:
    {SUPABASE_URL}/storage/v1/object/public/{bucket}/{path}
    """
    base_url = os.getenv("SUPABASE_URL")
    if not base_url:
        raise RuntimeError("SUPABASE_URL environment variable is not set")

    # 파일 경로에 한글/공백이 있을 수 있으므로 URL 인코딩
    safe_path = quote(path, safe="/")
    return f"{base_url.rstrip('/')}/storage/v1/object/public/{bucket}/{safe_path}"
