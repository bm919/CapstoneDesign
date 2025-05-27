from rest_framework import serializers
from .models import VectorMetadata, CustomUser

class VectorMetadataSerializer(serializers.ModelSerializer):
    class Meta:
        model = VectorMetadata
        fields = ['vector_id', 'metadata','waste_image','created_at']

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = [
            'id',
            'username',
            'email',
            'home_location',
            'current_location',
            'created_at',
        ]
