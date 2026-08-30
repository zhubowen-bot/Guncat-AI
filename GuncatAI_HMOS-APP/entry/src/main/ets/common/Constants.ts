export class Constants {
  // App info
  static readonly APP_NAME: string = 'Guncat AI';
  static readonly APP_VERSION: string = '6.0.0';

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
  // 流式期间持久化存档节流(全量序列化所有会话开销大, 高频调用会撑爆共享堆引发 OOM;
  // 常规持久化依赖工具步骤边界与流式结束/出错回调)
  static readonly STREAM_THROTTLE_MS: number = 5000;

  // 文件解析
  static readonly MAX_FILE_SIZE_MB: number = 20;
  static readonly MAX_FILE_PARSE_RETRY: number = 4;
  static readonly MAX_FILE_PARSE_RETRY_WAIT_MS: number = 800;
  static readonly FILE_PARSE_INTERLEAVE_MS: number = 200;

  // 会话持久化安全阈值(UTF-16 码元): Preferences 单值上限 16MB 字节,
  // 附件图片 base64 字节量超过该值即剥离, 防止序列化大字符串引发 OOM
  static readonly LS_CONVERSATIONS_SAFE_BYTES: number = 4 * 1024 * 1024;
  // 持久化时单条消息思考文本保留的末尾字符数(reasoning 是过程性内容, 无需全量落盘)
  static readonly REASONING_SAVE_MAX_CHARS: number = 20000;

  // ===== 工作模式 (Agent Loop + 沙箱工作区) =====
  // 工作模式虚拟智能体 id(与 agents.json 智能体平行, 注入在列表顶部)
  static readonly WORK_AGENT_ID: string = 'work';
  // 工作区根目录名(位于应用沙箱 filesDir 下, 按会话 id 分目录, 无需任何文件权限)
  static readonly WORKSPACE_ROOT_DIR: string = 'workspaces';
  // 任务清单文件(工作区根目录, 由 todo_write 工具维护)
  static readonly WORK_TODO_FILE: string = '.todo.json';
  // view_image 工具可读取的图片字节上限
  static readonly WORK_VIEW_IMAGE_MAX_BYTES: number = 8 * 1024 * 1024;
  // 单次任务最多工具调用轮数(防失控保险: 防止工具调用死循环持续消耗, 正常长任务触不到)
  static readonly WORK_MAX_STEPS: number = 200;
  // read_file 单次读取上限(字节), 超出截断并提示
  static readonly WORK_READ_MAX_BYTES: number = 64 * 1024;
  // write/append_file 单次写入上限(字节)
  static readonly WORK_WRITE_MAX_BYTES: number = 512 * 1024;
  // 工具结果送回模型的字符上限
  static readonly WORK_RESULT_MAX_CHARS: number = 12000;
  // PDF 分页提取的默认页数(parse_document 的 page_count 默认值)
  static readonly WORK_PDF_PAGES_PER_CALL: number = 30;
  // PDF 转图的默认页数(pdf_to_images 的 page_count 默认值)
  static readonly WORK_PDF_RENDER_PAGES_PER_CALL: number = 10;
  // read_file 纯文本全量读取上限(字节), 行分页在该范围内进行
  static readonly WORK_READ_FULL_MAX_BYTES: number = 1024 * 1024;
  // read_file 单次返回的最大行数(字符预算另计, 防超长单行刷屏)
  static readonly WORK_READ_MAX_LINES: number = 600;
  // search_files 覆盖的 Office 文档(zip 容器)单文件大小上限
  static readonly WORK_SEARCH_OFFICE_MAX_BYTES: number = 20 * 1024 * 1024;
  // Office 抽取缓存单条文本的字符上限
  static readonly WORK_OFFICE_CACHE_MAX_CHARS: number = 2 * 1024 * 1024;
  // search_files 最大匹配条数
  static readonly WORK_SEARCH_MAX_MATCHES: number = 50;
  // search_files 单文件读取上限(字节)
  static readonly WORK_SEARCH_FILE_MAX_BYTES: number = 256 * 1024;
  // list_files 最大条目数与递归深度
  static readonly WORK_LIST_MAX_ENTRIES: number = 400;
  static readonly WORK_LIST_MAX_DEPTH: number = 6;
  // 触发上下文压缩的历史字符阈值(适配 1M 级上下文): 超出时先把早期历史压缩为状态摘要,
  // 压缩失败或压缩后仍超预算才回退为从最旧处整条裁剪。
  static readonly WORK_HISTORY_MAX_CHARS: number = 600000;
  // 上下文压缩时保留原样的最近消息条数(最近轮次对后续执行最关键, 不参与汇总)
  static readonly WORK_COMPACT_KEEP_MESSAGES: number = 12;
  // 上下文压缩摘要的最大字符数
  static readonly WORK_SUMMARY_MAX_CHARS: number = 2400;
  // 深度思考条展开时工具结果的最大展示字符数
  static readonly WORK_STEP_DISPLAY_CHARS: number = 500;
}
