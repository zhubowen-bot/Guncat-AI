# 技能文档体量 + README 代码块配对检查
import os

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
files = [
    'entry/src/main/resources/rawfile/skills/svg/SKILL.md',
    'entry/src/main/resources/rawfile/skills/svg/reference/svg-craft.md',
    'entry/src/main/resources/rawfile/skills/svg/reference/svg-recipes.md',
    'entry/src/main/resources/rawfile/skills/ppt/SKILL.md',
    'entry/src/main/resources/rawfile/skills/ppt/reference/deck-dsl.md',
    'entry/src/main/resources/rawfile/skills/ppt/reference/design-guide.md',
    'entry/src/main/resources/rawfile/skills/ppt/reference/themes.md',
    'README.md',
    'README_EN.md',
]
lines = []
ok_all = True
for f in files:
    t = open(f, encoding='utf-8').read()
    fences = sum(1 for ln in t.splitlines() if ln.strip().startswith('```'))
    if 'README' in f:
        status = 'fences %d %s' % (fences, 'BALANCED' if fences % 2 == 0 else 'UNBALANCED!')
        if fences % 2 != 0:
            ok_all = False
    else:
        too_long = len(t) > 12000
        status = '%d chars %s (fences %d %s)' % (len(t), 'TOO LONG!' if too_long else 'OK',
                                                 fences, 'BALANCED' if fences % 2 == 0 else 'UNBALANCED!')
        if too_long or fences % 2 != 0:
            ok_all = False
    lines.append('%s -> %s' % (f, status))
lines.append('ALL OK' if ok_all else 'PROBLEMS FOUND')
open(os.path.join('test', 'pptx-harness', '_docsize.txt'), 'w', encoding='utf-8').write('\n'.join(lines))
