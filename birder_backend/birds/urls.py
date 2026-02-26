from django.urls import path
from .views import (
    #IdentifyView,
    #IdentifyNextView,
    IdentifyAnswerView,
    UploadBirdPhotoView,
    AreaSummaryView,
    SpeciesSearchView,
    SpeciesSummaryView,
    AreaSpeciesLogsView,
    SpeciesMapPointsView,
    SpeciesMapRecordsView,
    ObservationUploadView,
)
from .views_fieldguide import FieldGuideView
from .views_species_detail import SpeciesObservationsView
from .views_map import MapPointsView

from .temp_testview import TempTestView

urlpatterns = [
    # 새 식별 관련 엔드포인트
    #path("identify/", IdentifyView.as_view(), name="bird_identify"),
    #path("identify/<int:session_id>/next/", IdentifyNextView.as_view(), name="bird_identify_next"),

    # 새 사진 업로드 엔드포인트
    # 사진 업로드 + 위경도 정규화 + photo 테이블 insert
    path("identify/photo/", UploadBirdPhotoView.as_view(), name="birds_upload"),
    path("identify/answer/", IdentifyAnswerView.as_view(), name="bird_identify_answer"),
    # 지역명으로 종별 누적 관측 횟수
    path("areas/search/", AreaSummaryView.as_view(), name="area_summary"),
    # 특정 지역 + 종의 관측 로그 목록
    path("areas/logs/", AreaSpeciesLogsView.as_view(), name="area_species_logs"),

    # 종명으로 지역별 누적 관측 횟수
    path("species/search/", SpeciesSearchView.as_view(), name="species_search"), # 사용자가 검색한 검색어에 해당하고 로그가 존재하는 종 리스트 반환
    path("species/map/", SpeciesSummaryView.as_view(), name="species_summary"), # 사용자가 종 리스트에서 선택한 특정 종의 관측 로그 반환

    # 종별 지도
    path("map/points/", SpeciesMapPointsView.as_view(), name="species_map_points"),
    path("map/records/", SpeciesMapRecordsView.as_view(), name="species_map_records"),

    # 관측 로그 업로드
    path("observations/upload/", ObservationUploadView.as_view(), name="observation_upload"),

    # 도감 메인(목별 그리드 + 관측 여부/대표사진)
    path("fieldguide/", FieldGuideView.as_view(), name="fieldguide"),

    # 종 상세(슬라이드 + 로그)
    path("species/<str:species_code>/observations/", SpeciesObservationsView.as_view(), name="species_observations"),
    
    # 피크민st 지도 API v2
    path("map/v2/points/", MapPointsView.as_view(), name="map_points_v2"),

    # test View
    path("test/", TempTestView.as_view(), name="temptest")
]
