extends Node3D
# The meadow: ground, light, scenery, obstacles and the rewards worth walking to.

const ARENA_R := 74.0

var main
var env: Environment
var obstacles: Array = []   # Vector3(x, z, radius)
var static_obstacles: Array = []
var chests: Array = []
var shrines: Array = []
var jars: Array = []
var chest_timer := 0.0
var hive_mat: StandardMaterial3D
var poi_root: Node3D
var shrine_progress := -1.0
var time := 0.0
var rng := RandomNumberGenerator.new()

func setup(m) -> void:
	main = m
	rng.seed = 20261116
	_build_environment()
	_build_ground()
	_build_scenery()
	poi_root = Node3D.new()
	add_child(poi_root)

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.22, 0.5, 0.95)
	sm.sky_horizon_color = Color(0.72, 0.87, 1.0)
	sm.ground_horizon_color = Color(0.6, 0.8, 0.7)
	sm.ground_bottom_color = Color(0.35, 0.55, 0.3)
	sm.sun_angle_max = 12.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.86, 1.0)
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.6
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.86, 1.0)
	env.fog_density = 0.0007
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.06
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 38, 0)
	sun.light_color = Color(1.0, 0.96, 0.86)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_opacity = 0.65
	add_child(sun)

func set_brightness(v: float) -> void:
	env.adjustment_brightness = v

func _build_ground() -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	g.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform float arena = 74.0;
varying vec3 wp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = vec2(wp.x * 0.30 + wp.z * 0.12, wp.z * 0.30 - wp.x * 0.07);
	vec2 c = floor(p);
	vec2 f = fract(p);
	float tri = step(f.x + f.y, 1.0);
	float h = hash(c + vec2(tri * 7.3, tri * 1.7));
	float big = hash(floor(wp.xz * 0.05 + 3.0));
	vec3 col = mix(vec3(0.36, 0.63, 0.20), vec3(0.47, 0.73, 0.26), h);
	col *= 0.93 + 0.12 * big;
	float r = length(wp.xz);
	col = mix(col, vec3(0.27, 0.48, 0.19), smoothstep(arena - 3.0, arena + 4.0, r));
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("arena", ARENA_R)
	g.material_override = mat
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)

