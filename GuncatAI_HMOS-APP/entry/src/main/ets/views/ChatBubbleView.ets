import { Message } from '../model/Message';
import { Attachment } from '../model/Attachment';
import { ToolCallRecord } from '../model/ToolCallRecord';
import { RichTextView } from './RichTextView';

// 工具步骤的文本格式化(静态类, 供 @Builder 内调用; WorkTurnView 复用)
export class WorkStepFormat {
  static capText(text: string, max: number): string {
    if (text.length <= max) {
      return text;
    }
    return text.substring(0, max) + '...';
  }

  // 参数概要: 优先展示 path/from/to/query, content 只取开头
  static summarizeArgs(call: ToolCallRecord): string {
    // 流式生成中的参数不是完整 JSON: 大参数整段解析(失败也要扫到末尾)开销大,
    // 先用结尾字符廉价判断, 未收口直接回退原文展示
    let trimmed: string = call.argsJson.trim();
    if (trimmed !== '' && !trimmed.endsWith('}')) {
      return WorkStepFormat.capText(call.argsJson, 80);
    }
    try {
      let parsed: Object = JSON.parse(call.argsJson);
      if (typeof parsed === 'object' && parsed !== null && !(parsed instanceof Array)) {
        let rec: Record<string, Object> = parsed as Record<string, Object>;
        let keys: string[] = ['path', 'from', 'to', 'query', 'content'];
        let parts: string[] = [];
        for (let i: number = 0; i < keys.length; i++) {
          let v: Object = rec[keys[i]];
          if (typeof v === 'string' && (v as string) !== '') {
            let val: string = v as string;
            if (keys[i] === 'content') {
              parts.push('content=' + WorkStepFormat.capText(val.replace(/\s+/g, ' '), 48));
            } else {
              parts.push(keys[i] + '=' + WorkStepFormat.capText(val, 80));
            }
          }
        }
        if (parts.length > 0) {
          // 单参数时省略 "path=" 这类键名, 对齐 CLI 工具行 "Edit · 路径" 的观感
          if (parts.length === 1) {
            let eq: number = parts[0].indexOf('=');
            if (eq >= 0) {
              return parts[0].substring(eq + 1);
            }
          }
          return parts.join(', ');
        }
      }
    } catch (e) {
      // 参数不是合法 JSON 时回退原文
    }
    return WorkStepFormat.capText(call.argsJson, 80);
  }

  static formatDuration(ms: number): string {
    if (ms < 1000) {
      return ms.toString() + 'ms';
    }
    return (ms / 1000).toFixed(1) + 's';
  }

  // 工具类别图标: CLI 式行内工具行左端的彩色系单色小图标, 按工具名映射 sys.symbol
  static iconRes(toolName: string): Resource {
    switch (toolName) {
      case 'read_file':
      case 'read_ppt':
      case 'parse_document':
        return $r('sys.symbol.doc_text');
      case 'write_file':
      case 'write_docx':
      case 'write_xlsx':
      case 'write_pptx':
      case 'write_csv':
      case 'write_svg':
        return $r('sys.symbol.doc_plaintext_and_pencil');
      case 'append_file':
      case 'edit_ppt':
      case 'transform_file':
        return $r('sys.symbol.pencil_tip');
      case 'search_files':
      case 'search_pdf':
      case 'record_search':
      case 'glob':
        return $r('sys.symbol.magnifyingglass');
      case 'list_files':
        return $r('sys.symbol.folder');
      case 'create_dir':
        return $r('sys.symbol.folder_badge_plus');
      case 'delete_file':
        return $r('sys.symbol.trash');
      case 'move_file':
        return $r('sys.symbol.move');
      case 'download_file':
        return $r('sys.symbol.arrow_down_to_line');
      case 'view_image':
      case 'pdf_to_images':
        return $r('sys.symbol.picture');
      case 'todo_write':
        return $r('sys.symbol.list_checkmark');
      case 'list_skills':
      case 'load_skill':
        return $r('sys.symbol.list_book');
      case 'bash':
        return $r('sys.symbol.code');
      default:
        return $r('sys.symbol.wrench_and_screwdriver');
    }
  }

