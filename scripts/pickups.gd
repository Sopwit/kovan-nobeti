extends Node3D
# Experience drops (honey) and the rare items elites leave behind.

const GMAX := 500

var main
var gx := PackedFloat32Array()
var gz := PackedFloat32Array()
var gy := PackedFloat32Array()
var gval := PackedInt32Array()
var gpull := PackedByteArray()
var gspeed := PackedFloat32Array()
var gn := 0
var mm: MultiMesh
var items: Array = []
var time := 0.0
var combo := 0
var combo_t := 0.0

func setup(m) -> void:
	main = m
	for arr in [gx, gz, gy, gspeed]:
		arr.resize(GMAX)
	gval.resize(GMAX)
	gpull.resize(GMAX)
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = main.assets.gem_mesh()
	mm.instance_count = GMAX
	mm.visible_instance_count = 0
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.custom_aabb = AABB(Vector3(-200, -5, -200), Vector3(400, 40, 400))
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)

func reset() -> void:
	gn = 0
	mm.visible_instance_count = 0
	for it in items:
		it.node.queue_free()
	items.clear()

func drop_gem(at: Vector3, value: int) -> void:
	if gn >= GMAX:
		# the field is full: fold the value into a random gem instead of losing it
		var k := randi() % gn
		gval[k] += value
		return
	var i := gn
	gn += 1
	gx[i] = at.x + randf_range(-0.4, 0.4)
	gz[i] = at.z + randf_range(-0.4, 0.4)
	gy[i] = 0.45
	gval[i] = value
	gpull[i] = 0
	gspeed[i] = 0.0

func drop_item(kind: String, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	if kind == "chest":
		mi.mesh = main.assets.prop_mesh("kovan")
		var m: StandardMaterial3D = main.assets.prop_material("kovan")
		m.emission_enabled = true
		m.emission = Color(1.0, 0.8, 0.2)
		m.emission_energy_multiplier = 0.6
		mi.material_override = m
		mi.scale = Vector3.ONE * 1.2
	elif kind == "heal":
		mi.mesh = main.assets.prop_mesh("kavanoz")
		var mh: StandardMaterial3D = main.assets.prop_material("kavanoz")
		mh.emission_enabled = true
		mh.emission = Color(1.0, 0.4, 0.5)
		mh.emission_energy_multiplier = 0.5
		mi.material_override = mh
		mi.scale = Vector3.ONE * 0.75
	else:
		var tm := TorusMesh.new()
		tm.inner_radius = 0.3
		tm.outer_radius = 0.55
		tm.rings = 12
		tm.ring_segments = 6
		mi.mesh = tm
		var m2 := StandardMaterial3D.new()
		m2.albedo_color = Color(0.3, 0.8, 1.0)
		m2.emission_enabled = true
		m2.emission = Color(0.2, 0.7, 1.0)
		m2.emission_energy_multiplier = 1.5
		mi.material_override = m2
		mi.rotation.x = PI * 0.5
	mi.position = Vector3(at.x, 0.5, at.z)
	add_child(mi)
	items.append({"node": mi, "kind": kind, "pos": Vector3(at.x, 0, at.z)})

func count_of(kind: String) -> int:
	var n := 0
	for it in items:
		if it.kind == kind:
			n += 1
	return n

func pull_all() -> void:
	for i in gn:
		gpull[i] = 1

func update(dt: float) -> void:
	time += dt
	combo_t -= dt
	if combo_t <= 0.0:
		combo = 0
	var pl = main.player
	var px: float = pl.pos.x
	var pz: float = pl.pos.z
	var py: float = pl.pos.y + 0.9
	var pr: float = pl.pickup_r
	var pr2 := pr * pr
	var i := 0
	var got := 0
	while i < gn:
		var dx := px - gx[i]
		var dz := pz - gz[i]
		var d2 := dx * dx + dz * dz
		if gpull[i] == 0 and d2 < pr2:
			gpull[i] = 1
		var taken := false
		if gpull[i] == 1:
			gspeed[i] = minf(gspeed[i] + dt * 60.0, 34.0)
			var d := sqrt(d2) + 0.001
			var step := gspeed[i] * dt
			if d <= step + 0.5:
				taken = true
			else:
				gx[i] += dx / d * step
				gz[i] += dz / d * step
				gy[i] = lerpf(gy[i], py, minf(1.0, dt * 8.0))
		if taken:
			got += gval[i]
			var l := gn - 1
			gx[i] = gx[l]; gz[i] = gz[l]; gy[i] = gy[l]; gval[i] = gval[l]; gpull[i] = gpull[l]; gspeed[i] = gspeed[l]
			gn = l
		else:
			var v := gval[i]
			var s := 1.0 if v < 5 else (1.4 if v < 20 else 1.9)
			var b := Basis(Vector3.UP, time * 2.0 + gx[i]).scaled(Vector3(s, s, s))
			mm.set_instance_transform(i, Transform3D(b, Vector3(gx[i], gy[i] + sin(time * 3.0 + gz[i]) * 0.08, gz[i])))
			mm.set_instance_color(i, Color(1.0, 0.72, 0.1) if v < 5 else (Color(0.2, 0.9, 0.8) if v < 20 else Color(1.0, 0.35, 0.8)))
			i += 1
	mm.visible_instance_count = gn
	if got > 0:
		combo = mini(combo + 1, 14)
		combo_t = 0.6
		main.audio.play("gem", 0.0, 1.0 + combo * 0.045)
		main.game.add_xp(got)
	var keep: Array = []
	for it in items:
		it.node.rotation.y += dt * 2.0
		it.node.position.y = 0.55 + sin(time * 3.0) * 0.15
		# a dropped jar waits on the ground while health is full
		if Vector2(px - it.pos.x, pz - it.pos.z).length() < 1.8 and (it.kind != "heal" or pl.hp < pl.max_hp):
			it.node.queue_free()
			if it.kind == "heal":
				pl.heal(12.0)
				main.audio.play("heal", -3.0, 1.25)
				main.fx.burst(it.pos + Vector3(0, 1, 0), Color(1.0, 0.45, 0.55), 12, 5.0)
			elif it.kind == "chest":
				main.audio.play("chest")
				main.fx.burst(it.pos + Vector3(0, 1, 0), Color(1.0, 0.85, 0.2), 24, 8.0)
				main.game.open_chest()
			else:
				pull_all()
				main.audio.play("shrine", -6.0, 1.4)
				main.ui.toast("Mıknatıs! Bütün bal sana geliyor")
		else:
			keep.append(it)
	items = keep
