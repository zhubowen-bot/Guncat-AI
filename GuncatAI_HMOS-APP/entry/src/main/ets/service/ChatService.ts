// ChatService: 真正的 SSE 流式双协议, 对齐 web 版本 streamChat
//  - provider !== 'volcano' → Chat Completions (/chat/completions)
//  - provider === 'volcano' → Responses API    (/responses)
import { http } from '@kit.NetworkKit';
import { ApiConfig } from '../model/ApiConfig';
import { Agent } from '../model/Agent';
import { Message } from '../model/Message';
import { StreamCallbacks, AbortSignal } from '../common/Types';
import { Constants } from '../common/Constants';
import { util } from '@kit.ArkTS';

class StreamAccumulator {
  buffer: ArrayBuffer = new ArrayBuffer(0);
  decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  fullContent: string = '';

  append(data: ArrayBuffer): string {
    let newBuffer: ArrayBuffer = new ArrayBuffer(this.buffer.byteLength + data.byteLength);
    let src: Uint8Array = new Uint8Array(this.buffer);
    let add: Uint8Array = new Uint8Array(data);
    let dst: Uint8Array = new Uint8Array(newBuffer);
    dst.set(src, 0);
    dst.set(add, this.buffer.byteLength);
    this.buffer = newBuffer;
    return this.decoder.decodeToString(add, { stream: true });
  }
}

function buildChatCompletionsBody(config: ApiConfig, agent: Agent | null,
  history: Message[], userText: string,
  thinkingEnabled: boolean): Record<string, Object> {
  let messages: Record<string, string>[] = [];
  if (agent !== null && agent.systemPrompt !== '') {
    messages.push({ role: 'system', content: agent.systemPrompt });
  }
  for (let i: number = 0; i < history.length; i++) {
    let m: Message = history[i];
    if (m.content === '') {
      continue;
    }
    messages.push({ role: m.role, content: m.content });
  }
  messages.push({ role: 'user', content: userText });

  let body: Record<string, Object> = {
    model: config.model,
    messages: messages,
    stream: true
  };

  if (thinkingEnabled) {
    body['reasoning_effort'] = 'high';
  }
  if (config.temperature !== null) {
    body['temperature'] = config.temperature;
  }
  if (config.topP !== null) {
    body['top_p'] = config.topP;
  }
  if (config.maxTokens !== null) {
    body['max_tokens'] = config.maxTokens;
  }
  if (config.extraBody !== '') {
    try {
      let extra: Object = JSON.parse(config.extraBody);
      if (typeof extra === 'object' && extra !== null) {
        let keys: string[] = Object.keys(extra);
        for (let i: number = 0; i < keys.length; i++) {
          body[keys[i]] = (extra as Record<string, Object>)[keys[i]];
        }
      }
    } catch (e) {
      // 忽略非法 JSON
    }
  }
  return body;
}

function buildResponsesBody(config: ApiConfig, agent: Agent | null,
  history: Message[], userText: string,
  thinkingEnabled: boolean, webSearchEnabled: boolean): Record<string, Object> {
  let input: Record<string, string>[] = [];
  for (let i: number = 0; i < history.length; i++) {
    let m: Message = history[i];
    if (m.content === '') {
      continue;
    }
    if (m.role !== 'user' && m.role !== 'assistant') {
      continue;
    }
    input.push({ role: m.role, content: m.content });
  }
  input.push({ role: 'user', content: userText });

  let body: Record<string, Object> = {
    model: config.model,
    input: input,
    stream: true,
    store: false
  };

  if (agent !== null && agent.systemPrompt !== '') {
    body['instructions'] = agent.systemPrompt;
  }
  if (thinkingEnabled) {
    body['thinking'] = { type: 'enabled' };
  }
  if (webSearchEnabled) {
    let tool: Record<string, Object> = { type: 'web_search', max_keyword: 5 };
    body['tools'] = [tool];
  }
  if (config.temperature !== null) {
    body['temperature'] = config.temperature;
  }
  if (config.topP !== null) {
    body['top_p'] = config.topP;
  }
  if (config.maxTokens !== null) {
    body['max_output_tokens'] = config.maxTokens;
  }
  if (config.extraBody !== '') {
    try {
      let extra: Object = JSON.parse(config.extraBody);
      if (typeof extra === 'object' && extra !== null) {
        let keys: string[] = Object.keys(extra);
        for (let i: number = 0; i < keys.length; i++) {
          body[keys[i]] = (extra as Record<string, Object>)[keys[i]];
        }
      }
    } catch (e) {
      // ignore
    }
  }
  return body;
}

