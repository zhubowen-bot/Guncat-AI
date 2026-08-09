import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { MultimodalConfig } from '../model/MultimodalConfig';
import { ApiConfig } from '../model/ApiConfig';
import { ApiProfile } from '../model/ApiProfile';
import { StorageManager } from '../data/StorageManager';
import { Constants } from '../common/Constants';
import { FileService, PickedFile } from '../service/FileService';
import { TableOcrService } from '../service/TableOcrService';
import { HtmlTableParser, TableGridInfo, TableCellInfo, TableRowInfo } from '../export/TableHtmlParser';
import { XlsxExporter } from '../export/XlsxExporter';
import { XmlUtil } from '../export/XmlUtil';

// 平台预设 (对齐 web 版本 PROVIDERS)
export class ProviderPreset {
  name: string = '';
  baseUrl: string = '';
  model: string = '';

  constructor(name: string, baseUrl: string, model: string) {
    this.name = name;
    this.baseUrl = baseUrl;
    this.model = model;
  }
}

// 预览用单元格 (带网格坐标)
export class PreviewCell {
  r: number = 0;
  c: number = 0;
  rowspan: number = 1;
  colspan: number = 1;
  text: string = '';
  isHeader: boolean = false;
  height: number = 36;
}

const PRESETS: ProviderPreset[] = [
  new ProviderPreset('智谱 GLM', 'https://open.bigmodel.cn/api/paas/v4', 'glm-4.6v-flash'),
  new ProviderPreset('火山方舟 (豆包)', 'https://ark.cn-beijing.volces.com/api/v3', 'doubao-seed-2-0-lite-260428')
];

const COLUMN_WIDTH: number = 90;
const BASE_ROW_HEIGHT: number = 36;
const LINE_VP: number = 18;

@Entry
@Component
struct TableOcrPage {
  @State providerIndex: number = 0;
  @State modelText: string = '';
  @State apiKeyText: string = '';
  @State keySavedHint: string = '';
  @State selectedUri: string = '';
  @State converting: boolean = false;
  @State statusText: string = '';
  @State errorMsg: string = '';
  @State activeTab: number = 0;
  @State grid: TableGridInfo | null = null;
  @State currentHtml: string = '';
  @State excelInfo: string = '';
  @State gridInfoLines: string[] = [];
  @State gridInfoOk: boolean = true;
  @State debugText: string = '';
  @State previewCells: PreviewCell[] = [];
  @State gridTotalHeight: number = 120;
  private currentProfile: ApiProfile = ApiProfile.create('默认配置');
  private selectedBytes: ArrayBuffer | null = null;
  private selectedMime: string = 'image/jpeg';

  aboutToAppear(): void {
    this.loadConfig();
  }

  private async loadConfig(): Promise<void> {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    try {
      this.currentProfile = await this.loadCurrentProfile(context);
    } catch (e) {
      this.currentProfile = ApiProfile.fromLegacy('默认配置', ApiConfig.default(), MultimodalConfig.default());
    }
    let savedProvider: string = await StorageManager.loadString(
      context, Constants.LS_KEY_TABLE_OCR_PROVIDER, '');
    if (savedProvider === 'volc') {
      this.providerIndex = 1;
    } else if (savedProvider !== 'zhipu' &&
      this.currentProfile.multimodalConfig.baseUrl.indexOf('volces.com') !== -1) {
      // 兼容旧版本: 火山配置以前直接写在多模态配置里
      this.providerIndex = 1;
    } else {
      this.providerIndex = 0;
    }
    this.applyProviderFields();
  }

  // 加载当前使用中的 API 配置 (无 profile 时用旧版单配置降级)
  private async loadCurrentProfile(context: common.UIAbilityContext): Promise<ApiProfile> {
    let profiles: ApiProfile[] = await StorageManager.loadApiProfiles(context);
    if (profiles.length === 0) {
      let api: ApiConfig | null = await StorageManager.loadApiConfig(context);
      let legacyApi: ApiConfig = api !== null ? api : ApiConfig.default();
      let legacyMm: MultimodalConfig = await StorageManager.loadMultimodalConfig(context);
      return ApiProfile.fromLegacy('默认配置', legacyApi, legacyMm);
    }
    let savedId: string = await StorageManager.loadString(
      context, Constants.LS_KEY_CURRENT_API_PROFILE_ID, '');
    for (let i: number = 0; i < profiles.length; i++) {
      if (profiles[i].id === savedId) {
        return profiles[i];
      }
    }
    return profiles[0];
  }

