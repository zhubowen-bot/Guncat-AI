// SubagentService: subagent 工具 —— 进程内嵌套代理(对齐 DeepSeek Harness subagent 的进程内形态)
// 子代理与父任务共享同一沙箱工作区, 拥有除自身/交互类之外的全部工具, 独立上下文运行
// 一个受限步数的完整 Agent Loop, 结束后把最终报告作为工具结果交还父任务。
// 通过 hook 注入 WorkFileService(规避循环导入): ChatViewModel.init 时调用 SubagentService.init()。
import { common } from '@kit.AbilityKit';
import { AgentLoopService, LoopMessage, LoopTurnCallbacks, LoopTurnResult } from './AgentLoopService.ts';
import { WorkFileService, ToolExecResult } from './WorkFileService.ts';
import { SpillStore } from './SpillStore.ts';
import { ToolCallRecord } from './ToolCallRecord.ts';
import { ApiConfig } from './ApiConfig.ts';
import { AbortSignal } from './Types.ts';
import { Constants } from './Constants.ts';

export class SubagentService {
  // 工具执行器(由宿主 ChatViewModel 注入的 .ets 实现, 规避 TS→ArkTS 导入限制)
  private static toolExecutor: ((context: common.UIAbilityContext, convId: string,
    name: string, argsJson: string) => Promise<ToolExecResult>) | null = null;
  // 运行期配置引用(由宿主注入: API 配置与思考开关与父任务一致)
  private static apiConfig: ApiConfig | null = null;
  private static thinkingRef: boolean = true;
  private static effortRef: string = 'high';

  // 宿主(ChatViewModel)在 init/每次任务开始时注入运行配置与工具执行器
  static bind(config: ApiConfig, thinkingEnabled: boolean, reasoningEffort: string,
    toolExecutor: (context: common.UIAbilityContext, convId: string,
      name: string, argsJson: string) => Promise<ToolExecResult>): void {
    SubagentService.apiConfig = config;
    SubagentService.thinkingRef = thinkingEnabled;
    SubagentService.effortRef = reasoningEffort;
    SubagentService.toolExecutor = toolExecutor;
    if (WorkFileService.subagentHook === null) {
      WorkFileService.subagentHook = SubagentService.run;
    }
  }

  // 子代理系统提示词: 复用主提示词, 追加子代理职责与收尾纪律
  private static buildSubagentPrompt(): string {
    let base: string = AgentLoopService.buildWorkSystemPrompt();
    let extra: string[] = [];
    extra.push('');
    extra.push('# 子代理模式(当前生效)');
    extra.push('- 你是一个被主代理派生的子代理, 正在独立完成一个分配的子任务; 用户看不到你的过程。');
    extra.push('- 不要向用户提问(没有交互通道); 依赖不足时基于合理假设推进, 并在报告中写明假设。');
    extra.push('- 完成子任务后, 输出一份自包含的最终报告(结论 + 关键过程 + 产出文件路径), 报告即工具结果, 主代理只能看到它。');
    extra.push('- 与主代理通过工作区文件交接: 产出写入工作区相对路径, 报告中列出这些路径。');
    extra.push('- 不要使用 todo_write(避免与主代理的清单互相覆盖); 也无法创建子代理或向用户提问。');
    return base + '\n' + extra.join('\n');
  }

  // 子代理工具面: 从全量工具定义中排除自身(防递归)与交互/调度类(无宿主通道)
  private static excludedTools(): string[] {
    return ['subagent', 'ask_user_question',
      'schedule_create', 'schedule_delete', 'schedule_list',
      'goal_create', 'goal_update', 'todo_write'];
  }

  private static filteredToolDefs(): Record<string, Object>[] {
    let all: Record<string, Object>[] = WorkFileService.toolDefs();
    let excluded: string[] = SubagentService.excludedTools();
    let out: Record<string, Object>[] = [];
    for (let i: number = 0; i < all.length; i++) {
      let nameObj: Object = all[i]['name'];
      let name: string = typeof nameObj === 'string' ? nameObj as string : '';
      if (excluded.indexOf(name) === -1) {
        out.push(all[i]);
      }
    }
    return out;
  }