function extractChatCompletionsDelta(sseData: string): string {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return '';
    }
    let choices: Object = (json as Record<string, Object>)['choices'];
    if (!(choices instanceof Array) || choices.length === 0) {
      return '';
    }
    let first: Object = choices[0];
    if (typeof first !== 'object' || first === null) {
      return '';
    }
    let delta: Object = (first as Record<string, Object>)['delta'];
    if (typeof delta !== 'object' || delta === null) {
      return '';
    }
    let content: Object = (delta as Record<string, Object>)['content'];
    if (typeof content === 'string') {
      return content;
    }
    return '';
  } catch (e) {
    return '';
  }
}

function extractResponsesDelta(sseData: string): string {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return '';
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string' || type !== 'response.output_text.delta') {
      return '';
    }
    let delta: Object = (json as Record<string, Object>)['delta'];
    if (typeof delta === 'string') {
      return delta;
    }
    return '';
  } catch (e) {
    return '';
  }
}

function extractResponsesFailure(sseData: string): string {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return '';
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string' || type !== 'response.failed') {
      return '';
    }
    let resp: Object = (json as Record<string, Object>)['response'];
    if (typeof resp !== 'object' || resp === null) {
      return 'Responses API 返回失败';
    }
    let err: Object = (resp as Record<string, Object>)['error'];
    if (typeof err === 'object' && err !== null) {
      let msg: Object = (err as Record<string, Object>)['message'];
      if (typeof msg === 'string') {
        return msg;
      }
    }
    return 'Responses API 返回失败';
  } catch (e) {
    return '';
  }
}

export class ChatService {
  private static activeRequest: http.HttpRequest | null = null;

