from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
BASE = 0x1000

RET = bytes([0xC0, 0x03, 0x5F, 0xD6])
NOP = bytes.fromhex('1f2003d5')

for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off + 4] = RET
    print('RET', name)

shake_off = 0x2108528
chunk = bytes(data[shake_off:shake_off + 0x40])
seq = bytes.fromhex('6c00005441000037c0035fd6')
idx = chunk.find(seq)
if idx >= 0:
    data[shake_off + idx:shake_off + idx + 12] = NOP * 3
    print('SetShake early-exit NOP')
else:
    print('SetShake early-exit already gone')

col_off = 0x21557C4
load = bytearray()
load += struct.pack('<I', 0x52800008)
load += struct.pack('<I', 0x72A7D008)
load += struct.pack('<I', 0x1E270100)
data[col_off + 0x17c:col_off + 0x188] = load
print('OnCollision intensity 0.25f')

col = bytearray(data[col_off:col_off + 0x200])
for pat in [
    bytes.fromhex('c8000037'),
    bytes.fromhex('5400064d'),
    bytes.fromhex('340003c8'),
    bytes.fromhex('36000220'),
    bytes.fromhex('36000120'),
]:
    i = 0
    while True:
        j = col.find(pat, i)
        if j < 0:
            break
        col[j:j + 4] = NOP
        print('collision gate NOP at', hex(col_off + j))
        i = j + 4
data[col_off:col_off + 0x200] = col

ss = 0x222DC2C
ts = 0x222DB88
region = bytes(data[ts:ts + 0xA0])
found_ldr = False
for i in range(0, len(region) - 4, 4):
    w = int.from_bytes(region[i:i+4], 'little')
    if (w & 0xFFC00000) == 0xBD400000:
        imm = ((w >> 10) & 0xFFF) * 4
        if imm == 0x28:
            rt = w & 0x1F
            code = bytearray()
            code += struct.pack('<I', 0x529999A8)
            code += struct.pack('<I', 0x72A7C988)
            code += struct.pack('<I', 0x1E270100 | rt)
            data[ts + i:ts + i + 12] = code
            print('forced slowMotionScale read -> 0.2f')
            found_ldr = True
            break
if not found_ldr:
    code = bytearray()
    code += struct.pack('<I', 0x529999A8)
    code += struct.pack('<I', 0x72A7C988)
    code += struct.pack('<I', 0x1E270100)
    data[ss + 0x10:ss + 0x1c] = code
    print('setScale forced arg toward 0.2f (fallback)')

libp.write_bytes(data)
print('NO coin patch')
print('native_patch done')
