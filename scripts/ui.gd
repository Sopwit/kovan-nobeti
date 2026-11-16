extends CanvasLayer
# Menus, HUD, upgrade cards and the end screen. Everything is built in code.

const AMBER := Color(1.0, 0.74, 0.16)
const TEAL := Color(0.2, 0.85, 0.75)
const NAVY := Color(0.06, 0.08, 0.16)
const CREAM := Color(1.0, 0.96, 0.86)

var main
var font: Font
var font_bold: FontVariation
var root: Control
var num_layer: Control
var hurt: ColorRect
var hud: Control
var menu: Control
var menu_record: Label
var pause_panel: Control
var settings_box: Control
var settings_overlay: Control
var choice_panel: Control
var choice_title: Label
var cards: Array = []
var card_data: Array = []
var end_panel: Control
var end_title: Label
var end_stats: VBoxContainer
var end_damage: VBoxContainer
var end_again: Button
var choosing := false
var choice_lock := 0.0
var bot_t := 0.0
var toast_text := ""
var toast_t := 0.0
var icons := {}
var sliders := {}
var hint_t := 0.0
var hold_choice := false

func setup(m) -> void:
	main = m
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	font_bold = FontVariation.new()
	font_bold.base_font = font
	font_bold.variation_embolden = 0.9
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hurt = ColorRect.new()
	hurt.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt.color = Color(1, 0, 0, 0)
	hurt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hurt)
	num_layer = Control.new()
	num_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	num_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(num_layer)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	root.add_child(hud)
	main.fx.attach_ui(num_layer, hurt)
	for i in 20:
		icons[i] = main.assets.icon(i)
	_build_choice()
	_build_menu()
	_build_pause()
	_build_end()
	_build_settings_overlay()

# ---------- helpers

func _style(bg: Color, border: Color, bw := 3, radius := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(22)
	return s

func _label(text: String, size: int, col := CREAM, bold := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_bold if bold else font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1))
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	return l

func _button(text: String, cb: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 68)
	b.add_theme_font_override("font", font_bold)
	b.add_theme_font_size_override("font_size", 30)
	var base := Color(0.95, 0.62, 0.1) if primary else Color(0.14, 0.18, 0.32)
	b.add_theme_stylebox_override("normal", _style(base, base.lightened(0.25), 3, 16))
	b.add_theme_stylebox_override("hover", _style(base.lightened(0.15), CREAM, 3, 16))
	b.add_theme_stylebox_override("focus", _style(base.lightened(0.15), CREAM, 3, 16))
	b.add_theme_stylebox_override("pressed", _style(base.darkened(0.2), CREAM, 3, 16))
	b.add_theme_color_override("font_color", NAVY if primary else CREAM)
	b.add_theme_color_override("font_hover_color", NAVY if primary else Color.WHITE)
	b.add_theme_color_override("font_focus_color", NAVY if primary else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", NAVY if primary else Color.WHITE)
	b.pressed.connect(func():
		main.audio.play("click")
		cb.call())
	return b

func _dim(alpha: float) -> ColorRect:
	var c := ColorRect.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.color = Color(0.02, 0.03, 0.08, alpha)
	return c

func fmt_time(sec: float) -> String:
	var s := int(floor(maxf(0.0, sec)))
	@warning_ignore("integer_division")
	return "%02d:%02d" % [s / 60, s % 60]

func fmt_int(v: float) -> String:
	var s := str(int(round(v)))
	var out := ""
	var n := s.length()
	for i in n:
		out += s[i]
		var left := n - i - 1
		if left > 0 and left % 3 == 0:
			out += "."
	return out

func toast(t: String) -> void:
	toast_text = t
	toast_t = 2.6

# ---------- settings (shared by the pause menu and the main menu)

func _slider_row(parent: Container, title: String, key: String, lo: float, hi: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var l := _label(title, 24, CREAM, false)
	l.custom_minimum_size = Vector2(210, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = main.settings[key]
	s.custom_minimum_size = Vector2(300, 36)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var grab := StyleBoxFlat.new()
	grab.bg_color = AMBER
	grab.set_corner_radius_all(6)
	grab.set_content_margin_all(6)
	s.add_theme_stylebox_override("grabber_area", grab)
	s.add_theme_stylebox_override("grabber_area_highlight", grab)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.2, 0.24, 0.4)
	track.set_corner_radius_all(6)
	track.set_content_margin_all(6)
	s.add_theme_stylebox_override("slider", track)
	s.value_changed.connect(func(v: float):
		main.settings[key] = v
		main.apply_settings())
	row.add_child(s)
	parent.add_child(row)
	if not sliders.has(key):
		sliders[key] = []
	sliders[key].append(s)

func _settings_rows(parent: Container) -> void:
	_slider_row(parent, "Fare hassasiyeti", "sens", 0.2, 3.0)
	_slider_row(parent, "Müzik", "music", 0.0, 1.0)
	_slider_row(parent, "Efekt sesi", "sfx", 0.0, 1.0)
	_slider_row(parent, "Parlaklık", "brightness", 0.6, 1.5)

func _sync_sliders() -> void:
	for key in sliders:
		for s in sliders[key]:
			(s as HSlider).set_value_no_signal(main.settings[key])

func _build_settings_overlay() -> void:
	settings_overlay = Control.new()
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.visible = false
	root.add_child(settings_overlay)
	settings_overlay.add_child(_dim(0.6))
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.1, 0.2, 0.97), AMBER))
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	p.add_child(v)
	v.add_child(_label("Ayarlar", 40, AMBER))
	_settings_rows(v)
	var b := _button("Tamam", func():
		settings_overlay.visible = false
		main.save_settings())
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)

