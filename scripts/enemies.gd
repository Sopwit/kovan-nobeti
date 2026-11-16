extends Node3D
# All enemies live in flat arrays and are drawn with one MultiMesh per type.

const MAXN := 520
const CELL := 2.0
const T_BEETLE := 0
const T_WASP := 1
const T_BRUTE := 2
const T_SPIT := 3
const T_BOSS := 4

# hp, speed, dmg, radius, xp, fly height, visual size, knockback factor
const TYPES := [
	{"key": "bocek", "hp": 7.0, "speed": 4.5, "dmg": 6.0, "radius": 0.55, "xp": 1, "fly": 0.0, "size": 1.25, "kb": 1.0},
	{"key": "esekarisi", "hp": 6.0, "speed": 6.4, "dmg": 5.0, "radius": 0.5, "xp": 1, "fly": 1.25, "size": 1.2, "kb": 1.3},
	{"key": "gergedan", "hp": 60.0, "speed": 3.3, "dmg": 14.0, "radius": 1.0, "xp": 8, "fly": 0.0, "size": 2.1, "kb": 0.25},
	{"key": "tukuren", "hp": 24.0, "speed": 3.4, "dmg": 7.0, "radius": 0.7, "xp": 3, "fly": 0.0, "size": 1.6, "kb": 0.7},
	{"key": "kralice", "hp": 30000.0, "speed": 4.6, "dmg": 26.0, "radius": 2.6, "xp": 0, "fly": 0.0, "size": 7.0, "kb": 0.0},
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
var dead := PackedByteArray()
var nxt := PackedInt32Array()
var head := {}
var dead_any := false
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
	for arr in [px, pz, vx, vz, sx, sz, hp, maxhp, rad, spd, dmg, flash, atk_cd, slow_t, orb_cd, timer, phase, yaw, scl, born]:
		arr.resize(MAXN)
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
		m2.instance_count = MAXN if t < T_BOSS else 2
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
	boss_state = 0
	rings.clear()
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
	var late: float = 1.0 if t == T_BOSS else 1.0 + 0.035 * main.game.time / 60.0
	dmg[i] = d.dmg * (1.6 if is_elite else 1.0) * late
	flash[i] = 0.0
	atk_cd[i] = 0.3
	slow_t[i] = 0.0
	orb_cd[i] = 0.0
	timer[i] = randf_range(1.0, 3.0)
	phase[i] = randf() * TAU
	born[i] = 0.5
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
		boss_t = 2.5
		scl[i] = d.size
		spd[i] = d.speed
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
	var f: float = TYPES[typ[i]].fly
	if f > 0.0:
		return f + sin(time * 5.0 + phase[i]) * 0.2
	return 0.0

# Returns true when the hit killed the enemy.
func hurt(i: int, amount: float, kx: float, kz: float, src: String, crit := false) -> bool:
	if i < 0 or i >= count or dead[i] == 1:
		return false
	hp[i] -= amount
	flash[i] = 1.0
	var t := typ[i]
	var kb: float = TYPES[t].kb * (0.5 if elite[i] == 1 else 1.0)
	vx[i] += kx * kb
	vz[i] += kz * kb
	main.game.on_damage_dealt(amount, src)
	if t == T_BOSS:
		main.game.boss_taken += amount
	main.fx.number(Vector3(px[i], height_of(i) + scl[i] * 0.7, pz[i]), amount, crit)
	if hp[i] <= 0.0:
		dead[i] = 1
		dead_any = true
		if dying.size() < 90:
			dying.append([t, px[i], height_of(i), pz[i], yaw[i], scl[i], 0.16])
		main.game.on_enemy_killed(t, Vector3(px[i], height_of(i), pz[i]), elite[i] == 1, scl[i])
		if t == T_BOSS:
			boss_uid = -1
			tele_node.visible = false
		return true
	main.fx.hit(Vector3(px[i], height_of(i) + scl[i] * 0.4, pz[i]))
	return false

func slow(i: int, t: float) -> void:
	if typ[i] != T_BOSS:
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
	var tcount := [0, 0, 0, 0, 0]
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
		if flash[i] > 0.0:
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
			var bm := _boss_update(i, dt, nx, nz, d)
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
		if t != T_WASP and t != T_BOSS:
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
		yaw[i] = lerp_angle(yaw[i], want, minf(1.0, dt * 8.0))
		# contact damage
		if t != T_BOSS and d < rad[i] + 0.55 and atk_cd[i] <= 0.0 and born[i] <= 0.0:
			var fly: float = TYPES[t].fly
			var reach := ply < 1.15 if fly == 0.0 else ply < 2.6
			if reach and pl.hurt(dmg[i], px[i], pz[i]):
				atk_cd[i] = 0.75
				main.game.note_hit(TYPES[t].key)
		# draw
		var s := scl[i] * (1.0 + flash[i] * 0.18)
		if born[i] > 0.0:
			# newcomers grow out of the ground
			var g := 1.0 - born[i] * 2.0
			s *= 0.15 + 0.85 * (1.0 - (1.0 - g) * (1.0 - g))
		var yy := 0.0
		var roll := 0.0
		if t == T_WASP:
			yy = TYPES[t].fly + sin(time * 5.0 + phase[i]) * 0.2
			roll = sin(time * 9.0 + phase[i]) * 0.12
		elif t == T_BOSS:
			yy = _boss_y()
			roll = sin(time * 3.0) * 0.04
		else:
			roll = sin(time * (9.0 if t == T_BEETLE else 5.0) + phase[i]) * 0.14
			yy = absf(sin(time * (9.0 if t == T_BEETLE else 5.0) + phase[i])) * 0.07 * scl[i]
		var cy := cos(yaw[i])
		var sy := sin(yaw[i])
		var bas := Basis(Vector3(cy, 0, -sy) * s, Vector3(0, s, 0), Vector3(sy, 0, cy) * s)
		if roll != 0.0:
			bas = bas * Basis(Vector3(0, 0, 1), roll)
		var k2: int = tcount[t]
		var m2 := mm[t]
		if k2 >= m2.instance_count:
			continue
		m2.set_instance_transform(k2, Transform3D(bas, Vector3(px[i], yy, pz[i])))
		m2.set_instance_custom_data(k2, Color(flash[i], 0.0, 0.0, 0.0))
		if elite[i] == 1:
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
		var f: float = 1.0 - float(dd[6]) / 0.16
		var ds: float = dd[5]
		var wide := ds * (1.0 + 0.5 * f)
		var tall := ds * (1.0 - 0.9 * f)
		var dyaw: float = dd[4]
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
	match boss_state:
		0:
			tele_node.visible = false
			if boss_t <= 0.0:
				boss_attack_i += 1
				var pick := boss_attack_i % 4
				if pick == 1:
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
