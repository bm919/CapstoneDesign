

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken

@api_view(['POST'])
def login_view(request):
    try:
        if request.method != 'POST':
            return Response({'error' : 'POST 방식으로 요청하세요'}, status=405)
        username = request.data.get('username')
        password = request.data.get('password')

        print(f"[DEBUG] 요청 방식: {request.method}")
        print(f"[DEBUG] 요청 데이터: {request.data}")


        user = authenticate(request, username=username, password=password)
        if user is None:
            return Response({'status': 'fail', 'message': '이메일 또는 비밀번호가 올바르지 않습니다.'}, status=401)

        refresh = RefreshToken.for_user(user)
        return Response({
            'status': 'success',
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'username': user.username
        }, status=200)

    except Exception as e:
        print(f"[ERROR] 로그인 중 예외 발생: {str(e)}")
        return Response({
            'status': 'error',
            'message': f'서버 내부 오류가 발생했습니다.',
            'detail': str(e)
        }, status=500)
