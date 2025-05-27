from langchain.embeddings import HuggingFaceEmbeddings
from langchain.vectorstores import Chroma

# 1) 같은 HF 임베딩 & Chroma 연결
hf_embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectordb = Chroma(
    embedding_function=hf_embeddings,
    persist_directory="./chroma_db",
    collection_name="waste_policy_hf"
)

# 2) Retriever 생성 & 쿼리
retriever = vectordb.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 4}
)

results = retriever.get_relevant_documents("배출방법 안내")

# 3) 출력
for doc in results:
    header = doc.metadata.get("header", "NoHeader")
    print(f"[{header}] {doc.page_content[:200].replace(chr(10), ' ')}...\n")

