from django.db import models
from django.contrib.auth.models import User

# UserSettings model: 사용자 설정 저장용 -> 사용자 한 명당 하나의 설정 객체 생성
class UserSettings(models.Model):
    # 사용자가 삭제되면 설정도 함께 삭제
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="settings")
    # 앱 알림 허용 여부 (기본값: False)
    notifications_enabled = models.BooleanField(default=False)
    # 위치 정보 사용 허용 여부 (기본값: False)
    location_enabled = models.BooleanField(default=False)
    # 마지막 수정 시각 자동 기록
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Settings<{self.user.username}>"
