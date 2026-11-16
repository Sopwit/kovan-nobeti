extends Node3D
# Player movement is integrated by hand in _process: flat ground, circle obstacles.

const GRAVITY := 30.0
const JUMP_V := 10.5
const SLIDE_TIME := 0.55
const SLIDE_SPEED := 17.0

var main
var pos := Vector3.ZERO
var vel := Vector3.ZERO
var facing := 0.0
var on_ground := true
var coyote := 0.0
var jump_buf := 0.0
var slide_buf := 0.0
var slide_t := 0.0
var slide_cd := 0.0
var slide_dir := Vector3.ZERO
var slide_hit := {}
var inv_t := 0.0
var hp := 100.0
var alive := true
var air_peak := 0.0

# stats changed by upgrades
var max_hp := 100.0
var move_speed := 8.2
var pickup_r := 3.2
var armor := 0.0
var regen := 0.0
var stomp_lv := 0
var slide_lv := 0

# camera
var cam_yaw := 0.0
var cam_pitch := -0.6
var cam_dist := 9.5
var look_shift := 0.0
var cam: Camera3D
var model: Node3D
var anim: AnimationPlayer
var cur_anim := ""
var blob: MeshInstance3D
var model_tilt := 0.0

# bot input
var bot_move := Vector2.ZERO
var bot_jump := false
var bot_slide := false

func setup(m) -> void:
	main = m
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.far = 400.0
	add_child(cam)
	cam.top_level = true
	cam.current = true
	var built: Dictionary = main.assets.build_hero()
	model = built.node
	anim = built.anim
	add_child(model)
	blob = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	q.orientation = PlaneMesh.FACE_Y
	blob.mesh = q
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_texture = main.assets.blob_texture()
	bm.albedo_color = Color(0, 0, 0, 0.45)
	blob.material_override = bm
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blob.top_level = true
	add_child(blob)

func reset() -> void:
	pos = Vector3.ZERO
	vel = Vector3.ZERO
	hp = 100.0
	max_hp = 100.0
	move_speed = 8.2
	pickup_r = 3.2
	armor = 0.0
	regen = 0.0
	stomp_lv = 0
	slide_lv = 0
	alive = true
	inv_t = 1.0
	slide_t = 0.0
	slide_cd = 0.0
	jump_buf = 0.0
	slide_buf = 0.0
	on_ground = true
	model.rotation = Vector3.ZERO
	model.visible = true
	cam_yaw = 0.0
	cam_pitch = -0.6
	cam_dist = 9.5
	look_shift = 0.0
	facing = 0.0
	model_tilt = 0.0
	_play("idle")
	position = pos
	_update_camera(1.0)

# Menu and end screen: the keeper stands idle while the camera orbits.
func menu_idle(dt: float) -> void:
	cam_dist = 6.2
	look_shift = -2.0
	if alive:
		_play("idle")
		model.rotation = Vector3(0, facing, 0)
	model.visible = true
	position = pos
	blob.position = Vector3(pos.x, 0.04, pos.z)
	_update_camera(dt)

func look(rel: Vector2) -> void:
	var s: float = main.settings.sens * 0.0032
	cam_yaw -= rel.x * s
	cam_pitch = clampf(cam_pitch - rel.y * s, -1.2, -0.08)

func _play(n: String, blend := 0.12) -> void:
	if cur_anim == n:
		return
	cur_anim = n
	if anim != null and anim.has_animation(n):
		anim.speed_scale = 1.0
		anim.play(n, blend)

func hurt(amount: float, fx: float, fz: float) -> bool:
	if not alive or inv_t > 0.0 or main.debug_god:
		return false
	var a := maxf(1.0, amount - armor)
	hp -= a
	inv_t = 0.6
	# a hit buys a moment of room instead of starting a chain of hits
	main.weapons.push_back(pos, 3.6, 10.0, false)
	main.game.stats.taken += a
	main.fx.shake(0.45)
	main.fx.hurt_flash()
	main.audio.play("hurt", 0.0, 1.0)
	var d := Vector3(pos.x - fx, 0, pos.z - fz)
	if d.length() > 0.01:
		d = d.normalized()
		vel.x += d.x * 7.0
		vel.z += d.z * 7.0
	if hp <= 0.0:
		hp = 0.0
		alive = false
		main.game.on_player_dead()
	return true

