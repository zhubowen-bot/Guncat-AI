"""
Guncat 2.5-Pro - Agent核心模块

集成图片处理、视频处理、网页内容处理、文档处理、搜索服务和代码执行等多项能力。
"""

import os
import json
from typing import Annotated, Literal
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import AnyMessage, BaseMessage
from coze_coding_utils.runtime_ctx.context import default_headers
from storage.memory.memory_saver import get_memory_saver

# 导入所有工具模块
from tools.image_tools import (
    generate_image, image_understanding, extract_text_from_image,
    analyze_chart, compare_images, detect_objects, remove_watermark,
    enhance_image, style_transfer
)
from tools.video_tools import (
    generate_video, trim_video, concat_videos, extract_key_frames,
    extract_frames_by_interval, extract_audio, add_subtitles,
    auto_subtitle, analyze_video, extract_video_frames_count, combine_video_audio
)
from tools.web_tools import (
    fetch_webpage, extract_text_from_url, extract_images_from_url,
    extract_links_from_url, analyze_article, convert_url_to_markdown,
    summarize_article, compare_articles
)
from tools.document_tools import (
    create_pdf, create_docx, create_pptx, create_excel,
    translate_text, summarize_document, qa_document,
    extract_table_from_document, create_report, convert_document_format,
    proofread_document
)
from tools.search_tools import (
    web_search, web_search_with_ai_summary, image_search,
    search_news, academic_search, verify_information,
    get_knowledge_answer, compare_products, get_trending_topics
)
from tools.code_tools import (
    execute_python_code, calculate, generate_chart, parse_json,
    format_json, convert_data_format, generate_mindmap,
    analyze_data, generate_code, debug_code, explain_code,
    validate_json_schema
)

LLM_CONFIG = "config/agent_llm_config.json"

# 默认保留最近 20 轮对话 (40 条消息)
MAX_MESSAGES = 40

def _windowed_messages(old, new):
    """滑动窗口: 只保留最近 MAX_MESSAGES 条消息"""
    combined = add_messages(old, new)
    # 转换为list后切片
    return list(combined)[-MAX_MESSAGES:] if len(combined) > MAX_MESSAGES else list(combined)

class AgentState(MessagesState):
    messages: Annotated[list[AnyMessage], _windowed_messages]

def build_agent(ctx=None):
    """构建 Guncat 2.5-Pro Agent"""
    workspace_path = os.getenv("COZE_WORKSPACE_PATH", "/workspace/projects")
    config_path = os.path.join(workspace_path, LLM_CONFIG)

    with open(config_path, 'r', encoding='utf-8') as f:
        cfg = json.load(f)

    api_key = os.getenv("COZE_WORKLOAD_IDENTITY_API_KEY")
    base_url = os.getenv("COZE_INTEGRATION_MODEL_BASE_URL")

    llm = ChatOpenAI(
        model=cfg['config'].get("model"),
        api_key=api_key,
        base_url=base_url,
        temperature=cfg['config'].get('temperature', 0.7),
        streaming=True,
        timeout=cfg['config'].get('timeout', 600),
        extra_body={
            "thinking": {
                "type": cfg['config'].get('thinking', 'disabled')
            }
        },
        default_headers=default_headers(ctx) if ctx else {}
    )

    # 聚合所有工具
    tools = [
        # 图片处理工具
        generate_image, image_understanding, extract_text_from_image,
        analyze_chart, compare_images, detect_objects, remove_watermark,
        enhance_image, style_transfer,
        # 视频处理工具
        generate_video, trim_video, concat_videos, extract_key_frames,
        extract_frames_by_interval, extract_audio, add_subtitles,
        auto_subtitle, analyze_video, extract_video_frames_count, combine_video_audio,
        # 网页处理工具
        fetch_webpage, extract_text_from_url, extract_images_from_url,
        extract_links_from_url, analyze_article, convert_url_to_markdown,
        summarize_article, compare_articles,
        # 文档处理工具
        create_pdf, create_docx, create_pptx, create_excel,
        translate_text, summarize_document, qa_document,
        extract_table_from_document, create_report, convert_document_format,
        proofread_document,
        # 搜索工具
        web_search, web_search_with_ai_summary, image_search,
        search_news, academic_search, verify_information,
        get_knowledge_answer, compare_products, get_trending_topics,
        # 代码工具
        execute_python_code, calculate, generate_chart, parse_json,
        format_json, convert_data_format, generate_mindmap,
        analyze_data, generate_code, debug_code, explain_code,
        validate_json_schema
    ]

    return create_agent(
        model=llm,
        system_prompt=cfg.get("sp"),
        tools=tools,
        checkpointer=get_memory_saver(),
        state_schema=AgentState,
    )
