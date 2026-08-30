import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { ChatBubbleView } from '../views/ChatBubbleView';
import { MessageInputView } from '../views/MessageInputView';
import { ToggleSwitch } from '../components/ToggleSwitch';
import { AgentDrawerView } from '../views/AgentDrawerView';
import { FlyInLaunchView } from '../views/FlyInLaunchView';
import { ToastView } from '../views/ToastView';
import { ImageLightbox } from '../views/ImageLightbox';
import { SettingsPanel } from '../views/SettingsPanel';
import { AboutPanel } from '../views/AboutPanel';
import { WorkspaceBar } from '../views/WorkspaceBar';
import { WorkTurnView } from '../views/WorkTurnView';
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
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { DocxExporter } from '../export/DocxExporter';

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
  @State private launchVisible: boolean = true;
  @State private inputAreaVisible: boolean = false;
  // 单一“hero 图标”节点：不依赖共享元素转场，避免交叉淡化导致的发白闪烁
  @State private heroVisible: boolean = true;
  @State private heroX: number = 0;
  @State private heroY: number = 0;
  @State private heroSize: number = 60;
  private heroTargetX: number = 0;
  private heroTargetY: number = 0;
  private heroTargetSize: number = 96;
  private emptyStateBaseX: number = 0;
  private emptyStateBaseY: number = 0;
  private rootW: number = 360;
  private rootH: number = 780;
  @State private lightboxVisible: boolean = false;
  @State private lightboxUrl: string = '';
  @State private toastMessage: string = '';
  @State private toastVisible: boolean = false;
  @State private isListening: boolean = false;
  @State private refreshTick: number = 0;
  // 工作模式工作区弹层开关(挂在"工作模式"胶囊上方)
  @State private workspacePopupOpen: boolean = false;
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
  // 会话工作时间计时: 工作模式任务执行期间每秒累计(秒数存 VM 供工作区面板显示), 切换/新建会话归零
  private workTickTimer: number = -1;
  private lastWorkConvId: string = '';
  private voiceInputService: VoiceInputService = new VoiceInputService();
  // 用户手指触摸滚动期间暂停自动置底, 松手后恢复
  // (避免 scrollTo 与进行中的手势冲突导致白屏)
  private userScrolling: boolean = false;
  // 流式自动置底定时器句柄(页面销毁时需清理)
  private streamScrollTimer: number = -1;

  aboutToAppear(): void {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.vm.setContext(context);
    this.initHeroLayout();
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
      // 切到非工作模式的智能体/会话时收起工作区弹层
      if (!this.vm.workMode && this.workspacePopupOpen) {
        this.workspacePopupOpen = false;
      }
      // 切换/新建会话时工作时间归零
      if (this.vm.currentConversationId !== this.lastWorkConvId) {
        this.lastWorkConvId = this.vm.currentConversationId;
        this.vm.workElapsedSec = 0;
      }
      this.rebuildPreviewItems();
      this.refreshTick++;
      // 每次 VM 状态变化触发置底 (对齐 web 版本自动滚动); 用户触摸时跳过, 松手后恢复
      setTimeout(() => {
        if (!this.userScrolling) {
          this.messageScroller.scrollTo({ xOffset: 0, yOffset: 999999, animation: { duration: 0 } });
        }
      }, 0);
    });
    this.vm.init().then(() => {
      this.refreshTick++;
      this.consumeSharedFiles();
      setTimeout(() => {
        if (!this.userScrolling) {
          this.messageScroller.scrollTo({ xOffset: 0, yOffset: 999999, animation: { duration: 0 } });
        }
      }, 100);
    });
    // 工作模式工作时间计时: 面板随开随关, 计时必须挂在常驻的 ChatPage 上才不中断
    this.workTickTimer = setInterval((): void => {
      if (!this.vm.workMode) {
        return;
      }
      if (this.vm.currentConversationId !== this.lastWorkConvId) {
        this.lastWorkConvId = this.vm.currentConversationId;
        this.vm.workElapsedSec = 0;
      }
      if (this.vm.isStreaming) {
        this.vm.workElapsedSec++;
      }
    }, 1000);
    // 流式期间每 100ms 置底一次 (revealedCount 在 ChatBubbleView 内部定时推进,
    // ChatPage 需要通过此 timer 确保 Scroll 跟随新字符出现)
    this.streamScrollTimer = setInterval(() => {
      if (this.vm.isStreaming && !this.userScrolling) {
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
    if (this.workTickTimer !== -1) {
      clearInterval(this.workTickTimer);
      this.workTickTimer = -1;
    }
    if (this.streamScrollTimer !== -1) {
      clearInterval(this.streamScrollTimer);
      this.streamScrollTimer = -1;
    }
  }

  private async initHeroLayout(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const win = await window.getLastWindow(context);
      const rect = win.getWindowProperties().windowRect;
      const w: number = this.getUIContext().px2vp(rect.width);
      const h: number = this.getUIContext().px2vp(rect.height);
      const startSize: number = 60;
      const targetSize: number = 96;
      const headerH: number = 64;
      const inputH: number = 108;
      this.heroSize = startSize;
      this.heroX = w / 2 - startSize / 2;
      this.heroY = h / 2 - startSize / 2;
      this.heroTargetX = w / 2 - targetSize / 2;
      const msgH: number = h - headerH - inputH;
      this.heroTargetY = headerH + msgH / 2 - targetSize / 2;
      this.heroTargetSize = targetSize;
    } catch (error) {
      const w: number = 360;
      const h: number = 780;
      this.heroSize = 60;
      this.heroX = w / 2 - 30;
      this.heroY = h / 2 - 30;
      this.heroTargetX = w / 2 - 48;
      this.heroTargetY = h / 2 - 48 - 22;
      this.heroTargetSize = 96;
    }
  }

  private updateHeroStart(): void {
    const startSize: number = 60;
    this.heroSize = startSize;
    this.heroX = this.rootW / 2 - startSize / 2;
    this.heroY = this.rootH / 2 - startSize / 2;
  }

  private startHeroTransition(): void {
    animateTo({
      duration: 360,
      curve: Curve.EaseOut
    }, () => {
      this.heroX = this.heroTargetX;
      this.heroY = this.heroTargetY;
      this.heroSize = this.heroTargetSize;
    });
    // 等 hero 到位后再关闭启动层、显示底部输入区
    setTimeout(() => {
      this.launchVisible = false;
      this.inputAreaVisible = true;
    }, 380);
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
          // 空状态始终渲染以测量 hero 图标终点；启动期间被启动层遮挡，不会露出
          this.buildEmptyState();
        } else {
          this.buildMessageList();
        }

        // 输入区(工具开关行 + 文件预览 + 输入行, 由 ChatPage 直接组合避免 @Prop 深拷)
        if (this.inputAreaVisible) {
          Column() {
            // 工具开关行
            Row() {
              this.buildModelSelector()
              if (this.vm.workMode) {
                // 工作模式: 联网搜索摆在原深度思考的位置; 深度思考默认开启不再显示开关
                ToggleSwitch({
                  isOn: this.vm.webSearchEnabled,
                  label: '联网搜索',
                  toggleEnabled: true,
                  onChange: (v: boolean) => {
                    this.vm.setWebSearchEnabled(v);
                    this.refreshTick++;
                  }
                })
                  .margin({ left: 10 })
                ToggleSwitch({
                  isOn: true,
                  label: '工作区',
                  // 点击不再直接退出工作模式, 而是在胶囊上方弹出工作区面板(退出入口在面板里)
                  onChange: (_v: boolean) => {
                    this.workspacePopupOpen = !this.workspacePopupOpen;
                    if (this.workspacePopupOpen) {
                      this.vm.refreshWorkspace().then(() => {
                        this.refreshTick++;
                      });
                    }
                  }
                })
                  .margin({ left: 10 })
                  .bindPopup(this.workspacePopupOpen, {
                    builder: this.buildWorkspacePopup,
                    placement: Placement.Top,
                    // 透明遮罩: 点击面板外任意区域即收起, 且不压暗页面
                    mask: { color: Color.Transparent },
                    showInSubWindow: false,
                    onStateChange: (e: PopupStateChangeParam) => {
                      if (this.workspacePopupOpen !== e.isVisible) {
                        this.workspacePopupOpen = e.isVisible;
                      }
                    }
                  })
              } else {
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
                  toggleEnabled: true,
                  onChange: (v: boolean) => {
                    this.vm.setWebSearchEnabled(v);
                    this.refreshTick++;
                  }
                })
                  // 联网搜索胶囊左侧加 10vp 间距, 避免两个胶囊贴在一起
                  .margin({ left: 10 })
              }
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 4 })
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
              placeholder: this.vm.workMode ? '描述任务...' : '输入消息...',
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
              },
              onCameraCapture: () => {
                this.handleCameraCapture();
              }
            })
          }
          .width('100%')
          .backgroundColor($r('app.color.surface'))
          .shadow({ radius: 18, color: '#0D000000', offsetX: 0, offsetY: -2 })
          // 从屏幕底部外滑入
          .transition(TransitionEffect.translate({ y: '100%' })
            .combine(TransitionEffect.OPACITY)
            .animation({ duration: 360, curve: Curve.EaseOut }))
          // 底部 surface 色延伸到导航条安全区
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        } else {
          // 输入区出现前先用等高的占位保住消息区布局，
          // 避免空状态头像在 geometryTransition 过程中因布局变化而闪烁。
          Column()
            .width('100%')
            .height(108)
            .backgroundColor(Color.Transparent)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))

      // 单一 hero 图标：启动时在屏幕中心，随后移动到空状态中心，全程清晰无交叉淡化。
      // 保持常驻渲染，但层级低于抽屉/设置浮层，让浮层自然遮盖它，避免主动消失感。
      if (this.heroVisible && (this.launchVisible || this.vm.currentMessages.length === 0)) {
        this.buildHeroIcon()
      }

      if (this.readerVisible) {
        this.buildReaderControl()
      }

      // 抽屉 - 从左侧滑入/滑出；全屏 scrim 固定覆盖，滑动过程中右侧始终有阴影
      if (this.drawerOpen) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.modal_backdrop'))
          .onClick(() => {
            this.drawerOpen = false;
          })
          .transition(
            TransitionEffect.opacity(0).animation({ duration: 200, curve: Curve.EaseOut })
          )
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
        // 右侧透明点击层：视觉阴影由全屏 scrim 提供，这里只保证点击右侧空白能关闭
        Column()
          .width('18%')
          .height('100%')
          .position({ x: '82%', y: 0 })
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.drawerOpen = false;
          })
          .transition(
            TransitionEffect.opacity(0).animation({ duration: 200, curve: Curve.EaseOut })
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

      // 开屏飞入动效
      if (this.launchVisible) {
        FlyInLaunchView({
          showCenter: false,
          onFinish: () => {
            this.startHeroTransition();
          }
        })
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .onAreaChange((_old: Area, newArea: Area) => {
      const wValue = newArea.width;
      const hValue = newArea.height;
      this.rootW = wValue === undefined ? this.rootW :
        (typeof wValue === 'string' ? parseFloat(wValue) : (typeof wValue === 'number' ? wValue : this.rootW));
      this.rootH = hValue === undefined ? this.rootH :
        (typeof hValue === 'string' ? parseFloat(hValue) : (typeof hValue === 'number' ? hValue : this.rootH));
      this.updateHeroStart();
    })
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
        .width(32)
        .height(32)
        .padding(0)
        .borderRadius(16)
        .backgroundColor($r('app.color.raised_surface'))
        .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 2 })
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

      Row({ space: 8 }) {
        Button(this.readerPaused ? '▶' : 'Ⅱ')
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
          .height(32)
          .width(36)
          .padding(0)
          .borderRadius(16)
          .backgroundColor($r('app.color.raised_surface'))
          .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 2 })
          .onClick((): void => {
            if (this.readerPaused) {
              TextReaderService.resume();
            } else {
              TextReaderService.pause();
            }
          })

        Button(this.getReaderSpeedLabel())
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
          .height(32)
          .width(48)
          .padding(0)
          .borderRadius(16)
          .backgroundColor($r('app.color.raised_surface'))
          .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 2 })
          .onClick((): void => {
            let nextSpeed: number = this.readerSpeed >= 1.75 ? 0.75 : this.readerSpeed + 0.25;
            TextReaderService.setSpeed(nextSpeed);
          })

        Button(this.getReaderVoiceLabel())
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
          .width(128)
          .height(32)
          .padding({ left: 10, right: 10 })
          .borderRadius(16)
          .backgroundColor($r('app.color.raised_surface'))
          .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 2 })
          .bindMenu(this.buildReaderVoiceMenu(), { placement: Placement.Bottom })
      }
      .width('100%')
    }
    .width('82%')
    .padding({ left: 14, right: 12, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.surface'))
    .borderRadius(24)
    .shadow({ radius: 18, color: '#1F000000', offsetX: 0, offsetY: 6 })
    .position({ x: '9%', y: 72 })
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
          .width(42)
          .height(42)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .backgroundColor(Color.White)
      } else {
        Text('FILE')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.brand'))
          .width(40)
          .height(38)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.surface'))
          .borderRadius(12)
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
    .padding({ left: 12, right: 10, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.raised_surface'))
    .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 2 })
    .borderRadius(18)
    .margin({ right: 10 })
    .constraintSize({ maxWidth: 250 })
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
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.drawerOpen = true;
      })

      // 与右侧两个按钮保持等宽，让标题仍处于屏幕正中。
      Blank()
        .width(44)

      // 标题 (智能体名, 居中显示)
      Row() {
        if (this.vm.currentAgent !== null) {
          Text(this.vm.currentAgent.name)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
      .width(44)
      .height(44)
      .borderRadius(22)
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
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.settingsOpen = true;
      })
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 8 })
    .backgroundColor($r('app.color.surface'))
    .shadow({ radius: 18, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildHeroIcon() {
    Column() {
      Image($r('app.media.cat_avatar'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    }
    .width(this.heroSize)
    .height(this.heroSize)
    .borderRadius(this.heroSize / 2)
    .backgroundColor($r('app.color.brand_light'))
    .shadow({ radius: 24, color: '#1A000000', offsetX: 0, offsetY: 8 })
    .clip(true)
    .position({ x: this.heroX, y: this.heroY })
    .hitTestBehavior(HitTestMode.None)
    .zIndex(this.launchVisible ? 101 : 0)
  }

  @Builder
  buildEmptyState() {
    Column() {
      Blank()
      // 图标由 ChatPage 根部的 heroIcon 单节点负责，这里只留等高空位，避免重复渲染
      Column()
        .width(96)
        .height(96)
        .margin({ bottom: 12 })
        .id('emptyStateIconAnchor')
        .onAreaChange((_old: Area, newArea: Area) => {
          const px = newArea.position.x;
          const py = newArea.position.y;
          const localX: number = px === undefined ? 0 :
            (typeof px === 'string' ? parseFloat(px) : (typeof px === 'number' ? px : 0));
          const localY: number = py === undefined ? 0 :
            (typeof py === 'string' ? parseFloat(py) : (typeof py === 'number' ? py : 0));
          this.heroTargetX = this.emptyStateBaseX + localX;
          this.heroTargetY = this.emptyStateBaseY + localY;
          this.heroTargetSize = 96;
        })
      Text(this.vm.currentAgent !== null ? this.vm.currentAgent.name : 'Guncat Work')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 12 })
      Text(this.vm.workMode ?
        'Guncat Harness：自主调度数十种工具，直接读写工作区文件，单次任务可连续运行上百轮会话，独立完成编程级复杂度的长程任务。' :
        (this.vm.currentAgent !== null ? this.vm.currentAgent.description : '选择一个智能体开始对话'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .padding({ left: 32, right: 32 })
      Blank()
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .onAreaChange((_old: Area, newArea: Area) => {
      const bx = newArea.position.x;
      const by = newArea.position.y;
      this.emptyStateBaseX = bx === undefined ? 0 :
        (typeof bx === 'string' ? parseFloat(bx) : (typeof bx === 'number' ? bx : 0));
      this.emptyStateBaseY = by === undefined ? 0 :
        (typeof by === 'string' ? parseFloat(by) : (typeof by === 'number' ? by : 0));
    })
  }

  @Builder
  buildMessageList() {
    Scroll(this.messageScroller) {
      Column() {
        if (this.vm.workMode) {
          this.buildWorkTimeline()
        } else {
          ForEach(this.vm.currentMessages, (msg: Message) => {
            ChatBubbleView({
              message: msg,
              isStreaming: this.vm.isStreaming &&
                msg === this.vm.currentMessages[this.vm.currentMessages.length - 1] &&
                msg.role === 'assistant',
              isWork: this.vm.workMode,
              isLastAssistant: this.vm.currentMessages.length > 0 &&
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
              onSelectPartial: (id: string) => {
                this.showToast('已开启，长按内容即可选择复制');
              },
              onRegenerate: (id: string) => {
                this.vm.regenerateMessage(id);
                this.refreshTick++;
              },
              onRead: (id: string) => {
                this.vm.readMessage(id);
              },
              onExportWord: (id: string) => {
                this.handleExportWord(id);
              },
              onImageTap: (url: string) => {
                this.lightboxUrl = url;
                this.lightboxVisible = true;
              }
            })
          }, (msg: Message) => msg.id)
        }
        Blank().height(8)
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 12, right: 12 })
    }
    .layoutWeight(1)
    .width('100%')
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    // 触摸期间标记 userScrolling, 暂停自动置底; 松手后恢复自动置底
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down || event.type === TouchType.Move) {
        this.userScrolling = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.userScrolling = false;
      }
    })
  }

  // 工作模式时间线: 单容器 + 单一标识, 用户任务与各轮 思考→工具→正文 按发生顺序排列
  @Builder
  buildWorkTimeline() {
    Column({ space: 14 }) {
      // 时间线头(全时间线唯一的标识, 不再逐轮出现头像)
      Row({ space: 10 }) {
        // 机器人标识: 无背景底色, 放大显示
        Image($r('app.media.ic_work'))
          .width(32)
          .height(32)
          .fillColor($r('app.color.brand'))

        Column() {
          Text('工作模式')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(this.vm.isStreaming ? '任务执行中...' : 'Agent 就绪, 描述任务或上传文件')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      ForEach(this.vm.currentMessages, (msg: Message) => {
        if (msg.role === 'user') {
          this.buildWorkTaskCard(msg)
        } else {
          WorkTurnView({
            message: msg,
            isStreaming: this.vm.isStreaming &&
              msg === this.vm.currentMessages[this.vm.currentMessages.length - 1],
            isLastAssistant: msg === this.vm.currentMessages[this.vm.currentMessages.length - 1] &&
              msg.role === 'assistant',
            onCopyPlain: (id: string) => {
              this.vm.copyMessagePlain(id);
              this.showToast('已复制');
            },
            onCopyMarkdown: (id: string) => {
              this.vm.copyMessageMarkdown(id);
              this.showToast('已复制 Markdown');
            },
            onExportWord: (id: string) => {
              this.handleExportWord(id);
            },
            onRegenerate: (id: string) => {
              this.vm.regenerateMessage(id);
              this.refreshTick++;
            }
          })
        }
      }, (msg: Message) => msg.id)
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(20)
    .shadow({ radius: 16, color: '#14000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  buildWorkTaskCard(msg: Message) {
    Row({ space: 10 }) {
      Text('任务')
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.brand'))
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(8)
        .backgroundColor($r('app.color.raised_surface'))
      Text(msg.displayContent !== '' ? msg.displayContent : msg.content)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .lineHeight(21)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .borderRadius(14)
    .backgroundColor($r('app.color.brand_light'))
    .alignItems(VerticalAlign.Top)
  }

  // 导出消息为 Word 文档
  private handleExportWord(msgId: string): void {
    let msg: Message | null = this.findMessage(msgId);
    if (msg === null || msg.role !== 'assistant') {
      this.showToast('消息不存在');
      return;
    }
    if (msg.content.trim() === '') {
      this.showToast('消息内容为空');
      return;
    }
    this.showToast('正在导出…');
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    DocxExporter.exportToDocx(context, msg.content, 'Guncat Work 对话导出').then((fileName: string) => {
      this.showToast('已导出 ' + fileName);
    }).catch((error: Error) => {
      this.showToast('导出失败: ' + error.message);
    });
  }

  private findMessage(id: string): Message | null {
    let msgs: Message[] = this.vm.currentMessages;
    for (let i: number = 0; i < msgs.length; i++) {
      if (msgs[i].id === id) {
        return msgs[i];
      }
    }
    return null;
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
    .layoutWeight(1)
    .height(34)
    .padding({ left: 10, right: 10 })
    .constraintSize({ minWidth: 108 })
    .borderRadius(17)
    .backgroundColor($r('app.color.raised_surface'))
    .shadow({ radius: 12, color: '#14000000', offsetX: 0, offsetY: 3 })
    .margin({ right: 8 })
    .enabled(!this.vm.isStreaming && !this.vm.isParsing && !this.isListening)
    .bindMenu(this.buildModelProfileMenu(), { placement: Placement.Top })
  }

  @Builder
  private buildModelProfileMenu() {
    Menu() {
      ForEach(this.vm.apiProfiles, (profile: ApiProfile) => {
        MenuItem() {
          Row() {
            Text(profile.name)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(48)
        .selected(profile.id === this.vm.currentApiProfileId)
        .onChange(() => {
          this.vm.selectApiProfile(profile.id);
          this.refreshTick++;
        })
      }, (profile: ApiProfile) => profile.id)
    }
    .width(240)
    .borderRadius(18)
    .backgroundColor($r('app.color.surface'))
    .padding(6)
    .shadow({ radius: 16, color: '#1A000000', offsetX: 0, offsetY: 6 })
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
    // 工作模式: 上传直接进入沙箱工作区, 不作为聊天附件
    if (this.vm.workMode) {
      await this.vm.uploadToWorkspace();
      this.refreshTick++;
      return;
    }
    await this.vm.pickAndParseFiles();
    this.rebuildPreviewItems();
    this.refreshTick++;
  }

  // "工作模式"胶囊上方的工作区弹层
  @Builder
  buildWorkspacePopup() {
    WorkspaceBar({
      vm: this.vm,
      onUpload: () => {
        this.handleWorkspaceUpload();
      },
      onExport: () => {
        this.handleWorkspaceExport();
      }
    })
  }

  // 工作区面板: 上传
  private handleWorkspaceUpload(): void {
    this.vm.uploadToWorkspace().then(() => {
      this.refreshTick++;
    });
  }

  // 工作区面板: 打包导出 zip
  private handleWorkspaceExport(): void {
    if (this.vm.workspaceFiles.length === 0) {
      this.showToast('工作区为空, 无可导出内容');
      return;
    }
    this.showToast('正在打包工作区...');
    this.vm.exportWorkspaceZip().then((fileName: string) => {
      this.showToast('已导出 ' + fileName);
    }).catch((error: Error) => {
      this.showToast('导出失败: ' + error.message);
    });
  }

  // 快捷拍照: 系统相机拍照后加入附件
  private async handleCameraCapture(): Promise<void> {
    if (this.vm.isStreaming || this.vm.isParsing || this.isListening) {
      return;
    }
    try {
      await this.vm.capturePhoto();
    } catch (error) {
      let err: Error = error as Error;
      this.showToast('拍照失败: ' + err.message);
    }
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
