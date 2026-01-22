from django.db import models
from django.contrib.auth.models import User

# 새 식별 세션 : 사용자가 새 사진을 올리고 후보군을 받아보는 세션 기록용(한 번 식별 시도할 때마다 하나의 세션 생성)
class BirdIdentifySession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="identify_sessions")
    image_url = models.ImageField(upload_to="identify/")  # 사용자가 업로드한 새 사진
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
    # ERD의 species_code 같은 역할을 Django id가 대신, ERD 수정되면 수정 필요
    species_code = models.BigAutoField(primary_key=True)
    common_name = models.CharField(max_length=100)    
    scientific_name = models.CharField(max_length=100) 
    # 위키미디어 대표 이미지 url, 분류(목/과/속/종), 영문명 등 이후에 추가

    def __str__(self):
        return f"{self.common_name} ({self.scientific_name})"

class Photo(models.Model):
    photo_num = models.BigAutoField(primary_key=True)
    
    image = models.ImageField(upload_to="uploads/birds/")  # supabase 전환 시 변경 필요
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    
    obs_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    grid_lat = models.DecimalField(max_digits=9, decimal_places=4, db_index=True)
    grid_lng = models.DecimalField(max_digits=9, decimal_places=4, db_index=True)

    def __str__(self):
        return f"Photo<{self.id}>"

class Species(models.Model):
    # supabase 구축 되면 조정 필요 
    species_code = models.BigAutoField(primary_key=True)
    common_name = models.CharField(max_length=100)
    scientific_name = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.common_name}({self.scientific_name})"

class Photo(models.Model):
    photo_num = models.BigAutoField(primary_key=True)

    # supabase 연동 시 수정 필요 
    image = models.ImageField(upload_to="uploads/")

    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    obs_date = models.DateTimeField()  # 촬영/관측 시각(프론트에서 받거나 업로드 시각 사용)

    # 업로드 시 역지오코딩 결과 저장
    area1 = models.CharField(max_length=50, blank=True, default="")  # 시/도
    area2 = models.CharField(max_length=50, blank=True, default="")  # 시/군/구
    area_full = models.CharField(max_length=120, blank=True, default="")  # 전체 문자열

    def __str__(self):
        return f"Photo<{self.photo_num}>"

# 관측 로그 = 사용자가 올린 사진 + 식별된 종 + 위치/시각 정보
class Log(models.Model):
    num = models.BigAutoField(primary_key=True)

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='logs')
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, related_name='logs')
    species = models.ForeignKey(Species, on_delete=models.SET_NULL, null=True, blank=True, related_name='logs')

    location = models.CharField(max_length=120, db_index=True, blank=True, default="")  # 역지오코딩된 위치명

    rec_date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Log<{self.num}> user={self.user_id} species={self.species_id}"