# Key presses that land on a frame the simulation skips (hit stop) are kept for the next one.
func buffer_input() -> void:
	if main.bot_mode:
		return
	if Input.is_action_just_pressed("jump"):
		jump_buf = 0.14
	if Input.is_action_just_pressed("slide"):
		slide_buf = 0.14

# Camera only, for frames where the simulation is frozen.
func hold_camera(dt: float) -> void:
	_update_camera(dt)

func heal(a: float) -> void:
	hp = minf(max_hp, hp + a)

func sliding() -> bool:
	return slide_t > 0.0

func update(dt: float) -> void:
	if not alive:
		model.rotation.x = lerpf(model.rotation.x, -PI * 0.5, minf(1.0, dt * 6.0))
		_update_camera(dt)
		return
	if inv_t > 0.0:
		inv_t -= dt
	if regen > 0.0:
		heal(regen * dt)
	slide_cd -= dt
	var inp := Vector2.ZERO
	var want_jump := false
	var want_slide := false
	if main.bot_mode:
		inp = bot_move
		want_jump = bot_jump
		want_slide = bot_slide
		bot_jump = false
		bot_slide = false
	else:
		inp = Input.get_vector("move_left", "move_right", "move_fwd", "move_back")
		want_jump = Input.is_action_just_pressed("jump")
		want_slide = Input.is_action_just_pressed("slide")
	var fwd := Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
	var right := Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
	var wish := right * inp.x - fwd * inp.y
	if main.bot_mode:
		wish = Vector3(inp.x, 0, inp.y)
	if wish.length() > 1.0:
		wish = wish.normalized()
	if want_jump:
		jump_buf = 0.14
	if want_slide:
		slide_buf = 0.14
	jump_buf -= dt
	slide_buf -= dt
	coyote = 0.12 if on_ground else coyote - dt
	# slide
	if slide_buf > 0.0 and slide_cd <= 0.0 and slide_t <= 0.0 and on_ground:
		slide_buf = 0.0
		slide_t = SLIDE_TIME
		slide_cd = 1.0 - 0.12 * slide_lv
		slide_dir = wish.normalized() if wish.length() > 0.2 else Vector3(sin(facing), 0, cos(facing))
		slide_hit.clear()
		inv_t = maxf(inv_t, 0.38)
		main.audio.play("slide", 0.0, 1.0)
		main.fx.burst(pos + Vector3(0, 0.2, 0), Color(0.85, 0.95, 0.6), 10, 4.0)
	var hv := Vector3(vel.x, 0, vel.z)
	if slide_t > 0.0:
		slide_t -= dt
		var k := clampf(slide_t / SLIDE_TIME, 0.0, 1.0)
		var sp := lerpf(move_speed * 1.05, SLIDE_SPEED + move_speed * 0.4, k)
		# a little steering while sliding
		slide_dir = (slide_dir + wish * dt * 2.5).normalized()
		hv = slide_dir * sp
		if slide_lv > 0:
			_slide_damage()
	else:
		var target := wish * move_speed
		var acc := 70.0 if on_ground else 28.0
		hv = hv.move_toward(target, acc * dt)
	# jump (also allowed out of a slide: keeps the speed)
	if jump_buf > 0.0 and coyote > 0.0:
		vel.y = JUMP_V
		jump_buf = 0.0
		coyote = 0.0
		on_ground = false
		air_peak = 0.0
		if slide_t > 0.0:
			slide_t = 0.0
			hv *= 1.08
		main.audio.play("jump", 0.0, 1.0)
	if not on_ground:
		# every jump has the same height: it is a dodge, and it has to clear spit and shock rings every time
		vel.y -= GRAVITY * dt
	vel.x = hv.x
	vel.z = hv.z
	pos += vel * dt
	air_peak = maxf(air_peak, pos.y)
	if pos.y <= 0.0:
		pos.y = 0.0
		if not on_ground:
			on_ground = true
			if air_peak > 0.8:
				main.audio.play("land", 0.0, 1.0)
				main.fx.burst(pos + Vector3(0, 0.1, 0), Color(0.8, 0.9, 0.55), 8, 3.5)
				if stomp_lv > 0:
					main.weapons.stomp(pos, stomp_lv)
		vel.y = 0.0
	else:
		on_ground = false
	# obstacles and arena edge
	for o in main.world.obstacles:
		var dx: float = pos.x - o.x
		var dz: float = pos.z - o.y
		var lim: float = o.z + 0.45
		var d2 := dx * dx + dz * dz
		if d2 < lim * lim and d2 > 0.0001 and pos.y < 2.2:
			var d := sqrt(d2)
			pos.x = o.x + dx / d * lim
			pos.z = o.y + dz / d * lim
	var ar: float = main.world.ARENA_R - 1.5
	var r2 := pos.x * pos.x + pos.z * pos.z
	if r2 > ar * ar:
		var rr := sqrt(r2)
		pos.x = pos.x / rr * ar
		pos.z = pos.z / rr * ar
	# facing and animation
	var flat := Vector3(vel.x, 0, vel.z)
	var spd := flat.length()
	if spd > 0.5:
		facing = lerp_angle(facing, atan2(flat.x, flat.z), minf(1.0, dt * 14.0))
	position = pos
	model.rotation.y = facing
	var tilt_target := 0.0
	if slide_t > 0.0:
		_play("slide", 0.08)
		if anim == null or not anim.has_animation("slide"):
			tilt_target = -0.35
	elif not on_ground:
		_play("jump", 0.08)
	elif spd > 1.0:
		_play("run", 0.12)
		if anim != null:
			anim.speed_scale = clampf(spd / 8.0, 0.7, 1.6)
	else:
		_play("idle", 0.18)
	model_tilt = lerpf(model_tilt, tilt_target, minf(1.0, dt * 14.0))
	model.rotation.x = model_tilt
	model.visible = inv_t <= 0.0 or slide_t > 0.0 or fmod(inv_t, 0.12) > 0.05
	blob.position = Vector3(pos.x, 0.04, pos.z)
	var bs := clampf(1.0 - pos.y * 0.12, 0.4, 1.0)
	blob.scale = Vector3(bs, 1, bs)
	_update_camera(dt)

