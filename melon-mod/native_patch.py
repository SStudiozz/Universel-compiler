from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
BASE = 0x1000

def va(o):
    return o + BASE

def enc_b(f, t):
    return struct.pack('<I', 0x14000000 | (((t - f) // 4) & 0x3FFFFFF))

def enc_bl(f, t):
    return struct.pack('<I', 0x94000000 | (((t - f) // 4) & 0x3FFFFFF))

RET = bytes([0xC0, 0x03, 0x5F, 0xD6])
NOP = bytes.fromhex('1f2003d5')

# --- Kill interstitials only (keep rewarded / shop) ---
for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off + 4] = RET
    print('RET', name)

# --- SetShake: force strong intensity (2.0f) on every call ---
shake_off = 0x2108528
chunk = bytes(data[shake_off:shake_off + 0x40])
seq = bytes.fromhex('6c00005441000037c0035fd6')  # original early exit
idx = chunk.find(seq)
if idx >= 0:
    data[shake_off + idx:shake_off + idx + 12] = NOP * 3
    print('SetShake early-exit NOP')

# Force intensity at short-path store (+0x2c): movz + fmov + str + ret
store_rel = 0x2c
force = bytearray()
force += struct.pack('<I', 0x52A80008)  # movz w8, #0x4000, lsl #16  => 0x40000000 = 2.0f
force += struct.pack('<I', 0x1E270100)  # fmov s0, w8
force += struct.pack('<I', 0xBD002400)  # str s0, [x0, #0x24]
force += RET
data[shake_off + store_rel:shake_off + store_rel + 16] = force
print('SetShake force intensity 2.0f')

# --- Collision path: NOP remaining skip gates so hits always reach SetShake ---
col_off = 0x21557C4
col = bytearray(data[col_off:col_off + 0x200])
for pat in [bytes.fromhex('c8000037'), bytes.fromhex('36000220'), bytes.fromhex('36000120')]:
    i = col.find(pat)
    if i >= 0:
        col[i:i + 4] = NOP
        print('collision gate NOP at', hex(col_off + i))
data[col_off:col_off + 0x200] = col

# --- DealDamage: safe cave (no broken this-call) ---
cave_off = 0x203FED8
cave_va = va(cave_off)
dd_off = 0x21D0164
dd_va = va(dd_off)
orig = bytes(data[dd_off:dd_off + 16])

code = bytearray()
code += orig
bpos = cave_va + len(code)
code += enc_b(bpos, dd_va + 16)
assert len(code) < 0x40
data[cave_off:cave_off + len(code)] = code
data[dd_off:dd_off + 4] = enc_b(dd_va, cave_va)
data[dd_off + 4:dd_off + 16] = NOP * 3
print('DealDamage safe cave', len(code), '(shake from forced SetShake on hits)')

libp.write_bytes(data)
print('NO coin patch')
print('native_patch done')
