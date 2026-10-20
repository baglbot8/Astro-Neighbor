class_name SafariIntro
extends Node3D
## THE SAFARI START CUTSCENE (prototype, builder SINTRO, 2026-10-19). The user: "a bit of a mini cutscene
## when you start a safari. Almost like how in Pokemon Snap at the start of the level you see the player
## moving then slowly zooming in and settling into a first person view" (OPTION A), or "3 scenes across the
## planet and a name of the planet fades in ... cut it down to 2 scenes and the start point" (OPTION B).
## Both are built so the user can compare them on the phone; ONE runner plays either, they differ only in
## the shot list. About TOTAL_SEC (4.5 s) from the black lifting to control.
##
## WHERE IT RUNS. PlanetSafari._run(), after the world is built and warmed behind the black, asks
## `kind_for` and, when it is "a" or "b", adds this node and awaits `done` INSTEAD of today's 0.45 s fade-in.
## Everything after (`phase = AWAKE`, `elapsed = 0.0`, the opening line) is unchanged, so THE TIMER STARTS
## WHEN CONTROL RETURNS, exactly as before. The schedule, the content's tick and every tip/hint run only in
## phase AWAKE, so nothing in the safari can start or arm during the intro: no creature is ticked, no event
## warned, no tip card or hover hint armed. The content is NOT ticked here (ticking it early would draw on
## its random numbers and change what a normal start does).
##
## THE DEV SWITCH. GameState.settings["safari_intro"] = "a" | "b" | "off" (default "b", the dev menu's
## World tab), read at each safari start. "off" is today's start, line for line. Only the planets in
## PROTOTYPE_PLANETS (Zorp) play it; every other planet always starts the old way.
##
## WHAT IT TOUCHES, AND PUTS BACK (also from `_exit_tree`, so a quit or scene change mid-intro leaves
## nothing behind):
##   * its own Camera3D, current for the intro; the rig's camera is made current again at the end. The last
##     HANDBACK_SEC blend the intro's lens into the rig's live first-person lens (position, direction, FOV),
##     so the hand-back step is one frame of ordinary motion.
##   * the "safari_intro" modal, open for the whole intro: the player cannot walk, look, hop or talk, the
##     touch stick hides, and SafariLayer ignores every press (it only listens in phase AWAKE).
##   * SafariLayer's black: set to clear the instant this node's own (identical navy) black is up, so the
##     lift and the dips run on THIS node's clock - which freezes while the Skip pop-up is open.
##   * SafariLayer's "Root" (the shutter, film, sun-dial, End button): shown and faded in over the last
##     UI_FADE_SEC, fully opaque at control.
## It never touches the player, the real astronaut model, the real Zorp or the content. Option A's walking
## astronaut is a DOUBLE (an AstronautModel in the player's own style, on render layer DOUBLE_LAYER, which
## only the intro's camera draws); the real astronaut is already standing at the start, hidden by the rig's
## first-person layer, so the double walks INTO him and the lens goes through the double's helmet into the
## real first-person eye. The double vanishes by the same mechanism the rig uses (the camera stops drawing its
## layer), never `visible`. Option B's waving Zorp is a double too (NpcModels.make), so the real Zorp's
## place, emote and wander state are exactly what a normal start leaves.
##
## SKIP. The first time a save sees a prototype it plays in full (GameState.flags SEEN_FLAG_PREFIX + kind, set
## when it ends). Later ones show a small "Skip" pill bottom right (the cockpit's look, at least SKIP_MIN_PT
## tall on a phone, clear of the home bar): it, any key, or a pad button opens SkipConfirm ("Skip the
## intro?"); the clock is frozen while it is open; a tap anywhere else does nothing. A confirmed skip dips to
## navy, lands in the end state (rig lens current, first-person pose, UI shown) and lifts in SKIP_LIFT_SEC.

signal done(skipped: bool)

const SETTING := "safari_intro"
## "b" since the critic's round (2026-10-19): the user's first Zorp safari plays the version with no known pop.
const DEFAULT_KIND := "b"
const SEEN_FLAG_PREFIX := "safari_intro_seen_"
const PROTOTYPE_PLANETS: PackedStringArray = ["zorp"]
const MODAL := "safari_intro"

## Render layer of option A's double (1-based). 17 is the rig's first-person layer, 19 the rocket's ground
## light, 20 the crash's fill, 6 the water: 18 is free (grep `layers` / `cull_mask`, 2026-10-19).
const DOUBLE_LAYER := 18
const DOUBLE_BIT := 1 << (DOUBLE_LAYER - 1)
## Over SafariLayer (30), under SafariLayer's own black (99) and SkipConfirm (150).
const CARD_LAYER := 98

## From the black starting to lift to control.
const TOTAL_SEC := 4.5
const LIFT_SEC := 0.5
## The intro's lens blends into the rig's first-person lens over the last this-long.
const HANDBACK_SEC := 0.8
## SafariLayer's controls fade in over the last this-long (opaque at control).
const UI_FADE_SEC := 0.35
## Option B: the dip between shots (out and back in), and the name card's fade out at the end.
const DIP_SEC := 0.18
const CARD_OUT_SEC := 0.5
## OPTION B's TITLE, the planet's own lettering (TitleLettering, the user: "takes up a lot of the screen and is in the
## center middle. Then it becomes more transparent and fades out"). Its strength over the 4.5 s, in order:
## fades IN with the black's lift to full by TITLE_IN_END; HOLDS full to TITLE_HOLD_END; DRIFTS smoothly down to
## TITLE_DRIFT_ALPHA by TITLE_DRIFT_END (the middle of scene 2) so the scenes show through; LINGERS, still thinning,
## to TITLE_LINGER_ALPHA at TITLE_LINGER_END; then FADES OUT, gone (and no longer drawn) at TITLE_GONE, before
## control. It grows by TITLE_GROW (a few percent) from the end of the hold to gone.
const TITLE_IN_END := 0.5
const TITLE_HOLD_END := 1.5
const TITLE_DRIFT_END := 2.2
const TITLE_DRIFT_ALPHA := 0.33
const TITLE_LINGER_END := 3.6
const TITLE_LINGER_ALPHA := 0.22
const TITLE_GONE := 4.4
const TITLE_GROW := 0.06
## The subtitle comes in a little after the title (then follows its schedule).
const SUB_IN := Vector2(0.45, 1.0)
## The title block (lettering + subtitle) fits inside this share of the screen's height and of its width between
## the safe areas.
const TITLE_MAX_H := 0.40
const TITLE_MAX_W := 0.80
## The block's vertical centre, as a share of the screen height from the top (0.5 = the middle).
## 0.28: the two-line block ends above Zorp's head in scene 2 (three centred lines ran across his face).
const TITLE_CENTER_Y := 0.28
## The lettering atlas is baked at this share of the cap height the screen shows (0.75: about 56% of the texture
## memory of a full-resolution bake; compared side by side at phone size).
const TITLE_BAKE_SCALE := 0.75
## The intro's own lens (the rig's first person is 45).
const INTRO_FOV := 50.0
const SKIP_ARM_SEC := 0.3
const SKIP_MIN_PT := 44.0
const SKIP_DIP_SEC := 0.2
const SKIP_LIFT_SEC := 0.3
## Director timelines tap these (Input.action_press sends no InputEvent): CockpitIntro's set.
const SKIP_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "cancel", "pause"]

