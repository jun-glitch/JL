from urllib import request
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from .models import UserSettings
from rest_framework_simplejwt.tokens import RefreshToken

# 접근 권한 설정
from rest_framework.permissions import AllowAny, IsAuthenticated

# 회원가입 입력 검증용 Serializer
from .serializers import SignupSerializer,UserSettingsSerializer

# 회원 테이블 접근용 User
from django.contrib.auth.models import User

# 비밀번호 변경 후 로그아웃 방지
from django.contrib.auth import update_session_auth_hash

# 가입 시 사용했던 비밀번호 유효성 검사
from django.contrib.auth.password_validation import validate_password

# pk encode, decode용
from django.utils.http import urlsafe_base64_encode
from django.utils.http import urlsafe_base64_decode
from django.utils.encoding import force_bytes

# token 발행
from django.contrib.auth.tokens import default_token_generator

# 메일 전송
from django.core.mail import send_mail

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

        # 검증 통과 시 User가 DB에 생성
        user = serializer.save()

        # 생성된 사용자 정보 반환(비밀번호 제외)
        return Response(
            {"id": user.id, "username": user.username, "email": user.email},
            status=status.HTTP_201_CREATED,
        )

# 현재 로그인한 사용자 정보 반환 API
class MeView(APIView):
    permission_classes = [IsAuthenticated] # 로그인한 사용자만 접근 가능

    def get(self, request):
        # 요청한 사용자 객체 가져오기
        u = request.user

        # 로그인한 사용자 정보 반환
        return Response({"id": u.id, "username": u.username, "email": u.email})

# 아이디 찾기
class FindUsernameView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email') # 이메일 data 변수명 email로 보내기

        if not email: # 이메일을 입력하지 않은 경우 프론트에서 막아주기
            return Response({"error" : "이메일을 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(email=email)
            return Response({"username" : user.username}, status=status.HTTP_200_OK)
        
        except User.DoesNotExist:
            return Response({"error" : "해당 이메일로 가입된 아이디가 없습니다."}, status=status.HTTP_404_NOT_FOUND)

# 비밀번호 찾기 기능에서 아이디, 이메일 확인 후 비밀번호 재설정 페이지 링크를 이메일로 전송
class FindPwdView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        username = request.data.get('username') # id data 변수명 username
        email = request.data.get('email') # data 변수명 email

        if not username: # 아이디 입력 안 한 경우 프론트에서 막아주기
            return  Response({"error" : "아이디를 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)
        
        if not email: # 이메일을 입력 안 한 경우 프론트에서 막아주기
            return  Response({"error" : "이메일을 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(email=email, id=username)

            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = default_token_generator.make_token(user)

            reset_link = f"http://localhost:3000/change-pwd/{uid}/{token}"

            send_mail(
                '비밀번호 재설정 안내',
                f'해당 링크를 클릭하여 비밀번호를 재설정하세요: {reset_link}',
                [email]
            )
            return Response({"message" : "이메일로 비밀번호 재설정 링크가 전송되었습니다. 도착하지 않은 경우 스팸메일함을 확인해주세요."}, status=status.HTTP_200_OK)
            
        except User.DoesNotExist:
            return Response({"error" : "해당 정보로 가입된 계정이 없습니다."}, status=status.HTTP_404_NOT_FOUND)

# 로그인 상태에서 비밀번호 변경을 위한 본인 인증 > 비밀번호 재입력
class CheckPwdView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        user = request.user # 현재 로그인되어 있는 계정 가져오기
        pwd = request.data.get('pwd')

        if  user.check_password(pwd):
            uid = urlsafe_base64_encode(force_bytes(user.pk)) # 현재 사용자의 pk 암호화
            token = default_token_generator.make_token(user)
            return Response({"uidb64" : uid, "token" : token}, status=status.HTTP_200_OK)

        return Response({"error" : "틀린 비밀번호입니다."}, status=status.HTTP_200_OK)

# 새 비밀번호 변경 페이지 - 비밀번호 찾기, 변경 공동 페이지
class SetPwdView(APIView):
    permission_classes = [AllowAny] # 해당 화면에 들어온 사용자는 모두 가능
    def post(self, request):
        uidb64 = request.data.get('uidb64')
        token = request.data.get('token') # 비밀번호 변경 > 본인 인증용 비밀번호 재확인 페이지에서 토큰 발행 // 비밀번호 찾기 > 본인 인증 후 이메일에 보낼 때 토큰 발행
        new_pwd = request.data.get('new_pwd')
        new_pwd_confirm = request.data.get('new_pwd_confirm')
        try:
            uid = urlsafe_base64_decode(uidb64).decode() # 비밀번호 변경/찾기 할 때 사용된 user의 encode된 pk 받기
            user = User.objects.get(pk=uid)
            
            # 발행된 토큰 유효성 검증
            if not default_token_generator.check_token(user, token):
                return Response({"error" : "링크의 유효기한이 만료되었습니다."}, status=800) # 800 error 발생 시 링크 만료 안내

            if new_pwd != new_pwd_confirm:
                return Response({"error" : "새 비밀번호가 일치하지 않습니다"}, status=status.HTTP_400_BAD_REQUEST)
            
            validate_password(new_pwd, user)

            user.set_password(new_pwd)
            user.save()
            update_session_auth_hash(request, user) # 로그인 상태 유지

            return Response({"message" : "비밀번호가 성공적으로 변경되었습니다."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error" : list(e.messages)})
        
class SettingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        settings_obj, _ = UserSettings.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(settings_obj)
        return Response(serializer.data)

    def patch(self, request):
        settings_obj, _ = UserSettings.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(settings_obj, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
        
class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh = request.data.get("refresh")
        if not refresh:
            return Response(
                {"detail": "refresh token required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        token = RefreshToken(refresh)
        token.blacklist()
        return Response(status=status.HTTP_204_NO_CONTENT)
