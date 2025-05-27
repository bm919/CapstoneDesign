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
COLLECTION = "waste_vectors"
os.makedirs(PERSIST_DIR, exist_ok=True)

# ----------- 지역 추출 함수 -----------
def extract_region_from_filename(filename: str) -> str:
    return os.path.splitext(filename)[0].split("_")[0].strip()

# ----------- 클래스명 기준 라벨링 ----------
CLASS_LABEL_KEYWORDS = {
    "beverage_can": ["음료수캔", "맥주캔", "캔류", "음료/주류캔", "beverage can"],
    "canned_can": ["통조림캔", "식료품캔", "식품캔", "canned can"],
    "glass_beer_bottle": ["맥주병", "beer bottle", "glass beer bottle"],
    "glass_clear_bottle": ["투명 유리병", "유리병", "clear bottle", "glass clear bottle"],
    "glass_tableware": ["유리 식기", "유리식기", "glass tableware"],
    "metal_pot": ["냄비", "금속냄비", "metal pot"],
    "paper_book": ["책자", "노트", "책", "잡지", "공책", "paper book"],
    "paper_box": ["종이박스", "종이팩", "골판지", "상자", "paper box"],
    "paper_news": ["신문지", "paper news"],
    "plastic_bottle": ["페트병", "플라스틱병", "plastic bottle"],
    "plastic_crushed": ["압착 플라스틱", "압착", "crushed plastic", "plastic crushed"],
    "plastic_cup_container": ["플라스틱 컵", "플라스틱용기", "플라스틱 컨테이너", "plastic cup", "plastic container", "plastic_cup_container"],
    "vinyl": ["비닐", "비닐봉투", "포장 비닐", "vinyl"],
}

def classify_label(text: str) -> str:
    text = text.lower()
    for class_name, keywords in CLASS_LABEL_KEYWORDS.items():
        if any(kw in text for kw in keywords):
            return class_name
    return "Other"

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

# ----------- chunk splitter -----------
splitter = RecursiveCharacterTextSplitter(
    chunk_size=300,   # 좀 더 세분화 원할 시 더 줄이기
    chunk_overlap=0,
    separators=[
        "\n\n", "\n", "end"    ]
)

# .docx 파일만 대상
#doc_paths = list(DOCUMENT_DIR.glob("*.docx")) + list(DOCUMENT_DIR.glob("*.DOCX"))
doc_paths = [DOCUMENT_DIR / "남양주시_분리수거규정.docx"]

print(f"\n📂 문서 탐색 경로: {DOCUMENT_DIR}")
print(f"🔍 문서 파일 수: {len(doc_paths)}")

for file_path in doc_paths:
    try:
        print(f"\n📄 Processing: {file_path.name}")
        region = extract_region_from_filename(file_path.name)

        loader = Docx2txtLoader(str(file_path))
        docs = loader.load()

        # --- 전처리: 주요 분할 키워드로 줄바꿈 강제 삽입
        def doc_pre_split(text):
            for kw in [
                "배출방법", "배출요령", "해당품목", "비해당품목",
                "종이류", "유리병", "금속캔", "비닐", "스티로폼", "플라스틱",
                "종이팩", "책자", "상자류", "포장지", "캔류", "고철", "전자제품", "형광등"
            ]:
                text = text.replace(kw, f"\n\n{kw}")
            return text

        if isinstance(docs, str):
            docs = [Document(page_content=doc_pre_split(docs))]
        elif isinstance(docs, list):
            if all(isinstance(doc, str) for doc in docs):
                docs = [Document(page_content=doc_pre_split(doc)) for doc in docs]
            elif all(isinstance(doc, Document) for doc in docs):
                pass
            else:
                raise ValueError(f"Unsupported document type in list: {type(docs[0])}")
        else:
            raise ValueError(f"Unsupported document type: {type(docs)}")

        # --- chunk 분할 ---
        chunks = splitter.split_documents(docs)
        print(f"분할된 chunk 수: {len(chunks)}")
        for idx, chunk in enumerate(chunks[:5], 1):
            print(f"\nchunk {idx} 샘플:\n{chunk.page_content[:200]}\n---")

        # --- 라벨링 및 DB 저장 ---
        ids = [str(uuid.uuid4()) for _ in chunks]
        documents = []
        for chunk, vector_id in zip(chunks, ids):
            label = classify_label(chunk.page_content)
            metadata = {
                "type": "guideline",
                "label": label,
                "region": region,
                "source_file": file_path.name
            }
            documents.append(Document(page_content=chunk.page_content, metadata=metadata))

        print(f"✅ vectordb 타입 확인: {type(vectordb)}")
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

