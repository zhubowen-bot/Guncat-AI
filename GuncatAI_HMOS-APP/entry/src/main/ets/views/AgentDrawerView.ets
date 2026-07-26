import { Agent } from '../model/Agent';
import { Conversation } from '../model/Conversation';

// 智能体 / 对话抽屉 (对齐 web 版本 .drawer)
@Component
export struct AgentDrawerView {
  // @Prop: 父组件 (ChatPage) 重渲染时新数组会传递进来, 解决删除/新建对话后侧边栏不更新
  // 之前用 private 字段, 父级 vm.conversations 变了子组件读不到
  @Prop agents: Agent[] = [];
  @Prop conversations: Conversation[] = [];
  @Prop currentAgentId: string = '';
  @Prop currentConversationId: string = '';
  private onSelectAgent: (id: string) => void = (_id: string): void => {};
  private onSelectConversation: (id: string) => void = (_id: string): void => {};
  private onDeleteConversation: (id: string) => void = (_id: string): void => {};
  private onNewConversation: () => void = (): void => {};
  private onAbout: () => void = (): void => {};
  private onClose: () => void = (): void => {};

  build() {
    Stack() {
      // 遮罩 + 阴影: 仅覆盖右侧 20% 露出区域, 从抽屉右边缘 (深) 渐变到屏幕右边缘 (浅)
      // 这样整个右边剩余部分都有阴影变暗效果, 而不是在右边缘一条窄带
      Column()
        .width('20%')
        .height('100%')
        .position({ x: '80%', y: 0 })
        .linearGradient({
          angle: 90,
          colors: [['#60000000', 0.0], ['#20000000', 1.0]]
        })
        .onClick(() => {
          this.onClose();
        })

      // 抽屉主体
      Column() {
        // 头部
        Row() {
          Image($r('app.media.cat_avatar'))
            .width(28)
            .height(28)
            .borderRadius(14)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.brand_light'))
          Text('Guncat AI')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 8 })
            .layoutWeight(1)
          Button() {
            SymbolGlyph($r('sys.symbol.info_circle'))
              .fontSize(18)
              .fontColor([$r('app.color.text_secondary')])
          }
          .width(32)
          .height(32)
          .borderRadius(8)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onAbout();
          })
        }
        .width('100%')
        .height(56)
        .padding({ left: 14, right: 14 })
        .backgroundColor($r('app.color.surface'))
        .border({ width: { bottom: 1 }, color: $r('app.color.border') })
        .alignItems(VerticalAlign.Center)

        // 新建对话
        // 用包裹 Column 的 padding 实现左右内边距, 避免按钮 width('100%') + margin 溢出
        Column() {
          Button() {
            Row() {
              Text('+ 新建对话')
                .fontSize(14)
                .fontColor($r('app.color.brand'))
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .height(40)
          .borderRadius(10)
          .border({ width: 1, style: BorderStyle.Dashed, color: $r('app.color.border') })
          .backgroundColor($r('app.color.background'))
          .onClick(() => {
            this.onNewConversation();
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
        .margin({ top: 12, bottom: 14 })

        // 智能体列表
        Column() {
          Text('智能体')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_secondary'))
            .letterSpacing(0.5)
            .width('100%')
            .padding({ left: 18, right: 18, top: 4, bottom: 8 })
          List() {
            ForEach(this.agents, (agent: Agent) => {
              ListItem() {
                this.buildAgentItem(agent);
              }
            }, (agent: Agent) => agent.id)
          }
          .width('100%')
          .layoutWeight(1)
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 0 })
          .padding({ left: 8, right: 8 })
        }
        .width('100%')
        .layoutWeight(1)

        // 分割
        Divider().color($r('app.color.border')).margin({ top: 8 })

        // 对话列表
        Column() {
          Text('历史对话')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_secondary'))
            .letterSpacing(0.5)
            .width('100%')
            .padding({ left: 18, right: 18, top: 10, bottom: 8 })
          List() {
            ForEach(this.conversations, (conv: Conversation) => {
              ListItem() {
                this.buildConvItem(conv);
              }
            }, (conv: Conversation) => conv.id)
          }
          .width('100%')
          .layoutWeight(1)
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 0 })
          .padding({ left: 8, right: 8, bottom: 12 })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('80%')
      .height('100%')
      .backgroundColor($r('app.color.surface'))
      .alignItems(HorizontalAlign.Start)
      // 移除原 .shadow: 它的 radius 会向四个方向扩散, 导致顶部边线也出现阴影
      // 仅让抽屉 Column 向下延伸到底部系统安全区 (导航条), 不影响上侧
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      // 阴影改在 Stack 第一层 (遮罩层) 实现, 覆盖整个右侧 20% 露出区域, 不影响抽屉顶部
    }
    .width('100%')
    .height('100%')
    // Stack 默认居中, 改成左对齐让抽屉靠左
    .alignContent(Alignment.Start)
  }

  @Builder
  buildAgentItem(agent: Agent) {
    Row() {
      Image($r('app.media.cat_avatar'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.brand_light'))
      Column() {
        Text(agent.name)
          .fontSize(14)
          .fontWeight(this.currentAgentId === agent.id ? FontWeight.Medium : FontWeight.Normal)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(agent.description)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .margin({ left: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 10, bottom: 10 })
    .borderRadius(10)
    .backgroundColor(this.currentAgentId === agent.id ? $r('app.color.brand_light') : Color.Transparent)
    .onClick(() => {
      this.onSelectAgent(agent.id);
    })
  }

  @Builder
  buildConvItem(conv: Conversation) {
    Row() {
      Text(this.getConvTitle(conv))
        .fontSize(14)
        .fontColor(this.currentConversationId === conv.id ? $r('app.color.brand') : $r('app.color.text_primary'))
        .fontWeight(this.currentConversationId === conv.id ? FontWeight.Medium : FontWeight.Normal)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(14)
        .fontColor([$r('app.color.text_secondary')])
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .borderRadius(6)
        .onClick(() => {
          this.onDeleteConversation(conv.id);
        })
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 10, bottom: 10 })
    .borderRadius(10)
    .backgroundColor(this.currentConversationId === conv.id ? $r('app.color.brand_light') : Color.Transparent)
    .onClick(() => {
      this.onSelectConversation(conv.id);
    })
  }

  private getConvTitle(conv: Conversation): string {
    if (conv.title !== '') {
      return conv.title;
    }
    for (let i: number = 0; i < this.agents.length; i++) {
      if (this.agents[i].id === conv.agentId) {
        return '与 ' + this.agents[i].name + ' 的对话';
      }
    }
    return '新对话';
  }
}
