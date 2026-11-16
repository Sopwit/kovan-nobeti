extends Node3D
# All enemies live in flat arrays and are drawn with one MultiMesh per type.

const MAXN := 520
const CELL := 2.0
const T_BEETLE := 0
const T_WASP := 1
const T_BRUTE := 2
const T_SPIT := 3
const T_BOSS := 4
const T_BOOM := 5
const T_HOP := 6
const T_STAG := 7
const T_SCORP := 8
# how many of each kind can be on screen at once
const CAP := [MAXN, MAXN, MAXN, MAXN, 2, 160, 160, 2, 2]
const POP_R := 3.0
const HOP_R := 1.9
const LOB_R := 2.3

# hp, speed, dmg, radius, xp, fly height, visual size, knockback factor
const TYPES := [
	{"key": "bocek", "hp": 7.0, "speed": 4.5, "dmg": 6.0, "radius": 0.55, "xp": 1, "fly": 0.0, "size": 1.25, "kb": 1.0},
	{"key": "esekarisi", "hp": 6.0, "speed": 6.4, "dmg": 5.0, "radius": 0.5, "xp": 1, "fly": 1.25, "size": 1.2, "kb": 1.3},
	{"key": "gergedan", "hp": 60.0, "speed": 3.3, "dmg": 14.0, "radius": 1.0, "xp": 8, "fly": 0.0, "size": 2.1, "kb": 0.25},
	{"key": "tukuren", "hp": 24.0, "speed": 3.4, "dmg": 7.0, "radius": 0.7, "xp": 3, "fly": 0.0, "size": 1.6, "kb": 0.7},
	{"key": "kralice", "hp": 30000.0, "speed": 4.6, "dmg": 26.0, "radius": 2.6, "xp": 0, "fly": 0.0, "size": 7.0, "kb": 0.0},
	# the exploder runs in, swells and bursts: its blast hurts the swarm as much as the keeper
	{"key": "patlak", "hp": 13.0, "speed": 5.4, "dmg": 20.0, "radius": 0.6, "xp": 2, "fly": 0.0, "size": 1.5, "kb": 0.8},
	# the hopper leaps to a spot it marks first
	{"key": "cekirge", "hp": 15.0, "speed": 3.2, "dmg": 10.0, "radius": 0.6, "xp": 2, "fly": 0.0, "size": 1.6, "kb": 0.9},
	# the two champions that come before the queen
	{"key": "makas", "hp": 1000.0, "speed": 4.3, "dmg": 17.0, "radius": 1.7, "xp": 0, "fly": 0.0, "size": 4.8, "kb": 0.0},
	{"key": "akrep", "hp": 1000.0, "speed": 3.8, "dmg": 16.0, "radius": 1.6, "xp": 0, "fly": 0.0, "size": 4.6, "kb": 0.0},
]

var main
var count := 0
var next_uid := 1
var px := PackedFloat32Array()
var pz := PackedFloat32Array()
var vx := PackedFloat32Array()
var vz := PackedFloat32Array()
var sx := PackedFloat32Array()
var sz := PackedFloat32Array()
var hp := PackedFloat32Array()
var maxhp := PackedFloat32Array()
var rad := PackedFloat32Array()
var spd := PackedFloat32Array()
var dmg := PackedFloat32Array()
var flash := PackedFloat32Array()
var atk_cd := PackedFloat32Array()
var slow_t := PackedFloat32Array()
var orb_cd := PackedFloat32Array()
var timer := PackedFloat32Array()
var phase := PackedFloat32Array()
var born := PackedFloat32Array()
var yaw := PackedFloat32Array()
var scl := PackedFloat32Array()
var typ := PackedInt32Array()
var uid := PackedInt32Array()
var elite := PackedByteArray()
# brain state, aim (a point or a direction, by kind) and height above the ground while leaping
var st := PackedInt32Array()
var ax := PackedFloat32Array()
var az := PackedFloat32Array()
var air := PackedFloat32Array()
# the champion on the field (stag beetle or scorpion), -1 when there is none
var champ_uid := -1
# blasts waiting to go off: [x, z, delay, hurts the keeper too (1 or 0)]
var pops: Array = []
# venom in the air: [target x, target z, time left, flight time, start x, start z, damage]
var lobs: Array = []
var lob_mm: MultiMesh
var dead := PackedByteArray()
var nxt := PackedInt32Array()
var head := {}
var dead_any := false
# what each kind leaves on the ground when it dies
const GOO := [Color(0.45, 0.2, 0.6, 0.7), Color(0.75, 0.2, 0.15, 0.65), Color(0.3, 0.25, 0.6, 0.75), Color(0.85, 0.3, 0.55, 0.7), Color(0.7, 0.1, 0.2, 0.8),
	Color(0.95, 0.5, 0.1, 0.7), Color(0.5, 0.7, 0.15, 0.7), Color(0.6, 0.12, 0.12, 0.8), Color(0.15, 0.45, 0.45, 0.8)]
# bodies that were just killed: drawn squashing flat for a moment
var dying: Array = []
var sep_cursor := 0

var mm: Array[MultiMesh] = []
var mmi: Array[MultiMeshInstance3D] = []

# enemy projectiles
var bx := PackedFloat32Array()
var bz := PackedFloat32Array()
var bvx := PackedFloat32Array()
var bvz := PackedFloat32Array()
var blife := PackedFloat32Array()
var bdmg := PackedFloat32Array()
var bcount := 0
const BMAX := 220
var bmm: MultiMesh

# boss
var boss_uid := -1
var boss_state := 0
var boss_raged := false
var boss_t := 0.0
var boss_dirx := 0.0
var boss_dirz := 0.0
var boss_attack_i := 0
var boss_rings_left := 0
var rings: Array = []
var ring_nodes: Array[MeshInstance3D] = []
var tele_node: MeshInstance3D
var time := 0.0

