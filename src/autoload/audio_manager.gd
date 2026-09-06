extends Node
## Audio playback hub (AUDIO BUILDER). Public API (contract, keep stable):
##   play_sfx(name, volume_db, pitch_var)          2D / UI sound
##   play_sfx_at(name, world_pos, volume_db, ...)  positional 3D sound
##   play_footstep(surface)                        alternates footstep_<surface>_0/_1 ("grass" | "stone" | "metal")
##   play_music(track, fade)                       crossfade; "" fades out. Resolves _day/_night variants by phase.
##   play_music_for_phase(planet_track, phase)     explicit phase switch ("dawn" "day" "dusk" "night")
##   play_voice_blip(profile)                      animalese blip, profile in ["astro","alien","robot","elder","kid"]
##   start_loop(name, volume_db) / stop_loop(name) looping sfx (rocket_loop, dance_beat)
##   apply_settings() / set_bus_volume(bus, linear) / get_bus_volume(bus)   buses: Master, Music, SFX
## SFX live in res://assets/audio/sfx/<name>.wav ; music in res://assets/audio/music/<name>.wav|ogg
## Music ducks by -6 dB while a dialogue is open (EventBus.dialogue_started/finished or ui_modal "dialogue").
## Identical SFX are not retriggered within RETRIGGER_MS. Music WAVs are forced to LOOP_FORWARD at runtime.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const BUS_NAMES: PackedStringArray = ["Master", "Music", "SFX"]
const RETRIGGER_MS := 40
const DUCK_DB := -6.0
const DUCK_FADE := 0.25
const POOL_2D := 12
const POOL_3D := 8
const MUSIC_MIN_DB := -40.0
const PHASE_NIGHT := "night"
const NIGHT_SUFFIX := "_night"
const DAY_SUFFIX := "_day"
const FOOTSTEP_SURFACES: PackedStringArray = ["grass", "stone", "metal"]
const EXIT_FLUSH_MS := 260

