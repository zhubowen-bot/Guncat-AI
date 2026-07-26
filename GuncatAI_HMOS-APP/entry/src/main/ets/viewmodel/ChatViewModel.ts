// ChatViewModel: 整体状态 + 行为 (对齐 web 版本的 store)
//  - @Observed + 内部 version 计数器, 通过 ChatPage 的 @State vm 触发刷新
import { Agent } from '../model/Agent';
import { Conversation } from '../model/Conversation';
import { Message } from '../model/Message';
import { Attachment } from '../model/Attachment';
import { ApiConfig } from '../model/ApiConfig';
import { MultimodalConfig } from '../model/MultimodalConfig';
import { FileItem, StreamCallbacks, AbortSignal } from '../common/Types';
import { AgentLoader } from '../service/AgentLoader';
import { ChatService } from '../service/ChatService';
import { FileService, PickedFile } from '../service/FileService';
import { MultimodalService } from '../service/MultimodalService';
import { StorageManager } from '../data/StorageManager';
import { Constants } from '../common/Constants';
import { generateMessageId } from '../common/Utils';
import { arrayBufferToBase64 } from '../common/Utils';
import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Observed
export class ChatViewModel {
  agents: Agent[] = [];
  conversations: Conversation[] = [];
  currentAgent: Agent | null = null;
  currentConversationId: string = '';
  isStreaming: boolean = false;
  thinkingEnabled: boolean = false;
  webSearchEnabled: boolean = false;
  pendingFiles: FileItem[] = [];
  drawerOpen: boolean = false;
  apiConfig: ApiConfig = ApiConfig.default();
  multimodalConfig: MultimodalConfig = MultimodalConfig.default();

  // 文件解析内部状态
  private fileBuffers: Map<string, ArrayBuffer> = new Map();
  // 流式更新节流
  private streamTimer: number = -1;
  private pendingUIChange: boolean = false;
  private streamTarget: Message | null = null;
  // 取消信号
  private abortSignal: AbortSignal = new AbortSignal();
  // context
  private context: common.UIAbilityContext | null = null;
  // 初始化完成
  ready: boolean = false;
  // 全局文件解析中标志(显式管理, 不依赖每个 FileItem.isParsing)
  private _isParsing: boolean = false;
  get isParsing(): boolean {
    return this._isParsing;
  }
  // UI 状态变化回调(用于在 VM 内部状态变化时通知 ChatPage 触发 refreshTick)
  onStateChange: () => void = (): void => {};

  setStateChangeListener(cb: () => void): void {
    this.onStateChange = cb;
  }

  private notifyUIChange(): void {
    try {
      this.onStateChange();
    } catch (e) {
      // ignore
    }
  }

  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  get currentConversation(): Conversation | null {
    if (this.currentConversationId === '') {
      return null;
    }
    for (let i: number = 0; i < this.conversations.length; i++) {
      if (this.conversations[i].id === this.currentConversationId) {
        return this.conversations[i];
      }
    }
    return null;
  }

  get currentMessages(): Message[] {
    let conv: Conversation | null = this.currentConversation;
    if (conv === null) {
      return [];
    }
    return conv.messages;
  }

  async init(): Promise<void> {
    if (this.context === null) {
      return;
    }
    await this.restoreState();
  }

