from pathlib import Path
import struct

libp = Path('decoded/lib/arm64-v8a/libil2cpp.so')
data = bytearray(libp.read_bytes())
RET = bytes([0xC0, 0x03, 0x5F, 0xD6])
NOP = bytes.fromhex('1f2003d5')

def enc(i):
    return struct.pack('<I', i)

def fmov_s_imm(rd, imm8):
    return (0x1E27D001 & ~0x001FE000 & ~0x1F) | (rd & 31) | ((imm8 & 0xFF) << 13)

for off, name in [
    (0x203FED4, 'ShowInterstitial'),
    (0x203FEB0, 'ShowAdWithDelay'),
    (0x3925D20, 'MaxSdk.ShowInterstitial'),
]:
    data[off:off + 4] = RET
    print('RET', name)

col_off = 0x21557C4

# Shake force limit 30 -> 6.0
insn_off = col_off + 0x104
old = int.from_bytes(data[insn_off:insn_off + 4], 'little')
if ((old >> 5) & 0xFF) == 0x80 and (old & 31) == 1:
    new = (0x1E27D001 & ~0x001FE000) | (0x18 << 13)
    data[insn_off:insn_off + 4] = struct.pack('<I', new)
    print(f'shake limit -> 6.0')
else:
    print(f'WARNING shake fmov {old:08x}')

# Bypass shouldShake
data[col_off + 0x114:col_off + 0x118] = NOP
print('shouldShake bypassed')

# Shake intensity stronger: SetShake mul 1.0 -> 1.5 (imm8 0x78)
shake_off = 0x2108528
fmov_off = shake_off + 4
fmov = int.from_bytes(data[fmov_off:fmov_off + 4], 'little')
new_f = (0x1E2E1002 & ~0x001FE000) | (0x78 << 13)  # fmov s2, #1.5
data[fmov_off:fmov_off + 4] = struct.pack('<I', new_f)
print(f'SetShake intensity mul -> 1.5 (was {fmov:08x})')

# ============================================================
# Limb/bone strength: Joint2D.set_breakForce / set_breakTorque
# Multiply incoming force threshold by ~1.31 (imm 0x75 = 1.3125)
# Higher breakForce = harder to tear limbs / break joints
# File offsets (Il2CppDumper Offset field)
# ============================================================
CAVE = 0x21559B0
cave_cursor = CAVE

def hook_mul_s0(func_off, label):
    global cave_cursor
    orig0 = int.from_bytes(data[func_off:func_off + 4], 'little')
    # b cave
    br = (cave_cursor - func_off) // 4
    data[func_off:func_off + 4] = enc(0x14000000 | (br & 0x03FFFFFF))

    code = bytearray()
    # fmov s1, #1.3125
    code += enc(fmov_s_imm(1, 0x75))
    # fmul s0, s0, s1
    code += enc(0x1E210800)  # fmul s0, s0, s1
    # original first insn
    code += enc(orig0)
    # b func+4
    back = ((func_off + 4) - (cave_cursor + len(code))) // 4
    code += enc(0x14000000 | (back & 0x03FFFFFF))

    data[cave_cursor:cave_cursor + len(code)] = code
    print(f'{label}: break threshold *1.3125 cave@{cave_cursor:#x}')
    cave_cursor += len(code)
    # align
    while cave_cursor % 4:
        cave_cursor += 1

hook_mul_s0(0x4448A24, 'set_breakForce')
hook_mul_s0(0x4448A70, 'set_breakTorque')

print('resolution: JNI only')
print('NO slow-mo')
libp.write_bytes(data)
print('native_patch done')
