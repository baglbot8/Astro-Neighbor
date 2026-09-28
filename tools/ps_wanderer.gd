extends Node
## PS WANDERER - THE DENSITY GATE'S TEST PLAYER (docs/PLANET_SAFARI_SPEC.md 11.2 and 11.2b; builder R4,
## 2026-09-24/25).
##
## The user's rules, in their words: "if nothing shows up in 20 seconds of wandering, then it's not
## frequent enough", and "make sure things that you'd take photos of arent way too common or too rare."
## This node plays one planet safari as a WANDERER and reports, per run, both halves of the BAND (11.2b):
##   NOT TOO RARE    longest_gap: the longest stretch with NOTHING photographable on screen.
##                   Gate: 20 s or less in at least 90% of runs, never over 30 s.
##   NOT TOO COMMON  median_between: the median time between NEW ENCOUNTERS - a subject coming on screen
##                   photographable (the test below); the same subject id counts again only after
##                   REENCOUNTER_OFF_SEC (10 s) off screen. Gate: 8-15 s.
##                   share_3plus: the share of frames with three or more DIFFERENT subjects on screen at
##                   once. Gate: 10% or less.
## Every encounter is listed ([t, id, where, seconds it had been off screen or -1 the first time]).
##
## HOW TO RUN (it is an autoload that does nothing unless `--ps-wander` is passed). In a scratch copy,
## put this in `override.cfg` at the project root (the pattern earlier probes used; never in the real
## project folder), then:
##
##     [autoload]
##     PSWanderer="*res://tools/ps_wanderer.gd"
##
##     godot --headless --path <copy> --fixed-fps 60 --quit-after 20000 \
##         res://src/world/world.tscn -- --planet=<id> --no-autosave --ps-wander --ps-seed=7 \
##         [--ps-night] [--safari-rare | --safari-common] [--ps-out=/abs/file.jsonl] \
##         [--ps-frame=WxH] [--ps-trace] [--ps-trace-start] [--ps-perf] [--ps-min-size=F]
##         [--ps-gaze=mixed|level|ground|deck|high] [--ps-layout] [--ps-shots=<dir>]
##
## ANY PLANET (SYS, 2026-09-25): nothing below names a planet; --ps-layout lists the planet's host (its
## MANIFEST's, PlanetSafari.manifest) instead of Bolt, and RESULT carries "planet".
## It prints one line `[PSW] RESULT {json}` and quits: longest_gap, where and when it began, every gap
## of 10 s or more, encounters, median_between, share_3plus and `band` (each gate true/false), the share
## of frames with something on screen, seconds on screen per subject, and `dists` (each subject's distance, sampled every 0.5 s while photographable - the
## "usual distance" bolt.gd's size bands are set from). `--fixed-fps 60` makes a run deterministic and
## lets a headless run go faster than real time (every frame is 1/60 s of game time; ~10 s a run).
##   --ps-frame  the judged frame. A headless viewport is 1280x1280, so the root is sized to 1280x720 (16:9,
##               the desktop, narrower than the phone and so the stricter); --ps-frame=2556x1179 gives
##               the phone's aspect (the project's stretch makes it a 1560x720 viewport).
##   --ps-trace  prints, every 0.5 s through the longest gap, where it was, its pitch and glance, and
##               why each awake subject was not photographable (behind / off / hidden / small / edge).
##   --ps-trace-start  the same rows for the first 20 s too.
##   --ps-min-size=F   judge "big enough to recognise" at F instead of MIN_SIZE_FRAC (a sensitivity run).
##   --ps-gaze=G       the gaze (see GAZES): mixed (the DEFAULT since round 3, the critic's), level,
##                     ground, deck (round 2's), high (round 1's -12..+4), for comparison.
##   --ps-layout       prints every prop's place (degrees round, bearing) and quits.
##   --ps-shots=<dir>  a WINDOWED run stands at the start and saves the view at pitch 0/-12/-20/-28/-36.
##   --ps-perf   for a WINDOWED run on the phone renderer (--rendering-method gl_compatibility
##               --always-on-top --position 100,100 before the --): per-frame real ms and draw calls in
##               the RESULT, and a LONG FRAME line (what was on screen) for every frame over 50 ms.
##               Another agent's always-on-top window over this one stops it drawing: the draw calls
##               then freeze at one value - check for that before trusting a run.
## A herd (nut-crabs, gear-beetles, spring-hoppers, spark-moths) is ONE subject (one id, so crabs in
## three places are one subject met again, not three) whose node sits on the
## member the world script picks (worlds/bolt.gd `_pick_focus`: the most central one in view that the
## lens can see); that one member is what a photo would score, so it is what is judged here.
##
## THE WANDERER (all of it stated, so it can be argued with):
##   * Starts the safari directly (PlanetSafari.request_start - the talk with Bolt is skipped).
##   * Walks at the safari walk (the stick fully pushed; Player caps it at SAFARI_WALK_SPEED 1.5 m/s).
##   * Picks a NEW RANDOM HEADING every 5-15 s (uniform), turning to it over about a second. The new
##     heading is uniform over all 360 degrees.
##   * LOOKS AROUND LIKE A PERSON while it walks: the view's yaw drifts to a new glance every 1.5-4 s,
##     an offset from the walking heading drawn from a normal of sd 35 degrees (clamped to +-90); the
##     view's pitch is drawn per glance from the GAZE (see GAZES; default "mixed": 55% at the deck,
##     30% near the horizon, 15% up). (Round 2's "deck" gaze: mostly the deck ahead (-28..-8 degrees),
##     one glance in six up at the sky (+10..+35), the next glance or a new heading bringing the eyes
##     back to the ground.) WHY THE DECK MATTERS: on a 10.5 m planet the horizon from the eye (1.09 m up) is
##     acos(10.5 / 11.59) = 25 degrees below level, lower than the lens's half-height (22.5): at pitch 0
##     the deck is not in the picture at all, only the sky and what stands above the horizon; -12 shows
##     a sliver of deck, -20 its far half, -28 the ground a few metres ahead (frames saved with
##     --ps-shots on the phone renderer, 2026-09-25). Round 1 of this tool used -12..+4 and so hardly
##     ever looked at the deck, where the creatures are. (Round 1 also let sky glances chain; a trace
##     of its worst run showed it staring at the empty sky for 18 s, which is not how a person looks
##     round.) The stick keeps it
##     walking along its heading while it glances (it is pushed diagonally when the view is turned).
##   * Now and then (one heading change in five) it STOPS for 2-4 s and pans slowly round, the way a
##     person stops to look about.
##   * Turned by a wall: if it has made under 0.5 m/s for 1 s while walking, it picks a new heading.
##   * NEVER reads a warning, never raises the camera, never zooms (45 degrees), never reacts to what
##     it sees, and never hops.
##
## SIGHTS AND BONUS SUBJECTS DO NOT COUNT (spec 15.5, SafariWorld.counts_for_pacing): a sight is always
## there and a bonus subject is a hidden collector's page, so neither closes a gap, makes an encounter or
## crowds the screen. They are left out of every number below (and show as "uncounted" in --ps-trace).
##
## "PHOTOGRAPHABLE ON SCREEN" is decided by the safari's own scorer (SafariPhotoScorer.score_subject),
## run every frame on every awake subject with the real view camera and the real physics: the subject
## is in front of the lens, at least half of its on-screen box is inside the frame (the scorer's
## inside fraction >= MIN_INSIDE), at least one of its five sight rays reaches it (the scorer's own
## occlusion check: hidden by the planet or a prop = not there), and it is BIG ENOUGH TO RECOGNISE:
## its projected diameter is at least MIN_SIZE_FRAC of the frame height (the scorer's size_frac).
##
## SAY WHAT IS SYNTHETIC: the stick is Input.action_press (no InputEvent is sent), the look is
## CameraRig.add_look (the touch front end's own entry point, not a finger), the safari starts without
## the talk, day or night is forced before the start with Environment.set_time (the dev menu's own
## call). The run is usually headless: nothing is drawn, so "on screen" is the camera's projection maths
## and physics rays, not pixels, and lighting (night) is not judged.

