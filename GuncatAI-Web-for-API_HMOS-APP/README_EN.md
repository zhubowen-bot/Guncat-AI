# Guncat AI Web for API - HarmonyOS Version

> 中文 | [English](README_EN.md)

This is the HarmonyOS-adapted H5 application version of Guncat AI Web for API.

---

Web for API Version: 3.1.0

2026.7.7 Fixed bugs with duplicate message input and errors after terminating conversations.

---

## Tech Stack

Built on the Bowen_ArkWeb Framework V1.2, using H5 embedded construction.

Original site:

[Guncat AI Web](https://guncat-ai-platform.netlify.app)

Bowen_ArkWeb Framework:

[Bowen_ArkWeb_framework](https://github.com/zhubowen-bot/Bowen_ArkWeb_framework)

Used under the [Apache-2.0 License](https://github.com/zhubowen-bot/Bowen_ArkWeb_framework?tab=Apache-2.0-1-ov-file#).

Since HTTP protocol is required for cross-origin calls to JSON and Markdown prompt files, the app accesses the web version instead of loading HTML locally. Due to unstable Netlify site access from within China, JSON and Markdown files are localized as follows.

## Web Loading Optimization

Based on the Bowen_ArkWeb Framework V1.2, loading optimizations were applied to the ArkWeb application, primarily covering "pre-connect" and "local resource interception replacement" — the two highest-impact optimization points.

### Modifications from the Original Framework

**1. [EntryAbility.ets](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/entryability/EntryAbility.ets#L14-L25) — Pre-connection**

- Retains existing `initializeWebEngine()` and BFCache.
- Adds pre-connection for the homepage `guncat-ai-platform.netlify.app` and two CDN sources `cdnjs.cloudflare.com` and `cdn.jsdelivr.net`, completing DNS + TCP handshake in advance.

**2. [Index.ets](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/pages/Index.ets#L315-L352) — Local Resource Interception**

- Added `buildLocalResponse()` to directly replace Netlify requests for `agents.json`, all `.md` prompt files, and `cat-avatar(1).png` with `rawfile` local copies, eliminating network latency for these fixed resources.
- Connected [`.onInterceptRequest()`](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/pages/Index.ets#L522-L529) on the Web component.

**3. [Index.ets](file:///c:/Users/a1519/Documents/GuncatAI-HMOS/entry/src/main/ets/pages/Index.ets#L356-L677) — Rendering & Caching**

- Added `renderMode: RenderMode.ASYNC_RENDER` to the Web constructor.
- Added `.cacheMode(CacheMode.Default)` to let the kernel reuse resources per standard HTTP caching policy.

Diagnostics check passed with no errors.

### Notes

- Locally intercepted `agents.json`, `.md`, and avatar files must remain consistent with the Netlify online version; remember to sync updates to `rawfile` after updating the website.
