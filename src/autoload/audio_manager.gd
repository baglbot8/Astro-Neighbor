extends Node
## Audio playback hub (AUDIO BUILDER). Public API (contract, keep stable):
##   play_sfx(name, volume_db, pitch_var)          2D / UI sound
##   play_sfx_at(name, world_pos, volume_db, ...)  positional 3D sound
##   play_footstep(surface)                        alternates footstep_<surface>_0/_1 ("grass" | "stone" | "metal")
##   play_music(track, fade)                       crossfade; "" fades out. Resolves _day/_night variants by phase.
##   play_music_for_phase(planet_track, phase)     explicit phase switch ("dawn" "day" "dusk" "night")
##   comms_open_line / comms_reveal / comms_close_line   Zorp: voiced as a radio TRANSMISSION, one
##                                                 gesture per phrase, never per letter. Every other
##                                                 speaker: a shared neutral "doot" every ~2 revealed
##                                                 letters, no framing (see DOOT_* below, 2026-09-10)
##   play_voice_blip(profile)                      compatibility wrapper: Zorp's gesture, or a doot
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


# ----------------------------------------------------------------------------- comms voices
## COMMS VOICES. Every neighbour lives on another planet, so every line they say is a radio
## TRANSMISSION. This replaced a random pitched blip every 2-3 letters (13-20 a second) - a per-letter
## babble that read as an Animal Crossing copy, which the user asked us to lose. Now, per line:
##
##   comms_open_line(voice, line, closes_turn)  key-up (relay click + ~90 ms static burst) and a faint
##                                              static bed under the open line
##   comms_reveal(visible_chars)                call every frame while the line types. ONE voiced
##                                              gesture per PHRASE (words up to , . ! ? ; : or a dash),
##                                              never per letter; the phrase's punctuation picks the
##                                              gesture: ? rises, ! is brighter, ... trails off
##   comms_close_line(cut)                      typing finished (cut = false: the last gesture plays out,
##                                              then a squelch - or the roger "over" beep when the line
##                                              closes the speaker's turn) or skipped (cut = true: the
##                                              voice is cut and the squelch plays now, like letting go
##                                              of the talk button)
##   comms_hold(paused)                         the pause menu opened over a line: bed off / back on
##   comms_voice_for(profile, speaker, line_i)  neighbour id ("zorp"), legacy profile ("elder") or "";
##                                              a duo speaker ("Pip & Pop") alternates per line
##   play_voice_blip(profile)                   COMPATIBILITY: one short gesture, no framing
##
## THE FRAME IS A CONTRACT: every voiced line gets exactly one key-up and exactly one squelch/over.
## If the next line keys up while the previous line's squelch is still owed (its last gesture was
## sounding), the gesture is cut, the squelch plays at once and the key-up follows COMMS_FLUSH_GAP
## later. The rate is a contract too: gestures hold 1-2 syllables >= ~150 ms apart and are separated
## by COMMS_PHRASE_GAP, so no voice runs at more than half the old blip rate (measured on the demos).
##
## Ten voices, one per neighbour (COMMS_VOICES; NpcData.voice_profile holds the id). Files, all mono
## 22.05 kHz and built by tools/gen/audio/voices.py: voice_<id>_{short,long,ask,exclaim,trail}.wav,
## comms_key_up_{0,1}, comms_key_down_{0,1}, comms_over, comms_bed (loop). Every file went through the
## same 300-3400 Hz channel (synth.comms_chain), which is what makes ten sources one universe.
## voices.schedule_line() MIRRORS the scheduler below for the listening demos: change both together.
const COMMS_VOICES: PackedStringArray = ["zorp", "bolt", "pip", "pop", "stella", "mayor_orbit", "dj_nova",
	"fen", "grig", "vela"]
