# api/views/vector_view.py
# vector_view.py

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .base import AuthenticatedAPIView
from SQLDB.models import VectorMetadata
from chromadb import Client
from chromadb.config import Settings
from rest_framework.views import APIView

class VectorListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        vectors = VectorMetadata.objects.all()
        serializer = VectorMetadataSerializer(vectors, many=True)
        return Response(serializer.data)

class VectorDeleteView(AuthenticatedAPIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, vector_id):
        try:
            vector = VectorMetadata.objects.get(vector_id=vector_id)

            # ChromaDB에서 삭제
            client = Client(Settings(chroma_db_impl="duckdb+parquet", persist_directory="./chroma_db"))
            collection = client.get_collection("waste_vectors")
            collection.delete(ids=[vector_id])

            # DB에서도 삭제
            vector.delete()

            return Response({'message': '벡터 삭제 완료'}, status=200)

        except VectorMetadata.DoesNotExist:
            return Response({'error': '해당 벡터 없음'}, status=404)

