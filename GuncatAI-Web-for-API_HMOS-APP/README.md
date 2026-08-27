# Guncat AI Web for API 鸿蒙版

> [English](README_EN.md) | 中文

这是 Guncat AI Web for API 的H5应用鸿蒙适配版本。

---

Web for API 版本：5.2.1

2026.8.27 同步 Web for API 5.2.1：新增 **Guncat 3.0-Mini（轻简模式）** 并置于智能体列表首位——基于 3.0-Flash 进一步精简，移除输出丰富性原则、代之以任务适配输出原则（回答长度由任务复杂度决定，简单对话简洁自然、复杂任务充分展开）；rawfile 同步更新 `agents.json`、双语提示词与独立图标
2026.8.26 同步 Web for API 5.2.0：深度思考开关按协议显式控制（OpenAI Completions / Anthropic Messages 使用 `thinking.type`，OpenAI Responses 使用 `reasoning.effort = high/none`）；新建对话按智能体名称重置深度思考默认值（效率模式默认关闭、专家模式默认开启）
2026.8.24 同步 Web for API 5.1.1：系统提示词最前面自动拼接今天的日期（运行时获取本地日期，跨天自动更新），三种协议统一生效
2026.8.23 同步 Web for API 5.1.0：新增深度思考（推理过程）展示（三种协议增量解析，默认折叠点击展开，思考条右侧实时显示 token 速度与缓存命中率）；设置页移除「快速选择接入方式」快捷预设板块，接入协议统一通过「接入方式」下拉框选择
2026.7.7 修复了重复输入消息和终止对话后报错的Bug

---

## 技术栈

基于Bowen_ArkWeb 框架 V1.2 构建，采用H5嵌套构建。

原站点：

[Guncat AI Web](https://guncat-ai-platform.netlify.app)

Bowen_ArkWeb 框架：

[Bowen_ArkWeb_framework](https://github.com/zhubowen-bot/Bowen_ArkWeb_framework)

基于[Apache-2.0 license](https://github.com/zhubowen-bot/Bowen_ArkWeb_framework?tab=Apache-2.0-1-ov-file#)协议使用

因为必须要http协议才能跨域调用json和md提示词，因此没有采用本地直接加载html的形式，而是访问网页端实现。由于netlify站点国内访问不稳定，因此采取本地化json和md的方式，如下。

## Web加载优化

在Bowen_ArkWeb 框架 V1.2的基础上，根据文档对 ArkWeb 应用做了加载优化，主要覆盖「预连接」和「本地资源拦截替换」两个收益最高的点。

### 相比原始框架的修改

**1. [EntryAbility.ets](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/entryability/EntryAbility.ets#L14-L25) — 预连接**

- 保留已有的 `initializeWebEngine()` 与 BFCache。
- 对首页 `guncat-ai-platform.netlify.app` 以及两个 CDN 源 `cdnjs.cloudflare.com`、`cdn.jsdelivr.net` 做预连接，提前完成 DNS + TCP 握手。

**2. [Index.ets](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/pages/Index.ets#L315-L352) — 本地资源拦截**

- 新增 `buildLocalResponse()`，把 `agents.json`、所有 `.md` 提示词文件、`cat-avatar(1).png` 的 Netlify 请求直接替换为 `rawfile` 本地副本，消除这些固定资源的网络耗时。
- 在 Web 组件上接入 [`.onInterceptRequest()`](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/pages/Index.ets#L522-L529)。

**3. [Index.ets](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/pages/Index.ets#L356-L677) — 渲染与缓存**

- Web 构造函数增加 `renderMode: RenderMode.ASYNC_RENDER`。
- 增加 `.cacheMode(CacheMode.Default)`，让内核按标准 HTTP 缓存策略复用资源。

Diagnostics 检查无错误。

### 注意事项

- 本地拦截的 `agents.json`、`.md`、头像必须与 Netlify 线上版本保持一致；更新网页后记得同步更新 `rawfile`。
- 智能体深度思考默认值位于 `rawfile/index.html` 的 `AGENT_THINKING_DEFAULT_BY_NAME` 映射（键为智能体 `name`，值为布尔：`false` 默认关闭 / `true` 默认开启）；当前默认：效率模式 `false`、轻简模式 `false`、专家模式 `true`，未列入映射的智能体不重置开关（沿用上次状态）。调整默认值直接修改该映射，并与 Web for API 线上版 `index.html` 保持同步。