# ------------------------------------------------------------------------------ option A, the swoop
## How far behind the start the double begins (metres along the start heading). The pad's centre is 3.2 m
## behind the start (PlanetSafari.PAD_STEP_M), its deck 2.55 m round (RocketPad.PAD_R) and the rocket's hull
## 0.62 m: the start is only 0.65 m off the deck, so a walk along the heading that ENDS on the start always begins
## on the deck. 1.6 m keeps him about 1 m clear of the hull and steps him off the deck early in the shot.
const A_WALK_M := 1.6
## He walks at a steady pace until A_WALK_STEADY, then slows to a stop at A_WALK_STOP.
const A_WALK_STEADY := 2.8
const A_WALK_STOP := 3.8
## The orbit, in his own frame: azimuth from straight ahead toward his LEFT, radius, lens height.
## It opens from his LEFT side, a little high, aimed A_LEAD0 m AHEAD of him (room in front of a walking subject):
## the rocket, 1.6 m behind him at the start, then falls outside the frame's ~45 degree half-width. From his
## front-left, or aimed at him, it filled the background (the critic: "the opening is crowded"; seen in frames).
const A_PHI0_DEG := 95.0
const A_R0 := 2.4
const A_H0 := 1.5
## Where the opening looks on him (height above his feet); it rises to the helmet as the lens comes round.
const A_LOOK_Y0 := 0.75
const A_LEAD0 := 1.2
## Behind him at the end of the orbit.
const A_ORBIT_END := 2.6
const A_R1 := 1.45
const A_H1 := 1.30
## The push into the helmet ends here (then the lens rides at the eye and settles).
const A_PUSH_END := 3.65
## The look the push ends on, before the settle tilts it up to the safari's own START_PITCH_DEG (-10): lower, so
## the ground ahead and the start's crystal fill the view through the vanish (the critic: "70% empty sky").
const A_END_PITCH_DEG := -16.0
## THE VANISH is covered by a dip to the visor's navy (the intro's own black), up over A_DIP_IN to full on the frame
## he vanishes and back over A_DIP_OUT: going "into his head" rather than a shape disappearing in one frame.
const A_DIP_IN := 0.14
const A_DIP_OUT := 0.10
## The brass camera in his hands, this many times the cockpit's (so it reads from 3 m).
const A_CAM_SCALE := 1.5

var safari: PlanetSafari
var kind := ""
var skippable := false

var _cam: Camera3D
var _rig_cam: Camera3D
var _t := 0.0
var _running := false
var _done := false
var _confirming := false
var _skipping := false
var _modal_open := false
var _ui_shown := false
var _skip_primed := false
var _skip_held: Dictionary = {}
var _hide_dist := 0.5
var _double_hidden := false
## When option A's lens reaches _hide_dist (found once from the path, before the clock starts).
var _t_hide := -1.0
## True when `done` came from `_exit_tree` (this node, and probably the scene, going away): the caller must
## not start the safari.
var aborted := false
var _warming := false

var _card_layer: CanvasLayer
var _card_root: Control
var _black: ColorRect
var _title: Label
var _sub: Label
var _lettering: TitleLettering
var _title_fit := 1.0
var _title_alpha := 0.0
var _skip: Button
var _ui_root: Control

# option A
var _double: AstronautModel
var _shadow: MeshInstance3D
var _base_xf := Transform3D()       # the real player's body at the start
var _model_local := Transform3D()   # its model, relative to the body
var _shadow_local := Transform3D()  # its blob shadow, relative to the body
var _axis := Vector3.RIGHT          # rotating the start about this walks it forward
var _h0 := 0.0
var _walk_v := 1.0

# option B
var _shots: Array[Shot] = []        # compiled once: see `_build_b`
var _cuts := PackedFloat32Array()   # shot start times
var _zorp: Node3D                   # the waving double
var _zorp_shot := -1

# trace
var _trace := false


## The intro to play at this safari start: "a", "b" or "" (none - today's fade). `content` is the world
## script PlanetSafari just built (option B reads its `intro_shots()`).
static func kind_for(planet_id: String, content: Object) -> String:
	var k := str(GameState.settings.get(SETTING, DEFAULT_KIND))
	if k != "a" and k != "b":
		return ""
	if not PROTOTYPE_PLANETS.has(planet_id):
		return ""
	if k == "b" and (content == null or not content.has_method("intro_shots")
			or (content.call("intro_shots") as Array).is_empty()):
		return ""
	return k


func setup(s: PlanetSafari, intro_kind: String) -> void:
	safari = s
	kind = intro_kind
	name = "SafariIntro"


func _ready() -> void:
	process_priority = 20   # after CameraRig (10): the rig's lens is already this frame's when it is read
	_trace = OS.get_cmdline_user_args().has("--safari-intro-trace")


