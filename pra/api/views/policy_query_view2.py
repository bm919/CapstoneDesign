# api/views/policy_query_view.py

from api.views.base import AuthenticatedAPIView
from rest_framework.response import Response
from rest_framework import status
from chromadb import Client
from chromadb.config import Settings
from langchain.embeddings import HuggingFaceEmbeddings


class PolicyQueryView(AuthenticatedAPIView):
    def post(self, request):
        label = request.data.get("label")
        query_text = request.data.get("query", "분리수거 방법 알려줘")

        # ✅ JWT 토큰으로부터 인증된 사용자 정보에서 region 자동 추출
        try:
            region = "춘천시"
        except AttributeError:
            return Response(
                {"error": "사용자 지역 정보(current_location)가 등록되어 있지 않습니다."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not label:
            return Response(
                {"error": "label 값은 필수입니다."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # ChromaDB 연결
            client = Client(Settings(
                chroma_db_impl="duckdb+parquet",
                persist_directory="./chroma_db"
            ))
            collection = client.get_collection(name="waste_policy_hf")

        except Exception as e:
            return Response({"error": f"ChromaDB 연결 실패: {str(e)}"}, status=500)
