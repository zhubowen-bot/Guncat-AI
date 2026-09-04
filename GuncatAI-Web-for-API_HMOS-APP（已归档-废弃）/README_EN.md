# Guncat AI Web for API - HarmonyOS Version

> [中文](README.md) | English

This is the HarmonyOS-adapted H5 application version of Guncat AI Web for API.

---

Web for API Version: 5.2.1

2026.8.27 Synced with Web for API 5.2.1: added **Guncat 3.0-Mini (Light & Simple Mode)** and placed it first in the agent list — further streamlined from 3.0-Flash, removing the Output Richness Principle in favor of the Task-Adaptive Output Principle (answer length decided by task complexity; light conversation is naturally concise, complex tasks are fully elaborated); rawfile updated with `agents.json`, the bilingual prompts, and the dedicated icon
2026.8.26 Synced with Web for API 5.2.0: deep-thinking toggle now explicitly controls the request per protocol (OpenAI Completions / Anthropic Messages use `thinking.type`, OpenAI Responses uses `reasoning.effort = high/none`); new conversations reset the deep-thinking default by agent name (off in Efficiency Mode, on in Expert Mode)
2026.8.24 Synced with Web for API 5.1.1: today's date is automatically prepended to the system prompt (fetched at runtime from the local date, auto-updates across days), applied uniformly across all three protocols
2026.8.23 Synced with Web for API 5.1.0: new deep-thinking (reasoning) display (incremental parsing for all three protocols, collapsed by default with tap-to-expand, live token speed and cache hit rate shown on the reasoning bar); the settings panel no longer shows the quick-select access-method presets — the protocol is chosen via the Access Method dropdown instead
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
- The per-agent deep-thinking default lives in the `AGENT_THINKING_DEFAULT_BY_NAME` map in `rawfile/index.html` (key = agent `name`, value = boolean: `false` off / `true` on). Current defaults: Efficiency Mode `false`, Light & Simple Mode `false`, Expert Mode `true`; agents not in the map leave the toggle untouched (keeps the previous state). Edit the map to change defaults, keeping it in sync with the online `index.html` of Web for API.
