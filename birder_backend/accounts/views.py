from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from integrations.supabase_client import supabase

# 접근 권한 설정
from rest_framework.permissions import AllowAny, IsAuthenticated

# 회원가입 입력 검증용 Serializer
from .serializers import SignupSerializer

# 가입 시 사용했던 비밀번호 유효성 검사
from django.contrib.auth.password_validation import validate_password

# 회원가입 API 뷰
class SignupView(APIView):
    permission_classes = [AllowAny] # 누구나 접근 가능(로그인 전 사용자도 접근 가능해야 해서)

    # POST 요청이 들어오면 실행
    def post(self, request):
        # 클라이언트에서 보낸 데이터로 Serializer에 전달
        serializer = SignupSerializer(data=request.data)
        
        # 입력값 검증(비밀번호 일치 여부, 중복 ID/이메일, 비밀번호 정책 등)
        # 문제 발생 시 400 에러 자동 반환
        serializer.is_valid(raise_exception=True)

        validated_data = serializer.validated_data
        id = validated_data.get('username')
        email = validated_data.get('email')
        pwd = validated_data.get('password')
        username = validated_data.get('name')

        try:
            auth_response = supabase.auth.sign_up({
                'email' : email,
                'password' : pwd
            })
            user = auth_response.user

            if not user : 
                return Response({"message" : "인증 계정 생성 실패"}, status=status.HTTP_400_BAD_REQUEST)
            
            if not id or not email or not pwd:
                return Response({"message" : "정확한 정보를 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)
            
            birder_data = {
                'id' : user.id,
                'user_id' : id,
                'user_pwd' : pwd,
                'user_name' : username,
                'user_email' : email,
                'enable' : 1,
                'location_enable' : 1
            }

            db_response = supabase.table('birder').insert(birder_data).execute()

            return Response({
                "message" : "회원가입 성공",
                "user_id" : id,
                "user_email" : email,
                "user_name": username
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({"message" : f"계정 생성 실패: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 로그인 API
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        login_info = request.data

        id = login_info.get('username')
        pwd = login_info.get('password')

        if not id or not pwd :
            return Response({"message" : "아이디와 비밀번호를 모두 입력해주세요"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            birder_user_query = supabase.table('birder').select('id', 'user_id', 'user_pwd', 'user_email', 'enable', 'location_enable').eq('user_id', id).single().execute()
            birder_user = birder_user_query.data

            if not birder_user:
                return Response({"message" : "올바르지 않은 로그인 정보입니다"}, status=status.HTTP_400_BAD_REQUEST)
            
            if birder_user.get('enable') == 0:
                return Response({"message" : "비활성화된 계정입니다"}, status=status.HTTP_401_UNAUTHORIZED)
            
            user_email = birder_user.get('user_email')

            auth_response = supabase.auth.sign_in_with_password({
                'email' : user_email,
                'password' : pwd
            })
            session = auth_response.session

            if not session :
                return Response({"message" : "올바르지 않은 로그인 정보입니다"}, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({
                "access_token" : session.access_token,
                "refresh_token" : session.refresh_token,
                "user" : {
                    "id" : id,
                    "email" : user_email,
                    "location_enable" : birder_user.get('location_enable')
                }
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"로그인 실패: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 현재 로그인한 사용자 정보 반환 API
class MeView(APIView):
    permission_classes = [IsAuthenticated] # 로그인한 사용자만 접근 가능

    def get(self, request):
        # 요청한 사용자 객체 가져오기
        u = request.user

        # 로그인한 사용자 정보 반환
        return Response({"id": u.user_id, "username": u.user_name, "email": u.email})

# 아이디 찾기
class FindUsernameView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email') # 이메일 data 변수명 email로 보내기

        if not email: # 이메일을 입력하지 않은 경우 프론트에서 막아주기
            return Response({"message" : "이메일을 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user_id = supabase.table('birder').select('user_id').eq('email', email).execute()
            if user_id:
                return Response({"user_id" : user_id}, status=status.HTTP_200_OK) 
            else: 
                return Response({"message" : "해당 이메일로 가입된 아이디가 없습니다."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"message" : f"유저 검색 중 에러 발생: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 비밀번호 찾기 기능에서 아이디, 이메일 확인 후 비밀번호 재설정 페이지 링크를 이메일로 전송
class FindPwdView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        id = request.data.get('username') # id data 변수명 username
        email = request.data.get('email') # data 변수명 email

        if not id or not email: # 아이디 또는 이메일을 입력 안 한 경우 프론트에서 막아주기
            return  Response({"message" : "아이디와 이메일을 정확히 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = supabase.table('birder').eq('user_id', id).eq('user_email', email).single().execute()

            if not user:
                return Response({"message" : "해당 정보로 가입된 계정이 없습니다."}, status=status.HTTP_404_NOT_FOUND)
            
            supabase.auth.reset_password_for_email(email, {"redirect_to" : "http://localhost:8000/api/auth/change-pwd/"})

            return Response({
                "message" : "이메일로 비밀번호 재설정 링크가 전송되었습니다. 도착하지 않은 경우 스팸메일함을 확인해주세요."
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({"message" : f"비밀번호 찾기 중 에러 발생: {str(e)}"}, status=status.HTTP_404_NOT_FOUND)

# 로그인 상태에서 비밀번호 변경을 위한 본인 인증 > 비밀번호 재입력
class CheckPwdView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        email = request.user.email
        pwd = request.data.get('password')
        if not pwd:
            return Response({"message" : "비밀번호를 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            auth_response = supabase.auth.sign_in_with_password({
                "email" : email,
                "password" : pwd
            })

            return Response({
                "message" : "비밀번호 확인 완료",
                "session" : {
                    "access_token" : auth_response.session.access_token,
                    "refresh_token" : auth_response.session.refresh_token
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"message" : f"비밀번호 인증 중 에러 발생: {str(e)}"}, status=status.HTTP_401_UNAUTHORIZED)

# 새 비밀번호 변경 페이지 - 비밀번호 찾기, 변경 공동 페이지
class SetPwdView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        new_pwd = request.data.get('new_password')
        new_pwd_confirm = request.data.get('new_password_confirm')
        try:
            if new_pwd != new_pwd_confirm:
                return Response({"message" : "새 비밀번호가 일치하지 않습니다."}, status=status.HTTP_400_BAD_REQUEST)
            
            validate_password(new_pwd)

            supabase.auth.update_user({
                "password" : new_pwd
            })

            id = request.user.id
            supabase.table('birder').update({"user_pwd" : new_pwd}).eq('id', id).execute()

            # 현재 발급된 토큰 만료 모든 로그인된 계정 로그아웃 처리
            supabase.auth.admin.sign_out(id)

            return Response({"message" : "비밀번호가 성공적으로 변경되었습니다. 보안을 위해 다시 로그인해주세요."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"비밀번호 재설정 중 에러 발생: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

 # 사용자 설정 조회 및 수정 API
class SettingsView(APIView):
    permission_classes = [IsAuthenticated]

    # 설정 조회
    def get(self, request):
        # 현재 로그인한 사용자의 설정 가져오기 
        id = request.user.id # birder table pk

        try:
            response = supabase.table('birder').select('location_enable', 'user_id', 'user_email', 'user_name', 'updated_at').eq('id', id).single().execute()

            if not response:
                return Response({"message" : "유저를 찾을 수 없습니다."}, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({
                "data" : response.data
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"설정 조회 실패: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # 설정 수정
    def patch(self, request):
        # 현재 로그인한 사용자의 설정 가져오기 
        id = request.user.id # birder table pk

        update_data = {} # 수정할 데이터
        if 'location_enable' in request.data:
            update_data['location_enable'] = request.data['location_enable']
        
        if not update_data:
            return Response({"message" : "수정할 내용이 없습니다."}, status=status.HTTP_204_NO_CONTENT)
        # updated_at 컬럼은 supabase 트리거로 컬럼이 update되는 경우 now()로 update하는 함수 설정

        try:
            response = supabase.table('birder').update(update_data).eq('id', id).execute()

            return Response({
                "message" : "설정이 성공적으로 수정되었습니다",
                "data" : response.data[0] if response.data else {}
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"설정 수정 중 에러: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 로그아웃 API
class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        access_token = request.auth

        try:
            supabase.auth.sign_out(access_token)
            return Response({"message" : "로그아웃이 성공적으로 완료되었습니다."}, status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            return Response({"message" : f"로그아웃 중 에러 발생: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 회원 탈퇴 API
class WithdrawView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        id = request.user.id # birder table pk

        # 사용자 가입 내역 삭제가 아닌 enable 컬럼에서 활성화 > 비활성화 상태로 변경
        try:
            response = supabase.table('birder').update({'enable': 0, 'location_enable' : 0}).eq('id', id).execute()

            # supabase auth 영역에서 세션 만료 처리
            supabase.auth.admin.update_user_by_id(id, {'user_metadata' : {'disabled' : True}})

            return Response({
                "message" : "탈퇴 처리를 성공적으로 마쳤습니다.",
                "data" : response.data[0] if response.data else {}
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"탈퇴 처리에 실패: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class TokenRefreshView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # 프론트엔드에서 보낸 refresh_token을 가져옵니다.
        refresh_token = request.data.get('refresh_token')

        if not refresh_token:
            return Response({"message": "refresh_token이 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Supabase Auth를 통해 세션 갱신 요청
            auth_response = supabase.auth.refresh_session(refresh_token)
            
            new_session = auth_response.session

            return Response({
                "message" : "token이 성공적으로 재발행되었습니다.",
                "access_token": new_session.access_token,
                "refresh_token": new_session.refresh_token, # 갱신된 새로운 리프레시 토큰
                "expires_in": new_session.expires_in
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"message": f"토큰 갱신 실패: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
