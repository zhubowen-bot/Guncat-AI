---
name: svg
description: 需要生成图片时加载——图标、徽标、示意图、流程图、架构图、信息图、插画、装饰图形，或任务要求"画图/生图/出图/配图"而工作区没有现成素材。任何 write_svg 任务开始前先加载：SVG 绘制规范、预览迭代工作流、可直接套用的配方。
---

# SVG 矢量绘图（生图）

模型不输出位图，但写好 SVG 是基本功：本技能把"手写 SVG"变成一条可靠的生图流水线——**写 → 栅格化 → 看图 → 修正**，直到合格再交付。

## 工具链

| 工具 | 用途 |
|---|---|
| `write_svg(path, svg, width?)` | 保存 `.svg` + 自动栅格化出 `<name>_preview.png`。根元素缺 width/height 时按 viewBox 自动补齐（但仍按模板显式写全，一次成功） |
| `view_image(path)` | 查看预览 PNG——这是你的眼睛，**生成后必看** |
| `write_pptx` | 图片参数可直接引用 `.svg`（导出时自动栅格化） |
| `write_docx` | 图片引用预览 PNG |
| `download_file(url)` | 需要照片级素材（真实照片）时下载现成图片，而不是硬画 |

**分界线**：几何图形、图标、图示、信息图 → SVG 生图；真实世界照片 → `download_file` 找现成图。给"风景照""人像"之类的需求写 SVG 是错误用法。

## 工作流（每张图都走完整循环）

1. **定规格**：这张图放哪（PPT 内页/封面/文档配图/独立交付）？用途决定画布比例与配色（放进 PPT 时配色对齐所选主题，见 ppt 技能的 themes）。
2. **管线验证（新会话首次生图或复杂图必做）**：先用**仅含一个 `<rect>` 的最小 SVG** 走一次 write_svg + view_image，确认管线畅通再全量绘制——栅格/解码类失败一律按"**最小复现 → 增量叠加**"二分定位，不要先读回全文验证语法（刚写入的文件不存在语法损坏）。
3. **写 SVG**：按 `reference/svg-craft.md` 的规范写——根元素带 `xmlns` + `width/height` + `viewBox`，图形优先 path，图标加 `<title>`。
4. **生成**：`write_svg` 一次成型（返回预览 PNG 路径与尺寸；源码缺 width/height 会自动补齐并在返回中注明）。
5. **看图自检**：`view_image` 看预览，对照下方清单逐项检查。
6. **迭代**：有问题直接改 SVG 源码重新 `write_svg`（覆盖同一路径），不要生成一堆 v2/v3 文件；迭代仍失败时回到第 2 步的最小复现定位不兼容特性。
7. **交付**：确认合格后，在交付物里引用它；总结中说明文件路径与用途。

## 最小示例（保存为 assets/arrow-right.svg，可直接验证管线）

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none"
     stroke="#1B2330" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <title>右箭头</title>
  <path d="M5 12h14M13 6l6 6-6 6"/>
</svg>
```

`write_svg` 后得到 `assets/arrow-right.svg` + `assets/arrow-right_preview.png`。

## 配方

24×24 描边图标、填充图标、横向流程图、架构图、信息图卡片、封面装饰、sparkline 等可直接套用的模板见 `reference/svg-recipes.md`（均含 width/height 与 `<title>`）；绘制规范与场景分级见 `reference/svg-craft.md`。

## 交付前自检清单

- [ ] 根元素带 `xmlns`、`width/height`、`viewBox` 三件套？
- [ ] `view_image` 预览看过：无越界、无重叠、无文字截断、缩到小尺寸仍清晰？
- [ ] 图标/信息图带 `<title>` 可访问性标注？
- [ ] 用了 `<text>` 的话预览里渲染正常（字体依赖是最大风险，异常就转 path）？
- [ ] 配色与元素数符合场景分级（图标/信息图从严，卡通插画放宽至 4~6 色、30+ 元素）？
- [ ] 背景透明是否合适（放深色页会看不见深色笔画）？
- [ ] 图形含义准确、没有自造的符号？文件落在合理路径（如 assets/）？
- [ ] 最终交付物引用的是 svg/preview 路径，且路径真实存在？
