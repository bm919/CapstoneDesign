from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma

embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectordb = Chroma(
    embedding_function=embeddings,
    persist_directory="./chroma_db",
    collection_name="waste_policy_hf"
)

collection = vectordb._collection  # Chroma 내부 collection 접근
result = collection.get(include=["metadatas"], limit=3)
for i, meta in enumerate(result["metadatas"], 1):
    print(f"📄 meta {i}: {meta}")