  async restoreState(): Promise<void> {
    if (this.context === null) {
      return;
    }
    // 加载设置
    let cfg: ApiConfig | null = await StorageManager.loadApiConfig(this.context);
    if (cfg !== null) {
      this.apiConfig = cfg;
    }
    this.multimodalConfig = await StorageManager.loadMultimodalConfig(this.context);
    this.thinkingEnabled = await StorageManager.loadBoolean(this.context, Constants.LS_KEY_THINKING_ENABLED, false);
    this.webSearchEnabled = await StorageManager.loadBoolean(this.context, Constants.LS_KEY_WEB_SEARCH_ENABLED, false);

    // 加载智能体
    this.agents = await AgentLoader.loadAllAgents(this.context);

    // 加载对话
    this.conversations = await StorageManager.loadConversations(this.context);

    // 恢复当前智能体
    let agentId: string = await StorageManager.loadString(this.context, Constants.LS_KEY_CURRENT_AGENT_ID, '');
    let firstAgent: Agent | null = this.agents.length > 0 ? this.agents[0] : null;
    if (agentId !== '') {
      for (let i: number = 0; i < this.agents.length; i++) {
        if (this.agents[i].id === agentId) {
          this.currentAgent = this.agents[i];
          break;
        }
      }
    }
    if (this.currentAgent === null && firstAgent !== null) {
      this.currentAgent = firstAgent;
    }

    // 恢复当前对话
    let currentConvId: string = await StorageManager.loadString(this.context, Constants.LS_KEY_CURRENT_CONV_ID, '');
    let found: boolean = false;
    if (currentConvId !== '') {
      for (let i: number = 0; i < this.conversations.length; i++) {
        if (this.conversations[i].id === currentConvId) {
          this.currentConversationId = currentConvId;
          // 同步智能体
          if (this.currentAgent === null) {
            let aid: string = this.conversations[i].agentId;
            for (let j: number = 0; j < this.agents.length; j++) {
              if (this.agents[j].id === aid) {
                this.currentAgent = this.agents[j];
                break;
              }
            }
          }
          found = true;
          break;
        }
      }
    }
    if (!found && this.currentAgent !== null) {
      // 自动选 agent 最新对话, 没有则创建新对话
      let latest: Conversation | null = this.findLatestConversationForAgent(this.currentAgent.id);
      if (latest !== null) {
        this.currentConversationId = latest.id;
      } else {
        let newConv: Conversation = Conversation.create(this.currentAgent.id, '');
        this.conversations.unshift(newConv);
        this.currentConversationId = newConv.id;
        await this.persistConversations();
      }
    }
    this.ready = true;
  }

  private findLatestConversationForAgent(agentId: string): Conversation | null {
    let latest: Conversation | null = null;
    for (let i: number = 0; i < this.conversations.length; i++) {
      let c: Conversation = this.conversations[i];
      if (c.agentId === agentId) {
        if (latest === null || c.createdAt > latest.createdAt) {
          latest = c;
        }
      }
    }
    return latest;
  }

  // 切换智能体
  async selectAgent(agentId: string): Promise<void> {
    let target: Agent | null = null;
    for (let i: number = 0; i < this.agents.length; i++) {
      if (this.agents[i].id === agentId) {
        target = this.agents[i];
        break;
      }
    }
    if (target === null) {
      return;
    }
    this.currentAgent = target;
    if (this.context !== null) {
      await StorageManager.saveString(this.context, Constants.LS_KEY_CURRENT_AGENT_ID, agentId);
    }
    // 切换到该 agent 的最新对话
    let latest: Conversation | null = this.findLatestConversationForAgent(agentId);
    if (latest !== null) {
      this.openConversation(latest.id);
    } else {
      this.startNewConversation();
    }
  }

  // 打开/切换对话
  async openConversation(convId: string): Promise<void> {
    let conv: Conversation | null = null;
    for (let i: number = 0; i < this.conversations.length; i++) {
      if (this.conversations[i].id === convId) {
        conv = this.conversations[i];
        break;
      }
    }
    if (conv === null) {
      return;
    }
    this.currentConversationId = convId;
    // 立刻通知 UI (scrollTo bottom + rebuildPreviewItems), 不等 storage 落盘
    this.notifyUIChange();
    if (this.context !== null) {
      await StorageManager.saveString(this.context, Constants.LS_KEY_CURRENT_CONV_ID, convId);
    }
    // 同步 agent
    if (this.currentAgent === null || this.currentAgent.id !== conv.agentId) {
      for (let i: number = 0; i < this.agents.length; i++) {
        if (this.agents[i].id === conv.agentId) {
          this.currentAgent = this.agents[i];
          if (this.context !== null) {
            await StorageManager.saveString(this.context, Constants.LS_KEY_CURRENT_AGENT_ID, this.agents[i].id);
          }
          break;
        }
      }
    }
  }

  // 新建对话
  async startNewConversation(): Promise<void> {
    // 清空空对话
    await this.cleanupEmptyConversation();
    if (this.currentAgent === null) {
      return;
    }
    let conv: Conversation = Conversation.create(this.currentAgent.id, '');
    this.conversations.unshift(conv);
    this.currentConversationId = conv.id;
    if (this.context !== null) {
      await StorageManager.saveString(this.context, Constants.LS_KEY_CURRENT_CONV_ID, conv.id);
    }
    this.persistConversations();
  }

