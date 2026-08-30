// PptxBuilder: 大纲文本 -> .pptx 文件 (工作模式 write_pptx 工具使用)
// 大纲格式:
//   "# 标题"            -> 内容页(标题 + 要点)
//   "## 标题"           -> 分节页(品牌色整版大字)
//   "- 要点" / 普通行    -> 一级要点
//   "  - 要点"(缩进)     -> 二级要点
// 设计: 品牌色顶栏/分节整版、标题与要点字号按内容量自适应、页脚页码;
//      每页为独立文本框(不依赖占位符继承), WPS/PowerPoint 均可打开。
import { XmlUtil } from './XmlUtil';
import { ZipWriter, ZipEntry } from './ZipWriter';

// 解析后的一页
class PptxSlide {
  kind: string = 'content'; // 'content' | 'section'
  title: string = '';
  bullets: PptxBullet[] = [];
}

class PptxBullet {
  text: string = '';
  level: number = 1;
}

// 16:9 画布 (EMU)
const SLIDE_W: number = 12192000;
const SLIDE_H: number = 6858000;
const MARGIN_X: number = 900000;
const ACCENT_H: number = 76200;
const TITLE_Y: number = 560000;
const TITLE_H: number = 1050000;
const BODY_Y: number = 1780000;
const BODY_H: number = 4550000;

// 配色
const COLOR_BRAND: string = '0A7AFF';
const COLOR_TITLE: string = '1B2330';
const COLOR_BODY: string = '333F50';
const COLOR_SUB: string = '6B7280';
const COLOR_FAINT: string = '9AA3AF';

export class PptxBuilder {
  // 大纲 -> pptx 字节; 空大纲生成单页标题
  static buildPptxBytes(title: string, outline: string): Uint8Array {
    let slides: PptxSlide[] = PptxBuilder.parseOutline(outline);
    if (slides.length === 0) {
      let hero: PptxSlide = new PptxSlide();
      hero.kind = 'section';
      hero.title = title;
      slides.push(hero);
    }
    return PptxBuilder.assemble(slides);
  }

