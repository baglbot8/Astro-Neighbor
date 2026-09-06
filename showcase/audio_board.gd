extends Control
## Audio showcase board: plays every SFX and voice blip in sequence (SFX_GAP apart), then every music
## track for MUSIC_SECONDS, logging each name. Also exercises play_footstep, ducking and the day/night
## switch. Headless-safe (audio may be silent) — it proves every file listed in the audio spec loads.
## Run:  godot --path . res://showcase/audio_board.tscn -- --quit-at=55

const SFX_GAP := 0.4
const MUSIC_SECONDS := 3.0
const SFX_NAMES: PackedStringArray = [
	"footstep_grass_0", "footstep_grass_1", "footstep_stone_0", "footstep_stone_1", "footstep_metal_0", "footstep_metal_1",
	"jump", "land", "pickup", "collect_stardust", "place", "pickup_item", "rotate", "blocked",
	"ui_tick", "ui_confirm", "ui_cancel", "ui_open", "ui_close", "ui_buy", "toast",
	"quest_accept", "quest_complete", "friendship_up",
	"rocket_ignite", "rocket_loop", "rocket_land", "door_open", "door_close", "tree_shake", "splash",
	"emote_happy", "emote_wave", "dance_beat", "text_advance", "shooting_star",
]
const VOICE_PROFILES: PackedStringArray = ["astro", "alien", "robot", "elder", "kid"]
const MUSIC_TRACKS: PackedStringArray = ["title", "meadow_day", "meadow_night", "violet", "chrome", "hub", "space", "event"]
const CREAM := Color("#fff8e1")
const BROWN := Color("#6b5232")
const BLUE := Color("#4c6fff")
const YELLOW := Color("#ffcc33")
const BG_TOP := Color("#4fa8ff")
const BG_BOTTOM := Color("#bfe6ff")

var _items: Array[Dictionary] = []   # {"kind": "sfx"|"voice"|"music", "name": String}
var _index: int = -1
var _timer: float = 0.0
var _missing: PackedStringArray = []
var _done: bool = false
var _wave: PackedFloat32Array = []
var _current_label: String = ""

@onready var _title: Label = $Panel/Title
@onready var _now: Label = $Panel/Now
@onready var _list: RichTextLabel = $Panel/List
@onready var _wave_box: Control = $Panel/Wave
@onready var _status: Label = $Panel/Status


func _ready() -> void:
	for n in SFX_NAMES:
		_items.append({"kind": "sfx", "name": n})
	for p in VOICE_PROFILES:
		for i in 5:
			_items.append({"kind": "voice", "name": "voice_%s_%d" % [p, i]})
	for t in MUSIC_TRACKS:
		_items.append({"kind": "music", "name": t})
	_title.text = "Astro Neighbor — Audio Board"
	_status.text = "%d sfx · %d voice blips · %d music loops" % [SFX_NAMES.size(), VOICE_PROFILES.size() * 5, MUSIC_TRACKS.size()]
	_wave_box.draw.connect(_draw_wave)
	# preflight: every file the spec lists must exist
	for it in _items:
		var ok := AudioManager.music_exists(it["name"]) if it["kind"] == "music" else AudioManager.sfx_exists(it["name"])
		if not ok:
			_missing.append(it["name"])
	if _missing.is_empty():
		print("AUDIO_BOARD preflight: all %d files present" % _items.size())
	else:
		push_error("AUDIO_BOARD preflight: missing files: %s" % ", ".join(_missing))
	# phase + duck exercise (title starts when the sequence reaches music)
	AudioManager.play_footstep("grass")
	_timer = SFX_GAP


func _process(delta: float) -> void:
	if _done:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_index += 1
	if _index >= _items.size():
		_finish()
		return
	var it := _items[_index]
	var kind: String = it["kind"]
	var item_name: String = it["name"]
	_current_label = "%s: %s" % [kind, item_name]
	_now.text = _current_label
	print("AUDIO_BOARD play %s %s" % [kind, item_name])
	match kind:
		"sfx":
			AudioManager.play_sfx(item_name)
			_timer = SFX_GAP
			_load_wave(AudioManager.SFX_DIR + item_name + ".wav")
		"voice":
			AudioManager.play_voice_blip(item_name.trim_prefix("voice_").left(-2))
			_timer = SFX_GAP
			_load_wave(AudioManager.SFX_DIR + item_name + ".wav")
		"music":
			# meadow_night is reached through the phase switch so play_music_for_phase gets exercised too
			if item_name == "meadow_night":
				AudioManager.play_music_for_phase("meadow_day", "night", 0.5)
			elif item_name == "meadow_day":
				AudioManager.play_music_for_phase("meadow_day", "day", 0.5)
			else:
				AudioManager.play_music(item_name, 0.5)
			if AudioManager.current_track() != item_name:
				push_error("AUDIO_BOARD: expected track %s, got %s" % [item_name, AudioManager.current_track()])
			_timer = MUSIC_SECONDS
			_load_wave(AudioManager.MUSIC_DIR + item_name + ".wav")
			# duck exercise on the first music track
			if _index == _items.size() - MUSIC_TRACKS.size():
				EventBus.dialogue_started.emit("board")
				get_tree().create_timer(0.8).timeout.connect(_check_duck)
				get_tree().create_timer(1.5).timeout.connect(_end_dialogue)
	_refresh_list()
	_wave_box.queue_redraw()


