export class Constants {
  // App info
  static readonly APP_NAME: string = 'Guncat AI';
  static readonly APP_VERSION: string = '5.1.0';

  // LocalStorage keys (统一存放在 Preferences 中, key 名字符串)
  static readonly LS_KEY_CONVERSATIONS: string = 'guncat_conversations';
  static readonly LS_KEY_API_CONFIG: string = 'guncat_api_config';
  static readonly LS_KEY_MULTIMODAL_CONFIG: string = 'guncat_mm_config';
  static readonly LS_KEY_API_PROFILES: string = 'guncat_api_profiles';
  static readonly LS_KEY_CURRENT_API_PROFILE_ID: string = 'guncat_current_api_profile';
  static readonly LS_KEY_THINKING_ENABLED: string = 'guncat_thinking_enabled';
  static readonly LS_KEY_WEB_SEARCH_ENABLED: string = 'guncat_web_search_enabled';
  static readonly LS_KEY_AUTO_READ_ENABLED: string = 'guncat_auto_read_enabled';
  static readonly LS_KEY_CURRENT_AGENT_ID: string = 'guncat_current_agent';
  static readonly LS_KEY_CURRENT_CONV_ID: string = 'guncat_current_conv';
  // 表格识别页当前选择的配置 ('multimodal' / 'main'), 决定引用多模态解析还是主模型配置
  static readonly LS_KEY_TABLE_OCR_PROVIDER: string = 'table_ocr_provider';

  // API presets
  static readonly PRESET_OPENAI_COMPLETIONS_BASE_URL: string = 'https://api.openai.com/v1';
  static readonly PRESET_OPENAI_RESPONSES_BASE_URL: string = 'https://api.openai.com/v1';
  static readonly PRESET_ANTHROPIC_BASE_URL: string = 'https://api.anthropic.com/v1';

  // Default multimodal model
  static readonly DEFAULT_MM_BASE_URL: string = 'https://open.bigmodel.cn/api/paas/v4';
  static readonly DEFAULT_MM_MODEL: string = 'glm-4.6v-flash';

  // API endpoints
  static readonly CHAT_COMPLETIONS_PATH: string = '/chat/completions';
  static readonly RESPONSES_PATH: string = '/responses';
  static readonly MESSAGES_PATH: string = '/messages';
  static readonly ANTHROPIC_V1_MESSAGES_PATH: string = '/v1/messages';
  static readonly ANTHROPIC_DEEPSEEK_MESSAGES_PATH: string = '/anthropic/v1/messages';

  // SSE
  static readonly SSE_DONE_TOKEN: string = '[DONE]';
  static readonly SSE_DATA_PREFIX: string = 'data: ';

  // UI 限制
  static readonly MAX_INPUT_HEIGHT: number = 120;
  static readonly TOAST_DURATION_MS: number = 2200;
  static readonly STREAM_THROTTLE_MS: number = 50;

  // 文件解析
  static readonly MAX_FILE_SIZE_MB: number = 20;
  static readonly MAX_FILE_PARSE_RETRY: number = 4;
  static readonly MAX_FILE_PARSE_RETRY_WAIT_MS: number = 800;
  static readonly FILE_PARSE_INTERLEAVE_MS: number = 200;

  // 会话持久化安全阈值(UTF-16 码元): Preferences 单值上限 16MB 字节,
  // 附件图片 base64 字节量超过该值即剥离, 防止序列化大字符串引发 OOM
  static readonly LS_CONVERSATIONS_SAFE_BYTES: number = 4 * 1024 * 1024;
}
