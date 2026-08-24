# Guncat AI Web for API - Local Setup (Windows)

> [中文](README.md) | English

> Configurable API Chat Client - Windows Local Launch Version

---

Web for API Version: 5.1.1

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
    ├── Guncat 2.0-flash-main_agent_prompt.md
    ├── Guncat 2.0-pro-main_agent_prompt .md
    ├── Guncat 2.5-lite _prompt.md
    ├── Guncat 2.5-max _prompt.md
    ├── Guncat Cnvt-Paper_prompt.md
    ├── Guncat Srch-Law V1.0-prompt.md
    ├── Guncat Srch-Research-prompt.md
    ├── Guncat Srch-Sift-prompt.md
    └── Guncat Eval-LLM_prompt.md

### agents.json Configuration Example

    {
      "agents": [
        {
          "id": "guncat-2.5-max",
          "name": "Guncat 2.5-Max",
          "description": "The most powerful version in the Guncat 2.5 general agent series, with structured thinking chain & three-tier reasoning modes",
          "category": "General Agent",
          "promptFile": "Guncat 2.5-max _prompt.md"
        },
        {
          "id": "guncat-cnvt-paper",
          "name": "Guncat Cnvt-Paper",
          "description": "Paper conversion expert, transforms non-academic text into academically compliant papers",
          "category": "Rewriting Agent",
          "promptFile": "Guncat Cnvt-Paper_prompt.md"
        }
      ]
    }

Each agent configuration includes:

* `id`: Unique identifier
* `name`: Display name
* `description`: Functional description
* `category`: Classification (General Agent / Search Agent / Rewriting Agent / Evaluation Agent)
* `promptFile`: Path to the corresponding prompt file

### Core Features

* **Agent Switching**: Switch between different Guncat agents via the sidebar drawer (2.0/2.5 General Agents, Srch Search Agents, Cnvt Rewriting Agents, Eval Evaluation Agents)
* **Markdown Rendering**: Full Markdown syntax support including code highlighting, tables, lists, blockquotes, etc.
* **Streaming Output**: Typewriter-effect streaming display for AI responses
* **Deep Thinking / Web Search Toggles**: UI switches for manually enabling or disabling deep thinking, web search, and other features
* **API Profiles (Custom Model Switching)**: Save multiple named API configuration profiles (each with its own main model and multimodal settings), switch anytime via the model selector pill above the input or the settings panel; legacy single config auto-migrates to a default profile
* **Direct Attachment Upload**: Multimodal parsing supports both "pre-parse" and "direct upload" modes; in direct mode, images and documents are sent as-is to the main model of the current access method (supported by all three protocols), following the HarmonyOS 5.1.0 hybrid strategy: small images are inlined as Base64, large images (>4MB) / OpenAI Responses documents are automatically uploaded via the Files API and referenced by `file_id`, with automatic Base64 fallback when upload fails
* **Auto-Read (TTS)**: Auto-read replies when enabled, or tap the "Read" button under any AI message; supports pause and speed control (browser TTS)
* **Voice Input**: Mic button next to the input box for speech-to-text (browser speech recognition; Chrome/Edge engines)
* **New Conversation**: Supports clearing context to start a new conversation session
* **Conversation History**: Supports saving and viewing historical conversations
* **File Parsing**: Supports configuring specialized multimodal APIs to parse files and images that pure text models cannot handle
* **API Configuration**: Users can configure their API Key, Base URL, and model name in the UI. Access methods are unified into three mainstream protocols (aligned with HarmonyOS 5.1.0): `openai-completions` (/chat/completions), `openai-responses` (/responses, compatible with DeepSeek / Volcano Ark services), and `anthropic-messages` (/messages, compatible with the DeepSeek Anthropic endpoint); legacy provider configs (custom/deepseek/volcano) migrate automatically. Deep thinking is explicitly controlled per protocol (Volcano `thinking.enabled/disabled`, OpenAI Responses `reasoning.effort=high`), and web search sends protocol-appropriate tool definitions; custom advanced parameters (length control, Top P, etc.) and custom JSON request bodies are supported
* **Table Extraction**: "Table Extraction" tool entry in the sidebar; uses vision LLMs to recognize table images into editable HTML tables and export Excel (.xlsx), faithfully preserving merged cells (rowspan/colspan), blank writing row heights, and in-cell line breaks; supports multiple views (rendered preview / HTML code / grid structure / debug info). The model dropdown dynamically lists main models and multimodal models from all API profiles (deduplicated), and recognition uses the selected model's own Base URL / API Key without re-entering keys; DeepSeek vision output is handled gracefully (thinking mode auto-disabled, full-width angle bracket normalization, truncated-table fallback)

### How to Add a New Agent

1. Save the new agent's prompt as a `.md` file and place it in the `Guncat API version/` directory
2. Add a new object in `agents.json` with `id`, `name`, `description`, `category`, and `promptFile`
3. Restart the client or refresh the browser page, and the new agent will appear in the sidebar

### Tech Stack

* **Frontend**: Pure HTML/CSS/JavaScript, no framework dependencies
* **Rendering**: Marked.js (Markdown rendering) + Highlight.js (code highlighting), with LaTeX formula rendering support (after version 2.0.0)
* **Mobile**: WebView wrapped as Android APK
* **API Protocol**: Three protocols since 5.0.0 — OpenAI `/chat/completions`, OpenAI `/responses`, and Anthropic `/messages`
