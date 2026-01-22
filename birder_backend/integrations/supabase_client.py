import os
from supabase import create_client, Client
from django.conf import settings

def get_supabase_client() -> Client:
    url = getattr(settings, "SUPABASE_URL", os.environ.get("SUPABASE_URL"))
    key = getattr(settings, "SUPABASE_KEY", os.environ.get("SUPABASE_KEY"))
    
    if not url or not key:
        raise ValueError("Supabase URL 또는 Key가 설정되지 않았습니다.")
    
    return create_client(url, key)

supabase = get_supabase_client()