# Guncat Work

> [中文](README.md) | English

Guncat Work is a native HarmonyOS AI chat client built with ArkTS and ArkUI. Its primary interface is not hosted in a WebView.

Current app version: `6.1.0`

## Features

### Native streaming chat

- Processes SSE streams with `@kit.NetworkKit` and `http.requestInStream`.
- Supports three mainstream integration modes: OpenAI Completions (`/chat/completions`), OpenAI Responses (`/responses`, including DeepSeek and Volcengine Ark compatible services), and Anthropic Messages (`/messages`).
- All three integration modes support direct image input; OpenAI Responses additionally uses a hybrid Files API strategy for large images/documents.
- DeepSeek now uses the latest Responses API with native web search and vision-model image input.
- Supports stopping generation, regenerating responses, conversation history, and multiple API profiles.
- Uses throttled UI updates and automatic scrolling during streaming.

### Deep thinking and web search

- The deep-thinking toggle explicitly controls the request per protocol (aligned with the official DeepSeek parameters):
  - OpenAI Completions: `thinking.type = enabled / disabled`, plus `reasoning_effort = high` when enabled
  - Anthropic Messages: `thinking.type = enabled / disabled`, plus `output_config.effort = high` when enabled
  - OpenAI Responses: `reasoning.effort = high / none` (`none` disables thinking)
- The visible toggle takes precedence over extra request-body fields, preventing UI/request mismatches.
- When web search is enabled, the previous assistant's `reasoning_content` is sent back in multi-turn turns (OpenAI Completions) to avoid 400 errors.
- OpenAI Completions / Anthropic Messages also send their corresponding web-search tool; whether it works depends on provider support.
- Deep-thinking and web-search preferences persist across app restarts; new conversations (including the one auto-created on every launch) reset the deep-thinking default by agent name — off in Efficiency Mode, off in Light & Simple Mode, on in Expert Mode.

### Maintenance: per-agent deep-thinking default

New conversations, app launches, and opening empty conversations reset the deep-thinking toggle by agent **name**. Configuration lives in `entry/src/main/ets/viewmodel/ChatViewModel.ets`:

- The `defaultThinkingForAgent()` method: returns a boolean by `agent.name` (`false` = off by default, `true` = on by default); returning `null` leaves the toggle untouched (keeps the previous state)
- Current defaults: Efficiency Mode `false`, Light & Simple Mode `false`, Expert Mode `true`
- To adjust: add or modify an `if (agent.name === '...') return ...;` branch in that method. Matching is by name (not `id`), so future renames are safe.

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
- Guncat Work can be selected from the Gallery or file manager share sheet.
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

### Work mode (Agent Loop)

Work mode is an **independent identity parallel to the chat agents** — the 🛠 "Work Mode" entry in its own "Agent Mode" group above the "Chat Mode" section header in the drawer. It opens an Agent loop with a per-conversation local sandbox workspace and tool-calling capability, allowing the agent to autonomously complete multi-step, long-horizon tasks. See "[Work mode architecture & maintenance guide](#work-mode-architecture--maintenance-guide)" below.

