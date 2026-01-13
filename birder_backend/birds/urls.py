from django.urls import path
from .views import IdentifyView, IdentifyNextView, IdentifyAnswerView

urlpatterns = [
    path("identify/", IdentifyView.as_view(), name="bird_identify"),
    path("identify/<int:session_id>/next/", IdentifyNextView.as_view(), name="bird_identify_next"),
    path("identify/<int:session_id>/answer/", IdentifyAnswerView.as_view(), name="bird_identify_answer"),
]

