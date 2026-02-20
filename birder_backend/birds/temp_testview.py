import uuid
from datetime import datetime

from django.db.models import Count
from django.db.models.functions import Round
from django.utils import timezone
from django.conf import settings

from httpcore import request
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from rest_framework.parsers import MultiPartParser, FormParser
from .models import BirdIdentifySession, BirdCandidate, Photo, Species, Log
from .serializers import BirdCandidateSerializer, BirdIdentifySessionSerializer, UploadBirdPhotoSerializer, SpeciesSummarySerializer, LogItemSerializer, ObservationUploadSerializer 
from .services.identify import identify_bird
from .utils.geocode import normalize_area_from_latlon
from .utils.supabase_storage import get_public_url

from integrations.supabase_client import supabase

from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS

class TempTestView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            image = request.data.get('image')
            out = identify_bird(image)
            print(f'out: {out}')
            return Response({"list" : out}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)