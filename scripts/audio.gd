extends Node
# Sound levels come from measurements of the files (tools/lufs.sh, tools/lufs_kisa.sh), not from guesses.
# The only sound that plays continuously is the music: there are no ambient loops, filters or ducking.

const MUSIC_TARGET := -14.0
# track -> measured integrated loudness (LUFS)
const MUSIC := {
	"menu": ["muzik_menu.mp3", -14.3],
	"oyun1": ["muzik_oyun1.mp3", -14.3],
	"oyun2": ["muzik_oyun2.mp3", -12.0],
	"gece": ["muzik_gece.mp3", -13.3],
	"boss": ["muzik_boss.mp3", -12.3],
}
# effect -> [measured loudness when looped back to back (LUFS), target loudness, minimum gap between plays (s)]
# Frequent effects sit 11 to 16 LU under the music, rare big ones 3 to 6 LU under it. Rendered together
# at the pace of a busy fight (tools/miks.py) they measure -20.2 LUFS, about 6 LU under the music, and
# -14.1 LUFS with every effect at its minimum gap: they are heard, the music still leads.
# The hit sits with the kill and the pickup, not far below them.
const SFX := {
	"hit": [-15.8, -25.0, 0.06],
	"kill": [-14.5, -25.0, 0.07],
	"gem": [-15.5, -26.0, 0.05],
	"shoot": [-21.4, -30.0, 0.08],
	"zap": [-17.0, -25.0, 0.1],
	"spit": [-15.8, -26.0, 0.1],
	"jump": [-13.8, -25.0, 0.05],
	"land": [-14.9, -25.0, 0.05],
	"slide": [-15.7, -23.0, 0.05],
	"hurt": [-12.2, -19.0, 0.1],
	"explosion": [-11.9, -22.0, 0.09],
	"click": [-30.6, -24.0, 0.03],
	"heal": [-15.7, -20.0, 0.1],
	"levelup": [-15.0, -18.0, 0.2],
	"chest": [-22.7, -18.0, 0.2],
	"shrine": [-19.3, -18.0, 0.2],
	"boss_roar": [-19.9, -18.0, 0.3],
	"boss_slam": [-16.6, -19.0, 0.1],
	"horn": [-9.9, -20.0, 0.5],
	"victory": [-15.4, -16.0, 1.0],
	"defeat": [-14.0, -17.0, 1.0],
}

var main
var streams := {}
var gains := {}
var last_play := {}
var pool: Array[AudioStreamPlayer] = []
var pool_i := 0
# Long, rare sounds get their own players: the busy short ones would otherwise cut them off within
# half a second of a fight.
const LONG := ["boss_roar", "boss_slam", "shrine", "heal", "horn", "chest", "levelup", "victory", "defeat"]
var long_pool: Array[AudioStreamPlayer] = []
var long_i := 0
# level of the outgoing track at the moment a new crossfade started
var out_from := 1.0
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var music_streams := {}
var current := ""
var fade := 1.0
var gain_a := 0.0
var gain_b := 0.0
var clock := 0.0

func setup(m) -> void:
	main = m
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	for k in SFX:
		var p := "res://assets/audio/%s.wav" % k
		if ResourceLoader.exists(p):
			streams[k] = load(p)
			gains[k] = SFX[k][1] - SFX[k][0]
	for k in MUSIC:
		var p2: String = "res://assets/audio/" + MUSIC[k][0]
		if ResourceLoader.exists(p2):
			var s = load(p2)
			s.loop = true
			music_streams[k] = s
	for i in 26:
		var pl := AudioStreamPlayer.new()
		pl.bus = "SFX"
		add_child(pl)
		if i < 20:
			pool.append(pl)
		else:
			long_pool.append(pl)
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	for mp in [music_a, music_b]:
		mp.bus = "Music"
		add_child(mp)
	apply_volumes()

func apply_volumes() -> void:
	var mi := AudioServer.get_bus_index("Music")
	var si := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(mi, linear_to_db(maxf(0.0001, main.settings.music)))
	AudioServer.set_bus_mute(mi, main.settings.music <= 0.001)
	AudioServer.set_bus_volume_db(si, linear_to_db(maxf(0.0001, main.settings.sfx)))
	AudioServer.set_bus_mute(si, main.settings.sfx <= 0.001)

func play(n: String, extra_db := 0.0, pitch := 1.0) -> void:
	if not streams.has(n):
		return
	var gap: float = SFX[n][2]
	if clock - float(last_play.get(n, -10.0)) < gap:
		return
	last_play[n] = clock
	var pl: AudioStreamPlayer
	if LONG.has(n):
		pl = long_pool[long_i]
		long_i = (long_i + 1) % long_pool.size()
	else:
		pl = pool[pool_i]
		pool_i = (pool_i + 1) % pool.size()
	pl.stream = streams[n]
	# extra_db can only make a sound quieter than its measured level, never louder
	pl.volume_db = gains[n] + minf(0.0, extra_db)
	pl.pitch_scale = pitch
	pl.play()

# Crossfade to another track. The old track keeps playing until the new one is up: no silent gap.
func music(n: String) -> void:
	if n == current or not music_streams.has(n):
		return
	current = n
	# a switch in the middle of a crossfade starts from the level the incoming track had reached
	out_from = sin(fade * PI * 0.5) if fade < 1.0 else 1.0
	music_b.stop()
	var t := music_a
	music_a = music_b
	music_b = t
	gain_b = gain_a
	gain_a = MUSIC_TARGET - float(MUSIC[n][1])
	music_a.stream = music_streams[n]
	music_a.volume_db = -60.0
	music_a.play()
	fade = 0.0

func _process(dt: float) -> void:
	clock += dt
	if fade < 1.0:
		fade = minf(1.0, fade + dt / 0.9)
		# equal-power crossfade
		music_a.volume_db = gain_a + linear_to_db(maxf(0.001, sin(fade * PI * 0.5)))
		if music_b.playing:
			music_b.volume_db = gain_b + linear_to_db(maxf(0.001, out_from * cos(fade * PI * 0.5)))
			if fade >= 1.0:
				music_b.stop()
	elif current != "" and not music_a.playing:
		# safety net: the music must never stay silent
		music_a.play()
