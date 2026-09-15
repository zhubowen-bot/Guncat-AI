---
name: xlsx
description: Excel 表格制作/修改/分析技能: Workbook JSON 语法、公式优先、数字格式、编辑完整性。任何 write_xlsx / read_xlsx / edit_xlsx 任务先加载。
---

# Excel 表格制作与编辑

## 何时用

- 生成/重建 `.xlsx`（报表、预算、经营数据、统计表、清单、财务模型）→ `write_xlsx`
- 读回已有 `.xlsx` 的内容用于仿制/分析 → `read_xlsx`
- 对已有 `.xlsx` 改单元格/加行/加表/替换文字 → `edit_xlsx`
- 触发词：Excel、表格、报表、预算、明细、统计、透视、xlsx、财务模型

## 工具链

- `write_xlsx(path, workbook?, workbook_file?, table?, name?, style?)`：三选一输入。
  **正式表格一律用 `workbook`（Workbook JSON）**——支持多工作表、表头、公式、数字格式、列宽、冻结窗格；
  `workbook_file` 先 `write_file`/`append_file` 分块写好 JSON 再导出（长表）；
  `table`（Markdown 表格/CSV/TSV）只适合一次性简单表，首行作表头、无公式无格式。
- `read_xlsx(path)`：读回 Workbook JSON。本应用生成的文件无损还原；外来 xlsx 近似导入（数值/文本/公式还原，样式细节丢失）。编辑前**先读它**。
- `edit_xlsx(path, ops)`：ops 为 JSON 数组（详见 workbook-dsl.md 的算子表）。外来文件自动备份 `*_原版备份.xlsx`。
- 数据来源：工作区已有文件（CSV/JSON/xlsx）用 `read_file`/`read_xlsx` 读取；大文件清洗转换用 `transform_file`（load_skill("data")）。
- 图片不进入 xlsx（Excel 嵌入图片本环境不支持）。

## 工作流 A：新建工作簿

1. `list_files` 看工作区有没有可复用的数据文件；有就先读。
2. 规划工作表结构：sheet 名（≤31 字符、唯一）、每列含义与数字格式、哪些列是公式。
3. **公式优先**：合计/同比/比率等派生值必须写成公式（`"=SUM(B2:B9)"`、`"=B2*C2"`），不要手算成数字——Excel 里改数自动联动，这也是财务表格的硬规范。
4. 组织 `workbook` JSON（语法见 `reference/workbook-dsl.md`），直接传 `write_xlsx`；长表先 `write_file` 写 JSON 文件再用 `workbook_file` 导出。
5. 交付前 `read_xlsx` 抽查：表名、行数、关键单元格、公式是否在。

最小示例（含公式 + 数字格式 + 表头）：

```json
{
  "name": "月度经营表",
  "sheets": [{
    "name": "收入",
    "headers": ["月份", "线上", "线下", "合计"],
    "rows": [
      ["1月", 120000, 80000, "=SUM(B2:C2)"],
      ["2月", 150000, 95000, "=SUM(B3:C3)"],
      ["合计", "=SUM(B2:B3)", "=SUM(C2:C3)", "=SUM(D2:D3)"]
    ],
    "formats": ["text", "money", "money", "money"],
    "freeze": "A2"
  }]
}
```

## 工作流 B：编辑已有工作簿

1. `read_xlsx(path)` 拿到当前 Workbook JSON（外来文件会提示"近似导入"）。
2. 按目标写 `ops` 数组，**一次调用完成一批操作**（单次 ≤50 个）：
   - **坐标约定**：`row`/`index` 按**数据行**从 1 起算、不含表头（与 read_xlsx 的 rows 一一对应）；有表头时 `row:1` 在 Excel 里显示为第 2 行。改表头单元格用 `set_header`。
   - 改单元格：`{"op":"set_cell","sheet":"收入","row":2,"col":2,"value":999}`
   - 改表头：`{"op":"set_header","sheet":"收入","col":2,"value":"电商收入"}`
   - 加行（插到第 3 位）：`{"op":"add_row","sheet":"收入","row":["3月",110000,70000,"=SUM(B4:C4)"],"index":3}`
   - 加表：`{"op":"add_sheet","sheet":{"name":"费用","headers":["科目","金额"],"rows":[["房租",5000]]}}`
   - 全局改词：`{"op":"replace_text","find":"线上","replace":"电商"}`
