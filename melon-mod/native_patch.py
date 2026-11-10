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
    data[shake_off + idx:shake_off + idx + 12] = bytes.fromhex('1f2003d5') * 3
    print('SetShake NOP')

col_off = 0x21557C4
col = bytes(data[col_off:col_off + 0x80])
if bytes.fromhex('c8000037') in col:
    i = col.find(bytes.fromhex('c8000037'))
    data[col_off + i:col_off + i + 4] = bytes.fromhex('1f2003d5')
    print('collision NOP')

cave_off = 0x203FED8
cave_va = va(cave_off)
dd_off = 0x21D0164
dd_va = va(dd_off)
get_shake_va = 0x2156710
set_shake_va = 0x2109528
orig = bytes(data[dd_off:dd_off + 16])

code = bytearray()
code += struct.pack('<I', 0xD10203FF)
code += struct.pack('<I', 0xA9077BFD)
code += struct.pack('<I', 0xA90607E0)
code += struct.pack('<I', 0xBD015FE0)
code += bytes.fromhex('e80300aa')
for ins in ['1f0000a9', '1f8400a9', '1f0801a9', '1f8c01a9', '1f1002a9']:
    code += bytes.fromhex(ins)
code += bytes.fromhex('e00300aa')
bl1 = cave_va + len(code)
code += enc_bl(bl1, get_shake_va)
cbz_at = len(code)
code += struct.pack('<I', 0xB4000000)
code += struct.pack('<I', 0x52A7D008)
code += struct.pack('<I', 0x1E270100)
code += bytes.fromhex('21008052')
bl2 = cave_va + len(code)
code += enc_bl(bl2, set_shake_va)
skip = len(code)
imm = (skip - cbz_at) // 4
struct.pack_into('<I', code, cbz_at, 0xB4000000 | ((imm & 0x7FFFF) << 5))
code += struct.pack('<I', 0xA94607E0)
code += struct.pack('<I', 0xBD415FE0)
code += struct.pack('<I', 0xA9477BFD)
code += struct.pack('<I', 0x910203FF)
code += orig
bpos = cave_va + len(code)
code += enc_b(bpos, dd_va + 16)
assert len(code) < 0x120
data[cave_off:cave_off + len(code)] = code
data[dd_off:dd_off + 4] = enc_b(dd_va, cave_va)
data[dd_off + 4:dd_off + 16] = bytes.fromhex('1f2003d5') * 3
print('DealDamage hooked cave', len(code))
libp.write_bytes(data)
print('NO coin patch')
