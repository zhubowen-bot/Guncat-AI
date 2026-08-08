lv-markdown-in 3.4.5 表格渲染闪退排查报告

  一、崩溃现象

  设备：nova 14 Ultra（HarmonyOS 6.1.0.135），应用冷启动进入会话页即闪退，两次崩溃日志完全一致：

  Reason: TypeError
  Error message: Cannot read property forEach of undefined
  Stacktrace:
      at anonymous (TableRender.ts:255:1)
      at anonymous (TableRender.ts:253:26)
      at aboutToAppear (TableRender.ts:252:27)

  HybridStack 中出现两次 BuiltinStub_ArrayForEachStwCopy，说明是嵌套 forEach，内层 forEach 的调用对象为 undefined。异常发生在组件生命周期 aboutToAppear
  内，业务侧无法捕获，进程被直接杀死（Kill Reason: Js Error）。Process life time 仅 10~14 秒——历史消息在冷启动重渲染时必现，与网络、时序无关。

  二、定位方法

  三方库以字节码（.abc）形式发布，无源码可读，采用两步取证：

1. 反编译：用 SDK 自带 ark_disasm 反汇编 ets/modules.abc（3.2MB panda 汇编），还原 TableRender 的完整渲染路径；

2. 数据取证：通过 hdc 拉取应用沙箱的 Preferences 文件（guncat_preferences），从 guncat_conversations 中找到触发闪退的那条历史消息。
   三、根因（反编译证据链）
   TableRender 编译产物中有两个核心遍历函数（源码约 252-256 行）：
   #3812580469706854206#aboutToAppear:          // ≈ 源码 252-253 行
    v0 = this.base
    if (v0 != null && v0 != undefined):
   
        this.base.header.forEach(#75733629770248258#)
   
   #75733629770248258#(cell):                    // 表头单元格回调 ≈ 源码 255 行
    cell.children.forEach(#7128237658016810309#)   // ← 此处 cell.children 为 undefined 时崩溃
   崩溃链还原为：
   aboutToAppear() {
   this.base.header.forEach((cell) => {      // 外层 forEach 正常（header 存在）
    cell.children.forEach(...)              // 内层 forEach 抛 TypeError（children 缺失）
   })
   }
   即：TableRender 在 aboutToAppear 中遍历表头单元格的 children 计算列宽时，某个表头单元格节点缺少 children 属性。
   值得说明的是，完整解析路径（parseTableCell → parseInline）产出的单元格 children 恒为数组：parseInline 对空串返回 []，其余输入返回数组，异常路径全部
   rethrow。因此该缺陷只出现在特定畸形输入下解析器产出的 TableNode 中。
   四、触发内容（已确证）
   触发消息的 Markdown 结构：
   | 姓名 | ____________________ | 参加工作时间 | ____________ 年 _______ 月 | 岗位（职务） | ____________________ |
   |------|----------------------|--------------|---------------------------|--------------
   特征：

3. 表头 6 列，分隔线仅 5 段（列数不一致）；

4. 分隔线最后一段无闭合竖线（以 |-------------- 结尾）；

5. 消息在分隔线处截断——表格无任何数据行（header-only）；

6. 表头单元格含长下划线串（____________________）。
   复现：将该内容作为 Markdown 组件 text 渲染即闪退；存入历史后冷启动重渲染必现。
   五、建议的库侧修复

7. 直接兜底：TableRender 遍历 header/rows 时对 children 判空——
   cell.children?.forEach(...) 或构造节点时保证 children 恒为数组；

8. 定位解析缺陷：查表头单元格 children 缺失的具体路径（疑似与"对齐列数 < 表头列数"或"无数据行的表格"相关），解析侧补齐 children: []；

9. 统一健壮性：所有 AST 遍历改为安全访问，避免生命周期内抛未捕获异常（该异常在组件生命周期中无法被业务 try-catch 捕获，直接杀进程）；

10. 附带观察：TableImpl.tableWidthsList 按 tableId 全局索引，而 tableId 每次解析从 0 重新计数，多 Markdown 组件并存时存在缓存碰撞风险（当前靠 markdownUnion 比对兜底，建议关注）。
    六、应用侧缓解（已落地，版本 4.3.1）
    新增渲染前表格规范化 MarkdownSanitizer：
- 合法表格：补齐列数、闭合竖线、保留对齐冒号，正常渲染；

- 空表头单元格 / 仅表头无数据行 / 全空数据行表格：降级为纯文本（内容不丢失）；

- 表格后紧跟正文（无空行）：自动补空行分隔；

- 代码围栏、列表、引用、缩进代码：原样透传。
  原崩溃内容经处理后不再产生表格结构，25 项边界用例全部通过。
  
  ---
  
  可直接提交的 Issue 文本
  标题：TableRender.aboutToAppear 对 undefined 调 forEach 导致闪退（表头列数不一致 + 无数据行的表格）
  版本：@luvi/lv-markdown-in 3.4.5（ohpm latest）
  现象：渲染含异常结构表格的 Markdown 时进程直接闪退。冷启动渲染历史消息必现。异常发生在组件生命周期内，业务侧无法捕获。
  崩溃栈：
  TypeError: Cannot read property forEach of undefined
  at anonymous (TableRender.ts:255:1)
  at anonymous (TableRender.ts:253:26)
  at aboutToAppear (TableRender.ts:252:27)
  最小复现（消息内容以分隔线结尾，无数据行；表头 6 列、分隔线 5 段且末段无闭合竖线）：
  | 姓名 | ____________________ | 参加工作时间 | ____________ 年 _______ 月 | 岗位（职务） | ____________________ |
  |------|----------------------|--------------|---------------------------|--------------
  分析：反编译字节码确认崩溃链为 base.header.forEach(cell => cell.children.forEach(...))，某个表头单元格节点缺 children 属性（完整解析路径下 parseInline 恒返回数组，疑似对齐列数 <
  表头列数或无数据行场景下解析产出异常节点）。另：tableWidthsList 按 tableId 全局索引、tableId 每次解析从 0 计数，多组件场景存在缓存碰撞隐患，建议一并核查。
  建议：TableRender 遍历对 children 判空兜底，并修复表头单元格 children 缺失的解析路径。
  临时绕过：应用侧已在渲染前规范化表格结构（补齐列数/闭合竖线，空表头单元格与无数据行表格降级为纯文本），崩溃不再复现；但建议库侧根修。
