// WorkToolRunner: 工作模式工具统一分发入口
// 文件类工具委托 WorkFileService(ts); Office 生成需要 .ets 模块
// (OoxmlBuilder/XlsxExporter/PptxBuilder), 在此实现。全部工具均为本地实现, 无多模态依赖。
import { common } from '@kit.AbilityKit';
import { WorkFileService, ToolExecResult } from './WorkFileService';
import { PdfTextExtractor, PdfPagesResult, PdfSearchHit, PdfRenderResult } from './PdfTextExtractor';
import { DocxExporter } from '../export/DocxExporter';
import { XlsxExporter } from '../export/XlsxExporter';
import { PptxBuilder } from '../export/PptxBuilder';
import { Constants } from '../common/Constants';

export class WorkToolRunner {
  static async execute(context: common.UIAbilityContext, convId: string,
    name: string, argsJson: string): Promise<ToolExecResult> {
    if (name === 'write_docx') {
      return await WorkToolRunner.toolWriteDocx(context, convId, argsJson);
    }
    if (name === 'write_xlsx') {
      return await WorkToolRunner.toolWriteXlsx(context, convId, argsJson);
    }
    if (name === 'write_pptx') {
      return await WorkToolRunner.toolWritePptx(context, convId, argsJson);
    }
    if (name === 'parse_document') {
      return await WorkToolRunner.toolParseDocument(context, convId, argsJson);
    }
    if (name === 'search_pdf') {
      return await WorkToolRunner.toolSearchPdf(context, convId, argsJson);
    }
    if (name === 'pdf_to_images') {
      return await WorkToolRunner.toolPdfToImages(context, convId, argsJson);
    }
    return await WorkFileService.executeTool(context, convId, name, argsJson);
  }

  // ===== 参数读取 =====

  private static strArg(args: Record<string, Object>, key: string, defVal: string): string {
    let v: Object = args[key];
    if (typeof v === 'string') {
      return v as string;
    }
    if (typeof v === 'number') {
      return (v as number).toString();
    }
    return defVal;
  }

  private static argError(): ToolExecResult {
    let r: ToolExecResult = new ToolExecResult();
    r.ok = false;
    r.output = 'ERROR: 参数不是合法的 JSON 对象';
    return r;
  }

