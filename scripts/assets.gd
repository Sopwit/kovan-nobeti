extends RefCounted
# Loads the generated models, normalises them and builds the small code-made meshes.

const MODEL_DIR := "res://assets/models/"
# key -> [what "1 unit" means: "h" height or "w" widest horizontal side, yaw fix in degrees]
const NORM := {
	"bocek": ["w", 0.0], "esekarisi": ["w", 90.0], "gergedan": ["w", 0.0], "tukuren": ["w", 0.0], "kralice": ["w", 0.0],
	"kovan": ["h", 0.0], "sunak": ["h", 0.0], "agac": ["h", 0.0], "kavanoz": ["h", 0.0],
}
# how much each generated texture is darkened (1 = as is)
const GRADE := {"bocek": 1.7, "esekarisi": 1.15, "gergedan": 1.25, "tukuren": 1.15, "kralice": 1.2}
# shader motion per model: leg height, leg swing, stride speed, wing start (distance from the body axis),
# wing height, wing swing. Unit model space.
const ANIM_KEYS := ["leg_h", "leg_amp", "stride", "wing_x", "wing_y", "wing_amp"]
const ANIM := {
	"bocek": [0.16, 0.08, 14.0, 0.0, 0.0, 1.0],
	"esekarisi": [0.0, 0.0, 0.0, 0.14, 0.2, 0.9],
	"gergedan": [0.16, 0.06, 8.0, 0.0, 0.0, 1.0],
	"tukuren": [0.14, 0.07, 9.0, 0.0, 0.0, 1.0],
	"kralice": [0.14, 0.04, 6.0, 0.0, 0.0, 1.0],
}
const FALLBACK_COL := {
	"bocek": Color(0.5, 0.2, 0.7), "esekarisi": Color(0.9, 0.2, 0.2), "gergedan": Color(0.3, 0.25, 0.7),
	"tukuren": Color(0.95, 0.3, 0.6), "kralice": Color(0.8, 0.1, 0.2), "kovan": Color(0.95, 0.7, 0.15),
	"sunak": Color(0.6, 0.6, 0.65), "agac": Color(0.35, 0.65, 0.2), "kavanoz": Color(1.0, 0.7, 0.1),
}

var meshes := {}
var textures := {}
var enemy_shader: Shader
var _aura_shader: Shader
var _blob: Texture2D
var icon_sheet: Texture2D
var retarget_info := {}

func _init() -> void:
	enemy_shader = Shader.new()
	enemy_shader.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float use_tex = 1.0;
uniform float grade = 1.0;
// The generated models are rigid, so the shader moves them: vertices near the ground are legs that
// scuttle in alternating groups, vertices far out to the sides and high up are wings that beat.
// Model space is unit sized, base on y = 0, facing +Z. INSTANCE_CUSTOM = (hit flash, phase, activity).
uniform float leg_h = 0.14;
uniform float leg_amp = 0.07;
uniform float stride = 11.0;
uniform float wing_x = 0.0;
uniform float wing_y = 0.0;
uniform float wing_amp = 1.0;
varying float fl;
const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void vertex() {
	fl = INSTANCE_CUSTOM.x;
	float ph = INSTANCE_CUSTOM.y;
	float act = INSTANCE_CUSTOM.z;
	vec3 v = VERTEX;
	if (wing_x > 0.0) {
		float w = max(0.0, abs(v.x) - wing_x) * step(wing_y, v.y);
		v.y += w * sin(TIME * 52.0 + ph) * wing_amp * act;
	}
	if (leg_h > 0.0 && v.y < leg_h) {
		float k = 1.0 - v.y / leg_h;
		float band = floor(v.z * 5.0);
		float side = step(0.0, v.x);
		float a = TIME * stride + ph + (band + side) * 3.14159;
		v.z += sin(a) * leg_amp * k * act;
		v.y += max(0.0, cos(a)) * leg_amp * 0.6 * k * act;
	}
	VERTEX = v;
}
void fragment() {
	// bodies that come between the camera and the player dissolve instead of blocking the view
	float near = smoothstep(1.5, 4.5, length(VERTEX));
	int bx = int(FRAGCOORD.x) % 4;
	int by = int(FRAGCOORD.y) % 4;
	if (near < (BAYER[bx + by * 4] + 0.5) / 16.0) { discard; }
	vec3 c = mix(tint.rgb, texture(tex, UV).rgb, use_tex);
	// image-to-3D washes the texture out; grade pulls it back towards the source image
	c = pow(c, vec3(grade));
	float l = dot(c, vec3(0.3, 0.6, 0.1));
	c = mix(vec3(l), c, 1.0 + (grade - 1.0) * 0.5) * COLOR.rgb;
	ALBEDO = mix(c, vec3(1.0), fl * 0.6);
	EMISSION = vec3(1.0, 0.9, 0.7) * fl * 0.5;
	ROUGHNESS = 0.8;
}
"""
	_aura_shader = Shader.new()
	_aura_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float pulse = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float swirl = sin(a * 6.0 + TIME * 1.6 + r * 5.0) * 0.5 + 0.5;
	float ring = smoothstep(0.88, 0.96, r) * (1.0 - smoothstep(0.97, 1.0, r));
	float wisp = smoothstep(0.45, 0.9, r) * (1.0 - smoothstep(0.9, 1.0, r)) * swirl;
	ALBEDO = mix(vec3(0.86, 0.9, 0.82), vec3(1.0, 0.9, 0.55), pulse * 0.6);
	ALPHA = clamp((ring * 0.3 + wisp * 0.07) * (1.0 + pulse * 0.6), 0.0, 0.45);
}
"""
	if ResourceLoader.exists("res://assets/tex/ikonlar.png"):
		icon_sheet = load("res://assets/tex/ikonlar.png")

