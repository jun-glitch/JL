from django.urls import path

# JWT 토큰 발급 및 갱신 뷰 임포트
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

# 회원가입 처리, 현재 로그인한 사용자 정보 반환, 아이디·비밀번호 찾기
from .views import SignupView, MeView, FindUsernameView, ChangePwdView, LogoutView, SettingsView

urlpatterns = [
    path("signup/", SignupView.as_view(), name="signup"), # 회원가입 API, Serializer로 입력값 검증 후 User 생성
    path("login/", TokenObtainPairView.as_view(), name="login"), # username, password로 토큰 발급
    path("refresh/", TokenRefreshView.as_view(), name="refresh"), # 리프레시 토큰으로 액세스 토큰 재발급
    path("me/", MeView.as_view(), name="me"), # 현재 로그인한 사용자 정보 반환 API
    path('find-username/', FindUsernameView.as_view(), name="find_username"), # email 입력받아 회원 아이디 찾기
    path('change-pwd/', ChangePwdView.as_view(), name='change_pwd'), # 비밀번호 변경
    path("settings/", SettingsView.as_view(), name="settings"),
    path("logout/", LogoutView.as_view(), name="logout"),
]
