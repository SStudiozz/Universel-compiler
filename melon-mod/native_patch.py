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

# Shake: force limit 30 -> 6.0 (imm8 0x3e -> 0x18)
col_off = 0x21557C4
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off+4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    new = (0x1E27D001 & ~0x001FE000) | (0x18 << 13)
    data[insn_off:insn_off+4] = struct.pack('<I', new)
    print(f'shake limit -> 6.0  {new:08x}')
else:
    print(f'WARNING shake fmov {old:08x}')

print('resolution: overlay only this build (ResizeBuffers wire-up next)')
print('NO slow-mo patch')
print('NO gate NOPs')
print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
