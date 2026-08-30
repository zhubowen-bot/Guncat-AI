---
name: data
description: 处理表格/结构化数据时加载——CSV/JSON 清洗、去重、拆列、合并、正则提取、格式互转（CSV/TSV/JSON/Markdown 表格/XLSX）、大文件本地转换，或任何 transform_file 任务开始前。管道 ops 与表达式完整语法、三类场景配方、限额与自检清单。
---

# 数据清洗与转换（transform_file）

大文件与非标数据的唯一处理手段：**数据不经过模型上下文**，你写"管道"（steps），本地求值器执行。小表格（十几行）直接 `write_file`/`write_csv` 更快，不要滥用。

## 工具链与工作流

| 工具 | 用途 |
|---|---|
| `transform_file(input, steps)` | **预览模式**：执行管道但只回前 3 行效果——第一次调用永远这样 |
| `transform_file(input, steps, output)` | 确认无误后写盘（.csv/.tsv/.json/.md/.xlsx/.txt） |
| `read_file(path)` | 写盘后抽查前几行确认结果 |
| `write_csv` / `write_xlsx` | 小表格直接生成时用（数据走上下文）；大表用 transform_file 输出 |

1. `read_file` 看输入文件前几十行，确认列名/分隔符/脏数据模式；
2. 写 steps，**省略 output 预览**；
3. 预览对 → 加 output 写盘；预览不对 → 修改 steps 重试（报错信息含行列定位，照着修）；
4. `read_file` 抽查输出。

## 输入格式（format 省略时自动识别）

| format | 内容 | 说明 |
|---|---|---|
| `csv` | 逗号/分号分隔 | RFC 4180 引号字段正确解析；`delimiter` 可显式指定单字符；`has_header` 默认 true |
| `tsv` | 制表符分隔 | 同上 |
| `md` | Markdown 表格 | `\|` 分隔，首行即表头 |
| `json` | JSON | 顶层数组或对象；`json_path: "data.items"` 定位数组（数字段为 0 起下标） |
| `jsonl` | 每行一个 JSON | |
| `lines` | 纯文本行 | 每行一条记录，单列 `line`（正则提取的常用入口） |

## 数据模型

统一为「表头 + 字符串单元格」。列引用两种写法：`col('年龄')`（需表头）或 `col(2)`（1 起列号，无表头时唯一选择）。`rownum()` 返回当前 1 起行号。

## 表达式语法（filter/derive/map/sort 的 expr 字段）

- 字面量：数字 `18`、字符串 `'待定'` 或 `"待定"`、`true`/`false`/`null`；字符串内转义 `\n` `\t` `\'` `\\`
- 运算符：`+ - * / %`、`== != < <= > >=`（`=` 宽松按 `==`）、`&& || !`；`+` 任一侧为文本时做拼接
- 比较规则：两侧都能解析成数字 → 数值比较；否则按文本比较。**等值比较不忽略空格**，脏数据先 `trim()`
- 数字解析（`num()` 与数值上下文共用）：去首尾空白、剥离千分位逗号与 `￥$€£¥` 前缀后前缀解析；解析不出得 NaN——比较按文本、算术传播 NaN、filter 中视为假。`'12%'` 不会自动转数字，先 `regex_replace(col('x'), '%$', '')`
- 空值：单元格缺失即空串 `''`，用 `is_empty(col('x'))` 判断

## 函数表

| 函数 | 说明 |
|---|---|
| `trim(s)` `upper(s)` `lower(s)` `len(s)` `str(v)` | 文本基础 |
| `substr(s, start, end?)` | 0 起、含头不含尾 |
| `replace(s, old, new)` | 字面量**全部**替换 |
| `regex_replace(s, pattern, repl)` | 正则全部替换，repl 支持 `$1` |
| `matches(s, pattern)` | 正则测试（部分匹配即真），返回布尔 |
| `extract(s, pattern, group?)` | 首个匹配的第 group 组（默认 0=整个匹配），无匹配返回 `''` |
| `split(s, sep)` / `join(arr, sep)` | sep 是字面量；split 结果通常立刻 join 或取 extract |
| `num(s)` `round(n, d?)` `abs` `floor` `ceil` `min(a,b,…)` `max(a,b,…)` | 数值 |
| `if(cond, a, b)` `coalesce(v1, v2, …)` | coalesce 返回第一个非空（`''`/null/NaN 视为缺失） |
| `is_empty(v)` `starts_with` `ends_with` `contains` | 判断 |
| `col('名')` `col(1)` `rownum()` | 数据引用 |