## Old profile names still passed as literals by some callers (hub buildings). "astro" means NO
## transmission: narration, the mailbox, the bulletin board and the player's own thoughts are not
## somebody on the radio, so they type in silence.
const LEGACY_VOICES := {"alien": "zorp", "robot": "bolt", "elder": "mayor_orbit", "kid": "pip", "astro": ""}
## The first gesture waits this long after the key-up so it does not land on the static burst.
const COMMS_KEYUP_LEAD := 0.11
## When a line is keyed up while the previous line's squelch is still waiting (the player advanced
## while its last gesture was sounding), that squelch is played NOW and the new key-up waits this long:
## the squelch's hiss has closed by 0.12-0.14 s (voices.comms_key_down), so the two never smear into
## one noise burst. Every line keeps both ends of its frame.
const COMMS_FLUSH_GAP := 0.13
## A phrase of <= 12 letters gets the "short" statement gesture, longer ones "long". The median phrase
## in npc_data.gd is 13 letters (0.33 s at 40 cps); the 90th percentile is 32.
const COMMS_SHORT_PHRASE := 12
## A phrase with more letters than this gets ONE extra gesture at its middle word break (~10 % do).
const COMMS_SPLIT_PHRASE := 30
## Silence between one phrase gesture and the next. Round 1 ran them LEGATO (30 ms overlap), and
## chained legato a 3-syllable gesture after a 3-syllable gesture measured as many onsets a second as
## the per-letter blips it replaced. An 80 ms breath between phrases is what makes each one a phrase.
const COMMS_PHRASE_GAP := 0.08
const COMMS_TAIL_GAP := 0.03
## Pitch: +3 % on a comma phrase ("go on..."), a +3 % -> -3 % drift across the line (declination, how
## speech sinks as it goes), and +-2.5 % jitter so no two gestures are identical.
const COMMS_GO_PITCH := 0.03
const COMMS_DECLINATION := 0.03
const COMMS_JITTER := 0.025
## Levels, set against two measured neighbours. Each gesture file is normalised to -15 LUFS
## (K-weighted, so Pip at 1.4 kHz is not louder than Fen at 0.5 kHz), so at -5 dB a gesture sits near
## -20 LUFS. On the ten two-line demos that measured -19.2 LUFS momentary max against -14.8 for the old
## blip stream (4.4 dB quieter), and the music under a conversation is -22.7 to -27.4 LUFS (bus 0.8,
## ducked -6 dB): the voice stays readable above it without being the loudest thing in the room. A
## first pass at -11 dB sat at -25 LUFS, UNDER the ducked music.
const COMMS_VOICE_DB := -5.0
const COMMS_RADIO_DB := -7.0
const COMMS_BED_DB := -26.0
const COMMS_BED_FADE_IN := 0.06
const COMMS_BED_FADE_OUT := 0.12
## A skipped line cuts its voice with this fade (a hard stop would click).
const COMMS_CUT_FADE := 0.035
const COMMS_SILENT_DB := -60.0
const COMMS_PUNCT := ".!?,;:—…"

## DOOT (shipped 2026-09-10). The user, after listening to the comms voices on her phone: "I only like
## Zorp's new voice better than the animalese / original robot sounds. The only thing I can think of is
## making generic doot doot doot noises as the letters are being written out and then we dont have
## unique voices for each." Zorp keeps his comms voice above, UNCHANGED (comms_voice_for still resolves
## everyone else to their old id - bolt/pip/pop/stella/mayor_orbit/dj_nova/fen/grig/vela - it just no
## longer means a unique voice). Everyone else gets ONE shared, neutral, non-vocal tone instead, as its
## letters type: no per-neighbour timbre, no radio click/static framing. Built by
## tools/gen/audio/voices.py's DOOT section (doot_names() / render_doot(), flavour "a" - 4 pitch
## variants, +-3 %, so it never machine-guns one sample).
const DOOT_FILES: PackedStringArray = ["doot_a_0", "doot_a_1", "doot_a_2", "doot_a_3"]
## One doot at most every this many REVEALED LETTERS (spaces and punctuation never count) - the user
## described only "doot doot doot", nothing per letter and nothing per space/punctuation mark.
const DOOT_LETTERS_PER_TICK := 2
const DOOT_DB := -9.0    # doot_a_*.wav is already RMS-levelled well under the old voice_robot files
## Non-Zorp lines get NO radio key-up/key-down framing by default - the user's phone review asked only
## for plain doots, nothing else, for everyone but Zorp. Kept as ONE const, default OFF, in case a
## later round decides doot lines should open/close like a transmission after all.
const DOOT_FRAMING_ENABLED := false

