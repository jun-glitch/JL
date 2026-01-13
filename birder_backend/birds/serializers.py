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
