# run_ingest_mixed.py

import os
import sys
import uuid
import django
from pathlib import Path
from dotenv import load_dotenv

from langchain_community.document_loaders import PyPDFLoader, Docx2txtLoader
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter

# ──────────────────────────────────────
# Django 설정
sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")  # 프로젝트에 맞게 수정
django.setup()

from SQLDB.models import VectorMetadata
# ──────────────────────────────────────

# .env 로드
load_dotenv()

# 파일 저장 디렉토리
DOCUMENT_DIR = Path("/home/ubuntu/policy_file")  # .pdf, .docx 저장 폴더
PERSIST_DIR = "./chroma_db"
COLLECTION = "waste_policy_hf"

os.makedirs(PERSIST_DIR, exist_ok=True)

# 지역명 자동 추출 함수
def extract_region_from_filename(filename: str) -> str:
    basename = os.path.splitext(filename)[0]
    first_token = basename.split("_")[0]
    return first_token.strip()

# label 자동 분류 함수
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
    elif any(kw in text for kw in ["재활용 불가", "재활용품인척", "기름종이", "컵밥", "라면 용기", "파쇄지"]):
        return "NonRecyclable"
    else:
        return "Other"

# 임베딩 모델
hf_embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

# ChromaDB 연결
vectordb = Chroma(
    embedding_function=hf_embeddings,
    persist_directory=PERSIST_DIR,
    collection_name=COLLECTION
)

# 문서 분할기
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=0)

# PDF + DOCX 자동 탐색
doc_paths = list(DOCUMENT_DIR.glob("*.pdf")) + list(DOCUMENT_DIR.glob("*.docx"))

for file_path in doc_paths:
    try:
        print(f"\n📄 Processing: {file_path.name}")

        # 지역명 추출
        region = extract_region_from_filename(file_path.name)

        # 파일 형식 로더 분기
        if file_path.suffix == ".pdf":
            loader = PyPDFLoader(str(file_path))
        elif file_path.suffix == ".docx":
            loader = Docx2txtLoader(str(file_path))
        else:
            print(f"⚠️ 지원되지 않는 형식: {file_path.name}")
            continue

        docs = loader.load()
        chunks = splitter.split_documents(docs)

        texts = [chunk.page_content for chunk in chunks]
        ids = [str(uuid.uuid4()) for _ in chunks]
        metadatas = [{
            "type": "guideline",
            "label": classify_label(chunk.page_content),
            "region": region,
            "source_file": file_path.name
        } for chunk in chunks]

        # ChromaDB 저장
        vectordb.add_documents(documents=texts, metadatas=metadatas, ids=ids)

        # PostgreSQL 저장
        for vector_id in ids:
            VectorMetadata.objects.create(vector_id=vector_id)

        print(f"✅ {file_path.name}: {len(texts)} chunks 저장 완료")

    except Exception as e:
        print(f"❌ 오류 발생: {file_path.name} - {str(e)}")

vectordb.persist()
print(f"\n✅ 전체 ingest 완료: {len(doc_paths)}개 문서")

