extends Node
## THE GIFT (docs/PHASE5_SPEC.md §2 "Gift", §3 GIFT, §6, §7; docs/BUILD_PLAN.md Phase 5 builder G).
## finale.gd instances this by path as /root/World/FinaleGift once FinaleLaunch has finished, calls
## `play(meeting)` and awaits `finished`. Nothing here names another finale class: FinaleState, the
## lines, the meeting, the pad and the launch are all reached by path or through `has_method`.
##
## WHAT HAPPENS
##   open     the camera stays on the frame the send-off ended on (the meeting's camera, the crowd's
##            upturned faces, the pad behind the lens). DJ Nova, then Zorp's "One more! Did you see?" /
##            "Okay. Don't look at the pad." play over it.
##   lump     every frame the pad's volume (deck ring 2.7 m out, 3 m up) is tested against the frustum
##            of the camera actually drawing. Once it has been outside for LUMP_OUT_S (wall clock), the
##            skiff - built hidden at the pad's rest pose at `play`, outside the pad's subtree (see
##            `_build_skiff`) - and the tarp over it are shown, out of view.
##            Zorp's "...Now look at the pad!" waits for that. Grig and Bolt set off for the lump then.
##   reveal   the camera turns to the lump; Grig and Bolt take a side each; the tarp slides back off the
##            skiff and scales to nothing (`skiff_reveal`). It never fades and nothing toggles in view:
##            the tarp is hidden only once its scale is 0.
##   pieces   the Professor, then each friend over a shot that frames their own piece of the skiff
##            (hatch, antenna, lamp, ladder, dish) above the dialogue box, with the whole skiff in frame;
##            the astronaut walks to the hand-back spot, 5.5 m from the pad (outside Fly's 4.2 m reach),
##            during the Professor's first box. The Professor's last box is framed on the gameplay
##            camera's own settled pose behind the astronaut (`_read_rig_pose`).
##   done     after the Professor's last box: FinaleState.finish_story() (stage 4, the ship flag,
##            story_done, one campaign_changed, the clock runs again, the checkpoint save),
##            rocket_pad.adopt_model(skiff), the astronaut turns back to the skiff while the gameplay
##            camera lets go of the box's focus (0.9 s), a 1.1 s blend onto it, control back, the §3
##            toast, `finished`. So DONE is on disk before the first frame the astronaut can move.
##
## SHOTS. Every framing is a `meeting.camera_to_transform` (the meeting's own clock-driven blend and its
## speed limits), solved once at `play` over candidate eyes round the skiff and cached: each piece's
## sample points must sit inside the frame and above the dialogue box, face the lens, and have clear
## sight lines past the skiff's own body, the crowd, the astronaut, the pad's mast and the physics world
## (terrain, decorations, buildings) and every visible mesh near the skiff (its box), with no body near
## the lens; near meshes and friends may cover at most FG_MAX_SHARE of the frame above the box and
## FG_MAX_COVER of the skiff. Of up to PASS_KEEP passing framings, the cheapest move from the previous shot
## plus its clutter wins. A friend's box opens only once the camera has settled on their shot (CAM_WAIT_MAX).
##
## NIGHT. The meeting holds the clock at night from the Commons load; this node only checks it (and holds
## it itself if something let it run) until DONE, where finish_story sets it running again.
##
## SKIPS. The gift has no skip: every beat is a tap-through dialogue box, and the one non-box motion
## (the tarp pull) lasts PULL_S. If one is ever added it must ask first through
## res://src/ui/common/skip_confirm.gd.
##
## TRACE. `--finale-trace=<file>` gets "GIFT ..." lines through FinaleState.trace: every pad in/out
## change of the frustum test with its wall-clock ms, the lump's appearance with how long the pad had
## been out, each beat, and DONE. The same lines are printed to stdout.
##
## HEAT (§7). The skiff (M1's model, only materials the rocket draws) replaces the hidden rocket; the tarp
## is one MeshInstance3D on a material the Commons already draws (the deco store's awning cloth, found
## in the world, or the same cached preset), no shadow, freed after the pull.

signal finished

const TRACE_TAG := "GIFT"
const MODAL_NAME := "cutscene"
const FINALE_STATE_PATH := "res://src/campaign/finale_state.gd"
const LINES_PATH := "res://src/campaign/finale_lines.gd"
const ROCKET_SCENE_PATH := "res://src/rocket/rocket_model.tscn"
const VISITOR_SYSTEM_PATH := "res://src/campaign/visitor_system.gd"

# ------------------------------------------------------------------------------------ pacing
const LUMP_OUT_S := 4.0
## Beyond the minimum: the lump waits for the pad to have been out this much longer, so a frame of
## rounding never lands exactly on the gate.
const LUMP_MARGIN_S := 0.10
## If the pad is still in view this long after Zorp's second box, the camera turns away from it.
const LUMP_FALLBACK_S := 2.5
## ...and if the turned frame still sees it this long after the box, the camera looks up at the sky.
const LUMP_SKY_S := 9.0
const CAM_WAIT_MAX := 4.0
const PULLERS_WAIT_MAX := 7.0
const PULL_S := 1.5
const PULL_BACK_M := 1.9
const PULL_LIFT_M := 0.55
const HANDBACK_S := 1.1
const MAX_STEP := 0.05
const WALK_MPS := 1.9
const WALK_SPEED_FACTOR := 0.5
const TURN_S := 0.45

# ------------------------------------------------------------------------------------ geometry
## The pad's volume for the frustum test: the deck ring (PAD_R 2.55 plus a margin) from the deck to
## above the tarp's top.
const PAD_TEST_R := 2.7
const PAD_TEST_H := 3.0
const PAD_TEST_SIDES := 10
## "Control returns 4.5-6.5 m from the pad (outside Fly reach 4.2)".
const CONTROL_M := 5.5
const PULLER_R := 2.95
const PULLER_WAYPOINT_R := 3.6
## A walk whose straight line comes nearer the pad's centre than this goes round by a waypoint instead.
const PAD_WALK_CLEAR_M := 2.75
## Grig and Bolt's side angles from the reveal camera's bearing, tried in order.
const PULLER_ANGLES: Array[float] = [60.0, 50.0, 72.0, 85.0, 40.0, 100.0]
const MAST_CLEAR_M := 1.1
## The tarp's profile in the skiff's own frame (radius, height), bottom to top: it clears the legs'
## pads (r 1.14), the lamp hood (r ~1.25 at 1.5 m), the dish (r ~1.1 at 2.0 m) and the antenna bulb
## (r 0.76 at 2.3 m) with room for its folds; its foot is sunk under the deck's curve.
const TARP_PROFILE: Array[Vector2] = [Vector2(1.66, -0.12), Vector2(1.62, 0.20), Vector2(1.55, 0.80),
	Vector2(1.47, 1.40), Vector2(1.38, 1.85), Vector2(1.22, 2.15), Vector2(0.97, 2.40), Vector2(0.56, 2.60),
	Vector2(0.0, 2.68)]
const TARP_SIDES := 14
const TARP_FOLD := 0.055
const TARP_A := Color("#6e6552")
const TARP_B := Color("#635a48")
const TARP_INNER := Color("#3f392f")
const TARP_ROPE := Color("#463d31")
## The Commons' awning cloth (deco_store.gd AWNING_OPTS), used when the node itself is not found.
const AWNING_OPTS := {"pitch_b": 2.12, "seam_strength": 1.5}

# ------------------------------------------------------------------------------------ shots
## The dialogue box on the phone frame (finale_meeting.gd BOX_TOP_Y / BOX_X, measured there).
const BOX_TOP := 0.675
const SAFE_X := Vector2(0.08, 0.92)
const SAFE_Y := Vector2(0.10, 0.62)
const PIECE_FOV := 40.0
const REVEAL_FOV := 44.0
const PIECE_DISTS: Array[float] = [4.0, 4.8, 5.6]
const PIECE_HEIGHTS: Array[float] = [0.9, 1.4, 1.9, 2.5]
const REVEAL_DISTS: Array[float] = [5.6, 6.6, 7.6]
const REVEAL_HEIGHTS: Array[float] = [1.5, 2.3, 3.1]
const AZ_STEPS := 24
const MAX_LOOK_DOWN_DEG := 32.0
const LENS_CLEAR_M := 1.3
## A walking puller's body axis keeps this far from every camera eye it could meet on its walk (round-4
## critic: Bolt's straight walk from the crowd came 0.59 m from the lens while the camera travelled to the
## reveal). LENS_CLEAR_M plus a body radius and the stroll's steering slack.
const PULLER_LENS_M := LENS_CLEAR_M + 0.45
const PULLER_BODY_H := 1.45
## The meeting's camera moves in a straight line between shots (finale_meeting.gd _drive): that line keeps
## this far from every standing body axis, so no face fills the lens on the way (round-4 critic re-check:
## per-frame camera-to-NPC >= 1.3 m; r2a measured Grig 1.11 m on the reveal->hatch move without it).
const TRAVEL_CLEAR_M := LENS_CLEAR_M + 0.2
## A move the solve could not keep clear goes by one waypoint (_drive_shot): the goal switches to the shot
## once the camera is this close to the waypoint, so each leg is gated this much wider.
const DETOUR_SWITCH_M := 0.35
const DETOUR_TS: Array[float] = [0.5, 0.35, 0.65, 0.2, 0.8]
const DETOUR_UPS: Array[float] = [0.0, 1.2, 2.0, 2.8, 3.6]
const DETOUR_SIDES: Array[float] = [0.0, 1.5, -1.5, 2.5, -2.5, 3.5, -3.5]
## The switch waits for the camera to reach the waypoint (it brakes there); only a stuck move switches early.
const DETOUR_WAIT_MAX := 12.0
## Leg sample spacing for that test (m).
const PULLER_LENS_STEP := 0.2
const CAND_RAY_TRIES := 140
## Shot search budget per frame (§7: no frame over 50 ms); the search waits a frame when it runs over.
const SLICE_USEC := 6000
## Occluders: meshes this near the skiff, at least this tall along the planet's up, at most this large.
const OCC_REACH_M := 11.0
const OCC_MIN_H := 0.45
const OCC_MAX_SIZE := 18.0
## A mesh's box is shrunk this much before a sight line is tested against it (a rounded shape fills less
## of its box), and nothing but a friend may come nearer the lens than OCC_LENS_M.
const OCC_SHRINK := 0.85
const OCC_LENS_M := 0.7
## Foreground: a near mesh (within FG_SHARE of the way to the subject, at least FG_MIN_M) whose bounding
## disc shows anywhere above the dialogue box is clutter across the shot.
const FG_SHARE := 0.55
const FG_MIN_M := 2.6
## More than this share of the frame above the box covered by near meshes rejects a shot; less is scored
## (FG_WEIGHT seconds of camera travel per whole frame covered).
const FG_MAX_SHARE := 0.10
const FG_WEIGHT := 12.0
## A near mesh or friend may cover at most this share of the skiff's screen rectangle.
const FG_MAX_COVER := 0.06
## Passing candidates a search collects before it picks the best score.
const PASS_KEEP := 8
## meeting camera limits (finale_meeting.gd CAM_VMAX, CAM_WMAX): the effort score of a move.
const CAM_VMAX := 2.35
const CAM_WMAX := 33.0

## Each friend's piece: skiff-local sample points (the first is its centre), the outward normal it is
## seen along, and the least dot of that normal with the direction to the lens. Positions from
## skiff_mesh_lib.gd (hatch door, lamp lens, ladder, dish frame, antenna bulb).
const PIECE_OF := {"bolt": "hatch", "zorp": "antenna", "fen": "lamp", "grig": "ladder", "vela": "dish"}

enum Phase { IDLE, OPEN, LUMP, REVEAL, PIECES, DONE }

var _meeting: Node
var _world: Node
var _planet: Planet
var _pad: Node3D
var _pad_root: Node3D
var _old_rocket: Node3D
var _skiff: Node3D
var _tarp: MeshInstance3D
var _player: Node3D
var _rig: Node
var _env: Node
var _lines: Script
var _phase: int = Phase.IDLE
var _modal := false
var _clock_held := false
var _saved_time_scale := 1.0
var _trace_on := false
var _t := 0.0

var _skiff_xf := Transform3D.IDENTITY
var _up := Vector3.UP
var _hatch_dir := Vector3.FORWARD
var _mast_pos := Vector3.ZERO
var _mast_up := Vector3.UP
var _has_mast := false
var _blocker_rids: Array[RID] = []
var _aspect := 1560.0 / 720.0

var _pad_in_view := true
var _pad_out_ms := -1
var _lump_shown := false
var _lump_ms := -1
var _frustum_changes := 0

