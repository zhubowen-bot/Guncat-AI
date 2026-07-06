"""
网页与内容处理工具模块
提供网页抓取、内容提取、链接分析、格式转换等能力
"""
from typing import List, Optional
from langchain.tools import tool
from coze_coding_dev_sdk.fetch import FetchClient
from coze_coding_dev_sdk import LLMClient, DocumentGenerationClient
from coze_coding_utils.runtime_ctx.context import new_context
from coze_coding_utils.log.write_log import request_context
from langchain_core.messages import HumanMessage, SystemMessage


def _get_ctx():
    """获取请求上下文"""
    return request_context.get() or new_context(method="web_tools")


def _get_text_content(content):
    """安全获取文本内容"""
    if isinstance(content, str):
        return content
    elif isinstance(content, list):
        if content and isinstance(content[0], str):
            return " ".join(content)
        else:
            return " ".join(item.get("text", "") for item in content if isinstance(item, dict) and item.get("type") == "text")
    return str(content)


@tool
def fetch_webpage(url: str) -> str:
    """
    网页内容抓取工具。获取网页的标题、文本内容和链接。
    
    参数:
        url: 网页URL
    
    返回:
        网页标题和内容摘要
    """
    ctx = _get_ctx()
    client = FetchClient(ctx=ctx)
    
    response = client.fetch(url=url)
    
    if response.status_code == 0:
        # 提取文本内容
        text_parts = []
        for item in response.content:
            if item.type == "text":
                text_parts.append(item.text)
        
        content = "\\n".join(text_parts)
        
        result = f"标题: {response.title}\\n"
        result += f"来源: {response.url}\\n"
        result += f"发布时间: {response.publish_time or '未知'}\\n"
        result += f"\\n内容摘要:\\n{content[:2000]}"
        
        if len(content) > 2000:
            result += f"\\n... (还有 {len(content) - 2000} 字)"
        
        return result
    else:
        return f"网页抓取失败: {response.status_message}"


@tool
def extract_text_from_url(url: str) -> str:
    """
    URL文本提取工具。从URL中提取纯文本内容。
    
    参数:
        url: 支持的URL类型，包括网页、PDF、Office文档等
    
    返回:
        提取的文本内容
    """
    ctx = _get_ctx()
    client = FetchClient(ctx=ctx)
    
    response = client.fetch(url=url)
    
    if response.status_code == 0:
        text_parts = []
        for item in response.content:
            if item.type == "text":
                text_parts.append(item.text)
        
        return "\\n".join(text_parts)
    else:
        return f"文本提取失败: {response.status_message}"


@tool
def extract_images_from_url(url: str) -> str:
    """
    URL图片提取工具。提取网页中的所有图片URL。
    
    参数:
        url: 网页URL
    
    返回:
        图片URL列表（注意：链接有过期时间）
    """
    ctx = _get_ctx()
    client = FetchClient(ctx=ctx)
    
    response = client.fetch(url=url)
    
    if response.status_code == 0:
        images = []
        for item in response.content:
            if item.type == "image":
                images.append({
                    "url": item.image.display_url,
                    "width": item.image.width,
                    "height": item.image.height,
                    "thumbnail": item.image.thumbnail_display_url
                })
        
        if images:
            result = f"提取到 {len(images)} 张图片：\\n"
            for i, img in enumerate(images, 1):
                result += f"\\n{i}. {img['url']}\\n   尺寸: {img['width']}x{img['height']}\\n   缩略图: {img['thumbnail']}"
            result += "\\n\\n⚠️ 注意：这些链接有过期时间，如需永久链接请使用原始URL。"
            return result
        else:
            return "未找到图片"
    else:
        return f"图片提取失败: {response.status_message}"


@tool
def extract_links_from_url(url: str) -> str:
    """
    链接提取工具。提取网页中的所有超链接。
    
    参数:
        url: 网页URL
    
    返回:
        链接列表及其描述
    """
    ctx = _get_ctx()
    client = FetchClient(ctx=ctx)
    
    response = client.fetch(url=url)
    
    if response.status_code == 0:
        links = []
        for item in response.content:
            if item.type == "link":
                links.append(item.url)
        
        if links:
            return f"提取到 {len(links)} 个链接：\\n" + "\\n".join([f"- {link}" for link in links[:50]])
        else:
            return "未找到链接"
    else:
        return f"链接提取失败: {response.status_message}"