var _music_player: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _current_track: String = ""      # the resolved file actually playing (e.g. "meadow_night")
var _planet_track: String = ""       # what gameplay asked for (e.g. "meadow_day"); re-resolved on phase change
var _phase: String = "day"
var _stream_cache: Dictionary = {}   # path -> AudioStream (or null when missing)
var _pool: Array[AudioStreamPlayer] = []
var _pool3d: Array[AudioStreamPlayer3D] = []
var _pool_started: Array[int] = []
var _pool3d_started: Array[int] = []
var _last_play_ms: Dictionary = {}   # sfx name -> msec of last trigger
var _loops: Dictionary = {}          # name -> AudioStreamPlayer
var _footstep_toggle: Dictionary = {}  # surface -> int
var _duck_db: float = 0.0
var _duck_tween: Tween
var _dialogue_active: bool = false
var _dialogue_modal: bool = false
var _music_tweens: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_music_player = _make_music_player()
	_music_player_b = _make_music_player()
	for i in POOL_2D:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
		_pool_started.append(0)
	for i in POOL_3D:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.max_distance = 40.0
		p3.unit_size = 4.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p3)
		_pool3d.append(p3)
		_pool3d_started.append(0)
	_phase = phase_for_hour(GameState.time_of_day)
	EventBus.day_phase_changed.connect(_on_day_phase_changed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.ui_modal_opened.connect(_on_modal_opened)
	EventBus.ui_modal_closed.connect(_on_modal_closed)
	apply_settings()


func _exit_tree() -> void:
	# Quit hygiene: stop every playback, then let the audio thread run a couple of mix steps so the
	# AudioServer releases its playback objects. Otherwise a sound still playing at quit is reported as
	# "resources still in use at exit" (the dummy/headless driver mixes only every ~90 ms).
	for p in _pool:
		p.stop()
	for p3 in _pool3d:
		p3.stop()
	for k in _loops:
		(_loops[k] as AudioStreamPlayer).stop()
	_music_player.stop()
	_music_player_b.stop()
	OS.delay_msec(EXIT_FLUSH_MS)


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.finished.connect(_on_music_finished.bind(p))
	add_child(p)
	return p

# ----------------------------------------------------------------------------- buses / settings

func _ensure_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


## Names of the buses this manager guarantees exist (Master, Music, SFX).
func bus_names() -> PackedStringArray:
	return BUS_NAMES


func _settings_key(bus: String) -> String:
	return bus.to_lower() + "_volume"


## Linear volume (0..1) stored in GameState.settings for a bus.
func get_bus_volume(bus: String) -> float:
	return clampf(float(GameState.settings.get(_settings_key(bus), 1.0 if bus != "Music" else 0.8)), 0.0, 1.0)


## Set a bus volume (linear 0..1); persists to GameState.settings and applies immediately.
func set_bus_volume(bus: String, linear: float) -> void:
	GameState.settings[_settings_key(bus)] = clampf(linear, 0.0, 1.0)
	apply_settings()


## Re-read GameState.settings and push volumes to the buses (music also gets the dialogue duck).
func apply_settings() -> void:
	for bus_name in BUS_NAMES:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		var lin := get_bus_volume(bus_name)
		var vol_db := linear_to_db(maxf(lin, 0.0001))
		if bus_name == "Music":
			vol_db += _duck_db
		AudioServer.set_bus_volume_db(idx, vol_db)
		AudioServer.set_bus_mute(idx, lin <= 0.0)

# ----------------------------------------------------------------------------- loading

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_stream_cache[path] = s
	return s


func _sfx_path(sfx_name: String) -> String:
	var path := SFX_DIR + sfx_name + ".wav"
	if not ResourceLoader.exists(path):
		path = SFX_DIR + sfx_name + ".ogg"
	return path


func _music_path(track: String) -> String:
	var path := MUSIC_DIR + track + ".ogg"
	if not ResourceLoader.exists(path):
		path = MUSIC_DIR + track + ".wav"
	return path


func _load_sfx(sfx_name: String) -> AudioStream:
	var s := _load_stream(_sfx_path(sfx_name))
	if s == null:
		push_warning("AudioManager: missing sfx '%s'" % sfx_name)
	return s


## True if an sfx file with this name exists.
func sfx_exists(sfx_name: String) -> bool:
	return ResourceLoader.exists(_sfx_path(sfx_name))


## True if a music track file with this name exists.
func music_exists(track: String) -> bool:
	return ResourceLoader.exists(_music_path(track))


## Force forward looping on a stream (imported WAVs default to no loop unless the file carries a loop chunk).
func _force_loop(s: AudioStream) -> void:
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		if w.loop_mode == AudioStreamWAV.LOOP_DISABLED or w.loop_end <= 0:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = _wav_frames(w)
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	elif s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true


func _wav_frames(w: AudioStreamWAV) -> int:
	var bytes_per_sample := 2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1
	if w.format != AudioStreamWAV.FORMAT_16_BITS and w.format != AudioStreamWAV.FORMAT_8_BITS:
		return 0
	var channels := 2 if w.stereo else 1
	@warning_ignore("integer_division")
	return w.data.size() / (bytes_per_sample * channels)

# ----------------------------------------------------------------------------- sfx

func _retrigger_blocked(sfx_name: String) -> bool:
	var now := Time.get_ticks_msec()
	var last: int = int(_last_play_ms.get(sfx_name, -RETRIGGER_MS - 1))
	if now - last < RETRIGGER_MS:
		return true
	_last_play_ms[sfx_name] = now
	return false


func _free_2d() -> int:
	var oldest := 0
	for i in _pool.size():
		if not _pool[i].playing:
			return i
		if _pool_started[i] < _pool_started[oldest]:
			oldest = i
	return oldest


func _free_3d() -> int:
	var oldest := 0
	for i in _pool3d.size():
		if not _pool3d[i].playing:
			return i
		if _pool3d_started[i] < _pool3d_started[oldest]:
			oldest = i
	return oldest


## Play a 2D (UI / player) sound. pitch_var adds random pitch variation so repeats don't sound robotic.
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_var: float = 0.06) -> void:
	if _retrigger_blocked(sfx_name):
		return
	var s := _load_sfx(sfx_name)
	if s == null:
		return
	var i := _free_2d()
	var p := _pool[i]
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()
	_pool_started[i] = Time.get_ticks_msec()


