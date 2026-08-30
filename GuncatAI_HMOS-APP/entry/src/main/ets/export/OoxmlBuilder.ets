import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { MdBlock, InlineToken, InlineParser, MarkdownParser } from './MarkdownParser';
import { OmmlConverter } from './OmmlConverter';
import { XmlUtil } from './XmlUtil';

// 将 Markdown 块渲染为完整的 OOXML (docx) 各部件 XML
// 生成: document.xml / styles.xml / numbering.xml / [Content_Types].xml / rels / core.xml / app.xml
// 图片支持: dataUrl 内嵌 + http(s) 下载, 自动读取宽高按比例缩放到页宽

// 图片部件
export class MediaPart {
  relId: string = '';
  name: string = '';
  mime: string = '';
  data: Uint8Array = new Uint8Array(0);
  width: number = 0;   // 像素
  height: number = 0;  // 像素
}

// 超链接记录
class HyperlinkRec {
  relId: string = '';
  url: string = '';
}

// 构建结果
export class OoxmlDocument {
  documentXml: string = '';
  stylesXml: string = '';
  numberingXml: string = '';
  contentTypesXml: string = '';
  rootRelsXml: string = '';
  documentRelsXml: string = '';
  coreXml: string = '';
  appXml: string = '';
  mediaParts: MediaPart[] = [];
  title: string = '';
}

// 图片尺寸(解析 PNG/JPEG/GIF/BMP 头)
class ImageSize {
  width: number = 0;
  height: number = 0;
}

const XML_HEAD: string = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
const NS_W: string = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
const NS_R: string = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const NS_WP: string = 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing';
const NS_A: string = 'http://schemas.openxmlformats.org/drawingml/2006/main';
const NS_PIC: string = 'http://schemas.openxmlformats.org/drawingml/2006/picture';
const NS_M: string = 'http://schemas.openxmlformats.org/officeDocument/2006/math';

export class OoxmlBuilder {
  private blocks: MdBlock[] = [];
  private mediaParts: MediaPart[] = [];
  private mediaByUrl: Map<string, string> = new Map<string, string>(); // url -> relId
  private hyperlinks: HyperlinkRec[] = [];
  private hyperByUrl: Map<string, string> = new Map<string, string>(); // url -> relId
  private relCounter: number = 1;
  private drawIdCounter: number = 1;

  // 主入口
  static async build(title: string, markdown: string): Promise<OoxmlDocument> {
    let builder: OoxmlBuilder = new OoxmlBuilder();
    builder.blocks = MarkdownParser.parseBlocks(markdown);
    await builder.collectImages();
    let doc: OoxmlDocument = new OoxmlDocument();
    doc.title = title;
    doc.documentXml = builder.buildDocumentXml();
    doc.stylesXml = builder.buildStylesXml();
    doc.numberingXml = builder.buildNumberingXml();
    doc.contentTypesXml = builder.buildContentTypesXml();
    doc.rootRelsXml = builder.buildRootRelsXml();
    doc.documentRelsXml = builder.buildDocumentRelsXml();
    doc.coreXml = builder.buildCoreXml(title);
    doc.appXml = builder.buildAppXml();
    doc.mediaParts = builder.mediaParts;
    return doc;
  }

  // ---------- 图片收集 ----------

  private async collectImages(): Promise<void> {
    let urls: string[] = [];
    let seen: string[] = [];
    for (let b: number = 0; b < this.blocks.length; b++) {
      let block: MdBlock = this.blocks[b];
      if (block.type === 'codeblock' || block.type === 'math' || block.type === 'hr') {
        continue;
      }
      this.collectImagesFromInline(block.inline, urls, seen);
      for (let it: number = 0; it < block.items.length; it++) {
        this.collectImagesFromInline(block.items[it], urls, seen);
      }
      for (let h: number = 0; h < block.tableHeaders.length; h++) {
        this.collectImagesFromInline(block.tableHeaders[h], urls, seen);
      }
      for (let r: number = 0; r < block.tableRows.length; r++) {
        let row: string[] = block.tableRows[r];
        for (let c: number = 0; c < row.length; c++) {
          this.collectImagesFromInline(row[c], urls, seen);
        }
      }
    }
    // 限制图片数量, 防止过大文档
    let limit: number = urls.length > 20 ? 20 : urls.length;
    for (let i: number = 0; i < limit; i++) {
      let url: string = urls[i];
      if (this.mediaByUrl.has(url)) {
        continue;
      }
      let part: MediaPart | null = await this.resolveImage(url);
      if (part !== null) {
        this.mediaParts.push(part);
        this.mediaByUrl.set(url, part.relId);
      }
    }
  }