## Builds everything behind the black and starts the clock. `done` is emitted once, when control should
## return (or from `_exit_tree` if this node is freed first).
func start() -> void:
	skippable = bool(GameState.flags.get(SEEN_FLAG_PREFIX + kind, false))
	_rig_cam = safari.rig.get_view_camera()
	_build_card()
	EventBus.ui_modal_opened.emit(MODAL)
	_modal_open = true
	# Our black is up (navy, opaque, under SafariLayer's own): clear SafariLayer's so ours is the one that lifts.
	safari.layer.fade_to(0.0, 0.0)
	_ui_root = safari.layer.get_node_or_null("Root") as Control
	_cam = Camera3D.new()
	_cam.name = "IntroCamera"
	_cam.near = _rig_cam.near
	_cam.far = _rig_cam.far
	_cam.environment = _rig_cam.environment
	_cam.attributes = _rig_cam.attributes
	_cam.keep_aspect = _rig_cam.keep_aspect
	_cam.cull_mask = _rig_cam.cull_mask
	_cam.fov = INTRO_FOV
	add_child(_cam)
	if kind == "a":
		_build_a()
		_cam.cull_mask = _rig_cam.cull_mask | DOUBLE_BIT
	else:
		_build_b()
	# He vanishes when the dome covers the WHOLE frame - its angular radius reaches half the DIAGONAL field of
	# view - or, if the near plane would cut into the dome before that, just outside the near plane (helmet
	# radius + the near plane's corner distance). The visor dip (A_DIP_IN/OUT) covers whatever corner is left.
	_hide_dist = maxf(_helmet_radius() / sin(_half_diag_fov(_cam)), _helmet_radius() + _near_corner(_cam))
	if kind == "a":
		_t_hide = _find_hide_time()
	_cam.current = true
	# WARM-UP behind the black: one frame from each shot's pose, so whatever the intro shows for the first time
	# (the doubles, the brass camera, a corner of the planet the player has not looked at, the card's text) is
	# drawn - its shaders compiled - before anyone can see it. Measured without it: two 125-145 ms frames in
	# option B (the crystal field coming into view, and Zorp's stand-in's first frame).
	var us0 := Time.get_ticks_usec()
	if _lettering != null:
		# Baked once, behind the black, at the cap height the screen will really show at its largest (the fit,
		# the grow, and the window's stretch: 1.64 on a 1179-px-tall phone).
		# It renders during the first warm-up frame below (bake_finish after the loop).
		var stretch := get_tree().root.get_final_transform().get_scale().y
		_lettering.bake_start(TitleLettering.BUILD_CAP_PX * _title_fit * (1.0 + TITLE_GROW) * stretch * TITLE_BAKE_SCALE)
	_warming = true
	if _title != null:
		_title.modulate.a = 0.01
	if _lettering != null:
		_lettering.set_strength(0.01)
	if _sub != null:
		_sub.modulate.a = 0.01
	for wt: float in _warm_times():
		_apply_shot(wt, 0.0)
		await get_tree().process_frame
		if _done or not is_inside_tree():
			return
	_warming = false
	if _lettering != null:
		_lettering.bake_finish()
		_log("title baked into a %s atlas" % str(_lettering.atlas_size))
	if _zorp != null:
		_zorp.visible = false
	if _title != null:
		_title.modulate.a = 0.0
	if _lettering != null:
		# The baked sprites exist only from here: draw them once (faintly, behind the black) so their first visible
		# frame is not their first draw (a 26 ms frame in B was measured without this).
		_lettering.set_strength(0.01)
	if _sub != null:
		_sub.modulate.a = 0.0
	_apply_shot(0.0, 0.0)
	await get_tree().process_frame
	if _done or not is_inside_tree():
		return
	if _lettering != null:
		_lettering.set_strength(0.0)
	_running = true
	_t = 0.0
	_log("start kind=%s skippable=%s hide_dist=%.2f t_hide=%.3f warm=%d poses %.1f ms" % [kind, str(skippable),
		_hide_dist, _t_hide, _warm_times().size(), float(Time.get_ticks_usec() - us0) / 1000.0])
	if kind == "a":
		# He must end exactly on the real player: his feet at the end of the walk vs the player's body.
		_log("double ends %.5f m from the player's start" % _frame_at(_walk_s(TOTAL_SEC)).origin.distance_to(
			safari.player.global_position))


func _process(delta: float) -> void:
	if not _running or _done or _skipping:
		return
	if _confirming or get_tree().paused:
		return
	_t = minf(_t + delta, TOTAL_SEC)
	_apply_shot(_t, delta)
	_apply_overlays(_t)
	if _skip != null:
		_skip.visible = skippable and _t >= SKIP_ARM_SEC and _t < TOTAL_SEC - UI_FADE_SEC
	if _t >= TOTAL_SEC:
		_finish(false)


# ======================================================================================== THE SHOTS
## Places the intro lens (and the doubles) for time `t`, then blends it into the rig's lens over the last
## HANDBACK_SEC.
func _apply_shot(t: float, delta: float) -> void:
	var xf: Transform3D
	var fov := INTRO_FOV
	if kind == "a":
		xf = _shot_a(t, delta)
	else:
		xf = _shot_b(t, delta)
	var w := smoothstep(TOTAL_SEC - HANDBACK_SEC, TOTAL_SEC, t)
	if w > 0.0:
		var rx := _rig_cam.global_transform
		var q := xf.basis.get_rotation_quaternion().slerp(rx.basis.get_rotation_quaternion(), w)
		xf = Transform3D(Basis(q), xf.origin.lerp(rx.origin, w))
		fov = lerpf(INTRO_FOV, _rig_cam.fov, w)
	_cam.global_transform = xf
	_cam.fov = fov
	if kind == "a" and not _double_hidden and not _warming and _double != null:
		var helmet := _frame_at(_walk_s(t)) * Vector3(0.0, AstronautModel.HELMET_CY, 0.0)
		# At the vanish time found from the path (the same distance test, at the dip's darkest frame).
		if (_t_hide > 0.0 and t >= _t_hide) or xf.origin.distance_to(helmet) < _hide_dist:
			_double_hidden = true
			_cam.cull_mask = _rig_cam.cull_mask & ~DOUBLE_BIT
			_log("double hidden at t=%.3f (lens %.2f m from the helmet centre)" % [t, xf.origin.distance_to(helmet)])
	if _trace:
		var f := -xf.basis.z
		print("[SafariIntro] t=%.3f pos=(%.3f,%.3f,%.3f) fwd=(%.3f,%.3f,%.3f) fov=%.2f w=%.3f" % [t, xf.origin.x,
			xf.origin.y, xf.origin.z, f.x, f.y, f.z, fov, w])


