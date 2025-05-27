from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from api.views.base import AuthenticatedAPIView

from SQLDB.models import ChatHistory

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

        # 1. 기존 ChatHistory 조회 (user 체크)
        try:
            chat_history = ChatHistory.objects.get(id=chat_id, user=user)
        except ChatHistory.DoesNotExist:
            return Response({"error": "해당 chat_id의 히스토리가 없습니다."}, status=status.HTTP_404_NOT_FOUND)

        # 2. ChromaDB에서 reward type만 검색
        embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
        vectordb = Chroma(
            collection_name="waste_vectors",
            embedding_function=embeddings,
            persist_directory="./chroma_db"
        )
        retriever = vectordb.as_retriever(
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
        docs = retriever.get_relevant_documents(query_text)  # query_text는 '보상안내' 등

        # 3. 보상안내 텍스트 선정
        guides = []
        if docs and docs.get("documents"):
            for doc, meta in zip(docs["documents"], docs["metadatas"]):
                guides.append({
                    "region": meta.get("region"),
                    "label": meta.get("label"),
                    "content": doc
                })
            reward_text = guides[0]["content"]  # 가장 첫 번째 안내만 저장
        else:
            reward_text = "해당사항이 없습니다."

        # 4. ChatHistory reward_text만 업데이트
        chat_history.reward_text = reward_text
        chat_history.save()

        # 5. 응답: 항상 status=200
        if guides:
            return Response({"reward_guides": guides}, status=status.HTTP_200_OK)
        else:
            return Response({"message": "해당사항이 없습니다."}, status=status.HTTP_200_OK)

