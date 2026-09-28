extends Node
## THE CARELESS TEST PLAYER, and the wandering body both test players share (builder R3,
## docs/PLANET_SAFARI_SPEC.md 11.1 calibration gate: "a careless test player - points roughly, never
## zooms, any distance - averages Fair"). It wanders like the user said they play - the safari walk, a
## new heading every 5-15 s, the view drifting 25 degrees either side and between 14 down and 4 up
## (centred just below the horizon, spec 17.3 ruling 4: -4..+14 until 2026-09-27 - a change of the
## measuring instrument, not of the game; a safari itself starts about 10 degrees down, 13.3),
## never reading a warning - and the moment an awake subject is on its screen (in the frame, not hidden
## by the planet or a prop, at least NOTICE_FRAC of the frame tall) it stops where it stands, raises the
## camera, points ROUGHLY at the nearest one (the subject lands 0..AIM_ERR half frame heights off
## centre, uniform, in a random direction), waits RAISE_SEC and TAPS the shutter: no zoom (45 degrees
## always), no walking closer, no waiting for the subject to turn, no holding for focus. That is the
## user's own first log (never zoomed, 3-5 m, took what was there). ps_careful_player.gd extends this
## file and changes only what it picks and how it takes the shot, so the two differ by skill alone.
##
## RUN (in a SCRATCH copy, never the user's folder): autoload both through the copy's override.cfg
##   [autoload]
##   PSCareless="*res://tools/ps_careless_player.gd"
##   PSCareful="*res://tools/ps_careful_player.gd"
## then  godot --path <copy> --rendering-method gl_compatibility res://src/world/world.tscn -- --planet=<id>
##   --ps-play=careless --ps-seed=3 --ps-out=/abs/result.json [--ps-night] [--safari-rare|--safari-common]
##   --no-autosave
## ANY PLANET (SYS, 2026-09-25): nothing here names a planet - it starts whatever safari the planet has
## (its world script, or the placeholder world) and reads only the safari's own subject list. The
## report grades on the PLANET scale (spec 13.1: SafariScoring.planet_grade - craft cut at 0.35 / 0.70,
## a caught moment lifts one grade): `counts` per grade, `mean_grade_idx` (Smudge 0 .. Gallery 3; the
## player "averages Fair" when it rounds to 1), `moments` (photos that caught one), `refused` (shutter
## presses with nothing in the frame: no picture, no plate) and the VARIETY - `per_subject` {id: n} and
## `share` {id: fraction of the photos} and `top_share`.
## Each acts only when --ps-play names it, so both are harmless when autoloaded. It quits by itself when
## the safari's session ends (about 190 s); the review is not driven. Output: `PS_RESULT {...}` on stdout
## and the full rows in --ps-out (every photo: subject, grade, the raw numbers, distance, lens, moment).
## HEADLESS runs work too and go faster than real time with --fixed-fps 60 (every frame is 1/60 s of
## game time; the frame is sized by --ps-frame, see _frame): nothing is drawn, so the photo's pixels are
## empty but every score is the same maths on the same camera and physics.
## Windowed runs need the window uncovered (macOS stops drawing a covered window and the shutter waits
## for a drawn frame): pass --always-on-top --position X,Y before the --.
##
## SIGHTS AND BONUS SUBJECTS (spec 15.5): neither player goes looking for them (`visible_subjects` skips
## them, as the density gate does) unless `--ps-collect` is passed; a photo may still NAME one (the scorer
## picks the best subject in the frame). The VARIETY - per_subject, share, top_share, top_id - counts only
## the photos of counted subjects (`photos_counted` of them); `uncounted` lists the sight and bonus photos
## by id, and `counts` still grades every photo.
##
## SYNTHETIC, said plainly: the safari starts with PlanetSafari.request_start (no talk to Bolt); walking
## is Input.action_press (no InputEvent); looking is CameraRig.add_look - the drag's own entry point,
## with the angle a finger would drag, not a finger; camera, zoom and shutter are PlanetSafari's
## set_camera_up / set_zoom_fov / shutter_down / shutter_up - what the on-screen buttons call, not taps.
## The players see subjects only through their own screen; the careful one also reads a subject's band
## and front, which a person learns from the review's numbers and the zoom nudge.

