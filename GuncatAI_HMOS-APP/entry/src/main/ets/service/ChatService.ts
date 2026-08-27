// ChatService: 真正的 SSE 流式三协议, 对齐 web 版本 streamChat
//  - openai-completions → Chat Completions (/chat/completions)
//  - openai-responses   → Responses API    (/responses)
//  - anthropic-messages → Anthropic Messages (/messages)
import { http } from '@kit.NetworkKit';
import { ApiConfig } from '../model/ApiConfig';
import { Agent } from '../model/Agent';
import { Message } from '../model/Message';
import { Attachment } from '../model/Attachment';
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

function getProtocol(provider: string): string {
  if (provider === 'openai-responses') {
    return 'responses';
  }
  if (provider === 'anthropic-messages') {
    return 'anthropic';
  }
  return 'completions';
}

function buildChatCompletionsBody(config: ApiConfig, agent: Agent | null,
  history: Message[], userText: string,
  thinkingEnabled: boolean, webSearchEnabled: boolean): Record<string, Object> {
  let messages: Record<string, Object>[] = [];
  if (agent !== null && agent.systemPrompt !== '') {
    messages.push({ role: 'system', content: agent.systemPrompt });
  }
  for (let i: number = 0; i < history.length; i++) {
    let m: Message = history[i];
    if (m.content === '') {
      continue;
    }
    if (m.role !== 'user' && m.role !== 'assistant') {
      continue;
    }
    if (m.role === 'user' && m.attachments.length > 0) {
      let contentParts: Record<string, Object>[] = [];
      if (m.content !== '') {
        contentParts.push({ type: 'text', text: m.content });
      }
      for (let j: number = 0; j < m.attachments.length; j++) {
        let attachment: Attachment = m.attachments[j];
        if (attachment.parsedText !== '' || attachment.dataUrl === '') {
          continue;
        }
        if (attachment.type === 'image') {
          if (attachment.fileId !== '') {
            contentParts.push({
              type: 'file',
              file_id: attachment.fileId
            });
          } else {
            contentParts.push({
              type: 'image_url',
              image_url: { url: attachment.dataUrl }
            });
          }
        } else {
          if (attachment.fileId !== '') {
            contentParts.push({
              type: 'file',
              file_id: attachment.fileId
            });
          } else {
            // 兼容支持 file_url 的 OpenAI 兼容接口；不支持的提供商会忽略或报错。
            contentParts.push({
              type: 'file_url',
              file_url: { url: attachment.dataUrl }
            });
          }
        }
      }
      if (contentParts.length > 0) {
        messages.push({ role: 'user', content: contentParts });
        continue;
      }
    }
    let chatMsg: Record<string, Object> = { role: m.role, content: m.content };
    // 请求携带 tools（联网搜索）时，DeepSeek 要求回传中间 assistant 的 reasoning_content，否则多轮可能 400。
    if (m.role === 'assistant' && webSearchEnabled && m.reasoning !== '') {
      chatMsg['reasoning_content'] = m.reasoning;
    }
    messages.push(chatMsg);
  }
  let lastHistory: Message | null = history.length > 0 ? history[history.length - 1] : null;
  if (lastHistory === null || lastHistory.role !== 'user' || lastHistory.content !== userText) {
    messages.push({ role: 'user', content: userText });
  }

  let body: Record<string, Object> = {
    model: config.model,
    messages: messages,
    stream: true
  };

  if (webSearchEnabled) {
    // OpenAI 兼容 Chat Completions 服务若支持服务端搜索，可识别该工具。
    let tool: Record<string, Object> = { type: 'web_search' };
    body['tools'] = [tool];
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
  // 深度思考开关（OpenAI 兼容格式）：thinking.type 控制开关 + reasoning_effort 控制强度。
  // 放在 extraBody 合并之后，确保界面开关优先级最高。
  body['thinking'] = { type: thinkingEnabled ? 'enabled' : 'disabled' };
  if (thinkingEnabled) {
    body['reasoning_effort'] = 'high';
  }
  return body;
}

function buildResponsesBody(config: ApiConfig, agent: Agent | null,
  history: Message[], userText: string,
  thinkingEnabled: boolean, webSearchEnabled: boolean): Record<string, Object> {
  let input: Record<string, Object>[] = [];
  for (let i: number = 0; i < history.length; i++) {
    let m: Message = history[i];
    if (m.content === '') {
      continue;
    }
    if (m.role !== 'user' && m.role !== 'assistant') {
      continue;
    }
    if (m.role === 'user' && m.attachments.length > 0) {
      let contentParts: Record<string, Object>[] = [];
      contentParts.push({ type: 'input_text', text: m.content });
      for (let j: number = 0; j < m.attachments.length; j++) {
        let attachment: Attachment = m.attachments[j];
        if (attachment.parsedText !== '' || attachment.dataUrl === '') {
          continue;
        }
        if (attachment.type === 'image') {
          if (attachment.fileId !== '') {
            contentParts.push({
              type: 'input_image',
              file_id: attachment.fileId
            });
          } else {
            contentParts.push({
              type: 'input_image',
              image_url: attachment.dataUrl
            });
          }
        } else {
          // 统一发送 input_file；若服务商不支持会由服务端返回错误。
          if (attachment.fileId !== '') {
            contentParts.push({
              type: 'input_file',
              file_id: attachment.fileId
            });
          } else {
            contentParts.push({
              type: 'input_file',
              filename: attachment.name,
              file_data: attachment.dataUrl
            });
          }
        }
      }
      input.push({ role: m.role, content: contentParts });
    } else {
      input.push({ role: m.role, content: m.content });
    }
  }
  let lastHistory: Message | null = history.length > 0 ? history[history.length - 1] : null;
  if (lastHistory === null || lastHistory.role !== 'user' || lastHistory.content !== userText) {
    input.push({ role: 'user', content: userText });
  }

  let body: Record<string, Object> = {
    model: config.model,
    input: input,
    stream: true,
    store: false
  };

  if (agent !== null && agent.systemPrompt !== '') {
    body['instructions'] = agent.systemPrompt;
  }
  if (webSearchEnabled) {
    // OpenAI Responses 兼容格式；DeepSeek 与火山方舟均支持该工具。
    let tool: Record<string, Object> = { type: 'web_search' };
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
  // 深度思考开关（Responses API 格式）：reasoning.effort 控制开关，none 表示关闭。
  // 放在 extraBody 合并之后，确保界面开关优先级最高。
  body['reasoning'] = { effort: thinkingEnabled ? 'high' : 'none' };
  return body;
}

function appendAnthropicMessage(messages: Record<string, Object>[], role: string, content: Object): void {
  let last: Record<string, Object> | null = messages.length > 0 ? messages[messages.length - 1] : null;
  let lastRole: Object = last !== null ? last['role'] : null;
  if (typeof lastRole === 'string' && lastRole === role) {
    let prevContent: Object = last['content'];
    if (typeof prevContent === 'string' && typeof content === 'string') {
      last['content'] = prevContent + '\n\n' + content;
      return;
    }
    if (prevContent instanceof Array && content instanceof Array) {
      let prevArr: Object[] = prevContent as Object[];
      let addArr: Object[] = content as Object[];
      for (let i: number = 0; i < addArr.length; i++) {
        prevArr.push(addArr[i]);
      }
      return;
    }
    if (prevContent instanceof Array && typeof content === 'string') {
      let prevArr: Object[] = prevContent as Object[];
      prevArr.push({ type: 'text', text: content });
      return;
    }
    if (typeof prevContent === 'string' && content instanceof Array) {
      let merged: Object[] = [{ type: 'text', text: prevContent }];
      let addArr: Object[] = content as Object[];
      for (let i: number = 0; i < addArr.length; i++) {
        merged.push(addArr[i]);
      }
      last['content'] = merged;
      return;
    }
  }
  messages.push({ role: role, content: content });
}

function buildAnthropicBody(config: ApiConfig, agent: Agent | null,
  history: Message[], userText: string,
  thinkingEnabled: boolean, webSearchEnabled: boolean): Record<string, Object> {
  let messages: Record<string, Object>[] = [];
  for (let i: number = 0; i < history.length; i++) {
    let m: Message = history[i];
    if (m.content === '') {
      continue;
    }
    if (m.role !== 'user' && m.role !== 'assistant') {
      continue;
    }
    if (m.role === 'user' && m.attachments.length > 0) {
      let contentParts: Record<string, Object>[] = [];
      if (m.content !== '') {
        contentParts.push({ type: 'text', text: m.content });
      }
      for (let j: number = 0; j < m.attachments.length; j++) {
        let attachment: Attachment = m.attachments[j];
        if (attachment.parsedText !== '' || attachment.dataUrl === '') {
          continue;
        }
        if (attachment.type === 'image') {
          if (attachment.fileId !== '') {
            contentParts.push({
              type: 'image',
              source: { type: 'file', file_id: attachment.fileId }
            });
          } else if (attachment.dataUrl.startsWith('http://') || attachment.dataUrl.startsWith('https://')) {
            contentParts.push({
              type: 'image',
              source: { type: 'url', url: attachment.dataUrl }
            });
          } else {
            let dataUrl: string = attachment.dataUrl;
            let comma: number = dataUrl.indexOf(';base64,');
            if (comma > 0) {
              let mediaType: string = dataUrl.substring(5, comma);
              let data: string = dataUrl.substring(comma + 8);
              contentParts.push({
                type: 'image',
                source: { type: 'base64', media_type: mediaType, data: data }
              });
            }
          }
        } else {
          // 统一发送 document 块；若服务商不支持会由服务端返回错误。
          if (attachment.fileId !== '') {
            contentParts.push({
              type: 'document',
              source: { type: 'file', file_id: attachment.fileId }
            });
          } else if (attachment.dataUrl.startsWith('http://') || attachment.dataUrl.startsWith('https://')) {
            contentParts.push({
              type: 'document',
              source: { type: 'url', url: attachment.dataUrl }
            });
          } else {
            let dataUrl: string = attachment.dataUrl;
            let comma: number = dataUrl.indexOf(';base64,');
            if (comma > 0) {
              let mediaType: string = dataUrl.substring(5, comma);
              let data: string = dataUrl.substring(comma + 8);
              contentParts.push({
                type: 'document',
                source: { type: 'base64', media_type: mediaType, data: data }
              });
            }
          }
        }
      }
      if (contentParts.length > 0) {
        appendAnthropicMessage(messages, 'user', contentParts);
        continue;
      }
    }
    appendAnthropicMessage(messages, m.role, m.content);
  }
  let lastHistory: Message | null = history.length > 0 ? history[history.length - 1] : null;
  if (lastHistory === null || lastHistory.role !== 'user' || lastHistory.content !== userText) {
    appendAnthropicMessage(messages, 'user', userText);
  }

  let maxTokens: number = config.maxTokens !== null ? config.maxTokens : 4096;
  let body: Record<string, Object> = {
    model: config.model,
    messages: messages,
    stream: true,
    max_tokens: maxTokens
  };
  if (agent !== null && agent.systemPrompt !== '') {
    body['system'] = agent.systemPrompt;
  }
  if (webSearchEnabled) {
    let tool: Record<string, Object> = {
      type: 'web_search_20250305',
      name: 'web_search',
      max_uses: 5
    };
    body['tools'] = [tool];
  }
  if (config.temperature !== null) {
    body['temperature'] = config.temperature;
  }
  if (config.topP !== null) {
    body['top_p'] = config.topP;
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
  // 深度思考开关（Anthropic 兼容格式）：thinking.type 控制开关 + output_config.effort 控制强度。
  // 放在 extraBody 合并之后，确保界面开关优先级最高。
  body['thinking'] = { type: thinkingEnabled ? 'enabled' : 'disabled' };
  if (thinkingEnabled) {
    body['output_config'] = { effort: 'high' };
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

function extractAnthropicDelta(sseData: string): string {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return '';
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string' || type !== 'content_block_delta') {
      return '';
    }
    let delta: Object = (json as Record<string, Object>)['delta'];
    if (typeof delta !== 'object' || delta === null) {
      return '';
    }
    let deltaType: Object = (delta as Record<string, Object>)['type'];
    if (typeof deltaType !== 'string' || deltaType !== 'text_delta') {
      return '';
    }
    let text: Object = (delta as Record<string, Object>)['text'];
    if (typeof text === 'string') {
      return text;
    }
    return '';
  } catch (e) {
    return '';
  }
}

function extractAnthropicFailure(sseData: string): string {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return '';
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string' || type !== 'error') {
      return '';
    }
    let err: Object = (json as Record<string, Object>)['error'];
    if (typeof err === 'object' && err !== null) {
      let msg: Object = (err as Record<string, Object>)['message'];
      if (typeof msg === 'string') {
        return msg;
      }
    }
    return 'Anthropic Messages API 返回失败';
  } catch (e) {
    return '';
  }
}

// ===== 深度思考增量解析 (对齐 web 版本 extractXXXReasoning) =====

function extractChatCompletionsReasoning(sseData: string): string {
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
    // DeepSeek 使用 reasoning_content; 部分 OpenAI 兼容服务使用 reasoning
    let reasoning: Object = (delta as Record<string, Object>)['reasoning_content'];
    if (typeof reasoning === 'string') {
      return reasoning;
    }
    let reasoningAlt: Object = (delta as Record<string, Object>)['reasoning'];
    if (typeof reasoningAlt === 'string') {
      return reasoningAlt;
    }
    return '';
  } catch (e) {
    return '';
  }
}