func setup(m) -> void:
	main = m
	for arr in [px, pz, vx, vz, sx, sz, hp, maxhp, rad, spd, dmg, flash, atk_cd, slow_t, orb_cd, timer, phase, yaw, scl, born, ax, az, air]:
		arr.resize(MAXN)
	st.resize(MAXN)
	typ.resize(MAXN)
	uid.resize(MAXN)
	nxt.resize(MAXN)
	elite.resize(MAXN)
	dead.resize(MAXN)
	for t in TYPES.size():
		var m2 := MultiMesh.new()
		m2.transform_format = MultiMesh.TRANSFORM_3D
		m2.use_colors = true
		m2.use_custom_data = true
		m2.mesh = main.assets.enemy_mesh(TYPES[t].key)
		m2.instance_count = CAP[t]
		m2.visible_instance_count = 0
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = m2
		inst.material_override = main.assets.enemy_material(TYPES[t].key)
		inst.custom_aabb = AABB(Vector3(-200, -5, -200), Vector3(400, 40, 400))
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(inst)
		mm.append(m2)
		mmi.append(inst)
	for arr in [bx, bz, bvx, bvz, blife, bdmg]:
		arr.resize(BMAX)
	bmm = MultiMesh.new()
	bmm.transform_format = MultiMesh.TRANSFORM_3D
	var sph := SphereMesh.new()
	sph.radius = 0.32
	sph.height = 0.64
	sph.radial_segments = 8
	sph.rings = 4
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.75, 0.15, 0.9)
	bmat.emission_enabled = true
	bmat.emission = Color(0.9, 0.2, 1.0)
	bmat.emission_energy_multiplier = 2.2
	sph.material = bmat
	bmm.mesh = sph
	bmm.instance_count = BMAX
	bmm.visible_instance_count = 0
	var binst := MultiMeshInstance3D.new()
	binst.multimesh = bmm
	binst.custom_aabb = AABB(Vector3(-200, -5, -200), Vector3(400, 40, 400))
	binst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(binst)
	lob_mm = MultiMesh.new()
	lob_mm.transform_format = MultiMesh.TRANSFORM_3D
	var lsph := SphereMesh.new()
	lsph.radius = 0.32
	lsph.height = 0.64
	lsph.radial_segments = 8
	lsph.rings = 4
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.4, 0.9, 0.2)
	lmat.emission_enabled = true
	lmat.emission = Color(0.5, 1.0, 0.25)
	lmat.emission_energy_multiplier = 2.2
	lsph.material = lmat
	lob_mm.mesh = lsph
	lob_mm.instance_count = 16
	lob_mm.visible_instance_count = 0
	var linst := MultiMeshInstance3D.new()
	linst.multimesh = lob_mm
	linst.custom_aabb = AABB(Vector3(-200, -5, -200), Vector3(400, 40, 400))
	linst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(linst)
	for k in 3:
		var rn := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.9
		tm.outer_radius = 1.0
		tm.rings = 48
		tm.ring_segments = 6
		rn.mesh = tm
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(1.0, 0.25, 0.3)
		rmat.emission_enabled = true
		rmat.emission = Color(1.0, 0.2, 0.3)
		rmat.emission_energy_multiplier = 3.0
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rn.material_override = rmat
		rn.visible = false
		rn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rn)
		ring_nodes.append(rn)
	tele_node = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.05
	cyl.radial_segments = 40
	tele_node.mesh = cyl
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(1.0, 0.15, 0.2, 0.35)
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tele_node.material_override = tmat
	tele_node.visible = false
	tele_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tele_node)

func clear() -> void:
	count = 0
	bcount = 0
	dying.clear()
	boss_uid = -1
	champ_uid = -1
	boss_state = 0
	rings.clear()
	pops.clear()
	lobs.clear()
	lob_mm.visible_instance_count = 0
	head.clear()
	for rn in ring_nodes:
		rn.visible = false
	tele_node.visible = false
	for m2 in mm:
		m2.visible_instance_count = 0
	bmm.visible_instance_count = 0

func spawn(t: int, x: float, z: float, is_elite := false, hp_mult := 1.0) -> int:
	if count >= MAXN:
		return -1
	var i := count
	count += 1
	var d: Dictionary = TYPES[t]
	px[i] = x
	pz[i] = z
	vx[i] = 0.0
	vz[i] = 0.0
	sx[i] = 0.0
	sz[i] = 0.0
	var h: float = d.hp * hp_mult
	var s := 1.0
	if is_elite:
		h *= 9.0
		s = 1.7
	hp[i] = h
	maxhp[i] = h
	rad[i] = d.radius * s
	spd[i] = d.speed * randf_range(0.9, 1.1) * (0.85 if is_elite else 1.0)
	# the swarm bites a little harder every minute; the queen keeps her own numbers
	var late: float = 1.0 if (t == T_BOSS or t >= T_STAG) else 1.0 + 0.035 * main.game.time / 60.0
	dmg[i] = d.dmg * (1.6 if is_elite else 1.0) * late
	flash[i] = 0.0
	atk_cd[i] = 0.3
	slow_t[i] = 0.0
	orb_cd[i] = 0.0
	timer[i] = randf_range(1.0, 3.0)
	phase[i] = randf() * TAU
	born[i] = 0.5
	st[i] = 0
	ax[i] = 0.0
	az[i] = 0.0
	air[i] = 0.0
	if t != T_WASP and t != T_BOSS:
		main.fx.splat(x, z, d.size * s * 0.75, Color(0.22, 0.15, 0.08, 0.75), 1.6)
	yaw[i] = 0.0
	scl[i] = d.size * s * randf_range(0.92, 1.08)
	typ[i] = t
	uid[i] = next_uid
	next_uid += 1
	elite[i] = 1 if is_elite else 0
	dead[i] = 0
	if t == T_BOSS:
		boss_uid = uid[i]
		boss_state = 0
		boss_raged = false
		boss_attack_i = 0
		boss_t = 2.5
		scl[i] = d.size
		spd[i] = d.speed
	elif t >= T_STAG:
		champ_uid = uid[i]
		scl[i] = d.size
		spd[i] = d.speed
		timer[i] = 2.2
		born[i] = 1.0
	return i

