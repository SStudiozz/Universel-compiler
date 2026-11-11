from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
RET = bytes([0xC0, 0x03, 0x5F, 0xD6])

# Interstitials only
for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off+4] = RET
    print('RET', name)

# ============================================================
# Shake: modify EXISTING bytecode value only
# At OnCollisionEnter2D +0x104: fmov s1, #imm8
#   imm8=0x3e -> 30.0  (original COLLISION_FORCE_LIMIT)
#   imm8=0x28 -> 12.0  (middle sensitivity)
# Encoding: FMOV Sd, #imm  bits[20:13]=imm8, Rd=s1
# NO gate NOPs. NO SetShake NOPs. NO control-flow changes.
# ============================================================
col_off = 0x21557C4
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off+4], 'little')
print(f'old insn @ +0x104: {old:08x}')

# Verify it is the expected fmov-imm (bits[12:5]==0x80, Rd==1)
if ((old >> 5) & 0xFF) != 0x80 or (old & 31) != 1:
    print('WARNING: +0x104 is not the expected fmov s1, #imm — aborting shake patch')
else:
    imm8_old = (old >> 13) & 0xFF
    print(f'old imm8={imm8_old:#x} (expect 0x3e = 30.0)')
    imm8_new = 0x28  # 12.0
    new = (old & ~0x001FE000) | (imm8_new << 13)
    data[insn_off:insn_off+4] = struct.pack('<I', new)
    print(f'new insn @ +0x104: {new:08x}  imm8={imm8_new:#x} (12.0)')

# Slow-mo: leave alone (forcing scale locked the game before)
print('NO slow-mo patch')
print('NO gate NOPs')
print('NO coin patch')
print('NO fps')
libp.write_bytes(data)
print('native_patch done')
