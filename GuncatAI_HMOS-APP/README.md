# Guncat Work

> 中文 | [English](README_EN.md)

Guncat Work 是使用 ArkTS 与 ArkUI 开发的原生 HarmonyOS AI 对话客户端，代替了原有的 WebView 承载主界面的旧方案。

当前应用版本：`6.0.0`

## 主要功能

### 原生流式对话

- 基于 `@kit.NetworkKit` 和 `http.requestInStream` 处理 SSE 流式响应。
- 支持三种主流接入方式：OpenAI Completions（`/chat/completions`）、OpenAI Responses（`/responses`，DeepSeek / 火山方舟等兼容服务）、Anthropic Messages（`/messages`）。
- 三种接入方式均支持图片直传；OpenAI Responses 额外支持 Files API 混合上传大图/文档。
- DeepSeek 已统一使用最新 Responses API，支持原生联网搜索与识图版图片直传。
- 支持停止生成、重新生成、对话历史管理和多套 API 配置。
- 流式输出采用节流刷新与自动滚动，减少频繁重绘。

### 深度思考与联网搜索

- 深度思考按钮按接入协议显式控制（对齐 DeepSeek 官方参数）：
  - OpenAI Completions：`thinking.type = enabled / disabled`，开启时另发 `reasoning_effort = high`
  - Anthropic Messages：`thinking.type = enabled / disabled`，开启时另发 `output_config.effort = high`
  - OpenAI Responses：`reasoning.effort = high / none`（`none` 表示关闭思考）
- 按钮状态优先于额外请求参数，避免界面状态与实际请求不一致。
- 联网搜索开启时，多轮对话自动回传上一轮 assistant 的 `reasoning_content`（OpenAI Completions），避免 400。
- OpenAI Completions / Anthropic Messages 也会按各自格式发送联网搜索工具（是否生效取决于服务商支持）。
- 深度思考和联网搜索状态会持久化保存；新建对话（含每次启动自动新建）按智能体名称重置深度思考默认值：效率模式默认关闭、轻简模式默认关闭、专家模式默认开启。

### 维护：智能体深度思考默认值

新建对话 / 每次启动 / 打开空对话时，应用按智能体**名称**重置深度思考开关，配置位于 `entry/src/main/ets/viewmodel/ChatViewModel.ets`：

- `defaultThinkingForAgent()` 方法：按 `agent.name` 返回布尔（`false` = 默认关闭，`true` = 默认开启），返回 `null` 表示不重置（沿用上次状态）
- 当前默认值：效率模式 `false`、轻简模式 `false`、专家模式 `true`
- 调整方式：在该方法中新增/修改 `if (agent.name === '…') return …;` 分支即可；以名称匹配而非 `id`，便于将来改名

### 原生 Markdown

基于 `@luvi/lv-markdown-in` 原生组件渲染，支持：

- CommonMark 与 GFM 常用语法
- 代码块及语法高亮
- 表格、任务列表、引用和链接
- LaTeX 行内与块级公式
- Mermaid 流程图、时序图等图表
- 深色与浅色主题自动适配

### 图片与文件附件

- 支持从系统图片选择器或文件选择器添加附件。
- 支持图片预览、文本提取、Office 文档与 PDF 解析。
- 可选择预解析附件，或通过 OpenAI Responses / Anthropic Messages 直接传递多模态内容。
- OpenAI Responses 附件采用混合策略：小图 Base64 内联，大图/火山方舟文档优先走 Files API 上传 `file_id`。
- 文件解析带状态提示、失败重试和并发节流。
- 图片附件自动生成 256px 缩略图渲染，点击查看原图，降低大图内存占用。

### 快捷拍照

- 输入框麦克风右侧提供拍照按钮，一键调起系统相机（CameraPicker，无需相机权限）。
- 拍摄的照片直接加入待发送附件，与其他附件走相同的解析流程。

### 导出 Word 文档

- AI 回答可一键导出为 `.docx` 文件，通过系统保存面板选择保存位置。
- 完整还原 Markdown 结构：标题、加粗/斜体/删除线、表格（边框与表头底纹）、代码块、引用、有序/无序列表、链接与图片内嵌。
- LaTeX 公式转换为 Word 原生公式（OMML），在 Word 中可编辑、不丢失。
- 图片支持本地 dataUrl 与网络 URL，自动缩放至页宽。

### 局部文本复制

- 回答操作区提供「复制局部」按钮，点击后长按回答内容即可跨段落拖选文本。
- 选择操作栏提供复制、全选、取消，选中内容直接写入剪贴板。

### 接收系统分享

应用已注册为 HarmonyOS 系统分享目标：

- 支持接收图片、文本和通用文件，单次最多 5 个。
- 从图库或文件管理器选择“分享”后，可以选择 Guncat Work。
- 分享内容只会加入当前聊天的待发送附件区，不会自动发送消息。
- 基于 HarmonyOS Share Kit 的 UTD 类型匹配和 `systemShare.getSharedData()` 解析。

### CoreSpeechKit 朗读

最终朗读方案采用 HarmonyOS CoreSpeechKit 的 `textToSpeech` 能力，不包含本地 VITS、MeloTTS、sherpa-onnx 等已撤回方案。

- 查询设备实际支持的系统音色，并允许在朗读控制条中切换。
- 默认优先选择女声，默认语速为 `1.5×`。
- 音色和语速使用 Preferences 持久化，重启应用后自动恢复。
- 提供暂停/继续、关闭、倍速切换和可拖动进度。
- 朗读控制条可在页面内拖动位置。
- 使用 AVSession、音频播放长时任务和后台语音参数支持锁屏及退到后台继续播放。
- 朗读完成后控制条仍可用于拖动进度并重新播放。

> 可用音色及某些音色是否需要下载由设备和系统版本决定。

### 语音输入

- 使用 HarmonyOS 原生语音识别能力。
- 支持开始、停止和取消语音输入。
- 识别结果直接进入消息输入框，由用户确认后发送。

### 智能体与持久化

- 内置多个通用、论文、法律检索、学术检索和模型评测智能体。
- 对话、当前智能体、API 配置、功能开关及朗读配置均保存在本地。
- 支持新建、切换和删除对话。
- 跟随系统切换深色/浅色主题，并同步状态栏、导航栏和 Markdown 样式。

### 工作模式（Agent Loop）

