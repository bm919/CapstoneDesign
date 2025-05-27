from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from api.views.base import AuthenticatedAPIView
from SQLDB.models import ChatHistory, FavoriteChat
from api.serializers.favorite_serializer import (
    FavoriteChatListSerializer
)

# ✅ 목록 조회: /favorite-chat/
class FavoriteChatListAPIView(AuthenticatedAPIView):
    def get(self, request):
        favorites = FavoriteChat.objects.filter(user=request.user).order_by('-chat__created_at')
        serializer = FavoriteChatListSerializer(favorites, many=True)
        return Response(serializer.data, status=200)

# ✅ 상세 조회: /favorite-chat/<id>/
class FavoriteChatDetailAPIView(AuthenticatedAPIView):
    def get(self, request, favorite_id):
        try:
            favorite = FavoriteChat.objects.select_related(
                'chat__waste_image'
            ).get(id=favorite_id, user=request.user)
        except FavoriteChat.DoesNotExist:
            return Response({"error": "즐겨찾기를 찾을 수 없습니다."}, status=404)

        chat = favorite.chat

        # 정책 안내(기본 내역)
        favorite_data = {
            "id": favorite.id,
            "label": chat.label,
            "region": chat.region,
            "image_url": chat.waste_image.image.url if chat.waste_image and chat.waste_image.image else None,
            "response_text": chat.response_text,
            "created_at": chat.created_at,
        }

        # 응답 딕셔너리 만들기
        response_dict = {"favorite": favorite_data}

        # 보상내역이 진짜로 존재할 때만 reward 키 포함
        if chat.reward_text and chat.reward_text.strip():
            response_dict["reward"] = {
                "reward_text": chat.reward_text,
                "checked": True
            }
        # else: reward 키 아예 없음

        return Response(response_dict, status=200)

# ✅ 등록/삭제: /favorite-chat-action/
class FavoriteChatActionAPIView(AuthenticatedAPIView):
    def post(self, request):
        chat_id = request.data.get("chat_id")
        if not chat_id:
            return Response({"error": "chat_id is required"}, status=400)

        try:
            chat = ChatHistory.objects.get(id=chat_id, user=request.user)
        except ChatHistory.DoesNotExist:
            return Response({"error": "Chat not found or not owned by you"}, status=404)

        favorite, created = FavoriteChat.objects.get_or_create(user=request.user, chat=chat)
        return Response({
            "status": "success",
            "message": "즐겨찾기에 추가되었습니다." if created else "이미 등록되어 있습니다.",
            "chat_id": chat.id
        }, status=201 if created else 200)

    def delete(self, request, favorite_id=None):
        if not favorite_id:
            return Response({"error": "favorite_id is required in URL"}, status=400)

        try:
            favorite = FavoriteChat.objects.get(user=request.user, id=int(favorite_id))
            favorite.delete()
            return Response({"message": "즐겨찾기에서 제거되었습니다."}, status=200)
        except FavoriteChat.DoesNotExist:
            return Response({"error": "즐겨찾기를 찾을 수 없습니다."}, status=404)