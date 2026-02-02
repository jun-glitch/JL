from collections import defaultdict

from django.db.models import Count, Max, Q
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Species, Log
from .serializers_fieldguide import FieldGuideOrderGroupSerializer


class FieldGuideView(APIView):
    """
    도감 메인:
    - Species(마스터)를 order(목) 기준으로 그룹핑
    - 로그인 유저의 Log를 집계해서:
      observed 여부, observation_count, last_observed_at, cover_image_url(최근 1장) 제공
    검색/필터:
    - ?order=기러기목 (목별 필터)
    - ?q=청둥 (학명 부분검색)
    - ?observed=true|false (관측한 종만/관측 안한 종만)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # 프론트에서 보내는 검색 파라미터 읽기
        order_param = request.query_params.get("order")
        q = request.query_params.get("q")
        observed_param = request.query_params.get("observed")  # "true" | "false" | None

        # Species 먼저 필터링
        species_qs = Species.objects.all()

        if order_param:
            species_qs = species_qs.filter(order=order_param)

        if q:
            # 학명 부분 검색
            species_qs = species_qs.filter(
                Q(common_name__icontains=q) | Q(scientific_name__icontains=q)
            )

        species_list = list(
            species_qs.values("species_code", "common_name", "scientific_name", "order")
        )
        species_codes = [s["species_code"] for s in species_list]

        # 유저 로그 집계 (count, last_obs_date)
        agg = (
            Log.objects
            .filter(user=user, species__species_code__in=species_codes)
            .values("species__species_code")
            .annotate(
                observation_count=Count("num"),
                last_observed_at=Max("photo__obs_date"),
            )
        )
        agg_map = {row["species__species_code"]: row for row in agg}

        # cover 이미지(최근 1장)용: species별 최신 log 1개를 가져와 photo.image 사용
        latest_logs = (
            Log.objects
            .filter(user=user, species__species_code__in=species_codes)
            .select_related("photo", "species")
            .order_by("species__species_code", "-photo__obs_date", "-reg_date", "-num")
        )

        cover_map = {}
        for log in latest_logs:
            if not log.species:
                continue
            code = log.species.species_code
            if code in cover_map:
                continue
            photo = log.photo
            cover_map[code] = request.build_absolute_uri(photo.image.url) if (photo and getattr(photo, "image", None)) else None

        # Species 목록을 도감 카드로 아이템화, 목별 그룹핑
        grouped = defaultdict(list)
        for s in species_list:
            sid = s["species_code"]
            a = agg_map.get(sid) # 관측했으면 row 반환, 못했으면 None

            observed = a is not None
            observation_count = int(a["observation_count"]) if observed else 0
            last_observed_at = a["last_observed_at"] if observed else None
            cover_image_url = cover_map.get(sid) if observed else None

            item = {
                "species_code": sid,
                "common_name": s["common_name"],
                "scientific_name": s.get("scientific_name") or "",
                "order": s.get("order") or "",
                "observed": observed,
                "observation_count": observation_count,
                "last_observed_at": last_observed_at,
                "cover_image_url": cover_image_url,
            }
            
            # 관측 여부 필터링
            if observed_param == "true" and not observed:
                continue
            if observed_param == "false" and observed:
                continue

            grouped[item["order"]].append(item)

        # order 내 정렬(관측한 것 우선, 그 다음 최근 관측 순)
        groups_payload = []
        for order_name, items in grouped.items():
            items.sort(
                key=lambda x: (
                    0 if x["observed"] else 1,
                    x["last_observed_at"] is None,
                    x["last_observed_at"] if x["last_observed_at"] else "",
                    x["common_name"],
                ),
                reverse=False,
            )
            groups_payload.append({"order": order_name, "items": items})

        # order 그룹 정렬
        groups_payload.sort(key=lambda g: g["order"])
        out = FieldGuideOrderGroupSerializer(groups_payload, many=True)
        return Response({"groups": out.data})
