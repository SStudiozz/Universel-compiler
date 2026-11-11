from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())

RET = bytes([0xC0, 0x03, 0x5F, 0xD6])
NOP = bytes.fromhex('1f2003d5')

# --- Kill interstitials only ---
for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off + 4] = RET
    print('RET', name)

# --- SetShake: NOP early-exit only ---
shake_off = 0x2108528
chunk = bytes(data[shake_off:shake_off + 0x40])
seq = bytes.fromhex('6c00005441000037c0035fd6')
idx = chunk.find(seq)
if idx >= 0:
    data[shake_off + idx:shake_off + idx + 12] = NOP * 3
    print('SetShake early-exit NOP')
else:
    print('SetShake early-exit already gone')

# --- OnCollisionEnter2D ---
# Moderate threshold: light intentional taps yes, physics noise no.
col_off = 0x21557C4

# Intensity ~0.15f
load = bytearray()
load += struct.pack('<I', 0x52933348)  # movz w8, #0x999a
load += struct.pack('<I', 0x72A7C328)  # movk w8, #0x3e19, lsl #16
load += struct.pack('<I', 0x1E270100)  # fmov s0, w8
data[col_off + 0x17c:col_off + 0x188] = load
print('OnCollision intensity ~0.15f')

col = bytearray(data[col_off:col_off + 0x200])

# Main force b.le at +0x10c
if col[0x10c:0x110] == bytes.fromhex('5400064d'):
    col[0x10c:0x110] = NOP
    print('NOP main force b.le +0x10c')

for pat in [
    bytes.fromhex('c8000037'),
    bytes.fromhex('36000220'),
    bytes.fromhex('36000120'),
]:
    i = 0x30
    while True:
        j = col.find(pat, i)
        if j < 0 or j > 0x160:
            break
        col[j:j+4] = NOP
        print(f'gate NOP +{j:x}')
        i = j + 4

data[col_off:col_off + 0x200] = col

for const_hex, new_hex, name in [
    ('0000f041', '00000041', '30.0 -> 8.0'),
]:
    region = data[col_off:col_off+0x200]
    j = region.find(bytes.fromhex(const_hex))
    if j >= 0:
        data[col_off+j:col_off+j+4] = bytes.fromhex(new_hex)
        print(f'replaced {name}')

ts = 0x222DB88
ss = 0x222DC2C
region = bytes(data[ts:ts + 0xA0])
found = False
for i in range(0, len(region) - 4, 4):
    w = int.from_bytes(region[i:i+4], 'little')
    if (w & 0xFFC00000) == 0xBD400000:
        imm = ((w >> 10) & 0xFFF) * 4
        if imm == 0x28:
            rt = w & 0x1F
            code = bytearray()
            code += struct.pack('<I', 0x52933348)
            code += struct.pack('<I', 0x72A7C328)
            code += struct.pack('<I', 0x1E270100 | rt)
            data[ts + i:ts + i + 12] = code
            print('slowMotionScale -> 0.15f')
            found = True
            break
if not found:
    code = bytearray()
    code += struct.pack('<I', 0x52933348)
    code += struct.pack('<I', 0x72A7C328)
    code += struct.pack('<I', 0x1E270100)
    data[ss + 0x10:ss + 0x1c] = code
    print('setScale fallback 0.15f')

print('NO coin patch')
libp.write_bytes(data)
print('native_patch done')
