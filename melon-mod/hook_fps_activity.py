from pathlib import Path
import re

targets = []
for p in Path('decoded').rglob('*.smali'):
    name = str(p)
    if 'UnityPlayerActivity' in name or p.name == 'UnityPlayerActivity.smali':
        targets.append(p)

if not targets:
    for p in Path('decoded/smali').rglob('*Activity*.smali'):
        t = p.read_text(errors='ignore')
        if 'UnityPlayer' in t:
            targets.append(p)

print('candidates', [str(p) for p in targets[:8]])
hooked = False
for p in targets:
    t = p.read_text(errors='ignore')
    if 'MelonFpsOverlay' in t:
        print('already hooked', p)
        hooked = True
        break
    pattern = re.compile(
        r'(\x2emethod\s+(?:public|protected)\s+onCreate\(Landroid/os/Bundle;\)V[\s\S]*?'
        r'invoke-super\s+\{([^}]+)\},\s*L[^;]+;->onCreate\(Landroid/os/Bundle;\)V)'.replace('\\x2e', '.'),
        re.M,
    )
    pattern = re.compile(
        r'(\.method\s+(?:public|protected)\s+onCreate\(Landroid/os/Bundle;\)V[\s\S]*?'
        r'invoke-super\s+\{([^}]+)\},\s*L[^;]+;->onCreate\(Landroid/os/Bundle;\)V)',
        re.M,
    )
    m = pattern.search(t)
    if not m:
        continue
    regs = m.group(2)
    this_reg = regs.split(',')[0].strip()
    inject = (
        '\n    invoke-static {' + this_reg +
        '}, Lcom/studio27/melonmod/MelonFpsOverlay;->install(Landroid/app/Activity;)V\n'
    )
    t = t[: m.end()] + inject + t[m.end() :]
    p.write_text(t)
    print('hooked FPS into', p, 'reg', this_reg)
    hooked = True
    break

if not hooked:
    print('WARNING: could not hook FPS overlay')
