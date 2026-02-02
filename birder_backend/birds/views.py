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

from .models import BirdIdentifySession, BirdCandidate, Photo, Species, Log
from .serializers import BirdCandidateSerializer, BirdIdentifySessionSerializer, UploadBirdPhotoSerializer, SpeciesSummarySerializer, LogItemSerializer, ObservationUploadSerializer 
from .services.identify import gpt_top5_candidates, build_candidates_with_images
from .utils.geocode import normalize_area_from_latlon
from .utils.supabase_storage import get_public_url

from integrations.supabase_client import supabase

from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS

# EXIF에서 위도/경도를 실수형으로 변환하는 헬퍼 함수
def get_decimal_from_dms(dms, ref):
    degrees = dms[0]
    minutes = dms[1] / 60.0
    seconds = dms[2] / 3600.0
    if ref in ['S', 'W']:
        return -float(degrees + minutes + seconds)
    return float(degrees + minutes + seconds)

# 이미지에서 위치정보&날짜정보 추출하는 함수
def extract_exif_data(image_file):
    lat, lng, obs_date = None, None, None
    try:
        # 이미지 열기
        img = Image.open(image_file)
        exif_data = img._getexif()
        if not exif_data:
            return lat, lng, obs_date

        gps_info = {}
        for tag, value in exif_data.items():
            decoded = TAGS.get(tag, tag)

            # 날짜정보 추출
            if decoded == "DateTimeOriginal":
                try:
                    obs_date = datetime.strptime(value, "%Y:%m:%d %H:%M:%S")
                except ValueError:
                    pass

            # 위치정보 추출
            if decoded == "GPSInfo":
                for t in value:
                    sub_tag = GPSTAGS.get(t, t)
                    gps_info[sub_tag] = value[t]

        if "GPSLatitude" in gps_info and "GPSLatitudeRef" in gps_info:
            lat = get_decimal_from_dms(gps_info["GPSLatitude"], gps_info["GPSLatitudeRef"])
            lng = get_decimal_from_dms(gps_info["GPSLongitude"], gps_info["GPSLongitudeRef"])
    except Exception as e:
        print(f"EXIF 추출 에러: {e}")
    return lat, lng, obs_date

