# Guncat AI

> [中文](README.md) | English

Guncat AI is a native HarmonyOS AI chat client built with ArkTS and ArkUI. Its primary interface is not hosted in a WebView.

Current app version: `4.2.0`

## Features

### Native streaming chat

- Processes SSE streams with `@kit.NetworkKit` and `http.requestInStream`.
- Supports OpenAI Chat Completions (`/chat/completions`) and the Volcengine Ark Responses API (`/responses`).
- Works with DeepSeek, Volcengine Ark, and compatible custom endpoints.
- Supports stopping generation, regenerating responses, conversation history, and multiple API profiles.
- Uses throttled UI updates and automatic scrolling during streaming.

### Deep thinking and web search

- The deep-thinking toggle explicitly controls Volcengine Ark requests:
  - Off: `thinking.type = disabled`
  - On: `thinking.type = enabled`
- The visible toggle takes precedence over extra request-body fields, preventing UI/request mismatches.
- Volcengine Ark profiles can use the Web Search tool.
- Deep-thinking and web-search preferences persist across app restarts.

### Native Markdown

Rendered with the native `@luvi/lv-markdown-in` component, with support for:

- CommonMark and commonly used GFM syntax
- Code blocks and syntax highlighting
- Tables, task lists, blockquotes, and links
- Inline and block LaTeX
- Mermaid flowcharts, sequence diagrams, and other diagrams
- Automatic light/dark theme adaptation

### Image and file attachments

- Adds attachments through the system photo picker or document picker.
- Supports image previews, text extraction, Office documents, and PDFs.
- Attachments can be pre-parsed or sent directly as multimodal Responses API input.
- Parsing includes status feedback, retries, and concurrency throttling.

### Receiving system shares

The app is registered as a HarmonyOS system share target:

- Receives images, text, and general files, up to five items at a time.
- Guncat AI can be selected from the Gallery or file manager share sheet.
- Shared items are added to the current chat's pending attachment area and are never sent automatically.
- Uses Share Kit UTD matching and `systemShare.getSharedData()` for reception.

### CoreSpeechKit read-aloud

The final read-aloud implementation uses HarmonyOS CoreSpeechKit `textToSpeech`. Experimental local VITS, MeloTTS, and sherpa-onnx implementations are not included.

- Queries the voices actually supported by the device and exposes them in the reader controls.
- Prefers a female voice by default and uses a default speed of `1.5×`.
- Persists the selected voice and speed with Preferences.
- Provides pause/resume, close, speed selection, and draggable progress.
- The floating reader control can be repositioned within the page.
- Uses AVSession, an audio playback continuous task, and background TTS parameters for background and screen-off playback.
- After completion, the reader remains available for seeking and replay.

> Voice availability and download requirements depend on the device and system version.

### Voice input

- Uses the native HarmonyOS speech recognition capability.
- Supports starting, stopping, and cancelling voice input.
- Recognition results are placed in the message editor for confirmation before sending.

### Agents and persistence

- Includes general-purpose, paper-writing, legal-search, academic-research, and evaluation agents.
- Conversations, selected agent, API profiles, feature toggles, and reader preferences are stored locally.
- Supports creating, switching, and deleting conversations.
- Follows the system light/dark theme, including system bars and Markdown styles.

## Built-in agents

Agents are managed through `resources/rawfile/agents.json` and separate Markdown prompt files:

| Agent | Category | Purpose |
| --- | --- | --- |
| Guncat 2.0-Flash | General | General-purpose agent balancing speed and quality |
| Guncat 2.0-Pro | General | High-quality analysis and complex tasks |
| Guncat 2.5-Lite | General | Structured thinking with lightweight reasoning |
| Guncat 2.5-Max | General | More complete structured, multi-stage reasoning |
| Guncat Cnvt-Paper | Paper rewriting | Converts ordinary text into academic prose |
| Guncat Srch-Law | Legal search | Multi-step legal research and structured opinions |
| Guncat Srch-Research | Academic search | Cross-domain research with source cross-validation |
| Guncat Srch-Sift | AI information filtering | Official-source tracing and AI information filtering |
| Guncat Eval-LLM | Model evaluation | LLM evaluation intelligence analysis based on a 12-step workflow and eight anti-hallucination mechanisms |

