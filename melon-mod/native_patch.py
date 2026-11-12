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

# Force limit 30 -> 6.0
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off + 4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    new = (0x1E27D001 & ~0x001FE000) | (0x18 << 13)
    data[insn_off:insn_off + 4] = struct.pack('<I', new)
    print(f'shake limit -> 6.0  {new:08x}')
else:
    print(f'WARNING shake fmov {old:08x}')

# Bypass shouldShake
data[col_off + 0x114:col_off + 0x118] = NOP
print('shouldShake cbz NOPed')

# Intensity +22%~ : SetShake multiplies by fmov #1.0 -> #1.25 (imm8 0x70 -> 0x74)
# (ARM fmov imm has no exact 1.22; 1.25 is closest = +25%)
shake_off = 0x2108528
fmov_off = shake_off + 4
fmov = int.from_bytes(data[fmov_off:fmov_off + 4], 'little')
# expected 0x1e2e1002 = fmov s2, #1.0
if (fmov & 0xFFE01FE0) == (0x1E2E1002 & 0xFFE01FE0) or ((fmov >> 5) & 0xFF) == 0x80:
    new_f = (fmov & ~0x001FE000) | (0x74 << 13)  # 1.25
    data[fmov_off:fmov_off + 4] = struct.pack('<I', new_f)
    print(f'SetShake mul 1.0 -> 1.25  {fmov:08x} -> {new_f:08x}')
else:
    # force known encoding fmov s2, #1.25
    new_f = (0x1E2E1002 & ~0x001FE000) | (0x74 << 13)
    data[fmov_off:fmov_off + 4] = struct.pack('<I', new_f)
    print(f'SetShake mul forced 1.25 (was {fmov:08x})')

print('resolution: JNI path only (no IL2CPP hooks)')
print('NO slow-mo')
libp.write_bytes(data)
print('native_patch done')
