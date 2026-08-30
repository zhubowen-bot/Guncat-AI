# Deck JSON 完整语法

Deck = `{"title": 元数据标题, "theme": 主题id, "themeOverride": {…}, "slides": [页]}`。
页上限 80 页；超长用 deck_file 分块写 + `edit_ppt` 的 add_slide 追加。所有参数都是字符串型工具参数，deck 值为 JSON 文本。

## 页面公共字段（所有版式通用）

| 字段 | 类型 | 说明 |
|---|---|---|
| layout | string | 版式，见下表 |
| title | string | 页标题 |
| subtitle | string | 副标题（cover/section/end 显示） |
| notes | string | 演讲者备注（写入 pptx 备注页） |
| background | object | `{color, image, fit, overlay}`；color 为语义色/hex，image 为图片 src，overlay 0~1 深色遮罩 |

## 13 种版式与专属字段

**cover** 封面：title（大字）、subtitle。可用 background.image 做图底封面（配 overlay 0.4~0.6）。
**toc** 目录：`bullets: ["章节名", …]`（>5 项自动双栏）。
**section** 分节：title（大字）、subtitle；`index:"01"` 可自定义编号，缺省自动编号。
**content** 要点页：`bullets` 数组，元素为字符串或 `{"text":"…","level":2}`（level 2 为二级要点）。
**two-col** 双栏：`left:{heading, bullets:[…]}`, `right:{…}`（或 `columns:[{…},{…}]`）。
**image-text** 图文并排：`image:{src, fit}`、`bullets`、`imageSide:"left"|"right"`（默认右图）。
**image** 单图页：`image:{src, fit}`、`caption`（图注）。
**image-full** 全幅大图：`image:{src}`、`caption`（底部半透明字幕条，title 可替代 caption）。
**table** 表格：`headers:[…]`、`rows:[[…],…]`（≤20 行）、`widths:[0.3,0.7]`（列宽比例，可省略）、`note`（来源注）。
**chart** 图表：
```json
{"layout":"chart","title":"图表标题",
 "chart":{"type":"bar","categories":["类目1","类目2"],
   "series":[{"name":"系列名","values":[1,2]}],
   "showLegend":true,"showValue":false},
 "caption":"数据来源: xx"}
```
type：bar / line / area / pie / doughnut。pie/doughnut 只取第一个 series，≤6 块。
**quote** 引用：`text`（引文）、`author`（署名）。
**end** 结尾：title（默认"谢谢观看"）、subtitle。
**custom** 自由版面：`elements` 数组（≤30 个）：

```json
{"layout":"custom","elements":[
 {"type":"text","x":0.08,"y":0.35,"w":0.5,"h":0.3,"text":"标题",
  "size":32,"bold":true,"color":"primary","align":"left"},
 {"type":"shape","shape":"roundRect","x":0.6,"y":0.3,"w":0.3,"h":0.4,"fill":"surface"},
 {"type":"image","src":"pdf_images/doc/p001.jpg","x":0.6,"y":0.2,"w":0.35,"h":0.6,"fit":"cover"},
 {"type":"table","x":0.1,"y":0.5,"w":0.8,"h":0.4,"headers":["名","值"],"rows":[["A","1"]]}]}
```

custom 坐标为 **0~1 的画布比例**（x/y 左上原点，w/h 宽高），size 单位 pt。color/fill 支持语义色（primary/accent/bg/surface/title/body/sub/faint/white）或 6 位 hex。shape：rect / roundRect / ellipse / triangle / arrow。

## bullets 字号自适应

content 页一级要点 ≤3 条 20pt、≤5 条 18pt、≤7 条 16pt、更多 14pt；二级要点再小 3pt。**这是上限信号：要点超过 7 条必须拆页。**

## 图片 src 三种来源

1. 工作区相对路径：`pdf_images/报告/p001.jpg`（先 list_files 确认存在）
2. data URL：`data:image/png;base64,…`
3. http(s) 链接

限制：单图 ≤10MB；整册 ≤40 张。fit：`contain`（完整显示按比例居中）/ `cover`（填满裁剪）/ `fill`（拉伸）。找不到或无法解码时报错指明页码与 src。

补充：`.svg` 工作区文件可直接作为 src——导出时自动栅格化为 1024px 宽 PNG（配合 svg 技能生成的图标/示意图），无需手工转格式。

## 校验错误

非法 deck 会整册拒绝并返回具体页码与原因（如"第 3 页(layout=chart) 缺少 chart.categories"）——按提示修正后重试即可，不要换用 outline 逃避结构问题。

## Deck 源文件模式（推荐用于长 deck）

1. `write_file("deck.json", 首段)` → `append_file("deck.json", 续段)` 分块写完（每块 ≤512KB）；
2. `write_pptx(path, deck_file:"deck.json")` 导出；
3. 后续修改直接改 deck.json 再导出，或 `edit_ppt` 直接改 pptx。

deck.json 保留在工作区，是可追溯的版面源文件。