func _remove(i: int) -> void:
	var l := count - 1
	if i != l:
		px[i] = px[l]; pz[i] = pz[l]; vx[i] = vx[l]; vz[i] = vz[l]
		sx[i] = sx[l]; sz[i] = sz[l]; hp[i] = hp[l]; maxhp[i] = maxhp[l]
		rad[i] = rad[l]; spd[i] = spd[l]; dmg[i] = dmg[l]; flash[i] = flash[l]
		atk_cd[i] = atk_cd[l]; slow_t[i] = slow_t[l]; orb_cd[i] = orb_cd[l]
		timer[i] = timer[l]; phase[i] = phase[l]; yaw[i] = yaw[l]; scl[i] = scl[l]; born[i] = born[l]
		typ[i] = typ[l]; uid[i] = uid[l]; elite[i] = elite[l]; dead[i] = dead[l]
		st[i] = st[l]; ax[i] = ax[l]; az[i] = az[l]; air[i] = air[l]
	count = l

func _sweep_dead() -> void:
	if not dead_any:
		return
	dead_any = false
	var i := count - 1
	while i >= 0:
		if dead[i] == 1:
			_remove(i)
		i -= 1

func _rebuild_grid() -> void:
	head.clear()
	for i in count:
		var key := (int(floor(px[i] / CELL)) + 512) * 1024 + int(floor(pz[i] / CELL)) + 512
		nxt[i] = head.get(key, -1)
		head[key] = i

func boss_index() -> int:
	if boss_uid < 0:
		return -1
	for i in count:
		if uid[i] == boss_uid and dead[i] == 0:
			return i
	return -1

func champ_index() -> int:
	if champ_uid < 0:
		return -1
	for i in count:
		if uid[i] == champ_uid and dead[i] == 0:
			return i
	return -1

func index_of(u: int, hint: int) -> int:
	if hint >= 0 and hint < count and uid[hint] == u and dead[hint] == 0:
		return hint
	return -1

