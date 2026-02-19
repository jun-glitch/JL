from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .serializers_fieldguide import (
    SpeciesObservationDetailSerializer,
    SpeciesObservationItemSerializer,
)
from integrations.supabase_client import supabase

class SpeciesObservationsView(APIView):
    """
    종 상세(슬라이드 + 로그):
    - 특정 species_code에 대해 로그인 유저의 관측 logs/사진 반환 (Supabase 기준)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, species_code: str):
        try:
            user_uuid = str(request.user.id)

            # 1) species 테이블에서 종 기본 정보 조회
            species_res = (
                supabase
                .table("species")
                .select("species_code, common_name, scientific_name, order_name")
                .eq("species_code", species_code)
                .limit(1)
                .execute()
            )
            species_rows = species_res.data or []
            if not species_rows:
                return Response({"detail": "species not found"}, status=status.HTTP_404_NOT_FOUND)

            sp = species_rows[0]

            # 2) log 테이블에서 사용자가 올린 종의 로그 조회 + 사진 정보 가져옴
            logs_res = (
                supabase
                .table("log")
                .select(
                    "log_num, reg_date, species_code, photo_num, "
                    "photo:photo_num(location, latitude, longitude, obs_date, s_filenum)"
                )
                .eq("id", user_uuid)
                .eq("species_code", species_code)
                .order("reg_date", desc=True)
                .execute()
            )

            rows = logs_res.data or []

            # 3) summary : 총 관측 횟수, 첫 관측 시각, 마지막 관측 시각
            count = len(rows)
            obs_dates = []
            for r in rows:
                p = r.get("photo") or {}
                od = p.get("obs_date")
                if od:
                    obs_dates.append(od)

            first_observed_at = min(obs_dates) if obs_dates else None
            last_observed_at = max(obs_dates) if obs_dates else None

            # 4) Serializer 맞게 items 구성
            items = []
            for r in rows:
                p = r.get("photo") or {}

                items.append({
                    "log_id": r.get("log_num"),
                    "photo_id": r.get("photo_num"),
                    "obs_date": p.get("obs_date"),
                    "reg_date": r.get("reg_date"),
                    "area_full": p.get("location", "") or "",   
                    "latitude": p.get("latitude"),
                    "longitude": p.get("longitude"),
                    "image_url": p.get("s_filenum"),            
                })

            payload = {
                "species": {
                    "species_code": sp.get("species_code", ""),
                    "common_name": sp.get("common_name", "") or "",
                    "scientific_name": sp.get("scientific_name", "") or "",
                    "order": sp.get("order", "") or "",
                },
                "summary": {
                    "count": int(count),
                    "first_observed_at": first_observed_at,
                    "last_observed_at": last_observed_at,
                },
                "photos": SpeciesObservationItemSerializer(items, many=True).data,
                "logs": SpeciesObservationItemSerializer(items, many=True).data,
                "next_cursor": None,
            }

            out = SpeciesObservationDetailSerializer(payload)
            return Response(out.data, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {"message": f"SpeciesObservationsView failed: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
