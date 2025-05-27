from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from api.views.base import AuthenticatedAPIView
from SQLDB.models import ChatHistory

# ✅ 모델과 DB를 전역(모듈레벨)에서 1번만 로드
EMBEDDINGS = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2"
)
VECTORDB = Chroma(
    collection_name="waste_vectors",
    embedding_function=EMBEDDINGS,
    persist_directory="./chroma_db"
)

class RewardGuideAPIView(APIView):
    def post(self, request):
        user = request.user
        try:
            region = user.current_location.region_name
        except AttributeError:
            return Response({"error": "유저 지역 정보가 없습니다."}, status=status.HTTP_400_BAD_REQUEST)

        waste_type = request.data.get("label")
        chat_id = request.data.get("chat_id")
        if not waste_type or not chat_id:
            return Response({"error": "label과 chat_id 값이 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)

        # 기존 ChatHistory 조회 (user 체크)
        try:
            chat_history = ChatHistory.objects.get(id=chat_id, user=user)
        except ChatHistory.DoesNotExist:
            return Response({"error": "해당 chat_id의 히스토리가 없습니다."}, status=status.HTTP_404_NOT_FOUND)

        # query_text는 반드시 정의 필요 (예: "보상안내" or 사용자가 입력한 검색어)
        query_text = request.data.get("query", "보상안내")  # 기본값 '보상안내'

        retriever = VECTORDB.as_retriever(
            search_type="similarity",
            search_kwargs={
                "k": 4,
                "filter": {
                    "$and": [
                        {"label": {"$in": [waste_type]}},
                        {"region": {"$in": [region]}},
                        {"type": {"$in": ["reward"]}}
                    ]
                }
            }
        )
        docs = retriever.get_relevant_documents(query_text)

        guides = []
        if docs:
            for doc in docs:
                guides.append({
                    "region": doc.metadata.get("region"),
                    "label": doc.metadata.get("label"),
                    "content": doc.page_content
                })
            reward_text = guides[0]["content"]
        else:
            reward_text = "해당사항이 없습니다."

        # ChatHistory reward_text 업데이트
        chat_history.reward_text = reward_text
        chat_history.save()

        # 응답
        if guides:
            return Response({"reward_guides": guides}, status=status.HTTP_200_OK)
        else:
            return Response({"message": "해당사항이 없습니다."}, status=status.HTTP_200_OK)

