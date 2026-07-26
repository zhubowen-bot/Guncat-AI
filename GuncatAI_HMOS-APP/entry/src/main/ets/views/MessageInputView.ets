// 消息输入区 (对齐 web 版本 .input-wrap + .upload-btn + .send-btn)
// 文件预览条 + 工具开关行由父组件 ChatPage 直接在外部渲染
@Component
export struct MessageInputView {
  @Link inputText: string;
  @Prop isStreaming: boolean = false;
  @Prop @Watch('onParsingChange') isParsing: boolean = false;
  private onSend: (text: string) => void = (_t: string): void => {};
  private onStop: () => void = (): void => {};
  private onFileUpload: () => void = (): void => {};

  @State private parsingAngle: number = 0;
  private angleTimer: number = -1;

  aboutToAppear(): void {
    if (this.isParsing) {
      this.startRotation();
    }
  }

  aboutToDisappear(): void {
    this.stopRotation();
  }

  onParsingChange(): void {
    if (this.isParsing) {
      this.startRotation();
    } else {
      this.stopRotation();
    }
  }

  private startRotation(): void {
    this.stopRotation();
    this.parsingAngle = 0;
    this.angleTimer = setInterval(() => {
      this.parsingAngle = (this.parsingAngle + 6) % 360;
    }, 16);
  }

  private stopRotation(): void {
    if (this.angleTimer !== -1) {
      clearInterval(this.angleTimer);
      this.angleTimer = -1;
    }
    this.parsingAngle = 0;
  }

  build() {
    Row() {
      this.buildInputWrap()
      this.buildUploadButton()
      this.buildSendButton()
    }
    .width('100%')
    .padding({ left: 14, right: 8, top: 4, bottom: 8 })
    .alignItems(VerticalAlign.Bottom)
  }

  @Builder
  buildInputWrap() {
    Row() {
      TextArea({
        placeholder: '输入消息...',
        text: this.inputText
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_secondary'))
        .constraintSize({ minHeight: 36, maxHeight: 120 })
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .onChange((value: string) => {
          this.inputText = value;
        })
    }
    .layoutWeight(1)
    .backgroundColor($r('app.color.input_bg'))
    .borderRadius(20)
    .border({ width: 1, color: $r('app.color.border') })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildUploadButton() {
    Button() {
      if (this.isParsing) {
        SymbolGlyph($r('sys.symbol.arrow_clockwise'))
          .fontSize(20)
          .fontColor([$r('app.color.brand')])
          .rotate({ angle: this.parsingAngle })
      } else {
        SymbolGlyph($r('sys.symbol.paperclip'))
          .fontSize(20)
          .fontColor([$r('app.color.text_secondary')])
      }
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .backgroundColor(this.isParsing ? $r('app.color.brand_light') : Color.Transparent)
    .margin({ left: 4 })
    .onClick(() => {
      if (!this.isStreaming && !this.isParsing) {
        this.onFileUpload();
      }
    })
  }

  @Builder
  buildSendButton() {
    if (this.isStreaming) {
      Button() {
        Stack() {
          Stack()
            .width(12)
            .height(12)
            .backgroundColor(Color.White)
            .borderRadius(2)
        }
        .width(20)
        .height(20)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor($r('app.color.stop_btn'))
      .margin({ left: 4 })
      .onClick(() => {
        this.onStop();
      })
    } else {
      Button() {
        SymbolGlyph($r('sys.symbol.paperplane'))
          .fontSize(18)
          .fontColor([Color.White])
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor((this.inputText.trim() !== '' && !this.isParsing) ?
        $r('app.color.brand') : $r('app.color.text_tertiary'))
      .margin({ left: 4 })
      .onClick(() => {
        // 只有在非解析中且有文本时,才真正发送并清空
        if (this.isParsing) {
          return;
        }
        if (this.inputText.trim() === '') {
          return;
        }
        this.onSend(this.inputText);
        this.inputText = '';
      })
    }
  }
}
