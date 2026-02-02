from rest_framework import serializers

# 각 종이 어떤 필드 가지는지 정의
class FieldGuideSpeciesItemSerializer(serializers.Serializer):
    species_code = serializers.CharField()
    common_name = serializers.CharField()
    scientific_name = serializers.CharField()
    order = serializers.CharField()

    observed = serializers.BooleanField() # 이 유저가 관측했는지
    observation_count = serializers.IntegerField() # 이 유저의 누적 관측 횟수
    last_observed_at = serializers.DateTimeField(allow_null=True) # 최근 관측일

    cover_image_url = serializers.CharField(allow_null=True) # 대표 사진 URL (미관측이면 null)

# 도감 메인 화면에서 목 단위 그룹
class FieldGuideOrderGroupSerializer(serializers.Serializer):
    order = serializers.CharField()
    items = FieldGuideSpeciesItemSerializer(many=True)

# 종 상세 화면에서 관측 1건에 포함되는 필드 (슬라이드와 로그 리스트에서 사용)
class SpeciesObservationItemSerializer(serializers.Serializer):
    log_id = serializers.IntegerField()
    photo_id = serializers.IntegerField()

    obs_date = serializers.DateTimeField(allow_null=True)
    reg_date = serializers.DateTimeField()

    area_full = serializers.CharField(allow_blank=True)
    latitude = serializers.FloatField(allow_null=True)
    longitude = serializers.FloatField(allow_null=True)

    image_url = serializers.CharField(allow_null=True)

# 종 상세 화면 전체 응답 ()
class SpeciesObservationDetailSerializer(serializers.Serializer):
    species = serializers.DictField()
    summary = serializers.DictField()
    photos = SpeciesObservationItemSerializer(many=True)
    logs = SpeciesObservationItemSerializer(many=True)
    next_cursor = serializers.CharField(allow_null=True)
