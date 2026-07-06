"""
图片处理工具模块
提供智能图片处理能力，包括视觉理解、图文问答、文字提取、图片生成等
"""
from typing import List, Optional, Union
from langchain.tools import tool
from coze_coding_dev_sdk import ImageGenerationClient, LLMClient
from coze_coding_utils.runtime_ctx.context import new_context
from coze_coding_utils.log.write_log import request_context
from langchain_core.messages import HumanMessage, SystemMessage


def _get_ctx():
    """获取请求上下文"""
    return request_context.get() or new_context(method="image_tools")


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
def generate_image(
    prompt: str,
    size: str = "2K",
    image: Optional[str] = None
) -> str:
    """
    AI图片生成工具。根据文本描述生成高质量图片，或基于参考图片进行风格转换。
    
    参数:
        prompt: 图片生成的描述文本，描述你想要生成的图片内容
        size: 图片尺寸，支持 "2K"(2560x1440) 或 "4K"(4096x4096)
        image: 可选，参考图片URL，用于图生图模式
    
    返回:
        生成的图片URL列表
    """
    ctx = _get_ctx()
    client = ImageGenerationClient(ctx=ctx)
    
    response = client.generate(
        prompt=prompt,
        size=size,
        image=image
    )
    
    if response.success:
        urls = response.image_urls
        return f"成功生成 {len(urls)} 张图片:\\n" + "\\n".join([f"- {url}" for url in urls])
    else:
        return f"图片生成失败: {response.error_messages}"


@tool
def image_understanding(
    image_url: str,
    question: str = "描述这张图片的内容"
) -> str:
    """
    图片理解与问答工具。使用多模态大模型理解图片内容并回答相关问题。
    
    参数:
        image_url: 图片的URL地址
        question: 关于图片的问题，默认为描述图片内容
    
    返回:
        对图片内容的理解和回答
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content="你是一个专业的图片理解助手，请仔细分析图片内容并准确回答用户问题。"),
        HumanMessage(content=[
            {"type": "text", "text": question},
            {"type": "image_url", "image_url": {"url": image_url}}
        ])
    ]
    
    response = client.invoke(
        messages=messages,
        temperature=0.7
    )
    
    return _get_text_content(response.content)


@tool
def extract_text_from_image(image_url: str) -> str:
    """
    图片文字识别(OCR)工具。从图片中提取文字内容。
    
    参数:
        image_url: 包含文字的图片URL
    
    返回:
        图片中提取的文字内容
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content="你是一个OCR文字识别专家。请准确提取图片中的所有文字，保持原有格式和结构。"),
        HumanMessage(content=[
            {"type": "text", "text": "请提取这张图片中的所有文字内容，保持原有格式。"},
            {"type": "image_url", "image_url": {"url": image_url}}
        ])
    ]
    
    response = client.invoke(
        messages=messages,
        temperature=0.1
    )
    
    return _get_text_content(response.content)


@tool
def analyze_chart(image_url: str) -> str:
    """
    图表分析工具。分析图片中的图表、数据可视化内容，提取关键信息和趋势。
    
    参数:
        image_url: 包含图表的图片URL
    
    返回:
        图表分析结果，包括数据趋势、关键发现等
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content="你是一个专业的数据分析师。请分析图表内容，提取关键数据、趋势和洞察。"),
        HumanMessage(content=[
            {"type": "text", "text": "请详细分析这张图表，提取数据、识别趋势并给出关键洞察。"},
            {"type": "image_url", "image_url": {"url": image_url}}
        ])
    ]
    
    response = client.invoke(
        messages=messages,
        temperature=0.3
    )
    
    return _get_text_content(response.content)


@tool
def compare_images(image_urls: List[str], comparison_type: str = "general") -> str:
    """
    图片对比工具。比较两张或多张图片的异同，支持设计对比、差异分析等。
    
    参数:
        image_urls: 图片URL列表，至少2张图片
        comparison_type: 对比类型，可选 "general"(综合对比)、"design"(设计对比)、"content"(内容对比)
    
    返回:
        图片对比分析结果
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    if len(image_urls) < 2:
        return "请至少提供2张图片进行对比"
    
    content = [{"type": "text", "text": f"请对比这些{len(image_urls)}张图片，分析它们的异同点。"}]
    for url in image_urls:
        content.append({"type": "image_url", "image_url": {"url": url}})
    
    messages = [
        SystemMessage(content="你是一个专业的图片对比分析专家。"),
        HumanMessage(content=content)
    ]
    
    response = client.invoke(
        messages=messages,
        temperature=0.5
    )
    
    return _get_text_content(response.content)


