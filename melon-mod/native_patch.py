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

# --- SetShake: keep original logic, only NOP early-exit that skips weak shakes ---
shake_off = 0x2108528
chunk = bytes(data[shake_off:shake_off + 0x40])
seq = bytes.fromhex('6c00005441000037c0035fd6')
idx = chunk.find(seq)
if idx >= 0:
    data[shake_off + idx:shake_off + idx + 12] = NOP * 3
    print('SetShake early-exit NOP (keep original intensity path)')
else:
    print('SetShake early-exit already patched or missing')

# --- OnCollisionEnter2D: force intensity 0.6f right before BL SetShake ---
col_off = 0x21557C4
print('OnCollision pre-SetShake:', data[col_off+0x170:col_off+0x190].hex())

# 0.6f = 0x3f19999a
load06 = bytearray()
load06 += struct.pack('<I', 0x52933348)  # movz w8, #0x999a
load06 += struct.pack('<I', 0x72A7E328)  # movk w8, #0x3f19, lsl #16
load06 += struct.pack('<I', 0x1E270100)  # fmov s0, w8
# Put at +0x17c (12 bytes), BL SetShake stays at +0x188
data[col_off + 0x17c:col_off + 0x188] = load06
print('OnCollision force intensity 0.6f before SetShake')

# Lower collision force gate (weak-skip only)
col = bytearray(data[col_off:col_off + 0x200])
for pat in [bytes.fromhex('c8000037')]:
    i = col.find(pat)
    if i >= 0:
        col[i:i+4] = NOP
        print('collision weak-gate NOP at', hex(col_off + i))
data[col_off:col_off + 0x200] = col

print('DealDamage left original (shake via collision path at 0.6)')
libp.write_bytes(data)
print('NO coin patch')
print('native_patch done')