  // 智谱 → 多模态解析引擎配置; 火山方舟 → 支持原生多模态的主模型配置
  private applyProviderFields(): void {
    if (this.providerIndex === 1) {
      let api: ApiConfig = this.currentProfile.apiConfig;
      this.modelText = api.model;
      this.apiKeyText = api.apiKey;
    } else {
      let mm: MultimodalConfig = this.currentProfile.multimodalConfig;
      this.modelText = mm.model;
      this.apiKeyText = mm.apiKey;
    }
    this.keySavedHint = '';
  }

  private getPreset(): ProviderPreset {
    return PRESETS[this.providerIndex];
  }

  private async saveSettings(): Promise<void> {
    let preset: ProviderPreset = this.getPreset();
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    if (this.providerIndex === 1) {
      // 火山方舟: 保存到主模型配置
      let api: ApiConfig = this.currentProfile.apiConfig;
      api.provider = 'volcano';
      api.baseUrl = preset.baseUrl;
      api.model = this.modelText.trim() === '' ? preset.model : this.modelText.trim();
      api.apiKey = this.apiKeyText.trim();
      await this.persistCurrentProfile(context);
      await StorageManager.saveApiConfig(context, api);
      this.keySavedHint = '✓ 已保存 (与主模型配置同步)';
    } else {
      // 智谱: 保存到多模态解析引擎配置
      let mm: MultimodalConfig = this.currentProfile.multimodalConfig;
      mm.baseUrl = preset.baseUrl;
      mm.model = this.modelText.trim() === '' ? preset.model : this.modelText.trim();
      mm.apiKey = this.apiKeyText.trim();
      await this.persistCurrentProfile(context);
      await StorageManager.saveMultimodalConfig(context, mm);
      this.keySavedHint = '✓ 已保存 (与多模态解析配置同步)';
    }
    promptAction.showToast({ message: '配置已保存', duration: 1500 });
  }

  private async persistCurrentProfile(context: common.UIAbilityContext): Promise<void> {
    let profiles: ApiProfile[] = await StorageManager.loadApiProfiles(context);
    let found: boolean = false;
    for (let i: number = 0; i < profiles.length; i++) {
      if (profiles[i].id === this.currentProfile.id) {
        profiles[i] = this.currentProfile;
        found = true;
        break;
      }
    }
    if (!found) {
      profiles.push(this.currentProfile);
    }
    await StorageManager.saveApiProfiles(context, profiles);
  }

  private async persistProvider(): Promise<void> {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    await StorageManager.saveString(
      context, Constants.LS_KEY_TABLE_OCR_PROVIDER, this.providerIndex === 1 ? 'volc' : 'zhipu');
  }

  private async pickImage(): Promise<void> {
    if (this.converting) {
      return;
    }
    let files: PickedFile[] = [];
    try {
      files = await FileService.pickImages();
    } catch (e) {
      this.errorMsg = '选择图片失败: ' + (e as Error).message;
      return;
    }
    if (files.length === 0) {
      return;
    }
    let file: PickedFile = files[0];
    this.selectedUri = file.uri;
    this.selectedBytes = file.buffer;
    this.selectedMime = file.fileType;
    this.errorMsg = '';
    this.statusText = '';
    this.grid = null;
    this.currentHtml = '';
  }

  private clearAll(): void {
    this.selectedUri = '';
    this.selectedBytes = null;
    this.errorMsg = '';
    this.statusText = '';
    this.grid = null;
    this.currentHtml = '';
    this.excelInfo = '';
    this.gridInfoLines = [];
    this.debugText = '';
    this.previewCells = [];
  }

