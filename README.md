## Language

- [English](#english)

- [中文](#中文)
  
  

---



### English

# Guncat AI

> Structured Chain-of-Thought × Multi-Agent Collaboration × Configurable API — A New-Generation Large Model Agent Framework

* * *

## Introduction

Guncat AI is a large model agent solution spanning **general-purpose agents, vertical retrieval, content rewriting, legal analysis**, and **cross-platform clients**. Rather than merely providing prompts, it delivers multiple practical technical pathways — from prompt-driven and Python code-driven approaches, to web clients and native HarmonyOS applications.

The core design goal of Guncat is to **ensure that complex tasks are completed in a stable, controllable, and traceable manner**. To this end, Guncat introduces mechanisms such as structured chain-of-thought, multi-agent collaboration, mandatory multi-round retrieval, RAG knowledge bases, and source grading across multiple product lines — systematically reducing large model hallucinations and improving the reliability of long-horizon tasks and complex reasoning.

* * *

## Agent Series

Guncat comprises **6 agent series**, each representing a core technical implementation of "how an agent is organized, driven, and produces content."

### Guncat 2.0 Series — All-Purpose Agent Cluster

Prompt-driven, equipped with a complete agent cluster across the entire lineup, focused on completing complex tasks with maturity and reliability.

* **2.0-pro**: Flagship edition. Operates through sub-agent collaboration throughout the entire process, pursuing ultimate task completion quality. Supports ultra-long-horizon work and extended multi-round conversations without losing context. Deep thinking enabled.
* **2.0-flash**: Ultra-fast edition. Invokes tools through the main agent while retaining the full Pro agent cluster as a fallback. Prompt engineering restructured to achieve the unification of "extreme speed + reliable quality."
* **2.0-fast**: Discontinued, evolved into 2.0-flash.

**Core Orchestration Capabilities**: Web search, image understanding, document parsing, third-party platform integration, advanced document processing and conversion, advanced image processing, AI image generation, video editing and processing, code interpreter, mind map generation.

* * *

### Guncat 2.5 Series — Sequential Thinking Structured Chain-of-Thought

Prompt-driven, innovatively featuring the **Sequential Thinking** structured chain-of-thought and a multi-agent collaboration architecture. A "more stable, faster, and more structured" upgrade succeeding the 2.0 series.

**Core Upgrades**

* **Structured Chain-of-Thought**: Introduces Sequential Thinking and task lists, significantly improving the stability, visibility, structure, and continuity of multi-round tool invocation (especially in fast mode).
* **New Prompt Architecture**: Fully describes each tool's input/output parameters with detailed input specifications, but does not restrict when the model invokes tools. Compared to 2.0's "list tools + specify invocation conditions" approach, this improves tool invocation efficiency and accuracy.
* **Three-Tier Reasoning Modes**: The model autonomously selects reasoning strategies — Fast mode (no tool invocation) → Standard mode (tool invocation available) → Deep mode (Sequential Thinking + multi-round backtracking).

**Version Matrix**

| Version           | Positioning | Deep Thinking | Speed (vs 2.5-lite) | Quality |
| ----------------- | ----------- | ------------- | ------------------- | ------- |
| 2.5-max           | Flagship    | ✅             | ~0.75x              | Highest |
| 2.5-lite-thinking | Recommended | ✅             | ~0.9x               | High    |
| 2.5-lite          | Ultra-fast  | —             | 1x                  | High    |

**Core Orchestration Capabilities**: Web search, image understanding, document parsing, code interpreter, deep thinking, multi-agent collaboration, structured chain-of-thought.

* * *

### Guncat Srch Series — Accurate, Traceable Information Retrieval

Distinct from general-purpose agents, the **Guncat Srch Series** is purpose-built for **accurate, traceable information retrieval**, leveraging carefully designed mechanisms to substantially reduce large model hallucinations at the source. Three versions target different scenarios:

#### Guncat Srch-Law — SOE Legal Analysis Expert

* **Specialized Domain**: State-owned enterprise (SOE) legal affairs, civil/administrative/criminal cross-jurisdictional cases, state asset regulatory compliance.
* **Retrieval Intensity**: Mandatory **6 rounds of sequential retrieval**.
* **Output Format**: Structured legal opinion letter.

#### Guncat Srch-Research — Multi-Round Verification Research Expert

* **Specialized Domain**: Cross-domain information retrieval, multi-source cross-verification, complex concept disambiguation, trend and risk assessment.
* **Retrieval Intensity**: Mandatory **4–6 rounds of search verification**.
* **Output Format**: Structured research report.

#### Guncat Srch-Sift — AI Information Filtration Retrieval Expert

* **Specialized Domain**: Time-sensitive/high-hallucination-risk information queries, AI-generated content filtration, official primary-source tracing and entity state anchoring.
* **Retrieval Intensity**: **Nine-step deep search method** (trace → anchor → investigate → sift).
* **Output Format**: Source-verified report.

**Core Anti-Hallucination Mechanisms (Law / Research)**

* **Mandatory Multi-Round Sequential Retrieval**: Each analysis must follow prioritized retrieval sequences, eliminating "answering without retrieval."
* **Time-Sensitivity Iron Rule**: Strictly prohibits citing repealed/revised/outdated/unverifiable information; every citation must be annotated with its source and latest revision/publication date.
* **No-Fabrication Principle**: Uncertain issues must be explicitly marked as "requires further verification" with verification directions specified; the Law version strictly prohibits fabricating case examples.
* **Multi-Source Cross-Verification Matrix**: The Research version mandatorily constructs a multi-source verification matrix, surfacing contradictory information.
* **Authoritative Source Priority**: Prioritizes high-confidence sources such as government websites, official media, academic institutions, official announcements, and academic literature with DOIs.
* **Mandatory Deep Analysis Chain**: 6 reasoning chains are enforced; skipping any deep analysis step on the grounds of "length constraints" is strictly prohibited.

**Core Anti-Hallucination Mechanisms (Sift, Exclusive Pathway)**

* **Official Source Tracing**: Mandatorily searches for official information sources for each key entity by P0–P5 priority (official website/docs → official social media/blog → code hosting platform → official app store → authoritative release platform → authoritative review institution).
* **Entity State Anchoring**: Only version numbers/states confirmed by official page text are used as benchmarks; when multiple official sources conflict, the most recently published one prevails.
* **AI Content Identification and Mandatory Filtration**: Performs six checks on each search result (title pattern, author information, content structure, temporal expression, source traceability, URL characteristics), with tiered degradation handling.
* **Five-Tier Source Authority Grading (S-A-B-C-D)**: S-tier official sources can be directly adopted; D-tier suspected AI content is excluded in principle.
* **Time-Sensitivity Graded Assessment**: Determines the query's time-sensitivity before retrieval (🔴 very high / 🟡 moderate / 🟢 low); 🔴 very high sensitivity domains are flagged as potentially outdated after 3 months.
* **"Trace First → Anchor → Then Investigate" Thinking Discipline**: No version number/state is confirmed until an official source is found; historical information is physically isolated from "current state" descriptions.
* **AI Content Encirclement Breakthrough Strategy**: When AI-generated content exceeds 80% in a search round, automatically switches search terms to include first-party information qualifiers such as "official website," "official announcement," "Release," "whitepaper," etc.

* * *

### Guncat Cnvt Series — Style Conversion / Content Rewriting

The **Guncat Cnvt Series** (Convert) is purpose-built for **high-quality style conversion and content rewriting**. The first agent, **Cnvt-Paper**, is a "paper rewriting expert" that excels at transforming various non-academic text types (reviews, essays, notes, reports, dialogues, blog posts, lecture notes, etc.) into academically compliant papers.

**Core Innovation: Eight-Parameter Fine-Grained Control System**

| Parameter                        | Options                                                                                                                     | Function                                                                                        |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| A Target Paper Type              | course_essay / major_course / literature_review / research_proposal / academic_paper / thesis_chapter / conference_abstract | Determines structural requirements and citation standards                                       |
| B Rewriting Mode                 | preserve / expand_light / expand_heavy / reconstruct / polish_only                                                          | Controls rewriting intensity (minimal changes → full reconstruction)                            |
| C Expansion Strategy             | fluff / substance / research                                                                                                | Filler expansion / substantive supplementation / in-depth material supplementation (web search) |
| D Professional Level             | casual / standard / advanced / interdisciplinary                                                                            | Controls terminology usage and academic depth                                                   |
| E Word Count Strategy            | maintain / double / triple / custom / compress                                                                              | Controls output word count                                                                      |
| F Academic Standards & Citations | none / informal / apa / mla / chicago / gb7714 / custom                                                                     | Controls citation format                                                                        |
| G Language Style                 | formal / rigorous / engaging / critical                                                                                     | Controls academic language style                                                                |
| H Output Granularity             | outline / section / full / annotated                                                                                        | Outline / sectioned / complete / annotated                                                      |

**Core Capabilities**

* **Source Text Diagnosis**: Automatically identifies text type, analyzing original structure, linguistic features, information density, and logical completeness.
* **Style Conversion Technique Library**: Spoken → written, narrative → argumentative, essay → academic.
* **Argument Structure Reconstruction**: Identifies core arguments → distills Thesis Statement, supplements the complete "background–problem–literature–method–analysis–conclusion" chain, configures the TEEA structure (Topic sentence–Elaboration–Evidence–Anchor-back).
* **Academic Language Upgrade**: Terminology substitution, nominalization, passive voice, hedging language.
* **Logical Chain Completion**: Supplements "why / on what basis / so what / what about the counterargument."
* **Academic Element Embedding**: Research questions, literature review, theoretical framework, methodology description, research significance.
* **Source-Text-Specific Strategies**: Different source text types — reviews, essays, lecture notes, lab reports, dialogues, news, blogs, slides — each have dedicated strategies.
* **Anti-Hallucination Mechanism**: When `substance` or `research` expansion strategy is selected, mandatory web search verifies knowledge authenticity; fabricating data and fictitious references is prohibited.

**Source-Text-Specific Strategies**

| Source Text Type                | Core Challenge                                | Targeted Strategy                                                                                          |
| ------------------------------- | --------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Review / Reading Notes          | Lacks independent argument, merely enumerates | Distills a critical perspective, transforms "description" into "commentary," identifies "research gaps"    |
| Essay / Commentary              | Emotional, fragmented, unstructured           | Extracts core ideas as arguments, reconstructs IMRaD or "general–specific–general," removes sentimentality |
| Course Lecture Notes / Notes    | Lists knowledge points, lacks argumentation   | Reorganizes into "problem-driven" discourse, supplements academic history context                          |
| Lab / Practice Report           | Process-heavy, analysis-light                 | Strengthens "problem–method–finding–discussion," supplements theoretical explanation                       |
| Dialogue / Interview Transcript | Colloquial, repetitive, disjointed            | Extracts core viewpoints, removes pleasantries and repetition, reorganizes into coherent argumentation     |
| News / Commentary               | Time-sensitive, lacks theoretical depth       | Supplements theoretical framework, transforms specific events into case studies                            |
| Blog / Self-Media               | Emotional, highly subjective                  | Removes emotional language, supplements data support                                                       |
| Slides / Outline                | Fragmented, lacks transitions                 | Expands into complete paragraphs, supplements transitions and argumentation                                |

* * *

### Guncat 2.5-Pro — LangGraph Code-Driven, 60+ Tool Ecosystem

Built on the **LangChain / LangGraph** ecosystem, Python code-driven, equipped with **doubao-seed-2.0-Pro**, achieving top-tier international performance. Transitions from prompt-driven to code-level controllable tool invocation, with traceable and debuggable workflows.

**Core Upgrades**

* **Python Code-Driven**: Tool invocation and agent logic are directly controlled by code, offering greater stability, controllability, and debuggability than pure prompt-driven approaches.
* **LangGraph Ecosystem**: Supports complex workflow orchestration, state management, and multi-agent collaboration.
* **60+ Professional Tools**: Covering six major domains (see the tool ecosystem table below).
* **4x Speed**: Complex tasks run at approximately 4x the speed of 2.0-flash.

**Tool Ecosystem (Six Domains)**

| Domain              | Tool Count | Representative Tools                                                                                                                                         |
| ------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Image Processing    | 9          | generate_image, image_understanding, extract_text_from_image, analyze_chart, compare_images, detect_objects, remove_watermark, enhance_image, style_transfer |
| Video Processing    | 11         | generate_video, trim_video, concat_videos, extract_key_frames, add_subtitles, auto_subtitle, analyze_video, combine_video_audio                              |
| Web Content         | 8          | fetch_webpage, extract_text_from_url, convert_url_to_markdown, analyze_article, summarize_article, compare_articles                                          |
| Document Processing | 11         | create_pdf, create_docx, create_pptx, create_excel, translate_text, summarize_document, proofread_document                                                   |
| Search Services     | 9          | web_search, image_search, search_news, academic_search, verify_information, compare_products, get_trending_topics                                            |
| Code Execution      | 12         | execute_python_code, calculate, generate_chart, parse_json, generate_mindmap, debug_code, validate_json_schema                                               |

* * *

### Guncat Srch-Law V2 — SOE Legal Intelligent Analysis Agent System

**Guncat Srch-Law V2** is a **complete agent application upgrade** of Srch-Law V1.0, transitioning from prompt-driven to a **Python code-driven Multi-Agent system**. It introduces RAG knowledge bases, real-time web retrieval, structured output, and other full capabilities, achieving the leap from a "prompt-based agent" to an "application-level intelligent system."

**Core Upgrades (vs V1.0)**

| Dimension       | V1.0 (Prompt-Driven)                                  | V2.0 (Python Code-Driven)                                                                                                |
| --------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Architecture    | Monolithic Prompt, relies on platform tool invocation | Multi-Agent routing architecture (Router + Contract + Compliance + Criminal)                                             |
| Knowledge Base  | Relies solely on web search                           | **RAG legal provisions knowledge base** (ChromaDB + bge-m3)                                                              |
| Retrieval       | Platform web search                                   | Dual-engine: local RAG retrieval + real-time web retrieval                                                               |
| Output          | Markdown text                                         | Three structured formats: Markdown / Word / PDF                                                                          |
| SOE Compliance  | Prompt conventions                                    | **Dedicated ComplianceAgent** ("Triple Major, One Large" decisions, state asset supervision, related-party transactions) |
| Criminal Risk   | Prompt coverage                                       | **Dedicated CriminalAgent** (full coverage of Criminal Law Articles 165–169)                                             |
| Portability     | Platform-dependent                                    | Python-portable, supports local execution / FastAPI deployment / Coze integration                                        |
| Controllability | Model self-controlled                                 | Code-controlled workflows, traceable and debuggable steps                                                                |

**Multi-Agent Architecture**

| Agent           | Function                                                   | Specialized Scenarios                                                                                                                                 |
| --------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| RouterAgent     | Intent recognition, case classification, routing decisions | Automatically determines case type (contract dispute / SOE compliance / criminal risk / comprehensive)                                                |
| ContractAgent   | Contract parsing and analysis                              | Systematic contract interpretation (five-step method), key term disambiguation, breach-of-contract liability analysis                                 |
| ComplianceAgent | SOE compliance review                                      | "Triple Major, One Large" decision procedures, state asset supervision procedural compliance, related-party transaction review, state asset loss risk |
| CriminalAgent   | Criminal risk assessment                                   | Full coverage of Criminal Law Articles 165–169, duty crime risk simulation, management personnel liability analysis                                   |

**RAG Knowledge Base (ChromaDB + bge-m3)**

| Category                   | Count | Regulation List                                                                                                                                                                                                                               |
| -------------------------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Laws                       | 4     | Enterprise State-Owned Assets Law, Company Law (2023 Revision), Administrative Penalty Law, Criminal Law (SOE-related provisions)                                                                                                             |
| Administrative Regulations | 2     | Measures for Supervision and Administration of Transactions of Enterprise State-Owned Assets (Order No. 32), Interim Regulations on Supervision and Administration of Enterprise State-Owned Assets                                           |
| SASAC Normative Documents  | 4     | "Triple Major, One Large" Decision System Opinions, Central Enterprise Compliance Management Measures, Interim Measures for Management of SOE Equity Participation, Interim Measures for Management of Enterprise State-Owned Asset Appraisal |
| Judicial Interpretations   | 5     | Supreme Court Company Law Judicial Interpretations (I–V)                                                                                                                                                                                      |

**Workflow**: Case classification → RAG knowledge base retrieval → Real-time web retrieval → 6-chain deep analysis (legal relationship deconstruction → systematic contract interpretation → SOE-specific rule application → in-depth jurisprudential analysis → liability risk simulation → compliance recommendations) → Formatted legal opinion letter output.

* * *

## Deployment Solutions

The same set of agents can be carried by different clients or platforms. Guncat offers 6 deployment forms.

| Deployment Solution     | Applicable Agents                     | Form                    | Description                                                                                                      |
| ----------------------- | ------------------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Tencent Yuanqi**      | Guncat 2.0 / 2.5 Series               | Platform-hosted         | Platform-adapted prompts; agents can be created directly on Tencent Yuanqi                                       |
| **Zhipu Qingyan**       | Guncat Srch / Cnvt Series             | Platform-hosted         | Platform-adapted prompts, deployed on the Zhipu Qingyan platform                                                 |
| **Guncat AI-zhipu Web** | Zhipu Qingyan chat client             | Browser H5              | Official chat webpage based on Zhipu's free GLM API, ready out of the box                                        |
| **Guncat Web for API**  | Universal prompts (platform-agnostic) | Web / Windows / Android | "Configuration-as-Agent" architecture; users select their own OpenAI-compatible API                              |
| **Coze Service**        | Guncat 2.5-Pro                        | Cloud API               | Python agent deployed as a Coze API service for external capability provision                                    |
| **HarmonyOS App**       | Web for API universal prompts         | HarmonyOS native app    | Secondary packaging based on Web for API, with HarmonyOS rawfile preloading + resource interception optimization |

### 1. Tencent Yuanqi

* Search for "Guncat" directly in the Tencent Yuanqi platform marketplace to start using it.

### 2. Zhipu Qingyan

* Search for "Guncat" directly in the Zhipu Qingyan official website/app agent center to start using it.

### 3. Guncat AI-zhipu Web (Zhipu Qingyan Chat Client)

* Located at [Guncat AI Release/Guncat AI-zhipu_glm_version](./Guncat%20AI%20Release/).
* Pure frontend HTML; open `guncat-app.html` directly in a browser.
* Connects to the Zhipu Qingyan free GLM API (API Key entered in page settings).
* Suitable for: Zero-dependency trial for Zhipu Qingyan users.

### 4. Guncat Web for API

* "Configuration-as-Agent" architecture: The agent list is defined by `agents.json`, with prompts stored as external `.md` files.
* Users select their own OpenAI-compatible API (OpenAI, Azure, Zhipu, Tongyi Qianwen, DeepSeek, etc.).
* Suitable for: Cross-platform unified entry point, flexible deployment with user's own API.

#### Windows Local HTTP Service Version

A pre-built `.bat` file is included; simply click to launch the local HTTP service.

#### HarmonyOS App Version

* A HarmonyOS H5 native application developed based on Web for API.
* rawfile bundles `agents.json`, all `.md` prompts, and avatars, preventing load failures caused by unstable Netlify access in mainland China.
* Optimizations: DNS/TCP preconnect, local resource interception and replacement, async rendering, caching strategy.
* Suitable for: Native app experience on HarmonyOS devices.

### 5. Coze Service (Guncat 2.5-Pro)

* Deploy the Guncat 2.5-Pro Python project to the Coze platform, providing a Coze API externally.
* Supports the OpenAI-compatible `/v1/chat/completions` interface.
* Suitable for: Integrating 2.5-Pro as a backend service into other applications.

* * *

## Project Structure

This project has been fully restructured, with **agent series** and **deployment solutions** clearly separated by responsibility:

| Module                                                                            | Category           | Description                                                                                  |
| --------------------------------------------------------------------------------- | ------------------ | -------------------------------------------------------------------------------------------- |
| [Guncat AI Release](./Guncat%20AI%20Release/)                                     | Agent + Deployment | Tencent Yuanqi, Zhipu Qingyan, and other platform-adapted prompts + Zhipu Qingyan web client |
| [Guncat AI Python](./Guncat%20AI%20Python/)                                       | Agent              | Two Python code-driven projects: Guncat 2.5-Pro and Srch-Law V2                              |
| [Guncat AI Web for API](./Guncat%20AI%20Web%20for%20API/)                         | Deployment         | Universal prompt web client, self-configured API                                             |
| [Guncat AI Web for API_local-setup](./Guncat%20AI%20Web%20for%20API_local-setup/) | Deployment         | Windows one-click local launch version of the web client                                     |
| [GuncatAI-Web-for-API_HMOS-APP](./GuncatAI-Web-for-API_HMOS-APP/)                 | Deployment         | HarmonyOS native application                                                                 |

* * *

## Quick Start

| What You Want to Do                             | Directory                                                                         |
| ----------------------------------------------- | --------------------------------------------------------------------------------- |
| Deploy agents on Tencent Yuanqi / Zhipu Qingyan | [Guncat AI Release](./Guncat%20AI%20Release/)                                     |
| Run or further develop Python agents            | [Guncat AI Python](./Guncat%20AI%20Python/)                                       |
| Use your own API Key in the browser             | [Guncat AI Web for API](./Guncat%20AI%20Web%20for%20API/)                         |
| Windows one-click local launch                  | [Guncat AI Web for API_local-setup](./Guncat%20AI%20Web%20for%20API_local-setup/) |
| Install and use on HarmonyOS devices            | [GuncatAI-Web-for-API_HMOS-APP](./GuncatAI-Web-for-API_HMOS-APP/)                 |

* * *

## License

MIT License

Copyright (c) 2026 Zhu Bowen



---



### 中文

# Guncat AI

> 结构化思维链 × 多 Agent 协同 × 可配置 API —— 新一代大模型智能体框架

---

## 简介

Guncat AI 是一套覆盖**通用智能体、垂直检索、内容改写、法律分析**到**跨平台客户端**的大模型智能体方案。它不只提供提示词，而是从 Prompt 驱动、Python 代码驱动、Web 客户端到鸿蒙原生应用，提供了多条可落地的技术路径。

Guncat 的核心设计目标是：**让复杂任务能被稳定、可控、可溯源地完成**。为此，Guncat 在多个产品线中引入了结构化思维链、多 Agent 协同、强制多轮检索、RAG 知识库、来源分级等机制，系统性地降低大模型幻觉，提升长程任务和复杂推理的可靠性。

---

## 智能体系列

Guncat 包含 **6 个智能体系列**，每条系列代表一种「智能体如何被组织、如何被驱动、如何产出内容」的核心技术实现。

### Guncat 2.0 系列 — 全能 Agent 集群

Prompt 驱动，全系搭载完整 Agent 集群，专注于完成复杂任务，成熟可靠。

- **2.0-pro**：旗舰版。全过程通过子 Agent 协同工作，追求极致任务完成质量，支持超长程工作与长时间多轮对话不断链。开启深度思考。
- **2.0-flash**：极速版。通过主 Agent 调用工具，同时保留 Pro 完整 Agent 集群作为备选，重构提示词实现「极致速度 + 可靠质量」的统一。
- **2.0-fast**：已停止服务，演进为 2.0-flash。

**核心编排能力**：联网搜索、图片理解、文档解析、第三方平台接入、高级文档处理与转换、高级图片处理、AI 图片生成、视频剪辑与处理、代码解释器、脑图生成。

---

### Guncat 2.5 系列 — Sequential Thinking 结构化思维链

Prompt 驱动，创新搭载 **Sequential Thinking** 结构化思维链与多 Agent 协同架构，是 2.0 系列后继的「更稳、更快、更结构化」升级。

**核心升级**

- **结构化思维链**：引入 Sequential Thinking 和任务 list，大幅提高多轮工具调用（尤其快速模式下）的稳定性、可视性、结构性和连续性。
- **全新提示词架构**：完整描述每个工具的输入输出参数，给出细致的输入规范，但不限制模型何时调用工具。相较 2.0「只列工具 + 规定调用条件」，更有利于工具调用效率和准确性。
- **三档推理模式**：模型自主选择推理策略 — 极速模式（不调用工具）→ 标准模式（可调用工具）→ 深度模式（Sequential Thinking + 多轮回溯）。

**版本矩阵**

| 版本                | 定位  | 深度思考 | 速度 (vs 2.5-lite) | 质量  |
| ----------------- | --- | ---- | ---------------- | --- |
| 2.5-max           | 旗舰  | ✅    | ~0.75x           | 最高  |
| 2.5-lite-thinking | 推荐  | ✅    | ~0.9x            | 高   |
| 2.5-lite          | 极速  | —    | 1x               | 高   |

**核心编排能力**：联网搜索、图片理解、文档解析、代码解释器、深度思考、多 Agent 协同、结构化思维链。

---

### Guncat Srch 系列 — 准确、可溯源的信息检索

区别于通用智能体，**Guncat Srch 系列**专为**准确、可溯源的信息检索**而生，通过精心设计的机制从源头大幅降低大模型幻觉。三个版本针对不同场景：

#### Guncat Srch-Law — 国企法律分析专家

- **专精领域**：国有企业法律事务、商事/行政/刑事交叉案件、国资监管合规。
- **检索强度**：强制 **6 轮串行检索**。
- **输出形态**：结构化法律意见书。

#### Guncat Srch-Research — 多轮验证研究专家

- **专精领域**：跨领域信息检索、多源交叉验证、复杂概念辨析、趋势与风险评估。
- **检索强度**：强制 **4-6 轮搜索验证**。
- **输出形态**：结构化研究报告。

#### Guncat Srch-Sift — AI 信息筛滤检索专家

- **专精领域**：时效性强/幻觉率高的信息查询、AI 生成内容过滤、官方一手信息溯源与实体状态锚定。
- **检索强度**：**九步深度搜索法**（溯源→锚定→调研→筛滤）。
- **输出形态**：溯源验证报告。

**核心反幻觉机制（Law / Research）**

- **强制多轮串行检索**：每次分析必须按优先级排列的检索，杜绝「无检索即作答」。
- **时效性铁律**：严禁引用已废止/已修订/已过时/来源不明的信息；每条引用必须标注来源 + 最新修订/发布时间。
- **禁止臆断原则**：对不确定的问题必须明确标注「需进一步核实」并说明核实方向；Law 版本严禁编造案例。
- **多源交叉验证矩阵**：Research 版本强制构建多源验证矩阵，将矛盾信息显性化。
- **权威来源优先**：优先选取政府网站、官媒、学术机构、官方公告、学术文献 DOI 等高置信度来源。
- **深度分析强制链**：6 条推理链强制执行，严禁以「篇幅限制」为由跳过任何深度分析步骤。

**核心反幻觉机制（Sift，独家路径）**

- **官方渠道溯源（Official Source Tracing）**：强制按 P0-P5 优先级为每个关键实体查找官方信息源（官网/文档 → 官方社媒/博客 → 代码托管平台 → 官方应用商店 → 权威发布平台 → 权威评测机构）。
- **实体状态锚定（Entity State Anchoring）**：仅以官方页面原文确认的版本号/状态为基准；多官方源矛盾时以发布时间最新者为准。
- **AI 内容识别与强制过滤**：对每条搜索结果执行六项检查（标题模式、作者信息、内容结构、时间表述、来源追溯、URL 特征），分级降级处理。
- **来源权威性 S-A-B-C-D 五级分级**：S 级官方来源可直接采信，D 级疑似 AI 内容原则上排除。
- **时效敏感度分级评估**：检索前先判定问题时效敏感度（🔴极高 / 🟡中等 / 🟢较低），🔴极高敏感领域超过 3 个月即标记为可能过时。
- **「先溯源→后锚定→再调研」思维纪律**：没找到官方渠道前绝不确认任何版本号/状态；历史信息物理隔离于「当前状态」描述。
- **AI 内容包围突破策略**：当某轮搜索 AI 内容占比超 80% 时，自动切换搜索词加入「官网」「官方公告」「Release」「白皮书」等一手信息限定词。

---

### Guncat Cnvt 系列 — 文体转换 / 内容改写

**Guncat Cnvt 系列**（Convert 转换）专为实现**高质量文体转换与内容改写**而生，首款智能体 **Cnvt-Paper** 是一位「论文改写专家」，擅长将各种非论文文体（综述、散文、笔记、报告、对话、博客、讲义等）转化为符合学术规范的论文。

**核心创新：八参数精细化控制系统**

| 参数        | 可选值                                                                                                                         | 功能                         |
| --------- | --------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| A 目标论文类型  | course_essay / major_course / literature_review / research_proposal / academic_paper / thesis_chapter / conference_abstract | 决定结构要求与引用标准                |
| B 改写模式    | preserve / expand_light / expand_heavy / reconstruct / polish_only                                                          | 控制改写程度（最小改动→完全重构）          |
| C 扩充策略    | fluff / substance / research                                                                                                | 废话扩充 / 实质补充 / 深度素材补充（联网检索） |
| D 专业程度    | casual / standard / advanced / interdisciplinary                                                                            | 控制术语使用与学术深度                |
| E 字数策略    | maintain / double / triple / custom / compress                                                                              | 控制输出字数                     |
| F 学术规范与引用 | none / informal / apa / mla / chicago / gb7714 / custom                                                                     | 控制引用格式                     |
| G 语言风格    | formal / rigorous / engaging / critical                                                                                     | 控制学术语言风格                   |
| H 输出粒度    | outline / section / full / annotated                                                                                        | 大纲 / 分段 / 完整 / 带批注         |

**核心能力**

- **源文体诊断**：自动识别文体类型，分析原始结构、语言特征、信息密度、逻辑完整性。
- **文体转换技术库**：口语→书面语、叙述→论证、散文→学术。
- **论证结构重构**：识别核心论点 → 提炼 Thesis Statement，补充「背景-问题-文献-方法-分析-结论」完整链条，配置 TEEA 结构（主题句-展开-证据-回扣）。
- **学术语言升级**：术语替换、名词化、被动语态、模糊限制语。
- **逻辑链条补全**：补充「为什么 / 凭什么 / 所以呢 / 反面呢」。
- **学术要素嵌入**：研究问题、文献综述、理论框架、方法论说明、研究意义。
- **分文体针对性策略**：综述、散文、讲义、实验报告、对话、新闻、博客、PPT 等不同源文体有各自专门策略。
- **反幻觉机制**：当选择 `substance` 或 `research` 扩充策略时，强制联网搜索验证知识真实性，禁止编造数据和虚构文献。

**分文体针对性策略**

| 源文体       | 核心挑战        | 针对性策略                             |
| --------- | ----------- | --------------------------------- |
| 综述 / 读书笔记 | 缺乏独立论点，只是罗列 | 提炼批判性视角，将「介绍」转为「评述」，识别「研究空白」      |
| 散文 / 杂文   | 感性化、碎片化、无结构 | 提取核心思想作为论点，重构 IMRaD 或「总-分-总」，去除抒情 |
| 课程讲义 / 笔记 | 知识点罗列，缺乏论证  | 重组为「问题驱动」的论述，补充学术史脉络              |
| 实验 / 实践报告 | 重过程轻分析      | 强化「问题-方法-发现-讨论」，补充理论解释            |
| 对话 / 访谈记录 | 口语化、重复、跳跃   | 提取核心观点，去除寒暄和重复，重组为连贯论证            |
| 新闻 / 评论   | 时效性强，缺乏理论深度 | 补充理论框架，将具体事件转为案例                  |
| 博客 / 自媒体  | 情绪化、主观性强    | 去除情绪词，补充数据支撑                      |
| PPT / 大纲  | 碎片化、缺乏连接    | 扩写为完整段落，补充过渡与论证                   |

---

### Guncat 2.5-Pro — LangGraph 代码驱动，60+ 工具生态

基于 **LangChain / LangGraph** 生态，Python 代码驱动，搭载 **doubao-seed-2.0-Pro**，国际第一梯队水平。从 Prompt 驱动跃迁为代码级可控的工具调用，工作流可追溯、可调试。

**核心升级**

- **Python 代码驱动**：工具调用和 Agent 逻辑由代码直接控制，比纯 Prompt 驱动更稳定、可控、可调试。
- **LangGraph 生态**：支持复杂工作流编排、状态管理和多 Agent 协作。
- **60+ 专业工具**：覆盖六大领域（详见下方工具生态表）。
- **速度 4x**：复杂任务速度约为 2.0-flash 的 4 倍。

**工具生态（六大领域）**

| 领域   | 工具数 | 代表工具                                                                                                                                                         |
| ---- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 图片处理 | 9   | generate_image, image_understanding, extract_text_from_image, analyze_chart, compare_images, detect_objects, remove_watermark, enhance_image, style_transfer |
| 视频处理 | 11  | generate_video, trim_video, concat_videos, extract_key_frames, add_subtitles, auto_subtitle, analyze_video, combine_video_audio                              |
| 网页内容 | 8   | fetch_webpage, extract_text_from_url, convert_url_to_markdown, analyze_article, summarize_article, compare_articles                                          |
| 文档处理 | 11  | create_pdf, create_docx, create_pptx, create_excel, translate_text, summarize_document, proofread_document                                                   |
| 搜索服务 | 9   | web_search, image_search, search_news, academic_search, verify_information, compare_products, get_trending_topics                                            |
| 代码执行 | 12  | execute_python_code, calculate, generate_chart, parse_json, generate_mindmap, debug_code, validate_json_schema                                               |

---

### Guncat Srch-Law V2 — 国企法律智能分析 Agent 系统

**Guncat Srch-Law V2** 是 Srch-Law V1.0 的**完整 Agent 应用升级版**，从 Prompt 驱动升级为 **Python 代码驱动的 Multi-Agent 系统**，引入 RAG 知识库、联网实时检索、结构化输出等完整能力，实现从「提示词智能体」到「应用级智能系统」的跨越。

**核心升级（相对 V1.0）**

| 维度   | V1.0（Prompt 驱动）    | V2.0（Python 代码驱动）                                           |
| ---- | ------------------ | ----------------------------------------------------------- |
| 架构   | 单体 Prompt，依赖平台工具调用 | Multi-Agent 路由架构（Router + Contract + Compliance + Criminal） |
| 知识库  | 仅依赖联网搜索            | **RAG 法律条文知识库**（ChromaDB + bge-m3）                          |
| 检索   | 平台联网搜索             | 本地 RAG 检索 + 联网实时检索双引擎                                       |
| 输出   | Markdown 文本        | Markdown / Word / PDF 三种结构化格式                               |
| 国企合规 | Prompt 约定          | **专项 ComplianceAgent**（「三重一大」、国资监管、关联交易）                    |
| 刑事风险 | Prompt 覆盖          | **专项 CriminalAgent**（刑法第 165-169 条全覆盖）                      |
| 可移植性 | 依赖平台               | Python 可移植，支持本地运行 / FastAPI 部署 / Coze 集成                    |
| 可控性  | 模型自主控制             | 代码控制工作流，步骤可追溯、可调试                                           |

**Multi-Agent 架构**

| Agent           | 功能             | 专精场景                                |
| --------------- | -------------- | ----------------------------------- |
| RouterAgent     | 意图识别、案件分类、路由决策 | 自动判断案件类型（合同纠纷 / 国企合规 / 刑事风险 / 综合）   |
| ContractAgent   | 合同解析分析         | 合同体系化解释（五步法）、关键术语辨析、违约责任分析          |
| ComplianceAgent | 国企合规审查         | 「三重一大」决策程序、国资监管程序合规、关联交易审查、国有资产流失风险 |
| CriminalAgent   | 刑事风险评估         | 刑法第 165-169 条全覆盖、职务犯罪风险推演、管理人员责任分析  |

**RAG 知识库（ChromaDB + bge-m3）**

| 类别       | 数量  | 法规列表                                                |
| -------- | --- | --------------------------------------------------- |
| 法律       | 4 部 | 企业国有资产法、公司法（2023 修订）、行政处罚法、刑法（国企相关条款）               |
| 行政法规     | 2 部 | 企业国有资产交易监督管理办法（32 号令）、企业国有资产监督管理暂行条例                |
| 国资委规范性文件 | 4 部 | 「三重一大」决策制度意见、中央企业合规管理办法、国有企业参股管理暂行办法、企业国有资产评估管理暂行办法 |
| 司法解释     | 5 部 | 最高法公司法司法解释（一~五）                                     |

**工作流**：案件分类 → RAG 知识库检索 → 联网实时检索 → 6 条推理链深度分析（法律关系解构 → 合同体系化解释 → 国企特殊规则适用 → 法理深度分析 → 责任风险推演 → 合规建议）→ 格式化输出法律意见书。

---

## 搭载 / 部署方案

同一套智能体可以由不同的客户端或平台承载，Guncat 提供 6 种部署形态。

| 部署方案                   | 适用智能体                 | 形态                      | 说明                                           |
| ---------------------- | --------------------- | ----------------------- | -------------------------------------------- |
| **腾讯元器**               | Guncat 2.0 / 2.5 系列   | 平台托管                    | 平台适配提示词，可直接在腾讯元器创建智能体                        |
| **智谱清言**               | Guncat Srch / Cnvt 系列 | 平台托管                    | 平台适配提示词，部署于智谱清言平台                            |
| **Guncat AI-zhipu 网页** | 智谱清言对话客户端             | 浏览器 H5                  | 基于智谱免费 GLM API 的官方对话网页，开箱即用                  |
| **Guncat Web for API** | 通用提示词（不绑定平台）          | Web / Windows / Android | 「配置即智能体」架构，用户自选 OpenAI 兼容 API                |
| **Coze 服务**            | Guncat 2.5-Pro        | 云端 API                  | Python 智能体部署为 Coze API 服务对外提供能力              |
| **HarmonyOS 鸿蒙应用**     | Web for API 通用提示词     | 鸿蒙原生 App                | 基于 Web for API 二次包装，鸿蒙端 rawfile 预加载 + 资源拦截优化 |

### 1. 腾讯元器

- 在腾讯元器平台广场直接搜索Guncat 即可体验

### 2. 智谱清言

- 在智谱清言官方网站/APP智能体中心直接搜索Guncat即可体验

### 3. Guncat AI-zhipu 网页（智谱清言对话客户端）

- 位于 [Guncat AI Release/Guncat AI-zhipu_glm_version](./Guncat%20AI%20Release/)。
- 纯前端 HTML，直接浏览器打开 `guncat-app.html`。
- 接入智谱清言免费 GLM API（API Key 在页面设置中填写）。
- 适合：智谱清言用户的零依赖试用。

### 4. Guncat Web for API

- 「配置即智能体」架构：智能体列表由 `agents.json` 定义，提示词以外部 `.md` 文件存储。
- 用户自选 OpenAI 兼容 API（OpenAI、Azure、智谱、通义千问、DeepSeek 等）。
- 适合：跨平台统一入口、用户自有 API 灵活部署。

#### Windows 本地http服务版本

已包含构建好的bat文件，直接点击即可启动本地http服务使用

#### HarmonyOS 鸿蒙应用版本

* 基于 Web for API 开发的 HarmonyOS H5 原生应用。
* rawfile 内置 `agents.json`、全部 `.md` 提示词与头像，避免 Netlify 国内访问不稳导致的加载失败。
* 优化项：预连接 DNS/TCP、本地资源拦截替换、异步渲染、缓存策略。
* 适合：鸿蒙设备的原生 App 体验。

### 5. Coze 服务（Guncat 2.5-Pro）

- 将 Guncat 2.5-Pro Python 项目部署到 Coze 平台，对外提供 Coze API。
- 支持 OpenAI 兼容的 `/v1/chat/completions` 接口。
- 适合：将 2.5-Pro 作为后端服务集成到其他应用。

---

## 项目结构

本项目已完成重构，**智能体系列**与**部署方案**职责清晰分离：

| 模块                                                                                | 类别       | 说明                                            |
| --------------------------------------------------------------------------------- | -------- | --------------------------------------------- |
| [Guncat AI Release](./Guncat%20AI%20Release/)                                     | 智能体 + 部署 | 腾讯元器、智谱清言等平台适配提示词 + 智谱清言网页客户端                 |
| [Guncat AI Python](./Guncat%20AI%20Python/)                                       | 智能体      | Guncat 2.5-Pro 与 Srch-Law V2 两个 Python 代码驱动项目 |
| [Guncat AI Web for API](./Guncat%20AI%20Web%20for%20API/)                         | 部署       | 通用提示词 Web 客户端，自主配置 API                        |
| [Guncat AI Web for API_local-setup](./Guncat%20AI%20Web%20for%20API_local-setup/) | 部署       | Web 客户端的 Windows 一键本地启动版                      |
| [GuncatAI-Web-for-API_HMOS-APP](./GuncatAI-Web-for-API_HMOS-APP/)                 | 部署       | HarmonyOS 鸿蒙原生应用                              |

---

## 快速开始

| 你想做什么               | 进入目录                                                                              |
| ------------------- | --------------------------------------------------------------------------------- |
| 在腾讯元器 / 智谱清言部署智能体   | [Guncat AI Release](./Guncat%20AI%20Release/)                                     |
| 运行 Python 版智能体或二次开发 | [Guncat AI Python](./Guncat%20AI%20Python/)                                       |
| 在浏览器中使用自己的 API Key  | [Guncat AI Web for API](./Guncat%20AI%20Web%20for%20API/)                         |
| Windows 一键本地启动      | [Guncat AI Web for API_local-setup](./Guncat%20AI%20Web%20for%20API_local-setup/) |
| 在鸿蒙设备上安装使用          | [GuncatAI-Web-for-API_HMOS-APP](./GuncatAI-Web-for-API_HMOS-APP/)                 |

---

## 许可证

MIT License

Copyright (c) 2026 Zhu Bowen