  private async cleanupEmptyConversation(): Promise<void> {
    let conv: Conversation | null = this.currentConversation;
    if (conv !== null && conv.messages.length === 0) {
      this.conversations = this.conversations.filter((c: Conversation): boolean => c.id !== conv.id);
      this.currentConversationId = '';
      this.persistConversations();
    }
  }

  // 删除对话
  async deleteConversation(convId: string): Promise<void> {
    this.conversations = this.conversations.filter((c: Conversation): boolean => c.id !== convId);
    if (this.currentConversationId === convId) {
      this.currentConversationId = '';
      if (this.conversations.length > 0) {
        this.currentConversationId = this.conversations[0].id;
      } else {
        // 创建新对话
        if (this.currentAgent !== null) {
          let conv: Conversation = Conversation.create(this.currentAgent.id, '');
          this.conversations.unshift(conv);
          this.currentConversationId = conv.id;
        }
      }
      if (this.context !== null && this.currentConversationId !== '') {
        await StorageManager.saveString(this.context, Constants.LS_KEY_CURRENT_CONV_ID, this.currentConversationId);
      }
    }
    this.persistConversations();
  }

  // 抽屉
  toggleDrawer(): void {
    this.drawerOpen = !this.drawerOpen;
  }
  closeDrawer(): void {
    this.drawerOpen = false;
  }
  openDrawer(): void {
    this.drawerOpen = true;
  }

  // 思考/联网开关
  async setThinkingEnabled(enabled: boolean): Promise<void> {
    this.thinkingEnabled = enabled;
    if (this.context !== null) {
      await StorageManager.saveBoolean(this.context, Constants.LS_KEY_THINKING_ENABLED, enabled);
    }
  }

  async setWebSearchEnabled(enabled: boolean): Promise<void> {
    this.webSearchEnabled = enabled;
    if (this.context !== null) {
      await StorageManager.saveBoolean(this.context, Constants.LS_KEY_WEB_SEARCH_ENABLED, enabled);
    }
  }

  // 设置保存
  async saveApiConfig(cfg: ApiConfig): Promise<void> {
    this.apiConfig = cfg;
    if (this.context !== null) {
      await StorageManager.saveApiConfig(this.context, cfg);
    }
  }

  async saveMultimodalConfig(cfg: MultimodalConfig): Promise<void> {
    this.multimodalConfig = cfg;
    if (this.context !== null) {
      await StorageManager.saveMultimodalConfig(this.context, cfg);
    }
  }

  // 应用预设
  applyDeepseekPreset(): ApiConfig {
    let cfg: ApiConfig = ApiConfig.deepseekPreset();
    return cfg;
  }
  applyVolcanoPreset(): ApiConfig {
    let cfg: ApiConfig = ApiConfig.volcanoPreset();
    return cfg;
  }

  // 文件选择 + 解析
  async pickAndParseFiles(): Promise<void> {
    if (this.context === null) {
      return;
    }
    if (this.multimodalConfig.apiKey === '') {
      promptAction.showToast({ message: '请先配置多模态解析 API 密钥', duration: 2000 });
      return;
    }
    // 提前 toast, 避免 picker 返回后到文件读取之间的空白期页面无反馈
    promptAction.showToast({ message: '正在读取文件...', duration: 2000 });
    let files: PickedFile[] = [];
    try {
      // 同时支持图片与文档
      let docs: PickedFile[] = await FileService.pickFiles();
      files = files.concat(docs);
    } catch (e) {
      promptAction.showToast({ message: '文件选择失败: ' + (e as Error).message, duration: 2000 });
      return;
    }
    if (files.length === 0) {
      return;
    }
    this._isParsing = true;
    this.notifyUIChange();
    let newPending: FileItem[] = [];
    for (let i: number = 0; i < files.length; i++) {
      let item: FileItem = FileService.createFileItem(files[i]);
      this.fileBuffers.set(item.id, files[i].buffer);
      newPending.push(item);
    }
    // 必须整体重新赋值, 不能 push, 否则 @Observed 检测不到数组变更
    this.pendingFiles = [...this.pendingFiles, ...newPending];
    // picker 关闭后立刻刷新一次,让预览条/按钮状态立刻出现
    this.notifyUIChange();
    // 文件列表已经出现在预览条上, 同时开始解析
    for (let i: number = 0; i < this.pendingFiles.length; i++) {
      if (i > 0) {
        await this.sleep(Constants.FILE_PARSE_INTERLEAVE_MS);
      }
      await this.parseOneFile(i);
    }
    // 所有文件解析完毕
    this._isParsing = false;
    this.notifyUIChange();
  }

