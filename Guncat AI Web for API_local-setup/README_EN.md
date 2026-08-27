# Guncat AI Web for API - Local Setup (Windows)

> [中文](README.md) | English

> Configurable API Chat Client - Windows Local Launch Version

---

Web for API Version: 5.2.1

2026.8.26 Deep-thinking toggle now explicitly controls the request per protocol (aligned with the official DeepSeek parameters): OpenAI Completions `thinking.type = enabled/disabled` + `reasoning_effort = high`; Anthropic Messages `thinking.type = enabled/disabled` + `output_config.effort = high`; OpenAI Responses `reasoning.effort = high/none` (`none` disables thinking); when web search is enabled, the previous assistant's `reasoning_content` is sent back in multi-turn turns to avoid 400 errors. New conversations reset the deep-thinking default by agent name: off in Efficiency Mode (3.0-Flash), off in Light & Simple Mode (3.0-Mini), on in Expert Mode (3.0-Pro)
2026.8.27 Version bumped to **5.2.1**: added **Guncat 3.0-Mini (Light & Simple Mode)** and placed it first in the agent list (in `agents.json`, 3.0-Mini comes before 3.0-Flash) — a small all-purpose agent further streamlined from 3.0-Flash. The core change is removing the Output Richness Principle in favor of the **Task-Adaptive Output Principle**: answer length is decided by task complexity and user needs — light conversation is naturally concise, standard tasks are medium-length, and complex tasks are fully elaborated, fitting the task without padding; it fully retains 3.0-Flash's three-layers-in-one architecture, Fast/Standard two-tier modes, tool-calling methodology, and anti-hallucination system
2026.8.26 Agent system upgrade: added **Guncat 3.0-Flash (Efficiency Mode)** and **Guncat 3.0-Pro (Expert Mode)** (3.0-series monolithic super-agent foundation); 2.5-Lite renamed to "Classic Mode"; domain experts unified under the "Conversion Expert / Search Expert / Evaluation Expert - Domain" naming scheme; removed the 2.0-series prompt files; sidebar agents now support per-agent icons (`icon` field in `agents.json`, PNGs stored in the `icons/` directory named by agent id, falling back to the default cat avatar when not configured); descriptions split into `description` (full version shown on the new-conversation page) and `shortDescription` (short version shown in the sidebar)
2026.8.24 Synced with HarmonyOS app 5.1.1: today's date is automatically prepended to the system prompt (fetched at runtime from the local date, auto-updates across days), applied uniformly across all three protocols — OpenAI Completions / OpenAI Responses / Anthropic Messages
2026.8.23 Synced with HarmonyOS app 5.1.0: new deep-thinking (reasoning) display (incremental parsing for OpenAI Completions / OpenAI Responses / Anthropic Messages, collapsed by default with tap-to-expand, live token speed and cache hit rate shown on the reasoning bar); the settings panel no longer shows the quick-select access-method presets — the protocol is chosen via the Access Method dropdown instead
2026.8.23 Synced with HarmonyOS app 5.0.0: access methods unified into three mainstream protocols (OpenAI Completions / OpenAI Responses / Anthropic Messages) with automatic migration of legacy configs; DeepSeek upgraded to the Responses API (native web search, direct image upload, Files API `file_id` hybrid upload); table extraction page now dynamically lists main models and multimodal models from all API profiles, with DeepSeek vision output compatibility; updated app icon assets (file names unchanged); brand-new soft modern UI (low-saturation palette, large corner radii, white lightweight 3D buttons, soft shadows), model switcher menu items unified in width and centered
2026.8.8 Added table extraction tool: recognize table images into HTML/Excel (preserving merged cells and row heights).
2026.8.6 Aligned with HarmonyOS app: multiple API profiles (custom model switching), direct file upload to Volcano, auto-read (TTS), voice input.
2026.7.7 Fixed bugs with duplicate message input and errors after terminating conversations.

---

Guncat AI Web for API is a **custom configuration client solution** for the Guncat agent framework, adopting the "Configuration as Agent" design philosophy: all agent information is configured via `agents.json`, and prompts are stored as external `.md` files.

