from rest_framework import serializers
from .models import BirdIdentifySession, BirdCandidate

class BirdCandidateSerializer(serializers.ModelSerializer):
    class Meta:
        model = BirdCandidate 
        fields = ["id", "rank", "common_name_ko", "scientific_name", "short_description", "wikimedia_image_url"]

class BirdIdentifySessionSerializer(serializers.ModelSerializer):
    candidates = BirdCandidateSerializer(many=True, read_only=True)

    class Meta:
        model = BirdIdentifySession
        fields = ["id", "current_index", "is_finished", "selected_candidate", "created_at", "candidates"]

class UploadBirdPhotoSerializer(serializers.Serializer):
    image = serializers.ImageField()
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)
    obs_date = serializers.DateTimeField(required=False)

    # GPT api 넣으면 수정 필요
    species_id = serializers.IntegerField()

class SpeciesSummarySerializer(serializers.Serializer):
    species_id = serializers.IntegerField()
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