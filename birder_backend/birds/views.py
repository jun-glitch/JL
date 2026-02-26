import uuid
from datetime import datetime

import traceback
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

# 세션 불필요
"""
class IdentifyView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        # 1) 이미지 파일 받기
        image = request.FILES.get("image")
        if not image:
            return Response({"detail": "image file required"}, status=status.HTTP_400_BAD_REQUEST)
        
        session = BirdIdentifySession.objects.create(
            user=request.user,
            image_url=None,           
            is_finished=False,
            current_index=0,
        )

        try:
            top5 = identify_bird(image, supabase=supabase)  
            try:
                image.seek(0)
            except Exception:
                pass

            if not top5:
                session.delete()
                return Response({"detail": "no candidates found"}, status=status.HTTP_502_BAD_GATEWAY)
            
        except Exception as e:
            session.delete()
            print(f"Identification error: {e}")
            print(traceback.format_exc())
            return Response({"detail": f"identification failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        normalized = []
        for i, c in enumerate(top5[:5], start=1):
            if isinstance(c, dict):
                normalized.append({**c, "rank": int(c.get("rank", i))})
            else:
                normalized.append({"rank": i, "common_name_ko": str(c)})

        # 4) 후보 DB 저장
        for c in normalized:
            common = c.get("common_name_ko")
            if not common:
                continue

            BirdCandidate.objects.create(
                session=session,
                rank=c.get("rank", 0),
                common_name_ko=common,
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
        candidates_qs = session.candidates.order_by("rank")
        total = candidates_qs.count()

        if session.current_index >= total:
            session.is_finished = True
            session.save(update_fields=["is_finished"])
            return Response({"detail": "no more candidates", "is_finished": True, "reupload_required": True,})

        candidate = candidates_qs[session.current_index]
        return Response({
            "session_id": session.id,
            "index": session.current_index,
            "candidate": BirdCandidateSerializer(candidate).data,
        })
"""

