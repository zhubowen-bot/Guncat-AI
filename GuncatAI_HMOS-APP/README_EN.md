# Guncat AI

> [中文](README.md) | English

Guncat AI is a native HarmonyOS AI chat client built with ArkTS and ArkUI. Its primary interface is not hosted in a WebView.

Current app version: `5.0.0`

## Features

### Native streaming chat

- Processes SSE streams with `@kit.NetworkKit` and `http.requestInStream`.
- Supports three mainstream integration modes: OpenAI Completions (`/chat/completions`), OpenAI Responses (`/responses`, including DeepSeek and Volcengine Ark compatible services), and Anthropic Messages (`/messages`).
- All three integration modes support direct image input; OpenAI Responses additionally uses a hybrid Files API strategy for large images/documents.
- DeepSeek now uses the latest Responses API with native web search and vision-model image input.
- Supports stopping generation, regenerating responses, conversation history, and multiple API profiles.
- Uses throttled UI updates and automatic scrolling during streaming.

### Deep thinking and web search

- The deep-thinking toggle explicitly controls OpenAI Responses requests:
  - Volcengine Ark: `thinking.type = enabled / disabled`
  - DeepSeek / OpenAI Responses: sends `reasoning.effort = high` when enabled
- The visible toggle takes precedence over extra request-body fields, preventing UI/request mismatches.
- OpenAI Responses profiles (DeepSeek / Volcengine Ark) can use the native Web Search tool.
- OpenAI Completions / Anthropic Messages also send their corresponding web-search tool; whether it works depends on provider support.
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
- Attachments can be pre-parsed or sent directly as multimodal OpenAI Responses / Anthropic Messages input.
- OpenAI Responses attachments use a hybrid strategy: small images are inlined as Base64, while large images and Volcengine Ark documents prefer Files API `file_id` uploads.
- Parsing includes status feedback, retries, and concurrency throttling.
- Image attachments render as auto-generated 256px thumbnails; tap to view the full image, keeping memory usage low.

### Quick camera capture

- A camera button sits right of the microphone, launching the system CameraPicker (no camera permission required).
- The captured photo joins the pending attachments and goes through the same parsing pipeline.

### Export to Word

- Export any AI reply to a `.docx` file and choose the destination through the system save panel.
- Faithfully restores the Markdown structure: headings, bold/italic/strikethrough, tables (borders and shaded headers), code blocks, quotes, ordered/unordered lists, links, and embedded images.
- LaTeX formulas become native Word formulas (OMML) that remain editable in Word.
- Images from data URLs or network URLs are auto-scaled to the page width.

### Partial text selection

- A "Select part" action enables cross-paragraph text selection with a long press.
- The selection toolbar provides copy / select-all / cancel, writing the selection to the clipboard.

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

### UI and motion (5.0.0)

- A refreshed, soft modern UI: low-saturation palette, large rounded corners, white soft-elevated buttons, gentle shadows, and no heavy outlines or glow effects.
- Launch fly-in animation: icons fly out from the center in sequence, staying sharp throughout with no blur fade or cross-fade flicker.
- One-shot central icon transition: the launch icon uses a single hero node to smoothly move and scale into the empty-state icon at the page center, avoiding "white flash then clear" artifacts.
- The bottom input area slides in from below the screen edge with no bounce or unnatural top-down drop.
- Side drawers, settings sheets, and about overlays naturally cover the underlying hero icon instead of leaving it floating above overlays.

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

1. Integration mode (`openai-completions` / `openai-responses` / `anthropic-messages`)
2. Base URL
3. API Key
4. Model
5. Optional temperature, Top P, and maximum output tokens
6. Extra request-body fields

Common compatible endpoints:

- DeepSeek Responses: `https://api.deepseek.com`
- DeepSeek Anthropic: `https://api.deepseek.com/anthropic`, or simply `https://api.deepseek.com` (the app appends `/anthropic/v1/messages` automatically)
- Volcengine Ark Responses: `https://ark.cn-beijing.volces.com/api/v3`
- Anthropic Messages: `https://api.anthropic.com/v1`

Multimodal pre-parsing has a separate model, endpoint, and API key configuration.

## Usage guide

### Basic chat

1. Open Settings after the first launch.
2. Create or select an API profile and enter the integration mode, Base URL, API key, and model.
3. Select an agent from the drawer.
4. Enter and send a message.

### Adding images or files

1. Tap the attachment button beside the editor.
2. Select content from the photo or document picker.
3. Wait for pre-parsing; when pre-parsing is disabled, attachments are passed directly to a compatible multimodal endpoint.
4. Review pending attachments and explicitly tap Send.