## A lens transform looking along `dir` with the planet's up at `pos`.
func _look(pos: Vector3, dir: Vector3) -> Transform3D:
	var up := safari.planet.up_at(pos)
	var d := dir.normalized()
	if absf(d.dot(up)) > 0.999:
		up = -_rig_cam.global_transform.basis.z
	return Transform3D(Basis.looking_at(d, up), pos)


# ---------------------------------------------------------------------------- option A
func _build_a() -> void:
	var player := safari.player
	_base_xf = player.global_transform
	var model := player.get_model()
	_model_local = _base_xf.affine_inverse() * model.global_transform
	var up := safari.start_dir.normalized()
	_axis = up.cross(safari.start_fwd).normalized()
	_h0 = safari.planet.height_at(up)
	_walk_v = A_WALK_M / (A_WALK_STEADY + 0.5 * (A_WALK_STOP - A_WALK_STEADY))
	_double = AstronautModel.new()
	_double.name = "IntroDouble"
	add_child(_double)
	_double.set_carry_item(brass_camera_mesh(A_CAM_SCALE), Vector3(0.0, 0.0575 * A_CAM_SCALE, 0.0))
	_double.set_state("carry_walk")
	# The player's own blob shadow, copied (Compatibility draws no cast shadows: without it he floats).
	var src := player.get_node_or_null("BlobShadow") as MeshInstance3D
	if src != null:
		_shadow = MeshInstance3D.new()
		_shadow.name = "IntroShadow"
		_shadow.mesh = src.mesh
		_shadow.material_override = src.material_override
		_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_shadow_local = _base_xf.affine_inverse() * src.global_transform
		add_child(_shadow)
	for gi: Node in _geometry(self, []):
		if gi != _cam:
			(gi as GeometryInstance3D).layers = DOUBLE_BIT


## Metres along the start heading from the start (negative = behind) at time `t`.
func _walk_s(t: float) -> float:
	var tc := A_WALK_STEADY
	var td := A_WALK_STOP - A_WALK_STEADY
	var d: float
	if t <= tc:
		d = _walk_v * t
	elif t < A_WALK_STOP:
		var u := (t - tc) / td
		d = _walk_v * tc + _walk_v * td * (u - 0.5 * u * u)
	else:
		d = A_WALK_M
	return d - A_WALK_M


func _walk_speed(t: float) -> float:
	if t <= A_WALK_STEADY:
		return _walk_v
	if t >= A_WALK_STOP:
		return 0.0
	return _walk_v * (1.0 - (t - A_WALK_STEADY) / (A_WALK_STOP - A_WALK_STEADY))


## The real player's body frame carried `s` metres along the start heading over the sphere (feet on the
## ground there, up = the planet's up, -Z = the heading there). At s = 0 it IS the player's frame.
func _frame_at(s: float) -> Transform3D:
	var p := safari.planet
	var c := p.global_position
	var rot := Basis(_axis, s / p.radius)
	var o := c + rot * (_base_xf.origin - c)
	var d := (o - c).normalized()
	o += d * (p.height_at(d) - _h0)
	return Transform3D(rot * _base_xf.basis, o)


func _shot_a(t: float, delta: float) -> Transform3D:
	var frame := _frame_at(_walk_s(t))
	if _double != null:
		_double.global_transform = frame * _model_local
		var v := _walk_speed(t)
		_double.set_state("carry_walk" if v > 0.05 else "carry_idle")
		_double.tick(delta, v / Player.WALK_SPEED)
		if _shadow != null:
			_shadow.global_transform = frame * _shadow_local
	var phi: float
	var r: float
	var h: float
	var look_y := 1.0
	var lead := 0.0
	if t <= A_ORBIT_END:
		var e := smoothstep(0.0, 1.0, t / A_ORBIT_END)
		phi = deg_to_rad(lerpf(A_PHI0_DEG, 180.0, e))
		r = lerpf(A_R0, A_R1, e)
		h = lerpf(A_H0, A_H1, e)
		look_y = lerpf(A_LOOK_Y0, AstronautModel.HELMET_CY, e)
		lead = lerpf(A_LEAD0, 0.0, e)
	else:
		var u := clampf((t - A_ORBIT_END) / (A_PUSH_END - A_ORBIT_END), 0.0, 1.0)
		var e := smoothstep(0.0, 1.0, u)
		phi = PI
		r = lerpf(A_R1, 0.0, e)
		h = lerpf(A_H1, AstronautModel.HELMET_CY, e)
		look_y = AstronautModel.HELMET_CY
	# Azimuth from straight ahead (-Z) toward his left (-X).
	var local := Vector3(-sin(phi) * r, h, -cos(phi) * r)
	var pos := frame * local
	var at_dir := frame * Vector3(0.0, look_y, -lead) - pos
	var end_pitch := deg_to_rad(A_END_PITCH_DEG)
	var end_dir := frame.basis * Vector3(0.0, sin(end_pitch), -cos(end_pitch))
	var dir: Vector3
	if t <= A_ORBIT_END:
		dir = at_dir
	else:
		var k := smoothstep(0.0, 1.0, (t - A_ORBIT_END) / (A_PUSH_END - A_ORBIT_END))
		if at_dir.length() < 0.05:
			dir = end_dir
		else:
			dir = at_dir.normalized().lerp(end_dir.normalized(), k)
	return _look(pos, dir)


