import tempfile
import os
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from api.vector_service import extract_vector, store_vector
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from api.tasks import process_image
from SQLDB.serializers import VectorMetadataSerializer
from SQLDB.models import WasteImage, VectorMetadata
from django.db import transaction  # 누락 시 오류 발생 가능

@method_decorator(csrf_exempt, name='dispatch')
class ImageUploadView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request, *args, **kwargs):
        image = request.FILES.get('image') or request.FILES.get('file')

        if not image:
            return Response({
                'status': 'fail',
                'message': 'No image uploaded'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                # 1. 이미지 저장
                image_instance = WasteImage.objects.create(image=image)

                # 2. 임시 파일로 저장
                with tempfile.NamedTemporaryFile(delete=False):
                    for chunk in image.chunks():
                        temp_file.write(chunk)
                    temp_file.flush()
                    temp_file.close()

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
            task = process_image.delay(temp_file.name)

            return Response({
                'status': 'success',
                'vector_id': vector_id
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({
                'status': 'error',
                'message': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

