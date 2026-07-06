"""
BaseAgent - 所有 Agent 的基类
定义通用接口和方法
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Any, Optional
from langchain.chat_models import init_chat_model
from langchain.schema import HumanMessage, SystemMessage
from ...config import MODEL_CONFIG


class BaseAgent(ABC):
    """Agent 基类，所有专用 Agent 继承此类"""

    def __init__(self, name: str, system_prompt: str):
        self.name = name
        self.system_prompt = system_prompt
        self.chat_history: List[Dict] = []

        # 初始化 LLM
        self.llm = self._init_llm()

    def _init_llm(self):
        """初始化语言模型"""
        provider = MODEL_CONFIG["provider"]
        model_name = MODEL_CONFIG["model_name"]

        if provider == "openai":
            from langchain_openai import ChatOpenAI
            return ChatOpenAI(
                model=model_name,
                temperature=MODEL_CONFIG["temperature"],
                max_tokens=MODEL_CONFIG["max_tokens"],
                api_key=MODEL_CONFIG["api_key"] or None,
                base_url=MODEL_CONFIG["api_base"] or None,
            )
        elif provider == "anthropic":
            from langchain_anthropic import ChatAnthropic
            return ChatAnthropic(
                model=model_name,
                temperature=MODEL_CONFIG["temperature"],
                max_tokens=MODEL_CONFIG["max_tokens"],
                api_key=MODEL_CONFIG["api_key"] or None,
            )
        elif provider == "qwen":
            from langchain_openai import ChatOpenAI
            return ChatOpenAI(
                model=model_name,
                temperature=MODEL_CONFIG["temperature"],
                max_tokens=MODEL_CONFIG["max_tokens"],
                api_key=MODEL_CONFIG["api_key"],
                base_url=MODEL_CONFIG["api_base"] or "https://dashscope.aliyuncs.com/compatible-mode/v1",
            )
        else:
            raise ValueError(f"不支持的模型提供商: {provider}")

    @abstractmethod
    def analyze(self, case_info: Dict[str, Any]) -> Dict[str, Any]:
        """
        执行分析的主方法（由子类实现）

        Args:
            case_info: 案件信息字典，包含事实、主体、争议点等

        Returns:
            分析结果字典
        """
        pass

    def _call_llm(self, user_prompt: str, context: Optional[str] = None) -> str:
        """
        调用 LLM 进行推理

        Args:
            user_prompt: 用户提示词
            context: 可选的上文上下文（如RAG检索结果）

        Returns:
            LLM 生成的回复
        """
        messages = [SystemMessage(content=self.system_prompt)]

        # 添加历史对话
        for msg in self.chat_history:
            if msg["role"] == "user":
                messages.append(HumanMessage(content=msg["content"]))
            # 可扩展添加 AI 消息

        # 添加当前prompt（如有上下文则拼接）
        full_prompt = user_prompt
        if context:
            full_prompt = f"【参考信息】\n{context}\n\n【分析任务】\n{user_prompt}"

        messages.append(HumanMessage(content=full_prompt))

        response = self.llm.invoke(messages)
        return response.content

    def add_to_history(self, role: str, content: str):
        """添加消息到对话历史"""
        self.chat_history.append({"role": role, "content": content})

    def clear_history(self):
        """清空对话历史"""
        self.chat_history = []
