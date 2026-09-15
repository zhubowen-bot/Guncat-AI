// WorkSkillService: 工作模式的「技能」注册与加载
// 技能 = 打包在 rawfile/skills/<id>/ 下的领域操作指南(SKILL.md + reference/*.md)。
// 对齐 Agent Skills 的渐进披露设计: 系统提示词只保留一句触发提示(前缀稳定),
// 模型通过 list_skills 看到技能清单, 需要时用 load_skill 按文件加载正文。
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Constants } from './Constants.ts';

// 技能可加载的文件
export class SkillFileInfo {
  file: string = '';        // 相对技能目录的路径(SKILL.md 或 reference/xxx.md)
  desc: string = '';        // 一句话说明
}

// 已注册技能
export class SkillInfo {
  id: string = '';
  name: string = '';
  description: string = ''; // 触发语义: 什么任务应该加载该技能
  files: SkillFileInfo[] = [];
}

export class WorkSkillService {
  // ===== 技能注册表(新增技能: 在 rawfile/skills/<id>/ 放文档 + 在此登记) =====
  private static registry(): SkillInfo[] {
    let list: SkillInfo[] = [];
    let ppt: SkillInfo = new SkillInfo();
    ppt.id = 'ppt';
    ppt.name = 'PPT 制作与编辑';
    ppt.description = '制作/修改/美化演示文稿(.pptx)时加载: Deck JSON 完整语法(13 种版式/图表/表格/图片/备注)、' +
      '8 套主题、设计规范与自检清单。任何 write_pptx / read_ppt / edit_ppt 任务开始前先加载。';
    let f1: SkillFileInfo = new SkillFileInfo();
    f1.file = 'reference/deck-dsl.md';
    f1.desc = 'Deck JSON 完整字段定义与示例';
    let f2: SkillFileInfo = new SkillFileInfo();
    f2.file = 'reference/design-guide.md';
    f2.desc = '页面设计规范与场景建议';
    let f3: SkillFileInfo = new SkillFileInfo();
    f3.file = 'reference/themes.md';
    f3.desc = '主题预设清单与自定义主题';
    let f4: SkillFileInfo = new SkillFileInfo();
    f4.file = 'reference/troubleshooting.md';
    f4.desc = '常见问题排查（症状→修复）';
    ppt.files.push(f1);
    ppt.files.push(f2);
    ppt.files.push(f3);
    ppt.files.push(f4);
    list.push(ppt);
    let docx: SkillInfo = new SkillInfo();
    docx.id = 'docx';
    docx.name = 'Word 文档制作与编辑';
    docx.description = '制作/修改 Word 文档(.docx)时加载: Doc JSON 完整语法(封面/目录/分级标题/正文/列表/表格/图片/引用/代码块)、' +
      '三种样式预设、中文排版规范与自检清单。任何 write_docx / read_docx / edit_docx 任务开始前先加载。';
    let d1: SkillFileInfo = new SkillFileInfo();
    d1.file = 'reference/doc-dsl.md';
    d1.desc = 'Doc JSON 完整字段定义与示例';
    let d2: SkillFileInfo = new SkillFileInfo();
    d2.file = 'reference/design-guide.md';
    d2.desc = '中文文档排版规范与场景建议';
    let d3: SkillFileInfo = new SkillFileInfo();
    d3.file = 'reference/troubleshooting.md';
    d3.desc = '常见问题排查（症状→修复）';
    docx.files.push(d1);
    docx.files.push(d2);
    docx.files.push(d3);
    list.push(docx);
    let xlsx: SkillInfo = new SkillInfo();
    xlsx.id = 'xlsx';
    xlsx.name = 'Excel 表格制作与编辑';
    xlsx.description = '制作/修改/分析 Excel 表格(.xlsx)时加载: Workbook JSON 完整语法(多工作表/表头/公式/数字格式/列宽/冻结窗格)、' +
      '表格规范(公式优先/数字格式矩阵/负数与零值显示/假设区与模型区分离)、编辑完整性规则与自检清单。任何 write_xlsx / read_xlsx / edit_xlsx 任务开始前先加载。';
    let x1: SkillFileInfo = new SkillFileInfo();
    x1.file = 'reference/workbook-dsl.md';
    x1.desc = 'Workbook JSON 完整字段定义与示例';
    let x2: SkillFileInfo = new SkillFileInfo();
    x2.file = 'reference/format-guide.md';
    x2.desc = '表格规范: 公式优先/数字格式/财务配色/编辑完整性';
    let x3: SkillFileInfo = new SkillFileInfo();
    x3.file = 'reference/troubleshooting.md';
    x3.desc = '常见问题排查（症状→修复）';
    xlsx.files.push(x1);
    xlsx.files.push(x2);
    xlsx.files.push(x3);
    list.push(xlsx);
    let svg: SkillInfo = new SkillInfo();
    svg.id = 'svg';
    svg.name = 'SVG 矢量绘图（生图）';
    svg.description = '需要生成图片——图标、徽标、示意图、流程图、架构图、信息图、插画、装饰图形——或任务要求"画图/生图/出图/配图"而工作区没有现成素材时加载: SVG 绘制规范(视框/描边风格/配色/文字处理)、"生成→预览→修正"工作流、可直接套用的配方。任何 write_svg 任务开始前先加载。';
    let s1: SkillFileInfo = new SkillFileInfo();
    s1.file = 'reference/svg-craft.md';
    s1.desc = '绘制规范: 视框/网格/path优先/文字风险/配色纪律';
    let s2: SkillFileInfo = new SkillFileInfo();
    s2.file = 'reference/svg-recipes.md';
    s2.desc = '可套用模板: 描边图标/流程图/架构图/信息图卡片/封面装饰';
    svg.files.push(s1);
    svg.files.push(s2);
    list.push(svg);
    let data: SkillInfo = new SkillInfo();
    data.id = 'data';
    data.name = '数据清洗与转换';
    data.description = '处理表格/结构化数据时加载——CSV/JSON 清洗、去重、拆列、合并、正则提取、' +
      '格式互转(CSV/TSV/JSON/Markdown 表格/XLSX)、大文件本地转换, 或任何 transform_file 任务开始前: ' +
      '管道 ops 与表达式完整语法、三类场景配方、限额与自检清单。';
    list.push(data);
    // ===== 五个专家智能体的 prompt 注册为技能(prompt 原文在 skills/<id>/SKILL.md) =====
    let paper: SkillInfo = new SkillInfo();
    paper.id = 'paper';
    paper.name = '论文改写与学术化';
    paper.description = '把综述/散文/笔记/报告/讲义/对话/博客等非论文文体改写为规范学术论文, 或论文扩写/润色/重构时加载: ' +
      '源文体诊断、八项改写参数(论文类型/改写模式/扩充策略/学术深度/字数策略/引用格式/语言风格/输出粒度)、' +
      '分文体改写策略与质量自检清单。';
    list.push(paper);
    let law: SkillInfo = new SkillInfo();
    law.id = 'law';
    law.name = '国企法律事务分析';
    law.description = '分析企业法律案例/纠纷并输出结构化法律意见书时加载, 尤其国企国资监管、股权转让、合同纠纷、合规与责任认定: ' +
      '合同解释五法、法理分析工具箱、六条深度推理链、法律时效性铁律与法律意见书模板。';
    list.push(law);
    let research: SkillInfo = new SkillInfo();
    research.id = 'research';
    research.name = '深度研究与多轮验证';
    research.description = '对任何主题做事实核查、深度调研、多源交叉验证并产出结构化研究报告时加载: ' +
      '4-6 轮检索验证流程、术语精细辨析、多源体系化解释、分析工具箱(因果链/利益相关方/反事实推演等)与研究报告模板。';
    list.push(research);
    let sift: SkillInfo = new SkillInfo();
    sift.id = 'sift';
    sift.name = '信息溯源与AI内容过滤';
    sift.description = '查询"最新版本/最新状态/排名对比"等时效敏感信息, 需甄别AI生成内容与营销文、锚定官方一手来源时加载: ' +
      '九步深度搜索法(官方渠道溯源→实体状态锚定→AI内容识别过滤→整合输出)、来源分级与时效标记规范。';
    list.push(sift);
    let llmEval: SkillInfo = new SkillInfo();
    llmEval.id = 'llm-eval';
    llmEval.name = '大模型评测与选型分析';
    llmEval.description = '对比/评估/选型大模型时加载——"XX相当于什么模型""XX与YY谁强""推荐哪个模型"、benchmark分数解读、模型推荐: ' +
      '信源分级(Tier 1-6)与引用前检查门、版本时间戳校验与跨版本比较禁令、代际确认与知识库对标约束、能力维度拆解(代码能力主权重)、对标类问题强制自检清单。';
    let le1: SkillFileInfo = new SkillFileInfo();
    le1.file = 'reference/capability-alignment.md';
    le1.desc = 'Step 5-8: 模型代际确认与知识库对标约束、能力维度拆解与差距量化、场景化选型、版本模式标注';
    let le2: SkillFileInfo = new SkillFileInfo();
    le2.file = 'reference/output-checklist.md';
    le2.desc = 'Step 9-12: 生态位与性价比分析、认知误区纠正、自检清单、结构化输出规范';
    llmEval.files.push(le1);
    llmEval.files.push(le2);
    list.push(llmEval);
    return list;
  }

