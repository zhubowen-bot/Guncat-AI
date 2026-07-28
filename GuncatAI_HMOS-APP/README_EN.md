# Guncat AI

> [中文](README.md) | English

**Native HarmonyOS AI Chat Client** — Built entirely with ArkTS + ArkUI, not a WebView wrapper.

Most AI clients on the market are essentially browser wrappers. Guncat AI is built from the ground up on HarmonyOS native capabilities — from UI framework to network communication to Markdown rendering — delivering fundamental differences in performance, interaction smoothness, and system integration depth.

## Key Highlights

### Native ArkTS Streaming Chat Interaction

- **SSE Streaming Communication**: Native SSE parsing based on `@kit.NetworkKit`'s `http.requestInStream`, with token-by-token incremental updates — not WebSocket or polling
- **Dual Protocol Compatibility**: Supports both OpenAI Chat Completions (`/chat/completions`) and Anthropic/Volcengine Responses API (`/responses`), compatible with Deepseek, Volcengine Ark, and other providers
- **50ms Throttled Refresh**: 50ms throttle strategy + 33ms UI visible text buffer alignment during streaming, avoiding full-block rendering on every token
- **100ms Auto-Scroll**: Timer ensures message list stays at bottom during streaming output, matching WebChat experience

### Advanced Native Markdown Rendering

Using `@luvi/lv-markdown-in` native component (not WebView-embedded HTML), supporting:

- **Full CommonMark + GFM Standard**: Complete Markdown syntax including headings, lists, blockquotes, code blocks, tables, etc.
- **LaTeX Math Formulas**: Supports `$...$` / `$$...$$`, automatic text color switching for dark/light modes
- **Code Syntax Highlighting**: 19 token types with fine-grained coloring, independent warm/high-saturation schemes for dark/light modes
- **Mermaid Diagrams**: Supports flowcharts, sequence diagrams, Gantt charts, and other visualizations
- **Streaming Incremental Rendering**: Version 3.3+ optimization for table/code block/plugin flickering during streaming
- **Tables**: Header coloring, alternating row colors, rounded borders
- **Task Lists**: Todo List support
- **Full UI Style Programmable Control**: Heading colors, blockquote colors and rounded corners, hyperlink underlines, list bullet colors, inline code colors, etc.

### Multi-Agent System

8 built-in specialized agents, managed via `resources/rawfile/agents.json` + independent Markdown prompt files:

| Agent | Category | Description |
|-------|----------|-------------|
| Guncat 2.0-Flash | General | Flagship version balancing speed and quality |
| Guncat 2.0-Pro | General | High-quality results through iterative reasoning |
| Guncat 2.5-Lite | General | Structured thinking chain & two-tier reasoning modes |
| Guncat 2.5-Max | General | Structured thinking chain & three-tier reasoning modes |
| Guncat Cnvt-Paper | Paper Rewriting | Transforms non-academic text into academically compliant papers |
| Guncat Srch-Law | Legal Search | SOE legal analysis expert with mandatory multi-turn search & structured legal opinions |
| Guncat Srch-Research | Academic Search | Cross-domain information retrieval with multi-source cross-validation |
| Guncat Srch-Sift | AI Information Filtering | Official source tracing & AI content filtering |

### Multimodal File Parsing

After uploading images or documents, parsed via GLM-4.6V-Flash (ZhipuAI API) multimodal API, supporting:

- **Images**: PNG/JPEG/WebP/GIF
- **Text Documents**: TXT/MD/JSON/TS/JSX/TSX/HTML/CSS/CSV/LOG/YAML and various programming languages
- **Office Documents**: PDF/DOC/DOCX/XLS/XLSX/PPT/PPTX

**Smart Parsing Features**:

- Auto-retry on parsing failure (up to 4 times, 800ms interval)
- 200ms staggered parsing between files to avoid concurrent rate limiting
- Image preview and document content extraction support
- Real-time parsing status display (parsing/ready/failed)

### Native Theme System

Complete Light/Dark theme based on HarmonyOS resource framework, not CSS variable simulation:

- Uses `dark/element/color.json` + `base/element/color.json` resource qualifiers
- `EntryAbility` listens for system theme switches via `onConfigurationUpdate` callback
- Propagates `systemColorMode` state to all components via `AppStorage`
- Status bar/navigation bar colors auto-adapt to theme
- Markdown code theme and math formula colors sync with theme switching

