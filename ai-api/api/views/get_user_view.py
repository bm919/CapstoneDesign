
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .base import AuthenticatedAPIView
from SQLDB.serializers import CustomUserSerializer


class GetUserInfoView(AuthenticatedAPIView):
    def get(self, request):
        user = request.user
        return Response({
            'email': user.email,
            'username': user.username,
            'current_location_id': user.current_location.region_name,
            'created_at': user.created_at,
        })

