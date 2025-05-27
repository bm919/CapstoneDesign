# api/serializers/favorite_serializer.py

from rest_framework import serializers
from SQLDB.models import FavoriteChat, ChatHistory

# ✅ 목록용: 라벨 + 생성일자만
class FavoriteChatListSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField()
    label = serializers.CharField(source='chat.label')
    region = serializers.CharField(source='chat.region')
    created_at = serializers.DateTimeField(source='chat.created_at')

    class Meta:
        model = FavoriteChat
        fields = ['id', 'label', 'region', 'created_at']
    def get_waste_type(self, obj):
        try:
            return obj.chat.waste_image.prediction.name  # prediction.name 접근
        except AttributeError:
            return None

    def get_created_at(self, obj):
        return obj.chat.created_at if obj.chat else None

