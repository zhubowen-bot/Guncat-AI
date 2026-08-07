// 统一使用 Preferences 存储(对齐 web 版本 localStorage 的 KV 行为)
import { preferences } from '@kit.ArkData';
import { Conversation } from '../model/Conversation';
import { Message } from '../model/Message';
import { Attachment } from '../model/Attachment';
import { ApiConfig } from '../model/ApiConfig';
import { MultimodalConfig } from '../model/MultimodalConfig';
import { ApiProfile } from '../model/ApiProfile';
import { Constants } from '../common/Constants';

let preferencesInstance: preferences.Preferences | undefined = undefined;

async function getPreferences(context: Context): Promise<preferences.Preferences> {
  if (preferencesInstance === undefined) {
    preferencesInstance = await preferences.getPreferences(context, 'guncat_preferences');
  }
  return preferencesInstance;
}

export class StorageManager {
  static async saveConversations(context: Context, convs: Conversation[]): Promise<void> {
    try {
      // 必须先检查附件图片字节量再序列化: 一旦 stringify 出 16MB+ 的大字符串,
      // Preferences 写入抛 401 且大字符串反复分配会直接撑爆共享堆(OOM 不可捕获)
      let arr: Object[] = [];
      for (let i: number = 0; i < convs.length; i++) {
        arr.push(convs[i].toJson());
      }
      let jsonStr: string;
      if (StorageManager.hasHeavyAttachments(convs)) {
        // 图片字节超阈值: 剥离附件 dataUrl/thumbnail 后持久化(保留文件名与解析文本)
        let safeArr: Object[] = StorageManager.sanitizeConversations(arr);
        jsonStr = JSON.stringify(safeArr);
      } else {
        jsonStr = JSON.stringify(arr);
      }
      let prefs: preferences.Preferences = await getPreferences(context);
      await prefs.put(Constants.LS_KEY_CONVERSATIONS, jsonStr);
      await prefs.flush();
    } catch (error) {
      // 保存失败(如仍超限)不抛出, 避免反复重试放大内存压力
      console.error('saveConversations failed: ' + JSON.stringify(error));
    }
  }