## Option A's double holds the cockpit's brass camera. CockpitProps._camera_prop is not reachable on its own
## (it writes into the cockpit's shared room mesh at the dash's spot, with a yaw and a strap lying on the
## dash), so this is the same camera - the cockpit's pieces, sizes and colours, on its room material - built
## alone, centred, the lens facing -Z (away from the chest), `k` times the size.
static func brass_camera_mesh(k: float) -> ArrayMesh:
	var kit := PlanetMeshKit.new()
	var c := Vector3.ZERO
	var yaw := Basis(Vector3.UP, PI)
	kit.rounded_box(c, Vector3(0.19, 0.115, 0.095) * k, 0.028 * k, CockpitProps.BRASS, yaw)
	kit.rounded_box(c + yaw * Vector3(0.0, -0.005, 0.0) * k, Vector3(0.195, 0.048, 0.1) * k, 0.02 * k,
		CockpitProps.BRASS_DARK, yaw)
	var lens_basis := yaw * Basis(Vector3.RIGHT, PI * 0.5)
	var front := c + yaw * Vector3(0.02, 0.0, 0.047) * k
	kit.cylinder(front, 0.043 * k, 0.04 * k, 0.042 * k, CockpitProps.BRASS_DARK, lens_basis, 20)
	kit.cylinder(front + yaw * Vector3(0.0, 0.0, 0.042) * k, 0.038 * k, 0.038 * k, 0.01 * k, CockpitProps.LENS,
		lens_basis, 20)
	kit.torus(front + yaw * Vector3(0.0, 0.0, 0.047) * k, 0.038 * k, 0.008 * k, CockpitProps.BRASS, lens_basis, 20)
	kit.rounded_box(c + yaw * Vector3(-0.052, 0.072, 0.0) * k, Vector3(0.048, 0.034, 0.048) * k, 0.012 * k,
		CockpitProps.BRASS_DARK, yaw)
	kit.cylinder(c + yaw * Vector3(0.056, 0.057, -0.01) * k, 0.013 * k, 0.013 * k, 0.02 * k, CockpitProps.KNOB, yaw, 10)
	kit.sphere(c + yaw * Vector3(0.07, 0.053, 0.033) * k, 0.03 * k, CockpitProps.BRASS_DARK.darkened(0.25),
		Vector3(1.2, 0.45, 1.0), 10, yaw)
	kit.sphere(c + yaw * Vector3(0.045, 0.06, 0.043) * k, 0.016 * k, Color("#d8c08c"), Vector3(1.4, 0.3, 0.8), 8, yaw)
	var m := kit.commit()
	m.surface_set_material(0, CockpitProps.room_material())
	return m


# ---------------------------------------------------------------------------- option B
## One shot of the tour, compiled once from the world script's data (no per-frame allocation after).
class Shot:
	var dirs: Array[Vector3] = []
	var arcs := PackedFloat32Array()
	var h0 := 1.5
	var h1 := 1.5
	var secs := 1.5
	var t0 := 0.0
	var ease := 0            # 0 linear, 1 ease out (arrive), 2 ease in and out
	var look_from := Vector3.ZERO
	var look_to := Vector3.ZERO
	var from_fp := false     # "fp": the safari's own first-person direction
	var to_fp := false
	var emote := ""


## Reads the world script's `intro_shots()` (see worlds/zorp.gd, THE SAFARI INTRO'S TOUR) into world-space
## paths once, so the per-frame step only interpolates.
func _build_b() -> void:
	var content: Object = safari.get("_content")
	var raw: Array = content.call("intro_shots") if content != null else []
	var t0 := 0.0
	for i in raw.size():
		var r: Dictionary = raw[i]
		var sh := Shot.new()
		for p: Vector2 in r.get("path", []):
			sh.dirs.append(safari.dir_from_start(p.x, p.y))
		sh.arcs.append(0.0)
		for j in range(1, sh.dirs.size()):
			sh.arcs.append(sh.arcs[j - 1] + sh.dirs[j - 1].angle_to(sh.dirs[j]))
		var hv: Vector2 = r.get("height", Vector2(1.5, 1.5))
		sh.h0 = hv.x
		sh.h1 = hv.y
		sh.secs = float(r.get("secs", 1.5))
		sh.ease = {"linear": 0, "out": 1, "inout": 2}.get(str(r.get("ease", "linear")), 0)
		var lf: Variant = r.get("look_from", "fp")
		var lt: Variant = r.get("look_to", "fp")
		sh.from_fp = not (lf is Vector3)
		sh.to_fp = not (lt is Vector3)
		if not sh.from_fp:
			sh.look_from = _look_point(lf as Vector3)
		if not sh.to_fp:
			sh.look_to = _look_point(lt as Vector3)
		sh.t0 = t0
		_cuts.append(t0)
		t0 += sh.secs
		_shots.append(sh)
		var cast: Variant = r.get("cast")
		if cast is Dictionary and str((cast as Dictionary).get("npc", "")) == "zorp":
			_build_zorp(sh, cast as Dictionary)
			_zorp_shot = i
	_build_card_text()
	if absf(t0 - TOTAL_SEC) > 0.01:
		push_warning("SafariIntro: %s's intro shots last %.2f s, not %.2f" % [safari.planet_id, t0, TOTAL_SEC])


## Vector3(around_deg, bearing_deg, lift_m) from the start -> a world point.
func _look_point(v: Vector3) -> Vector3:
	return safari.ground_point(safari.dir_from_start(v.x, v.y), v.z)


func _build_zorp(sh: Shot, cast: Dictionary) -> void:
	var at: Vector2 = cast.get("at", Vector2.ZERO)
	var p := safari.planet
	var bed := safari.dir_from_start(at.x, at.y)
	var cam_end := sh.dirs[sh.dirs.size() - 1]
	# Beside the bed, toward where the shot's lens ends, facing it - on a spot clear of the plants.
	var toward := (cam_end - bed * cam_end.dot(bed)).normalized()
	var axis := bed.cross(toward).normalized()
	var stand := bed.rotated(axis, float(cast.get("out_m", 0.9)) / p.radius).normalized()
	if p.nearest_prop_distance(stand) < 0.45:
		for k: float in [0.6, -0.6, 1.2, -1.2]:
			var cand := stand.rotated(toward, k / p.radius).normalized()
			if p.nearest_prop_distance(cand) >= 0.45:
				stand = cand
				break
	var g := p.surface_point(stand)
	var up := p.up_at(g)
	var face := p.surface_point(cam_end) - g
	face -= up * face.dot(up)
	_zorp = NpcModels.make("zorp")
	_zorp.name = "IntroZorp"
	add_child(_zorp)
	_zorp.global_transform = Transform3D(Basis.looking_at(face.normalized(), up), g)
	_zorp.visible = false
	sh.emote = str(cast.get("emote", "wave"))


