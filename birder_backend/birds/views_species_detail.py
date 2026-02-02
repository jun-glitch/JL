from django.db.models import Min, Max, Count
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Species, Log
from .serializers_fieldguide import SpeciesObservationDetailSerializer, SpeciesObservationItemSerializer

class SpeciesObservationsView(APIView):
    """
    종 상세(슬라이드 + 로그):
    - 특정 species_id에 대해 로그인 유저의 관측 logs/사진 반환
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, species_code: str):
        user = request.user

        species = Species.objects.filter(species_code=species_code).first()
        if not species:
            return Response({"detail": "species not found"}, status=404)

        # 해당 유저의 해당 종 관측 로그만 가져오기
        logs_qs = (
            Log.objects
            .filter(user=user,
                    species__species_code=species_code,
                    )
            .select_related("photo")
            .order_by("-photo__obs_date", "-reg_date", "-num")
        )

        # summary
        summary_row = logs_qs.aggregate(
            count=Count("num"),
            first_observed_at=Min("photo__obs_date"),
            last_observed_at=Max("photo__obs_date"),
        )

        # 로그/사진 아이템화
        items = []
        for log in logs_qs:
            photo = log.photo

            # supabase 연동 시 수정 필요
            image_url = None
            if photo and getattr(photo, "image", None):
                image_url = request.build_absolute_uri(photo.image.url)

            items.append({
                "log_id": getattr(log, "num", log.id),
                "photo_id": getattr(photo, "photo_num", photo.id) if photo else None,
                "obs_date": getattr(photo, "obs_date", None) if photo else None,
                "reg_date": getattr(log, "reg_date", None),
                "area_full": getattr(photo, "area_full", "") if photo else "",
                "latitude": float(photo.latitude) if (photo and photo.latitude is not None) else None,
                "longitude": float(photo.longitude) if (photo and photo.longitude is not None) else None,
                "image_url": image_url,
            })

        payload = {
            "species": {
                "species_code": species.species_code,
                "common_name": species.common_name,
                "scientific_name": species.scientific_name,
                "order": getattr(species, "order", ""),
            },
            "summary": {
                "count": int(summary_row["count"] or 0),
                "first_observed_at": summary_row["first_observed_at"],
                "last_observed_at": summary_row["last_observed_at"],
            },
            "photos": SpeciesObservationItemSerializer(items, many=True).data,
            "logs": SpeciesObservationItemSerializer(items, many=True).data,
            "next_cursor": None,  # 추후 페이지네이션 도입 시 사용
        }

        out = SpeciesObservationDetailSerializer(payload)
        return Response(out.data)
