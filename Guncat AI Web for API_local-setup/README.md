# Guncat AI Web for API_local-setup- 可配置 API 的对话客户端的windows本地启动版本

> [English](README_EN.md) | 中文

---

Web for API 版本：3.2.0

2026.8.6 对齐鸿蒙版新增功能：多套配置方案（自定义切换模型）、附件直传火山、自动朗读、语音输入
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
    ├── cat-avatar(1).png               # 应用图标
    ├── Guncat 2.0-flash-main_agent_prompt.md
    ├── Guncat 2.0-pro-main_agent_prompt .md
    ├── Guncat 2.5-lite _prompt.md
    ├── Guncat 2.5-max _prompt.md
    ├── Guncat Cnvt-Paper_prompt.md
    ├── Guncat Srch-Law V1.0-prompt.md
    ├── Guncat Srch-Research-prompt.md
    ├── Guncat Srch-Sift-prompt.md
    └── Guncat Eval-LLM_prompt.md

### agents.json 配置示例

    {
      "agents": [
        {
          "id": "guncat-2.5-max",
          "name": "Guncat 2.5-Max",
          "description": "Guncat 2.5 通用智能体中最强大的版本，结构化思维链&三档推理模式",
          "category": "通用智能体",
          "promptFile": "Guncat 2.5-max _prompt.md"
        },
        {
          "id": "guncat-cnvt-paper",
          "name": "Guncat Cnvt-Paper",
          "description": "论文转换专家，将非论文文体转化为符合学术规范的论文",
          "category": "改写智能体",
          "promptFile": "Guncat Cnvt-Paper_prompt.md"
        }
      ]
    }

每个智能体配置包含：

* `id`：唯一标识
* `name`：显示名称
* `description`：功能描述
* `category`：分类（通用智能体/检索智能体/改写智能体/评估智能体）
* `promptFile`：对应的提示词文件路径

### 核心能力

* **智能体切换**：通过侧边栏抽屉切换不同 Guncat 智能体（2.0/2.5 通用智能体、Srch 检索智能体、Cnvt 改写智能体、Eval 评估智能体）
* **Markdown 渲染**：完整支持 Markdown 语法，包括代码高亮、表格、列表、引用等
* **流式输出**：支持 AI 回复的打字机效果流式显示
* **深度思考 / 联网搜索开关**：界面提供工具开关，用户可手动开启或关闭深度思考、联网搜索等功能
* **配置方案（自定义切换模型）**：支持保存多套命名 API 配置方案（每套含主模型与多模态配置），可通过输入框上方的模型选择胶囊或设置面板随时切换，旧版单配置自动迁移为默认方案
* **附件直传**：多模态解析支持"先行解析"与"直传"两种模式，直传模式下图片和文档直接随请求发送给支持多模态的火山方舟主模型
* **自动朗读**：支持开启自动朗读回复，或点击消息下方的"朗读"按钮播报任意 AI 回复，可暂停、调速（基于浏览器 TTS）
* **语音输入**：输入框左侧麦克风按钮支持语音转文字输入（基于浏览器语音识别，仅支持 Chrome/Edge 等内核）
* **新建对话**：支持清空上下文，开始新的对话会话
* **历史对话**：支持保存历史对话并查看
* **文件解析**：支持配置专门的多模态API，解析纯文本模型不能解析的文件和图片
* **API 配置**：用户可在界面中配置自己的 API Key、Base URL 和模型名称，支持Chat API和Response API两种配置方式，支持自定义高级模型参数（长度控制、Top P等），以及自定义json请求体

### 如何新增智能体

1. 将新智能体的提示词保存为 `.md` 文件，放入 `Guncat API version/` 目录
2. 在 `agents.json` 中新增一个对象，填写 `id`、`name`、`description`、`category`、`promptFile`
3. 重启客户端或刷新浏览器页面，新智能体即可出现在侧边栏中

### 技术栈

* **前端**：纯 HTML/CSS/JavaScript，无框架依赖
* **渲染**：Marked.js（Markdown 渲染）+ Highlight.js（代码高亮），新增Latex公式渲染（2.0.0版本后）。
* **移动端**：WebView 包装为 Android APK
* **API 协议**：OpenAI 兼容的 `/v1/chat/completions` 接口