func _shot_b(t: float, delta: float) -> Transform3D:
	var i := _cuts.size() - 1
	while i > 0 and t < _cuts[i]:
		i -= 1
	var sh: Shot = _shots[i]
	var u := clampf((t - sh.t0) / sh.secs, 0.0, 1.0)
	var e := u
	if sh.ease == 1:
		e = 1.0 - (1.0 - u) * (1.0 - u)
	elif sh.ease == 2:
		e = smoothstep(0.0, 1.0, u)
	var n := sh.dirs.size()
	var d := sh.dirs[0]
	if n > 1:
		var want := e * sh.arcs[n - 1]
		var j := 0
		while j < n - 2 and want > sh.arcs[j + 1]:
			j += 1
		var seg := maxf(sh.arcs[j + 1] - sh.arcs[j], 1e-6)
		d = sh.dirs[j].slerp(sh.dirs[j + 1], clampf((want - sh.arcs[j]) / seg, 0.0, 1.0))
	var pos := safari.ground_point(d, lerpf(sh.h0, sh.h1, e))
	var fp_dir := -_rig_cam.global_transform.basis.z
	var k := smoothstep(0.0, 1.0, e)
	var dir: Vector3
	if sh.from_fp and sh.to_fp:
		dir = fp_dir
	elif sh.to_fp:
		dir = (sh.look_from - pos).normalized().lerp(fp_dir, k)
	elif sh.from_fp:
		dir = fp_dir.lerp((sh.look_to - pos).normalized(), k)
	else:
		dir = sh.look_from.lerp(sh.look_to, e) - pos
	# Zorp's double is only in his own shot, waving from its first frame.
	if _zorp != null and _warming:
		_zorp.visible = i == _zorp_shot
	elif _zorp != null:
		var on := i == _zorp_shot
		if on != _zorp.visible:
			_zorp.visible = on
			if on:
				_zorp.call("set_state", sh.emote)
		if on:
			_zorp.call("tick", delta, 0.0)
	return _look(pos, dir)


# ======================================================================================== THE CARD
func _build_card() -> void:
	_card_layer = CanvasLayer.new()
	_card_layer.name = "IntroCard"
	_card_layer.layer = CARD_LAYER
	add_child(_card_layer)
	_card_root = Control.new()
	_card_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_layer.add_child(_card_root)
	_black = ColorRect.new()
	_black.color = Color(UIStyle.NAVY, 1.0)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(_black)
	if skippable:
		# CockpitOverlay's Skip pill, the same look and the same place.
		_skip = Button.new()
		_skip.name = "SkipButton"
		_skip.text = "Skip"
		_skip.focus_mode = Control.FOCUS_NONE
		_skip.mouse_filter = Control.MOUSE_FILTER_STOP
		_skip.add_theme_stylebox_override("normal",
			UIStyle.make_pill_style(Color(0.09, 0.10, 0.20, 0.62), Color(0.55, 0.58, 0.72, 0.5), 2, 0, 22.0, 8.0))
		_skip.add_theme_stylebox_override("hover",
			UIStyle.make_pill_style(Color(0.13, 0.14, 0.26, 0.75), Color(0.70, 0.72, 0.85, 0.7), 2, 0, 22.0, 8.0))
		_skip.add_theme_stylebox_override("pressed",
			UIStyle.make_pill_style(Color(0.18, 0.19, 0.32, 0.85), Color(0.80, 0.82, 0.92, 0.8), 2, 0, 22.0, 8.0))
		_skip.add_theme_color_override("font_color", Color("#dfe2ee"))
		_skip.add_theme_color_override("font_hover_color", Color("#ffffff"))
		_skip.add_theme_color_override("font_pressed_color", Color("#ffffff"))
		_skip.add_theme_font_override("font", UIStyle.ui_font())
		_skip.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_BODY, 26.0)))
		_skip.visible = false
		_skip.pressed.connect(_on_skip_button)
		_card_root.add_child(_skip)
	_card_root.resized.connect(_layout)
	_layout()


## Option B's name card: the planet's own name and the world's subtitle, centred in the upper third (clear of
## a landscape phone's notch at the sides and of the thumbs at the bottom corners).
func _build_card_text() -> void:
	var content: Object = safari.get("_content")
	var pd: PlanetData = safari.planet.data
	var name_text := pd.display_name if pd != null else safari.planet_id.capitalize()
	if content != null and content.has_method("intro_title_style"):
		# The planet's own lettering (src/planet_safari/title_lettering.gd), built once here.
		var st: Dictionary = content.call("intro_title_style")
		var title_lines := PackedStringArray(st.get("lines", [name_text.to_upper()]))
		_lettering = TitleLettering.new()
		_lettering.name = "TitleLettering"
		_card_root.add_child(_lettering)
		_lettering.build(title_lines, st)
		_lettering.set_strength(0.0)
	else:
		_title = _card_label(name_text, 56, 10)
		_title.modulate.a = 0.0
	var sub := ""
	if content != null and content.has_method("intro_subtitle"):
		sub = str(content.call("intro_subtitle"))
	_sub = _card_label(sub, 30, 7)
	_sub.modulate.a = 0.0
	# Above the black, under the Skip pill.
	if _skip != null:
		_card_root.move_child(_skip, -1)
	_layout()


func _card_label(text: String, size: int, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UIStyle.CREAM)
	l.add_theme_color_override("font_outline_color", Color(UIStyle.NAVY, 0.85))
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_shadow_color", Color(UIStyle.NAVY, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	_card_root.add_child(l)
	return l