class IdentifyView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # 1) 이미지 파일 받기
        image = request.FILES.get("image")
        if not image:
            return Response({"detail": "image file required"}, status=status.HTTP_400_BAD_REQUEST)
        
        # 2) 식별 세션 생성
        file_path = f"identify/{uuid.uuid4().hex}_{image.name}"
        image_bytes = image.read()
        image.seek(0)

        upload_res = supabase.storage.from_("bird_photos").upload(
            file_path,
            image_bytes,
            {"content-type": image.content_type or "image/jpeg"},
        )

        # 업로드 실패 방어
        if getattr(upload_res, "error", None):
            return Response({"detail": "supabase upload failed"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        image_url = get_public_url("bird_photos", file_path)
        if not image_url:
            return Response({"detail": "failed to get public url"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        session = BirdIdentifySession.objects.create(user=request.user, image_url=image_url)
        
        # 3) Top5 후보 생성
        top5 = gpt_top5_candidates(session.image_url)
        top5 = build_candidates_with_images(top5)

        # 4) 후보 DB 저장
        for c in top5:
            BirdCandidate.objects.create(
                session=session,
                rank=c["rank"],
                common_name_ko=c["common_name_ko"],
                scientific_name=c.get("scientific_name", ""),
                short_description=c.get("short_description", ""),
                wikimedia_image_url=c.get("wikimedia_image_url", ""),
            )

        # 5) 세션 + 후보 전체 반환 (프론트에서 후보 리스트를 한꺼번에 받기 위해)
        return Response(BirdIdentifySessionSerializer(session).data, status=status.HTTP_201_CREATED)

# 사용자가 다음 후보 새를 요청하는 뷰
class IdentifyNextView(APIView):
    permission_classes = [IsAuthenticated]

    # GET 요청 시 다음 후보 새 반환
    def get(self, request, session_id: int):
        session = get_object_or_404(BirdIdentifySession, id=session_id, user=request.user)

        if session.is_finished:
            # 이미 끝난 세션이면 확정/종료 상태 알려주기
            return Response(BirdIdentifySessionSerializer(session).data)

        # 다음 후보 새 반환
        candidates = session.candidates.order_by("rank")
        if session.current_index >= candidates.count():
            session.is_finished = True
            session.save()
            return Response({"detail": "no more candidates", "is_finished": True, "reupload_required": True,})

        candidate = candidates[session.current_index]
        return Response({
            "session_id": session.id,
            "index": session.current_index,
            "candidate": BirdCandidateSerializer(candidate).data,
        })

# 사용자가 후보 새에 대해 처리하는 view
class IdentifyAnswerView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, session_id: int):
        session = get_object_or_404(BirdIdentifySession, id=session_id, user=request.user)

        answer = request.data.get("answer")  # "yes" / "no"
        if answer not in ["yes", "no"]:
            return Response({"detail": "answer must be 'yes' or 'no'"}, status=status.HTTP_400_BAD_REQUEST)

        candidates = session.candidates.order_by("rank")
        total = candidates.count()

        if session.current_index >= total:
            session.is_finished = True
            session.save()
            return Response({"detail": "no more candidates", "is_finished": True})

        current_candidate = candidates[session.current_index]

        # answer == "yes" → 확정
        if answer == "yes":
            session.selected_candidate = current_candidate
            session.is_finished = True
            session.save()
           
            photo = Photo.objects.create(
               image=session.image,
               latitude=session.latitude,
               longitude=session.longitude,
               obs_date=session.obs_date,
            )

            location = "UNKNOWN"
            if session.latitude is not None and session.longitude is not None:
                try:
                    location = normalize_area_from_latlon(float(session.latitude), float(session.longitude))
                except Exception:
                    location = "UNKNOWN"

            log = Log.objects.create(
                user=request.user,
                photo=photo,
                species=current_candidate.species,
                location=location,
            )

            return Response({
                "detail": "selected",
                "selected": BirdCandidateSerializer(current_candidate).data,
                "is_finished": True,
            })

        # answer == "no" → 다음 후보로
        session.current_index += 1

        if session.current_index >= total:
            session.is_finished = True
            session.save()
            return Response({
                "detail": "no more candidates",
                "is_finished": True,
                "reupload_required": True,
                "next_index": session.current_index,
        })

        session.save()
        return Response({
            "detail": "next",
            "next_index": session.current_index,
            "is_finished": False,
        })

# 변경된 ERD & supabase 연동 수정 완료
class UploadBirdPhotoView(APIView):
    permission_classes = [IsAuthenticated]

    
    def post(self, request):
        serializer = UploadBirdPhotoSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        image = data["image"]

        # 1) 이미지에서 위치정보 추출
        lat, lng, obs_date = extract_exif_data(image)
        image.seek(0)

        # 2) Supabase Storage에 이미지 업로드
        try:
            file_ext = image.name.split('.')[-1]
            file_name = f"{uuid.uuid4()}.{file_ext}"
            
            # 파일을 바이너리로 읽기
            file_content = image.read()
            
            # .upload(경로, 파일데이터, 옵션)
            storage_response = supabase.storage.from_(settings.SUPABASE_STORAGE_BUCKET).upload(
                path=file_name,
                file=file_content,
                file_options={"content-type": image.content_type}
            )

            # 업로드된 파일의 Public URL 가져오기
            image_url = supabase.storage.from_(settings.SUPABASE_STORAGE_BUCKET).get_public_url(file_name)
        except Exception as e:
            return Response({"detail" : f"Storage upload failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # 3) photo 테이블에 인스턴스 추가
        try:
            photo_data = {
                "s_fileNum" : image_url,
                "latitude" : lat,
                "longitude" : lng,
                "obs_date" : obs_date.isoformat() if obs_date else None
            }
        
            db_photo_res = supabase.table("photo").insert(photo_data).execute()
        except Exception as e:
            return Response({"detail" : f"Supabase Photo table upload failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 4) log 테이블에 인스턴스 추가
        try:
            if not db_photo_res.data : 
                return Response({"error" : "Failed to retrieve saved photo data"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            photo_num = db_photo_res.data[0]["photo_num"]

            log_data = {
                "photo_num" : photo_num,
                "species_code" : data["species_code"],
                "reg_date" : datetime.now().isoformat(),
                "id" : request.user.id
            }

            db_log_res = supabase.table("log").insert(log_data).execute()
        except Exception as e:
            return Response({"detail" : f"Supabase log table upload failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response(
            {
                "log_id": db_log_res.data[0]["log_num"],
                "photo_id": photo_num,
                "image_url": image_url,
            },
            status=status.HTTP_201_CREATED,
        )

# 지역별 누적 관측 횟수 뷰    
class AreaSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, area: str):
        try:
            response = supabase.table('log').select(
                "species_code, species:species_code(common_name, scientific_name), "
                "photo:photo_num!inner(location)"
            ).ilike("photo.location", f"{area}%").execute()

            if not logs:
                return Response([], status=status.HTTP_200_OK) # 검색된 로그가 없는 경우 빈 배열 전송

            logs = response.data
            
            logs = response.data

            summary_dict = {}
            for entry in logs:
                code = entry["species_code"]
                species_info = entry.get("species")

                if not species_info:
                    continue

                if code not in summary_dict:
                    summary_dict[code] = {
                        "species_code" : code,
                        "common_name" : species_info["common_name"],
                        "scientific_name" : species_info["scientific_name"],
                        "total_count" : 0
                    }
                summary_dict[code]["total_count"] += 1
            
            payload = sorted(
                summary_dict.values(),
                key=lambda x: x["total_count"],
                reverse=True
            )

            return Response(payload, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"detail" : f"Area search failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 종별 누적 관측 횟수 뷰
class SpeciesSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, species_code: str):
        try:
            response = supabase.table('log').select(
                "log_num, species_code, reg_date species:species_code(common_name, scientific_name), "
                "photo:photo_num!inner(s_fileNum, obs_date, latitude, longitude, location)"
            ).ilike("species_code", species_code).filter("photo.latitude", "not.is", "null"
            ).filter("photo.longitude", "not.is", "null").execute()

            if not logs:
                return Response([], status=status.HTTP_200_OK) # 검색된 로그가 없는 경우 빈 배열 전송
            
            logs = response.data

            first_entry = logs[0]
            species_info = first_entry.get('species')

            payload = {
                "species_code" : first_entry['species_code'],
                "common_name" : species_info['common_name'] if species_info else None,
                "scientific_name" : species_info['scientific_name'] if species_info else None,
                "records" : []
            }
            for entry in logs:
                photo = entry.get('photo')
                if not photo or photo.get('latitude') is None or photo.get('longitude') is None:
                    continue

                payload['records'].append({
                    "latitude" : photo['latitude'],
                    "longitude" : photo['longitude'], # 값이 없을 경우 KeyError
                    "location" : photo['location'],
                    "image_url" : photo['s_fileNum'], # 이미지 url(supabase storage url)
                    "date" : photo['obs_date'] if photo['obs_date'] else entry['reg_date'] # 사진의 촬영일자가 없을 경우 로그 등록일자
                })
            
            return Response(payload, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"detail" : f"Species search failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 특정 지역 + 종의 관측 로그 목록 뷰    
class AreaSpeciesLogsView(APIView):    
    permission_classes = [IsAuthenticated]

    def get(self, request, area: str, species_code: str):
        logs = (
            Log.objects
            .select_related("photo", "species")
            .filter(
                user=request.user,
                photo__area_full__startswith=area,
                species__species_code=species_code
            )
            .order_by("-photo__obs_date", "-reg_date", "-num")
        )

        items = []
        for log in logs:
            photo = log.photo
            items.append({
                "log_id": getattr(log, "num", log.id),
                "location": getattr(photo, "area_full", ""),
                "rec_date": getattr(log, "reg_date", None),  
                "obs_date": getattr(photo, "obs_date", None),
                "latitude": float(photo.latitude) if photo and photo.latitude is not None else None,
                "longitude": float(photo.longitude) if photo and photo.longitude is not None else None,
                "image_url": request.build_absolute_uri(photo.image.url) if (photo and getattr(photo, "image", None)) else None,
            })

        out = LogItemSerializer(items, many=True)
        return Response(out.data, status=status.HTTP_200_OK)

# 지도 점(소수점 4자리까지 좌표 라운딩) 
class SpeciesMapPointsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        species_code = request.query_params.get("species_code")
        start = request.query_params.get("start")
        end = request.query_params.get("end")

        if not (species_code and start and end):
            return Response({"detail": "species_code, start, end are required."}, status=400)

        species = Species.objects.filter(species_code=species_code).first()
        if not species:
            return Response({"detail": "species not found."}, status=404)

        qs = (
            Log.objects
            .filter(
                user=request.user,
                species__species_code=species_code,
                photo__obs_date__date__range=(start, end),
            )
            .exclude(photo__latitude__isnull=True)
            .exclude(photo__longitude__isnull=True)
            .annotate(
                grid_lat=Round("photo__latitude", 4),
                grid_lng=Round("photo__longitude", 4),
            )
            .values("grid_lat", "grid_lng")
            .annotate(count=Count("num"))
            .order_by("-count")
        )

        points = [
            {
                "grid_lat": float(row["grid_lat"]),
                "grid_lng": float(row["grid_lng"]),
                "count": row["count"],
            }
            for row in qs
        ]

        return Response({
            "species": {
                "species_code": species.species_code,
                "common_name": species.common_name,
                "scientific_name": species.scientific_name,
            },
            "start": start,
            "end": end,
            "points": points,
        })

# 특정 격자점의 관측 기록 뷰
class SpeciesMapRecordsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # 특정 격자점(grid_lat/grid_lng) 클릭 시 해당 격자에 포함된 관측 기록 반환
        species_code = request.query_params.get("species_code")
        start = request.query_params.get("start")
        end = request.query_params.get("end")
        grid_lat = request.query_params.get("grid_lat")
        grid_lng = request.query_params.get("grid_lng")

        if not (species_code and start and end and grid_lat and grid_lng):
            return Response({"detail": "species_code, start, end, grid_lat, grid_lng are required."}, status=400)

        try:
            grid_lat = float(grid_lat)
            grid_lng = float(grid_lng)
        except ValueError:
            return Response({"detail": "grid_lat/grid_lng must be numbers."}, status=400)

        logs_qs = (
            Log.objects
            .filter(
                user=request.user,
                species__species_code=species_code,
                photo__obs_date__date__range=(start, end),
            )
            .exclude(photo__latitude__isnull=True)
            .exclude(photo__longitude__isnull=True)
            .annotate(
                grid_lat_4=Round("photo__latitude", 4),
                grid_lng_4=Round("photo__longitude", 4),
            )
            .filter(grid_lat_4=grid_lat, grid_lng_4=grid_lng)
            .select_related("photo")
            .order_by("-photo__obs_date", "-reg_date", "-num")
        )

        records = []
        for log in logs_qs:
            photo = log.photo
            records.append({
                "log_id": getattr(log, "num", log.id),
                "obs_date": getattr(photo, "obs_date", None),
                "area_full": getattr(photo, "area_full", ""),
                "latitude": float(photo.latitude) if photo and photo.latitude is not None else None,
                "longitude": float(photo.longitude) if photo and photo.longitude is not None else None,
                "photo_url": request.build_absolute_uri(photo.image.url) if (photo and getattr(photo, "image", None)) else None,
            })

        return Response({
            "grid": {"grid_lat": grid_lat, "grid_lng": grid_lng},
            "records": records,
        })

class ObservationUploadView(APIView):
    permission_classes = [IsAuthenticated]

    # multipart/form-data 로 받기
    def post(self, request):
        serializer = ObservationUploadSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        result = serializer.save()
        return Response(result, status=status.HTTP_201_CREATED)