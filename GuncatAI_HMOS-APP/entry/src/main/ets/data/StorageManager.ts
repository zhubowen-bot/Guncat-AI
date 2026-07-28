// 统一使用 Preferences 存储(对齐 web 版本 localStorage 的 KV 行为)
import { preferences } from '@kit.ArkData';
import { Conversation } from '../model/Conversation';
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
    let arr: Object[] = [];
    for (let i: number = 0; i < convs.length; i++) {
      arr.push(convs[i].toJson());
    }
    let jsonStr: string = JSON.stringify(arr);
    let prefs: preferences.Preferences = await getPreferences(context);
    await prefs.put(Constants.LS_KEY_CONVERSATIONS, jsonStr);
    await prefs.flush();
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
