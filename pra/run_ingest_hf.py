import os
from itertools import islice
from dotenv import load_dotenv

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_community.document_loaders import PyPDFLoader

# 1) .env 로드 (HUGGINGFACE_API_KEY가 필요 없지만, .env 파일 구조 통일)
load_dotenv()

# 2) PDF 파일 위치 & Chroma 설정
PDF_PATH = "/home/ubuntu/ai-api/document_data.pdf"
PERSIST_DIR = "chroma_db"
COLLECTION = "waste_policy_hf"

os.makedirs(PERSIST_DIR, exist_ok=True)

# 3) 텍스트 로드 & 분할
loader = PyPDFLoader(PDF_PATH)
docs = loader.load()

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=100,
    separators=["\n\n", "\n", " ", ""]
)
chunks = splitter.split_documents(docs)

# 4. HuggingFace 임베딩 모델 지정
hf_embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

texts = [chunk.page_content for chunk in chunks]
metadatas = [chunk.metadata for chunk in chunks]

# 5. Chroma 벡터스토어 초기화
vector_db = Chroma(
    embedding_function=hf_embeddings,
    persist_directory=PERSIST_DIR,
    collection_name=COLLECTION
)

# 6. 문서 업로드
batch_size = 20
for i in range(0, len(chunks), batch_size):
    batch = chunks[i:i+batch_size]
    batch_ids = [str(i + j) for j in range(len(batch))]

    vector_db.add_documents(
        documents=batch,
        ids=batch_ids
    )
    print("[batch {idx//batch_size + 1}] ingested {len(batch_texts)} chunks")

vector_db.persist()
print(f"✅ Ingest complete: {len(texts)} chunks into '{COLLECTION}'")
