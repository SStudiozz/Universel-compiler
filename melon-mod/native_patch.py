from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
RET = bytes([0xC0, 0x03, 0x5F, 0xD6])
NOP = bytes.fromhex('1f2003d5')

# Interstitials only
for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off+4] = RET
    print('RET', name)

# --- Shake: minimal, known-working path ---
# Previous value rewrite broke the method (no shake at all).
# Restore approach: only NOP SetShake early-exit + main force b.le.
# Do NOT rewrite the compare block.

shake_off = 0x2108528
chunk = bytes(data[shake_off:shake_off+0x40])
seq = bytes.fromhex('6c00005441000037c0035fd6')
idx = chunk.find(seq)
if idx >= 0:
    data[shake_off+idx:shake_off+idx+12] = NOP * 3
    print('SetShake early-exit NOP')
else:
    print('SetShake early-exit already gone')

col_off = 0x21557C4
# Only the force skip branch — leave rest of method intact
if data[col_off+0x10c:col_off+0x110] == bytes.fromhex('5400064d'):
    data[col_off+0x10c:col_off+0x110] = NOP
    print('NOP force b.le +0x10c')
else:
    # may already be patched or different; still force NOP for this build
    data[col_off+0x10c:col_off+0x110] = NOP
    print('NOP force b.le +0x10c (forced)')

# --- Slow-mo: DO NOT PATCH ---
# Forcing scale to 0.15 on read locked the game into slow-mo.
print('NO slow-mo patch (fixes lock)')

print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
