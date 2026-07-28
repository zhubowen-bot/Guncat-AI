# Guncat AI

> [English](README_EN.md) | 中文

**原生鸿蒙 AI 对话客户端** — 纯 ArkTS + ArkUI 实现，非 WebView 套壳。

市面上大多数 AI 客户端本质是浏览器套壳，Guncat AI 从 UI 框架到网络通信到 Markdown 渲染全部基于 HarmonyOS 原生能力构建，在性能、交互流畅度和系统集成深度上具备本质差异。

## 🎯 核心亮点

### 🚀 原生 ArkTS 流式对话交互

- **SSE 流式实时通信**：基于 `@kit.NetworkKit` 的 `http.requestInStream` 实现原生 SSE 解析，逐 token 增量更新，非 WebSocket 或轮询方案
- **双协议兼容**：同时支持 OpenAI Chat Completions (`/chat/completions`) 和 Anthropic/火山 Responses API (`/responses`)，适配 Deepseek、火山方舟等多家供应商
- **50ms 节流失效刷新**：流式过程采用 50ms 节流策略 + 33ms UI 可见文本缓冲对齐，避免每 token 触发整块渲染
- **100ms 自动滚动**：流式输出时定时器确保消息列表持续置底，体验对齐 WebChat

### 📝 高级原生 Markdown 渲染

使用 `@luvi/lv-markdown-in` 原生组件（非 WebView 内嵌 HTML），支持：

- **完整 CommonMark + GFM 标准**：标题、列表、引用、代码块、表格等完整 Markdown 语法
- **LaTeX 数学公式**：支持 `$...$` / `$$...$$`，深色/浅色模式自动切换文字色
- **代码语法高亮**：19 种 token 类型的细粒度配色，深/浅模式各有独立的暖色/高饱和配色方案
- **Mermaid 图表**：支持流程图、时序图、甘特图等可视化图表
- **流式增量渲染**：3.3+ 版本优化表格/代码块/插件在流式过程中的闪烁问题
- **表格**：带表头着色、行交错色、边框圆角
- **任务列表**：Todo List 支持
- **全套 UI 样式可编程控制**：标题色、引用块颜色与圆角、超链接下划线、列表点色、行内代码色等

### 🤖 多智能体系统

内置 8 个专业智能体，通过 `resources/rawfile/agents.json` + 独立 Markdown 提示词文件管理：

| 智能体                  | 类别      | 功能描述                    |
| -------------------- | ------- | ----------------------- |
| Guncat 2.0-Flash     | 通用智能体   | 速度与质量平衡的旗舰版本            |
| Guncat 2.0-Pro       | 通用智能体   | 依赖重复推理获得高质量结果           |
| Guncat 2.5-Lite      | 通用智能体   | 结构化思维链&两档推理模式           |
| Guncat 2.5-Max       | 通用智能体   | 结构化思维链&三档推理模式           |
| Guncat Cnvt-Paper    | 论文改写    | 将非论文文体转化为符合学术规范的论文      |
| Guncat Srch-Law      | 法律检索    | 国企法律分析专家，强制多轮检索与结构化法律意见 |
| Guncat Srch-Research | 学术检索    | 跨领域信息检索与多源交叉验证          |
| Guncat Srch-Sift     | AI 信息筛选 | 官方溯源与 AI 内容过滤           |

### 📁 多模态文件解析

上传图片或文档后，通过 GLM-4.6V-Flash（智谱 API）多模态解析，支持：

- **图片**：PNG/JPEG/WebP/GIF
- **文本文档**：TXT/MD/JSON/TS/JSX/TSX/HTML/CSS/CSV/LOG/YAML/ 及多种编程语言
- **Office 文档**：PDF/DOC/DOCX/XLS/XLSX/PPT/PPTX

**智能解析特性**：

- 解析失败自动重试（最多 4 次，800ms 间隔）
- 文件间 200ms 交错解析避免并发限流
- 支持图片预览和文档内容提取
- 实时解析状态显示（解析中/已就绪/失败）

### 🎨 原生主题系统

基于 HarmonyOS 资源框架实现完整 Light/Dark 主题，非 CSS 变量模拟：

- 使用 `dark/element/color.json` + `base/element/color.json` 资源限定符
- `EntryAbility` 通过 `onConfigurationUpdate` 回调监听系统主题切换
- 通过 `AppStorage` 传播 `systemColorMode` 状态到所有组件
- 状态栏/导航栏颜色随主题自动适配
- Markdown 代码主题、数学公式颜色同步切换

### 💾 智能持久化系统

基于 `@kit.ArkData` Preferences API（对标 Web 的 localStorage）：

