import sys, json, struct
# Print the rest rotation of a few key bones so clips from different rigging jobs can be compared.
for p in sys.argv[1:]:
    b = open(p, 'rb').read(); n = struct.unpack('<I', b[12:16])[0]; j = json.loads(b[20:20 + n])
    d = {x.get('name'): x for x in j['nodes']}
    print(p)
    for k in ('Armature', 'Hips', 'LeftUpLeg', 'RightUpLeg', 'Spine', 'LeftArm', 'Head'):
        if k in d:
            print('  ', k.ljust(11), 'rot', [round(v, 3) for v in d[k].get('rotation', [0, 0, 0, 1])], 'pos', [round(v, 2) for v in d[k].get('translation', [0, 0, 0])], 'scale', [round(v, 3) for v in d[k].get('scale', [1, 1, 1])])
    print('   anim', [(a.get('name'), len(a['channels'])) for a in j.get('animations', [])])