@tool
def analyze_article(url: str) -> str:
    """
    文章分析工具。深度分析网页文章内容，提取关键信息。
    
    参数:
        url: 文章URL
    
    返回:
        文章分析结果
    """
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    response = fetch_client.fetch(url=url)
    
    if response.status_code != 0:
        return f"文章获取失败: {response.status_message}"
    
    # 提取文本
    text_parts = []
    for item in response.content:
        if item.type == "text":
            text_parts.append(item.text)
    
    article_text = "\\n".join(text_parts)
    
    # 使用LLM分析
    messages = [
        SystemMessage(content="你是一个专业的文章分析专家。请分析以下文章内容，提取关键信息、核心观点和结构。"),
        HumanMessage(content=f"文章标题: {response.title}\\n\\n文章内容:\\n{article_text[:5000]}")
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.3)
    
    analysis = _get_text_content(result.content)
    
    return f"文章: {response.title}\\n\\n分析结果:\\n{analysis}"


@tool
def convert_url_to_markdown(url: str) -> str:
    """
    URL转Markdown工具。将网页内容转换为Markdown格式。
    
    参数:
        url: 网页URL
    
    返回:
        Markdown格式的内容
    """
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    response = fetch_client.fetch(url=url)
    
    if response.status_code != 0:
        return f"内容获取失败: {response.status_message}"
    
    # 提取文本和图片
    text_parts = []
    images = []
    for item in response.content:
        if item.type == "text":
            text_parts.append(item.text)
        elif item.type == "image":
            images.append(item.image.display_url)
    
    article_text = "\\n".join(text_parts)
    
    # 使用LLM转换为Markdown
    messages = [
        SystemMessage(content="你是一个专业的文档转换专家。请将文章内容转换为格式良好的Markdown，保留标题层级、列表、链接等格式。"),
        HumanMessage(content=f"标题: {response.title}\\n\\n内容:\\n{article_text}")
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.3)
    
    md_content = _get_text_content(result.content)
    
    # 添加图片
    if images:
        md_content += "\\n\\n## 相关图片\\n"
        for img in images[:10]:
            md_content += f"\\n![]({img})"
    
    return md_content


@tool
def summarize_article(url: str, max_length: int = 500) -> str:
    """
    文章摘要工具。对网页文章生成简洁摘要。
    
    参数:
        url: 文章URL
        max_length: 摘要最大字数，默认500
    
    返回:
        文章摘要
    """
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    response = fetch_client.fetch(url=url)
    
    if response.status_code != 0:
        return f"文章获取失败: {response.status_message}"
    
    # 提取文本
    text_parts = []
    for item in response.content:
        if item.type == "text":
            text_parts.append(item.text)
    
    article_text = "\\n".join(text_parts)
    
    # 生成摘要
    messages = [
        SystemMessage(content=f"请为以下文章生成简洁的摘要，控制在{max_length}字以内，保留核心要点。"),
        HumanMessage(content=f"文章标题: {response.title}\\n\\n文章内容:\\n{article_text[:8000]}")
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.3)
    
    return f"标题: {response.title}\\n\\n摘要:\\n{_get_text_content(result.content)}"


@tool
def compare_articles(urls: List[str]) -> str:
    """
    文章对比工具。对比多篇文章的异同和关键信息。
    
    参数:
        urls: 文章URL列表，至少2个URL
    
    返回:
        文章对比分析结果
    """
    if len(urls) < 2:
        return "请至少提供2篇文章URL进行对比"
    
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    articles = []
    
    for url in urls:
        response = fetch_client.fetch(url=url)
        if response.status_code == 0:
            text_parts = []
            for item in response.content:
                if item.type == "text":
                    text_parts.append(item.text)
            articles.append({
                "title": response.title,
                "url": url,
                "content": "\\n".join(text_parts)[:3000]
            })
    
    if not articles:
        return "无法获取任何文章内容"
    
    # 对比分析
    comparison_text = "\\n\\n---\\n\\n".join([
        f"### {a['title']}\\n来源: {a['url']}\\n\\n{a['content']}"
        for a in articles
    ])
    
    messages = [
        SystemMessage(content="你是一个专业的文章对比分析专家。请对比以下文章，提取各自的核心观点、相同点和不同点。"),
        HumanMessage(content=comparison_text)
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.5)
    
    return f"对比分析结果:\\n\\n{_get_text_content(result.content)}"
