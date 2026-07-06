# Guncat 2.5-Pro - LangChain / LangGraph 智能体

基于 **LangChain / LangGraph** 生态，Python 代码驱动，搭载 **doubao-seed-2.0-Pro**，国际第一梯队水平。

---

## 项目结构

```
Guncat 2.5-Pro-Project/
├── assets/                    # 静态资源（头像等）
├── config/                    # 配置文件
│   └── agent_llm_config.json  # Agent配置（模型、工具、系统提示）
├── scripts/                   # 运行脚本
│   ├── http_run.sh            # HTTP服务启动
│   ├── load_env.py            # 环境变量加载（Python）
│   ├── load_env.sh            # 环境变量加载（Shell）
│   ├── local_run.sh           # 本地运行
│   ├── pack.sh                # 打包脚本
│   └── setup.sh               # 安装脚本
├── src/                       # 源代码
│   ├── agents/                # Agent实现
│   │   ├── __init__.py
│   │   └── agent.py
│   ├── graphs/                # LangGraph工作流
│   │   ├── nodes/             # 自定义节点
│   │   └── __init__.py
│   ├── storage/               # 存储层
│   │   ├── database/          # 数据库（PostgreSQL）
│   │   ├── memory/            # 记忆存储
│   │   ├── s3/                # S3存储
│   │   └── __init__.py
│   ├── tools/                 # 工具集（60+工具）
│   │   ├── code_tools.py      # 代码执行工具
│   │   ├── document_tools.py  # 文档处理工具
│   │   ├── image_tools.py     # 图片处理工具
│   │   ├── search_tools.py    # 搜索工具
│   │   ├── video_tools.py     # 视频处理工具
│   │   ├── web_tools.py       # 网页工具
│   │   └── __init__.py
│   ├── utils/                 # 工具函数
│   │   ├── file/              # 文件操作工具
│   │   └── __init__.py
│   ├── __init__.py
│   └── main.py                # 入口文件（FastAPI服务）
├── .coze                      # Coze平台配置
├── .gitignore
├── pyproject.toml             # 依赖配置（使用uv管理）
├── uv.lock                    # 依赖锁定文件
└── README.md
```

---

## 快速开始

### 环境要求

- Python >= 3.12
- uv（推荐）或 pip

### 安装依赖

```bash
# 使用 uv（推荐）
uv sync

# 或使用 pip
pip install -e .
```

### 本地运行

```bash
# 运行工作流
bash scripts/local_run.sh -m flow

# 运行指定节点
bash scripts/local_run.sh -m node -n node_name

# 使用输入参数运行
bash scripts/local_run.sh -m flow -i '{"text": "你好"}'
```

### 启动 HTTP 服务

```bash
# 默认端口 8000
bash scripts/http_run.sh

# 指定端口
bash scripts/http_run.sh -p 5000
```

---

## API 接口

| 接口 | 方法 | 描述 |
| ---- | ---- | ---- |
| `/run` | POST | 同步执行工作流 |
| `/stream_run` | POST | 流式执行工作流（SSE） |
| `/cancel/{run_id}` | POST | 取消指定任务 |
| `/node_run/{node_id}` | POST | 运行指定节点 |
| `/v1/chat/completions` | POST | OpenAI 兼容接口 |
| `/health` | GET | 健康检查 |
| `/graph_parameter` | GET | 获取图参数 |

### 接口调用示例

**流式执行**
```bash
curl -X POST http://localhost:5000/stream_run \
  -H "Content-Type: application/json" \
  -d '{
    "content": {
      "query": {
        "prompt": [{"type": "text", "content": {"text": "你好"}}]
      }
    },
    "type": "query",
    "session_id": "test-session"
  }'
```

**同步执行**
```bash
curl -X POST http://localhost:5000/run \
  -H "Content-Type: application/json" \
  -d '{"text": "你好"}'
```

---

## 工具生态

| 领域 | 工具数量 |
| ---- | ---- |
| 图片处理 | 9 |
| 视频处理 | 11 |
| 网页内容 | 8 |
| 文档处理 | 11 |
| 搜索服务 | 9 |
| 代码执行 | 12 |

---

## 核心依赖

| 依赖 | 版本 | 用途 |
| ---- | ---- | ---- |
| langchain | 1.0.3 | LLM框架 |
| langgraph | 1.0.2 | 工作流编排 |
| langchain-openai | 1.0.1 | OpenAI兼容接口 |
| fastapi | >=0.121 | Web服务框架 |
| uvicorn | >=0.38 | ASGI服务器 |
| pydantic | >=2.12 | 数据验证 |
| pandas | >=2.2 | 数据分析 |
| Pillow | >=10.3 | 图片处理 |
| opencv-python | >=4.12 | 视频处理 |

---

## 配置说明

`config/agent_llm_config.json` 包含：
- `avatar`: Agent头像URL
- `config`: 模型配置（model、temperature、top_p等）
- `sp`: 系统提示词
- `tools`: 可用工具列表

---

## 部署

### Coze 平台部署

1. 将项目打包上传至 Coze 平台
2. 配置环境变量
3. 设置 API 访问权限

### 本地开发

```bash
# 开发模式（自动重载）
uv run python src/main.py -m http -p 5000
```

---

## 许可证

MIT License

