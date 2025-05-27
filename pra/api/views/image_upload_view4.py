import requests
import tempfile
import os
from django.http import JsonResponse
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework import status
from api.vector_service import extract_vector, store_vector
from SQLDB.models import WasteImage, VectorMetadata
from django.db import transaction
from django.conf import settings
from api.tasks import process_image

FASTAPI_PREDICT_URL = "http://localhost:8001/predict"  # 실제 FastAPI 서버 주소로 교체

class ImageUploadView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request, *args, **kwargs):
        image = request.FILES.get("image") or request.FILES.get("file")

        if not image:
            return Response({
                "status": "fail",
                "message": "No image uploaded"
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                # 1. WasteImage 저장 (사용자 포함)
                image_instance = WasteImage.objects.create(
                    user=request.user,
                    image=image
                )

                # 2. 이미지 임시 저장 (FastAPI 요청을 위해)
                with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                    for chunk in image.chunks():
                        temp_file.write(chunk)
                    temp_file_path = temp_file.name

                # 3. FastAPI 예측 호출
                with open(temp_file_path, 'rb') as img_file:
                    response = requests.post(
                        FASTAPI_PREDICT_URL,
                        files={'file': img_file}
                    )

                if response.status_code != 200:
                    raise Exception(f"Prediction failed: {response.text}")

                prediction = response.json()
                label = prediction.get("label")
                confidence = prediction.get("confidence")

                # 4. 벡터 추출 + 저장
                vector = extract_vector(temp_file_path)
                vector_id = store_vector(vector)

                # 5. 메타데이터 저장
                metadata = {
                    "filename": image.name,
                    "content_type": image.content_type,
                    "size": image.size,
                    "predicted_label": label,
                    "confidence": confidence,
                }

                VectorMetadata.objects.create(
                    waste_image=image_instance,
                    vector_id=vector_id,
                    metadata=metadata
                )

                # 6. 비동기 백업 처리
                process_image.delay(temp_file_path)

                return Response({
                    "status": "success",
                    "label": label,
                }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({
                "status": "error",
                "message": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

