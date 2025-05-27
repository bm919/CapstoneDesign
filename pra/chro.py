import pandas as pd
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma

# 저장된 ChromaDB 디렉토리와 컬렉션 이름 (여기만 환경에 맞게!)
PERSIST_DIR = "./chroma_db"
COLLECTION = "waste_vectors"

# 임베딩 함수 선언 (컬렉션 조회에 필요)
hf_embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2",
    model_kwargs={"device": "cpu"},
    encode_kwargs={"batch_size": 5}
)

# ChromaDB 컬렉션 연결
vectordb = Chroma(
    embedding_function=hf_embeddings,
    persist_directory=PERSIST_DIR,
    collection_name=COLLECTION
)

# 컬렉션에서 데이터 가져오기
results = vectordb._collection.get(
    include=["metadatas","documents"],  # 필요시 "embeddings" 추가 가능
      # 원하는 개수 조회 (없애면 전체)
)

# DataFrame 변환
df = pd.DataFrame({
    "id": results.get("ids"),
    "document": results.get("documents"),
    "metadata": results.get("metadatas"),
    # "embedding": results.get("embeddings"),  # 필요시 주석 해제
})

# 상위 5개 미리보기
print(df)

df.to_csv("chroma_dump.csv", index=False)