func _layout() -> void:
	if _card_root == null:
		return
	var vp := _card_root.size
	if _lettering != null:
		# Centred in the middle of the screen, as big as fits TITLE_MAX_H x TITLE_MAX_W (subtitle included).
		var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
		var avail_w := (vp.x - safe.x - safe.z) * TITLE_MAX_W
		_sub.size = Vector2(vp.x, 0.0)
		_sub.reset_size()
		_sub.size.x = vp.x
		var sub_h := _sub.size.y
		var bs := _lettering.block_size
		_title_fit = minf((vp.y * TITLE_MAX_H - sub_h - 14.0) / maxf(bs.y, 1.0), avail_w / maxf(bs.x, 1.0))
		var block_h := bs.y * _title_fit + 14.0 + sub_h
		var cx := safe.x + (vp.x - safe.x - safe.z) * 0.5
		var top := vp.y * TITLE_CENTER_Y - block_h * 0.5
		_lettering.position = Vector2(cx, top + bs.y * _title_fit * 0.5)
		_lettering.scale = Vector2.ONE * _title_fit
		_sub.position = Vector2(cx - vp.x * 0.5, top + bs.y * _title_fit + 14.0)
	elif _title != null:
		_title.size = Vector2(vp.x, 0.0)
		_title.reset_size()
		_title.size.x = vp.x
		_title.position = Vector2(0.0, vp.y * 0.10)
		_sub.size = Vector2(vp.x, 0.0)
		_sub.reset_size()
		_sub.size.x = vp.x
		_sub.position = Vector2(0.0, _title.position.y + _title.size.y - 6.0)
	if _skip != null:
		var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
		# 44 pt minimum: the canvas is 720 rows tall, an iPhone landscape screen ~390 pt (CockpitOverlay).
		var h := MobileUI.pick(52.0, SKIP_MIN_PT * 720.0 / 390.0)
		_skip.custom_minimum_size = Vector2(h * 1.9, h)
		_skip.reset_size()
		_skip.position = Vector2(vp.x - _skip.size.x - 24.0 - safe.z, vp.y - _skip.size.y - 22.0 - safe.w)


## The black (the lift, option B's dips), the name card, and SafariLayer's controls fading in at the end.
func _apply_overlays(t: float) -> void:
	var a := 1.0 - smoothstep(0.0, LIFT_SEC, t)
	if kind == "a" and _t_hide > 0.0:
		var dip := smoothstep(_t_hide - A_DIP_IN, _t_hide, t) if t <= _t_hide \
			else 1.0 - smoothstep(_t_hide, _t_hide + A_DIP_OUT, t)
		a = maxf(a, dip)
	if kind == "b":
		var half := DIP_SEC * 0.5
		for k in range(1, _cuts.size()):
			var dt := absf(t - _cuts[k])
			if dt < half:
				a = maxf(a, 1.0 - smoothstep(0.0, half, dt))
		var out := 1.0 - smoothstep(TOTAL_SEC - CARD_OUT_SEC, TOTAL_SEC, t)
		if _lettering != null:
			_title_alpha = title_alpha(t)
			_lettering.set_strength(_title_alpha)
			_lettering.visible = _title_alpha > 0.0
			_lettering.scale = Vector2.ONE * _title_fit * (1.0 + TITLE_GROW * smoothstep(TITLE_HOLD_END, TITLE_GONE, t))
			_sub.modulate.a = smoothstep(SUB_IN.x, SUB_IN.y, t) * _title_alpha
			_sub.visible = _sub.modulate.a > 0.0
		elif _title != null:
			_title.modulate.a = smoothstep(0.0, LIFT_SEC, t) * out
			_sub.modulate.a = smoothstep(LIFT_SEC * 0.9, LIFT_SEC * 2.0, t) * out
	_black.color.a = a
	if t >= TOTAL_SEC - UI_FADE_SEC and _ui_root != null:
		if not _ui_shown:
			_ui_shown = true
			_ui_root.modulate.a = 0.0
			safari.layer.show_awake_ui(true)
		_ui_root.modulate.a = smoothstep(TOTAL_SEC - UI_FADE_SEC, TOTAL_SEC, t)


# ======================================================================================== THE END
## Everything this node changed, put back: the rig's lens current, our nodes gone, the controls shown and
## opaque, the modal closed. Safe to call twice and from `_exit_tree`.
func _teardown() -> void:
	if _cam != null and is_instance_valid(_cam):
		if _cam.current and _rig_cam != null and is_instance_valid(_rig_cam):
			_rig_cam.current = true
		_cam.current = false
		_cam.queue_free()
	_cam = null
	for n: Node in [_double, _shadow, _zorp, _card_layer]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_double = null
	_shadow = null
	_zorp = null
	_card_layer = null
	_skip = null
	if _ui_root != null and is_instance_valid(_ui_root):
		_ui_root.modulate.a = 1.0
	if _modal_open:
		_modal_open = false
		# A scene change has already cleared every modal (EventBus.reset_modals): only close ours if it is open.
		if EventBus.modal_counts().has(MODAL):
			EventBus.ui_modal_closed.emit(MODAL)


func _finish(skipped: bool) -> void:
	if _done:
		return
	_done = true
	_running = false
	if is_instance_valid(safari) and safari.layer != null:
		safari.layer.show_awake_ui(true)
	_teardown()
	GameState.flags[SEEN_FLAG_PREFIX + kind] = true
	_log("done kind=%s skipped=%s t=%.3f" % [kind, str(skipped), _t])
	done.emit(skipped)
	queue_free()


func _exit_tree() -> void:
	if _done:
		return
	aborted = true
	_done = true
	_running = false
	_teardown()
	done.emit(true)


# ======================================================================================== SKIP
func _on_skip_button() -> void:
	if not skippable or not _running or _done or _skipping or _confirming or _t < SKIP_ARM_SEC:
		return
	_ask_skip()