func _mm(mesh: Mesh, mat: Material, xfs: Array, cols: Array = [], shadows := true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not cols.is_empty()
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		if not cols.is_empty():
			mm.set_instance_color(i, cols[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	if mat != null:
		inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	return inst

func _free_spot(rmin: float, rmax: float, clearance: float) -> Vector2:
	for attempt in 60:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf_range(rmin * rmin, rmax * rmax))
		var p := Vector2(cos(a) * r, sin(a) * r)
		var ok := true
		for o in obstacles:
			if Vector2(o.x, o.y).distance_to(p) < o.z + clearance:
				ok = false
				break
		if ok:
			return p
	return Vector2(rmin, 0)

func _build_scenery() -> void:
	var tree_mesh: Mesh = main.assets.prop_mesh("agac")
	var tree_mat: Material = main.assets.prop_material("agac")
	var xfs: Array = []
	# a thick ring of trees closes the meadow
	for i in 170:
		var a := TAU * i / 170.0 + rng.randf_range(-0.02, 0.02)
		var r := ARENA_R + rng.randf_range(1.5, 16.0)
		var s := rng.randf_range(8.0, 13.0)
		xfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(cos(a) * r, 0, sin(a) * r)))
	# trees inside are obstacles
	for i in 20:
		var p := _free_spot(12.0, ARENA_R - 6.0, 6.0)
		var s2 := rng.randf_range(6.5, 9.0)
		xfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s2, s2, s2)), Vector3(p.x, 0, p.y)))
		obstacles.append(Vector3(p.x, p.y, 0.75))
	_mm(tree_mesh, tree_mat, xfs)
	# decorative hives
	var hive_mesh: Mesh = main.assets.prop_mesh("kovan")
	var hive_mat: Material = main.assets.prop_material("kovan")
	xfs = []
	for i in 9:
		var p2 := _free_spot(9.0, ARENA_R - 8.0, 5.0)
		xfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(2.6, 2.6, 2.6)), Vector3(p2.x, 0, p2.y)))
		obstacles.append(Vector3(p2.x, p2.y, 1.1))
	_mm(hive_mesh, hive_mat, xfs)
	# rocks
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 1.4
	rock.radial_segments = 7
	rock.rings = 3
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.58, 0.58, 0.62)
	rmat.roughness = 0.95
	xfs = []
	for i in 34:
		var p3 := _free_spot(8.0, ARENA_R - 3.0, 3.0)
		var s3 := rng.randf_range(0.5, 1.7)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s3 * rng.randf_range(0.8, 1.3), s3 * rng.randf_range(0.6, 1.0), s3))
		xfs.append(Transform3D(b, Vector3(p3.x, s3 * 0.15, p3.y)))
		if s3 > 1.0:
			obstacles.append(Vector3(p3.x, p3.y, s3 * 0.95))
	_mm(rock, rmat, xfs)
	static_obstacles = obstacles.duplicate()
	# flowers and grass tufts: colour and shape only, no collisions
	# flowers: a thin stem and a flat head, in loose patches
	var head := CylinderMesh.new()
	head.top_radius = 0.11
	head.bottom_radius = 0.05
	head.height = 0.05
	head.radial_segments = 6
	head.rings = 1
	var stem := BoxMesh.new()
	stem.size = Vector3(0.03, 1.0, 0.03)
	var fmat := StandardMaterial3D.new()
	fmat.vertex_color_use_as_albedo = true
	fmat.roughness = 0.9
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.25, 0.5, 0.16)
	smat.roughness = 0.95
	xfs = []
	var stems: Array = []
	var cols: Array = []
	var palette := [Color(1, 1, 0.95), Color(1.0, 0.85, 0.2), Color(0.66, 0.42, 0.9), Color(1.0, 0.6, 0.75)]
	for patch in 150:
		var ca := rng.randf() * TAU
		var cr := sqrt(rng.randf()) * (ARENA_R + 4.0)
		var centre := Vector2(cos(ca) * cr, sin(ca) * cr)
		var col: Color = palette[rng.randi() % palette.size()]
		for i in rng.randi_range(4, 11):
			var p4 := centre + Vector2(rng.randf_range(-1.6, 1.6), rng.randf_range(-1.6, 1.6))
			var h4 := rng.randf_range(0.14, 0.3)
			var s4 := rng.randf_range(0.8, 1.3)
			var tilt := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.35, 0.35))
			xfs.append(Transform3D(tilt.scaled(Vector3(s4, s4, s4)), Vector3(p4.x, h4, p4.y)))
			stems.append(Transform3D(Basis.from_scale(Vector3(1, h4, 1)), Vector3(p4.x, h4 * 0.5, p4.y)))
			cols.append(col.lerp(Color.WHITE, rng.randf() * 0.2))
	_mm(head, fmat, xfs, cols, false)
	_mm(stem, smat, stems, [], false)
	# grass: clumps of three thin blades
	var blade := PrismMesh.new()
	blade.size = Vector3(0.1, 0.42, 0.02)
	var tmat := StandardMaterial3D.new()
	tmat.vertex_color_use_as_albedo = true
	tmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tmat.roughness = 0.95
	xfs = []
	cols = []
	for i in 1700:
		var a3 := rng.randf() * TAU
		var r3 := sqrt(rng.randf()) * (ARENA_R + 6.0)
		var base := Vector3(cos(a3) * r3, 0, sin(a3) * r3)
		var gcol := Color(0.26, 0.52, 0.15).lerp(Color(0.36, 0.62, 0.18), rng.randf())
		var yaw0 := rng.randf() * TAU
		for k in 3:
			var s5 := rng.randf_range(0.7, 1.35)
			var yw := yaw0 + TAU * k / 3.0
			var bb := Basis(Vector3.UP, yw) * Basis(Vector3.RIGHT, rng.randf_range(0.15, 0.45))
			var off := Vector3(sin(yw), 0, cos(yw)) * 0.07
			xfs.append(Transform3D(bb.scaled(Vector3(s5, s5, s5)), base + off + Vector3(0, 0.19 * s5, 0)))
			cols.append(gcol)
	_mm(blade, tmat, xfs, cols, false)
	# far hills
	var hill := CylinderMesh.new()
	hill.top_radius = 0.0
	hill.bottom_radius = 1.0
	hill.height = 1.0
	hill.radial_segments = 6
	hill.rings = 1
	var hmat := StandardMaterial3D.new()
	hmat.vertex_color_use_as_albedo = true
	hmat.roughness = 1.0
	xfs = []
	cols = []
	for i in 16:
		var a4 := TAU * i / 16.0 + rng.randf_range(-0.1, 0.1)
		var r4 := rng.randf_range(210.0, 300.0)
		var h := rng.randf_range(50.0, 110.0)
		var w := rng.randf_range(70.0, 120.0)
		xfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(w, h, w)), Vector3(cos(a4) * r4, h * 0.5 - 4.0, sin(a4) * r4)))
		cols.append(Color(0.3, 0.52, 0.45).lerp(Color(0.42, 0.6, 0.62), rng.randf()))
	_mm(hill, hmat, xfs, cols, false)