## Big enough to recognise: the subject's projected diameter as a fraction of the frame height. 1/20:
## 36 px on a 720 px desktop frame, 59 px on the phone's 1179 px. A stated pick, not fitted. (On Bolt's
## 10.5 m planet it hardly binds: a spring-hopper is 1/20 of the frame at 10.6 m, past the horizon.)
const MIN_SIZE_FRAC := 0.05
var _min_size := MIN_SIZE_FRAC
## At least half of it inside the frame.
const MIN_INSIDE := 0.5
const HEADING_SEC := Vector2(5.0, 15.0)
const GLANCE_SEC := Vector2(1.5, 4.0)
const GLANCE_SD_DEG := 35.0
const GLANCE_MAX_DEG := 90.0
const PITCH_GROUND := Vector2(-28.0, -8.0)
var _pitch_ground := PITCH_GROUND
const PITCH_SKY := Vector2(10.0, 35.0)
## THE GAZE (R4 round 3). Which way "a person looks round" on this small world decides the gate more
## than anything on the planet does, and the critic (2026-09-25) showed the gate held only for a gaze
## that kept to the deck - the gaze this tool had been retuned to in the same round the planet was
## tuned against it. So the DEFAULT is now the critic's own MIXED gaze, and the others stay for
## comparison. Each is a mixture of pitch ranges, one drawn per glance: [share, from, to] in degrees.
##   mixed  55% at the deck (-30..-10), 30% near the horizon (-10..+5), 15% up (+5..+30); mean about -9
##   level  35% / 45% / 20% of the same three ranges; mean about -4
##   ground 80% at the deck, 20% at -10..+10 (the critic's "ground"); mean about -16
##   deck   this tool's round-2 gaze: -28..-8, one glance in six at the sky (+10..+35), never two running
##   high   round 1: -12..+4 (as deck, with that range)
const GAZES := {
	"mixed": [[0.55, -30.0, -10.0], [0.30, -10.0, 5.0], [0.15, 5.0, 30.0]],
	"level": [[0.35, -30.0, -10.0], [0.45, -10.0, 5.0], [0.20, 5.0, 30.0]],
	"ground": [[0.8, -30.0, -10.0], [0.2, -10.0, 10.0]],
}
var _gaze := "mixed"
const SKY_ONE_IN := 6
const STOP_ONE_IN := 5
const STOP_SEC := Vector2(2.0, 4.0)
## Turn rates of the view (degrees a second): a person's look, not a snap.
const YAW_RATE := 110.0
const PITCH_RATE := 60.0
const STUCK_SPEED := 0.5
const STUCK_SEC := 1.0

