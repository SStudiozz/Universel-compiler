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

# Bypass shouldShake: NOP cbz at +0x114 (ldrb at +0x110 stays)
cbz = data[col_off + 0x114:col_off + 0x118]
if cbz == bytes.fromhex('340003c8'):
    data[col_off + 0x114:col_off + 0x118] = NOP
    print('shouldShake cbz NOPed — all CollisionActivityChecker objects can shake')
else:
    data[col_off + 0x114:col_off + 0x118] = NOP
    print(f'shouldShake cbz forced NOP (was {cbz.hex()})')

print('resolution native: DISABLED')
print('NO slow-mo')
libp.write_bytes(data)
print('native_patch done')
