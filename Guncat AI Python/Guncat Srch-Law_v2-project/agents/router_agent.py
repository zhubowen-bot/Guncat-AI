"""
RouterAgent - 意图识别与案件分类器
负责分析用户输入，将案件路由到合适的子Agent
"""

from typing import Dict, List, Any
from .base_agent import BaseAgent


class RouterAgent(BaseAgent):
    """
    路由Agent：识别案件类型，分发到专门的子Agent

    分类维度：
    1. 合同纠纷 - 涉及合同条款解释、违约责任、合同履行争议
    2. 国企合规 - 涉及国资监管、三重一大、关联交易、合规审查
    3. 刑事风险 - 涉及职务犯罪、贪污贿赂、国有资产流失犯罪
    4. 综合类 - 以上多类交织的复杂案件
    """

    ROUTER_SYSTEM_PROMPT = """你是Guncat Srch-Law V2的意图识别与案件分类器。

你的任务是对用户输入的案件描述进行精准分类，输出标准化路由指令。

## 分类标准

### 类型A：合同纠纷
关键词特征：
- 合同条款解释争议
- 违约责任认定
- 合同履行纠纷
- 股权转让合同、买卖合同、借款合同等具体合同类型
- 价格调整、利润分配、过渡期安排等合同机制

### 类型B：国企合规审查
关键词特征：
- 国资监管程序合规性（资产评估、进场交易、审批备案）
- "三重一大"决策程序
- 关联交易审查
- 国有资产交易合规性
- 央企/地方国企合规体系建设

### 类型C：刑事风险评估
关键词特征：
- 国企管理人员职务行为
- 贪污贿赂、滥用职权、失职渎职
- 国有资产流失
- 利益输送、关联交易犯罪
- 监察调查、刑事责任追究

### 类型D：综合类（A+B/C交织）
特征：同时涉及以上多种类型的复杂案件

## 输出格式

必须严格按以下JSON格式输出：
```json
{
  "case_type": "A|B|C|D",
  "confidence": 0.0-1.0,
  "keywords": ["关键词1", "关键词2"],
  "routing": {
    "primary_agent": "contract|compliance|criminal|comprehensive",
    "secondary_agents": ["可选：需要协同的其它Agent"],
    "reason": "路由理由说明"
  },
  "extracted_info": {
    "parties": ["涉及主体"],
    "enterprise_type": "央企|省属国企|市属国企|区属国企|不确定",
    "time_line": "时间线摘要",
    "key_facts": ["关键事实1", "关键事实2"]
  }
}
```

## 注意
- 如无法确定单一类型，选择"D（综合类）"
- confidence低于0.6时，必须在reason中说明不确定性
- 涉及国企的必须标注enterprise_type
"""

    def __init__(self):
        super().__init__(
            name="RouterAgent",
            system_prompt=self.ROUTER_SYSTEM_PROMPT
        )

    def analyze(self, case_info: Dict[str, Any]) -> Dict[str, Any]:
        """
        分析案件并输出路由决策

        Args:
            case_info: 包含用户案件描述的字典，必须有 'description' 字段

        Returns:
            路由决策字典，包含 case_type, routing, extracted_info 等
        """
        description = case_info.get("description", "")
        if not description:
            return {"error": "案件描述不能为空"}

        # 构建分析prompt
        prompt = f"""请对以下案件描述进行分类路由分析：

案件描述：
{description}

请严格按照JSON格式输出路由结果。"""

        # 调用LLM
        response = self._call_llm(prompt)

        # 解析JSON响应（处理可能的markdown代码块包装）
        import json
        import re

        # 尝试提取JSON
        json_match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
            json_str = response.strip()

        try:
            result = json.loads(json_str)
            # 添加原始响应
            result["_raw_response"] = response
            return result
        except json.JSONDecodeError:
            # 解析失败，返回原始响应
            return {
                "error": "路由解析失败",
                "case_type": "D",  # 默认综合类
                "routing": {
                    "primary_agent": "comprehensive",
                    "reason": "路由解析失败，默认使用综合分析"
                },
                "_raw_response": response
            }

    def route(self, case_info: Dict[str, Any]) -> str:
        """
        简化路由接口，直接返回目标Agent名称

        Returns:
            目标Agent名称: 'contract' | 'compliance' | 'criminal' | 'comprehensive'
        """
        result = self.analyze(case_info)
        return result.get("routing", {}).get("primary_agent", "comprehensive")