var _on := false
var _seed := 1
var _night := false
var _out := ""
## The frame the view is judged in. A headless run has no real window (its viewport is 1280x1280), so
## the root viewport is sized to this: 16:9 desktop by default (narrower than the phone's 2556x1179,
## so the stricter of the two); `--ps-frame=2556x1179` for the phone.
var _frame := Vector2i(1280, 720)
var _rng := RandomNumberGenerator.new()
var _s: PlanetSafari

var _heading := Vector3.FORWARD
var _prev_up := Vector3.UP
var _next_heading := 0.0
var _glance := 0.0
var _glance_target := 0.0
var _next_glance := 0.0
var _pitch_target := -6.0
var _stop_until := -1.0
var _sky_last := false
var _pan_dir := 1.0
var _slow_for := 0.0

var _last_seen_t := 0.0
var _gap_start_pos := Vector3.ZERO
var _longest := 0.0
var _longest_at := 0.0
var _longest_where := ""
var _gaps: Array = []          # every gap >= 10 s: [start, length, where]
var _seen_sec: Dictionary = {}  # subject id -> seconds on screen
var _first_seen: Dictionary = {}
var _frames := 0
var _frames_seen := 0
var _headings := 0
var _stuck := 0
var _path_m := 0.0
var _last_pos := Vector3.ZERO
var _done := false
var _yaw_err_sum := 0.0
var _pitch_err_sum := 0.0
var _pitch_sum := 0.0
## Distance to each subject while it is photographable, sampled every 0.5 s (its "usual distance").
var _dists: Dictionary = {}
var _dist_clock := 0.0
## --ps-perf: per-frame real milliseconds and draw calls (a windowed run on a real renderer).
var _perf := false
## --ps-trace: every 0.5 s, where it is, where it looks, and why each awake subject is or is not
## photographable (behind / off the frame / hidden / too small / OK); printed for the longest gap.
var _trace := false
var _trace_rows: Array = []
var _trace_clock := 0.0
var _perf_rows: Array = []     # [t, ms, draw_calls]
var _last_us := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_on = args.has("--ps-wander")
	if not _on:
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_night = args.has("--ps-night")
	_perf = args.has("--ps-perf")
	_trace = args.has("--ps-trace")
	for a in args:
		if a.begins_with("--ps-seed="):
			_seed = int(a.substr(10))
		elif a.begins_with("--ps-out="):
			_out = a.substr(9)
		elif a.begins_with("--ps-min-size="):
			_min_size = float(a.substr(14))
		elif a == "--ps-gaze=high":
			_gaze = "deck"
			_pitch_ground = Vector2(-12.0, 4.0)
		elif a.begins_with("--ps-gaze="):
			_gaze = a.substr(10)
			assert(_gaze == "deck" or GAZES.has(_gaze), "unknown --ps-gaze")
		elif a.begins_with("--ps-shots="):
			_shots_dir = a.substr(11)
		elif a.begins_with("--ps-frame="):
			var wh := a.substr(11).split("x")
			_frame = Vector2i(int(wh[0]), int(wh[1]))
	_rng.seed = hash("ps_wanderer:%d" % _seed)
	_start.call_deferred()


