"""
搜索与生活服务工具模块
提供联网搜索、天气查询、信息检索等能力
"""
from typing import Optional, List
from langchain.tools import tool
from coze_coding_dev_sdk import SearchClient, LLMClient
from coze_coding_utils.runtime_ctx.context import new_context
from coze_coding_utils.log.write_log import request_context
from langchain_core.messages import HumanMessage, SystemMessage


def _get_ctx():
    """获取请求上下文"""
    return request_context.get() or new_context(method="search_tools")


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
def web_search(query: str, count: int = 10) -> str:
    """
    联网搜索工具。使用搜索引擎检索信息。
    
    参数:
        query: 搜索关键词
        count: 返回结果数量，默认10条
    
    返回:
        搜索结果列表
    """
    ctx = _get_ctx()
    client = SearchClient(ctx=ctx)
    
    response = client.web_search(query=query, count=count)
    
    if not response.web_items:
        return f"未找到与「{query}」相关的搜索结果"
    
    results = []
    for i, item in enumerate(response.web_items, 1):
        results.append(f"{i}. {item.title}\\n   来源: {item.site_name}\\n   链接: {item.url}\\n   摘要: {item.snippet[:150]}...")
    
    return f"搜索「{query}」找到 {len(response.web_items)} 条结果：\\n\\n" + "\\n\\n".join(results)


@tool
def web_search_with_ai_summary(query: str, count: int = 5) -> str:
    """
    智能搜索工具。搜索并使用AI生成摘要。
    
    参数:
        query: 搜索关键词
        count: 返回结果数量，默认5条
    
    返回:
        搜索结果及AI摘要
    """
    ctx = _get_ctx()
    client = SearchClient(ctx=ctx)
    
    response = client.web_search_with_summary(query=query, count=count)
    
    result = f"## 搜索「{query}」\\n\\n"
    
    if response.summary:
        result += f"### AI摘要\\n{response.summary}\\n\\n"
    
    if response.web_items:
        result += f"### 搜索结果 ({len(response.web_items)}条)\\n\\n"
        for i, item in enumerate(response.web_items, 1):
            result += f"{i}. **{item.title}**\\n   来源: {item.site_name}\\n   链接: {item.url}\\n"
            if item.summary:
                result += f"   摘要: {item.summary}\\n"
            result += "\\n"
    
    return result


@tool
def image_search(query: str, count: int = 10) -> str:
    """
    图片搜索工具。搜索相关图片。
    
    参数:
        query: 搜索关键词
        count: 返回结果数量，默认10张
    
    返回:
        图片结果列表
    """
    ctx = _get_ctx()
    client = SearchClient(ctx=ctx)
    
    response = client.image_search(query=query, count=count)
    
    if not response.image_items:
        return f"未找到与「{query}」相关的图片"
    
    results = []
    for i, item in enumerate(response.image_items, 1):
        results.append(f"{i}. {item.title or '无标题'}\\n   来源: {item.site_name}\\n   图片: {item.image.url}\\n   尺寸: {item.image.width}x{item.image.height}")
    
    return f"图片搜索「{query}」找到 {len(response.image_items)} 张图片：\\n\\n" + "\\n\\n".join(results)


@tool
def search_news(query: str, time_range: str = "1w") -> str:
    """
    新闻搜索工具。搜索最新新闻。
    
    参数:
        query: 搜索关键词
        time_range: 时间范围，支持 "1d"(一天), "1w"(一周), "1m"(一月)
    
    返回:
        新闻搜索结果
    """
    ctx = _get_ctx()
    client = SearchClient(ctx=ctx)
    
    response = client.search(
        query=query,
        search_type="web",
        count=10,
        time_range=time_range,
        need_summary=True
    )
    
    if not response.web_items:
        return f"未找到「{query}」相关的新闻"
    
    results = [f"## 「{query}」最新新闻\\n"]
    
    for i, item in enumerate(response.web_items, 1):
        results.append(f"### {i}. {item.title}")
        results.append(f"来源: {item.site_name} | 时间: {item.publish_time or '未知'}")
        results.append(f"链接: {item.url}")
        if item.summary:
            results.append(f"摘要: {item.summary}")
        results.append("")
    
    return "\\n".join(results)


@tool
def academic_search(query: str) -> str:
    """
    学术搜索工具。搜索学术资料和研究论文。
    
    参数:
        query: 搜索关键词
    
    返回:
        学术资料搜索结果
    """
    ctx = _get_ctx()
    client = SearchClient(ctx=ctx)
    
    response = client.search(
        query=f"{query} 学术 论文 研究",
        count=10,
        need_content=True,
        need_summary=True
    )
    
    if not response.web_items:
        return f"未找到「{query}」相关的学术资料"
    
    results = [f"## 学术搜索「{query}」\\n\\n"]
    
    for i, item in enumerate(response.web_items, 1):
        results.append(f"{i}. **{item.title}**")
        results.append(f"来源: {item.site_name}")
        results.append(f"链接: {item.url}")
        if item.auth_info_des:
            results.append(f"权威性: {item.auth_info_des}")
        if item.summary:
            results.append(f"摘要: {item.summary}")
        results.append("")
    
    return "\\n".join(results)


