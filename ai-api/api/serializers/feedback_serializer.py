from rest_framework import serializers
from SQLDB.models import Feedback

class FeedbackSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Feedback
        fields = ['id', 'message', 'type', 'status', 'response', 'created_at', 'image_url','image']
        read_only_fields = ['status', 'response', 'created_at']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and hasattr(obj.image, 'image') and hasattr(obj.image.image, 'url'):
            url = obj.image.image.url
        # 상대 경로로 내려주기 (e.g. /media/waste_images/...)
            if request is not None:
                return request.build_absolute_uri(url)
            else:
                return url
        return None
