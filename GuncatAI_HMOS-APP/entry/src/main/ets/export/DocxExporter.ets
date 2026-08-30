import { common } from '@kit.AbilityKit';
import { picker, fileIo as fs } from '@kit.CoreFileKit';
import { OoxmlBuilder, OoxmlDocument, MediaPart } from './OoxmlBuilder';
import { ZipWriter, ZipEntry } from './ZipWriter';
import { XmlUtil } from './XmlUtil';

// 导出服务: Markdown 内容 -> .docx 文件
// 流程: 解析 -> 生成 OOXML 部件 -> 组装 zip -> 系统保存面板选择位置写入
export class DocxExporter {
  // 导出对话消息为 Word 文档, 返回保存的文件名; 用户取消时抛出错误
  static async exportToDocx(context: common.UIAbilityContext, markdown: string,
    defaultName: string): Promise<string> {
    let title: string = defaultName !== '' ? defaultName : 'Guncat AI 对话导出';
    let doc: OoxmlDocument = await OoxmlBuilder.build(title, markdown);
    let bytes: Uint8Array = DocxExporter.assembleZip(doc);
    return DocxExporter.saveViaPicker(context, bytes);
  }

  // 仅构建 .docx 字节(工作模式 write_docx 工具复用), 不弹保存面板
  static async buildDocxBytes(title: string, markdown: string): Promise<Uint8Array> {
    let doc: OoxmlDocument = await OoxmlBuilder.build(title, markdown);
    return DocxExporter.assembleZip(doc);
  }

  // 组装 zip 条目 -> docx 字节
  private static assembleZip(doc: OoxmlDocument): Uint8Array {
    let entries: ZipEntry[] = [];
    entries.push(DocxExporter.entry('[Content_Types].xml', doc.contentTypesXml));
    entries.push(DocxExporter.entry('_rels/.rels', doc.rootRelsXml));
    entries.push(DocxExporter.entry('word/document.xml', doc.documentXml));
    entries.push(DocxExporter.entry('word/styles.xml', doc.stylesXml));
    entries.push(DocxExporter.entry('word/numbering.xml', doc.numberingXml));
    entries.push(DocxExporter.entry('word/_rels/document.xml.rels', doc.documentRelsXml));
    for (let i: number = 0; i < doc.mediaParts.length; i++) {
      let part: MediaPart = doc.mediaParts[i];
      let e: ZipEntry = new ZipEntry();
      e.name = 'word/media/' + part.name;
      e.data = part.data;
      entries.push(e);
    }
    entries.push(DocxExporter.entry('docProps/core.xml', doc.coreXml));
    entries.push(DocxExporter.entry('docProps/app.xml', doc.appXml));
    return ZipWriter.create(entries);
  }

  private static entry(name: string, xml: string): ZipEntry {
    let e: ZipEntry = new ZipEntry();
    e.name = name;
    e.data = DocxExporter.stringToBytes(xml);
    return e;
  }

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
        // 代理对(emoji 等)
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

  // 系统文档保存面板, 写入文件
  private static async saveViaPicker(context: common.UIAbilityContext, bytes: Uint8Array): Promise<string> {
    let fileName: string = XmlUtil.makeFileName('Guncat-导出');
    // newFileNames 不携带扩展名, 后缀由 fileSuffixChoices 拼接(需带点号)
    let baseName: string = fileName.endsWith('.docx') ?
      fileName.substring(0, fileName.length - 5) : fileName;
    let options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    options.newFileNames = [baseName];
    options.fileSuffixChoices = ['.docx'];
    let viewPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    let uris: string[] = await viewPicker.save(options);
    if (uris.length === 0) {
      throw new Error('已取消导出');
    }
    let uri: string = uris[0];
    let file: fs.File = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      // 写入 zip 字节
      let buffer: ArrayBuffer = bytes.buffer as ArrayBuffer;
      if (bytes.byteOffset !== 0 || bytes.byteLength !== buffer.byteLength) {
        buffer = bytes.slice().buffer as ArrayBuffer;
      }
      fs.writeSync(file.fd, buffer);
    } finally {
      fs.closeSync(file);
    }
    return fileName;
  }
}