  private static parseOutline(outline: string): PptxSlide[] {
    let slides: PptxSlide[] = [];
    let lines: string[] = outline.split('\n');
    for (let i: number = 0; i < lines.length; i++) {
      let raw: string = lines[i].replace(/\t/g, '  ');
      let trimmed: string = raw.trim();
      if (trimmed === '') {
        continue;
      }
      if (trimmed.startsWith('#')) {
        let slide: PptxSlide = new PptxSlide();
        let heading: string = trimmed.replace(/^#+\s*/, '');
        // "## " 为分节页
        if (trimmed.startsWith('##')) {
          slide.kind = 'section';
        } else {
          slide.kind = 'content';
        }
        slide.title = heading;
        slides.push(slide);
        continue;
      }
      if (slides.length === 0) {
        let first: PptxSlide = new PptxSlide();
        first.kind = 'content';
        first.title = '';
        slides.push(first);
      }
      let bullet: PptxBullet = new PptxBullet();
      let indent: number = raw.length - raw.replace(/^\s+/, '').length;
      bullet.level = indent >= 2 ? 2 : 1;
      bullet.text = trimmed.replace(/^[-*•]\s*/, '');
      if (bullet.text === '') {
        continue;
      }
      let last: PptxSlide = slides[slides.length - 1];
      last.bullets.push(bullet);
    }
    return slides;
  }

  private static assemble(slides: PptxSlide[]): Uint8Array {
    let entries: ZipEntry[] = [];
    let slideCount: number = slides.length;

    entries.push(PptxBuilder.entry('[Content_Types].xml', PptxBuilder.contentTypesXml(slideCount)));
    entries.push(PptxBuilder.entry('_rels/.rels', PptxBuilder.rootRelsXml()));
    entries.push(PptxBuilder.entry('docProps/core.xml', PptxBuilder.coreXml()));
    entries.push(PptxBuilder.entry('docProps/app.xml', PptxBuilder.appXml(slideCount)));
    entries.push(PptxBuilder.entry('ppt/presentation.xml', PptxBuilder.presentationXml(slideCount)));
    entries.push(PptxBuilder.entry('ppt/_rels/presentation.xml.rels', PptxBuilder.presentationRelsXml(slideCount)));
    entries.push(PptxBuilder.entry('ppt/theme/theme1.xml', PptxBuilder.themeXml()));
    entries.push(PptxBuilder.entry('ppt/slideMasters/slideMaster1.xml', PptxBuilder.slideMasterXml()));
    entries.push(PptxBuilder.entry('ppt/slideMasters/_rels/slideMaster1.xml.rels', PptxBuilder.slideMasterRelsXml()));
    entries.push(PptxBuilder.entry('ppt/slideLayouts/slideLayout1.xml', PptxBuilder.slideLayoutXml()));
    entries.push(PptxBuilder.entry('ppt/slideLayouts/_rels/slideLayout1.xml.rels', PptxBuilder.slideLayoutRelsXml()));
    for (let i: number = 0; i < slideCount; i++) {
      entries.push(PptxBuilder.entry('ppt/slides/slide' + (i + 1).toString() + '.xml',
        PptxBuilder.slideXml(slides[i], i + 1)));
      entries.push(PptxBuilder.entry('ppt/slides/_rels/slide' + (i + 1).toString() + '.xml.rels',
        PptxBuilder.slideRelsXml()));
    }
    return ZipWriter.create(entries);
  }

  private static entry(name: string, xml: string): ZipEntry {
    let e: ZipEntry = new ZipEntry();
    e.name = name;
    e.data = PptxBuilder.stringToBytes(xml);
    return e;
  }

  // UTF-8 编码(含代理对), 与 DocxExporter 保持一致
  private static stringToBytes(text: string): Uint8Array {
    let bytes: Uint8Array = new Uint8Array(text.length * 3);
    let count: number = 0;
    for (let i: number = 0; i < text.length; i++) {
      let code: number = text.charCodeAt(i);
      if (code < 0x80) {
        bytes[count] = code;
        count++;
      } else if (code < 0x800) {
        bytes[count] = 0xC0 | (code >> 6);
        bytes[count + 1] = 0x80 | (code & 0x3F);
        count += 2;
      } else if (code >= 0xD800 && code <= 0xDBFF && i + 1 < text.length) {
        let low: number = text.charCodeAt(i + 1);
        if (low >= 0xDC00 && low <= 0xDFFF) {
          let cp: number = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00);
          bytes[count] = 0xF0 | (cp >> 18);
          bytes[count + 1] = 0x80 | ((cp >> 12) & 0x3F);
          bytes[count + 2] = 0x80 | ((cp >> 6) & 0x3F);
          bytes[count + 3] = 0x80 | (cp & 0x3F);
          count += 4;
          i++;
        } else {
          bytes[count] = 0xEF;
          bytes[count + 1] = 0xBF;
          bytes[count + 2] = 0xBD;
          count += 3;
        }
      } else {
        bytes[count] = 0xE0 | (code >> 12);
        bytes[count + 1] = 0x80 | ((code >> 6) & 0x3F);
        bytes[count + 2] = 0x80 | (code & 0x3F);
        count += 3;
      }
    }
    let result: Uint8Array = new Uint8Array(count);
    result.set(bytes.subarray(0, count));
    return result;
  }

  // ===== 单页渲染 =====

