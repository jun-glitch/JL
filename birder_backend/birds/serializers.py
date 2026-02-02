from rest_framework import serializers
from decimal import Decimal, ROUND_HALF_UP
from django.utils import timezone

from .models import BirdIdentifySession, BirdCandidate, Photo, Species, Log
from .utils.geocode import normalize_area_from_latlon

class BirdCandidateSerializer(serializers.ModelSerializer):
    class Meta:
        model = BirdCandidate 
        fields = [
            "id", 
            "rank",
            "common_name_ko",
            "scientific_name",
            "short_description",
            "wikimedia_image_url",
            "confidence",
        ]

class BirdIdentifySessionSerializer(serializers.ModelSerializer):
    candidates = BirdCandidateSerializer(many=True, read_only=True)

    class Meta:
        model = BirdIdentifySession
        fields = [
            "id",
            "image_url",
            "current_index",
            "is_finished",
            "selected_candidate",
            "created_at",
            "candidates"
            ]

class UploadBirdPhotoSerializer(serializers.Serializer):
    image = serializers.ImageField()
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)
    obs_date = serializers.DateTimeField(required=False)

    # GPT api 넣으면 수정 필요
    species_code = serializers.CharField(required=False, allow_blank=True, allow_null=True)

class SpeciesSummarySerializer(serializers.Serializer):
    species_code = serializers.CharField()
    common_name = serializers.CharField()
    scientific_name = serializers.CharField()
    total_count = serializers.IntegerField()

class LogItemSerializer(serializers.Serializer):
    log_id = serializers.IntegerField()
    location = serializers.CharField()
    rec_date = serializers.DateTimeField()
    obs_date = serializers.DateTimeField(allow_null=True)
    latitude = serializers.FloatField(allow_null=True)
    longitude = serializers.FloatField(allow_null=True)
    image_url = serializers.CharField()

# 추후 DB 개설 후 수정 필요 
class ObservationUploadSerializer(serializers.Serializer):
    image = serializers.ImageField()
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    obs_date = serializers.DateTimeField(required=False, allow_null=True)

    species_code = serializers.CharField(required=False, allow_blank=True)

    def _round4_decimal(self, x: float) -> Decimal:
        return Decimal(str(x)).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)

    def create(self, validated_data):
        request = self.context["request"]
        user = request.user

        image = validated_data["image"]
        lat = validated_data.get("latitude")
        lng = validated_data.get("longitude")
        obs_date = validated_data.get("obs_date") or timezone.now()

        # 1) 역지오코딩 (좌표 없으면 UNKNOWN)
        area_full = ""
        area1 = ""
        area2 = ""
        if lat is not None and lng is not None:
            area_full = normalize_area_from_latlon(lat, lng)
            # area_full이 "대구광역시 중구" 형태면 단순 split
            parts = area_full.split()
            if len(parts) >= 1:
                area1 = parts[0]
            if len(parts) >= 2:
                area2 = parts[1]

        # 2) Photo 저장
        photo = Photo.objects.create(
            image=image,
            latitude=lat,
            longitude=lng,
            obs_date=obs_date,
            area1=area1,
            area2=area2,
            area_full=area_full,
        )

        # 2-1) Photo에 grid_lat/grid_lng 필드가 "존재하는 경우에만" 채우기
        if hasattr(photo, "grid_lat") and lat is not None:
            photo.grid_lat = self._round4_decimal(lat)
        if hasattr(photo, "grid_lng") and lng is not None:
            photo.grid_lng = self._round4_decimal(lng)
        if hasattr(photo, "grid_lat") or hasattr(photo, "grid_lng"):
            photo.save(update_fields=[f for f in ["grid_lat", "grid_lng"] if hasattr(photo, f)])

        # 3) species 연결
        species = None
        species_code = validated_data.get("species_code")
        if species_code:
            species = Species.objects.filter(species_code=species_code).first()
      
        # 4) Log 저장
        log = Log.objects.create(
            user=user,
            photo=photo,
            species=species,          
        )

        return {
            "photo_num": getattr(photo, "photo_num", photo.id),
            "log_id": getattr(log, "num", log.id),
            "location": area_full or "",
            "obs_date": photo.obs_date,
            "latitude": float(photo.latitude) if photo.latitude is not None else None,
            "longitude": float(photo.longitude) if photo.longitude is not None else None,
            "image_url": photo.image.url if photo.image else "",
        }
