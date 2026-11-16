extends Node
# One run: clock, spawning, experience, upgrades, the boss and the end of the run.

const BOSS_TIME := 600.0

# kind "w" = weapon (desc per level), "p" = player trait (one desc, repeated per level)
const UPG := [
	{"id": "ari", "name": "Arı Sürüsü", "icon": 0, "max": 6, "kind": "w", "desc": ["En yakın düşmana güdümlü arı yollar", "+1 arı", "+5 hasar", "+1 arı, arılar bir düşmanı delip geçer", "%28 daha sık ateş eder", "+2 arı, +7 hasar, bir delme daha"]},
	{"id": "tutsu", "name": "Tütsü Halkası", "icon": 1, "max": 6, "kind": "w", "desc": ["Çevrendeki düşmanlar sürekli hasar alır", "Halka %22 genişler", "+3 hasar", "Halkadaki düşmanlar yavaşlar", "Halka %25 daha genişler", "+6 hasar, daha sık vurur"]},
	{"id": "bomba", "name": "Bal Bombası", "icon": 2, "max": 6, "kind": "w", "desc": ["Kalabalığın ortasına patlayan kavanoz atar", "+12 hasar", "+1 bomba", "Patlama %30 genişler", "%25 daha sık atılır", "+1 bomba, +22 hasar"]},
	{"id": "igne", "name": "İğne Çarkı", "icon": 3, "max": 6, "kind": "w", "desc": ["Etrafında dönen 2 iğne düşmanları biçer", "+1 iğne", "+5 hasar", "+1 iğne, çark hızlanır", "Çark %25 genişler", "+2 iğne, +9 hasar"]},
	{"id": "kivilcim", "name": "Polen Kıvılcımı", "icon": 4, "max": 6, "kind": "w", "desc": ["Düşmandan düşmana seken kıvılcım çakar", "+2 sekme", "+8 hasar", "%20 daha sık çakar", "+3 sekme", "Çift çakar, +14 hasar"]},
	{"id": "kalp", "name": "Bal Kalbi", "icon": 5, "max": 5, "kind": "p", "desc": "+20 can, 20 can iyileşir"},
	{"id": "cizme", "name": "Kanatlı Çizme", "icon": 6, "max": 5, "kind": "p", "desc": "+%8 koşu hızı"},
	{"id": "miknatis", "name": "Mıknatıs", "icon": 7, "max": 5, "kind": "p", "desc": "+%35 toplama menzili"},
	{"id": "ofke", "name": "Öfke", "icon": 8, "max": 5, "kind": "p", "desc": "Bütün silahlara +%14 hasar"},
	{"id": "saat", "name": "Çabuk El", "icon": 9, "max": 5, "kind": "p", "desc": "Silahlar %9 daha sık ateş eder"},
	{"id": "menzil", "name": "Geniş Etki", "icon": 10, "max": 5, "kind": "p", "desc": "+%12 etki alanı"},
	{"id": "cogalt", "name": "Çoğalt", "icon": 11, "max": 2, "kind": "p", "desc": "Her silaha +1 mermi"},
	{"id": "tulum", "name": "Kalın Tulum", "icon": 12, "max": 4, "kind": "p", "desc": "Her vuruştan 1,5 daha az hasar"},
	{"id": "yaprak", "name": "Şifalı Yaprak", "icon": 13, "max": 5, "kind": "p", "desc": "Saniyede +0,5 can yenilenir"},
	{"id": "kitap", "name": "Arıcı Defteri", "icon": 14, "max": 5, "kind": "p", "desc": "+%12 tecrübe"},
	{"id": "nisan", "name": "Keskin Göz", "icon": 15, "max": 5, "kind": "p", "desc": "+%8 kritik şansı, kritik 2 kat vurur"},
	{"id": "inis", "name": "Ezici İniş", "icon": 16, "max": 5, "kind": "p", "desc": "Zıplayıp inince şok dalgası, +12 hasar"},
	{"id": "kayis", "name": "Dikenli Kayış", "icon": 17, "max": 5, "kind": "p", "desc": "Kayarken çarptığın düşman +14 hasar alır, kayma sıklaşır"},
]
const HEAL_CARD := {"id": "sifa", "name": "Bal Kavanozu", "icon": 18, "max": 999, "kind": "p", "desc": "40 can iyileşir"}
const SRC_NAMES := {"ari": "Arı Sürüsü", "tutsu": "Tütsü Halkası", "bomba": "Bal Bombası", "igne": "İğne Çarkı", "kivilcim": "Polen Kıvılcımı", "inis": "Ezici İniş", "kayis": "Dikenli Kayış", "sunak": "Sunak"}
const KILL_COL := [Color(0.6, 0.25, 0.8), Color(0.95, 0.25, 0.2), Color(0.4, 0.3, 0.8), Color(1.0, 0.4, 0.7), Color(1.0, 0.2, 0.2)]

