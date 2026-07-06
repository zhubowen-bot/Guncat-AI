"""
文档处理工具模块
提供文档生成、格式转换、翻译、阅读理解等能力
"""
from typing import List, Dict, Any, Optional
from langchain.tools import tool
from coze_coding_dev_sdk import DocumentGenerationClient, LLMClient
from coze_coding_dev_sdk.fetch import FetchClient
from coze_coding_utils.runtime_ctx.context import new_context
from coze_coding_utils.log.write_log import request_context
from langchain_core.messages import HumanMessage, SystemMessage


def _get_ctx():
    """获取请求上下文"""
    return request_context.get() or new_context(method="document_tools")


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
def create_pdf(content: str, title: str = "document") -> str:
    """
    PDF生成工具。从Markdown内容生成PDF文档。
    
    参数:
        content: Markdown格式的文档内容
        title: 文档标题（英文，用于文件名）
    
    返回:
        PDF下载链接
    """
    ctx = _get_ctx()
    client = DocumentGenerationClient()
    
    # 生成PDF
    url = client.create_pdf_from_markdown(content, title)
    
    return f"PDF文档已生成：\\n{url}"


@tool
def create_docx(content: str, title: str = "document") -> str:
    """
    Word文档生成工具。从Markdown内容生成DOCX文档。
    
    参数:
        content: Markdown格式的文档内容
        title: 文档标题（英文，用于文件名）
    
    返回:
        DOCX下载链接
    """
    ctx = _get_ctx()
    client = DocumentGenerationClient()
    
    url = client.create_docx_from_markdown(content, title)
    
    return f"Word文档已生成：\\n{url}"


@tool
def create_pptx(markdown_content: str, title: str = "presentation") -> str:
    """
    PPT生成工具。从Markdown内容生成PowerPoint演示文稿。
    使用 --- 分隔各幻灯片。
    
    参数:
        markdown_content: Markdown格式的演示文稿内容，使用 --- 分隔幻灯片
        title: 演示文稿标题（英文，用于文件名）
    
    返回:
        PPTX下载链接
    """
    ctx = _get_ctx()
    client = DocumentGenerationClient()
    
    url = client.create_pptx_from_markdown(markdown_content, title)
    
    return f"PPT演示文稿已生成：\\n{url}"


@tool
def create_excel(data: List[Dict[str, Any]], title: str = "data", sheet_name: str = "Sheet1") -> str:
    """
    Excel表格生成工具。从数据列表生成XLSX电子表格。
    
    参数:
        data: 数据列表，每项为字典
        title: 文件标题（英文，用于文件名）
        sheet_name: 工作表名称
    
    返回:
        XLSX下载链接
    """
    ctx = _get_ctx()
    client = DocumentGenerationClient()
    
    url = client.create_xlsx_from_list(data, title, sheet_name)
    
    return f"Excel表格已生成：\\n{url}"