## Something is NOTICED at 3 % of the frame height (22 px of 720): smaller, a 0.6 m crab is a dot 14 m
## away. A stated pick.
const NOTICE_FRAC := 0.03
## No second photo of one subject within this long, and no two photos closer than SHOT_GAP (the film is
## about ten plates for three minutes).
const SAME_SUBJECT_GAP := 20.0
const SHOT_GAP := 5.0
const HEADING_MIN := 5.0
const HEADING_MAX := 15.0
const DRIFT_YAW_DEG := 25.0
const DRIFT_PITCH_LO := -14.0
const DRIFT_PITCH_HI := 4.0
## How far off centre a rough point lands, at most, in half frame heights (Centred's own unit: 0.5 is a
## Centred of 5). A stated model of "roughly", not fitted to any result.
const AIM_ERR := 0.5
## Raise, point, press: about a second for a person. A stated pick.
const RAISE_SEC := 1.0

var who := "careless"
var rng := RandomNumberGenerator.new()
var seed_n := 1
var out_path := ""
var safari: PlanetSafari
var _play := false
var _heading_left := 0.0
var _heading := Vector3.ZERO
var _drift_t := 0.0
var _last_shot := -999.0
var _shot_at: Dictionary = {}
var _photos: Array = []
var _finished := false
var _session: Dictionary = {}
var _held: Dictionary = {}
var _refused := 0
## THE LONGEST TIME WITH NOTHING ON SCREEN (spec 17.3 gate): seconds of safari time with no counted subject
## in visible_subjects() (the player's own notion of "on my screen"), sampled every NOTHING_STEP s.
const NOTHING_STEP := 0.25
var _nothing_since := -1.0
var _nothing_longest := 0.0
var _nothing_longest_at := 0.0
var _nothing_next := 0.0
## The judged frame for a HEADLESS run (its viewport is otherwise 1280x1280): 1280x720 by default, the
## desktop window's own size, as tools/ps_wanderer.gd does; --ps-frame=WxH to change it. A windowed run
## keeps its window.
var _frame := Vector2i(1280, 720)
## --ps-collect: also go for sights and bonus subjects (spec 15.5); off by default.
var _collect := false


func _init() -> void:
	who = "careless"


func _process(_delta: float) -> void:
	if not _play or safari == null or not is_instance_valid(safari):
		return
	# THE OUT-OF-FILM CARD (spec 17.2.1): it pauses the whole tree (planet_safari.gd
	# _offer_film_out), so a run out of film sat there forever with nothing to press - the same
	# report that got the End button and this card built in the first place, now happening to the
	# test player instead of a human. Tap "See your photos" (the card's primary button) the real way
	# (SafariLayer.debug_choice_tap, MobileUI.synth_tap under the hood) the moment it is up, so a
	# careless run ends itself instead of hanging past DURATION. Checked before `awake()`/elapsed
	# gating below: the tree is paused while the card is up, so `elapsed` itself is frozen too.
	if safari.layer != null and safari.layer.choice_showing() and EventBus.modal_counts().has(PlanetSafari.FILM_OUT_MODAL):
		safari.layer.debug_choice_tap("primary")
		return
	if not awake() or safari.elapsed < _nothing_next:
		return
	_nothing_next = safari.elapsed + NOTHING_STEP
	var saw := not visible_subjects().is_empty()
	if saw or _nothing_since < 0.0:
		_nothing_since = safari.elapsed if not saw else -1.0
		if saw:
			return
	var gap := safari.elapsed - _nothing_since
	if gap > _nothing_longest:
		_nothing_longest = gap
		_nothing_longest_at = _nothing_since


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a == "--ps-play=" + who:
			_play = true
		elif a.begins_with("--ps-seed="):
			seed_n = int(a.substr(10))
		elif a.begins_with("--ps-out="):
			out_path = a.substr(9)
		elif a == "--ps-collect":
			_collect = true
		elif a.begins_with("--ps-frame="):
			var wh := a.substr(11).split("x")
			_frame = Vector2i(int(wh[0]), int(wh[1]))
	if not _play:
		return
	rng.seed = seed_n * 7919 + (1 if who == "careless" else 2)
	_run.call_deferred()