  // list_skills 输出: 技能清单(含触发语义与文件索引)
  static listText(): string {
    let list: SkillInfo[] = WorkSkillService.registry();
    if (list.length === 0) {
      return '(当前没有可用技能)';
    }
    let out: string = '可用技能(用 load_skill(name) 加载正文, load_skill(name, file) 加载参考文件):\n';
    for (let i: number = 0; i < list.length; i++) {
      let s: SkillInfo = list[i];
      out += '\n- ' + s.id + ' — ' + s.name + '\n  触发: ' + s.description + '\n  文件: SKILL.md(正文)';
      for (let f: number = 0; f < s.files.length; f++) {
        out += ', ' + s.files[f].file + '(' + s.files[f].desc + ')';
      }
      out += '\n';
    }
    return out;
  }

  // 注入系统提示词末尾的技能清单: 模型未必会主动调 list_skills(不调就不知道有哪些技能,
  // 会跳过技能直接搜索作答), 所以把 id/名称/触发条件直接暴露在提示词里, 促成"命中即先 load_skill"。
  // 仅由静态注册表生成、逐字节稳定, 追加在提示词末尾——不破坏前缀 KV 缓存。
  static promptSection(): string {
    let list: SkillInfo[] = WorkSkillService.registry();
    if (list.length === 0) {
      return '';
    }
    let out: string = '# 技能库（命中领域的任务，第一步先加载技能）\n';
    out += '下面列出全部可用技能及其触发条件。任务命中某技能的触发条件时，**必须先 load_skill 加载该技能再动手**，按其方法论执行；';
    out += '技能正文优先于你的默认做法，也优先于"直接搜索后凭通用知识作答"——技能规定要检索的信息缺口，再用搜索/读文件工具按技能的要求补足。';
    out += '技能内的参考文件用 load_skill(name, file) 按需加载。\n';
    for (let i: number = 0; i < list.length; i++) {
      let s: SkillInfo = list[i];
      out += '\n- ' + s.id + ' — ' + s.name + '\n  触发: ' + s.description + '\n';
    }
    return out;
  }

