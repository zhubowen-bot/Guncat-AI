// API 配置 (对齐 web 版本的 guncat_api_config 结构)
export class ApiConfig {
  provider: string = 'custom';
  baseUrl: string = '';
  apiKey: string = '';
  model: string = '';
  temperature: number | null = null;
  topP: number | null = null;
  maxTokens: number | null = null;
  extraBody: string = '';

  static default(): ApiConfig {
    return new ApiConfig();
  }

  static deepseekPreset(): ApiConfig {
    let cfg: ApiConfig = new ApiConfig();
    cfg.provider = 'deepseek';
    cfg.baseUrl = 'https://api.deepseek.com';
    cfg.model = 'deepseek-chat';
    return cfg;
  }

  static volcanoPreset(): ApiConfig {
    let cfg: ApiConfig = new ApiConfig();
    cfg.provider = 'volcano';
    cfg.baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
    cfg.model = '';
    return cfg;
  }

  static fromJson(json: Record<string, Object>): ApiConfig {
    let cfg: ApiConfig = new ApiConfig();
    cfg.provider = (json['provider'] as string) ?? 'custom';
    cfg.baseUrl = (json['baseUrl'] as string) ?? '';
    cfg.apiKey = (json['apiKey'] as string) ?? '';
    cfg.model = (json['model'] as string) ?? '';
    cfg.extraBody = (json['extraBody'] as string) ?? '';
    let t: Object = json['temperature'];
    if (t !== undefined && t !== null) {
      cfg.temperature = t as number;
    }
    let p: Object = json['topP'];
    if (p !== undefined && p !== null) {
      cfg.topP = p as number;
    }
    let m: Object = json['maxTokens'];
    if (m !== undefined && m !== null) {
      cfg.maxTokens = m as number;
    }
    return cfg;
  }

  toJson(): Record<string, Object> {
    let result: Record<string, Object> = {
      'provider': this.provider,
      'baseUrl': this.baseUrl,
      'apiKey': this.apiKey,
      'model': this.model,
      'extraBody': this.extraBody
    };
    if (this.temperature !== null) {
      result['temperature'] = this.temperature;
    }
    if (this.topP !== null) {
      result['topP'] = this.topP;
    }
    if (this.maxTokens !== null) {
      result['maxTokens'] = this.maxTokens;
    }
    return result;
  }
}