  // 附件图片(dataUrl/thumbnail)字节总量是否超过安全阈值
  private static hasHeavyAttachments(convs: Conversation[]): boolean {
    let total: number = 0;
    for (let i: number = 0; i < convs.length; i++) {
      let msgs: Message[] = convs[i].messages;
      for (let j: number = 0; j < msgs.length; j++) {
        let atts: Attachment[] = msgs[j].attachments;
        for (let k: number = 0; k < atts.length; k++) {
          total += atts[k].dataUrl.length + atts[k].thumbnail.length;
          if (total > Constants.LS_CONVERSATIONS_SAFE_BYTES) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // 重建会话 JSON, 剥离附件 dataUrl/thumbnail(仅保留文件名与解析文本)
  private static sanitizeConversations(arr: Object[]): Object[] {
    let out: Object[] = [];
    for (let i: number = 0; i < arr.length; i++) {
      let c: Record<string, Object> = arr[i] as Record<string, Object>;
      let msgs: Object[] = [];
      let rawMsgs: Object = c['messages'];
      if (rawMsgs !== undefined) {
        let rawArr: Object[] = rawMsgs as Object[];
        for (let j: number = 0; j < rawArr.length; j++) {
          msgs.push(StorageManager.sanitizeMessage(rawArr[j] as Record<string, Object>));
        }
      }
      out.push({
        'id': (c['id'] as string) ?? '',
        'agentId': (c['agentId'] as string) ?? '',
        'title': (c['title'] as string) ?? '',
        'messages': msgs,
        'createdAt': (c['createdAt'] as number) ?? 0
      });
    }
    return out;
  }

  private static sanitizeMessage(m: Record<string, Object>): Record<string, Object> {
    let atts: Object[] = [];
    let rawAtts: Object = m['attachments'];
    if (rawAtts !== undefined) {
      let rawArr: Object[] = rawAtts as Object[];
      for (let i: number = 0; i < rawArr.length; i++) {
        let a: Record<string, Object> = rawArr[i] as Record<string, Object>;
        atts.push({
          'name': (a['name'] as string) ?? '',
          'parsedText': (a['parsedText'] as string) ?? '',
          'type': (a['type'] as string) ?? '',
          'thumbnail': '',
          'dataUrl': ''
        });
      }
    }
    return {
      'id': (m['id'] as string) ?? '',
      'role': (m['role'] as string) ?? '',
      'content': (m['content'] as string) ?? '',
      'displayContent': (m['displayContent'] as string) ?? '',
      'attachments': atts,
      'timestamp': (m['timestamp'] as number) ?? 0
    };
  }

  static async loadConversations(context: Context): Promise<Conversation[]> {
    let prefs: preferences.Preferences = await getPreferences(context);
    let jsonStr: string = (await prefs.get(Constants.LS_KEY_CONVERSATIONS, '')) as string;
    if (jsonStr === '') {
      return [];
    }
    let parsed: Object = JSON.parse(jsonStr);
    if (!(parsed instanceof Array)) {
      return [];
    }
    let rawArr: Object[] = parsed as Object[];
    let result: Conversation[] = [];
    for (let i: number = 0; i < rawArr.length; i++) {
      result.push(Conversation.fromJson(rawArr[i] as Record<string, Object>));
    }
    return result;
  }

  static async saveApiConfig(context: Context, config: ApiConfig): Promise<void> {
    let prefs: preferences.Preferences = await getPreferences(context);
    await prefs.put(Constants.LS_KEY_API_CONFIG, JSON.stringify(config.toJson()));
    await prefs.flush();
  }

  static async loadApiConfig(context: Context): Promise<ApiConfig | null> {
    let prefs: preferences.Preferences = await getPreferences(context);
    let jsonStr: string = (await prefs.get(Constants.LS_KEY_API_CONFIG, '')) as string;
    if (jsonStr === '') {
      return null;
    }
    let parsed: Object = JSON.parse(jsonStr);
    if (typeof parsed !== 'object' || parsed === null) {
      return null;
    }
    return ApiConfig.fromJson(parsed as Record<string, Object>);
  }

  static async saveMultimodalConfig(context: Context, config: MultimodalConfig): Promise<void> {
    let prefs: preferences.Preferences = await getPreferences(context);
    await prefs.put(Constants.LS_KEY_MULTIMODAL_CONFIG, JSON.stringify(config.toJson()));
    await prefs.flush();
  }

  static async loadMultimodalConfig(context: Context): Promise<MultimodalConfig> {
    let prefs: preferences.Preferences = await getPreferences(context);
    let jsonStr: string = (await prefs.get(Constants.LS_KEY_MULTIMODAL_CONFIG, '')) as string;
    if (jsonStr === '') {
      return MultimodalConfig.default();
    }
    let parsed: Object = JSON.parse(jsonStr);
    if (typeof parsed !== 'object' || parsed === null) {
      return MultimodalConfig.default();
    }
    return MultimodalConfig.fromJson(parsed as Record<string, Object>);
  }

  static async saveApiProfiles(context: Context, profiles: ApiProfile[]): Promise<void> {
    let data: Object[] = [];
    for (let i: number = 0; i < profiles.length; i++) {
      data.push(profiles[i].toJson());
    }
    let prefs: preferences.Preferences = await getPreferences(context);
    await prefs.put(Constants.LS_KEY_API_PROFILES, JSON.stringify(data));
    await prefs.flush();
  }

  static async loadApiProfiles(context: Context): Promise<ApiProfile[]> {
    let prefs: preferences.Preferences = await getPreferences(context);
    let jsonStr: string = (await prefs.get(Constants.LS_KEY_API_PROFILES, '')) as string;
    if (jsonStr === '') {
      return [];
    }
    let parsed: Object = JSON.parse(jsonStr);
    if (!(parsed instanceof Array)) {
      return [];
    }
    let values: Object[] = parsed as Object[];
    let result: ApiProfile[] = [];
    for (let i: number = 0; i < values.length; i++) {
      result.push(ApiProfile.fromJson(values[i] as Record<string, Object>));
    }
    return result;
  }

  static async saveBoolean(context: Context, key: string, val: boolean): Promise<void> {
    let prefs: preferences.Preferences = await getPreferences(context);
    await prefs.put(key, val);
    await prefs.flush();
  }

  static async loadBoolean(context: Context, key: string, defaultVal: boolean): Promise<boolean> {
    let prefs: preferences.Preferences = await getPreferences(context);
    let v: Object = await prefs.get(key, defaultVal);
    if (typeof v === 'boolean') {
      return v;
    }
    return defaultVal;
  }

  static async saveString(context: Context, key: string, val: string): Promise<void> {
    let prefs: preferences.Preferences = await getPreferences(context);
    await prefs.put(key, val);
    await prefs.flush();
  }

  static async loadString(context: Context, key: string, defaultVal: string): Promise<string> {
    let prefs: preferences.Preferences = await getPreferences(context);
    let v: Object = await prefs.get(key, defaultVal);
    if (typeof v === 'string') {
      return v;
    }
    return defaultVal;
  }
}
