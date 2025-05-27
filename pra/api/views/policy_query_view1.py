# api/views/policy_query_view.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from chromadb import Client
from chromadb.config import Settings

class PolicyQueryView(APIView):
    def post(self, request):
        label = request.data.get("label")
        region = request.data.get("region")

        if not label or not region:
            return Response(
                {"error": "label과 region 값을 모두 제공해야 합니다."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ChromaDB 초기화
        client = Client(Settings(chroma_db_impl="duckdb+parquet", persist_directory="./chroma"))
        collection = client.get_collection(name="waste_vectors")

        # 조건에 맞는 메타데이터 필터링
        try:
            results = collection.get(
                where={"label": label, "region": region},
                include=["metadatas"]
            )
            if results["metadatas"]:
                policy = results["metadatas"][0]  # 첫 번째 결과 사용
                return Response({
                    "status": "success",
                    "matched_policy": policy
                })
            else:
                return Response({
                    "status": "not_found",
                    "message": "해당 조건의 분리수거 규정을 찾을 수 없습니다."
                }, status=404)

        except Exception as e:
            return Response({"error": str(e)}, status=500)

