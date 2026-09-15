// 工作模式(Agent Loop)单次工具调用记录
// 同一实例同时承载三条信息: 模型的调用参数(argsJson)、执行结果(result)、执行状态(durationMs<0 表示执行中)
// 会话持久化时随 Message.toJson 一起落盘, 重启后据此还原步骤时间线与 LLM 历史
export class ToolCallRecord {
  id: string = '';
  name: string = '';
  argsJson: string = '';
  result: string = '';
  isError: boolean = false;
  // 执行耗时(毫秒); -1 表示尚未执行完成
  durationMs: number = -1;
  // 结构化展示数据(JSON 字符串), 如 edit 工具的 diff 卡片; 随会话持久化供 UI 重放
  meta: string = '';
  // 运行态标记(不持久化): true 表示模型还在流式生成调用参数, 尚未开始执行;
  // 区分时间线上的"生成调用中"与"执行中/等待中"状态
  preparing: boolean = false;

  static of(id: string, name: string, argsJson: string): ToolCallRecord {
    let rec: ToolCallRecord = new ToolCallRecord();
    rec.id = id;
    rec.name = name;
    rec.argsJson = argsJson;
    rec.result = '';
    rec.isError = false;
    rec.durationMs = -1;
    return rec;
  }

  static fromJson(json: Record<string, Object>): ToolCallRecord {
    let rec: ToolCallRecord = new ToolCallRecord();
    rec.id = (json['id'] as string) ?? '';
    rec.name = (json['name'] as string) ?? '';
    rec.argsJson = (json['argsJson'] as string) ?? '';
    rec.result = (json['result'] as string) ?? '';
    rec.isError = (json['isError'] as boolean) ?? false;
    rec.durationMs = (json['durationMs'] as number) ?? -1;
    rec.meta = (json['meta'] as string) ?? '';
    return rec;
  }

  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'argsJson': this.argsJson,
      'result': this.result,
      'isError': this.isError,
      'durationMs': this.durationMs,
      'meta': this.meta
    };
  }
}
