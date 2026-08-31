// WorkTurnView: 工作模式时间线中的单轮渲染(思考 → 正文 → 工具步骤)
// 顺序即实际执行顺序: 模型每轮先思考、再输出叙述文字、最后发起工具调用(调用执行在其后),
// 因此正文渲染在工具行之前; 相邻轮次按消息先后自然衔接成完整时间线。
// 与 ChatBubbleView 的区别: 无头像、无气泡底色, 作为一个连续"任务时间线"的条目,
// 由 ChatPage 在工作模式下把整个会话渲染为单容器时间线, 避免逐轮头像的多次对话观感。
// 更新机制: 流式期间 33ms 定时器只把最新文本同步进 @State(细粒度刷新富文本),
// 步骤列表仅在存在工具调用时低频重建, 避免整轮高频全量重渲染造成卡顿。
import { Message } from '../model/Message';
import { ToolCallRecord } from '../model/ToolCallRecord';
import { RichTextView } from './RichTextView';
import { WorkStepFormat } from './ChatBubbleView';

@Component
export struct WorkTurnView {
  @ObjectLink message: Message;
  @Prop @Watch('onStreamChanged') isStreaming: boolean = false;
  @Prop isLastAssistant: boolean = false;
  private onCopyPlain: (id: string) => void = (_id: string): void => {};
  private onCopyMarkdown: (id: string) => void = (_id: string): void => {};
  private onExportWord: (id: string) => void = (_id: string): void => {};
  private onRegenerate: (id: string) => void = (_id: string): void => {};
  @State private reasoningExpanded: boolean = false;
  @State private expandedStepId: string = '';
  @State private stepsTick: number = 0;
  @State private visibleText: string = '';
  @State private visibleReasoning: string = '';
  private flushTimer: number = -1;
  // 思考跑马灯: 流式中在思考条右侧空白区滚动呈现最新思考内容
  private marqueeScroller: Scroller = new Scroller();

