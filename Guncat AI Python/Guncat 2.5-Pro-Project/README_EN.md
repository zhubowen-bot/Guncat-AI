# Guncat 2.5-Pro - LangChain / LangGraph Agent

> [中文](README.md) | English

Built on the **LangChain / LangGraph** ecosystem, driven by Python code, powered by **doubao-seed-2.0-Pro**, achieving international first-tier performance.

---

## Project Structure

```
Guncat 2.5-Pro-Project/
├── assets/                    # Static resources (avatars, etc.)
├── config/                    # Configuration files
│   └── agent_llm_config.json  # Agent config (model, tools, system prompt)
├── scripts/                   # Runtime scripts
│   ├── http_run.sh            # HTTP service startup
│   ├── load_env.py            # Environment variable loading (Python)
│   ├── load_env.sh            # Environment variable loading (Shell)
│   ├── local_run.sh           # Local run
│   ├── pack.sh                # Packaging script
│   └── setup.sh               # Setup script
├── src/                       # Source code
│   ├── agents/                # Agent implementations
│   │   ├── __init__.py
│   │   └── agent.py
│   ├── graphs/                # LangGraph workflows
│   │   ├── nodes/             # Custom nodes
│   │   └── __init__.py
│   ├── storage/               # Storage layer
│   │   ├── database/          # Database (PostgreSQL)
│   │   ├── memory/            # Memory storage
│   │   ├── s3/                # S3 storage
│   │   └── __init__.py
│   ├── tools/                 # Toolset (60+ tools)
│   │   ├── code_tools.py      # Code execution tools
│   │   ├── document_tools.py  # Document processing tools
│   │   ├── image_tools.py     # Image processing tools
│   │   ├── search_tools.py    # Search tools
│   │   ├── video_tools.py     # Video processing tools
│   │   ├── web_tools.py       # Web tools
│   │   └── __init__.py
│   ├── utils/                 # Utility functions
│   │   ├── file/              # File operation tools
│   │   └── __init__.py
│   ├── __init__.py
│   └── main.py                # Entry file (FastAPI service)
├── .coze                      # Coze platform config
├── .gitignore
├── pyproject.toml             # Dependency config (managed by uv)
├── uv.lock                    # Dependency lock file
└── README.md
```

---

## Quick Start

### Requirements

- Python >= 3.12
- uv (recommended) or pip

### Install Dependencies

```bash
# Using uv (recommended)
uv sync

# Or using pip
pip install -e .
```

### Local Run

```bash
# Run workflow
bash scripts/local_run.sh -m flow

# Run specific node
bash scripts/local_run.sh -m node -n node_name

# Run with input parameters
bash scripts/local_run.sh -m flow -i '{"text": "hello"}'
```

### Start HTTP Service

```bash
# Default port 8000
bash scripts/http_run.sh

# Specify port
bash scripts/http_run.sh -p 5000
```

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/run` | POST | Synchronous workflow execution |
| `/stream_run` | POST | Streaming workflow execution (SSE) |
| `/cancel/{run_id}` | POST | Cancel specified task |
| `/node_run/{node_id}` | POST | Run specific node |
| `/v1/chat/completions` | POST | OpenAI-compatible endpoint |
| `/health` | GET | Health check |
| `/graph_parameter` | GET | Get graph parameters |

### API Call Examples

**Streaming Execution**
```bash
curl -X POST http://localhost:5000/stream_run \
  -H "Content-Type: application/json" \
  -d '{
    "content": {
      "query": {
        "prompt": [{"type": "text", "content": {"text": "hello"}}]
      }
    },
    "type": "query",
    "session_id": "test-session"
  }'
```

**Synchronous Execution**
```bash
curl -X POST http://localhost:5000/run \
  -H "Content-Type: application/json" \
  -d '{"text": "hello"}'
```

---

## Tool Ecosystem

| Domain | Tool Count |
|--------|-----------|
| Image Processing | 9 |
| Video Processing | 11 |
| Web Content | 8 |
| Document Processing | 11 |
| Search Services | 9 |
| Code Execution | 12 |

---

## Core Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| langchain | 1.0.3 | LLM framework |
| langgraph | 1.0.2 | Workflow orchestration |
| langchain-openai | 1.0.1 | OpenAI-compatible interface |
| fastapi | >=0.121 | Web service framework |
| uvicorn | >=0.38 | ASGI server |
| pydantic | >=2.12 | Data validation |
| pandas | >=2.2 | Data analysis |
| Pillow | >=10.3 | Image processing |
| opencv-python | >=4.12 | Video processing |

---

## Configuration

`config/agent_llm_config.json` contains:
- `avatar`: Agent avatar URL
- `config`: Model configuration (model, temperature, top_p, etc.)
- `sp`: System prompt
- `tools`: Available tool list

---

## Deployment

### Coze Platform Deployment

1. Package the project and upload to the Coze platform
2. Configure environment variables
3. Set API access permissions

### Local Development

```bash
# Development mode (auto-reload)
uv run python src/main.py -m http -p 5000
```

---

## License

MIT License
