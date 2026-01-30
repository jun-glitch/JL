from __future__ import annotations

from typing import Tuple, Optional

from django.db.models import Count
from django.db.models.functions import Round
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import Log, Species
from .serializers_map import MapPointSerializer, MapClusterSerializer


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
    """
    points API의 최대 응답 개수를 제한
    """
    raw = request.query_params.get("limit", str(default))
    try:
        n = int(raw)
    except ValueError:
        raise ValueError("limit must be integer")
    return max(1, min(n, max_limit))


def _decimal_places_for_zoom(zoom: int) -> int:
    """
    zoom 레벨에 따라 '그리드 집계의 라운딩 자릿수'를 결정.
    - zoom 낮음: 크게 묶기
    - zoom 높음: 촘촘히

    지도 확대해보면서 보이는 개수 조절 필요할듯

    """
    if zoom <= 6:
        return 1
    if zoom <= 8:
        return 2
    if zoom <= 10:
        return 3
    return 4

# 사진 이미지 정보 URL 반환
def _photo_image_url(request, photo) -> Optional[str]:
    if not photo:
        return None
    return photo.image_url

class MapPointsView(APIView):
    permission_classes = [IsAuthenticated]

    # 프론트가 보낸 bbox 내의 관측 지점들 반환
    def get(self, request):
        try:
            min_lat, min_lng, max_lat, max_lng = _parse_bbox(request)
            limit = _parse_limit(request, default=500, max_limit=2000)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        # 본인 관측만
        qs = (
            Log.objects
            .filter(user=request.user)
            .select_related("photo", "species")
            .exclude(photo__latitude__isnull=True)
            .exclude(photo__longitude__isnull=True)
            .filter(photo__latitude__gte=min_lat, photo__latitude__lte=max_lat)
            .filter(photo__longitude__gte=min_lng, photo__longitude__lte=max_lng)
        )

        # 최신 관측 우선
        qs = qs.order_by("-photo__obs_date", "-reg_date", "-num")[:limit]

        points = []
        for log in qs:
            photo = log.photo
            sp = log.species

            points.append({
                "photo_id": photo.photo_num,
                "lat": float(photo.latitude),
                "lng": float(photo.longitude),
                "image_url": _photo_image_url(request, photo),
            })

        out = MapPointSerializer(points, many=True)
        return Response({
            "bbox": {"min_lat": min_lat, "min_lng": min_lng, "max_lat": max_lat, "max_lng": max_lng},
            "count": len(points),
            "points": out.data,
        }, status=status.HTTP_200_OK)

class MapClustersView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            min_lat, min_lng, max_lat, max_lng = _parse_bbox(request)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        # zoom 파싱
        raw_zoom = request.query_params.get("zoom")
        if raw_zoom is None:
            return Response({"detail": "zoom is required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            zoom = int(raw_zoom)
        except ValueError:
            return Response({"detail": "zoom must be integer"}, status=status.HTTP_400_BAD_REQUEST)

        dp = _decimal_places_for_zoom(zoom)

        # 대표 이미지 포함 여부
        include_sample = request.query_params.get("include_sample", "true").lower() == "true"

        base = (
            Log.objects
            .filter(user=request.user)
            .exclude(photo__latitude__isnull=True)
            .exclude(photo__longitude__isnull=True)
            .filter(photo__latitude__gte=min_lat, photo__latitude__lte=max_lat)
            .filter(photo__longitude__gte=min_lng, photo__longitude__lte=max_lng)
        )

        # 클러스터링 
        agg = (
            base
            .annotate(grid_lat=Round("photo__latitude", dp), grid_lng=Round("photo__longitude", dp))
            .values("grid_lat", "grid_lng")
            .annotate(count=Count("pk"))
            .order_by("-count")
        )

        clusters = []

        # 대표 이미지  가장 최근 사진 1장으로 보여줌 -> 느리면 바꾸기 
        if not include_sample:
            for row in agg:
                clusters.append({
                    "grid_lat": float(row["grid_lat"]),
                    "grid_lng": float(row["grid_lng"]),
                    "count": row["count"],
                    "sample_image_url": None,
                })
        else:
            for row in agg:
                glat = float(row["grid_lat"])
                glng = float(row["grid_lng"])

                sample_log = (
                    base
                    .annotate(grid_lat=Round("photo__latitude", dp), grid_lng=Round("photo__longitude", dp))
                    .filter(grid_lat=glat, grid_lng=glng)
                    .select_related("photo")
                    .order_by("-photo__obs_date", "-reg_date", "-num")
                    .first()
                )

                sample_url = _photo_image_url(request, sample_log.photo) if sample_log else None

                clusters.append({
                    "grid_lat": glat,
                    "grid_lng": glng,
                    "count": row["count"],
                    "sample_image_url": sample_url,
                })

        out = MapClusterSerializer(clusters, many=True)
        return Response({
            "bbox": {"min_lat": min_lat, "min_lng": min_lng, "max_lat": max_lat, "max_lng": max_lng},
            "zoom": zoom,
            "decimal_places": dp,
            "count": len(clusters),
            "clusters": out.data,
        }, status=status.HTTP_200_OK)
