from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

# 접근 권한 설정
from rest_framework.permissions import AllowAny, IsAuthenticated

# 회원가입 입력 검증용 Serializer
from .serializers import SignupSerializer

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