# Indices of living enemies whose body overlaps the circle.
func query(x: float, z: float, r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	# pad by the largest body that is not the queen (an elite brute, radius 1.7)
	var rr := r + 1.8
	var c0x := int(floor((x - rr) / CELL)) + 512
	var c1x := int(floor((x + rr) / CELL)) + 512
	var c0z := int(floor((z - rr) / CELL)) + 512
	var c1z := int(floor((z + rr) / CELL)) + 512
	for cx in range(c0x, c1x + 1):
		for cz in range(c0z, c1z + 1):
			var i: int = head.get(cx * 1024 + cz, -1)
			while i >= 0:
				if dead[i] == 0:
					var dx := px[i] - x
					var dz := pz[i] - z
					var lim := r + rad[i]
					if dx * dx + dz * dz <= lim * lim:
						out.append(i)
				i = nxt[i]
	var b := boss_index()
	if b >= 0 and not out.has(b):
		var dx2 := px[b] - x
		var dz2 := pz[b] - z
		var lim2 := r + rad[b]
		if dx2 * dx2 + dz2 * dz2 <= lim2 * lim2:
			out.append(b)
	return out

func nearest(x: float, z: float, max_r: float, skip := {}) -> int:
	var best := -1
	var best_d := max_r * max_r
	for i in count:
		if dead[i] == 1:
			continue
		var dx := px[i] - x
		var dz := pz[i] - z
		var d := dx * dx + dz * dz - rad[i] * rad[i]
		if d < best_d and not skip.has(uid[i]):
			best_d = d
			best = i
	return best

func random_near(x: float, z: float, max_r: float) -> int:
	var tries := 10
	var best := -1
	while tries > 0 and count > 0:
		tries -= 1
		var i := randi() % count
		if dead[i] == 1:
			continue
		var dx := px[i] - x
		var dz := pz[i] - z
		if dx * dx + dz * dz < max_r * max_r:
			return i
	best = nearest(x, z, max_r)
	return best

func height_of(i: int) -> float:
	if air[i] > 0.0:
		return air[i]
	var f: float = TYPES[typ[i]].fly
	if f > 0.0:
		return f + sin(time * 5.0 + phase[i]) * 0.2
	return 0.0

# Returns true when the hit killed the enemy.
func hurt(i: int, amount: float, kx: float, kz: float, src: String, crit := false) -> bool:
	if i < 0 or i >= count or dead[i] == 1:
		return false
	var t := typ[i]
	if t == T_BOSS:
		amount *= main.game.boss_tired()
	hp[i] -= amount
	if t == T_BOSS or t >= T_STAG:
		# hit many times a second, a big body would stay white: one short pulse, then a rest that shows its skin
		if flash[i] <= -1.4:
			flash[i] = 0.5
	else:
		flash[i] = 1.0
	var kb: float = TYPES[t].kb * (0.5 if elite[i] == 1 else 1.0)
	vx[i] += kx * kb
	vz[i] += kz * kb
	main.game.on_damage_dealt(amount, src)
	if t == T_BOSS and src != "cagri" and src != "nefes":
		# blasts that take a share of her health say nothing about the build, so the probe ignores them
		main.game.boss_taken += amount
	main.fx.number(Vector3(px[i], height_of(i) + scl[i] * 0.7, pz[i]), amount, crit)
	if hp[i] <= 0.0:
		dead[i] = 1
		dead_any = true
		if dying.size() < 90:
			# small bodies squash flat in a blink; the queen shudders through her last blasts
			var dtime := 0.76 if t == T_BOSS else (0.4 if t >= T_STAG else 0.16)
			dying.append([t, px[i], height_of(i), pz[i], yaw[i], scl[i], dtime, dtime])
		main.fx.splat(px[i], pz[i], scl[i] * 0.85, GOO[t], 9.0)
		main.game.on_enemy_killed(t, Vector3(px[i], height_of(i), pz[i]), elite[i] == 1, scl[i])
		if t == T_BOSS:
			boss_uid = -1
			tele_node.visible = false
		elif t >= T_STAG:
			# the bar passes to the other champion if one still stands
			champ_uid = -1
			for j in count:
				if j != i and typ[j] >= T_STAG and dead[j] == 0:
					champ_uid = uid[j]
		elif t == T_BOOM:
			# shot down, it still bursts: only the swarm around it pays
			pops.append([px[i], pz[i], 0.12, 0])
		return true
	main.fx.hit(Vector3(px[i], height_of(i) + scl[i] * 0.4, pz[i]))
	return false

func slow(i: int, t: float) -> void:
	if typ[i] != T_BOSS and typ[i] < T_STAG:
		slow_t[i] = maxf(slow_t[i], t)

func fire_bullet(x: float, z: float, dx: float, dz: float, speed: float, damage: float) -> void:
	if bcount >= BMAX:
		return
	var i := bcount
	bcount += 1
	bx[i] = x
	bz[i] = z
	bvx[i] = dx * speed
	bvz[i] = dz * speed
	blife[i] = 5.0
	bdmg[i] = damage

func update(dt: float) -> void:
	time += dt
	_sweep_dead()
	_rebuild_grid()
	var pl = main.player
	var plx: float = pl.pos.x
	var plz: float = pl.pos.z
	var ply: float = pl.pos.y
	var kd := exp(-7.0 * dt)
	var fd := dt * 7.0
	var arena: float = main.world.ARENA_R - 1.0
	var obs: Array = main.world.obstacles
	# staggered separation: a quarter of the crowd per frame
	var n_sep := (count >> 2) + 1
	for k in n_sep:
		if count == 0:
			break
		sep_cursor = (sep_cursor + 1) % count
		var i := sep_cursor
		var ax := 0.0
		var az := 0.0
		var cx := int(floor(px[i] / CELL)) + 512
		var cz := int(floor(pz[i] / CELL)) + 512
		var ri := rad[i]
		for ox in range(cx - 1, cx + 2):
			for oz in range(cz - 1, cz + 2):
				var j: int = head.get(ox * 1024 + oz, -1)
				while j >= 0:
					if j != i:
						var dx := px[i] - px[j]
						var dz := pz[i] - pz[j]
						var lim := ri + rad[j]
						var d2 := dx * dx + dz * dz
						if d2 < lim * lim and d2 > 0.0001:
							var d := sqrt(d2)
							var push := (lim - d) / lim
							# big bodies shove small ones, not the other way round
							if rad[j] < ri * 0.7:
								push *= 0.15
							ax += dx / d * push
							az += dz / d * push
					j = nxt[j]
		sx[i] = ax * 5.0
		sz[i] = az * 5.0
	var tcount: Array = []
	tcount.resize(TYPES.size())
	tcount.fill(0)
	for i in count:
		if dead[i] == 1:
			continue
		var t := typ[i]
		var dx := plx - px[i]
		var dz := plz - pz[i]
		var d := sqrt(dx * dx + dz * dz) + 0.0001
		var nx := dx / d
		var nz := dz / d
		var speed := spd[i]
		if slow_t[i] > 0.0:
			slow_t[i] -= dt
			speed *= 0.55
		if t == T_BOSS or t >= T_STAG:
			# below zero is the rest between two hit pulses
			flash[i] = maxf(-1.5, flash[i] - fd)
		elif flash[i] > 0.0:
			flash[i] = maxf(0.0, flash[i] - fd)
		if atk_cd[i] > 0.0:
			atk_cd[i] -= dt
		if orb_cd[i] > 0.0:
			orb_cd[i] -= dt
		if born[i] > 0.0:
			born[i] -= dt
			speed *= 0.4
		var mvx := 0.0
		var mvz := 0.0
		if t == T_BOSS:
			# she does nothing until she has broken out of the ground
			var bm := Vector2.ZERO if born[i] > 0.0 else _boss_update(i, dt, nx, nz, d)
			mvx = bm.x
			mvz = bm.y
		elif t == T_SPIT:
			timer[i] -= dt
			if d < 7.5:
				mvx = -nx * speed
				mvz = -nz * speed
			elif d > 11.5:
				mvx = nx * speed
				mvz = nz * speed
			else:
				mvx = -nz * speed * 0.6
				mvz = nx * speed * 0.6
			if timer[i] <= 0.0 and d < 16.0:
				timer[i] = randf_range(3.4, 4.8)
				fire_bullet(px[i] + nx * 0.6, pz[i] + nz * 0.6, nx, nz, 9.0, TYPES[T_SPIT].dmg)
				flash[i] = 0.6
		elif t == T_BOOM:
			if st[i] == 0:
				mvx = nx * speed
				mvz = nz * speed
				if d < 2.4 and born[i] <= 0.0:
					st[i] = 1
					timer[i] = 0.8
					main.fx.warn(px[i], pz[i], POP_R, 0.8)
					main.audio.play("spit", -3.0, 1.6)
			else:
				timer[i] -= dt
				flash[i] = 0.5 + 0.5 * sin(time * 45.0)
				if timer[i] <= 0.0:
					# it took itself out: no honey for that
					pops.append([px[i], pz[i], 0.0, 1])
					dead[i] = 1
					dead_any = true
					main.fx.splat(px[i], pz[i], scl[i] * 0.85, GOO[t], 9.0)
					continue
		elif t == T_HOP:
			if st[i] == 0:
				timer[i] -= dt
				if d > rad[i] + 0.35:
					mvx = nx * speed
					mvz = nz * speed
				if timer[i] <= 0.0 and d < 17.0 and d > 3.0 and born[i] <= 0.0:
					st[i] = 1
					timer[i] = 0.45
					# it aims where the keeper is heading, not where they stand
					var hx: float = plx + pl.vel.x * 0.5 - px[i]
					var hz: float = plz + pl.vel.z * 0.5 - pz[i]
					var hd := sqrt(hx * hx + hz * hz) + 0.001
					var reach2 := minf(hd, 13.0)
					ax[i] = px[i] + hx / hd * reach2
					az[i] = pz[i] + hz / hd * reach2
					main.fx.warn(ax[i], az[i], HOP_R, 1.25)
					main.game.hint("cekirge", "Çekirge kırmızı daireye iner, içinden çık")
			elif st[i] == 1:
				timer[i] -= dt
				if timer[i] <= 0.0:
					st[i] = 2
					timer[i] = 0.8
			else:
				var left := maxf(timer[i], dt)
				mvx = (ax[i] - px[i]) / left
				mvz = (az[i] - pz[i]) / left
				sx[i] = 0.0
				sz[i] = 0.0
				vx[i] = 0.0
				vz[i] = 0.0
				timer[i] -= dt
				air[i] = sin(clampf(1.0 - timer[i] / 0.8, 0.0, 1.0) * PI) * 4.4 + 0.01
				if timer[i] <= 0.0:
					st[i] = 0
					air[i] = 0.0
					timer[i] = randf_range(2.8, 4.2)
					main.fx.explosion(Vector3(ax[i], 0.2, az[i]), HOP_R, Color(0.7, 0.9, 0.2))
					main.audio.play("land", -2.0, 0.7)
					var ldx: float = plx - ax[i]
					var ldz: float = plz - az[i]
					if ldx * ldx + ldz * ldz < (HOP_R + 0.3) * (HOP_R + 0.3) and ply < 1.0 and pl.hurt(dmg[i] * 1.4, ax[i], az[i]):
						main.game.note_hit("cekirge")
		elif t == T_STAG:
			var gm := _stag_update(i, dt, nx, nz, d, ply)
			mvx = gm.x
			mvz = gm.y
		elif t == T_SCORP:
			var cm := _scorp_update(i, dt, nx, nz, d)
			mvx = cm.x
			mvz = cm.y
		else:
			var stop := rad[i] + 0.35
			if d > stop:
				mvx = nx * speed
				mvz = nz * speed
		px[i] += (mvx + sx[i] + vx[i]) * dt
		pz[i] += (mvz + sz[i] + vz[i]) * dt
		vx[i] *= kd
		vz[i] *= kd
		# static obstacles are circles: slide around them
		if t != T_WASP and t != T_BOSS and air[i] <= 0.0:
			for o in obs:
				var odx: float = px[i] - o.x
				var odz: float = pz[i] - o.y
				var olim: float = o.z + rad[i] * 0.6
				var od2 := odx * odx + odz * odz
				if od2 < olim * olim and od2 > 0.0001:
					var od := sqrt(od2)
					px[i] = o.x + odx / od * olim
					pz[i] = o.y + odz / od * olim
		var r2 := px[i] * px[i] + pz[i] * pz[i]
		if r2 > arena * arena:
			var rr := sqrt(r2)
			px[i] = px[i] / rr * arena
			pz[i] = pz[i] / rr * arena
		# face the player, turning smoothly
		var want := atan2(nx, nz)
		if t == T_STAG and st[i] != 0:
			# the stag keeps looking down its lane
			want = atan2(ax[i], az[i])
		yaw[i] = lerp_angle(yaw[i], want, minf(1.0, dt * 8.0))
		# contact damage
		if t != T_BOSS and t != T_BOOM and air[i] <= 0.0 and d < rad[i] + 0.55 and atk_cd[i] <= 0.0 and born[i] <= 0.0:
			var fly: float = TYPES[t].fly
			var reach := ply < 1.15 if fly == 0.0 else ply < 2.6
			if reach and pl.hurt(dmg[i], px[i], pz[i]):
				atk_cd[i] = 0.75
				main.game.note_hit(TYPES[t].key)
		# draw
		var s := scl[i] * (1.0 + maxf(0.0, flash[i]) * 0.18)
		var act := 1.0
		var squat := 1.0
		if t == T_BOOM and st[i] == 1:
			# swelling up before the burst
			s *= 1.0 + 0.4 * (1.0 - timer[i] / 0.8)
			act = 0.0
		elif t == T_HOP and st[i] != 0:
			act = 0.15
			if st[i] == 1:
				squat = 0.65
		elif t == T_STAG:
			act = [1.0, 0.0, 2.2, 0.0][st[i]]
			if st[i] == 3:
				squat = 0.92 + 0.05 * sin(time * 9.0)
		var dig := 0.0
		if born[i] > 0.0:
			# newcomers dig themselves out of the ground; wasps dive in from above
			var g := 1.0 - minf(1.0, born[i] * 2.0)
			var ease := 1.0 - (1.0 - g) * (1.0 - g)
			s *= 0.6 + 0.4 * ease
			dig = (1.0 - ease) * (6.0 if t == T_WASP else -scl[i] * 0.9)
		var yy := 0.0
		var roll := 0.0
		if t == T_WASP:
			yy = TYPES[t].fly + sin(time * 5.0 + phase[i]) * 0.2
			roll = sin(time * 9.0 + phase[i]) * 0.12
		elif t == T_BOSS:
			yy = _boss_y()
			roll = sin(time * 3.0) * 0.04
		elif t >= T_STAG:
			roll = sin(time * 4.0) * 0.03
		elif air[i] > 0.0:
			yy = air[i]
		else:
			roll = sin(time * (9.0 if t == T_BEETLE else 5.0) + phase[i]) * 0.14
			yy = absf(sin(time * (9.0 if t == T_BEETLE else 5.0) + phase[i])) * 0.07 * scl[i]
		var cy := cos(yaw[i])
		var sy := sin(yaw[i])
		var bas := Basis(Vector3(cy, 0, -sy) * s, Vector3(0, s * squat, 0), Vector3(sy, 0, cy) * s)
		if roll != 0.0:
			bas = bas * Basis(Vector3(0, 0, 1), roll)
		var k2: int = tcount[t]
		var m2 := mm[t]
		if k2 >= m2.instance_count:
			continue
		m2.set_instance_transform(k2, Transform3D(bas, Vector3(px[i], yy + dig, pz[i])))
		m2.set_instance_custom_data(k2, Color(maxf(0.0, flash[i]), phase[i], act, 0.0))
		if (t >= T_STAG or t == T_BOSS) and hp[i] < maxhp[i] * 0.5:
			# a champion or the queen that is half down turns angry red
			m2.set_instance_color(k2, Color(1.0, 0.66, 0.6))
		elif elite[i] == 1:
			m2.set_instance_color(k2, Color(1.0, 0.72, 0.25))
		elif slow_t[i] > 0.0:
			m2.set_instance_color(k2, Color(0.75, 0.8, 1.0))
		else:
			m2.set_instance_color(k2, Color.WHITE)
		tcount[t] = k2 + 1
	var keep_dying: Array = []
	for dd in dying:
		dd[6] -= dt
		if dd[6] <= 0.0:
			continue
		keep_dying.append(dd)
		var dt_type: int = dd[0]
		var k3: int = tcount[dt_type]
		if k3 >= mm[dt_type].instance_count:
			continue
		var f: float = 1.0 - float(dd[6]) / float(dd[7])
		var ds: float = dd[5]
		var wide := ds * (1.0 + 0.5 * f)
		var tall := ds * (1.0 - 0.9 * f)
		var dyaw: float = dd[4]
		if dt_type == T_BOSS:
			wide = ds * (1.0 + 0.14 * f + 0.03 * sin(time * 70.0))
			tall = ds * (1.0 + 0.1 * f)
			dyaw += sin(time * 55.0) * 0.07
		var dbas := Basis(Vector3(cos(dyaw), 0, -sin(dyaw)) * wide, Vector3(0, tall, 0), Vector3(sin(dyaw), 0, cos(dyaw)) * wide)
		mm[dt_type].set_instance_transform(k3, Transform3D(dbas, Vector3(dd[1], dd[2], dd[3])))
		mm[dt_type].set_instance_custom_data(k3, Color(1.0, 0.0, 0.0, 0.0))
		mm[dt_type].set_instance_color(k3, Color.WHITE)
		tcount[dt_type] = k3 + 1
	dying = keep_dying
	for t in mm.size():
		mm[t].visible_instance_count = tcount[t]
	_update_bullets(dt, plx, plz, ply)
	_update_rings(dt, plx, plz, ply)
	_update_lobs(dt, plx, plz, ply)
	_update_pops(dt)

# A burst: everything in reach is hurt and thrown outward, the keeper only when the blast was not their doing.
func _pop(x: float, z: float, hits_player: bool) -> void:
	main.fx.explosion(Vector3(x, 0.3, z), POP_R, Color(1.0, 0.55, 0.1))
	main.audio.play("explosion", -5.0, randf_range(1.1, 1.3))
	main.fx.shake(0.22)
	var amount: float = 9.0 * main.game.hp_scale()
	for j in query(x, z, POP_R):
		if dead[j] == 1 or typ[j] == T_BOSS:
			continue
		var dx := px[j] - x
		var dz := pz[j] - z
		var d := sqrt(dx * dx + dz * dz) + 0.001
		hurt(j, amount, dx / d * 7.0, dz / d * 7.0, "patlak")
	if hits_player:
		var pl = main.player
		var pdx: float = pl.pos.x - x
		var pdz: float = pl.pos.z - z
		if pdx * pdx + pdz * pdz < (POP_R + 0.2) * (POP_R + 0.2) and pl.pos.y < 2.6:
			if pl.hurt(TYPES[T_BOOM].dmg * (1.0 + 0.035 * main.game.time / 60.0), x, z):
				main.game.note_hit("patlak")

func _update_pops(dt: float) -> void:
	if pops.is_empty():
		return
	var keep: Array = []
	var due: Array = []
	for p in pops:
		p[2] -= dt
		if p[2] <= 0.0:
			due.append(p)
		else:
			keep.append(p)
	pops = keep
	# a burst that kills another exploder queues its burst: chains ripple outward instead of going off at once
	for p in due:
		_pop(p[0], p[1], p[3] == 1)

func _update_lobs(dt: float, plx: float, plz: float, ply: float) -> void:
	var keep: Array = []
	var k := 0
	for l in lobs:
		l[2] -= dt
		if l[2] <= 0.0:
			main.fx.explosion(Vector3(l[0], 0.2, l[1]), LOB_R, Color(0.5, 0.95, 0.3))
			main.fx.splat(l[0], l[1], LOB_R * 0.9, Color(0.35, 0.75, 0.2, 0.6), 3.0)
			main.audio.play("spit", -4.0, 0.6)
			var dx: float = plx - float(l[0])
			var dz: float = plz - float(l[1])
			if dx * dx + dz * dz < (LOB_R + 0.2) * (LOB_R + 0.2) and ply < 1.2:
				if main.player.hurt(l[6], l[0], l[1]):
					main.game.note_hit("akrep")
			continue
		keep.append(l)
		if k < lob_mm.instance_count:
			var f: float = 1.0 - float(l[2]) / float(l[3])
			var at := Vector3(lerpf(l[4], l[0], f), 1.8 + sin(f * PI) * 8.0, lerpf(l[5], l[1], f))
			lob_mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ONE * 1.7), at))
			k += 1
	lobs = keep
	lob_mm.visible_instance_count = k