func _log(m: String) -> void:
	print("[PSW] " + m)


## One glance's pitch from the gaze's mixture (see GAZES).
func _mixture_pitch() -> float:
	var r := _rng.randf()
	var acc := 0.0
	for g: Array in GAZES[_gaze]:
		acc += float(g[0])
		if r <= acc:
			return _rng.randf_range(float(g[1]), float(g[2]))
	var last: Array = GAZES[_gaze][-1]
	return _rng.randf_range(float(last[1]), float(last[2]))


func _start() -> void:
	# Let the world finish loading, then set the hour and start the safari as Bolt's "yes" would.
	for i in 30:
		await get_tree().process_frame
	get_tree().root.size = _frame
	# The dev menu's way (dev_menu.gd _set_time): the Environment owns the clock.
	var hour := 22.0 if _night else 10.0
	var env := get_tree().root.get_node_or_null("World/Environment")
	if env != null and env.has_method("set_time"):
		env.call("set_time", hour)
	GameState.time_of_day = hour
	PlanetSafari.request_start(get_tree())
	var waited := 0
	while waited < 7200:
		var s := PlanetSafari.current
		if s != null and s.phase == PlanetSafari.Phase.AWAKE:
			_s = s
			break
		await get_tree().process_frame
		waited += 1
	if _s == null:
		var c := PlanetSafari.current
		_log("NO SAFARI after %d frames: current=%s phase=%s modal=%s" % [waited, str(c),
			str(c.phase) if c != null else "-", str(EventBus.is_modal_open())])
		get_tree().quit(2)
		return
	if OS.get_cmdline_user_args().has("--ps-layout"):
		# where everything is, as (degrees round from the start, bearing), then quit
		for c in _s.planet.get_node("Props").get_children():
			_log("LAYOUT prop %s %s" % [c.name, _where((c as Node3D).global_position)])
		var host_id := str(PlanetSafari.manifest(_s.planet_id).get("host", ""))
		var host := get_tree().root.get_node_or_null("World/NPCs/" + host_id) as Node3D if host_id != "" else null
		if host != null:
			_log("LAYOUT %s %s" % [host_id, _where(host.global_position)])
		_log("LAYOUT pad %s" % _where(_s.planet.surface_point(_s.planet.data.pad_dir)))
		get_tree().quit()
		return
	_heading = _s.start_fwd
	_prev_up = _s.planet.up_at(_s.player.global_position)
	_last_pos = _s.player.global_position
	_gap_start_pos = _last_pos
	_next_heading = _rng.randf_range(HEADING_SEC.x, HEADING_SEC.y)
	_log("awake planet=%s seed=%d night=%s rare=%s frame=%s renderer=%s" % [_s.planet_id, _seed, str(_s.is_night), str(_s.is_rare_day),
		str(get_viewport().get_visible_rect().size), RenderingServer.get_current_rendering_method()])