func _find_mesh_instances(n: Node, out: Array) -> void:
	if n is MeshInstance3D and n.mesh != null:
		out.append(n)
	for c in n.get_children():
		_find_mesh_instances(c, out)

# Bakes the node transform into the vertices, puts the base on y=0, centres XZ and scales to one unit.
func _load_normalized(key: String) -> void:
	var path: String = MODEL_DIR + key + ".glb"
	if not ResourceLoader.exists(path):
		return
	var scene: Node = (load(path) as PackedScene).instantiate()
	var list: Array = []
	_find_mesh_instances(scene, list)
	if list.is_empty():
		scene.free()
		return
	var mi: MeshInstance3D = list[0]
	var xf := Transform3D.IDENTITY
	var n: Node = mi
	while n != null and n is Node3D:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	var yaw_fix: float = NORM[key][1]
	xf = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_fix)), Vector3.ZERO) * xf
	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := -lo
	for i in verts.size():
		var v: Vector3 = xf * verts[i]
		verts[i] = v
		lo = lo.min(v)
		hi = hi.max(v)
	var size := hi - lo
	var mode: String = NORM[key][0]
	var unit: float = size.y if mode == "h" else maxf(size.x, size.z)
	var s := 1.0 / maxf(unit, 0.001)
	var off := Vector3((lo.x + hi.x) * 0.5, lo.y, (lo.z + hi.z) * 0.5)
	for i in verts.size():
		verts[i] = (verts[i] - off) * s
	var nb := xf.basis.orthonormalized()
	for i in norms.size():
		norms[i] = nb * norms[i]
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = norms
	out[Mesh.ARRAY_TEX_UV] = arrays[Mesh.ARRAY_TEX_UV]
	out[Mesh.ARRAY_INDEX] = arrays[Mesh.ARRAY_INDEX]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	meshes[key] = am
	var mat: Material = mi.get_active_material(0)
	if mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture != null:
		textures[key] = (mat as BaseMaterial3D).albedo_texture
	scene.free()

func _mesh(key: String) -> Mesh:
	if not meshes.has(key):
		_load_normalized(key)
	if not meshes.has(key):
		var b := BoxMesh.new()
		b.size = Vector3(0.7, 0.6, 1.0)
		var am := ArrayMesh.new()
		var arr: Array = b.get_mesh_arrays()
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in v.size():
			v[i] += Vector3(0, 0.3, 0)
		arr[Mesh.ARRAY_VERTEX] = v
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		meshes[key] = am
	return meshes[key]