# The stag beetle walks the keeper down, then charges along a lane it shows first.
# States: 0 chase, 1 windup, 2 charge, 3 winded.
func _stag_update(i: int, dt: float, nx: float, nz: float, d: float, ply: float) -> Vector2:
	timer[i] -= dt
	var angry := hp[i] < maxhp[i] * 0.5
	match st[i]:
		0:
			if timer[i] <= 0.0 and d < 24.0 and born[i] <= 0.0:
				st[i] = 1
				timer[i] = 0.7 if angry else 0.9
				ax[i] = nx
				az[i] = nz
				main.fx.warn_lane(px[i], pz[i], atan2(nx, nz), 2.4, 18.0, timer[i])
				main.audio.play("boss_roar", -4.0, 1.35)
				main.game.hint("makas", "Makas kırmızı şeritten hücum eder, yana kaç")
			elif d > rad[i] + 0.4:
				return Vector2(nx, nz) * spd[i] * (0.4 if born[i] > 0.0 else 1.0)
		1:
			flash[i] = 0.3 + 0.3 * sin(time * 30.0)
			if timer[i] <= 0.0:
				st[i] = 2
				timer[i] = 0.62
				main.audio.play("slide", 0.0, 0.6)
				# the lane stays lit for the rush itself and fills as the beetle runs it
				main.fx.warn_lane(px[i], pz[i], atan2(ax[i], az[i]), 2.4, 18.0, 0.62)
			# it leans back before the rush
			return Vector2(-ax[i], -az[i]) * 1.2
		2:
			# the hit reaches exactly as far as the lane that was drawn
			if d < rad[i] + 0.7 and ply < 1.3 and atk_cd[i] <= 0.0:
				if main.player.hurt(dmg[i] * 1.3, px[i], pz[i]):
					atk_cd[i] = 0.75
					main.game.note_hit("makas")
			if timer[i] <= 0.0:
				st[i] = 3
				timer[i] = 0.7 if angry else 1.0
				main.fx.shake(0.25)
			return Vector2(ax[i], az[i]) * 27.0
		3:
			if timer[i] <= 0.0:
				st[i] = 0
				timer[i] = 1.6 if angry else 2.6
	return Vector2.ZERO

