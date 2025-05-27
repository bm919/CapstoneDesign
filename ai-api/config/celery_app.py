from __future__ import absolute_import, unicode_literals
import os
from celery_app import Celery

# Django 세팅 모듈 설정
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('ai_api')

# Django settings에서 Celery 관련 설정 가져오기
app.config_from_object('django.conf:settings', namespace='CELERY')

# 모든 등록된 task 모듈 자동 탐지
app.autodiscover_tasks()