- **Sandbox workspace**: each work conversation maps to `filesDir/workspaces/<convId>/`, with upload, `.zip` export, and clear actions. Everything stays inside the app sandbox plus system safe components (document picker) — **no new permissions**.
- **36 local tools**: file CRUD (list/read/write/append/delete/create_dir/move/search, with `glob` filename filtering on search_files), task checklist (`todo_write`), image viewing (`view_image`, routed to the main model's multimodal vision), web download (`download_file`, pulls linked files into the workspace), PDF parsing (`parse_document` + automatic `read_file` routing), Office generation (`write_docx` / `write_xlsx` / `write_csv`), data pipeline (`transform_file`, local cleaning/transformation/conversion of large files without entering model context), PPT read/write/edit (`write_pptx` / `read_ppt` / `edit_ppt`, on a Deck JSON intermediate layer), SVG image generation (`write_svg`, vector output + PNG preview), and the skill system (`list_skills` / `load_skill`, on-demand domain guides). New in 6.1 (DeepSeek Harness port): `glob` / `grep` (pattern-based file lookup and regex content search), `edit` / `str_replace_editor` (exact character-level editing with a diff card), `web_fetch` (fetch page/API source as readable text), `ask_user_question` (ask the user and wait for an answer), `schedule_create/list/delete` (session-local reminders), `goal_create/get/update` (session goal), `subagent` (child-agent delegation), `session_search` (session event-log search).
- **Skill system**: domain operation guides are packaged under `rawfile/skills/<id>/` (SKILL.md + reference/*.md). The system prompt keeps only a one-line trigger (preserving the byte-stable KV-cache prefix); the model loads skills on demand via `list_skills`/`load_skill`. The bundled `ppt` skill covers the Deck JSON syntax, design guidelines, themes, and self-check lists; the `svg` skill covers SVG authoring rules, the "generate → preview → iterate" workflow, and recipes for icons/flowcharts/infographics.
- **Local parsing engine**: `.docx/.xlsx/.pptx/.pdf` text is extracted entirely on-device — no multimodal parsing API and no quota consumption.
- **Task checklist discipline**: complex tasks start with a `todo_write` checklist; checklist and workspace state reach the model through a "runtime context" snapshot appended to the tail of the conversation. Progress is updated item by item.
- **Codex-style timeline**: each turn is its own message, laid out chronologically as "thinking → tool steps → answer" inside a single-container timeline; tool steps expand to show arguments and results.
- **Three-protocol tool calling**: OpenAI Completions / OpenAI Responses / Anthropic Messages all support streaming function calling; the web-search toggle remains in the tool row (the server-side search tool coexists with client tools).

### UI and motion (5.1.0)

- Reworked the deep-thinking (reasoning) bar UI: it now renders as a standalone card above the bubble with uniform corner radii and a neutral light-gray background that blends with the chat area; the loading spinner sits directly to the right of the "Deep Thinking" label, and the separate "Thinking…" text was removed.
- Updated the app icon assets while keeping the original filenames, so existing resource references remain valid (just replace the image files to apply).
- A refreshed, soft modern UI: low-saturation palette, large rounded corners, white soft-elevated buttons, gentle shadows, and no heavy outlines or glow effects.
- Launch fly-in animation: icons fly out from the center in sequence, staying sharp throughout with no blur fade or cross-fade flicker.
- One-shot central icon transition: the launch icon uses a single hero node to smoothly move and scale into the empty-state icon at the page center, avoiding "white flash then clear" artifacts.
- The bottom input area slides in from below the screen edge with no bounce or unnatural top-down drop.
- Side drawers, settings sheets, and about overlays naturally cover the underlying hero icon instead of leaving it floating above overlays.

## Built-in agents

Agents are managed through `resources/rawfile/agents.json` and separate Markdown prompt files. The sidebar supports per-agent custom icons (`icon` field pointing to a PNG named by agent id under `icons/`, falling back to the cat avatar when unset) and dual descriptions: the sidebar shows `shortDescription`, while the new-conversation page shows the full `description`:

| Agent | Category | Purpose |
| --- | --- | --- |
| 轻简模式 (Light & Simple) | General | Guncat 3.0-Mini base: lighter and faster than Flash, task-adaptive output length — concise for simple chat, fully elaborated for complex tasks |
| 效率模式 (Efficiency) | General | Guncat 3.0-Flash base: gap-driven execution for instant responses, answer thoroughness on par with Pro |
| 专家模式 (Expert) | General | Guncat 3.0-Pro base: the most powerful monolithic super-agent with full expert capabilities and industry-leading anti-hallucination |
| 经典模式 (Classic) | General | Based on Guncat 2.5-Lite: mature lightweight general agent, structured CoT for high-quality long outputs |
| 转换专家-论文 | Rewriting | Based on Guncat Cnvt-Paper: converts non-academic text into academically compliant papers |
| 检索专家-法律 | Search | Based on Guncat Srch-Law: SOE legal analysis with mandatory multi-round research and structured opinions |
| 检索专家-研究 | Search | Based on Guncat Srch-Research: cross-domain retrieval with multi-source cross-validation |
| 检索专家-筛滤 | Search | Based on Guncat Srch-Sift: official-source tracing and AI content filtering |
| 评估专家-LLM | Evaluation | Based on Guncat Eval-LLM: LLM evaluation with minimized hallucination |

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
│   ├── ChatPage.ets                # Main page: chat + work-mode timeline + workspace panel wiring
│   └── TableOcrPage.ets
├── views/
│   ├── ChatBubbleView.ets          # Chat bubble (reasoning bar / tool-step timeline / WorkStepFormat)
│   ├── WorkTurnView.ets            # One work-mode turn (thinking→tools→answer, no avatar)
│   ├── WorkspaceBar.ets            # Work-mode workspace panel (list/upload/export/clear)
│   ├── RichTextView.ets
│   ├── MessageInputView.ets
│   ├── AgentDrawerView.ets
│   ├── SettingsPanel.ets
│   ├── AboutPanel.ets
│   ├── FlyInLaunchView.ets
│   ├── ToastView.ets
│   ├── FilePreviewBar.ets
│   └── ImageLightbox.ets
├── viewmodel/
│   └── ChatViewModel.ets           # Chat state + work-mode Agent Loop driver (note: .ets)
├── service/
│   ├── ChatService.ts              # Three-protocol SSE (parsers exported for AgentLoopService)
│   ├── AgentLoopService.ts         # Work mode: per-turn tool-calling request + system prompt (static, cache red line)
│   ├── WorkToolRunner.ets          # Unified tool dispatch (capabilities requiring .ets modules)
│   ├── WorkFileService.ts          # Sandbox workspace + file/skill tools + tool schemas (toolDefs)
│   ├── WorkSkillService.ts         # Skill registry (registry) + rawfile skill-doc loading (list/load)
│   ├── OfficeReader.ts             # Local docx/xlsx/pptx text extraction (zlib unpack + XML scan)
│   ├── PdfTextExtractor.ts         # Local PDF text extraction (byte-level objects/pages/ToUnicode)
│   ├── Flate.ts                    # Pure-TS DEFLATE/zlib inflate (SDK zlib is file-level only)
│   ├── MultimodalService.ts
│   ├── FileService.ts
│   ├── FileUploadService.ts
│   ├── AgentLoader.ts
│   ├── TableOcrService.ts
│   ├── TextReaderService.ets
│   ├── BackgroundReaderService.ets
│   └── VoiceInputService.ets
├── export/
│   ├── DocxExporter.ets            # Markdown→docx (includes buildDocxBytes for work mode)
│   ├── XlsxExporter.ets            # Table→xlsx (includes buildXlsxFromRows)
│   ├── CsvWriter.ts                # Rows→CSV (RFC 4180 escaping + optional BOM, pure logic)
│   ├── DeckModel.ets               # PPT intermediate layer: Deck JSON parse/validate/edit ops (pure logic, no Kit API)
│   ├── PptxThemes.ets              # 8 theme presets + semantic-color resolution (pure logic)
│   ├── PptxCharts.ets              # Chart part XML (bar/line/area/pie/doughnut, pure logic)
│   ├── PptxImage.ets               # Image resolution (workspace/data URL/http + dimension probing)
│   ├── PptxBuilder.ets             # Deck→pptx renderer (13 layouts / embedded deck source / notes)
│   ├── PptxImporter.ets            # pptx→Deck (lossless restore from embedded source / XML import)
│   ├── OoxmlBuilder.ets / MarkdownParser.ets / OmmlConverter.ets / TableHtmlParser.ets / XmlUtil.ets
│   └── ZipWriter.ts                # STORE-method zip writer (.ts: reusable from TS modules)
├── data/
│   └── StorageManager.ts
├── model/
│   ├── Message.ts / Conversation.ts / Attachment.ts / ToolCallRecord.ts
│   └── Agent.ts / ApiConfig.ts / ApiProfile.ts / MultimodalConfig.ts
└── common/
    ├── Constants.ts / Types.ts / Utils.ts / MarkdownSanitizer.ts

entry/src/main/resources/rawfile/
├── agents.json + *_prompt*.md      # Chat agent definitions and prompt files
└── skills/                         # Work-mode skills (loaded on demand via load_skill, see "3.2 Skill system")
    ├── ppt/
    │   ├── SKILL.md                # PPT skill body (workflows / quick reference / self-check list)
    │   └── reference/              # deck-dsl.md / design-guide.md / themes.md
    └── svg/
        ├── SKILL.md                # SVG image-generation skill (generate→preview→iterate workflow / self-check)
        └── reference/              # svg-craft.md / svg-recipes.md

test/
└── pptx-harness/                   # Offline verification harness for PPT/CSV (Node build + python-pptx checks + PNG review)
```

The project follows an MVVM-like separation:

- View: ArkUI pages and components.
- ViewModel: chat, attachment, configuration, work-mode loop, and persistence state.
- Service: SSE, Agent Loop, tool execution, local document parsing, system sharing, TTS, and ASR.
- Model: messages, conversations, attachments, tool-call records, agents, and API profiles.

> **File extension = dependency rule**: ArkTS forbids `.ts` files from importing `.ets` files (`.ets` may import `.ts`). Decide the extension before creating/moving a file based on dependency direction — capabilities referenced by `.ets` modules such as `ChatViewModel.ets` / `WorkToolRunner.ets` (e.g. Office generation, multimodal) must live in `.ets` files; pure logic (e.g. ZipWriter, PDF/Office parsing) can stay in `.ts` and be used from both sides.

### Data flow

```text
[Chat mode]
ChatService (SSE)
  → ChatViewModel
  → @Observed Message
  → @ObjectLink ChatBubbleView
  → RichTextView

[Work mode] per loop turn
User task → ChatViewModel.executeWorkLoop
  → AgentLoopService.runTurn (three-protocol SSE + streamed tool-call accumulation)
  → WorkToolRunner.execute → WorkFileService.executeTool
      → OfficeReader / PdfTextExtractor (reading)
      → DocxExporter / XlsxExporter (generation)
      → PptxBuilder / PptxImporter / PptxImage / DeckOps (PPT write/read/edit, see "3.1")
      → WorkSkillService (list_skills / load_skill, see "3.2")
  → Tool results written back to ToolCallRecord → injected into next request history
  → one @Observed Message per turn (thinking/tools/answer)
  → ChatPage.buildWorkTimeline → WorkTurnView
```

### Core components

1. **ChatViewModel**
   - Manages conversations, agent selection, API profiles, and editor state.
   - Handles sending, streaming responses, attachment parsing, and regeneration.
   - Coordinates persistence and state restoration.
   - Work mode: `executeWorkLoop` drives the Agent loop (one message per turn, tool execution, image injection, history trimming).

2. **ChatService**
   - Implements SSE streaming and request cancellation.
   - Supports Chat Completions and Responses API.
   - Parses response deltas and handles network/server errors.

3. **AgentLoopService / WorkToolRunner / WorkFileService / WorkSkillService (work-mode quartet)**
   - `AgentLoopService`: one LLM turn — three-protocol request bodies (tool definitions, image messages), streamed tool-call accumulation, and the work-mode system prompt.
   - `WorkToolRunner`: unified tool dispatch entry implementing capabilities that require `.ets` modules (write_docx/xlsx, write_pptx/read_ppt/edit_ppt, parse_document).
   - `WorkFileService`: all sandbox workspace file operations, file-tool implementations, tool schemas (`toolDefs()`), and workspace zip export.
   - `WorkSkillService`: the skill registry (`registry()`) and rawfile skill-doc loading for `list_skills`/`load_skill`.

4. **MultimodalService**
   - Processes images, text, PDFs, and Office documents.
   - Supports pre-parsing, retries, and concurrency control.
   - Supports direct Responses API image/file input.

5. **OfficeReader / PdfTextExtractor / Flate (local parsing engine)**
   - `OfficeReader`: unpacks OOXML and extracts `w:t`/`a:t`/`sharedStrings` text with tag-boundary checks.
   - `PdfTextExtractor`: byte-level object table + ObjStm expansion + page-tree resource inheritance + ToUnicode CMap + content-stream text.
   - `Flate`: pure-TS DEFLATE/zlib inflate (the SDK zlib only offers file-level APIs).

6. **StorageManager**
   - Wraps Preferences storage.
   - Persists conversations, profiles, toggles, and reader preferences.

7. **TextReaderService / BackgroundReaderService**
   - Discovers and manages CoreSpeechKit voices.
   - Controls reading, pause, seeking, and speed.
   - Uses AVSession and a continuous task for background audio.

## Work mode architecture & maintenance guide

Work mode is a standalone agent execution environment: a virtual agent + a per-conversation sandbox workspace + a multi-turn tool-calling loop. This section targets maintainers and covers module responsibilities, data flow, and extension recipes.

> **Maintenance doc map** (which doc to read for which change):
> - This section (README) — architecture, plus the design and extension recipes for the three systems: tools, skills, and the PPT pipeline.
> - `test/pptx-harness/README.md` — the offline verification harness for the PPT pipeline and CSV writer (Node build + python-pptx checks + PNG review). Mandatory after touching anything under `export/`.
> - `entry/src/main/resources/rawfile/skills/` — the **model-facing** operation guides (`ppt`: deck-dsl syntax / design guidelines / themes; `svg`: authoring rules / image-generation recipes). They evolve in lockstep with the tools and double as reusable assets portable to other agent frameworks.

### 1. Identity and conversation model

- **Virtual agent**: `Constants.WORK_AGENT_ID = 'work'`. Injected at the top of the agent list on launch by `ChatViewModel.buildWorkAgent()`; `AgentDrawerView` splits it into its own "Agent Mode" group above the "Chat Mode" section header, parallel to the chat agents, with a 🛠 badge (special case for `id === 'work'`).
- **Enter/exit**: tapping "Work Mode" in the drawer = `selectAgent('work')`; tapping any real agent exits (the tool-row Work Mode pill exits back to `lastChatAgentId`, the most recently used real agent).
- **Conversation binding**: `Conversation.mode = 'chat' | 'work'`; work conversations keep `agentId = 'work'`, migrated automatically for legacy data on launch. Deleting a work conversation also deletes its sandbox workspace directory.
- **Toggle differences**: entering work mode force-enables deep thinking (the toggle is hidden from the tool row); web search stays available (the server-side search tool is sent alongside client function tools); uploads and camera captures go into the workspace instead of chat attachments.
- **Persistence**: conversation JSON gains `mode` and `Message.toolCalls` (`ToolCallRecord[]` with arguments/results/duration — the timeline and the LLM history are restored from these after restart). Workspace files themselves live in the sandbox `filesDir`, not in Preferences.

### 2. Agent Loop (`ChatViewModel.executeWorkLoop`)

```text
for step in 1..WORK_MAX_STEPS(200, runaway safeguard):
  1. Create a new assistant message (this turn's thinking/tools/answer attach to it)
  2. Budget check: when over 850K tokens (1M×0.85, usage-anchored), prune oversized early
     tool results first, then compress older history into a state digest (model call only if pruning is not enough)
  3. Append the "runtime context" snapshot (date + file tree + task checklist) to the tail of
     the history (skipped when unchanged)
  4. AgentLoopService.runTurnWithRetry (three-protocol streaming request with tool definitions;
     429/5xx/network/empty responses retried with exponential backoff)
  5. No tool calls → this turn is the final answer, stop
  6. Tool calls → consecutive read-only calls run concurrently, the rest sequentially
     (WorkToolRunner); results written back into ToolCallRecord
     - Mutating tools refresh the workspace file panel
     - A successful view_image injects a multimodal user message (in-memory only)
  7. This turn (assistant + tool results) enters the request history; continue
```

- **One message per turn** is the foundation of the timeline UI: the message list is naturally the chronological "thinking→tools→answer" stream, instead of one big aggregated message.
- **Automatic context compaction (cache-aware, aligned with DeepSeek Harness)**: the budget is anchored to the previous request's real prompt tokens (usage-anchored) against `WORK_CONTEXT_WINDOW_TOKENS`×0.85 (1M×0.85 = 850K tokens), falling back to the session's measured chars→tokens ratio when usage data is absent. When over budget, a two-stage pipeline runs: first a model-free prune of oversized early tool results (head/tail excerpts with precise omission notices); if that is not enough, older history is summarized by the model into a compact "state digest" (≤2400 chars, keeping the most recent 12 messages verbatim) — the summarization request reuses the full prefix (static system prompt + tool definitions + history), so it is a continuation of the last real request for the model-side KV cache and the prefix is billed as cache hits. If the digest fails or the history is still over budget, the loop falls back to trimming oldest-first. If a request fails outright with a context-overflow error, the history is force-compacted and the request retried once. The task checklist and workspace files are never compacted and can always be re-read via `read_file` — this is what lets long tasks survive context limits. The timeline shows an "early history compacted" note.
- **Prefix-cache design**: the system prompt is fully static (built once, never rebuilt); date / file tree / task checklist travel in a "runtime context" snapshot user message appended to the tail of the history, and only when its content changes; history grows strictly append-only (compaction is the only operation that rewrites it) — consecutive requests therefore share a byte-identical prefix, the model-side KV cache hits across turns, and only a small tail needs recomputation after file writes.
- **Cancellation**: `stopStreaming()` calls both `ChatService.abort()` and `AgentLoopService.abort()`; an interrupted turn with no output is removed, otherwise a "⏹ Task stopped" note is appended.
- **Step safeguard**: `WORK_MAX_STEPS(200)` exists purely as a runaway guard (preventing endless tool-call loops from burning tokens); normal long tasks never reach it — when triggered, a "send 'continue' to proceed" note is appended to the last message.

### 3. Tool system (36 tools)

Dispatch chain: `ChatViewModel` → `WorkToolRunner.execute()` (.ets entry) → Office generation/parse_document/PPT/transform_file implemented locally, everything else delegated to `WorkFileService.executeTool()` (.ts); the 6.1 tools fall through to `HarnessTools.dispatch()` (.ts).

| Tool | Implementation | Notes |
| --- | --- | --- |
| `todo_write` | WorkFileService.toolTodoWrite | Writes `.todo.json`; accepts an array or an embedded JSON string |
| `list_files` | WorkFileService.toolList | Recursive listing, dirs first, with sizes |
| `read_file` | WorkFileService.toolRead | Plain text direct read; `.docx/.xlsx/.pptx`→OfficeReader, `.pdf`→PdfTextExtractor |
| `write_file` / `append_file` | WorkFileService.toolWrite | Overwrite/append text (512KB cap, parent dirs auto-created) |
| `delete_file` / `create_dir` / `move_file` | toolDelete / toolMkdir / toolMove | Recursive delete / mkdir / move (moveFileSync/moveDirSync) |
| `search_files` | WorkFileService.toolSearch | Case-insensitive substring search over text files, with line numbers; optional `glob` filename filter (`*`/`?`, comma-separated patterns), directories still recursed |
| `view_image` | WorkFileService.toolViewImage | Image→dataUrl (≤8MB); the loop injects it as the next multimodal message |
| `download_file` | WorkToolRunner.toolDownloadFile | Downloads an http(s) file into the workspace (≤20MB; type sniffing + html warning; auto or explicit naming) |
| `parse_document` | WorkToolRunner.toolParseDocument | Full PDF text (local, 3× output cap) |
| `write_docx` | toolWriteDocx → DocxExporter.buildDocxBytes | Markdown→Word |
| `write_xlsx` | toolWriteXlsx → XlsxExporter.buildXlsxFromRows | Markdown table/CSV/TSV→Excel |
| `write_csv` | toolWriteCsv → CsvWriter.buildCsvBytes | Markdown table/CSV/TSV→CSV (RFC 4180 escaping, UTF-8 BOM by default; input parsing goes through CsvParser, quoted fields handled correctly) |
| `transform_file` | WorkToolRunner.toolTransformFile → DataPipeline | **Local data pipeline** (data never enters model context): CSV/TSV/MD/JSON/JSONL/lines input; filter/derive/regex-extract/split/dedupe/sort plus CSV↔TSV↔JSON↔MD↔XLSX conversion; restricted DSL (whitelisted ops + expression evaluator, no I/O), preview before write; syntax via `load_skill("data")`; ≤2MB/100k rows/30 steps |
| `write_pptx` | toolWritePptx → PptxBuilder.buildPptxBytes | **Deck JSON / deck file / outline → PPT** (see the next section) |
| `read_ppt` | toolReadPpt → PptxImporter.import | .pptx → Deck JSON source (lossless restore for app-generated files, approximate import otherwise) |
| `edit_ppt` | toolEditPpt → PptxImporter + DeckOps + PptxBuilder | Restore → apply ops → rebuild (foreign files are backed up first) |
| `write_svg` | WorkToolRunner.toolWriteSvg → SvgUtil | SVG source → workspace .svg + rasterized PNG preview; xmlns/no-script validation, missing width/height auto-filled from viewBox (required by the device engine), precise diagnostics on decode failure |
| `list_skills` / `load_skill` | WorkFileService.dispatchTool → WorkSkillService | Skill list and on-demand skill-doc loading (the ppt, svg, and data skills under rawfile/skills/) |
| `glob` | HarnessTools.toolGlob → FileSearchCore | Find files by glob pattern (`**`/`*`/`?`/`{a,b}`/`[...]`; top-level commas don't break `{}` branches); returns relative paths with sizes (≤500) |
| `grep` | HarnessTools.toolGrep → FileSearchCore | Regex search over text files, returning `file:line: text` (≤200 hits; optional `glob` filename filter and `ignore_case`; invalid patterns fail with a clear error) |
| `edit` | HarnessTools.toolEdit → DiffUtil | Exact character-level replacement (multiple matches rejected; `replace_all` overrides); the result carries line-level diff hunks (meta persisted with the session, rendered as a diff card) |
| `str_replace_editor` | HarnessTools.toolEdit | view/create/str_replace/insert editor (view reuses read_file's line paging; insert adds lines after a given line) |
| `web_fetch` | HarnessTools.toolWebFetch → WebFetchService | GET ≤2MB page/API source; HTML stripped to readable text (script/style/comments removed, block tags → newlines, entities decoded); JSON/text returned as-is (truncation noted) |
| `ask_user_question` | HarnessTools.toolAskUser → AskUserBridge | Pauses execution for a user answer; the UI card supports single/multi select plus free text, submitted via one "Submit" button; unanswered for 5 minutes resolves as cancelled; loop abort resolves all pending asks |
| `schedule_create` / `schedule_list` / `schedule_delete` | HarnessTools → ScheduleService | Session-local reminders (persisted in `.schedule.json`; one-shot `after_seconds` or recurring `every_seconds`≥300s); when due, a user message wakes the loop (steered mid-task) |
| `goal_create` / `goal_get` / `goal_update` | HarnessTools → GoalService | Session goal (`.goal.json`) injected via the runtime snapshot; `bump_round` counts rounds, auto-pausing at the cap |
| `subagent` | HarnessTools → SubagentService (via the `WorkFileService.subagentHook`) | In-process child agent: shares the workspace, isolated context (toolset excludes subagent/ask_user/schedule/goal/todo_write), ≤40 steps, final report returned as the tool result |
| `session_search` | HarnessTools.toolSessionSearch → SessionLogService | Search the session event log (JSONL) to recover details lost to context compaction |

Path safety: every tool path passes through `resolveSafe()` — absolute paths, drive letters, and `..` traversal are rejected; operations stay inside `filesDir/workspaces/<convId>/`.

### 3.1 PPT pipeline (Deck JSON intermediate layer)

The design mirrors open-kimi-ppt-skill's PPTD philosophy: **the AI-editable intermediate layer is decoupled from the exporter**. The AI only ever faces the Deck JSON layer — "generate a PPT" = write a Deck → render; "edit a PPT" = restore the Deck → apply ops → rebuild. The exporter knows nothing about prompts, only about the Deck structure, so its behavior is fully deterministic and testable offline.

```text
write_pptx ──┐                                      ┌─ write_pptx (rebuild the pptx)
deck JSON ───┼→ PptxBuilder (renders 13 layouts) → .pptx │
             │    └─ embedded docProps/deck.json source  │
read_ppt  ───┤                                     └─ edit_ppt (DeckOps apply ops then rebuild)
             └─→ PptxImporter (lossless restore from embedded source / approximate XML import)
```

#### Module responsibilities & public API (entry/src/main/ets/export/)

| File | Responsibility | Key public members |
| --- | --- | --- |
| `DeckModel.ets` | Intermediate-layer model + JSON parsing/validation + edit ops (**pure logic, no Kit API**) | `Deck/DeckSlide/DeckBullet/DeckChart/DeckTable/DeckElement/DeckBackground`, `DeckParser.parse`, `DeckOutline.parse` (legacy outline compat), `DeckOps.apply`, `DECK_LAYOUTS`, `DECK_MAX_SLIDES` |
| `PptxThemes.ets` | 8 theme presets + semantic/hex color resolution (**pure logic**) | `PptxThemes.resolve` (Deck→ThemeColors), `resolveColor(colors, spec, fallback)` (primary/accent/bg/surface/title/body/sub/faint/onPrimary/white/dark/light or hex), `ThemeColors` |
| `PptxCharts.ets` | Chart part XML (bar/line/area/pie/doughnut, data embedded as numCache/strCache, **pure logic**) | `PptxCharts.buildXml(chart, colors)` |
| `PptxImage.ets` | Image reference resolution: workspace path / data URL / http(s), mime sniffing + PNG/JPEG/GIF/BMP dimension probing | `PptxImage.resolve(src, workspaceRoot)` → `PptxImagePart` |
| `PptxBuilder.ets` | Deck → pptx full-part rendering (two passes: resolve images/charts first, then render pages) | `PptxBuilder.buildPptxBytes(deck, resolveImage)`; also defines `PptxImagePart`/`ImageResolver` (types live here to avoid a PptxBuilder→PptxImage compile-time dependency) |
| `PptxImporter.ets` | pptx → Deck: reads the embedded `docProps/deck.json` first (lossless), otherwise parses slide XML into custom layouts (text/tables/image positions preserved, charts become placeholder notes) | `PptxImporter.import(absPath, cacheDir)` → `PptxImportResult{deck, embedded, slideCount}` |

**Dependency direction** (`.ts` must not import `.ets`): `DeckModel ← PptxThemes/PptxCharts/PptxBuilder`; `PptxBuilder ← WorkToolRunner.ets`; `PptxImage → WorkFileService.ts` (only `resolveSafe`, legal direction); no cycles. Draw this map before adding any new file.

**SVG auto-rasterization**: `WorkToolRunner.imageResolver` rasterizes `.svg` source files at 1024px width through the device image engine before they enter the render pipeline — outputs of `write_svg` can be referenced by `write_pptx` directly (together with the svg skill's authoring rules), no manual conversion needed.

#### Deck JSON contract (three places to sync on every field change)

The model-facing field documentation = **the ppt skill's `reference/deck-dsl.md`**. The authoritative implementation is `DeckModel.ets`. When changing any field, all three of the following must be updated, otherwise the model generates from stale docs and error rates rise:

1. `DeckModel.ets` (parsing + validation: `parseSlide`/`validateSlide` error messages must include the page number and state what is missing, so the AI can self-correct);
2. The skill docs `rawfile/skills/ppt/reference/deck-dsl.md` (field tables) and `SKILL.md` (quick-reference example);
3. `test/pptx-harness/test-build.mjs` (samples must cover the field, negative cases must cover the new validation).

Structure overview: top level `{title, theme, themeOverride{8 color slots}, slides[]}`; page cap `DECK_MAX_SLIDES(80)`; common page fields `{layout, title, subtitle, notes, background{color|image, fit, overlay}}`; the 13 layouts each have their own fields (bullets / columns / image / table / chart / elements / text/author / imageSide…); limits: table ≤20 rows, one image ≤10MB (`WORK_PPT_IMAGE_MAX_BYTES`), whole deck ≤40 images (`WORK_PPT_MAX_IMAGES`).

#### pptx parts & relationship numbering conventions (read before touching PptxBuilder)

- Per-slide rels: `rId1` is always the slideLayout; then rId2… are allocated **in media → chart order**; the rIds in `renderChart`/background images/`renderCustom` are **computed** from this rule (`'rId' + (2 + mediaParts.length)`) — keep the same algorithm when adding elements that consume relationships.
- Chart global numbering is allocated during the **first scan pass** (`ctx.chartNos`) and shared by `[Content_Types].xml` and slide rels — never re-count at render time.
- Notes pages `ppt/notesSlides/`: the notesMaster **always exists** (regardless of notes), which keeps presentation rels stable; each notesSlide's rels back-reference its owning slide number.
- The embedded source `docProps/deck.json` (Override application/json) is what makes `read_ppt`/`edit_ppt` lossless — rendering changes must not touch it; it is generated by `JSON.stringify(deck)` in the build pass.
- The notesSlide rels' `../slides/slideN.xml` back-reference must receive the correct page number (`notesSlideRelsXml(i + 1)`).

#### Dark-background auto lightening (contrast red line)

`isDarkBg(slide, colors)`: background image with `overlay ≥ 0.3`, or a resolved background color with luminance < 0.55 → dark surface. When it applies:

- **Page text** (titles/bullets/captions/page numbers) goes through `TextScheme` (computed once in `renderSlide`, passed to every layout renderer), lightened to FFFFFF / E2E8F0 / A9B6C6 / 7E8CA0;
- **Charts** use a `lightened(colors)` copy: axis labels, legend, and data labels lighten while the **series palette stays unchanged**;
- **Table cells** always use theme `bg`/`surface` fills + theme `body` text — fills follow the theme rather than the page background, so every theme × page-background combination stays readable (this once caused a rework; do not change it back to hardcoded FFFFFF).

When writing a new layout renderer, **always take text colors from `ts` (TextScheme), never from `colors`** — that is how the rule above is enforced.

#### Extension recipes

**Adding a layout** (4 places):
1. Register the name in `DeckModel.DECK_LAYOUTS` → add field parsing in `parseSlide` → add required-field validation in `validateSlide` (errors include the page number);
2. Add a switch branch in `PptxBuilder.renderSlide` → write `renderXxx(slide, …, ts, …)`: geometry constants go at the top of the file (EMU, 1pt = 12700), text uses `ts`, decoration uses `colors.primary/accent`;
3. Add a sample page to `fullDeck` in `test/pptx-harness/test-build.mjs` → run the full verification chain (below);
4. Sync the skill docs: the `deck-dsl.md` field table + the layout table in `SKILL.md`.

**Adding a theme**: add a branch in `PptxThemes.preset()` (primary/accent/bg/surface/title/body/sub/faint/onPrimary/dark + a 6-color `series` palette) → add a row to `themes.md`. Unknown theme names fall back to brand-blue (do not throw — the model will correct itself).

**Adding a chart type**: add a branch in `PptxCharts.buildXml`. Mind the OOXML `CT_*Ser` child order `idx→order→tx→spPr→marker→dLbls→cat→val`; `dLblPos` is only valid for bar/line/pie (not doughnut — do not add it there) → sync `deck-dsl.md`.

#### Verification loop (mandatory after touching the generator; commands in test/pptx-harness/README.md)

```bash
node setup.mjs && node test-build.mjs        # all-layout/multi-theme/edit-ops/negative builds → gen/out_*.pptx
python validate.py gen\out_all.pptx …        # zip CRC/all-part XML/relationship consistency/content-types/python-pptx
python deep-check.py                         # python-pptx chart data + embedded source round-trip
node check-setup.mjs && npx -y -p typescript@5.5.4 tsc -p check/tsconfig.json   # service-layer type check
```

Visual review (on machines with PowerPoint): export PNGs with `export-png.ps1` and inspect page by page — focus on text overflow, dark-page lightening, chart label readability, and table contrast (all three historical visual bugs were these categories).

### 3.2 Skill system (reusable domain operation guides)

A skill = an **id-organized, pure-Markdown domain operation guide** (no code) that the model loads on demand when a matching task arrives. The problem it solves: domain knowledge (Deck JSON syntax, design guidelines, …) must not go into the system prompt — the system prompt has to stay byte-stable (the KV-cache red line), while skill docs can be added, changed, and layered at any time **without touching a line of prompt code**.

#### Structure conventions

```text
entry/src/main/resources/rawfile/skills/
├── ppt/                        ← skill id (lowercase, unique; directory name = id)
│   ├── SKILL.md                ← skill body (required): when-to-use / toolchain / workflows / quick ref / self-check
│   └── reference/              ← deep-dive material, loaded file by file (optional)
│       ├── deck-dsl.md         # field-level syntax
│       ├── design-guide.md     # design guidelines
│       └── themes.md           # theme catalog
└── svg/                        ← built-in skill 2: SVG vector drawing (image generation)
    ├── SKILL.md                # "generate → preview → iterate" workflow + tool boundaries (photos via download_file)
    └── reference/
        ├── svg-craft.md        # authoring rules: xmlns/viewBox requirements, 24 grid, path-first, text risk, color discipline
        └── svg-recipes.md      # ready-to-use templates: stroke icons / flowcharts / architecture / infographic cards / cover decor
```

The registry lives in `WorkSkillService.registry()` (**the code is the registry, no config file**). Each `SkillInfo = { id, name, description, files: SkillFileInfo[] }`; `files` is the whitelist of files `load_skill` may read (`SKILL.md` is always allowed), guarding against path probing. **Unregistered skills are invisible to the model** — dropping docs into the directory without registering them does nothing.

#### Loading chain (progressive disclosure)

```text
System prompt "Skill system" section (a one-line trigger, static)
  → the model calls list_skills()            → WorkSkillService.listText()
      returns: id + name + trigger semantics + file index
  → the model calls load_skill("ppt")        → rawfile read of SKILL.md
  → the model calls load_skill("ppt", "reference/deck-dsl.md") → load deep-dive file by file
Dispatch: WorkFileService.dispatchTool() (pure TS, no .ets needed); both are registered in isReadOnlyTool() and may run concurrently.
Results follow the normal tool rules: over 12K chars they are truncated head+tail (WORK_SKILL_MAX_CHARS is the hard cap on the loading side).
```

#### SKILL.md writing conventions (reusable skeleton)

```markdown
---
name: <id>
description: <one-line trigger semantics, see below>
---
# <Skill name>

## When to use      ← trigger scenario list (the model decides whether to load from this)
## Toolchain        ← which tools, how to pass arguments, hard constraints such as image sources
## Workflow A/B     ← numbered steps per scenario, one action per step; include a minimal runnable example
## Quick reference  ← table/JSON samples (keep the most-used 20%; push the long tail into reference)
## Pre-delivery self-check list ← checkbox list the model runs before delivering
```

- Split `reference/` files by topic; **each file under 12K chars** (longer files get truncated in the middle — the lost middle makes them useless);
- Code examples must be **minimal samples that run as-is**, consistent with the current tool implementation;
- Length budget: keep SKILL.md at 4–6K chars and leave details to reference.

#### How to write the description (trigger semantics)

The description plays two roles: the expansion of the system-prompt trigger line and the display text in `list_skills`. Formula = **enumerate task keywords + name the tools involved + state "load first"**:

- ✅ `Load when creating/modifying/beautifying presentations (.pptx): the full Deck JSON syntax (13 layouts/charts/tables/images/notes), 8 themes, design guidelines, and the self-check list. Load before any write_pptx / read_ppt / edit_ppt task.`
- ❌ `PPT skill` (the model cannot tell when to load it — as good as unwritten)

#### Adding a new skill (docs + 1–2 code touch points)

1. Create `rawfile/skills/<id>/SKILL.md` (+ `reference/*.md` as needed) following the skeleton above;
2. Register the entry in `WorkSkillService.registry()`: id / name / description / files whitelist (every reference file must be registered, otherwise it cannot be loaded);
3. If proactive triggering is wanted, add a sentence to the "Skill system" section of `AgentLoopService.buildWorkSystemPrompt()` (appending lines does not break the static red line);
4. **No toolDefs/dispatchTool changes needed**: `list_skills`/`load_skill` are generic tools that automatically cover new skills;
5. Self-test: in work mode run `list_skills` → `load_skill` every file to confirm nothing is truncated → run a real matching task and check the model follows the skill.

#### Maintenance red lines & portability

- Skill docs **evolve in lockstep with the tools**: change a Deck field/tool parameter → sync the skill doc → then the system prompt (if affected);
- description wording = trigger behavior; treat changes seriously (flag them separately in commit messages);
- Skill docs are a **cross-agent reusable asset**: the frontmatter (name/description) deliberately follows the standard Agent Skills convention (same structure as open-kimi-ppt-skill's SKILL.md). Copy the whole directory into another agent framework's skills directory (e.g. `~/.claude/skills/<id>/`) and SKILL.md-aware frameworks will pick it up — no rewriting required.

### 4. Adding a new tool (5 places)

1. `WorkFileService.toolDefs()`: register the schema (name/description/parameters) — this is what the model sees; use `props0`/`props1`/`props2`/`props3` to build property maps.
2. `WorkFileService.dispatchTool()`: add the dispatch branch (for capabilities requiring `.ets` modules, dispatch from `WorkToolRunner.execute()` instead).
3. Implement the executor returning a `ToolExecResult` (`ok`/`output`; `imageDataUrl` is reserved for view-image-style tools).
4. `AgentLoopService.buildWorkSystemPrompt()`: document the tool and its discipline (stay byte-static; do not put large bodies of domain knowledge here — make it a skill, see 3.2).
5. If it mutates the workspace, register it in `WorkFileService.isMutatingTool()`; read-only tools go into `isReadOnlyTool()` (they may run concurrently).

> Content that "teaches the model how to use the new tool" (DSL syntax, format specs, workflows) should become a skill doc rather than being stuffed into the tool description or the system prompt — the description states the purpose in one line, and the details are fetched via `load_skill` on demand.

### 5. Local parsing engine and the memory/main-thread red lines

**Parsing chain**: `OfficeReader` (zlib.decompressFile unpacks OOXML → XML text-node extraction), `PdfTextExtractor` (byte-level object table → ObjStm sequential-value expansion → page-tree resource inheritance → ToUnicode CMap for CJK → content-stream `Tj/TJ` parsing → raw-stream fallback with diagnostics), `Flate` (pure-TS DEFLATE/zlib inflate).

Three red lines learned from production incidents:

1. **Never build large strings via per-character concatenation** (`s += x` loops are O(n²)) — this OOM'd the shared heap. Large fragments go through `bytesToString()`: bytes are copied into a UTF-16LE buffer and decoded natively with `util.TextDecoder`; `arrayBufferToBase64` likewise generates bytes numerically and decodes natively.
2. **Heavy CPU parsing must yield the main thread in stages** — a fallback scan over every stream (including font programs) once triggered a THREAD_BLOCK_6S appfreeze. `PdfTextExtractor` uses `yieldNow()` (setTimeout 0) after the object table, between pages, and between fallback streams.
3. **Every fragment conversion must be capped**: dict 64KB, ObjStm 2MB, CMap 1MB, content stream 4MB, single text decode 128KB, line buffer 100K chars, whole file 16MB — preventing pathological/malicious files from exhausting memory.

### 6. ArkTS constraints learned the hard way

- **`.ts` must not import `.ets`** (compile error 10605999). Draw the dependency direction before choosing an extension: `ChatViewModel.ets` needs Office generation/multimodal modules, so the ViewModel itself must be `.ets`; `WorkFileService.ts` can only depend on `.ts` (ZipWriter was therefore converted from .ets to .ts).
- **`.ets` forbids anonymous object literal types** (arkts-no-obj-literals-as-types). Use named classes for cross-module structures (`ParsedFileResult`, `ToolExecResult`).
- **Closures do not inherit null narrowing**: after `let conv: X | null` is null-checked, lambdas may still report "possibly null" — capture a non-null local (e.g. `let emptyConv: Conversation = conv`) before the closure.
- **The directory-listing API is `listFileSync`** (this SDK has no `readdirSync`); `mkdirSync(path, true)` creates directories recursively.
- **Imports must precede all other statements** (comments excepted).
- Rewriting source files through PowerShell pipes re-encodes UTF-8 as GBK and corrupts Chinese text — always edit source files with an editor, never shell redirection.

### 7. UI (Codex-style timeline)

- `ChatPage.buildWorkTimeline`: in work mode the whole conversation renders as a **single-container timeline** — a unique 🛠 "Work Mode" header (with execution status) followed by user task cards (brand-colored) and `WorkTurnView` entries in message order.
- `WorkTurnView` (`@ObjectLink Message`): CLI-style inline thinking row (`icon + label`, spinner/marquee while streaming, the label gains a static "· 持续了几秒" suffix once done, no fill) → CLI-style inline tool rows (`tool icon + short name · arg summary + status/duration`, no filled background; tap to expand arguments and results, the expanded block hangs off a thin left rule) → answer body (RichTextView); thinking/tool rows carry a 16vp horizontal inset so their width matches the body text; action buttons appear only on the final turn; a 33ms flush timer syncs text and step states during streaming.
- Chat mode keeps using `ChatBubbleView` (its thinking bar uses the same fill-free inline style); the two render paths do not interfere.
- `WorkspaceBar`: workspace popup (file list + upload/export zip/delete); file rows map the extension to a category icon (`sys.symbol`: image/table/slides/PDF/archive/code/audio/video etc.), unknown types fall back to a generic doc icon.

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
2. Open the `GuncatAI_HMOS-APP` directory in DevEco Studio.
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

You can also select content in Gallery or a file manager and choose Guncat Work from the system share sheet. The app only stages the items as attachments and does not submit a request automatically.

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

- OpenAI Completions: off sends `thinking: { "type": "disabled" }`; on sends `thinking: { "type": "enabled" }` plus `reasoning_effort: "high"`.
- Anthropic Messages: off sends `thinking: { "type": "disabled" }`; on sends `thinking: { "type": "enabled" }` plus `output_config: { "effort": "high" }`.
- OpenAI Responses: on sends `reasoning: { "effort": "high" }`; off sends `reasoning: { "effort": "none" }`.
- New conversations reset the toggle by agent name: off in Efficiency Mode, on in Expert Mode.

### Work mode

1. Tap the 🛠 "Work Mode" entry at the top of the drawer; the page title and empty state switch to work mode.
2. Use the workspace panel's "Upload" to add files (or the camera button — photos go straight into the workspace).
3. Describe the task in the editor; for complex tasks the agent first builds a task checklist, then executes it step by step with tool calls visible in the timeline.
4. Deliverables come out in phone-readable formats: reports→`docx`, tables→`xlsx`, presentations→`pptx` (themes, charts, and editing of existing PPTs are supported; the agent automatically loads the built-in PPT skill and follows its guidelines).
5. Tap any tool step to expand its arguments and results; "Export" packages the whole workspace into a `.zip`.
6. When finished, the agent outputs a detailed summary (including produced file paths); switching to another agent exits work mode — the work conversation and workspace files are preserved.

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
- Work mode: all file I/O happens inside the app sandbox (`filesDir/workspaces/`); picking/saving files uses system safe components (DocumentViewPicker) — **no new permissions**.
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

## Version 6.1.0 (DeepSeek Harness port)

This release ports the core Agent Loop capabilities of DeepSeek Harness (dsh) into Work Mode: a batch of purely local tools, scheduling upgrades in the loop, and a three-column desktop UI for wide screens. Version bumped to 6.1.0 (`Constants.APP_VERSION` and `AppScope/app.json5` versionName 6.1.0 / versionCode 610 in sync). See `PORT_NOTES.md` for the full port map.

- **New tools (11)**: `glob` (path search with `**`/`{a,b}`/`[...]` patterns), `grep` (regex search over text content), `edit` (exact unique-match replacement returning a line diff), `str_replace_editor` (view/create/str_replace/insert editor), `web_fetch` (fetch pages/APIs, HTML stripped to readable text), `ask_user_question` (pauses the loop for an answer; the UI card supports single/multi select plus free-text, submitted via one "Submit" button), `schedule_create/list/delete` (session-local reminders that wake the agent when due, recurring ≥300s), `goal_create/get/update` (session goal injected via the runtime snapshot), `subagent` (in-process child agent: shared workspace, isolated context, ≤40 steps, returns a final report as the tool result), `session_search` (search the session event log).
- **Agent Loop upgrades**: append-only session event log (JSONL at `<filesDir>/sessions/<convId>.jsonl`); user steering — messages sent while a task runs no longer get rejected, they are injected as a "user supplement" into the next request; bounded parallel tool pool (consecutive read-only calls run concurrently, max 4, committed in model order; mutating calls act as barriers); sticky max-tokens (turn finalizes with a "send 继续" hint when output hits the ceiling); spill store (tool results over ~12K chars are fully saved to workspace `.spill/` while the model receives head+tail excerpts with a locator); LLM session titles (generated in the background after the first task, once per session).
- **Three-column desktop UI**: at ≥700vp the layout becomes sidebar (brand row / new session / engines & conversations / bottom actions, collapsible to a 56vp icon rail) | conversation | workspace details panel (task stats / goal / file management, auto-opened once on wide screens); design tokens align with the dsh web UI — neutral-bluish dark palette with the DeepSeek blue accent, white light theme. Narrow screens keep the original single-column + drawer interaction.
- **Tool row visuals**: dsh-style 24px single-line rows (icon + title + separator dot + args summary + status/duration) expanding into IN/OUT detail cards (long content scrolls inside its slot); `edit` renders a diff card (+adds −dels with stats); `todo_write` renders a checklist; the final answer gains a stats line (output speed / cache hit rate / tool time).
- **Performance & fixes**: sidebar/drawer now receive a lightweight conversation projection (fixes the stutter from deep-copying all messages when opening the drawer); the workspace details panel refreshes in real time (after every tool result + every 3s while streaming + a manual refresh button); fixed tool rows momentarily filling the whole page, long results overflowing detail cards, a stray streaming cursor under the answer text, and ask_user single-select submitting before confirmation.
- **Sandbox unchanged**: the workspace is still confined to `<filesDir>/workspaces/<convId>` (`resolveSafe` rejects absolute paths and `..` traversal); files cross the boundary only via system pickers (DocumentViewPicker) with no new storage permissions; the new `.spill/` directory is excluded from the runtime snapshot tree.
- **Full PC adaptation**: all pages are adapted to a PC wide-screen style — a three-column desktop layout with the sidebar on the left, the conversation in the middle, and the workspace details on the right; the sidebar collapses to a 56vp icon rail and the columns stretch adaptively when the window is resized or maximized; settings/about overlays become centered floating panels; list items and buttons gain mouse hover states with wheel-scroll polish; narrow screens (phones/folded state) automatically fall back to the single-column + drawer interaction, both forms sharing the same UI code.
- **Third-party upgrade**: the `@luvi/lv-markdown-in` Markdown rendering engine is upgraded to the latest 3.4.6 version.
- **Visual polish**: improved the display of several screens — conversation whitespace and bubble spacing, input-bar/tool-row alignment, and consistent palette details across dark/light themes.
- **Mermaid diagram polish**: improved the rendering of Mermaid diagrams for clearer graphics and more stable layouts.
- **New answer-bubble actions**: the AI answer bubble gains "Copy" and "Copy to input box" — copy the whole answer with one tap, or drop it into the input box for quick edits and resend.
- **Action icon refinements**: refreshed the icons for copy and a few other answer actions, with a more consistent style and clearer meaning.
- **Free text selection & copy**: message text can now be freely selected and copied directly, with no need to tap "Select part" first.
- **New "Play with the App" guide**: tapping the "About" button opens the Play-with-the-App panel, which gathers feature walkthroughs and usage tips so you can browse each function's guide in detail.

## Version 6.0.0 (Work mode, Agent Loop)

Alongside chat mode, this release adds an independent work mode: the 🛠 "Work Mode" virtual agent (top of the agent list, parallel to other agents) opens a conversation bound to a sandbox workspace, where the agent completes long-horizon tasks through a multi-turn tool-calling loop. Version bumped to 6.0.0 (`Constants.APP_VERSION` and `AppScope/app.json5` versionName 6.0.0 / versionCode 600 in sync).

- **Identity and entry**: the `work` virtual agent is injected at the top of the list; the page title, empty state, and new-conversation ownership follow the selected agent automatically; work conversations use `agentId='work'` (legacy data migrated automatically) and deleting one cleans up its workspace.
- **Agent Loop**: one message per turn (thinking→tools→answer in chronological order), three-protocol streaming function calling, a 200-turn runaway safeguard, request-level automatic retries (429/5xx/network/empty responses with exponential backoff and jitter), two-stage compaction of over-budget history (model-free prune first, then prefix-reusing summarization, falling back to oldest-first trimming), cancellation annotations, and empty-output cleanup; tool results are truncated head+tail before being sent back to the model.
- **Task checklist**: the `todo_write` tool maintains `.todo.json`; checklist and workspace state reach the model through a "runtime context" snapshot appended to the conversation tail (only when it changes) — plan first for complex tasks and progress item by item.
- **25 local tools**: file CRUD/search (with `glob` filename filtering on `search_files`), `view_image` (images are sent to the main model's multimodal vision), `parse_document` (local PDF), Office generation (`write_docx`/`write_xlsx`/`write_csv`), data pipeline (`transform_file`), the PPT read/write/edit trio (`write_pptx`/`read_ppt`/`edit_ppt`), web download (`download_file`), SVG image generation (`write_svg`), and the skill system (`list_skills`/`load_skill`).
- **Data pipeline transform_file**: the dedicated tool for large files and non-standard data — CSV/TSV/Markdown-table/JSON/JSONL/lines input, filter/derive/map/regex-extract/split/dedupe/sort/replace/numeric-cast plus CSV↔TSV↔JSON↔MD↔XLSX conversion, **data never enters model context**. Restricted-DSL design: ops go through a whitelist dispatch and expressions through a self-contained evaluator (no I/O, bounded steps, termination guaranteed by construction), with a "preview 3 rows → write → spot-check" workflow mirroring the SVG loop. Full syntax lives in the `data` skill. Two new pure-TS modules — `CsvParser` (RFC 4180 parsing + Markdown/TSV/CSV auto-detection, also benefits write_csv/write_xlsx) and `DataPipeline` — are wired into the pptx-harness verification chain (54 unit tests).
- **Material acquisition & image generation**: `download_file` pulls network images/files into the workspace (type sniffing, html warning, ≤20MB); `write_svg` lets the model hand-write SVG for icons/diagrams/infographics — validated automatically (xmlns/viewBox/no script) and rasterized to a PNG preview via the device image engine, forming a "generate → preview → iterate" loop with `view_image`; `write_pptx` can reference `.svg` directly (rasterized automatically on export). `search_files` gains a `glob` filename filter (`*.md`, `*.png,*.jpg`). `write_csv` adds explicit CSV support (RFC 4180 escaping + UTF-8 BOM).
- **PPT pipeline (Deck JSON intermediate layer)**: aligned with open-kimi-ppt-skill's PPTD design — the AI writes a structured Deck source, and `PptxBuilder` renders 13 layouts (cover/TOC/section/bullets/two-column/image-text/image/full-bleed image/table/chart/quote/closing/free-form), 8 themes + custom palettes, charts (bar/line/area/pie/doughnut with embedded data), tables, images (workspace/data URL/http), and speaker notes; exported files embed a `docProps/deck.json` source so `read_ppt` restores them losslessly and `edit_ppt` applies operator-style edits (foreign pptx files are imported approximately and automatically backed up before rebuild); dark backgrounds lighten text and chart labels automatically. Five new modules (`DeckModel/PptxThemes/PptxCharts/PptxImage/PptxImporter`) plus a rewritten `PptxBuilder`; comes with the offline verification harness `test/pptx-harness/` (Node builds of all layouts + negatives, python-pptx structural checks, PowerPoint-rendered PNG reviews).
- **Skill system**: domain operation guides are organized under `rawfile/skills/<id>/` (SKILL.md + reference/) and loaded progressively via `list_skills`/`load_skill`; the system prompt keeps only a one-line trigger, so the KV-cache prefix stays byte-stable. The bundled `ppt` skill covers Deck JSON syntax / design guidelines / themes / self-check lists, the `svg` skill covers authoring rules / the "generate → preview → iterate" workflow / recipes for icons, flowcharts, and infographics, and the `data` skill covers pipeline ops / expression syntax / cleaning-extraction-conversion recipes; the skill format follows the standard Agent Skills convention and is portable across agent frameworks. Adding a skill = writing docs + registering it in `WorkSkillService.registry()` (see architecture guide 3.2).
- **Local parsing engine**: new `OfficeReader` (OOXML text extraction, fixing the `<w:t` prefix mismatch that leaked XML), `PdfTextExtractor` (byte-level object table / ObjStm expansion / page-tree resource inheritance / ToUnicode CJK mapping / content-stream parsing / fallback scan with diagnostics), and `Flate` (pure-TS DEFLATE inflate). The multimodal parsing API is no longer required.
- **Codex-style timeline UI**: a single-container timeline (unique 🛠 header + task cards + per-turn "thinking→tools→answer"); tool steps expand to show arguments and results; intermediate turns hide action buttons; the workspace panel supports upload / zip export / clear.
- **Stability fixes**: PDF parsing OOM (whole-file latin1 concatenation replaced with byte-level scanning + native utf-16le decoding); main-thread block appfreeze (parsing yields in stages and the fallback scan skips fonts/images/oversized streams with caps and pre-checks); the same O(n²) concatenation in `arrayBufferToBase64` was fixed as well.
- The system prompt now follows the Guncat 3.0 discipline: planner/executor/final-verifier roles, gap-driven convergence, anti-hallucination, pre-delivery verification, and the output richness principle.
- **Agent prompts add an "opening Mermaid structure diagram"**: the Guncat 3.0-Pro and 3.0-Flash prompts (Chinese and English) are upgraded in sync — the first element of every formal answer is fixed to a Mermaid mindmap outlining the content structure of the answer body (root node = the answer's topic; second/third-level nodes map one-to-one onto the body's major sections and key points); `mindmap` syntax by default, falling back to `flowchart TD` when unsupported; effective in all modes, with only pure-greeting ultra-short interactions exempt; the time-baseline statement now comes right after the diagram, and the pre-output self-check checklist gains a matching item.

## Version 5.2.1

- Added **Guncat 3.0-Mini (Light & Simple Mode)** and placed it first in the agent list: further streamlined from 3.0-Flash, removing the Output Richness Principle in favor of the Task-Adaptive Output Principle (answer length decided by task complexity and user needs — light conversation is naturally concise, standard tasks are medium-length, and complex tasks are fully elaborated); fully retains the three-layers-in-one architecture, the two-tier modes, the tool-calling methodology, and the anti-hallucination system.
- Bumped to version 5.2.1: rawfile adds `Guncat 3.0-Mini_prompt_ZH_CN.md` / `_EN.md`, `agents.json` (3.0-Mini listed first) and `icons/guncat-3.0-mini.png`; `Constants.APP_VERSION` and `AppScope/app.json5` (versionName 5.2.1 / versionCode 521) updated in step.
- New-conversation deep-thinking default extended: Light & Simple Mode defaults off (same as Efficiency Mode).

## Version 5.2.0

- The deep-thinking toggle now explicitly controls the request per protocol (aligned with the official DeepSeek parameters): OpenAI Completions uses `thinking.type` + `reasoning_effort`, Anthropic Messages uses `thinking.type` + `output_config.effort`, OpenAI Responses uses `reasoning.effort = high/none` (`none` disables thinking); when web search is enabled, the previous assistant's `reasoning_content` is sent back in multi-turn turns (OpenAI Completions) to avoid 400 errors.
- New conversations reset the deep-thinking default by agent name: off in Efficiency Mode (3.0-Flash), on in Expert Mode (3.0-Pro); the toggle resets on every app launch.
- Synced the Guncat 3.0-series agent foundations: added "Efficiency Mode" (Guncat 3.0-Flash) and "Expert Mode" (Guncat 3.0-Pro), with "Classic Mode" carrying over the 2.5-Lite foundation; domain experts unified under the "Conversion / Search / Evaluation Expert - Domain" naming scheme; removed the 2.0-series prompt files — the rawfile prompt library is fully aligned with Web for API 5.2.0.
- Per-agent sidebar icons: a new `icon` field in `agents.json` (pointing to a PNG named by agent id under `rawfile/icons/`); `AgentDrawerView` loads them dynamically via `$rawfile`, falling back to the default cat avatar when unset.
- Dual descriptions: a new `shortDescription` field — the sidebar shows the short version while the new-conversation welcome page shows the full one, falling back to each other when unset; `AgentLoader` and the `Agent` model extended accordingly.
- Version governance: the About panel now references `Constants.APP_VERSION` as the single source of truth, consistent with `AppScope/app.json5` and the READMEs.

## Version 5.1.1

- Today's date automatically prepended to system prompts: when loading an agent's prompt, the device's local date is fetched at runtime (e.g., "Today's date is 2026-08-24.") and prepended to the beginning of the prompt, updating automatically across days; applies uniformly to all three access methods — OpenAI Completions / OpenAI Responses / Anthropic Messages.

## Version 5.1.0

- New deep-thinking (reasoning) display: the reasoning content of AI replies is shown in a collapsible card that is collapsed by default and expands on tapping the header; incremental parsing supports all three protocols — OpenAI Completions (`reasoning_content` / `reasoning`), OpenAI Responses (`reasoning_text` / `reasoning_summary_text`), and Anthropic Messages (`thinking_delta`).
- Live stats on the reasoning bar: the right side shows the token speed (tok/s) in real time during streaming and then the API-derived exact token speed plus cache hit rate once the stream ends (the cache hit rate only appears when the API returns cache-token usage; otherwise it stays hidden).
- Reworked the deep-thinking bar UI: a standalone card above the bubble with uniform corner radii and a neutral light-gray background; the spinner sits to the right of the "Deep Thinking" label and the separate "Thinking…" text was removed.

## Version 5.0.0

- Unified API integration into three mainstream protocols: OpenAI Completions, OpenAI Responses, and Anthropic Messages; removed standalone DeepSeek / Volcengine Ark presets with automatic migration for old configs.
- Upgraded DeepSeek to the latest Responses API, including native web search, vision-model image input, and hybrid Files API `file_id` uploads.
- Added Anthropic Messages support, compatible with the DeepSeek Anthropic endpoint (`https://api.deepseek.com/anthropic`), including image input and web search.
- Table recognition now lists all main and multimodal models from every API profile (deduplicated) for direct selection; improved DeepSeek vision output handling (thinking disabled, full-width angle bracket normalization, Markdown table fallback).
- Improved the model-switch menu: equal item widths, centered text, rounded corners, and a softer shadow.
- Improved the drawer shadow: a fixed full-screen scrim keeps the right side shaded during the slide, and tapping the blank area closes the drawer.
- Updated the app icon assets while keeping the original filenames, so existing resource references remain valid (just replace the image files to apply).
- Refreshed the UI with a soft modern style: low-saturation palette, large rounded corners, white soft-elevated buttons, gentle shadows, and no heavy outlines or glow effects.
- Added a launch fly-in animation: icons fly out from the center in sequence, staying sharp throughout with no blur fade or cross-fade flicker.
- Added an one-shot central icon transition: the launch icon uses a single hero node to smoothly move and scale into the empty-state icon at the page center, avoiding "white flash then clear" artifacts.
- Added a bottom input slide-in animation: it slides in from below the screen edge with no bounce or unnatural top-down drop.
- Side drawers, settings sheets, and about overlays naturally cover the underlying hero icon instead of leaving it floating above overlays.

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

### Guncat Work is missing from the Gallery share sheet

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
