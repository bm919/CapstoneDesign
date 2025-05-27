from rest_framework.response import Response
from rest_framework import status
from api.views.base import AuthenticatedAPIView
from SQLDB.models import Location

class UpdateUserView(AuthenticatedAPIView):
    def patch(self, request):
        user = request.user

        new_username = request.data.get('username')
        new_password = request.data.get('password')
        new_email = request.data.get('email')
        region_name = request.data.get('region')

        print(f"[DEBUG] 요청 데이터: {request.data}")
        print(f"[DEBUG] 전달된 email: {new_email}")

        if new_username:
            user.username = new_username
        if new_password:
            user.set_password(new_password)
        if new_email:
            user.email = new_email
        if region_name:
            try:
                location = Location.objects.get(region_name=region_name)
                user.current_location = location
            except Location.DoesNotExist:
                return Response({
                    'status': 'fail',
                    'message': '유효하지 않은 지역 ID입니다.'
                }, status=400)

        user.save()

        return Response({
            'status': 'success',
            'message': '회원정보가 수정되었습니다.'
        }, status=200)