  // 执行子任务; 返回作为工具结果送回父任务的文本
  private static async run(context: common.UIAbilityContext, convId: string,
    description: string, prompt: string): Promise<ToolExecResult> {
    let config: ApiConfig | null = SubagentService.apiConfig;
    if (config === null) {
      return SubagentService.failResult('子代理尚未绑定模型配置');
    }
    let abortSignal: AbortSignal = new AbortSignal();
    let messages: LoopMessage[] = [];
    messages.push(LoopMessage.system(SubagentService.buildSubagentPrompt()));
    messages.push(LoopMessage.user('【子任务】' + description + '\n\n【执行指令】\n' + prompt));
    let finalText: string = '';
    let stepsUsed: number = 0;
    try {
      for (let step: number = 0; step < Constants.WORK_SUBAGENT_MAX_STEPS; step++) {
        if (abortSignal.aborted) {
          break;
        }
        let callbacks: LoopTurnCallbacks = new LoopTurnCallbacks();
        let turn: LoopTurnResult = await AgentLoopService.runTurnWithRetry(
          config, messages, SubagentService.thinkingRef, SubagentService.effortRef, false,
          callbacks, abortSignal, true, 2, SubagentService.filteredToolDefs());
        stepsUsed = step + 1;
        let calls: ToolCallRecord[] = turn.toolCalls;
        if (calls.length === 0) {
          finalText = turn.content;
          break;
        }
        // 执行工具(全部顺序执行; 子代理过程不进入 UI 时间线)
        let loopMsg: LoopMessage = LoopMessage.assistant(turn.content, calls);
        for (let i: number = 0; i < calls.length; i++) {
          if (abortSignal.aborted) {
            calls[i].result = '(子代理被中断, 无结果)';
            calls[i].isError = true;
            continue;
          }
          let execStart: number = Date.now();
          let exec: ToolExecResult = await SubagentService.runTool(
            context, convId, calls[i].name, calls[i].argsJson);
          calls[i].durationMs = Date.now() - execStart;
          calls[i].isError = !exec.ok;
          calls[i].result = SubagentService.capResult(context, convId, exec.output,
            calls[i].name, execStart);
        }
        messages.push(loopMsg);
      }
    } catch (e) {
      let err: Error = e as Error;
      let msg: string = err.message !== undefined ? err.message : '子代理执行失败';
      if (finalText === '') {
        return SubagentService.failResult('子代理执行失败(' + msg + '), 已运行 ' +
          stepsUsed.toString() + ' 步');
      }
    }
    if (finalText.trim() === '') {
      return SubagentService.failResult('子代理在 ' + stepsUsed.toString() +
        ' 步内未产出最终报告(可能被截断), 可拆小任务重试');
    }
    let header: string = '【子代理报告】(' + description + ' · ' + stepsUsed.toString() + ' 步)\n\n';
    let out: ToolExecResult = new ToolExecResult();
    out.ok = true;
    out.output = header + finalText;
    return out;
  }

  // 工具执行(经宿主注入的执行器; 未注入时全部报错)
  private static async runTool(context: common.UIAbilityContext, convId: string,
    name: string, argsJson: string): Promise<ToolExecResult> {
    let executor = SubagentService.toolExecutor;
    if (executor === null) {
      return SubagentService.failResult('子代理工具执行器尚未注入');
    }
    return await executor(context, convId, name, argsJson);
  }

  // 工具结果截断 + 溢出暂存(与主循环 applyToolResult 同策略, 简化为独立实现)
  private static capResult(context: common.UIAbilityContext, convId: string,
    output: string, toolName: string, execStart: number): string {
    if (output.length <= Constants.WORK_RESULT_MAX_CHARS) {
      return output;
    }
    let root: string = WorkFileService.workspaceRoot(context, convId);
    let label: string = 'subagent_' + toolName + '_' + execStart.toString();
    let spillRel: string = SpillStore.save(root, label, output);
    return SpillStore.truncateWithLocator(output, spillRel);
  }

  private static failResult(msg: string): ToolExecResult {
    let r: ToolExecResult = new ToolExecResult();
    r.ok = false;
    r.output = 'ERROR: ' + msg;
    return r;
  }
}