  private async parseOneFile(index: number): Promise<void> {
    let item: FileItem = this.pendingFiles[index];
    if (item === undefined || item.error) {
      return;
    }
    let buf: ArrayBuffer | undefined = this.fileBuffers.get(item.id);
    if (buf === undefined) {
      // buffer 不存在 → 创建新对象并替换
      let updated: FileItem[] = [...this.pendingFiles];
      updated[index] = FileItem.withError(item);
      this.pendingFiles = updated;
      this.notifyUIChange();
      return;
    }
    let attempts: number = 0;
    let lastErr: Error | null = null;
    while (attempts < Constants.MAX_FILE_PARSE_RETRY) {
      try {
        let result: { content: string; dataUrl: string } = await MultimodalService.parseFile(
          this.multimodalConfig, item.name, buf, item.type
        );
        // 创建新 FileItem 实例替换旧对象 → @Prop 能检测到属性变化
        let updated: FileItem[] = [...this.pendingFiles];
        updated[index] = FileItem.withParsed(item, result.content, result.dataUrl);
        this.pendingFiles = updated;
        this.notifyUIChange();
        return;
      } catch (e) {
        lastErr = e as Error;
        attempts++;
        if (attempts < Constants.MAX_FILE_PARSE_RETRY) {
          await this.sleep(Constants.MAX_FILE_PARSE_RETRY_WAIT_MS);
        }
      }
    }
    // 所有重试均失败 → 创建失败状态的新对象
    let updated: FileItem[] = [...this.pendingFiles];
    updated[index] = FileItem.withError(item);
    this.pendingFiles = updated;
    this.notifyUIChange();
    if (lastErr !== null) {
      promptAction.showToast({ message: item.name + ' 解析失败: ' + lastErr.message, duration: 2500 });
    }
  }

  removePendingFile(id: string): void {
    this.pendingFiles = this.pendingFiles.filter((f: FileItem): boolean => f.id !== id);
    this.fileBuffers.delete(id);
    this.notifyUIChange();
  }

  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  // 发送消息
  async sendMessage(displayText: string): Promise<void> {
    let userText: string = displayText;
    if (userText.trim() === '') {
      return;
    }
    if (this.isStreaming) {
      return;
    }
    if (this.context === null) {
      return;
    }
    if (this.apiConfig.apiKey === '') {
      promptAction.showToast({ message: '请先配置 API Key', duration: 2000 });
      return;
    }
    if (this.currentAgent === null) {
      promptAction.showToast({ message: '请先选择一个智能体', duration: 2000 });
      return;
    }
    let parsing: FileItem[] = this.pendingFiles.filter((f: FileItem): boolean => f.isParsing);
    if (parsing.length > 0) {
      promptAction.showToast({ message: '文件解析中，请稍候', duration: 2000 });
      return;
    }
    // 确保有对话
    if (this.currentConversationId === '' || this.currentConversation === null) {
      await this.startNewConversation();
    }
    let conv: Conversation | null = this.currentConversation;
    if (conv === null) {
      return;
    }

    // 拼接附件文本
    let ready: FileItem[] = this.pendingFiles.filter((f: FileItem): boolean => f.parsedText !== '' && !f.error);
    let fullText: string = userText;
    if (ready.length > 0) {
      let parts: string[] = [];
      for (let i: number = 0; i < ready.length; i++) {
        parts.push('【文件解析：' + ready[i].name + '】\n' + ready[i].parsedText);
      }
      fullText = parts.join('\n\n') + '\n\n' + userText;
    }
    // 构造附件
    let attachments: Attachment[] = [];
    for (let i: number = 0; i < ready.length; i++) {
      let f: FileItem = ready[i];
      let type: string = f.type.startsWith('image/') ? 'image' : 'file';
      attachments.push(Attachment.of(f.name, f.parsedText, type, f.thumbnail, f.dataUrl));
    }
    // 添加 user 消息
    let userMsg: Message = Message.ofUser(generateMessageId(), fullText, userText, attachments);
    conv.messages.push(userMsg);
    // 自动命名
    if (conv.title === '') {
      conv.title = userText.length > 24 ? userText.substring(0, 24) + '...' : userText;
    }
    this.pendingFiles = [];
    this.fileBuffers.clear();
    this.persistConversations();

    // 添加 assistant 占位
    let assistantMsg: Message = Message.ofAssistant(generateMessageId(), '');
    conv.messages.push(assistantMsg);

    this.abortSignal = new AbortSignal();
    this.isStreaming = true;
    this.streamTarget = assistantMsg;
    this.streamTimer = -1;

    // 构造 history(不包含 user 占位 assistant)
    let history: Message[] = conv.messages.slice(0, conv.messages.length - 1);

    let callbacks: StreamCallbacks = new StreamCallbacks();
    callbacks.onToken = (delta: string): void => {
      assistantMsg.content += delta;
      // displayContent 与 content 同步, 但流式中渲染走纯 Text, 避免每 token 双倍 setter 通知
      this.scheduleStreamUpdate();
    };
    callbacks.onError = (err: string): void => {
      this.handleStreamError(assistantMsg, err);
    };
    callbacks.onDone = (_full: string): void => {
      this.handleStreamDone(assistantMsg, conv);
    };

    ChatService.streamChat(
      this.apiConfig,
      this.currentAgent,
      history,
      fullText,
      this.thinkingEnabled,
      this.webSearchEnabled && this.apiConfig.provider === 'volcano',
      callbacks,
      this.abortSignal
    );
  }

