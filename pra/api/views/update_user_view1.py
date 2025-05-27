from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from api.views.base import AuthenticatedAPIView

class UpdateUserView(AuthenticatedAPIView):
    def put(self, request):
        user = request.user  # JWT 토큰을 통해 인증된 사용자

        new_username = request.data.get('username')
        new_password = request.data.get('password')

        if new_username:
            user.username = new_username
        if new_password:
            user.set_password(new_password)  # 반드시 해시 저장

        user.save()

        return Response({'status': 'success', 'message': '회원정보가 수정되었습니다.'}, status=200)

