// WorkTurnView: 工作模式时间线中的单轮渲染(思考 → 工具步骤 → 正文)
// 与 ChatBubbleView 的区别: 无头像、无气泡底色, 作为一个连续"任务时间线"的条目,
// 由 ChatPage 在工作模式下把整个会话渲染为单容器时间线, 避免逐轮头像的多次对话观感。
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

  build() {
    Column({ space: 8 }) {
      // 思考(折叠条, 默认收起)
      if (this.isStreaming || this.message.reasoning !== '') {
        this.buildThinking()
      }
      // 工具步骤(紧凑行, 点击展开参数与结果)
      if (this.message.toolCalls.length > 0) {
        this.buildSteps()
      }
      // 正文
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
          // 操作按钮(仅最终回复)
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildThinking() {
    Column() {
      Row() {
        Text(this.isStreaming ? '思考中...' : '思考')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.brand'))
        if (this.isStreaming) {
          LoadingProgress()
            .width(11)
            .height(11)
            .color($r('app.color.brand'))
            .margin({ left: 6 })
        }
        // 思考跑马灯: 占据标签右侧空白区, 单行滚动呈现最新思考内容, 两端渐隐避免截断突兀
        if (this.isStreaming && !this.reasoningExpanded && this.getMarqueeText() !== '') {
          Stack() {
            Scroll(this.marqueeScroller) {
              Text(this.getMarqueeText())
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(1)
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.None)
            .align(Alignment.Start)
            .width('100%')
            .height('100%')

            // 两端渐隐遮罩 (与思考条底色同色的渐变), 不拦截点击
            Row() {
              Row()
                .width(20)
                .height('100%')
                .linearGradient({
                  angle: 90,
                  colors: [[$r('app.color.surface_secondary'), 0.0], ['#00F2F3F7', 1.0]]
                })
              Blank()
              Row()
                .width(20)
                .height('100%')
                .linearGradient({
                  angle: 90,
                  colors: [['#00F2F3F7', 0.0], [$r('app.color.surface_secondary'), 1.0]]
                })
            }
            .width('100%')
            .height('100%')
            .hitTestBehavior(HitTestMode.None)
          }
          .layoutWeight(1)
          .height(16)
          .margin({ left: 8 })
        } else {
          Blank()
        }
        Text(this.reasoningExpanded ? '▴ 收起' : '▾ 展开')
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .onClick(() => {
        this.reasoningExpanded = !this.reasoningExpanded;
      })

      if (this.reasoningExpanded) {
        Text(this.isStreaming ? this.visibleReasoning : this.message.reasoning)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(19)
          .width('100%')
          .padding({ top: 6 })
      }
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 7, bottom: 7 })
    .borderRadius(10)
    .backgroundColor($r('app.color.surface_secondary'))
  }

  private getMarqueeText(): string {
    let raw: string = this.isStreaming ? this.visibleReasoning : this.message.reasoning;
    let tail: string = raw;
    if (raw.length > 400) {
      tail = '…' + raw.slice(raw.length - 400);
    }
    return tail.replace(/[\r\n\t]+/g, ' ').trim();
  }

  @Builder
  private buildSteps() {
    Column({ space: 4 }) {
      ForEach(this.message.toolCalls, (call: ToolCallRecord, index: number) => {
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            if (call.durationMs >= 0) {
              Text(call.isError ? '✗' : '✓')
                .fontSize(11)
                .fontColor(call.isError ? $r('app.color.danger') : $r('app.color.success'))
            } else {
              LoadingProgress()
                .width(10)
                .height(10)
                .color($r('app.color.brand'))
            }
            Text((index + 1).toString() + '. ' + call.name)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text(WorkStepFormat.summarizeArgs(call))
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(this.expandedStepId === call.id ? '▴' : '▾')
              .fontSize(10)
              .fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(10)
          .backgroundColor($r('app.color.input_bg'))
          .onClick(() => {
            this.expandedStepId = this.expandedStepId === call.id ? '' : call.id;
          })

          if (this.expandedStepId === call.id) {
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
            .width('100%')
            .padding(10)
            .borderRadius(10)
            .backgroundColor($r('app.color.input_bg'))
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