- 对话历史与配置均以 JSON 序列化存储
- 自动保存当前对话状态和智能体选择
- 支持多对话管理和切换
- 配置信息本地持久化，重启应用自动恢复

## 📁 项目结构

```
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets           # 应用入口 Ability
├── entrybackupability/
│   └── EntryBackupAbility.ets     # 备份恢复 Ability
├── pages/
│   └── ChatPage.ets               # 主页面：消息列表 + Header + 输入区 + 抽屉
├── views/
│   ├── ChatBubbleView.ets         # 聊天气泡（用户/助手）
│   ├── RichTextView.ets           # 原生 Markdown 渲染封装
│   ├── MessageInputView.ets       # 消息输入栏
│   ├── AgentDrawerView.ets        # 智能体/对话侧边抽屉
│   ├── SettingsPanel.ets          # API 配置弹层
│   ├── ImageLightbox.ets          # 图片灯箱
│   ├── FilePreviewBar.ets         # 文件预览条
│   ├── ToastView.ets              # 轻提示
│   └── AboutPanel.ets             # 关于弹层
├── viewmodel/
│   └── ChatViewModel.ts           # 核心状态管理（MVVM 层）
├── service/
│   ├── ChatService.ts             # SSE 流式网络请求
│   ├── MultimodalService.ts       # 多模态文件解析
│   ├── FileService.ts             # 文件选择与读取
│   ├── AgentLoader.ts             # 智能体配置加载
│   ├── TextReaderService.ts       # 鸿蒙朗读服务（TTS）
│   └── VoiceInputService.ets      # 鸿蒙语音识别服务（ASR）
├── model/
│   ├── Message.ts                 # 消息模型（@Observed）
│   ├── Conversation.ts            # 对话模型
│   ├── Agent.ts                   # 智能体模型
│   ├── ApiConfig.ts               # API 配置
│   ├── ApiProfile.ts              # API 配置档（多配置管理）
│   ├── MultimodalConfig.ts        # 多模态配置
│   └── Attachment.ts              # 附件模型
├── data/
│   └── StorageManager.ts          # Preferences 持久化层
├── common/
│   ├── Types.ts                   # 共享类型定义
│   ├── Utils.ts                   # 工具函数
│   └── Constants.ts               # 全局常量
└── components/
    └── ToggleSwitch.ets           # 开关胶囊组件
```

## 🏗️ 技术架构

采用类 **MVVM 架构**：

### 架构层次

- **Model** (`model/`)：纯数据类，`@Observed` 装饰器让属性变更可追踪
- **ViewModel** (`viewmodel/ChatViewModel.ts`)：集中管理所有状态与业务逻辑，内部维护 `version` 计数器驱动 UI 刷新
- **View** (`views/` + `pages/`)：无状态 UI 组件，通过 `@Prop` / `@ObjectLink` / `@Link` 绑定 VM 数据

### 数据流

```
ChatService (SSE) → ChatViewModel → @Observed Message.content → @ObjectLink ChatBubbleView → RichTextView（原生 Markdown 渲染）
```

### 核心组件说明

1. **ChatViewModel** - 核心状态管理器
   
   - 管理对话列表、智能体选择、API配置
   - 处理消息发送、流式响应、文件解析
   - 实现持久化存储和状态恢复

2. **ChatService** - 网络通信层
   
   - 实现SSE流式通信协议
   - 支持Chat Completions和Responses API双协议
   - 处理连接管理、错误处理、中断支持

3. **MultimodalService** - 多模态解析服务
   
   - 调用智谱GLM-4.6V-Flash API
   - 支持图片、文本、Office文档解析
   - 实现重试机制和并发控制

4. **StorageManager** - 持久化层
   
   - 基于Preferences API实现本地存储
   - 管理对话历史、配置信息、智能体状态

## 🛠️ 构建与运行

### 环境要求

- **开发工具**：DevEco Studio 5.0+ 
- **HarmonyOS SDK**：API 12+
- **系统版本**：HarmonyOS 5.0+
- **设备**：真机或模拟器

### 构建步骤

```bash
# 1. 克隆项目
git clone <repository-url>

# 2. 使用 DevEco Studio 打开项目根目录

# 3. 确保已安装 HarmonyOS SDK API 12+

# 4. 连接真机或启动模拟器

# 5. 点击 Run 或使用命令行：
hvigorw assembleHap

# 6. 安装到设备
hvigorw installHap
```

### 配置说明

#### API 配置

在应用设置中配置以下参数：

