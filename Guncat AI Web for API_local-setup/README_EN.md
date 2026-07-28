# Guncat AI Web for API - Local Setup (Windows)

> [中文](README.md) | English

> Configurable API Chat Client - Windows Local Launch Version

---

Web for API Version: 3.1.0

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
    ├── cat-avatar(1).png               # Application icon
    ├── Guncat 2.0-flash-main_agent_prompt.md
    ├── Guncat 2.0-pro-main_agent_prompt .md
    ├── Guncat 2.5-lite _prompt.md
    ├── Guncat 2.5-max _prompt.md
    ├── Guncat Cnvt-Paper_prompt.md
    ├── Guncat Srch-Law V1.0-prompt.md
    ├── Guncat Srch-Research-prompt.md
    └── Guncat Srch-Sift-prompt.md

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
* `category`: Classification (General Agent / Search Agent / Rewriting Agent)
* `promptFile`: Path to the corresponding prompt file

### Core Features

* **Agent Switching**: Switch between different Guncat agents via the sidebar drawer (2.0/2.5 General Agents, Srch Search Agents, Cnvt Rewriting Agents)
* **Markdown Rendering**: Full Markdown syntax support including code highlighting, tables, lists, blockquotes, etc.
* **Streaming Output**: Typewriter-effect streaming display for AI responses
* **Deep Thinking / Web Search Toggles**: UI switches for manually enabling or disabling deep thinking, web search, and other features
* **New Conversation**: Supports clearing context to start a new conversation session
* **Conversation History**: Supports saving and viewing historical conversations
* **File Parsing**: Supports configuring specialized multimodal APIs to parse files and images that pure text models cannot handle
* **API Configuration**: Users can configure their API Key, Base URL, and model name in the UI, supporting both Chat API and Response API configuration methods, custom advanced model parameters (length control, Top P, etc.), and custom JSON request bodies

### How to Add a New Agent

1. Save the new agent's prompt as a `.md` file and place it in the `Guncat API version/` directory
2. Add a new object in `agents.json` with `id`, `name`, `description`, `category`, and `promptFile`
3. Restart the client or refresh the browser page, and the new agent will appear in the sidebar

### Tech Stack

* **Frontend**: Pure HTML/CSS/JavaScript, no framework dependencies
* **Rendering**: Marked.js (Markdown rendering) + Highlight.js (code highlighting), with LaTeX formula rendering support (after version 2.0.0)
* **Mobile**: WebView wrapped as Android APK
* **API Protocol**: OpenAI-compatible `/v1/chat/completions` endpoint
