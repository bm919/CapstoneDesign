from rest_framework.response import Response
from rest_framework import status
from api.views.base import AuthenticatedAPIView
from SQLDB.models import Feedback, WasteImage
from api.serializers.feedback_serializer import FeedbackSerializer
from django.utils import timezone

class FeedbackAPIView(AuthenticatedAPIView):
    def post(self, request):
        print(f"[DEBUG] request.data: {request.data}")
        message = request.data.get("message")
        feedback_type = request.data.get("type")
        image_id = request.data.get("image_id") or request.data.get("image")
        print(f"[DEBUG] image_id from request: {image_id}")

        if not message or not feedback_type:
            return Response({"error": "message and type are required"}, status=400)

        image = None
        if image_id:
            try:
                image = WasteImage.objects.get(id=image_id, user=request.user)
            except WasteImage.DoesNotExist:
                return Response({"error": "Image not found or not yours"}, status=404)

        feedback = Feedback.objects.create(
            user=request.user,
            message=message,
            type=feedback_type,
            image=image,
            created_at=timezone.now(),
            status="접수 전"
        )
        print(f"[DEBUG] Feedback created: ID={feedback.id}, image_id={feedback.image_id}")
        return Response({"message": "Feedback submitted", "id": feedback.id, "image_id": feedback.image.id if feedback.image else None}, status=201)

    def get(self, request):
        """현재 로그인 유저의 모든 피드백 조회"""
        feedbacks = Feedback.objects.filter(user=request.user).order_by('-created_at')
        serializer = FeedbackSerializer(feedbacks, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

