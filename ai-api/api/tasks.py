import os
import uuid
import requests
from celery import shared_task
from chromadb import Client
from chromadb.config import Settings

# ✅ FastAPI 임베딩 URL
FASTAPI_EMBEDDING_URL = "http://localhost:8001/embedding"

# ✅ Chroma client singleton
_chroma_client = None

def get_chroma_client():
    global _chroma_client
    if _chroma_client is None:
        _chroma_client = Client(Settings(
            chroma_db_impl="duckdb+parquet",
            persist_directory="./chroma_db"
        ))
    return _chroma_client

def get_chroma_collection():
    return get_chroma_client().get_or_create_collection(name="waste_vectors")

@shared_task
def process_image(image_path):
    try:
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"File not found: {image_path}")

        # ✅ 1. FastAPI에 /embedding 요청
        with open(image_path, 'rb') as img_file:
            response = requests.post(
                FASTAPI_EMBEDDING_URL,
                files={"file": img_file}
            )
        if response.status_code != 200:
            raise Exception(f"Embedding failed: {response.text}")

        embedding = response.json()["embedding"]

        # ✅ 2. ChromaDB에 벡터 저장
        vector_id = str(uuid.uuid4())
        collection = get_chroma_collection()
        collection.add_embeddings(
            embeddings=[embedding],
            metadatas=[{
                "type": "image",
                "source_file": os.path.basename(image_path),
                "backup": True
            }],
            ids=[vector_id]
        )

        # ✅ 3. 임시 파일 삭제
        try:
            os.remove(image_path)
        except Exception as cleanup_error:
            print(f"[WARNING] Failed to delete temp file: {cleanup_error}")

        return vector_id

    except Exception as e:
        print(f"[ERROR] process_image failed: {str(e)}")
        return None

