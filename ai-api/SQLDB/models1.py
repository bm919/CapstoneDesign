# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models
from django.db.models import JSONField
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings




class ChatHistory(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    message_text = models.TextField()
    response_text = models.TextField()
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'chat_history'




class FavoriteChat(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    chat = models.ForeignKey(ChatHistory, models.DO_NOTHING, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'favorite_chat'


class Feedback(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    image = models.ForeignKey('WasteImage', models.DO_NOTHING, blank=True, null=True)
    message = models.CharField(max_length=200)
    status = models.CharField(max_length=50, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    response = models.TextField(blank=True, null=True)
    type = models.CharField(max_length=50)

    class Meta:
        managed = True
        db_table = 'feedback'


class Location(models.Model):
    region_name = models.CharField(unique=True, max_length=255)
    disposal_day = models.CharField(max_length=100, blank=True, null=True)
    disposal_place = models.CharField(max_length=255, blank=True, null=True)
    external_bag_allowed = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'location'


class PolicyUpdate(models.Model):
    location = models.ForeignKey(Location, models.DO_NOTHING, blank=True, null=True)
    waste_category = models.ForeignKey('WasteCategory', models.DO_NOTHING, blank=True, null=True)
    policy_text = models.TextField()
    updated_at = models.DateTimeField(blank=True, null=True)
    pdf_url = models.TextField(blank=True, null=True)
    reference_url = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'policy_update'


"""class Users(models.Model):
    username = models.CharField(max_length=100)
    email = models.CharField(unique=True, max_length=255)
    password_hash = models.CharField(max_length=255)
    home_location = models.ForeignKey(Location, models.DO_NOTHING, blank=True, null=True)
    current_location = models.ForeignKey(Location, models.DO_NOTHING, related_name='users_current_location_set', blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'users'
"""

class WasteCategory(models.Model):
    name = models.CharField(unique=True, max_length=100)
    description = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'waste_category'


class WasteImage(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, models.DO_NOTHING)
    image_url = models.CharField(max_length=255)
    prediction = models.ForeignKey(WasteCategory, models.DO_NOTHING, blank=True, null=True)
    confidence = models.FloatField(blank=True, null=True)
    uploaded_at = models.DateTimeField(blank=True, null=True)
    image = models.ImageField(upload_to='waste_images/')

    class Meta:
        managed = True
        db_table = 'waste_image'

class VectorMetadata(models.Model):
    waste_image = models.ForeignKey(WasteImage, on_delete=models.CASCADE, null=True, blank=True)
    vector_id = models.CharField(max_length=100, unique=True)
    dimension = models.IntegerField(blank=True, null=True)  # 벡터 차원 수 (예: 512, 768)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'vector_metadata'
        managed = True


class CustomUserManager(BaseUserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError('이메일은 필수입니다.')
        email = self.normalize_email(email)
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)  # 🔐 비밀번호 자동 해시
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_staff', True)
        return self.create_user(email, username, password, **extra_fields)

class CustomUser(AbstractBaseUser, PermissionsMixin):
    username = models.CharField(max_length=100, unique=True)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    home_location = models.ForeignKey('Location', models.DO_NOTHING, null=True, blank=True)
    current_location = models.ForeignKey('Location', models.DO_NOTHING, related_name='users_current_location_set', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_login = models.DateTimeField(blank=True, null=True)  # ✅ 추가 추천
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    is_superuser = models.BooleanField(default=False)


    objects = CustomUserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    class Meta:
        db_table = 'users'
        managed = True  # 기존 테이블 그대로 사용

