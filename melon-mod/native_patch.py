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
    data[off:off+4] = RET
    print('RET', name)

shake_off = 0x2108528
chunk = bytes(data[shake_off:shake_off+0x40])
seq = bytes.fromhex('6c00005441000037c0035fd6')
idx = chunk.find(seq)
if idx >= 0:
    data[shake_off+idx:shake_off+idx+12] = NOP*3
    print('SetShake early-exit NOP')
else:
    print('SetShake early-exit already gone')

# Middle: force limit ~12 (was 30). Codecave so fcmp+b.le still work.
col_off = 0x21557C4
cave = col_off + 0x1C0

# +0x100: b cave (48 instructions forward)
data[col_off+0x100:col_off+0x104] = struct.pack('<I', 0x14000000 | 48)

# cave:
#   movz w8,#0
#   movk w8,#0x4140,lsl#16    ; 12.0f
#   fmov s1,w8
#   fcmp s0,s1
#   b.le skip (+0x1d4)
#   b +0x110                 ; continue past original compare
cave_code = bytearray()
cave_code += struct.pack('<I', 0x52800008)
cave_code += struct.pack('<I', 0x72A41408)
cave_code += struct.pack('<I', 0x1E270101)
cave_code += struct.pack('<I', 0x1E202020)  # fcmp s0, s1
# 5th insn at col+0x1d0: b.le to col+0x1d4 (imm19=1)
cave_code += struct.pack('<I', 0x5400002D)
# 6th insn at col+0x1d4: b to col+0x110
# delta = 0x110 - 0x1d4 = -0xc4 bytes = -49 instructions
imm26 = (-49) & 0x03FFFFFF
cave_code += struct.pack('<I', 0x14000000 | imm26)
data[cave:cave+len(cave_code)] = cave_code
print('cave ok: limit 12.0f')

ts = 0x222DB88
ss = 0x222DC2C
region = bytes(data[ts:ts+0xA0])
found = False
for i in range(0, len(region)-4, 4):
    w = int.from_bytes(region[i:i+4], 'little')
    if (w & 0xFFC00000) == 0xBD400000:
        imm = ((w >> 10) & 0xFFF) * 4
        if imm == 0x28:
            rt = w & 0x1F
            code = bytearray()
            code += struct.pack('<I', 0x52933348)
            code += struct.pack('<I', 0x72A7C328)
            code += struct.pack('<I', 0x1E270100 | rt)
            data[ts+i:ts+i+12] = code
            print('slowMotionScale -> 0.15f')
            found = True
            break
if not found:
    code = bytearray()
    code += struct.pack('<I', 0x52933348)
    code += struct.pack('<I', 0x72A7C328)
    code += struct.pack('<I', 0x1E270100)
    data[ss+0x10:ss+0x1c] = code
    print('setScale fallback 0.15f')

print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
