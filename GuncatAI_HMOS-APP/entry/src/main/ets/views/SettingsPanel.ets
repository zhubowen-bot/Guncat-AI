import { ApiConfig } from '../model/ApiConfig';
import { MultimodalConfig } from '../model/MultimodalConfig';

// API 设置弹层 (对齐 web 版本 .modal / .settings)
@Component
export struct SettingsPanel {
  // @Watch: 面板从隐藏变为打开时强制把 @Prop 同步到 @State
  // aboutToAppear 在组件首次创建就跑, 那时 vm.init() 还没结束, 读到的是默认空值
  // 后续 vm.apiConfig 加载完成不会再触发 aboutToAppear, 必须靠 visible 变化时再同步一次
  @Prop @Watch('onVisibleChange') visible: boolean = false;
  @Prop @Watch('onProfileChange') initProfileId: string = '';
  @Prop initProfileName: string = '默认配置';
  @Prop profileNames: string[] = [];
  @Prop selectedProfileIndex: number = 0;
  // 父组件传入的初始值 (只读). 父级用 @State vm 传过来,
  // 每次重新打开 SettingsPanel (条件渲染导致组件重建) 时 aboutToAppear 会重新同步
  @Prop initProvider: string = 'openai-completions';
  @Prop initBaseUrl: string = '';
  @Prop initApiKey: string = '';
  @Prop initModel: string = '';
  @Prop initTemperature: string = '';
  @Prop initTopP: string = '';
  @Prop initMaxTokens: string = '';
  @Prop initExtraBody: string = '';
  @Prop initMmBaseUrl: string = '';
  @Prop initMmApiKey: string = '';
  @Prop initMmModel: string = '';
  @Prop initMmPreparseEnabled: boolean = true;
  // 工作副本 (用户可编辑). 改回 @State, 不再被父级覆盖
  @State provider: string = 'openai-completions';
  @State profileName: string = '默认配置';
  @State baseUrl: string = '';
  @State apiKey: string = '';
  @State model: string = '';
  @State temperature: string = '';
  @State topP: string = '';
  @State maxTokens: string = '';
  @State extraBody: string = '';
  @State mmBaseUrl: string = '';
  @State mmApiKey: string = '';
  @State mmModel: string = '';
  @State mmPreparseEnabled: boolean = true;
  @State advancedOpen: boolean = false;
  @State multimodalOpen: boolean = false;

  private onClose: () => void = (): void => {};
  private onSave: (name: string, api: ApiConfig, mm: MultimodalConfig) => void =
    (_name: string, _a: ApiConfig, _m: MultimodalConfig): void => {};
  private onAddProfile: () => void = (): void => {};
  private onSelectProfile: (index: number) => void = (_index: number): void => {};

  aboutToAppear(): void {
    this.syncFromInit();
  }

  onVisibleChange(): void {
    // 面板打开时 (false → true) 强制同步一次 @Prop → @State,
    // 解决 vm.init() 在组件创建之后才完成导致的初始空值问题
    if (this.visible) {
      this.syncFromInit();
    }
  }

  onProfileChange(): void {
    // @Watch 触发时，同一轮父组件刷新的其他 @Prop 可能尚未全部提交。
    // 延迟到下一帧再读取，避免表单内容总是落后当前配置一次。
    setTimeout(() => {
      this.syncFromInit();
    }, 0);
  }

  private syncFromInit(): void {
    this.profileName = this.initProfileName;
    this.provider = this.initProvider;
    this.baseUrl = this.initBaseUrl;
    this.apiKey = this.initApiKey;
    this.model = this.initModel;
    this.temperature = this.initTemperature;
    this.topP = this.initTopP;
    this.maxTokens = this.initMaxTokens;
    this.extraBody = this.initExtraBody;
    this.mmBaseUrl = this.initMmBaseUrl;
    this.mmApiKey = this.initMmApiKey;
    this.mmModel = this.initMmModel;
    this.mmPreparseEnabled = this.initMmPreparseEnabled;
  }

