from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.response import Response



User = get_user_model()

@api_view(['POST'])
def register_view(request):
    email = request.data.get('email')
    username = request.data.get('username')
    password = request.data.get('password')

    if User.objects.filter(email=email).exists():
        return Response({'status': 'fail', 'message': '이미 등록된 이메일입니다.'}, status=400)

    user = User.objects.create_user(email=email, username=username, password=password)

    return Response({'status': 'success', 'message': '회원가입이 완료되었습니다.'}, status=201)

# 회원가입 후 user 객체가 생성되었다면:
    refresh = RefreshToken.for_user(user)

    return Response({
        'status': 'success',
        'message': '회원가입이 완료되었습니다.',
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'username': user.username
    }, status=201)

