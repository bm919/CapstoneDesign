from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta

from SQLDB.models import (
    CustomUser, WasteImage, VectorMetadata,
    Feedback, ChatHistory, FavoriteChat
)

class Command(BaseCommand):
    help = '1일 이상 비활성화된 유저와 관련 데이터 자동 삭제'

    def handle(self, *args, **kwargs):
        threshold = timezone.now() - timedelta(days=1)
        users_to_delete = CustomUser.objects.filter(is_active=False, deactivated_at__lte=threshold)

        deleted_count = 0

        for user in users_to_delete:
            images = WasteImage.objects.filter(user=user)
            VectorMetadata.objects.filter(waste_image__in=images).delete()
            ChatHistory.objects.filter(waste_image__in=images).delete()
            ChatHistory.objects.filter(user=user).delete()
            FavoriteChat.objects.filter(user=user).delete()
            Feedback.objects.filter(user=user).delete()
            images.delete()
            user.delete()
            deleted_count += 1

        self.stdout.write(self.style.SUCCESS(f"{deleted_count}명의 유저와 관련 데이터를 삭제했습니다."))

