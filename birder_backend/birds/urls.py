from django.urls import path
from .views import (
    IdentifyView,
    IdentifyNextView,
    IdentifyAnswerView,
    UploadBirdPhotoView,
    AreaSpeciesSummaryView,
    AreaSpeciesLogsView,
)   

urlpatterns = [
    # 새 식별 관련 엔드포인트
    path("identify/", IdentifyView.as_view(), name="bird_identify"),
    path("identify/<int:session_id>/next/", IdentifyNextView.as_view(), name="bird_identify_next"),
    path("identify/<int:session_id>/answer/", IdentifyAnswerView.as_view(), name="bird_identify_answer"),

    # 새 사진 업로드 엔드포인트
    # 사진 업로드 + 위경도 정규화 + 로그 생성
    path("upload/", UploadBirdPhotoView.as_view(), name="birds_upload"),
    # 지역명으로 종별 누적 관측 횟수
    path("areas/<str:area>/species/", AreaSpeciesSummaryView.as_view(), name="area_species_summary"),
    # 특정 지역 + 종의 관측 로그 목록
    path("areas/<str:area>/species/<int:species_id>/logs/", AreaSpeciesLogsView.as_view(), name="area_species_logs"),
]