func enemy_mesh(key: String) -> Mesh:
	return _mesh(key)

func enemy_material(key: String) -> ShaderMaterial:
	_mesh(key)
	var m := ShaderMaterial.new()
	m.shader = enemy_shader
	m.set_shader_parameter("grade", GRADE.get(key, 1.0))
	var an: Array = ANIM.get(key, [0.14, 0.07, 11.0, 0.0, 0.0, 1.0])
	for ai in ANIM_KEYS.size():
		m.set_shader_parameter(ANIM_KEYS[ai], an[ai])
	if textures.has(key):
		m.set_shader_parameter("tex", textures[key])
		m.set_shader_parameter("use_tex", 1.0)
	else:
		m.set_shader_parameter("use_tex", 0.0)
		m.set_shader_parameter("tint", FALLBACK_COL.get(key, Color.WHITE))
	return m

func prop_mesh(key: String) -> Mesh:
	return _mesh(key)

func prop_material(key: String, fade_near := false) -> StandardMaterial3D:
	_mesh(key)
	var m := StandardMaterial3D.new()
	m.roughness = 0.85
	if fade_near:
		# scenery between the camera and the player dissolves
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
		m.distance_fade_min_distance = 3.0
		m.distance_fade_max_distance = 9.0
	if textures.has(key):
		m.albedo_texture = textures[key]
	else:
		m.albedo_color = FALLBACK_COL.get(key, Color.WHITE)
	return m

# clip -> [file, start fraction, end fraction, playback length in seconds (0 keeps the source length), loop,
#          yaw correction in degrees: the source idle and jump clips stand turned 43 degrees to one side]
const CLIPS := {
	"idle": ["arici_idle", 0.0, 1.0, 0.0, true, 43.4],
	"jump": ["arici_jump", 0.36, 0.58, 0.6, false, 43.2],
	"slide": ["arici_slide", 0.14, 0.5, 0.42, false, -15.0],
}

# The extra clips were rigged by separate jobs and their skeletons differ from the main one
# (hip joint 17 cm lower, other bone lengths). They are moved onto the main skeleton here.
func build_hero(raw_clips := false) -> Dictionary:
	var root := Node3D.new()
	var anim: AnimationPlayer = null
	var path: String = MODEL_DIR + "arici.glb"
	if ResourceLoader.exists(path):
		var scene: Node3D = (load(path) as PackedScene).instantiate()
		root.add_child(scene)
		anim = _find_anim(scene)
		var sk := _find_skeleton(scene)
		var list: Array = []
		_find_mesh_instances(scene, list)
		if anim != null and sk != null and not list.is_empty():
			var lib: AnimationLibrary = anim.get_animation_library(anim.get_animation_library_list()[0])
			var first: String = lib.get_animation_list()[0]
			var run: Animation = lib.get_animation(first)
			_prepare_clip(run, true)
			if first != "run":
				lib.add_animation("run", run)
			var prefix := ""
			for t in run.get_track_count():
				var tp := str(run.track_get_path(t))
				if tp.contains(":"):
					prefix = tp.substr(0, tp.rfind(":") + 1)
					break
			var main_bind := _bind_globals(sk, (list[0] as MeshInstance3D).skin)
			for clip in CLIPS:
				var spec: Array = CLIPS[clip]
				var cp: String = MODEL_DIR + str(spec[0]) + ".glb"
				if not ResourceLoader.exists(cp):
					continue
				var cs: Node = (load(cp) as PackedScene).instantiate()
				var ca := _find_anim(cs)
				var csk := _find_skeleton(cs)
				var clist: Array = []
				_find_mesh_instances(cs, clist)
				if ca != null and csk != null and not clist.is_empty():
					var src: Animation = ca.get_animation(ca.get_animation_list()[0])
					var a0: float = 0.0 if raw_clips else float(spec[1])
					var a1: float = 1.0 if raw_clips else float(spec[2])
					var dur: float = 0.0 if raw_clips else float(spec[3])
					var out := _retarget(src, csk, _bind_globals(csk, (clist[0] as MeshInstance3D).skin), sk, main_bind, prefix, a0, a1, dur, clip == "jump", deg_to_rad(float(spec[5])))
					out.loop_mode = Animation.LOOP_LINEAR if spec[4] else Animation.LOOP_NONE
					lib.add_animation(clip, out)
				cs.free()
	else:
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.75
		body.mesh = cap
		body.position.y = 0.875
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.95, 0.9, 0.8)
		body.material_override = bm
		root.add_child(body)
	return {"node": root, "anim": anim}

