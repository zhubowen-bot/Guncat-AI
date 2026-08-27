# Guncat AI Release

> [English](README_EN.md) | 中文

> 平台部署版提示词

本目录存放**针对特定平台能力做过适配**的提示词与部署资源，可直接用于腾讯元器、智谱清言等平台智能体的创建与运行。其中 **Guncat 3.0 系列（Pro / Flash / Mini）** 为平台无关的通用提示词，同时作为 Web 端与鸿蒙端 `agents.json` 提示词库的权威副本。

> 如需**通用泛化**提示词（不绑定平台特性、可自主配置 API），请使用项目根目录下的 [Guncat AI Web for API](../Guncat%20AI%20Web%20for%20API/)。

---

## 目录结构

```
Guncat AI Release/
├── Guncat 2.0/                          # 腾讯元器部署用提示词
│   ├── Guncat 2.0-flash-main_agent_prompt.md
│   └── Guncat 2.0-pro-main_agent_prompt .md
├── Guncat 2.5/                          # 腾讯元器部署用提示词（Sequential Thinking 版）
│   ├── Guncat 2.5-lite _prompt.md
│   └── Guncat 2.5-max _prompt.md
├── Guncat 3.0/                          # 3.0 系列通用提示词（Pro / Flash / Mini，中英双语）
│   ├── Guncat 3.0-Pro_prompt_ZH_CN.md
│   ├── Guncat 3.0-Pro_prompt_EN.md
│   ├── Guncat 3.0-Flash_prompt_ZH_CN.md
│   ├── Guncat 3.0-Flash_prompt_EN.md
│   ├── Guncat 3.0-Mini_prompt_ZH_CN.md
│   └── Guncat 3.0-Mini_prompt_EN.md
├── Guncat Cnvt/                         # 论文改写智能体提示词
│   └── Guncat Cnvt-Paper_prompt.md
├── Guncat Srch/                         # 信息检索智能体提示词（法律 / 研究 / 筛滤）
│   ├── Guncat Srch-Law V1.0-prompt.md
│   ├── Guncat Srch-Research-prompt.md
│   └── Guncat Srch-Sift-prompt.md
├── Guncat Eval/                         # 模型评测情报分析智能体提示词
│   └── Guncat Eval-LLM_prompt.md
└── LICENSE
```

---

## 提示词使用方式

### 腾讯元器

1. 进入 [腾讯元器](https://yuanqi.tencent.com/) 创建智能体。
2. 将对应版本的 `.md` 提示词完整复制到「系统提示词」或「人设与回复逻辑」中。
3. 根据提示词内声明的工具需求，在元器中配置对应的插件/工作流。
4. 发布后即可通过元器平台对话或 API 调用。

### 智谱清言

1. 进入 [智谱清言](https://chatglm.cn/) 创建智能体。
2. 将对应版本的 `.md` 提示词完整复制到智能体配置中。
3. 如需调用外部搜索或工具，请按提示词说明开启对应能力。

---

## 注意事项

- 本目录下除 `Guncat 3.0/` 外的提示词**包含平台特定语法、工具名和调用约定**，直接移植到其他平台可能出现行为不一致。
- `Guncat 3.0/` 中的提示词为**通用（平台无关）版本**，与 [Guncat AI Web for API](../Guncat%20AI%20Web%20for%20API/) 及两个鸿蒙应用 `rawfile/` 中的同名提示词保持一致；修改后请同步更新，避免多端加载旧版本。
- 若希望跨平台使用同一套提示词，或需要自定义 API，请使用 [Guncat AI Web for API](../Guncat%20AI%20Web%20for%20API/)。
- 修改提示词后，如果同时维护 [GuncatAI-Web-for-API_HMOS-APP](../GuncatAI-Web-for-API_HMOS-APP/)，请同步更新其 `entry/src/main/resources/rawfile/` 中的同名文件，避免鸿蒙端加载旧版本。

---

## 许可证

MIT License