# ---------- main menu

func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.05, 0.12, 0.28)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(shade)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	v.position = Vector2(140, -330)
	v.add_theme_constant_override("separation", 16)
	menu.add_child(v)
	var t1 := _label("KOVAN", 150, AMBER)
	var t2 := _label("NÖBETİ", 150, CREAM)
	t1.add_theme_constant_override("line_spacing", -30)
	v.add_child(t1)
	v.add_child(t2)
	menu_record = _label("", 28, CREAM, false)
	v.add_child(menu_record)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	v.add_child(sp)
	var start := _button("Başla", func(): main.start_run(), true)
	start.name = "Basla"
	for b in [start, _button("Ayarlar", func():
		_sync_sliders()
		settings_overlay.visible = true), _button("Çıkış", func(): main.quit_game())]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		v.add_child(b)

func show_menu() -> void:
	menu.visible = true
	hud.visible = false
	pause_panel.visible = false
	choice_panel.visible = false
	end_panel.visible = false
	var r: Dictionary = main.record
	if r.get("runs", 0) > 0:
		var s := "En uzun tur %s, %s böcek" % [fmt_time(r.get("best_time", 0.0)), fmt_int(r.get("best_kills", 0))]
		if r.get("wins", 0) > 0:
			s += ", Kraliçe %d kez devrildi" % r.wins
		menu_record.text = s
	else:
		menu_record.text = "Kraliçe 10. dakikada geliyor"
	(menu.find_child("Basla", true, false) as Button).grab_focus()

# ---------- pause

func _build_pause() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	root.add_child(pause_panel)
	pause_panel.add_child(_dim(0.6))
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.1, 0.2, 0.97), AMBER))
	cc.add_child(p)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 22)
	p.add_child(outer)
	outer.add_child(_label("Duraklatıldı", 44, AMBER))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 48)
	outer.add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	h.add_child(left)
	var cont := _button("Devam", func(): main.toggle_pause(), true)
	cont.name = "Devam"
	left.add_child(cont)
	left.add_child(_button("Yeniden başla", func(): main.start_run()))
	left.add_child(_button("Ana menü", func(): main.to_menu()))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 20)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right)
	_settings_rows(right)

func show_pause(on: bool) -> void:
	pause_panel.visible = on
	if on:
		_sync_sliders()
		(pause_panel.find_child("Devam", true, false) as Button).grab_focus()

# ---------- upgrade choice

