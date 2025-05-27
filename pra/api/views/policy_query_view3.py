from api.views.base import AuthenticatedAPIView
from rest_framework.response import Response
from rest_framework import status

from chromadb import PersistentClient
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from SQLDB.models import WasteImage
from .label_lower import classify_label


class PolicyQueryView(AuthenticatedAPIView):
    def post(self, request):
        label = request.data.get("label")
        label = classify_label(label)
        image_id = request.data.get("image")
        query_text = request.data.get("query", "분리수거 방법 알려줘")

        # ✅ JWT 토큰에서 사용자 지역 추출 (현재는 강제 설정)
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

        # ✅ WasteImage + Chat 연결 확인
        try:
            image = WasteImage.objects.select_related("chat").get(id=image_id, user=request.user)
            if not image.chat:
                return Response({"error": "해당 이미지에 연결된 채팅 내역이 없습니다."}, status=404)
        except WasteImage.DoesNotExist:
            return Response({"error": "이미지를 찾을 수 없거나 권한이 없습니다."}, status=404)


        try:
            # ✅ 최신 방식으로 ChromaDB 연결
            client = PersistentClient(path="./chroma_db")
            hf_embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={"device": "cpu"})
            vectordb = Chroma(
                client=client,
                collection_name="waste_vectors",
                embedding_function=hf_embeddings
            )



            # ✅ 조건 검색 (type=guideline + label + region)
            try:
                retriever = vectordb.as_retriever(
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
            except Exception as e:
                print("❌ Error in policy_query_view:", e)
                return Response({"error": str(e)}, status=500)


            if docs:

                policy_text = docs[0].page_content
                chat = image.chat
                
                # ✅ ChatHistory에 정책 응답 저장
                chat.region = region              # 지역 저장
                chat.label = label                # 분류 저장
                chat.response_text = policy_text  # 분리수거규정만 저장
                chat.save()

                print(" Chat ID 확인:", chat.id)

                return Response({
                    "status": "success",
                    "chat_id": chat.id,
                    "matched_policy":docs[0].page_content,
                    "metadata": docs[0].metadata
                })

            else:
                return Response({
                    "status": "not_found",
                    "message": f"'{region}' 지역에 대한 '{label}' 분리수거 규정을 찾을 수 없습니다."
                }, status=404)

        except Exception as e:
            return Response({"error": f"ChromaDB 연결 실패: {str(e)}"}, status=500)