3. `edit_xlsx(path, ops)` 执行，返回摘要后 `read_xlsx` 抽查。
4. 外来文件改前会自动备份 `*_原版备份.xlsx`，不要删它。

## 速查：Workbook JSON

顶层 `{name?, style?, sheets[]}`；style：default / academic / minimal（表头配色）。
每 sheet：`{name, headers?, rows, colWidths?, freeze?, formats?}`。

- `rows`：二维数组，**矩形**（每行列数一致）；单元格值 = 数字 | 字符串 | `"=公式"`。
- `headers`：可选，有则首行加粗+底纹，列数必须与 rows 一致。
- `formats`：可选，每列数字格式 hint：`money`（¥千分位两位小数）、`int`（千分位整数）、`percent`（0.0%）、`year`（年份不加千分位）、`date`（m/d/yyyy）、`number`（千分位两位小数）、`text`/`plain`（默认）。
- `colWidths`：可选每列宽 1~255；`freeze`：可选如 `"A2"`（冻结首行）或 `"B1"`（冻结首列）。

## 能力边界（重要：不要承诺做不到的功能）

**支持**：多工作表（≤20）、表头加粗底纹、公式（SUM/引用/跨表）、数字格式（money/int/percent/year/date/number）、列宽、冻结窗格、read_xlsx 读回与 edit_xlsx 编辑。

**不支持**（用户要求时**明确说明做不到**，并给替代方案）：
- 合并单元格、条件格式、数据验证（下拉/范围限制）
- Excel 图表、数据透视表、宏、公式锁定/工作表保护
- 单元格样式细节（字体/底色/边框/对齐/行高、斜体加粗）
- 图片嵌入、超链接、批注
- 外来 xlsx 的样式保留（近似导入只还原数值/文本/公式；样式与合并丢失）

替代思路：条件格式/数据验证这类"防呆"需求 → 在表头或备注行写明填写规范；样式需求 → 在交付说明里描述期望样式，让用户用 Excel 一键加样式。

## 排版与数据规范（详见 reference/format-guide.md）

- **公式优先**：派生值必须是公式，禁止硬编码计算结果；合计行用 `SUM` 公式。
- **数字格式**：金额用 `money`、比率用 `percent`（存小数如 0.08 = 8%，不要存 8）、年份用 `year`（防 2024 变 2,024）、数量用 `int`。
- **小数纪律**：要求两位小数就整列 `money`/`number`，不要出现 12875 混 12875.00。
- **假设与模型分离**（财务模型）：假设集中放一个 sheet（如"假设"），模型区只写引用假设的公式，不写死数字。
- **编辑完整性**：只改目标单元格/行，不动其它数据；交付前 read_xlsx 验证表名与抽样数据还在。

## 交付前自检清单

> **QA 心态**：第一次输出几乎总有问题——按"找 bug"的心态复验，一次就找到 0 个问题说明没认真找；**至少完成一轮「发现问题→修复→复验」再交付**。

- [ ] 所有派生值都是公式（合计/同比/比率），没有手算数字？
- [ ] 金额列用了 money/number 格式？比率列存的是小数并配 percent？
- [ ] 年份列用 year（不会显示成 2,024）？
- [ ] 表名唯一、≤31 字符；数据矩形？
- [ ] 无占位残留：不含 xxxx/lorem/ipsum/待填/TODO？
- [ ] 有表头且列数与数据一致？
- [ ] read_xlsx 抽查过最终文件（表名/行数/关键值/公式）？
- [ ] 外来文件编辑前自动备份存在？
