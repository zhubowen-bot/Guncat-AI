import { Message } from '../model/Message';
import { Attachment } from '../model/Attachment';
import { RichTextView } from './RichTextView';

// 聊天气泡 (对齐 web 版本 .message / .bubble)
@Component
export struct ChatBubbleView {
  @ObjectLink message: Message;
  private onCopyPlain: (id: string) => void = (_id: string): void => {};
  private onCopyMarkdown: (id: string) => void = (_id: string): void => {};
  private onRegenerate: (id: string) => void = (_id: string): void => {};
  private onRead: (id: string) => void = (_id: string): void => {};
  private onImageTap: (url: string) => void = (_url: string): void => {};
  // 流式也走 RichTextView (库内置流式增量渲染 + Worker 子线程解析)
  // visibleText 保留 33ms 节流, 作为 UI 缓冲, 避免每个 token 都触发整块重渲染
  @State visibleText: string = '';
  private flushTimer: number = -1;

  @Watch('onStreamPropChanged')
  @Prop isStreaming: boolean = false;

  onStreamPropChanged(): void {
    if (!this.isStreaming && this.flushTimer !== -1) {
      clearInterval(this.flushTimer);
      this.flushTimer = -1;
      this.visibleText = this.message.content;
    }
  }

  aboutToAppear(): void {
    this.visibleText = this.message.content;
    if (this.isStreaming && this.flushTimer === -1) {
      this.flushTimer = setInterval(() => {
        if (this.isStreaming) {
          const current: string = this.message.content;
          if (current !== this.visibleText) {
            this.visibleText = current;
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
            .fontColor(Color.White)
            .lineHeight(22)
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })

          // 附件
          if (this.message.attachments.length > 0) {
            this.buildUserAttachments();
          }
        }
        // 显式声明 HorizontalAlign.Start, 确保附件区与文字左对齐,
        // 避免默认行为在某些场景下把子项推到边线
        .alignItems(HorizontalAlign.Start)
        .backgroundColor($r('app.color.user_msg'))
        .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4 })
        .constraintSize({ maxWidth: '82%' })
      }
      .width('100%')
      .padding({ left: 60, right: 12, top: 6, bottom: 6 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  buildUserAttachments() {
    // 用 Column 显式包裹 + padding, 不依赖 Flex 自身 width('100%') 的隐式尺寸.
    // 附件 padding-left 与上面 Text 的 14 一致, 图片不再设 left margin.
    Column() {
      Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
        ForEach(this.message.attachments, (att: Attachment) => {
          if (att.type === 'image' && att.thumbnail !== '') {
            Image(att.thumbnail !== '' ? att.thumbnail : att.dataUrl)
              .width(64)
              .height(64)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
              .border({ width: 1, color: '#FFFFFF55' })
              .margin({ top: 6, right: 4 })
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
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor($r('app.color.surface'))
            .border({ width: 1, color: $r('app.color.border') })
            .borderRadius(10)
            .margin({ top: 6, right: 4 })
            .constraintSize({ maxWidth: 200 })
          }
        }, (att: Attachment) => att.name)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 30, right: 30, top: 4, bottom: 15 })
  }

  @Builder
  buildAIMessage() {
    Row() {
      // 头像
      Image($r('app.media.cat_avatar'))
        .width(34)
        .height(34)
        .borderRadius(17)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.brand_light'))
        .margin({ top: 4 })

      Column() {
        // 消息内容
        // 流式中与流式结束统一使用 RichTextView
        // 库内置流式增量渲染 (3.3+ 优化表格/代码块/插件闪烁)
        // visibleText 在 33ms 节流中持续更新, 同一组件实例贯穿整个生命周期,
        // Controller / 主题色 / 滚动位置都不会因为 isStreaming 切换而丢失
        if (this.isStreaming && this.message.content === '') {
          // 首个 token 到达前显示原生加载动画，避免只有静止光标。
          Row() {
            LoadingProgress()
              .width(18)
              .height(18)
              .color($r('app.color.brand'))
            Text('正在思考…')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
          }
          .height(42)
          .padding({ left: 14, right: 14 })
          .alignItems(VerticalAlign.Center)
        } else {
          RichTextView({
            content: this.isStreaming ? this.visibleText : this.message.content
          })
        }

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

        // 操作按钮
        if (!this.isStreaming && this.message.content !== '') {
          this.buildAIActions();
        }
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.ai_msg'))
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
      .margin({ left: 10 })
      .constraintSize({ maxWidth: '82%' })

      Blank()
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildAIActions() {
    Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
      this.buildActionChip('复制', false, () => this.onCopyPlain(this.message.id))
      this.buildActionChip('复制 MD', false, () => this.onCopyMarkdown(this.message.id))
      this.buildActionChip('朗读', false, () => this.onRead(this.message.id))
      this.buildActionChip('重新回答', false, () => this.onRegenerate(this.message.id))
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 4, bottom: 8 })
  }

  @Builder
  buildActionChip(label: string, copied: boolean, onTap: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor(copied ? $r('app.color.success') : $r('app.color.text_secondary'))
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(12)
      .border({ width: 1, color: copied ? $r('app.color.success') : $r('app.color.border') })
      .backgroundColor($r('app.color.surface'))
      .margin({ right: 6, bottom: 4 })
      .onClick(() => {
        onTap();
      })
  }
}