## Debug: print every comms event ("COMMS <t> <what> <file> ps=<pitch>"). A Director timeline can set
## it: {"set": {"node": "/root/AudioManager", "property": "comms_log", "value": true}}.
var comms_log := false
## Event counters for tests: key_up / phrase / key_down / over / cut.
var comms_counts := {"key_up": 0, "phrase": 0, "key_down": 0, "over": 0, "cut": 0, "doot": 0}
var _comms_voice_players: Array[AudioStreamPlayer] = []
var _comms_voice_next := 0
var _comms_radio_players: Array[AudioStreamPlayer] = []
var _comms_radio_next := 0
var _comms_bed: AudioStreamPlayer
var _comms_bed_tween: Tween
var _comms_open := false
var _comms_voice := ""
var _comms_closes_turn := false
var _comms_phrases: Array = []
var _comms_next := 0
## Due phrases waiting for the voice, oldest first. At most two: the line's FIRST phrase (protected -
## "Oh!", "Ahoy?", "YO!" are the most expressive part of a line and round 1 dropped them) and the
## newest due phrase (protected - it carries the ? ! ... contour). Middle phrases are the ones dropped.
var _comms_queue: Array[int] = []
var _comms_free_at := 0.0
## A line finished typing and its squelch is queued behind its last gesture. If the next line keys
## up first, comms_open_line plays that squelch immediately instead of losing it.
var _comms_kd_pending := false
var _comms_kd_closes := false
var _comms_key_toggle := 0
var _comms_clock := 0.0
## Bumped whenever a line is aborted, so a timer queued for the old line (its last gesture, its
## squelch) finds a stale token and does nothing.
var _comms_gen := 0

## Which path the currently-open line is using: "zorp" (full comms scheduler below), "doot" (plain
## tone every DOOT_LETTERS_PER_TICK letters), or "" (nothing open / a silent line).
var _voice_mode := ""
var _doot_line := ""
var _doot_letters_seen := 0
var _doot_letter_accum := 0
var _doot_last_variant := -1
var _doot_closes_turn := false

## Resolves who is talking to a comms voice id, or "" for no transmission. Order: an id already; the
## speaker's name ("Mayor Orbit (radio)" -> mayor_orbit), because hub buildings pass legacy literals
## ("alien" for the Cosmo Depot twins); then the legacy map.
## DUO SPEAKERS ("Pip & Pop"): the two take turns, line by line, first-named first - `line_index` picks
## which. The Cosmo Depot greeting is written that way ("...I'm Pip..." / "...and I'm Pop!"), and
## round 1 resolved the whole box to Pip, so Pop's own line came out in Pip's voice.
func comms_voice_for(profile: String, speaker: String = "", line_index: int = 0) -> String:
	if profile in COMMS_VOICES:
		return profile
	var who := speaker.strip_edges()
	var paren := who.find(" (")
	if paren > 0:
		who = who.substr(0, paren)
	var amp := who.find(" & ")
	if amp > 0:
		var pair := [who.substr(0, amp), who.substr(amp + 3)]
		var first := _comms_voice_by_name(pair[0])
		var second := _comms_voice_by_name(pair[1])
		if first != "" and second != "":
			return first if line_index % 2 == 0 else second
		if first != "":
			return first
	var by_name := _comms_voice_by_name(who)
	if by_name != "":
		return by_name
	return str(LEGACY_VOICES.get(profile, ""))