func _build_choice() -> void:
	choice_panel = Control.new()
	choice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	choice_panel.visible = false
	root.add_child(choice_panel)
	choice_panel.add_child(_dim(0.5))
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	choice_panel.add_child(cc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 30)
	cc.add_child(v)
	choice_title = _label("SEVİYE ATLADIN", 64, AMBER)
	choice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(choice_title)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	v.add_child(h)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(380, 470)
		b.add_theme_stylebox_override("normal", _style(Color(0.08, 0.1, 0.2, 0.96), Color(0.3, 0.36, 0.6), 4, 22))
		b.add_theme_stylebox_override("hover", _style(Color(0.13, 0.16, 0.3, 0.98), AMBER, 5, 22))
		b.add_theme_stylebox_override("focus", _style(Color(0.13, 0.16, 0.3, 0.98), AMBER, 5, 22))
		b.add_theme_stylebox_override("pressed", _style(Color(0.2, 0.2, 0.3, 0.98), CREAM, 5, 22))
		var idx := i
		b.pressed.connect(func(): _choose(idx))
		h.add_child(b)
		var box := VBoxContainer.new()
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 24
		box.offset_right = -24
		box.offset_top = 22
		box.offset_bottom = -22
		box.add_theme_constant_override("separation", 10)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(box)
		var top := HBoxContainer.new()
		top.custom_minimum_size = Vector2(0, 48)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(top)
		var key := _label(str(i + 1), 26, Color(0.6, 0.66, 0.85))
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(key)
		# the evolution partner of this card: a trait for a weapon, a weapon for a trait
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 8)
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(pair)
		var pair_l := _label("Evrim", 20, Color(0.7, 0.75, 0.92), false)
		pair.add_child(pair_l)
		var pair_icon := TextureRect.new()
		pair_icon.custom_minimum_size = Vector2(46, 46)
		pair_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pair_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pair_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(pair_icon)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(170, 170)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
		var nm := _label("", 34, CREAM)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(nm)
		var lv := _label("", 24, AMBER)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(lv)
		var ds := _label("", 24, Color(0.85, 0.88, 1.0), false)
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(ds)
		cards.append({"button": b, "icon": icon, "name": nm, "level": lv, "desc": ds, "pair": pair, "pair_icon": pair_icon})

func show_choice(kind: String, list: Array) -> void:
	choosing = true
	choice_lock = 0.45
	bot_t = 0.25
	card_data = list
	choice_title.text = "SANDIK AÇILDI" if kind == "chest" else "SEVİYE %d" % main.game.level
	for i in 3:
		var u: Dictionary = list[i]
		var c: Dictionary = cards[i]
		var l: int = main.game.level_of(u.id)
		c.icon.texture = icons.get(u.icon)
		c.name.text = u.name
		var partner: String = "" if (u.id == "sifa" or u.kind == "e") else main.game.evo_partner(u.id)
		c.pair.visible = partner != ""
		if partner != "":
			c.pair_icon.texture = icons.get(main.game.upg(partner).icon)
			var ready: bool = main.game.evo_ready(u.id if u.kind == "w" else partner)
			c.pair.modulate.a = 1.0 if ready else 0.5
		if u.id == "sifa":
			c.level.text = ""
			c.desc.text = u.desc
		elif u.kind == "e":
			c.level.text = "EVRİM"
			c.desc.text = u.desc
		elif u.kind == "w":
			c.level.text = "YENİ SİLAH" if l == 0 else "Silah, seviye %d" % (l + 1)
			c.desc.text = u.desc[l]
		else:
			c.level.text = "Özellik, seviye %d" % (l + 1)
			c.desc.text = u.desc
		c.level.add_theme_color_override("font_color", TEAL if u.kind == "p" else AMBER)
		c.name.add_theme_color_override("font_color", AMBER if u.kind == "e" else CREAM)
	choice_panel.visible = true
	choice_panel.modulate.a = 0.0
	get_tree().paused = true
	main.audio.play("chest" if kind == "chest" else "levelup")
	main.release_mouse()
	cards[1].button.grab_focus()

