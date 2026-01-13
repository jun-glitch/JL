from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404

from .models import BirdIdentifySession, BirdCandidate
from .serializers import BirdCandidateSerializer, BirdIdentifySessionSerializer
from .services.identify import mock_top5_candidates, build_candidates_with_images

class IdentifyView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # 1) 이미지 파일 받기
        image = request.FILES.get("image")
        if not image:
            return Response({"detail": "image file required"}, status=status.HTTP_400_BAD_REQUEST)

        # 2) 식별 세션 생성
        session = BirdIdentifySession.objects.create(user=request.user, image=image)

        # 3) Top5 후보 생성(현재 mock -> 추후 Chat-GPT API 연동 예정)
        top5 = mock_top5_candidates()
        top5 = build_candidates_with_images(top5)

        # 4) 후보 DB 저장
        for c in top5:
            BirdCandidate.objects.create(
                session=session,
                rank=c["rank"],
                common_name_ko=c["common_name_ko"],
                scientific_name=c.get("scientific_name", ""),
                short_description=c.get("short_description", ""),
                wikimedia_image_url=c.get("wikimedia_image_url", ""),
            )

        # 5) 세션 + 후보 전체 반환 (프론트에서 후보 리스트를 한꺼번에 받기 위해)
        return Response(BirdIdentifySessionSerializer(session).data, status=status.HTTP_201_CREATED)

# 사용자가 다음 후보 새를 요청하는 뷰
class IdentifyNextView(APIView):
    permission_classes = [IsAuthenticated]

    # GET 요청 시 다음 후보 새 반환
    def get(self, request, session_id: int):
        session = get_object_or_404(BirdIdentifySession, id=session_id, user=request.user)

        if session.is_finished:
            # 이미 끝난 세션이면 확정/종료 상태 알려주기
            return Response(BirdIdentifySessionSerializer(session).data)

        # 다음 후보 새 반환
        candidates = session.candidates.order_by("rank")
        if session.current_index >= candidates.count():
            session.is_finished = True
            session.save()
            return Response({"detail": "no more candidates", "is_finished": True})

        candidate = candidates[session.current_index]
        return Response({
            "session_id": session.id,
            "index": session.current_index,
            "candidate": BirdCandidateSerializer(candidate).data,
        })

# 사용자가 후보 새에 대해 처리하는 view
class IdentifyAnswerView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, session_id: int):
        session = get_object_or_404(BirdIdentifySession, id=session_id, user=request.user)

        answer = request.data.get("answer")  # "yes" / "no"
        if answer not in ["yes", "no"]:
            return Response({"detail": "answer must be 'yes' or 'no'"}, status=status.HTTP_400_BAD_REQUEST)

        candidates = session.candidates.order_by("rank")
        if session.current_index >= candidates.count():
            session.is_finished = True
            session.save()
            return Response({"detail": "no more candidates", "is_finished": True})

        current_candidate = candidates[session.current_index]

        # answer == "yes" → 확정
        if answer == "yes":
            session.selected_candidate = current_candidate
            session.is_finished = True
            session.save()
            return Response({
                "detail": "selected",
                "selected": BirdCandidateSerializer(current_candidate).data,
                "is_finished": True,
            })

        # answer == "no" → 다음 후보로
        session.current_index += 1
        session.save()
        return Response({
            "detail": "next",
            "next_index": session.current_index,
            "is_finished": False,
        })