func _process(delta: float) -> void:
	if _s == null or _done or not is_instance_valid(_s):
		return
	if _s.phase != PlanetSafari.Phase.AWAKE:
		if _s.elapsed > 1.0:
			_finish()
		return
	var t := _s.elapsed
	var pl := _s.player
	if _shots_dir != "":
		_shots(t)
		return
	var up := _s.planet.up_at(pl.global_position)
	# carry the heading along the sphere (parallel transport), then flatten it onto the ground
	if _prev_up.dot(up) < 0.999999:
		_heading = Quaternion(_prev_up, up) * _heading
	_prev_up = up
	_heading = (_heading - up * _heading.dot(up)).normalized()
	_path_m += pl.global_position.distance_to(_last_pos)
	_last_pos = pl.global_position

	var stopped := t < _stop_until
	# ---- a new heading
	if t >= _next_heading:
		_headings += 1
		_heading = _heading.rotated(up, _rng.randf_range(-PI, PI)).normalized()
		_next_heading = t + _rng.randf_range(HEADING_SEC.x, HEADING_SEC.y)
		_glance_target = 0.0
		_next_glance = t + _rng.randf_range(GLANCE_SEC.x, GLANCE_SEC.y)
		# a new way to walk: eyes back on the ground ahead (the deck gaze; a mixture gaze keeps its pitch)
		if _gaze == "deck":
			_pitch_target = _rng.randf_range(_pitch_ground.x, _pitch_ground.y)
		_sky_last = false
		if _rng.randi_range(1, STOP_ONE_IN) == 1:
			_stop_until = t + 1.0 + _rng.randf_range(STOP_SEC.x, STOP_SEC.y)
			_pan_dir = 1.0 if _rng.randf() < 0.5 else -1.0
	# ---- glances
	if t >= _next_glance:
		_next_glance = t + _rng.randf_range(GLANCE_SEC.x, GLANCE_SEC.y)
		_glance_target = clampf(_rng.randfn(0.0, GLANCE_SD_DEG), -GLANCE_MAX_DEG, GLANCE_MAX_DEG)
		if _gaze != "deck":
			_pitch_target = _mixture_pitch()
		elif not _sky_last and _rng.randi_range(1, SKY_ONE_IN) == 1:
			_pitch_target = _rng.randf_range(PITCH_SKY.x, PITCH_SKY.y)
			_sky_last = true
		else:
			_pitch_target = _rng.randf_range(_pitch_ground.x, _pitch_ground.y)
			_sky_last = false
	if stopped:
		# a slow pan round while standing (about 25 degrees a second)
		_glance_target = wrapf(_glance + _pan_dir * 25.0 * delta, -180.0, 180.0)
	_glance = move_toward(_glance, _glance_target, YAW_RATE * delta) if not stopped else _glance_target
	# ---- steer the view (closed loop, so the look sensitivity setting does not matter)
	var cam := _s.rig.get_view_camera()
	var cam_fwd := -cam.global_transform.basis.z
	cam_fwd = (cam_fwd - up * cam_fwd.dot(up)).normalized()
	var want := _heading.rotated(up, -deg_to_rad(_glance)).normalized()
	var yaw_err := rad_to_deg(cam_fwd.signed_angle_to(want, up))
	_yaw_err_sum += absf(yaw_err)
	_pitch_err_sum += absf(_pitch_target - _s.rig.get_view_pitch_deg())
	_pitch_sum += _s.rig.get_view_pitch_deg()
	var yaw_step := clampf(-yaw_err, -YAW_RATE * delta * 2.0, YAW_RATE * delta * 2.0)
	var pitch_now := _s.rig.get_view_pitch_deg()
	var pitch_step := clampf(_pitch_target - pitch_now, -PITCH_RATE * delta, PITCH_RATE * delta)
	_look(Vector2(yaw_step, pitch_step))
	# ---- walk along the heading (the stick relative to the view)
	var move := Vector2.ZERO
	if not stopped:
		var right := cam_fwd.cross(up).normalized()
		move = Vector2(_heading.dot(right), -_heading.dot(cam_fwd))
		if move.length() > 0.001:
			move = move.normalized()
	_stick(move)
	var speed := pl.get_tangent_velocity().length()
	if not stopped and t > 1.0:
		_slow_for = (_slow_for + delta) if speed < STUCK_SPEED else 0.0
		if _slow_for >= STUCK_SEC:
			_slow_for = 0.0
			_stuck += 1
			_next_heading = t   # a wall: pick a new way next frame
	# ---- what is on screen
	_frames += 1
	if _perf:
		var now := Time.get_ticks_usec()
		if _last_us > 0:
			var ms := (now - _last_us) / 1000.0
			_perf_rows.append([snappedf(t, 0.01), ms,
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
			if ms > 50.0:
				_log("LONG FRAME %.0f ms t=%.2f at %s pitch %.0f | %s" % [ms, t, _where(pl.global_position),
					_s.rig.get_view_pitch_deg(), _why(cam, t)])
		_last_us = now
	_dist_clock -= delta
	var sample_dist := _dist_clock <= 0.0
	if sample_dist:
		_dist_clock = 0.5
	var seen := _visible_now(cam, t, sample_dist)
	if _trace:
		_trace_clock -= delta
		if _trace_clock <= 0.0:
			_trace_clock = 0.5
			_trace_rows.append([snappedf(t, 0.1), _where(pl.global_position), snappedf(_s.rig.get_view_pitch_deg(), 1.0),
				snappedf(_glance, 1.0), stopped, _why(cam, t)])
	# ---- the band's "not too common" half (spec 11.2b): encounters and crowding
	if seen.size() >= 3:
		_frames_3plus += 1
	for id: String in seen:
		var off := t - float(_last_on.get(id, -INF))
		if off >= REENCOUNTER_OFF_SEC:
			_encounters.append([snappedf(t, 0.01), id, _where(pl.global_position), snappedf(off, 0.1) if off < 1e6 else -1.0])
		_last_on[id] = t
	if not seen.is_empty():
		_frames_seen += 1
		for id: String in seen:
			_seen_sec[id] = float(_seen_sec.get(id, 0.0)) + delta
			if not _first_seen.has(id):
				_first_seen[id] = snappedf(t, 0.1)
		_close_gap(t)
		_last_seen_t = t
		_gap_start_pos = pl.global_position
	else:
		var g := t - _last_seen_t
		if g > _longest:
			_longest = g
			_longest_at = _last_seen_t
			_longest_where = _where(_gap_start_pos)


var _open_gap_logged := false
## --ps-shots=<dir>: a WINDOWED run stands at the start and saves the view at a few pitches (to judge
## what a pitch shows on this small planet), then quits.
var _shots_dir := ""
var _shot_i := -1
var _shot_wait := 0
const SHOT_PITCHES := [0.0, -12.0, -20.0, -28.0, -36.0]


func _shots(t: float) -> void:
	_stick(Vector2.ZERO)
	if t < 3.0:
		return
	if _shot_i < 0:
		_shot_i = 0
		_shot_wait = 20
	var want: float = SHOT_PITCHES[_shot_i]
	var now := _s.rig.get_view_pitch_deg()
	_look(Vector2(0.0, clampf(want - now, -30.0, 30.0)))
	_shot_wait -= 1
	if _shot_wait > 0:
		return
	var img := get_viewport().get_texture().get_image()
	var path := _shots_dir.path_join("pitch_%d.png" % int(want))
	img.save_png(path)
	_log("SHOT %s pitch %.1f size %s" % [path, _s.rig.get_view_pitch_deg(), str(img.get_size())])
	_shot_i += 1
	_shot_wait = 20
	if _shot_i >= SHOT_PITCHES.size():
		_done = true
		get_tree().quit()
## The band's second half: every ENCOUNTER as [t, id] (a subject coming on screen photographable; the
## same id counts again only after REENCOUNTER_OFF_SEC off screen), when each id was last on screen,
## and the frames with three or more different subjects on screen at once.
const REENCOUNTER_OFF_SEC := 10.0
var _encounters: Array = []
var _last_on: Dictionary = {}
var _frames_3plus := 0


## Median of a list of floats (0 when empty).
static func _median(xs: Array) -> float:
	if xs.is_empty():
		return 0.0
	var s := xs.duplicate()
	s.sort()
	var n := s.size()
	return float(s[n / 2]) if n % 2 == 1 else 0.5 * (float(s[n / 2 - 1]) + float(s[n / 2]))


func _close_gap(t: float) -> void:
	var g := t - _last_seen_t
	if g >= 10.0:
		_gaps.append([snappedf(_last_seen_t, 0.1), snappedf(g, 0.1), _where(_gap_start_pos)])


## [ids] of every awake subject that is photographable right now (see the header).
func _visible_now(cam: Camera3D, t: float, sample_dist: bool) -> Array:
	var frame := get_viewport().get_visible_rect().size
	var space := _s._space()
	var excl := _s._exclude()
	var out: Array = []
	for sj: Dictionary in _s.awake_subjects():
		if not SafariWorld.counts_for_pacing(sj):
			continue   # a sight or a bonus subject (spec 15.5)
		var e := SafariPhotoScorer.score_subject(cam, frame, sj, _s.focus_m, space, excl, t)
		if e.is_empty():
			continue
		if float(e["size_frac"]) < _min_size or float(e["inside_frac"]) < MIN_INSIDE:
			continue
		var id := str(sj.get("id", ""))
		out.append(id)
		if sample_dist:
			if not _dists.has(id):
				_dists[id] = []
			(_dists[id] as Array).append(snappedf(float(e["dist"]), 0.01))
	return out


## For --ps-trace: each awake subject's state, "id:reason@dist".
func _why(cam: Camera3D, t: float) -> String:
	var frame := get_viewport().get_visible_rect().size
	var out: PackedStringArray = []
	for sj: Dictionary in _s.awake_subjects():
		var p := SafariPhotoScorer.subject_point(sj)
		var d := cam.global_position.distance_to(p)
		var why := "OK"
		if not SafariWorld.counts_for_pacing(sj):
			why = "uncounted"
		elif cam.is_position_behind(p):
			why = "behind"
		elif not Rect2(Vector2.ZERO, frame).has_point(cam.unproject_position(p)):
			why = "off"
		else:
			var e := SafariPhotoScorer.score_subject(cam, frame, sj, _s.focus_m, _s._space(), _s._exclude(), t)
			if e.is_empty():
				why = "hidden"
			elif float(e["size_frac"]) < _min_size:
				why = "small"
			elif float(e["inside_frac"]) < MIN_INSIDE:
				why = "edge"
		out.append("%s:%s@%.1f" % [str(sj.get("id", "")), why, d])
	return " ".join(out)


func _look(d: Vector2) -> void:
	# CameraRig.add_look: +x yaws right, +y looks further DOWN.
	_s.rig.add_look(Vector2(d.x, -d.y))


func _stick(v: Vector2) -> void:
	_press("move_right", maxf(v.x, 0.0))
	_press("move_left", maxf(-v.x, 0.0))
	_press("move_back", maxf(v.y, 0.0))
	_press("move_forward", maxf(-v.y, 0.0))


func _press(action: String, k: float) -> void:
	if k > 0.001:
		Input.action_press(action, k)
	else:
		Input.action_release(action)


## Where a point is, as (degrees round from the start, bearing from the start heading).
func _where(p: Vector3) -> String:
	var d := _s.planet.dir_of(p)
	var around := rad_to_deg(_s.start_dir.angle_to(d))
	var tt := d - _s.start_dir * d.dot(_s.start_dir)
	var bearing := 0.0
	if tt.length() > 1e-5:
		bearing = -rad_to_deg(_s.start_fwd.signed_angle_to(tt.normalized(), _s.start_dir))
	return "(%.0f, %.0f)" % [around, bearing]


func _finish() -> void:
	_done = true
	_stick(Vector2.ZERO)
	# a gap still open at the end of the three minutes counts too
	var end_t := PlanetSafari.DURATION
	var g := end_t - _last_seen_t
	if g > _longest:
		_longest = g
		_longest_at = _last_seen_t
		_longest_where = _where(_gap_start_pos)
	if g >= 10.0:
		_gaps.append([snappedf(_last_seen_t, 0.1), snappedf(g, 0.1), _where(_gap_start_pos)])
	var secs := {}
	for k: String in _seen_sec:
		secs[k] = snappedf(float(_seen_sec[k]), 0.1)
	var res := {
		"planet": _s.planet_id, "seed": _seed, "night": _s.is_night, "rare": _s.is_rare_day,
		"longest_gap": snappedf(_longest, 0.01), "longest_from": snappedf(_longest_at, 0.1), "longest_where": _longest_where,
		"gaps_10s": _gaps, "pass": _longest <= 20.0,
		"on_screen_frac": snappedf(float(_frames_seen) / maxf(float(_frames), 1.0), 0.001),
		"seen_sec": secs, "first_seen": _first_seen,
		"headings": _headings, "stuck_turns": _stuck, "path_m": snappedf(_path_m, 0.1),
		"frame": str(get_viewport().get_visible_rect().size),
		"mean_yaw_err": snappedf(_yaw_err_sum / maxf(float(_frames), 1.0), 0.1),
		"mean_pitch_err": snappedf(_pitch_err_sum / maxf(float(_frames), 1.0), 0.1),
		"gaze": _gaze, "mean_pitch": snappedf(_pitch_sum / maxf(float(_frames), 1.0), 0.1),
		"dists": _dists,
	}
	# the band (spec 11.2b)
	var gaps_between: Array = []
	for k in range(1, _encounters.size()):
		gaps_between.append(float(_encounters[k][0]) - float(_encounters[k - 1][0]))
	var med := _median(gaps_between)
	var share3 := float(_frames_3plus) / maxf(float(_frames), 1.0)
	res["encounters"] = _encounters
	res["encounter_n"] = _encounters.size()
	res["first_encounter"] = float(_encounters[0][0]) if not _encounters.is_empty() else -1.0
	res["median_between"] = snappedf(med, 0.01)
	res["share_3plus"] = snappedf(share3, 0.0001)
	res["band"] = {"gap_le_20": _longest <= 20.0, "gap_le_30": _longest <= 30.0,
		"median_8_15": med >= 8.0 and med <= 15.0, "share3_le_10pct": share3 <= 0.10}
	if _perf:
		res["perf"] = _perf_rows
	if _trace:
		for row: Array in _trace_rows:
			var in_start := OS.get_cmdline_user_args().has("--ps-trace-start") and float(row[0]) < 20.0
			if in_start or (float(row[0]) >= _longest_at - 0.5 and float(row[0]) <= _longest_at + _longest + 0.5):
				_log("TRACE t=%s at %s pitch %s glance %s stopped %s | %s" % row)
	var line := JSON.stringify(res)
	_log("RESULT " + line)
	if _out != "":
		var f := FileAccess.open(_out, FileAccess.READ_WRITE if FileAccess.file_exists(_out) else FileAccess.WRITE)
		if f != null:
			f.seek_end()
			f.store_line(line)
			f.close()
	get_tree().quit()