# ============================================================================================ helpers
func L(m: String) -> void:
	var t := ("%.2f" % safari.elapsed) if safari != null and is_instance_valid(safari) else "-"
	print("[PS %s %s] %s" % [who, t, m])


func W(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func F(n: int = 1) -> void:
	for i in range(n):
		await get_tree().process_frame


func P() -> Player:
	return get_node_or_null("/root/World/Player") as Player


func R() -> CameraRig:
	return get_node_or_null("/root/World/CameraRig") as CameraRig


func cam() -> Camera3D:
	return R().get_view_camera() if R() != null else null


func frame() -> Vector2:
	return get_viewport().get_visible_rect().size


func awake() -> bool:
	return safari != null and is_instance_valid(safari) and safari.phase == PlanetSafari.Phase.AWAKE


func _space() -> PhysicsDirectSpaceState3D:
	return safari.get_world_3d().direct_space_state


func _exclude() -> Array[RID]:
	var ex: Array[RID] = []
	if P() != null:
		ex.append(P().get_rid())
	return ex


## Holds (or lets go of) one input action; "" lets go of everything.
func hold_action(action: String, on: bool) -> void:
	if on and not _held.has(action):
		_held[action] = true
		Input.action_press(action)
	elif not on and _held.has(action):
		_held.erase(action)
		Input.action_release(action)


func release_all() -> void:
	for a: String in _held.keys():
		Input.action_release(a)
	_held.clear()


# ============================================================================================ run
func _run() -> void:
	await W(1.5)
	if DisplayServer.get_name() == "headless":
		get_tree().root.size = _frame
	if OS.get_cmdline_user_args().has("--ps-night"):
		# The Environment owns the clock and writes GameState.time_of_day back every frame, so night is
		# set through it (setting GameState alone is undone before the safari reads it).
		var env := get_tree().root.find_child("Environment", true, false)
		if env != null and env.has_method("set_time"):
			env.call("set_time", 23.0)
		GameState.time_of_day = 23.0
		await F(2)
	safari = PlanetSafari.request_start(get_tree())
	if safari == null:
		L("FAIL no safari")
		get_tree().quit(1)
		return
	safari.photo_taken.connect(func(p: Dictionary) -> void: _photos.append(p))
	safari.photo_refused.connect(func(_t: float) -> void: _refused += 1)
	safari.session_finished.connect(func(s: Dictionary) -> void:
		_session = s
		_finished = true)
	var guard := 0.0
	while safari.phase != PlanetSafari.Phase.AWAKE and guard < 30.0:
		await W(0.05)
		guard += 0.05
	L("awake planet=%s night=%s rare=%s film=%d pitch=%.1f renderer=%s" % [safari.planet_id, str(safari.is_night),
		str(safari.is_rare_day), safari.film_left, R().get_view_pitch_deg(), RenderingServer.get_current_rendering_method()])
	_new_heading()
	while awake():
		var target := spot()
		if not target.is_empty():
			release_all()
			var key := str(target["s"]["key"])
			L("spotted %s dist=%.1f size_frac=%.3f" % [key, float(target["dist"]), float(target["size_frac"])])
			await _take(target)
			release_all()
			if awake():
				_shot_at[key] = safari.elapsed
				_last_shot = safari.elapsed
				if safari.camera_up:
					safari.set_camera_up(false)
			await F(2)
			continue
		_wander(get_process_delta_time())
		await F(1)
	release_all()
	var g := 0.0
	while not _finished and g < 20.0:
		await W(0.1)
		g += 0.1
	_report()
	get_tree().quit()


func _may_shoot(key: String) -> bool:
	if safari.film_left <= 0 or safari.elapsed - _last_shot < SHOT_GAP:
		return false
	return safari.elapsed - float(_shot_at.get(key, -999.0)) >= SAME_SUBJECT_GAP


# ============================================================================================ seeing
## Every awake subject on this player's screen right now (in the frame, a sight ray reaches it, at least
## NOTICE_FRAC tall), nearest first: {s, p, dist, size_frac, d (off centre, half frame heights)}.
func visible_subjects() -> Array:
	var c := cam()
	if c == null:
		return []
	var fr := frame()
	var half_h := fr.y * 0.5
	var tan_half := tan(deg_to_rad(c.fov) * 0.5)
	var out: Array = []
	for s: Dictionary in safari.awake_subjects():
		if not _collect and not SafariWorld.counts_for_pacing(s):
			continue   # a sight or a bonus subject (spec 15.5)
		var p := SafariPhotoScorer.subject_point(s)
		var dist := c.global_position.distance_to(p)
		if dist < 0.05 or c.is_position_behind(p):
			continue
		var sp := c.unproject_position(p)
		if not Rect2(Vector2.ZERO, fr).has_point(sp):
			continue
		var r := float(s.get("radius", 0.5))
		var size_frac := tan(asin(clampf(r / dist, 0.0, 1.0))) / tan_half
		if size_frac < NOTICE_FRAC:
			continue
		if SafariPhotoScorer.seen_fraction(c, p, r, _space(), _exclude()) <= 0.0:
			continue
		out.append({"s": s, "p": p, "dist": dist, "size_frac": size_frac, "d": sp.distance_to(fr * 0.5) / half_h})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["dist"]) < float(b["dist"]))
	return out