  private static slideXml(slide: PptxSlide, pageNo: number): string {
    let spTree: string = '';
    spTree += '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>';
    spTree += '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>';

    if (slide.kind === 'section' || slide.bullets.length === 0) {
      // 分节/封面页: 品牌色整版 + 白色大字居中 + 底部细线
      spTree += PptxBuilder.rect(2, 0, 0, SLIDE_W, SLIDE_H, COLOR_BRAND);
      let heading: string = slide.title !== '' ? slide.title : '未命名演示';
      spTree += PptxBuilder.textBody(3, MARGIN_X + 200000, 2450000, SLIDE_W - (MARGIN_X + 200000) * 2,
        1958000, 4000, 'FFFFFF', true, heading, true);
      spTree += PptxBuilder.rect(4, SLIDE_W / 2 - 600000, 4500000, 1200000, 50800, 'FFFFFF');
    } else {
      // 内容页: 顶部品牌细条 + 标题 + 自适应要点 + 页码
      spTree += PptxBuilder.rect(2, 0, 0, SLIDE_W, ACCENT_H, COLOR_BRAND);
      let titleSize: number = slide.title.length <= 12 ? 3200 :
        (slide.title.length <= 20 ? 2800 : 2400);
      spTree += PptxBuilder.textBody(3, MARGIN_X, TITLE_Y, SLIDE_W - MARGIN_X * 2, TITLE_H,
        titleSize, COLOR_TITLE, true, slide.title, false);

      let l1Count: number = 0;
      for (let i: number = 0; i < slide.bullets.length; i++) {
        if (slide.bullets[i].level === 1) {
          l1Count++;
        }
      }
      let baseSize: number = l1Count <= 3 ? 2000 : (l1Count <= 6 ? 1800 : 1500);

      let bodyParas: string = '';
      for (let i: number = 0; i < slide.bullets.length; i++) {
        let b: PptxBullet = slide.bullets[i];
        let size: number = b.level === 2 ? Math.max(1200, baseSize - 300) : baseSize;
        bodyParas += PptxBuilder.bulletPara(b.text, b.level, size);
      }
      spTree += '<p:sp>' +
        '<p:nvSpPr><p:cNvPr id="4" name="Content"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>' +
        '<p:spPr><a:xfrm><a:off x="' + MARGIN_X.toString() + '" y="' + BODY_Y.toString() + '"/>' +
        '<a:ext cx="' + (SLIDE_W - MARGIN_X * 2).toString() + '" cy="' + BODY_H.toString() + '"/></a:xfrm>' +
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>' +
        '<p:txBody><a:bodyPr wrap="square"><a:normAutofit fontScale="100000"/></a:bodyPr><a:lstStyle/>' +
        bodyParas +
        '</p:txBody></p:sp>';

      // 页脚页码
      spTree += PptxBuilder.textBody(5, SLIDE_W - 1000000, SLIDE_H - 430000, 700000, 280000,
        1100, COLOR_FAINT, false, pageNo.toString(), false);
    }

    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" ' +
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' +
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">' +
      '<p:cSld><p:spTree>' + spTree + '</p:spTree></p:cSld>' +
      '<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>' +
      '</p:sld>';
  }

  // 纯色矩形
  private static rect(id: number, x: number, y: number, w: number, h: number, color: string): string {
    return '<p:sp>' +
      '<p:nvSpPr><p:cNvPr id="' + id.toString() + '" name="Shape"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>' +
      '<p:spPr><a:xfrm><a:off x="' + Math.round(x).toString() + '" y="' + Math.round(y).toString() + '"/>' +
      '<a:ext cx="' + Math.round(w).toString() + '" cy="' + Math.round(h).toString() + '"/></a:xfrm>' +
      '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>' +
      '<a:solidFill><a:srgbClr val="' + color + '"/></a:solidFill><a:ln><a:noFill/></a:ln></p:spPr>' +
      '<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="zh-CN"/></a:p></p:txBody></p:sp>';
  }

  // 文本框(bodyPr anchor/algn 由 center 控制)
  private static textBody(id: number, x: number, y: number, w: number, h: number,
    size: number, color: string, bold: boolean, text: string, center: boolean): string {
    let anchor: string = center ? ' anchor="ctr"' : '';
    let algn: string = center ? '<a:pPr algn="ctr"/>' : '';
    let fill: string = '<a:solidFill><a:srgbClr val="' + color + '"/></a:solidFill>';
    return '<p:sp>' +
      '<p:nvSpPr><p:cNvPr id="' + id.toString() + '" name="Text"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>' +
      '<p:spPr><a:xfrm><a:off x="' + Math.round(x).toString() + '" y="' + Math.round(y).toString() + '"/>' +
      '<a:ext cx="' + Math.round(w).toString() + '" cy="' + Math.round(h).toString() + '"/></a:xfrm>' +
      '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>' +
      '<p:txBody><a:bodyPr wrap="square"' + anchor + '><a:normAutofit/></a:bodyPr><a:lstStyle/>' +
      '<a:p>' + algn + '<a:r><a:rPr lang="zh-CN" altLang="en-US" sz="' + size.toString() + '"' +
      (bold ? ' b="1"' : '') + ' dirty="0">' + fill + '</a:rPr>' +
      '<a:t>' + XmlUtil.escape(text) + '</a:t></a:r></a:p>' +
      '</p:txBody></p:sp>';
  }