func _comms_voice_by_name(speaker: String) -> String:
	var who := speaker.strip_edges()
	if who == "":
		return ""
	for id: String in NpcData.ids():
		var d := NpcData.get_data(id)
		if str(d.get("display_name", "")).to_lower() == who.to_lower():
			var v := str(d.get("voice_profile", ""))
			return v if v in COMMS_VOICES else ""
	return ""


## True when the gesture files for a comms voice exist.
func comms_voice_exists(voice: String) -> bool:
	return voice != "" and sfx_exists("voice_%s_short" % voice)


## Opens a line. voice == "zorp" -> the full comms scheduler (key-up, gestures, key-down/over -
## unchanged). Any other non-empty voice -> the doot path (no framing, see DOOT_FRAMING_ENABLED): a
## plain tone plays roughly every DOOT_LETTERS_PER_TICK letters as comms_reveal() is called. voice ==
## "" (or a blank line) types in silence either way.
func comms_open_line(voice: String, line: String, closes_turn: bool = false) -> void:
	if voice == "zorp":
		_zorp_open_line(voice, line, closes_turn)
		return
	if _voice_mode == "zorp":
		_zorp_close_line(true)          # re-keyed from a zorp line straight into a doot line
	_voice_mode = "doot" if (voice != "" and line.strip_edges() != "") else ""
	_doot_line = line
	_doot_letters_seen = 0
	_doot_letter_accum = 0
	_doot_last_variant = -1
	_doot_closes_turn = closes_turn
	if _voice_mode == "doot" and DOOT_FRAMING_ENABLED:
		_comms_key_toggle = 1 - _comms_key_toggle
		_comms_radio("comms_key_up_%d" % _comms_key_toggle, "key_up")


func _zorp_open_line(voice: String, line: String, closes_turn: bool = false) -> void:
	_voice_mode = "zorp"
	var lead := 0.0
	if _comms_open:
		# Re-keyed while the last line was still typing (the box normally closes it first): that is
		# letting go of the talk button - cut and squelch now.
		comms_close_line(true)
		lead = COMMS_FLUSH_GAP
	elif _comms_kd_pending:
		# The player advanced while the last line's final gesture was still sounding. Round 1 dropped
		# that line's squelch here (and a 30 ms-late one could land in the NEW line and turn its bed
		# off). Now: cut the gesture, play the owed squelch NOW, key up after it.
		_comms_cut_voice()
		_comms_kd_pending = false
		_comms_key_down(_comms_kd_closes)
		lead = COMMS_FLUSH_GAP
	elif _comms_voice_busy():
		_comms_cut_voice()          # a stray play_voice_blip() gesture: nothing to close
	# ALWAYS: every timer still queued for an older line (a gesture, a squelch) is now stale.
	_comms_gen += 1
	_comms_queue.clear()
	_comms_voice = voice
	if not comms_voice_exists(voice) or line.strip_edges() == "":
		return
	_comms_open = true
	_comms_closes_turn = closes_turn
	_comms_phrases = comms_parse(line)
	_comms_next = 0
	_comms_free_at = _comms_now() + lead + COMMS_KEYUP_LEAD
	_comms_key_toggle = 1 - _comms_key_toggle
	var key_up := "comms_key_up_%d" % _comms_key_toggle
	if lead <= 0.0:
		_comms_radio(key_up, "key_up")
		_comms_bed_on()
		return
	var gen := _comms_gen
	_comms_after(lead, func() -> void:
		if gen == _comms_gen and _comms_open:
			_comms_radio(key_up, "key_up")
			_comms_bed_on())


## Called every frame while the line types, with how many characters are visible.
func comms_reveal(visible_chars: int) -> void:
	if _voice_mode == "zorp":
		_zorp_reveal(visible_chars)
	elif _voice_mode == "doot":
		_doot_reveal(visible_chars)


