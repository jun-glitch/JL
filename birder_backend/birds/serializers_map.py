from rest_framework import serializers

class MapPointSerializer(serializers.Serializer):
    """
    지도에 '사진'을 보이기 위한 데이터
    - 프론트는 lat/lng 기준으로 마커 배치
    - image_url은 썸네일/대표사진으로 사용
    """
    photo_id = serializers.IntegerField()

    lat = serializers.FloatField()
    lng = serializers.FloatField()

    image_url = serializers.CharField(allow_null=True)

class MapClusterSerializer(serializers.Serializer):
    """
    피크민st 지도 클러스터 
    """
    grid_lat = serializers.FloatField()
    grid_lng = serializers.FloatField()
    count = serializers.IntegerField()