  // 要点段落: level 1 圆点/level 2 短横, 品牌色项目符号, 段前距
  private static bulletPara(text: string, level: number, size: number): string {
    let marL: number = level === 2 ? 800100 : 342900;
    let indent: number = level === 2 ? -285750 : -342900;
    let char: string = level === 2 ? '–' : '•';
    let color: string = level === 2 ? COLOR_SUB : COLOR_BODY;
    let buColor: string = level === 2 ? COLOR_FAINT : COLOR_BRAND;
    return '<a:p><a:pPr marL="' + marL.toString() + '" indent="' + indent.toString() + '">' +
      '<a:spcBef><a:spcPts val="900"/></a:spcBef>' +
      '<a:buClr><a:srgbClr val="' + buColor + '"/></a:buClr>' +
      '<a:buFont typeface="Arial"/><a:buChar char="' + char + '"/></a:pPr>' +
      '<a:r><a:rPr lang="zh-CN" altLang="en-US" sz="' + size.toString() + '" dirty="0">' +
      '<a:solidFill><a:srgbClr val="' + color + '"/></a:solidFill></a:rPr>' +
      '<a:t>' + XmlUtil.escape(text) + '</a:t></a:r></a:p>';
  }

  // ===== 部件 XML =====

  private static contentTypesXml(slideCount: number): string {
    let sb: string = '';
    sb += '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
    sb += '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">';
    sb += '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>';
    sb += '<Default Extension="xml" ContentType="application/xml"/>';
    sb += '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>';
    sb += '<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>';
    sb += '<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>';
    sb += '<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>';
    for (let i: number = 1; i <= slideCount; i++) {
      sb += '<Override PartName="/ppt/slides/slide' + i.toString() + '.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>';
    }
    sb += '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>';
    sb += '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>';
    sb += '</Types>';
    return sb;
  }

  private static rootRelsXml(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>' +
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>' +
      '</Relationships>';
  }

  private static coreXml(): string {
    let iso: string = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ' +
      'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" ' +
      'xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
      '<dc:creator>Guncat AI</dc:creator><cp:lastModifiedBy>Guncat AI</cp:lastModifiedBy>' +
      '<dcterms:created xsi:type="dcterms:W3CDTF">' + iso + '</dcterms:created>' +
      '<dcterms:modified xsi:type="dcterms:W3CDTF">' + iso + '</dcterms:modified>' +
      '</cp:coreProperties>';
  }

