// 上传中 / 已解析的附件 (对齐 web 版本的 pendingFiles)
export class Attachment {
  name: string = '';
  parsedText: string = '';
  type: string = 'file';
  thumbnail: string = '';
  dataUrl: string = '';

  static of(name: string, parsedText: string, type: string,
    thumbnail: string, dataUrl: string): Attachment {
    let att: Attachment = new Attachment();
    att.name = name;
    att.parsedText = parsedText;
    att.type = type;
    att.thumbnail = thumbnail;
    att.dataUrl = dataUrl;
    return att;
  }

  static fromJson(json: Record<string, Object>): Attachment {
    let att: Attachment = new Attachment();
    att.name = (json['name'] as string) ?? '';
    att.parsedText = (json['parsedText'] as string) ?? '';
    att.type = (json['type'] as string) ?? 'file';
    att.thumbnail = (json['thumbnail'] as string) ?? '';
    att.dataUrl = (json['dataUrl'] as string) ?? '';
    return att;
  }

  toJson(): Record<string, Object> {
    return {
      'name': this.name,
      'parsedText': this.parsedText,
      'type': this.type,
      'thumbnail': this.thumbnail,
      'dataUrl': this.dataUrl
    };
  }
}
