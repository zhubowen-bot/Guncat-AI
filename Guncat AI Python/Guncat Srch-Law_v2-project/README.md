# Guncat Srch-Law V2

国企法律智能分析 Agent 系统

## 版本

V2.0 - 2026年6月

## 功能概述

Guncat Srch-Law V2 是一款专为国有企业法律事务设计的智能分析系统，具备以下核心能力：

- **Multi-Agent 路由架构**：自动识别案件类型，路由到专用子Agent（合同解析/国企合规/刑事风险）
- **RAG 法律条文知识库**：基于 ChromaDB 的向量化法律条文检索，确保法条引用准确
- **联网实时检索**：支持搜索最新法律法规、司法解释和裁判案例
- **结构化法律意见书生成**：支持 Markdown / Word / PDF 三种输出格式
- **国企合规专项强化**：针对"三重一大"、国资监管、关联交易等国企特有场景专项优化

## 系统架构

```
用户输入
   ↓
RouterAgent（意图识别与分类）
   ↓
┌─────────┬─────────┬─────────┐
合同解析   国企合规    刑事风险
Agent     Agent     Agent
└─────────┴─────────┴─────────┘
   ↓
工具层：RAG检索 / 联网搜索 / 案例检索
   ↓
记忆与状态管理
   ↓
结构化法律意见书输出
```

## 快速开始

### 1. 安装依赖

```bash
pip install -r requirements.txt
```

主要依赖：
- `langchain` / `langchain-openai` - LLM 调用框架
- `langgraph` - Multi-Agent 编排
- `chromadb` - 向量数据库
- `sentence-transformers` - 中文文本向量化（bge-m3）
- `python-docx` - Word 文档生成
- `weasyprint` - PDF 生成（可选）

### 2. 配置 API 密钥

在 `config.py` 中配置，或通过环境变量传入：

```bash
export LLM_API_KEY="your-api-key"
export LLM_MODEL="gpt-4o"  # 或 claude-3-5-sonnet 等
export LLM_PROVIDER="openai"  # openai / anthropic / qwen
```

### 3. 初始化知识库

首次运行时会自动加载核心法律法规数据到向量数据库。

如需手动初始化：

```python
from knowledge_base.rag_engine import RAGEngine
engine = RAGEngine()
engine.initialize(force_reload=True)
```

### 4. 运行系统

#### 交互式模式

```bash
python main.py --mode interactive
```

#### 文件输入模式

```bash
python main.py --mode file --input case_description.txt --format markdown
```

## 使用示例

### 示例1：国企合规审查

```
案件描述：
某省属国企拟将其持有的子公司30%股权以协议方式转让给民营企业，
交易价格低于评估结果20%，且未履行进场交易程序。涉及金额5000万元。
```

系统将自动识别为"国企合规"类型，调用 ComplianceAgent 进行分析，输出包含：
- 国资监管程序合规性审查
- "三重一大"决策程序审查
- 关联交易审查
- 国有资产流失风险评估
- 管理人员履职责任分析

### 示例2：合同纠纷

```
案件描述：
股权转让合同中约定过渡期经营性盈利由受让方享有，
但双方对"经营性盈利"的定义产生争议。
```

系统将自动识别为"合同纠纷"类型，调用 ContractAgent 进行分析，输出包含：
- 合同体系化解释（五步法）
- 关键术语精细化辨析
- 法理深度分析
- 违约责任分析

## 模块说明

| 模块 | 路径 | 功能 |
|------|------|------|
| 主入口 | `main.py` | CLI交互、工作流编排 |
| 配置 | `config.py` | 所有可配置参数 |
| 路由Agent | `agents/router_agent.py` | 意图识别、案件分类 |
| 合同Agent | `agents/contract_agent.py` | 合同解析分析 |
| 合规Agent | `agents/compliance_agent.py` | 国企合规审查 |
| 刑事Agent | `agents/criminal_agent.py` | 刑事风险评估 |
| RAG引擎 | `knowledge_base/rag_engine.py` | 法条向量检索 |
| 向量库 | `knowledge_base/vector_store.py` | ChromaDB封装 |
| 联网检索 | `tools/web_search.py` | 实时搜索工具 |
| 输出格式化 | `output/formatter.py` | 法律意见书生成 |

## 优化亮点（针对V1.0问题反馈）

### 问题1：分析深度不够 → 解法

- **强化 System Prompt**：新增"法理分析工具箱"，强制运用整体对价理论、不当得利理论等深层法理工具
- **RAG 知识库**：检索真实法条后再分析，避免模型"幻觉"
- **五步合同解释法**：体系解释→目的解释→文义解释→历史解释→诚信解释，缺一不可

### 问题2：国企场景覆盖弱 → 解法

- **ComplianceAgent 专项强化**：针对"三重一大"、32号令、关联交易、国资流失等场景专项分析
- **国企合规专项输出章节**：输出中必须包含独立的"国企合规专项分析"章节
- **刑事责任全覆盖**：刑法第165-169条（国企相关犯罪）全部覆盖

## 扩展建议

### 1. 接入真实法律数据库API

当前 `tools/` 模块预留了接口，可接入：
- 北大法宝 API
- 裁判文书网
- 国家法律法规数据库

### 2. 增强 RAG 知识库

在 `knowledge_base/law_data_loader.py` 中加载更多法律法规全文：
- 建议加载至少 20 部核心法规的完整条文
- 定期更新（建议每季度）

### 3. 接入 LangGraph 编排

当前架构为简化版串行流程，可升级为 LangGraph 状态图：
- 支持 Agent 之间的条件跳转
- 支持并行调用多个子Agent
- 支持推理过程可追溯

### 4. 部署为 API 服务

可使用 FastAPI 封装，提供 HTTP API：

```python
# api.py（示例代码）
from fastapi import FastAPI
from main import GuncatSrchLawV2

app = FastAPI()
system = GuncatSrchLawV2()

@app.post("/analyze")
def analyze_case(case: dict):
    return system.analyze(case["description"], case.get("enterprise_type"))
```

## 测试

运行基础测试：

```bash
python tests/test_basic.py
```

## 注意事项

1. **LLM API 密钥**：Agent 分析需要配置有效的 LLM API 密钥
2. **联网检索**：当前默认使用 mock 模式，配置搜索 API 后可启用真实联网检索
3. **向量化模型**：首次运行会自动下载 bge-m3 模型（约 2GB），请耐心等待
4. **法条时效性**：系统会标注法条生效日期，但仍需人工核实是否为最新版本

## 许可证

MIT License

## 联系方式

如有问题或建议，欢迎反馈。