func _choose(i: int) -> void:
	if not choosing or choice_lock > 0.0:
		return
	choosing = false
	main.audio.play("click")
	main.game.apply(card_data[i].id)
	choice_panel.visible = false
	if main.game.queue.is_empty():
		get_tree().paused = false
		main.capture_mouse()
		# play resumes with breathing room: the crowd is shoved back and the first hit is forgiven
		main.weapons.push_back(main.player.pos, 6.5, 16.0)
		main.player.inv_t = maxf(main.player.inv_t, 0.5)
	else:
		var kind: String = main.game.queue.pop_front()
		show_choice(kind, main.game.choices())

# ---------- end screen

func _build_end() -> void:
	end_panel = Control.new()
	end_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_panel.visible = false
	root.add_child(end_panel)
	end_panel.add_child(_dim(0.62))
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_panel.add_child(cc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	cc.add_child(v)
	end_title = _label("", 86, AMBER)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(end_title)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	for k in 2:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(520, 400)
		p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.1, 0.2, 0.95), Color(0.3, 0.36, 0.6)))
		h.add_child(p)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		p.add_child(box)
		if k == 0:
			end_stats = box
		else:
			end_damage = box
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 24)
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(bh)
	end_again = _button("Bir tur daha", func(): main.start_run(), true)
	bh.add_child(end_again)
	bh.add_child(_button("Ana menü", func(): main.to_menu()))

func _stat_row(parent: Container, name: String, value: String, col := CREAM) -> void:
	var row := HBoxContainer.new()
	var a := _label(name, 26, Color(0.75, 0.8, 0.95), false)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(a)
	row.add_child(_label(value, 28, col))
	parent.add_child(row)

func show_end(victory: bool, new_record: bool) -> void:
	var g = main.game
	hud.visible = false
	end_title.text = "KRALİÇE DEVRİLDİ" if victory else "KOVAN DÜŞTÜ"
	end_title.add_theme_color_override("font_color", AMBER if victory else Color(1.0, 0.4, 0.35))
	for c in end_stats.get_children():
		c.queue_free()
	for c in end_damage.get_children():
		c.queue_free()
	_stat_row(end_stats, "Süre", fmt_time(g.time), AMBER if new_record else CREAM)
	_stat_row(end_stats, "Öldürülen böcek", fmt_int(g.kills))
	_stat_row(end_stats, "Seviye", str(g.level))
	_stat_row(end_stats, "Verilen hasar", fmt_int(g.stats.dealt))
	_stat_row(end_stats, "Alınan hasar", fmt_int(g.stats.taken))
	_stat_row(end_stats, "Açılan sandık", str(g.stats.chests))
	_stat_row(end_stats, "Uyanan sunak", "%d / 4" % g.stats.shrines)
	if new_record:
		_stat_row(end_stats, "Yeni rekor", fmt_time(g.time), AMBER)
	# damage share per weapon, biggest first
	var by: Dictionary = g.stats.by
	var keys: Array = by.keys()
	keys.sort_custom(func(a, b): return by[a] > by[b])
	var top := 1.0
	if not keys.is_empty():
		top = maxf(1.0, by[keys[0]])
	for k in keys:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var hh := HBoxContainer.new()
		var nm := _label(g.SRC_NAMES.get(k, k), 24, CREAM, false)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hh.add_child(nm)
		hh.add_child(_label(fmt_int(by[k]), 24, AMBER))
		row.add_child(hh)
		var bar := ColorRect.new()
		bar.color = AMBER
		bar.custom_minimum_size = Vector2(maxf(6.0, 470.0 * by[k] / top), 10)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(bar)
		end_damage.add_child(row)
	end_panel.visible = true
	end_again.grab_focus()

# ---------- per frame

func _process(dt: float) -> void:
	if choosing:
		choice_lock -= dt
		choice_panel.modulate.a = minf(1.0, choice_panel.modulate.a + dt * 6.0)
		if main.bot_mode and not hold_choice:
			bot_t -= dt
			if bot_t <= 0.0:
				choice_lock = 0.0
				# the bot plays like a sensible player: evolutions first, then weapons, else anything
				var pick := randi() % 3
				for want in (["w", "e"] if randf() < 0.6 else ["e"]):
					for ci in 3:
						if card_data[ci].kind == want and card_data[ci].id != "sifa":
							pick = ci
				_choose(pick)
	if toast_t > 0.0:
		toast_t -= dt
	hint_t -= dt
	if hud.visible:
		hud.queue_redraw()

