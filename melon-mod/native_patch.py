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

# Joint breakForce/Torque hooks REMOVED — previous cave @ 0x21559B0
# overwrote live code and crashed in libunity physics.
print('joint break hooks: DISABLED (safety)')
print('resolution: JNI only')
print('NO slow-mo')
libp.write_bytes(data)
print('native_patch done')