### Smart Persistence System

Based on `@kit.ArkData` Preferences API (analogous to Web's localStorage):

- Conversation history and configuration serialized as JSON for storage
- Auto-saves current conversation state and agent selection
- Supports multi-conversation management and switching
- Configuration persisted locally, auto-restored on app restart

## Project Structure

```
entry/src/main/ets/
├── pages/
│   └── ChatPage.ets           # Main page: message list + Header + input area + drawer
├── views/
│   ├── ChatBubbleView.ets     # Chat bubble (user/assistant)
│   ├── RichTextView.ets       # Native Markdown rendering wrapper
│   ├── MessageInputView.ets   # Message input bar
│   ├── AgentDrawerView.ets    # Agent/conversation sidebar drawer
│   ├── SettingsPanel.ets      # API configuration panel
│   ├── ImageLightbox.ets      # Image lightbox
│   ├── FilePreviewBar.ets     # File preview bar
│   ├── ToastView.ets          # Toast notification
│   └── AboutPanel.ets         # About panel
├── viewmodel/
│   └── ChatViewModel.ts       # Core state management (MVVM layer)
├── service/
│   ├── ChatService.ts         # SSE streaming network requests
│   ├── MultimodalService.ts   # Multimodal file parsing
│   ├── FileService.ts         # File selection and reading
│   └── AgentLoader.ts         # Agent configuration loading
├── model/
│   ├── Message.ts             # Message model (@Observed)
│   ├── Conversation.ts        # Conversation model
│   ├── Agent.ts               # Agent model
│   ├── ApiConfig.ts           # API configuration
│   ├── MultimodalConfig.ts    # Multimodal configuration
│   └── Attachment.ts          # Attachment model
├── data/
│   └── StorageManager.ts      # Preferences persistence layer
├── common/
│   ├── Types.ts               # Shared type definitions
│   ├── Utils.ts               # Utility functions
│   └── Constants.ts           # Global constants
└── components/
    └── ToggleSwitch.ets       # Toggle switch component
```

## Technical Architecture

MVVM-like architecture:

### Architecture Layers

- **Model** (`model/`): Pure data classes, `@Observed` decorator makes property changes trackable
- **ViewModel** (`viewmodel/ChatViewModel.ts`): Centralized state and business logic management, maintains an internal `version` counter to drive UI refresh
- **View** (`views/` + `pages/`): Stateless UI components, bound to VM data via `@Prop` / `@ObjectLink` / `@Link`

### Data Flow

```
ChatService (SSE) → ChatViewModel → @Observed Message.content → @ObjectLink ChatBubbleView → RichTextView (Native Markdown Rendering)
```

### Core Component Description

1. **ChatViewModel** - Core State Manager
   
   - Manages conversation list, agent selection, API configuration
   - Handles message sending, streaming responses, file parsing
   - Implements persistent storage and state restoration

2. **ChatService** - Network Communication Layer
   
   - Implements SSE streaming communication protocol
   - Supports Chat Completions and Responses API dual protocols
   - Handles connection management, error handling, interruption support

3. **MultimodalService** - Multimodal Parsing Service
   
   - Calls ZhipuAI GLM-4.6V-Flash API
   - Supports image, text, and Office document parsing
   - Implements retry mechanism and concurrency control

4. **StorageManager** - Persistence Layer
   
   - Implements local storage based on Preferences API
   - Manages conversation history, configuration information, agent state

## Build & Run

### Requirements

- **IDE**: DevEco Studio 5.0+
- **HarmonyOS SDK**: API 12+
- **System Version**: HarmonyOS 5.0+
- **Device**: Physical device or emulator

### Build Steps

```bash
# 1. Clone the project
git clone <repository-url>

# 2. Open the project root directory in DevEco Studio

# 3. Ensure HarmonyOS SDK API 12+ is installed

# 4. Connect a physical device or start an emulator

# 5. Click Run or use command line:
hvigorw assembleHap

# 6. Install to device
hvigorw installHap
```

### Configuration

#### API Configuration

Configure the following parameters in the app settings:

1. **Provider**: Select `deepseek`, `volcano`, or `custom`
2. **Base URL**: API endpoint address
3. **API Key**: Valid API key
4. **Model**: Model name to use

#### Preset Configurations

- **Deepseek Preset**:
  
  - Base URL: `https://api.deepseek.com`
  - Model: `deepseek-chat`

- **Volcengine Ark Preset**:
  
  - Base URL: `https://ark.cn-beijing.volces.com/api/v3`
  - Model: Fill in based on actual usage

#### Multimodal Configuration

- **Base URL**: `https://open.bigmodel.cn/api/paas/v4` (default)
- **Model**: `glm-4.6v-flash` (default)
- **API Key**: ZhipuAI API key

## Dependencies

### Core Dependencies

- `@luvi/lv-markdown-in: ^3.4.5` — Native Markdown rendering component
- HarmonyOS API 12+ (`@kit.NetworkKit`, `@kit.ArkData`, `@kit.BasicServicesKit`, `@kit.CoreFileKit`)

### System Capabilities

- **Network Communication**: HTTP/HTTPS requests, SSE streaming
- **Data Storage**: Preferences API local persistence
- **File Management**: File selection, reading, Base64 encoding
- **UI Components**: ArkUI declarative UI, animations, theme adaptation

## Usage Guide

### Basic Usage Flow

1. **Launch App**: Default agent is automatically loaded on first launch
2. **Configure API**: Click the settings button in the top-right corner to configure API key
3. **Select Agent**: Click the menu button in the top-left corner to select an appropriate agent
4. **Start Chatting**: Enter your question in the input box and click send

### Advanced Features

#### 1. File Upload & Parsing

- Click the attachment button on the left side of the input box
- Select image or document files
- Wait for parsing to complete (status shows "ready")
- File content is automatically attached to the message

#### 2. Deep Thinking Mode

- When enabled, AI performs deeper reasoning
- Suitable for complex problem analysis and academic research

#### 3. Web Search

- Only supported by Volcengine Ark Provider
- When enabled, AI can search for the latest information

#### 4. Conversation Management

- **New Conversation**: Click "New Conversation" in the drawer
- **Switch Conversation**: Select historical conversations in the drawer
- **Delete Conversation**: Long press or right-click to delete

#### 5. Message Actions

- **Copy Text**: Long press message to copy
- **Regenerate**: Click the regenerate button on assistant messages
- **Image Preview**: Click image messages for full-screen preview

### Quick Actions

- **Auto-Scroll**: Automatically scrolls to bottom during streaming
- **Theme Switching**: Follows system dark/light mode
- **Config Persistence**: All settings are auto-saved

## FAQ

### 1. Invalid API Key?

- Check if the API key is correctly copied, watching for leading/trailing spaces
- Confirm if the API key has expired or credits are exhausted
- Check if the network connection is stable

### 2. File Parsing Failure?

- Check if file size exceeds the 20MB limit
- Confirm if the file format is supported
- Check if multimodal API configuration is correct
- The app auto-retries; wait and try again

### 3. Streaming Output Stuttering?

- Check network connection stability
- Try switching to different API Providers
- Disable deep thinking mode to reduce computation load

### 4. How to Update?

- Rebuild and install the HAP package
- Conversation history and configuration are automatically preserved

### 5. Supported Devices?

- Supports HarmonyOS 5.0+ phones and tablets
- Requires sufficient storage (recommended 100MB+)

## Security & Privacy

- **Local Storage**: All data stored locally on device
- **API Keys**: Only used for AI service calls, never uploaded to other servers
- **File Processing**: Files processed locally on device, original files not persistently stored
- **Network Communication**: Uses HTTPS encrypted transmission

## Version History

### Version 4 (Current)

- Brand new native ArkTS architecture
- Multi-agent system support
- Multimodal file parsing
- Native Markdown rendering
- HarmonyOS TTS control support, auto-read aloud (v 4.1.0)
- HarmonyOS speech recognition control support, voice input (v 4.1.0)
- Multi-config save and free config switching (v 4.1.0)
- Multimodal model Response API image/file direct upload (v 4.1.0)

## Contributing

Issues and Pull Requests are welcome!

### Development Setup

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add some amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Create a Pull Request

### Code Standards

- Follow ArkTS coding conventions
- Use meaningful variable and function names
- Add necessary comments
- Ensure code passes type checking

---

**Guncat AI** — Making AI conversations more native, smoother, and smarter!
