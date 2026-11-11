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

# --- Shake: VALUES ONLY, no gate NOPs ---
# Original COLLISION_FORCE_LIMIT = 30. Inject 12.0f via codecave.
# Gates (fcmp / b.le / SetShake) stay intact.
col_off = 0x21557C4
cave = col_off + 0x1C0

# Replace original fcmp at +0x108 with: b cave
# (48 instr forward from +0x108 to +0x1c0: (0x1c0-0x108)/4 = 46)
data[col_off+0x108:col_off+0x10c] = struct.pack('<I', 0x14000000 | 46)
print('hook fcmp -> b cave')

# Cave:
#   movz w8, #0
#   movk w8, #0x4140, lsl #16   ; 12.0f = 0x41400000
#   fmov s1, w8
#   fcmp s0, s1
#   b.le skip   ; original skip target = col+0x1d4
#   b +0x10c    ; back to original b.le site — but that was our hook.
#              ; continue at +0x10c would re-hit. Go to +0x110 instead.
cave_code = bytearray()
cave_code += struct.pack('<I', 0x52800008)  # movz w8, #0
cave_code += struct.pack('<I', 0x72A41408)  # movk w8, #0x4140, lsl #16
cave_code += struct.pack('<I', 0x1E270101)  # fmov s1, w8
cave_code += struct.pack('<I', 0x1E202020)  # fcmp s0, s1

# 5th insn at col+0x1d0: b.le to original skip col+0x1d4
# From +0x1d0 to +0x1d4 = +4 bytes = imm19=1, cond=LE(0xD)
cave_code += struct.pack('<I', 0x5400002D)

# 6th insn at col+0x1d4: b continue at col+0x110 (shouldShake check)
# delta = 0x110 - 0x1d4 = -0xc4 bytes = -49 instrs
imm26 = (-49) & 0x03FFFFFF
cave_code += struct.pack('<I', 0x14000000 | imm26)

data[cave:cave+len(cave_code)] = cave_code
print('cave: force limit 12.0f (gates intact)')

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
print('NO gate NOPs')
libp.write_bytes(data)
print('native_patch done')
