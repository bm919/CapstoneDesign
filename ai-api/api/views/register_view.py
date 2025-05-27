from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from SQLDB.models import CustomUser, Location
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.hashers import make_password

@api_view(['POST'])
def register_view(request):
    try:
        print("요청 데이터:", request.data)
        username = request.data.get('username')
        email = request.data.get('email')
        password = request.data.get('password')
        region_name = request.data.get('region') or request.data.get('current_location_id')

        print("입력값 확인:")
        print("username:", username)
        print("email:", email)
        print("password:", password)
        print("region_name:", region_name)

        if not all([username, email, password, region_name]):
            return Response({'status': 'fail', 'message': '모든 필드를 입력해주세요.'}, status=400)

        if CustomUser.objects.filter(email=email).exists():
            return Response({'status': 'fail', 'message': '이미 사용 중인 이메일입니다.'}, status=400)

        if CustomUser.objects.filter(username=username).exists():
            return Response({'status': 'fail', 'message': '이미 사용 중인 사용자 이름입니다.'}, status=400)

        try:
            location = Location.objects.get(region_name=region_name)
        except Location.DoesNotExist:
            return Response({'status': 'fail', 'message': '유효하지 않은 지역 ID입니다.'}, status=400)

        print("입력값 확인:")
        print("username:", username)
        print("email:", email)
        print("password:", password)
        print("region_name:", region_name)


        user = CustomUser.objects.create(
            username=username,
            email=email,
            current_location=location,
            password=make_password(password)  # 🔐 비밀번호 해시
        )


        refresh = RefreshToken.for_user(user)

        return Response({
            'status': 'success',
            'message': '회원가입이 완료되었습니다.',
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'username': user.username
        }, status=201)

    except Exception as e:
        return Response({'status': 'error', 'message': '회원가입 중 오류가 발생했습니다.', 'detail': str(e)}, status=500)