func _input(ev: InputEvent) -> void:
	if choosing and ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = (ev as InputEventKey).physical_keycode
		if k == KEY_1 or k == KEY_KP_1:
			_choose(0)
		elif k == KEY_2 or k == KEY_KP_2:
			_choose(1)
		elif k == KEY_3 or k == KEY_KP_3:
			_choose(2)

func start_hud() -> void:
	menu.visible = false
	end_panel.visible = false
	pause_panel.visible = false
	choice_panel.visible = false
	choosing = false
	hud.visible = true
	hint_t = 14.0
	toast_t = 0.0

func _text(c: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	c.draw_string_outline(font_bold, pos, s, align, width, size, maxi(4, size / 5), Color(0.05, 0.04, 0.1, col.a))
	c.draw_string(font_bold, pos, s, align, width, size, col)

func _bar(c: CanvasItem, r: Rect2, frac: float, col: Color, bg := Color(0.05, 0.07, 0.14, 0.8)) -> void:
	c.draw_rect(r.grow(3), Color(0.03, 0.03, 0.08, 0.85))
	c.draw_rect(r, bg)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), col)

func _draw_hud() -> void:
	var g = main.game
	var pl = main.player
	var en = main.enemies
	var W := hud.size.x
	var H := hud.size.y
	# experience across the top
	_bar(hud, Rect2(0, 0, W, 14), float(g.xp) / float(g.xp_need), AMBER)
	_text(hud, Vector2(24, 62), "Seviye %d" % g.level, 34, CREAM)
	_text(hud, Vector2(24, 100), "%s böcek" % fmt_int(g.kills), 26, Color(0.85, 0.88, 1.0))
	# clock or boss bar
	var b: int = en.boss_index()
	if b >= 0:
		_text(hud, Vector2(W * 0.5 - 300, 62), "KRALİÇE", 36, Color(1.0, 0.35, 0.3), HORIZONTAL_ALIGNMENT_CENTER, 600)
		_bar(hud, Rect2(W * 0.5 - 360, 78, 720, 22), en.hp[b] / en.maxhp[b], Color(0.9, 0.15, 0.2))
	else:
		var left: float = g.BOSS_TIME - g.time
		var col := CREAM if left > 30.0 else Color(1.0, 0.45, 0.35)
		var secs := int(ceil(maxf(0.0, left)))
		@warning_ignore("integer_division")
		_text(hud, Vector2(W * 0.5 - 200, 78), "%02d:%02d" % [secs / 60, secs % 60], 56, col, HORIZONTAL_ALIGNMENT_CENTER, 400)
	# health and slide
	var hw := 460.0
	var hr := Rect2(W * 0.5 - hw * 0.5, H - 74, hw, 28)
	var hp_frac: float = pl.hp / pl.max_hp
	_bar(hud, hr, hp_frac, Color(0.3, 0.85, 0.35) if hp_frac > 0.3 else Color(0.95, 0.25, 0.2))
	_text(hud, Vector2(hr.position.x, hr.position.y + 23), "%d / %d" % [int(ceil(pl.hp)), int(pl.max_hp)], 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, hw)
	var sl := 1.0 - clampf(pl.slide_cd / 1.0, 0.0, 1.0)
	_bar(hud, Rect2(W * 0.5 - hw * 0.5, H - 36, hw, 8), sl, TEAL if sl >= 1.0 else Color(0.2, 0.5, 0.55))
	# weapons and traits
	var x := 24.0
	for id in main.weapons.IDS:
		var l: int = main.weapons.levels[id]
		if l <= 0:
			continue
		var u: Dictionary = g.upg(id)
		var r := Rect2(x, H - 96, 72, 72)
		hud.draw_rect(r.grow(4), Color(0.05, 0.07, 0.15, 0.85))
		hud.draw_rect(r.grow(4), CREAM if l >= 7 else AMBER, false, 4.0 if l >= 7 else 2.0)
		if icons.get(u.icon) != null:
			hud.draw_texture_rect(icons[u.icon], r, false)
		_text(hud, Vector2(x + 46, H - 22), str(l), 24, CREAM if l >= 7 else AMBER)
		x += 88.0
	x = 24.0
	for id in g.passives:
		var u2: Dictionary = g.upg(id)
		var r2 := Rect2(x, H - 160, 46, 46)
		hud.draw_rect(r2.grow(3), Color(0.05, 0.07, 0.15, 0.8))
		if icons.get(u2.icon) != null:
			hud.draw_texture_rect(icons[u2.icon], r2, false)
		_text(hud, Vector2(x + 30, H - 112), str(g.passives[id]), 18, TEAL)
		x += 56.0
	_draw_minimap(W)
	if main.world.shrine_progress >= 0.0:
		_text(hud, Vector2(W * 0.5 - 200, H * 0.70), "Sunak uyanıyor", 26, TEAL, HORIZONTAL_ALIGNMENT_CENTER, 400)
		_bar(hud, Rect2(W * 0.5 - 170, H * 0.70 + 12, 340, 14), main.world.shrine_progress, TEAL)
	if toast_t > 0.0:
		var a := clampf(toast_t * 2.0, 0.0, 1.0)
		var pop := 1.0 + maxf(0.0, toast_t - 2.4) * 1.5
		_text(hud, Vector2(W * 0.5 - 600, H * 0.27), toast_text, int(46 * pop), Color(1.0, 0.9, 0.5, a), HORIZONTAL_ALIGNMENT_CENTER, 1200)
	if hint_t > 0.0:
		var ha := clampf(hint_t, 0.0, 1.0)
		_text(hud, Vector2(W * 0.5 - 700, H - 120), "WASD koş     Boşluk zıpla     Shift kay     Silahlar kendi ateş eder", 26, Color(1, 1, 1, ha), HORIZONTAL_ALIGNMENT_CENTER, 1400)