## Play a positional sound in the 3D world.
func play_sfx_at(sfx_name: String, world_pos: Vector3, volume_db: float = 0.0, pitch_var: float = 0.06) -> void:
	if _retrigger_blocked(sfx_name):
		return
	var s := _load_sfx(sfx_name)
	if s == null:
		return
	var i := _free_3d()
	var p := _pool3d[i]
	p.stream = s
	p.global_position = world_pos
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()
	_pool3d_started[i] = Time.get_ticks_msec()


## Footstep helper: alternates the _0/_1 variants of footstep_<surface>. Unknown surfaces fall back to grass.
## Pass a world position to make it positional (Vector3.INF = 2D).
func play_footstep(surface: String, world_pos: Vector3 = Vector3.INF, volume_db: float = -4.0) -> void:
	var surf := surface if surface in FOOTSTEP_SURFACES else "grass"
	var idx: int = int(_footstep_toggle.get(surf, 0))
	_footstep_toggle[surf] = 1 - idx
	var sfx_name := "footstep_%s_%d" % [surf, idx]
	if world_pos == Vector3.INF:
		play_sfx(sfx_name, volume_db + randf_range(-1.5, 0.0), 0.08)
	else:
		play_sfx_at(sfx_name, world_pos, volume_db + randf_range(-1.5, 0.0), 0.08)


## Short "animalese" style blip for dialogue typewriter. Files: voice_<profile>_N.wav (N = 0..4).
func play_voice_blip(profile: String) -> void:
	var n := randi_range(0, 4)
	var sfx_name := "voice_%s_%d" % [profile, n]
	if not sfx_exists(sfx_name):
		sfx_name = "voice_astro_%d" % n
	play_sfx(sfx_name, -6.0, 0.12)


## Start (or retune) a looping sfx such as "rocket_loop". Returns the player so callers can move/stop it.
func start_loop(sfx_name: String, volume_db: float = 0.0, fade: float = 0.15) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = _loops.get(sfx_name)
	if p == null:
		var s := _load_sfx(sfx_name)
		if s == null:
			return null
		_force_loop(s)
		p = AudioStreamPlayer.new()
		p.bus = "SFX"
		p.stream = s
		add_child(p)
		_loops[sfx_name] = p
	if not p.playing:
		p.volume_db = MUSIC_MIN_DB
		p.play()
	var t := create_tween()
	t.tween_property(p, "volume_db", volume_db, fade)
	return p


## Fade out and stop a looping sfx started with start_loop.
func stop_loop(sfx_name: String, fade: float = 0.4) -> void:
	var p: AudioStreamPlayer = _loops.get(sfx_name)
	if p == null or not p.playing:
		return
	var t := create_tween()
	t.tween_property(p, "volume_db", MUSIC_MIN_DB, fade)
	t.tween_callback(p.stop)

# ----------------------------------------------------------------------------- music

## Day phase for an hour (0..24): dawn 5-7, day 7-18, dusk 18-20, night otherwise.
func phase_for_hour(hour: float) -> String:
	if hour >= 5.0 and hour < 7.0:
		return "dawn"
	if hour >= 7.0 and hour < 18.0:
		return "day"
	if hour >= 18.0 and hour < 20.0:
		return "dusk"
	return PHASE_NIGHT


func _base_track(track: String) -> String:
	if track.ends_with(NIGHT_SUFFIX):
		return track.substr(0, track.length() - NIGHT_SUFFIX.length())
	if track.ends_with(DAY_SUFFIX):
		return track.substr(0, track.length() - DAY_SUFFIX.length())
	return track


