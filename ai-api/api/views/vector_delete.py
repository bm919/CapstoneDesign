from chromadb import Client  # ChromaDB 클라이언트
from chromadb.config import Settings

client = Client(Settings(chroma_db_impl="duckdb+parquet", persist_directory="./chroma_db"))

class VectorDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, image_id):
        try:
            vector = VectorMetadata.objects.get(image_id=image_id, user=request.user)

            # 벡터 DB에서도 삭제
            client.get_collection(name="waste_vectors").delete(ids=[str(image_id)])

            # 메타데이터 삭제
            vector.delete()
            return Response({"message": "삭제 완료"}, status=200)
        except VectorMetadata.DoesNotExist:
            return Response({"error": "해당 벡터를 찾을 수 없습니다."}, status=404)

