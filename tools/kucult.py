"""Shrink the embedded textures of a GLB: kucult.py in.glb out.glb max_size"""
import sys, json, struct, io
from PIL import Image

src, dst, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
b = open(src, 'rb').read()
jn = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + jn])
bo = 20 + jn
bn = struct.unpack('<I', b[bo:bo + 4])[0]
binc = b[bo + 8:bo + 8 + bn]
views = j['bufferViews']
chunks = [binc[v.get('byteOffset', 0):v.get('byteOffset', 0) + v['byteLength']] for v in views]
for im in j.get('images', []):
    if 'bufferView' not in im:
        continue
    pic = Image.open(io.BytesIO(chunks[im['bufferView']]))
    pic = pic.convert('RGBA' if pic.mode in ('RGBA', 'LA', 'P') else 'RGB')
    if max(pic.size) > size:
        pic = pic.resize((size, size), Image.LANCZOS)
    out = io.BytesIO(); pic.save(out, 'PNG', optimize=True)
    chunks[im['bufferView']] = out.getvalue(); im['mimeType'] = 'image/png'
blob = bytearray()
for v, c in zip(views, chunks):
    while len(blob) % 4:
        blob.append(0)
    v['byteOffset'] = len(blob); v['byteLength'] = len(c); blob += c
while len(blob) % 4:
    blob.append(0)
j['buffers'][0]['byteLength'] = len(blob)
js = json.dumps(j, separators=(',', ':')).encode()
while len(js) % 4:
    js += b' '
total = 12 + 8 + len(js) + 8 + len(blob)
open(dst, 'wb').write(b'glTF' + struct.pack('<II', 2, total) + struct.pack('<I', len(js)) + b'JSON' + js + struct.pack('<I', len(blob)) + b'BIN\x00' + bytes(blob))
print(dst, total // 1024, 'KB')
