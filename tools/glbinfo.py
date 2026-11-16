import sys, json, struct
# Summarise a GLB: mesh sizes, bounds, images, skins and animations.
for p in sys.argv[1:]:
    b = open(p, 'rb').read(); n = struct.unpack('<I', b[12:16])[0]; j = json.loads(b[20:20 + n])
    acc = j.get('accessors', [])
    print(p, len(b) // 1024, 'KB')
    for m in j.get('meshes', []):
        for pr in m['primitives']:
            pos = acc[pr['attributes']['POSITION']]
            idx = acc[pr['indices']]['count'] // 3 if 'indices' in pr else pos['count'] // 3
            print('  mesh', m.get('name'), 'verts', pos['count'], 'tris', idx, 'min', [round(v, 2) for v in pos['min']], 'max', [round(v, 2) for v in pos['max']], 'attrs', list(pr['attributes']))
    print('  images', [(i.get('mimeType'), j['bufferViews'][i['bufferView']]['byteLength'] // 1024) for i in j.get('images', []) if 'bufferView' in i])
    print('  materials', [(m.get('name'), list(m.get('pbrMetallicRoughness', {}).keys())) for m in j.get('materials', [])])
    print('  nodes', len(j.get('nodes', [])), 'skins', [len(s['joints']) for s in j.get('skins', [])], 'anims', [(a.get('name'), len(a['channels'])) for a in j.get('animations', [])])
    for nd in j.get('nodes', [])[:6]:
        print('   node', nd.get('name'), {k: nd[k] for k in ('scale', 'rotation', 'translation') if k in nd})
