# Guncat Srch-Law V2

> [中文](README.md) | English

Intelligent Legal Analysis Agent System for State-Owned Enterprises

## Version

V2.0 - June 2026

## Overview

Guncat Srch-Law V2 is an intelligent analysis system specifically designed for legal affairs of state-owned enterprises (SOEs), fully embodying the **RAR (Retrieval-Augmented Reasoning)** paradigm — retrieval serves reasoning, and evidence precedes conclusions. Core capabilities:

- **Multi-Agent Routing Architecture**: Automatically identifies case types and routes to specialized sub-agents (Contract Analysis / SOE Compliance / Criminal Risk)
- **RAR Local Legal Retrieval Source**: Vectorized legal article retrieval based on ChromaDB + bge-m3; retrieved provisions enter the reasoning chains as evidence after cross-validation, ensuring accurate legal citation
- **Real-time Web Search**: Supports searching for the latest laws, regulations, judicial interpretations, and court cases, forming the RAR dual retrieval source with local legal retrieval
- **Forced Deep Reasoning Chains**: Verified evidence feeds 6-chain deep analysis, running a full "retrieve → verify → reason → self-check" loop
- **Structured Legal Opinion Generation**: Supports Markdown / Word / PDF output formats
- **SOE Compliance Specialization**: Optimized for SOE-specific scenarios including "Three Important and One Major" decisions, state asset supervision, and related-party transactions

## System Architecture

```
User Input
    ↓
RouterAgent (Intent Recognition & Classification)
    ↓
┌──────────┬──────────┬──────────┐
Contract   SOE        Criminal
Analysis   Compliance Risk
Agent      Agent      Agent
└──────────┴──────────┴──────────┘
    ↓
RAR Retrieval Phase: Local Legal Retrieval / Web Search / Case Retrieval
    ↓
Source Grading & Cross-Validation
    ↓
6-Chain Deep Analysis (Memory & State Management)
    ↓
Structured Legal Opinion Output
```

> **RAR (Retrieval-Augmented Reasoning)**: The system does not stuff retrieved snippets into prompts to generate answers. Instead, it runs a "retrieve → verify → reason → self-check" closed loop — the local legal provisions store (ChromaDB + bge-m3) and web retrieval form dual retrieval sources; results are first source-graded and cross-validated, then enter the 6-chain deep analysis as evidence, with every citation carrying a source and timeliness mark.

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

Key dependencies:
- `langchain` / `langchain-openai` - LLM invocation framework
- `langgraph` - Multi-Agent orchestration
- `chromadb` - Vector database
- `sentence-transformers` - Chinese text vectorization (bge-m3)
- `python-docx` - Word document generation
- `weasyprint` - PDF generation (optional)

### 2. Configure API Keys

Configure in `config.py` or pass via environment variables:

```bash
export LLM_API_KEY="your-api-key"
export LLM_MODEL="gpt-4o"  # or claude-3-5-sonnet, etc.
export LLM_PROVIDER="openai"  # openai / anthropic / qwen
```

### 3. Initialize Local Legal Retrieval Source

Core legal data will be automatically loaded into the vector database on first run (the RAR local retrieval source).

To manually initialize:

```python
from knowledge_base.rag_engine import RAGEngine
engine = RAGEngine()
engine.initialize(force_reload=True)
```

### 4. Run the System

#### Interactive Mode

```bash
python main.py --mode interactive
```

#### File Input Mode

```bash
python main.py --mode file --input case_description.txt --format markdown
```

## Usage Examples

### Example 1: SOE Compliance Review

```
Case Description:
A provincial SOE plans to transfer 30% equity of its subsidiary to a private enterprise
via agreement. The transaction price is 200% below the appraisal result, and the
mandatory exchange transaction procedure was not followed. The transaction amount is
50 million yuan.
```

The system will automatically identify this as an "SOE Compliance" case and invoke the ComplianceAgent for analysis, outputting:
- State Asset Supervision Procedure Compliance Review
- "Three Important and One Major" Decision Procedure Review
- Related-Party Transaction Review
- State Asset Loss Risk Assessment
- Management Personnel Responsibility Analysis

