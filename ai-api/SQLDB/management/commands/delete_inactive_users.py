from django.core.management.base import BaseCommand
from SQLDB.models import (
    CustomUser, WasteImage, VectorMetadata,
    Feedback, ChatHistory, FavoriteChat
)

class Command(BaseCommand):
    help = '비활성화된 사용자와 관련된 모든 데이터 삭제'

    def handle(self, *args, **kwargs):
        users_to_delete = CustomUser.objects.filter(is_active=False)

        for user in users_to_delete:
            images = WasteImage.objects.filter(user=user)
            VectorMetadata.objects.filter(waste_image__in=images).delete()
            ChatHistory.objects.filter(waste_image__in=images).delete()
            ChatHistory.objects.filter(user=user).delete()
            FavoriteChat.objects.filter(user=user).delete()
            Feedback.objects.filter(user=user).delete()
            images.delete()
            user.delete()

        self.stdout.write(self.style.SUCCESS(f"{users_to_delete.count()}명의 비활성화 계정이 삭제되었습니다."))

