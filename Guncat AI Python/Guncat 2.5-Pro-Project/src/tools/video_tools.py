"""
视频处理工具模块
提供智能视频处理能力，包括视频生成、剪辑、抽帧、音频提取等
"""
from typing import List, Optional
from langchain.tools import tool
from coze_coding_dev_sdk.video import VideoGenerationClient, TextContent, ImageURLContent, ImageURL
from coze_coding_dev_sdk.video_edit import (
    FrameExtractorClient, 
    VideoEditClient, 
    SubtitleConfig, 
    FontPosConfig, 
    TextItem
)
from coze_coding_dev_sdk import LLMClient
from coze_coding_utils.runtime_ctx.context import new_context
from coze_coding_utils.log.write_log import request_context
from langchain_core.messages import HumanMessage, SystemMessage


def _get_ctx():
    """获取请求上下文"""
    return request_context.get() or new_context(method="video_tools")


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
def generate_video(
    prompt: str,
    resolution: str = "720p",
    ratio: str = "16:9",
    duration: int = 5,
    first_frame: Optional[str] = None,
    last_frame: Optional[str] = None
) -> str:
    """
    AI视频生成工具。根据文本描述生成视频，或基于首尾帧生成连续视频。
    
    参数:
        prompt: 视频内容描述文本
        resolution: 视频分辨率，支持 "480p", "720p", "1080p"
        ratio: 视频比例，支持 "16:9"(横屏), "9:16"(竖屏), "1:1"(方形)
        duration: 视频时长(秒)，支持4-12秒
        first_frame: 可选，首帧图片URL
        last_frame: 可选，尾帧图片URL
    
    返回:
        生成的视频URL
    """
    ctx = _get_ctx()
    client = VideoGenerationClient(ctx=ctx)
    
    content_items = [TextContent(text=prompt)]
    
    if first_frame:
        content_items.insert(0, ImageURLContent(
            image_url=ImageURL(url=first_frame),
            role="first_frame"
        ))
    
    if last_frame:
        content_items.append(ImageURLContent(
            image_url=ImageURL(url=last_frame),
            role="last_frame"
        ))
    
    video_url, response, _ = client.video_generation(
        content_items=content_items,
        resolution=resolution,
        ratio=ratio,
        duration=duration,
        watermark=False
    )
    
    if video_url:
        return f"视频生成成功！\\nURL: {video_url}\\n分辨率: {resolution}\\n时长: {duration}秒"
    else:
        return f"视频生成失败: {response.get('error', '未知错误')}"


@tool
def trim_video(
    video_url: str,
    start_time: float = 0,
    end_time: Optional[float] = None
) -> str:
    """
    视频裁剪工具。截取视频的指定片段。
    
    参数:
        video_url: 原始视频URL
        start_time: 开始时间(秒)
        end_time: 结束时间(秒)，None表示到视频结尾
    
    返回:
        裁剪后的视频URL
    """
    ctx = _get_ctx()
    client = VideoEditClient(ctx=ctx)
    
    response = client.video_trim(
        video=video_url,
        start_time=start_time,
        end_time=end_time
    )
    
    if response.url:
        return f"视频裁剪完成！\\n起始: {start_time}秒\\n结束: {end_time or '视频结尾'}秒\\n结果: {response.url}"
    else:
        return "视频裁剪失败"


@tool
def concat_videos(
    video_urls: List[str],
    transitions: Optional[List[str]] = None
) -> str:
    """
    视频拼接工具。将多个视频片段合并成一个。
    
    参数:
        video_urls: 视频URL列表，按拼接顺序排列
        transitions: 可选，转场效果ID列表
            - "1182356": 百叶窗
            - "1182376": 圆形打开
            - "1182355": 叶片翻转
            - "1182360": 旋转放大
    
    返回:
        拼接后的视频URL
    """
    ctx = _get_ctx()
    client = VideoEditClient(ctx=ctx)
    
    response = client.concat_videos(
        videos=video_urls,
        transitions=transitions
    )
    
    if response.url:
        return f"视频拼接完成！\\n共拼接 {len(video_urls)} 个片段\\n结果: {response.url}"
    else:
        return "视频拼接失败"


@tool
def extract_key_frames(video_url: str) -> str:
    """
    关键帧提取工具。提取视频中的关键帧。
    
    参数:
        video_url: 视频URL
    
    返回:
        关键帧图片URL列表
    """
    ctx = _get_ctx()
    client = FrameExtractorClient(ctx=ctx)
    
    response = client.extract_by_key_frame(url=video_url)
    
    if response.data and response.data.chunks:
        frames = []
        for chunk in response.data.chunks:
            frames.append(f"- 第{chunk.index}帧: {chunk.screenshot} (时间戳: {chunk.timestamp_ms}ms)")
        return f"提取到 {len(frames)} 个关键帧：\\n" + "\\n".join(frames)
    else:
        return "未能提取到关键帧"


@tool
def extract_frames_by_interval(video_url: str, interval_seconds: float = 5) -> str:
    """
    定时帧提取工具。按固定时间间隔提取视频帧。
    
    参数:
        video_url: 视频URL
        interval_seconds: 间隔秒数，默认5秒
    
    返回:
        提取的帧图片URL列表
    """
    ctx = _get_ctx()
    client = FrameExtractorClient(ctx=ctx)
    
    interval_ms = int(interval_seconds * 1000)
    response = client.extract_by_interval(url=video_url, interval_ms=interval_ms)
    
    if response.data and response.data.chunks:
        frames = []
        for chunk in response.data.chunks:
            frames.append(f"- {chunk.screenshot} (时间戳: {chunk.timestamp_ms}ms)")
        return f"提取到 {len(frames)} 帧（每{interval_seconds}秒一帧）：\\n" + "\\n".join(frames)
    else:
        return "未能提取到帧"


