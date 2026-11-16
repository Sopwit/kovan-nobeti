extends Node3D
# Hit feedback: damage numbers (drawn in 2D), particle bursts, explosions, screen shake.

var main
var trauma := 0.0
var shake_time := 0.0
var numbers: Array = []
var num_layer: Control
var bursts: Array[CPUParticles3D] = []
var burst_i := 0
var hits: Array[CPUParticles3D] = []
var hit_i := 0
var booms: Array[MeshInstance3D] = []
var boom_t: Array[float] = []
var boom_r: Array[float] = []
var boom_i := 0
var hurt_rect: ColorRect
var hurt_a := 0.0
var hit_budget := 0

func setup(m) -> void:
	main = m
	var pm := BoxMesh.new()
	pm.size = Vector3(0.16, 0.16, 0.16)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.vertex_color_use_as_albedo = true
	pmat.vertex_color_is_srgb = true
	pm.material = pmat
	for k in 14:
		var p := _make_particles(pm, 14, 0.5)
		bursts.append(p)
	for k in 20:
		var p2 := _make_particles(pm, 5, 0.28)
		p2.initial_velocity_min = 3.0
		p2.initial_velocity_max = 6.0
		p2.color = Color(1.0, 0.95, 0.7)
		hits.append(p2)
	# explosions are flat shockwaves on the ground: a bright rim that runs outward over a short flash
	var sm := QuadMesh.new()
	sm.size = Vector2(2, 2)
	sm.orientation = PlaneMesh.FACE_Y
	var boom_shader := Shader.new()
	boom_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 col : source_color = vec4(1.0);
uniform float f = 0.0;
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float rim = smoothstep(0.70, 0.90, r) * (1.0 - smoothstep(0.93, 1.0, r));
	float flash = 1.0 - smoothstep(0.0, 0.95, r);
	float fade = 1.0 - f;
	ALBEDO = mix(col.rgb, vec3(1.0), 0.35 * fade);
	ALPHA = clamp(rim * 0.85 * fade + flash * 0.4 * fade * fade, 0.0, 1.0);
}
"""
	for k in 14:
		var b := MeshInstance3D.new()
		b.mesh = sm
		var bm := ShaderMaterial.new()
		bm.shader = boom_shader
		b.material_override = bm
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.visible = false
		add_child(b)
		booms.append(b)
		boom_t.append(0.0)
		boom_r.append(1.0)

func _make_particles(mesh: Mesh, amount: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = false
	p.direction = Vector3.UP
	p.spread = 80.0
	p.gravity = Vector3(0, -16, 0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 7.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.5
	var c := Curve.new()
	c.add_point(Vector2(0, 1))
	c.add_point(Vector2(1, 0))
	p.scale_amount_curve = c
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p

func attach_ui(layer: Control, hurt: ColorRect) -> void:
	num_layer = layer
	hurt_rect = hurt
	num_layer.draw.connect(_draw_numbers)

func reset() -> void:
	numbers.clear()
	trauma = 0.0
	hurt_a = 0.0
	for b in booms:
		b.visible = false

func shake(a: float) -> void:
	trauma = minf(1.0, maxf(trauma, a))

func shake_offset() -> Vector3:
	var t := trauma * trauma * 0.55
	return Vector3(sin(shake_time * 61.0) * t, cos(shake_time * 47.0) * t, 0)

func hurt_flash() -> void:
	hurt_a = 0.5

func number(at: Vector3, amount: float, crit: bool) -> void:
	if numbers.size() > 90:
		numbers.pop_front()
	numbers.append({"p": at, "v": int(round(amount)), "t": 0.0, "c": crit, "ox": randf_range(-18.0, 18.0)})

func hit(at: Vector3) -> void:
	main.audio.play("hit", -9.0, randf_range(0.85, 1.25))
	if hit_budget <= 0:
		return
	hit_budget -= 1
	var p := hits[hit_i]
	hit_i = (hit_i + 1) % hits.size()
	p.position = at
	p.restart()
	p.emitting = true

func burst(at: Vector3, col: Color, amount: int, speed: float) -> void:
	var p := bursts[burst_i]
	burst_i = (burst_i + 1) % bursts.size()
	p.position = at
	p.color = col
	p.amount = maxi(4, amount)
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.restart()
	p.emitting = true

func explosion(at: Vector3, r: float, col: Color) -> void:
	var b := booms[boom_i]
	boom_t[boom_i] = 0.28
	boom_r[boom_i] = r
	boom_i = (boom_i + 1) % booms.size()
	b.visible = true
	b.position = Vector3(at.x, 0.16, at.z)
	b.scale = Vector3(r * 0.3, 1.0, r * 0.3)
	var bmat := b.material_override as ShaderMaterial
	bmat.set_shader_parameter("col", col)
	bmat.set_shader_parameter("f", 0.0)
	burst(at + Vector3(0, 0.4, 0), col, 20, 9.0)

func update(dt: float) -> void:
	shake_time += dt
	trauma = maxf(0.0, trauma - dt * 1.9)
	hit_budget = 6
	for k in booms.size():
		if boom_t[k] > 0.0:
			boom_t[k] -= dt
			var f := 1.0 - boom_t[k] / 0.28
			var b := booms[k]
			var grow := boom_r[k] * (0.3 + 0.7 * sqrt(f))
			b.scale = Vector3(grow, 1.0, grow)
			(b.material_override as ShaderMaterial).set_shader_parameter("f", f)
			if boom_t[k] <= 0.0:
				b.visible = false
	var keep: Array = []
	for n in numbers:
		n.t += dt
		if n.t < 0.7:
			keep.append(n)
	numbers = keep
	if hurt_rect != null:
		hurt_a = maxf(0.0, hurt_a - dt * 1.6)
		var low := 0.0
		if main.player.alive and main.player.hp < main.player.max_hp * 0.3:
			low = 0.12 + 0.08 * sin(shake_time * 6.0)
		hurt_rect.color = Color(0.85, 0.05, 0.05, maxf(hurt_a, low))
	if num_layer != null:
		num_layer.queue_redraw()

func _draw_numbers() -> void:
	var cam: Camera3D = main.player.cam
	var font: Font = main.ui.font_bold
	for n in numbers:
		var wp: Vector3 = n.p
		if cam.is_position_behind(wp):
			continue
		var sp := cam.unproject_position(wp)
		var t: float = n.t
		var rise := t * 70.0
		var size := 20
		var col := Color(1, 1, 1)
		if n.c:
			size = 34
			col = Color(1.0, 0.85, 0.2)
		elif n.v >= 40:
			size = 26
			col = Color(1.0, 0.92, 0.6)
		var pop := 1.0 + maxf(0.0, 0.12 - t) * 5.0
		size = int(size * pop)
		col.a = clampf((0.7 - t) * 3.5, 0.0, 1.0)
		var s := str(n.v)
		var pos := Vector2(sp.x + n.ox - size * 0.3 * s.length(), sp.y - rise)
		num_layer.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0.1, 0.05, 0.15, col.a))
		num_layer.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
