from rest_framework import authentication
from rest_framework import exceptions
from integrations.supabase_client import supabase

class SupabaseAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        # 헤더에서 Authorization: Bearer <token> 추출
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return None

        token = auth_header.split(' ')[1]

        try:
            # Supabase에 토큰 검증 요청
            user_response = supabase.auth.get_user(token)
            user = user_response.user

            if not user:
                return None

            # Django가 이해할 수 있는 객체로 반환 (실제 DB 유저가 아니어도 객체화 가능)
            # 보통 여기서 user 정보를 바탕으로 익명 객체를 만들거나 birder 정보를 합칩니다.
            return (user, token) # (request.user에 담길 값, request.auth에 담길 값)

        except Exception:
            raise exceptions.AuthenticationFailed('유효하지 않은 토큰입니다.')