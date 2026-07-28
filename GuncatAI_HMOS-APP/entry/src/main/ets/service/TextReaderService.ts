import { TextReader } from '@kit.SpeechKit';
import { common } from '@kit.AbilityKit';

// HarmonyOS Speech Kit 朗读服务。
export class TextReaderService {
  private static initialized: boolean = false;

  private static async ensureInitialized(context: common.UIAbilityContext): Promise<void> {
    if (TextReaderService.initialized) {
      return;
    }
    let readerParam: TextReader.ReaderParam = {
      isVoiceBrandVisible: false
    };
    await TextReader.init(context, readerParam);
    TextReaderService.initialized = true;
  }

  static async read(context: common.UIAbilityContext, id: string, text: string): Promise<void> {
    if (text.trim() === '') {
      return;
    }
    await TextReaderService.ensureInitialized(context);
    try {
      await TextReader.stop();
    } catch (e) {
      // 当前没有朗读任务时 stop 可能失败，不影响启动新任务。
    }
    let readInfo: TextReader.ReadInfo = {
      id: id,
      title: {
        text: 'AI 回复',
        isClickable: false
      },
      bodyInfo: text
    };
    await TextReader.start([readInfo], id);
  }

  static async stop(): Promise<void> {
    if (!TextReaderService.initialized) {
      return;
    }
    try {
      await TextReader.stop();
    } catch (e) {
      // ignore
    }
  }
}
