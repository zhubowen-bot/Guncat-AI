// Guncat Work 6.1 核心逻辑验证环境: 把纯逻辑模块移植为 Node 可运行的 .ts
// - PathMatcher / DiffUtil / FileSearchCore / Constants 不依赖任何 HarmonyOS API, 直接复制;
// - FileSearchCore 通过 FsAdapter 注入文件系统, 测试里用内存实现。
// 用法: node setup.mjs && node test-core.mjs
import { rmSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const srcDir = join(here, '..', '..', 'entry', 'src', 'main', 'ets');
const genDir = join(here, 'gen');
rmSync(genDir, { recursive: true, force: true });
mkdirSync(genDir, { recursive: true });

// 给无扩展名的相对 import 补 .ts(Node ESM 要求显式扩展名)
function withTs(spec) {
  if (spec.endsWith('.ts') || spec.endsWith('.mjs') || spec.endsWith('.js')) {
    return spec;
  }
  return spec + '.ts';
}

function port(relSrc, relDst, replaces) {
  let text = readFileSync(join(srcDir, relSrc), 'utf8');
  for (const [from, to] of replaces) {
    text = text.split(from).join(to);
  }
  text = text.replace(/(from\s+['"])(\.[^'"]*)(['"])/g, (_m, a, spec, b) => a + withTs(spec) + b);
  writeFileSync(join(genDir, relDst), text);
  console.log('port', relSrc, '->', relDst);
}

port('common/Constants.ts', 'Constants.ts', []);
port('common/PathMatcher.ts', 'PathMatcher.ts', []);
port('common/DiffUtil.ts', 'DiffUtil.ts', []);
port('common/EditCore.ts', 'EditCore.ts', []);
port('common/FileSearchCore.ts', 'FileSearchCore.ts', []);
console.log('done');
