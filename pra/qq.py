from chromadb import PersistentClient
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma

# 1) 조건 강제 지정
label = "Plastic"
region = "춘천시"
doc_type = "guideline"
query_text = "분리수거 방법 알려줘"

# 2) ChromaDB 연결
client = PersistentClient(path="./chroma_db")
hf_embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectordb = Chroma(
    client=client,
    collection_name="waste_policy_hf",
    embedding_function=hf_embeddings
)

# 3) 필터 적용 (최신 문법)
retriever = vectordb.as_retriever(
    search_type="similarity",
    search_kwargs={
        "k": 4,
        "filter": {
            "where": {
                "and": [
                    {"type": {"$eq": doc_type}},
                    {"label": {"$eq": label}},
                    {"region": {"$eq": region}}
                ]
            }
        }
    }
)

# 4) 쿼리 및 터미널 출력
docs = retriever.invoke(query_text)
for i, doc in enumerate(docs, 1):
    print(f"\n--- Result {i} ---")
    print(f"region: {doc.metadata.get('region')}, label: {doc.metadata.get('label')}, type: {doc.metadata.get('type')}")
    print(f"내용: {doc.page_content[:200]} ...")

