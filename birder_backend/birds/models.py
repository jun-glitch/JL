from django.db import models
from django.contrib.auth.models import User

# 새 식별 세션 : 사용자가 새 사진을 올리고 후보군을 받아보는 세션 기록용(한 번 식별 시도할 때마다 하나의 세션 생성)
class BirdIdentifySession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="identify_sessions")
    image = models.ImageField(upload_to="identify/")  # 사용자가 업로드한 새 사진
    current_index = models.IntegerField(default=0)    # 지금 몇 번째 후보를 보고 있는지(0~4)
    is_finished = models.BooleanField(default=False)  # 식별 완료 여부
    selected_candidate = models.ForeignKey(
        "BirdCandidate",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="+",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"IdentifySession<{self.id}, user={self.user.username}>"

# 새 후보군 : 한 식별 세션에서 제시되는 최대 5개의 후보 새 정보 저장용
class BirdCandidate(models.Model):
    session = models.ForeignKey(BirdIdentifySession, on_delete=models.CASCADE, related_name="candidates")
    rank = models.IntegerField()  # 후보 순위(0~4)
    common_name_ko = models.CharField(max_length=100)
    scientific_name = models.CharField(max_length=100, blank=True, default="")
    short_description = models.TextField(blank=True, default="")
    wikimedia_image_url = models.URLField(blank=True, default="")

    def __str__(self):
        return f"Candidate<{self.rank}: {self.common_name_ko}>"

class Species(models.Model):
    # ERD의 species_code 같은 역할을 Django id가 대신
    common_name = models.CharField(max_length=100)    
    scientific_name = models.CharField(max_length=100) 
    # 위키미디어 대표 이미지 url, 분류(목/과/속/종), 영문명 등 이후에 추가

    def __str__(self):
        return f"{self.common_name} ({self.scientific_name})"

class Photo(models.Model):
    # ERD의 photo_num 역할
    image = models.ImageField(upload_to="uploads/birds/")  # supabase 전환 시 변경 필요
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    obs_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Photo<{self.id}>"


class Log(models.Model):
    # ERD의 log.num 역할
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="logs")
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, related_name="logs")
    species = models.ForeignKey(Species, on_delete=models.PROTECT, related_name="logs")

    # 업로드 시점에 정규화된 행정구역 문자열 저장 -> ERD 변경이나, supabase 구조에 따라 조정 가능
    location = models.CharField(max_length=100, db_index=True)

    rec_date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Log<{self.id}> {self.user.username} {self.species.common_name}"
