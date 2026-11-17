from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
RET = bytes([0xC0, 0x03, 0x5F, 0xD6])
NOP = bytes.fromhex('1f2003d5')

for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off + 4] = RET
    print('RET', name)

col_off = 0x21557C4

# Shake force limit 30 -> 6.0
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off + 4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    new = (0x1E27D001 & ~0x001FE000) | (0x18 << 13)
    data[insn_off:insn_off + 4] = struct.pack('<I', new)
    print('shake limit -> 6.0')
else:
    print(f'WARNING shake fmov {old:08x}')

# Bypass shouldShake
data[col_off + 0x114:col_off + 0x118] = NOP
print('shouldShake bypassed')

# Shake intensity: SetShake mul 1.0 -> 1.5
shake_off = 0x2108528
fmov_off = shake_off + 4
fmov = int.from_bytes(data[fmov_off:fmov_off + 4], 'little')
new_f = (0x1E2E1002 & ~0x001FE000) | (0x78 << 13)  # fmov s2, #1.5
data[fmov_off:fmov_off + 4] = struct.pack('<I', new_f)
print(f'SetShake intensity mul -> 1.5 (was {fmov:08x})')

# ============================================================
# NUCLEAR RESOLUTION: CreateRenderTextureDescriptor +0x38
# was: mov v8.16b, v0.16b  (s8 = renderScale argument)
# now: fmov s8, #0.5       (always half internal RT scale)
# Width/height later do: pixel * s8  -> half res targets.
# Runtime JNI can rewrite this insn for other tiers.
# ============================================================
CRTD = 0x42C0824
scale_insn = CRTD + 0x38
cur = int.from_bytes(data[scale_insn:scale_insn + 4], 'little')
print(f'CRTD+0x38 before: {cur:08x}')
if cur == 0x4EA01C08:
    # fmov s8, #0.5
    data[scale_insn:scale_insn + 4] = struct.pack('<I', 0x1E2E1008)
    print('CRTD renderScale FORCED to 0.5 (fmov s8, #0.5)')
else:
    print(f'WARNING unexpected CRTD insn {cur:08x}, patching anyway')
    data[scale_insn:scale_insn + 4] = struct.pack('<I', 0x1E2E1008)

print('joint break hooks: DISABLED (safety)')
print('NO slow-mo')
libp.write_bytes(data)
print('native_patch done')