## ops 全表（steps 数组元素）

| op | 参数 | 说明 |
|---|---|---|
| `filter` | `expr` | 保留真值行（`''`/0/null 视为假） |
| `derive` | `name, expr` | 追加计算列 |
| `map` | `col, expr` | 重算某列（可引用自身） |
| `select` | `cols`, `optional?` | 保留/重排列；`optional: true` 时缺失列跳过 |
| `drop` | `cols` | 删除列 |
| `rename` | `from, to` | 改列名（需表头） |
| `set_header` | `names` | 为无表头数据定义列名（个数=列数） |
| `promote_header` | — | 首行数据提升为表头（当前无表头时） |
| `sort` | `expr, desc?` | 排序，空值恒排最后 |
| `limit` / `skip` | `n` | 截取/跳过 |
| `dedupe` | `keys?` | 按整行（或指定列）去重，保留首个 |
| `drop_empty` | — | 剔除全空行 |
| `fill` | `col?, value` | 填充空单元格 |
| `trim` | `cols?` | 去首尾空白（缺省全部列） |
| `replace` | `col?, find, replace, regex?` | 单元格替换（缺省全部列） |
| `extract` | `col, pattern, name?, group?` | 正则提取为新列 |
| `split_col` | `col, sep, names` | 拆列；任何行拆出段数超过 names 即报错 |
| `to_num` | `cols?` | 列数值化（解析失败置空） |

列引用统一为：列名字符串或 1 起数字（如 `"cols": ["姓名", 3]`）。

## 配方

**① CSV 清洗 → 规范 CSV**

```json
{"input":"客户名单.csv","steps":[
  {"op":"trim"},
  {"op":"filter","expr":"col('手机号') != '' && matches(col('手机号'), '^1\\d{10}$')"},
  {"op":"to_num","cols":["消费额"]},
  {"op":"fill","col":"城市","value":"未知"},
  {"op":"dedupe"},
  {"op":"sort","expr":"num(col('消费额'))","desc":true}
],"output":"客户名单_清洗.csv"}
```

**② 从文本提取结构（正则）**

```json
{"input":"日志.txt","format":"lines","steps":[
  {"op":"extract","col":"line","pattern":"\\[(\\d{4}-\\d{2}-\\d{2})\\]","name":"日期","group":1},
  {"op":"extract","col":"line","pattern":"耗时 (\\d+)ms","name":"耗时ms","group":1},
  {"op":"select","cols":["日期","耗时ms"]},
  {"op":"filter","expr":"num(col('耗时ms')) > 500"}
],"output":"慢请求.csv"}
```

**③ JSON → 表格**

```json
{"input":"接口返回.json","json_path":"data.orders","steps":[
  {"op":"rename","from":"create_time","to":"下单时间"},
  {"op":"select","cols":["下单时间","amount","status"]}
],"output":"订单.xlsx"}
```

## 限额与限制

- 输入 ≤2MB 文本、≤10 万行、≤512 列；steps ≤30 步；xlsx 输出 ≤5 万行（更大用 csv）
- 输入按 UTF-8 读取；GBK 等编码的旧文件请先让用户转码
- 单元格全是字符串：数字比较依赖自动解析，金额/百分比等脏格式先 `to_num`/`regex_replace`
- 求值无任何 I/O 与网络：管道只能变换数据，取文件用 `input`，写文件用 `output`

## 交付前自检清单

- [ ] 先预览后写盘，写盘后 `read_file` 抽查过？
- [ ] 列名与输入完全一致（空格/全半角）？报错"列不存在"时优先核对列名
- [ ] 数字列做过 `to_num` 或比较用 `num()`？百分比/千分位先清理？
- [ ] 去重/过滤的口径与用户要求一致（保留哪条、空值算不算）？
- [ ] 输出格式匹配下游用途（给 Excel 用 csv+bom 或直接 xlsx；给程序读的 json/csv 用 `bom: false`）？