  private collectImagesFromInline(text: string, urls: string[], seen: string[]): void {
    let tokens: InlineToken[] = InlineParser.parse(text);
    for (let i: number = 0; i < tokens.length; i++) {
      let t: InlineToken = tokens[i];
      if (t.type === 'image') {
        let url: string = t.text.trim();
        if (url === '') {
          continue;
        }
        let dup: boolean = false;
        for (let s: number = 0; s < seen.length; s++) {
          if (seen[s] === url) {
            dup = true;
            break;
          }
        }
        if (!dup) {
          seen.push(url);
          urls.push(url);
        }
      }
    }
  }

  private async resolveImage(url: string): Promise<MediaPart | null> {
    let data: Uint8Array | null = null;
    let mime: string = '';
    if (url.startsWith('data:image/')) {
      let comma: number = url.indexOf(',');
      if (comma === -1) {
        return null;
      }
      let header: string = url.substring(5, comma);
      let semi: number = header.indexOf(';');
      mime = semi !== -1 ? header.substring(0, semi) : 'image/png';
      let b64: string = url.substring(comma + 1);
      try {
        let helper: util.Base64Helper = new util.Base64Helper();
        data = helper.decodeSync(b64);
      } catch (error) {
        data = null;
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      data = await this.downloadImage(url);
      mime = '';
    }
    if (data === null || data.length < 8) {
      return null;
    }
    if (mime === '') {
      mime = OoxmlBuilder.sniffMime(data);
    }
    if (mime === '') {
      return null;
    }
    let size: ImageSize = OoxmlBuilder.parseImageSize(data);
    if (size.width <= 0 || size.height <= 0) {
      return null;
    }
    let part: MediaPart = new MediaPart();
    part.relId = 'rId' + this.relCounter.toString();
    this.relCounter++;
    part.name = 'image' + this.mediaParts.length.toString() + '.' + OoxmlBuilder.extOf(mime);
    part.mime = mime;
    part.data = data;
    part.width = size.width;
    part.height = size.height;
    return part;
  }

  private async downloadImage(url: string): Promise<Uint8Array | null> {
    let req: http.HttpRequest = http.createHttp();
    try {
      let resp: http.HttpResponse = await req.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 10000,
        readTimeout: 15000
      });
      if (resp.responseCode !== 200) {
        return null;
      }
      if (resp.result instanceof ArrayBuffer) {
        return new Uint8Array(resp.result as ArrayBuffer);
      }
      return null;
    } catch (error) {
      return null;
    } finally {
      req.destroy();
    }
  }

  private static sniffMime(data: Uint8Array): string {
    if (data.length >= 8 &&
      data[0] === 0x89 && data[1] === 0x50 && data[2] === 0x4E && data[3] === 0x47) {
      return 'image/png';
    }
    if (data.length >= 3 && data[0] === 0xFF && data[1] === 0xD8 && data[2] === 0xFF) {
      return 'image/jpeg';
    }
    if (data.length >= 6 && data[0] === 0x47 && data[1] === 0x49 && data[2] === 0x46) {
      return 'image/gif';
    }
    if (data.length >= 2 && data[0] === 0x42 && data[1] === 0x4D) {
      return 'image/bmp';
    }
    return '';
  }

  private static extOf(mime: string): string {
    if (mime === 'image/jpeg') {
      return 'jpeg';
    }
    if (mime === 'image/gif') {
      return 'gif';
    }
    if (mime === 'image/bmp') {
      return 'bmp';
    }
    return 'png';
  }

  // 解析图片真实尺寸(像素)
  private static parseImageSize(data: Uint8Array): ImageSize {
    let size: ImageSize = new ImageSize();
    let len: number = data.length;
    if (len >= 24 && data[0] === 0x89 && data[1] === 0x50 && data[2] === 0x4E && data[3] === 0x47) {
      // PNG: IHDR 宽高
      size.width = OoxmlBuilder.be32(data, 16);
      size.height = OoxmlBuilder.be32(data, 20);
      return size;
    }
    if (len >= 10 && data[0] === 0x47 && data[1] === 0x49 && data[2] === 0x46 && data[3] === 0x38) {
      // GIF
      size.width = OoxmlBuilder.le16(data, 6);
      size.height = OoxmlBuilder.le16(data, 8);
      return size;
    }
    if (len >= 26 && data[0] === 0x42 && data[1] === 0x4D) {
      // BMP
      size.width = OoxmlBuilder.le32(data, 18);
      size.height = Math.abs(OoxmlBuilder.le32(data, 22));
      return size;
    }
    if (len >= 4 && data[0] === 0xFF && data[1] === 0xD8 && data[2] === 0xFF) {
      // JPEG: 扫描段找 SOF
      let i: number = 2;
      while (i + 9 < len) {
        if (data[i] !== 0xFF) {
          i++;
          continue;
        }
        let marker: number = data[i + 1];
        if (marker === 0xD8 || marker === 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
          i += 2;
          continue;
        }
        if (marker >= 0xC0 && marker <= 0xCF && marker !== 0xC4 && marker !== 0xC8 && marker !== 0xCC) {
          size.height = OoxmlBuilder.be16(data, i + 5);
          size.width = OoxmlBuilder.be16(data, i + 7);
          return size;
        }
        let segLen: number = OoxmlBuilder.be16(data, i + 2);
        if (segLen < 2) {
          break;
        }
        i += 2 + segLen;
      }
    }
    return size;
  }

  private static be16(d: Uint8Array, off: number): number {
    return (d[off] << 8) | d[off + 1];
  }

  private static be32(d: Uint8Array, off: number): number {
    return ((d[off] << 24) | (d[off + 1] << 16) | (d[off + 2] << 8) | d[off + 3]) >>> 0;
  }

  private static le16(d: Uint8Array, off: number): number {
    return d[off] | (d[off + 1] << 8);
  }

  private static le32(d: Uint8Array, off: number): number {
    return (d[off] | (d[off + 1] << 8) | (d[off + 2] << 16) | (d[off + 3] << 24)) >>> 0;
  }

  // ---------- document.xml ----------

  private buildDocumentXml(): string {
    let body: string = '';
    for (let i: number = 0; i < this.blocks.length; i++) {
      body += this.renderBlock(this.blocks[i]);
    }
    body += '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" ' +
      'w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>';
    return XML_HEAD + '<w:document xmlns:w="' + NS_W + '" xmlns:r="' + NS_R + '" xmlns:wp="' + NS_WP +
      '" xmlns:a="' + NS_A + '" xmlns:pic="' + NS_PIC + '" xmlns:m="' + NS_M + '">' +
      '<w:body>' + body + '</w:body></w:document>';
  }

  private renderBlock(block: MdBlock): string {
    if (block.type === 'heading') {
      let styleId: string = 'Heading' + block.level.toString();
      return '<w:p><w:pPr><w:pStyle w:val="' + styleId + '"/></w:pPr>' +
        this.renderInline(block.inline) + '</w:p>';
    }
    if (block.type === 'paragraph') {
      return '<w:p>' + this.renderInline(block.inline) + '</w:p>';
    }
    if (block.type === 'codeblock') {
      return this.renderCodeBlock(block);
    }
    if (block.type === 'quote') {
      let lines: string[] = block.inline.split('\n');
      let out: string = '';
      for (let i: number = 0; i < lines.length; i++) {
        out += '<w:p><w:pPr><w:pStyle w:val="Quote"/></w:pPr>' + this.renderInline(lines[i]) + '</w:p>';
      }
      return out;
    }
    if (block.type === 'ul' || block.type === 'ol') {
      let numId: number = block.type === 'ul' ? 1 : 2;
      let out: string = '';
      for (let i: number = 0; i < block.items.length; i++) {
        let ilvl: number = 0;
        if (i < block.itemLevels.length) {
          ilvl = block.itemLevels[i];
        }
        let styleId: string = block.type === 'ul' ? 'ListBullet' : 'ListNumber';
        out += '<w:p><w:pPr><w:pStyle w:val="' + styleId + '"/>' +
          '<w:numPr><w:ilvl w:val="' + ilvl.toString() + '"/><w:numId w:val="' + numId.toString() + '"/></w:numPr>' +
          '</w:pPr>' + this.renderInline(block.items[i]) + '</w:p>';
      }
      return out;
    }
    if (block.type === 'table') {
      return this.renderTable(block);
    }
    if (block.type === 'hr') {
      return '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="C0C0C0"/>' +
        '</w:pBdr><w:spacing w:before="60" w:after="60"/></w:pPr></w:p>';
    }
    if (block.type === 'math') {
      return '<w:p><w:pPr><w:spacing w:before="120" w:after="120"/></w:pPr>' +
        OmmlConverter.display(block.math) + '</w:p>';
    }
    return '<w:p>' + this.renderInline(block.inline) + '</w:p>';
  }

  private renderCodeBlock(block: MdBlock): string {
    let code: string = block.code.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    let lines: string[] = code.split('\n');
    if (lines.length === 0) {
      lines = [''];
    }
    let out: string = '';
    for (let i: number = 0; i < lines.length; i++) {
      let line: string = lines[i];
      out += '<w:p><w:pPr><w:pStyle w:val="CodeBlock"/></w:pPr>' +
        '<w:r><w:rPr><w:rStyle w:val="CodeChar"/></w:rPr>' +
        '<w:t xml:space="preserve">' + XmlUtil.escape(line) + '</w:t></w:r></w:p>';
    }
    return out;
  }

  private renderTable(block: MdBlock): string {
    let colCount: number = block.tableHeaders.length;
    for (let r: number = 0; r < block.tableRows.length; r++) {
      if (block.tableRows[r].length > colCount) {
        colCount = block.tableRows[r].length;
      }
    }
    if (colCount === 0) {
      colCount = 1;
    }
    let contentWidth: number = 9026; // 页宽11906 - 左右边距2880
    let colW: number = Math.floor(contentWidth / colCount);
    let grid: string = '';
    for (let c: number = 0; c < colCount; c++) {
      grid += '<w:gridCol w:w="' + colW.toString() + '"/>';
    }
    let xml: string = '<w:tbl><w:tblPr><w:tblW w:w="' + contentWidth.toString() + '" w:type="dxa"/>' +
      '<w:tblBorders>' +
      '<w:top w:val="single" w:sz="4" w:space="0" w:color="A6A6A6"/>' +
      '<w:left w:val="single" w:sz="4" w:space="0" w:color="A6A6A6"/>' +
      '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="A6A6A6"/>' +
      '<w:right w:val="single" w:sz="4" w:space="0" w:color="A6A6A6"/>' +
      '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="A6A6A6"/>' +
      '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="A6A6A6"/>' +
      '</w:tblBorders>' +
      '<w:tblCellMar><w:top w:w="60" w:type="dxa"/><w:left w:w="100" w:type="dxa"/>' +
      '<w:bottom w:w="60" w:type="dxa"/><w:right w:w="100" w:type="dxa"/></w:tblCellMar>' +
      '</w:tblPr><w:tblGrid>' + grid + '</w:tblGrid>';
    // 表头
    xml += this.renderTableRow(block.tableHeaders, colCount, colW, true);
    // 数据行
    for (let r: number = 0; r < block.tableRows.length; r++) {
      xml += this.renderTableRow(block.tableRows[r], colCount, colW, false);
    }
    xml += '</w:tbl>';
    // 表后留一个空行, 避免与下段粘连
    xml += '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr></w:p>';
    return xml;
  }

  private renderTableRow(cells: string[], colCount: number, colW: number, header: boolean): string {
    let xml: string = '<w:tr>';
    for (let c: number = 0; c < colCount; c++) {
      let cellText: string = c < cells.length ? cells[c] : '';
      let tcPr: string = '<w:tcPr><w:tcW w:w="' + colW.toString() + '" w:type="dxa"/>' +
        '<w:vAlign w:val="center"/>';
      if (header) {
        tcPr += '<w:shd w:val="clear" w:color="auto" w:fill="E8EDF5"/>';
      }
      tcPr += '</w:tcPr>';
      // 表头强制加粗
      let content: string = '<w:p><w:pPr><w:spacing w:before="20" w:after="20"/></w:pPr>' +
        this.renderInline(cellText, header) + '</w:p>';
      xml += '<w:tc>' + tcPr + content + '</w:tc>';
    }
    xml += '</w:tr>';
    return xml;
  }

  // ---------- 行内渲染 ----------

  private renderInline(text: string, forceBold: boolean = false): string {
    if (text === '') {
      return '';
    }
    let tokens: InlineToken[] = InlineParser.parse(text);
    let out: string = '';
    for (let i: number = 0; i < tokens.length; i++) {
      out += this.renderToken(tokens[i], forceBold);
    }
    return out;
  }

  private renderToken(token: InlineToken, forceBold: boolean): string {
    if (token.type === 'br') {
      return '<w:r><w:br/></w:r>';
    }
    if (token.type === 'math') {
      if (token.displayMath) {
        return '<w:r>' + OmmlConverter.display(token.text) + '</w:r>';
      }
      return '<w:r>' + OmmlConverter.inline(token.text) + '</w:r>';
    }
    if (token.type === 'link') {
      let relId: string = this.ensureHyperlink(token.href);
      if (relId === '') {
        return this.renderRun(token.text, token.bold, token.italic, token.strike, false, forceBold);
      }
      return '<w:hyperlink r:id="' + relId + '" w:history="1">' +
        this.renderInline(token.text, forceBold) + '</w:hyperlink>';
    }
    if (token.type === 'image') {
      return this.renderImage(token);
    }
    // text
    return this.renderRun(token.text, token.bold, token.italic, token.strike, token.code, forceBold);
  }

  private renderRun(text: string, bold: boolean, italic: boolean, strike: boolean,
    code: boolean, forceBold: boolean): string {
    let rPr: string = '';
    if (code) {
      rPr += '<w:rStyle w:val="CodeChar"/>';
    }
    if (bold || forceBold) {
      rPr += '<w:b/><w:bCs/>';
    }
    if (italic) {
      rPr += '<w:i/><w:iCs/>';
    }
    if (strike) {
      rPr += '<w:strike/>';
    }
    let rPrXml: string = rPr === '' ? '' : '<w:rPr>' + rPr + '</w:rPr>';
    return '<w:r>' + rPrXml + '<w:t xml:space="preserve">' + XmlUtil.escape(text) + '</w:t></w:r>';
  }

  private ensureHyperlink(url: string): string {
    if (this.hyperByUrl.has(url)) {
      return this.hyperByUrl.get(url) as string;
    }
    if (url === '') {
      return '';
    }
    let rec: HyperlinkRec = new HyperlinkRec();
    rec.relId = 'rId' + this.relCounter.toString();
    this.relCounter++;
    rec.url = url;
    this.hyperlinks.push(rec);
    this.hyperByUrl.set(url, rec.relId);
    return rec.relId;
  }

  private renderImage(token: InlineToken): string {
    let url: string = token.text.trim();
    let relId: string | undefined = this.mediaByUrl.get(url);
    if (relId === undefined) {
      // 无法获取图片: 回退为 alt 文本
      let alt: string = token.alt !== '' ? token.alt : url;
      return this.renderRun(alt, false, true, false, false, false);
    }
    let part: MediaPart | null = null;
    for (let i: number = 0; i < this.mediaParts.length; i++) {
      if (this.mediaParts[i].relId === relId) {
        part = this.mediaParts[i];
        break;
      }
    }
    if (part === null) {
      return '';
    }
    // 按页宽限制尺寸 (最大 550px ≈ 5.8 英寸)
    let maxW: number = 550;
    let w: number = part.width;
    let h: number = part.height;
    if (w > maxW) {
      h = Math.round(h * maxW / w);
      w = maxW;
    }
    let cx: number = Math.round(w * 9525);
    let cy: number = Math.round(h * 9525);
    let drawId: number = this.drawIdCounter;
    this.drawIdCounter++;
    let picName: string = '图片' + drawId.toString();
    return '<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">' +
      '<wp:extent cx="' + cx.toString() + '" cy="' + cy.toString() + '"/>' +
      '<wp:effectExtent l="0" t="0" r="0" b="0"/>' +
      '<wp:docPr id="' + drawId.toString() + '" name="' + picName + '"/>' +
      '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>' +
      '<a:graphic><a:graphicData uri="' + NS_PIC + '">' +
      '<pic:pic><pic:nvPicPr><pic:cNvPr id="0" name="' + picName + '"/><pic:cNvPicPr/></pic:nvPicPr>' +
      '<pic:blipFill><a:blip r:embed="' + relId + '"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>' +
      '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="' + cx.toString() + '" cy="' + cy.toString() + '"/>' +
      '</a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>' +
      '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>';
  }

  // ---------- styles.xml ----------

  private buildStylesXml(): string {
    let styles: string = XML_HEAD + '<w:styles xmlns:w="' + NS_W + '">';
    styles += '<w:docDefaults><w:rPrDefault><w:rPr>' +
      '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="宋体" w:cs="Calibri"/>' +
      '<w:sz w:val="22"/><w:szCs w:val="22"/>' +
      '<w:lang w:val="en-US" w:eastAsia="zh-CN" w:bidi="ar-SA"/></w:rPr></w:rPrDefault>' +
      '<w:pPrDefault><w:pPr><w:spacing w:after="60" w:line="300" w:lineRule="auto"/>' +
      '</w:pPr></w:pPrDefault></w:docDefaults>';
    styles += '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">' +
      '<w:name w:val="Normal"/><w:qFormat/></w:style>';
    // 标题样式: 加粗 + 主题色 + 分级字号
    let headingSizes: string[] = ['32', '28', '26', '24', '22', '22'];
    let headingColors: string[] = ['1F3864', '2F5496', '305496', '44546A', '44546A', '44546A'];
    for (let h: number = 1; h <= 6; h++) {
      styles += '<w:style w:type="paragraph" w:styleId="Heading' + h.toString() + '">' +
        '<w:name w:val="heading ' + h.toString() + '"/><w:basedOn w:val="Normal"/>' +
        '<w:next w:val="Normal"/><w:qFormat/><w:uiPriority w:val="9"/>' +
        '<w:pPr><w:keepNext/><w:keepLines/>' +
        '<w:spacing w:before="' + (h === 1 ? '240' : '180').toString() + '" w:after="120"/>' +
        '<w:outlineLvl w:val="' + (h - 1).toString() + '"/></w:pPr>' +
        '<w:rPr><w:rFonts w:asciiTheme="majorHAnsi" w:hAnsiTheme="majorHAnsi" w:eastAsia="黑体"/>' +
        '<w:b/><w:bCs/><w:color w:val="' + headingColors[h - 1] + '"/>' +
        '<w:sz w:val="' + headingSizes[h - 1] + '"/><w:szCs w:val="' + headingSizes[h - 1] + '"/></w:rPr>' +
        '</w:style>';
    }
    // 引用
    styles += '<w:style w:type="paragraph" w:styleId="Quote"><w:name w:val="Quote"/>' +
      '<w:basedOn w:val="Normal"/><w:qFormat/><w:uiPriority w:val="15"/>' +
      '<w:pPr><w:spacing w:before="60" w:after="60"/><w:ind w:left="425"/>' +
      '<w:pBdr><w:left w:val="single" w:sz="12" w:space="8" w:color="9E9E9E"/></w:pBdr></w:pPr>' +
      '<w:rPr><w:color w:val="616161"/></w:rPr></w:style>';
    // 代码块
    styles += '<w:style w:type="paragraph" w:styleId="CodeBlock"><w:name w:val="CodeBlock"/>' +
      '<w:basedOn w:val="Normal"/><w:qFormat/><w:uiPriority w:val="16"/>' +
      '<w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>' +
      '<w:ind w:left="140" w:right="140"/>' +
      '<w:shd w:val="clear" w:color="auto" w:fill="F5F5F5"/></w:pPr></w:style>';
    // 列表
    styles += '<w:style w:type="paragraph" w:styleId="ListBullet"><w:name w:val="ListBullet"/>' +
      '<w:basedOn w:val="Normal"/><w:uiPriority w:val="17"/>' +
      '<w:pPr><w:ind w:left="567" w:hanging="283"/></w:pPr></w:style>';
    styles += '<w:style w:type="paragraph" w:styleId="ListNumber"><w:name w:val="ListNumber"/>' +
      '<w:basedOn w:val="Normal"/><w:uiPriority w:val="18"/>' +
      '<w:pPr><w:ind w:left="567" w:hanging="283"/></w:pPr></w:style>';
    // 字符样式
    styles += '<w:style w:type="character" w:styleId="CodeChar"><w:name w:val="CodeChar"/>' +
      '<w:basedOn w:val="DefaultParagraphFont"/><w:uiPriority w:val="19"/>' +
      '<w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas" w:eastAsia="宋体"/>' +
      '<w:sz w:val="19"/><w:szCs w:val="19"/><w:color w:val="C7254E"/>' +
      '<w:shd w:val="clear" w:color="auto" w:fill="F3EFF4"/></w:rPr></w:style>';
    styles += '<w:style w:type="character" w:styleId="Hyperlink"><w:name w:val="Hyperlink"/>' +
      '<w:basedOn w:val="DefaultParagraphFont"/><w:uiPriority w:val="20"/>' +
      '<w:rPr><w:color w:val="0563C1"/><w:u w:val="single"/></w:rPr></w:style>';
    styles += '</w:styles>';
    return styles;
  }

  // ---------- numbering.xml ----------

  private buildNumberingXml(): string {
    return XML_HEAD + '<w:numbering xmlns:w="' + NS_W + '">' +
      '<w:abstractNum w:abstractNumId="0">' +
      '<w:multiLevelType w:val="hybridMultilevel"/>' +
      '<w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="•"/>' +
      '<w:lvlJc w:val="left"/><w:pPr><w:ind w:left="567" w:hanging="283"/></w:pPr>' +
      '<w:rPr><w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/></w:rPr></w:lvl>' +
      '<w:lvl w:ilvl="1"><w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="◦"/>' +
      '<w:lvlJc w:val="left"/><w:pPr><w:ind w:left="850" w:hanging="425"/></w:pPr>' +
      '<w:rPr><w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/></w:rPr></w:lvl>' +
      '</w:abstractNum>' +
      '<w:abstractNum w:abstractNumId="1">' +
      '<w:multiLevelType w:val="hybridMultilevel"/>' +
      '<w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/>' +
      '<w:lvlJc w:val="left"/><w:pPr><w:ind w:left="567" w:hanging="283"/></w:pPr></w:lvl>' +
      '<w:lvl w:ilvl="1"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%2."/>' +
      '<w:lvlJc w:val="left"/><w:pPr><w:ind w:left="850" w:hanging="425"/></w:pPr></w:lvl>' +
      '</w:abstractNum>' +
      '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>' +
      '<w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>' +
      '</w:numbering>';
  }

  // ---------- 包结构部件 ----------

  private buildContentTypesXml(): string {
    let types: string = XML_HEAD + '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
      '<Default Extension="xml" ContentType="application/xml"/>' +
      '<Default Extension="png" ContentType="image/png"/>' +
      '<Default Extension="jpeg" ContentType="image/jpeg"/>' +
      '<Default Extension="gif" ContentType="image/gif"/>' +
      '<Default Extension="bmp" ContentType="image/bmp"/>' +
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' +
      '<Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>' +
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
      '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>' +
      '</Types>';
    return types;
  }

  private buildRootRelsXml(): string {
    return XML_HEAD + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>' +
      '</Relationships>';
  }

  private buildDocumentRelsXml(): string {
    let rels: string = XML_HEAD + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
    for (let i: number = 0; i < this.mediaParts.length; i++) {
      let part: MediaPart = this.mediaParts[i];
      rels += '<Relationship Id="' + part.relId + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/' + part.name + '"/>';
    }
    for (let i: number = 0; i < this.hyperlinks.length; i++) {
      let rec: HyperlinkRec = this.hyperlinks[i];
      rels += '<Relationship Id="' + rec.relId + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="' +
        XmlUtil.escapeAttr(rec.url) + '" TargetMode="External"/>';
    }
    rels += '</Relationships>';
    return rels;
  }

  private buildCoreXml(title: string): string {
    let now: string = XmlUtil.isoDateTime();
    return XML_HEAD + '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ' +
      'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" ' +
      'xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
      '<dc:title>' + XmlUtil.escape(title) + '</dc:title>' +
      '<dc:creator>Guncat Work</dc:creator>' +
      '<cp:lastModifiedBy>Guncat Work</cp:lastModifiedBy>' +
      '<dcterms:created xsi:type="dcterms:W3CDTF">' + now + '</dcterms:created>' +
      '<dcterms:modified xsi:type="dcterms:W3CDTF">' + now + '</dcterms:modified>' +
      '</cp:coreProperties>';
  }

  private buildAppXml(): string {
    return XML_HEAD + '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" ' +
      'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">' +
      '<Application>Guncat Work</Application>' +
      '<DocSecurity>0</DocSecurity>' +
      '<ScaleCrop>false</ScaleCrop>' +
      '<LinksUpToDate>false</LinksUpToDate>' +
      '<SharedDoc>false</SharedDoc>' +
      '<HyperlinksChanged>false</HyperlinksChanged>' +
      '<AppVersion>16.0000</AppVersion>' +
      '</Properties>';
  }
}