@tool
def translate_text(text: str, target_language: str = "English") -> str:
    """
    多语言翻译工具。将文本翻译成指定语言。
    
    参数:
        text: 待翻译的文本
        target_language: 目标语言，如 "English", "Japanese", "Korean", "French" 等
    
    返回:
        翻译后的文本
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content=f"你是一个专业的翻译专家。请将以下内容翻译成{target_language}，保持原文风格和语气，准确传达原意。"),
        HumanMessage(content=text)
    ]
    
    result = client.invoke(messages=messages, temperature=0.3)
    
    return f"原文：\\n{text}\\n\\n翻译（{target_language}）：\\n{_get_text_content(result.content)}"


@tool
def summarize_document(url: str, max_length: int = 800) -> str:
    """
    文档摘要工具。对PDF、Word等文档生成摘要。
    
    参数:
        url: 文档URL（支持PDF、DOC、DOCX等格式）
        max_length: 摘要最大字数，默认800
    
    返回:
        文档摘要
    """
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    response = fetch_client.fetch(url=url)
    
    if response.status_code != 0:
        return f"文档获取失败: {response.status_message}"
    
    # 提取文本
    text_parts = []
    for item in response.content:
        if item.type == "text":
            text_parts.append(item.text)
    
    content = "\\n".join(text_parts)
    
    # 生成摘要
    messages = [
        SystemMessage(content=f"请为这篇文档生成简洁的摘要，控制在{max_length}字以内，提取核心要点。"),
        HumanMessage(content=f"文档标题: {response.title}\\n\\n文档内容:\\n{content[:10000]}")
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.3)
    
    return f"文档: {response.title}\\n\\n摘要：\\n{_get_text_content(result.content)}"


@tool
def qa_document(question: str, url: str) -> str:
    """
    文档问答工具。基于文档内容回答问题。
    
    参数:
        question: 关于文档的问题
        url: 文档URL
    
    返回:
        基于文档的回答
    """
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    response = fetch_client.fetch(url=url)
    
    if response.status_code != 0:
        return f"文档获取失败: {response.status_message}"
    
    # 提取文本
    text_parts = []
    for item in response.content:
        if item.type == "text":
            text_parts.append(item.text)
    
    content = "\\n".join(text_parts)
    
    # 回答问题
    messages = [
        SystemMessage(content="你是一个专业的文档阅读助手。请根据提供的文档内容回答用户问题。如果文档中没有相关信息，请明确说明。"),
        HumanMessage(content=f"文档标题: {response.title}\\n\\n文档内容:\\n{content[:10000]}\\n\\n用户问题: {question}")
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.5)
    
    return f"问题: {question}\\n\\n回答：\\n{_get_text_content(result.content)}"


@tool
def extract_table_from_document(url: str) -> str:
    """
    文档表格提取工具。从文档中提取表格数据。
    
    参数:
        url: 文档URL
    
    返回:
        提取的表格数据（Markdown格式）
    """
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    response = fetch_client.fetch(url=url)
    
    if response.status_code != 0:
        return f"文档获取失败: {response.status_message}"
    
    # 提取文本
    text_parts = []
    for item in response.content:
        if item.type == "text":
            text_parts.append(item.text)
    
    content = "\\n".join(text_parts)
    
    # 提取表格
    messages = [
        SystemMessage(content="请从以下文档内容中提取所有表格，并以Markdown表格格式输出。"),
        HumanMessage(content=content[:10000])
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.3)
    
    return f"文档: {response.title}\\n\\n提取的表格：\\n{_get_text_content(result.content)}"


@tool
def create_report(
    title: str,
    sections: List[Dict[str, str]],
    format: str = "pdf"
) -> str:
    """
    报告生成工具。创建结构化报告文档。
    
    参数:
        title: 报告标题
        sections: 报告章节列表，格式为 [{"heading": "章节标题", "content": "章节内容"}, ...]
        format: 输出格式，支持 "pdf", "docx", "pptx"
    
    返回:
        生成的报告下载链接
    """
    ctx = _get_ctx()
    client = DocumentGenerationClient()
    
    # 构建Markdown内容
    content = f"# {title}\\n\\n"
    for section in sections:
        content += f"## {section.get('heading', '')}\\n\\n{section.get('content', '')}\\n\\n"
    
    # 生成文档
    title_en = title.replace(" ", "_")[:50]
    
    if format == "pdf":
        url = client.create_pdf_from_markdown(content, title_en)
    elif format == "docx":
        url = client.create_docx_from_markdown(content, title_en)
    elif format == "pptx":
        # 转换为PPT格式
        md_slides = f"# {title}\\n\\n---\\n\\n"
        for section in sections:
            md_slides += f"## {section.get('heading', '')}\\n\\n{section.get('content', '')}\\n\\n---\\n\\n"
        url = client.create_pptx_from_markdown(md_slides, title_en)
    else:
        return f"不支持的格式: {format}"
    
    return f"报告已生成（{format.upper()}）：\\n{url}"


@tool
def convert_document_format(
    source_url: str,
    source_format: str,
    target_format: str
) -> str:
    """
    文档格式转换工具。在不同文档格式间转换。
    
    参数:
        source_url: 源文档URL
        source_format: 源格式（自动检测，可忽略）
        target_format: 目标格式，支持 "pdf", "docx"
    
    返回:
        转换后的文档URL
    """
    ctx = _get_ctx()
    fetch_client = FetchClient(ctx=ctx)
    doc_client = DocumentGenerationClient()
    
    # 获取内容
    response = fetch_client.fetch(url=source_url)
    
    if response.status_code != 0:
        return f"文档获取失败: {response.status_message}"
    
    # 提取文本
    text_parts = []
    for item in response.content:
        if item.type == "text":
            text_parts.append(item.text)
    
    content = "\\n".join(text_parts)
    title = response.title.replace(" ", "_")[:50]
    
    # 转换
    if target_format == "pdf":
        url = doc_client.create_pdf_from_markdown(content, title)
    elif target_format == "docx":
        url = doc_client.create_docx_from_markdown(content, title)
    else:
        return f"不支持的目标格式: {target_format}"
    
    return f"文档已转换为 {target_format.upper()}：\\n{url}"


@tool
def proofread_document(text: str) -> str:
    """
    文档校对工具。检查并修正文本中的语法、拼写错误。
    
    参数:
        text: 待校对的文本
    
    返回:
        校对后的文本及修改建议
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content="你是一个专业的文字校对专家。请仔细检查文本中的语法错误、拼写错误、标点问题等，并给出修正后的版本。列出所有修改的地方及原因。"),
        HumanMessage(content=text)
    ]
    
    result = client.invoke(messages=messages, temperature=0.3)
    
    return f"校对结果：\\n\\n{_get_text_content(result.content)}"
