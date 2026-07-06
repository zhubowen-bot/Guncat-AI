"""
Guncat Srch-Law V2 配置文件
所有可配置参数集中管理
"""

import os
from pathlib import Path

# 项目根目录
BASE_DIR = Path(__file__).parent

# ============ 模型配置 ============
MODEL_CONFIG = {
    "provider": os.getenv("LLM_PROVIDER", "openai"),  # openai / anthropic / qwen
    "model_name": os.getenv("LLM_MODEL", "gpt-4o"),
    "api_key": os.getenv("LLM_API_KEY", ""),
    "api_base": os.getenv("LLM_API_BASE", ""),  # 可选：自定义 API 地址
    "temperature": 0.1,  # 法律分析需要低温度
    "max_tokens": 8192,
}

# ============ 知识库配置 ============
KNOWLEDGE_BASE_CONFIG = {
    "embedding_model": "BAAI/bge-m3",  # 中文法律文本最佳选择
    "vector_store_path": str(BASE_DIR / "knowledge_base" / "chroma_db"),
    "collection_name": "guncat_law_db",
    "top_k": 5,  # 每次检索返回 top-k 条
    "score_threshold": 0.3,  # 相似度阈值
}

# ============ 国企法律核心法规清单 ============
# 这些是 RAG 知识库需要预先加载的法规
CORE_REGULATIONS = [
    # 法律
    "中华人民共和国企业国有资产法",
    "中华人民共和国公司法（2023修订）",
    "中华人民共和国行政处罚法",
    "中华人民共和国刑法（国企相关条款）",
    # 行政法规
    "企业国有资产交易监督管理办法（国资委财政部令第32号）",
    "企业国有资产监督管理暂行条例",
    # 国资委规范性文件
    "关于进一步推进国有企业贯彻落实"三重一大"决策制度的意见",
    "中央企业合规管理办法",
    "国有企业参股管理暂行办法",
    "企业国有资产评估管理暂行办法",
    # 司法解释
    "最高人民法院关于适用《中华人民共和国公司法》若干问题的规定（一~五）",
]

# ============ Agent 配置 ============
AGENT_CONFIG = {
    "max_iterations": 10,  # 单轮最大推理步数
    "recursion_limit": 50,  # 递归深度限制
    "enable_streaming": True,
}

# ============ 输出配置 ============
OUTPUT_CONFIG = {
    "output_dir": str(BASE_DIR / "output"),
    "template_path": str(BASE_DIR / "templates" / "legal_opinion_template.md"),
    "supported_formats": ["markdown", "docx", "pdf"],
    "default_format": "markdown",
}

# ============ 联网检索配置 ============
SEARCH_CONFIG = {
    "enabled": True,
    "max_results": 5,
    "search_regions": ["cn"],  # 优先中文结果
    "time_range": "past_2y",  # 法律时效性：检索近2年
}