## What this player goes for: the NEAREST thing on screen it may shoot.
func spot() -> Dictionary:
	for v: Dictionary in visible_subjects():
		if _may_shoot(str(v["s"]["key"])):
			return v
	return {}


## The subject's entry again (it moves), or {} once it has gone to sleep.
func refresh(s: Dictionary) -> Dictionary:
	var key := str(s["key"])
	for a: Dictionary in safari.awake_subjects():
		if str(a["key"]) == key:
			var c := cam()
			var p := SafariPhotoScorer.subject_point(a)
			var dist := c.global_position.distance_to(p)
			var r := float(a.get("radius", 0.5))
			var tan_half := tan(deg_to_rad(c.fov) * 0.5)
			return {"s": a, "p": p, "dist": dist, "size_frac": tan(asin(clampf(r / dist, 0.0, 1.0))) / tan_half}
	return {}


# ============================================================================================ wandering
func _new_heading() -> void:
	_heading_left = rng.randf_range(HEADING_MIN, HEADING_MAX)
	_heading = R().get_planar_forward().rotated(P().up, deg_to_rad(rng.randf_range(-180.0, 180.0))).normalized()


## One frame of wandering: walk along the heading, the view drifting about it.
func _wander(delta: float) -> void:
	if safari.camera_up:
		safari.set_camera_up(false)
	_heading_left -= delta
	if _heading_left <= 0.0:
		_new_heading()
	var up := P().up
	_heading = (_heading - up * _heading.dot(up)).normalized()
	_drift_t += delta
	var yaw := DRIFT_YAW_DEG * sin(_drift_t * 0.45 + float(seed_n))
	var pitch := lerpf(DRIFT_PITCH_LO, DRIFT_PITCH_HI, 0.5 + 0.5 * sin(_drift_t * 0.29 + 1.3 * float(seed_n)))
	var look := _heading.rotated(up, deg_to_rad(yaw))
	look = (look * cos(deg_to_rad(pitch)) + up * sin(deg_to_rad(pitch))).normalized()
	aim_dir(look, 0.25)
	hold_action("move_forward", true)


# ============================================================================================ aiming
## One frame of turning toward world direction `dir`, `gain` of the error per frame, through
## CameraRig.add_look (the drag's entry point) with the angle a drag would carry. Returns the error
## (yaw, pitch) in degrees before the turn.
func aim_dir(dir: Vector3, gain: float = 0.8) -> Vector2:
	var c := cam()
	var up := P().up
	var f := -c.global_transform.basis.z
	var fh := (f - up * f.dot(up)).normalized()
	var dh := (dir - up * dir.dot(up)).normalized()
	var yaw := rad_to_deg(fh.signed_angle_to(dh, up))
	var pitch := rad_to_deg(asin(clampf(dir.normalized().dot(up), -1.0, 1.0)) - asin(clampf(f.dot(up), -1.0, 1.0)))
	add_look_deg(Vector2(-yaw, -pitch) * gain)
	return Vector2(yaw, pitch)


