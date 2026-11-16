extends Node
# Root of the game: builds every system, owns the state (menu, run, pause, end) and the saved settings.

const SAVE_PATH := "user://kovan_nobeti.cfg"

const Assets := preload("res://scripts/assets.gd")
const World := preload("res://scripts/world.gd")
const Player := preload("res://scripts/player.gd")
const Enemies := preload("res://scripts/enemies.gd")
const Weapons := preload("res://scripts/weapons.gd")
const Pickups := preload("res://scripts/pickups.gd")
const Fx := preload("res://scripts/fx.gd")
const Audio := preload("res://scripts/audio.gd")
const Game := preload("res://scripts/game.gd")
const Ui := preload("res://scripts/ui.gd")
const Bot := preload("res://scripts/bot.gd")

enum { MENU, PLAY, END }

var assets
var world
var player
var enemies
var weapons
var pickups
var fx
var audio
var game
var ui
var bot

var state := MENU
var paused := false
var settings := {"sens": 1.0, "music": 0.9, "sfx": 0.8, "brightness": 1.0}
var record := {"runs": 0, "best_time": 0.0, "best_kills": 0, "wins": 0}
var menu_yaw := 0.0

# test hooks: the demo bot plays by itself and never touches the saved record
var bot_mode := false
var debug_god := false
var debug_speed := 1.0:
	set(v):
		debug_speed = v
		if state == PLAY and game != null and not game.over:
			Engine.time_scale = v
var debug_time := -1.0:
	set(v):
		debug_time = v
		if game != null and v >= 0.0:
			game.time = v
			game.next_wave = (floor(v / 60.0) + 1.0) * 60.0
			game.next_elite = v + 20.0
var debug_levels := 0:
	set(v):
		debug_levels = v
		if game != null and v > 0:
			for i in v:
				game.level += 1
				game.queue.append("level")
var debug_start := false:
	set(v):
		debug_start = v
		if v and state != PLAY and game != null:
			start_run()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load()
	var want_time := -1.0
	var want_levels := 0
	for a in OS.get_cmdline_user_args():
		if a == "--bot":
			bot_mode = true
		elif a == "--god":
			debug_god = true
		elif a.begins_with("--speed="):
			debug_speed = float(a.split("=")[1])
		elif a.begins_with("--time="):
			want_time = float(a.split("=")[1])
		elif a.begins_with("--levels="):
			want_levels = int(a.split("=")[1])
	assets = Assets.new()
	audio = Audio.new()
	add_child(audio)
	audio.setup(self)
	world = World.new()
	add_child(world)
	world.setup(self)
	fx = Fx.new()
	add_child(fx)
	fx.setup(self)
	enemies = Enemies.new()
	add_child(enemies)
	enemies.setup(self)
	player = Player.new()
	add_child(player)
	player.setup(self)
	weapons = Weapons.new()
	add_child(weapons)
	weapons.setup(self)
	pickups = Pickups.new()
	add_child(pickups)
	pickups.setup(self)
	game = Game.new()
	add_child(game)
	game.setup(self)
	bot = Bot.new()
	bot.setup(self)
	ui = Ui.new()
	add_child(ui)
	ui.setup(self)
	for n in [world, fx, enemies, player, weapons, pickups, game]:
		n.process_mode = Node.PROCESS_MODE_PAUSABLE
	apply_settings()
	to_menu()
	if bot_mode:
		start_run()
		debug_time = want_time
		debug_levels = want_levels

func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_fwd": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE], "slide": [KEY_SHIFT, KEY_CTRL], "pause": [KEY_ESCAPE],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func _load() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	for k in settings:
		settings[k] = float(cf.get_value("ayarlar", k, settings[k]))
	for k in record:
		record[k] = cf.get_value("rekor", k, record[k])

func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings:
		cf.set_value("ayarlar", k, settings[k])
	for k in record:
		cf.set_value("rekor", k, record[k])
	cf.save(SAVE_PATH)

func apply_settings() -> void:
	audio.apply_volumes()
	world.set_brightness(settings.brightness)

func capture_mouse() -> void:
	if not bot_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func to_menu() -> void:
	state = MENU
	paused = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	game.active = false
	enemies.clear()
	pickups.reset()
	weapons.reset()
	world.reset()
	player.reset()
	fx.reset()
	ui.show_menu()
	release_mouse()
	audio.music("menu")

func start_run() -> void:
	state = PLAY
	paused = false
	get_tree().paused = false
	game.start()
	ui.start_hud()
	capture_mouse()

func toggle_pause() -> void:
	if state != PLAY or ui.choosing or game.over:
		return
	paused = not paused
	get_tree().paused = paused
	ui.show_pause(paused)
	if paused:
		release_mouse()
	else:
		save_settings()
		capture_mouse()

func finish_run(victory: bool) -> void:
	state = END
	var new_record := false
	if not bot_mode:
		record.runs += 1
		if victory:
			record.wins += 1
		if game.time > record.best_time:
			record.best_time = game.time
			new_record = record.runs > 1
		record.best_kills = maxi(record.best_kills, game.kills)
		save_settings()
	release_mouse()
	ui.show_end(victory, new_record)

func quit_game() -> void:
	save_settings()
	get_tree().quit()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause"):
		if ui.settings_overlay.visible:
			ui.settings_overlay.visible = false
		else:
			toggle_pause()
	elif ev is InputEventMouseMotion and state == PLAY and not paused and not ui.choosing and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.look((ev as InputEventMouseMotion).relative)

func _process(dt: float) -> void:
	if state == PLAY:
		if get_tree().paused:
			return
		if bot_mode:
			bot.update(dt)
		game.update(dt)
	else:
		# menu and end screen: a slow orbit around the keeper
		menu_yaw += dt * 0.12
		player.cam_yaw = menu_yaw
		player.cam_pitch = -0.2
		player.menu_idle(dt)
		fx.update(dt)