Due to cross-origin restrictions, the `file://` protocol cannot read external JSON files. Therefore, this Windows local launch version includes a `.bat` file that can be clicked to start an HTTP service, making it easy for beginners to use out of the box.

### Core Design Philosophy

* **Configuration as Agent**: Instead of hardcoding prompts into client code, agents are defined via `agents.json`, with the `promptFile` field pointing to external `.md` prompt files
* **Externalized Prompts**: All prompts are stored as Markdown files in the client directory, facilitating independent updates, version management, and hot-replacement
* **Configurable API**: Users can choose any OpenAI API-compatible LLM service (e.g., OpenAI, Azure, ZhipuAI, Tongyi Qianwen, DeepSeek, etc.); the client only handles UI and conversation management
* **H5 Cross-Platform Coverage**: Built with HTML, directly deployable as H5 applications across multiple platforms

### Project Structure

    Guncat AI Web for API
    ├── agents.json                     # Agent list configuration
    ├── index.html                      # Web entry point
    ├── table-ocr.html                  # Table extraction tool (image → HTML/Excel)
    ├── cat-avatar(1).png               # Application icon
    ├── icons/                          # Sidebar agent icons (PNGs named by agent id)
    ├── Guncat 2.5-lite _prompt.md
    ├── Guncat 2.5-max _prompt.md
    ├── Guncat 3.0-Flash_prompt_ZH_CN.md # Chinese version
    ├── Guncat 3.0-Flash_prompt_EN.md    # English version
    ├── Guncat 3.0-Mini_prompt_ZH_CN.md  # Chinese version
    ├── Guncat 3.0-Mini_prompt_EN.md     # English version
    ├── Guncat 3.0-Pro_prompt_ZH_CN.md   # Chinese version
    ├── Guncat 3.0-Pro_prompt_EN.md      # English version
    ├── Guncat Cnvt-Paper_prompt.md
    ├── Guncat Srch-Law V1.0-prompt.md
    ├── Guncat Srch-Research-prompt.md
    ├── Guncat Srch-Sift-prompt.md
    └── Guncat Eval-LLM_prompt.md

### agents.json Configuration Example

    {
      "agents": [
        {
          "id": "guncat-3.0-flash",
          "name": "效率模式",
          "description": "Guncat 3.0-Flash：专家级轻量全能智能体，融合多轮搜索、多步推理与行业领先的反幻觉体系，缺口驱动执行带来极速响应",
          "shortDescription": "Guncat 3.0-Flash「新」",
          "icon": "icons/guncat-3.0-flash.png",
          "category": "通用智能体",
          "promptFile": "Guncat 3.0-Flash_prompt_EN.md"
        }
      ]
    }

Each agent configuration includes:

* `id`: Unique identifier
* `name`: Display name
* `description`: Functional description (full version shown on the new-conversation welcome page)
* `shortDescription`: Short description (shown in the sidebar list; falls back to `description` when not configured)
* `icon`: Path to the per-agent sidebar icon (a PNG under the `icons/` directory, square, ≥128×128 recommended; falls back to the cat avatar when not configured)
* `category`: Classification (General Agent / Search Agent / Rewriting Agent / Evaluation Agent)
* `promptFile`: Path to the corresponding prompt file

### Core Features