工作模式是**与聊天智能体平行的独立身份**（侧边栏「聊天模式」标题上方的「Agent模式」分组中的 🛠「工作模式」项），进入后进入一个具备本地沙箱工作区与工具调用能力的 Agent 循环，可自主完成多步骤长程任务。完整架构见下文「[工作模式架构与维护指南](#工作模式架构与维护指南)」。

- **沙箱工作区**：每个工作会话对应 `filesDir/workspaces/<convId>/` 目录，支持上传文件、导出 `.zip` 打包、清空；全程应用沙箱内读写 + 系统安全组件选/存文件，无新增权限。
- **25 个本地工具**：文件 CRUD（list/read/write/append/delete/create_dir/move/search，search_files 支持 glob 文件名过滤）、任务清单（todo_write）、图片查看（view_image，走主模型多模态）、网络下载（download_file，把链接文件拉进工作区）、PDF 解析（parse_document + read_file 自动路由）、Office 生成（write_docx / write_xlsx / write_csv）、数据管道（transform_file，大文件本地清洗/转换/互转，数据不经模型上下文）、PPT 读写编辑（write_pptx / read_ppt / edit_ppt，基于 Deck JSON 中间层）、SVG 生图（write_svg，矢量出图 + PNG 预览）、技能系统（list_skills / load_skill，按需加载领域操作指南）。
- **技能系统**：领域操作指南打包在 `rawfile/skills/<id>/`（SKILL.md + reference/*.md），系统提示词只保留触发提示（保证 KV 缓存前缀稳定），模型通过 `list_skills`/`load_skill` 渐进式加载。内置 `ppt` 技能（Deck JSON 语法、设计规范、主题、自检清单）、`svg` 技能（SVG 绘制规范、"生成→预览→修正"工作流、图标/流程图/信息图配方）与 `data` 技能（transform_file 管道 ops 与表达式完整语法、清洗/提取/互转配方）。
- **本地解析引擎**：`.docx/.xlsx/.pptx/.pdf` 全部在设备本地抽取文本，不依赖多模态解析 API、不消耗配额。
- **任务清单纪律**：复杂任务先 `todo_write` 建清单，清单与工作区状态经「运行时上下文」快照注入对话尾部，逐项推进、完成后更新。
- **Codex 式时间线**：每轮独立消息按「思考 → 工具步骤 → 正文」时序排列，单容器时间线 UI，工具步骤可展开查看参数与结果。
- **三协议工具调用**：OpenAI Completions / OpenAI Responses / Anthropic Messages 均支持流式 function-calling；联网搜索开关在工具行保留（服务端搜索工具与客户端工具并存）。

### UI 与动效（5.1.0）

- 深度思考条 UI 重做：独立卡片置于气泡上方，四角统一圆角、中性浅灰配色，与整体灰调协调；「深度思考」文字右侧显示流式转圈动画，不再单独显示「思考中…」文字。
- 更新了应用图标资源（文件名不变，沿用原有资源引用，直接替换图标图片即可生效）。
- 全新柔和现代 UI：低饱和配色、大圆角、白色轻立体按钮、柔和阴影，去除复杂描边与发光装饰。
- 开屏飞入动效：启动页图标从中心向外依次弹性飞入，全程清晰，无模糊渐变或交叉淡化闪烁。
- 一镜到底中央图标：启动页中央图标使用单一 hero 节点平滑移动、放大到页面空状态中央，无“变白再清晰”的闪变。
- 底部输入区从屏幕下方外侧平滑滑入，无回弹、无从上掉落的生硬感。
- 侧边栏、设置弹层、关于弹层等浮层自然遮盖底层 hero 图标，不会出现图标悬浮在浮层之上的问题。

## 内置智能体

智能体通过 `resources/rawfile/agents.json` 和独立 Markdown 提示词文件管理。侧边栏支持独立自定义图标（`icon` 字段指向 `icons/` 目录下以智能体 id 命名的 PNG，未配置回退猫头像），并采用双描述机制：侧边栏展示 `shortDescription` 短描述，新建对话页展示 `description` 完整描述：

| 智能体      | 类别    | 功能                                                         |
| -------- | ----- | ---------------------------------------------------------- |
| 轻简模式     | 通用智能体 | Guncat 3.0-Mini 基座：比 Flash 更轻更快，任务适配输出长度，简单对话简洁自然、复杂任务充分展开 |
| 效率模式     | 通用智能体 | Guncat 3.0-Flash 基座：缺口驱动执行带来极速响应，回答详尽度与 Pro 同标准            |
| 专家模式     | 通用智能体 | Guncat 3.0-Pro 基座：最强大的单体化超级智能体，全系专家能力与行业领先的反幻觉体系           |
| 经典模式     | 通用智能体 | 基于 Guncat 2.5-Lite：成熟的轻量级通用智能体，结构化思维链引导高质量长输出              |
| 转换专家-论文  | 改写智能体 | 基于 Guncat Cnvt-Paper：将非论文文体转化为符合学术规范的论文                    |
| 检索专家-法律  | 检索智能体 | 基于 Guncat Srch-Law：国企法律分析，强制多轮检索与结构化法律意见                   |
| 检索专家-研究  | 检索智能体 | 基于 Guncat Srch-Research：跨领域信息检索与多源交叉验证                     |
| 检索专家-筛滤  | 检索智能体 | 基于 Guncat Srch-Sift：官方溯源与 AI 内容过滤                          |
| 评估专家-LLM | 评估智能体 | 基于 Guncat Eval-LLM：最大减少幻觉地评估 LLM 模型的性能                     |

## 持久化与主题系统

应用基于 `@kit.ArkData` Preferences 保存数据：

- 对话历史与配置使用 JSON 序列化。
- 自动保存当前对话、智能体选择和多套 API 配置。
- 自动保存深度思考、联网搜索、朗读音色和朗读倍速。
- 应用重启后恢复本地状态。

主题使用 HarmonyOS 资源限定符实现：

- `base/element/color.json` 提供浅色资源。
- `dark/element/color.json` 提供深色资源。
- `EntryAbility.onConfigurationUpdate()` 监听系统主题变化。
- 状态栏、导航栏、Markdown、代码高亮及公式颜色同步切换。

## 项目结构

```text
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets
├── pages/
│   ├── ChatPage.ets                # 主页：聊天 + 工作模式时间线 + 工作区面板接线
│   └── TableOcrPage.ets
├── views/
│   ├── ChatBubbleView.ets          # 聊天气泡（含深度思考条 / 工具步骤时间线 / WorkStepFormat）
│   ├── WorkTurnView.ets            # 工作模式时间线的单轮渲染（思考→工具→正文，无头像）
│   ├── WorkspaceBar.ets            # 工作模式工作区面板（文件列表/上传/导出/清空）
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
│   └── ChatViewModel.ets           # 聊天状态 + 工作模式 Agent Loop 驱动（注意是 .ets）
├── service/
│   ├── ChatService.ts              # 三协议 SSE 流式（解析函数已导出供 AgentLoopService 复用）
│   ├── AgentLoopService.ts         # 工作模式：三协议 tool-calling 单轮请求 + 系统提示词（静态, 缓存红线）
│   ├── WorkToolRunner.ets          # 工作模式工具统一分发入口（Office 生成/PPT 读写等 .ets 能力）
│   ├── WorkFileService.ts          # 沙箱工作区 + 文件类/技能类工具实现 + 工具 Schema（toolDefs）
│   ├── WorkSkillService.ts         # 技能注册表（registry）+ rawfile 技能文档加载（list/load）
│   ├── OfficeReader.ts             # docx/xlsx/pptx 本地文本抽取（zlib 解包 + XML 扫描）
│   ├── PdfTextExtractor.ts         # 本地 PDF 文本抽取（字节层对象表/页面树/ToUnicode/内容流）
│   ├── Flate.ts                    # 纯 TS 实现的 DEFLATE/zlib inflate（SDK zlib 仅文件级 API）
│   ├── MultimodalService.ts
│   ├── FileService.ts
│   ├── FileUploadService.ts
│   ├── AgentLoader.ts
│   ├── TableOcrService.ts
│   ├── TextReaderService.ets
│   ├── BackgroundReaderService.ets
│   └── VoiceInputService.ets
├── export/
│   ├── DocxExporter.ets            # Markdown→docx（含工作模式用的 buildDocxBytes）
│   ├── XlsxExporter.ets            # 表格→xlsx（含 buildXlsxFromRows）
│   ├── CsvWriter.ts                # 行数据→CSV（RFC 4180 转义 + 可选 BOM, 纯逻辑）
│   ├── DeckModel.ets               # PPT 中间层：Deck JSON 解析/校验/编辑算子（纯逻辑, 无 Kit API）
│   ├── PptxThemes.ets              # 8 套主题预设 + 语义色解析（纯逻辑）
│   ├── PptxCharts.ets              # 图表 part XML（bar/line/area/pie/doughnut, 纯逻辑）
│   ├── PptxImage.ets               # 图片解析（工作区/data URL/http + 尺寸嗅探）
│   ├── PptxBuilder.ets             # Deck→pptx 渲染器（13 种版式/内嵌 deck 源/备注）
│   ├── PptxImporter.ets            # pptx→Deck（内嵌源无损还原 / 外来 XML 近似导入）
│   ├── OoxmlBuilder.ets / MarkdownParser.ets / OmmlConverter.ets / TableHtmlParser.ets / XmlUtil.ets
│   └── ZipWriter.ts                # STORE 方式 zip 写入器（.ts：供 TS 模块打包工作区复用）
├── data/
│   └── StorageManager.ts
├── model/
│   ├── Message.ts / Conversation.ts / Attachment.ts / ToolCallRecord.ts
│   └── Agent.ts / ApiConfig.ts / ApiProfile.ts / MultimodalConfig.ts
└── common/
    ├── Constants.ts / Types.ts / Utils.ts / MarkdownSanitizer.ts

entry/src/main/resources/rawfile/
├── agents.json + *_prompt*.md      # 聊天智能体定义与提示词
└── skills/                         # 工作模式技能（AI 按需 load_skill 加载, 见「3.2 技能系统」）
    ├── ppt/
    │   ├── SKILL.md                # PPT 技能正文（工作流/速查/自检清单）
    │   └── reference/              # deck-dsl.md / design-guide.md / themes.md
    └── svg/
        ├── SKILL.md                # SVG 生图技能（生成→预览→修正工作流/自检清单）
        └── reference/              # svg-craft.md / svg-recipes.md

test/
└── pptx-harness/                   # PPT/CSV 离线验证环境（Node 构建 + python-pptx 校验 + PNG 目检）
```

项目采用类似 MVVM 的分层方式：

- View：ArkUI 页面与组件。
- ViewModel：集中管理聊天、附件、配置、工作模式循环和持久化状态。
- Service：负责 SSE、Agent Loop、工具执行、本地文档解析、系统分享、TTS 和 ASR 等能力。
- Model：消息、对话、附件、工具调用记录、智能体及 API 配置模型。

> **扩展名即依赖规则**：ArkTS 禁止 `.ts` 文件导入 `.ets` 文件（`.ets` 可以导入 `.ts`）。新建/移动文件时先看依赖方向再定扩展名——需要被 `ChatViewModel.ets` / `WorkToolRunner.ets` 等 `.ets` 模块引用的能力（如 Office 生成、多模态）必须放在 `.ets`；纯逻辑工具（如 ZipWriter、PDF/Office 解析）放 `.ts` 即可被两侧复用。

### 数据流

```text
【聊天模式】
ChatService (SSE)
  → ChatViewModel
  → @Observed Message
  → @ObjectLink ChatBubbleView
  → RichTextView

【工作模式】每轮循环
用户任务 → ChatViewModel.executeWorkLoop
  → AgentLoopService.runTurn（三协议 SSE + 流式工具调用累积）
  → WorkToolRunner.execute → WorkFileService.executeTool
      → OfficeReader / PdfTextExtractor（读取）
      → DocxExporter / XlsxExporter（生成）
      → PptxBuilder / PptxImporter / PptxImage / DeckOps（PPT 写/读/编辑, 见「3.1」）
      → WorkSkillService（list_skills / load_skill, 见「3.2」）
  → 工具结果回填 ToolCallRecord → 注入下一轮请求历史
  → 每轮一条 @Observed Message（思考/工具/文本）
  → ChatPage.buildWorkTimeline → WorkTurnView
```

### 核心组件

1. **ChatViewModel**
   
   - 管理对话列表、智能体选择、API 配置和输入状态。
   - 处理消息发送、流式响应、附件解析与重新生成。
   - 负责持久化存储和状态恢复。
   - 工作模式：`executeWorkLoop` 驱动 Agent 循环（每轮一条消息、工具执行、图片注入、上下文自动压缩）。

2. **ChatService**
   
   - 实现 SSE 流式通信和请求中断。
   - 支持 Chat Completions 与 Responses API。
   - 解析增量回答并处理网络及服务端错误。

3. **AgentLoopService / WorkToolRunner / WorkFileService（工作模式三件套）**
   
   - `AgentLoopService`：单轮 LLM 请求——三协议请求体构建（含工具定义、图片消息）、流式工具调用累积、工作模式系统提示词。
   - `WorkToolRunner`：工具统一分发入口，实现需要 `.ets` 模块的能力（write_docx/xlsx/pptx、parse_document）。
   - `WorkFileService`：沙箱工作区全部文件操作、文件类工具实现、工具 Schema（`toolDefs()`）、工作区打包导出。

4. **MultimodalService**
   
   - 处理图片、文本、PDF 和 Office 文档。
   - 支持预解析、重试与并发控制。
   - 支持 Responses API 图片和文件直传。

5. **OfficeReader / PdfTextExtractor / Flate（本地解析引擎）**
   
   - `OfficeReader`：解包 OOXML 并按标签边界抽取 `w:t`/`a:t`/`sharedStrings` 文本。
   - `PdfTextExtractor`：字节层对象表 + ObjStm 展开 + 页面树资源继承 + ToUnicode CMap + 内容流文本。
   - `Flate`：纯 TS 的 DEFLATE/zlib 解压（SDK zlib 只有文件级 API，无法按缓冲区解压）。

6. **StorageManager**
   
   - 封装 Preferences 本地存储。
   - 管理对话、配置、开关和朗读偏好。

7. **TextReaderService / BackgroundReaderService**
   
   - 查询和管理 CoreSpeechKit 音色。
   - 管理朗读、暂停、进度跳转与语速。
   - 通过 AVSession 和长时任务维持后台音频会话。

## 工作模式架构与维护指南

工作模式是独立的 Agent 执行环境：一个虚拟智能体 + 一个每会话独立的沙箱工作区 + 一个多轮工具调用循环。本节面向维护者，说明各模块职责、数据流与扩展方法。

> **维护文档地图**（改哪块看哪份）：
> 
> - 本节（README）——架构、工具/技能/PPT 三套系统的设计与扩展步骤；
> - `test/pptx-harness/README.md`——PPT 生成器与 CSV 写入器的离线验证环境（Node 构建 + python-pptx 校验 + PNG 目检），改 `export/` 下任何文件后必跑；
> - `entry/src/main/resources/rawfile/skills/`——**模型看到的**操作指南（`ppt`：deck-dsl 语法/设计规范/主题；`svg`：绘制规范/生图配方），是随工具演进同步维护的文档，也是可移植到其他 Agent 框架的复用资产。

### 1. 身份与会话模型

- **虚拟智能体**：`Constants.WORK_AGENT_ID = 'work'`。启动时由 `ChatViewModel.buildWorkAgent()` 注入智能体列表顶部；`AgentDrawerView` 将其拆为独立的「Agent模式」分组展示在「聊天模式」标题上方，与聊天智能体**平行**展示（对 `id === 'work'` 特判渲染 🛠 徽标）。
- **进入/退出**：侧边栏点击「工作模式」= `selectAgent('work')`；点击任意真实智能体即退出（`lastChatAgentId` 记录最近使用的真实智能体，供工具行的工作模式胶囊退出时回切）。
- **会话绑定**：`Conversation.mode = 'chat' | 'work'`；工作会话 `agentId` 固定为 `'work'`，启动时对旧数据自动迁移。删除工作会话会同步清理沙箱工作区目录。
- **开关差异**：进入工作模式强制开启深度思考（工具行不显示该开关）；联网搜索保留（服务端搜索工具与客户端函数工具并存下发）；上传/拍照直接进入工作区而非聊天附件。
- **持久化**：会话 JSON 新增 `mode` 与 `Message.toolCalls`（`ToolCallRecord[]`，含调用参数/结果/耗时，重启后据此还原时间线与 LLM 历史）。工作区文件本体存沙箱 `filesDir`，不进 Preferences。

### 2. Agent Loop（`ChatViewModel.executeWorkLoop`）

```text
for step in 1..WORK_MAX_STEPS(200, 防失控保险):
  1. 新建一条 assistant 消息（本轮的思考/工具/文本都挂在它上面）
  2. 预算检查: 超 85 万 token(1M×0.85, usage 锚定)时先无模型修剪早期工具结果,
     再把早期历史压缩为状态摘要（仅当修剪不够时才调模型）
  3. 追加「运行时上下文」快照(日期+文件树+任务清单)到历史末尾(内容未变则不追加)
  4. AgentLoopService.runTurnWithRetry(三协议流式请求, 含工具定义;
     429/5xx/网络传输/空响应自动指数退避重试)
  5. 无工具调用 → 本轮即最终回答，结束
  6. 有工具调用 → 连续只读调用并发执行、其余逐个执行（WorkToolRunner），结果写回 ToolCallRecord
     - 变更类工具执行后刷新工作区文件列表
     - view_image 成功后注入一条携带图片的多模态 user 消息（仅内存）
  7. 本轮(assistant + 工具结果)进入请求历史，继续下一轮
```

- **每轮一条消息**是时间线 UI 的数据基础：消息列表天然按「思考→工具→正文」时序排列，不再复用单条大消息。
- **上下文自动压缩（缓存感知，对齐 DeepSeek Harness）**：预算优先用上一请求真实 prompt tokens（usage 锚定）对比 `WORK_CONTEXT_WINDOW_TOKENS`×0.85（1M×0.85=85 万 token），无 usage 数据时按会话实测字符→token 比例估算。超预算时两级处理：先无模型修剪早期过长工具结果（头尾节选 + 精确省略提示），不够再把早期历史交给模型压缩成「状态摘要」（≤2400 字，保留最近 12 条原样）——摘要请求自带完整前缀（静态系统提示词+工具定义+历史），对模型侧 KV 缓存是上一请求的延续而非冷启动，前缀按缓存命中计价。摘要失败或仍超预算才回退为从最旧处整条丢弃；若请求直接报上下文超限，强制压缩后自动重试一次。任务清单与工作区文件不参与压缩，始终可被模型 `read_file` 找回——这是长任务跨上下文存续状态的关键。时间线上会标注「已自动压缩早期历史」。
- **前缀缓存设计**：系统提示词全静态（构建一次不再变）；日期/文件树/任务清单以「运行时上下文」快照 user 消息追加到历史末尾、且仅在内容变化时追加；历史严格追加式增长（压缩是唯一改写历史的操作）——相邻两轮请求共享逐字节相同前缀，模型侧 KV 缓存可跨轮命中，写文件后也只有末尾一小段需要重算。
- **中断**：`stopStreaming()` 同时调用 `ChatService.abort()` 与 `AgentLoopService.abort()`；中断轮若无产出则移除消息，否则追加「⏹ 任务已手动停止」。
- **步数保险**：`WORK_MAX_STEPS(200)` 仅作为失控保护（防止工具调用死循环持续消耗），正常长任务触不到；触发后在最后一条消息标注「发送“继续”可接着执行」。

### 3. 工具系统（25 个）

分发链：`ChatViewModel` → `WorkToolRunner.execute()`（.ets 入口）→ Office 生成/parse_document/PPT/transform_file 就地实现，其余委托 `WorkFileService.executeTool()`（.ts）。

| 工具 | 实现位置 | 说明 |
| --- | --- | --- |
| `todo_write` | WorkFileService.toolTodoWrite | 任务清单写入 `.todo.json`，支持数组/内嵌 JSON 字符串两种传参 |
| `list_files` | WorkFileService.toolList | 递归列目录，目录优先排序，含大小 |
| `read_file` | WorkFileService.toolRead | 文本直读；`.docx/.xlsx/.pptx`→OfficeReader，`.pdf`→PdfTextExtractor |
| `write_file` / `append_file` | WorkFileService.toolWrite | 覆盖/追加写文本（512KB 上限，自动建父目录） |
| `delete_file` / `create_dir` / `move_file` | WorkFileService.toolDelete/toolMkdir/toolMove | 递归删除/建目录/移动（moveFileSync/moveDirSync） |
| `search_files` | WorkFileService.toolSearch | 文本类文件大小写不敏感子串搜索，带行号；`glob` 参数按文件名过滤（`*`/`?`，逗号分隔多模式），目录仍递归 |
| `view_image` | WorkFileService.toolViewImage | 图片→dataUrl（≤8MB），由循环注入下一条多模态消息 |
| `download_file` | WorkToolRunner.toolDownloadFile | http(s) 文件下载进工作区（≤20MB；类型嗅探 + html 告警；自动命名或指定 path） |
| `parse_document` | WorkToolRunner.toolParseDocument | PDF 完整文本（本地，3 倍输出上限） |
| `write_docx` | WorkToolRunner.toolWriteDocx → DocxExporter.buildDocxBytes | Markdown→Word |
| `write_xlsx` | WorkToolRunner.toolWriteXlsx → XlsxExporter.buildXlsxFromRows | Markdown 表格/CSV/TSV→Excel |
| `write_csv` | WorkToolRunner.toolWriteCsv → CsvWriter.buildCsvBytes | Markdown 表格/CSV/TSV→CSV（RFC 4180 转义，默认 UTF-8 BOM；输入解析走 CsvParser，引号字段正确处理） |
| `transform_file` | WorkToolRunner.toolTransformFile → DataPipeline | **本地数据管道**（数据不经模型上下文）：CSV/TSV/MD/JSON/JSONL/文本行 输入，过滤/派生列/正则提取/拆列/去重/排序 + CSV↔TSV↔JSON↔MD↔XLSX 互转；受限 DSL（ops 白名单 + 表达式求值器，无 I/O），先预览后写盘；语法见 `load_skill("data")`；≤2MB/10 万行/30 步 |
| `write_pptx` | WorkToolRunner.toolWritePptx → PptxBuilder.buildPptxBytes | **Deck JSON / deck 文件 / outline 大纲 → PPT**（详见下节） |
| `read_ppt` | WorkToolRunner.toolReadPpt → PptxImporter.import | .pptx → Deck JSON 源（自家文件无损还原，外来近似导入） |
| `edit_ppt` | WorkToolRunner.toolEditPpt → PptxImporter + DeckOps + PptxBuilder | 读回→应用操作→重建（外来文件先备份） |
| `write_svg` | WorkToolRunner.toolWriteSvg → SvgUtil | SVG 源码→工作区 .svg + 栅格化 PNG 预览；xmlns/禁 script 校验，缺 width/height 自动按 viewBox 补齐（实机引擎必需），解码失败报精确诊断 |
| `list_skills` / `load_skill` | WorkFileService.dispatchTool → WorkSkillService | 技能清单与技能文档按需加载（rawfile/skills/ 下 ppt、svg、data 三个技能） |

路径安全：所有工具路径经 `resolveSafe()` 校验——拒绝绝对路径、盘符与 `..` 穿越，只能在 `filesDir/workspaces/<convId>/` 内操作。

### 3.1 PPT 生成链路（Deck JSON 中间层）

设计对齐 open-kimi-ppt-skill 的 PPTD 思想：**AI 可编辑的中间层与导出器分离**。AI 永远只面向 Deck JSON 这一层——"生成 PPT"= 写 Deck → 渲染；"编辑 PPT"= 还原 Deck → 应用算子 → 重建。导出器不认识 prompt，只认识 Deck 结构，因此行为完全确定、可离线测试。

```text
write_pptx ──┐                                     ┌─ write_pptx(重建 pptx)
deck JSON ───┼→ PptxBuilder(渲染 13 种版式)→ .pptx │
             │    └─ 内嵌 docProps/deck.json 源    │
read_ppt  ───┤                                    └─ edit_ppt(DeckOps 应用操作后重建)
             └─→ PptxImporter(内嵌源无损还原 / 外来 XML 近似导入)
```

#### 模块职责与公开 API（entry/src/main/ets/export/）

| 文件                 | 职责                                                                                              | 关键公开成员                                                                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DeckModel.ets`    | 中间层模型 + JSON 解析校验 + 编辑算子（**纯逻辑，无 Kit API**）                                                     | `Deck/DeckSlide/DeckBullet/DeckChart/DeckTable/DeckElement/DeckBackground`、`DeckParser.parse`、`DeckOutline.parse`（旧大纲兼容）、`DeckOps.apply`、`DECK_LAYOUTS`、`DECK_MAX_SLIDES`    |
| `PptxThemes.ets`   | 8 套主题预设 + 语义色/十六进制色解析（**纯逻辑**）                                                                  | `PptxThemes.resolve`（Deck→ThemeColors）、`resolveColor(colors, spec, fallback)`（primary/accent/bg/surface/title/body/sub/faint/onPrimary/white/dark/light 或 hex）、`ThemeColors` |
| `PptxCharts.ets`   | 图表 part XML（bar/line/area/pie/doughnut，数据内嵌 numCache/strCache，**纯逻辑**）                          | `PptxCharts.buildXml(chart, colors)`                                                                                                                                         |
| `PptxImage.ets`    | 图片引用解析：工作区相对路径 / data URL / http(s)，mime 嗅探 + PNG/JPEG/GIF/BMP 尺寸探测 | `PptxImage.resolve(src, workspaceRoot)` → `PptxImagePart`                                                                                                                    |
| `PptxBuilder.ets`  | Deck → pptx 全部件渲染（两遍式：先解析图片/图表，再逐页渲染）                                                           | `PptxBuilder.buildPptxBytes(deck, resolveImage)`；另定义 `PptxImagePart`/`ImageResolver`（类型在此，避免 PptxBuilder→PptxImage 的编译期依赖）                                                   |
| `PptxImporter.ets` | pptx → Deck：优先读内嵌 `docProps/deck.json`（无损），否则解析 slide XML 为 custom 版式（文本/表格/图片位置保留，图表转占位说明）     | `PptxImporter.import(absPath, cacheDir)` → `PptxImportResult{deck, embedded, slideCount}`                                                                                    |

**依赖方向**（`.ets` 不得被 `.ts` 导入）：`DeckModel ← PptxThemes/PptxCharts/PptxBuilder`；`PptxBuilder ← WorkToolRunner.ets`；`PptxImage → WorkFileService.ts`（仅 `resolveSafe`，方向合法）；无环。新文件加入前先画这张图。

**SVG 自动栅格化**：`WorkToolRunner.imageResolver` 对 `.svg` 源文件按 1024px 宽经设备图片引擎栅格化为 PNG 再进入渲染管线——`write_svg` 的产物可被 `write_pptx` 直接引用（配合 svg 技能的绘制规范），无需手工转格式。

#### Deck JSON 契约（改字段必同步的三处）

AI 视角的完整字段文档 = **ppt 技能的 `reference/deck-dsl.md`**。Deck 结构的权威实现在 `DeckModel.ets`。改动任一字段时，以下三处必须同步，否则模型会按旧文档生成、报错率上升：

1. `DeckModel.ets`（解析 + 校验：`parseSlide`/`validateSlide` 的报错文案要带页码、说清缺什么，供 AI 自纠错）；
2. 技能文档 `rawfile/skills/ppt/reference/deck-dsl.md`（字段表）与 `SKILL.md`（速查示例）；
3. `test/pptx-harness/test-build.mjs`（样例覆盖该字段，负例覆盖新校验）。

结构概览：顶层 `{title, theme, themeOverride{8 色槽}, slides[]}`；页上限 `DECK_MAX_SLIDES(80)`；页公共字段 `{layout, title, subtitle, notes, background{color|image, fit, overlay}}`；13 种版式各有专属字段（bullets / columns / image / table / chart / elements / text/author / imageSide…）；limits：表格 ≤20 行、单图 ≤10MB（`WORK_PPT_IMAGE_MAX_BYTES`）、整册 ≤40 图（`WORK_PPT_MAX_IMAGES`）。

#### pptx 部件与关系编号约定（改 PptxBuilder 前必读）

- 每页 rels：`rId1` 固定 = slideLayout；其后**按 media → chart 顺序**依次分配 rId2…；`renderChart`/背景图/`renderCustom` 里的 rId 都是按这个规则**算出来的**（`'rId' + (2 + mediaParts.length)`），新增消耗关系的元素时保持同一算法。
- 图表全局编号在**首遍扫描**时分配（`ctx.chartNos`），`[Content_Types].xml` 与 slide rels 共用同一序号——不要在渲染期再数一遍。
- 备注页 `ppt/notesSlides/`：notesMaster **恒定存在**（与是否有备注无关），presentation rels 结构因此稳定；notesSlide 的 rels 反向引用所属 slide 的编号。
- 内嵌源 `docProps/deck.json`（Override application/json）是 `read_ppt`/`edit_ppt` 无损往返的关键，渲染改动不要动它；`renderSlide` 里它由 `JSON.stringify(deck)` 直接生成。
- 备注页 rels 的 `../slides/slideN.xml` 反向引用要传对页码（`notesSlideRelsXml(i + 1)`）。

#### 深色背景自动反白（对比度红线）

`isDarkBg(slide, colors)`：背景图 + `overlay ≥ 0.3`，或背景色亮度 < 0.55 → 判定深色底。判定后：

- **页面文字**（标题/要点/图注/页码）走 `TextScheme`（`renderSlide` 计算一次传给各版式渲染器），反白为 FFFFFF / E2E8F0 / A9B6C6 / 7E8CA0；
- **图表**走 `lightened(colors)` 副本：轴刻度、图例、数据标签变浅，**系列色板不变**；
- **表格单元格**永远用主题 `bg`/`surface` 填充 + 主题 `body` 文字——填充跟随主题而非页面底色，任意主题×任意页面底色组合都可读（曾因此返工，勿改回硬编码 FFFFFF）。

新写版式渲染器时，文字颜色**一律取 `ts`（TextScheme）而非 `colors`**，这是上面规则的落地姿势。

#### 扩展指南

**加新版式**（4 处）：

1. `DeckModel.DECK_LAYOUTS` 注册名字 → `parseSlide` 加字段解析 → `validateSlide` 加必备字段校验（error 信息含页码）；
2. `PptxBuilder.renderSlide` 的 switch 加分支 → 新写 `renderXxx(slide, …, ts, …)`：几何常量放文件头（EMU，1pt=12700），文字用 `ts`，装饰用 `colors.primary/accent`；
3. `test/pptx-harness/test-build.mjs` 的 fullDeck 加样例页 → 跑完整验证链（下文）；
4. 同步技能文档：`deck-dsl.md` 字段表 + `SKILL.md` 版式速查表。

**加主题**：`PptxThemes.preset()` 加分支（primary/accent/bg/surface/title/body/sub/faint/onPrimary/dark + series 6 色板）→ `themes.md` 加一行。未知主题名回退 brand-blue（勿抛错，模型会自行修正）。

**加图表类型**：`PptxCharts.buildXml` 加分支。注意 OOXML 的 `CT_*Ser` 子元素顺序是 `idx→order→tx→spPr→marker→dLbls→cat→val`，`dLblPos` 仅 bar/line/pie 支持（doughnut 不支持，勿加）→ 同步 `deck-dsl.md`。

#### 验证闭环（改完生成器必跑，命令见 test/pptx-harness/README.md）

```bash
node setup.mjs && node test-build.mjs        # 全版式/多主题/编辑算子/负例构建 → gen/out_*.pptx
python validate.py gen\out_all.pptx …        # zip CRC/全部件 XML/关系一致/content-types/python-pptx
python deep-check.py                         # python-pptx 读图表数据 + 内嵌源往返
node check-setup.mjs && npx -y -p typescript@5.5.4 tsc -p check/tsconfig.json   # 服务层类型检查
```

视觉自检（装了 PowerPoint 的机器）：`export-png.ps1` 导出 PNG 后逐页目检——重点看文字出界、深色页反白、图表标签可读、表格对比度（历史上 3 个视觉 bug 全是这三类）。

### 3.2 技能系统（可复用的领域操作指南）

技能 = 按 id 组织的**纯 Markdown 领域操作指南**（无代码）。模型接到对应任务时自行加载。解决的核心问题：领域知识（Deck JSON 语法、设计规范……）不能写进系统提示词——系统提示词必须逐字节静态（KV 缓存红线），而技能文档可以随时增改、按需加载、按文件分层，**不动一行提示词代码**。

#### 结构约定

```text
entry/src/main/resources/rawfile/skills/
├── ppt/                        ← 技能 id（小写、唯一；目录名 = id）
│   ├── SKILL.md                ← 技能正文（必备）：何时用 / 工具链 / 工作流 / 速查 / 自检清单
│   └── reference/              ← 深入资料，按需逐文件加载（可选）
│       ├── deck-dsl.md         # 字段级语法
│       ├── design-guide.md     # 设计规范
│       └── themes.md           # 主题清单
└── svg/                        ← 内置技能 2：SVG 矢量绘图（生图）
    ├── SKILL.md                # "生成→预览→修正"工作流 + 工具分界（照片用 download_file）
    └── reference/
        ├── svg-craft.md        # 绘制规范: xmlns/viewBox 硬要求、24 网格、path 优先、文字风险、配色纪律
        └── svg-recipes.md      # 可套用模板: 描边图标/流程图/架构图/信息图卡片/封面装饰
```

注册表在 `WorkSkillService.registry()`（**代码即注册表，无配置文件**）。每个 `SkillInfo = { id, name, description, files: SkillFileInfo[] }`；`files` 是 `load_skill` 允许的文件白名单（`SKILL.md` 恒可用），防路径探测。**没有登记的技能对模型不存在**——文档放了对目录里也不会被加载。

#### 加载链路（渐进披露）

```text
系统提示词「技能系统」段(一行触发提示, 静态)
  → 模型 list_skills()                        → WorkSkillService.listText()
      返回: id + name + 触发语义 + 文件索引
  → 模型 load_skill("ppt")                    → rawfile 读 SKILL.md 全文
  → 模型 load_skill("ppt", "reference/deck-dsl.md") → 按文件加载深入资料
分发: WorkFileService.dispatchTool()（纯 TS, 无需 .ets）; 二者登记在 isReadOnlyTool() 可并发。
结果与普通工具一致: 超 1.2 万字符被头尾保留式截断(WORK_SKILL_MAX_CHARS 是加载侧硬上限)。
```

#### SKILL.md 写作约定（可复用骨架）

```markdown
---
name: <id>
description: <一句话触发语义, 写法见下>
---
# <技能名>

## 何时用          ← 触发场景清单（模型据此决定是否加载）
## 工具链          ← 涉及哪些工具、参数怎么传、图片来源等硬约束
## 工作流 A/B      ← 分场景编号步骤, 每步一个动作; 附最小可用示例
## 速查            ← 表格/JSON 样例（放最常用的 20%, 长尾放 reference）
## 交付前自检清单   ← checkbox 列表, 模型交付前逐项自查
```

- `reference/` 文件按主题内聚拆分，**单文件 < 1.2 万字符**（超出会被截断、中段丢失，等于白写）；
- 示例代码块必须是**可原样跑通的最小样例**，与当前工具实现一致；
- 长度预算：SKILL.md 控制在 4~6k 字符，把细节留给 reference。

#### description 触发语义怎么写

description 同时承担两个职责：系统提示词触发提示的展开、`list_skills` 的展示文本。写法 = **枚举任务关键词 + 指明涉及的工具 + 声明先加载**：

- ✅ `制作/修改/美化演示文稿(.pptx)时加载: Deck JSON 完整语法(13 种版式/图表/表格/图片/备注)、8 套主题、设计规范与自检清单。任何 write_pptx / read_ppt / edit_ppt 任务开始前先加载。`
- ❌ `PPT 技能`（模型无法判断何时该加载，等于没写）

#### 新增一个技能的步骤（写文档 + 1~2 处代码）

1. 建 `rawfile/skills/<id>/SKILL.md`（+ 按需 `reference/*.md`），按上面的骨架写；
2. `WorkSkillService.registry()` 登记条目：id / name / description / files 白名单（每个 reference 文件都要登记，否则 load 不到）；
3. 需要主动触发时，在 `AgentLoopService.buildWorkSystemPrompt()` 的「技能系统」段补一句（追加行不改历史行，静态红线不破坏）；
4. **不用改 toolDefs / dispatchTool**：`list_skills`/`load_skill` 是通用工具，自动覆盖新技能；
5. 自测：工作模式里 `list_skills` → 逐文件 `load_skill` 确认完整无截断 → 实跑一个对应任务看模型是否按技能执行。

#### 维护红线与可移植性

- 技能文档与工具实现**同步演进**：改 Deck 字段/工具参数 → 同步对应技能文档 → 再改系统提示词（若有涉及）；
- description 措辞 = 触发行为，改动要当回事（建议在 git 提交说明里单独标注）；
- 技能文档是**跨 Agent 可复用资产**：frontmatter（name/description）刻意对齐标准 Agent Skills 约定（同 open-kimi-ppt-skill 的 SKILL.md 结构），整目录拷入其他 Agent 框架的技能目录（如 `~/.claude/skills/<id>/`）即可被支持 SKILL.md 的框架识别，无需改写。

### 4. 新增工具的步骤（5 处）

1. `WorkFileService.toolDefs()`：登记工具 Schema（名称/描述/参数），这是模型看到的定义；`props0`/`props1`/`props2`/`props3` 构造属性表。
2. `WorkFileService.dispatchTool()`：加入分发分支（需要 `.ets` 能力时改在 `WorkToolRunner.execute()` 分发）。
3. 实现执行函数：返回 `ToolExecResult`（`ok`/`output`；`imageDataUrl` 仅供 view_image 类工具注入视觉消息）。
4. `AgentLoopService.buildWorkSystemPrompt()`：补充工具说明与使用纪律（保持逐字节静态；大段领域知识不要写这里——做成技能，见 3.2）。
5. 若会改变工作区内容，登记 `WorkFileService.isMutatingTool()`；纯只读工具登记 `isReadOnlyTool()`（可参与只读并发）。

> 涉及"教模型怎么用新工具"的内容（DSL 语法、格式规范、工作流），优先做成技能文档而不是堆进工具 description 或系统提示词——description 一句话说明用途即可，细节让模型 `load_skill` 自取。

### 5. 本地解析引擎与内存/主线程红线

**解析链**：`OfficeReader`（zlib.decompressFile 解包 OOXML → XML 文本节点抽取）、`PdfTextExtractor`（字节层对象表扫描 → ObjStm 顺序值展开 → 页面树资源继承 → ToUnicode CMap 映射 CJK → 内容流 `Tj/TJ` 解析 → 全流扫描兜底 + 诊断信息）、`Flate`（纯 TS DEFLATE/zlib 解压，SDK zlib 只有文件级 API）。

维护时必须守住三条红线（每条都有过线上事故）：

1. **禁止大字符串逐字符拼接**（`s += x` 循环 O(n²)）——曾把共享堆打爆（OOM）。大片段统一走 `bytesToString()`：字节拷入 UTF-16LE 缓冲后用 `util.TextDecoder` 一次性原生解码；`arrayBufferToBase64` 同样是全数值化生成 + 原生解码。
2. **重 CPU 解析必须分阶段让出主线程**——曾在兜底扫描全量解析字体流时触发 THREAD_BLOCK_6S appfreeze。`PdfTextExtractor` 用 `yieldNow()`（setTimeout 0）在对象表构建后、每页之间、兜底每个流之间让出；兜底扫描跳过字体/图片/超大流并做内容预检。
3. **所有片段转换必须设上限**：字典 64KB、ObjStm 2MB、CMap 1MB、内容流 4MB、单条文本解码 128KB、单行缓冲 100K 字符、整文件 16MB——防止异常/恶意文件打爆内存。

### 6. ArkTS 落地约束（踩过的坑）

- **`.ts` 不得 import `.ets`**（编译错误 10605999）。选扩展名前先画依赖方向：`ChatViewModel.ets` 需要引用 Office 生成/多模态等 `.ets` 模块，因此 ViewModel 本身必须是 `.ets`；`WorkFileService.ts` 只能依赖 `.ts`（ZipWriter 因此从 .ets 改成了 .ts）。
- **`.ets` 禁止匿名对象字面量类型**（arkts-no-obj-literals-as-types）。跨模块返回结构用命名类（如 `ParsedFileResult`、`ToolExecResult`）。
- **闭包不继承可空变量的收窄**：`let conv: X | null` 判空后，在 lambda 里仍可能报 possibly null——先落成非空局部量（如 `let emptyConv: Conversation = conv`）再进闭包。
- **目录列举 API 是 `listFileSync`**（该 SDK 无 `readdirSync`）；`mkdirSync(path, true)` 支持递归建目录。
- **import 必须置于文件最前**（注释除外），且所有 import 语句先于其他语句。
- PowerShell 管道改文件内容会把 UTF-8 按 GBK 重写导致中文乱码——修改源码一律用编辑工具，不用 shell 重写。

### 7. UI（Codex 式时间线）

- `ChatPage.buildWorkTimeline`：工作模式下整个会话渲染为**单容器时间线**——顶部唯一 🛠「工作模式」标识（含执行状态），下方按消息顺序排列：用户任务卡（品牌色）与 `WorkTurnView`。
- `WorkTurnView`（`@ObjectLink Message`）：CLI 式行内思考条（`图标 + 思考`，流式转圈 + 跑马灯，完成后标题缀「· 持续了几秒」占位文案，无底色）→ CLI 式行内工具行（`工具图标 + 短名 · 参数摘要 + 状态/耗时`，无底色块，点击展开参数与结果，展开区以左侧细竖线挂载）→ 正文（RichTextView）；思考/工具行带 16vp 水平边距，宽度与正文对齐；仅最终轮显示复制/导出/重新执行按钮；流式期间 33ms flush 定时器同步文本与步骤状态。
- 聊天模式完全沿用 `ChatBubbleView`（深度思考条同样为无底色行内样式），两条渲染路径互不影响。
- `WorkspaceBar`：工作区弹层（文件列表 + 上传/导出 zip/删除）；文件行按扩展名映射类别图标（`sys.symbol`：图片/表格/演示文稿/PDF/压缩包/代码/音视频等），未知类型回退通用文档图标。

## 构建要求

- DevEco Studio 6.0.1 或兼容版本
- HarmonyOS SDK API 24（`6.1.1`）
- HarmonyOS 手机真机

使用 DevEco Studio 打开项目后，配置签名并运行 `entry` 模块即可。命令行构建示例：

```bash
hvigorw --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap
```

### 构建步骤

1. 克隆或下载项目。
2. 使用 DevEco Studio 打开 `GuncatAI_HMOS-APP` 目录。
3. 安装并选择 HarmonyOS SDK API 24。
4. 配置调试或发布签名。
5. 连接 HarmonyOS 真机。
6. 运行 `entry` 模块，或使用上述命令构建 HAP。

## 配置

应用设置中可保存并切换多套 API 配置：

1. 接入方式（`openai-completions` / `openai-responses` / `anthropic-messages`）
2. Base URL
3. API Key
4. Model
5. Temperature、Top P、最大输出 Token 等可选参数
6. 额外请求参数

常用兼容地址：

- DeepSeek Responses：`https://api.deepseek.com`
- DeepSeek Anthropic：`https://api.deepseek.com/anthropic`，也可直接填 `https://api.deepseek.com`（应用自动补全 `/anthropic/v1/messages`）
- 火山方舟 Responses：`https://ark.cn-beijing.volces.com/api/v3`
- Anthropic Messages：`https://api.anthropic.com/v1`

多模态预解析可单独配置模型、地址和 API Key。

## 使用指南

### 基本对话

1. 首次启动后打开设置。
2. 新建或选择 API 配置，填写接入方式、Base URL、API Key 和模型名称。
3. 从侧边栏选择智能体。
4. 输入消息并发送。

### 添加图片或文件

1. 点击输入框旁的附件按钮。
2. 从图片选择器或文件选择器选择内容。
3. 等待预解析完成；关闭预解析时，附件会在发送时直接传给支持多模态的接口。
4. 检查待发送附件后，由用户主动发送。

也可以在图库或文件管理器中选择内容，通过系统“分享”选择 Guncat Work。应用只会把内容放入待发送附件，不会自动提交请求。

#### 附件直传策略

- OpenAI Completions：小图使用 `image_url` 内联，大图自动上传 Files API 后使用 `file` + `file_id`；文档使用 `file_url`。
- Anthropic Messages：小图使用 base64 `image` 内容块内联，大图自动上传 Files API 后使用 `source.type = file` + `file_id`；文档会发送 `document` 块。
- OpenAI Responses：
  - 小图（≤4MB）：Base64 内联发送。
  - 大图（>4MB）：自动上传 Files API，使用 `input_image.file_id`。
  - 文档：自动上传 Files API 后使用 `input_file.file_id`，或内联 `input_file.file_data`。
  - 上传失败会自动回退 Base64。
- 如果服务商不支持某种文档/图片块，服务端会返回错误；应用会原样展示错误，不会在客户端擅自丢弃。

### 深度思考

- 火山方舟：关闭发送 `thinking: { "type": "disabled" }`，打开发送 `thinking: { "type": "enabled" }`。
- DeepSeek / OpenAI Responses：打开时发送 `reasoning: { "effort": "high" }`。
- 适用于支持对应参数的 OpenAI Responses API 模型。

### 工作模式

1. 侧边栏点击顶部 🛠「工作模式」进入，主页面标题与空态随之切换为工作模式。
2. 需要材料时通过工作区面板「上传」添加文件（或用拍照按钮，照片直接进入工作区）。
3. 在输入框描述任务；复杂任务 Agent 会先建立任务清单，再逐项调用工具执行，时间线中可实时查看每一步。
4. 产出物直接是手机可读格式：报告→`docx`、表格→`xlsx`、演示文稿→`pptx`（支持指定主题、图表、编辑已有 PPT；Agent 会自动加载内置的 PPT 技能按规范制作）。
5. 点击任意工具步骤可展开查看参数与执行结果；右上角「导出」把整个工作区打包为 `.zip` 保存。
6. 完成后 Agent 输出详尽总结（含产出文件路径）；侧边栏切换到其他智能体即退出工作模式，工作会话与工作区文件保留。

### 朗读

1. 点击助手消息的朗读操作。
2. 在悬浮控制条中暂停/继续、切换语速或音色。
3. 拖动进度条可从相应文本位置继续朗读。
4. 拖动控制条空白区域可调整位置。
5. 点击关闭按钮结束朗读并收起控制条。

### 对话与消息操作

- 在侧边栏中新建、切换或删除对话。
- 复制助手消息内容。
- 对助手消息执行重新生成。
- 点击图片进入大图预览。
- 生成过程中可停止当前请求。

## 权限与系统能力

- `ohos.permission.INTERNET`：访问模型 API。
- `ohos.permission.MICROPHONE`：语音输入。
- `ohos.permission.KEEP_BACKGROUND_RUNNING`：朗读后台音频长时任务。
- 工作模式：文件读写全部在应用沙箱（`filesDir/workspaces/`）内完成，文件选择/保存走系统安全组件（DocumentViewPicker），**未新增任何权限**。
- Share Kit：接收其他应用分享的图片和文件。
- CoreSpeechKit：文本朗读与语音识别。
- AVSession Kit：后台媒体会话。
- ArkData Preferences：本地配置与对话持久化。

## 隐私说明

- API Key 和应用配置保存在应用本地沙箱。
- 聊天请求和附件只会发送到用户配置的模型服务。
- 从系统分享接收的内容不会自动发送，必须由用户主动点击发送。
- 原始附件不会作为永久文件复制到应用数据中。
- 网络请求使用 HTTPS，实际数据处理政策以所配置的模型服务商为准。

## 6.0.0 更新（工作模式 Agent Loop）

在聊天模式之外新增独立的工作模式：以 🛠「工作模式」虚拟智能体（侧边栏列表顶部，与智能体平行）为入口，每个工作会话绑定一个沙箱工作区，Agent 通过多轮工具调用循环自主完成长程任务。版本升至 6.0.0（`Constants.APP_VERSION` 与 `AppScope/app.json5` versionName 6.0.0 / versionCode 600 同步）。

- **身份与入口**：`work` 虚拟智能体注入列表顶部；主页面标题/空态/新建对话归属随当前智能体自动切换；工作会话 `agentId='work'`（旧数据自动迁移），删除会话同步清理工作区。
- **Agent Loop**：每轮一条消息（思考→工具→正文按时序排列），三协议流式 function-calling，200 轮防失控保险，请求级自动重试（429/5xx/网络传输/空响应，指数退避+抖动），上下文超预算先修剪早期工具结果、再前缀复用式压缩为状态摘要（失败回退整条裁剪），中断标注、空产出清理；工具结果头尾保留式截断送回模型。
- **任务清单**：`todo_write` 工具维护 `.todo.json`，清单与工作区状态经「运行时上下文」快照注入对话尾部（内容变化时才追加），复杂任务先规划、逐项推进。
- **25 个本地工具**：文件 CRUD/搜索（`search_files` 支持 glob 文件名过滤）、`view_image`（图片经多模态消息送给主模型视觉）、`parse_document`（本地 PDF）、Office 生成（`write_docx`/`write_xlsx`/`write_csv`）、数据管道（`transform_file`）、PPT 读写编辑三件套（`write_pptx`/`read_ppt`/`edit_ppt`）、网络下载（`download_file`）、SVG 生图（`write_svg`）、技能系统（`list_skills`/`load_skill`）。
- **数据管道 transform_file**：大文件与非标数据的专用工具——CSV/TSV/Markdown 表格/JSON/JSONL/文本行 输入，过滤/派生列/重算列/正则提取/拆列/去重/排序/替换/数值化 + CSV↔TSV↔JSON↔MD↔XLSX 互转，**数据全程不经过模型上下文**。受限 DSL 设计：ops 走白名单分发、表达式走自研求值器（无 I/O、步数有界、结构上必然终止），"预览前 3 行 → 写盘 → 抽查"工作流对齐 SVG 的"生成→预览→修正"纪律；完整语法在 `data` 技能。新增 `CsvParser`（RFC 4180 解析 + Markdown/TSV/CSV 智能识别，write_csv/write_xlsx 同步受益）与 `DataPipeline` 两个纯 TS 模块，并入 pptx-harness 验证链路（54 项单测）。
- **素材获取与生图**：`download_file` 把网络图片/文件拉进工作区（类型嗅探、html 告警、≤20MB）；`write_svg` 让模型手写 SVG 生成图标/示意图/信息图——自动校验（xmlns/viewBox/禁 script）并经设备图片引擎栅格化出 PNG 预览，配合 `view_image` 形成"生成→预览→修正"闭环；`write_pptx` 可直接引用 `.svg`（导出时自动栅格化）。`search_files` 新增 `glob` 文件名过滤（`*.md`、`*.png,*.jpg`）。`write_csv` 显式支持 CSV（RFC 4180 转义 + UTF-8 BOM）。
- **PPT 工具链（Deck JSON 中间层）**：对齐 open-kimi-ppt-skill 的 PPTD 设计——AI 写结构化 Deck 源，`PptxBuilder` 渲染 13 种版式（封面/目录/分节/要点/双栏/图文/图片/全幅大图/表格/图表/引用/结尾/自由版面）、8 套主题 + 自定义色板、图表（柱/折线/面积/饼/环，数据内嵌）、表格、图片（工作区/data URL/http）、演讲备注；导出文件内嵌 `docProps/deck.json` 源，`read_ppt` 无损读回、`edit_ppt` 算子式编辑（外来 pptx 近似导入并在重建前自动备份）；深色背景文字与图表自动反白。新增 `DeckModel/PptxThemes/PptxCharts/PptxImage/PptxImporter` 五个模块并重写 `PptxBuilder`；配套离线验证环境 `test/pptx-harness/`（Node 构建全版式/负例 + python-pptx 结构校验 + PowerPoint 渲染 PNG 目检）。
- **技能系统**：领域操作指南按 `rawfile/skills/<id>/`（SKILL.md + reference/）组织，`list_skills`/`load_skill` 渐进式加载；系统提示词只保留一行触发提示，KV 缓存前缀保持逐字节稳定。内置 `ppt` 技能（Deck JSON 语法/设计规范/主题/自检清单）、`svg` 技能（绘制规范/"生成→预览→修正"工作流/图标·流程图·信息图配方）与 `data` 技能（管道 ops/表达式语法/清洗·提取·互转配方）；技能格式对齐标准 Agent Skills 约定，可跨 Agent 框架复用；新增技能只需写文档 + `WorkSkillService.registry()` 登记（详见架构指南 3.2）。
- **本地解析引擎**：新增 `OfficeReader`（OOXML 文本抽取，修复 `<w:t` 前缀误匹配导致的 XML 泄漏）、`PdfTextExtractor`（字节层对象表/ObjStm 展开/页面树资源继承/ToUnicode CJK 映射/内容流解析/兜底扫描与诊断）、`Flate`（纯 TS DEFLATE 解压）。不再依赖多模态解析 API。
- **Codex 式时间线 UI**：单容器时间线（唯一 🛠 标识 + 任务卡 + 逐轮「思考→工具→正文」），工具步骤可展开参数与结果，中间轮隐藏操作按钮；工作区面板支持上传/导出 zip/清空。
- **稳定性修复**：PDF 解析 OOM（整文件 latin1 拼接改为字节层扫描 + utf-16le 原生转换）；主线程阻塞 appfreeze（解析分阶段 yield、兜底扫描跳过字体/图片/超大流并限量限预检）；`arrayBufferToBase64` 同类 O(n²) 拼接一并修复。
- 系统提示词对齐 Guncat 3.0 纪律：规划者/执行者/终验者、缺口驱动收口、反幻觉、交付前验证、输出丰富性原则。
- **智能体提示词新增「回答开头 Mermaid 结构导图」**：Guncat 3.0-Pro 与 3.0-Flash 的中英文提示词同步升级——正式回答的第一个元素固定为一个 Mermaid 思维导图，示意本次回答正文的内容结构（根节点为回答主题，二三级节点对应正文各大章节与关键要点，与标题结构一一对应）；默认 `mindmap` 语法、渲染环境不支持时退化为 `flowchart TD`；所有模式生效，纯寒暄类超简短交互豁免；时间基准声明改为紧随导图之后，输出前自检清单同步新增结构导图检查项。

## 5.2.1 更新

- 新增 **Guncat 3.0-Mini（轻简模式）** 并置于智能体列表首位：基于 3.0-Flash 进一步精简，移除输出丰富性原则、代之以任务适配输出原则（回答长度由任务复杂度与用户需求决定，简单对话简洁自然、标准任务中等篇幅、复杂任务充分展开）；完整保留三层一体架构、双档模式、工具方法论与反幻觉体系。
- 版本升至 5.2.1：rawfile 同步新增 `Guncat 3.0-Mini_prompt_ZH_CN.md` / `_EN.md`、`agents.json`（3.0-Mini 排在首位）与 `icons/guncat-3.0-mini.png`；`Constants.APP_VERSION` 与 `AppScope/app.json5`（versionName 5.2.1 / versionCode 521）同步更新。
- 新建对话深度思考默认值补充：轻简模式默认关闭（与效率模式一致）。

## 5.2.0 更新

- 深度思考开关按协议显式控制（对齐 DeepSeek 官方参数）：OpenAI Completions 使用 `thinking.type` + `reasoning_effort`，Anthropic Messages 使用 `thinking.type` + `output_config.effort`，OpenAI Responses 使用 `reasoning.effort = high/none`（`none` 关闭思考）；联网搜索开启时多轮对话自动回传上一轮 assistant 的 `reasoning_content`（OpenAI Completions），避免 400。
- 新建对话默认深度思考按智能体名称重置：效率模式（3.0-Flash）默认关闭、专家模式（3.0-Pro）默认开启；每次启动应用都会重置。
- 同步 Guncat 3.0 系列智能体基座：新增「效率模式」（Guncat 3.0-Flash）与「专家模式」（Guncat 3.0-Pro），「经典模式」承接原 2.5-Lite 基座；各领域专家统一为「转换专家 / 检索专家 / 评估专家-领域」命名；移除 2.0 系列提示词文件，rawfile 提示词库全量对齐 Web for API 5.2.0。
- 侧边栏自定义图标：`agents.json` 新增 `icon` 字段（指向 `rawfile/icons/` 目录下以智能体 id 命名的 PNG），`AgentDrawerView` 通过 `$rawfile` 动态加载，未配置自动回退默认猫头像。
- 双描述机制：新增 `shortDescription` 字段——侧边栏展示短描述、新建对话欢迎页展示完整描述，未配置时相互回退；`AgentLoader` 与 `Agent` 模型同步扩展解析。
- 版本号治理：关于弹层版本号改为引用 `Constants.APP_VERSION` 单一来源，与 `AppScope/app.json5`、README 保持一致。

## 5.1.1 更新

- 系统提示词自动拼接今日日期：加载智能体提示词时在最前面动态获取设备本地日期（如「今天的日期是 2026年08月24日。」）并拼接，跨天自动更新；OpenAI Completions / OpenAI Responses / Anthropic Messages 三种接入方式统一生效。

## 5.1.0 更新

- 新增深度思考（推理过程）展示：AI 回复中的深度思考内容以折叠卡片形式显示，默认折叠，点击头部展开查看完整推理过程；兼容 OpenAI Completions（`reasoning_content` / `reasoning`）、OpenAI Responses（`reasoning_text` / `reasoning_summary_text`）、Anthropic Messages（`thinking_delta`）三种协议增量解析。
- 思考条右侧实时统计：流式中实时显示 token 速度（tok/s），流式结束后显示 API 返回的精确 token 速度与缓存命中率（缓存命中率仅在 API 返回缓存 token 字段时显示，无返回值不显示）。
- 深度思考条 UI 重做：独立卡片置于气泡上方，四角统一圆角、中性浅灰配色；「深度思考」文字右侧显示流式转圈动画，不再单独显示「思考中…」文字。

## 5.0.0 更新

- API 接入方式统一为三种主流协议：OpenAI Completions、OpenAI Responses、Anthropic Messages；移除 DeepSeek / 火山方舟独立预设，旧配置自动迁移。
- DeepSeek 接入升级为最新 Responses API，支持原生联网搜索、识图版图片直传与 Files API `file_id` 混合上传。
- 新增 Anthropic Messages 支持，兼容 DeepSeek Anthropic 端点（`https://api.deepseek.com/anthropic`），支持图片直传与联网搜索。
- 表格识别页改为动态展示所有 API Profile 的主模型与多模态解析模型，去重后可直接选择；兼容 DeepSeek 视觉模型输出（关闭思考模式、全角尖括号归一化、Markdown 表格兜底）。
- 优化模型切换菜单：选项统一宽度、文字居中、菜单圆角与轻阴影。
- 优化侧边栏抽屉阴影：全屏 scrim 固定覆盖，滑动过程中右侧始终有阴影，点击空白可关闭。
- 更新应用图标资源（文件名不变，沿用原有资源引用，直接替换图标图片即可生效）。
- 全新柔和现代 UI：低饱和配色、大圆角、白色轻立体按钮、柔和阴影，去除复杂描边与发光装饰。
- 新增开屏飞入动效：启动页图标从中心向外依次弹性飞入，全程清晰，无模糊渐变或交叉淡化闪烁。
- 新增一镜到底中央图标：启动页中央图标使用单一 hero 节点平滑移动、放大到页面空状态中央，无“变白再清晰”的闪变。
- 新增底部输入区滑入动画：从屏幕下方外侧平滑滑入，无回弹、无从上掉落的生硬感。
- 侧边栏、设置弹层、关于弹层等浮层自然遮盖底层 hero 图标，不会出现图标悬浮在浮层之上的问题。

## 4.4.0 更新

- 新增表格识别：回答操作区新增「表格识别」入口，调起独立识别页，经多模态模型将图片中的表格转为 HTML 表格并预览，保留合并单元格（rowspan/colspan）、表头与书写行高信息。
- 新增导出 Excel：识别结果可一键导出为 `.xlsx` 文件，通过系统保存面板选择保存位置，原生解析与导出引擎对齐 Web 版本，不依赖网络上传。
- 表格识别配置拆分：智谱引用「多模态解析引擎」配置，火山方舟（豆包）引用「主模型」配置（支持原生多模态的模型），两个平台的 API Key 独立保存、互不共用。
- 启动自动新建对话：每次重新打开应用自动新建一条对话；若该智能体最后一条对话仍为空则直接复用，不产生重复空对话。

## 4.3.1 更新

- 修复 Markdown 表格渲染闪退：三方渲染库 @luvi/lv-markdown-in 在解析结构异常的表格（空表头单元格、表头与分隔线列数不一致、仅表头无数据行、消息在表格处截断）时会遍历未定义数据抛异常，导致进程直接闪退；历史消息在冷启动重渲染时必现。
- 新增渲染前表格规范化：结构合法的表格自动补齐列数与闭合竖线、保留列对齐方式；无法修复的退化表格降级为纯文本，内容不丢失。
- 规范化仅作用于表格块，不影响代码围栏、列表、引用块等其他 Markdown 语法。

## 4.3.0 更新

- 新增一键导出 Word：AI 回答导出为 `.docx`，支持标题、加粗斜体、表格、代码块、引用、列表、链接与图片内嵌，LaTeX 公式转换为 Word 原生公式（OMML）。
- 新增快捷拍照：麦克风右侧拍照按钮调起系统相机（CameraPicker，无需相机权限），照片直接加入附件。
- 新增复制局部：回答操作区「复制局部」按钮，点击后长按可跨段落拖选文本并复制。
- 修复流式生成中滑动查看历史消息导致的白屏：触摸期间暂停自动置底，松手后恢复。
- 修复大图附件导致的偶发内存溢出闪退：会话持久化自动剥离超限图片字节，附件改为 256px 缩略图渲染。
- 调整输入框布局：麦克风与拍照按钮紧凑排列并垂直对齐。

## 4.2.1 更新

- 新增 Guncat Eval-LLM 模型评测智能体：基于 12 步工作流与八项防幻觉机制的大模型评测情报分析。

## 4.2.0 更新

- 完善 CoreSpeechKit 朗读：系统音色查询与切换、默认女声与 `1.5×` 语速、配置持久化。
- 新增可拖动朗读控制条、暂停/继续、关闭、倍速控制和进度跳转。
- 增加 AVSession 与音频播放长时任务，支持后台和锁屏朗读。
- 新增 HarmonyOS 系统分享接收，图片和文件可直接加入待发送附件。
- 修正火山方舟深度思考开关：关闭显式发送 `disabled`，开启显式发送 `enabled`。
- 保留原生语音输入、多 API 配置及 Responses API 多模态直传。

## 常见问题

### API Key 无效

- 检查是否带有多余空格。
- 确认模型、接入方式与 Base URL 匹配。
- 检查账户额度、接口权限和网络连接。

### 文件解析失败

- 确认格式和文件大小受模型接口支持。
- 检查多模态配置是否正确。
- 可以关闭预解析，改用支持附件直传的 Responses API 模型。

### 流式输出中断

- 检查网络稳定性及服务端限流信息。
- 尝试切换 API 配置。
- 对简单问题关闭深度思考可减少响应等待。

### 图库分享列表中没有 Guncat Work

- 确认安装的是包含 Share Kit UTD 声明的最新 HAP。
- 更新安装后重新打开图库分享面板，让系统刷新分享目标。

### 后台朗读停止

- 确认应用通知和后台运行权限未被系统限制。
- 不同机型的后台策略和可用系统音色可能不同。

## 贡献

欢迎提交 Issue 和 Pull Request。

1. Fork 仓库。
2. 创建功能分支。
3. 遵循 ArkTS 编码规范完成修改。
4. 确保项目通过类型检查和 HAP 构建。
5. 提交 Pull Request，并说明修改内容及验证方式。

## 说明

本次版本不包含曾经评估或试验过、但最终撤回的本地 TTS 模型方案；README 仅描述当前代码中实际保留的功能。
