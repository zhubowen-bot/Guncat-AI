// Guncat Work 6.1 核心逻辑测试: PathMatcher / DiffUtil / EditCore / FileSearchCore
// 运行: node setup.mjs && node test-core.mjs (Node ≥ 22.6 原生 TS strip)
import { PathMatcher } from './gen/PathMatcher.ts';
import { DiffUtil, FileDiff } from './gen/DiffUtil.ts';
import { EditCore } from './gen/EditCore.ts';
import { FileSearchCore, GrepOptions } from './gen/FileSearchCore.ts';

let passed = 0;
let failed = 0;

function check(name, cond) {
  if (cond) {
    passed++;
    console.log('  OK ' + name);
  } else {
    failed++;
    console.log('  FAIL: ' + name);
  }
}

// ===== PathMatcher =====
console.log('[PathMatcher]');
const m = (pattern, path) => PathMatcher.matchAny(path, PathMatcher.compileList(pattern, null));

check('**/*.csv 命中根文件', m('**/*.csv', 'a.csv'));
check('**/*.csv 命中深层', m('**/*.csv', 'x/y/z.csv'));
check('**/*.csv 不命中其他扩展', !m('**/*.csv', 'a/b.csv.txt'));
check('* 段内不跨目录', !m('*.md', 'a/b.md'));
check('*.md 命中同级', m('*.md', 'README.md'));
check('assets/*.svg 命中', m('assets/*.svg', 'assets/icon.svg'));
check('assets/*.svg 不命中子目录', !m('assets/*.svg', 'assets/sub/icon.svg'));
check('{docx,xlsx} 分支', m('output/{docx,xlsx}/*.docx', 'output/docx/r.docx'));
check('{docx,xlsx} 分支排除', !m('output/{docx,xlsx}/*', 'output/csv/r.csv'));
check('? 单字符', m('?at.txt', 'cat.txt') && !m('?at.txt', 'chat.txt'));
check('[ab] 字符类', m('[ab].txt', 'b.txt') && !m('[ab].txt', 'c.txt'));
check('默认大小写不敏感', m('DATA/*.CSV', 'data/x.csv'));
check('点号转义(不按正则)', !m('a.txt', 'aXtxt'));

// ===== DiffUtil =====
console.log('[DiffUtil]');
{
  const old1 = 'line1\nline2\nline3';
  const new1 = 'line1\nline2-changed\nline3';
  const d1 = DiffUtil.computeFileDiff(old1, new1, 'a.txt', 3);
  check('单处修改 adds=1', d1.adds === 1);
  check('单处修改 dels=1', d1.dels === 1);
  check('生成一个 hunk', d1.hunks.length === 1);
  check('hunk 含上下文行', d1.hunks[0].lines.length >= 3);
  const plain = DiffUtil.renderPlain(d1);
  check('渲染含 + 行', plain.indexOf('+ line2-changed') !== -1);
  check('渲染含 - 行', plain.indexOf('- line2') !== -1);

  const same = DiffUtil.computeFileDiff(old1, old1.slice(), 'a.txt', 3);
  check('相同文本无 hunk', same.hunks.length === 0 && same.adds === 0 && same.dels === 0);

  const old2 = 'a\nb\nc\nd\ne\nf';
  const new2 = 'A\nb\nc\nd\ne\nF';
  const d2 = DiffUtil.computeFileDiff(old2, new2, 'x', 1);
  check('两处远距修改产生两个 hunk', d2.hunks.length === 2);

  // 序列化往返(meta 持久化 → UI 重放)
  const round = FileDiff.fromJson(JSON.parse(JSON.stringify(d1.toJsonObject())));
  check('meta 序列化往返 adds 一致', round.adds === d1.adds && round.dels === d1.dels);
  check('meta 序列化往返行数一致',
    round.hunks.length === d1.hunks.length &&
    round.hunks[0].lines.length === d1.hunks[0].lines.length);
  check('meta 往返行文本一致', round.hunks[0].lines[1].text === d1.hunks[0].lines[1].text);

  // 插入 diff(对应 str_replace_editor insert)
  const d3 = DiffUtil.computeFileDiff('a\nc', 'a\nb\nc', 'x', 0);
  check('纯插入 adds=1 dels=0', d3.adds === 1 && d3.dels === 0);
}

