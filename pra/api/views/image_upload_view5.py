import requests
import tempfile
import os
import uuid
from django.http import JsonResponse
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from SQLDB.models import WasteImage, VectorMetadata, ChatHistory
from chromadb import PersistentClient  # ✅ import 위치 고정
from api.tasks import process_image

_chroma_client = None

FASTAPI_PREDICT_URL = "http://localhost:8001/predict"
FASTAPI_EMBEDDING_URL = "http://localhost:8001/embedding"

def get_chroma_client():
    global _chroma_client
    if _chroma_client is None:
        _chroma_client = PersistentClient(path="./chroma_db")  # ✅ 중복 import 제거
    return _chroma_client

def get_chroma_collection():
    return get_chroma_client().get_or_create_collection(name="waste_im")

class ImageUploadView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request, *args, **kwargs):
        image = request.FILES.get("image") or request.FILES.get("file")

        if not image:
            return Response({
                "status": "fail",
                "message": "No image uploaded"
            }, status=status.HTTP_400_BAD_REQUEST)

        temp_file_path = None

        try:
            with transaction.atomic():

                with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as temp_file:
                    for chunk in image.chunks():
                        temp_file.write(chunk)
                    temp_file_path = temp_file.name

                with open(temp_file_path, 'rb') as img_file:
                    pred_response = requests.post(
                        FASTAPI_PREDICT_URL,
                        files={'file': img_file}
                    )
                if pred_response.status_code != 200:
                    raise Exception(f"Prediction failed: {pred_response.text}")

                pred_data = pred_response.json()
                label = pred_data["label"]
                confidence = pred_data["confidence"]

                image_instance = WasteImage.objects.create(
                    user=request.user,
                    image=image,
                    confidence=confidence,
                    image_url=""
                )
                image_instance.image_url = image_instance.image.path
                image_instance.save()


                 # ✅ 2. ChatHistory 생성 및 연결
                chat = ChatHistory.objects.create(
                    user=request.user,
                    waste_image=image_instance  # 연결
                )

                # ✅ 3. WasteImage에도 연결 정보 저장
                image_instance.chat = chat
                image_instance.save()


                with open(temp_file_path, 'rb') as img_file:
                    embed_response = requests.post(
                        FASTAPI_EMBEDDING_URL,
                        files={'file': img_file}
                    )
                if embed_response.status_code != 200:
                    raise Exception(f"Embedding failed: {embed_response.text}")

                embedding = embed_response.json()["embedding"]
                vector_id = str(uuid.uuid4())

                try:

                    collection = get_chroma_collection()

                # ✅ 최신 Chroma 방식 - add_documents() 사용 (안정적)
                    collection.add(
                        documents=["image_placeholder"],
                        embeddings=[embedding],
                        metadatas=[{
                            "type": "image",
                            "label": label,
                            "confidence": confidence,
                            "region": request.user.current_location.region_name if request.user.current_location else "unknown",
                            "source_file": image_instance.image.path,
                        }],
                        ids=[vector_id]
                    )
                    test = collection.get(ids=[vector_id], include=["documents", "metadatas"])
                    print("✅ 저장 직후 ChromaDB 확인:", test)

                except Exception as e:
                    import traceback
                    print("❌ ChromaDB 저장 예외 발생:", traceback.format_exc())
                    raise  # 반드시 예외를 다시 던져서 실제로 터지는지 확인

                VectorMetadata.objects.create(
                    waste_image=image_instance,
                    vector_id=vector_id,
                    dimension=len(embedding)
                )

                process_image.delay(temp_file_path)

                return Response({
                    "status": "success",
                    "label": label,
                    "confidence": confidence,
                    "image_id": image_instance.id
                }, status=status.HTTP_201_CREATED)

        except Exception as e:
            import traceback
            print("🔴 예외 발생:", traceback.format_exc())

            return Response({
                "status": "error",
                "message": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        finally:
    # 임시파일 삭제 (중요!)
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path)
