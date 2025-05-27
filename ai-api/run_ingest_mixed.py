import os
import sys
import uuid
import django
from pathlib import Path
from dotenv import load_dotenv
import re

from langchain_community.document_loaders import Docx2txtLoader
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from langchain_core.documents import Document

# Django 초기화
sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from SQLDB.models import VectorMetadata

# 환경변수 및 경로 설정
load_dotenv()
DOCUMENT_DIR = Path("/home/ubuntu/policy_file")
PERSIST_DIR = "./chroma_db"
COLLECTION = "waste_vectors"
os.makedirs(PERSIST_DIR, exist_ok=True)

# ----------- 지역 추출 함수 -----------
def extract_region_from_filename(filename: str) -> str:
    return os.path.splitext(filename)[0].split("_")[0].strip()

# ----------- 카테고리 블록 분리 함수 -----------
def split_by_category(doc_text):
    # [Category] ... end 블록 단위로 쪼개기
    pattern = r"(\[Category\][\s\S]*?end)"
    blocks = re.findall(pattern, doc_text)
    return blocks

# ----------- 카테고리명 추출 함수 -----------
def extract_category_label(block):
    match = re.search(r"\[Category\]\s*([^\n\r]+)", block)
    if match:
        return match.group(1).strip()
    else:
        return "기타"

# ----------- 임베딩 모델 초기화 -----------
hf_embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2",
    model_kwargs={"device": "cpu"},
    encode_kwargs={"batch_size": 5}
)

vectordb = Chroma(
    embedding_function=hf_embeddings,
    persist_directory=PERSIST_DIR,
    collection_name=COLLECTION
)

# ----------- 파일 리스트 준비 -----------
doc_paths = list(DOCUMENT_DIR.glob("*.docx")) + list(DOCUMENT_DIR.glob("*.DOCX"))

print(f"\n📂 문서 탐색 경로: {DOCUMENT_DIR}")
print(f"🔍 문서 파일 수: {len(doc_paths)}")

for file_path in doc_paths:
    try:
        print(f"\n📄 Processing: {file_path.name}")
        region = extract_region_from_filename(file_path.name)

        loader = Docx2txtLoader(str(file_path))
        docs = loader.load()
        
        # --- 텍스트만 추출 ---
        if isinstance(docs, list):
            docs = "\n".join([d.page_content if isinstance(d, Document) else str(d) for d in docs])
        elif isinstance(docs, Document):
            docs = docs.page_content
        elif isinstance(docs, str):
            docs = docs
        else:
            raise ValueError("문서 형식이 올바르지 않습니다.")

        # --- 카테고리 단위로 분리 ---
        category_blocks = split_by_category(docs)
        print(f"카테고리 블록 개수: {len(category_blocks)}")
        
        # --- 카테고리명 추출 및 임베딩용 chunk 만들기 ---
        ids = [str(uuid.uuid4()) for _ in category_blocks]
        documents = []
        for block, vector_id in zip(category_blocks, ids):
            label = extract_category_label(block)   # [Category] 뒷부분을 label로!
            metadata = {
                "type": "guideline",
                "label": label,                     # label: [Category] 명칭 그대로
                "region": region,
                "source_file": file_path.name
            }
            documents.append(Document(page_content=block, metadata=metadata))

        print(f"최종 chunk 개수: {len(documents)}")
        for idx, doc in enumerate(documents[:5], 1):
            print(f"\nchunk {idx} (label: {doc.metadata['label']}):\n{doc.page_content[:200]}\n---")

        # --- 임베딩 및 DB 저장 ---
        vectordb.add_documents(documents=documents, ids=ids)
        for vector_id in ids:
            VectorMetadata.objects.create(vector_id=vector_id)

        print(f"✅ {file_path.name}: {len(documents)} chunks 저장 완료")

    except Exception as e:
        print(f"❌ 오류 발생: {file_path.name} - {str(e)}")

print("\n📌 ChromaDB에 저장된 메타데이터 샘플 확인:")
try:
    raw = vectordb._collection.get(include=["metadatas", "documents"], limit=5)
    for i, (meta, doc) in enumerate(zip(raw["metadatas"], raw["documents"]), 1):
        print(f"\n🧩 meta {i}: {meta}")
        print(f"📝 doc {i}: {doc[:120]}...")
except Exception as e:
    print(f"⚠️ 메타데이터 확인 실패: {str(e)}")