  build() {
    Stack() {
      // 遮罩常驻，只改变透明度，避免打开时与复杂表单同时创建。
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.modal_backdrop'))
        .opacity(this.visible ? 1 : 0)
        .animation({ duration: 180, curve: Curve.EaseOut })
        .onClick(() => {
          if (this.visible) {
            this.onClose();
          }
        })

      // 表单常驻在屏幕下方，打开时只做合成层平移。
      Column() {
          // 标题
          Row() {
            Text('API 配置')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Button() {
              Text('✕')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
            }
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor($r('app.color.raised_surface'))
            .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 2 })
            .onClick(() => {
              this.onClose();
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 18, bottom: 14 })
          .alignItems(VerticalAlign.Center)

          // 主体 (可滚动)
          Scroll() {
            Column() {
              this.buildSectionHeader('配置方案')
              Row() {
                Select(this.getProfileOptions())
                  .selected(this.selectedProfileIndex)
                  .value(this.initProfileName)
                  .fontColor($r('app.color.text_primary'))
                  .selectedOptionBgColor($r('app.color.brand_light'))
                  .selectedOptionFontColor($r('app.color.brand'))
                  .optionBgColor($r('app.color.surface'))
                  .optionFontColor($r('app.color.text_primary'))
                  .layoutWeight(1)
                  .height(44)
                  .borderRadius(14)
                  .backgroundColor($r('app.color.surface_secondary'))
                  .onSelect((index: number) => {
                    this.onSelectProfile(index);
                  })

                Button() {
                  SymbolGlyph($r('sys.symbol.plus'))
                    .fontSize(18)
                    .fontColor([$r('app.color.brand')])
                }
                .width(44)
                .height(44)
                .borderRadius(14)
                .backgroundColor($r('app.color.brand_light'))
                .margin({ left: 8 })
                .onClick(() => {
                  this.onAddProfile();
                })
              }
              .width('100%')

              this.buildSectionHeader('配置名称')
              TextInput({ placeholder: '例如：DeepSeek V4', text: this.profileName })
                .width('100%')
                .height(44)
                .borderRadius(16)
                .backgroundColor($r('app.color.surface_secondary'))
                .padding({ left: 12, right: 12 })
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_secondary'))
                .onChange((value: string) => {
                  this.profileName = value;
                })

              this.buildSectionHeader('接入方式')
              Select([
                { value: 'openai-completions' },
                { value: 'openai-responses' },
                { value: 'anthropic-messages' }
              ])
                .selected(this.getProviderIndex())
                .value(this.getProviderLabel())
                .fontColor($r('app.color.text_primary'))
                .selectedOptionBgColor($r('app.color.brand_light'))
                .selectedOptionFontColor($r('app.color.brand'))
                .optionBgColor($r('app.color.surface'))
                .optionFontColor($r('app.color.text_primary'))
                .width('100%')
                .height(44)
                .borderRadius(16)
                .backgroundColor($r('app.color.surface_secondary'))
                .onSelect((index: number) => {
                  if (index === 0) {
                    this.provider = 'openai-completions';
                  } else if (index === 1) {
                    this.provider = 'openai-responses';
                  } else if (index === 2) {
                    this.provider = 'anthropic-messages';
                  }
                })

              this.buildSectionHeader('Base URL')
              TextInput({ placeholder: this.getBaseUrlPlaceholder(), text: this.baseUrl })
                .width('100%')
                .height(44)
                .borderRadius(16)
                .backgroundColor($r('app.color.surface_secondary'))
                .padding({ left: 12, right: 12 })
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_secondary'))
                .onChange((v: string) => {
                  this.baseUrl = v;
                })

              this.buildSectionHeader('API Key')
              TextInput({ placeholder: 'sk-...', text: this.apiKey })
                .type(InputType.Password)
                .width('100%')
                .height(44)
                .borderRadius(16)
                .backgroundColor($r('app.color.surface_secondary'))
                .padding({ left: 12, right: 12 })
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_secondary'))
                .onChange((v: string) => {
                  this.apiKey = v;
                })

              this.buildSectionHeader('模型名称 / Endpoint ID')
              TextInput({ placeholder: this.getModelPlaceholder(), text: this.model })
                .width('100%')
                .height(44)
                .borderRadius(16)
                .backgroundColor($r('app.color.surface_secondary'))
                .padding({ left: 12, right: 12 })
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_secondary'))
                .onChange((v: string) => {
                  this.model = v;
                })

              // 高级参数切换
              this.buildAdvancedSection()

              // 多模态切换
              this.buildMultimodalSection()

              // 提示
              Text(this.getHint())
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .lineHeight(18)
                .width('100%')
                .margin({ top: 8 })

              Text(this.getAutoCompleteHint())
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .lineHeight(18)
                .width('100%')
                .margin({ top: 4 })

              // 保存按钮
              Button() {
                Text('保存配置')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
              }
              .width('100%')
              .height(50)
              .borderRadius(18)
              .backgroundColor($r('app.color.brand'))
              .margin({ top: 20, bottom: 24 })
              .onClick(() => {
                this.onSave(this.profileName, this.buildConfig(), this.buildMmConfig());
              })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 4, bottom: 24 })
          }
          .layoutWeight(1)
      }
      .width('100%')
      .height('92%')
      .backgroundColor($r('app.color.surface'))
      .borderRadius({ topLeft: 30, topRight: 30 })
      .shadow({ radius: 28, color: '#1F000000', offsetX: 0, offsetY: -6 })
      .position({ x: 0, y: '100%' })
      .translate({ y: this.visible ? '-100%' : '0%' })
      .opacity(this.visible ? 1 : 0)
      .animation({ duration: 260, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(this.visible ? 10 : -1)
    .hitTestBehavior(this.visible ? HitTestMode.Default : HitTestMode.None)
  }

  @Builder
  buildSectionHeader(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_secondary'))
      .width('100%')
      .margin({ top: 18, bottom: 8 })
  }

  private getProfileOptions(): SelectOption[] {
    let options: SelectOption[] = [];
    for (let i: number = 0; i < this.profileNames.length; i++) {
      options.push({ value: this.profileNames[i] });
    }
    return options;
  }

  @Builder
  buildAdvancedSection() {
    Column() {
      Row() {
        Text('高级模型参数')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Text(this.advancedOpen ? '▲' : '▼')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ top: 14, bottom: 14 })
      .margin({ top: 12 })
      .onClick(() => {
        this.advancedOpen = !this.advancedOpen;
      })

      if (this.advancedOpen) {
        Column() {
          this.buildSectionHeader('Temperature')
          TextInput({ placeholder: '例如 0.7', text: this.temperature })
            .width('100%')
            .height(44)
            .borderRadius(16)
            .backgroundColor($r('app.color.surface_secondary'))
            .padding({ left: 12, right: 12 })
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .onChange((v: string) => {
              this.temperature = v;
            })
          Text('数值越低回答越确定, 越高越随机。')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: 4 })

          this.buildSectionHeader('Top P')
          TextInput({ placeholder: '0.9', text: this.topP })
            .width('100%')
            .height(44)
            .borderRadius(16)
            .backgroundColor($r('app.color.surface_secondary'))
            .padding({ left: 12, right: 12 })
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .onChange((v: string) => {
              this.topP = v;
            })

          this.buildSectionHeader('Max Tokens')
          TextInput({ placeholder: '4096', text: this.maxTokens })
            .width('100%')
            .height(44)
            .borderRadius(16)
            .backgroundColor($r('app.color.surface_secondary'))
            .padding({ left: 12, right: 12 })
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .onChange((v: string) => {
              this.maxTokens = v;
            })

          this.buildSectionHeader('额外请求参数 (JSON)')
          TextArea({ placeholder: '{"presence_penalty": 0, "frequency_penalty": 0}', text: this.extraBody })
            .width('100%')
            .height(80)
            .borderRadius(16)
            .backgroundColor($r('app.color.surface_secondary'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .fontSize(13)
            .fontFamily('monospace')
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .onChange((v: string) => {
              this.extraBody = v;
            })
          Text('会合并到请求体中, 适合自定义 provider 专属参数。')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: 4 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: 8 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildMultimodalSection() {
    Column() {
      Row() {
        Text('多模态解析 API (可选)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Text(this.multimodalOpen ? '▲' : '▼')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ top: 14, bottom: 14 })
      .margin({ top: 12 })
      .onClick(() => {
        this.multimodalOpen = !this.multimodalOpen;
      })

      if (this.multimodalOpen) {
        Column() {
          Row() {
            Column() {
              Text('先行解析附件')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              Text(this.mmPreparseEnabled ?
                '开启后先由下方独立 API 解析，再将文本交给主模型。' :
                '关闭后图片和文档将直接传给当前接入方式的主模型。')
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .lineHeight(18)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Toggle({ type: ToggleType.Switch, isOn: this.mmPreparseEnabled })
              .selectedColor($r('app.color.brand'))
              .onChange((enabled: boolean) => {
                this.mmPreparseEnabled = enabled;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 12, top: 4 })

          Text('默认使用 GLM-4.6V-Flash（免费API调用，请在智谱官网获取API Key），推荐使用 Doubao-Seed-2.0-mini 等轻量多模态模型。')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .lineHeight(18)
            .margin({ bottom: 12 })

          if (this.mmPreparseEnabled) {
            this.buildSectionHeader('Base URL')
            TextInput({ placeholder: 'https://open.bigmodel.cn/api/paas/v4', text: this.mmBaseUrl })
              .width('100%')
              .height(44)
              .borderRadius(16)
              .backgroundColor($r('app.color.surface_secondary'))
              .padding({ left: 12, right: 12 })
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_secondary'))
              .onChange((v: string) => {
                this.mmBaseUrl = v;
              })

            this.buildSectionHeader('API Key')
            TextInput({ placeholder: '...', text: this.mmApiKey })
              .type(InputType.Password)
              .width('100%')
              .height(44)
              .borderRadius(16)
              .backgroundColor($r('app.color.surface_secondary'))
              .padding({ left: 12, right: 12 })
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_secondary'))
              .onChange((v: string) => {
                this.mmApiKey = v;
              })

            this.buildSectionHeader('模型名称')
            TextInput({ placeholder: 'glm-4.6v-flash', text: this.mmModel })
              .width('100%')
              .height(44)
              .borderRadius(16)
              .backgroundColor($r('app.color.surface_secondary'))
              .padding({ left: 12, right: 12 })
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_secondary'))
              .onChange((v: string) => {
                this.mmModel = v;
              })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: 8 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private getProviderIndex(): number {
    if (this.provider === 'openai-completions') {
      return 0;
    }
    if (this.provider === 'openai-responses') {
      return 1;
    }
    if (this.provider === 'anthropic-messages') {
      return 2;
    }
    return 0;
  }

  private getProviderLabel(): string {
    if (this.provider === 'openai-completions') {
      return 'openai-completions';
    }
    if (this.provider === 'openai-responses') {
      return 'openai-responses';
    }
    if (this.provider === 'anthropic-messages') {
      return 'anthropic-messages';
    }
    return '';
  }

  private getBaseUrlPlaceholder(): string {
    if (this.provider === 'openai-completions') {
      return 'https://api.openai.com/v1 或 https://api.deepseek.com';
    }
    if (this.provider === 'openai-responses') {
      return 'https://api.deepseek.com 或 https://ark.cn-beijing.volces.com/api/v3';
    }
    if (this.provider === 'anthropic-messages') {
      return 'https://api.anthropic.com/v1 或 https://api.deepseek.com';
    }
    return 'https://api.example.com/v1';
  }

  private getModelPlaceholder(): string {
    if (this.provider === 'openai-completions') {
      return 'deepseek-chat / deepseek-reasoner / gpt-...';
    }
    if (this.provider === 'openai-responses') {
      return 'deepseek-v4-flash / deepseek-v4-pro / ep-xxx';
    }
    if (this.provider === 'anthropic-messages') {
      return 'deepseek-v4-pro / deepseek-v4-flash / claude-...';
    }
    return 'model-name';
  }

  private getHint(): string {
    if (this.provider === 'openai-completions') {
      return '当前接入方式：OpenAI Completions，通用API接入方式，兼容大部分模型。若需要原生图片直传、联网搜索等能力，建议切换 Responses API 或 Anthropic API 选项（需查询模型支持的方式）';
    }
    if (this.provider === 'openai-responses') {
      return '当前接入方式：OpenAI Responses， 建议支持 Responses API 的模型优先选择此选项，以获得原生图片直传、联网搜索等能力';
    }
    if (this.provider === 'anthropic-messages') {
      return '当前接入方式：Anthropic Messages，建议支持 Anthropic API 的模型优先选择此选项，以获得原生图片直传、联网搜索等能力';
    }
    return 'OpenAI Completions: 填写完整的 Base URL、API Key 与模型名称。';
  }

  private getAutoCompleteHint(): string {
    if (this.provider === 'openai-completions') {
      return '自动补全 /chat/completions';
    }
    if (this.provider === 'openai-responses') {
      return '自动补全 /responses';
    }
    if (this.provider === 'anthropic-messages') {
      return '自动补全 /v1/messages 。DeepSeek 可填 https://api.deepseek.com（自动补 /anthropic/v1/messages）';
    }
    return '填写完整的 Base URL、API Key 与模型名称。';
  }

  private buildConfig(): ApiConfig {
    let cfg: ApiConfig = new ApiConfig();
    cfg.provider = this.provider;
    cfg.baseUrl = this.baseUrl.trim();
    cfg.apiKey = this.apiKey.trim();
    cfg.model = this.model.trim();
    cfg.extraBody = this.extraBody.trim();
    cfg.temperature = this.temperature !== '' ? parseFloat(this.temperature) : null;
    cfg.topP = this.topP !== '' ? parseFloat(this.topP) : null;
    cfg.maxTokens = this.maxTokens !== '' ? parseInt(this.maxTokens) : null;
    return cfg;
  }

  private buildMmConfig(): MultimodalConfig {
    let cfg: MultimodalConfig = MultimodalConfig.default();
    if (this.mmBaseUrl.trim() !== '') {
      cfg.baseUrl = this.mmBaseUrl.trim();
    }
    cfg.apiKey = this.mmApiKey.trim();
    if (this.mmModel.trim() !== '') {
      cfg.model = this.mmModel.trim();
    }
    cfg.preparseEnabled = this.mmPreparseEnabled;
    return cfg;
  }
}