func _slide_damage() -> void:
	var en = main.enemies
	for i in en.query(pos.x, pos.z, 1.4):
		var u: int = en.uid[i]
		if slide_hit.has(u):
			continue
		slide_hit[u] = true
		var dx: float = en.px[i] - pos.x
		var dz: float = en.pz[i] - pos.z
		var l := sqrt(dx * dx + dz * dz) + 0.01
		main.weapons.deal(i, 14.0 * slide_lv, dx / l * 9.0, dz / l * 9.0, "kayis")

func _update_camera(dt: float) -> void:
	var sh: Vector3 = main.fx.shake_offset()
	var spd := Vector3(vel.x, 0, vel.z).length()
	var target := pos + Vector3(0, 1.7, 0) + Vector3(cos(cam_yaw), 0, -sin(cam_yaw)) * look_shift
	var back := Vector3(sin(cam_yaw) * cos(cam_pitch), -sin(cam_pitch), cos(cam_yaw) * cos(cam_pitch))
	var want := target + back * cam_dist
	want.y = maxf(want.y, 0.6)
	cam.global_position = cam.global_position.lerp(want, minf(1.0, dt * 22.0)) if dt < 1.0 else want
	cam.look_at(target + Vector3(0, 0.3, 0), Vector3.UP)
	cam.h_offset = sh.x
	cam.v_offset = sh.y
	var fov_t := 68.0 + clampf((spd - 8.0) * 1.1, 0.0, 12.0)
	cam.fov = lerpf(cam.fov, fov_t, minf(1.0, dt * 6.0))