You can also select content in Gallery or a file manager and choose Guncat AI from the system share sheet. The app only stages the items as attachments and does not submit a request automatically.

#### Attachment strategy

- OpenAI Completions: small images are inlined with `image_url`; large images are uploaded through the Files API and referenced as `file` + `file_id`; documents use `file_url`.
- Anthropic Messages: small images are inlined as base64 `image` content blocks; large images are uploaded through the Files API and referenced as `source.type = file` + `file_id`; documents are sent as `document` blocks.
- OpenAI Responses:
  - Small images (≤4MB): sent inline as Base64.
  - Large images (>4MB): uploaded through the Files API and referenced as `input_image.file_id`.
  - Documents: uploaded through the Files API and referenced as `input_file.file_id`, or inlined with `input_file.file_data`.
  - If an upload fails, the app automatically falls back to Base64.
- If a provider does not support a particular image/document block, the server returns an error; the app displays it instead of silently dropping the attachment.

### Deep thinking

- Volcengine Ark: off sends `thinking: { "type": "disabled" }`, on sends `thinking: { "type": "enabled" }`.
- DeepSeek / OpenAI Responses: when enabled, sends `reasoning: { "effort": "high" }`.
- This applies to compatible OpenAI Responses API models.

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

## Version 5.0.0

- Unified API integration into three mainstream protocols: OpenAI Completions, OpenAI Responses, and Anthropic Messages; removed standalone DeepSeek / Volcengine Ark presets with automatic migration for old configs.
- Upgraded DeepSeek to the latest Responses API, including native web search, vision-model image input, and hybrid Files API `file_id` uploads.
- Added Anthropic Messages support, compatible with the DeepSeek Anthropic endpoint (`https://api.deepseek.com/anthropic`), including image input and web search.
- Table recognition now lists all main and multimodal models from every API profile (deduplicated) for direct selection; improved DeepSeek vision output handling (thinking disabled, full-width angle bracket normalization, Markdown table fallback).
- Improved the model-switch menu: equal item widths, centered text, rounded corners, and a softer shadow.
- Improved the drawer shadow: a fixed full-screen scrim keeps the right side shaded during the slide, and tapping the blank area closes the drawer.

## Version 4.4.0

- New table recognition: a "Table Recognition" entry in the answer action bar opens a dedicated page that converts tables in images to HTML via a multimodal model, preserving merged cells (rowspan/colspan), headers and reserved writing-line heights.
- New Excel export: recognized tables can be exported as `.xlsx` via the system save panel; the native parsing/export engine mirrors the Web version and requires no upload.
- Split table-recognition credentials: the Zhipu option references the multimodal parsing-engine config, while the Volcano Ark (Doubao) option references the native-multimodal main-model config; the two platforms keep independent API keys.
- Auto new conversation on launch: reopening the app creates a new conversation automatically; if the agent's latest conversation is still empty it is reused instead, so no duplicate empty conversations are created.

## Version 4.3.1

- Fixed a crash when rendering Markdown tables: the @luvi/lv-markdown-in rendering library threw an uncaught exception while iterating undefined data for structurally broken tables (empty header cells, header/separator column-count mismatch, header-only tables, or a message truncated at the table), killing the process; re-rendering saved history on cold start always reproduced it.
- Added pre-render table normalization: structurally valid tables are padded to a consistent column count with closed pipes and preserved alignment; unrepairable degenerate tables degrade to plain text without losing content.
- Normalization touches table blocks only; code fences, lists, blockquotes and other Markdown syntax are unaffected.

## Version 4.3.0

- Added one-tap Word export: AI replies export to `.docx` with headings, bold/italic, tables, code blocks, quotes, lists, links, and embedded images; LaTeX formulas convert to native Word formulas (OMML).
- Added quick camera capture: a camera button next to the microphone launches the system CameraPicker (no camera permission required).
- Added partial text selection: the "Select part" action enables long-press cross-paragraph text selection and copying.
- Fixed the white screen when swiping up to review history during streaming: auto-scroll pauses while touching and resumes on release.
- Fixed an intermittent out-of-memory crash with large image attachments: persistence now strips oversized image bytes and attachments render as 256px thumbnails.
- Tidied the input bar: the microphone and camera buttons are compact and vertically aligned.

## Version 4.2.1

- Added the Guncat Eval-LLM evaluation agent: LLM evaluation intelligence analysis based on a 12-step workflow and eight anti-hallucination mechanisms.

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
- Confirm that model, integration mode, and Base URL match.
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
