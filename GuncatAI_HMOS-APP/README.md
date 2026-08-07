# Guncat AI

> 中文 | [English](README_EN.md)

Guncat AI 是使用 ArkTS 与 ArkUI 开发的原生 HarmonyOS AI 对话客户端，不使用 WebView 承载主界面。

当前应用版本：`4.3.1`

## 主要功能

### 原生流式对话

- 基于 `@kit.NetworkKit` 和 `http.requestInStream` 处理 SSE 流式响应。
- 支持 OpenAI Chat Completions（`/chat/completions`）和火山方舟 Responses API（`/responses`）。
- 支持 DeepSeek、火山方舟及兼容接口的自定义服务。
- 支持停止生成、重新生成、对话历史管理和多套 API 配置。
- 流式输出采用节流刷新与自动滚动，减少频繁重绘。

### 深度思考与联网搜索

- 深度思考按钮会显式控制火山方舟请求：
  - 关闭：`thinking.type = disabled`
  - 开启：`thinking.type = enabled`
- 按钮状态优先于额外请求参数，避免界面状态与实际请求不一致。
- 火山方舟配置支持 Web Search 工具。
- 深度思考和联网搜索状态会持久化保存。

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
- 可选择预解析附件，或通过 Responses API 直接传递多模态内容。
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
- 从图库或文件管理器选择“分享”后，可以选择 Guncat AI。
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

## 内置智能体

智能体通过 `resources/rawfile/agents.json` 和独立 Markdown 提示词文件管理：

| 智能体 | 类别 | 功能 |
| --- | --- | --- |
| Guncat 2.0-Flash | 通用 | 兼顾速度与质量的通用智能体 |
| Guncat 2.0-Pro | 通用 | 面向高质量分析与复杂任务 |
| Guncat 2.5-Lite | 通用 | 结构化思考与轻量推理 |
| Guncat 2.5-Max | 通用 | 更完整的结构化多阶段推理 |
| Guncat Cnvt-Paper | 论文改写 | 将普通文本转换为符合学术规范的论文文体 |
| Guncat Srch-Law | 法律检索 | 多轮法律检索与结构化法律意见 |
| Guncat Srch-Research | 学术检索 | 跨领域检索及多来源交叉验证 |
| Guncat Srch-Sift | AI 信息筛选 | 官方来源追踪与 AI 信息过滤 |
| Guncat Eval-LLM | 模型评估 | 基于 12 步工作流与八项防幻觉机制的大模型评测情报分析 |

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

项目采用类似 MVVM 的分层方式：

- View：ArkUI 页面与组件。
- ViewModel：集中管理聊天、附件、配置和持久化状态。
- Service：负责 SSE、文件解析、系统分享、TTS 和 ASR 等能力。
- Model：消息、对话、附件、智能体及 API 配置模型。

### 数据流

```text
ChatService (SSE)
  → ChatViewModel
  → @Observed Message
  → @ObjectLink ChatBubbleView
  → RichTextView
```

### 核心组件

1. **ChatViewModel**
   - 管理对话列表、智能体选择、API 配置和输入状态。
   - 处理消息发送、流式响应、附件解析与重新生成。
   - 负责持久化存储和状态恢复。

2. **ChatService**
   - 实现 SSE 流式通信和请求中断。
   - 支持 Chat Completions 与 Responses API。
   - 解析增量回答并处理网络及服务端错误。

3. **MultimodalService**
   - 处理图片、文本、PDF 和 Office 文档。
   - 支持预解析、重试与并发控制。
   - 支持 Responses API 图片和文件直传。

4. **StorageManager**
   - 封装 Preferences 本地存储。
   - 管理对话、配置、开关和朗读偏好。

5. **TextReaderService / BackgroundReaderService**
   - 查询和管理 CoreSpeechKit 音色。
   - 管理朗读、暂停、进度跳转与语速。
   - 通过 AVSession 和长时任务维持后台音频会话。

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
2. 使用 DevEco Studio 打开 `GuncatAI` 目录。
3. 安装并选择 HarmonyOS SDK API 24。
4. 配置调试或发布签名。
5. 连接 HarmonyOS 真机。
6. 运行 `entry` 模块，或使用上述命令构建 HAP。

## 配置

应用设置中可保存并切换多套 API 配置：

1. Provider
2. Base URL
3. API Key
4. Model
5. Temperature、Top P、最大输出 Token 等可选参数
6. 额外请求参数

火山方舟默认地址：

```text
https://ark.cn-beijing.volces.com/api/v3
```

多模态预解析可单独配置模型、地址和 API Key。

## 使用指南

### 基本对话

1. 首次启动后打开设置。
2. 新建或选择 API 配置，填写 Provider、Base URL、API Key 和模型名称。
3. 从侧边栏选择智能体。
4. 输入消息并发送。

### 添加图片或文件

1. 点击输入框旁的附件按钮。
2. 从图片选择器或文件选择器选择内容。
3. 等待预解析完成；关闭预解析时，附件会在发送时直接传给支持多模态的接口。
4. 检查待发送附件后，由用户主动发送。

也可以在图库或文件管理器中选择内容，通过系统“分享”选择 Guncat AI。应用只会把内容放入待发送附件，不会自动提交请求。

### 深度思考

- 关闭按钮会显式发送 `thinking: { "type": "disabled" }`。
- 打开按钮会显式发送 `thinking: { "type": "enabled" }`。
- 适用于支持该参数的火山方舟 Responses API 模型。

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
- 确认模型、Provider 与 Base URL 匹配。
- 检查账户额度、接口权限和网络连接。

### 文件解析失败

- 确认格式和文件大小受模型接口支持。
- 检查多模态配置是否正确。
- 可以关闭预解析，改用支持附件直传的 Responses API 模型。

### 流式输出中断

- 检查网络稳定性及服务端限流信息。
- 尝试切换 API 配置。
- 对简单问题关闭深度思考可减少响应等待。

### 图库分享列表中没有 Guncat AI

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
