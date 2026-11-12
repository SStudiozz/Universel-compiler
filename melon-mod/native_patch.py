from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
RET = bytes([0xC0, 0x03, 0x5F, 0xD6])

for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off+4] = RET
    print('RET', name)

col_off = 0x21557C4

def fmov_s1_imm(imm8):
    return (0x1E27D001 & ~0x001FE000) | ((imm8 & 0xFF) << 13)

# Force limit 30 -> 6.0
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off+4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    new = fmov_s1_imm(0x18)  # 6.0
    data[insn_off:insn_off+4] = struct.pack('<I', new)
    print(f'force limit -> 6.0  {new:08x}')
else:
    print(f'WARNING force fmov {old:08x}')

# Intensity: leave original ldr (vanilla ~0.10) — do NOT overwrite
print('intensity left at vanilla ~0.10 (no patch)')

print('NO slow-mo patch')
print('NO gate NOPs')
print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