### Example 2: Contract Dispute

```
Case Description:
The equity transfer agreement stipulates that operational profits during the transition
period shall belong to the buyer, but the parties dispute the definition of
"operational profits."
```

The system will automatically identify this as a "Contract Dispute" case and invoke the ContractAgent for analysis, outputting:
- Systematic Contract Interpretation (Five-Step Method)
- Key Terminology Precise Analysis
- Legal Principle Deep Analysis
- Breach of Contract Liability Analysis

## Module Description

| Module | Path | Function |
|--------|------|----------|
| Main Entry | `main.py` | CLI interaction, workflow orchestration |
| Configuration | `config.py` | All configurable parameters |
| Router Agent | `agents/router_agent.py` | Intent recognition, case classification |
| Contract Agent | `agents/contract_agent.py` | Contract analysis |
| Compliance Agent | `agents/compliance_agent.py` | SOE compliance review |
| Criminal Agent | `agents/criminal_agent.py` | Criminal risk assessment |
| Legal Retrieval Engine | `knowledge_base/rag_engine.py` | Legal article vector retrieval (RAR local source) |
| Vector Store | `knowledge_base/vector_store.py` | ChromaDB wrapper |
| Web Search | `tools/web_search.py` | Real-time search tool |
| Output Formatter | `output/formatter.py` | Legal opinion generation |

## Optimization Highlights (Addressing V1.0 Feedback)

### Issue 1: Insufficient Analysis Depth → Solution

- **Enhanced System Prompt**: Added "Legal Analysis Toolbox" forcing deep legal reasoning tools such as overall consideration theory and unjust enrichment theory
- **RAR Local Legal Retrieval**: Cross-validates retrieved real legal articles against web information before reasoning, to avoid model "hallucinations"
- **Five-Step Contract Interpretation**: Systematic Interpretation → Purpose Interpretation → Literal Interpretation → Historical Interpretation → Good Faith Interpretation

### Issue 2: Weak SOE Scenario Coverage → Solution

- **ComplianceAgent Specialization**: Targeted analysis for "Three Important and One Major," Order No. 32, related-party transactions, and state asset loss scenarios
- **SOE Compliance Output Section**: Output must include an independent "SOE Compliance Analysis" section
- **Comprehensive Criminal Liability Coverage**: Covers all Articles 165-169 of Criminal Law (SOE-related crimes)

## Extension Suggestions

### 1. Integrate Real Legal Database APIs

The current `tools/` module has interfaces ready for integration with:
- Peking University Law Database (PKULaw)
- China Judgments Online
- National Laws and Regulations Database

### 2. Enhance Local Legal Retrieval Source (RAR)

Load more legal regulation full texts in `knowledge_base/law_data_loader.py`:
- Recommended: Load complete articles of at least 20 core regulations
- Regular updates (recommended quarterly)

### 3. Integrate LangGraph Orchestration

The current architecture uses a simplified serial process, upgradeable to LangGraph state graph:
- Support conditional jumps between agents
- Support parallel invocation of multiple sub-agents
- Support traceable reasoning process

### 4. Deploy as API Service

Can be wrapped with FastAPI to provide HTTP API:

```python
# api.py (example code)
from fastapi import FastAPI
from main import GuncatSrchLawV2

app = FastAPI()
system = GuncatSrchLawV2()

@app.post("/analyze")
def analyze_case(case: dict):
    return system.analyze(case["description"], case.get("enterprise_type"))
```

## Testing

Run basic tests:

```bash
python tests/test_basic.py
```

## Notes

1. **LLM API Key**: Agent analysis requires a valid LLM API key
2. **Web Search**: Currently uses mock mode by default; real web search can be enabled after configuring a search API
3. **Vectorization Model**: The bge-m3 model (~2GB) will be automatically downloaded on first run; please be patient
4. **Legal Article Timeliness**: The system marks legal article effective dates, but manual verification of the latest version is still recommended

## License

MIT License

## Contact

For questions or suggestions, feel free to provide feedback.
