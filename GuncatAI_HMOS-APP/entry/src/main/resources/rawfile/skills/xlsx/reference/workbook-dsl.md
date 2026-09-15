# Workbook JSON 完整语法（write_xlsx / read_xlsx / edit_xlsx 的中间层）

生成 Excel = 写 Workbook JSON → 渲染；编辑 Excel = read_xlsx 还原 → 应用算子 → 重建。
**正式表格一律用本结构**；table 文本只适合一次性简单表。

## 1. 顶层结构

```json
{
  "name": "月度经营表",
  "style": "default",
  "sheets": [ ... ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `name` | string | 否 | 工作簿名（≤64 字符），缺省 "Guncat 工作簿" |
| `style` | string | 否 | 表头配色：`default`（蓝灰表头）/ `academic`（浅灰）/ `minimal`（浅灰淡字） |
| `sheets` | array | 是 | 工作表数组，1~20 个（`WORK_XLSX_MAX_SHEETS`） |

## 2. 工作表

```json
{
  "name": "收入",
  "headers": ["月份", "线上", "线下", "合计"],
  "rows": [
    ["1月", 120000, 80000, "=SUM(B2:C2)"],
    ["合计", "=SUM(B2:B3)", "=SUM(C2:C3)", "=SUM(D2:D3)"]
  ],
  "colWidths": [12, 14, 14, 14],
  "freeze": "A2",
  "formats": ["text", "money", "money", "money"]
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `name` | string | 是 | 工作表名（≤31 字符，全簿唯一） |
| `headers` | string[] | 否 | 表头行：加粗 + 主题底纹；列数必须与 rows 一致 |
| `rows` | array | 是 | 数据行（不含表头），**矩形**（每行列数一致），≥1 行，≤1000 行/60 列 |
| `colWidths` | number[] | 否 | 每列宽 1~255，长度 ≤ 列数；缺省 14 |
| `freeze` | string | 否 | 冻结窗格：单元格地址如 `"A2"`（冻结首行）/ `"B1"`（冻结首列）/ `"B2"`（冻结前两行首列） |
| `formats` | string[] | 否 | 每列数字格式 hint（见下表），长度 ≤ 列数 |

## 3. 单元格值

| 值 | 类型 | 说明 |
|---|---|---|
| `120000` | number | 数字（金额/数量/比率，比率存小数） |
| `"1月"` | string | 文本 |
| `"=SUM(B2:B9)"` | string（以 = 开头） | **公式**：Excel 原生公式，打开自动计算；公式内不要带前导 = 外的引号问题（普通写法即可） |

规则：
- 单元格值**只能是数字或字符串**；布尔/null/对象会报错。
- 公式示例：`"=SUM(B2:B9)"`、`"=B2*C2"`、`"=D2/(1+E2)"`、`"=IF(B2>0,B2,0)"`、跨表 `"=假设!B2"`（表名含空格时用单引号：`"='销售数据'!D2"`）。
- 数字上限：单格文本 ≤32767 字符；数字需有限（非 NaN/Infinity）。
- 字符串里想换行：直接写 `\n`（渲染为单元格内换行）。

## 4. 数字格式（formats）

| hint | 显示效果 | 典型用途 |
|---|---|---|
| `money` | ¥12,345.00 / (¥12,345.00) / - | 金额：报表数字列、合计行 |
| `number` | 12,345.67 | 千分位两位小数（通用数值） |
| `int` | 12,345 | 数量：员工数、件数 |
| `percent` | 12.5% | 比率：增长率、毛利率（**值存小数**：0.08 = 8%，禁止存 8） |
| `year` | 2024 | 年份列（`0` 格式，防止显示成 2,024） |
| `date` | 3/21/2026 | 日期列（值需为 Excel 日期序列号或由公式产生） |
| `text` / `plain` | 原样 | 文本/无格式（缺省） |

- 负数金额显示为括号 `(¥1,234.00)`；零值显示为 `-`（稀疏报表习惯）。全簿保持一致。
- `formats` 按列给；没给该列就按 General 显示。

## 5. edit_xlsx 算子表

`ops` 为 JSON 数组，一次 ≤50 个，整批生效（任一非法则全部不生效并报错）。
`sheet` 一律用**工作表名**；`row`/`index`/`from`/`to` 从 **1** 起；`col` 是列号（1=A）。

> **坐标约定（重要）**：`row`/`index` 按**数据行**从 1 起算，**不含表头**——与 `read_xlsx` 返回的 `rows` 数组一一对应：`row:1` = 第一个数据行（有表头时它在 Excel 里显示为第 2 行）；`row:2` = 第二个数据行（Excel 第 3 行）。表头是独立的 `headers` 字段，改表头单元格用 `set_header`，不能用 `set_cell`（会报"越界"或改到数据行）。

| op | 参数 | 说明 |
|---|---|---|
| `set_name` | `name` | 改工作簿名 |
| `set_style` | `style` | 改表头样式 default/academic/minimal |
| `set_sheet_name` | `sheet, name` | 重命名工作表 |
| `add_sheet` | `sheet{name,headers?,rows,...}, index?` | 追加或插入工作表（index 缺省追加） |
| `delete_sheet` | `sheet` | 删除工作表（不能删最后一个） |
| `move_sheet` | `sheet, to` | 移动工作表到第 to 位 |
| `add_row` | `sheet, row:[...], index?` | 追加或插入数据行（列数必须与现有列数一致） |
| `delete_row` | `sheet, index` | 删除数据行 |
| `update_row` | `sheet, index, row:[...]` | 整行覆盖 |
| `set_cell` | `sheet, row, col, value` | 改单个数据单元格（value 数字/字符串/公式；row 不含表头） |
| `set_header` | `sheet, col, value` | 改单个表头单元格（value 文本；表头不能放公式） |
| `replace_text` | `find, replace` | 全簿文本替换（跳过公式与数字） |

示例：

```json
[
  {"op":"set_cell","sheet":"收入","row":2,"col":2,"value":135000},
  {"op":"add_row","sheet":"收入","row":["3月",110000,70000,"=SUM(B4:C4)"],"index":3},
  {"op":"add_sheet","sheet":{"name":"费用","headers":["科目","金额"],"rows":[["房租",5000],["水电",1200]],"formats":["text","money"]}},
  {"op":"set_header","sheet":"收入","col":2,"value":"电商收入"},
  {"op":"replace_text","find":"线上","replace":"电商"}
]
```

## 6. 限制（超出即报错，报错带表名/行/列号）

- 工作表 ≤20 个；单表数据行 ≤1000、列 ≤60；行必须矩形。
- 表头列数 = 数据列数；工作表名唯一。
- 外来 xlsx 导入上限：5000 行/100 列/20MB（超出截断或拒绝）。

## 7. 与旧 table 文本的关系

`table`（Markdown 表格/CSV/TSV）输入仍可用：首行作表头、纯数字字符串转数字、单表 Sheet1、无公式无格式。
需要公式/格式/多表时用 `workbook`。