## Map a planet track to the file for a phase: "<base>_night" at night when it exists, else "<base>_day" /
## "<base>". Tracks without variants are returned unchanged.
func resolve_track_for_phase(track: String, phase: String) -> String:
	if track == "":
		return ""
	var base := _base_track(track)
	if phase == PHASE_NIGHT and music_exists(base + NIGHT_SUFFIX):
		return base + NIGHT_SUFFIX
	if music_exists(base + DAY_SUFFIX):
		return base + DAY_SUFFIX
	if music_exists(base):
		return base
	return track


## Crossfade to a music track (planet track name such as "meadow_day"; the night variant is chosen
## automatically while the phase is night). Pass "" to fade out.
func play_music(track: String, fade: float = 1.5) -> void:
	_planet_track = track
	_crossfade_to(resolve_track_for_phase(track, _phase), fade)


## Switch a planet track to the given phase explicitly (also remembers the phase for later changes).
func play_music_for_phase(planet_track: String, phase: String, fade: float = 2.5) -> void:
	_phase = phase
	_planet_track = planet_track
	_crossfade_to(resolve_track_for_phase(planet_track, phase), fade)


## Name of the music file currently playing ("" when silent).
func current_track() -> String:
	return _current_track


func _crossfade_to(track: String, fade: float) -> void:
	if track == _current_track:
		return
	_current_track = track
	for t in _music_tweens:
		if t.is_valid():
			t.kill()
	_music_tweens.clear()
	var incoming := _music_player_b if _music_player.playing else _music_player
	var outgoing := _music_player if incoming == _music_player_b else _music_player_b
	if incoming.playing and outgoing.playing:
		# both busy (rapid double switch): abort the one still fading in (the quieter) and reuse it
		incoming = _music_player if _music_player.volume_db < _music_player_b.volume_db else _music_player_b
		outgoing = _music_player_b if incoming == _music_player else _music_player
		incoming.stop()
	if track != "":
		var s := _load_stream(_music_path(track))
		if s == null:
			push_warning("AudioManager: missing music '%s'" % track)
		else:
			_force_loop(s)
			incoming.stream = s
			incoming.volume_db = MUSIC_MIN_DB
			incoming.play()
			var t := create_tween()
			t.tween_property(incoming, "volume_db", 0.0, maxf(fade, 0.01)).set_trans(Tween.TRANS_SINE)
			_music_tweens.append(t)
	if outgoing.playing:
		var t2 := create_tween()
		t2.tween_property(outgoing, "volume_db", MUSIC_MIN_DB, maxf(fade, 0.01)).set_trans(Tween.TRANS_SINE)
		t2.tween_callback(outgoing.stop)
		_music_tweens.append(t2)


func _on_music_finished(p: AudioStreamPlayer) -> void:
	# Only reached when a stream could not loop (e.g. an un-loopable format): restart to keep music going.
	if _current_track != "" and p.stream != null and p.volume_db > MUSIC_MIN_DB + 1.0:
		p.play()


func _on_day_phase_changed(phase: String) -> void:
	_phase = phase
	if _planet_track == "":
		return
	var want := resolve_track_for_phase(_planet_track, phase)
	if want != _current_track:
		_crossfade_to(want, 2.5)

# ----------------------------------------------------------------------------- ducking

func _on_dialogue_started(_speaker: String) -> void:
	_dialogue_active = true
	_update_duck()


func _on_dialogue_finished(_speaker: String) -> void:
	_dialogue_active = false
	_update_duck()


func _on_modal_opened(modal_name: String) -> void:
	if modal_name == "dialogue":
		_dialogue_modal = true
		_update_duck()


func _on_modal_closed(modal_name: String) -> void:
	if modal_name == "dialogue":
		_dialogue_modal = false
		_update_duck()


func _update_duck() -> void:
	var target := DUCK_DB if (_dialogue_active or _dialogue_modal) else 0.0
	if is_equal_approx(target, _duck_db):
		return
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(_set_duck_db, _duck_db, target, DUCK_FADE)


func _set_duck_db(v: float) -> void:
	_duck_db = v
	apply_settings()


## Current music duck in dB (0 = not ducked, -6 while a dialogue is open).
func music_duck_db() -> float:
	return _duck_db