  private scheduleStreamUpdate(): void {
    // 50ms 节流(对齐 web 版本的 STREAM_UPDATE_INTERVAL)
    // 仅做持久化, 不触发 UI 刷新 (@Observed Message 自身驱动子组件更新)
    if (this.streamTimer !== -1) {
      return;
    }
    this.streamTimer = setTimeout(() => {
      this.streamTimer = -1;
      this.persistConversations();
    }, Constants.STREAM_THROTTLE_MS);
  }

  private handleStreamError(msg: Message, err: string): void {
    if (msg.content === '') {
      msg.content = '⚠️ ' + err;
    } else {
      msg.content = msg.content + '\n\n⚠️ ' + err;
    }
    msg.displayContent = msg.content;
    this.isStreaming = false;
    this.streamTarget = null;
    if (this.streamTimer !== -1) {
      clearTimeout(this.streamTimer);
      this.streamTimer = -1;
    }
    this.persistConversations();
  }

  private handleStreamDone(msg: Message, conv: Conversation): void {
    this.isStreaming = false;
    this.streamTarget = null;
    // 流式结束前同步 displayContent, 让 RichTextView 解析最终完整内容
    msg.displayContent = msg.content;
    if (this.streamTimer !== -1) {
      clearTimeout(this.streamTimer);
      this.streamTimer = -1;
    }
    this.pendingUIChange = false;
    if (this.abortSignal.aborted && msg.content === '') {
      // 中断且无内容, 移除 assistant
      conv.messages = conv.messages.filter((m: Message): boolean => m !== msg);
    }
    this.persistConversations();
    // 通知 ChatPage isStreaming 等 VM 字段变化 (与流式内容无关, 走 refreshTick)
    this.notifyUIChange();
  }

  // 停止流式
  stopStreaming(): void {
    if (!this.isStreaming) {
      return;
    }
    this.isStreaming = false;
    this.abortSignal.aborted = true;
    ChatService.abort();
    if (this.streamTimer !== -1) {
      clearTimeout(this.streamTimer);
      this.streamTimer = -1;
    }
    this.streamTarget = null;
    this.notifyUIChange();
  }

