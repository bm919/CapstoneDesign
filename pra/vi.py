from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .base import AuthenticatedAPIView
from SQLDB.models import VectorMetadata
from chromadb import Client
from chromadb.config import Settings
from rest_framework.views import APIView


    def get
        vectors = VectorMetadata.objects.all()
        serializer = VectorMetadataSerializer(vectors, many=True)
        print serializer.data

