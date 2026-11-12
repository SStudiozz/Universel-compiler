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

# --- Force limit: 30 -> 6.0 (imm8 0x3e -> 0x18) ---
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off+4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    imm8_new = 0x18  # 6.0
    new = (old & ~0x001FE000) | (imm8_new << 13)
    data[insn_off:insn_off+4] = struct.pack('<I', new)
    print(f'force limit -> 6.0  insn={new:08x}')
else:
    print(f'WARNING: force fmov not found ({old:08x})')

# --- Intensity: replace ldr s1, [x8,#424] (SHAKE_FORCE 0.1)
# with fmov s1, #0.25 for a stronger kick ---
# Original at +0x174: bd41a901 = ldr s1, [x8, #0x1a8]
inten_off = col_off + 0x174
old_i = int.from_bytes(data[inten_off:inten_off+4], 'little')
print(f'intensity site @ +0x174: {old_i:08x}')
# fmov s1, #0.25 (imm8=0x50), same form as force fmov
# Template from known good fmov s1, #imm: Rd=1, bits[12:5]=0x80
fmov_tmpl = 0x1E270001 | (0x80 << 5)  # base with Rd=1 and imm field 0
# Correct: 0x1e27d001 was imm=0x3e. Build fresh:
# bits: FMOV-imm single, Rd=1, imm8=0x50
# 00011110 001 00111 10100000 00000001 with imm in [20:13]
# Use same construction as force patch
base = 0x1E270001
# set bits[12:5] = 0x80
base = (base & ~0x1FE0) | (0x80 << 5)
inten_insn = (base & ~0x001FE000) | (0x50 << 13)  # 0.25
data[inten_off:inten_off+4] = struct.pack('<I', inten_insn)
print(f'intensity -> 0.25  insn={inten_insn:08x}')

print('NO slow-mo patch')
print('NO gate NOPs')
print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
