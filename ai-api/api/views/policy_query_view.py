from api.views.base import AuthenticatedAPIView
from rest_framework.response import Response
from rest_framework import status

from chromadb import PersistentClient
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from SQLDB.models import WasteImage
from .label_lower import classify_label

# 1. 임베딩, 클라이언트, 벡터DB를 전역(최상단)에서 단 한 번만 생성!
CHROMA_CLIENT = PersistentClient(path="./chroma_db")
HF_EMBEDDINGS = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2",
    model_kwargs={"device": "cpu"}
)
VECTORDB = Chroma(
    client=CHROMA_CLIENT,
    collection_name="waste_vectors",
    embedding_function=HF_EMBEDDINGS
)

class PolicyQueryView(AuthenticatedAPIView):
    def post(self, request):
        label = request.data.get("label")
        label = classify_label(label)
        image_id = request.data.get("image")
        query_text = request.data.get("query", "분리수거 방법 알려줘")

        try:
            region = request.user.current_location.region_name
        except AttributeError:
            return Response(
                {"error": "사용자 지역 정보(current_location)가 등록되어 있지 않습니다."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not label or not image_id:
            return Response(
                {"error": "label image_id 값은 필수입니다."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            image = WasteImage.objects.select_related("chat").get(id=image_id, user=request.user)
            if not image.chat:
                return Response({"error": "해당 이미지에 연결된 채팅 내역이 없습니다."}, status=404)
        except WasteImage.DoesNotExist:
            return Response({"error": "이미지를 찾을 수 없거나 권한이 없습니다."}, status=404)

        try:
            # 2. 전역 객체 사용 (VECTORDB)
            retriever = VECTORDB.as_retriever(
                search_type="similarity",
                search_kwargs={
                    "k": 4,
                    "filter": {
                        "$and": [
                            {"label": {"$in": [label]}},
                            {"region": {"$in": [region]}},
                            {"type": {"$in": ["guideline"]}}
                        ]
                    }
                }
            )
            docs = retriever.get_relevant_documents(query_text)

            if docs:
                policy_text = docs[0].page_content
                metadata = docs[0].metadata
            else:
                policy_text = "분리수거 규정을 준비중입니다."
                metadata = {}

            chat = image.chat
            chat.region = region
            chat.label = label
            chat.response_text = policy_text
            chat.save()
            print(" Chat ID 확인:", chat.id)

            return Response({
                "status": "success",
                "chat_id": chat.id,
                "matched_policy": policy_text,
                "metadata": metadata
            }, status=200)

        except Exception as e:
            return Response({"error": f"ChromaDB 연결 실패: {str(e)}"}, status=500)