// ===== EditCore =====
console.log('[EditCore]');
{
  // str_replace 基础语义
  const r1 = EditCore.apply('a\nb\nc', 'b', 'B', false);
  check('唯一替换成功', r1.ok && r1.status === 'ok' && r1.newText === 'a\nB\nc');
  const r2 = EditCore.apply('abc', 'x', 'y', false);
  check('未找到返回 not_found', !r2.ok && r2.status === 'not_found');
  const r3 = EditCore.apply('xa\nxb', 'x', 'Y', false);
  check('多处匹配返回 multiple 且带次数', !r3.ok && r3.status === 'multiple' && r3.matchCount === 2);
  const r4 = EditCore.apply('xa\nxb', 'x', 'Y', true);
  check('replace_all 全部替换', r4.ok && r4.newText === 'Ya\nYb');
  const r5 = EditCore.apply('a\nb\nc', 'b\n', '', false);
  check('带换行的空替换删除整行', r5.ok && r5.newText === 'a\nc');
  const r6 = EditCore.apply('aaaa', 'aa', 'b', false);
  check('非重叠计数 multiple=2', !r6.ok && r6.status === 'multiple' && r6.matchCount === 2);
  const r7 = EditCore.apply('xind', 'ind', 'y', false);
  check('子串匹配不锚定行首', r7.ok && r7.newText === 'xy');
  const r8 = EditCore.apply('Apple', 'apple', 'x', false);
  check('大小写严格', !r8.ok && r8.status === 'not_found');
  const r9 = EditCore.apply('a  b', 'a b', 'x', false);
  check('空白逐字符严格', !r9.ok && r9.status === 'not_found');

  // 换行风格自适应
  const c1 = EditCore.apply('a\r\nb\r\nc', 'a\nb', 'X', false);
  check('CRLF 文件接受 LF 多行 old_string', c1.ok && c1.newText === 'X\r\nc');
  const c2 = EditCore.apply('a\r\nb\r\nc', 'b', 'X\nY', false);
  check('CRLF 文件新文本换行自动对齐', c2.ok && c2.newText === 'a\r\nX\r\nY\r\nc');
  const c3 = EditCore.apply('a\nb', 'a\r\nb', 'X', false);
  check('LF 文件接受 CRLF old_string', c3.ok && c3.newText === 'X');
  const c4 = EditCore.apply('a\nb\nc', 'b', 'X\nY', false);
  check('LF 文件新文本保持 LF', c4.ok && c4.newText === 'a\nX\nY\nc');
  const c5 = EditCore.apply('a\r\nb', 'a\nb', 'a\nb', false);
  check('换行归一后等价内容判 no_change', !c5.ok && c5.status === 'no_change');
  const c6 = EditCore.apply('a\r\nb\r\nc', 'a\r\nb\r\nc', '', false);
  check('CRLF 内容原样匹配可整段删除', c6.ok && c6.newText === '');

  // insertLines
  const i1 = EditCore.insertLines('a\nc', 1, 'b');
  check('LF 中部插入', i1.ok && i1.newText === 'a\nb\nc');
  const i2 = EditCore.insertLines('a\nb', 0, 'x');
  check('LF 首部插入', i2.ok && i2.newText === 'x\na\nb');
  const i3 = EditCore.insertLines('a\nb', 2, 'c');
  check('LF 末尾插入', i3.ok && i3.newText === 'a\nb\nc');
  const i4 = EditCore.insertLines('a\r\nb\r\n', 1, 'X');
  check('CRLF 中部插入补 \\r', i4.ok && i4.newText === 'a\r\nX\r\nb\r\n');
  const i5 = EditCore.insertLines('a\r\nb\r\n', 0, 'X\nY');
  check('CRLF 多行插入逐行补 \\r', i5.ok && i5.newText === 'X\r\nY\r\na\r\nb\r\n');
  const i6 = EditCore.insertLines('a\r\nb', 2, 'c');
  check('CRLF 末行后插入原末行补 \\r', i6.ok && i6.newText === 'a\r\nb\r\nc');
  const i7 = EditCore.insertLines('a\nc', 1, 'b\r\nd');
  check('LF 文件插入文本剔除 CR', i7.ok && i7.newText === 'a\nb\nd\nc');
  const i8 = EditCore.insertLines('a\r\nb\r\n', 5, 'x');
  check('插入越界返回 range 且带总行数', !i8.ok && i8.status === 'range' && i8.lineTotal === 3);
}


