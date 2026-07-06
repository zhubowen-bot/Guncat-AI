"""
VectorStore - ChromaDB 向量数据库封装
负责法条的存储和检索
"""

from typing import List, Dict, Any, Optional
import chromadb
from chromadb.config import Settings
from chromadb.utils import embedding_functions
import os
from pathlib import Path


class VectorStore:
    """
    ChromaDB 向量存储封装类

    功能：
    1. 初始化/连接 ChromaDB 实例
    2. 创建/获取集合
    3. 添加文档（法条）到集合
    4. 相似度检索
    """

    def __init__(
        self,
        persist_path: str = None,
        collection_name: str = "guncat_law_db",
        embedding_model: str = "BAAI/bge-m3",
    ):
        """
        初始化向量存储

        Args:
            persist_path: ChromaDB 持久化路径，None 表示内存模式
            collection_name: 集合名称
            embedding_model: 向量化模型名称（sentence-transformers）
        """
        self.persist_path = persist_path
        self.collection_name = collection_name
        self.embedding_model_name = embedding_model

        # 初始化 ChromaDB 客户端
        if persist_path:
            os.makedirs(persist_path, exist_ok=True)
            self.client = chromadb.PersistentClient(path=persist_path)
        else:
            self.client = chromadb.Client()

        # 设置 embedding 函数
        self._setup_embedding_function()

        # 获取或创建集合
        self.collection = self._get_or_create_collection()

    def _setup_embedding_function(self):
        """设置向量化函数"""
        try:
            # 使用 sentence-transformers 作为 embedding 后端
            from sentence_transformers import SentenceTransformer
            self.embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
                model_name=self.embedding_model_name,
                device="cpu",  # 如有GPU可改为"cuda"
            )
        except ImportError:
            # 降级：使用默认的 Chroma embedding
            self.embedding_fn = embedding_functions.DefaultEmbeddingFunction()

    def _get_or_create_collection(self):
        """获取或创建集合"""
        try:
            collection = self.client.get_collection(
                name=self.collection_name,
                embedding_function=self.embedding_fn,
            )
        except (ValueError, chromadb.errors.NotFoundError):
            collection = self.client.create_collection(
                name=self.collection_name,
                embedding_function=self.embedding_fn,
                metadata={"description": "Guncat Srch-Law 法律条文向量库"},
            )
        return collection

    def add_documents(self, documents: List[Dict[str, Any]]) -> int:
        """
        添加文档到向量库

        Args:
            documents: 文档列表，每条包含：
                - content: 法条内容
                - source: 来源文件（如"企业国有资产法"）
                - article: 条款号（如"第32条"）
                - effective_date: 生效日期
                - [可选] metadata: 其它元数据

        Returns:
            成功添加的文档数量
        """
        if not documents:
            return 0

        ids = []
        contents = []
        metadatas = []

        for i, doc in enumerate(documents):
            doc_id = doc.get("id", f"doc_{i}_{hash(doc['content'])}")
            ids.append(str(doc_id))
            contents.append(doc["content"])

            # 构建元数据
            metadata = {
                "source": doc.get("source", "未知"),
                "article": doc.get("article", ""),
                "effective_date": doc.get("effective_date", ""),
                "law_type": doc.get("law_type", ""),  # 法律/行政法规/部门规章
            }
            # 添加额外元数据
            if "metadata" in doc:
                metadata.update(doc["metadata"])
            metadatas.append(metadata)

        # 批量添加
        self.collection.add(
            ids=ids,
            documents=contents,
            metadatas=metadatas,
        )

        return len(ids)

    def search(
        self,
        query: str,
        top_k: int = 5,
        filter_dict: Optional[Dict] = None,
    ) -> List[Dict[str, Any]]:
        """
        相似度检索

        Args:
            query: 查询文本
            top_k: 返回结果数量
            filter_dict: 元数据过滤条件（如 {"source": "企业国有资产法"}）

        Returns:
            检索结果列表，每条包含 content, metadata, distance/score
        """
        results = self.collection.query(
            query_texts=[query],
            n_results=top_k,
            where=filter_dict,
        )

        # 格式化结果
        formatted = []
        if results and results.get("ids"):
            for i in range(len(results["ids"][0])):
                formatted.append({
                    "id": results["ids"][0][i],
                    "content": results["documents"][0][i],
                    "source": results["metadatas"][0][i].get("source", ""),
                    "article": results["metadatas"][0][i].get("article", ""),
                    "effective_date": results["metadatas"][0][i].get("effective_date", ""),
                    "law_type": results["metadatas"][0][i].get("law_type", ""),
                    "score": 1 - results["distances"][0][i],  # 距离转相似度
                })

        return formatted

    def clear_collection(self):
        """清空集合（谨慎使用）"""
        try:
            self.client.delete_collection(self.collection_name)
            self.collection = self._get_or_create_collection()
        except Exception as e:
            print(f"清空集合失败: {e}")

    def count(self) -> int:
        """返回集合中的文档数量"""
        return self.collection.count()

    def list_sources(self) -> List[str]:
        """列出知识库中所有来源文件"""
        results = self.collection.get(include=["metadatas"])
        sources = set()
        if results and results.get("metadatas"):
            for m in results["metadatas"]:
                if "source" in m:
                    sources.add(m["source"])
        return sorted(list(sources))
