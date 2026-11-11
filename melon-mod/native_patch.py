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

# Shake: fmov s1, #imm only — no gate NOPs
# 0x3e=30.0 (vanilla) | 0x28=12.0 | 0x24=10.0 | 0x20=8.0
col_off = 0x21557C4
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off+4], 'little')
print(f'old insn @ +0x104: {old:08x}')

if ((old >> 5) & 0xFF) != 0x80 or (old & 31) != 1:
    print('WARNING: +0x104 is not fmov s1, #imm — aborting shake patch')
else:
    imm8_old = (old >> 13) & 0xFF
    print(f'old imm8={imm8_old:#x}')
    imm8_new = 0x24  # 10.0 — a bit more sensitive than 12
    new = (old & ~0x001FE000) | (imm8_new << 13)
    data[insn_off:insn_off+4] = struct.pack('<I', new)
    print(f'new insn @ +0x104: {new:08x}  imm8={imm8_new:#x} (10.0)')

print('NO slow-mo patch')
print('NO gate NOPs')
print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