# 사진 저장 api
class UploadBirdPhotoView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        image = request.data.get('image')

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
            supabase.storage.from_(settings.SUPABASE_STORAGE_BUCKET).upload(
                path=f"{request.user.id}/{file_name}",
                file=file_content,
                file_options={"content-type": image.content_type}
            )

            # 업로드된 파일의 Public URL 가져오기
            image_url = supabase.storage.from_(settings.SUPABASE_STORAGE_BUCKET).get_public_url(f'{request.user.id}/{file_name}')

        except Exception as e:
            return Response({"message" : f"Supabase Storage upload failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # 3) photo 테이블에 인스턴스 추가
        try:
            photo_data = {
                "s_filenum" : image_url,
                "latitude" : lat,
                "longitude" : lng,
                "obs_date" : obs_date.isoformat() if obs_date else None
            }
        
            db_photo_res = supabase.table("photo").insert(photo_data).execute()
            photo_num = db_photo_res[0].get('photo_num')
        except Exception as e:
            return Response({"message" : f"Supabase Photo table upload failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        image.seek(0)

        # ai에 새 사진 판별 요청
        try:

            candidates = identify_bird(image) # rank, species_code, common_name_ko, scientific_name, confidence, wikimedia_image_url

            # 추가) 후보가 반환되지 않은 경우...


            for candidate in candidates:
                print(candidate)
                species_code = candidate['species_code']
                print(species_code)
                detail = supabase.table('species').select('detail').eq('species_code', species_code).single().execute()
                print(detail)
                if detail:
                    candidate['detail'] = detail
        
        except Exception as e:
            return Response({"message" : f"AI identification Error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({
            "candidates" : candidates,
            "photo_num" : photo_num
        }, status=status.HTTP_200_OK)


# 사용자가 선택한 후보 새에 대해 log 테이블에 저장하는 View
class IdentifyAnswerView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        photo_num = request.data.get('photo_num')
        species_code = request.data.get('species_code') # 만약 후보가 선택되지 않았다면 None

        if not species_code: # 선택된 후보가 없는 경우
            try:
                del_res = supabase.table('photo').delete().eq('photo_num', photo_num).execute() # 이미 저장된 사용자가 업로드한 사진에 대해 photo 테이블 인스턴스 삭제
                img_url = del_res.data[0].get('s_filenum')

                file_path = img_url.split(f'{settings.SUPABASE_STORAGE_BUCKET}/')[-1]

                supabase.storage.from_(settings.SUPABASE_STORAGE_BUCKET).remove([file_path]) # storage에 저장된 사용자가 업로드한 사진 삭제
                return Response({"message" : "업로드된 사진이 삭제되었습니다."}, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({"message" : f"업로드된 사진 삭제 중 에러 발생: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 4) log 테이블에 인스턴스 추가
        try:
            log_data = {
                "photo_num" : photo_num,
                "species_code" : species_code,
                "reg_date" : datetime.now().isoformat(),
                "id" : request.user.id
            }

            supabase.table("log").insert(log_data).execute()
        except Exception as e:
            return Response({"message" : f"Supabase log table upload failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({"message" : "로그 추가가 완료되었습니다."},status=status.HTTP_201_CREATED)

# 지역별 누적 관측 횟수 뷰    
class AreaSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            region = request.query_params.get('region')
            district = request.query_params.get('district')
            if not region:
                return Response({"message" : "검색할 지역명을 선택해주세요."}, status=status.HTTP_400_BAD_REQUEST)
            
            region_map = {
                "충남": "충청남도",
                "충북": "충청북도",
                "경남": "경상남도",
                "경북": "경상북도",
                "전남": "전라남도",
                "전북": "전라북도"
            }

            region = region_map.get(region, region)
            
            response = supabase.rpc('get_area_observation_summary', {'region' : region, 'district' : district}).execute()

            return Response({
                "region" : region,
                "district" : district,
                "list" : response.data
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"Area search failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 특정 지역 + 종의 관측 로그 목록 뷰    
class AreaSpeciesLogsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            region = request.query_params.get("region")
            district = request.query_params.get("district")
            species_code = request.query_params.get('species_code')
            start = request.query_params.get('start')
            end = request.query_params.get('end')
            # limit = int(request.query_params.get("limit", 20))
            # offset = int(request.query_params.get("offset", 0))

            print(f'전체 파라미터: {request.query_params}')
            if not region or not district:
                return Response({"message" : "검색할 지역명을 선택해주세요."}, status=status.HTTP_400_BAD_REQUEST)
            
            if not species_code:
                return Response({"message" : "검색할 새 종 코드가 비어있습니다."}, status=status.HTTP_400_BAD_REQUEST)
            
            species_res = supabase.table('species').select('species_code', 'common_name', 'scientific_name').eq('species_code', species_code).single().execute()

            response = species_res.data
            region_map = {
                "충남": "충청남도",
                "충북": "충청북도",
                "경남": "경상남도",
                "경북": "경상북도",
                "전남": "전라남도",
                "전북": "전라북도"
            }

            region = region_map.get(region, region)

            logs_res = supabase.rpc('get_area_observation_detail', {
                'region' : region, 'district' : district, 'p_species_code' : species_code, 'p_start_date' : start, 'p_end_date' : end
                }).execute()

            response['records'] =  logs_res.data if logs_res.data else []

            return Response(response, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {"message": f"Area species logs failed: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# 종 관측 검색 시 일치하는 종 반환 뷰
class SpeciesSearchView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            # 프론트에서 보내는 검색 파라미터 읽기
            kwd = request.query_params.get("kwd")

            if not kwd:
                return Response({"message" : "검색할 종을 입력해주세요"}, status=status.HTTP_400_BAD_REQUEST)
            
            response = supabase.table('species').select('species_code', 'common_name', 'scientific_name', 'log!inner(species_code)').or_(f'common_name.ilike.%{kwd}%,scientific_name.ilike.%{kwd}%').execute()

            return Response({"list" : response.data}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"{kwd} 에 해당하는 종 검색 중 에러 발생: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 특정 종 누적 관측 지도 뷰
class SpeciesSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            kwd = request.query_params.get('species_code')
            start = request.query_params.get('start')
            end = request.query_params.get('end')

            if not kwd:
                return Response({"message" : "관측 로그를 검색할 새 종을 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)

            species_res = supabase.table('species').select('species_code', 'common_name', 'scientific_name'
                ).eq('species_code', kwd).single().execute()
            species_info = species_res.data

            # log_num, species_code, common_name, scientific_name, longitude, latitude, location, obs_date, s_fileNum
            log_res = supabase.rpc("get_logs_by_species_code", {"p_species_code": kwd, 'p_start_date' : start, 'p_end_date' : end}).execute()
            result = log_res.data

            observation_count = result.get('observation_count', 0)
            records = result.get('logs', [])

            if not records:
                return Response({
                    "observation_count" : 0,
                    "records" : []
                }, status=status.HTTP_200_OK) # 검색된 로그가 없는 경우 빈 배열 전송
            
            species_info['observation_count'] = observation_count
            species_info['records'] = records

            return Response(species_info, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"Species search failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
                "photo_url": getattr(photo, "image_url", None) if photo else None,
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