## Turns the view by exactly `deg` (yaw, pitch as add_look takes them), undoing the player's
## sensitivity, inversion and the camera-up look scale that CameraRig.add_look applies.
func add_look_deg(deg: Vector2) -> void:
	var sens := clampf(float(GameState.settings.get("mouse_sensitivity", 1.0)), 0.1, 4.0)
	var k := float(R().get("_look_scale")) if R().is_first_person() else 1.0
	var sx := -1.0 if bool(GameState.settings.get("camera_invert_x", false)) else 1.0
	var sy := -1.0 if bool(GameState.settings.get("camera_invert_y", false)) else 1.0
	R().add_look(Vector2(deg.x * sx, deg.y * sy) / (sens * maxf(k, 0.001)))


func aim_at(p: Vector3, gain: float = 0.8) -> Vector2:
	return aim_dir((p - cam().global_position).normalized(), gain)


## Facing out of 10 from the lens now, or -1 for a subject with no front (the scorer's own rule).
func facing_now(s: Dictionary) -> float:
	return SafariPhotoScorer.facing_score(s, SafariPhotoScorer.subject_point(s), cam().global_position)


## Fires the shutter: a tap (`hold` false), or a hold until the focus has settled (on `lock_key` when
## given) for at most `max_hold` s, turning toward `track` every frame. Returns the photo, or {}.
func shoot(hold: bool, track: Dictionary = {}, max_hold: float = 1.5, lock_key: String = "") -> Dictionary:
	var n0 := _photos.size()
	safari.shutter_down()
	if hold:
		var t := 0.0
		while awake() and t < max_hold and not (safari.focus_settled() \
				and (lock_key == "" or safari.focus_target_key == lock_key)):
			if not track.is_empty():
				aim_at(SafariPhotoScorer.subject_point(track))
			await F(1)
			t += get_process_delta_time()
	else:
		await F(1)
	safari.shutter_up()
	var g := 0
	while _photos.size() == n0 and g < 30:
		await F(1)
		g += 1
	if _photos.size() == n0:
		return {}
	var ph: Dictionary = _photos[-1]
	var raw: Dictionary = ph.get("raw", {})
	L("photo aimed_at=%s subject=%s grade=%s scores=%s dist=%.1f size_frac=%.3f fov=%.1f mm=%.2f" % [
		str(track.get("key", "-")), ph["subject_key"], ph["grade"], str(ph["scores"]),
		float(raw.get("dist", 0.0)), float(raw.get("size_frac", 0.0)), float(ph["fov"]), float(ph["moment_mult"])])
	return ph


# ============================================================================================ the shot
## CARELESS: raise the camera where it stands, point roughly at the target, a second, tap.
func _take(target: Dictionary) -> void:
	var s: Dictionary = target["s"]
	safari.set_camera_up(true)
	await F(2)
	var ok := 0
	var e := Vector2.ZERO
	for i in range(30):
		if not awake():
			return
		e = aim_at(SafariPhotoScorer.subject_point(s))
		await F(1)
		ok = ok + 1 if absf(e.x) < 1.0 and absf(e.y) < 1.0 else 0
		if ok >= 2:
			break
	L("aimed: last error yaw %.1f pitch %.1f deg, view pitch %.1f" % [e.x, e.y, R().get_view_pitch_deg()])
	if not awake():
		return
	# The rough part: the same look, off by a random amount in a random direction.
	var u := rng.randf() * AIM_ERR
	var th := rng.randf() * TAU
	var ang := rad_to_deg(atan(u * tan(deg_to_rad(cam().fov) * 0.5)))
	add_look_deg(Vector2(cos(th), sin(th)) * ang)
	await W(RAISE_SEC)
	if awake():
		L("rough aim off by %.2f half-heights; nudge on screen: \"%s\"; it is now at %s" % [u, safari.zoom_nudge,
			str(cam().unproject_position(SafariPhotoScorer.subject_point(s))) if not cam().is_position_behind(SafariPhotoScorer.subject_point(s)) else "behind"])
		await shoot(false, s)


