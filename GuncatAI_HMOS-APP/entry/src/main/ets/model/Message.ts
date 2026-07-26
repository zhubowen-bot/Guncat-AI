import { Attachment } from './Attachment';

// 消息(对齐 web 版本的 message 字段)
// 必须 @Observed 才能让 @ObjectLink 追踪属性变化 (流式输出时 content 增量更新)
@Observed
export class Message {
  id: string = '';
  role: string = 'user';
  content: string = '';
  displayContent: string = '';
  attachments: Attachment[] = [];
  timestamp: number = 0;

  static ofUser(id: string, content: string, displayContent: string,
    attachments: Attachment[]): Message {
    let msg: Message = new Message();
    msg.id = id;
    msg.role = 'user';
    msg.content = content;
    msg.displayContent = displayContent;
    msg.attachments = attachments;
    msg.timestamp = new Date().getTime();
    return msg;
  }

  static ofAssistant(id: string, content: string): Message {
    let msg: Message = new Message();
    msg.id = id;
    msg.role = 'assistant';
    msg.content = content;
    msg.displayContent = content;
    msg.attachments = [];
    msg.timestamp = new Date().getTime();
    return msg;
  }

  static fromJson(json: Record<string, Object>): Message {
    let msg: Message = new Message();
    msg.id = (json['id'] as string) ?? '';
    msg.role = (json['role'] as string) ?? 'user';
    msg.content = (json['content'] as string) ?? '';
    msg.displayContent = (json['displayContent'] as string) ?? '';
    msg.timestamp = (json['timestamp'] as number) ?? 0;
    let raw: Object = json['attachments'];
    if (raw !== undefined) {
      let rawAttachments: Object[] = raw as Object[];
      let result: Attachment[] = [];
      for (let i: number = 0; i < rawAttachments.length; i++) {
        result.push(Attachment.fromJson(rawAttachments[i] as Record<string, Object>));
      }
      msg.attachments = result;
    }
    return msg;
  }

  toJson(): Record<string, Object> {
    let attArr: Object[] = [];
    for (let i: number = 0; i < this.attachments.length; i++) {
      attArr.push(this.attachments[i].toJson());
    }
    return {
      'id': this.id,
      'role': this.role,
      'content': this.content,
      'displayContent': this.displayContent,
      'attachments': attArr,
      'timestamp': this.timestamp
    };
  }
}
