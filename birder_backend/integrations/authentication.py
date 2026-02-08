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

            user_query = supabase.table('birder').select('*').eq('id', user.id).single().execute()
            user_data = user_query.data

            if not user_data:
                raise exceptions.AuthenticationFailed('등록된 사용자 정보가 없습니다.')
            
            if user_data.get('enable') == 0:
                raise exceptions.AuthenticationFailed('비활성화된 사용자입니다.')
            user.location_enable = user_data.get('location_enable') # 위치정보제공동의 여부 동의: 1 비동의: 0
            user.user_name = user_data.get('user_name') # 유저명
            user.user_id = user_data.get('user_id') # 로그인 시 사용하는 id

            return (user, token) # (request.user에 담길 값, request.auth에 담길 값)

        except Exception as e:
            raise exceptions.AuthenticationFailed(f'인증 실패: {str(e)}')