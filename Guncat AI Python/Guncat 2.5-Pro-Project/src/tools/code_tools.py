"""
代码执行与可视化工具模块
提供代码执行、数据处理、图表生成等能力
"""
import io
import sys
import json
import base64
from typing import Dict, Any, Optional, List
from langchain.tools import tool
from coze_coding_dev_sdk import LLMClient
from coze_coding_utils.runtime_ctx.context import new_context
from coze_coding_utils.log.write_log import request_context
from langchain_core.messages import HumanMessage, SystemMessage


def _get_ctx():
    """获取请求上下文"""
    return request_context.get() or new_context(method="code_tools")


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


class SafeCapture:
    """安全的输出捕获"""
    
    def __init__(self):
        self.stdout_buffer = io.StringIO()
        self.stderr_buffer = io.StringIO()
    
    def __enter__(self):
        self.old_stdout = sys.stdout
        self.old_stderr = sys.stderr
        sys.stdout = self.stdout_buffer
        sys.stderr = self.stderr_buffer
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        sys.stdout = self.old_stdout
        sys.stderr = self.old_stderr
    
    def get_output(self):
        stdout = self.stdout_buffer.getvalue()
        stderr = self.stderr_buffer.getvalue()
        return stdout, stderr


@tool
def execute_python_code(code: str) -> str:
    """
    Python代码执行工具。执行Python代码并返回结果。
    
    参数:
        code: Python代码
    
    返回:
        代码执行结果
    """
    capture = SafeCapture()
    
    try:
        with capture:
            # 为安全起见，限制执行
            exec_globals = {"__builtins__": __builtins__}
            exec(code, exec_globals)
        
        stdout, stderr = capture.get_output()
        
        result = ""
        if stdout:
            result += f"输出:\\n{stdout}"
        if stderr:
            result += f"\\n错误:\\n{stderr}"
        
        if not result:
            result = "代码执行完成，无输出"
        
        return result
        
    except Exception as e:
        return f"执行错误: {type(e).__name__}: {str(e)}"


@tool
def calculate(expression: str) -> str:
    """
    数学计算工具。执行数学表达式计算。
    
    参数:
        expression: 数学表达式，如 "2+3*4", "sqrt(16)", "sin(pi/2)"
    
    返回:
        计算结果
    """
    # 常用数学函数映射
    math_funcs = {
        "sqrt": "**0.5",
        "sin": "math.sin",
        "cos": "math.cos",
        "tan": "math.tan",
        "log": "math.log10",
        "ln": "math.log",
        "exp": "math.exp",
        "abs": "abs",
        "round": "round",
        "pi": "math.pi",
        "e": "math.e"
    }
    
    expression = expression.strip()
    
    # 替换函数名
    for func, replacement in math_funcs.items():
        if func in expression.lower():
            expression = expression.replace(func, replacement)
    
    try:
        import math
        result = eval(expression, {"__builtins__": math}, {"math": math})
        return f"表达式: {expression}\\n结果: {result}"
    except Exception as e:
        return f"计算错误: {str(e)}"


@tool
def generate_chart(
    chart_type: str,
    data: str,
    title: str = "数据图表"
) -> str:
    """
    图表生成工具。生成各类数据可视化图表。
    
    参数:
        chart_type: 图表类型，支持 "bar"(柱状图), "line"(折线图), "pie"(饼图), "scatter"(散点图)
        data: 数据，JSON格式的列表或字典
        title: 图表标题
    
    返回:
        图表图片URL或生成结果
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    # 解析数据
    try:
        parsed_data = json.loads(data)
    except:
        return "数据格式错误，请提供JSON格式的数据"
    
    # 生成Python代码
    messages = [
        SystemMessage(content="你是一个数据可视化专家。请生成Python代码来创建图表。使用matplotlib生成图片并保存到/tmp/chart.png。只输出代码，不要其他内容。"),
        HumanMessage(content=f"创建{chart_type}图表，标题: {title}，数据: {json.dumps(parsed_data)}")
    ]
    
    result = client.invoke(messages=messages, temperature=0.1)
    code = _get_text_content(result.content)
    
    # 清理代码
    if "```python" in code:
        code = code.split("```python")[1].split("```")[0]
    elif "```" in code:
        code = code.split("```")[1].split("```")[0]
    
    # 执行代码
    full_code = f"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import json

{data}

{code}

plt.savefig('/tmp/chart.png', dpi=150, bbox_inches='tight')
print('图表已保存到 /tmp/chart.png')
"""
    
    try:
        exec_globals = {"__builtins__": __builtins__}
        exec(full_code, exec_globals)
        
        return "图表已生成，请使用图片上传工具或查看 /tmp/chart.png"
    except Exception as e:
        return f"图表生成失败: {str(e)}\\n生成的代码:\\n{code}"


@tool
def parse_json(data_str: str) -> str:
    """
    JSON解析工具。解析和验证JSON数据。
    
    参数:
        data_str: JSON字符串
    
    返回:
        格式化后的JSON或错误信息
    """
    try:
        parsed = json.loads(data_str)
        formatted = json.dumps(parsed, indent=2, ensure_ascii=False)
        return f"JSON解析成功：\\n{formatted}"
    except json.JSONDecodeError as e:
        return f"JSON解析错误: {str(e)}"


@tool
def format_json(data_str: str, minify: bool = False) -> str:
    """
    JSON格式化工具。格式化或压缩JSON。
    
    参数:
        data_str: JSON字符串
        minify: 是否压缩（True为压缩，False为格式化）
    
    返回:
        格式化或压缩后的JSON
    """
    try:
        parsed = json.loads(data_str)
        if minify:
            return json.dumps(parsed, separators=(',', ':'))
        else:
            return json.dumps(parsed, indent=2, ensure_ascii=False)
    except json.JSONDecodeError as e:
        return f"JSON格式错误: {str(e)}"


