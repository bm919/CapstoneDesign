from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings


# 사용자 정의 유저 매니저
class CustomUserManager(BaseUserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError('이메일은 필수입니다.')
        email = self.normalize_email(email)
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_staff', True)
        return self.create_user(email, username, password, **extra_fields)


# 사용자 테이블
class CustomUser(AbstractBaseUser, PermissionsMixin):
    username = models.CharField(max_length=100, unique=True)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    current_location = models.ForeignKey('Location', models.DO_NOTHING, related_name='users_current_location_set', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_login = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

    objects = CustomUserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    class Meta:
        db_table = 'users'
        managed = True


# 지역 정보
class Location(models.Model):
    region_name = models.CharField(unique=True, max_length=255)
    disposal_day = models.CharField(max_length=100, blank=True, null=True)
    disposal_place = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'location'


# 폐기물 이미지
class WasteImage(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    image_url = models.CharField(max_length=255)
    confidence = models.FloatField(blank=True, null=True)
    uploaded_at = models.DateTimeField(blank=True, null=True)
    image = models.ImageField(upload_to='waste_images/')
    chat = models.OneToOneField(
        'ChatHistory',
        on_delete=models.DO_NOTHING,
        null=True,
        blank=True
    )

    class Meta:
        managed = True
        db_table = 'waste_image'


# 벡터 메타데이터
class VectorMetadata(models.Model):
    waste_image = models.ForeignKey(WasteImage, on_delete=models.CASCADE, null=True, blank=True)
    metadata = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    vector_id = models.CharField(max_length=255) 
    dimension = models.IntegerField(null=True)

    class Meta:
        db_table = 'vector_metadata'
        managed = True


# 채팅 기록
class ChatHistory(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    waste_image = models.ForeignKey(WasteImage, models.DO_NOTHING, null=True, blank=True)
    region = models.CharField(max_length=100, blank=True, null=True)   # 지역명 추가
    label = models.CharField(max_length=100, blank=True, null=True)    # 분류 추가
    response_text = models.TextField()                                 # 정책 내용(분리수거규정)만 저장
    reward_text = models.TextField(blank=True, null=True)  # 보상안내 추가
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = True
        db_table = 'chat_history'

# 즐겨찾기
class FavoriteChat(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    chat = models.ForeignKey(ChatHistory, models.DO_NOTHING, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'favorite_chat'


# 피드백
class Feedback(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    image = models.ForeignKey(WasteImage, models.DO_NOTHING, blank=True, null=True)
    message = models.CharField(max_length=200)
    status = models.CharField(max_length=50, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    response = models.TextField(blank=True, null=True)
    type = models.CharField(max_length=50)

    class Meta:
        managed = True
        db_table = 'feedback'


# 폐기물 카테고리
class WasteCategory(models.Model):
    name = models.CharField(unique=True, max_length=100)
    description = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'waste_category'


# 정책 업데이트
class PolicyUpdate(models.Model):
    location = models.ForeignKey(Location, models.DO_NOTHING, blank=True, null=True)
    waste_category = models.ForeignKey(WasteCategory, models.DO_NOTHING, blank=True, null=True)
    policy_text = models.TextField()
    updated_at = models.DateTimeField(blank=True, null=True)
    pdf_url = models.TextField(blank=True, null=True)
    reference_url = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'policy_update'