  private static appXml(slideCount: number): string {
    let titles: string = '';
    for (let i: number = 0; i < slideCount; i++) {
      titles += '<vt:lpstr>幻灯片 ' + (i + 1).toString() + '</vt:lpstr>';
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" ' +
      'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">' +
      '<Application>Guncat AI</Application>' +
      '<HeadingPairs><vt:vector size="2" baseType="variant">' +
      '<vt:variant><vt:lpstr>幻灯片</vt:lpstr></vt:variant>' +
      '<vt:variant><vt:i4>' + slideCount.toString() + '</vt:i4></vt:variant>' +
      '</vt:vector></HeadingPairs>' +
      '<TitlesOfParts><vt:vector size="' + (slideCount + 1).toString() + '" baseType="lpstr">' +
      '<vt:lpstr>Office 主题</vt:lpstr>' + titles + '</vt:vector></TitlesOfParts>' +
      '</Properties>';
  }

  private static presentationXml(slideCount: number): string {
    let sldIds: string = '';
    for (let i: number = 0; i < slideCount; i++) {
      sldIds += '<p:sldId id="' + (256 + i).toString() + '" r:id="rId' + (i + 2).toString() + '"/>';
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" ' +
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' +
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" ' +
      'saveSubsetFonts="1">' +
      '<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>' +
      '<p:sldIdLst>' + sldIds + '</p:sldIdLst>' +
      '<p:sldSz cx="' + SLIDE_W.toString() + '" cy="6858000"/>' +
      '<p:notesSz cx="6858000" cy="9144000"/>' +
      '</p:presentation>';
  }

  private static presentationRelsXml(slideCount: number): string {
    let rels: string = '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>';
    for (let i: number = 0; i < slideCount; i++) {
      rels += '<Relationship Id="rId' + (i + 2).toString() + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide' + (i + 1).toString() + '.xml"/>';
    }
    rels += '<Relationship Id="rId' + (slideCount + 2).toString() + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>';
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + rels + '</Relationships>';
  }

  private static themeXml(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Guncat Office">' +
      '<a:themeElements>' +
      '<a:clrScheme name="Guncat">' +
      '<a:dk1><a:sysClr val="windowText" lastClr="1B2330"/></a:dk1>' +
      '<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>' +
      '<a:dk2><a:srgbClr val="44546A"/></a:dk2>' +
      '<a:lt2><a:srgbClr val="F2F3F7"/></a:lt2>' +
      '<a:accent1><a:srgbClr val="0A7AFF"/></a:accent1>' +
      '<a:accent2><a:srgbClr val="3DBE64"/></a:accent2>' +
      '<a:accent3><a:srgbClr val="E9A23B"/></a:accent3>' +
      '<a:accent4><a:srgbClr val="E05252"/></a:accent4>' +
      '<a:accent5><a:srgbClr val="6B7280"/></a:accent5>' +
      '<a:accent6><a:srgbClr val="B4BAC6"/></a:accent6>' +
      '<a:hlink><a:srgbClr val="0A7AFF"/></a:hlink>' +
      '<a:folHlink><a:srgbClr val="6B7280"/></a:folHlink>' +
      '</a:clrScheme>' +
      '<a:fontScheme name="Guncat">' +
      '<a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>' +
      '<a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>' +
      '</a:fontScheme>' +
      '<a:fmtScheme name="Guncat">' +
      '<a:fillStyleLst>' +
      '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
      '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
      '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
      '</a:fillStyleLst>' +
      '<a:lnStyleLst>' +
      '<a:ln w="6350" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>' +
      '<a:ln w="12700" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>' +
      '<a:ln w="19050" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>' +
      '</a:lnStyleLst>' +
      '<a:effectStyleLst>' +
      '<a:effectStyle><a:effectLst/></a:effectStyle>' +
      '<a:effectStyle><a:effectLst/></a:effectStyle>' +
      '<a:effectStyle><a:effectLst/></a:effectStyle>' +
      '</a:effectStyleLst>' +
      '<a:bgFillStyleLst>' +
      '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
      '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
      '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
      '</a:bgFillStyleLst>' +
      '</a:fmtScheme>' +
      '</a:themeElements>' +
      '</a:theme>';
  }

  private static slideMasterXml(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" ' +
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' +
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">' +
      '<p:cSld><p:spTree>' +
      '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>' +
      '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>' +
      '</p:spTree></p:cSld>' +
      '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>' +
      '<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>' +
      '</p:sldMaster>';
  }

  private static slideMasterRelsXml(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>' +
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>' +
      '</Relationships>';
  }

  private static slideLayoutXml(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" ' +
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' +
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" ' +
      'type="obj" preserve="1">' +
      '<p:cSld name="标题和内容"><p:spTree>' +
      '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>' +
      '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>' +
      '</p:spTree></p:cSld>' +
      '<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>' +
      '</p:sldLayout>';
  }

  private static slideLayoutRelsXml(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>' +
      '</Relationships>';
  }

  private static slideRelsXml(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>' +
      '</Relationships>';
  }
}