func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find_skeleton(c)
		if r != null:
			return r
	return null

# Bone name -> global bind transform, taken from the skin (the node rest pose is not always the bind pose).
func _bind_globals(sk: Skeleton3D, skin: Skin) -> Dictionary:
	var out := {}
	if skin != null:
		for i in skin.get_bind_count():
			var bname := str(skin.get_bind_name(i))
			if bname == "":
				var bi := skin.get_bind_bone(i)
				if bi >= 0:
					bname = sk.get_bone_name(bi)
			if bname != "":
				out[bname] = skin.get_bind_pose(i).affine_inverse()
	for b in sk.get_bone_count():
		var n := sk.get_bone_name(b)
		if not out.has(n):
			out[n] = sk.get_bone_global_rest(b)
	return out

# Samples the source clip, turns every bone pose into a model-space rotation relative to its bind,
# and rebuilds that rotation on the destination skeleton. Bone lengths stay those of the destination.
func _retarget(src: Animation, ssk: Skeleton3D, sbind: Dictionary, dsk: Skeleton3D, dbind: Dictionary, prefix: String, f0: float, f1: float, dur: float, no_rise: bool, yaw_fix: float) -> Animation:
	var out := Animation.new()
	var turn := Basis(Vector3.UP, yaw_fix)
	var t0 := src.length * f0
	var t1 := src.length * f1
	var span := maxf(0.05, t1 - t0)
	var length := dur if dur > 0.0 else span
	out.length = length
	var steps := maxi(2, int(ceil(span * 30.0)))
	# source tracks by bone name
	var rot_t := {}
	var pos_t := {}
	for t in src.get_track_count():
		var tp := str(src.track_get_path(t))
		var bn := tp.substr(tp.rfind(":") + 1)
		if src.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			rot_t[bn] = t
		elif src.track_get_type(t) == Animation.TYPE_POSITION_3D:
			pos_t[bn] = t
	var sn := ssk.get_bone_count()
	var dn := dsk.get_bone_count()
	var d_rot_tracks := {}
	for b in dn:
		var ti := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(ti, NodePath(prefix + dsk.get_bone_name(b)))
		d_rot_tracks[b] = ti
	# the hips also get a position track
	var hips_d := dsk.find_bone("Hips")
	var hips_s := ssk.find_bone("Hips")
	var hips_track := -1
	if hips_d >= 0 and hips_s >= 0:
		hips_track = out.add_track(Animation.TYPE_POSITION_3D)
		out.track_set_path(hips_track, NodePath(prefix + "Hips"))
	# leg length ratio between the two rigs, measured from the lowest bone up to the hips
	var ratio := 1.0
	var s_hips_rest := Vector3.ZERO
	var d_hips_rest := Vector3.ZERO
	if hips_track >= 0:
		var s_low := 1e9
		var d_low := 1e9
		for key in sbind:
			s_low = minf(s_low, _bind_pos(sbind[key]).y)
		for key in dbind:
			d_low = minf(d_low, _bind_pos(dbind[key]).y)
		s_hips_rest = _bind_pos(sbind["Hips"])
		d_hips_rest = _bind_pos(dbind["Hips"])
		var s_leg := s_hips_rest.y - s_low
		var d_leg := d_hips_rest.y - d_low
		if s_leg > 0.001:
			ratio = d_leg / s_leg
		retarget_info = {"src_hips": s_hips_rest, "dst_hips": d_hips_rest, "src_low": s_low, "dst_low": d_low, "ratio": ratio, "src_len": src.length}
	var sg: Array[Transform3D] = []
	sg.resize(sn)
	var dg: Array[Basis] = []
	dg.resize(dn)
	for k in steps + 1:
		var u := float(k) / float(steps)
		var ts := t0 + span * u
		var td := length * u
		# source global poses (bones are stored parents first)
		for b in sn:
			var bn2 := ssk.get_bone_name(b)
			var loc := ssk.get_bone_rest(b)
			if rot_t.has(bn2):
				loc.basis = Basis(src.rotation_track_interpolate(rot_t[bn2], ts))
			if pos_t.has(bn2):
				loc.origin = src.position_track_interpolate(pos_t[bn2], ts)
			var par := ssk.get_bone_parent(b)
			sg[b] = loc if par < 0 else sg[par] * loc
		# destination global rotations
		for b in dn:
			var bn3 := dsk.get_bone_name(b)
			var sb := ssk.find_bone(bn3)
			var db: Transform3D = dbind[bn3]
			if sb >= 0 and sbind.has(bn3):
				var sbt: Transform3D = sbind[bn3]
				var delta := sg[sb].basis.orthonormalized() * sbt.basis.orthonormalized().inverse()
				dg[b] = turn * delta * db.basis.orthonormalized()
			else:
				dg[b] = db.basis.orthonormalized()
		for b in dn:
			var par2 := dsk.get_bone_parent(b)
			var lb: Basis = dg[b] if par2 < 0 else dg[par2].inverse() * dg[b]
			out.rotation_track_insert_key(d_rot_tracks[b], td, lb.get_rotation_quaternion())
		if hips_track >= 0:
			var dy := (sg[hips_s].origin.y - s_hips_rest.y) * ratio
			if no_rise:
				dy = minf(dy, 0.0)
			out.position_track_insert_key(hips_track, td, Vector3(d_hips_rest.x, d_hips_rest.y + dy, d_hips_rest.z))
	return out