func _beam(col: Color, height: float) -> MeshInstance3D:
	var b := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.12
	c.bottom_radius = 0.32
	c.height = height
	c.radial_segments = 8
	c.rings = 1
	b.mesh = c
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r, col.g, col.b, 0.22)
	m.disable_fog = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	b.material_override = m
	b.position.y = height * 0.5
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return b

# New reward layout every run, so exploring stays worth it.
func reset() -> void:
	for c in poi_root.get_children():
		c.queue_free()
	chests.clear()
	shrines.clear()
	jars.clear()
	obstacles = static_obstacles.duplicate()
	rng.randomize()
	shrine_progress = -1.0
	hive_mat = main.assets.prop_material("kovan")
	hive_mat.emission_enabled = true
	hive_mat.emission = Color(1.0, 0.8, 0.2)
	hive_mat.emission_energy_multiplier = 0.35
	# two chests wait far out at the start; more appear during the run
	chest_timer = 70.0
	var a0 := rng.randf() * TAU
	spawn_chest(a0, rng.randf_range(44.0, 60.0))
	spawn_chest(a0 + PI + rng.randf_range(-0.6, 0.6), rng.randf_range(44.0, 60.0))
	var sh_mesh: Mesh = main.assets.prop_mesh("sunak")
	for i in 4:
		var a2 := TAU * i / 4.0 + rng.randf_range(0.2, 1.2)
		var p2 := _spot_near(a2, rng.randf_range(34.0, 58.0))
		var n2 := Node3D.new()
		n2.position = Vector3(p2.x, 0, p2.y)
		var mi2 := MeshInstance3D.new()
		mi2.mesh = sh_mesh
		mi2.material_override = main.assets.prop_material("sunak")
		mi2.scale = Vector3.ONE * 3.4
		n2.add_child(mi2)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 4.75
		tm.outer_radius = 5.0
		tm.rings = 48
		tm.ring_segments = 4
		ring.mesh = tm
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.albedo_color = Color(0.2, 0.9, 0.8)
		ring.material_override = rm
		ring.position.y = 0.08
		ring.scale.y = 0.3
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n2.add_child(ring)
		var beam := _beam(Color(0.2, 0.95, 0.85), 30.0)
		n2.add_child(beam)
		poi_root.add_child(n2)
		obstacles.append(Vector3(p2.x, p2.y, 1.5))
		shrines.append({"node": n2, "pos": Vector3(p2.x, 0, p2.y), "charge": 0.0, "done": false, "ring": rm, "beam": beam})
	var jar_mesh: Mesh = main.assets.prop_mesh("kavanoz")
	for i in 7:
		var p3 := _free_spot(14.0, ARENA_R - 6.0, 3.0)
		var mi3 := MeshInstance3D.new()
		mi3.mesh = jar_mesh
		mi3.material_override = main.assets.prop_material("kavanoz")
		mi3.scale = Vector3.ONE * 1.1
		mi3.position = Vector3(p3.x, 0.2, p3.y)
		poi_root.add_child(mi3)
		jars.append({"node": mi3, "pos": Vector3(p3.x, 0, p3.y), "taken": false})