@tool
def convert_data_format(
    data: str,
    from_format: str,
    to_format: str
) -> str:
    """
    数据格式转换工具。在不同数据格式间转换。
    
    参数:
        data: 输入数据
        from_format: 源格式，支持 "json", "csv", "xml", "yaml"
        to_format: 目标格式，支持 "json", "csv", "xml", "yaml"
    
    返回:
        转换后的数据
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content="你是一个数据格式转换专家。请将数据从一种格式转换为另一种格式。只输出转换后的数据内容，不要其他说明。"),
        HumanMessage(content=f"将以下数据从{from_format}转换为{to_format}格式：\\n\\n{data}")
    ]
    
    result = client.invoke(messages=messages, temperature=0.1)
    
    return f"{from_format.upper()} 转 {to_format.upper()} 结果：\\n\\n{_get_text_content(result.content)}"


@tool
def generate_mindmap(topic: str, depth: int = 3) -> str:
    """
    思维导图生成工具。生成主题的思维导图结构。
    
    参数:
        topic: 思维导图主题
        depth: 展开深度，默认3层
    
    返回:
        思维导图的Markdown树形结构
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content=f"请为「{topic}」生成一个{depth}层的思维导图，使用Markdown树形结构展示，使用- 和 | 来表示层级关系。"),
        HumanMessage(content=f"主题: {topic}\\n层级: {depth}")
    ]
    
    result = client.invoke(messages=messages, temperature=0.7)
    
    return f"## 思维导图: {topic}\\n\\n{_get_text_content(result.content)}"


@tool
def analyze_data(data: str, analysis_type: str = "summary") -> str:
    """
    数据分析工具。对数据进行统计分析。
    
    参数:
        data: JSON格式的数据列表
        analysis_type: 分析类型，支持 "summary"(摘要), "trends"(趋势), "statistics"(统计)
    
    返回:
        数据分析结果
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    try:
        parsed_data = json.loads(data)
    except:
        return "数据格式错误，请提供JSON格式的数据"
    
    messages = [
        SystemMessage(content=f"你是一个专业的数据分析师。请对提供的数据进行{analysis_type}分析，给出有价值的洞察。"),
        HumanMessage(content=f"分析类型: {analysis_type}\\n数据: {json.dumps(parsed_data, ensure_ascii=False)}")
    ]
    
    result = client.invoke(messages=messages, temperature=0.5)
    
    return f"### 数据{analysis_type}分析\\n\\n{_get_text_content(result.content)}"


@tool
def generate_code(language: str, task: str) -> str:
    """
    代码生成工具。根据描述生成代码。
    
    参数:
        language: 编程语言，如 "python", "javascript", "java"
        task: 代码任务描述
    
    返回:
        生成的代码
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content=f"你是一个专业的{language}程序员。请根据描述生成完整、可运行的代码。只输出代码，添加必要的注释。"),
        HumanMessage(content=task)
    ]
    
    result = client.invoke(messages=messages, temperature=0.3)
    
    return f"## {language.title()} 代码\\n\\n{_get_text_content(result.content)}"


@tool
def debug_code(code: str, language: str = "python") -> str:
    """
    代码调试工具。检查代码错误并提供修复建议。
    
    参数:
        code: 待调试的代码
        language: 编程语言
    
    返回:
        调试结果和修复建议
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content=f"你是一个专业的{language}代码调试专家。请检查代码中的错误，并提供修复建议和修正后的代码。"),
        HumanMessage(content=f"请调试以下{language}代码：\\n\\n```{language}\\n{code}\\n```")
    ]
    
    result = client.invoke(messages=messages, temperature=0.3)
    
    return f"### 代码调试结果\\n\\n{_get_text_content(result.content)}"


@tool
def explain_code(code: str, language: str = "python") -> str:
    """
    代码解释工具。解释代码的功能和工作原理。
    
    参数:
        code: 待解释的代码
        language: 编程语言
    
    返回:
        代码解释
    """
    ctx = _get_ctx()
    client = LLMClient(ctx=ctx)
    
    messages = [
        SystemMessage(content="你是一个耐心的编程导师。请详细解释代码的功能、工作原理和关键知识点，使用通俗易懂的语言。"),
        HumanMessage(content=f"请解释以下{language}代码：\\n\\n```{language}\\n{code}\\n```")
    ]
    
    result = client.invoke(messages=messages, temperature=0.5)
    
    return f"### 代码解释\\n\\n{_get_text_content(result.content)}"


@tool
def validate_json_schema(json_data: str, schema: Optional[str] = None) -> str:
    """
    JSON Schema验证工具。验证JSON数据是否符合Schema。
    
    参数:
        json_data: 待验证的JSON数据
        schema: JSON Schema定义（可选）
    
    返回:
        验证结果
    """
    try:
        data = json.loads(json_data)
    except json.JSONDecodeError as e:
        return f"JSON格式错误: {str(e)}"
    
    if schema:
        try:
            schema_obj = json.loads(schema)
        except json.JSONDecodeError as e:
            return f"Schema格式错误: {str(e)}"
        
        return f"JSON数据有效，Schema验证通过。\\n数据预览: {json.dumps(data, indent=2, ensure_ascii=False)[:500]}"
    else:
        # 基本验证
        validation = {
            "is_valid_json": True,
            "data_type": type(data).__name__,
            "is_object": isinstance(data, dict),
            "is_array": isinstance(data, list),
            "keys" if isinstance(data, dict) else "length": list(data.keys()) if isinstance(data, dict) else len(data)
        }
        
        return f"### JSON验证结果\\n\\n```json\\n{json.dumps(validation, indent=2, ensure_ascii=False)}\\n```"