  onStreamChanged(): void {
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
          // 跑马灯跟随最新思考内容滚到末端 (延迟一拍让 Text 先完成布局)
          if (currentReasoning !== '' && !this.reasoningExpanded) {
            setTimeout((): void => {
              this.marqueeScroller.scrollTo({
                xOffset: 999999,
                yOffset: 0,
                animation: { duration: 150, curve: Curve.EaseOut }
              });
            }, 0);
          }
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

  // 进行中工具行的状态文案: 有更早未完成的调用 → 排队等待;
  // 模型仍在生成调用参数(preparing) → 生成调用中; 否则 → 执行中
  private stepStatusLabel(call: ToolCallRecord): string {
    let calls: ToolCallRecord[] = this.message.toolCalls;
    let myIdx: number = calls.indexOf(call);
    for (let i: number = 0; i < myIdx; i++) {
      if (calls[i].durationMs < 0) {
        return '等待中…';
      }
    }
    return call.preparing ? '生成调用中…' : '执行中…';
  }

  build() {
    Column({ space: 8 }) {
      // 思考(折叠条, 默认收起)
      if (this.isStreaming || this.message.reasoning !== '') {
        this.buildThinking()
      }
      // 正文: 本轮叙述/结论, 按发生时序渲染在工具行之前
      if (this.isStreaming || this.message.content !== '') {
        Column() {
          RichTextView({
            content: this.isStreaming ? this.visibleText : this.message.content,
            selectionTrigger: 0
          })
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
            .margin({ top: 4 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      // 工具步骤(CLI 式行内工具行, 点击展开参数与结果)
      if (this.message.toolCalls.length > 0) {
        this.buildSteps()
      }
      // 操作按钮(仅最终回复, 置于轮次末尾)
      if (!this.isStreaming && this.message.content !== '' && this.isLastAssistant) {
        Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
          this.buildChip('复制', (): void => this.onCopyPlain(this.message.id))
          this.buildChip('复制 MD', (): void => this.onCopyMarkdown(this.message.id))
          this.buildChip('导出 Word', (): void => this.onExportWord(this.message.id))
          this.buildChip('重新执行', (): void => this.onRegenerate(this.message.id))
        }
        .width('100%')
        .margin({ top: 6 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildThinking() {
    Column() {
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.lightbulb'))
          .fontSize(13)
          .fontColor([$r('app.color.text_secondary')])
        // 思考完成后在标题后固定缀一段"· 持续了几秒"(占位文案, 不接真实计时)
        Text(this.isStreaming ? '思考中...' : '思考 · 持续了几秒')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        if (this.isStreaming) {
          LoadingProgress()
            .width(11)
            .height(11)
            .color($r('app.color.brand'))
        }
        // 思考跑马灯: 占据标签右侧空白区, 单行滚动呈现最新思考内容
        if (this.isStreaming && !this.reasoningExpanded && this.getMarqueeText() !== '') {
          Scroll(this.marqueeScroller) {
            Text(this.getMarqueeText())
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(1)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None)
          .align(Alignment.Start)
          .height(16)
          .layoutWeight(1)
        } else {
          Blank()
        }
        SymbolGlyph(this.reasoningExpanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
          .fontSize(10)
          .fontColor([$r('app.color.text_tertiary')])
      }
      .width('100%')
      // 水平 16 边距与正文(RichTextView 内边距)对齐, 无底色卡片
      .padding({ left: 16, right: 16, top: 3, bottom: 3 })
      .onClick(() => {
        this.reasoningExpanded = !this.reasoningExpanded;
      })

      if (this.reasoningExpanded) {
        // 展开正文: 外层定位到标题文字起点, 无底色
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
  }

  private getMarqueeText(): string {
    let raw: string = this.isStreaming ? this.visibleReasoning : this.message.reasoning;
    let tail: string = raw;
    if (raw.length > 400) {
      tail = '…' + raw.slice(raw.length - 400);
    }
    return tail.replace(/[\r\n\t]+/g, ' ').trim();
  }

  // 工具步骤(CLI 式行内样式): [图标] 工具名 · 参数摘要, 无底色块, 右端为状态/耗时与展开箭头,
  // 点击展开参数与结果详情(左侧细竖线挂载, 同样无底色)
  @Builder
  private buildSteps() {
    Column({ space: 2 }) {
      ForEach(this.message.toolCalls, (call: ToolCallRecord) => {
        Column({ space: 2 }) {
          Row({ space: 6 }) {
            // 状态图标位: 完成显示工具类别图标(错误红色), 执行中转圈, 被打断则图标置灰
            if (call.durationMs >= 0) {
              SymbolGlyph(WorkStepFormat.iconRes(call.name))
                .fontSize(13)
                .fontColor([call.isError ? $r('app.color.danger') : $r('app.color.text_secondary')])
            } else if (this.isStreaming || call.preparing) {
              LoadingProgress()
                .width(11)
                .height(11)
                .color($r('app.color.brand'))
            } else {
              // 非流式消息上残留的未完成调用 = 执行被打断
              SymbolGlyph(WorkStepFormat.iconRes(call.name))
                .fontSize(13)
                .fontColor([$r('app.color.text_tertiary')])
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
            if (call.durationMs < 0 && (this.isStreaming || call.preparing)) {
              Text(this.stepStatusLabel(call))
                .fontSize(10)
                .fontColor($r('app.color.brand'))
            } else if (call.durationMs < 0) {
              // 执行被打断
              Text('已中断')
                .fontSize(10)
                .fontColor($r('app.color.text_tertiary'))
            } else if (call.isError) {
              Text('失败')
                .fontSize(10)
                .fontColor($r('app.color.danger'))
            } else {
              Text(WorkStepFormat.formatDuration(call.durationMs))
                .fontSize(10)
                .fontColor($r('app.color.text_tertiary'))
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
  }

  @Builder
  private buildChip(label: string, onTap: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor($r('app.color.text_secondary'))
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