## A phrase becomes due on the frame its first letter shows; a due gesture plays as soon as the voice
## is free. When the voice is busy, due phrases queue - but only the FIRST phrase and the NEWEST one
## are kept: a newer due phrase replaces a waiting MIDDLE phrase, never the opener ("Oh!") and never
## itself losing to an older one, so the line's ? ! ... contour always sounds.
func _zorp_reveal(visible_chars: int) -> void:
	if not _comms_open:
		return
	while _comms_next < _comms_phrases.size() and int(_comms_phrases[_comms_next]["start"]) < visible_chars:
		_comms_enqueue(_comms_next)
		_comms_next += 1
	if not _comms_queue.is_empty() and _comms_now() >= _comms_free_at:
		_comms_play_phrase(_comms_queue.pop_front())


## Doot path: one neutral tone every DOOT_LETTERS_PER_TICK LETTERS revealed so far (alnum only -
## spaces and punctuation never advance the count), counted against the line text passed to
## comms_open_line. No queueing, no framing: a doot is a single one-shot fired as it comes due.
func _doot_reveal(visible_chars: int) -> void:
	var upto: int = mini(visible_chars, _doot_line.length())
	var letters := 0
	for i in upto:
		if _is_letter(_doot_line[i]):
			letters += 1
	var new_letters: int = letters - _doot_letters_seen
	_doot_letters_seen = letters
	if new_letters <= 0:
		return
	_doot_letter_accum += new_letters
	while _doot_letter_accum >= DOOT_LETTERS_PER_TICK:
		_doot_letter_accum -= DOOT_LETTERS_PER_TICK
		_play_doot()


