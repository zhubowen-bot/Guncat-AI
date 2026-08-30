export class Constants {
  // App info
  static readonly APP_NAME: string = 'Guncat Work';
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
  // 上下文压缩时保留原样的最近消息条数(最近轮次对后续执行最关键, 不参与汇总)
  static readonly WORK_COMPACT_KEEP_MESSAGES: number = 12;
  // 上下文压缩摘要的最大字符数
  static readonly WORK_SUMMARY_MAX_CHARS: number = 2400;
  // 深度思考条展开时工具结果的最大展示字符数
  static readonly WORK_STEP_DISPLAY_CHARS: number = 500;
  // LLM 请求自动重试次数(429/5xx/网络传输/空响应), 指数退避 500ms→8s+抖动
  static readonly WORK_LLM_RETRY_MAX: number = 3;
  // 模型上下文窗口 token 数(DeepSeek V4 系列 1M 级上下文; 超阈值自动压缩历史。
  // 预算优先用 API 返回的真实 prompt tokens 锚定, 无数据时按本会话实测字符→token 比例估算)
  static readonly WORK_CONTEXT_WINDOW_TOKENS: number = 1000000;
  // 触发上下文压缩的 token 占比(usage 锚定: 上一请求真实 prompt tokens 达阈值即压缩)
  static readonly WORK_COMPACT_TOKEN_RATIO: number = 0.85;
  // 压缩第一阶段(无模型参与)对早期工具结果的修剪阈值与头尾保留量
  static readonly WORK_PRUNE_RESULT_MAX_CHARS: number = 2500;
  static readonly WORK_PRUNE_KEEP_HEAD: number = 1200;
  static readonly WORK_PRUNE_KEEP_TAIL: number = 400;
  // 工具结果头尾保留式截断的尾部保留量(头部占 WORK_RESULT_MAX_CHARS 的其余额度)
  static readonly WORK_RESULT_KEEP_TAIL: number = 400;
  // PPT(Deck) 单张图片字节上限(工作区文件/data URL/http 下载共用)
  static readonly WORK_PPT_IMAGE_MAX_BYTES: number = 10 * 1024 * 1024;
  // PPT(Deck) 整册图片张数上限(去重后)
  static readonly WORK_PPT_MAX_IMAGES: number = 40;
  // 技能文档单文件送回模型的字符上限
  static readonly WORK_SKILL_MAX_CHARS: number = 20000;
  // download_file 单文件下载字节上限
  static readonly WORK_DOWNLOAD_MAX_BYTES: number = 20 * 1024 * 1024;
  // write_svg 的 SVG 源码字符上限
  static readonly WORK_SVG_MAX_CHARS: number = 512 * 1024;
  // transform_file 输入文本字节上限(与 Office 抽取缓存同量级, 保证 UI 线程上求值可在数百毫秒内完成)
  static readonly WORK_TRANSFORM_INPUT_MAX_BYTES: number = 2 * 1024 * 1024;
  // transform_file 输入行数上限
  static readonly WORK_TRANSFORM_MAX_ROWS: number = 100000;
  // transform_file 管道步数上限
  static readonly WORK_TRANSFORM_MAX_STEPS: number = 30;
  // transform_file 预览行数
  static readonly WORK_TRANSFORM_PREVIEW_ROWS: number = 3;
  // transform_file 写盘字节上限(csv 之外的输出格式可能膨胀)
  static readonly WORK_TRANSFORM_OUTPUT_MAX_BYTES: number = 8 * 1024 * 1024;
  // transform_file xlsx 输出的行数上限(内存型构建, 超大表请用 csv)
  static readonly WORK_TRANSFORM_XLSX_MAX_ROWS: number = 50000;
}
