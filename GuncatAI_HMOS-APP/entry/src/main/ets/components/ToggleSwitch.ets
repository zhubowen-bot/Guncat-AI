// 工具开关(对齐 web 版本的 .tool-toggle: 圆角药丸样式, 激活态有圆点发光)
@Component
export struct ToggleSwitch {
  @Prop isOn: boolean = false;
  private label: string = '';
  private onChange: (value: boolean) => void = (_v: boolean): void => {};

  build() {
    Row() {
      // 圆点
      Stack()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.isOn ? $r('app.color.brand') : $r('app.color.text_tertiary'))
        .opacity(this.isOn ? 1 : 0.4)

      Text(this.label)
        .fontSize(13)
        .fontColor(this.isOn ? $r('app.color.brand') : $r('app.color.text_secondary'))
        .fontWeight(this.isOn ? FontWeight.Medium : FontWeight.Normal)
        .margin({ left: 6 })
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .borderRadius(16)
    .border({
      width: 1,
      color: this.isOn ? $r('app.color.brand') : $r('app.color.border')
    })
    .backgroundColor(this.isOn ? $r('app.color.brand_light') : $r('app.color.surface'))
    .onClick(() => {
      this.onChange(!this.isOn);
    })
  }
}