func _check_duck() -> void:
	var duck := AudioManager.music_duck_db()
	print("AUDIO_BOARD duck while dialogue open: %.1f dB (expect %.1f)" % [duck, AudioManager.DUCK_DB])
	if not is_equal_approx(duck, AudioManager.DUCK_DB):
		push_error("AUDIO_BOARD: music duck not applied (%.1f dB)" % duck)


func _end_dialogue() -> void:
	EventBus.dialogue_finished.emit("board")


func _finish() -> void:
	_done = true
	AudioManager.play_music("", 1.0)
	_now.text = "done"
	var summary := "AUDIO_BOARD done: %d sfx, %d voices, %d music; missing=%d duck=%.1f dB" % [
		SFX_NAMES.size(), VOICE_PROFILES.size() * 5, MUSIC_TRACKS.size(), _missing.size(), AudioManager.music_duck_db()]
	print(summary)
	_status.text = summary


func _refresh_list() -> void:
	var lines: PackedStringArray = []
	var lo := maxi(0, _index - 8)
	var hi := mini(_items.size(), lo + 18)
	for i in range(lo, hi):
		var it := _items[i]
		var line: String = "%s  %s" % [it["kind"].rpad(5), it["name"]]
		if i == _index:
			lines.append("[color=#4c6fff][b]▶ %s[/b][/color]" % line)
		elif i < _index:
			lines.append("[color=#9a8a6a]✓ %s[/color]" % line)
		else:
			lines.append("[color=#6b5232]  %s[/color]" % line)
	_list.text = "\n".join(lines)


## Reads the source WAV's 16-bit PCM directly (the imported stream may be QOA-compressed) and keeps a
## min/max envelope per column for the waveform strip.
func _load_wave(path: String) -> void:
	_wave = PackedFloat32Array()
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var bytes := f.get_buffer(f.get_length())
	f.close()
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return
	var pos := 12
	var channels := 1
	var bits := 16
	var data_start := -1
	var data_size := 0
	while pos + 8 <= bytes.size():
		var cid := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var size := bytes.decode_u32(pos + 4)
		if cid == "fmt ":
			channels = bytes.decode_u16(pos + 10)
			bits = bytes.decode_u16(pos + 22)
		elif cid == "data":
			data_start = pos + 8
			data_size = size
			break
		pos += 8 + size + (size & 1)
	if data_start < 0 or bits != 16 or channels < 1:
		return
	@warning_ignore("integer_division")
	var frames: int = data_size / (2 * channels)
	if frames <= 0:
		return
	var columns := 240
	_wave.resize(columns * 2)
	for c in columns:
		var f0 := int(float(c) / columns * frames)
		var f1 := int(float(c + 1) / columns * frames)
		var step := maxi(1, int((f1 - f0) / 48.0))
		var lo := 0.0
		var hi := 0.0
		var fr := f0
		while fr < f1:
			var v := float(bytes.decode_s16(data_start + fr * channels * 2)) / 32768.0
			lo = minf(lo, v)
			hi = maxf(hi, v)
			fr += step
		_wave[c * 2] = lo
		_wave[c * 2 + 1] = hi


func _draw_wave() -> void:
	var r := _wave_box.get_rect()
	var size := r.size
	_wave_box.draw_rect(Rect2(Vector2.ZERO, size), Color("#efe0b5"))
	if _wave.is_empty():
		return
	var columns := _wave.size() / 2
	var mid := size.y * 0.5
	for c in columns:
		var x := (float(c) + 0.5) / columns * size.x
		var y0 := mid - _wave[c * 2 + 1] * mid * 0.92
		var y1 := mid - _wave[c * 2] * mid * 0.92
		_wave_box.draw_line(Vector2(x, y0), Vector2(x, maxf(y1, y0 + 1.0)), BLUE, 2.0)
	_wave_box.draw_line(Vector2(0, mid), Vector2(size.x, mid), Color(BROWN, 0.3), 1.0)


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), BG_TOP)
	var steps := 24
	for i in steps:
		var k := float(i) / steps
		var col := BG_TOP.lerp(BG_BOTTOM, k)
		draw_rect(Rect2(0, size.y * k, size.x, size.y / steps + 1.0), col)