@tool
def verify_information(query: str) -> str:
    """
    信息验证工具。验证信息真实性。
    
    参数:
        query: 需要验证的信息或说法
    
    返回:
        信息验证结果
    """
    ctx = _get_ctx()
    search_client = SearchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    # 先搜索相关信息
    response = search_client.search(
        query=query,
        count=10,
        need_summary=True
    )
    
    # 使用LLM分析
    if response.web_items:
        context = "\\n".join([
            f"- {item.title}: {item.summary or item.snippet}"
            for item in response.web_items[:5]
        ])
        
        messages = [
            SystemMessage(content="你是一个专业的事实核查专家。请根据搜索到的资料验证以下信息的真实性，给出客观评估。"),
            HumanMessage(content=f"待验证信息: {query}\\n\\n相关搜索结果:\\n{context}")
        ]
        
        result = llm_client.invoke(messages=messages, temperature=0.3)
        
        return f"### 信息验证\\n\\n**待验证信息**: {query}\\n\\n**验证结果**:\\n{_get_text_content(result.content)}"
    else:
        return f"**待验证信息**: {query}\\n\\n未找到相关资料，建议谨慎对待该信息。"


@tool
def get_knowledge_answer(question: str) -> str:
    """
    百科问答工具。回答各类知识性问题。
    
    参数:
        question: 知识性问题
    
    返回:
        问题解答
    """
    ctx = _get_ctx()
    search_client = SearchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    # 搜索相关信息
    response = search_client.web_search_with_summary(query=question, count=5)
    
    # 综合回答
    if response.web_items or response.summary:
        context = response.summary + "\\n\\n" if response.summary else ""
        context += "\\n".join([
            f"- {item.title}: {item.snippet[:200]}"
            for item in response.web_items[:3]
        ])
        
        messages = [
            SystemMessage(content="你是一个知识渊博的专家。请结合搜索到的资料回答用户问题，给出准确、全面的解答。"),
            HumanMessage(content=f"问题: {question}\\n\\n参考资料:\\n{context[:3000]}")
        ]
        
        result = llm_client.invoke(messages=messages, temperature=0.5)
        
        return f"### {question}\\n\\n{_get_text_content(result.content)}"
    else:
        # 直接回答简单问题
        messages = [
            SystemMessage(content="你是一个知识渊博的专家。请直接回答用户的问题。"),
            HumanMessage(content=question)
        ]
        
        result = llm_client.invoke(messages=messages, temperature=0.5)
        
        return f"### {question}\\n\\n{_get_text_content(result.content)}"


@tool
def compare_products(product_names: List[str], criteria: str = "主要特点和优缺点") -> str:
    """
    产品对比工具。对比多个产品的信息。
    
    参数:
        product_names: 产品名称列表
        criteria: 对比维度，如 "价格、性能、用户体验"
    
    返回:
        产品对比分析
    """
    if len(product_names) < 2:
        return "请至少提供2个产品进行对比"
    
    ctx = _get_ctx()
    search_client = SearchClient(ctx=ctx)
    llm_client = LLMClient(ctx=ctx)
    
    # 搜索每个产品
    product_info = []
    for name in product_names:
        response = search_client.web_search_with_summary(query=f"{name} 产品评测", count=3)
        info = f"### {name}\\n"
        if response.summary:
            info += response.summary + "\\n"
        for item in response.web_items[:2]:
            info += f"- {item.title}: {item.snippet[:100]}\\n"
        product_info.append(info)
    
    # 综合对比
    combined = "\\n\\n".join(product_info)
    
    messages = [
        SystemMessage(content=f"你是一个专业的产品对比分析师。请对比以下产品，从{criteria}等维度进行分析。"),
        HumanMessage(content=combined)
    ]
    
    result = llm_client.invoke(messages=messages, temperature=0.5)
    
    return f"## 产品对比分析\\n\\n{_get_text_content(result.content)}"


@tool
def get_trending_topics(category: str = "technology", count: int = 10) -> str:
    """
    热门话题工具。获取各领域的热门话题。
    
    参数:
        category: 领域类别，支持 "technology", "entertainment", "sports", "business", "health"
        count: 返回数量，默认10条
    
    返回:
        热门话题列表
    """
    ctx = _get_ctx()
    client = SearchClient(ctx=ctx)
    
    categories = {
        "technology": "科技 热点",
        "entertainment": "娱乐 热点",
        "sports": "体育 热点",
        "business": "商业 财经 热点",
        "health": "健康 医疗 热点"
    }
    
    query = categories.get(category, "热点新闻")
    
    response = client.web_search(query=query, count=count)
    
    if not response.web_items:
        return f"未找到{category}领域的热门话题"
    
    topics = [f"## {category.capitalize()} 热门话题\\n"]
    
    for i, item in enumerate(response.web_items, 1):
        topics.append(f"{i}. **{item.title}**")
        topics.append(f"   {item.snippet[:100]}...")
        topics.append(f"   来源: {item.site_name} | {item.publish_time or ''}\\n")
    
    return "\\n".join(topics)
