from rest_framework.response import Response
from rest_framework import status
from api.views.base import AuthenticatedAPIView
from django.utils import timezone

class DeleteUserView(AuthenticatedAPIView):
    def delete(self, request):
        user = request.user
        username = user.username

        user.is_active = False
        user.save()

        return Response({
            'status': 'success',
            'message': f'사용자 "{username}"의 탈퇴가 처리되었습니다.'
        }, status=status.HTTP_200_OK)