console.log('[FileSearchCore]');

// 内存文件系统适配器(键为绝对路径, 与 fileIo 的绝对路径语义一致)
class MemFs {
  constructor(files) {
    this.files = files; // { '/a.md': 'text...' }
  }
  list(dirPath) {
    const prefix = dirPath.endsWith('/') ? dirPath : dirPath + '/';
    const seen = new Map();
    for (const p of Object.keys(this.files)) {
      if (!p.startsWith(prefix)) {
        continue;
      }
      const rest = p.substring(prefix.length);
      seen.set(rest.split('/')[0], rest.includes('/'));
    }
    return [...seen.keys()];
  }
  isDir(path) {
    const prefix = path.endsWith('/') ? path : path + '/';
    for (const p of Object.keys(this.files)) {
      if (p.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }
  readText(path, maxBytes) {
    const t = this.files[path];
    if (t === undefined) {
      return '';
    }
    return t.length > maxBytes ? '' : t;
  }
}

const fs = new MemFs({
  '/a.md': 'hello world\nfoo bar',
  '/sub/b.csv': 'id,name\n1,x\n2,y',
  '/sub/c.txt': 'say HELLO loud',
  '/logo.png': '\u0000\u0001binary'
});

{
  const hits = FileSearchCore.globSearch(fs, '/', '**/*.csv', '', ['.spill']);
  check('glob **/*.csv 命中 1 个', hits.length === 1 && hits[0].path === 'sub/b.csv');

  const hits2 = FileSearchCore.globSearch(fs, '/', 'sub/*', '', ['.spill']);
  check('glob sub/* 命中 2 个', hits2.length === 2);

  const hits3 = FileSearchCore.globSearch(fs, '/', '**/*.md', 'sub', ['.spill']);
  check('glob 限定 path 无命中', hits3.length === 0);

  const g1 = new GrepOptions();
  g1.pattern = 'hello';
  const ghits = FileSearchCore.grepSearch(fs, '/', g1, '', ['.spill']);
  check('grep 大小写不敏感命中 2 文件', ghits.length === 2);
  check('grep 命中带文件:行号', ghits.some(h => h.file === 'a.md' && h.line === 1));

  const g2 = new GrepOptions();
  g2.pattern = 'hello';
  g2.ignoreCase = false;
  const ghits2 = FileSearchCore.grepSearch(fs, '/', g2, '', ['.spill']);
  check('grep 大小写敏感仅命中原文小写', ghits2.length === 1 && ghits2[0].file === 'a.md');

  const g3 = new GrepOptions();
  g3.pattern = '\\d+';
  g3.glob = '*.csv';
  const ghits3 = FileSearchCore.grepSearch(fs, '/', g3, '', ['.spill']);
  check('grep 正则 \\d+ + glob 过滤', ghits3.length === 2 && ghits3.every(h => h.file.endsWith('.csv')));

  const g4 = new GrepOptions();
  g4.pattern = 'hello';
  g4.maxMatches = 1;
  const ghits4 = FileSearchCore.grepSearch(fs, '/', g4, '', ['.spill']);
  check('grep maxMatches 截断', ghits4.length === 1);

  const g5 = new GrepOptions();
  g5.pattern = '['; // 非法正则
  const ghits5 = FileSearchCore.grepSearch(fs, '/', g5, '', ['.spill']);
  check('非法正则返回空而非崩溃', ghits5.length === 0);

  const rendered = FileSearchCore.renderHits(ghits);
  check('renderHits 输出 file:line: text', rendered.indexOf('a.md:1: hello world') !== -1);
}

console.log('');
console.log('passed=' + passed + ' failed=' + failed);
process.exit(failed === 0 ? 0 : 1);
