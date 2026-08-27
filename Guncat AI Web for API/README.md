# Guncat AI Web for API - 可配置 API 的对话客户端的 Windows 本地启动版本

> [English](README_EN.md) | 中文

---

Web for API 版本：5.2.1

2026.8.27 版本升至 **5.2.1**：新增 **Guncat 3.0-Mini（轻简模式）** 并置于智能体列表首位（`agents.json` 中 3.0-Mini 排在 3.0-Flash 之前）——基于 3.0-Flash 进一步精简打造的小型全能智能体，核心变化是移除了输出丰富性原则，代之以**任务适配输出原则**：回答长度由任务复杂度与用户需求决定，简单对话简洁自然、标准任务中等篇幅、复杂任务充分展开，恰如其分而不堆砌；完整保留 3.0-Flash 的三层一体架构、极速/标准双档模式、工具调用方法论与反幻觉体系
2026.8.26 深度思考开关按协议显式控制（对齐 DeepSeek 官方参数）：OpenAI Completions `thinking.type = enabled/disabled` + `reasoning_effort = high`；Anthropic Messages `thinking.type = enabled/disabled` + `output_config.effort = high`；OpenAI Responses `reasoning.effort = high/none`（`none` 关闭思考）；联网搜索开启时多轮对话自动回传上一轮 assistant 的 `reasoning_content`，避免 400。新建对话按智能体名称重置深度思考默认值：效率模式（3.0-Flash）默认关闭、轻简模式（3.0-Mini）默认关闭、专家模式（3.0-Pro）默认开启
2026.8.26 智能体体系升级：新增 **Guncat 3.0-Flash（效率模式）** 与 **Guncat 3.0-Pro（专家模式）**（3.0 系列单体化超级智能体基座），2.5-Lite 更名「经典模式」；各领域专家统一为「转换专家 / 检索专家 / 评估专家-领域」命名；移除 2.0 系列提示词文件；侧边栏智能体支持独立图标（`agents.json` 新增 `icon` 字段，图标按智能体 id 存放于 `icons/` 目录，未配置时回退默认猫头像）；描述拆分为 `description`（新建对话页展示完整版）与 `shortDescription`（侧边栏展示短版）
2026.8.24 同步鸿蒙 APP 5.1.1：系统提示词最前面自动拼接今天的日期（运行时获取本地日期，跨天自动更新），OpenAI Completions / OpenAI Responses / Anthropic Messages 三种协议统一生效
2026.8.23 同步鸿蒙 APP 5.1.0：新增深度思考（推理过程）展示（OpenAI Completions / OpenAI Responses / Anthropic Messages 三种协议增量解析，默认折叠、点击头部展开，思考条右侧实时显示 token 速度与缓存命中率）；设置页移除「快速选择接入方式」快捷预设板块，接入协议统一通过「接入方式」下拉框选择
2026.8.23 同步鸿蒙 APP 5.0.0：接入方式统一为三种主流协议（OpenAI Completions / OpenAI Responses / Anthropic Messages），旧配置自动迁移；DeepSeek 升级 Responses API（原生联网搜索、图片直传、Files API `file_id` 混合上传）；表格识别页改为动态展示所有配置方案的主模型与多模态解析模型，兼容 DeepSeek 视觉输出；更新应用图标资源（文件名不变）；全新柔和现代 UI（低饱和配色、大圆角、白色轻立体按钮、柔和阴影），模型切换菜单选项统一宽度居中
2026.8.8 新增表格提取工具：图片表格识别为 HTML/Excel（保留合并单元格与行高）
2026.8.6 对齐鸿蒙版新增功能：多套配置方案（自动保存模型切换）、附件直传火山、自动朗读、语音输入
2026.7.7 修复了重复输入消息和终止对话后报错的Bug

---



Guncat AI Web for API 是 Guncat 智能体框架的**自定义配置客户端方案**，采用"配置即智能体"的设计理念：所有智能体信息通过 `agents.json` 进行配置，提示词统一以外部 `.md` 文件存储。

由于涉及到跨域启动，file://协议无法读取外部json，因此windows本地启动版本加入了bat文件，点击即可启动Http服务，方便小白用户开箱即用。

### 核心设计理念

* **配置即智能体**：不将提示词硬编码到客户端代码中，而是通过 `agents.json` 定义智能体列表，通过 `promptFile` 字段指向外部 `.md` 提示词文件
* **提示词外部化**：所有提示词以 Markdown 文件形式存储在客户端目录中，便于独立更新、版本管理和热替换
* **API 可配置**：用户可自选任意兼容 OpenAI API 格式的大模型服务（如 OpenAI、Azure、智谱、通义千问、DeepSeek 等），客户端仅负责界面与对话管理
* **H5跨平台多端覆盖**：采用html开发，可直接进行H5应用多端部署适配

### 项目结构

    Guncat AI Web for API
    ├── agents.json                     # 智能体列表配置
    ├── index.html                      # Web 版入口
    ├── table-ocr.html                  # 表格提取工具（图片→HTML/Excel）
    ├── cat-avatar(1).png               # 应用图标
    ├── icons/                          # 侧边栏智能体图标（按智能体 id 命名的 png）
    ├── Guncat 2.5-lite _prompt.md
    ├── Guncat 2.5-max _prompt.md
    ├── Guncat 3.0-Flash_prompt_ZH_CN.md # 中文版
    ├── Guncat 3.0-Flash_prompt_EN.md    # English version
    ├── Guncat 3.0-Mini_prompt_ZH_CN.md  # 中文版
    ├── Guncat 3.0-Mini_prompt_EN.md     # English version
    ├── Guncat 3.0-Pro_prompt_ZH_CN.md   # 中文版
    ├── Guncat 3.0-Pro_prompt_EN.md      # English version
    ├── Guncat Cnvt-Paper_prompt.md
    ├── Guncat Srch-Law V1.0-prompt.md
    ├── Guncat Srch-Research-prompt.md
    ├── Guncat Srch-Sift-prompt.md
    └── Guncat Eval-LLM_prompt.md