# The scorpion keeps its distance and lobs venom that lands in marked circles; up close it sweeps a ring.
# States: 0 stalk, 1 tail windup, 2 sweep windup. ax counts its attacks.
func _scorp_update(i: int, dt: float, nx: float, nz: float, d: float) -> Vector2:
	timer[i] -= dt
	var angry := hp[i] < maxhp[i] * 0.5
	var pl = main.player
	match st[i]:
		0:
			if timer[i] <= 0.0 and born[i] <= 0.0 and d < 26.0:
				ax[i] += 1.0
				flash[i] = 0.7
				if d < 8.5 and int(ax[i]) % 2 == 0:
					st[i] = 2
					timer[i] = 0.75
					main.fx.warn(px[i], pz[i], rad[i] + 2.2, 0.75)
				else:
					st[i] = 1
					timer[i] = 0.5
				return Vector2.ZERO
			if d > 12.5:
				return Vector2(nx, nz) * spd[i]
			if d < 7.0:
				return Vector2(-nx, -nz) * spd[i] * 0.75
			return Vector2(-nz, nx) * spd[i] * 0.6
		1:
			if timer[i] <= 0.0:
				for k in (5 if angry else 3):
					var tx: float = pl.pos.x + pl.vel.x * 0.6
					var tz: float = pl.pos.z + pl.vel.z * 0.6
					if k > 0:
						tx += randf_range(-5.5, 5.5)
						tz += randf_range(-5.5, 5.5)
					var fly := 0.95 + 0.12 * k
					main.fx.warn(tx, tz, LOB_R, fly)
					lobs.append([tx, tz, fly, fly, px[i], pz[i], dmg[i]])
				main.audio.play("spit", 0.0, 0.7)
				main.game.hint("akrep", "Akrebin zehri kırmızı dairelere düşer")
				st[i] = 0
				timer[i] = 2.0 if angry else 2.8
		2:
			if timer[i] <= 0.0:
				rings.append({"x": px[i], "z": pz[i], "r": rad[i], "speed": 13.0, "maxr": 17.0, "dmg": dmg[i], "hit": false})
				main.game.hint("ring", "Kırmızı halkanın üstünden zıpla")
				main.audio.play("boss_slam", -3.0, 1.3)
				main.fx.shake(0.4)
				st[i] = 0
				timer[i] = 2.0 if angry else 2.8
	return Vector2.ZERO

