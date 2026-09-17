// WorkSkillService: 工作模式的「技能」注册与加载
// 技能 = 打包在 rawfile/skills/<id>/ 下的领域操作指南(SKILL.md + reference/*.md)。
// 对齐 Agent Skills 的渐进披露设计: 系统提示词只保留一句触发提示(前缀稳定),
// 模型通过 list_skills 看到技能清单, 需要时用 load_skill 按文件加载正文。
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Constants } from '../common/Constants';
import { ToolRegistry, SkillMeta, SkillFileMeta } from '../common/ToolRegistry';
import { SkillDirectoryFormatter } from '../common/SkillDirectoryFormatter';

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
  // 技能是否已同步进 ToolRegistry(skill 作为首类插件)
  private static skillsSynced: boolean = false;

  private static ensureToolSkills(): void {
    if (WorkSkillService.skillsSynced) {
      return;
    }
    let list: SkillInfo[] = WorkSkillService.registry();
    for (let i: number = 0; i < list.length; i++) {
      let s: SkillInfo = list[i];
      let meta: SkillMeta = new SkillMeta();
      meta.id = s.id;
      meta.name = s.name;
      meta.description = s.description;
      for (let f: number = 0; f < s.files.length; f++) {
        let fm: SkillFileMeta = new SkillFileMeta();
        fm.file = s.files[f].file;
        fm.desc = s.files[f].desc;
        meta.files.push(fm);
      }
      ToolRegistry.registerSkill(meta);
    }
    WorkSkillService.skillsSynced = true;
  }

  // ===== 技能注册表(新增技能: 在 rawfile/skills/<id>/ 放文档 + 在此登记) =====
  private static registry(): SkillInfo[] {
    let list: SkillInfo[] = [];
    let ppt: SkillInfo = new SkillInfo();
    ppt.id = 'ppt';
    ppt.name = 'PPT 制作与编辑';
    ppt.description = '制作/修改/美化演示文稿(.pptx)时加载，V3 全量加载所有 reference：Deck JSON 完整语法(13 种版式/图表/表格/图片/备注/背景装饰)、' +
      '8 套主题 + themeOverride 多色混搭、视觉风格目录(科技/古风/简约/杂志/商务/学术/路演)与每页内容配图(流程图/时间轴/架构图/插画/信息图)、设计规范、内容纪律与自检报告。' +
      '任何 write_pptx / read_ppt / edit_ppt 任务开始前先 load_skill("ppt") 全量加载；新建 PPT 前须 ask_user_question 前置提问；默认 20 页以上；每页装饰 + 内容配图；交付前写 ppt_qa_report.md。';
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
    let f5: SkillFileInfo = new SkillFileInfo();
    f5.file = 'reference/deck-blueprints.md';
    f5.desc = '常见演示文稿蓝图：经营复盘/商业计划/技术分享/培训/路演页面节奏';
    let f6: SkillFileInfo = new SkillFileInfo();
    f6.file = 'reference/visual-components.md';
    f6.desc = 'PPT 视觉组件目录：指标区/对比/SWOT/雷达/漏斗/甘特/时间线/飞轮/分层架构';
    let f7: SkillFileInfo = new SkillFileInfo();
    f7.file = 'reference/style-guidelines.md';
    f7.desc = 'ChatGPT 演示文稿风格指南：沟通任务/叙事弧/文案/构图纪律/字号下限';
    let f8: SkillFileInfo = new SkillFileInfo();
    f8.file = 'reference/visual-styles.md';
    f8.desc = '视觉风格目录与装饰配方：科技/古风/简约/杂志/商务/学术/路演 + 纹理/勾边/花色 SVG 骨架';
    ppt.files.push(f1);
    ppt.files.push(f2);
    ppt.files.push(f3);
    ppt.files.push(f4);
    ppt.files.push(f5);
    ppt.files.push(f6);
    ppt.files.push(f7);
    ppt.files.push(f8);
    list.push(ppt);
    let docx: SkillInfo = new SkillInfo();
    docx.id = 'docx';
    docx.name = 'Word 文档制作与编辑';
    docx.description = '制作/修改 Word 文档(.docx)时加载，V3 全量加载所有 reference：Doc JSON 完整语法(封面/目录/分级标题/正文/列表/表格/图片/引用/代码块)、' +
      '三种样式预设、中文排版规范、文档形态选型与表格门禁、专业文书规范、自检报告。任何 write_docx / read_docx / edit_docx 任务开始前先 load_skill("docx") 全量加载；新建文档前须 ask_user_question 前置提问；交付前写 docx_qa_report.md。';
    let d1: SkillFileInfo = new SkillFileInfo();
    d1.file = 'reference/doc-dsl.md';
    d1.desc = 'Doc JSON 完整字段定义与示例';
    let d2: SkillFileInfo = new SkillFileInfo();
    d2.file = 'reference/design-guide.md';
    d2.desc = '中文文档排版规范与场景建议';
    let d3: SkillFileInfo = new SkillFileInfo();
    d3.file = 'reference/troubleshooting.md';
    d3.desc = '常见问题排查（症状→修复）';
    let d4: SkillFileInfo = new SkillFileInfo();
    d4.file = 'reference/document-blueprints.md';
    d4.desc = '常见 Word 文档蓝图：商务报告/方案/纪要/论文/操作手册结构';
    let d5: SkillFileInfo = new SkillFileInfo();
    d5.file = 'reference/professional-docs.md';
    d5.desc = '专业文书规范：公文/合同/研究报告/新闻稿/技术交底书结构与 Doc JSON 建议';
    let d6: SkillFileInfo = new SkillFileInfo();
    d6.file = 'reference/chatgpt-design-presets.md';
    d6.desc = 'ChatGPT 官方文档设计预设：memo/RFI/提案/决策备忘/指南的 token 级排版参考';
    docx.files.push(d1);
    docx.files.push(d2);
    docx.files.push(d3);
    docx.files.push(d4);
    docx.files.push(d5);
    docx.files.push(d6);
    list.push(docx);
    let xlsx: SkillInfo = new SkillInfo();
    xlsx.id = 'xlsx';
    xlsx.name = 'Excel 表格制作与编辑';
    xlsx.description = '制作/修改/分析 Excel 表格(.xlsx)时加载，V3 全量加载所有 reference：Workbook JSON 完整语法(多工作表/表头/公式/数字格式/列宽/冻结窗格)、' +
      '表格规范(公式优先/数字格式矩阵/负数与零值显示/假设区与模型区分离)、数据分析与报表交付链路、编辑完整性规则与自检报告。任何 write_xlsx / read_xlsx / edit_xlsx 任务开始前先 load_skill("xlsx") 全量加载；新建工作簿前须 ask_user_question 前置提问；交付前写 xlsx_qa_report.md。';
    let x1: SkillFileInfo = new SkillFileInfo();
    x1.file = 'reference/workbook-dsl.md';
    x1.desc = 'Workbook JSON 完整字段定义与示例';
    let x2: SkillFileInfo = new SkillFileInfo();
    x2.file = 'reference/format-guide.md';
    x2.desc = '表格规范: 公式优先/数字格式/财务配色/编辑完整性';
    let x3: SkillFileInfo = new SkillFileInfo();
    x3.file = 'reference/troubleshooting.md';
    x3.desc = '常见问题排查（症状→修复）';
    let x4: SkillFileInfo = new SkillFileInfo();
    x4.file = 'reference/report-blueprints.md';
    x4.desc = '常见 Excel 报表蓝图：经营月报/预算/财务模型/明细汇总/任务跟踪/台账';
    let x5: SkillFileInfo = new SkillFileInfo();
    x5.file = 'reference/analysis-playbook.md';
    x5.desc = '数据分析玩法：趋势/对比/构成/异常归因/敏感性/口径审计';
    xlsx.files.push(x1);
    xlsx.files.push(x2);
    xlsx.files.push(x3);
    xlsx.files.push(x4);
    xlsx.files.push(x5);
    list.push(xlsx);
    let svg: SkillInfo = new SkillInfo();
    svg.id = 'svg';
    svg.name = 'SVG 矢量绘图（生图）';
    svg.description = '需要生成图片——图标、徽标、示意图、流程图、架构图、信息图、插画、装饰图形——或任务要求"画图/生图/出图/配图"而工作区没有现成素材时加载: SVG 绘制规范(视框/描边风格/配色/文字处理)、"生成→预览→修正"工作流、可视化类型选择、可直接套用的配方。任何 write_svg 任务开始前先加载。';
    let s1: SkillFileInfo = new SkillFileInfo();
    s1.file = 'reference/svg-craft.md';
    s1.desc = '绘制规范: 视框/网格/path优先/文字风险/配色纪律';
    let s2: SkillFileInfo = new SkillFileInfo();
    s2.file = 'reference/svg-recipes.md';
    s2.desc = '可套用模板: 描边图标/流程图/架构图/信息图卡片/柱状对比/时间轴/封面装饰';
    let s3: SkillFileInfo = new SkillFileInfo();
    s3.file = 'reference/infographic-blueprints.md';
    s3.desc = '常见信息图蓝图: 对比/流程/时间线/架构/KPI卡/机制因果';
    svg.files.push(s1);
    svg.files.push(s2);
    svg.files.push(s3);
    list.push(svg);
    let data: SkillInfo = new SkillInfo();
    data.id = 'data';
    data.name = '数据清洗与转换';
    data.description = '处理表格/结构化数据时加载——CSV/JSON 清洗、去重、拆列、正则提取、' +
      '格式互转(CSV/TSV/JSON/Markdown 表格/XLSX)、大文件本地转换, 或任何 transform_file 任务开始前: ' +
      '管道 ops 与表达式完整语法、场景配方、能力边界(无分组聚合/merge/concat, 替代方案见技能正文)、限额与自检清单。';
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
    WorkSkillService.ensureToolSkills();
    return SkillDirectoryFormatter.listText(ToolRegistry.skillList());
  }

  // @deprecated 请使用 promptSectionWithMode(mode); 保留默认 full_index 兼容
  static promptSection(): string {
    WorkSkillService.ensureToolSkills();
    return SkillDirectoryFormatter.format(ToolRegistry.skillList(), SkillDirectoryFormatter.MODE_FULL_INDEX);
  }

  // 按目录模式生成技能提示词(full_index 完整清单 / trigger_only 渐进披露)
  static promptSectionWithMode(mode: string): string {
    WorkSkillService.ensureToolSkills();
    return SkillDirectoryFormatter.format(ToolRegistry.skillList(), mode);
  }

  // load_skill: 读取技能文档; 技能名或文件名不在注册表内时报错(防路径探测)
  static async load(context: common.UIAbilityContext, skillId: string, file: string): Promise<string> {
    WorkSkillService.ensureToolSkills();
    let id: string = skillId.trim().toLowerCase();
    let skill: SkillMeta | null = ToolRegistry.findSkill(id);
    if (skill === null) {
      let ids: string[] = ToolRegistry.skillIds();
      return 'ERROR: 未知技能 "' + skillId + '"。可用技能: ' + (ids.length > 0 ? ids.join(' / ') : '(无)');
    }
    let target: string = file.trim();
    if (target === '') {
      target = 'SKILL.md';
    }
    // V3: 核心办公技能 load_skill(name) 必须全量返回 SKILL.md + 全部 reference，禁止按需挑读。
    if ((skill.id === 'ppt' || skill.id === 'docx' || skill.id === 'xlsx') && target === 'SKILL.md') {
      return await WorkSkillService.loadBundle(context, skill);
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

  // V3 全量 bundle：一次返回 SKILL.md + 全部 reference（ppt/docx/xlsx），避免 agent 按需挑读。
  private static async loadBundle(context: common.UIAbilityContext, skill: SkillMeta): Promise<string> {
    let parts: string[] = [];
    let files: string[] = ['SKILL.md'];
    for (let i: number = 0; i < skill.files.length; i++) {
      files.push(skill.files[i].file);
    }
    for (let i: number = 0; i < files.length; i++) {
      let target: string = files[i];
      let rawPath: string = 'skills/' + skill.id + '/' + target;
      try {
        let raw: Uint8Array = await context.resourceManager.getRawFileContent(rawPath);
        let decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
        let text: string = decoder.decodeToString(raw, { stream: false });
        if (text.trim() === '') {
          return 'ERROR: 技能文件为空: ' + rawPath;
        }
        parts.push('【技能 ' + skill.id + ' · ' + target + '】\n' + text);
      } catch (e) {
        let msg: string = e instanceof Error ? (e as Error).message : String(e);
        return 'ERROR: 技能文件加载失败(' + msg + '): ' + rawPath;
      }
    }
    let bundle: string = parts.join('\n\n');
    if (bundle.length > Constants.WORK_SKILL_BUNDLE_MAX_CHARS) {
      bundle = bundle.substring(0, Constants.WORK_SKILL_BUNDLE_MAX_CHARS) + '\n...(过长已截断)';
    }
    return bundle;
  }
}
