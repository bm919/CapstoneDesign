from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from api.views.base import AuthenticatedAPIView


class DeleteUserView(AuthenticatedAPIView):
    def delete(self, request):
        user = request.user
        username = user.username
        user.delete()
        return Response({
            'status': 'success', 
            'message': f'사용자 "{username}"의 탈퇴가 완료되었습니다.'}, status.HTTP_200_OK)