  // 工具行的短显示名: 已知工具映射为动宾式短名, 未知工具回退原名
  static displayName(toolName: string): string {
    switch (toolName) {
      case 'read_file':
      case 'read_ppt':
        return 'Read';
      case 'parse_document':
        return 'Parse';
      case 'write_file':
      case 'write_docx':
      case 'write_xlsx':
      case 'write_pptx':
      case 'write_csv':
      case 'write_svg':
        return 'Write';
      case 'append_file':
        return 'Append';
      case 'edit_ppt':
        return 'Edit';
      case 'transform_file':
        return 'Transform';
      case 'search_files':
      case 'search_pdf':
      case 'record_search':
        return 'Search';
      case 'glob':
        return 'Glob';
      case 'list_files':
        return 'List';
      case 'list_skills':
        return 'Skills';
      case 'load_skill':
        return 'Skill';
      case 'create_dir':
        return 'Mkdir';
      case 'delete_file':
        return 'Delete';
      case 'move_file':
        return 'Move';
      case 'download_file':
        return 'Download';
      case 'view_image':
      case 'pdf_to_images':
        return 'Image';
      case 'todo_write':
        return 'Todo';
      case 'bash':
        return 'Bash';
      default:
        return toolName;
    }
  }
}

// 聊天气泡 (对齐 web 版本 .message / .bubble)
@Component
export struct ChatBubbleView {
  @ObjectLink message: Message;
  private onCopyPlain: (id: string) => void = (_id: string): void => {};
  private onCopyMarkdown: (id: string) => void = (_id: string): void => {};
  private onSelectPartial: (id: string) => void = (_id: string): void => {};
  private onRegenerate: (id: string) => void = (_id: string): void => {};
  private onRead: (id: string) => void = (_id: string): void => {};
  private onExportWord: (id: string) => void = (_id: string): void => {};
  private onImageTap: (url: string) => void = (_url: string): void => {};
  // 复制局部: 点击次数递增, 传给 RichTextView 触发开启文本选择模式
  @State private selectionTick: number = 0;
  // 深度思考条折叠状态 (默认折叠, 点击头部展开)
  @State private reasoningExpanded: boolean = false;
  // 当前展开结果详情的工具步骤(工作模式, 单步展开)
  @State private expandedStepId: string = '';
  // 步骤状态刷新计数(流式中由 flushTimer 推进, 驱动步骤卡片重渲染)
  @State private stepsTick: number = 0;
  // 工作模式上下文: 工作会话中间轮次隐藏操作按钮、思考条改称"思考"
  @Prop isWork: boolean = false;
  @Prop isLastAssistant: boolean = false;
  // 流式也走 RichTextView (库内置流式增量渲染 + Worker 子线程解析)
  // visibleText 保留 33ms 节流, 作为 UI 缓冲, 避免每个 token 都触发整块重渲染
  @State visibleText: string = '';
  @State visibleReasoning: string = '';
  private flushTimer: number = -1;

  @Watch('onStreamPropChanged')
  @Prop isStreaming: boolean = false;

  onStreamPropChanged(): void {
    if (!this.isStreaming && this.flushTimer !== -1) {
      clearInterval(this.flushTimer);
      this.flushTimer = -1;
      this.visibleText = this.message.content;
      this.visibleReasoning = this.message.reasoning;
      this.stepsTick++;
    }
  }

  aboutToAppear(): void {
    this.visibleText = this.message.content;
    this.visibleReasoning = this.message.reasoning;
    if (this.isStreaming && this.flushTimer === -1) {
      this.flushTimer = setInterval(() => {
        if (this.isStreaming) {
          const current: string = this.message.content;
          if (current !== this.visibleText) {
            this.visibleText = current;
          }
          const currentReasoning: string = this.message.reasoning;
          if (currentReasoning !== this.visibleReasoning) {
            this.visibleReasoning = currentReasoning;
          }
          // 工具步骤状态(执行中→完成)由 VM 原地更新, 用 tick 驱动卡片重渲染
          if (this.message.toolCalls.length > 0) {
            this.stepsTick++;
          }
        }
      }, 33);
    }
  }

  aboutToDisappear(): void {
    if (this.flushTimer !== -1) {
      clearInterval(this.flushTimer);
      this.flushTimer = -1;
    }
  }

  build() {
    if (this.message.role === 'user') {
      this.buildUserMessage();
    } else {
      this.buildAIMessage();
    }
  }

