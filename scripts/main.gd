extends Node
# Root of the game: builds every system, owns the state (menu, run, pause, end) and the saved settings.

# Plain JSON on purpose: it can only hold numbers, strings, arrays and dictionaries, so a tampered save
# cannot make the engine build objects or load resources the way a ConfigFile can.
const SAVE_PATH := "user://kovan_nobeti.json"
const SETTING_RANGE := {"sens": [0.2, 3.0], "music": [0.0, 1.0], "sfx": [0.0, 1.0], "brightness": [0.6, 1.5]}

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
# real seconds the simulation stays frozen after a heavy kill
var hit_stop := 0.0
var hit_stop_cd := 0.0

# test hooks: the demo bot plays by itself and never touches the saved record
var bot_mode := false
# with --once a bot run quits when it ends, for balance runs from the command line
var bot_once := false
var debug_god := false
var debug_speed := 1.0:
	set(v):
		debug_speed = clampf(v, 0.1, 20.0)
		if state == PLAY and game != null and not game.over:
			Engine.time_scale = debug_speed
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
			for i in mini(v, 200):
				game.level += 1
				game.xp_need = game._need(game.level)
				if bot_mode and not ui.hold_choice:
					# the bot takes its head start without sitting through the panels
					var c: Array = game.choices()
					game.apply(c[ui.bot_pick(c)].id)
				else:
					game.queue.append("level")
# "choice" holds an upgrade panel open ("chest" a chest one, "evo" one with an evolution),
# "pause" opens the pause menu, "settings" the settings panel of the main menu, "win" and "lose" end the run
var debug_ui := "":
	set(v):
		debug_ui = v
		if v == "settings" and ui != null:
			ui.open_settings()
			return
		if game == null or state != PLAY:
			return
		if v == "choice":
			ui.hold_choice = true
			game.queue.append("level")
		elif v == "chest":
			ui.hold_choice = true
			game.queue.append("chest")
		elif v == "evo":
			ui.hold_choice = true
			weapons.levels.ari = 6
			weapons.levels.bomba = 3
			game.passives.cogalt = 2
			game._recalc()
			game.queue.append("chest")
		elif v == "pause":
			toggle_pause()
		elif v == "win":
			game._win(player.pos)
		elif v == "lose":
			player.hp = 0.0
			player.alive = false
			game.on_player_dead()
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
	# the test flags only exist in debug builds: an exported release ignores them
	var args := OS.get_cmdline_user_args() if OS.is_debug_build() else PackedStringArray()
	for a in args:
		if a == "--bot":
			bot_mode = true
		elif a == "--once":
			bot_once = true
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
	var names := {"World": world, "Fx": fx, "Enemies": enemies, "Player": player, "Weapons": weapons, "Pickups": pickups, "Game": game, "Audio": audio, "Ui": ui}
	for key in names:
		names[key].name = key
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

func _num(v) -> bool:
	return (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and is_finite(float(v))

# Every value read from disk is checked for type and range: a broken or edited save falls back to defaults.
func _load() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null or f.get_length() > 65536:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	var s = data.get("ayarlar")
	if typeof(s) == TYPE_DICTIONARY:
		for k in settings:
			if _num(s.get(k)):
				settings[k] = clampf(float(s[k]), SETTING_RANGE[k][0], SETTING_RANGE[k][1])
	var r = data.get("rekor")
	if typeof(r) == TYPE_DICTIONARY:
		for k in record:
			if _num(r.get(k)):
				var v: float = clampf(float(r[k]), 0.0, 1.0e9)
				if k == "best_time":
					record[k] = v
				else:
					record[k] = int(v)

func save_settings() -> void:
	if bot_mode:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"ayarlar": settings, "rekor": record}, "\t"))

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
	hit_stop = 0.0
	hit_stop_cd = 0.0
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

# A run left from the pause menu still counts toward the record.
func leave_run() -> void:
	if state != PLAY or bot_mode or game.over:
		return
	record.runs += 1
	record.best_time = maxf(record.best_time, game.time)
	record.best_kills = maxi(record.best_kills, game.kills)
	save_settings()

# Freezes the simulation for a moment. Ordinary heavy kills share a cooldown so a strong build
# mowing through brutes does not turn into a stutter; always = true skips the cooldown.
func stop_for(d: float, always := false) -> void:
	if always or hit_stop_cd <= 0.0:
		hit_stop = maxf(hit_stop, d)
		hit_stop_cd = 0.5

func _notification(what: int) -> void:
	if ui == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# a run must not go on behind another window
		if state == PLAY and not paused and not bot_mode:
			toggle_pause()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_settings()

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
	if bot_mode and bot_once:
		get_tree().quit()

func quit_game() -> void:
	save_settings()
	get_tree().quit()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause"):
		if ui.settings_overlay.visible:
			ui.close_settings()
		else:
			toggle_pause()
	elif ev is InputEventMouseMotion and state == PLAY and not paused and not ui.choosing and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# screen_relative is in real pixels: plain relative is scaled with the window, which would tie
		# the sensitivity to the window size
		player.look((ev as InputEventMouseMotion).screen_relative)

func _process(dt: float) -> void:
	if state == PLAY:
		if get_tree().paused:
			return
		var real := dt / maxf(0.05, Engine.time_scale)
		hit_stop_cd -= real
		if hit_stop > 0.0:
			# the world holds still, the camera and the keys do not
			hit_stop -= real
			player.buffer_input()
			player.hold_camera(real)
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