  static async streamChat(
    config: ApiConfig,
    agent: Agent | null,
    history: Message[],
    userText: string,
    thinkingEnabled: boolean,
    webSearchEnabled: boolean,
    callbacks: StreamCallbacks,
    abortSignal: AbortSignal
  ): Promise<void> {
    let isResponses: boolean = config.provider === 'volcano';
    let path: string = isResponses ? Constants.RESPONSES_PATH : Constants.CHAT_COMPLETIONS_PATH;
    let url: string = config.baseUrl.replace(/\/+$/, '') + path;

    let body: Record<string, Object>;
    if (isResponses) {
      body = buildResponsesBody(config, agent, history, userText, thinkingEnabled, webSearchEnabled);
    } else {
      body = buildChatCompletionsBody(config, agent, history, userText, thinkingEnabled);
    }
    let bodyStr: string = JSON.stringify(body);

    let httpRequest: http.HttpRequest = http.createHttp();
    ChatService.activeRequest = httpRequest;
    let acc: StreamAccumulator = new StreamAccumulator();
    let lineBuffer: string = '';
    let receivedAnyData: boolean = false;
    let aborted: boolean = false;
    let failedMsg: string = '';
    // 对齐 web 版本: SSE 解析出一个 delta 就立即 onToken 全量累积,
    // UI 端 50ms 节流刷新. 不做应用层字符拆分 (避免 setTimeout 队列过长 OOM)

    try {
      await new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
        httpRequest.on('dataReceive', (data: ArrayBuffer) => {
          if (abortSignal.aborted) {
            return;
          }
          receivedAnyData = true;
          let chunk: string = acc.append(data);
          lineBuffer += chunk;
          let lines: string[] = lineBuffer.split('\n');
          if (lineBuffer.endsWith('\n')) {
            lineBuffer = '';
          } else {
            lineBuffer = lines.pop() as string;
          }
          for (let i: number = 0; i < lines.length; i++) {
            let line: string = lines[i];
            let trimmed: string = line.trim();
            if (trimmed === '' || trimmed === Constants.SSE_DONE_TOKEN) {
              continue;
            }
            if (!trimmed.startsWith(Constants.SSE_DATA_PREFIX)) {
              continue;
            }
            let sseData: string = trimmed.substring(Constants.SSE_DATA_PREFIX.length);
            if (isResponses) {
              let fail: string = extractResponsesFailure(sseData);
              if (fail !== '') {
                failedMsg = fail;
                reject(new Error(fail));
                return;
              }
              let delta: string = extractResponsesDelta(sseData);
              if (delta !== '') {
                acc.fullContent += delta;
                callbacks.onToken(delta);
              }
            } else {
              let delta: string = extractChatCompletionsDelta(sseData);
              if (delta !== '') {
                acc.fullContent += delta;
                callbacks.onToken(delta);
              }
            }
          }
        });

        httpRequest.on('dataEnd', () => {
          if (lineBuffer !== '') {
            let trimmed: string = lineBuffer.trim();
            if (trimmed.startsWith(Constants.SSE_DATA_PREFIX)) {
              let sseData: string = trimmed.substring(Constants.SSE_DATA_PREFIX.length);
              if (sseData !== Constants.SSE_DONE_TOKEN) {
                if (isResponses) {
                  let delta: string = extractResponsesDelta(sseData);
                  if (delta !== '') {
                    acc.fullContent += delta;
                    callbacks.onToken(delta);
                  }
                } else {
                  let delta: string = extractChatCompletionsDelta(sseData);
                  if (delta !== '') {
                    acc.fullContent += delta;
                    callbacks.onToken(delta);
                  }
                }
              }
            }
            lineBuffer = '';
          }
          resolve();
        });

        httpRequest.requestInStream(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + config.apiKey
          },
          extraData: bodyStr,
          connectTimeout: 30000,
          readTimeout: 180000,
          usingProtocol: http.HttpProtocol.HTTP1_1
        }).then((code: number) => {
          if (abortSignal.aborted) {
            return;
          }
          if (code < 200 || code >= 300) {
            let msg: string = '';
            if (code === 401) {
              msg = 'API Key 无效，请检查设置';
            } else if (code === 429) {
              msg = '请求过于频繁，请稍后再试';
            } else if (code >= 400 && code < 500) {
              msg = 'API 请求错误 (' + code + ')，请检查配置';
            } else if (code >= 500) {
              msg = '服务器错误 (' + code + ')，请稍后再试';
            } else {
              msg = '请求失败，状态码: ' + code;
            }
            reject(new Error(msg));
          }
        }).catch((err: Error) => {
          if (abortSignal.aborted) {
            // 当 abort 导致 requestInStream 抛错时 resolve, 让 promise 得以完成, finally 得以执行
            resolve();
            return;
          }
          if (!receivedAnyData) {
            reject(err);
          }
        });
      });
    } catch (e) {
      let err: Error = e as Error;
      if (abortSignal.aborted) {
        aborted = true;
      } else {
        if (failedMsg === '' && err.message !== undefined) {
          failedMsg = err.message;
        }
        if (failedMsg === '') {
          failedMsg = '请求失败';
        }
        callbacks.onError(failedMsg);
      }
    } finally {
      if (abortSignal.aborted) {
        aborted = true;
      }
      ChatService.activeRequest = null;
      try {
        httpRequest.off('dataReceive');
        httpRequest.off('dataEnd');
        httpRequest.destroy();
      } catch (e) {
        // ignore
      }
      if (!aborted) {
        callbacks.onDone(acc.fullContent);
      }
    }
  }

  static abort(): void {
    let req: http.HttpRequest | null = ChatService.activeRequest;
    if (req !== null) {
      try {
        req.destroy();
      } catch (e) {
        // ignore
      }
      ChatService.activeRequest = null;
    }
  }
}
