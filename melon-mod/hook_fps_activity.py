from pathlib import Path
import re

targets = []
for p in Path('decoded').rglob('*.smali'):
    if p.name == 'UnityPlayerActivity.smali' or 'UnityPlayerActivity' in str(p):
        targets.append(p)
if not targets:
    for p in Path('decoded').rglob('*Activity*.smali'):
        t = p.read_text(errors='ignore')
        if 'UnityPlayer' in t or 'com/unity3d/player' in t:
            targets.append(p)

print('candidates', [str(p) for p in targets[:12]])
hooked = 0
for p in targets:
    t = p.read_text(errors='ignore')
    if 'MelonResOverlay' in t:
        print('already hooked', p)
        hooked += 1
        continue
    t = re.sub(
        r'\n\s*# Melon FPS overlay\n\s*invoke-static \{[^}]+\}, Lcom/studio27/melonmod/MelonFpsOverlay;->install\(Landroid/app/Activity;\)V\n',
        '\n',
        t,
    )
    pattern = re.compile(
        r'(\.(?:method)\s+(?:public|protected)\s+onCreate\(Landroid/os/Bundle;\)V[\s\S]*?'
        r'invoke-super\s+\{([^}]+)\},\s*L[^;]+;->onCreate\(Landroid/os/Bundle;\)V)',
        re.M,
    )
    m = pattern.search(t)
    if not m:
        print('no onCreate match in', p)
        continue
    regs = m.group(2)
    this_reg = regs.split(',')[0].strip()
    inject = (
        f"\n\n    # Melon resolution overlay\n"
        f"    invoke-static {{{this_reg}}}, Lcom/studio27/melonmod/MelonResOverlay;->install(Landroid/app/Activity;)V\n"
    )
    t = t[: m.end()] + inject + t[m.end() :]
    p.write_text(t)
    print('hooked Res into', p, 'reg', this_reg)
    hooked += 1

if hooked == 0:
    print('WARNING: could not hook Res overlay')
else:
    print(f'Res hook ok ({hooked} files)')