func _draw_minimap(W: float) -> void:
	var c := Vector2(W - 128, 138)
	var R := 100.0
	var sc: float = R / main.world.ARENA_R
	hud.draw_circle(c, R + 6, Color(0.04, 0.07, 0.14, 0.62))
	hud.draw_arc(c, R + 2, 0, TAU, 56, Color(1, 1, 1, 0.55), 2.0)
	for s in main.world.shrines:
		if not s.done:
			var p: Vector2 = c + Vector2(s.pos.x, s.pos.z) * sc
			hud.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -7), p + Vector2(7, 0), p + Vector2(0, 7), p + Vector2(-7, 0)]), TEAL)
	for ch in main.world.chests:
		if not ch.open:
			var p2: Vector2 = c + Vector2(ch.pos.x, ch.pos.z) * sc
			hud.draw_rect(Rect2(p2 - Vector2(5, 5), Vector2(10, 10)), AMBER)
	for j in main.world.jars:
		if not j.taken:
			hud.draw_circle(c + Vector2(j.pos.x, j.pos.z) * sc, 3.5, Color(1.0, 0.45, 0.5))
	for it in main.pickups.items:
		hud.draw_circle(c + Vector2(it.pos.x, it.pos.z) * sc, 5.0, AMBER if it.kind == "chest" else (Color(1.0, 0.45, 0.5) if it.kind == "heal" else Color(0.3, 0.8, 1.0)))
	var en = main.enemies
	for i in en.count:
		if en.dead[i] == 0 and (en.elite[i] == 1 or en.typ[i] == en.T_BOSS):
			hud.draw_circle(c + Vector2(en.px[i], en.pz[i]) * sc, 8.0 if en.typ[i] == en.T_BOSS else 5.0, Color(1.0, 0.2, 0.2))
	var pp: Vector2 = c + Vector2(main.player.pos.x, main.player.pos.z) * sc
	var yaw: float = main.player.cam_yaw
	var f := Vector2(-sin(yaw), -cos(yaw))
	var rt := Vector2(-f.y, f.x)
	hud.draw_colored_polygon(PackedVector2Array([pp + f * 10.0, pp - f * 6.0 + rt * 6.5, pp - f * 6.0 - rt * 6.5]), Color.WHITE)
