---
name: ppt
description: 用 Deck JSON 制作与编辑 PPT（write_pptx / read_ppt / edit_ppt）
---

# PPT 制作与编辑

## 工具链

| 工具 | 用途 |
|---|---|
| `write_pptx(path, deck | deck_file | outline, theme?, title?)` | 生成/重建 .pptx（16:9） |
| `read_ppt(path)` | 读回 Deck JSON 源（自家文件无损；外来文件近似导入） |
| `edit_ppt(path, ops)` | 结构化编辑已有 .pptx（增删页/改内容/换主题/全文替换） |

图片来源只能是：工作区已有文件（用户上传、`pdf_to_images` 的 `pdf_images/` 产物）、data URL 或 http(s) 链接。`.svg` 文件可直接引用（导出时自动栅格化）；需要照片级素材用 `download_file` 下载到工作区；需要图标/示意图用 `write_svg` 生成（见 svg 技能）。**禁止编造不存在的图片路径**——先用 list_files 确认。

## 工作流 A：新建演示文稿

1. **规划页面节奏**：封面(cover) → 目录(toc，≥6 页时) → 分节(section) → 内容(content/two-col/table/chart/image-text) → 结尾(end)。内容页占大头，分节页隔开章节。
2. **写 Deck JSON**。速查最小例：

```json
{"title":"Q3 经营复盘","theme":"brand-blue","slides":[
 {"layout":"cover","title":"Q3 经营复盘","subtitle":"2026-08 · 经营分析组"},
 {"layout":"toc","bullets":["业绩概览","问题分析","下季度计划"]},
 {"layout":"section","title":"业绩概览"},
 {"layout":"content","title":"核心指标全面达标","bullets":[
   "营收 1.2 亿，同比 +18%","新增客户 3,240 家",{"text":"华东区贡献 42%","level":2}]},
 {"layout":"chart","title":"月度营收趋势","chart":{"type":"bar",
   "categories":["4月","5月","6月"],"series":[{"name":"营收(百万)","values":[36,39,45]}]}},
 {"layout":"end","title":"谢谢","subtitle":"欢迎讨论"}]}
```

3. **生成**：≤10 页直接 `write_pptx` 传 `deck`；更长先 `write_file("deck.json", …)` 分块写好（后续 `append_file` 续写），再 `write_pptx` 传 `deck_file:"deck.json"`。
4. **自检**（生成后必做，见文末清单）；有问题用 `edit_ppt` 修正或改 deck 后重新导出。

## 工作流 B：编辑已有 PPT

1. `read_ppt(path)` 读回源（外来文件注意提示中的近似导入说明）。
2. 小改：`edit_ppt` 用 `replace_text`（全文改词）/`update_slide`（改单页）/`add_slide`/`delete_slide`/`move_slide`。
3. 换风格：`edit_ppt` 传 `{"op":"set_theme","theme":"midnight"}`。
4. 用户上传外来 pptx 要求"照着做"：`read_ppt` 读回近似源 → 参考其内容用工作流 A 重做（版式会更精致）。

## 版式速选

| 版式 | 何时用 |
|---|---|
| cover / end | 首页 / 收尾（end 自动品牌色整版） |
| toc | ≥6 页时给目录 |
| section | 章节隔页（大字 + 编号，自动编） |
| content | 默认内容页（要点列表） |
| two-col | 对比/双栏要点 |
| table | 结构化数据（≤20 行） |
| chart | 数据趋势(bar/line/area)与占比(pie/doughnut) |
| image-text | 图文并排 |
| image / image-full | 单图展示 / 全幅大图 |
| quote | 引用金句 |
| custom | 自由版面（绝对定位元素，坐标 0~1） |

字段级语法（必填项、chart/table/image 全字段、custom 元素、背景、备注）：`load_skill("ppt","reference/deck-dsl.md")`。

## 设计规范（摘要，全文见 reference/design-guide.md）

- 每页只讲一个任务；**标题写结论**（"营收 +18%" 而非 "营收情况"）。
- 每页要点 3~7 条、每条一句话；多了拆页，不要塞满。
- 图表选型：趋势→line，对比→bar，占比→pie（≤5 块）。数据必须来自工作区资料，注明来源（放 caption）。
- 禁止 AI 腔与黑话（"赋能""闭环""综上所述""不是X而是Y"）；用具体名词和数字。
- 图片不凑数：没有合适图片就用纯版式，好过无关配图。

## 主题

8 套预设：brand-blue（默认商务蓝）/ midnight（深色科技）/ forest（墨绿）/ sunset（暖橙）/ violet（紫）/ graphite（极简灰）/ ivory（学术米白）/ crimson（红）。全表与自定义主题：`load_skill("ppt","reference/themes.md")`。

## 交付前自检清单

- [ ] 页面节奏完整（封面开头、end 收尾；≥6 页有 toc）？
- [ ] 每页要点 3~7 条、每条一句话？标题是结论句？
- [ ] chart/table 的数字与工作区资料一致？来源标注了？
- [ ] 引用的图片路径都真实存在（list_files 确认过）？
- [ ] read_ppt 或 read_file 抽查过最终文件内容？
- [ ] 无 AI 腔、无编造数据？
