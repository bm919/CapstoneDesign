from django.urls import path
from .views import login_view, register_view, ImageUploadView, GetUserInfoView, UpdateUserView, DeleteUserView
from rest_framework_simplejwt.views import TokenRefreshView
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static
from api.views.vector_view import VectorListView, VectorDeleteView
from api.views.policy_query_view import PolicyQueryView
from api.views.feedback_view import FeedbackAPIView
from api.views.favorite_chat_view import (
    FavoriteChatListAPIView,
    FavoriteChatDetailAPIView,
    FavoriteChatActionAPIView)
from api.views.reward_view import RewardGuideAPIView

def custom_404_view(request, exception):
    return JsonResponse({'status': 'fail', 'message': '존재하지 않는 URL입니다.'}, status=404)

def custom_500_view(request):
    return JsonResponse({'status': 'fail', 'message': '서버 내부 오류가 발생했습니다.'}, status=500)

handler404 = 'config.urls.custom_404_view'
handler500 = 'config.urls.custom_500_view'

urlpatterns = [
    path('image/upload/', ImageUploadView.as_view(), name='image_upload'),
    path('login/', login_view),
    path('register/', register_view),
    path('token/refresh/', TokenRefreshView.as_view()),
    path('user/info/', GetUserInfoView.as_view(), name='get-user-info'),
    path('user/update/', UpdateUserView.as_view()),
    path('user/delete/', DeleteUserView.as_view()),
    path('vectors/', VectorListView.as_view(), name='vector-list'),
    path('vectors/<uuid:image_id>/', VectorDeleteView.as_view(), name='vector-delete'),
    path('policy/query/', PolicyQueryView.as_view(), name='policy-query'),
    path('feedback/', FeedbackAPIView.as_view(), name='feedback'),
    path('favorite-chat/', FavoriteChatListAPIView.as_view(), name='favorite-chat-list'),
    path('favorite-chat/<int:favorite_id>/', FavoriteChatDetailAPIView.as_view(), name='favorite-chat-detail'),
    path('favorite-chat-action/', FavoriteChatActionAPIView.as_view(), name='favorite-chat-action'),
    path('favorite-chat-action/<int:favorite_id>/', FavoriteChatActionAPIView.as_view()),  # DELETE용
    path('reward/query/', RewardGuideAPIView.as_view(), name='reward-guide'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)


