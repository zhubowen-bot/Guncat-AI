// WorkSkillService: 工作模式的「技能」注册与加载
// 技能 = 打包在 rawfile/skills/<id>/ 下的领域操作指南(SKILL.md + reference/*.md)。
// 对齐 Agent Skills 的渐进披露设计: 系统提示词只保留一句触发提示(前缀稳定),
// 模型通过 list_skills 看到技能清单, 需要时用 load_skill 按文件加载正文。
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Constants } from '../common/Constants';

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
    ppt.files.push(f1);
    ppt.files.push(f2);
    ppt.files.push(f3);
    list.push(ppt);
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