# ============================================================================================ report
func _report() -> void:
	var counts := {"Smudge": 0, "Fair": 0, "Fine": 0, "Gallery": 0}
	var rows: Array = []
	var idx_sum := 0.0
	var craft_sum := 0.0
	var moments := 0
	var per_subject := {}
	var uncounted := {}
	for ph: Dictionary in _photos:
		counts[str(ph["grade"])] = int(counts.get(str(ph["grade"]), 0)) + 1
		var raw: Dictionary = ph.get("raw", {})
		idx_sum += float(ph.get("grade_idx", SafariScoring.GRADES.find(str(ph["grade"]))))
		craft_sum += float(ph["craft"])
		if bool(ph.get("moment", false)):
			moments += 1
		var sid := str(ph["subject_key"]).get_slice(":", 1)
		var cat := str(raw.get("category", ""))
		if cat == "":
			cat = SafariWorld.key_category(str(ph["subject_key"]))
		if SafariWorld.UNCOUNTED_CATEGORIES.has(cat):
			uncounted[sid] = int(uncounted.get(sid, 0)) + 1
		else:
			per_subject[sid] = int(per_subject.get(sid, 0)) + 1
		rows.append({"t": snappedf(float(ph["t"]), 0.01), "subject": ph["subject_key"], "grade": ph["grade"],
			"moment": bool(ph.get("moment", false)), "craft": snappedf(float(ph["craft"]), 0.001),
			"centred": snappedf(float(raw.get("centred", 0.0)), 0.01), "size": snappedf(float(raw.get("size", 0.0)), 0.01),
			"focus": snappedf(float(raw.get("focus", 0.0)), 0.01), "facing": snappedf(float(raw.get("facing", -1.0)), 0.01),
			"size_frac": snappedf(float(raw.get("size_frac", 0.0)), 0.001), "dist": snappedf(float(raw.get("dist", 0.0)), 0.01),
			"fov": snappedf(float(ph["fov"]), 0.1), "moment_mult": ph["moment_mult"], "held_s": snappedf(float(ph["held_s"]), 0.01),
			"price": ph["price"], "category": cat})
	var n := _photos.size()
	var mean_idx := idx_sum / float(maxi(n, 1))
	var mean_grade: String = SafariScoring.GRADES[clampi(int(round(mean_idx)), 0, 3)]
	var share := {}
	var top_share := 0.0
	var top_id := ""
	var n_counted := 0
	for k: String in per_subject:
		n_counted += int(per_subject[k])
	for k: String in per_subject:
		share[k] = snappedf(float(per_subject[k]) / float(maxi(n_counted, 1)), 0.001)
		if float(share[k]) > top_share:
			top_share = float(share[k])
			top_id = k
	var pid := str(_session.get("planet_id", GameState.current_planet_id))
	var res := {"player": who, "planet": pid, "seed": seed_n, "night": _session.get("is_night", false),
		"rare": _session.get("is_rare_day", false), "photos": n, "counts": counts,
		"mean_grade_idx": snappedf(mean_idx, 0.001), "mean_grade": mean_grade,
		"mean_craft": snappedf(craft_sum / float(maxi(n, 1)), 0.001), "moments": moments,
		"refused": _refused, "per_subject": per_subject, "share": share, "top_share": top_share, "top_id": top_id,
		"photos_counted": n_counted, "uncounted": uncounted,
		"longest_nothing_s": snappedf(_nothing_longest, 0.01), "longest_nothing_from": snappedf(_nothing_longest_at, 0.1),
		"rows": rows, "renderer": RenderingServer.get_current_rendering_method()}
	var brief := res.duplicate()
	brief.erase("rows")
	print("PS_RESULT " + JSON.stringify(brief))
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(res))
			f.close()
