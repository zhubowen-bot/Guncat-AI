"""
RAG Engine - 法律条文向量检索引擎
支持从本地知识库检索相关法条，为Agent提供准确的法律依据
"""

from typing import List, Dict, Any, Optional
import os
from pathlib import Path

from .vector_store import VectorStore


class RAGEngine:
    """
    法律RAG检索引擎

    功能：
    1. 加载法律条文到向量数据库
    2. 根据用户查询检索相关法条
    3. 返回格式化后的检索结果（含来源、条款号、生效日期）
    """

    def __init__(
        self,
        vector_store_path: str = None,
        collection_name: str = "guncat_law_db",
        embedding_model: str = "BAAI/bge-m3",
    ):
        """
        初始化RAG引擎

        Args:
            vector_store_path: ChromaDB存储路径
            collection_name: 集合名称
            embedding_model: 向量化模型名称
        """
        self.vector_store = VectorStore(
            persist_path=vector_store_path,
            collection_name=collection_name,
            embedding_model=embedding_model,
        )
        self.is_initialized = False

    def initialize(self, force_reload: bool = False):
        """
        初始化知识库（加载法条数据到向量数据库）

        Args:
            force_reload: 是否强制重新加载（覆盖已有数据）
        """
        if self.is_initialized and not force_reload:
            return

        # 加载核心法规数据
        from . import law_data_loader

        documents = law_data_loader.load_core_regulations()

        if force_reload:
            # 清空现有集合
            self.vector_store.clear_collection()

        # 添加到向量库
        self.vector_store.add_documents(documents)
        self.is_initialized = True

    def search(
        self,
        query: str,
        top_k: int = 5,
        score_threshold: float = 0.3,
        filter_dict: Optional[Dict] = None,
    ) -> List[Dict[str, Any]]:
        """
        检索相关法条

        Args:
            query: 查询文本（如案件描述、法律概念）
            top_k: 返回top-k条结果
            score_threshold: 相似度阈值（低于此值的结果被过滤）
            filter_dict: 可选过滤条件（如 {"source": "企业国有资产法"}）

        Returns:
            检索结果列表，每条包含：
            - content: 法条内容
            - source: 来源文件
            - article: 条款号
            - effective_date: 生效日期
            - score: 相似度得分
        """
        if not self.is_initialized:
            self.initialize()

        results = self.vector_store.search(
            query=query,
            top_k=top_k,
            filter_dict=filter_dict,
        )

        # 过滤低相似度结果
        filtered = [
            r for r in results
            if r.get("score", 0) >= score_threshold
        ]

        return filtered

    def search_by_source(self, source_name: str, top_k: int = 10) -> List[Dict[str, Any]]:
        """
        按来源文件检索（精准检索）

        Args:
            source_name: 来源文件名称（如"企业国有资产法"）
            top_k: 返回条数

        Returns:
            检索结果列表
        """
        return self.search(
            query=source_name,
            top_k=top_k,
            filter_dict={"source": source_name},
        )

    def format_results(self, results: List[Dict[str, Any]]) -> str:
        """
        将检索结果格式化为可读文本

        Args:
            results: 检索结果列表

        Returns:
            格式化后的文本，可直接拼接到prompt中
        """
        if not results:
            return "【未检索到相关法条】"

        lines = ["【相关法条检索结果】\n"]
        for i, r in enumerate(results, 1):
            content = r.get("content", "")
            source = r.get("source", "未知来源")
            article = r.get("article", "")
            effective_date = r.get("effective_date", "")
            score = r.get("score", 0)

            line = f"{i}. 《{source}》"
            if article:
                line += f"{article}"
            if effective_date:
                line += f"（生效日期：{effective_date}）"
            line += f"\n   内容：{content}"
            line += f"\n   相似度：{score:.3f}"
            lines.append(line)

        return "\n".join(lines)

    def get_law_by_keywords(self, keywords: List[str], top_k: int = 5) -> str:
        """
        根据关键词列表检索并格式化结果（便捷方法）

        Args:
            keywords: 关键词列表
            top_k: 每个关键词检索的条数

        Returns:
            格式化后的检索结果文本
        """
        all_results = []
        seen = set()

        for kw in keywords:
            results = self.search(kw, top_k=top_k)
            for r in results:
                # 去重
                content_hash = hash(r.get("content", ""))
                if content_hash not in seen:
                    seen.add(content_hash)
                    all_results.append(r)

        return self.format_results(all_results)