var _control := Vector3.ZERO
var _control_dir := Vector3.UP
var _pullers: Dictionary = {}
var _puller_wps: Dictionary = {}
var _pullers_sent := false
var _sent: Dictionary = {}
var _reveal_issued := false
var _detouring := false
var _detour_goal := Vector3.ZERO
var _shot_serial := 0
var _detour_why: Dictionary = {}
var _puller_lens_min := INF
var _puller_lens_warned := false
var _arrived: Dictionary = {}
var _turned_away := false
var _looked_up := false
var _shots: Dictionary = {}
var _notes: PackedStringArray = PackedStringArray()
var _walking := false
var _campaign_changes := 0
var _story_done := false
var _vs: Node
var _vs_ready := false
## Visible meshes near the skiff that can stand between a lens and a piece: [name, inverse transform,
## local box, world centre, bounding radius].
var _occ: Array = []
var _stage: Node3D
var _blocker_layer := -1
var _solve_budget_end := 0


# ============================================================================= public API
## Plays the gift. `meeting` is the FinaleMeeting (any Node; its API is used through has_method).
func play(meeting: Node) -> void:
	if _phase != Phase.IDLE:
		return
	_phase = Phase.OPEN
	if not is_inside_tree():
		push_warning("FinaleGift.play: not in the tree")
		finished.emit.call_deferred()
		return
	_meeting = meeting
	for a: String in OS.get_cmdline_user_args():
		_trace_on = _trace_on or a.begins_with("--finale-trace=")
	# Before anything else, in the frame the launch handed control back: the astronaut never moves.
	_begin_modal()
	if not _resolve():
		_beat("a piece of the world is missing (planet/pad/player/meeting); finishing without the gift")
		_finish_story()
		_end_modal()
		finished.emit.call_deferred()
		return
	EventBus.campaign_changed.connect(_on_campaign_changed)
	_check_night("play")
	await _wait_for_pad_arrival()
	if not is_inside_tree():
		return
	var u0 := Time.get_ticks_usec()
	_build_skiff()
	_build_tarp()
	var u1 := Time.get_ticks_usec()
	_beat("play stage=%d hour=%.2f time_scale=%s cam=%s skiff=%s tarp_mat=%s set-up %.1f ms" % [
		_fs_int("stage"), GameState.time_of_day, str(_env.get("time_scale")) if _env != null else "-",
		_cam_name(), str(_skiff != null), _notes[-1] if not _notes.is_empty() else "-", (u1 - u0) / 1000.0])
	var cam0 := get_viewport().get_camera_3d()
	if cam0 != null:
		_beat("frustum sanity: pad centre is_position_in_frustum=%s, plane test in=%s" % [
			str(cam0.is_position_in_frustum(_skiff_xf.origin + _up * 1.0)), str(_pad_volume_in_frustum(cam0))])
	set_process(true)
	# The debug entry (debug_start_gift) and a missing launch leave the gameplay camera drawing: take the
	# meeting's, and frame the crowd from the astronaut's side, away from the pad.
	var cam := get_viewport().get_camera_3d()
	var mcam := _meeting.call("camera") as Camera3D if _meeting.has_method("camera") else null
	if mcam != null and cam != mcam and _meeting.has_method("camera_to"):
		var s := float(_meeting.call("camera_to", "W", []))
		_beat("opening camera was %s, not the meeting's: camera_to W (%.1f s)" % [str(cam.name) if cam != null else "-", s])
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_crowd_face_point(_player.global_position + _up * 1.2)
	await _solve_all()
	if not is_inside_tree():
		return
	await _run()


func is_running() -> bool:
	return _phase != Phase.IDLE and _phase != Phase.DONE


func phase_name() -> String:
	return Phase.keys()[_phase]


# ============================================================================= set-up
func _resolve() -> bool:
	_world = get_tree().root.get_node_or_null("World")
	if _world == null or _meeting == null or not is_instance_valid(_meeting):
		return false
	_planet = _world.get_node_or_null("Planet") as Planet
	_pad = _world.get_node_or_null("Rocket") as Node3D
	_pad_root = _pad.get_node_or_null("Pad") as Node3D if _pad != null else null
	_old_rocket = _pad.get("rocket") as Node3D if _pad != null else null
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_rig = _world.get_node_or_null("CameraRig")
	_env = _world.get_node_or_null("Environment")
	_lines = load(LINES_PATH) as Script if ResourceLoader.exists(LINES_PATH) else null
	if _planet == null or _pad == null or _pad_root == null or _player == null or _lines == null:
		return false
	var vr := get_viewport().get_visible_rect().size
	_aspect = vr.x / maxf(vr.y, 1.0)
	return true


## A load that lands on the Commons by rocket can still be running the pad's arrival (its own camera, then a
## hand-back to the gameplay rig ~2 s after touchdown): FinaleLaunch waits for it before its shot, and the
## gift's debug entry skips the launch, so wait here too, with the modal already up, or the pad's
## hand-back cuts the view to the rig in the middle of a box.
func _wait_for_pad_arrival() -> void:
	var waited := 0.0
	var arriving := false
	while is_inside_tree() and waited < 20.0:
		var pad_cam := _pad.get("_cam") as Camera3D if _pad != null else null
		var cam_on := pad_cam != null and is_instance_valid(pad_cam) and pad_cam.current
		var ia := _pad_root.get_node_or_null("Interactable")
		var ia_on := ia == null or bool(ia.get("enabled"))
		arriving = arriving or GameState.flag("rocket_arriving") or cam_on
		if not (GameState.flag("rocket_arriving") or cam_on or (arriving and not ia_on)):
			break
		waited += get_process_delta_time()
		await get_tree().process_frame
	if waited > 0.0:
		await get_tree().process_frame
		await get_tree().process_frame
		_beat("waited %.2f s for the pad's arrival to finish" % waited)


## The skiff, built now (so its meshes cost no frame later) exactly where adopt_model will put it, and
## hidden until the pad has been out of view for LUMP_OUT_S.
func _build_skiff() -> void:
	var facing := 0.0
	if _old_rocket != null and is_instance_valid(_old_rocket):
		facing = _old_rocket.rotation.y
		var ob := _old_rocket.get_node_or_null("Blocker")
		if ob is CollisionObject3D:
			_blocker_rids.append((ob as CollisionObject3D).get_rid())
	var scene := load(ROCKET_SCENE_PATH) as PackedScene
	_skiff = scene.instantiate() as Node3D
	if _skiff.has_method("set_look"):
		_skiff.call("set_look", "skiff")
	_skiff.name = "GiftSkiff"
	# adopt_model's own placement (rocket_pad.gd): deck height, the old rocket's facing.
	_skiff.position = Vector3(0.0, float(_pad.get("DECK_Y")) if _pad.get("DECK_Y") != null else 0.10, 0.0)
	_skiff.rotation.y = facing
	_skiff.visible = false
	_pad_root.add_child(_skiff)
	if _skiff.has_method("fit_to_ground"):
		_skiff.call("fit_to_ground")
	var sb := _skiff.get_node_or_null("Blocker")
	if sb is CollisionObject3D:
		_blocker_rids.append((sb as CollisionObject3D).get_rid())
	_skiff_xf = _skiff.global_transform
	# OUT OF THE PAD'S SUBTREE until adopt_model, collider off. The gameplay camera keeps probing its sight
	# line to the astronaut while a cutscene camera draws (camera_rig.gd `_probe_occluders`), and a hit on
	# the pad's DeckBody dithers every mesh under the pad's root - which, under the pad, is the tarp and
	# the skiff fading in the middle of the reveal (measured: debug entry, pull_mid frame). A hit on the
	# skiff's own Blocker would fade the skiff the same way. Built under the pad first so its _ready fits
	# the legs to the drawn deck; adopt_model fits them to the same deck again, so nothing moves.
	_stage = Node3D.new()
	_stage.name = "GiftStage"
	add_child(_stage)
	_pad_root.remove_child(_skiff)
	_stage.add_child(_skiff)
	_skiff.global_transform = _skiff_xf
	if sb is CollisionObject3D:
		_blocker_layer = (sb as CollisionObject3D).collision_layer
		(sb as CollisionObject3D).collision_layer = 0
	_up = _skiff_xf.basis.y.normalized()
	_hatch_dir = -_skiff_xf.basis.z.normalized()
	var mast := _pad_root.get_node_or_null("BeaconMast") as Node3D
	if mast != null:
		_has_mast = true
		_mast_pos = mast.global_position
		_mast_up = mast.global_basis.y.normalized()


func _build_tarp() -> void:
	_tarp = MeshInstance3D.new()
	_tarp.name = "GiftTarp"
	_tarp.mesh = _tarp_mesh()
	_tarp.material_override = _awning_material()
	_tarp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tarp.visible = false
	_stage.add_child(_tarp)
	_tarp.global_transform = _skiff_xf