  private async startRecognize(): Promise<void> {
    if (this.selectedBytes === null) {
      return;
    }
    if (this.apiKeyText.trim() === '') {
      this.errorMsg = '请先填写 API Key';
      return;
    }
    let preset: ProviderPreset = this.getPreset();
    this.errorMsg = '';
    this.converting = true;
    this.statusText = '正在调用 ' + preset.name + '...';
    try {
      let config: MultimodalConfig = new MultimodalConfig();
      config.baseUrl = preset.baseUrl;
      config.model = this.modelText.trim() === '' ? preset.model : this.modelText.trim();
      config.apiKey = this.apiKeyText.trim();
      let compressed = await TableOcrService.compressImage(this.selectedBytes);
      let raw: string = await TableOcrService.recognizeImage(config, compressed);
      let html: string = TableOcrService.cleanHtml(raw);
      let parsed: TableGridInfo = HtmlTableParser.parse(html);
      this.currentHtml = html;
      this.grid = parsed;
      this.debugText = HtmlTableParser.debugJson(parsed);
      this.buildPreview(parsed);
      this.buildGridInfo(parsed);
      this.buildExcelInfo(parsed);
      this.activeTab = 0;
      this.statusText = '✓ 识别完成';
    } catch (e) {
      let err: Error = e as Error;
      this.errorMsg = err.message;
      this.statusText = '✗ 失败';
    } finally {
      this.converting = false;
    }
  }

  // 构建预览单元格列表 (带坐标与高度)
  private buildPreview(info: TableGridInfo): void {
    let heights: number[] = [];
    let rows: number = info.totalRows;
    for (let r: number = 0; r < rows; r++) {
      let h: number = BASE_ROW_HEIGHT;
      if (info.rowData[r].dataLines > 1) {
        h = info.rowData[r].dataLines * LINE_VP;
      }
      heights.push(Math.max(h, BASE_ROW_HEIGHT));
    }
    let cells: PreviewCell[] = [];
    for (let r: number = 0; r < rows; r++) {
      for (let c: number = 0; c < info.maxCols; c++) {
        let cell: TableCellInfo | null = info.grid[r][c];
        if (cell === null) {
          continue;
        }
        let pc: PreviewCell = new PreviewCell();
        pc.r = r;
        pc.c = c;
        pc.rowspan = cell.rowspan;
        pc.colspan = cell.colspan;
        pc.text = cell.text;
        pc.isHeader = cell.isHeader;
        let total: number = 0;
        for (let dr: number = 0; dr < cell.rowspan; dr++) {
          total += heights[r + dr];
        }
        let textLines: number = 1;
        if (cell.text.indexOf('\n') !== -1) {
          textLines = cell.text.split('\n').length;
        }
        pc.height = Math.max(total, textLines * LINE_VP + 10);
        cells.push(pc);
      }
    }
    let totalHeight: number = 0;
    for (let r: number = 0; r < heights.length; r++) {
      totalHeight += heights[r];
    }
    this.previewCells = cells;
    this.gridTotalHeight = totalHeight;
  }

  private columnsTemplate(): string {
    let s: string = '';
    let cols: number = this.grid !== null ? this.grid.maxCols : 1;
    for (let i: number = 0; i < cols; i++) {
      s += COLUMN_WIDTH.toString() + 'vp ';
    }
    return s.trim();
  }

  private buildGridInfo(info: TableGridInfo): void {
    let lines: string[] = [];
    let ok: boolean = true;
    lines.push('共 ' + info.totalRows.toString() + ' 行 × ' + info.maxCols.toString() + ' 列');
    for (let r: number = 0; r < info.grid.length; r++) {
      if (info.grid[r].length !== info.maxCols) {
        lines.push('⚠ 第 ' + (r + 1).toString() + ' 行: ' + info.grid[r].length.toString() +
          ' 列 (应为 ' + info.maxCols.toString() + ')');
        ok = false;
      }
    }
    if (ok) {
      lines.push('✓ 列数一致性校验通过');
    }
    for (let r: number = 0; r < info.rowData.length; r++) {
      let row: TableRowInfo = info.rowData[r];
      if (row.dataLines > 1 || row.dataH !== '') {
        lines.push('高行: 第' + (r + 1).toString() + '行 (data-lines=' + row.dataLines.toString() +
          (row.dataH !== '' ? ', data-h=' + row.dataH : '') + ')');
      }
    }
    this.gridInfoLines = lines;
    this.gridInfoOk = ok;
  }