  private static parseArgs(argsJson: string): Record<string, Object> | null {
    let trimmed: string = argsJson.trim();
    if (trimmed === '') {
      trimmed = '{}';
    }
    try {
      let parsed: Object = JSON.parse(trimmed);
      if (typeof parsed === 'object' && parsed !== null && !(parsed instanceof Array)) {
        return parsed as Record<string, Object>;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  private static extractErrMessage(e: Object): string {
    if (e instanceof Error) {
      let err: Error = e as Error;
      return err.message !== undefined ? err.message : String(e);
    }
    return String(e);
  }

  // 整数参数: 兼容 number 与数字字符串, 非法时用默认值
  private static intArg(args: Record<string, Object>, key: string, defVal: number): number {
    let v: Object = args[key];
    if (typeof v === 'number' && !isNaN(v as number)) {
      return Math.floor(v as number);
    }
    if (typeof v === 'string') {
      let n: number = parseInt(v as string, 10);
      if (!isNaN(n)) {
        return n;
      }
    }
    return defVal;
  }

  // ===== write_docx: Markdown -> .docx =====
  private static async toolWriteDocx(context: common.UIAbilityContext, convId: string,
    argsJson: string): Promise<ToolExecResult> {
    let args: Record<string, Object> | null = WorkToolRunner.parseArgs(argsJson);
    if (args === null) {
      return WorkToolRunner.argError();
    }
    let rel: string = WorkToolRunner.strArg(args, 'path', '');
    let markdown: string = WorkToolRunner.strArg(args, 'markdown', '');
    if (rel === '') {
      return WorkToolRunner.failMsg('缺少参数 path');
    }
    if (markdown.trim() === '') {
      return WorkToolRunner.failMsg('缺少参数 markdown');
    }
    let title: string = WorkToolRunner.strArg(args, 'title', 'Guncat AI 文档');
    try {
      let bytes: Uint8Array = await DocxExporter.buildDocxBytes(title, markdown);
      return WorkFileService.writeBytesAt(context, convId, rel, bytes);
    } catch (e) {
      return WorkToolRunner.failMsg('生成 Word 文档失败: ' + WorkToolRunner.extractErrMessage(e as Object));
    }
  }

  // ===== write_xlsx: Markdown表格/CSV/TSV -> .xlsx =====
  private static async toolWriteXlsx(context: common.UIAbilityContext, convId: string,
    argsJson: string): Promise<ToolExecResult> {
    let args: Record<string, Object> | null = WorkToolRunner.parseArgs(argsJson);
    if (args === null) {
      return WorkToolRunner.argError();
    }
    let rel: string = WorkToolRunner.strArg(args, 'path', '');
    let table: string = WorkToolRunner.strArg(args, 'table', '');
    if (rel === '') {
      return WorkToolRunner.failMsg('缺少参数 path');
    }
    if (table.trim() === '') {
      return WorkToolRunner.failMsg('缺少参数 table');
    }
    let rows: string[][] = WorkToolRunner.parseTableInput(table);
    if (rows.length === 0) {
      return WorkToolRunner.failMsg('表格数据为空, 请提供 Markdown 表格、CSV 或 TSV 文本');
    }
    try {
      let bytes: Uint8Array = XlsxExporter.buildXlsxFromRows(rows);
      return WorkFileService.writeBytesAt(context, convId, rel, bytes);
    } catch (e) {
      return WorkToolRunner.failMsg('生成 Excel 文件失败: ' + WorkToolRunner.extractErrMessage(e as Object));
    }
  }

  // 表格文本解析: 优先 Markdown 表格(|), 其次 TSV(制表符), 最后 CSV(逗号)
  private static parseTableInput(table: string): string[][] {
    let lines: string[] = [];
    let rawLines: string[] = table.split('\n');
    for (let i: number = 0; i < rawLines.length; i++) {
      let line: string = rawLines[i].trim();
      if (line === '') {
        continue;
      }
      // 跳过 Markdown 分隔行 |---|---|
      if (line.indexOf('-') !== -1 && /^\|?[\s\-:|]+\|?$/.test(line)) {
        continue;
      }
      lines.push(line);
    }
    if (lines.length === 0) {
      return [];
    }
    let rows: string[][] = [];
    let isMarkdown: boolean = lines[0].indexOf('|') !== -1;
    let isTsv: boolean = !isMarkdown && lines[0].indexOf('\t') !== -1;
    for (let i: number = 0; i < lines.length; i++) {
      let line: string = lines[i];
      let cells: string[] = [];
      if (isMarkdown) {
        let trimmed: string = line;
        if (trimmed.startsWith('|')) {
          trimmed = trimmed.substring(1);
        }
        if (trimmed.endsWith('|')) {
          trimmed = trimmed.substring(0, trimmed.length - 1);
        }
        let parts: string[] = trimmed.split('|');
        for (let c: number = 0; c < parts.length; c++) {
          cells.push(parts[c].trim());
        }
      } else if (isTsv) {
        cells = line.split('\t');
      } else {
        cells = line.split(',');
      }
      rows.push(cells);
    }
    return rows;
  }

  // ===== write_pptx: 大纲 -> .pptx =====
  private static async toolWritePptx(context: common.UIAbilityContext, convId: string,
    argsJson: string): Promise<ToolExecResult> {
    let args: Record<string, Object> | null = WorkToolRunner.parseArgs(argsJson);
    if (args === null) {
      return WorkToolRunner.argError();
    }
    let rel: string = WorkToolRunner.strArg(args, 'path', '');
    let outline: string = WorkToolRunner.strArg(args, 'outline', '');
    let title: string = WorkToolRunner.strArg(args, 'title', 'Guncat AI 演示');
    if (rel === '') {
      return WorkToolRunner.failMsg('缺少参数 path');
    }
    if (outline.trim() === '') {
      return WorkToolRunner.failMsg('缺少参数 outline');
    }
    try {
      let bytes: Uint8Array = PptxBuilder.buildPptxBytes(title, outline);
      return WorkFileService.writeBytesAt(context, convId, rel, bytes);
    } catch (e) {
      return WorkToolRunner.failMsg('生成演示文稿失败: ' + WorkToolRunner.extractErrMessage(e as Object));
    }
  }

  // ===== parse_document: PDF 文本(本地, 支持按页分段提取) =====
  private static async toolParseDocument(context: common.UIAbilityContext, convId: string,
    argsJson: string): Promise<ToolExecResult> {
    let args: Record<string, Object> | null = WorkToolRunner.parseArgs(argsJson);
    if (args === null) {
      return WorkToolRunner.argError();
    }
    let rel: string = WorkToolRunner.strArg(args, 'path', '');
    if (rel === '') {
      return WorkToolRunner.failMsg('缺少参数 path');
    }
    if (!rel.toLowerCase().endsWith('.pdf')) {
      return WorkToolRunner.failMsg('parse_document 仅支持 PDF; .docx/.xlsx/.pptx 请用 read_file(本地自动解析)');
    }
    let root: string = WorkFileService.workspaceRoot(context, convId);
    let abs: string | null = WorkFileService.resolveSafe(root, rel);
    if (abs === null) {
      return WorkToolRunner.failMsg('非法路径: ' + rel);
    }
    if (!WorkFileService.accessPath(abs)) {
      return WorkToolRunner.failMsg('文件不存在: ' + rel);
    }
    if (WorkFileService.isDirPath(abs)) {
      return WorkToolRunner.failMsg('路径是目录而非文件: ' + rel);
    }
    let startPage: number = WorkToolRunner.intArg(args, 'page', 1);
    let pageLimit: number = WorkToolRunner.intArg(args, 'page_count', Constants.WORK_PDF_PAGES_PER_CALL);
    if (pageLimit < 1) {
      pageLimit = 1;
    } else if (pageLimit > 200) {
      pageLimit = 200;
    }
    try {
      let r: PdfPagesResult = await PdfTextExtractor.extractPages(abs, startPage, pageLimit,
        Constants.WORK_RESULT_MAX_CHARS * 2);
      if (r.pageCount <= 0) {
        return WorkToolRunner.failMsg('该 PDF 无有效页面(可能是加密或损坏文件)');
      }
      if (r.pages.length === 0) {
        return WorkToolRunner.failMsg('共 ' + r.pageCount.toString() + ' 页, 传入的 page=' +
          r.startPage.toString() + ' 超出范围(1-' + r.pageCount.toString() + ')');
      }
      let out: string = '《' + rel + '》共 ' + r.pageCount.toString() + ' 页, 本次为第 ' +
        r.startPage.toString() + '-' + r.endPage.toString() + ' 页:\n\n';
      for (let i: number = 0; i < r.pages.length; i++) {
        out = out + '[第 ' + (r.startPage + i).toString() + ' 页]\n' + r.pages[i] + '\n\n';
      }
      if (r.nextStartPage > 0) {
        out = out + '—— 未读完。继续提取请调用 parse_document, 参数 {"path":"' + rel +
          '","page":' + r.nextStartPage.toString() + '}; 需要定位关键词所在页可用 search_pdf。';
      } else {
        out = out + '—— 已到文档末页。';
      }
      return WorkToolRunner.okMsg(out);
    } catch (e) {
      return WorkToolRunner.failMsg('解析失败: ' + WorkToolRunner.extractErrMessage(e as Object));
    }
  }

  // ===== search_pdf: PDF 关键词搜索(系统引擎, 兜底逐页扫描) =====
  private static async toolSearchPdf(context: common.UIAbilityContext, convId: string,
    argsJson: string): Promise<ToolExecResult> {
    let args: Record<string, Object> | null = WorkToolRunner.parseArgs(argsJson);
    if (args === null) {
      return WorkToolRunner.argError();
    }
    let rel: string = WorkToolRunner.strArg(args, 'path', '');
    let query: string = WorkToolRunner.strArg(args, 'query', '');
    if (rel === '') {
      return WorkToolRunner.failMsg('缺少参数 path');
    }
    if (query.trim() === '') {
      return WorkToolRunner.failMsg('缺少参数 query');
    }
    if (!rel.toLowerCase().endsWith('.pdf')) {
      return WorkToolRunner.failMsg('search_pdf 仅支持 PDF; 文本文件请用 search_files');
    }
    let root: string = WorkFileService.workspaceRoot(context, convId);
    let abs: string | null = WorkFileService.resolveSafe(root, rel);
    if (abs === null) {
      return WorkToolRunner.failMsg('非法路径: ' + rel);
    }
    if (!WorkFileService.accessPath(abs)) {
      return WorkToolRunner.failMsg('文件不存在: ' + rel);
    }
    if (WorkFileService.isDirPath(abs)) {
      return WorkToolRunner.failMsg('路径是目录而非文件: ' + rel);
    }
    try {
      let hits: PdfSearchHit[] = await PdfTextExtractor.searchText(abs, query,
        Constants.WORK_SEARCH_MAX_MATCHES);
      if (hits.length === 0) {
        return WorkToolRunner.okMsg('未在《' + rel + '》中找到 "' + query + '"');
      }
      let out: string = '《' + rel + '》共 ' + hits.length.toString() + ' 处命中:\n';
      for (let i: number = 0; i < hits.length; i++) {
        let ctx: string = hits[i].context !== '' ? hits[i].context : '(无上下文摘录)';
        out = out + '第 ' + hits[i].pageIndex.toString() + ' 页: ' + ctx + '\n';
      }
      out = out + '—— 提取对应页请调用 parse_document, 参数 {"path":"' + rel + '","page":页码}。';
      return WorkToolRunner.okMsg(out);
    } catch (e) {
      return WorkToolRunner.failMsg('PDF 搜索失败: ' + WorkToolRunner.extractErrMessage(e as Object));
    }
  }

  // ===== pdf_to_images: PDF 页面转图片(扫描件入口, 供 view_image 逐张查看) =====
  private static async toolPdfToImages(context: common.UIAbilityContext, convId: string,
    argsJson: string): Promise<ToolExecResult> {
    let args: Record<string, Object> | null = WorkToolRunner.parseArgs(argsJson);
    if (args === null) {
      return WorkToolRunner.argError();
    }
    let rel: string = WorkToolRunner.strArg(args, 'path', '');
    if (rel === '') {
      return WorkToolRunner.failMsg('缺少参数 path');
    }
    if (!rel.toLowerCase().endsWith('.pdf')) {
      return WorkToolRunner.failMsg('pdf_to_images 仅支持 PDF');
    }
    let root: string = WorkFileService.workspaceRoot(context, convId);
    let abs: string | null = WorkFileService.resolveSafe(root, rel);
    if (abs === null) {
      return WorkToolRunner.failMsg('非法路径: ' + rel);
    }
    if (!WorkFileService.accessPath(abs)) {
      return WorkToolRunner.failMsg('文件不存在: ' + rel);
    }
    if (WorkFileService.isDirPath(abs)) {
      return WorkToolRunner.failMsg('路径是目录而非文件: ' + rel);
    }
    let startPage: number = WorkToolRunner.intArg(args, 'page', 1);
    let pageLimit: number = WorkToolRunner.intArg(args, 'page_count',
      Constants.WORK_PDF_RENDER_PAGES_PER_CALL);
    if (pageLimit < 1) {
      pageLimit = 1;
    } else if (pageLimit > 50) {
      pageLimit = 50;
    }
    // 输出目录: pdf_images/<去扩展名的文件名>/, 重名 PDF 各自独立
    let base: string = rel;
    let slash: number = base.lastIndexOf('/');
    if (slash >= 0) {
      base = base.substring(slash + 1);
    }
    let dot: number = base.lastIndexOf('.');
    if (dot > 0) {
      base = base.substring(0, dot);
    }
    base = base.replace(/[\\/:*?"<>|]/g, '_').trim();
    if (base === '') {
      base = 'doc';
    }
    let outDir: string = root + '/pdf_images/' + base;
    try {
      let r: PdfRenderResult = await PdfTextExtractor.renderPages(abs, startPage, pageLimit, outDir);
      if (r.pageCount <= 0) {
        return WorkToolRunner.failMsg('该 PDF 无有效页面(可能是加密或损坏文件)');
      }
      if (r.files.length === 0) {
        return WorkToolRunner.failMsg('共 ' + r.pageCount.toString() + ' 页, 传入的 page=' +
          r.startPage.toString() + ' 超出范围(1-' + r.pageCount.toString() + ')');
      }
      let out: string = '已渲染《' + rel + '》第 ' + r.startPage.toString() + '-' +
        r.endPage.toString() + ' 页(共 ' + r.pageCount.toString() + ' 页) → ' +
        'pdf_images/' + base + '/ :\n';
      for (let i: number = 0; i < r.files.length; i++) {
        let shown: string = r.files[i];
        if (shown.startsWith(root + '/')) {
          shown = shown.substring(root.length + 1);
        }
        out = out + shown + ' (第 ' + (r.startPage + i).toString() + ' 页)\n';
      }
      if (r.nextStartPage > 0) {
        out = out + '—— 用 view_image 逐张查看(每次传一个 path); 需要更多页: pdf_to_images 传 {"path":"' +
          rel + '","page":' + r.nextStartPage.toString() + '}。';
      } else {
        out = out + '—— 已是全部页面。用 view_image 逐张查看(每次传一个 path)。';
      }
      return WorkToolRunner.okMsg(out);
    } catch (e) {
      return WorkToolRunner.failMsg('渲染失败: ' + WorkToolRunner.extractErrMessage(e as Object));
    }
  }

  // ===== 结果封装 =====

  private static okMsg(output: string): ToolExecResult {
    let r: ToolExecResult = new ToolExecResult();
    r.ok = true;
    r.output = output;
    return r;
  }

  private static failMsg(output: string): ToolExecResult {
    let r: ToolExecResult = new ToolExecResult();
    r.ok = false;
    r.output = 'ERROR: ' + output;
    return r;
  }
}