1. **Provider**：选择 `deepseek`、`volcano` 或 `custom`
2. **Base URL**：API 端点地址
3. **API Key**：有效的 API 密钥
4. **Model**：使用的模型名称

#### 预设配置

- **Deepseek 预设**：
  
  - Base URL: `https://api.deepseek.com`
  - Model: `deepseek-chat`

- **火山方舟预设**：
  
  - Base URL: `https://ark.cn-beijing.volces.com/api/v3`
  - Model: 根据实际使用填写

#### 多模态配置

- **Base URL**：`https://open.bigmodel.cn/api/paas/v4`（默认）
- **Model**：`glm-4.6v-flash`（默认）
- **API Key**：智谱 API 密钥

## 📦 依赖

### 核心依赖

- `@luvi/lv-markdown-in: ^3.4.5` — 原生 Markdown 渲染组件
- HarmonyOS API 12+ (`@kit.NetworkKit`, `@kit.ArkData`, `@kit.BasicServicesKit`, `@kit.CoreFileKit`)

### 系统能力

- **网络通信**：HTTP/HTTPS 请求、SSE 流式传输
- **数据存储**：Preferences API 本地持久化
- **文件管理**：文件选择、读取、Base64 编码
- **UI 组件**：ArkUI 声明式 UI、动画、主题适配

## 🎮 使用指南

### 基本使用流程

1. **启动应用**：首次启动会自动加载默认智能体
2. **配置 API**：点击右上角设置按钮，配置 API 密钥
3. **选择智能体**：点击左上角菜单按钮，选择适合的智能体
4. **开始对话**：在输入框输入问题，点击发送

### 高级功能

#### 1. 文件上传与解析

- 点击输入框左侧的附件按钮
- 选择图片或文档文件
- 等待解析完成（状态显示"已就绪"）
- 文件内容会自动附加到消息中

#### 2. 深度思考模式

- 开启后，AI 会进行更深入的推理
- 适合复杂问题分析和学术研究

#### 3. 联网搜索

- 仅火山方舟 Provider 支持
- 开启后，AI 可以搜索最新信息

#### 4. 对话管理

- **新建对话**：在抽屉中点击"新建对话"
- **切换对话**：在抽屉中选择历史对话
- **删除对话**：长按或右键删除对话

#### 5. 消息操作

- **复制文本**：长按消息选择复制
- **重新生成**：点击助手消息的重新生成按钮
- **图片预览**：点击图片消息进行全屏预览

### 快捷操作

- **自动滚动**：流式输出时自动置底
- **主题切换**：跟随系统深色/浅色模式
- **配置持久化**：所有设置自动保存

## 🔧 常见问题解答

### 1. API Key 无效怎么办？

- 检查 API Key 是否正确复制，注意前后空格
- 确认 API Key 是否过期或额度用尽
- 检查网络连接是否正常

### 2. 文件解析失败如何处理？

- 检查文件大小是否超过 20MB 限制
- 确认文件格式是否受支持
- 检查多模态 API 配置是否正确
- 应用会自动重试，等待片刻后重试

### 3. 流式输出卡顿怎么办？

- 检查网络连接稳定性
- 尝试切换不同的 API Provider
- 关闭深度思考模式减少计算量

### 4. 如何更新应用？

- 重新构建并安装 HAP 包
- 对话历史和配置会自动保留

### 5. 支持哪些设备？

- 支持 HarmonyOS 5.0+ 的手机、平板设备
- 需要足够的存储空间（建议 100MB+）

## 🛡️ 安全与隐私

- **本地存储**：所有数据存储在设备本地
- **API 密钥**：仅用于调用 AI 服务，不会上传到其他服务器
- **文件处理**：文件在设备本地处理，不会持久化存储原始文件
- **网络通信**：使用 HTTPS 加密传输

## 🔄 版本历史

### version 4 (当前版本)

- 全新原生 ArkTS 架构
- 支持多智能体系统
- 多模态文件解析
- 原生 Markdown 渲染
- 适配鸿蒙朗读控件，新增自动朗读 (v 4.1.0)
- 适配鸿蒙语音识别控件，新增语音输入 (v 4.1.0)
- 新增多配置保存、自由切换模型配置 (v 4.1.0)
- 新增多模态模型 Response API 图片/文件直传功能 (v 4.1.0)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发环境搭建

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m 'Add some amazing feature'`
4. 推送到分支：`git push origin feature/amazing-feature`
5. 创建 Pull Request

### 代码规范

- 遵循 ArkTS 编码规范
- 使用有意义的变量和函数名
- 添加必要的注释说明
- 确保代码通过类型检查

---

**Guncat AI** — 让 AI 对话更原生、更流畅、更智能！