## Persistence and themes

The app uses `@kit.ArkData` Preferences:

- Conversation history and settings are serialized as JSON.
- The current conversation, selected agent, and multiple API profiles are saved automatically.
- Deep thinking, web search, reader voice, and reader speed are persisted.
- Local state is restored when the app restarts.

The theme system uses HarmonyOS resource qualifiers:

- `base/element/color.json` provides light resources.
- `dark/element/color.json` provides dark resources.
- `EntryAbility.onConfigurationUpdate()` observes system theme changes.
- System bars, Markdown, syntax highlighting, and formula colors update together.

## Project structure

```text
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets
├── pages/
│   └── ChatPage.ets
├── views/
│   ├── ChatBubbleView.ets
│   ├── RichTextView.ets
│   ├── MessageInputView.ets
│   ├── AgentDrawerView.ets
│   ├── SettingsPanel.ets
│   ├── FilePreviewBar.ets
│   └── ImageLightbox.ets
├── viewmodel/
│   └── ChatViewModel.ts
├── service/
│   ├── ChatService.ts
│   ├── MultimodalService.ts
│   ├── FileService.ts
│   ├── TextReaderService.ets
│   ├── BackgroundReaderService.ets
│   └── VoiceInputService.ets
├── data/
│   └── StorageManager.ts
├── model/
└── common/
```

The project follows an MVVM-like separation:

- View: ArkUI pages and components.
- ViewModel: chat, attachment, configuration, and persistence state.
- Service: SSE, file parsing, system sharing, TTS, and ASR.
- Model: messages, conversations, attachments, agents, and API profiles.

### Data flow

```text
ChatService (SSE)
  → ChatViewModel
  → @Observed Message
  → @ObjectLink ChatBubbleView
  → RichTextView
```

### Core components

1. **ChatViewModel**
   - Manages conversations, agent selection, API profiles, and editor state.
   - Handles sending, streaming responses, attachment parsing, and regeneration.
   - Coordinates persistence and state restoration.

2. **ChatService**
   - Implements SSE streaming and request cancellation.
   - Supports Chat Completions and Responses API.
   - Parses response deltas and handles network/server errors.

3. **MultimodalService**
   - Processes images, text, PDFs, and Office documents.
   - Supports pre-parsing, retries, and concurrency control.
   - Supports direct Responses API image/file input.

4. **StorageManager**
   - Wraps Preferences storage.
   - Persists conversations, profiles, toggles, and reader preferences.

5. **TextReaderService / BackgroundReaderService**
   - Discovers and manages CoreSpeechKit voices.
   - Controls reading, pause, seeking, and speed.
   - Uses AVSession and a continuous task for background audio.

## Build requirements

- DevEco Studio 6.0.1 or a compatible version
- HarmonyOS SDK API 24 (`6.1.1`)
- A HarmonyOS phone

Open the project in DevEco Studio, configure signing, and run the `entry` module. Example command-line build:

```bash
hvigorw --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap
```

### Build steps

1. Clone or download the project.
2. Open the `GuncatAI` directory in DevEco Studio.
3. Install and select HarmonyOS SDK API 24.
4. Configure debug or release signing.
5. Connect a HarmonyOS device.
6. Run the `entry` module or build the HAP with the command above.

## Configuration

Multiple API profiles can be saved and switched in the app:

1. Provider
2. Base URL
3. API Key
4. Model
5. Optional temperature, Top P, and maximum output tokens
6. Extra request-body fields

Default Volcengine Ark endpoint:

```text
https://ark.cn-beijing.volces.com/api/v3
```

