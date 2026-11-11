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

# Middle sensitivity: force limit 30 -> 12 via tiny codecave.
# Original: fcmp + b.le at +0x108/+0x10c (limit baked earlier).
# We branch at +0x100 into cave: load 12.0f, fcmp, b.le to original skip, else return.
col_off = 0x21557C4
cave = col_off + 0x1C0

# at +0x100: b cave  (offset = 0x1c0-0x100 = 0xc0 bytes = 48 instr)
data[col_off+0x100:col_off+0x104] = struct.pack('<I', 0x14000000 | 48)
print('hook b to cave at +0x100')

# cave @ +0x1c0:
# movz w8, #0
# movk w8, #0x4140, lsl #16   ; 12.0f
# fmov s1, w8
# fcmp s0, s1
# b.le skip_target   ; same skip as original (+0x1d4 absolute)
# b continue         ; +0x104 (instruction after our hook)
cave_code = bytearray()
cave_code += struct.pack('<I', 0x52800008)  # movz w8, #0
cave_code += struct.pack('<I', 0x72A41408)  # movk w8, #0x4140, lsl #16
cave_code += struct.pack('<I', 0x1E270101)  # fmov s1, w8
cave_code += struct.pack('<I', 0x1E202020)  # fcmp s0, s1
# b.le to col+0x1d4. From cave+0x10 (fifth insn at +0x1d0):
# target 0x1d4, PC=0x1d0, delta=4 bytes = 1 instr -> imm19=1
cave_code += struct.pack('<I', 0x5400000D)  # b.le +1 (next insn if true... wrong)
# Fix: original skip target col+0x1d4
# fifth insn at cave+0x10 = col+0x1d0
# imm19 = (0x1d4 - 0x1d0) / 4 = 1, cond LE=0xD
# 0101 0100 0000000000000010 1101 - wait imm19=1 -> 0x5400002d?
# B.cond: 01010100 imm19 0 cond
# imm19=1: 0x5400000D is imm=0. For imm=1: 0x5400002D
cave_code = bytearray()
cave_code += struct.pack('<I', 0x52800008)
cave_code += struct.pack('<I', 0x72A41408)
cave_code += struct.pack('<I', 0x1E270101)
cave_code += struct.pack('<I', 0x1E202020)
# From col+0x1d0, skip target col+0x1d4 is +4 bytes = imm19=1
cave_code += struct.pack('<I', 0x5400002D)  # b.le +1 (to +0x1d4)
# continue to col+0x104: from col+0x1d4 (sixth insn)
# delta = 0x104 - 0x1d4 = -0xd0 = -208 bytes = -52 instr
# b encoding: imm26 = -52 & 0x3ffffff
imm26 = (-52) & 0x03FFFFFF
cave_code += struct.pack('<I', 0x14000000 | imm26)
data[cave:cave+len(cave_code)] = cave_code
print('cave: limit 12.0f + fcmp + b.le')

# Slow-mo 0.15
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