  private buildExcelInfo(info: TableGridInfo): void {
    let merges: number = 0;
    for (let r: number = 0; r < info.grid.length; r++) {
      for (let c: number = 0; c < info.maxCols; c++) {
        let cell: TableCellInfo | null = info.grid[r][c];
        if (cell !== null && (cell.rowspan > 1 || cell.colspan > 1)) {
          merges++;
        }
      }
    }
    let highRows: number = 0;
    for (let r: number = 0; r < info.rowData.length; r++) {
      if (info.rowData[r].dataLines > 1) {
        highRows++;
      }
    }
    this.excelInfo = info.totalRows.toString() + ' 行 × ' + info.maxCols.toString() + ' 列 · ' +
      merges.toString() + ' 个合并 · ' + highRows.toString() + ' 个高行';
  }

  private async copyHtml(): Promise<void> {
    if (this.currentHtml === '') {
      return;
    }
    let data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.currentHtml);
    await pasteboard.getSystemPasteboard().setData(data);
    promptAction.showToast({ message: '已复制', duration: 1500 });
  }

  private async downloadHtml(): Promise<void> {
    if (this.currentHtml === '') {
      return;
    }
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    try {
      let encoder: util.TextEncoder = new util.TextEncoder();
      let bytes: Uint8Array = encoder.encodeInto(this.currentHtml);
      let fileName: string = await XlsxExporter.saveBytesViaPicker(context, bytes,
        '表格-' + XmlUtil.stamp(), '.html');
      promptAction.showToast({ message: '已保存 ' + fileName, duration: 2000 });
    } catch (e) {
      promptAction.showToast({ message: '保存失败: ' + (e as Error).message, duration: 2000 });
    }
  }

  private async downloadExcel(): Promise<void> {
    if (this.grid === null) {
      return;
    }
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    try {
      let fileName: string = await XlsxExporter.exportXlsx(context,
        this.grid.grid, this.grid.rowData, this.grid.maxCols);
      promptAction.showToast({ message: '已导出 ' + fileName, duration: 2000 });
    } catch (e) {
      promptAction.showToast({ message: '导出失败: ' + (e as Error).message, duration: 2000 });
    }
  }

  build() {
    Column() {
      this.buildHeader()
      Scroll() {
        Column() {
          this.buildApiSection()
          this.buildUploadSection()
          if (this.grid !== null) {
            this.buildResultSection()
          }
          if (this.errorMsg !== '') {
            this.buildErrorBox()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 32 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildHeader() {
    Column() {
      Row() {
        Button() {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: -4 })
        }
        .width(40)
        .height(40)
        .borderRadius(10)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })
        Text('表格识别引擎')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 4 })
        Blank()
      }
      .width('100%')
      .height(52)
      .padding({ left: 6, right: 12 })
      .alignItems(VerticalAlign.Center)
      Text('图片 → HTML 表格 → Excel（保留合并单元格 + 行高）')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 10 })
    }
    .width('100%')
    .backgroundColor($r('app.color.surface'))
    .border({ width: { bottom: 1 }, color: $r('app.color.border') })
  }

  // ============ 1. API 设置 ============
  @Builder
  buildApiSection() {
    Column() {
      this.buildStepTitle('1', 'API 设置')
      Select([{ value: PRESETS[0].name }, { value: PRESETS[1].name }])
        .selected(this.providerIndex)
        .width('100%')
        .height(40)
        .borderRadius(8)
        .backgroundColor($r('app.color.surface_secondary'))
        .font({ size: 14 })
        .onSelect((index: number) => {
          if (this.providerIndex === index) {
            return;
          }
          this.providerIndex = index;
          this.applyProviderFields();
          this.persistProvider();
        })
      Text('平台')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 10, bottom: 4 })
      TextInput({ placeholder: '模型名称或 Endpoint ID', text: this.modelText })
        .width('100%')
        .height(40)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor($r('app.color.surface_secondary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .borderRadius(8)
        .onChange((value: string) => {
          this.modelText = value;
          this.keySavedHint = '';
        })
      Text('模型')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 10, bottom: 4 })
      TextInput({ placeholder: 'sk-...', text: this.apiKeyText })
        .type(InputType.Password)
        .width('100%')
        .height(40)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor($r('app.color.surface_secondary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .borderRadius(8)
        .onChange((value: string) => {
          this.apiKeyText = value;
          this.keySavedHint = '';
        })
      Text('API Key')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 10, bottom: 4 })
      Row() {
        Button('保存到本地')
          .fontSize(13)
          .height(32)
          .padding({ left: 14, right: 14 })
          .backgroundColor($r('app.color.surface_secondary'))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(8)
          .onClick(() => {
            this.saveSettings();
          })
        Text(this.keySavedHint)
          .fontSize(11)
          .fontColor($r('app.color.success'))
          .margin({ left: 10 })
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
      Text('• 智谱：引用「设置 → 多模态解析引擎」的配置，Key 从 open.bigmodel.cn 获取')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .margin({ top: 12 })
      Text('• 火山方舟：引用「设置 → 主模型」的配置（需为支持原生多模态的豆包模型），Key 从 console.volcengine.com 获取')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .margin({ top: 4 })
      Text('• 两个平台引用各自的 Key，互不共用；切换平台后自动读取对应配置')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(14)
    .margin({ top: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  // ============ 2. 上传 ============
  @Builder
  buildUploadSection() {
    Column() {
      this.buildStepTitle('2', '上传表格图片')
      Column() {
        if (this.selectedUri === '') {
          Column() {
            SymbolGlyph($r('sys.symbol.camera'))
              .fontSize(40)
              .fontColor([$r('app.color.text_tertiary')])
              .margin({ bottom: 8 })
            Text('点击选择图片')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Text('支持 JPG / PNG / WebP，建议宽度 1000-3000px')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 36, bottom: 36 })
          .justifyContent(FlexAlign.Center)
        } else {
          Image(this.selectedUri)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Contain)
            .borderRadius(10)
            .backgroundColor($r('app.color.background'))
        }
      }
      .width('100%')
      .border({ width: 1.5, style: BorderStyle.Dashed, color: $r('app.color.border') })
      .borderRadius(12)
      .backgroundColor($r('app.color.background'))
      .onClick(() => {
        this.pickImage();
      })
      Row() {
        Button(this.converting ? '识别中...' : '识别表格')
          .fontSize(14)
          .height(38)
          .padding({ left: 20, right: 20 })
          .backgroundColor(this.converting || this.selectedUri === '' ?
            $r('app.color.text_tertiary') : $r('app.color.brand'))
          .fontColor(Color.White)
          .borderRadius(10)
          .enabled(!this.converting && this.selectedUri !== '')
          .onClick(() => {
            this.startRecognize();
          })
        Button('清除')
          .fontSize(13)
          .height(38)
          .padding({ left: 16, right: 16 })
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_secondary'))
          .borderRadius(10)
          .enabled(!this.converting)
          .onClick(() => {
            this.clearAll();
          })
        Text(this.statusText)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 8 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(14)
    .margin({ top: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  // ============ 3. 结果 ============
  @Builder
  buildResultSection() {
    Column() {
      this.buildStepTitle('3', '结果')
      // Tabs
      Row() {
        this.buildTabButton('渲染预览', 0)
        this.buildTabButton('HTML 代码', 1)
        this.buildTabButton('网格结构', 2)
        this.buildTabButton('调试信息', 3)
      }
      .width('100%')
      .margin({ top: 8 })
      if (this.activeTab === 0) {
        this.buildPreviewTab()
      } else if (this.activeTab === 1) {
        this.buildHtmlTab()
      } else if (this.activeTab === 2) {
        this.buildGridTab()
      } else {
        this.buildDebugTab()
      }
      // Excel 下载
      Row() {
        Button('下载 Excel (.xlsx)')
          .fontSize(14)
          .height(38)
          .padding({ left: 20, right: 20 })
          .backgroundColor($r('app.color.success'))
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => {
            this.downloadExcel();
          })
        Text(this.excelInfo)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 10 })
      }
      .width('100%')
      .margin({ top: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(14)
    .margin({ top: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildTabButton(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.activeTab === index ? $r('app.color.brand') : $r('app.color.text_secondary'))
        .padding({ left: 8, right: 8, top: 8, bottom: 6 })
      Row()
        .width('100%')
        .height(3)
        .borderRadius(1.5)
        .backgroundColor(this.activeTab === index ? $r('app.color.brand') : Color.Transparent)
    }
    .layoutWeight(1)
    .onClick(() => {
      this.activeTab = index;
    })
  }

  // Tab: 渲染预览
  @Builder
  buildPreviewTab() {
    Column() {
      Scroll() {
        this.buildTableGrid()
      }
      .width('100%')
      .height(this.gridTotalHeight + 8)
      .scrollable(ScrollDirection.Free)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
    }
    .width('100%')
    .margin({ top: 12 })
  }

  // Tab: HTML 代码
  @Builder
  buildHtmlTab() {
    Column() {
      Row() {
        Button('复制 HTML')
          .fontSize(12)
          .height(30)
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.surface_secondary'))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(8)
          .onClick(() => {
            this.copyHtml();
          })
        Button('下载 .html')
          .fontSize(12)
          .height(30)
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.surface_secondary'))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(8)
          .margin({ left: 8 })
          .onClick(() => {
            this.downloadHtml();
          })
      }
      .width('100%')
      .margin({ top: 12, bottom: 8 })
      Scroll() {
        Text(this.currentHtml)
          .fontSize(11)
          .fontFamily('monospace')
          .fontColor($r('app.color.code_text'))
          .width('100%')
          .copyOption(CopyOptions.LocalDevice)
      }
      .width('100%')
      .height(260)
      .backgroundColor($r('app.color.code_bg'))
      .borderRadius(10)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .padding(12)
    }
    .width('100%')
  }

  // Tab: 网格结构
  @Builder
  buildGridTab() {
    Column() {
      Column() {
        ForEach(this.gridInfoLines, (line: string) => {
          Text(line)
            .fontSize(12)
            .fontColor(this.gridInfoOk ? $r('app.color.text_secondary') : $r('app.color.danger'))
            .width('100%')
            .margin({ top: 3 })
            .textAlign(TextAlign.Start)
        }, (line: string) => line)
      }
      .width('100%')
      .margin({ top: 12, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
      Scroll() {
        this.buildTableGrid()
      }
      .width('100%')
      .height(this.gridTotalHeight + 8)
      .scrollable(ScrollDirection.Free)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
    }
    .width('100%')
  }

  // Tab: 调试信息
  @Builder
  buildDebugTab() {
    Scroll() {
      Text(this.debugText)
        .fontSize(11)
        .fontFamily('monospace')
        .fontColor($r('app.color.code_text'))
        .width('100%')
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%')
    .height(280)
    .backgroundColor($r('app.color.code_bg'))
    .borderRadius(10)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .margin({ top: 12 })
    .padding(12)
  }

  // 网格渲染 (预览/网格结构共用)
  @Builder
  buildTableGrid() {
    Grid() {
      ForEach(this.previewCells, (cell: PreviewCell) => {
        GridItem() {
          Column() {
            Text(cell.text === '' ? ' ' : cell.text)
              .fontSize(11)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
          }
          .width('100%')
          .height('100%')
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
        }
        .rowStart(cell.r)
        .rowEnd(cell.r + cell.rowspan - 1)
        .columnStart(cell.c)
        .columnEnd(cell.c + cell.colspan - 1)
        .height(cell.height)
        .backgroundColor(cell.isHeader ? $r('app.color.brand_light') : $r('app.color.surface'))
        .border({ width: 0.5, color: $r('app.color.border') })
      }, (cell: PreviewCell) => cell.r.toString() + '_' + cell.c.toString())
    }
    .columnsTemplate(this.columnsTemplate())
    .rowsGap(0)
    .columnsGap(0)
    .width(this.grid !== null ? this.grid.maxCols * COLUMN_WIDTH : 1)
    .height(this.gridTotalHeight)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(10)
    .clip(true)
  }

  @Builder
  buildStepTitle(numberText: string, title: string) {
    Row() {
      Text(numberText)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(20)
        .height(20)
        .textAlign(TextAlign.Center)
        .borderRadius(10)
        .backgroundColor($r('app.color.brand'))
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 8 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  buildErrorBox() {
    Column() {
      Text('出错：')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.danger'))
        .width('100%')
      Text(this.errorMsg)
        .fontSize(12)
        .fontColor($r('app.color.danger'))
        .width('100%')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.brand_light'))
    .borderRadius(10)
    .margin({ top: 12 })
    .alignItems(HorizontalAlign.Start)
  }
}