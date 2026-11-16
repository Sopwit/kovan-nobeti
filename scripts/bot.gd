extends RefCounted
# Demo bot used for testing: it steers the player, jumps and slides. It cannot be enabled from inside the game.

var main
var wander := Vector2(1, 0)
var wander_t := 0.0

func setup(m) -> void:
	main = m

func _goal(p: Vector2) -> Variant:
	var pl = main.player
	var best = null
	var best_d := 1e9
	if pl.hp < pl.max_hp * 0.5:
		for j in main.world.jars:
			if not j.taken:
				var d := p.distance_to(Vector2(j.pos.x, j.pos.z))
				if d < best_d:
					best_d = d
					best = Vector2(j.pos.x, j.pos.z)
		if best != null:
			return best
	for it in main.pickups.items:
		var d2 := p.distance_to(Vector2(it.pos.x, it.pos.z))
		if d2 < 25.0 and d2 < best_d:
			best_d = d2
			best = Vector2(it.pos.x, it.pos.z)
	if best != null:
		return best
	var pk = main.pickups
	var n: int = mini(pk.gn, 120)
	for i in n:
		var d3 := p.distance_to(Vector2(pk.gx[i], pk.gz[i]))
		if d3 < 9.0 and d3 < best_d:
			best_d = d3
			best = Vector2(pk.gx[i], pk.gz[i])
	if best != null:
		return best
	for c in main.world.chests:
		if not c.open:
			var d4 := p.distance_to(Vector2(c.pos.x, c.pos.z))
			if d4 < best_d:
				best_d = d4
				best = Vector2(c.pos.x, c.pos.z)
	for s in main.world.shrines:
		if not s.done:
			var d5 := p.distance_to(Vector2(s.pos.x, s.pos.z)) - 3.0
			if d5 < best_d:
				best_d = d5
				best = Vector2(s.pos.x + 2.5, s.pos.z)
	return best

func update(dt: float) -> void:
	var pl = main.player
	var en = main.enemies
	var p := Vector2(pl.pos.x, pl.pos.z)
	var move := Vector2.ZERO
	var close := 0
	for i in en.query(p.x, p.y, 7.0):
		var d := Vector2(p.x - en.px[i], p.y - en.pz[i])
		var l: float = maxf(0.3, d.length() - en.rad[i])
		var w := 1.8 / l
		if en.typ[i] == en.T_BOSS:
			w *= 3.0
		move += d.normalized() * w
		if l < 1.8:
			close += 1
	var goal = _goal(p)
	if goal != null:
		var to: Vector2 = goal - p
		if to.length() > 0.6:
			move += to.normalized() * 1.1
	if p.length() > main.world.ARENA_R - 9.0:
		move -= p.normalized() * 2.0
	wander_t -= dt
	if wander_t <= 0.0:
		wander_t = randf_range(1.0, 2.5)
		wander = Vector2.from_angle(randf() * TAU)
	move += wander * 0.25
	pl.bot_move = move.normalized() if move.length() > 0.05 else Vector2.ZERO
	if pl.on_ground and close >= 2 and randf() < dt * 2.5:
		pl.bot_jump = true
	if close >= 4 and randf() < dt * 2.0:
		pl.bot_slide = true
	for r in en.rings:
		var rd: float = absf(p.distance_to(Vector2(r.x, r.z)) - r.r)
		if rd < 2.2 and pl.on_ground:
			pl.bot_jump = true
	# the camera drifts behind the direction of travel so recordings are watchable
	if pl.bot_move.length() > 0.1:
		var want := atan2(-pl.bot_move.x, -pl.bot_move.y)
		pl.cam_yaw = lerp_angle(pl.cam_yaw, want, minf(1.0, dt * 0.8))