  // 重新回答
  async regenerateMessage(msgId: string): Promise<void> {
    if (this.isStreaming) {
      promptAction.showToast({ message: 'AI 正在回复中，请稍候', duration: 2000 });
      return;
    }
    let conv: Conversation | null = this.currentConversation;
    if (conv === null) {
      return;
    }
    let aiIdx: number = -1;
    for (let i: number = 0; i < conv.messages.length; i++) {
      if (conv.messages[i].id === msgId) {
        aiIdx = i;
        break;
      }
    }
    if (aiIdx < 0 || conv.messages[aiIdx].role !== 'assistant') {
      return;
    }
    let lastUser: Message | null = null;
    for (let i: number = aiIdx - 1; i >= 0; i--) {
      if (conv.messages[i].role === 'user') {
        lastUser = conv.messages[i];
        break;
      }
    }
    if (lastUser === null) {
      promptAction.showToast({ message: '未找到对应的问题', duration: 2000 });
      return;
    }
    if (this.apiConfig.apiKey === '') {
      promptAction.showToast({ message: '请先配置 API Key', duration: 2000 });
      return;
    }
    // 删除该 assistant 消息
    conv.messages.splice(aiIdx, 1);

    // 复制一份 user 消息(在末尾重新发送, 对齐 web 版 "重新回答" 行为)
    let regenContent: string = '重新回答：' + lastUser.content;
    let regenDisplay: string = '重新回答：' + (lastUser.displayContent === '' ? lastUser.content : lastUser.displayContent);
    let regenAttachments: Attachment[] = lastUser.attachments;
    let regenUserMsg: Message = Message.ofUser(generateMessageId(), regenContent, regenDisplay, regenAttachments);
    conv.messages.push(regenUserMsg);

    let newAssistant: Message = Message.ofAssistant(generateMessageId(), '');
    conv.messages.push(newAssistant);

    this.abortSignal = new AbortSignal();
    this.isStreaming = true;
    this.streamTarget = newAssistant;
    this.streamTimer = -1;

    let history: Message[] = conv.messages.slice(0, conv.messages.length - 1);
    let callbacks: StreamCallbacks = new StreamCallbacks();
    callbacks.onToken = (delta: string): void => {
      newAssistant.content += delta;
      this.scheduleStreamUpdate();
    };
    callbacks.onError = (err: string): void => {
      this.handleStreamError(newAssistant, err);
    };
    callbacks.onDone = (_full: string): void => {
      this.handleStreamDone(newAssistant, conv);
    };

    ChatService.streamChat(
      this.apiConfig,
      this.currentAgent,
      history,
      regenContent,
      this.thinkingEnabled,
      this.webSearchEnabled && this.apiConfig.provider === 'volcano',
      callbacks,
      this.abortSignal
    );
  }

  // 复制
  async copyText(text: string): Promise<void> {
    try {
      let pb = pasteboard.getSystemPasteboard();
      let data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      await pb.setData(data);
    } catch (e) {
      // ignore
    }
  }

  async copyMessagePlain(msgId: string): Promise<void> {
    let conv: Conversation | null = this.currentConversation;
    if (conv === null) {
      return;
    }
    for (let i: number = 0; i < conv.messages.length; i++) {
      if (conv.messages[i].id === msgId) {
        let plain: string = stripMarkdown(conv.messages[i].content);
        await this.copyText(plain);
        return;
      }
    }
  }

  async copyMessageMarkdown(msgId: string): Promise<void> {
    let conv: Conversation | null = this.currentConversation;
    if (conv === null) {
      return;
    }
    for (let i: number = 0; i < conv.messages.length; i++) {
      if (conv.messages[i].id === msgId) {
        await this.copyText(conv.messages[i].content);
        return;
      }
    }
  }

  // 持久化
  private async persistConversations(): Promise<void> {
    if (this.context === null) {
      return;
    }
    try {
      await StorageManager.saveConversations(this.context, this.conversations);
    } catch (e) {
      // ignore
    }
  }
}

function stripMarkdown(md: string): string {
  let text: string = md;
  text = text.replace(/```[\s\S]*?```/g, '');
  text = text.replace(/`([^`]+)`/g, '$1');
  text = text.replace(/!\[[^\]]*\]\([^)]*\)/g, '');
  text = text.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1');
  text = text.replace(/^#{1,6}\s+/gm, '');
  text = text.replace(/\*\*([^*]+)\*\*/g, '$1');
  text = text.replace(/\*([^*]+)\*/g, '$1');
  text = text.replace(/^>\s?/gm, '');
  text = text.replace(/\|/g, '');
  text = text.replace(/^-{3,}$/gm, '');
  return text.trim();
}