### agents.json 配置示例

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

每个智能体配置包含：

* `id`：唯一标识
* `name`：显示名称
* `description`：功能描述（新建对话欢迎页展示的完整版）
* `shortDescription`：短描述（侧边栏列表展示；未配置时回退 `description`）
* `icon`：侧边栏独立图标路径（`icons/` 目录下的 png，建议正方形、≥128×128；未配置时回退猫头像）
* `category`：分类（通用智能体/检索智能体/改写智能体/评估智能体）
* `promptFile`：对应的提示词文件路径

### 核心能力

* **智能体切换**：通过侧边栏抽屉切换不同 Guncat 智能体（3.0 系列：效率模式 / 轻简模式 / 专家模式，2.5 经典模式，转换专家 / 检索专家 / 评估专家各领域专家），每个智能体可配置独立图标与双描述
* **Markdown 渲染**：完整支持 Markdown 语法，包括代码高亮、表格、列表、引用等
* **流式输出**：支持 AI 回复的打字机效果流式显示
* **深度思考 / 联网搜索开关**：界面提供工具开关，用户可手动开启或关闭深度思考、联网搜索等功能；新建对话时按智能体名称重置深度思考默认值（效率模式默认关闭、轻简模式默认关闭、专家模式默认开启）
* **配置方案（自定义切换模型）**：支持保存多套命名 API 配置方案（每套含主模型与多模态配置），可通过输入框上方的模型选择胶囊或设置面板随时切换，旧版单配置自动迁移为默认方案
* **附件直传**：多模态解析支持"先行解析"与"直传"两种模式；直传模式下图片和文档直接随请求发送给当前接入方式的主模型（三种协议均支持），并按鸿蒙 5.1.0 混合策略处理：小图 Base64 内联，大图（>4MB）/ OpenAI Responses 文档自动上传 Files API 后以 `file_id` 引用，上传失败自动回退 Base64
* **自动朗读**：支持开启自动朗读回复，或点击消息下方的"朗读"按钮播报任意 AI 回复，可暂停、调速（基于浏览器 TTS）
* **语音输入**：输入框左侧麦克风按钮支持语音转文字输入（基于浏览器语音识别，仅支持 Chrome/Edge 等内核）
* **新建对话**：支持清空上下文，开始新的对话会话
* **历史对话**：支持保存历史对话并查看
* **文件解析**：支持配置专门的多模态API，解析纯文本模型不能解析的文件和图片
* **API 配置**：用户可在界面中配置自己的 API Key、Base URL 和模型名称。接入方式统一为三种主流协议（对齐鸿蒙 5.1.0）：`openai-completions`（/chat/completions）、`openai-responses`（/responses，DeepSeek / 火山方舟等兼容服务）、`anthropic-messages`（/messages，兼容 DeepSeek Anthropic 端点）；旧 provider 配置（custom/deepseek/volcano）自动迁移。深度思考按协议显式控制（OpenAI Completions `thinking.type` + `reasoning_effort`、OpenAI Responses `reasoning.effort`（`none` 关闭）、Anthropic Messages `thinking.type` + `output_config.effort`），联网搜索按协议发送对应工具定义；支持自定义高级模型参数（长度控制、Top P等）以及自定义 json 请求体
* **表格提取**：侧边栏"智能体"分类下的"表格提取"工具入口，基于视觉大模型将表格图片识别为可编辑的 HTML 表格并导出 Excel（.xlsx），忠实保留合并单元格（rowspan/colspan）、空白书写行高信息与单元格内换行，支持渲染预览 / HTML 代码 / 网格结构 / 调试信息多视图。模型下拉框动态展示所有配置方案的主模型和多模态解析模型（去重），识别时直接使用所选模型对应的 Base URL / API Key，无需重复填写；兼容 DeepSeek 视觉输出（自动关闭思考模式、全角尖括号归一化、Markdown 表格兜底）

### 如何新增智能体

1. 将新智能体的提示词保存为 `.md` 文件，放入客户端目录
2. 在 `agents.json` 中新增一个对象，填写 `id`、`name`、`description`、`category`、`promptFile`（可选：`shortDescription` 短描述、`icon` 独立图标——将 png 放入 `icons/` 目录并以智能体 id 命名）
3. 重启客户端或刷新浏览器页面，新智能体即可出现在侧边栏中

### 维护：智能体深度思考默认值

新建对话（或打开空对话）时，客户端按智能体**名称**重置深度思考开关，配置位于 `index.html`：

- `AGENT_THINKING_DEFAULT_BY_NAME` 映射：键为智能体 `name`，值为布尔（`false` = 默认关闭，`true` = 默认开启）
- 当前默认值：效率模式 `false`、轻简模式 `false`、专家模式 `true`；未列入映射的智能体不重置开关（沿用上一次状态）
- 调整方式：直接修改该映射中对应智能体名称的取值，或新增一行即可；以名称匹配而非 `id`，便于将来改名

### 技术栈

* **前端**：纯 HTML/CSS/JavaScript，无框架依赖
* **渲染**：Marked.js（Markdown 渲染）+ Highlight.js（代码高亮），新增Latex公式渲染（2.0.0版本后）。
* **移动端**：WebView 包装为 Android APK
* **API 协议**：OpenAI `/chat/completions`、OpenAI `/responses`、Anthropic `/messages` 三种协议（5.0.0 起）
