from __future__ import annotations

from typing import Tuple, Optional

from django.db.models import Count
from django.db.models.functions import Round
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .serializers_map import MapPointSerializer

from integrations.supabase_client import get_supabase_client

import traceback

def _parse_bbox(request) -> Tuple[float, float, float, float]:
    """
    프론트가 보내는 bbox 파라미터를 숫자 형태로 변환, 좌표 검증 후 반환
    필수 파라미터:
      - min_lat, min_lng, max_lat, max_lng
    """
    try:
        min_lat = float(request.query_params.get("min_lat"))
        min_lng = float(request.query_params.get("min_lng"))
        max_lat = float(request.query_params.get("max_lat"))
        max_lng = float(request.query_params.get("max_lng"))
    except (TypeError, ValueError):
        raise ValueError("min_lat, min_lng, max_lat, max_lng are required and must be numbers")

    # bbox 논리 검증(사각형 맞는지)
    if min_lat > max_lat or min_lng > max_lng:
        raise ValueError("invalid bbox: min must be <= max")

    # 위도/경도 범위 검증
    if not (-90 <= min_lat <= 90 and -90 <= max_lat <= 90 and -180 <= min_lng <= 180 and -180 <= max_lng <= 180):
        raise ValueError("lat/lng out of range")

    return min_lat, min_lng, max_lat, max_lng


def _parse_limit(request, default=500, max_limit=2000) -> int:
    raw = request.query_params.get("limit", str(default))
    try:
        n = int(raw)
    except ValueError:
        raise ValueError("limit must be integer")
    return max(1, min(n, max_limit))


def _decimal_places_for_zoom(zoom: int) -> int:
    if zoom <= 6:
        return 1
    if zoom <= 8:
        return 2
    if zoom <= 10:
        return 3
    return 4

# 사진 이미지 정보 URL 반환
def _photo_image_url_from_row(photo_row: dict) -> Optional[str]:
    if not photo_row:
        return None
    return photo_row.get("s_filenum")

class MapPointsView(APIView):
    permission_classes = [IsAuthenticated]

    # 프론트가 보낸 bbox 내의 관측 지점들 반환
    def get(self, request):
        try:
            min_lat, min_lng, max_lat, max_lng = _parse_bbox(request)
            limit = _parse_limit(request, default=500, max_limit=2000)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        user_uuid = request.user.id
        try:
            client = get_supabase_client()
            print("CLIENT TYPE:", type(client), flush=True)
            print("client.table:", getattr(client, "table", None), flush=True)
            print("type(client.table):", type(getattr(client, "table", None)), flush=True)
            print("callable(client.table):", callable(getattr(client, "table", None)), flush=True)
            query = client.table("log")  

            query = query.select("photo_num,photo:photo_num(longitude,latitude,s_filenum)")
            query = query.eq("id", user_uuid)
            query = query.is_("photo.longitude", "not_null")
            query = query.is_("photo.latitude", "not_null")
            query = query.gte("photo.latitude", min_lat).lte("photo.latitude", max_lat)
            query = query.gte("photo.longitude", min_lng).lte("photo.longitude", max_lng)
            query = query.order("reg_date", desc=True)
            query = query.limit(limit)

            resp = query.execute()
            rows = resp.data or []
            
            points = []
            for row in rows:
                photo = row.get("photo")
                if not photo:
                    continue

                points.append({
                    "photo_id": row.get("photo_num"),
                    "lat": float(photo["latitude"]),
                    "lng": float(photo["longitude"]),
                    "image_url": photo.get("s_filenum"),
                })

            out = MapPointSerializer(points, many=True)
            return Response({
                "bbox": {"min_lat": min_lat, "min_lng": min_lng, "max_lat": max_lat, "max_lng": max_lng},
                "count": len(points),
                "results": out.data,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            traceback.print_exc() 
            return Response(
                {"detail": f"Error fetching map points: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )   