var main
var active := false
var time := 0.0
var kills := 0
var level := 1
var xp := 0
var xp_need := 6
var xp_mult := 1.0
var passives := {}
var queue: Array[String] = []
var stats := {"taken": 0.0, "dealt": 0.0, "by": {}, "chests": 0, "shrines": 0}
var spawn_acc := 0.0
var next_wave := 60.0
var next_elite := 110.0
var boss_spawned := false
var over := false
var victory := false
var end_t := 0.0
var recycle_i := 0
var god := false

func setup(m) -> void:
	main = m

func start() -> void:
	active = true
	time = 0.0
	kills = 0
	level = 1
	xp = 0
	xp_need = _need(1)
	xp_mult = 1.0
	passives = {}
	queue.clear()
	stats = {"taken": 0.0, "dealt": 0.0, "by": {}, "chests": 0, "shrines": 0}
	spawn_acc = 3.0
	next_wave = 60.0
	next_elite = 110.0
	boss_spawned = false
	over = false
	victory = false
	end_t = 0.0
	Engine.time_scale = main.debug_speed
	main.enemies.clear()
	main.weapons.reset()
	main.pickups.reset()
	main.world.reset()
	main.player.reset()
	main.fx.reset()
	main.audio.music("oyun1")

func _need(l: int) -> int:
	return 5 + 3 * l + int(0.3 * l * l)

func hp_scale() -> float:
	var m := time / 60.0
	return 1.0 + m * 0.2 + m * m * 0.014

func upg(id: String) -> Dictionary:
	for u in UPG:
		if u.id == id:
			return u
	return HEAL_CARD

func level_of(id: String) -> int:
	if main.weapons.levels.has(id):
		return main.weapons.levels[id]
	return passives.get(id, 0)

func choices() -> Array:
	var pool: Array = []
	var weights: Array = []
	for u in UPG:
		var l := level_of(u.id)
		if l >= u.max:
			continue
		pool.append(u)
		if u.kind == "w":
			weights.append(1.5 if l > 0 else 1.3)
		else:
			weights.append(1.0)
	var out: Array = []
	while out.size() < 3 and not pool.is_empty():
		var total := 0.0
		for w in weights:
			total += w
		var r := randf() * total
		var k := 0
		while k < pool.size() - 1 and r > weights[k]:
			r -= weights[k]
			k += 1
		out.append(pool[k])
		pool.remove_at(k)
		weights.remove_at(k)
	# the first pick of a run always offers a second weapon
	if level <= 2:
		var has_new := false
		for u in out:
			if u.kind == "w" and level_of(u.id) == 0:
				has_new = true
		if not has_new and out.size() == 3:
			var ws: Array = []
			for u in UPG:
				if u.kind == "w" and level_of(u.id) == 0:
					ws.append(u)
			out[0] = ws[randi() % ws.size()]
	while out.size() < 3:
		out.append(HEAL_CARD)
	return out

func apply(id: String) -> void:
	if id == "sifa":
		main.player.heal(40.0)
	elif main.weapons.levels.has(id):
		main.weapons.levels[id] += 1
	else:
		passives[id] = passives.get(id, 0) + 1
		if id == "kalp":
			main.player.max_hp += 20.0
			main.player.heal(20.0)
	_recalc()