Multimodal pre-parsing has a separate model, endpoint, and API key configuration.

## Usage guide

### Basic chat

1. Open Settings after the first launch.
2. Create or select an API profile and enter the provider, Base URL, API key, and model.
3. Select an agent from the drawer.
4. Enter and send a message.

### Adding images or files

1. Tap the attachment button beside the editor.
2. Select content from the photo or document picker.
3. Wait for pre-parsing; when pre-parsing is disabled, attachments are passed directly to a compatible multimodal endpoint.
4. Review pending attachments and explicitly tap Send.

You can also select content in Gallery or a file manager and choose Guncat AI from the system share sheet. The app only stages the items as attachments and does not submit a request automatically.

### Deep thinking

- Off explicitly sends `thinking: { "type": "disabled" }`.
- On explicitly sends `thinking: { "type": "enabled" }`.
- This applies to compatible Volcengine Ark Responses API models.

### Read-aloud

1. Tap the read-aloud action on an assistant message.
2. Pause/resume, change speed, or select a voice from the floating control.
3. Drag the progress control to continue from the corresponding text position.
4. Drag an empty area of the control to reposition it.
5. Tap Close to end reading and dismiss the control.

### Conversation and message actions

- Create, switch, and delete conversations from the drawer.
- Copy assistant message content.
- Regenerate an assistant response.
- Tap images for full-screen preview.
- Stop the active request while it is generating.

## Permissions and system capabilities

- `ohos.permission.INTERNET`: model API access.
- `ohos.permission.MICROPHONE`: voice input.
- `ohos.permission.KEEP_BACKGROUND_RUNNING`: continuous background audio for read-aloud.
- Share Kit: receiving images and files from other apps.
- CoreSpeechKit: text-to-speech and speech recognition.
- AVSession Kit: background media session.
- ArkData Preferences: local configuration and conversation persistence.

## Privacy

- API keys and app settings are stored in the app's local sandbox.
- Chats and attachments are sent only to model services configured by the user.
- Items received from the system share sheet are never sent automatically; the user must tap Send.
- Original attachments are not copied into permanent app storage.
- Requests use HTTPS. Data-processing policies still depend on the configured model provider.

## Version 4.2.0

- Expanded CoreSpeechKit read-aloud with voice discovery and selection, a preferred female voice, `1.5×` default speed, and persistent preferences.
- Added a movable reader control with pause/resume, close, speed controls, and seeking.
- Added AVSession and an audio playback continuous task for background and screen-off reading.
- Added HarmonyOS system share reception so images and files can be placed directly in pending attachments.
- Corrected Volcengine Ark deep-thinking semantics: Off sends `disabled`; On sends `enabled`.
- Retained native voice input, multiple API profiles, and Responses API multimodal passthrough.

## FAQ

### Invalid API key

- Check for leading or trailing whitespace.
- Confirm that model, provider, and Base URL match.
- Check account balance, API access, and network connectivity.

### File parsing failed

- Confirm that the format and size are supported by the model endpoint.
- Verify the multimodal configuration.
- Disable pre-parsing and use a Responses API model that accepts attachments directly.

### Streaming response stopped

- Check network stability and server rate-limit messages.
- Try another API profile.
- Disable deep thinking for simple tasks to reduce response latency.

### Guncat AI is missing from the Gallery share sheet

- Confirm that the latest HAP with Share Kit UTD declarations is installed.
- Reopen the Gallery share sheet after updating so the system refreshes share targets.

### Background reading stops

- Ensure notifications and background activity are not restricted for the app.
- Background policy and available system voices vary by device.

## Contributing

Issues and Pull Requests are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Follow ArkTS coding conventions.
4. Ensure the project passes type checks and HAP compilation.
5. Open a Pull Request describing the change and verification performed.

## Note

This release does not include local TTS model approaches that were evaluated or prototyped and later reverted. The README describes only functionality present in the current codebase.