  // load_skill: 读取技能文档; 技能名或文件名不在注册表内时报错(防路径探测)
  static async load(context: common.UIAbilityContext, skillId: string, file: string): Promise<string> {
    let id: string = skillId.trim().toLowerCase();
    let list: SkillInfo[] = WorkSkillService.registry();
    let skill: SkillInfo | null = null;
    for (let i: number = 0; i < list.length; i++) {
      if (list[i].id === id) {
        skill = list[i];
        break;
      }
    }
    if (skill === null) {
      let ids: string[] = [];
      for (let i: number = 0; i < list.length; i++) {
        ids.push(list[i].id);
      }
      return 'ERROR: 未知技能 "' + skillId + '"。可用技能: ' + (ids.length > 0 ? ids.join(' / ') : '(无)');
    }
    let target: string = file.trim();
    if (target === '') {
      target = 'SKILL.md';
    }
    let allowed: boolean = target === 'SKILL.md';
    for (let i: number = 0; i < skill.files.length; i++) {
      if (skill.files[i].file === target) {
        allowed = true;
        break;
      }
    }
    if (!allowed) {
      let names: string[] = ['SKILL.md'];
      for (let i: number = 0; i < skill.files.length; i++) {
        names.push(skill.files[i].file);
      }
      return 'ERROR: 技能 ' + skill.id + ' 没有 "' + file + '"。可用文件: ' + names.join(' / ');
    }
    let rawPath: string = 'skills/' + skill.id + '/' + target;
    try {
      let raw: Uint8Array = await context.resourceManager.getRawFileContent(rawPath);
      let decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      let text: string = decoder.decodeToString(raw, { stream: false });
      if (text.trim() === '') {
        return 'ERROR: 技能文件为空: ' + rawPath;
      }
      if (text.length > Constants.WORK_SKILL_MAX_CHARS) {
        text = text.substring(0, Constants.WORK_SKILL_MAX_CHARS) + '\n...(过长已截断)';
      }
      return '【技能 ' + skill.id + ' · ' + target + '】\n' + text;
    } catch (e) {
      let msg: string = e instanceof Error ? (e as Error).message : String(e);
      return 'ERROR: 技能文件加载失败(' + msg + '): ' + rawPath;
    }
  }
}