* **Agent Switching**: Switch between different Guncat agents via the sidebar drawer (3.0 series: Efficiency Mode / Light & Simple Mode / Expert Mode, 2.5 Classic Mode, Conversion / Search / Evaluation domain experts), each agent with a configurable icon and dual descriptions
* **Markdown Rendering**: Full Markdown syntax support including code highlighting, tables, lists, blockquotes, etc.
* **Streaming Output**: Typewriter-effect streaming display for AI responses
* **Deep Thinking / Web Search Toggles**: UI switches for manually enabling or disabling deep thinking, web search, and other features; new conversations reset the deep-thinking default by agent name (off in Efficiency Mode, off in Light & Simple Mode, on in Expert Mode)
* **API Profiles (Custom Model Switching)**: Save multiple named API configuration profiles (each with its own main model and multimodal settings), switch anytime via the model selector pill above the input or the settings panel; legacy single config auto-migrates to a default profile
* **Direct Attachment Upload**: Multimodal parsing supports both "pre-parse" and "direct upload" modes; in direct mode, images and documents are sent as-is to the main model of the current access method (supported by all three protocols), following the HarmonyOS 5.1.0 hybrid strategy: small images are inlined as Base64, large images (>4MB) / OpenAI Responses documents are automatically uploaded via the Files API and referenced by `file_id`, with automatic Base64 fallback when upload fails
* **Auto-Read (TTS)**: Auto-read replies when enabled, or tap the "Read" button under any AI message; supports pause and speed control (browser TTS)
* **Voice Input**: Mic button next to the input box for speech-to-text (browser speech recognition; Chrome/Edge engines)
* **New Conversation**: Supports clearing context to start a new conversation session
* **Conversation History**: Supports saving and viewing historical conversations
* **File Parsing**: Supports configuring specialized multimodal APIs to parse files and images that pure text models cannot handle
* **API Configuration**: Users can configure their API Key, Base URL, and model name in the UI. Access methods are unified into three mainstream protocols (aligned with HarmonyOS 5.1.0): `openai-completions` (/chat/completions), `openai-responses` (/responses, compatible with DeepSeek / Volcano Ark services), and `anthropic-messages` (/messages, compatible with the DeepSeek Anthropic endpoint); legacy provider configs (custom/deepseek/volcano) migrate automatically. Deep thinking is explicitly controlled per protocol (OpenAI Completions `thinking.type` + `reasoning_effort`, OpenAI Responses `reasoning.effort` with `none` disabling thinking, Anthropic Messages `thinking.type` + `output_config.effort`), and web search sends protocol-appropriate tool definitions; custom advanced parameters (length control, Top P, etc.) and custom JSON request bodies are supported
* **Table Extraction**: "Table Extraction" tool entry in the sidebar; uses vision LLMs to recognize table images into editable HTML tables and export Excel (.xlsx), faithfully preserving merged cells (rowspan/colspan), blank writing row heights, and in-cell line breaks; supports multiple views (rendered preview / HTML code / grid structure / debug info). The model dropdown dynamically lists main models and multimodal models from all API profiles (deduplicated), and recognition uses the selected model's own Base URL / API Key without re-entering keys; DeepSeek vision output is handled gracefully (thinking mode auto-disabled, full-width angle bracket normalization, truncated-table fallback)

### How to Add a New Agent

1. Save the new agent's prompt as a `.md` file and place it in the client directory
2. Add a new object in `agents.json` with `id`, `name`, `description`, `category`, and `promptFile` (optional: a `shortDescription`, and an `icon` — place a PNG in the `icons/` directory named after the agent id)
3. Restart the client or refresh the browser page, and the new agent will appear in the sidebar

### Maintenance: per-agent deep-thinking default

When a new conversation starts (or an empty conversation opens), the client resets the deep-thinking toggle by agent **name**. Configuration lives in `index.html`:

- The `AGENT_THINKING_DEFAULT_BY_NAME` map: key = agent `name`, value = boolean (`false` = off by default, `true` = on by default)
- Current defaults: Efficiency Mode `false`, Light & Simple Mode `false`, Expert Mode `true`; agents not in the map leave the toggle untouched (keeps the previous state)
- To adjust: edit the value for an existing agent name, or add a new line for a new agent. Matching is by name (not `id`), so future renames are safe.

### Tech Stack

* **Frontend**: Pure HTML/CSS/JavaScript, no framework dependencies
* **Rendering**: Marked.js (Markdown rendering) + Highlight.js (code highlighting), with LaTeX formula rendering support (after version 2.0.0)
* **Mobile**: WebView wrapped as Android APK
* **API Protocol**: Three protocols since 5.0.0 — OpenAI `/chat/completions`, OpenAI `/responses`, and Anthropic `/messages`