function extractResponsesReasoning(sseData: string): string {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return '';
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string') {
      return '';
    }
    if (type !== 'response.reasoning_summary_text.delta' && type !== 'response.reasoning_text.delta') {
      return '';
    }
    let delta: Object = (json as Record<string, Object>)['delta'];
    if (typeof delta === 'string') {
      return delta;
    }
    if (delta instanceof Array) {
      let parts: string[] = [];
      let arr: Object[] = delta as Object[];
      for (let i: number = 0; i < arr.length; i++) {
        let item: Object = arr[i];
        if (typeof item === 'object' && item !== null) {
          let text: Object = (item as Record<string, Object>)['text'];
          if (typeof text === 'string') {
            parts.push(text);
          }
        }
      }
      return parts.join('');
    }
    return '';
  } catch (e) {
    return '';
  }
}

function extractAnthropicReasoning(sseData: string): string {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return '';
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string' || type !== 'content_block_delta') {
      return '';
    }
    let delta: Object = (json as Record<string, Object>)['delta'];
    if (typeof delta !== 'object' || delta === null) {
      return '';
    }
    let deltaType: Object = (delta as Record<string, Object>)['type'];
    if (typeof deltaType !== 'string' || deltaType !== 'thinking_delta') {
      return '';
    }
    let thinking: Object = (delta as Record<string, Object>)['thinking'];
    if (typeof thinking === 'string') {
      return thinking;
    }
    return '';
  } catch (e) {
    return '';
  }
}