func _recalc() -> void:
	var pl = main.player
	var w = main.weapons
	pl.move_speed = 8.6 * (1.0 + 0.08 * passives.get("cizme", 0))
	pl.pickup_r = 3.2 * (1.0 + 0.35 * passives.get("miknatis", 0))
	pl.armor = 1.5 * passives.get("tulum", 0)
	pl.regen = 0.5 * passives.get("yaprak", 0)
	pl.stomp_lv = passives.get("inis", 0)
	pl.slide_lv = passives.get("kayis", 0)
	w.dmg_mult = 1.0 + 0.14 * passives.get("ofke", 0)
	w.cd_mult = pow(0.91, passives.get("saat", 0))
	w.area_mult = 1.0 + 0.12 * passives.get("menzil", 0)
	w.extra_proj = passives.get("cogalt", 0)
	w.crit = 0.05 + 0.08 * passives.get("nisan", 0)
	xp_mult = 1.0 + 0.12 * passives.get("kitap", 0)

func add_xp(v: int) -> void:
	xp += int(ceil(v * xp_mult))
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = _need(level)
		queue.append("level")

func open_chest() -> void:
	stats.chests += 1
	queue.append("chest")

func shrine_done(at: Vector3) -> void:
	stats.shrines += 1
	main.weapons.shrine_mult += 0.15
	main.player.heal(25.0)
	main.weapons.explode(at, 11.0, 70.0, "sunak")
	main.fx.shake(0.6)
	main.audio.play("shrine")
	main.ui.toast("Sunak uyandı, kalıcı +%15 hasar")

func on_damage_dealt(a: float, src: String) -> void:
	stats.dealt += a
	stats.by[src] = stats.by.get(src, 0.0) + a

func on_enemy_killed(t: int, at: Vector3, elite: bool, s: float) -> void:
	kills += 1
	main.audio.play("kill", 0.0, randf_range(0.85, 1.2))
	main.fx.burst(at + Vector3(0, 0.4, 0), KILL_COL[t], 8 + int(s * 3.0), 5.0 + s)
	if t == main.enemies.T_BOSS:
		_win(at)
		return
	var v: int = main.enemies.TYPES[t].xp
	if elite:
		main.pickups.drop_gem(at, 25)
		main.pickups.drop_item("chest", at)
		main.fx.shake(0.4)
	else:
		main.pickups.drop_gem(at, v)
		if randf() < 0.004:
			main.pickups.drop_item("magnet", at)

func on_player_dead() -> void:
	if over:
		return
	over = true
	victory = false
	end_t = 1.6
	Engine.time_scale = 0.35
	main.audio.play("defeat")

func _win(at: Vector3) -> void:
	over = true
	victory = true
	end_t = 2.6
	Engine.time_scale = 0.4
	main.fx.shake(1.0)
	main.fx.explosion(at, 12.0, Color(1.0, 0.8, 0.2))
	main.audio.play("victory")
	# the swarm dies with its queen
	var en = main.enemies
	for i in en.count:
		if en.dead[i] == 0:
			en.dead[i] = 1
			en.dead_any = true
			main.pickups.drop_gem(Vector3(en.px[i], 0, en.pz[i]), 1)
	main.pickups.pull_all()

func update(dt: float) -> void:
	if not active:
		return
	if over:
		end_t -= dt / maxf(0.05, Engine.time_scale)
		if end_t <= 0.0:
			active = false
			Engine.time_scale = 1.0
			main.finish_run(victory)
			return
	else:
		time += dt
	main.player.update(dt)
	main.enemies.update(dt)
	main.weapons.update(dt)
	main.pickups.update(dt)
	main.world.update(dt)
	main.fx.update(dt)
	if not over:
		_spawn(dt)
		if time >= 300.0 and not boss_spawned and main.audio.current == "oyun1":
			main.audio.music("oyun2")
		if not queue.is_empty() and not main.ui.choosing:
			var kind: String = queue.pop_front()
			main.ui.show_choice(kind, choices())