func _update_bullets(dt: float, plx: float, plz: float, ply: float) -> void:
	var i := 0
	var pl = main.player
	while i < bcount:
		bx[i] += bvx[i] * dt
		bz[i] += bvz[i] * dt
		blife[i] -= dt
		var dx := bx[i] - plx
		var dz := bz[i] - plz
		var gone := blife[i] <= 0.0
		if not gone and dx * dx + dz * dz < 0.75 and ply < 1.0:
			if pl.hurt(bdmg[i], bx[i], bz[i]):
				gone = true
				main.game.note_hit("mermi")
			if bcount == 0:
				# the hit ended the run and the field was cleared under this loop
				return
		if gone:
			var l := bcount - 1
			bx[i] = bx[l]; bz[i] = bz[l]; bvx[i] = bvx[l]; bvz[i] = bvz[l]
			blife[i] = blife[l]; bdmg[i] = bdmg[l]
			bcount = l
		else:
			bmm.set_instance_transform(i, Transform3D(Basis(), Vector3(bx[i], 0.8, bz[i])))
			i += 1
	bmm.visible_instance_count = bcount

func _update_rings(dt: float, plx: float, plz: float, ply: float) -> void:
	var k := 0
	for rn in ring_nodes:
		rn.visible = false
	var keep: Array = []
	for r in rings:
		r.r += r.speed * dt
		if r.r < r.maxr:
			keep.append(r)
			if k < ring_nodes.size():
				var rn := ring_nodes[k]
				rn.visible = true
				rn.position = Vector3(r.x, 0.25, r.z)
				rn.scale = Vector3(r.r, 1.6, r.r)
				k += 1
			var dx: float = plx - r.x
			var dz: float = plz - r.z
			var d := sqrt(dx * dx + dz * dz)
			if not r.hit and absf(d - r.r) < 0.7 and ply < 0.75:
				if main.player.hurt(r.dmg, r.x, r.z):
					r.hit = true
					main.game.note_hit("halka")
	rings = keep