@tool
def extract_audio(video_url: str, format: str = "mp3") -> str:
    """
    音频提取工具。从视频中提取音频轨道。
    
    参数:
        video_url: 视频URL
        format: 音频格式，支持 "mp3", "m4a"
    
    返回:
        提取的音频URL
    """
    ctx = _get_ctx()
    client = VideoEditClient(ctx=ctx)
    
    response = client.extract_audio(video=video_url, format=format)
    
    if response.url:
        return f"音频提取成功！\\n格式: {format}\\n时长: {response.video_meta.duration}秒\\n结果: {response.url}"
    else:
        return "音频提取失败"


@tool
def add_subtitles(
    video_url: str,
    subtitle_texts: List[dict],
    font_size: int = 36
) -> str:
    """
    字幕添加工具。为视频添加字幕。
    
    参数:
        video_url: 视频URL
        subtitle_texts: 字幕文本列表，格式为 [{"start": 0.0, "end": 5.0, "text": "字幕内容"}, ...]
        font_size: 字体大小，默认36
    
    返回:
        带有字幕的视频URL
    """
    ctx = _get_ctx()
    client = VideoEditClient(ctx=ctx)
    
    subtitle_config = SubtitleConfig(
        font_pos_config=FontPosConfig(
            pos_x="0",
            pos_y="90%",
            width="100%",
            height="10%"
        ),
        font_size=font_size,
        font_color="#FFFFFFFF",
        font_type="1525745",
        background_color="#00000000",
        border_width=1,
        border_color="#00000088"
    )
    
    text_list = [
        TextItem(start_time=item["start"], end_time=item["end"], text=item["text"])
        for item in subtitle_texts
    ]
    
    response = client.add_subtitles(
        video=video_url,
        subtitle_config=subtitle_config,
        text_list=text_list
    )
    
    if response.url:
        return f"字幕添加成功！\\n共添加 {len(subtitle_texts)} 条字幕\\n结果: {response.url}"
    else:
        return "字幕添加失败"


@tool
def auto_subtitle(video_url: str) -> str:
    """
    自动字幕生成工具。将视频中的语音自动转换为字幕。
    
    参数:
        video_url: 视频URL
    
    返回:
        字幕文件URL或带字幕视频URL
    """
    ctx = _get_ctx()
    client = VideoEditClient(ctx=ctx)
    
    # 首先将音频转换为字幕
    subtitle_response = client.audio_to_subtitle(source=video_url, subtitle_type="srt")
    
    if not subtitle_response.url:
        return "语音识别失败"
    
    # 然后添加到视频
    subtitle_config = SubtitleConfig(
        font_pos_config=FontPosConfig(
            pos_x="0",
            pos_y="90%",
            width="100%",
            height="10%"
        ),
        font_size=36,
        font_color="#FFFFFFFF",
        font_type="1525745",
        background_color="#00000000",
        border_width=1,
        border_color="#00000088"
    )
    
    video_response = client.add_subtitles(
        video=video_url,
        subtitle_config=subtitle_config,
        subtitle_url=subtitle_response.url
    )
    
    if video_response.url:
        return f"自动字幕生成成功！\\n字幕文件: {subtitle_response.url}\\n带字幕视频: {video_response.url}"
    else:
        return f"字幕文件已生成: {subtitle_response.url}\\n但添加到视频失败"


@tool
def analyze_video(video_url: str, question: str = "分析这个视频的主要内容") -> str:
    """
    视频理解与分析工具。使用多模态大模型理解视频内容。
    
    参数:
        video_url: 视频URL
        question: 关于视频的问题，默认为分析主要内容
    
    返回:
        视频分析结果
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content="你是一个专业的视频内容分析专家。请仔细观看视频并准确回答问题。"),
        HumanMessage(content=[
            {"type": "text", "text": question},
            {"type": "video_url", "video_url": {"url": video_url}}
        ])
    ]
    
    response = client.invoke(
        messages=messages,
        temperature=0.7
    )
    
    return _get_text_content(response.content)


@tool
def extract_video_frames_count(video_url: str, count: int = 10) -> str:
    """
    均匀抽帧工具。从视频中均匀提取指定数量的帧。
    
    参数:
        video_url: 视频URL
        count: 抽帧数量，默认10帧
    
    返回:
        提取的帧图片URL列表
    """
    ctx = _get_ctx()
    client = FrameExtractorClient(ctx=ctx)
    
    response = client.extract_by_count(url=video_url, count=count)
    
    if response.data and response.data.chunks:
        frames = []
        for chunk in response.data.chunks:
            frames.append(f"- 帧{chunk.index}: {chunk.screenshot}")
        return f"均匀提取 {len(frames)} 帧：\\n" + "\\n".join(frames)
    else:
        return "抽帧失败"


@tool
def combine_video_audio(
    video_url: str,
    audio_url: str,
    keep_original_audio: bool = False
) -> str:
    """
    音视频合成工具。将音频与视频合并。
    
    参数:
        video_url: 视频URL
        audio_url: 音频URL
        keep_original_audio: 是否保留原视频音频，默认False（替换）
    
    返回:
        合成后的视频URL
    """
    ctx = _get_ctx()
    client = VideoEditClient(ctx=ctx)
    
    response = client.compile_video_audio(
        video=video_url,
        audio=audio_url,
        is_audio_reserve=keep_original_audio
    )
    
    if response.url:
        mode = "保留原音频混合" if keep_original_audio else "替换音频"
        return f"音视频合成成功！\\n模式: {mode}\\n结果: {response.url}"
    else:
        return "音视频合成失败"
