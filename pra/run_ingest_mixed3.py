import os
import sys
import uuid
import django
from pathlib import Path
from dotenv import load_dotenv

from langchain_community.document_loaders import Docx2txtLoader
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
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
COLLECTION = "waste_policy_hf"  # "waste_vector"
os.makedirs(PERSIST_DIR, exist_ok=True)

# 지역 추출 함수
def extract_region_from_filename(filename: str) -> str:
    return os.path.splitext(filename)[0].split("_")[0].strip()

# 라벨 자동 분류 함수
def classify_label(text: str) -> str:
    text = text.lower()
    if any(kw in text for kw in ["페트", "플라스틱", "합성수지", "pp", "pe"]):
        return "Plastic"
    elif "스티로폼" in text:
        return "Styrofoam"
    elif any(kw in text for kw in ["고철", "쇠붙이", "스테인리스", "철", "알미늄", "금속"]):
        return "Metal"
    elif any(kw in text for kw in ["캔", "철캔", "알루미늄캔", "부탄가스", "살충제"]):
        return "Can"
    elif any(kw in text for kw in ["병", "유리병", "농약병", "음료수병"]):
        return "Glass"
    elif any(kw in text for kw in ["종이", "신문지", "책자", "상자", "달력", "노트"]):
        return "Paper"
    elif any(kw in text for kw in ["비닐"]):
        return "vinyl"
    elif any(kw in text for kw in ["재활용 불가", "기름종이", "컵밥", "파쇄지"]):
        return "NonRecyclable"
    else:
        return "Other"

# 임베딩 모델 초기화
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

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=0,
    separators=["\n\n", "\n", " ", ""]
)

# .docx 파일만 대상
doc_paths = list(DOCUMENT_DIR.glob("*.docx")) + list(DOCUMENT_DIR.glob("*.DOCX"))

print(f"\n📂 문서 탐색 경로: {DOCUMENT_DIR}")
print(f"🔍 문서 파일 수: {len(doc_paths)}")

for file_path in doc_paths:
    try:
        print(f"\n📄 Processing: {file_path.name}")
        region = extract_region_from_filename(file_path.name)

        loader = Docx2txtLoader(str(file_path))
        docs = loader.load()

        print(f"📎 loader 반환 타입: {type(docs)}")

        if isinstance(docs, str):
            docs = [Document(page_content=docs)]
        elif isinstance(docs, list):
            if all(isinstance(doc, str) for doc in docs):
                docs = [Document(page_content=doc) for doc in docs]
            elif all(isinstance(doc, Document) for doc in docs):
                pass
            else:
                raise ValueError(f"Unsupported document type in list: {type(docs[0])}")
        else:
            raise ValueError(f"Unsupported document type: {type(docs)}")

        chunks = splitter.split_documents(docs)
        texts = [chunk.page_content for chunk in chunks]
        ids = [str(uuid.uuid4()) for _ in chunks]

        documents = []
        for text, vector_id in zip(texts, ids):
            label = classify_label(text)
            metadata = {
                "type": "guideline",
                "label": label,
                "region": region,
                "source_file": file_path.name
            }
            documents.append(Document(page_content=text, metadata=metadata))

        print(f"✅ vectordb 타입 확인: {type(vectordb)}")
        vectordb.add_documents(documents=documents, ids=ids)

        for vector_id in ids:
            VectorMetadata.objects.create(vector_id=vector_id)

        print(f"✅ {file_path.name}: {len(texts)} chunks 저장 완료")

    except Exception as e:
        print(f"❌ 오류 발생: {file_path.name} - {str(e)}")

print("\n📌 ChromaDB에 저장된 메타데이터 샘플 확인:")
try:
    raw = vectordb._collection.get(include=["metadatas"], limit=5)
    for i, meta in enumerate(raw["metadatas"], 1):
        print(f"🧩 meta {i}: {meta}")
except Exception as e:
    print(f"⚠️ 메타데이터 확인 실패: {str(e)}")
