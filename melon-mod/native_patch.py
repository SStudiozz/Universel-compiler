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
    data[off:off + 4] = RET
    print('RET', name)

col_off = 0x21557C4
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off + 4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    new = (0x1E27D001 & ~0x001FE000) | (0x18 << 13)
    data[insn_off:insn_off + 4] = struct.pack('<I', new)
    print(f'shake limit -> 6.0  {new:08x}')
else:
    print(f'WARNING shake fmov {old:08x}')

UPDATE = 0x2068B40
RB = 0x43C6904
CAVE = 0x21559B0

orig0 = int.from_bytes(data[UPDATE:UPDATE + 4], 'little')
orig1 = int.from_bytes(data[UPDATE + 4:UPDATE + 8], 'little')

br = (CAVE - UPDATE) // 4
data[UPDATE:UPDATE + 4] = struct.pack('<I', 0x14000000 | (br & 0x03FFFFFF))
print(f'UIScaler.Update -> cave @ {CAVE:#x}')

def enc(i):
    return struct.pack('<I', i)

code = bytearray()
code += enc(0xD10013FF)
code += enc(0xA9037BFD)
code += enc(0xA90107E0)
code += enc(0xA90223E2)
code += enc(0xA9004FF4)
code += enc(0xD2800C80)
code += enc(0xCB0003E0)
adr_at = len(code)
code += enc(0x10000001)
code += enc(0xD2800002)
code += enc(0xD2800708)
code += enc(0xD4000001)
code += enc(0xF100001F)
blt_at = len(code)
code += enc(0x5400000B)
code += enc(0xAA0003F3)
code += enc(0x910043E1)
code += enc(0xD2800082)
code += enc(0xD28007E8)
code += enc(0xD4000001)
code += enc(0xAA1303E0)
code += enc(0xD2800728)
code += enc(0xD4000001)
code += enc(0xB94043E8)
code += enc(0x5AC00808)
code += enc(0x1E270100)
code += enc(0x1E204020)
bl_at = len(code)
code += enc(0x94000000)
skip_off = len(code)
imm19 = (skip_off - blt_at) // 4
code[blt_at:blt_at + 4] = enc(0x54000000 | ((imm19 & 0x7FFFF) << 5) | 0xB)
code += enc(0xA9404FF4)
code += enc(0xA94223E2)
code += enc(0xA94107E0)
code += enc(0xA9437BFD)
code += enc(0x910143FF)
code += enc(orig0)
code += enc(orig1)
back = ((UPDATE + 8) - (CAVE + len(code))) // 4
code += enc(0x14000000 | (back & 0x03FFFFFF))
while len(code) % 4:
    code += b'\x00'
path_at = len(code)
code += b'/data/data/com.studio27.MelonPlayground/files/melon_rscale\x00'
while len(code) % 4:
    code += b'\x00'
adr_byte_off = path_at - adr_at
immlo = (adr_byte_off >> 0) & 3
immhi = (adr_byte_off >> 2) & 0x7FFFF
code[adr_at:adr_at + 4] = enc(0x10000000 | (immlo << 29) | (immhi << 5) | 1)
bl_pc = CAVE + bl_at
bl_imm = ((RB - bl_pc) // 4) & 0x03FFFFFF
code[bl_at:bl_at + 4] = enc(0x94000000 | bl_imm)
print(f'cave size {len(code)} bytes @ {CAVE:#x}')
data[CAVE:CAVE + len(code)] = code
print('resolution WIRED: Update reads melon_rscale -> ResizeBuffers')
print('NO slow-mo')
libp.write_bytes(data)
print('native_patch done')