func _ring_pos(dmin: float, dmax: float) -> Vector2:
	var p: Vector3 = main.player.pos
	var lim: float = main.world.ARENA_R - 2.0
	var best := Vector2(p.x, p.z)
	for attempt in 8:
		var a := randf() * TAU
		var d := randf_range(dmin, dmax)
		best = Vector2(p.x + cos(a) * d, p.z + sin(a) * d)
		if best.length() < lim:
			return best
	return best.normalized() * lim

func _pick_type() -> int:
	var en = main.enemies
	var r := randf()
	if time > 300.0 and r < minf(0.13, (time - 300.0) / 1500.0 + 0.05):
		return en.T_SPIT
	r = randf()
	if time > 170.0 and r < minf(0.11, (time - 170.0) / 2500.0 + 0.04):
		return en.T_BRUTE
	r = randf()
	if time > 70.0 and r < minf(0.32, (time - 70.0) / 500.0 + 0.1):
		return en.T_WASP
	return en.T_BEETLE

func _spawn(dt: float) -> void:
	var en = main.enemies
	var boss_alive: bool = en.boss_uid >= 0
	var target := int(clampf(10.0 + time * 0.52, 10.0, 340.0))
	if boss_alive:
		target = 120
	spawn_acc += dt * (1.6 + time * 0.034)
	var n := 0
	while spawn_acc >= 1.0 and en.count < target and n < 12:
		spawn_acc -= 1.0
		n += 1
		var p := _ring_pos(24.0, 31.0)
		en.spawn(_pick_type(), p.x, p.y, false, hp_scale())
	if en.count >= target:
		spawn_acc = minf(spawn_acc, 1.0)
	# stragglers far behind the player rejoin the ring around them
	var pl: Vector3 = main.player.pos
	for k in 16:
		if en.count == 0:
			break
		recycle_i = (recycle_i + 1) % en.count
		var i := recycle_i
		if en.dead[i] == 0 and en.typ[i] != en.T_BOSS and en.elite[i] == 0:
			var dx: float = en.px[i] - pl.x
			var dz: float = en.pz[i] - pl.z
			if dx * dx + dz * dz > 46.0 * 46.0:
				var p2 := _ring_pos(26.0, 32.0)
				en.px[i] = p2.x
				en.pz[i] = p2.y
	if time >= next_wave and not boss_spawned:
		next_wave += 60.0
		var cnt := 14 + int(time / 18.0)
		var wt: int = en.T_WASP if (time > 200.0 and int(time / 60.0) % 2 == 0) else en.T_BEETLE
		var a0 := randf() * TAU
		for k in cnt:
			var a := a0 + TAU * k / cnt
			var q := Vector2(pl.x + cos(a) * 21.0, pl.z + sin(a) * 21.0)
			if q.length() > main.world.ARENA_R - 2.0:
				q = q.normalized() * (main.world.ARENA_R - 2.0)
			en.spawn(wt, q.x, q.y, false, hp_scale())
		main.ui.toast("Sürü geliyor!")
		main.audio.play("horn")
	if time >= next_elite and not boss_spawned:
		next_elite += 95.0
		var p3 := _ring_pos(22.0, 26.0)
		var et: int = en.T_BRUTE if time > 240.0 else en.T_BEETLE
		en.spawn(et, p3.x, p3.y, true, hp_scale() * (2.0 if et == en.T_BEETLE else 1.0))
		main.ui.toast("Elit geldi, sandığı onda")
		main.audio.play("horn", 0.0, 0.8)
	if time >= BOSS_TIME and not boss_spawned:
		boss_spawned = true
		var p4 := _ring_pos(28.0, 30.0)
		en.spawn(en.T_BOSS, p4.x, p4.y, false, 1.0)
		main.ui.toast("KRALİÇE GELDİ")
		main.audio.play("boss_roar")
		main.audio.music("boss")
		main.fx.shake(0.7)