# Position of a bind transform in skeleton units (the skin bakes the armature scale into the basis).
func _bind_pos(xf: Transform3D) -> Vector3:
	var s := xf.basis.get_scale().x
	return xf.origin / maxf(s, 0.000001)

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

# Loop where wanted and pin the hips in place so clips never drift away from the player node.
func _prepare_clip(a: Animation, loop: bool) -> void:
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		var p := str(a.track_get_path(t))
		if not p.ends_with(":Hips"):
			continue
		var n := a.track_get_key_count(t)
		if n == 0:
			continue
		var first: Vector3 = a.track_get_key_value(t, 0)
		for k in n:
			var v: Vector3 = a.track_get_key_value(t, k)
			a.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))

func bee_mesh() -> Mesh:
	var s := SphereMesh.new()
	s.radius = 0.2
	s.height = 0.4
	s.radial_segments = 8
	s.rings = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.82, 0.1)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.75, 0.1)
	m.emission_energy_multiplier = 1.6
	s.material = m
	return s

func stinger_mesh() -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.2
	c.height = 1.0
	c.radial_segments = 6
	c.rings = 1
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.6, 0.1)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.5, 0.05)
	m.emission_energy_multiplier = 1.8
	c.material = m
	return c

func bolt_mesh() -> Mesh:
	var b := BoxMesh.new()
	b.size = Vector3(0.07, 0.07, 1.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.95, 0.5)
	b.material = m
	return b

func gem_mesh() -> Mesh:
	var s := SphereMesh.new()
	s.radius = 0.22
	s.height = 0.5
	s.radial_segments = 5
	s.rings = 1
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.1)
	m.emission_energy_multiplier = 0.5
	m.roughness = 0.3
	s.material = m
	return s

func aura_shader() -> Shader:
	return _aura_shader

func blob_texture() -> Texture2D:
	if _blob == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 64
		t.height = 64
		_blob = t
	return _blob

# Icons come from one generated 5x4 sheet; the ragged tile border of each cell is cropped away.
func icon(i: int) -> Texture2D:
	if icon_sheet == null:
		return null
	var a := AtlasTexture.new()
	a.atlas = icon_sheet
	var cw := icon_sheet.get_width() / 5.0
	var ch := icon_sheet.get_height() / 4.0
	var m := 0.11
	@warning_ignore("integer_division")
	var row := i / 5
	a.region = Rect2((i % 5) * cw + cw * m, row * ch + ch * m, cw * (1.0 - 2.0 * m), ch * (1.0 - 2.0 * m))
	return a
