extends Node3D
# Bright preview stage for checking models and animation clips side by side. Not part of the game.

const Assets := preload("res://scripts/assets.gd")

# sheet = "" shows run, idle, jump, slide at `frac`; a clip name shows that clip at eight moments in a row
var sheet := "":
	set(v):
		sheet = v
		_build_heroes()
var frac := 0.3:
	set(v):
		frac = v
		_build_heroes()
# raw = true shows the whole source clips, false shows the trimmed game clips
var raw := true:
	set(v):
		raw = v
		_build_heroes()
var turn := 0.0:
	set(v):
		turn = v
		_build_heroes()
var view := 0:
	set(v):
		view = v
		_place_camera()
var hero_root: Node3D
var assets
var cam: Camera3D
var ready_done := false

func _ready() -> void:
	assets = Assets.new()
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 0.8
	add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.4, 0.45, 0.4)
	floor_mi.material_override = fm
	add_child(floor_mi)
	hero_root = Node3D.new()
	add_child(hero_root)
	# models in a second row, facing +Z like the game expects
	var keys: Array[String] = ["bocek", "esekarisi", "gergedan", "tukuren", "kralice", "makas", "akrep", "patlak", "cekirge"]
	for i in keys.size():
		var mi := MeshInstance3D.new()
		mi.mesh = assets.prop_mesh(keys[i])
		mi.material_override = assets.prop_material(keys[i])
		mi.position = Vector3(-8.0 + i * 2.0, 0, -20.0)
		mi.scale = Vector3.ONE * 1.6
		add_child(mi)
		var l2 := Label3D.new()
		l2.text = keys[i]
		l2.position = Vector3(-8.0 + i * 2.0, 2.2, -20.0)
		l2.font_size = 48
		add_child(l2)
	# a bar that points along +Z, the direction every model should face
	var arrow := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 2.0)
	arrow.mesh = bm
	arrow.position = Vector3(-10.0, 0.1, -19.0)
	add_child(arrow)
	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	ready_done = true
	_place_camera()
	_build_heroes()

func _build_heroes() -> void:
	if not ready_done:
		return
	_place_camera()
	for c in hero_root.get_children():
		c.queue_free()
	var names: Array[String] = ["run", "idle", "jump", "slide"]
	var count := 4 if sheet == "" else 8
	for i in count:
		var built: Dictionary = assets.build_hero(raw)
		var root: Node3D = built.node
		var x := (-3.0 + i * 2.0) if sheet == "" else (-5.6 + i * 1.6)
		root.position = Vector3(x, 0, 0)
		root.rotation.y = turn
		hero_root.add_child(root)
		var clip: String = names[i] if sheet == "" else sheet
		var f := frac if sheet == "" else float(i) / 8.0
		var ap: AnimationPlayer = built.anim
		if ap != null and ap.has_animation(clip):
			ap.play(clip)
			ap.pause()
			ap.seek(clampf(f, 0.0, 0.999) * ap.get_animation(clip).length, true)
		var l := Label3D.new()
		l.text = clip if sheet == "" else "%.2f" % f
		l.position = Vector3(x, 2.3, 0)
		l.font_size = 56
		hero_root.add_child(l)

func _place_camera() -> void:
	if cam == null:
		return
	cam.fov = 40.0
	if view == 0:
		cam.position = Vector3(0, 1.2, 9.5 if sheet != "" else 6.2)
		cam.look_at(Vector3(0, 1.0, 0))
	elif view == 1:
		cam.position = Vector3(12.0, 1.2, 0.0)
		cam.look_at(Vector3(0, 1.0, 0))
	elif view == 4:
		cam.position = Vector3(0, 16.0, 0.1)
		cam.look_at(Vector3(0, 0.0, 0.0), Vector3(0, 0, -1))
	elif view == 2:
		cam.position = Vector3(0, 4.0, -7.0)
		cam.look_at(Vector3(0, 0.6, -20.0))
	else:
		cam.position = Vector3(0, 26.0, -19.9)
		cam.look_at(Vector3(0, 0.0, -20.0), Vector3(0, 0, -1))
