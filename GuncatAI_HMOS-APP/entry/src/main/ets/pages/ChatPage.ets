import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { ChatBubbleView } from '../views/ChatBubbleView';
import { MessageInputView } from '../views/MessageInputView';
import { ToggleSwitch } from '../components/ToggleSwitch';
import { AgentDrawerView } from '../views/AgentDrawerView';
import { ToastView } from '../views/ToastView';
import { ImageLightbox } from '../views/ImageLightbox';
import { SettingsPanel } from '../views/SettingsPanel';
import { AboutPanel } from '../views/AboutPanel';
import { Message } from '../model/Message';
import { Agent } from '../model/Agent';
import { Conversation } from '../model/Conversation';
import { ApiConfig } from '../model/ApiConfig';
import { MultimodalConfig } from '../model/MultimodalConfig';
import { ApiProfile } from '../model/ApiProfile';
import { FileItem, PreviewData } from '../common/Types';
import { generateMessageId } from '../common/Utils';
import { VoiceInputService } from '../service/VoiceInputService';
import {
  ReaderCallbacks,
  ReaderProgress,
  ReaderVoiceOption,
  TextReaderService
} from '../service/TextReaderService';
import { abilityAccessCtrl, common, PermissionRequestResult } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ChatPage {
  @State private vm: ChatViewModel = new ChatViewModel();
  @StorageLink('sharedFileUris') @Watch('onSharedFileUrisChanged')
  private sharedFileUris: string = '';
  @State private inputText: string = '';
  @State private drawerOpen: boolean = false;
  @State private settingsOpen: boolean = false;
  @State private aboutOpen: boolean = false;
  @State private lightboxVisible: boolean = false;
  @State private lightboxUrl: string = '';
  @State private toastMessage: string = '';
  @State private toastVisible: boolean = false;
  @State private isListening: boolean = false;
  @State private refreshTick: number = 0;
  @State private previewItems: PreviewData[] = [];
  @State private readerVisible: boolean = false;
  @State private readerPhase: string = '';
  @State private readerProgress: number = 0;
  @State private readerVoiceIndex: number = 0;
  @State private readerVoices: ReaderVoiceOption[] = [];
  @State private readerSpeed: number = 1;
  @State private readerPaused: boolean = false;
  @State private readerOffsetX: number = 0;
  @State private readerOffsetY: number = 0;
  private readerDragStartX: number = 0;
  private readerDragStartY: number = 0;
  // 消息列表滚动控制器 + 自动置底
  private messageScroller: Scroller = new Scroller();
  private toastTimer: number = -1;
  private voiceInputService: VoiceInputService = new VoiceInputService();

  aboutToAppear(): void {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.vm.setContext(context);
    let readerCallbacks: ReaderCallbacks = new ReaderCallbacks();
    readerCallbacks.onChange = (state: ReaderProgress): void => {
      this.readerVisible = state.visible;
      this.readerPhase = state.phase;
      this.readerProgress = state.progress;
      this.readerVoiceIndex = state.voiceIndex;
      this.readerVoices = state.voices;
      this.readerSpeed = state.speed;
      this.readerPaused = state.paused;
    };
    TextReaderService.setCallbacks(readerCallbacks);
    this.vm.onReadText = async (id: string, text: string): Promise<void> => {
      await TextReaderService.read(context, id, text);
    };
    this.vm.onStopReading = async (): Promise<void> => {
      await TextReaderService.stop();
    };
    this.vm.setStateChangeListener(() => {
      this.rebuildPreviewItems();
      this.refreshTick++;
      // 每次 VM 状态变化触发置底 (对齐 web 版本自动滚动)
      setTimeout(() => {
        this.messageScroller.scrollTo({ xOffset: 0, yOffset: 999999, animation: { duration: 0 } });
      }, 0);
    });
    this.vm.init().then(() => {
      this.refreshTick++;
      this.consumeSharedFiles();
      setTimeout(() => {
        this.messageScroller.scrollTo({ xOffset: 0, yOffset: 999999, animation: { duration: 0 } });
      }, 100);
    });
    // 流式期间每 100ms 置底一次 (revealedCount 在 ChatBubbleView 内部定时推进,
    // ChatPage 需要通过此 timer 确保 Scroll 跟随新字符出现)
    setInterval(() => {
      if (this.vm.isStreaming) {
        this.messageScroller.scrollTo({ xOffset: 0, yOffset: 999999, animation: { duration: 0 } });
      }
    }, 100);
  }

  private onSharedFileUrisChanged(): void {
    this.consumeSharedFiles();
  }

  private consumeSharedFiles(): void {
    if (this.sharedFileUris === '') {
      return;
    }
    let payload: string = this.sharedFileUris;
    this.sharedFileUris = '';
    try {
      let parsed: Object = JSON.parse(payload);
      if (!(parsed instanceof Array)) {
        return;
      }
      let values: Object[] = parsed as Object[];
      let uris: string[] = [];
      for (let i: number = 0; i < values.length; i++) {
        if (typeof values[i] === 'string') {
          uris.push(values[i] as string);
        }
      }
      this.vm.acceptSharedFiles(uris);
    } catch (error) {
      console.error('Failed to consume shared files');
    }
  }

  aboutToDisappear(): void {
    if (this.isListening) {
      this.voiceInputService.cancel();
    }
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer);
      this.toastTimer = -1;
    }
  }

  private showToast(msg: string): void {
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer);
    }
    this.toastMessage = msg;
    this.toastVisible = true;
    this.toastTimer = setTimeout(() => {
      this.toastVisible = false;
      this.toastTimer = -1;
    }, 1000);
  }

  build() {
    Stack() {
      // 主聊天布局
      Column() {
        // 顶部 Header
        this.buildHeader()

        // 消息区
        if (this.vm.currentMessages.length === 0) {
          this.buildEmptyState();
        } else {
          this.buildMessageList();
        }

        // 输入区(工具开关行 + 文件预览 + 输入行, 由 ChatPage 直接组合避免 @Prop 深拷)
        Column() {
          // 工具开关行
          Row() {
            this.buildModelSelector()
            ToggleSwitch({
              isOn: this.vm.thinkingEnabled,
              label: '深度思考',
              onChange: (v: boolean) => {
                this.vm.setThinkingEnabled(v);
                this.refreshTick++;
              }
            })
            ToggleSwitch({
              isOn: this.vm.webSearchEnabled,
              label: '联网搜索',
              onChange: (v: boolean) => {
                this.vm.setWebSearchEnabled(v);
                this.refreshTick++;
              }
            })
              // 联网搜索胶囊左侧加 8vp 间距, 避免两个胶囊贴在一起
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 6, bottom: 4 })
          // 文件预览条
          if (this.vm.pendingFiles.length > 0) {
            this.buildFilePreview();
          }
          // 输入行 + 按钮
          MessageInputView({
            inputText: $inputText,
            isStreaming: this.vm.isStreaming,
            isParsing: this.vm.isParsing,
            isListening: this.isListening,
            onSend: (text: string) => {
              this.handleSend(text);
            },
            onStop: () => {
              this.handleStop();
            },
            onFileUpload: () => {
              this.handleFileUpload();
            },
            onVoiceInput: () => {
              this.handleVoiceInput();
            }
          })
        }
        .width('100%')
        .backgroundColor($r('app.color.surface'))
        .border({ width: { top: 1 }, color: $r('app.color.border') })
        // 底部 surface 色延伸到导航条安全区
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))

      if (this.readerVisible) {
        this.buildReaderControl()
      }

      // 抽屉 - 从左侧滑入/滑出
      if (this.drawerOpen) {
        AgentDrawerView({
          agents: this.vm.agents,
          conversations: this.vm.conversations,
          currentAgentId: this.vm.currentAgent !== null ? this.vm.currentAgent.id : '',
          currentConversationId: this.vm.currentConversationId,
          onSelectAgent: (id: string) => {
            this.vm.selectAgent(id).then(() => {
              this.drawerOpen = false;
              this.refreshTick++;
            });
          },
          onSelectConversation: (id: string) => {
            this.vm.openConversation(id).then(() => {
              this.drawerOpen = false;
              this.refreshTick++;
            });
          },
          onDeleteConversation: (id: string) => {
            this.vm.deleteConversation(id).then(() => {
              this.refreshTick++;
            });
          },
          onNewConversation: () => {
            this.vm.startNewConversation().then(() => {
              this.drawerOpen = false;
              this.refreshTick++;
            });
          },
          onAbout: () => {
            this.aboutOpen = true;
          },
          onClose: () => {
            this.drawerOpen = false;
          }
        })
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.translate({ x: '-100%' }).animation({ duration: 300, curve: Curve.FastOutSlowIn }),
              TransitionEffect.translate({ x: '-100%' }).animation({ duration: 250, curve: Curve.FastOutSlowIn })
            )
          )
      }

      // 设置
      SettingsPanel({
        visible: this.settingsOpen,
        initProfileId: this.vm.currentApiProfileId,
        initProfileName: this.vm.currentApiProfile !== null ? this.vm.currentApiProfile.name : '默认配置',
        profileNames: this.getApiProfileNames(),
        selectedProfileIndex: this.vm.currentApiProfileIndex,
        initProvider: this.vm.apiConfig.provider,
        initBaseUrl: this.vm.apiConfig.baseUrl,
        initApiKey: this.vm.apiConfig.apiKey,
        initModel: this.vm.apiConfig.model,
        initTemperature: this.vm.apiConfig.temperature !== null ? this.vm.apiConfig.temperature.toString() : '',
        initTopP: this.vm.apiConfig.topP !== null ? this.vm.apiConfig.topP.toString() : '',
        initMaxTokens: this.vm.apiConfig.maxTokens !== null ? this.vm.apiConfig.maxTokens.toString() : '',
        initExtraBody: this.vm.apiConfig.extraBody,
        initMmBaseUrl: this.vm.multimodalConfig.baseUrl,
        initMmApiKey: this.vm.multimodalConfig.apiKey,
        initMmModel: this.vm.multimodalConfig.model,
        initMmPreparseEnabled: this.vm.multimodalConfig.preparseEnabled,
        onClose: () => {
          this.settingsOpen = false;
        },
        onAddProfile: () => {
          this.vm.addApiProfile().then(() => {
            this.refreshTick++;
          });
        },
        onSelectProfile: (index: number) => {
          if (index >= 0 && index < this.vm.apiProfiles.length) {
            this.vm.selectApiProfile(this.vm.apiProfiles[index].id);
            this.refreshTick++;
          }
        },
        onSave: (name: string, api: ApiConfig, mm: MultimodalConfig) => {
          this.vm.saveCurrentApiProfile(name, api, mm).then(() => {
            this.settingsOpen = false;
            this.showToast('配置已保存');
            this.refreshTick++;
          });
        },
      })

      // 关于
      AboutPanel({
        visible: this.aboutOpen,
        onClose: () => {
          this.aboutOpen = false;
        }
      })

      // 灯箱
      ImageLightbox({
        visible: this.lightboxVisible,
        imageUrl: this.lightboxUrl,
        onClose: () => {
          this.lightboxVisible = false;
          this.lightboxUrl = '';
        }
      })

      // Toast
      if (this.toastVisible) {
        Stack() {
          ToastView({ message: this.toastMessage })
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Top)
        .padding({ top: 76 })
        .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildReaderControl() {
    Column({ space: 4 }) {
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.waveform'))
          .fontSize(16)
          .fontColor([$r('app.color.brand')])
        Text(this.readerPhase)
          .fontSize(12)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        Button() {
          Text('×')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width(24)
        .height(24)
        .padding(0)
        .borderRadius(6)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.vm.stopReading();
        })
      }
      .gesture(
        PanGesture({ fingers: 1, direction: PanDirection.All, distance: 4 })
          .onActionStart((_event: GestureEvent): void => {
            this.readerDragStartX = this.readerOffsetX;
            this.readerDragStartY = this.readerOffsetY;
          })
          .onActionUpdate((event: GestureEvent): void => {
            this.readerOffsetX = Math.max(-34,
              Math.min(34, this.readerDragStartX + event.offsetX));
            this.readerOffsetY = Math.max(-55,
              Math.min(620, this.readerDragStartY + event.offsetY));
          })
      )

      Row({ space: 6 }) {
        Slider({
          value: this.readerProgress * 100,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .trackThickness(3)
          .selectedColor($r('app.color.brand'))
          .blockColor($r('app.color.brand'))
          .onChange((value: number, mode: SliderChangeMode): void => {
            this.readerProgress = value / 100;
            if (mode === SliderChangeMode.End) {
              TextReaderService.seek(this.readerProgress);
            }
          })
        Text(Math.round(this.readerProgress * 100).toString() + '%')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .width(30)
      }
      .height(20)

      Row({ space: 5 }) {
        Button(this.readerPaused ? '▶' : 'Ⅱ')
          .fontSize(10)
          .fontColor($r('app.color.text_primary'))
          .height(24)
          .width(30)
          .padding(0)
          .borderRadius(6)
          .border({ width: 1, color: $r('app.color.border') })
          .backgroundColor($r('app.color.surface_secondary'))
          .onClick((): void => {
            if (this.readerPaused) {
              TextReaderService.resume();
            } else {
              TextReaderService.pause();
            }
          })

        Button(this.getReaderSpeedLabel())
          .fontSize(10)
          .fontColor($r('app.color.text_primary'))
          .height(24)
          .width(43)
          .padding(0)
          .borderRadius(6)
          .border({ width: 1, color: $r('app.color.border') })
          .backgroundColor($r('app.color.surface_secondary'))
          .onClick((): void => {
            let nextSpeed: number = this.readerSpeed >= 1.75 ? 0.75 : this.readerSpeed + 0.25;
            TextReaderService.setSpeed(nextSpeed);
          })

        Button(this.getReaderVoiceLabel())
          .fontSize(10)
          .fontColor($r('app.color.text_primary'))
          .width(118)
          .height(24)
          .padding({ left: 6, right: 6 })
          .borderRadius(6)
          .border({ width: 1, color: $r('app.color.border') })
          .backgroundColor($r('app.color.surface_secondary'))
          .bindMenu(this.buildReaderVoiceMenu(), { placement: Placement.Bottom })
      }
      .width('100%')
    }
    .width('80%')
    .padding({ left: 9, right: 7, top: 6, bottom: 7 })
    .backgroundColor($r('app.color.surface'))
    .borderRadius(13)
    .shadow({ radius: 12, color: '#26000000', offsetX: 0, offsetY: 4 })
    .position({ x: '10%', y: 68 })
    .translate({ x: this.readerOffsetX, y: this.readerOffsetY })
    .zIndex(20)
  }

  private getReaderVoiceOptions(): SelectOption[] {
    let options: SelectOption[] = [];
    for (let index: number = 0; index < this.readerVoices.length; index++) {
      options.push({ value: this.readerVoices[index].label });
    }
    if (options.length === 0) {
      options.push({ value: '正在查询音色…' });
    }
    return options;
  }

  @Builder
  private buildReaderVoiceMenu() {
    Column() {
      ForEach(this.readerVoices, (voice: ReaderVoiceOption, index: number) => {
        MenuItem({ content: voice.label })
          .selected(index === this.readerVoiceIndex)
          .onChange((): void => {
            TextReaderService.selectVoice(index).catch((error: Error): void => {
              this.readerPhase = '切换音色失败：' + error.message;
            });
          })
      }, (voice: ReaderVoiceOption) =>
        voice.language + voice.person.toString() + voice.style)
    }
  }

  private getReaderVoiceLabel(): string {
    if (this.readerVoiceIndex >= 0 && this.readerVoiceIndex < this.readerVoices.length) {
      return this.readerVoices[this.readerVoiceIndex].label;
    }
    return '正在查询音色…';
  }

  private getReaderSpeedLabel(): string {
    return this.readerSpeed.toFixed(1) + '×';
  }

  // 文件预览条(由 ChatPage 直接渲染, 避免子组件 @Prop 深拷不更新)
  @Builder
  buildFilePreview() {
    Column() {
      Scroll() {
        Row() {
          ForEach(this.previewItems, (item: PreviewData) => {
            this.buildPreviewItem(item)
          }, (item: PreviewData) => item.renderKey)
        }
        .padding({ left: 12, right: 12 })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ top: 4, bottom: 2 })
  }

  @Builder
  buildPreviewItem(item: PreviewData) {
    Row() {
      if (item.type.startsWith('image/') && item.thumbnail !== '') {
        Image(item.thumbnail)
          .width(40)
          .height(40)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .backgroundColor(Color.White)
      } else {
        Text('FILE')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.brand'))
          .width(36)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.border') })
          .borderRadius(6)
      }
      Column() {
        Text(item.name)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (item.status === 'parsing') {
          Text('解析中...')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 2 })
        } else if (item.status === 'error') {
          Text('解析失败')
            .fontSize(11)
            .fontColor($r('app.color.danger'))
            .margin({ top: 2 })
        } else {
          Text('已就绪')
            .fontSize(11)
            .fontColor($r('app.color.success'))
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .margin({ left: 8 })
      .alignItems(HorizontalAlign.Start)
      if (item.status !== 'parsing') {
        Text('✕')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 6, right: 2, top: 2, bottom: 2 })
          .onClick(() => {
            this.vm.removePendingFile(item.fileId);
            // rebuildPreviewItems 已由 VM 的 onStateChange 自动调用
          })
      }
    }
    .padding({ left: 8, right: 6, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.surface_secondary'))
    .border({
      width: 1,
      color: item.status === 'error' ? $r('app.color.danger') : $r('app.color.border')
    })
    .borderRadius(12)
    .margin({ right: 8 })
    .constraintSize({ maxWidth: 240 })
  }

  @Builder
  buildHeader() {
    Row() {
      // 菜单
      Button() {
        Text('☰')
          .fontSize(22)
          .fontColor($r('app.color.text_secondary'))
      }
      .width(40)
      .height(40)
      .borderRadius(10)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.drawerOpen = true;
      })

      // 与右侧两个按钮保持等宽，让标题仍处于屏幕正中。
      Blank()
        .width(40)

      // 标题 (头像 + 智能体名, 居中显示)
      Row() {
        Image($r('app.media.cat_avatar'))
          .width(28)
          .height(28)
          .borderRadius(14)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.brand_light'))
        if (this.vm.currentAgent !== null) {
          Text(this.vm.currentAgent.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ left: 8 })
            .constraintSize({ maxWidth: 200 })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 自动朗读
      Button() {
        if (this.vm.autoReadEnabled) {
          SymbolGlyph($r('sys.symbol.speaker_wave_3'))
            .fontSize(21)
            .fontColor([$r('app.color.brand')])
        } else {
          SymbolGlyph($r('sys.symbol.speaker_wave_3_slash'))
            .fontSize(21)
            .fontColor([$r('app.color.text_secondary')])
        }
      }
      .width(34)
      .height(34)
      .borderRadius(9)
      .backgroundColor(this.vm.autoReadEnabled ? $r('app.color.brand_light') : Color.Transparent)
      .margin({ right: 3 })
      .onClick(() => {
        let enabled: boolean = !this.vm.autoReadEnabled;
        this.vm.setAutoReadEnabled(enabled);
        this.showToast(enabled ? '已开启自动朗读' : '已关闭自动朗读');
        this.refreshTick++;
      })

      // 设置
      Button() {
        SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
          .fontSize(20)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width(40)
      .height(40)
      .borderRadius(10)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.settingsOpen = true;
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 4, right: 4 })
    .backgroundColor($r('app.color.surface'))
    .border({ width: { bottom: 1 }, color: $r('app.color.border') })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildEmptyState() {
    Column() {
      Blank()
      Image($r('app.media.cat_avatar'))
        .width(80)
        .height(80)
        .borderRadius(40)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.brand_light'))
        .opacity(0.9)
        .margin({ bottom: 16 })
      Text(this.vm.currentAgent !== null ? this.vm.currentAgent.name : 'Guncat AI')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 8 })
      Text(this.vm.currentAgent !== null ? this.vm.currentAgent.description : '选择一个智能体开始对话')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .padding({ left: 24, right: 24 })
      Blank()
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildMessageList() {
    Scroll(this.messageScroller) {
      Column() {
        ForEach(this.vm.currentMessages, (msg: Message) => {
          ChatBubbleView({
            message: msg,
            isStreaming: this.vm.isStreaming &&
              msg === this.vm.currentMessages[this.vm.currentMessages.length - 1] &&
              msg.role === 'assistant',
            onCopyPlain: (id: string) => {
              this.vm.copyMessagePlain(id);
              this.showToast('已复制');
            },
            onCopyMarkdown: (id: string) => {
              this.vm.copyMessageMarkdown(id);
              this.showToast('已复制 Markdown');
            },
            onRegenerate: (id: string) => {
              this.vm.regenerateMessage(id);
              this.refreshTick++;
            },
            onRead: (id: string) => {
              this.vm.readMessage(id);
            },
            onImageTap: (url: string) => {
              this.lightboxUrl = url;
              this.lightboxVisible = true;
            }
          })
        }, (msg: Message) => msg.id)
        Blank().height(8)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
    .layoutWeight(1)
    .width('100%')
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
  }

  private handleSend(text: string): void {
    if (text.trim() === '') {
      return;
    }
    if (this.vm.isStreaming) {
      return;
    }
    if (this.vm.apiConfig.apiKey === '') {
      this.showToast('请先配置 API Key');
      this.settingsOpen = true;
      return;
    }
    if (this.vm.currentAgent === null) {
      this.showToast('请先选择一个智能体');
      return;
    }
    // 注意: inputText 的清空由 MessageInputView 内部 onClick 在确认真正发送后才执行
    this.vm.sendMessage(text);
    this.refreshTick++;
  }

  @Builder
  private buildModelSelector() {
    Row() {
      Text(this.vm.currentApiProfile !== null ? this.vm.currentApiProfile.name : '模型')
        .fontSize(13)
        .maxFontSize(13)
        .minFontSize(6)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width(146)
    .height(30)
    .padding({ left: 8, right: 7 })
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.border') })
    .backgroundColor($r('app.color.surface'))
    .margin({ right: 8 })
    .enabled(!this.vm.isStreaming && !this.vm.isParsing && !this.isListening)
    .bindMenu(this.buildModelProfileMenu(), { placement: Placement.Top })
  }

  @Builder
  private buildModelProfileMenu() {
    Column() {
      ForEach(this.vm.apiProfiles, (profile: ApiProfile) => {
        MenuItem({ content: profile.name })
          .selected(profile.id === this.vm.currentApiProfileId)
          .onChange(() => {
            this.vm.selectApiProfile(profile.id);
            this.refreshTick++;
          })
      }, (profile: ApiProfile) => profile.id)
    }
  }

  private getApiProfileOptions(): SelectOption[] {
    let options: SelectOption[] = [];
    for (let i: number = 0; i < this.vm.apiProfiles.length; i++) {
      let profile: ApiProfile = this.vm.apiProfiles[i];
      options.push({ value: profile.name });
    }
    return options;
  }

  private getApiProfileNames(): string[] {
    let names: string[] = [];
    for (let i: number = 0; i < this.vm.apiProfiles.length; i++) {
      names.push(this.vm.apiProfiles[i].name);
    }
    return names;
  }

  private handleStop(): void {
    this.vm.stopStreaming();
    this.refreshTick++;
  }

  private async handleVoiceInput(): Promise<void> {
    if (this.voiceInputService.isListening()) {
      await this.voiceInputService.stop();
      return;
    }
    if (!canIUse('SystemCapability.AI.SpeechRecognizer')) {
      this.showToast('当前设备不支持语音输入');
      return;
    }
    let granted: boolean = await this.requestMicrophonePermission();
    if (!granted) {
      this.showToast('请允许麦克风权限后再使用语音输入');
      return;
    }
    await this.voiceInputService.start(
      this.inputText,
      (text: string): void => {
        this.inputText = text;
      },
      (listening: boolean): void => {
        this.isListening = listening;
      },
      (message: string): void => {
        this.isListening = false;
        this.showToast(message);
      }
    );
  }

  private async requestMicrophonePermission(): Promise<boolean> {
    try {
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      let manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      let result: PermissionRequestResult =
        await manager.requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE']);
      if (result.authResults.length === 0) {
        return false;
      }
      return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`Request microphone permission failed: ${businessError.code}, ${businessError.message}`);
      return false;
    }
  }

  private async handleFileUpload(): Promise<void> {
    await this.vm.pickAndParseFiles();
    this.rebuildPreviewItems();
    this.refreshTick++;
  }

  // 从 VM.pendingFiles 重建预览数据(每次状态变更时调用)
  private rebuildPreviewItems(): void {
    let items: PreviewData[] = [];
    let files: FileItem[] = this.vm.pendingFiles;
    for (let i: number = 0; i < files.length; i++) {
      items.push(PreviewData.fromFileItem(files[i]));
    }
    this.previewItems = items;
  }

  // 从预览数组中移除已删除的项
  private removePreviewItem(id: string): void {
    let remaining: PreviewData[] = [];
    for (let i: number = 0; i < this.previewItems.length; i++) {
      if (this.previewItems[i].fileId !== id) {
        remaining.push(this.previewItems[i]);
      }
    }
    this.previewItems = remaining;
  }
}
