import tempfile
import os
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from django.db import transaction
from django.contrib.auth import get_user_model
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import SessionAuthentication, BasicAuthentication

from api.vector_service import extract_vector, store_vector
from api.tasks import process_image
from SQLDB.models import WasteImage, VectorMetadata
from .base import AuthenticatedAPIView

@method_decorator(csrf_exempt, name='dispatch')
class ImageUploadView(AuthenticatedAPIView):
    parser_classes = [MultiPartParser]

    def post(self, request):
        user = request.user
        image = request.FILES.get('image') or request.FILES.get('file')

        if not image:
            return Response({
                'status': 'fail',
                'message': 'No image uploaded'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                # ✅ 인증된 사용자 확인
                user = request.user
                if not user or not user.is_authenticated:
                    return Response({
                        'status': 'fail',
                        'message': 'Authentication required.'
                    }, status=status.HTTP_401_UNAUTHORIZED)

                # 1. 이미지 저장 (user 포함)
                image_instance = WasteImage.objects.create(
                    user=user,
                    image=image
                )

                # 2. 임시 파일로 저장
                with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                    for chunk in image.chunks():
                        temp_file.write(chunk)
                    temp_file.flush()

                    # 3. 벡터 추출 + 저장
                    vector = extract_vector(temp_file.name)
                    vector_id = store_vector(vector)

                # 4. 메타데이터 저장
                metadata = {
                    "filename": image.name,
                    "content_type": image.content_type,
                    "size": image.size,
                }

                VectorMetadata.objects.create(
                    waste_image=image_instance,
                    vector_id=vector_id,
                    metadata=metadata
                )

            # 5. 비동기 처리 태스크 실행
            process_image.delay(image_instance.image.path)

            return Response({
                'status': 'success',
                'vector_id': vector_id
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({
                'status': 'error',
                'message': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