static func _is_letter(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")


func _play_doot() -> void:
	if DOOT_FILES.is_empty():
		return
	var idx := randi() % DOOT_FILES.size()
	if DOOT_FILES.size() > 1:
		while idx == _doot_last_variant:
			idx = randi() % DOOT_FILES.size()
	_doot_last_variant = idx
	var s := _load_sfx(DOOT_FILES[idx])
	if s == null:
		return
	if _comms_voice_players.is_empty():
		for i in 2:
			_comms_voice_players.append(_comms_player())
	var p := _comms_voice_players[_comms_voice_next]
	_comms_voice_next = (_comms_voice_next + 1) % _comms_voice_players.size()
	p.stream = s
	p.pitch_scale = 1.0
	p.volume_db = DOOT_DB
	p.play()
	_comms_count("doot", DOOT_FILES[idx])


func _comms_enqueue(k: int) -> void:
	if not _comms_queue.is_empty() and _comms_queue[-1] != 0:
		_comms_queue[-1] = k        # replace a waiting middle phrase
	else:
		_comms_queue.append(k)


## Closes the line, whichever path opened it.
func comms_close_line(cut: bool = false) -> void:
	if _voice_mode == "zorp":
		_zorp_close_line(cut)
	elif _voice_mode == "doot":
		_doot_close_line()


## Skip / mid-line close / pause must never leave a doot stuck: a doot is a single short one-shot (no
## bed, no queue), so closing just stops any that happens to still be playing and clears the mode.
func _doot_close_line() -> void:
	_voice_mode = ""
	for p in _comms_voice_players:
		if p.playing:
			p.stop()
	if DOOT_FRAMING_ENABLED:
		_comms_key_down(_doot_closes_turn)


## cut = false: typing finished, so phrases still waiting for the voice play first (at most two - see
## comms_reveal) and the squelch / "over" follows the last gesture. cut = true: the player skipped -
## the voice stops now (35 ms fade) and the squelch plays immediately.
func _zorp_close_line(cut: bool = false) -> void:
	if not _comms_open:
		return
	_comms_open = false
	var now := _comms_now()
	if cut:
		_comms_queue.clear()
		_comms_count("cut")
		_comms_cut_voice()
		_comms_key_down(_comms_closes_turn)
		return
	var gen := _comms_gen
	var at := maxf(now, _comms_free_at)
	for k: int in _comms_queue:
		var p: Dictionary = _comms_phrases[k]
		var file := _comms_file(p)
		var ps := _comms_pitch(p, k, _comms_phrases.size())
		_comms_after(at - now, func() -> void:
			if gen == _comms_gen:
				_comms_voice_play(file, ps))
		var s := _load_sfx(file)
		if s != null:
			at += s.get_length() / ps + COMMS_PHRASE_GAP
	_comms_queue.clear()
	# `at` / _comms_free_at is the end of the last gesture PLUS the phrase gap; the squelch follows the
	# gesture's end by COMMS_TAIL_GAP instead.
	var voice_end := at - COMMS_PHRASE_GAP
	_comms_kd_pending = true
	_comms_kd_closes = _comms_closes_turn
	_comms_after(maxf(now, voice_end) + COMMS_TAIL_GAP - now, func() -> void:
		if gen == _comms_gen and _comms_kd_pending:
			_comms_kd_pending = false
			_comms_key_down(_comms_kd_closes))


## The pause menu opened (true) or closed (false) over the dialogue box. The gesture and radio
## players are PROCESS_MODE_PAUSABLE and the scheduler's clock and timers stop with the tree (see
## _comms_player / _comms_now / _comms_after), so a gesture in flight freezes and resumes; this only
## has to take the static bed down and bring it back if the line (or its owed squelch) is still live.
func comms_hold(paused: bool) -> void:
	if paused:
		_comms_bed_off()
	elif _comms_open or _comms_kd_pending:
		_comms_bed_on()


## COMPATIBILITY WRAPPER for the old per-letter blip API. Dialogue no longer calls it: it plays ONE
## short sound (no key-up, no squelch) for a neighbour id or a legacy profile, which keeps
## showcase/audio_board.gd and any old caller working without bringing the babble back. "astro" -
## silent in dialogue - maps to Stella here, the one neighbour who used it. Zorp -> his comms gesture,
## unchanged; every other neighbour -> a doot (their comms gesture files no longer ship).
func play_voice_blip(profile: String) -> void:
	var v := comms_voice_for(profile)
	if v == "" and profile == "astro":
		v = "stella"
	if v == "zorp":
		_comms_voice_play("voice_zorp_short", 1.0 + randf_range(-COMMS_JITTER, COMMS_JITTER))
	elif v != "":
		_play_doot()


## Splits a line into phrases: [{start, end, letters, kind}]. `start` is the character index of the
## phrase's first character, which is when the typewriter reveals it. kind: ask (?), exclaim (!),
## trail (... or …), go (, ; : —), say (. or nothing). A punctuation run ends a phrase only when a space
## or the end of the line follows it, and only once the phrase has a letter - so "4,182" stays one
## word and "...and that's our shop!" is not a trailing phrase. A phrase with more than
## COMMS_SPLIT_PHRASE letters is split once at the word break nearest its middle.
static func comms_parse(line: String) -> Array:
	var out: Array = []
	var n := line.length()
	var i := 0
	while i < n:
		while i < n and _comms_space(line[i]):
			i += 1
		if i >= n:
			break
		var start := i
		var letters := 0
		var closed := false
		while i < n:
			var c := line[i]
			if COMMS_PUNCT.contains(c) and letters > 0:
				var j := i
				while j < n and COMMS_PUNCT.contains(line[j]):
					j += 1
				if j >= n or _comms_space(line[j]):
					out.append({"start": start, "end": j, "letters": letters, "kind": _comms_kind(line.substr(i, j - i))})
					i = j
					closed = true
					break
				i = j
				continue
			if _comms_alnum(c):
				letters += 1
			i += 1
		if not closed and letters > 0:
			out.append({"start": start, "end": n, "letters": letters, "kind": "say"})
	var split: Array = []
	for p: Dictionary in out:
		if int(p["letters"]) > COMMS_SPLIT_PHRASE:
			var s0 := int(p["start"])
			var s1 := int(p["end"])
			@warning_ignore("integer_division")
			var mid := (s0 + s1) / 2
			var best := -1
			for k in range(s0 + 1, s1 - 1):
				if line[k] == " " and (best < 0 or absi(k - mid) < absi(best - mid)):
					best = k
			if best >= 0:
				var cut := best + 1
				var first := 0
				for ci in range(s0, cut):
					if _comms_alnum(line[ci]):
						first += 1
				split.append({"start": s0, "end": cut, "letters": first, "kind": "go"})
				split.append({"start": cut, "end": s1, "letters": int(p["letters"]) - first, "kind": p["kind"]})
				continue
		split.append(p)
	return split


static func _comms_kind(run: String) -> String:
	if run.contains("?"):
		return "ask"
	if run.contains("!"):
		return "exclaim"
	if run.ends_with("...") or run.contains("…"):
		return "trail"
	for ch in [",", ";", ":", "—"]:
		if run.contains(ch):
			return "go"
	return "say"


static func _comms_space(c: String) -> bool:
	return c == " " or c == "\n" or c == "\t"


static func _comms_alnum(c: String) -> bool:
	return c.to_lower() != c.to_upper() or c.is_valid_int()


## The comms scheduler's clock: GAME time, summed from process delta - not Time.get_ticks. The
## typewriter and the SceneTreeTimers in _comms_after() both run on game time, and in a --write-movie
## capture the audio is mixed per frame, so wall-clock ticks ran ~5x ahead of what was audible and
## gestures piled on top of each other. In normal play the two clocks are the same. It STOPS while the
## tree is paused (this node is PROCESS_MODE_ALWAYS, so it has to check): the typewriter and the comms
## players freeze under the pause menu, and a clock that kept running would come back with every
## gesture "overdue" and fire them on top of the one resuming.
func _comms_now() -> float:
	return _comms_clock


func _process(delta: float) -> void:
	if not get_tree().paused:
		_comms_clock += delta


func _comms_file(p: Dictionary) -> String:
	var kind := str(p["kind"])
	if kind == "ask" or kind == "exclaim" or kind == "trail":
		return "voice_%s_%s" % [_comms_voice, kind]
	return "voice_%s_%s" % [_comms_voice, "short" if int(p["letters"]) <= COMMS_SHORT_PHRASE else "long"]


func _comms_pitch(p: Dictionary, k: int, count: int) -> float:
	var decl := 0.0
	if count > 1:
		decl = COMMS_DECLINATION * (1.0 - 2.0 * float(k) / float(maxi(1, count - 1)))
	var go := COMMS_GO_PITCH if str(p["kind"]) == "go" else 0.0
	return 1.0 + decl + go + randf_range(-COMMS_JITTER, COMMS_JITTER)


func _comms_play_phrase(k: int) -> void:
	var p: Dictionary = _comms_phrases[k]
	var file := _comms_file(p)
	var ps := _comms_pitch(p, k, _comms_phrases.size())
	var s := _comms_voice_play(file, ps)
	if s != null:
		_comms_free_at = _comms_now() + s.get_length() / ps + COMMS_PHRASE_GAP


func _comms_voice_play(file: String, ps: float) -> AudioStream:
	var s := _load_sfx(file)
	if s == null:
		return null
	if _comms_voice_players.is_empty():
		for i in 2:
			_comms_voice_players.append(_comms_player())
	var p := _comms_voice_players[_comms_voice_next]
	_comms_voice_next = (_comms_voice_next + 1) % _comms_voice_players.size()
	p.stream = s
	p.pitch_scale = ps
	p.volume_db = COMMS_VOICE_DB
	p.play()
	_comms_count("phrase", file, ps)
	return s


func _comms_voice_busy() -> bool:
	for p in _comms_voice_players:
		if p.playing:
			return true
	return false


func _comms_radio(file: String, what: String) -> void:
	var s := _load_sfx(file)
	if s == null:
		return
	if _comms_radio_players.is_empty():
		for i in 2:
			_comms_radio_players.append(_comms_player())
	var p := _comms_radio_players[_comms_radio_next]
	_comms_radio_next = (_comms_radio_next + 1) % _comms_radio_players.size()
	p.stream = s
	p.pitch_scale = 1.0
	p.volume_db = COMMS_RADIO_DB
	p.play()
	_comms_count(what, file)


func _comms_key_down(closes_turn: bool) -> void:
	_comms_key_toggle = 1 - _comms_key_toggle
	if closes_turn:
		_comms_radio("comms_over", "over")
	else:
		_comms_radio("comms_key_down_%d" % _comms_key_toggle, "key_down")
	_comms_bed_off()


func _comms_cut_voice() -> void:
	for p in _comms_voice_players:
		if p.playing:
			var t := create_tween()
			t.tween_property(p, "volume_db", COMMS_SILENT_DB, COMMS_CUT_FADE)
			t.tween_callback(p.stop)


func _comms_bed_on() -> void:
	if _comms_bed == null:
		var s := _load_sfx("comms_bed")
		if s == null:
			return
		_force_loop(s)
		_comms_bed = _comms_player(false)
		_comms_bed.stream = s
	if _comms_bed_tween != null and _comms_bed_tween.is_valid():
		_comms_bed_tween.kill()
	if not _comms_bed.playing:
		_comms_bed.volume_db = COMMS_SILENT_DB
		_comms_bed.play()
	_comms_bed_tween = create_tween()
	_comms_bed_tween.tween_property(_comms_bed, "volume_db", COMMS_BED_DB, COMMS_BED_FADE_IN)


func _comms_bed_off() -> void:
	if _comms_bed == null or not _comms_bed.playing:
		return
	if _comms_bed_tween != null and _comms_bed_tween.is_valid():
		_comms_bed_tween.kill()
	_comms_bed_tween = create_tween()
	_comms_bed_tween.tween_property(_comms_bed, "volume_db", COMMS_SILENT_DB, COMMS_BED_FADE_OUT)
	_comms_bed_tween.tween_callback(_comms_bed.stop)


## Comms players stop themselves as the tree exits (children exit before this node's _exit_tree), so
## the quit flush in _exit_tree covers them and nothing is "still in use at exit". Gesture and radio
## players are PROCESS_MODE_PAUSABLE (AudioManager itself is ALWAYS and children inherit that): round 1
## kept a gesture in flight playing under the pause menu. A pausable AudioStreamPlayer pauses its
## stream with the tree and resumes it after. The bed stays ALWAYS - comms_hold fades it itself.
func _comms_player(pausable: bool = true) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	if pausable:
		p.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(p)
	p.tree_exiting.connect(p.stop)
	return p


## Runs `fn` after `delay` seconds of game time (the same clock as _comms_now). The timer does NOT
## run while the tree is paused (process_always = false), like the clock and the players: a squelch
## owed by a line waits under the pause menu and plays when it closes, instead of firing into a paused
## player. Cancelled by _comms_gen, not by keeping the timer.
func _comms_after(delay: float, fn: Callable) -> void:
	if delay <= 0.0005:
		fn.call()
		return
	get_tree().create_timer(delay, false, false, false).timeout.connect(fn)


## Debug (Director timelines): prints the comms players' state and the event counters, so a test can
## prove e.g. that a gesture in flight is frozen under the pause menu (position not advancing).
func comms_debug_dump(tag: String = "") -> void:
	var rows: PackedStringArray = []
	for p: AudioStreamPlayer in _comms_voice_players + _comms_radio_players:
		if p.stream != null and (p.playing or p.stream_paused):
			rows.append("%s playing=%s paused=%s pos=%.3f" % [p.stream.resource_path.get_file(), p.playing,
				p.stream_paused, p.get_playback_position()])
	print("COMMS_STATE %.3f %s paused_tree=%s kd_pending=%s open=%s counts=%s [%s]" % [_comms_now(), tag,
		get_tree().paused, _comms_kd_pending, _comms_open, comms_counts, "; ".join(rows)])


func _comms_count(what: String, file: String = "", ps: float = 1.0) -> void:
	comms_counts[what] = int(comms_counts.get(what, 0)) + 1
	if comms_log:
		print("COMMS %.3f %s %s ps=%.3f" % [_comms_now(), what, file, ps])


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