func _boss_y() -> float:
	if boss_state == 3:
		return maxf(0.0, sin(clampf(1.0 - boss_t / 1.0, 0.0, 1.0) * PI)) * 3.5
	return 0.0

# Boss brain. States: 0 chase, 1 charge windup, 2 charging, 3 slam windup, 4 recover.
func _boss_update(i: int, dt: float, nx: float, nz: float, d: float) -> Vector2:
	boss_t -= dt
	var enraged := hp[i] < maxhp[i] * 0.5
	if enraged and not boss_raged and not main.game.over:
		boss_raged = true
		# her first move in the second half is the new one
		boss_attack_i = 3
		main.game.boss_rage(Vector3(px[i], 0, pz[i]))
	match boss_state:
		0:
			tele_node.visible = false
			if boss_t <= 0.0:
				boss_attack_i += 1
				# the second half of the fight adds a fifth attack to the cycle
				var pick := boss_attack_i % (5 if enraged else 4)
				if pick == 4:
					# venom rain: marked circles around the keeper and on the way they are running
					var pv: Vector3 = main.player.vel
					for k in 7:
						var tx: float = main.player.pos.x + pv.x * 0.6 * float(k % 3) + (randf_range(-7.0, 7.0) if k > 0 else 0.0)
						var tz: float = main.player.pos.z + pv.z * 0.6 * float(k % 3) + (randf_range(-7.0, 7.0) if k > 0 else 0.0)
						var fly := 1.0 + 0.1 * k
						main.fx.warn(tx, tz, LOB_R, fly)
						lobs.append([tx, tz, fly, fly, px[i], pz[i], dmg[i] * 0.8])
					flash[i] = 0.8
					main.audio.play("spit", 0.0, 0.6)
					main.game.hint("yagmur", "Zehir kırmızı dairelere düşer, dışına çık")
					boss_t = 2.2
				elif pick == 1:
					boss_state = 1
					boss_t = 0.9
					boss_dirx = nx
					boss_dirz = nz
					main.audio.play("boss_roar", 0.0, 1.0)
				elif pick == 2:
					boss_state = 3
					boss_t = 1.0
					boss_rings_left = 2 if enraged else 1
					main.audio.play("boss_roar", 0.0, 0.8)
				elif pick == 3:
					var n := 20 if enraged else 14
					for k in n:
						var a := TAU * k / n
						fire_bullet(px[i] + cos(a) * 2.5, pz[i] + sin(a) * 2.5, cos(a), sin(a), 8.5, 14.0)
					flash[i] = 0.8
					main.audio.play("spit", 0.0, 0.7)
					boss_t = 2.0 if enraged else 2.8
				else:
					var n2 := 10 if enraged else 6
					for k in n2:
						var a2 := randf() * TAU
						spawn(T_WASP, px[i] + cos(a2) * 4.0, pz[i] + sin(a2) * 4.0, false, main.game.hp_scale())
					flash[i] = 0.8
					boss_t = 2.2 if enraged else 3.0
			if d > rad[i] + 0.6:
				var s := spd[i] * (1.25 if enraged else 1.0)
				_boss_touch(i, d)
				return Vector2(nx * s, nz * s)
			_boss_touch(i, d)
			return Vector2.ZERO
		1:
			flash[i] = 0.35 + 0.35 * sin(time * 30.0)
			tele_node.visible = true
			tele_node.position = Vector3(px[i] + boss_dirx * 9.0, 0.06, pz[i] + boss_dirz * 9.0)
			tele_node.scale = Vector3(2.8, 1.0, 9.0)
			tele_node.rotation.y = atan2(boss_dirx, boss_dirz)
			if boss_t <= 0.0:
				boss_state = 2
				boss_t = 0.85
				tele_node.visible = false
				main.audio.play("slide", 0.0, 0.6)
			return Vector2.ZERO
		2:
			_boss_touch(i, d)
			if boss_t <= 0.0:
				boss_state = 4
				boss_t = 0.7
			return Vector2(boss_dirx * 24.0, boss_dirz * 24.0)
		3:
			tele_node.visible = true
			tele_node.position = Vector3(px[i], 0.06, pz[i])
			tele_node.scale = Vector3(5.0, 1.0, 5.0)
			tele_node.rotation.y = 0.0
			if boss_t <= 0.0:
				tele_node.visible = false
				rings.append({"x": px[i], "z": pz[i], "r": 2.0, "speed": 13.0, "maxr": 42.0, "dmg": 22.0, "hit": false})
				main.game.hint("ring", "Kırmızı halkanın üstünden zıpla")
				main.fx.shake(0.8)
				main.fx.burst(Vector3(px[i], 0.3, pz[i]), Color(1.0, 0.4, 0.3), 30, 9.0)
				main.audio.play("boss_slam", 0.0, 1.0)
				var dx: float = main.player.pos.x - px[i]
				var dz: float = main.player.pos.z - pz[i]
				if dx * dx + dz * dz < 25.0 and main.player.pos.y < 0.75:
					main.player.hurt(dmg[i], px[i], pz[i])
				boss_rings_left -= 1
				if boss_rings_left > 0:
					boss_t = 1.0
				else:
					boss_state = 4
					boss_t = 0.8
			return Vector2.ZERO
		4:
			if boss_t <= 0.0:
				boss_state = 0
				boss_t = 1.6 if enraged else 2.4
			return Vector2.ZERO
	return Vector2.ZERO

func _boss_touch(i: int, d: float) -> void:
	if d < rad[i] + 0.7 and atk_cd[i] <= 0.0 and main.player.pos.y < 3.0:
		if main.player.hurt(dmg[i], px[i], pz[i]):
			atk_cd[i] = 0.8
			main.game.note_hit("kralice")
