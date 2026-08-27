# Guncat AI Release

> [中文](README.md) | English

> Platform-Deployed Prompts

This directory contains **platform-adapted prompts and deployment resources**, ready for direct use in creating and running agents on platforms such as Tencent Yuanqi and ZhipuAI ChatGLM. The **Guncat 3.0 series (Pro / Flash / Mini)** are platform-independent universal prompts and serve as the authoritative copy of the prompt library used by the Web and HarmonyOS `agents.json` clients.

> For **generic, platform-independent** prompts (not tied to platform features, with customizable API), please use [Guncat AI Web for API](../Guncat%20AI%20Web%20for%20API/) in the project root directory.

---

## Directory Structure

```
Guncat AI Release/
├── Guncat 2.0/                          # Tencent Yuanqi deployment prompts
│   ├── Guncat 2.0-flash-main_agent_prompt.md
│   └── Guncat 2.0-pro-main_agent_prompt .md
├── Guncat 2.5/                          # Tencent Yuanqi deployment prompts (Sequential Thinking version)
│   ├── Guncat 2.5-lite _prompt.md
│   └── Guncat 2.5-max _prompt.md
├── Guncat 3.0/                          # 3.0-series universal prompts (Pro / Flash / Mini, CN + EN)
│   ├── Guncat 3.0-Pro_prompt_ZH_CN.md
│   ├── Guncat 3.0-Pro_prompt_EN.md
│   ├── Guncat 3.0-Flash_prompt_ZH_CN.md
│   ├── Guncat 3.0-Flash_prompt_EN.md
│   ├── Guncat 3.0-Mini_prompt_ZH_CN.md
│   └── Guncat 3.0-Mini_prompt_EN.md
├── Guncat Cnvt/                         # Paper rewriting agent prompts
│   └── Guncat Cnvt-Paper_prompt.md
├── Guncat Srch/                         # Information retrieval agent prompts (Legal / Research / Sift)
│   ├── Guncat Srch-Law V1.0-prompt.md
│   ├── Guncat Srch-Research-prompt.md
│   └── Guncat Srch-Sift-prompt.md
├── Guncat Eval/                         # LLM evaluation intelligence analysis agent prompts
│   └── Guncat Eval-LLM_prompt.md
└── LICENSE
```

---

## How to Use Prompts

### Tencent Yuanqi

1. Go to [Tencent Yuanqi](https://yuanqi.tencent.com/) and create an agent.
2. Copy the corresponding `.md` prompt content into the "System Prompt" or "Persona & Response Logic" section.
3. Configure the required plugins/workflows in Yuanqi as specified in the prompt.
4. After publishing, you can chat via the Yuanqi platform or API.

### ZhipuAI ChatGLM

1. Go to [ZhipuAI ChatGLM](https://chatglm.cn/) and create an agent.
2. Copy the corresponding `.md` prompt content into the agent configuration.
3. If external search or tools are needed, enable the corresponding capabilities as specified in the prompt.

---

## Notes

- Except for `Guncat 3.0/`, prompts in this directory **contain platform-specific syntax, tool names, and invocation conventions**; direct migration to other platforms may result in inconsistent behavior.
- The prompts in `Guncat 3.0/` are **universal (platform-independent)** and kept in sync with the identically named prompts in [Guncat AI Web for API](../Guncat%20AI%20Web%20for%20API/) and both HarmonyOS apps' `rawfile/`; sync them when modified to avoid any client loading outdated versions.
- For cross-platform use of the same prompt set, or for custom API configuration, please use [Guncat AI Web for API](../Guncat%20AI%20Web%20for%20API/).
- If you modify prompts and also maintain [GuncatAI-Web-for-API_HMOS-APP](../GuncatAI-Web-for-API_HMOS-APP/), please synchronize updates to the corresponding files in `entry/src/main/resources/rawfile/` to avoid the HarmonyOS app loading outdated versions.

---

## License

MIT License
