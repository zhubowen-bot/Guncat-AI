# Guncat AI Web for API 鸿蒙版

这是 Guncat AI Web for API 的H5应用鸿蒙适配版本。

---

Web for API 版本：3.1.0

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
