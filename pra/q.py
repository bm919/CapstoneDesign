from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma

# 1) ChromaDB 및 임베딩 모델 연결
hf_embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectordb = Chroma(
    embedding_function=hf_embeddings,
    persist_directory="./chroma_db",
    collection_name="waste_policy_hf"
)

# 2) 조건 필터링용 값 직접 지정 (여기서 원하는 값으로 변경)
label = "Plastic"    # 또는 "plastic_cup_container"
region = "춘천시"
doc_type = "guideline"

# 3) Retriever 생성 및 쿼리 (필터 포함, 최신 방식)
retriever = vectordb.as_retriever(
    search_type="similarity",
    search_kwargs={
        "k": 4,  # 원하는 결과 수
        "filter": {
            "and": [
                {"type": doc_type},
                {"label": label},
                {"region": region}
            ]
        }
    }
)

# 4) 실제 쿼리어(검색어)는 아무거나 ("분리수거 방법 알려줘" 등)
results = retriever.invoke("분리수거 방법 알려줘")  # LangChain 최신 방식은 .invoke() 사용

# 5) 출력 (meta, 내용 모두)
for i, doc in enumerate(results, 1):
    print(f"--- Result {i} ---")
    print(f"[region: {doc.metadata.get('region')}] [label: {doc.metadata.get('label')}] [type: {doc.metadata.get('type')}]")
    print(f"source: {doc.metadata.get('source_file')}")
    print(doc.page_content[:300], "\n")