## The Commons' own awning cloth, the very material instance on screen in gameplay when it is found.
func _awning_material() -> Material:
	for n: Node in _world.find_children("Awnings", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.material_override is ShaderMaterial:
			_notes.append("awning:" + str(_world.get_path_to(mi)))
			return mi.material_override
	_notes.append("awning:preset")
	return Building.cloth_material(AWNING_OPTS)


## A draped, faceted lump in the skiff's frame: TARP_SIDES gores over TARP_PROFILE with alternate fold
## lines pushed in and out, a rope band low down, and the inside drawn as its own darker faces (the
## material culls back faces, and the tarp lifts off during the pull).
static func _tarp_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in TARP_PROFILE.size():
		var pr: Vector2 = TARP_PROFILE[i]
		var ring := PackedVector3Array()
		for k in TARP_SIDES:
			var th := TAU * float(k) / float(TARP_SIDES)
			var wob := 1.0 + (TARP_FOLD if k % 2 == 0 else -TARP_FOLD) * clampf(pr.y / 1.2, 0.2, 1.0)
			wob += 0.025 * sin(float(k) * 2.3 + float(i) * 1.7)
			var r := pr.x * wob
			ring.append(Vector3(sin(th) * r, pr.y + 0.03 * sin(float(k) * 1.9 + float(i)), -cos(th) * r))
		rings.append(ring)
	for i in rings.size() - 1:
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		for k in TARP_SIDES:
			var k2 := (k + 1) % TARP_SIDES
			var col := TARP_A if k % 2 == 0 else TARP_B
			if i == 0:
				col = TARP_ROPE if k % 2 == 0 else TARP_ROPE.lightened(0.08)
			var mid := (a[k] + b[k] + b[k2] + a[k2]) * 0.25
			var out := Vector3(mid.x, maxf(mid.y - 1.0, 0.0) * 0.6, mid.z)
			if out.length_squared() < 1e-6:
				out = Vector3.UP
			_tri(st, a[k], b[k], b[k2], col, out)
			_tri(st, a[k], b[k2], a[k2], col, out)
			# The inside, 1.5 cm in, facing the axis.
			_tri(st, _inset(a[k]), _inset(b[k]), _inset(b[k2]), TARP_INNER, -out)
			_tri(st, _inset(a[k]), _inset(b[k2]), _inset(a[k2]), TARP_INNER, -out)
	return st.commit()


static func _inset(p: Vector3) -> Vector3:
	var h := Vector2(p.x, p.z)
	var l := h.length()
	if l < 0.02:
		return p - Vector3(0.0, 0.015, 0.0)
	h *= maxf(l - 0.015, 0.0) / l
	return Vector3(h.x, p.y - 0.01, h.y)


## One flat triangle whose front face (Godot: clockwise) points along `hint` (skiff_mesh_lib.gd Soup.tri).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, hint: Vector3) -> void:
	var fn := (c - a).cross(b - a)
	if fn.length_squared() < 1e-12:
		return
	if fn.dot(hint) < 0.0:
		var t := b
		b = c
		c = t
		fn = -fn
	fn = fn.normalized()
	for v: Vector3 in [a, b, c]:
		st.set_color(col)
		st.set_normal(fn)
		st.add_vertex(v)


# ============================================================================= the frustum watch
func _process(delta: float) -> void:
	_t += minf(delta, MAX_STEP)
	if _phase == Phase.IDLE or _phase == Phase.DONE or _skiff == null:
		return
	if not _lump_shown:
		_watch_pad()
		# A settled opening frame that still sees the pad (the debug entry's W, say) turns away at once
		# rather than holding the lump back through the boxes.
		if _pad_in_view and not _turned_away and _phase == Phase.OPEN and not _shots.is_empty() \
				and bool(_meeting.call("camera_settled")):
			_turn_away("opening frame settled with the pad in view")
	if _lump_shown and not _pullers_sent:
		_send_pullers()
	if not _sent.is_empty() and _phase <= Phase.PIECES:
		_watch_puller_lens()
	if not _story_done:
		_check_night("frame", true)


func _watch_pad() -> void:
	var cam := get_viewport().get_camera_3d()
	var now := Time.get_ticks_msec()
	var inside := cam == null or _pad_volume_in_frustum(cam)
	if inside != _pad_in_view or _pad_out_ms < 0 and not inside:
		_frustum_changes += 1
		_pad_in_view = inside
		if inside:
			_pad_out_ms = -1
		else:
			_pad_out_ms = now
		_beat("pad %s t=%.2f ms=%d cam=%s" % ["in_view" if inside else "out_of_frustum", _t, now, _cam_name()])
	if not inside and _pad_out_ms >= 0 and now - _pad_out_ms >= int((LUMP_OUT_S + LUMP_MARGIN_S) * 1000.0):
		_show_lump(now)


## True unless one frustum plane has every sample point of the pad's volume on its outer side (a
## conservative test: a volume straddling a corner counts as in view).
func _pad_volume_in_frustum(cam: Camera3D) -> bool:
	var pts := _pad_points()
	for pl: Plane in cam.get_frustum():
		var all_out := true
		for p: Vector3 in pts:
			if not pl.is_point_over(p):
				all_out = false
				break
		if all_out:
			return false
	return true


func _pad_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	var c := _skiff_xf.origin
	var bx := _skiff_xf.basis.x.normalized()
	var bz := _skiff_xf.basis.z.normalized()
	for k in PAD_TEST_SIDES:
		var th := TAU * float(k) / float(PAD_TEST_SIDES)
		var off := (bx * cos(th) + bz * sin(th)) * PAD_TEST_R
		out.append(c + off - _up * 0.25)
		out.append(c + off + _up * PAD_TEST_H)
	out.append(c + _up * (PAD_TEST_H + 0.2))
	return out


func _show_lump(now: int) -> void:
	_lump_shown = true
	_lump_ms = now
	_skiff.visible = true
	_tarp.visible = true
	_beat("lump appear t=%.2f out_for_s=%.3f (gate %.1f) cam=%s frustum_changes=%d" % [_t, (now - _pad_out_ms) / 1000.0,
		LUMP_OUT_S, _cam_name(), _frustum_changes])
	_send_pullers()


# ============================================================================= the beats
func _run() -> void:
	var turns: Array = _lines.get("GIFT")
	var zorp_seen := false
	var prof_seen := 0
	var toast := ""
	for turn: Dictionary in turns:
		if not is_inside_tree():
			return
		if turn.has("toast"):
			toast = str(turn["toast"])
			continue
		var id := str(turn.get("speaker", ""))
		var lines: Array = turn.get("lines", [])
		if id == "zorp" and not zorp_seen:
			zorp_seen = true
			await _say(id, lines.slice(0, lines.size() - 1))
			await _await_lump()
			if not is_inside_tree():
				return
			_phase = Phase.REVEAL
			_camera_shot("reveal")
			_reveal_issued = true
			_send_pullers()
			_crowd_face_point(_skiff_mid())
			await _say(id, lines.slice(lines.size() - 1))
			await _pull_tarp()
			continue
		if id == "mayor_orbit":
			prof_seen += 1
			if prof_seen == 1:
				_phase = Phase.PIECES
				_walk_player_to_control()
				await _say(id, lines)
				continue
			# The last box: the shot the gameplay camera will take over.
			while _walking and is_inside_tree():
				await get_tree().process_frame
			await _read_rig_pose()
			await _camera_and_wait("final")
			await _say(id, lines)
			continue
		if PIECE_OF.has(id):
			await _camera_and_wait("piece:" + str(PIECE_OF[id]))
			await _say(id, lines)
			continue
		await _say(id, lines)
	await _done(toast)


func _say(id: String, lines: Array) -> void:
	if lines.is_empty() or not _meeting.has_method("say"):
		return
	var n := _meeting.call("npc", id) as Node3D if _meeting.has_method("npc") else null
	if n == null:
		_beat("say %s: not in the crowd, box skipped" % id)
		return
	if id == "dj_nova" and n.has_method("play_emote"):
		n.call("play_emote", "dance")
	elif n.has_method("play_emote"):
		n.call("play_emote", "happy")
	_beat("say %s t=%.2f cam=%s rule=%s" % [id, _t, _cam_name(), str(_meeting.get("_rule"))])
	await _meeting.call("say", id, lines)
	if _player != null and is_instance_valid(_player):
		_player.set("input_enabled", false)


func _await_lump() -> void:
	var waited := 0.0
	var turned := false
	while is_inside_tree() and not _lump_shown:
		waited += minf(get_process_delta_time(), MAX_STEP)
		if waited >= LUMP_FALLBACK_S and not turned and _pad_in_view and not _turned_away:
			turned = true
			_turn_away("pad still in view %.1f s after Zorp's box" % waited)
		elif waited >= LUMP_SKY_S and not _looked_up and _pad_in_view:
			# Neither frame lost the pad (a layout where it sits behind every crowd view): look up at the
			# sky from where the camera is, which no pad at the feet can be inside.
			_looked_up = true
			var cam := get_viewport().get_camera_3d()
			if cam != null:
				var up := _planet.up_at(cam.global_position)
				var away := _tangent(cam.global_position - _skiff_xf.origin, up, _hatch_dir)
				var look := (away * 0.5 + up * 0.87).normalized()
				_meeting.call("camera_to_transform", Transform3D(Basis.looking_at(look, up), cam.global_position), cam.fov, 0.0)
				_beat("pad still in view %.1f s after Zorp's box: looking up at the sky" % waited)
		await get_tree().process_frame
	_beat("lump wait %.2f s" % waited)


func _turn_away(why: String) -> void:
	_turned_away = true
	var xf := _away_from_pad_xf()
	_meeting.call("camera_to_transform", xf[0], xf[1], 0.0)
	_beat("%s: turning the camera away from the pad" % why)


## The current eye, turned onto the crowd when that leaves the pad's volume out of the frame, else looking
## away from the pad and a little down.
func _away_from_pad_xf() -> Array:
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam != null else _player.global_position + _up * 2.0
	var fov := cam.fov if cam != null else 45.0
	var up := _planet.up_at(eye)
	var acc := Vector3.ZERO
	var count := 0
	for id in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n != null:
			acc += n.global_position + _planet.up_at(n.global_position) * 1.0
			count += 1
	var pad_pts := _pad_points()
	if count > 0:
		var target := acc / float(count)
		var d := (target - eye).normalized()
		if absf(d.dot(up)) < 0.95:
			var xf := Transform3D(Basis.looking_at(d, up), eye)
			var seen := false
			for p: Vector3 in pad_pts:
				var uv := _uv(xf, fov, p)
				if uv.x > -0.1 and uv.x < 1.1 and uv.y > -0.1 and uv.y < 1.1:
					seen = true
					break
			if not seen:
				return [xf, fov]
	var away := _tangent(eye - _skiff_xf.origin, up, _hatch_dir)
	var b := Basis.looking_at((away - up * 0.18).normalized(), up)
	return [Transform3D(b, eye), fov]


func _camera_shot(key: String) -> float:
	var s: Dictionary = _shots.get(key, {})
	if s.is_empty():
		_beat("no shot for %s; camera left where it is" % key)
		return 0.0
	return _drive_shot(s["xf"] as Transform3D, float(s["fov"]), key)


## Starts the camera move to `xf`. The meeting's camera travels in a straight line (finale_meeting.gd
## _drive); when that line from the drawing eye passes a body (the crowd where they stand, a puller's
## walk, the astronaut), it goes by the shortest clear waypoint instead. Returns the move's estimate (s).
func _drive_shot(xf: Transform3D, fov: float, key: String) -> float:
	_shot_serial += 1
	_detouring = false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return float(_meeting.call("camera_to_transform", xf, fov, 0.0))
	var a := cam.global_position
	var who := _move_body(a, xf.origin, 0.0)
	if who == "":
		return float(_meeting.call("camera_to_transform", xf, fov, 0.0))
	var w := _detour_point(a, xf.origin)
	if w == Vector3.INF:
		_beat("camera %s: the move passes %s (%.2f m) and no waypoint is clear (%s); straight" % [key, who,
			_move_clearance(a, xf.origin), str(_detour_why)])
		return float(_meeting.call("camera_to_transform", xf, fov, 0.0))
	var q := cam.global_basis.get_rotation_quaternion().slerp(xf.basis.get_rotation_quaternion(), 0.5)
	var wxf := Transform3D(Basis(q), w)
	var wfov := lerpf(cam.fov, fov, 0.5)
	_beat("camera %s: the move passes %s (%.2f m); by a waypoint %.2f m off the line (search %s)" % [key, who,
		_move_clearance(a, xf.origin), _seg_seg_dist(a, xf.origin, w, w), str(_detour_why)])
	_follow_detour(wxf, wfov, xf, fov, _shot_serial)
	return _effort(cam.global_transform, cam.fov, wxf, wfov) * 1.3 + _effort(wxf, wfov, xf, fov) * 1.3


func _follow_detour(wxf: Transform3D, wfov: float, xf: Transform3D, fov: float, serial: int) -> void:
	_detouring = true
	_detour_goal = xf.origin
	_meeting.call("camera_to_transform", wxf, wfov, 0.0)
	var t := 0.0
	while is_inside_tree() and serial == _shot_serial and t < DETOUR_WAIT_MAX:
		var cam := get_viewport().get_camera_3d()
		if cam == null or cam.global_position.distance_to(wxf.origin) < DETOUR_SWITCH_M or bool(_meeting.call("camera_settled")):
			break
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame
	if serial != _shot_serial or not is_inside_tree():
		return
	_meeting.call("camera_to_transform", xf, fov, 0.0)
	_detouring = false


## The first body the straight camera move a -> b passes within TRAVEL_CLEAR_M + `extra` of ("" if none):
## crowd members where they stand now, a walking puller anywhere on its walk (PULLER_LENS_M), and the
## astronaut. A body the move starts or ends beside, and only moves away from or towards, does not count.
func _move_body(a: Vector3, b: Vector3, extra: float, exempt_a: bool = true, exempt_b: bool = true) -> String:
	for id in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n == null:
			continue
		if _sent.has(id) and not _arrived.has(id):
			if _walk_lens_clear(n.global_position, _puller_wps.get(id, []), [[a, b]]) < PULLER_LENS_M + extra:
				return str(id)
			continue
		if _body_on_move(a, b, n.global_position, PULLER_BODY_H, TRAVEL_CLEAR_M + extra, exempt_a, exempt_b):
			return str(id)
	if _player != null and is_instance_valid(_player) \
			and _body_on_move(a, b, _player.global_position, 1.6, TRAVEL_CLEAR_M + extra, exempt_a, exempt_b):
		return "astronaut"
	return ""


func _body_on_move(a: Vector3, b: Vector3, feet: Vector3, h: float, clear: float, exempt_a: bool, exempt_b: bool) -> bool:
	var top := feet + _planet.up_at(feet) * h
	var d := _seg_seg_dist(a, b, feet, top)
	if d >= clear:
		return false
	var da := _seg_seg_dist(a, a, feet, top)
	var db := _seg_seg_dist(b, b, feet, top)
	return not ((exempt_a and da < clear and d >= da - 0.05) or (exempt_b and db < clear and d >= db - 0.05))


## Trace only: the least distance from the move a -> b to a crowd body axis or the astronaut.
func _move_clearance(a: Vector3, b: Vector3) -> float:
	var best := INF
	for id in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n != null:
			best = minf(best, _seg_seg_dist(a, b, n.global_position, n.global_position + _planet.up_at(n.global_position) * PULLER_BODY_H))
	return best


## The waypoint (INF if none) beside or above the move a -> b whose two legs pass no body (DETOUR_SWITCH_M
## wider), stay 0.8 m above the ground, hit no collider or near mesh, and come no closer to the skiff than
## the straight move did (or 2 m). Shortest total path wins.
func _detour_point(a: Vector3, b: Vector3) -> Vector3:
	var u0 := Time.get_ticks_usec()
	var c := _skiff_xf.origin
	var skiff_top := c + _up * 2.8
	var skiff_clear := minf(2.0, _seg_seg_dist(a, b, c, skiff_top))
	_detour_why.clear()
	var cands: Array = []
	for t: float in DETOUR_TS:
		var m := a.lerp(b, t)
		var up := _planet.up_at(m)
		var side := _tangent((b - a).cross(up), up, _hatch_dir)
		for hu: float in DETOUR_UPS:
			for sd: float in DETOUR_SIDES:
				if hu == 0.0 and sd == 0.0:
					continue
				var w := m + up * hu + side * sd
				cands.append([a.distance_to(w) + w.distance_to(b), w, up])
	cands.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var tried := 0
	for cand: Array in cands:
		tried += 1
		var w: Vector3 = cand[1]
		var up: Vector3 = cand[2]
		var why := ""
		if (w - _planet.surface_point(_planet.dir_of(w))).dot(up) < 0.8:
			why = "ground"
		# The waypoint is no end a body may be beside: only the real start and goal are exempt.
		if why == "":
			why = _move_body(a, w, DETOUR_SWITCH_M, true, false)
		if why == "":
			why = _move_body(w, b, DETOUR_SWITCH_M, false, true)
		if why == "" and (_seg_seg_dist(a, w, c, skiff_top) < skiff_clear or _seg_seg_dist(w, b, c, skiff_top) < skiff_clear):
			why = "skiff"
		if why == "" and not _sphere_clear(w, 0.35):
			why = "inside"
		if why == "":
			why = _ray(a, w)
		if why == "":
			why = _ray(w, b)
		if why == "":
			why = _occluder_on(a, w, 0.0)
		if why == "":
			why = _occluder_on(w, b, 0.0)
		if why == "":
			_detour_why["tried"] = tried
			_detour_why["ms"] = snappedf((Time.get_ticks_usec() - u0) / 1000.0, 0.01)
			return w
		_detour_why[why] = int(_detour_why.get(why, 0)) + 1
	_detour_why["ms"] = snappedf((Time.get_ticks_usec() - u0) / 1000.0, 0.01)
	return Vector3.INF


func _camera_and_wait(key: String) -> void:
	var est := _camera_shot(key)
	var t := 0.0
	while is_inside_tree() and t < CAM_WAIT_MAX:
		if not _detouring and _meeting.has_method("camera_settled") and bool(_meeting.call("camera_settled")):
			break
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame
	_beat("camera %s settled after %.2f s (estimate %.2f)" % [key, t, est])


# ------------------------------------------------------------------------------------ the tarp
## Sends each puller whose whole walk (from where it stands now, by its waypoints) keeps PULLER_LENS_M from
## every eye the camera can still be at before it arrives: the drawing camera's eye, the eye it is moving
## to, and the reveal eye while the reveal has not been framed yet (the meeting's camera moves in a
## straight line between eyes, finale_meeting.gd _drive). A puller that fails waits, re-tested every
## frame; once the reveal frame has settled the camera is still, and a walk that still meets its eye is
## not taken (the puller stays where it is, facing the skiff).
func _send_pullers() -> void:
	if _pullers_sent or _pullers.is_empty() or not _lump_shown:
		return
	var segs := _camera_segments()
	var still := _reveal_issued and not _detouring and bool(_meeting.call("camera_settled"))
	var pending := 0
	for id: String in _pullers.keys():
		if _sent.has(id):
			continue
		var n := _meeting.call("npc", id) as Node3D
		if n == null or not n.has_method("stroll_to"):
			_sent[id] = true
			_arrived[id] = true
			continue
		var clear := _walk_lens_clear(n.global_position, _puller_wps.get(id, []), segs)
		if clear >= PULLER_LENS_M:
			_sent[id] = true
			n.call("release_facing")
			_beat("puller %s sets off t=%.2f cam=%s rule=%s walk lens clearance %.2f m (gate %.2f)" % [id, _t,
				_cam_name(), str(_meeting.get("_rule")), clear, PULLER_LENS_M])
			_stroll_path(n, id)
		elif still:
			_sent[id] = true
			_arrived[id] = true
			if n.has_method("hold_facing"):
				n.call("hold_facing", _skiff_mid())
			_beat("puller %s stays put: its walk passes %.2f m from the settled reveal eye (gate %.2f)" % [id,
				clear, PULLER_LENS_M])
		else:
			pending += 1
	if pending == 0:
		_pullers_sent = true


## The camera eyes still to come, as segments the lens can sweep: current eye -> the meeting's goal eye,
## then (before the reveal is issued) that eye -> the reveal eye.
func _camera_segments() -> Array:
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam != null else _player.global_position + _up * 2.0
	var goal := eye
	if _meeting.get("_has_goal") == true and _meeting.get("_goal") is Transform3D:
		goal = (_meeting.get("_goal") as Transform3D).origin
	var segs: Array = [[eye, goal]]
	if _detouring:
		segs.append([goal, _detour_goal])
		goal = _detour_goal
	if not _reveal_issued and _shots.has("reveal"):
		segs.append([goal, (_shots["reveal"]["xf"] as Transform3D).origin])
	return segs


## The least distance between a body axis (PULLER_BODY_H tall) walked from `from` through `wps` and any of
## the eye segments `segs` (each [a, b]).
func _walk_lens_clear(from: Vector3, wps: Array, segs: Array) -> float:
	var best := INF
	var a := from
	for wp: Vector3 in wps:
		var n := maxi(2, int(ceil(a.distance_to(wp) / PULLER_LENS_STEP)) + 1)
		for i in n:
			var q := _planet.surface_point(_planet.dir_of(a.lerp(wp, float(i) / float(n - 1))))
			var top := q + _planet.up_at(q) * PULLER_BODY_H
			for sg: Array in segs:
				best = minf(best, _seg_seg_dist(sg[0], sg[1], q, top))
		a = wp
	if wps.is_empty():
		for sg: Array in segs:
			best = minf(best, _seg_seg_dist(sg[0], sg[1], from, from + _planet.up_at(from) * PULLER_BODY_H))
	return best


## Trace only: the drawing camera's least distance to a puller's body axis while they walk.
func _watch_puller_lens() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for id: String in _pullers.keys():
		var n := _meeting.call("npc", id) as Node3D
		if n == null:
			continue
		var u := n.global_basis.y.normalized()
		var d := _seg_seg_dist(cam.global_position, cam.global_position, n.global_position, n.global_position + u * PULLER_BODY_H)
		if d < _puller_lens_min:
			_puller_lens_min = d
		if d < LENS_CLEAR_M and not _puller_lens_warned:
			_puller_lens_warned = true
			_beat("LENS NEAR: %s %.2f m from the camera t=%.2f phase=%s" % [id, d, _t, phase_name()])


func _stroll_path(n: Node3D, id: String) -> void:
	var wps: Array = _puller_wps.get(id, [])
	for wp: Vector3 in wps:
		n.call("stroll_to", _planet.dir_of(wp))
		await get_tree().physics_frame
		await get_tree().physics_frame
		var t := 0.0
		while is_inside_tree() and is_instance_valid(n) and bool(n.call("is_strolling")) and t < PULLERS_WAIT_MAX:
			t += get_process_delta_time()
			await get_tree().process_frame
	if is_instance_valid(n) and n.has_method("hold_facing"):
		n.call("hold_facing", _skiff_mid())
	_arrived[id] = true


func _pull_tarp() -> void:
	var t := 0.0
	var since_sent := 0.0
	while is_inside_tree() and since_sent < PULLERS_WAIT_MAX and t < CAM_WAIT_MAX + PULLERS_WAIT_MAX:
		_send_pullers()
		var walking := false
		for id: String in _pullers.keys():
			walking = walking or not _arrived.has(id)
		var settled := not _detouring and bool(_meeting.call("camera_settled"))
		if not walking and settled and t > 0.2:
			break
		var dt := minf(get_process_delta_time(), MAX_STEP)
		t += dt
		if _pullers_sent:
			since_sent += dt
		await get_tree().process_frame
	var dists := PackedStringArray()
	for id: String in _pullers.keys():
		var n2 := _meeting.call("npc", id) as Node3D
		if n2 != null:
			dists.append("%s %.2f m from spot" % [id, n2.global_position.distance_to(_pullers[id] as Vector3)])
			if n2.has_method("play_emote"):
				n2.call("play_emote", "happy")
	_beat("pull start t=%.2f waited %.2f s %s; walking pullers' least camera distance %.2f m" % [_t, t,
		", ".join(dists), _puller_lens_min])
	var has_sfx := AudioManager.sfx_exists("skiff_reveal")
	if has_sfx:
		AudioManager.play_sfx_at("skiff_reveal", _skiff_mid(), -2.0)
	_beat("sfx skiff_reveal exists=%s" % str(has_sfx))
	var cam := get_viewport().get_camera_3d()
	var back := _tangent(_skiff_xf.origin - (cam.global_position if cam != null else _control), _up, _hatch_dir)
	var base := _tarp.global_transform
	var s := 0.0
	while is_inside_tree() and s < PULL_S:
		s = minf(PULL_S, s + minf(get_process_delta_time(), MAX_STEP))
		var e := _smootherstep(s / PULL_S)
		var k := 1.0 - pow(e, 1.6)
		var xf := base
		xf.origin = base.origin + back * (PULL_BACK_M * e) + _up * (PULL_LIFT_M * sin(PI * e))
		xf.basis = base.basis.scaled_local(Vector3(k, lerpf(1.0, 0.0, pow(e, 1.3)), k)) if k > 0.0 else base.basis.scaled_local(Vector3.ONE * 0.0001)
		_tarp.global_transform = xf
		await get_tree().process_frame
	# The last frame above drew it at 1e-4 of its size (nothing on screen); only now is it hidden.
	var last_scale := _tarp.global_basis.get_scale().x if is_instance_valid(_tarp) else -1.0
	if is_instance_valid(_tarp):
		_tarp.visible = false
	_beat("pull end t=%.2f tarp hidden after a frame at scale %.5f" % [_t, last_scale])
	if is_instance_valid(_tarp):
		_tarp.queue_free()
	_tarp = null
	for id in _crowd_ids():
		var n3 := _meeting.call("npc", id) as Node3D
		if n3 != null and n3.has_method("play_emote") and not _pullers.has(id):
			n3.call("play_emote", "happy")
	_crowd_face_point(_skiff_mid())
	await _wait(0.5)


# ------------------------------------------------------------------------------------ the astronaut
func _walk_player_to_control() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var start := _player.global_position
	var from_dir := _planet.dir_of(start)
	var dist := _planet.surface_distance(from_dir, _control_dir)
	var model: Node = _player.call("get_model") if _player.has_method("get_model") else null
	_beat("walk to control %.2f m (%.2f m from the pad)" % [dist, _control.distance_to(_pad_root.global_position)])
	_walking = true
	_player.set_physics_process(false)
	_player.set("velocity", Vector3.ZERO)
	# Around the pad, never across it: through a waypoint on PULLER_WAYPOINT_R when the straight line
	# comes closer than that.
	var path: Array[Vector3] = [start]
	var wp := _around_pad(start, _control)
	if wp != Vector3.INF:
		path.append(wp)
	path.append(_control)
	if model != null and dist > 0.2:
		_player.set("_speed_factor", WALK_SPEED_FACTOR)
		model.call("set_state", "walk")
	for i in path.size() - 1:
		var a := _planet.dir_of(path[i])
		var b := _planet.dir_of(path[i + 1])
		var leg := _planet.surface_distance(a, b)
		var gone := 0.0
		while is_inside_tree() and leg > 0.05 and gone < leg:
			gone = minf(leg, gone + WALK_MPS * minf(get_process_delta_time(), MAX_STEP))
			var p := _planet.surface_point(a.slerp(b, gone / leg).normalized())
			var up := _planet.up_at(p)
			var ahead := _planet.surface_point(a.slerp(b, minf(1.0, (gone + 0.3) / leg)).normalized())
			var f := _tangent(ahead - p, up, _hatch_dir)
			_player.global_transform = Transform3D(Basis.looking_at(f, up), p + up * 0.02)
			await get_tree().process_frame
	if not is_inside_tree():
		return
	_player.set("_speed_factor", 0.0)
	if model != null:
		model.call("set_state", "idle")
	var up2 := _planet.up_at(_control)
	var f0 := _tangent(-_player.global_basis.z, up2, _hatch_dir)
	var f1 := _tangent(_skiff_xf.origin - _control, up2, f0)
	var t := 0.0
	while is_inside_tree() and t < TURN_S:
		t = minf(TURN_S, t + minf(get_process_delta_time(), MAX_STEP))
		var f := f0.slerp(f1, smoothstep(0.0, 1.0, t / TURN_S)).normalized()
		_player.global_transform = Transform3D(Basis.looking_at(_tangent(f, up2, f1), up2), _player.global_position)
		await get_tree().process_frame
	_player.set("velocity", Vector3.ZERO)
	_player.set_physics_process(true)
	_walking = false
	_beat("walk done at %.2f m from the pad" % _player.global_position.distance_to(_pad_root.global_position))


## The closest the straight line a-b (on the ground plane at the pad) comes to the pad's centre.
func _chord_min(a: Vector3, b: Vector3) -> float:
	var c := _skiff_xf.origin
	var ab := b - a
	var u := clampf((c - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	var d := a + ab * u - c
	d -= _up * d.dot(_up)
	return d.length()


func _turn_player_to_skiff() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var p := _player.global_position
	var up := _planet.up_at(p)
	var f0 := _tangent(-_player.global_basis.z, up, _hatch_dir)
	var f1 := _tangent(_skiff_xf.origin - p, up, f0)
	var t := 0.0
	while is_inside_tree() and t < TURN_S:
		t = minf(TURN_S, t + minf(get_process_delta_time(), MAX_STEP))
		var f := f0.slerp(f1, smoothstep(0.0, 1.0, t / TURN_S)).normalized()
		_player.global_transform = Transform3D(Basis.looking_at(_tangent(f, up, f1), up), _player.global_position)
		await get_tree().process_frame


## A waypoint on PULLER_WAYPOINT_R round the pad when the chord a-b passes closer than that, else INF.
func _around_pad(a: Vector3, b: Vector3) -> Vector3:
	var c := _skiff_xf.origin
	var ab := b - a
	var u := clampf((c - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	var closest := a + ab * u
	var d := (closest - c)
	d -= _up * d.dot(_up)
	if d.length() >= PULLER_WAYPOINT_R - 0.05:
		return Vector3.INF
	var ta := _tangent(a - c, _up, _hatch_dir)
	var tb := _tangent(b - c, _up, _hatch_dir)
	var mid := (ta + tb)
	if mid.length_squared() < 1e-4:
		mid = _up.cross(ta)
	mid = mid.normalized()
	return _planet.surface_point(_planet.dir_of(c + mid * (PULLER_WAYPOINT_R + 0.3)))


# ------------------------------------------------------------------------------------ DONE
func _done(toast: String) -> void:
	var runner := DialogueRunner.get_or_create(self)
	if runner != null and runner.is_active():
		runner.finish()
	if _player != null and is_instance_valid(_player):
		_player.set("input_enabled", false)
	# DONE on disk before anything else can happen (§6 and checklist 2).
	var stage_before := _fs_int("stage")
	_finish_story()
	_beat("DONE stage %d->%d campaign_changed=%d saved_ok=%s t=%.2f hour=%.2f" % [stage_before, _fs_int("stage"),
		_campaign_changes, str(_fs_bool("can_save")), _t, GameState.time_of_day])
	if _pad.has_method("adopt_model") and _skiff != null and is_instance_valid(_skiff):
		var sb := _skiff.get_node_or_null("Blocker")
		if sb is CollisionObject3D and _blocker_layer >= 0:
			(sb as CollisionObject3D).collision_layer = _blocker_layer
		var before := _skiff.global_transform
		_pad.call("adopt_model", _skiff)
		_beat("adopt_model skiff moved %.4f m, pad rocket=%s look=%s" % [before.origin.distance_to(_skiff.global_transform.origin),
			str(_pad.get("rocket") == _skiff), str(_skiff.call("look")) if _skiff.has_method("look") else "-"])
	# The box turned the astronaut toward the Professor: back to the skiff (the gameplay camera's heading was
	# seated behind that facing in `_read_rig_pose`, and the focus release restores it, so no reseat here).
	_turn_player_to_skiff()
	# The last box's focus pulled the gameplay camera toward the Professor: hold the final frame while
	# it lets go and settles back where `_read_rig_pose` found it, so the hand-back stays a small move.
	await _wait(DialogueRunner.RELEASE_TIME + 0.4)
	if not is_inside_tree():
		return
	await _hand_back()
	if not is_inside_tree():
		return
	_phase = Phase.DONE
	_end_modal()
	if _player != null and is_instance_valid(_player):
		_player.set("velocity", Vector3.ZERO)
		_player.set_physics_process(true)
		_player.set("input_enabled", not EventBus.is_modal_open())
	if toast != "":
		EventBus.toast_requested.emit(toast, "star")
	_beat("control t=%.2f pad_dist=%.2f input=%s modal_open=%s time_scale=%s toast=%s" % [_t,
		_player.global_position.distance_to(_pad_root.global_position), str(_player.get("input_enabled")),
		str(EventBus.is_modal_open()), str(_env.get("time_scale")) if _env != null else "-", toast])
	if EventBus.campaign_changed.is_connected(_on_campaign_changed):
		EventBus.campaign_changed.disconnect(_on_campaign_changed)
	set_process(false)
	finished.emit()


func _finish_story() -> void:
	_story_done = true
	if _clock_held:
		_restore_clock()
	if ResourceLoader.exists(FINALE_STATE_PATH):
		load(FINALE_STATE_PATH).call("finish_story")


## HANDBACK_S from the meeting camera's frame onto the gameplay camera, tracking it while it settles.
func _hand_back() -> void:
	var mcam := _meeting.call("camera") as Camera3D if _meeting.has_method("camera") else null
	var rc := _rig.call("get_camera") as Camera3D if _rig != null and _rig.has_method("get_camera") else null
	if mcam == null or rc == null or not mcam.current:
		if rc != null:
			rc.current = true
		return
	# Stop any blend still running on the meeting camera (a goal equal to where it is ends on its next step).
	_meeting.call("camera_to_transform", mcam.global_transform, mcam.fov, 0.0)
	await get_tree().process_frame
	var from := mcam.global_transform
	var fov0 := mcam.fov
	var t := 0.0
	var gap := from.origin.distance_to(rc.global_position)
	while is_inside_tree() and t < HANDBACK_S:
		t = minf(HANDBACK_S, t + minf(get_process_delta_time(), MAX_STEP))
		var k := _smootherstep(t / HANDBACK_S)
		var to := rc.global_transform
		var q := from.basis.get_rotation_quaternion().slerp(to.basis.get_rotation_quaternion(), k)
		mcam.global_transform = Transform3D(Basis(q), from.origin.lerp(to.origin, k))
		mcam.fov = lerpf(fov0, rc.fov, k)
		await get_tree().process_frame
	if is_instance_valid(rc):
		rc.current = true
	var est: Dictionary = _shots.get("final", {})
	var est_note := ""
	if not est.is_empty() and is_instance_valid(rc):
		var ex: Transform3D = est["xf"]
		est_note = " final-shot estimate off by %.2f m, %.1f deg, fov %.1f vs %.1f (rig dist %.2f pitch %.1f)" % [
			ex.origin.distance_to(rc.global_position),
			rad_to_deg(ex.basis.get_rotation_quaternion().angle_to(rc.global_basis.get_rotation_quaternion())),
			float(est["fov"]), rc.fov, float(_rig.call("get_zoom_distance")) if _rig.has_method("get_zoom_distance") else -1.0,
			rad_to_deg(float(_rig.get("_pitch"))) if _rig.get("_pitch") != null else -1.0]
	_beat("hand-back %.2f s gap_at_start %.2f m%s" % [t, gap, est_note])


# ============================================================================= shots
## Everything the beats will frame, solved up front over a few frames: the reveal, where Grig and Bolt
## stand for it, the hand-back spot, each friend's piece, and the final frame.
func _solve_all() -> void:
	var u00 := Time.get_ticks_usec()
	await _collect_occluders()
	await get_tree().process_frame
	var u0 := Time.get_ticks_usec()
	_beat("occluders %d near the skiff in %.1f ms" % [_occ.size(), (u0 - u00) / 1000.0])
	await _choose_control()
	await get_tree().process_frame
	var u1 := Time.get_ticks_usec()
	var reveal: Dictionary = await _solve_reveal()
	if not reveal.is_empty():
		_shots["reveal"] = reveal
	var u2 := Time.get_ticks_usec()
	var ms := PackedStringArray()
	var final_est := _final_shot()
	_choose_pullers(reveal)
	await get_tree().process_frame
	var prev: Dictionary = reveal
	for id: String in ["bolt", "zorp", "fen", "grig", "vela"]:
		var piece: String = PIECE_OF[id]
		var uu := Time.get_ticks_usec()
		var s: Dictionary = await _solve_piece(piece, prev, final_est if id == "vela" else {})
		ms.append("%s %.1f" % [piece, (Time.get_ticks_usec() - uu) / 1000.0])
		if not s.is_empty():
			_shots["piece:" + piece] = s
			prev = s
		await get_tree().process_frame
		if not is_inside_tree():
			return
	# Trace only: moves the solve could not keep clear take a detour when they are played (_drive_shot).
	_beat("bodies on straight camera moves between solved shots: %s" % str(_move_blockers(final_est)))
	_shots["final"] = _final_shot()
	_send_pullers()
	var summary := PackedStringArray()
	for k: String in _shots.keys():
		var s2: Dictionary = _shots[k]
		summary.append("%s[%s]" % [k, str(s2.get("note", ""))])
	_beat("shots solved: control %.1f ms, reveal+pullers %.1f ms, pieces ms %s | %s" % [(u1 - u0) / 1000.0,
		(u2 - u1) / 1000.0, ", ".join(ms), " ".join(summary)])


## VisitorSystem's ground rules at `d`, with the rules that do not apply to a spot the astronaut or a
## friend stands on for a moment (pad, spawn, landing, prompts, pickups, trash) dropped. The public call
## rebuilds its caches every time (~45 ms measured), so it runs once and the rest use the cached check,
## the way finale_meeting.gd `_ground` does.
func _ground(d: Vector3) -> String:
	if _vs == null and ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		_vs = load(VISITOR_SYSTEM_PATH).call("find")
	if _vs == null:
		return ""
	var why := ""
	if not _vs_ready and _vs.has_method("ground_problem"):
		_vs_ready = true
		why = str(_vs.call("ground_problem", d))
	elif _vs.has_method("_ground_problem"):
		why = str(_vs.call("_ground_problem", d))
	elif _vs.has_method("ground_problem"):
		why = str(_vs.call("ground_problem", d))
	if why in ["pad", "spawn", "landing", "pickup", "trash"] or why.begins_with("prompt:"):
		why = ""
	return why


func _choose_control() -> void:
	var c := _skiff_xf.origin
	var axis := Vector3.ZERO
	if _meeting.has_method("axis"):
		axis = _meeting.call("axis") as Vector3
	if axis.length_squared() < 1e-4:
		axis = _player.global_position - c
	axis = _tangent(axis, _up, _hatch_dir)
	var side := _up.cross(axis).normalized()
	var best := Vector3.INF
	var best_score := INF
	var note := ""
	_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
	for deg: float in [75.0, -75.0, 60.0, -60.0, 90.0, -90.0, 45.0, -45.0, 105.0, -105.0, 30.0, -30.0, 0.0]:
		if Time.get_ticks_usec() > _solve_budget_end:
			await get_tree().process_frame
			_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
		var dir := axis.rotated(_up, deg_to_rad(deg))
		var p := _planet.surface_point(_planet.dir_of(c + dir * CONTROL_M))
		p = _planet.surface_point(_planet.dir_of(c + (p - c).normalized() * CONTROL_M))
		var why := _ground(_planet.dir_of(p))
		if why == "" and not _sphere_clear(p + _planet.up_at(p) * 0.9, 0.5):
			why = "body"
		if why == "":
			for id in _crowd_ids():
				var n := _meeting.call("npc", id) as Node3D
				if n != null and n.global_position.distance_to(p) < 1.4:
					why = "crowd:" + id
					break
		if why == "" and _has_mast and _mast_pos.distance_to(p) < 2.0:
			why = "mast"
		# The gameplay camera behind the astronaut must see the skiff: a sight line from where it sits.
		if why == "":
			var eye := _rig_eye_estimate(p)
			var hit := _ray(eye, _skiff_mid())
			if hit == "":
				hit = _occluder_on(eye, _skiff_mid(), 0.0)
			if hit != "":
				why = "rig_sight:" + hit
		note += " %+d:%s" % [int(deg), why if why != "" else "ok"]
		if why == "":
			var score := absf(absf(deg) - 75.0)
			if score < best_score:
				best_score = score
				best = p
	if best == Vector3.INF:
		best = _planet.surface_point(_planet.dir_of(c + axis * CONTROL_M))
		note += " (none passed: on the axis)"
	_control = best
	_control_dir = _planet.dir_of(best)
	_beat("control spot %.2f m from the pad:%s" % [best.distance_to(_pad_root.global_position), note])


## Where the gameplay camera will sit behind an astronaut standing at `p` facing the skiff (camera_rig.gd
## constants: pivot, pitch, distance), used to score spots and to frame the last box.
func _rig_eye_estimate(p: Vector3) -> Vector3:
	var up := _planet.up_at(p)
	var f := _tangent(_skiff_xf.origin - p, up, _hatch_dir)
	var dist := float(_rig.call("get_zoom_distance")) if _rig != null and _rig.has_method("get_zoom_distance") else 8.6
	var pitch := float(_rig.get("_pitch")) if _rig != null and _rig.get("_pitch") != null else deg_to_rad(34.0)
	var pivot := p + up * CameraRig.PIVOT_HEIGHT
	return pivot - f * cos(pitch) * dist + up * sin(pitch) * dist


## The last box is framed where the gameplay camera will be when control returns, so the 1.1 s hand-back
## is a small correction: the conversation is closed for a moment (the runner's focus pulls the gameplay
## camera toward the speaker), the rig is seated behind the astronaut, and its settled pose is read.
func _read_rig_pose() -> void:
	var runner := DialogueRunner.get_or_create(self)
	if runner != null and runner.is_active():
		runner.finish()
	if _player != null and is_instance_valid(_player):
		_player.set("input_enabled", false)
	if _rig == null or not _rig.has_method("get_camera"):
		return
	if _rig.has_method("reseat_behind_player"):
		_rig.call("reseat_behind_player")
	# DialogueRunner.RELEASE_TIME (0.5 s) for the focus and FOV to let go, plus the rig's smoothing.
	await _wait(DialogueRunner.RELEASE_TIME + 0.4)
	var rc := _rig.call("get_camera") as Camera3D
	if rc == null or not is_inside_tree():
		return
	var est: Dictionary = _shots.get("final", {})
	var off := (est["xf"] as Transform3D).origin.distance_to(rc.global_position) if not est.is_empty() else -1.0
	_shots["final"] = {"xf": rc.global_transform, "fov": rc.fov, "note": "rig pose read"}
	_beat("final shot: the gameplay camera's settled pose (analytic estimate was %.2f m off)" % off)


func _final_shot() -> Dictionary:
	var p := _control
	var up := _planet.up_at(p)
	var eye := _rig_eye_estimate(p)
	var pivot := p + up * CameraRig.PIVOT_HEIGHT
	var rc := _rig.call("get_camera") as Camera3D if _rig != null and _rig.has_method("get_camera") else null
	var fov := rc.fov if rc != null else 45.0
	# The runner pushes the gameplay camera's FOV in while a box is open; its resting FOV is the saved one.
	var runner := DialogueRunner.get_or_create(self)
	if runner != null and runner.get("_saved_fov") != null and runner.is_active():
		fov = float(runner.get("_saved_fov"))
	var b := Basis.looking_at((pivot - eye).normalized(), up)
	return {"xf": Transform3D(b, eye), "fov": fov, "note": "rig estimate"}


func _solve_reveal() -> Dictionary:
	var c := _skiff_xf.origin
	var pts := PackedVector3Array([c + _up * 2.75, c - _up * 0.05])
	for k in 4:
		var th := TAU * float(k) / 4.0
		pts.append(c + (_skiff_xf.basis.x.normalized() * cos(th) + _skiff_xf.basis.z.normalized() * sin(th)) * 1.7 + _up * 1.0)
	var aim := c + _up * 1.25
	var look_from := _player.global_position
	var best: Dictionary = {}
	var cands: Array[Dictionary] = []
	_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
	for i in AZ_STEPS:
		if Time.get_ticks_usec() > _solve_budget_end:
			await get_tree().process_frame
			_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
		var az := TAU * float(i) / float(AZ_STEPS)
		var dir := _hatch_dir.rotated(_up, az)
		for dist: float in REVEAL_DISTS:
			for h: float in REVEAL_HEIGHTS:
				var cand := _candidate(dir, dist, h, aim, 0.42, REVEAL_FOV)
				if cand.is_empty():
					continue
				var bad := _frame_gate(cand, pts, [])
				if bad != "":
					continue
				# The audience's side first: near the astronaut's bearing from the skiff.
				var bearing := _tangent(look_from - c, _up, _hatch_dir)
				var score := rad_to_deg(bearing.angle_to(dir)) / 30.0 + absf(dist - 6.6) * 0.3 + absf(h - 2.3) * 0.2
				cand["score"] = score
				cand["note"] = "az%d d%.1f h%.1f" % [int(rad_to_deg(az)), dist, h]
				cands.append(cand)
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) < float(b["score"]))
	var tries := 0
	var hist_r := {}
	var passing_r: Array[Dictionary] = []
	## Clear sight but the move there passes a body: used only when nothing else passes.
	var travel_only_r: Array[Dictionary] = []
	_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
	for cand: Dictionary in cands:
		tries += 1
		if tries > CAND_RAY_TRIES:
			break
		if Time.get_ticks_usec() > _solve_budget_end:
			await get_tree().process_frame
			_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
		var bad := _sight_gate(cand, [c + _up * 2.4, c + _up * 1.2, aim], ["grig", "bolt"], _player.global_position)
		if bad == "":
			var from_eye: Vector3 = _camera_segments()[-1][1]
			if _travel_gate(from_eye, from_eye, _player.global_position) == "" \
					and _travel_gate(from_eye, (cand["xf"] as Transform3D).origin, _player.global_position) != "":
				bad = "travel"
				travel_only_r.append(cand)
		if bad == "":
			passing_r.append(cand)
			if passing_r.size() >= PASS_KEEP:
				break
			continue
		hist_r[bad] = int(hist_r.get(bad, 0)) + 1
	if not passing_r.is_empty():
		best = _best_passing(passing_r)
	elif not travel_only_r.is_empty():
		best = _best_passing(travel_only_r)
		best["note"] = str(best["note"]) + " (camera move passes a body)"
	if best.is_empty() and not cands.is_empty():
		best = cands[0]
		best["note"] = str(best["note"]) + " (no clear sight line; best framing)"
		_beat("reveal: %d framings, none clear: %s" % [cands.size(), str(hist_r)])
	return best


func _choose_pullers(reveal: Dictionary) -> void:
	var c := _skiff_xf.origin
	var eye: Vector3 = (reveal["xf"] as Transform3D).origin if not reveal.is_empty() else _player.global_position
	var to_cam := _tangent(eye - c, _up, _hatch_dir)
	var chosen := {}
	var notes_p := PackedStringArray()
	# Lens tiers: first a walk clear of every eye from now to the reveal (it can start as soon as the lump is
	# there), then one clear of the still reveal eye only (it waits for that frame to settle; _send_pullers).
	var segs_all := _camera_segments()
	var still_eye: Vector3 = segs_all[-1][1]
	var segs_reveal: Array = [[still_eye, still_eye]]
	for pair: Array in [["grig", 1.0, true], ["bolt", -1.0, true], ["grig", 1.0, false], ["bolt", -1.0, false]]:
		var id: String = pair[0]
		var sgn: float = pair[1]
		var strict: bool = pair[2]
		if chosen.has(id):
			continue
		notes_p.append("%s:tier%d" % [id, 1 if strict else 2])
		for deg: float in PULLER_ANGLES:
			var dir := to_cam.rotated(_up, deg_to_rad(deg * sgn))
			var p := _planet.surface_point(_planet.dir_of(c + dir * PULLER_R))
			var why := ""
			if _has_mast and _mast_pos.distance_to(p) < MAST_CLEAR_M:
				why = "mast"
			if why == "":
				why = _ground(_planet.dir_of(p))
			var npc_n := _meeting.call("npc", id) as Node3D
			if why == "" and npc_n != null:
				var from := npc_n.global_position
				var up_f := _planet.up_at(from)
				# Straight there, or round the pad by one waypoint; every leg clear of near meshes and colliders.
				var legs: Array[Vector3] = [from]
				if _chord_min(from, p) < PAD_WALK_CLEAR_M:
					var wp := _around_pad(from, p)
					if wp == Vector3.INF:
						why = "path_across_pad"
					else:
						legs.append(wp)
				legs.append(p)
				for li in legs.size() - 1:
					if why != "":
						break
					var la := legs[li] + _planet.up_at(legs[li]) * 0.5
					var lb := legs[li + 1] + _planet.up_at(legs[li + 1]) * 0.5
					var hit := _occluder_on(la, lb, 0.0)
					if hit == "":
						hit = _ray(la, lb)
					if hit != "":
						why = "path%d:%s" % [li, hit]
				if why == "":
					var lens := _walk_lens_clear(from, legs.slice(1), segs_all if strict else segs_reveal)
					if lens < PULLER_LENS_M:
						why = "lens%.2f" % lens
			notes_p.append("%s%+d:%s" % [id, int(deg * sgn), why if why != "" else "ok"])
			if why == "":
				chosen[id] = p
				break
		if not chosen.has(id) and not strict:
			chosen[id] = _planet.surface_point(_planet.dir_of(c + to_cam.rotated(_up, deg_to_rad(PULLER_ANGLES[0] * sgn)) * PULLER_R))
			notes_p.append("%s:fallback" % id)
	_pullers = chosen
	var notes := PackedStringArray()
	for id: String in chosen.keys():
		var n := _meeting.call("npc", id) as Node3D
		var wps: Array = []
		if n != null:
			if _chord_min(n.global_position, chosen[id] as Vector3) < PAD_WALK_CLEAR_M:
				var wp := _around_pad(n.global_position, chosen[id] as Vector3)
				if wp != Vector3.INF:
					wps.append(wp)
		wps.append(chosen[id])
		_puller_wps[id] = wps
		notes.append("%s at %.2f m, %d waypoints" % [id, (chosen[id] as Vector3).distance_to(c), wps.size() - 1])
	_beat("pullers " + ", ".join(notes) + " | tried " + " ".join(notes_p))


## The piece's sample points (world), its outward normal and the least facing dot.
func _piece_geom(piece: String) -> Dictionary:
	var xf := _skiff_xf
	var ap := SkiffMeshLib.APOTHEM
	match piece:
		"hatch":
			var pts := [Vector3(0.0, 1.09, -ap - 0.02), Vector3(0.0, SkiffMeshLib.HATCH_Y1, -ap - 0.02),
				Vector3(0.0, SkiffMeshLib.HATCH_Y0, -ap - 0.02), Vector3(0.2, 1.09, -ap - 0.02), Vector3(-0.2, 1.09, -ap - 0.02)]
			return {"pts": _to_world(xf, pts), "n": xf.basis * Vector3(0, 0, -1), "dot": 0.5}
		"lamp":
			var pts2 := [Vector3(0.0, SkiffMeshLib.LAMP_Y, -ap - 0.12), Vector3(0.0, SkiffMeshLib.LAMP_Y + 0.12, -ap - 0.05),
				Vector3(0.12, SkiffMeshLib.LAMP_Y, -ap - 0.1), Vector3(-0.12, SkiffMeshLib.LAMP_Y, -ap - 0.1)]
			return {"pts": _to_world(xf, pts2), "n": (xf.basis * Vector3(0, -0.2, -1)).normalized(), "dot": 0.25}
		"ladder":
			var lf := SkiffMeshLib.LADDER_FOOT_R
			var pts3 := [Vector3(0.0, 0.40, -(ap + lf) * 0.5), Vector3(0.0, SkiffMeshLib.LADDER_TOP_Y, -ap - 0.03),
				Vector3(0.0, 0.22, -lf + 0.03), Vector3(0.16, 0.40, -(ap + lf) * 0.5), Vector3(-0.16, 0.40, -(ap + lf) * 0.5)]
			return {"pts": _to_world(xf, pts3), "n": (xf.basis * Vector3(0, 0.25, -1)).normalized(), "dot": 0.25}
		"dish":
			var th := deg_to_rad(SkiffMeshLib.DISH_DEG)
			var out := Vector3(sin(th), 0.0, -cos(th))
			var tilt := deg_to_rad(SkiffMeshLib.DISH_TILT_DEG)
			var n := (Vector3.UP * cos(tilt) + out * sin(tilt)).normalized()
			var centre := SkiffMeshLib.polar(0.80, th, 1.80) + n * 0.08
			var side := n.cross(Vector3.UP).normalized()
			var pts4 := [centre, centre + side * 0.2, centre - side * 0.2, centre + n.cross(side).normalized() * 0.2]
			return {"pts": _to_world(xf, pts4), "n": (xf.basis * (n + out * 0.6)).normalized(), "dot": 0.2}
		"antenna":
			var bulb := SkiffMeshLib.bulb_pos()
			var base := Vector3(bulb.x, SkiffMeshLib.COLLAR_Y1, bulb.z)
			var pts5 := [bulb, bulb.lerp(base, 0.4), bulb + Vector3(0, 0.08, 0)]
			var outw := Vector3(bulb.x, 0.0, bulb.z).normalized()
			return {"pts": _to_world(xf, pts5), "n": (xf.basis * (outw + Vector3.UP * 0.9)).normalized(), "dot": -0.05}
	return {}


static func _to_world(xf: Transform3D, pts: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for p: Vector3 in pts:
		out.append(xf * p)
	return out


func _solve_piece(piece: String, prev: Dictionary, next: Dictionary = {}) -> Dictionary:
	var g := _piece_geom(piece)
	if g.is_empty():
		return {}
	var pts: PackedVector3Array = g["pts"]
	var centre := pts[0]
	var n: Vector3 = g["n"]
	var min_dot: float = g["dot"]
	var aim := centre.lerp(_skiff_mid(), 0.5)
	var whole_pts := PackedVector3Array([_skiff_xf.origin + _up * 2.35, _skiff_xf.origin + _up * 0.02])
	var cands: Array[Dictionary] = []
	_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
	for i in AZ_STEPS:
		if Time.get_ticks_usec() > _solve_budget_end:
			await get_tree().process_frame
			_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
		var az := TAU * float(i) / float(AZ_STEPS)
		var dir := _hatch_dir.rotated(_up, az)
		for dist: float in PIECE_DISTS:
			for h: float in PIECE_HEIGHTS:
				var cand := _candidate(dir, dist, h, aim, 0.40, PIECE_FOV)
				if cand.is_empty():
					continue
				var eye: Vector3 = (cand["xf"] as Transform3D).origin
				if n.dot((eye - centre).normalized()) < min_dot:
					continue
				if _frame_gate(cand, pts, []) != "":
					continue
				# The whole skiff shows (its legs may pass under the box): the piece reads as part of her.
				var whole_ok := true
				for wp: Vector3 in whole_pts:
					var wuv := _uv(cand["xf"] as Transform3D, PIECE_FOV, wp)
					whole_ok = whole_ok and wuv.x > 0.04 and wuv.x < 0.96 and wuv.y > 0.04 and wuv.y < 0.97
				if not whole_ok:
					continue
				if _self_occluded(eye, pts):
					continue
				var score := 0.0
				if not prev.is_empty():
					score += _effort(prev["xf"] as Transform3D, float(prev["fov"]), cand["xf"] as Transform3D, float(cand["fov"]))
				score += absf(dist - 4.8) * 0.25
				# Square onto the piece reads best.
				score += (1.0 - n.dot((eye - centre).normalized())) * 1.5
				cand["score"] = score
				cand["note"] = "az%d d%.1f h%.1f" % [int(rad_to_deg(az)), dist, h]
				cands.append(cand)
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) < float(b["score"]))
	var tries := 0
	var hist := {}
	var passing: Array[Dictionary] = []
	var travel_only: Array[Dictionary] = []
	_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
	for cand: Dictionary in cands:
		tries += 1
		if tries > CAND_RAY_TRIES:
			break
		if Time.get_ticks_usec() > _solve_budget_end:
			await get_tree().process_frame
			_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
		var why := _sight_gate(cand, pts, [], _control)
		if why == "":
			var eye_c: Vector3 = (cand["xf"] as Transform3D).origin
			for pair: Array in [[prev, true], [next, false]]:
				var other_s: Dictionary = pair[0]
				if why != "" or other_s.is_empty():
					continue
				var oe: Vector3 = (other_s["xf"] as Transform3D).origin
				# A start or end eye already beside a body (the rig pose, a fallback) cannot be helped here.
				if _travel_gate(oe, oe, _control) != "":
					continue
				why = _travel_gate(oe, eye_c, _control) if bool(pair[1]) else _travel_gate(eye_c, oe, _control)
			if why != "":
				travel_only.append(cand)
		if why == "":
			passing.append(cand)
			if passing.size() >= PASS_KEEP:
				break
			continue
		var key := why.get_slice("@", 0)
		hist[key] = int(hist.get(key, 0)) + 1
	if not passing.is_empty():
		return _best_passing(passing)
	if not travel_only.is_empty():
		var bt := _best_passing(travel_only)
		bt["note"] = str(bt["note"]) + " (camera move passes a body)"
		return bt
	# Another friend's shot that already shows this piece clearly (the ladder hangs under the hatch).
	for key: String in _shots.keys():
		var other: Dictionary = _shots[key]
		if other.is_empty() or not other.has("xf"):
			continue
		var oeye: Vector3 = (other["xf"] as Transform3D).origin
		if n.dot((oeye - centre).normalized()) < min_dot or _frame_gate(other, pts, []) != "" or _self_occluded(oeye, pts):
			continue
		var probe := {"xf": other["xf"], "fov": other["fov"], "score": 0.0}
		if _sight_gate(probe, pts, [], _control) == "":
			var reuse := other.duplicate()
			reuse["note"] = "reuses %s" % key
			return reuse
	_beat("piece %s: %d framings, none with clear sight in %d tries: %s" % [piece, cands.size(), mini(tries, CAND_RAY_TRIES), str(hist)])
	if not cands.is_empty():
		var c0: Dictionary = cands[0]
		c0["note"] = str(c0["note"]) + " (sight not clear)"
		return c0
	return {}


func _best_passing(list: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = {}
	var best_s := INF
	for c: Dictionary in list:
		var sc := float(c["score"]) + FG_WEIGHT * float(c.get("clutter", 0.0)) + 2.0 * FG_WEIGHT * float(c.get("cover", 0.0))
		if sc < best_s:
			best_s = sc
			best = c
	best["note"] = "%s clutter %.3f cover %.3f of %d passing" % [str(best["note"]), float(best.get("clutter", 0.0)), float(best.get("cover", 0.0)), list.size()]
	return best


## An eye `dist` along `dir` from the skiff, `h` above the ground there, aimed so `aim` sits at `v` of the
## frame height from the top. Empty when the eye is under the ground, inside something, or looks down
## too steeply.
func _candidate(dir: Vector3, dist: float, h: float, aim: Vector3, v: float, fov: float) -> Dictionary:
	var c := _skiff_xf.origin
	var ground := _planet.surface_point(_planet.dir_of(c + dir * dist))
	var up := _planet.up_at(ground)
	var eye := ground + up * h
	var d := (aim - eye).normalized()
	if absf(d.dot(up)) > 0.98:
		return {}
	var b := Basis.looking_at(d, up)
	# Tilt down so `aim` lands above the centre: the camera pitches by the angle that moves it to `v`.
	var tv := tan(deg_to_rad(fov) * 0.5)
	var ang := atan((0.5 - v) * 2.0 * tv)
	var tilted := Basis(b.x, -ang) * b
	if absf(_uv(Transform3D(tilted, eye), fov, aim).y - v) > 0.01:
		tilted = Basis(b.x, ang) * b
	b = tilted
	var look_down := rad_to_deg(asin(clampf(-(-b.z).dot(up), -1.0, 1.0)))
	if look_down > MAX_LOOK_DOWN_DEG:
		return {}
	return {"xf": Transform3D(b.orthonormalized(), eye), "fov": fov}


func _frame_gate(cand: Dictionary, pts: PackedVector3Array, _ignore: Array) -> String:
	var xf: Transform3D = cand["xf"]
	var fov: float = cand["fov"]
	for p: Vector3 in pts:
		var uv := _uv(xf, fov, p)
		if uv.x < SAFE_X.x or uv.x > SAFE_X.y or uv.y < SAFE_Y.x or uv.y > SAFE_Y.y:
			return "frame"
	return ""


## Screen position (0-1, y from the top) of `p` for a camera at `xf` with vertical FOV `fov`.
func _uv(xf: Transform3D, fov: float, p: Vector3) -> Vector2:
	var v := p - xf.origin
	var fwd := -xf.basis.z
	var z := v.dot(fwd)
	if z < 0.2:
		return Vector2(-9.0, -9.0)
	var tv := tan(deg_to_rad(fov) * 0.5)
	return Vector2(0.5 + 0.5 * v.dot(xf.basis.x) / (z * tv * _aspect), 0.5 - 0.5 * v.dot(xf.basis.y) / (z * tv))


## True when a sight line from `eye` to any sample point passes through the skiff's own body (drum and
## collar r 0.80 from 0.6 to 1.72 m, canopy r 0.58 to 2.06 m), ignoring its first 12 cm at the piece.
func _self_occluded(eye: Vector3, pts: PackedVector3Array) -> bool:
	var inv := _skiff_xf.affine_inverse()
	var e := inv * eye
	for p_w: Vector3 in pts:
		var p := inv * p_w
		var seg := e - p
		var l := seg.length()
		# Past 2.5 m from the piece the line is clear of a body 0.8 m in radius.
		var steps := int(ceil(minf(l, 2.5) / 0.08))
		for s in steps:
			var t := (0.12 + float(s) * 0.08) / l
			if t >= 1.0:
				break
			var q := p + seg * t
			var r := Vector2(q.x, q.z).length()
			if (q.y > 0.6 and q.y < 1.72 and r < 0.80) or (q.y >= 1.72 and q.y < 2.06 and r < 0.58):
				return true
	return false


## "" when every sight line from the candidate's eye to `pts` is clear of the crowd (except `skip`), the
## astronaut standing at `astro`, the pad's mast and the physics world, with no body near the lens.
func _sight_gate(cand: Dictionary, pts: PackedVector3Array, skip: Array, astro: Vector3) -> String:
	var eye: Vector3 = (cand["xf"] as Transform3D).origin
	var bodies: Array = []
	for id in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n == null:
			continue
		var pos := n.global_position
		if _pullers.has(id):
			pos = _pullers[id]
		elif skip.has(id):
			continue
		bodies.append([id, pos, _planet.up_at(pos), 1.45, 0.42])
	bodies.append(["astronaut", astro, _planet.up_at(astro), 1.6, 0.40])
	if _has_mast:
		bodies.append(["mast", _mast_pos, _mast_up, 7.6, 0.24])
	for b: Array in bodies:
		var feet: Vector3 = b[1]
		var bu: Vector3 = b[2]
		var top := feet + bu * float(b[3])
		if _seg_seg_dist(eye, eye, feet, top) < LENS_CLEAR_M:
			return "lens:" + str(b[0])
		for p: Vector3 in pts:
			if _seg_seg_dist(eye, p, feet, top) < float(b[4]):
				return "body:" + str(b[0])
	if not _sphere_clear(eye, 0.35):
		return "eye_inside"
	for p1: Vector3 in pts:
		var o := _occluder_on(eye, p1, OCC_LENS_M)
		if o != "":
			return "mesh:" + o
	var fg := _foreground(cand, pts[0])
	cand["clutter"] = float(fg[0])
	cand["cover"] = float(fg[2])
	if float(fg[0]) > FG_MAX_SHARE:
		return "foreground:" + str(fg[1])
	if float(fg[2]) > FG_MAX_COVER:
		return "covers_skiff:" + str(fg[1])
	for p2: Vector3 in pts:
		var hit := _ray(eye, p2)
		if hit != "":
			return "world:" + hit
	return ""


## {id: clearance} for each crowd body standing within TRAVEL_CLEAR_M of a straight camera move between the
## solved shots in play order (reveal, the five pieces, the final estimate). A move whose own start or end
## eye is already that close to the body is not counted (no spot change helps it).
func _move_blockers(final_est: Dictionary) -> Dictionary:
	var eyes: Array[Vector3] = []
	for key: String in ["reveal", "piece:hatch", "piece:antenna", "piece:lamp", "piece:ladder", "piece:dish"]:
		if _shots.has(key) and not (_shots[key] as Dictionary).is_empty():
			eyes.append((_shots[key]["xf"] as Transform3D).origin)
	if not final_est.is_empty():
		eyes.append((final_est["xf"] as Transform3D).origin)
	var out := {}
	for id in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n == null:
			continue
		var pos: Vector3 = _pullers[id] if _pullers.has(id) else n.global_position
		var top := pos + _planet.up_at(pos) * PULLER_BODY_H
		for i in eyes.size() - 1:
			if _seg_seg_dist(eyes[i], eyes[i], pos, top) < TRAVEL_CLEAR_M or _seg_seg_dist(eyes[i + 1], eyes[i + 1], pos, top) < TRAVEL_CLEAR_M:
				continue
			var d := _seg_seg_dist(eyes[i], eyes[i + 1], pos, top)
			if d < TRAVEL_CLEAR_M:
				out[id] = minf(float(out.get(id, INF)), d)
	return out


## "" when the straight camera move a -> b keeps TRAVEL_CLEAR_M from every standing crowd body (Grig and
## Bolt at their tarp spots once chosen) and the astronaut at `astro`; else "travel:<id>".
func _travel_gate(a: Vector3, b: Vector3, astro: Vector3) -> String:
	for id in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n == null:
			continue
		var pos: Vector3 = _pullers[id] if _pullers.has(id) else n.global_position
		if _seg_seg_dist(a, b, pos, pos + _planet.up_at(pos) * PULLER_BODY_H) < TRAVEL_CLEAR_M:
			return "travel:" + str(id)
	if _seg_seg_dist(a, b, astro, astro + _planet.up_at(astro) * 1.6) < TRAVEL_CLEAR_M:
		return "travel:astronaut"
	return ""


func _collect_occluders() -> void:
	_occ.clear()
	var c := _skiff_xf.origin
	var skip: Array[Node] = [_skiff, _tarp, _player, _meeting]
	if _old_rocket != null:
		skip.append(_old_rocket)
	for id in _crowd_ids():
		var n := _meeting.call("npc", id) as Node
		if n != null:
			skip.append(n)
	for nm: String in ["HUD", "Environment", "FinaleLaunch", "SkyBodies"]:
		var x := _world.get_node_or_null(nm)
		if x != null:
			skip.append(x)
	_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
	# Variant, not a typed Node: a mesh freed while the search waits a frame must be skipped, not error.
	for node: Variant in _world.find_children("*", "MeshInstance3D", true, false):
		if Time.get_ticks_usec() > _solve_budget_end:
			await get_tree().process_frame
			_solve_budget_end = Time.get_ticks_usec() + SLICE_USEC
		if not is_instance_valid(node) or not (node as Node).is_inside_tree():
			continue
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var skipped := false
		for sk: Node in skip:
			if sk != null and (sk == mi or sk.is_ancestor_of(mi)):
				skipped = true
				break
		if skipped:
			continue
		var box := mi.get_aabb()
		var xf := mi.global_transform
		var centre := xf * box.get_center()
		var half := box.size * 0.5
		var ext := (xf.basis.x * half.x).abs() + (xf.basis.y * half.y).abs() + (xf.basis.z * half.z).abs()
		var radius := ext.length()
		if radius > OCC_MAX_SIZE or centre.distance_to(c) - radius > OCC_REACH_M:
			continue
		var up := _planet.up_at(centre)
		var h := absf((xf.basis.x * half.x).dot(up)) + absf((xf.basis.y * half.y).dot(up)) + absf((xf.basis.z * half.z).dot(up))
		if h * 2.0 < OCC_MIN_H:
			continue
		var shrunk := AABB(box.get_center() - half * OCC_SHRINK, box.size * OCC_SHRINK)
		var corners := PackedVector3Array()
		for k in 8:
			corners.append(xf * shrunk.get_endpoint(k))
		_occ.append([str(mi.name), xf.affine_inverse(), shrunk, centre, radius, corners])


## The name of the first near mesh whose (shrunk) box the segment a-b passes through, or that comes within
## `lens_m` of `a`; "" when clear.
func _occluder_on(a: Vector3, b: Vector3, lens_m: float) -> String:
	var ab := b - a
	var l2 := maxf(ab.length_squared(), 1e-6)
	for o: Array in _occ:
		var centre: Vector3 = o[3]
		var radius: float = o[4]
		var u := clampf((centre - a).dot(ab) / l2, 0.0, 1.0)
		if (a + ab * u).distance_to(centre) > radius + lens_m:
			continue
		var inv: Transform3D = o[1]
		var box: AABB = o[2]
		var la := inv * a
		var lb := inv * b
		if lens_m > 0.0:
			var grown := box.grow(lens_m)
			if grown.has_point(la):
				return str(o[0]) + "@lens"
		if _seg_box(la, lb, box):
			return str(o[0])
	return ""


## The share of the frame above the dialogue box covered by near meshes (their projected, shrunk boxes),
## and the name of the largest. Near: within FG_SHARE of the way to the subject (at least FG_MIN_M).
func _foreground(cand: Dictionary, subject: Vector3) -> Array:
	var xf: Transform3D = cand["xf"]
	var fov: float = cand["fov"]
	var eye := xf.origin
	var reach := maxf(FG_MIN_M, FG_SHARE * eye.distance_to(subject))
	var fwd := -xf.basis.z
	var total := 0.0
	var worst := ""
	var worst_a := 0.0
	# The skiff's own rectangle on screen: a near mesh over it hides the gift, not just clutters the frame.
	var sub := Rect2()
	var first := true
	for q0: Vector3 in [_skiff_xf.origin, _skiff_xf.origin + _up * 2.6]:
		for sx: float in [-1.1, 1.1]:
			var uq := _uv(xf, fov, q0 + xf.basis.x * sx)
			if uq.x < -8.0:
				continue
			if first:
				sub = Rect2(uq, Vector2.ZERO)
				first = false
			else:
				sub = sub.expand(uq)
	var sub_area := maxf(sub.get_area(), 1e-4)
	var cover := 0.0
	for o: Array in _occ:
		var centre: Vector3 = o[3]
		var radius: float = o[4]
		if centre.distance_to(eye) - radius > reach:
			continue
		if (centre - eye).dot(fwd) < -radius:
			continue
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		var behind := 0
		for c: Vector3 in (o[5] as PackedVector3Array):
			var uv := _uv(xf, fov, c)
			if uv.x < -8.0:
				behind += 1
				continue
			lo = lo.min(uv)
			hi = hi.max(uv)
		if behind == 8:
			continue
		if behind > 0:
			# Part of the box is behind the lens: it spans the frame from the visible corners outward.
			lo = lo.min(Vector2(0.0, 0.0)) if lo.x < 0.5 else lo
			hi = Vector2(maxf(hi.x, 1.0), maxf(hi.y, BOX_TOP))
		var x0 := clampf(lo.x, 0.0, 1.0)
		var x1 := clampf(hi.x, 0.0, 1.0)
		var y0 := clampf(lo.y, 0.0, BOX_TOP)
		var y1 := clampf(hi.y, 0.0, BOX_TOP)
		var a := maxf(0.0, x1 - x0) * maxf(0.0, y1 - y0) / BOX_TOP
		total += a
		if not first:
			var inter := sub.intersection(Rect2(Vector2(x0, y0), Vector2(maxf(0.0, x1 - x0), maxf(0.0, y1 - y0))))
			cover += inter.get_area() / sub_area
		if a > worst_a:
			worst_a = a
			worst = str(o[0])
	for id in _crowd_ids():
		var npc_n := _meeting.call("npc", id) as Node3D
		if npc_n == null:
			continue
		var feet: Vector3 = _pullers[id] if _pullers.has(id) else npc_n.global_position
		if feet.distance_to(eye) > reach:
			continue
		var nu := _planet.up_at(feet)
		var side := xf.basis.x * 0.45
		var lo2 := Vector2(INF, INF)
		var hi2 := Vector2(-INF, -INF)
		var seen := false
		for q: Vector3 in [feet - side, feet + side, feet + nu * 1.5 - side, feet + nu * 1.5 + side]:
			var uv2 := _uv(xf, fov, q)
			if uv2.x < -8.0:
				continue
			seen = true
			lo2 = lo2.min(uv2)
			hi2 = hi2.max(uv2)
		if not seen:
			continue
		var a2 := maxf(0.0, clampf(hi2.x, 0.0, 1.0) - clampf(lo2.x, 0.0, 1.0)) * maxf(0.0, clampf(hi2.y, 0.0, BOX_TOP) - clampf(lo2.y, 0.0, BOX_TOP)) / BOX_TOP
		total += a2
		if not first:
			var r2 := Rect2(Vector2(clampf(lo2.x, 0.0, 1.0), clampf(lo2.y, 0.0, BOX_TOP)), Vector2.ZERO).expand(Vector2(clampf(hi2.x, 0.0, 1.0), clampf(hi2.y, 0.0, BOX_TOP)))
			cover += sub.intersection(r2).get_area() / sub_area
		if a2 > worst_a:
			worst_a = a2
			worst = id
	return [total, worst, cover]


static func _seg_box(a: Vector3, b: Vector3, box: AABB) -> bool:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var lo := box.position
	var hi := box.end
	for i in 3:
		if absf(d[i]) < 1e-9:
			if a[i] < lo[i] or a[i] > hi[i]:
				return false
		else:
			var ta := (lo[i] - a[i]) / d[i]
			var tb := (hi[i] - a[i]) / d[i]
			if ta > tb:
				var tmp := ta
				ta = tb
				tb = tmp
			t0 = maxf(t0, ta)
			t1 = minf(t1, tb)
			if t0 > t1:
				return false
	return true


func _ray(from: Vector3, to: Vector3) -> String:
	var space := get_viewport().world_3d.direct_space_state if get_viewport() != null else null
	if space == null:
		return ""
	var dir := to - from
	var l := dir.length()
	if l < 0.4:
		return ""
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * ((l - 0.35) / l), 1 | (1 << 3) | (1 << 6))
	q.exclude = _blocker_rids
	var r := space.intersect_ray(q)
	if r.is_empty():
		return ""
	var col: Object = r.get("collider")
	return str((col as Node).name) if col is Node else "?"


func _sphere_clear(p: Vector3, radius: float) -> bool:
	var space := get_viewport().world_3d.direct_space_state if get_viewport() != null else null
	if space == null:
		return true
	var sh := SphereShape3D.new()
	sh.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis.IDENTITY, p)
	q.collision_mask = 1 | (1 << 3) | (1 << 6)
	q.exclude = _blocker_rids
	return space.intersect_shape(q, 1).is_empty()


static func _seg_seg_dist(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var d1 := q1 - p1
	var d2 := q2 - p2
	var r := p1 - p2
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var t := 0.0
	if a <= 1e-8 and e <= 1e-8:
		return r.length()
	if a <= 1e-8:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c := d1.dot(r)
		if e <= 1e-8:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b := d1.dot(d2)
			var den := a * e - b * b
			s = clampf((b * f - c * e) / den, 0.0, 1.0) if den > 1e-8 else 0.0
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	return (p1 + d1 * s).distance_to(p2 + d2 * t)


static func _effort(a: Transform3D, fov_a: float, b: Transform3D, fov_b: float) -> float:
	var d := a.origin.distance_to(b.origin)
	var ang := rad_to_deg(a.basis.get_rotation_quaternion().angle_to(b.basis.get_rotation_quaternion()))
	return maxf(d / CAM_VMAX, maxf(ang / CAM_WMAX, absf(fov_a - fov_b) / 20.0))


# ============================================================================= helpers
func _crowd_ids() -> Array:
	return _meeting.call("crowd_ids") if _meeting.has_method("crowd_ids") else []


func _crowd_face_point(point: Vector3) -> void:
	for id in _crowd_ids():
		if _pullers.has(id) and _lump_shown and _phase <= Phase.REVEAL:
			continue
		var n := _meeting.call("npc", id) as Node3D
		if n != null and n.has_method("hold_facing"):
			n.call("hold_facing", point)


func _skiff_mid() -> Vector3:
	return _skiff_xf.origin + _up * 1.2


func _begin_modal() -> void:
	if _modal:
		return
	_modal = true
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p != null:
		p.set("input_enabled", false)
		p.set("velocity", Vector3.ZERO)


func _end_modal() -> void:
	if not _modal:
		return
	_modal = false
	EventBus.ui_modal_closed.emit(MODAL_NAME)


## §0: night, clock held, until DONE. Logs the first time it finds the clock running and holds it.
func _check_night(where: String, quiet: bool = false) -> void:
	if _env == null or not is_instance_valid(_env):
		return
	var ts := float(_env.get("time_scale"))
	if ts != 0.0 and not _clock_held:
		_saved_time_scale = ts
		_env.set("time_scale", 0.0)
		_clock_held = true
		_beat("clock was running at %s (time_scale %.3f, hour %.2f): held" % [where, ts, GameState.time_of_day])
	elif not quiet:
		_beat("clock %s time_scale=%.3f hour=%.2f" % [where, ts, GameState.time_of_day])


func _restore_clock() -> void:
	if not _clock_held:
		return
	_clock_held = false
	if _env != null and is_instance_valid(_env):
		_env.set("time_scale", _saved_time_scale)


func _on_campaign_changed() -> void:
	_campaign_changes += 1


func _wait(seconds: float) -> void:
	var t := 0.0
	while is_inside_tree() and t < seconds:
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame


func _exit_tree() -> void:
	# Leaving mid-gift (quit to the title, a scene change): never leave the menus locked, the astronaut
	# frozen or the clock held. The skiff and tarp are children of the pad and go with the world.
	if _phase != Phase.DONE and _phase != Phase.IDLE:
		_end_modal()
		_restore_clock()
		if _player != null and is_instance_valid(_player):
			_player.set_physics_process(true)
			_player.set("input_enabled", true)
		_phase = Phase.DONE
	if EventBus.campaign_changed.is_connected(_on_campaign_changed):
		EventBus.campaign_changed.disconnect(_on_campaign_changed)


static func _smootherstep(x: float) -> float:
	var t := clampf(x, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


static func _tangent(v: Vector3, up: Vector3, fallback: Vector3) -> Vector3:
	var t := v - up * v.dot(up)
	if t.length_squared() < 1e-6:
		t = fallback - up * fallback.dot(up)
	return t.normalized()


func _cam_name() -> String:
	var cam := get_viewport().get_camera_3d() if get_viewport() != null else null
	return str(cam.name) if cam != null else "-"


func _fs_int(method: String) -> int:
	return int(load(FINALE_STATE_PATH).call(method)) if ResourceLoader.exists(FINALE_STATE_PATH) else -1


func _fs_bool(method: String) -> bool:
	return bool(load(FINALE_STATE_PATH).call(method)) if ResourceLoader.exists(FINALE_STATE_PATH) else false


func _beat(msg: String) -> void:
	print("GIFT ", msg)
	if _trace_on and ResourceLoader.exists(FINALE_STATE_PATH):
		load(FINALE_STATE_PATH).call("trace", TRACE_TAG, msg)


# ============================================================================= test hooks
## TEST HOOK: one line for a probe or a Director "call" step.
func debug_report(tag: String = "") -> void:
	print("GIFT REPORT %s phase=%s t=%.2f lump=%s pad_in_view=%s stage=%d shots=%s control=%.2f m campaign_changed=%d" % [
		tag, phase_name(), _t, str(_lump_shown), str(_pad_in_view), _fs_int("stage"), str(_shots.keys()),
		_control.distance_to(_pad_root.global_position) if _pad_root != null else -1.0, _campaign_changes])


## TEST HOOK: the solved shots and pieces, for a probe to measure frames against.
func debug_shots() -> Dictionary:
	var out := {}
	for k: String in _shots.keys():
		out[k] = _shots[k]
	for piece: String in ["hatch", "antenna", "lamp", "ladder", "dish"]:
		out["pts:" + piece] = _piece_geom(piece).get("pts", PackedVector3Array())
	out["control"] = _control
	out["pullers"] = _pullers
	return out
