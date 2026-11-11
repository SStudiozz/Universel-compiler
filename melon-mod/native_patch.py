from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
BASE = 0x1000

def va(o):
    return o + BASE

def enc_b(f, t):
    return struct.pack('<I', 0x14000000 | (((t - f) // 4) & 0x3FFFFFF))

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
# Lower intensity to ~0.10f (mild) and remove force gates so light/medium hits also shake
col_off = 0x21557C4

# Intensity 0.10f = 0x3dcccccd
# movz w8, #0xcccd; movk w8, #0x3dcc, lsl #16; fmov s0, w8
load = bytearray()
load += struct.pack('<I', 0x529999A8)  # movz w8, #0xcccd
load += struct.pack('<I', 0x72A7B988)  # movk w8, #0x3dcc, lsl #16
load += struct.pack('<I', 0x1E270100)  # fmov s0, w8
# Place before BL SetShake (around +0x188)
data[col_off + 0x17c:col_off + 0x188] = load
print('OnCollision intensity ~0.10f (mild)')

# NOP remaining force / skip gates (keep null-check CBNZs)
col = bytearray(data[col_off:col_off + 0x200])
for pat in [
    bytes.fromhex('c8000037'),  # tbnz weak skip
    bytes.fromhex('5400064d'),  # b.le force compare
    bytes.fromhex('340003c8'),  # cbz skip
    bytes.fromhex('36000220'),  # tbz
    bytes.fromhex('36000120'),  # tbz
    bytes.fromhex('c8000035'),  # cbnz
    bytes.fromhex('5400040d'),  # b.le
]:
    i = 0
    while True:
        j = col.find(pat, i)
        if j < 0:
            break
        # Avoid null-check patterns near the start that protect against null camera
        if j < 0x20:
            i = j + 4
            continue
        col[j:j + 4] = NOP
        print('collision gate NOP at', hex(col_off + j), pat.hex())
        i = j + 4
data[col_off:col_off + 0x200] = col

# Also try to lower the hard-coded COLLISION_FORCE_LIMIT comparison if present as float 30.0
# 30.0f = 0x41f00000. Search in the method for the constant load.
force_const = bytes.fromhex('0000f041')  # little-endian float 30.0
idx = col.find(force_const)
if idx >= 0:
    # replace with 6.0f = 0x40c00000
    col[idx:idx+4] = bytes.fromhex('0000c040')
    data[col_off:col_off + 0x200] = col
    print('lowered force limit constant 30 -> 6')
else:
    # try 0x41f00000 in other encodings / nearby
    print('force limit const not found as plain float (ok)')

# --- Better slow-mo ---
# Force slowMotionScale reads / setScale toward 0.15f for stronger, usable slow-mo
# 0.15f = 0x3e19999a
ts = 0x222DB88  # ToggleSlow
ss = 0x222DC2C  # setScale

region = bytes(data[ts:ts + 0xA0])
found_ldr = False
for i in range(0, len(region) - 4, 4):
    w = int.from_bytes(region[i:i+4], 'little')
    if (w & 0xFFC00000) == 0xBD400000:
        imm = ((w >> 10) & 0xFFF) * 4
        if imm == 0x28:  # field slowMotionScale
            rt = w & 0x1F
            print(f'ToggleSlow +{i:02x}: ldr s{rt}, [x?, #0x28]')
            code = bytearray()
            code += struct.pack('<I', 0x52933348)  # movz w8, #0x999a
            code += struct.pack('<I', 0x72A7C328)  # movk w8, #0x3e19, lsl #16
            code += struct.pack('<I', 0x1E270100 | rt)  # fmov s{rt}, w8
            data[ts + i:ts + i + 12] = code
            print('forced slowMotionScale -> 0.15f')
            found_ldr = True
            break
if not found_ldr:
    # Fallback: force arg of setScale
    code = bytearray()
    code += struct.pack('<I', 0x52933348)  # movz w8, #0x999a
    code += struct.pack('<I', 0x72A7C328)  # movk w8, #0x3e19, lsl #16
    code += struct.pack('<I', 0x1E270100)  # fmov s0, w8
    data[ss + 0x10:ss + 0x1c] = code
    print('setScale forced toward 0.15f (fallback)')

print('NO coin patch')
libp.write_bytes(data)
print('native_patch done')
