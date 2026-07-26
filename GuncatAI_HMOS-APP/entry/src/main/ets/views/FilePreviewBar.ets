import { FileItem } from '../common/Types';

// 文件预览条 (单独使用场景; 实际 MessageInputView 已内置, 此组件保留备用)
@Component
export struct FilePreviewBar {
  private files: FileItem[] = [];
  private onRemove: (id: string) => void = (_id: string): void => {};

  build() {
    if (this.files.length > 0) {
      Scroll() {
        Row() {
          ForEach(this.files, (file: FileItem) => {
            this.buildItem(file)
          }, (file: FileItem) => file.id)
        }
        .padding({ left: 12, right: 12 })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .padding({ top: 4, bottom: 4 })
    }
  }

  @Builder
  buildItem(file: FileItem) {
    Row() {
      if (file.type.startsWith('image/') && file.thumbnail !== '') {
        Image(file.thumbnail)
          .width(36)
          .height(36)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .backgroundColor(Color.White)
      } else {
        Text('📄')
          .fontSize(18)
          .fontColor($r('app.color.brand'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
      }
      Column() {
        Text(file.name)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (file.isParsing) {
          Text('解析中...')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 2 })
        } else if (file.error) {
          Text('解析失败')
            .fontSize(11)
            .fontColor('#DC2626')
            .margin({ top: 2 })
        } else {
          Text('已就绪')
            .fontSize(11)
            .fontColor('#16A34A')
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .margin({ left: 8 })
      .alignItems(HorizontalAlign.Start)
      if (!file.isParsing) {
        Text('✕')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 6, right: 2, top: 2, bottom: 2 })
          .onClick(() => {
            this.onRemove(file.id);
          })
      }
    }
    .padding({ left: 8, right: 6, top: 6, bottom: 6 })
    .backgroundColor(file.error ? '#FEE2E2' : $r('app.color.brand_light'))
    .borderRadius(12)
    .margin({ right: 8 })
    .constraintSize({ maxWidth: 220 })
  }
}