func spawn_chest(angle: float, radius: float) -> void:
	var p := _spot_near(angle, radius)
	var n := Node3D.new()
	n.position = Vector3(p.x, 0, p.y)
	var mi := MeshInstance3D.new()
	mi.mesh = main.assets.prop_mesh("kovan")
	mi.material_override = hive_mat
	mi.scale = Vector3.ONE * 2.0
	n.add_child(mi)
	n.add_child(_beam(Color(1.0, 0.8, 0.2), 30.0))
	poi_root.add_child(n)
	chests.append({"node": n, "mesh": mi, "pos": Vector3(p.x, 0, p.y), "open": false})

func _unopened() -> int:
	var n := 0
	for c in chests:
		if not c.open:
			n += 1
	return n

func _spot_near(angle: float, radius: float) -> Vector2:
	var best := Vector2(cos(angle) * radius, sin(angle) * radius)
	for attempt in 20:
		var p := best + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)) * float(attempt) * 0.3
		var ok := true
		for o in obstacles:
			if Vector2(o.x, o.y).distance_to(p) < o.z + 4.0:
				ok = false
				break
		if ok and p.length() < ARENA_R - 7.0:
			return p
	return best

func update(dt: float) -> void:
	time += dt
	var pl = main.player
	var p: Vector3 = pl.pos
	# a new chest appears on the far side of the meadow every 70 seconds, at most three wait at once
	chest_timer -= dt
	if chest_timer <= 0.0:
		chest_timer = 70.0
		if _unopened() < 3 and main.game.active and not main.game.boss_spawned:
			var away := atan2(-p.z, -p.x) + rng.randf_range(-0.9, 0.9)
			if Vector2(p.x, p.z).length() < 12.0:
				away = rng.randf() * TAU
			spawn_chest(away, rng.randf_range(40.0, 62.0))
			main.ui.toast("Uzakta bir sandık belirdi")
			main.audio.play("heal", -4.0, 0.8)
	for c in chests:
		if c.open:
			continue
		c.mesh.rotation.y += dt * 0.8
		c.mesh.position.y = 0.15 + sin(time * 2.0) * 0.12
		if Vector2(p.x - c.pos.x, p.z - c.pos.z).length() < 2.4:
			c.open = true
			c.node.visible = false
			main.fx.burst(c.pos + Vector3(0, 1.2, 0), Color(1.0, 0.85, 0.2), 28, 8.0)
			main.audio.play("chest")
			main.game.open_chest()
	shrine_progress = -1.0
	for s in shrines:
		if s.done:
			continue
		var d := Vector2(p.x - s.pos.x, p.z - s.pos.z).length()
		if d < 5.0:
			s.charge = minf(1.0, s.charge + dt / 5.0)
			shrine_progress = s.charge
			s.ring.albedo_color = Color(0.2, 0.9, 0.8).lerp(Color(1.0, 0.9, 0.3), s.charge)
			if s.charge >= 1.0:
				s.done = true
				s.ring.albedo_color = Color(0.4, 0.4, 0.45)
				s.beam.visible = false
				main.game.shrine_done(s.pos)
		else:
			s.charge = maxf(0.0, s.charge - dt * 0.25)
	for j in jars:
		if j.taken:
			continue
		j.node.rotation.y += dt * 1.5
		j.node.position.y = 0.3 + sin(time * 2.5 + j.pos.x) * 0.12
		if pl.hp < pl.max_hp and Vector2(p.x - j.pos.x, p.z - j.pos.z).length() < 1.7:
			j.taken = true
			j.node.visible = false
			pl.heal(35.0)
			main.fx.burst(j.pos + Vector3(0, 1.0, 0), Color(1.0, 0.5, 0.5), 14, 5.0)
			main.audio.play("heal")
			main.ui.toast("+35 can")
