from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
BASE = 0x1000

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

# --- SetShake: NOP early-exit only (keep normal body) ---
shake_off = 0x2108528
chunk = bytes(data[shake_off:shake_off + 0x40])
seq = bytes.fromhex('6c00005441000037c0035fd6')
idx = chunk.find(seq)
if idx >= 0:
    data[shake_off + idx:shake_off + idx + 12] = NOP * 3
    print('SetShake early-exit NOP')
else:
    print('SetShake early-exit already gone')

# --- OnCollisionEnter2D (CollisionActivityChecker @ 0x21557C4) ---
# Goal: light taps must also trigger shake. Aggressively kill force gates.
col_off = 0x21557C4

# 1) Force intensity ~0.12f (visible but not violent)
# 0.12f = 0x3df5c28f
load = bytearray()
load += struct.pack('<I', 0x528851E8)  # movz w8, #0xc28f
load += struct.pack('<I', 0x72A7BEA8)  # movk w8, #0x3df5, lsl #16
load += struct.pack('<I', 0x1E270100)  # fmov s0, w8
data[col_off + 0x17c:col_off + 0x188] = load
print('OnCollision intensity ~0.12f')

# 2) Nuclear option on force gates: NOP a wide range of skip branches
#    especially the fcmp + b.le at +0x100..+0x10c and later cbz/tbz
col = bytearray(data[col_off:col_off + 0x200])

# Explicitly kill the main force compare block (+0x100 to +0x114)
for off in range(0x100, 0x118, 4):
    col[off:off+4] = NOP
print('NOP force-compare block +0x100..+0x114')

# Broader pattern NOPs (skip anything that looks like a conditional exit)
for pat in [
    bytes.fromhex('c8000037'),  # tbnz
    bytes.fromhex('5400064d'),  # b.le
    bytes.fromhex('5400040d'),  # b.le
    bytes.fromhex('5400020d'),  # b.le
    bytes.fromhex('340003c8'),  # cbz
    bytes.fromhex('340002c8'),  # cbz
    bytes.fromhex('36000220'),  # tbz
    bytes.fromhex('36000120'),  # tbz
    bytes.fromhex('36000200'),  # tbz
    bytes.fromhex('c8000035'),  # cbnz
    bytes.fromhex('35000069'),  # cbnz
    bytes.fromhex('35000048'),  # cbnz
]:
    i = 0x20  # skip prologue null checks
    while True:
        j = col.find(pat, i)
        if j < 0 or j > 0x1b0:
            break
        col[j:j+4] = NOP
        print(f'gate NOP +{j:x} {pat.hex()}')
        i = j + 4

data[col_off:col_off + 0x200] = col

# 3) Also try to smash any remaining 30.0f / high force constants in the method
for const_hex, new_hex, name in [
    ('0000f041', '00000040', '30.0 -> 2.0'),   # 30.0f -> 2.0f
    ('0000a041', '00000040', '20.0 -> 2.0'),
    ('00002041', '00000040', '10.0 -> 2.0'),
]:
    idx = 0
    region = data[col_off:col_off+0x200]
    while True:
        j = region.find(bytes.fromhex(const_hex), idx)
        if j < 0:
            break
        data[col_off+j:col_off+j+4] = bytes.fromhex(new_hex)
        print(f'replaced {name} at +{j:x}')
        idx = j + 4

# --- Better slow-mo (keep 0.15) ---
ts = 0x222DB88
ss = 0x222DC2C
region = bytes(data[ts:ts + 0xA0])
found_ldr = False
for i in range(0, len(region) - 4, 4):
    w = int.from_bytes(region[i:i+4], 'little')
    if (w & 0xFFC00000) == 0xBD400000:
        imm = ((w >> 10) & 0xFFF) * 4
        if imm == 0x28:
            rt = w & 0x1F
            code = bytearray()
            code += struct.pack('<I', 0x52933348)  # movz w8, #0x999a
            code += struct.pack('<I', 0x72A7C328)  # movk w8, #0x3e19, lsl #16
            code += struct.pack('<I', 0x1E270100 | rt)
            data[ts + i:ts + i + 12] = code
            print('forced slowMotionScale -> 0.15f')
            found_ldr = True
            break
if not found_ldr:
    code = bytearray()
    code += struct.pack('<I', 0x52933348)
    code += struct.pack('<I', 0x72A7C328)
    code += struct.pack('<I', 0x1E270100)
    data[ss + 0x10:ss + 0x1c] = code
    print('setScale forced toward 0.15f (fallback)')

print('NO coin patch')
libp.write_bytes(data)
print('native_patch done')
