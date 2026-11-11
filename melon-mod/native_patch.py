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

# ============================================================
# Shake: VALUES ONLY (no gate NOPs)
# Replace limit setup with 12.0f + fcmp + b.le + shouldShake check
# Original limit was const 30.0; we use 12.0 for middle sensitivity
# ============================================================
col_off = 0x21557C4

# +0x100: movz w8, #0
# +0x104: movk w8, #0x4140, lsl #16   ; 12.0f
# +0x108: fmov s1, w8
# +0x10c: fcmp s0, s1
# +0x110: b.le skip  (target col+0x1d4)
# +0x114: ldrb w8, [x19, #0x28]       ; shouldShake
# +0x118: cbz w8, skip                ; skip if !shouldShake
code = bytearray()
code += struct.pack('<I', 0x52800008)  # movz w8, #0
code += struct.pack('<I', 0x72A41408)  # movk w8, #0x4140, lsl #16
code += struct.pack('<I', 0x1E270101)  # fmov s1, w8
code += struct.pack('<I', 0x1E202020)  # fcmp s0, s1
# b.le from +0x110 to +0x1d4: imm19 = (0x1d4-0x110)/4 = 49
code += struct.pack('<I', 0x54000000 | (49 << 5) | 0xD)  # b.le
code += struct.pack('<I', 0x3940A268)  # ldrb w8, [x19, #0x28]
# cbz w8, skip — from +0x118 to +0x1d4: imm19 = (0x1d4-0x118)/4 = 47
# CBZ Wt: 0011 0100 imm19 Rt
code += struct.pack('<I', 0x34000000 | (47 << 5) | 8)  # cbz w8

data[col_off+0x100:col_off+0x100+len(code)] = code
print('force limit -> 12.0f (values only, gates as rewritten compare)')
print('no pure gate NOPs')

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
            c = bytearray()
            c += struct.pack('<I', 0x52933348)
            c += struct.pack('<I', 0x72A7C328)
            c += struct.pack('<I', 0x1E270100 | rt)
            data[ts+i:ts+i+12] = c
            print('slowMotionScale -> 0.15f')
            found = True
            break
if not found:
    c = bytearray()
    c += struct.pack('<I', 0x52933348)
    c += struct.pack('<I', 0x72A7C328)
    c += struct.pack('<I', 0x1E270100)
    data[ss+0x10:ss+0x1c] = c
    print('setScale fallback 0.15f')

print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