@tool
def detect_objects(image_url: str) -> str:
    """
    目标检测工具。检测图片中的物体并返回位置信息。
    
    参数:
        image_url: 待检测的图片URL
    
    返回:
        检测到的物体列表及其位置信息
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    prompt = """请检测图片中的所有主要物体，并输出位置坐标。
使用相对坐标系统(0-1000)，格式如下：
{
  "objects": [
    {"name": "物体名称", "topLeftX": x_min, "topLeftY": y_min, "bottomRightX": x_max, "bottomRightY": y_max}
  ]
}"""
    
    messages = [
        SystemMessage(content="你是一个专业的目标检测助手。"),
        HumanMessage(content=[
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image_url}}
        ])
    ]
    
    response = client.invoke(
        messages=messages,
        temperature=0.1
    )
    
    return _get_text_content(response.content)


@tool
def remove_watermark(image_url: str, description: str = "") -> str:
    """
    图片去水印/擦除工具。移除图片中的不需要的元素（如水印、杂物等）。
    
    参数:
        image_url: 原始图片URL
        description: 需要移除的内容描述，如"移除右下角的水印"
    
    返回:
        处理后的图片URL
    """
    ctx = _get_ctx()
    client = ImageGenerationClient(ctx=ctx)
    
    prompt = f"移除图片中{description}的内容，保持图片自然无痕迹"
    
    response = client.generate(
        prompt=prompt,
        image=image_url,
        size="2K"
    )
    
    if response.success:
        return f"处理完成，已移除{description}，生成图片：\\n{response.image_urls[0]}"
    else:
        return f"处理失败: {response.error_messages}"


@tool
def enhance_image(image_url: str, enhancement_type: str = "quality") -> str:
    """
    图片增强工具。提升图片质量，包括超分辨率、去噪、色彩增强等。
    
    参数:
        image_url: 待增强的图片URL
        enhancement_type: 增强类型，可选 "quality"(画质提升)、"resolution"(分辨率提升)、"color"(色彩增强)
    
    返回:
        增强后的图片URL
    """
    ctx = _get_ctx()
    
    prompts = {
        "quality": "提升图片质量和清晰度，使画面更清晰细腻",
        "resolution": "提升图片分辨率和质量，使细节更清晰",
        "color": "增强图片的色彩和对比度，使颜色更鲜艳生动"
    }
    
    prompt = prompts.get(enhancement_type, "提升图片整体质量")
    
    client = ImageGenerationClient(ctx=ctx)
    
    response = client.generate(
        prompt=prompt,
        image=image_url,
        size="2K"
    )
    
    if response.success:
        return f"图片{enhancement_type}增强完成：\\n{response.image_urls[0]}"
    else:
        return f"增强失败: {response.error_messages}"


@tool
def style_transfer(image_url: str, style: str) -> str:
    """
    风格迁移工具。将图片转换为指定艺术风格。
    
    参数:
        image_url: 原图URL
        style: 目标风格描述，如"动漫风格"、"油画风格"、"水彩画风格"等
    
    返回:
        风格转换后的图片URL
    """
    ctx = _get_ctx()
    client = ImageGenerationClient(ctx=ctx)
    
    response = client.generate(
        prompt=f"将图片转换为{style}，保持原图主体内容",
        image=image_url,
        size="2K"
    )
    
    if response.success:
        return f"风格转换完成，已转换为{style}：\\n{response.image_urls[0]}"
    else:
        return f"风格转换失败: {response.error_messages}"