func _ask_skip() -> void:
	if _confirming or _skipping or _done:
		return
	_confirming = true
	if _skip != null:
		_skip.visible = false
	var go: bool = await SkipConfirm.ask(self, "Skip the intro?", "Skip", "Keep watching")
	_confirming = false
	if _done or not is_inside_tree() or _skipping:
		return
	if not go:
		for a in SKIP_ACTIONS:
			_skip_held[a] = Input.is_action_pressed(a)
		return
	_skipping = true
	_log("skip confirmed at t=%.3f" % _t)
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 1.0, SKIP_DIP_SEC)
	await tw.finished
	if _done or not is_inside_tree():
		return
	# The end state, behind the black: the rig's lens, the doubles gone, the card gone, the controls up.
	if _title != null:
		_title.visible = false
	if _lettering != null:
		_lettering.queue_free()
		_lettering = null
	if _sub != null:
		_sub.visible = false
	if _skip != null:
		_skip.visible = false
	if _rig_cam != null and is_instance_valid(_rig_cam):
		_rig_cam.current = true
	for n: Node in [_double, _shadow, _zorp]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_double = null
	_shadow = null
	_zorp = null
	safari.layer.show_awake_ui(true)
	if _ui_root != null:
		_ui_root.modulate.a = 1.0
	var tw2 := create_tween()
	tw2.tween_property(_black, "color:a", 0.0, SKIP_LIFT_SEC)
	await tw2.finished
	if not is_inside_tree():
		return
	_finish(true)


## Keys and pad buttons open the same pop-up (only when skipping is offered). Clicks and taps do not: only
## the Skip pill (a Button) takes those.
func _input(event: InputEvent) -> void:
	if not skippable or not _running or _done or _skipping or _confirming or _t < SKIP_ARM_SEC:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo or k.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
		get_viewport().set_input_as_handled()
		_ask_skip()
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		get_viewport().set_input_as_handled()
		_ask_skip()


## The action half, for Director timelines (`Input.action_press` sends no InputEvent): CockpitIntro's edges.
func _physics_process(_delta: float) -> void:
	if not skippable or not _running or _done or _skipping or _confirming:
		return
	var edge := false
	for a in SKIP_ACTIONS:
		var now := Input.is_action_pressed(a)
		if now and not bool(_skip_held.get(a, false)) and _skip_primed and _t >= SKIP_ARM_SEC:
			edge = true
		_skip_held[a] = now
	_skip_primed = true
	if edge:
		_ask_skip()


# ======================================================================================== HELPERS
## Option B's title strength at time `t` (see TITLE_IN_END and the constants after it).
static func title_alpha(t: float) -> float:
	if t <= TITLE_IN_END:
		return smoothstep(0.0, TITLE_IN_END, t)
	if t <= TITLE_HOLD_END:
		return 1.0
	if t <= TITLE_DRIFT_END:
		return lerpf(1.0, TITLE_DRIFT_ALPHA, smoothstep(TITLE_HOLD_END, TITLE_DRIFT_END, t))
	if t <= TITLE_LINGER_END:
		return lerpf(TITLE_DRIFT_ALPHA, TITLE_LINGER_ALPHA, (t - TITLE_DRIFT_END) / (TITLE_LINGER_END - TITLE_DRIFT_END))
	if t < TITLE_GONE:
		return lerpf(TITLE_LINGER_ALPHA, 0.0, smoothstep(TITLE_LINGER_END, TITLE_GONE, t))
	return 0.0



## The poses the warm-up draws: option A's opening, mid-orbit and behind-the-head; the middle of each of
## option B's shots.
func _warm_times() -> PackedFloat32Array:
	if kind == "a":
		return PackedFloat32Array([0.0, 1.3, 2.6, 3.0])
	var out := PackedFloat32Array()
	for sh: Shot in _shots:
		out.append(sh.t0 + sh.secs * 0.5)
	return out



func _helmet_radius() -> float:
	var r := AstronautModel.HELMET_R
	return maxf(r.x, maxf(r.y, r.z)) * AstronautModel.HELMET_SCALE


## Half the diagonal field of view of `c` on this viewport (the corner ray's angle from the view axis).
static func _half_diag_fov(c: Camera3D) -> float:
	var th := tan(deg_to_rad(maxf(c.fov, INTRO_FOV)) * 0.5)
	var vp := c.get_viewport()
	var aspect := 16.0 / 9.0
	if vp != null:
		var sz := vp.get_visible_rect().size
		aspect = maxf(sz.x / maxf(sz.y, 1.0), 1.0)
	return atan(th * sqrt(1.0 + aspect * aspect))


## The first time option A's lens comes within _hide_dist of the helmet (the path is fixed, so it is found once).
func _find_hide_time() -> float:
	var t := A_ORBIT_END
	while t <= A_PUSH_END:
		var xf := _shot_a(t, 0.0)
		var helmet := _frame_at(_walk_s(t)) * Vector3(0.0, AstronautModel.HELMET_CY, 0.0)
		if xf.origin.distance_to(helmet) < _hide_dist:
			return t
		t += 1.0 / 240.0
	return A_PUSH_END


## Distance from the eye to a corner of the near plane: a lens closer than helmet radius + this to the
## helmet's centre would cut into the dome.
static func _near_corner(c: Camera3D) -> float:
	var th := tan(deg_to_rad(maxf(c.fov, INTRO_FOV)) * 0.5)
	var vp := c.get_viewport()
	var aspect := 16.0 / 9.0
	if vp != null:
		var s := vp.get_visible_rect().size
		aspect = maxf(s.x / maxf(s.y, 1.0), 1.0)
	return c.near * sqrt(1.0 + th * th + th * th * aspect * aspect)


func _geometry(n: Node, out: Array) -> Array:
	for c in n.get_children():
		if c is GeometryInstance3D:
			out.append(c)
		_geometry(c, out)
	return out


func _log(msg: String) -> void:
	print("[SafariIntro] " + msg)


## For tests: one line of plain values.
func debug_state() -> Dictionary:
	return {"kind": kind, "t": _t, "running": _running, "done": _done, "confirming": _confirming,
		"skipping": _skipping, "skippable": skippable, "lifting": _running and _t > 0.0,
		"double_hidden": _double_hidden, "skip_visible": _skip != null and is_instance_valid(_skip) and _skip.visible,
		"cam_current": _cam != null and is_instance_valid(_cam) and _cam.current,
		"title_alpha": _title_alpha,
		"title_drawn": _lettering != null and is_instance_valid(_lettering) and _lettering.is_visible_in_tree()}


func debug_skip_rect() -> Rect2:
	if _skip == null or not is_instance_valid(_skip) or not _skip.visible:
		return Rect2()
	return _skip.get_global_rect()