  @Builder
  buildUserMessage() {
    Column() {
      Row() {
        Blank()
        Column() {
          // 文本
          Text(this.message.displayContent !== '' ? this.message.displayContent : this.message.content)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
            .padding({ left: 18, right: 18, top: 12, bottom: 12 })

          // 附件
          if (this.message.attachments.length > 0) {
            this.buildUserAttachments();
          }
        }
        // 显式声明 HorizontalAlign.Start, 确保附件区与文字左对齐,
        // 避免默认行为在某些场景下把子项推到边线
        .alignItems(HorizontalAlign.Start)
        .backgroundColor($r('app.color.raised_surface'))
        .borderRadius({ topLeft: 22, topRight: 22, bottomLeft: 22, bottomRight: 8 })
        .shadow({ radius: 14, color: '#14000000', offsetX: 0, offsetY: 4 })
        .constraintSize({ maxWidth: '82%' })
      }
      .width('100%')
      .padding({ left: 60, right: 16, top: 8, bottom: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  buildUserAttachments() {
    // 用 Column 显式包裹 + padding, 不依赖 Flex 自身 width('100%') 的隐式尺寸.
    // 附件 padding-left 与上面 Text 的 18 一致, 图片不再设 left margin.
    Column() {
      Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
        ForEach(this.message.attachments, (att: Attachment) => {
          if (att.type === 'image' && att.thumbnail !== '') {
            Image(att.thumbnail !== '' ? att.thumbnail : att.dataUrl)
              .width(72)
              .height(72)
              .objectFit(ImageFit.Cover)
              .borderRadius(14)
              .margin({ top: 8, right: 6 })
              .onClick(() => {
                this.onImageTap(att.dataUrl !== '' ? att.dataUrl : att.thumbnail);
              })
          } else {
            Row() {
              Text('FILE')
                .fontSize(9)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.brand'))
              Text(att.name)
                .fontSize(12)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
                .margin({ left: 4 })
            }
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .backgroundColor($r('app.color.input_bg'))
            .borderRadius(14)
            .margin({ top: 8, right: 6 })
            .constraintSize({ maxWidth: 200 })
          }
        }, (att: Attachment) => att.name)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 18, right: 18, top: 4, bottom: 16 })
  }

  @Builder
  buildAIMessage() {
    Row() {
      // 头像
      Image($r('app.media.cat_avatar'))
        .width(38)
        .height(38)
        .borderRadius(19)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.brand_light'))
        .margin({ top: 4 })

      Column() {
        // 思考条(Codex 式时间线: 思考在最前)
        if (this.isStreaming || this.message.reasoning !== '') {
          this.buildReasoningBar()
        }

        // 工具调用步骤(工作模式, CLI 式行内工具行, 单步点击展开参数与结果)
        if (this.message.toolCalls.length > 0) {
          this.buildToolSteps()
        }

        // 气泡本体
        Column() {
          // 消息内容
          // 流式中与流式结束统一使用 RichTextView
          // 库内置流式增量渲染 (3.3+ 优化表格/代码块/插件闪烁)
          // visibleText 在 33ms 节流中持续更新, 同一组件实例贯穿整个生命周期,
          // Controller / 主题色 / 滚动位置都不会因为 isStreaming 切换而丢失
          RichTextView({
            content: this.isStreaming ? this.visibleText : this.message.content,
            selectionTrigger: this.selectionTick
          })

          // 流式光标
          if (this.isStreaming && this.message.content !== '') {
            Row() {
              Stack()
                .width(2)
                .height(14)
                .backgroundColor($r('app.color.brand'))
                .borderRadius(1)
            }
            .width('100%')
            .padding({ left: 12 })
            .margin({ bottom: 6 })
          }

          // 操作按钮(工作模式仅最终消息显示, 中间轮次保持时间线干净)
          if (!this.isStreaming && this.message.content !== '' &&
            (!this.isWork || this.isLastAssistant)) {
            this.buildAIActions();
          }
        }
        .width('100%')
        .backgroundColor($r('app.color.ai_msg'))
        .borderRadius({ topLeft: 8, topRight: 22, bottomLeft: 22, bottomRight: 22 })
        .shadow({ radius: 14, color: '#12000000', offsetX: 0, offsetY: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .constraintSize({ maxWidth: '80%' })

      Blank()
    }
    .width('100%')
    .padding({ left: 4, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Top)
  }

  // 工具调用步骤(CLI 式行内样式): [图标] 工具名 · 参数摘要, 无底色块, 右端为耗时与展开箭头,
  // 点击展开参数与结果详情(左侧细竖线挂载, 同样无底色)
  @Builder
  buildToolSteps() {
    Column({ space: 2 }) {
      ForEach(this.message.toolCalls, (call: ToolCallRecord) => {
        Column({ space: 2 }) {
          Row({ space: 6 }) {
            // 状态图标位: 完成显示工具类别图标(错误时红色), 执行中转圈
            if (call.durationMs >= 0) {
              SymbolGlyph(WorkStepFormat.iconRes(call.name))
                .fontSize(13)
                .fontColor([call.isError ? $r('app.color.danger') : $r('app.color.text_secondary')])
            } else {
              LoadingProgress()
                .width(11)
                .height(11)
                .color($r('app.color.brand'))
            }
            Text(WorkStepFormat.displayName(call.name))
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
            Text('·')
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
            Text(WorkStepFormat.summarizeArgs(call))
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            if (call.durationMs >= 0) {
              if (call.isError) {
                Text('失败')
                  .fontSize(10)
                  .fontColor($r('app.color.danger'))
              } else {
                Text(WorkStepFormat.formatDuration(call.durationMs))
                  .fontSize(10)
                  .fontColor($r('app.color.text_tertiary'))
              }
            }
            SymbolGlyph(this.expandedStepId === call.id ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
              .fontSize(10)
              .fontColor([$r('app.color.text_tertiary')])
          }
          .width('100%')
          // 水平 16 边距与正文(RichTextView 内边距)对齐, 工具行宽度即正文宽度
          .padding({ left: 16, right: 16, top: 3, bottom: 3 })
          .onClick(() => {
            this.expandedStepId = this.expandedStepId === call.id ? '' : call.id;
          })

          if (this.expandedStepId === call.id) {
            // 外层定位到行内文字起点(16 边距 + 图标约 20), 细竖线挂在文字下方, 详情随正文宽度收窄
            Column() {
              Column({ space: 4 }) {
                Text('参数')
                  .fontSize(10)
                  .fontColor($r('app.color.text_tertiary'))
                Text(WorkStepFormat.capText(call.argsJson, 600))
                  .fontSize(11)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                Text(call.isError ? '错误' : '结果')
                  .fontSize(10)
                  .fontColor($r('app.color.text_tertiary'))
                Text(WorkStepFormat.capText(call.result === '' ? '(执行中...)' : call.result, 800))
                  .fontSize(11)
                  .fontColor(call.isError ? $r('app.color.danger') : $r('app.color.text_secondary'))
                  .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 10, right: 0, top: 6, bottom: 6 })
              .border({ width: { left: 2 }, color: { left: $r('app.color.border') } })
            }
            .width('100%')
            .padding({ left: 36, right: 16 })
          }
        }
        .width('100%')
      }, (call: ToolCallRecord) => call.id + '#' + call.durationMs.toString() + '#' +
        call.result.length.toString() + '#' + this.stepsTick.toString())
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  // 深度思考条(CLI 式行内样式): [图标] 思考标题, 无底色卡片, 与工具行同一套观感.
  // 流式中在标题右侧显示转圈动画; 右端实时显示 token 速度(流式中按已输出字符实时估算,
  // 流式结束后由 API usage 精确替换)与缓存命中率(读取 API 返回的缓存 token 数, 无返回值不显示).
  @Builder
  buildReasoningBar() {
    Column() {
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.lightbulb'))
          .fontSize(13)
          .fontColor([$r('app.color.text_secondary')])
        // 思考完成后在标题后固定缀一段"· 持续了几秒"(占位文案, 不接真实计时)
        Text((this.isWork ? '思考' : '深度思考') + (this.isStreaming ? '' : ' · 持续了几秒'))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        if (this.isStreaming) {
          LoadingProgress()
            .width(11)
            .height(11)
            .color($r('app.color.brand'))
        }
        Blank()
        if (this.message.tokenSpeed > 0) {
          Text(this.message.tokenSpeed.toFixed(1) + ' tok/s')
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))
        }
        if (this.message.cacheHitRate >= 0) {
          Text('缓存命中 ' + Math.round(this.message.cacheHitRate * 100).toString() + '%')
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ left: 8 })
        }
        SymbolGlyph(this.reasoningExpanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
          .fontSize(10)
          .fontColor([$r('app.color.text_tertiary')])
      }
      .width('100%')
      // 水平 16 边距与正文(RichTextView 内边距)对齐
      .padding({ left: 16, right: 16, top: 3, bottom: 3 })
      .onClick(() => {
        this.reasoningExpanded = !this.reasoningExpanded;
      })

      if (this.reasoningExpanded) {
        // 展开正文: 外层定位到标题文字起点, 细竖线挂载, 无底色
        Column() {
          Text(this.isStreaming ? this.visibleReasoning : this.message.reasoning)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .lineHeight(19)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 36, right: 16 })
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  buildAIActions() {
    Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
      this.buildActionChip('复制', false, () => this.onCopyPlain(this.message.id))
      this.buildActionChip('复制 MD', false, () => this.onCopyMarkdown(this.message.id))
      this.buildActionChip('复制局部', false, () => {
        this.selectionTick++;
        this.onSelectPartial(this.message.id);
      })
      this.buildActionChip('朗读', false, () => this.onRead(this.message.id))
      this.buildActionChip('导出 Word', false, () => this.onExportWord(this.message.id))
      this.buildActionChip('重新回答', false, () => this.onRegenerate(this.message.id))
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 6, bottom: 10 })
  }

  @Builder
  buildActionChip(label: string, copied: boolean, onTap: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor(copied ? $r('app.color.success') : $r('app.color.text_secondary'))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor($r('app.color.raised_surface'))
      .shadow({ radius: 10, color: '#10000000', offsetX: 0, offsetY: 2 })
      .margin({ right: 8, bottom: 6 })
      .onClick(() => {
        onTap();
      })
  }
}