// ===== usage 解析 (对齐 web 版本 extractXXXUsage) =====

function extractChatCompletionsUsage(sseData: string): Record<string, Object> | null {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return null;
    }
    let usage: Object = (json as Record<string, Object>)['usage'];
    if (typeof usage === 'object' && usage !== null) {
      return usage as Record<string, Object>;
    }
    return null;
  } catch (e) {
    return null;
  }
}

function extractResponsesUsage(sseData: string): Record<string, Object> | null {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return null;
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string' || type !== 'response.completed') {
      return null;
    }
    let resp: Object = (json as Record<string, Object>)['response'];
    if (typeof resp === 'object' && resp !== null) {
      let usage: Object = (resp as Record<string, Object>)['usage'];
      if (typeof usage === 'object' && usage !== null) {
        return usage as Record<string, Object>;
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}

function extractAnthropicUsage(sseData: string): Record<string, Object> | null {
  try {
    let json: Object = JSON.parse(sseData);
    if (typeof json !== 'object' || json === null) {
      return null;
    }
    let type: Object = (json as Record<string, Object>)['type'];
    if (typeof type !== 'string' || type !== 'message_delta') {
      return null;
    }
    let usage: Object = (json as Record<string, Object>)['usage'];
    if (typeof usage === 'object' && usage !== null) {
      return usage as Record<string, Object>;
    }
    return null;
  } catch (e) {
    return null;
  }
}

// 由 API 返回的 usage 派生 token 速度(tok/s)与缓存命中率(0..1);
// 只读返回值, 不做自创算法; 无对应字段时返回 -1.
function deriveStreamStats(usage: Record<string, Object> | null, elapsedMs: number): number[] {
  let speed: number = -1;
  let hit: number = -1;
  if (usage === null) {
    return [speed, hit];
  }
  let outTokens: number = -1;
  let completionTokens: Object = usage['completion_tokens'];
  if (typeof completionTokens === 'number') {
    outTokens = completionTokens as number;
  } else {
    let outputTokens: Object = usage['output_tokens'];
    if (typeof outputTokens === 'number') {
      outTokens = outputTokens as number;
    }
  }
  let hitTokens: number = -1;
  let totalTokens: number = -1;
  let hitT: Object = usage['prompt_cache_hit_tokens'];
  let missT: Object = usage['prompt_cache_miss_tokens'];
  if (typeof hitT === 'number' && typeof missT === 'number') {
    hitTokens = hitT as number;
    totalTokens = (hitT as number) + (missT as number);
  } else {
    let promptDetails: Object = usage['prompt_tokens_details'];
    if (typeof promptDetails === 'object' && promptDetails !== null) {
      let cached: Object = (promptDetails as Record<string, Object>)['cached_tokens'];
      if (typeof cached === 'number') {
        hitTokens = cached as number;
        let promptTokens: Object = usage['prompt_tokens'];
        totalTokens = typeof promptTokens === 'number' ? (promptTokens as number) : hitTokens;
      }
    } else {
      let inputDetails: Object = usage['input_tokens_details'];
      if (typeof inputDetails === 'object' && inputDetails !== null) {
        let cached: Object = (inputDetails as Record<string, Object>)['cached_tokens'];
        if (typeof cached === 'number') {
          hitTokens = cached as number;
          let inputTokens: Object = usage['input_tokens'];
          totalTokens = typeof inputTokens === 'number' ? (inputTokens as number) : hitTokens;
        }
      } else {
        let cacheRead: Object = usage['cache_read_input_tokens'];
        let cacheCreate: Object = usage['cache_creation_input_tokens'];
        let inputT: Object = usage['input_tokens'];
        if (typeof cacheRead === 'number' || typeof cacheCreate === 'number') {
          let cr: number = typeof cacheRead === 'number' ? (cacheRead as number) : 0;
          let cc: number = typeof cacheCreate === 'number' ? (cacheCreate as number) : 0;
          let inp: number = typeof inputT === 'number' ? (inputT as number) : 0;
          hitTokens = cr;
          totalTokens = cr + cc + inp;
        }
      }
    }
  }
  if (outTokens > 0 && elapsedMs > 0) {
    speed = outTokens / (elapsedMs / 1000);
  }
  if (hitTokens >= 0 && totalTokens > 0) {
    hit = hitTokens / totalTokens;
  }
  return [speed, hit];
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
    let protocol: string = getProtocol(config.provider);
    let path: string;
    if (protocol === 'responses') {
      path = Constants.RESPONSES_PATH;
    } else if (protocol === 'anthropic') {
      let trimmedBase: string = config.baseUrl.replace(/\/+$/, '');
      if (trimmedBase.endsWith('/v1') || trimmedBase.endsWith('/anthropic/v1')) {
        path = Constants.MESSAGES_PATH;
      } else if (trimmedBase === 'https://api.deepseek.com' || trimmedBase === 'http://api.deepseek.com') {
        // 兼容用户直接填 DeepSeek 主域名时自动切到 Anthropic 兼容端点
        path = Constants.ANTHROPIC_DEEPSEEK_MESSAGES_PATH;
      } else {
        path = Constants.ANTHROPIC_V1_MESSAGES_PATH;
      }
    } else {
      path = Constants.CHAT_COMPLETIONS_PATH;
    }
    let url: string = config.baseUrl.replace(/\/+$/, '') + path;

    let body: Record<string, Object>;
    if (protocol === 'responses') {
      body = buildResponsesBody(config, agent, history, userText, thinkingEnabled, webSearchEnabled);
    } else if (protocol === 'anthropic') {
      body = buildAnthropicBody(config, agent, history, userText, thinkingEnabled, webSearchEnabled);
    } else {
      body = buildChatCompletionsBody(config, agent, history, userText, thinkingEnabled, webSearchEnabled);
    }
    let bodyStr: string = JSON.stringify(body);

    let httpRequest: http.HttpRequest = http.createHttp();
    ChatService.activeRequest = httpRequest;
    let acc: StreamAccumulator = new StreamAccumulator();
    let lineBuffer: string = '';
    let receivedAnyData: boolean = false;
    let aborted: boolean = false;
    let failedMsg: string = '';
    // 深度思考累积 + 请求起始时间(用于由 usage 派生 token 速度)
    let fullReasoning: string = '';
    let startTime: number = Date.now();
    // 对齐 web 版本: SSE 解析出一个 delta 就立即 onToken 全量累积,
    // UI 端 50ms 节流刷新. 不做应用层字符拆分 (避免 setTimeout 队列过长 OOM)

    try {
      await new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
        let statusCode: number = 0;
        let dataEnded: boolean = false;
        let settled: boolean = false;
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
            if (protocol === 'responses') {
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
              let reasoning: string = extractResponsesReasoning(sseData);
              if (reasoning !== '') {
                fullReasoning += reasoning;
                callbacks.onReasoning(fullReasoning);
              }
              let usageObj: Record<string, Object> | null = extractResponsesUsage(sseData);
              if (usageObj !== null) {
                let stats: number[] = deriveStreamStats(usageObj, Date.now() - startTime);
                callbacks.onUsage(stats[0], stats[1]);
              }
            } else if (protocol === 'anthropic') {
              let fail: string = extractAnthropicFailure(sseData);
              if (fail !== '') {
                failedMsg = fail;
                reject(new Error(fail));
                return;
              }
              let delta: string = extractAnthropicDelta(sseData);
              if (delta !== '') {
                acc.fullContent += delta;
                callbacks.onToken(delta);
              }
              let reasoning: string = extractAnthropicReasoning(sseData);
              if (reasoning !== '') {
                fullReasoning += reasoning;
                callbacks.onReasoning(fullReasoning);
              }
              let usageObj: Record<string, Object> | null = extractAnthropicUsage(sseData);
              if (usageObj !== null) {
                let stats: number[] = deriveStreamStats(usageObj, Date.now() - startTime);
                callbacks.onUsage(stats[0], stats[1]);
              }
            } else {
              let delta: string = extractChatCompletionsDelta(sseData);
              if (delta !== '') {
                acc.fullContent += delta;
                callbacks.onToken(delta);
              }
              let reasoning: string = extractChatCompletionsReasoning(sseData);
              if (reasoning !== '') {
                fullReasoning += reasoning;
                callbacks.onReasoning(fullReasoning);
              }
              let usageObj: Record<string, Object> | null = extractChatCompletionsUsage(sseData);
              if (usageObj !== null) {
                let stats: number[] = deriveStreamStats(usageObj, Date.now() - startTime);
                callbacks.onUsage(stats[0], stats[1]);
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
                if (protocol === 'responses') {
                  let delta: string = extractResponsesDelta(sseData);
                  if (delta !== '') {
                    acc.fullContent += delta;
                    callbacks.onToken(delta);
                  }
                  let reasoning: string = extractResponsesReasoning(sseData);
                  if (reasoning !== '') {
                    fullReasoning += reasoning;
                    callbacks.onReasoning(fullReasoning);
                  }
                  let usageObj: Record<string, Object> | null = extractResponsesUsage(sseData);
                  if (usageObj !== null) {
                    let stats: number[] = deriveStreamStats(usageObj, Date.now() - startTime);
                    callbacks.onUsage(stats[0], stats[1]);
                  }
                } else if (protocol === 'anthropic') {
                  let delta: string = extractAnthropicDelta(sseData);
                  if (delta !== '') {
                    acc.fullContent += delta;
                    callbacks.onToken(delta);
                  }
                  let reasoning: string = extractAnthropicReasoning(sseData);
                  if (reasoning !== '') {
                    fullReasoning += reasoning;
                    callbacks.onReasoning(fullReasoning);
                  }
                  let usageObj: Record<string, Object> | null = extractAnthropicUsage(sseData);
                  if (usageObj !== null) {
                    let stats: number[] = deriveStreamStats(usageObj, Date.now() - startTime);
                    callbacks.onUsage(stats[0], stats[1]);
                  }
                } else {
                  let delta: string = extractChatCompletionsDelta(sseData);
                  if (delta !== '') {
                    acc.fullContent += delta;
                    callbacks.onToken(delta);
                  }
                  let reasoning: string = extractChatCompletionsReasoning(sseData);
                  if (reasoning !== '') {
                    fullReasoning += reasoning;
                    callbacks.onReasoning(fullReasoning);
                  }
                  let usageObj: Record<string, Object> | null = extractChatCompletionsUsage(sseData);
                  if (usageObj !== null) {
                    let stats: number[] = deriveStreamStats(usageObj, Date.now() - startTime);
                    callbacks.onUsage(stats[0], stats[1]);
                  }
                }
              }
            }
            lineBuffer = '';
          }
          dataEnded = true;
          if (statusCode !== 0 && statusCode >= 200 && statusCode < 300 && !settled) {
            settled = true;
            resolve();
          }
        });

        let headers: Record<string, string> = {
          'Content-Type': 'application/json'
        };
        if (protocol === 'anthropic') {
          let needsAnthropicBeta: boolean = false;
          for (let hi: number = 0; hi < history.length; hi++) {
            let hm: Message = history[hi];
            for (let hj: number = 0; hj < hm.attachments.length; hj++) {
              if (hm.attachments[hj].fileId !== '') {
                needsAnthropicBeta = true;
                break;
              }
            }
            if (needsAnthropicBeta) {
              break;
            }
          }
          headers['x-api-key'] = config.apiKey;
          headers['anthropic-version'] = '2023-06-01';
          headers['Accept'] = 'text/event-stream';
          if (needsAnthropicBeta) {
            headers['anthropic-beta'] = 'files-api-2025-04-14';
          }
        } else {
          headers['Authorization'] = 'Bearer ' + config.apiKey;
        }
        httpRequest.requestInStream(url, {
          method: http.RequestMethod.POST,
          header: headers,
          extraData: bodyStr,
          connectTimeout: 30000,
          readTimeout: 180000,
          usingProtocol: http.HttpProtocol.HTTP1_1
        }).then((code: number) => {
          statusCode = code;
          if (abortSignal.aborted) {
            return;
          }
          if (code < 200 || code >= 300) {
            if (!settled) {
              settled = true;
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
            return;
          }
          if (dataEnded && !settled) {
            settled = true;
            resolve();
          }
        }).catch((err: Error) => {
          if (abortSignal.aborted) {
            // 当 abort 导致 requestInStream 抛错时 resolve, 让 promise 得以完成, finally 得以执行
            if (!settled) {
              settled = true;
              resolve();
            }
            return;
          }
          if (!settled) {
            settled = true;
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
