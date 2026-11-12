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
    # Known-good template: fmov s1, #30.0 was 0x1e27d001 (imm8=0x3e)
    return (0x1E27D001 & ~0x001FE000) | ((imm8 & 0xFF) << 13)

# Force limit 30 -> 6.0 (imm8 0x3e -> 0x18)
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off+4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    new = fmov_s1_imm(0x18)  # 6.0
    data[insn_off:insn_off+4] = struct.pack('<I', new)
    print(f'force limit -> 6.0  {new:08x}')
else:
    print(f'WARNING force fmov {old:08x}')

# Intensity: replace ldr s1,[x8,#424] (0.1) with fmov s1, #0.25
inten_off = col_off + 0x174
old_i = int.from_bytes(data[inten_off:inten_off+4], 'little')
print(f'intensity site was {old_i:08x}')
inten_insn = fmov_s1_imm(0x50)  # 0.25
data[inten_off:inten_off+4] = struct.pack('<I', inten_insn)
print(f'intensity -> 0.25  {inten_insn:08x}')

print('NO slow-mo patch')
print('NO gate NOPs')
print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
