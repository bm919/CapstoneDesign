import tempfile
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from api.vector_service import extract_vector, store_vector
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from api.tasks import process_image
from SQLDB.serializers import VectorMetadataSerializer
from SQLDB.models import WasteImage, VectorMetadata


@method_decorator(csrf_exempt, name='dispatch')
class ImageUploadView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request, *args, **kwargs):
        image = request.FILES.get('image') or request.FILES.get('file')
        if not image:
            return Response({'status': 'fail', 'message': 'No image uploaded'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            image_instance = WasteImage.objects.create(image=image)

            with tempfile.NamedTemporaryFile(delete=True) as temp_file:
                for chunk in image.chunks():
                    temp_file.write(chunk)
                temp_file.flush()

                vector = extract_vector(temp_file.name)
                vector_id = store_vector(vector)

                metadata = {
                    "filename": image.name,
                    "content_type": image.content_type,
                    "size": image.size,
                }

                VectorMetadata.objects.create(
                waste_image=image_instance,
                vector_id=vector_id,
                metadata=metadata
            )

        task = process_image.delay(image_instance.image.path)

        return Response({'status': 'success', 'vector_id': vector_id}, status=status.HTTP_201_CREATED)
