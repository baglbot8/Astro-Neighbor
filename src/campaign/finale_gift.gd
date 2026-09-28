extends Node
## HOME - the last beat of the finale (docs/STORY_HOME_SPEC.md §2 rulings 8 and 11, §3 beat 10; since the
## user's party version, §8 and §8.1: the ships come back bruised but working, Pip and Pop offer to fix them,
## a party, the self-timer group photo).
## It replaced the skiff gift (docs/PHASE5_SPEC.md §2 "Gift") on 2026-09-27; the file keeps its name and
## its contract so finale.gd, the dev menu and the probes need no change: finale.gd instances it by path as
## /root/World/FinaleGift once FinaleLaunch has finished, calls `play(meeting)` and awaits `finished`.
## Nothing here names another finale class: FinaleState, the lines, the meeting and the scrapbook
## (SkyJournal) are reached by path, by node name or through `has_method`.
##
## WHAT HAPPENS
##   back     a navy dip (the meeting's `dip`) over the send-off's last frame; behind it the meeting's
##            `stage_home()` puts everyone back on the Commons - the crowd on its meeting spots, the five
##            ships parked, your rocket on the pad, the astronaut on the mark - and the camera on W. The
##            shower keeps falling over all of HOME at the send-off's closing rate, into whatever camera is
##            drawing (`_feed_sky`, see SKY_IN_FRAME); FinaleLaunch's stragglers run on until finale.gd
##            stops them after this beat. The dip lifts.
##            The five ships and your rocket are still "up there": hidden behind the same dip (`_ships_up`).
##   lines    finale_lines.gd HOME, each box framed the meeting's way (`say_turn`: P on the speaker, W for a
##            back-row speaker such as DJ Nova, who dances). Its actions: "pause" (the crowd on W, a beat of
##            quiet), "return" (`_ships_return`: the camera behind the astronaut looking up over the crowd,
##            the rocket and then the five ships come down one after another onto their spots - the ships
##            bruised, leaning, smoking a little (neighbour_ships.gd `set_bruised`) - a thump as each lands,
##            the crowd turned to watch), "party" (Nova's party track, everyone celebrating at their own
##            offsets for PARTY_S on W).
##   photo    after Bolt's "A photo. Everyone. Now.": THE LAST PHOTO (see below).
##   done     the Professor's last two boxes; the astronaut walks out of the Fly reach (`control_spot`);
##            FinaleState.finish_story() (stage 4, story_done, one campaign_changed, the clock runs again,
##            the checkpoint save - and NO skiff: your rocket stays your rocket); the meeting's camera
##            hands back to the gameplay rig; control; the toast "Every world is open. Planet stats are
##            back."; `finished`. DONE is on disk before the first frame the astronaut can move.
##
## THE LAST PHOTO - A SELF-TIMER SHOT (ruling 2.14 (a), the user 2026-09-27: "can we have astronaut main
## character appear in the final photo as well"). A small viewfinder of this file's own that copies the
## planet safari's camera look (SafariLayer: the cream corner brackets, the focus ring, the white shutter
## disc with a navy ring at MobileUI's primary-button spot, green while held) - not PlanetSafari itself,
## whose session (film, subjects, scoring, the review, the pay) has nothing to photograph on the Commons.
## Behind a dip the camera stands on a tripod PHOTO_BACK_M behind the mark at PHOTO_EYE_H and the astronaut
## stands AMONG the neighbours, front and centre (FinaleMeeting.photo_spot), facing it: a third-person group
## shot, the frame fitted to every head (the astronaut's too), the sky and the shower above them; PhotoMode
## is on so the HUD steps aside. The player presses the shutter once (its release starts it); a 3-2-1
## count runs (TIMER_S, a tick a second, the number big in the middle), everyone starts a jump or a wave at
## their own offset (ruling 2.14 (b)) so the click catches them in different phases, and click. The frame is read with every canvas item culled (the
## safari's own `canvas_cull_mask` trick), shrunk to PHOTO_W, and filed in the scrapbook as the page
## "Home" (Neighbours section, SkyJournal key PAGE_KEY) - see `_file_photo` for what the scrapbook shows
## today and what it needs to show the page as "???" before it is taken. The print is shown for a moment.
## A safety net, not the design: with no press at all for AUTO_TAKE_S the game takes it itself (logged
## "auto"), so a lost input can never leave the ending stuck.
##
## INPUT. The viewfinder eats every touch, click and key while it is up (so a tap never becomes a camera
## drag) and ignores any press that began before it armed (ARM_S). Touch, the left mouse button, F / E /
## Space / Enter and the "interact" / "ui_accept" actions (polled, for a Director tap) all hold the shutter.
##
## NIGHT. The meeting holds the clock at night from the Commons load; finish_story sets it running again.
##
## TRACE. `--finale-trace=<file>` gets "HOME ..." lines through FinaleState.trace; the same go to stdout.

signal finished

const TRACE_TAG := "HOME"
const MODAL_NAME := "cutscene"
const FINALE_STATE_PATH := "res://src/campaign/finale_state.gd"
const LINES_PATH := "res://src/campaign/finale_lines.gd"
## The scrapbook's page for the last photo: planet "hub" (the Commons), id "home".
const PAGE_KEY := "hub:home"
const PAGE_PLANET := "hub"
const PAGE_NAME := "Home"
const PAGE_GRADE := "Gallery"
const PAGE_LINE := "Everyone. Home."
## The safari keeps its photos this wide (PlanetSafari.PHOTO_W; not named here - see the scrapbook's own
## note on never loading the safari's script graph from a small file).
const PHOTO_W := 512

const DIP_OUT_S := 0.4
const DIP_IN_S := 0.6
const MAX_STEP := 0.05
## The photo: the astronaut steps back this far from the mark (toward the pad) to fit everyone in; the lens
## at helmet height; a margin round the heads; the sky share above them.
const PHOTO_BACK_M := 1.9
## Held up high, the way a group photo is taken: at helmet height (1.28 m) the front row hid the back row,
## and at 2.05 m it still hid Pop and Stella (MEASURED on the rendered frames).
const PHOTO_EYE_H := 2.5
const PHOTO_MARGIN_DEG := 5.0
## Each neighbour's width either side of its axis, for the frame fit (Vela's arms were cut at the edge).
const PHOTO_BODY_HALF_W := 0.45
const PHOTO_SKY_SHARE := 0.16
const PHOTO_FOV_MIN := 36.0
const PHOTO_FOV_MAX := 64.0
const ARM_S := 0.6
const AUTO_TAKE_S := 40.0
## The self-timer: 3-2-1, one tick a second, then the click.
const TIMER_S := 3.0
## During the count each one's move starts this long (0.15 .. 0.15 + TIMER_PHASE_S) before the click, a
## different share each (FinaleLaunch.cheer_offset), so the photo holds every jump at its own height.
const TIMER_PHASE_MIN := 0.15
const TIMER_PHASE_S := 1.2
## The astronaut's own jump starts this long before the click.
const ASTRO_PHASE := 0.55
## Helmet top and knee height of the astronaut, for the frame fit.
const ASTRO_TOP_H := 1.35
const ASTRO_LOW_H := 0.35
## HOME's celebrations (ruling 2.14 (b): "stagger their celebrations so it looks more natural"): the
## first round starts spread over CHEER_SPREAD_S; while the viewfinder waits, each one repeats on a period
## of its own (the move's length plus a rest of CHEER_REST_MIN .. + CHEER_REST_S), so they drift, never sync.
const CHEER_SPREAD_S := 1.8
const CHEER_REST_MIN := 0.35
const CHEER_REST_S := 0.7
const LAUNCH_PATH := "res://src/campaign/finale_launch.gd"
## "pause": a beat of quiet on the whole crowd.
const PAUSE_S := 1.4
## "return": the ships and the rocket come down from RETURN_FROM_M above their spots over RETURN_DESCENT_S
## each, one after another RETURN_GAP_S apart.
## THE FRAMING (critic, FINALE3 round 1: on the meeting's W tipped up 9 deg only ONE of the six landed in
## frame - your rocket and four ships came down off screen and were only heard - and the dents could not be
## read at crowd distance). Two shots, both solved from where the crafts really land:
##   wide   a cut to a lens looking down RETURN_EL_DEG on the whole landing field (the pad and the ring of
##          ships round the crowd), RETURN_FOV_ADD wider than W. Its distance is the exact fit of every
##          craft's box on its spot - raised by how high it still is RETURN_SEEN_S before touchdown - into
##          RETURN_FILL of the frame, so each craft is seen for at least its last RETURN_SEEN_S coming
##          down and every touchdown is in frame (the tightest centred fit, solved exactly per heading).
##          Its heading is searched RETURN_AZ_STEP at a time either side of W's (out to RETURN_AZ_MAX) for
##          the fewest crafts hidden behind a building, a prop (VisitorSystem's sight lines) or another
##          craft, then the nearest lens (the biggest crafts). RETURN_WIDE_HOLD_S after the last lands.
##   close  a cut to one bruised ship's hatch side (its soot and scratches, set_bruised), the ship's height
##          filling CLOSE_FILL of the frame, held RETURN_CLOSE_S with a slow push-in of CLOSE_PUSH. The ship
##          is the first in CLOSE_ORDER (Bolt's first: he counts the dents next) with a clear view from
##          one of CLOSE_SIDES_DEG round its hatch (CLOSE_RAISE_M up): no prop or craft in the sight line,
##          and no neighbour, astronaut or other craft inside the frame in front of the ship. Both shots
##          are solved before anything moves.
## WHEN THEY ARE SOLVED (builder ALBUMFIN, 2026-09-28): behind the "back" dip, while the screen is solid
## navy (`_plan_return`), not at the return itself. MEASURED (headless, efficiency cores): solving at the
## return cost one 108.5 ms frame right before the wide cut, and 106.5 ms of it was the ONE call that builds
## VisitorSystem's occluder space (`open_sight`, visitor_system.gd) - wide 1.1 ms, close 0.1 ms. That call
## cannot be split from this file, so slicing wide/close over frames the way finale_meeting.gd slices its
## search would have saved ~1 ms; the cost moves instead to a frame nobody can see. Nothing the solve reads
## changes in between: the crafts are hidden and parked (stage_home + _ships_up), the crowd and the astronaut
## stand on their marks with input off, and W is the meeting's. `_ships_return` re-solves only if no plan was
## made (a debug entry that skips the dip).
## Then a cut back to W for the next line.
const RETURN_FROM_M := 30.0
const RETURN_DESCENT_S := 3.4
const RETURN_GAP_S := 0.55
const RETURN_FOV_ADD := 6.0
const RETURN_EL_DEG := 28.0
const RETURN_SEEN_S := 1.0
const RETURN_FILL := 0.9
const RETURN_AZ_STEP := 15.0
const RETURN_AZ_MAX := 90.0
const RETURN_WIDE_HOLD_S := 0.9
const RETURN_CLOSE_S := 2.8
const CLOSE_FILL := 0.7
const CLOSE_FOV := 40.0
const CLOSE_PUSH := 1.12
## The eye height on the ship, as a share of its height: the middle of the marks' band (_make_bruise puts
## them between 0.55 m and 0.62 h up the hull).
const CLOSE_AIM_H := 0.5
## Up to this far above the aim, looking down on it: the crowd's heads (1.1-1.6 m) drop below the frame.
const CLOSE_RAISE_M: Array[float] = [0.0, 0.8]
const CLOSE_SIDES_DEG: Array[float] = [0.0, 25.0, -25.0, 45.0, -45.0]
const CLOSE_ORDER: PackedStringArray = ["bolt", "zorp", "fen", "vela", "grig"]
## A neighbour's body as a column this wide (radius), for the close-up's clear-view test.
const CLOSE_BODY_R := 0.45
const VISITOR_SYSTEM_PATH := "res://src/campaign/visitor_system.gd"
## "party": event_space.gd's PARTY_TRACK, and how long everyone celebrates before the next line.
const PARTY_TRACK := "event"
const PARTY_S := 3.6
const PRINT_S := 2.8
const PRINT_TAP_S := 0.9
const OVERLAY_LAYER := 90
const SHUTTER_KEYS: Array[Key] = [KEY_F, KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
const SHUTTER_ACTIONS: PackedStringArray = ["interact", "ui_accept"]
## THE SHOWER OVER HOME (§3 beat 10, §5.7 HOME: "Best. Light show. EVER!", "Counted the shooting stars").
## FinaleLaunch's stragglers alone (one every 8-12 s) left HOME's sky empty about 90% of the time (critic,
## round 1), so from the moment everyone is back on the Commons until control returns, this file keeps the
## send-off's closing rate going (FinaleLaunch.home_rate(), streaks per second), each streak's midpoint drawn
## into the camera's view now with SKY_IN_FRAME (the send-off's faces frame uses 0.9 too). The last photo
## always has a shower in it: if fewer than PHOTO_MIN_STREAKS streak heads are in the lens when the shutter
## fires, streaks already in flight are added inside the frame first (two, because one streak reads as a
## straggler, not a shower).
const SKY_IN_FRAME := 0.9
const PHOTO_MIN_STREAKS := 2
const SKY_SEED := 7206

enum Phase { IDLE, BACK, LINES, PHOTO, DONE }

var _phase: int = Phase.IDLE
var _meeting: Node
var _world: Node
var _planet: Planet
var _pad: Node3D
var _player: Node3D
var _rig: Node
var _env: Node
var _lines: Script
var _modal := false
var _trace_on := false
var _campaign_changes := 0
var _t := 0.0
var _control_dir := Vector3.ZERO
var _launch: Node
var _sky_on := false
var _sky_acc := 0.0
var _sky_rng := RandomNumberGenerator.new()
var _sky_frames := 0
var _sky_frames_lit := 0
# the ships' return
var _ships: Node3D
var _rocket: Node3D
var _rocket_rest := Transform3D.IDENTITY
## The return, solved behind the "back" dip (`_plan_return`): order, lands, wide, close, note. Empty = none.
var _return_plan: Dictionary = {}

# the photo
var _overlay: CanvasLayer
var _drawer: Control
var _photo_cam: Camera3D
var _viewfinder_on := false
var _armed_at := -1.0
var _holding := false
var _hold_src := ""
var _hold_t := 0.0
var _fired := false
var _shot_how := ""
var _action_down: Dictionary = {}
var _photo_img: Image
## The frame at full size, for the print shown on screen (the scrapbook keeps the PHOTO_W copy).
var _print_img: Image
var _photo_note := ""
var _print_up := false
var _print_close := false
## The self-timer: seconds left (<0 when not counting), and when the click lands (in _t).
var _count_left := -1.0
var _click_at := -1.0
var _astro_jumped := false
# The staggered celebrations: id -> _t of that one's next move; repeat while the viewfinder waits.
var _cheer_next: Dictionary = {}
var _cheer_rest: Dictionary = {}
var _cheer_repeat := false
var _cheer_log := PackedStringArray()


# ============================================================================= public API
## Plays HOME. `meeting` is the FinaleMeeting (any Node; its API is used through has_method).
func play(meeting: Node) -> void:
	if _phase != Phase.IDLE:
		return
	_phase = Phase.BACK
	if not is_inside_tree():
		push_warning("FinaleGift.play: not in the tree")
		finished.emit.call_deferred()
		return
	_meeting = meeting
	for a: String in OS.get_cmdline_user_args():
		_trace_on = _trace_on or a.begins_with("--finale-trace=")
	_begin_modal()
	if not _resolve():
		_beat("a piece of the world is missing (planet/pad/player/meeting); finishing without HOME")
		_finish_story()
		_end_modal()
		finished.emit.call_deferred()
		return
	EventBus.campaign_changed.connect(_on_campaign_changed)
	set_process(true)
	await _wait_for_pad_arrival()
	if not is_inside_tree():
		return
	# Back on the Commons, behind a dip.
	await _meeting.call("dip", 1.0, DIP_OUT_S)
	if not is_inside_tree():
		return
	_meeting.call("stage_home")
	_ships_up()
	_sky_on = _launch != null
	_control_dir = _meeting.call("control_spot") as Vector3 if _meeting.has_method("control_spot") else Vector3.ZERO
	var snapped := bool(_meeting.call("snap_to", "W", []))
	# Still behind the solid dip: solve the return's two shots now (see WHEN THEY ARE SOLVED above).
	_return_plan = _plan_return()
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_beat("back on the Commons: camera W snapped=%s hour=%.2f time_scale=%s control_dir=%s" % [str(snapped),
		GameState.time_of_day, str(_env.get("time_scale")) if _env != null else "-", str(_control_dir != Vector3.ZERO)])
	# The celebration, each at its own offset as the dip lifts (ruling 2.14 (b)).
	_cheer_start(false, CHEER_SPREAD_S)
	await _meeting.call("dip", 0.0, DIP_IN_S)
	if not is_inside_tree():
		return
	_phase = Phase.LINES
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
	for m: String in ["dip", "stage_home", "snap_to", "say_turn", "npc", "camera"]:
		if not _meeting.has_method(m):
			return false
	_planet = _world.get_node_or_null("Planet") as Planet
	_pad = _world.get_node_or_null("Rocket") as Node3D
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_rig = _world.get_node_or_null("CameraRig")
	_env = _world.get_node_or_null("Environment")
	_lines = load(LINES_PATH) as Script if ResourceLoader.exists(LINES_PATH) else null
	_launch = _world.get_node_or_null("FinaleLaunch")
	if _launch != null and not (_launch.has_method("home_streak") and _launch.has_method("home_rate")):
		_launch = null
	_sky_rng.seed = SKY_SEED
	return _planet != null and _pad != null and _player != null and _lines != null


## A load that lands on the Commons by rocket can still be running the pad's arrival (its own camera, then a
## hand-back to the gameplay rig ~2 s after touchdown). The launch waits for it; the debug entry
## (debug_start_gift) skips the launch, so wait here too, with the modal already up.
func _wait_for_pad_arrival() -> void:
	var waited := 0.0
	var arriving := false
	var pad_root := _pad.get_node_or_null("Pad")
	while is_inside_tree() and waited < 20.0:
		var pad_cam := _pad.get("_cam") as Camera3D
		var cam_on := pad_cam != null and is_instance_valid(pad_cam) and pad_cam.current
		var ia := pad_root.get_node_or_null("Interactable") if pad_root != null else null
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


func _process(delta: float) -> void:
	_t += minf(delta, MAX_STEP)
	if _sky_on:
		_feed_sky(minf(delta, MAX_STEP))
	_cheer_tick()
	if _count_left >= 0.0:
		_timer_tick()
	if _viewfinder_on:
		_poll_actions()
		if _holding:
			_hold_t += delta
		if _drawer != null:
			_drawer.queue_redraw()


# ============================================================================= the beats
func _run() -> void:
	var turns: Array = _lines.get("HOME")
	var toast := ""
	for turn: Dictionary in turns:
		if not is_inside_tree():
			return
		if turn.has("toast"):
			toast = str(turn["toast"])
			continue
		if turn.has("action"):
			var aid := str(turn.get("id", ""))
			_beat("action %s t=%.2f" % [aid, _t])
			match aid:
				"photo":
					await _photo()
				"pause":
					_meeting.call("camera_to", "W", [])
					await _wait(PAUSE_S)
				"return":
					await _ships_return()
				"party":
					await _party()
			continue
		var id := str(turn.get("speaker", ""))
		var lines: Array = turn.get("lines", [])
		var n := _meeting.call("npc", id) as Node3D
		if n == null:
			_beat("say %s: not in the crowd, box skipped" % id)
			continue
		if id == "dj_nova" and n.has_method("play_emote"):
			n.call("play_emote", "dance")
		_beat("say %s t=%.2f" % [id, _t])
		await _meeting.call("say_turn", "P", id, lines)
		if _player != null and is_instance_valid(_player):
			_player.set("input_enabled", false)
	await _done(toast)


# ============================================================================= the ships come back
## Behind the "back" dip: the five ships and your rocket are still up there (FinaleLaunch hid them in the flash).
func _ships_up() -> void:
	_ships = _pad.get_node_or_null("NeighbourShips") as Node3D
	if _ships != null and not _ships.has_method("bruised_xf"):
		_ships = null
	if _ships != null:
		_ships.call("set_all_visible", false)
	_rocket = _pad.get("rocket") as Node3D
	if _rocket != null and is_instance_valid(_rocket):
		_rocket_rest = _rocket.global_transform
		_rocket.visible = false
		if _rocket.has_method("set_ladder_deployed"):
			_rocket.call("set_ladder_deployed", false)


## "return" (§8.1: "the ships come back bruised but working"). Awaitable.
func _ships_return() -> void:
	var runner := DialogueRunner.get_or_create(self)
	if runner != null and runner.is_active():
		runner.finish()
	if _player != null and is_instance_valid(_player):
		_player.set("input_enabled", false)
	var plan := _return_plan if not _return_plan.is_empty() else _plan_return()
	_return_plan = {}
	var order: Array[String] = plan["order"]
	var lands: Dictionary = plan["lands"]
	var wide: Array = plan["wide"]
	var close: Array = plan["close"]
	if not wide.is_empty():
		_cut(wide[0], float(wide[1]))
	# Everyone looks up toward the pad, where your rocket comes down first (their faces to the lens).
	_meeting.call("crowd_face", _rocket_rest.origin + _planet.up_at(_rocket_rest.origin) * 6.0)
	_beat("return: %d to land (%s), wide %s, both shots solved %s in %.1f ms" % [order.size(), ",".join(order),
		str(wide[2]) if not wide.is_empty() else "NONE", str(plan["when"]), float(plan["ms"])])
	var t := 0.0
	var landed := {}
	var total := RETURN_GAP_S * float(order.size() - 1) + RETURN_DESCENT_S
	while is_inside_tree() and t < total:
		t += minf(get_process_delta_time(), MAX_STEP)
		for i in order.size():
			var id: String = order[i]
			var land: Transform3D = lands[id]
			var k := clampf((t - RETURN_GAP_S * float(i)) / RETURN_DESCENT_S, 0.0, 1.0)
			var node := _rocket if id == "rocket" else _ships.call("ship", id) as Node3D
			if node == null or not is_instance_valid(node):
				continue
			if k <= 0.0:
				continue
			node.visible = true
			var lup := land.basis.y.normalized()
			var h := RETURN_FROM_M * pow(1.0 - k, 2.2)
			# A wobble on the way down that settles as it lands: bruised, but flying.
			var wob := Basis(land.basis.x.normalized(), 0.10 * sin(t * 6.0 + float(i)) * (1.0 - k)) \
				* Basis(land.basis.z.normalized(), 0.08 * sin(t * 4.3 + 2.0 * float(i)) * (1.0 - k))
			node.global_transform = Transform3D(wob * land.basis, land.origin + lup * h)
			var flame := 0.0 if k >= 1.0 else 0.35 + 0.65 * (1.0 - k)
			if id == "rocket":
				if node.has_method("set_engine"):
					node.call("set_engine", flame > 0.0)
				if node.has_method("set_flame_scale"):
					node.call("set_flame_scale", flame)
			else:
				_ships.call("set_flame", id, flame, t)
			if k >= 1.0 and not landed.has(id):
				landed[id] = true
				node.global_transform = land
				AudioManager.play_sfx_at("rocket_land" if id == "rocket" else "land", land.origin, -3.0 if id == "rocket" else -1.0)
				if id == "rocket" and node.has_method("set_ladder_deployed"):
					node.call("set_ladder_deployed", true)
				_beat("return: %s landed t=%.2f" % [id, t])
		await get_tree().process_frame
	if not is_inside_tree():
		return
	await _wait(RETURN_WIDE_HOLD_S)
	if not is_inside_tree():
		return
	# The close-up on one bruised ship: its soot and scratches, near enough to read.
	if not close.is_empty():
		_beat("return: close-up %s" % str(close[3]))
		_cut(close[0], CLOSE_FOV)
		_meeting.call("camera_to_transform", close[1], CLOSE_FOV, RETURN_CLOSE_S)
		await _wait(RETURN_CLOSE_S)
		if not is_inside_tree():
			return
	else:
		_beat("return: no ship has a clear close-up; the wide shot holds")
		await _wait(RETURN_CLOSE_S)
	_meeting.call("crowd_face_astronaut")
	_meeting.call("snap_to", "W", [])


## Cuts the meeting's camera to `xf` (a blend with nothing left to blend).
## Who comes down (your rocket first, then the five ships), where each lands, and both shots:
## {order, lands, wide, close, ms, when}. Marks the ships bruised (hidden until they come down).
func _plan_return() -> Dictionary:
	var u0 := Time.get_ticks_usec()
	var ids: PackedStringArray = _ships.call("ids") if _ships != null else PackedStringArray()
	var order: Array[String] = ["rocket"]
	for id in ids:
		if _ships.call("ship", id) != null:
			order.append(id)
	var lands := {}
	for id in order:
		if id == "rocket":
			lands[id] = _rocket_rest
		else:
			lands[id] = _ships.call("bruised_xf", id)
			_ships.call("set_bruised", id, true)
	# One sight session (VisitorSystem's space, built while every craft is still hidden up there; the landed
	# crafts are tested as columns of their own instead), closed again at once.
	var axes := _craft_axes(order, lands)
	var vs := _sight_open(_rocket_rest.origin, 120.0)
	var wide := _return_wide(order, lands, axes, vs)
	var close := _return_close(lands, axes, vs)
	if vs != null:
		vs.call("close_sight")
	return {"order": order, "lands": lands, "wide": wide, "close": close,
		"ms": float(Time.get_ticks_usec() - u0) / 1000.0, "when": "behind the dip" if _phase == Phase.BACK else "at the return"}


func _cut(xf: Transform3D, fov: float) -> void:
	_meeting.call("camera_to_transform", xf, fov, 0.0)
	var cam := _meeting.call("camera") as Camera3D
	if cam != null:
		cam.global_transform = xf.orthonormalized()
		cam.fov = fov


## The crafts' mesh box in `node`'s own space (visible or not: they are hidden until they come down).
static func _craft_box(node: Node3D) -> AABB:
	var inv := node.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	for m: Node in meshes:
		var mi := m as MeshInstance3D
		if mi.mesh == null or str(mi.name) == "Flame" or (mi.get_parent() != null and str(mi.get_parent().name) == "Flame"):
			continue
		var b := (inv * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _craft(id: String) -> Node3D:
	return _rocket if id == "rocket" else (_ships.call("ship", id) as Node3D if _ships != null else null)


## VisitorSystem's shared occluder space, opened round `centre` (closed again by `_sight_close`).
func _sight_open(centre: Vector3, reach: float) -> Node:
	if not ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		return null
	var vs := load(VISITOR_SYSTEM_PATH).call("find") as Node
	if vs == null or not vs.has_method("sight_blocker"):
		return null
	vs.call("open_sight", centre, reach)
	return vs


## Whether the line from `eye` to `p` is blocked by anything but `own` (a label fragment, "" for none).
static func _sight_blocked(vs: Node, eye: Vector3, p: Vector3, own: String) -> String:
	if vs == null:
		return ""
	var hit := str(vs.call("sight_blocker", eye, p))
	if hit == "" or (own != "" and hit.to_lower().contains(own.to_lower())):
		return ""
	return hit


## The wide shot: [Transform3D, fov, note], or [] (no W to start from).
## Each landed craft as [ground, top, half-width] (for "one craft stands in front of another").
func _craft_axes(order: Array[String], lands: Dictionary) -> Dictionary:
	var axes := {}
	for id: String in order:
		var node := _craft(id)
		if node == null:
			continue
		var land: Transform3D = lands[id]
		var box := _craft_box(node)
		axes[id] = [land.origin, land.origin + land.basis.y.normalized() * box.end.y, maxf(box.size.x, box.size.z) * 0.5]
	return axes


func _return_wide(order: Array[String], lands: Dictionary, axes: Dictionary, vs: Node) -> Array:
	var w: Array = _meeting.call("shot_xf", "W", [])
	if w.size() != 2 or order.is_empty():
		return []
	var fov := float(w[1]) + RETURN_FOV_ADD
	var vp := get_viewport().get_visible_rect().size
	var asp := vp.x / maxf(vp.y, 1.0)
	var ty := tan(deg_to_rad(fov) * 0.5) * RETURN_FILL
	var tx := ty * asp
	# How high a craft still is RETURN_SEEN_S before touchdown (the descent's own curve, below).
	var h_seen := RETURN_FROM_M * pow(RETURN_SEEN_S / RETURN_DESCENT_S, 2.2)
	var pts: Array[Vector3] = []
	var mids := {}
	var lo := Vector3.INF
	var hi := -Vector3.INF
	var centre := Vector3.ZERO
	for id: String in order:
		var node := _craft(id)
		if node == null:
			continue
		var land: Transform3D = lands[id]
		var box := _craft_box(node)
		var up := land.basis.y.normalized()
		for i in 8:
			var c := land * box.get_endpoint(i)
			for p: Vector3 in [c, c + up * h_seen]:
				pts.append(p)
				lo = lo.min(p)
				hi = hi.max(p)
		mids[id] = land * box.get_center()
		centre += land.origin
	centre /= float(mids.size())
	var aim := (lo + hi) * 0.5
	var up_c := _planet.up_at(centre)
	var wxf: Transform3D = w[0]
	var head0 := _tangent(-wxf.basis.z, up_c, centre - _rocket_rest.origin)
	var el := deg_to_rad(RETURN_EL_DEG)
	var best: Array = []
	var best_key := Vector2(INF, INF)
	var steps := int(round(RETURN_AZ_MAX / RETURN_AZ_STEP))
	for k in 2 * steps + 1:
		var az := RETURN_AZ_STEP * float((k + 1) / 2) * (1.0 if k % 2 == 1 else -1.0)
		var head := head0.rotated(up_c, deg_to_rad(az))
		var fwd := (head * cos(el) - up_c * sin(el)).normalized()
		var basis := Basis.looking_at(fwd, up_c)
		# The nearest lens that holds every point, centred on them: in the lens's own axes (x right, y up, z
		# forward) a point is inside the side planes when x - tx z <= ex - tx ez and x + tx z >= ex + tx ez,
		# so the tightest eye has ex - tx ez = max(x - tx z), ex + tx ez = min(x + tx z); the same for y.
		# The eye then takes the further back of the two depths, centred on both.
		var ax_hi := -INF
		var ax_lo := INF
		var ay_hi := -INF
		var ay_lo := INF
		for p: Vector3 in pts:
			var q := p - aim
			var z := q.dot(fwd)
			ax_hi = maxf(ax_hi, q.dot(basis.x) - tx * z)
			ax_lo = minf(ax_lo, q.dot(basis.x) + tx * z)
			ay_hi = maxf(ay_hi, q.dot(basis.y) - ty * z)
			ay_lo = minf(ay_lo, q.dot(basis.y) + ty * z)
		var ez := minf((ax_lo - ax_hi) / (2.0 * tx), (ay_lo - ay_hi) / (2.0 * ty))
		var eye := aim + basis.x * ((ax_hi + ax_lo) * 0.5) + basis.y * ((ay_hi + ay_lo) * 0.5) + fwd * ez
		var d := eye.distance_to(aim)
		var hidden := PackedStringArray()
		for id: String in mids:
			var hit := _sight_blocked(vs, eye, mids[id], "rocket" if id == "rocket" else "ship_" + id)
			if hit == "":
				hit = _craft_between(axes, id, eye, mids[id])
			if hit != "":
				hidden.append("%s<%s" % [id, hit.get_file()])
		var key := Vector2(float(hidden.size()), -ez)
		if key.x < best_key.x or (key.x == best_key.x and key.y < best_key.y):
			best_key = key
			best = [Transform3D(basis, eye), fov, "az=%+.0f d=%.1fm fov=%.1f hidden=[%s]" % [az, d, fov, ",".join(hidden)]]
	return best


## The other craft whose body (a column of its own half-width, ground to top) the sight line from `eye` to
## `p` passes through, or "": one landed ship standing in front of another.
static func _craft_between(axes: Dictionary, id: String, eye: Vector3, p: Vector3) -> String:
	for other: String in axes:
		if other == id:
			continue
		var ax: Array = axes[other]
		var cp := Geometry3D.get_closest_points_between_segments(eye, p, ax[0], ax[1])
		if cp[0].distance_to(cp[1]) < float(ax[2]):
			return "craft:" + other
	return ""


## The close-up: [start Transform3D, end Transform3D (the push-in), fov, note], or [] (none clear).
func _return_close(lands: Dictionary, axes: Dictionary, vs: Node) -> Array:
	if _ships == null:
		return []
	var ty := tan(deg_to_rad(CLOSE_FOV) * 0.5)
	var vp := get_viewport().get_visible_rect().size
	var tx := ty * vp.x / maxf(vp.y, 1.0)
	var bodies: Array[Node3D] = []
	for cid: Variant in _meeting.call("crowd_ids"):
		var n := _meeting.call("npc", str(cid)) as Node3D
		if n != null:
			bodies.append(n)
	if _player != null and is_instance_valid(_player):
		bodies.append(_player)
	var out: Array = []
	var tried := PackedStringArray()
	for id: String in CLOSE_ORDER:
		var node := _craft(id)
		if node == null or not lands.has(id) or not out.is_empty():
			continue
		var land: Transform3D = lands[id]
		var box := _craft_box(node)
		var up := land.basis.y.normalized()
		var hatch := _tangent(-land.basis.z, up, land.basis.x)
		var aim := land.origin + up * (box.size.y * CLOSE_AIM_H)
		# From the hull's front (hull_r out from the axis), the ship's height fills CLOSE_FILL of the frame.
		var dist := box.size.y * 0.5 / CLOSE_FILL / ty + float(node.get_meta("hull_r", box.size.z * 0.5))
		for raise: float in CLOSE_RAISE_M:
			for side: float in CLOSE_SIDES_DEG:
				if not out.is_empty():
					break
				var dir := hatch.rotated(up, deg_to_rad(side))
				var eye := aim + dir * dist + up * raise
				var eye_out := aim + (eye - aim) * CLOSE_PUSH
				var why := _sight_blocked(vs, eye_out, aim, "ship_" + id)
				if why == "":
					why = _craft_between(axes, id, eye_out, aim)
				if why == "":
					# From where the push-in starts: the widest this shot ever sees.
					why = _body_in_view(bodies, eye_out, aim, up, tx, ty, eye_out.distance_to(aim))
				if why == "":
					why = _craft_in_view(axes, id, eye_out, aim, up, tx, ty)
				if why != "":
					tried.append("%s@%+.0f/%.1f<%s" % [id, side, raise, why.get_file()])
					continue
				var end := Transform3D(Basis.looking_at(aim - eye, up), eye)
				var eye0 := aim + (eye - aim) * CLOSE_PUSH
				var start := Transform3D(Basis.looking_at(aim - eye0, up), eye0)
				out = [start, end, CLOSE_FOV, "%s side=%+.0f raise=%.1f dist=%.2fm (refused: %s)" % [id, side, raise, dist, ",".join(tried)]]
	return out


## Another landed craft standing inside the close-up's frame NEARER the lens than the ship it is on (a hull
## cut by the frame edge in front of the subject), or "". A craft behind the subject is only background.
static func _craft_in_view(axes: Dictionary, id: String, eye: Vector3, aim: Vector3, cam_up: Vector3, tx: float, ty: float) -> String:
	var fwd := (aim - eye).normalized()
	var basis := Basis.looking_at(fwd, cam_up)
	var depth := eye.distance_to(aim)
	for other: String in axes:
		if other == id:
			continue
		var ax: Array = axes[other]
		var r := float(ax[2])
		for f: float in [0.1, 0.5, 0.9]:
			var v := (ax[0] as Vector3).lerp(ax[1], f) - eye
			var z := v.dot(fwd)
			if z <= 0.0 or z > depth:
				continue
			if absf(v.dot(basis.x)) <= z * tx + r and absf(v.dot(basis.y)) <= z * ty + r:
				return "craft:" + other
	return ""


## The first neighbour (or the astronaut) standing inside the close-up's frame in front of the ship, or "".
func _body_in_view(bodies: Array[Node3D], eye: Vector3, aim: Vector3, cam_up: Vector3, tx: float, ty: float, dist: float) -> String:
	var fwd := (aim - eye).normalized()
	var basis := Basis.looking_at(fwd, cam_up)
	for n: Node3D in bodies:
		if not is_instance_valid(n) or not n.is_visible_in_tree():
			continue
		var feet := n.global_position
		var up := _planet.up_at(feet)
		for hgt: float in [0.3, 0.8, 1.3]:
			var v := feet + up * hgt - eye
			var z := v.dot(fwd)
			if z <= 0.0 or z > dist:
				continue
			var r := CLOSE_BODY_R
			if absf(v.dot(basis.x)) <= z * tx + r and absf(v.dot(basis.y)) <= z * ty + r:
				return "body:" + str(n.name)
	return ""


## "party": Nova's party track and everyone celebrating, each at its own offset, on the whole crowd.
func _party() -> void:
	AudioManager.play_music(PARTY_TRACK, 1.0)
	_meeting.call("camera_to", "W", [])
	_cheer_start(true, CHEER_SPREAD_S)
	await _wait(PARTY_S)
	_cheer_stop()


# ============================================================================= the shower over HOME
## FinaleLaunch.home_rate() streaks a second into whatever camera is drawing (the meeting's, or the lens).
func _feed_sky(dt: float) -> void:
	if _launch == null or not is_instance_valid(_launch):
		_sky_on = false
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var rate := float(_launch.call("home_rate"))
	_sky_acc += dt * rate
	while _sky_acc >= 1.0:
		_sky_acc -= 1.0
		# Spread over the frame's time slice so streaks never start in step.
		_launch.call("home_streak", _cam_frame(cam), SKY_IN_FRAME, _sky_rng.randf_range(0.0, 1.0 / maxf(rate, 0.1)))
	_sky_frames += 1
	if int(_launch.call("shower_on_screen", cam)) > 0:
		_sky_frames_lit += 1


## The UPPER HALF of `cam`'s view now, as `[Transform3D, vfov_deg, aspect]` (StarShower's frame format;
## Camera3D.fov is vertical): every HOME shot is framed on faces with the sky above them, and a streak aimed
## at the whole frame mostly landed behind the crowd and the town hall (MEASURED, second HOME run: DJ Nova's
## "Best. Light show. EVER!" W frame showed none). The upper half spans pitch 0..fov/2 above the axis: a
## frame pitched up by fov/4, fov/2 tall, as wide in tan space as the real one.
func _cam_frame(cam: Camera3D) -> Array:
	var vr := get_viewport().get_visible_rect().size
	var aspect := vr.x / maxf(vr.y, 1.0)
	var half_v := deg_to_rad(cam.fov * 0.5)
	var tx := tan(half_v) * aspect
	var xf := cam.global_transform
	var b := xf.basis.rotated(xf.basis.x.normalized(), half_v * 0.5)
	return [Transform3D(b, xf.origin), cam.fov * 0.5, tx / tan(half_v * 0.5)]


## Before the shutter's frame is read: at least PHOTO_MIN_STREAKS streak heads in the lens (see the constant).
func _photo_shower() -> void:
	if _launch == null or not is_instance_valid(_launch) or _photo_cam == null:
		return
	var before := int(_launch.call("shower_on_screen", _photo_cam))
	var added := 0
	var tries := 0
	while int(_launch.call("shower_on_screen", _photo_cam)) < PHOTO_MIN_STREAKS and tries < 8:
		tries += 1
		# Already a fifth of a second into its flight: bright, with a tail, the frame it is taken in.
		_launch.call("home_streak", _cam_frame(_photo_cam), 1.0, -0.2)
		added += 1
	# The shower draws what was just queued on its next frame.
	await get_tree().process_frame
	_beat("photo sky: %d streak heads in the lens, %d added in flight -> %d" % [before, added,
		int(_launch.call("shower_on_screen", _photo_cam))])


# ============================================================================= the last photo
func _photo() -> void:
	_phase = Phase.PHOTO
	var runner := DialogueRunner.get_or_create(self)
	if runner != null and runner.is_active():
		runner.finish()
	await _meeting.call("dip", 1.0, DIP_OUT_S)
	if not is_inside_tree():
		return
	var frame := _photo_frame()
	_photo_cam = Camera3D.new()
	_photo_cam.name = "PhotoCamera"
	_photo_cam.near = 0.05
	_photo_cam.far = 400.0
	var mcam := _meeting.call("camera") as Camera3D
	if mcam != null:
		_photo_cam.cull_mask = mcam.cull_mask
	add_child(_photo_cam)
	_photo_cam.global_transform = frame[0]
	_photo_cam.fov = float(frame[1])
	_photo_cam.current = true
	# The astronaut is IN the picture (placed by _photo_frame), posed by this node: physics must not re-pick
	# "idle" under the jump.
	_player.visible = true
	_player.set("velocity", Vector3.ZERO)
	# Physics stays ON here on purpose (round 2, docs/OPEN_ISSUES.md): the old code switched physics
	# off to stop _select_state re-picking "idle" under the jump, but EventBus's stuck-player
	# watchdog (event_bus.gd ~167, STUCK_GRACE 12 s) has no idea a cutscene is running and forces
	# physics back on once the viewfinder has waited that long - and player.gd's own _select_state
	# then fought the timer's "happy" pose every physics frame after that, with the sudden re-enable
	# after 12+ s off also costing the astronaut a ~5 cm slide. `play_emote` (_timer_tick, below) is
	# the idiom that actually holds a pose against _select_state - the same call the neighbours' own
	# cheering already uses (_cheer_tick) - so physics is simply never turned off here at all.
	var model := _player.call("get_model") as Node if _player.has_method("get_model") else null
	if model != null and model.has_method("set_state"):
		model.call("set_state", "idle")
	for id: String in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n != null and n.has_method("hold_facing"):
			n.call("hold_facing", (frame[0] as Transform3D).origin)
	PhotoMode.begin(PAGE_PLANET)
	_build_overlay()
	_viewfinder_on = true
	_armed_at = _t + ARM_S
	_cheer_start(true, CHEER_SPREAD_S)
	_beat("viewfinder up (self-timer): eye %s fov %.1f (fitted to %d heads + the astronaut) %s astro_in_view=%s" % [
		str((frame[0] as Transform3D).origin), float(frame[1]), _crowd_ids().size(), str(frame[2]),
		str(_photo_cam.is_position_in_frustum(_player.global_position + _planet.up_at(_player.global_position) * 0.8))])
	await _meeting.call("dip", 0.0, DIP_IN_S)
	var waited := 0.0
	while is_inside_tree() and not _fired:
		waited += minf(get_process_delta_time(), MAX_STEP)
		if waited >= AUTO_TAKE_S and not _holding:
			_shot_how = "auto (no press for %.0f s)" % AUTO_TAKE_S
			_fired = true
			break
		await get_tree().process_frame
	if not is_inside_tree():
		return
	# The self-timer: 3, 2, 1, click.
	_start_timer()
	while is_inside_tree() and _count_left >= 0.0:
		await get_tree().process_frame
	if not is_inside_tree():
		return
	await _photo_shower()
	await _capture()
	_cheer_stop()
	await _show_print()
	if not is_inside_tree():
		return
	# Back to the Commons for the Professor: the astronaut on the mark again, the camera on his close-up.
	await _meeting.call("dip", 1.0, DIP_OUT_S)
	_close_overlay()
	PhotoMode.end()
	_viewfinder_on = false
	_player.set_physics_process(true)
	_meeting.call("stage_home")
	if not bool(_meeting.call("snap_to", "P", ["mayor_orbit"])):
		_meeting.call("snap_to", "W", [])
	if is_instance_valid(_photo_cam):
		_photo_cam.queue_free()
	_photo_cam = null
	await get_tree().process_frame
	await _meeting.call("dip", 0.0, DIP_IN_S)
	_phase = Phase.LINES


## `[Transform3D, vfov, note]`: the tripod PHOTO_BACK_M behind the mark at PHOTO_EYE_H; the astronaut placed
## among the neighbours (FinaleMeeting.photo_spot, or the mark when the meeting has none) facing it; every
## crowd head and the astronaut's helmet (and feet a little) inside the frame with PHOTO_MARGIN_DEG round
## them and PHOTO_SKY_SHARE of the frame's height of sky over the tallest.
func _photo_frame() -> Array:
	var mark_dir: Vector3 = _meeting.call("mark_dir")
	var centre: Vector3 = _meeting.call("crowd_centre")
	var mark := _planet.surface_point(mark_dir)
	var up := _planet.up_at(mark)
	var fwd := centre - mark
	fwd = (fwd - up * fwd.dot(up)).normalized()
	var spot_dir := _planet.dir_of(mark - fwd * PHOTO_BACK_M)
	var spot := _planet.surface_point(spot_dir)
	var up2 := _planet.up_at(spot)
	var eye := spot + up2 * PHOTO_EYE_H
	# The astronaut, among the neighbours, facing the tripod.
	var a_dir := mark_dir
	var a_cover := -1.0
	if _meeting.has_method("photo_spot"):
		var ps: Array = _meeting.call("photo_spot", eye)
		a_dir = ps[0]
		a_cover = float(ps[1])
	var a_p := _planet.surface_point(a_dir)
	var a_up := _planet.up_at(a_p)
	_player.global_transform = Transform3D(Basis.looking_at(_tangent(eye - a_p, a_up, -fwd), a_up), a_p + a_up * 0.02)
	var look := Basis.looking_at(_tangent(centre - eye, up2, fwd), up2)
	var pts: Array[Vector3] = []
	for id: String in _crowd_ids():
		var n := _meeting.call("npc", id) as Node3D
		if n == null:
			continue
		var nu := _planet.up_at(n.global_position)
		for sx: float in [-PHOTO_BODY_HALF_W, PHOTO_BODY_HALF_W]:
			pts.append(n.global_position + nu * 1.62 + look.x * sx)
			pts.append(n.global_position + nu * 0.45 + look.x * sx)
	for sx: float in [-PHOTO_BODY_HALF_W, PHOTO_BODY_HALF_W]:
		pts.append(a_p + a_up * ASTRO_TOP_H + look.x * sx)
		pts.append(a_p + a_up * ASTRO_LOW_H + look.x * sx)
	var yaw_lo := INF
	var yaw_hi := -INF
	var pit_lo := INF
	var pit_hi := -INF
	for p in pts:
		var v := look.inverse() * (p - eye)
		var z := -v.z
		if z < 0.1:
			continue
		yaw_lo = minf(yaw_lo, rad_to_deg(atan2(v.x, z)))
		yaw_hi = maxf(yaw_hi, rad_to_deg(atan2(v.x, z)))
		pit_lo = minf(pit_lo, rad_to_deg(atan2(v.y, z)))
		pit_hi = maxf(pit_hi, rad_to_deg(atan2(v.y, z)))
	if yaw_lo == INF:
		return [Transform3D(look, eye), 50.0, "no heads"]
	var vr := get_viewport().get_visible_rect().size
	var aspect := vr.x / maxf(vr.y, 1.0)
	var yaw_c := (yaw_lo + yaw_hi) * 0.5
	var half_w := (yaw_hi - yaw_lo) * 0.5 + PHOTO_MARGIN_DEG
	var v_from_w := rad_to_deg(2.0 * atan(tan(deg_to_rad(half_w)) / aspect))
	var span_v := (pit_hi - pit_lo) + 2.0 * PHOTO_MARGIN_DEG
	var fov := clampf(maxf(v_from_w, span_v / (1.0 - PHOTO_SKY_SHARE)), PHOTO_FOV_MIN, PHOTO_FOV_MAX)
	# The heads' top PHOTO_SKY_SHARE of the frame down from the top edge (the sky and the shower above).
	var top_pitch := pit_hi + PHOTO_MARGIN_DEG
	var pitch_c := top_pitch + fov * PHOTO_SKY_SHARE - fov * 0.5
	var b := look.rotated(up2, deg_to_rad(-yaw_c))
	b = b.rotated(b.x, deg_to_rad(pitch_c))
	return [Transform3D(b.orthonormalized(), eye), fov, "yaw %.1f..%.1f pitch %.1f..%.1f aspect %.2f astro %.2f m from the mark, worst head cover %.2f" % [
		yaw_lo, yaw_hi, pit_lo, pit_hi, aspect, a_p.distance_to(mark), a_cover]]


# ------------------------------------------------------------------------------------ the self-timer
func _start_timer() -> void:
	_count_left = TIMER_S
	_click_at = _t + TIMER_S
	_astro_jumped = false
	_holding = false
	AudioManager.play_sfx("ui_tick", -4.0)
	# Everyone's move lands at its own phase at the click (ruling 2.14 (b)): a start time per character.
	var ids := _crowd_ids()
	_cheer_next.clear()
	_cheer_repeat = false
	for i in ids.size():
		_cheer_next[ids[i]] = _click_at - (TIMER_PHASE_MIN + _offset(i, ids.size(), TIMER_PHASE_S))
	_beat("self-timer started (%s)" % _shot_how)


func _timer_tick() -> void:
	var before := ceili(_count_left)
	_count_left = _click_at - _t
	if not _astro_jumped and _t >= _click_at - ASTRO_PHASE:
		_astro_jumped = true
		# play_emote, not a direct set_state: it sets _emote, which player.gd's own _select_state
		# checks first and skips while set, so the pose holds no matter how long the count runs or
		# whether the stuck-player watchdog has touched physics in the meantime (see _photo()'s note).
		if _player != null and is_instance_valid(_player) and _player.has_method("play_emote"):
			_player.call("play_emote", "happy")
	if _count_left <= 0.0:
		_count_left = -1.0
		return
	if ceili(_count_left) < before:
		AudioManager.play_sfx("ui_tick", -4.0)


# ------------------------------------------------------------------------------------ the celebrations
## Member i of n's offset: FinaleLaunch.cheer_offset (evenly spaced, shuffled), or a plain spread.
func _offset(i: int, n: int, spread: float) -> float:
	if ResourceLoader.exists(LAUNCH_PATH):
		return float(load(LAUNCH_PATH).call("cheer_offset", i, n, spread))
	return float(i) / float(maxi(n, 1)) * spread


func _cheer_start(repeat: bool, spread: float) -> void:
	var ids := _crowd_ids()
	_cheer_repeat = repeat
	_cheer_next.clear()
	for i in ids.size():
		_cheer_next[ids[i]] = _t + _offset(i, ids.size(), spread)
		_cheer_rest[ids[i]] = CHEER_REST_MIN + _offset(i + 1, ids.size(), CHEER_REST_S)


func _cheer_stop() -> void:
	_cheer_next.clear()
	_cheer_repeat = false


func _cheer_tick() -> void:
	if _cheer_next.is_empty() or _meeting == null or not is_instance_valid(_meeting):
		return
	for id: String in _cheer_next.keys():
		if _t < float(_cheer_next[id]):
			continue
		var n := _meeting.call("npc", id) as Node3D
		var move := _move_for(id)
		if n != null and n.has_method("play_emote"):
			n.call("play_emote", move)
			if _cheer_log.size() < 64:
				_cheer_log.append("%s@%.2f" % [id, _t])
		if _cheer_repeat:
			var dur := 1.6
			var model := n.call("get_model") as Node if n != null and n.has_method("get_model") else null
			if model != null and model.has_method("emote_duration"):
				dur = float(model.call("emote_duration", move))
			_cheer_next[id] = _t + dur + float(_cheer_rest.get(id, CHEER_REST_MIN))
		else:
			_cheer_next.erase(id)


## Each one's own celebration: DJ Nova dances; the twins and Stella wave on alternate rounds; everyone
## else jumps ("happy": hops the whole body, both arms up).
func _move_for(id: String) -> String:
	if id == "dj_nova":
		return "dance"
	if id in ["pip", "pop", "stella"] and (_cheer_log.size() + id.length()) % 2 == 0:
		return "wave"
	return "happy"


## The frame with no 2D on it (the safari's rule: every canvas item culled for the one frame the picture is
## read from), a white flash, the shutter sound, and the page filed.
func _capture() -> void:
	var vp := get_viewport()
	var saved_mask := vp.canvas_cull_mask
	vp.canvas_cull_mask = 0
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		await RenderingServer.frame_post_draw
	var img: Image = null if headless else vp.get_texture().get_image()
	vp.canvas_cull_mask = saved_mask
	_print_img = img.duplicate() as Image if img != null else null
	if img != null:
		if img.get_width() > PHOTO_W:
			var h := maxi(1, int(round(float(img.get_height()) * PHOTO_W / float(img.get_width()))))
			img.resize(PHOTO_W, h, Image.INTERPOLATE_BILINEAR)
		if img.get_format() != Image.FORMAT_RGB8:
			img.convert(Image.FORMAT_RGB8)
	_photo_img = img
	_flash()
	AudioManager.play_sfx("place", -2.0)
	_file_photo(img)
	_beat("photo taken (%s) image=%s %s" % [_shot_how, "%dx%d" % [img.get_width(), img.get_height()] if img != null else "none (headless)", _photo_note])


## Files the photo as the scrapbook's last page through SkyJournal's existing planet-photo API:
## planet_learn_roster (so "hub:home" is a known page), planet_offer_photo, planet_keep_new - a record in
## the "neighbour" category named PAGE_NAME. TODAY the scrapbook lists it once it exists (last: the
## Commons' group comes after the five worlds, titled from its planet id); it cannot show it as a "???"
## page BEFORE it is taken - that needs sky_journal.gd's owner (needs_from_others: `home_page_key()` and
## the fixed page). When that lands, `file_home_photo(photo)` is called instead, if the journal has it.
func _file_photo(img: Image) -> void:
	var sj := _journal()
	if sj == null:
		_photo_note = "NO SCRAPBOOK (SkyJournal not found): not filed"
		return
	var photo := {
		"subject_key": PAGE_KEY, "subject_name": PAGE_NAME, "grade": PAGE_GRADE, "rarity": 0, "price": 0,
		"scores": {"centred": 0, "size": 0, "focus": 0, "rarity": 0}, "moment_line": PAGE_LINE,
		"raw": {"kind": "neighbour", "category": "neighbour"}, "image": img,
	}
	if sj.has_method("file_home_photo"):
		sj.call("file_home_photo", photo)
		_photo_note = "filed via file_home_photo"
		return
	if sj.has_method("planet_learn_roster"):
		sj.call("planet_learn_roster", PAGE_PLANET, [PAGE_KEY])
	if sj.has_method("planet_offer_photo"):
		sj.call("planet_offer_photo", photo, PAGE_PLANET)
	if sj.has_method("planet_keep_new"):
		sj.call("planet_keep_new", photo, PAGE_PLANET)
	var rec: Dictionary = sj.call("planet_record_for", PAGE_KEY) if sj.has_method("planet_record_for") else {}
	var cat := str(sj.call("scrap_category", PAGE_KEY)) if sj.has_method("scrap_category") else "?"
	_photo_note = "filed %s: record=%s category=%s thumb_b64=%d chars" % [PAGE_KEY, str(not rec.is_empty()), cat, str(rec.get("thumb_b64", "")).length()]


func _journal() -> Node:
	for n: String in ["SkyJournal", "SkyBook"]:
		var j := get_tree().root.get_node_or_null(n)
		if j != null:
			return j
	return null


## The print, for a moment (PRINT_S, or a tap after PRINT_TAP_S): the photo on a cream card, "Home", and
## where it went.
func _show_print() -> void:
	if _overlay == null or _photo_img == null:
		await _wait(0.8)
		return
	_viewfinder_on = false
	if _drawer != null:
		_drawer.queue_redraw()
	# Let the flash clear first, so the print lands on the picture it was taken from.
	await _wait(0.3)
	var card := PanelContainer.new()
	card.name = "Print"
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIStyle.CREAM
	sb.border_color = UIStyle.CREAM_EDGE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14.0)
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var tex := TextureRect.new()
	tex.texture = ImageTexture.create_from_image(_print_img if _print_img != null else _photo_img)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var vp := get_viewport().get_visible_rect().size
	var w := minf(vp.x * 0.46, 620.0)
	tex.custom_minimum_size = Vector2(w, w * float(_photo_img.get_height()) / float(maxi(_photo_img.get_width(), 1)))
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tex)
	var title := Label.new()
	title.text = PAGE_NAME
	title.add_theme_font_override("font", UIStyle.ui_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UIStyle.TEXT_BROWN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Label.new()
	sub.text = "The last page of your scrapbook."
	sub.add_theme_font_override("font", UIStyle.ui_font())
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", UIStyle.TEXT_SOFT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	_overlay.add_child(card)
	await get_tree().process_frame
	card.position = (vp - card.size) * 0.5
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE * 0.85
	card.rotation = deg_to_rad(-2.5)
	var tw := card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_print_up = true
	_print_close = false
	var t := 0.0
	while is_inside_tree() and t < PRINT_S and not (_print_close and t >= PRINT_TAP_S):
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame
	_print_up = false
	_beat("print shown %.2f s" % t)


# ------------------------------------------------------------------------------------ the viewfinder
func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "PhotoViewfinder"
	_overlay.layer = OVERLAY_LAYER
	add_child(_overlay)
	_drawer = _Viewfinder.new()
	_drawer.set("owner_node", self)
	_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_drawer)
	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(flash)


func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_drawer = null


func _flash() -> void:
	var f := _overlay.get_node_or_null("Flash") as ColorRect if _overlay != null else null
	if f == null:
		return
	f.color = Color(1, 1, 1, 0.85)
	var tw := f.create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.32).set_ease(Tween.EASE_OUT)


func _armed() -> bool:
	return _viewfinder_on and _armed_at >= 0.0 and _t >= _armed_at and not _fired


func _press(src: String) -> void:
	if not _armed() or _holding:
		return
	_holding = true
	_hold_src = src
	_hold_t = 0.0
	AudioManager.play_sfx("ui_tick", -8.0)


func _release(src: String) -> void:
	if not _holding or src != _hold_src:
		return
	_holding = false
	if not _armed():
		return
	_shot_how = "shutter held %.2f s (%s)" % [_hold_t, src]
	_fired = true


func _input(event: InputEvent) -> void:
	if _print_up:
		if (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
				or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
				or (event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo):
			_print_close = true
			get_viewport().set_input_as_handled()
		return
	if not _viewfinder_on:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_press("touch%d" % t.index)
		else:
			_release("touch%d" % t.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# A finger's emulated mouse copy is the touch again; take the touch.
		if mb.device != InputEvent.DEVICE_ID_EMULATION and mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press("mouse")
			else:
				_release("mouse")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if not k.echo and SHUTTER_KEYS.has(k.physical_keycode):
			if k.pressed:
				_press("key%d" % k.physical_keycode)
			else:
				_release("key%d" % k.physical_keycode)
		get_viewport().set_input_as_handled()


## The actions, polled (a Director tap presses an action with no InputEvent). A press that began before
## the viewfinder armed is ignored until it has been let go.
func _poll_actions() -> void:
	for a in SHUTTER_ACTIONS:
		if not InputMap.has_action(a):
			continue
		var down := Input.is_action_pressed(a)
		var was := bool(_action_down.get(a, true))
		if down and not was:
			_press("action:" + a)
		elif not down and was:
			_release("action:" + a)
		_action_down[a] = down


class _Viewfinder:
	extends Control
	var owner_node: Node

	func _draw() -> void:
		var g := owner_node
		if g == null or not bool(g.get("_viewfinder_on")):
			return
		var sz := get_viewport_rect().size
		var font := UIStyle.ui_font()
		var inset := Vector2(sz.x * 0.08, sz.y * 0.07)
		var a := inset
		var b := sz - inset
		var arm := 46.0
		var col := Color(UIStyle.CREAM, 0.85)
		for corner in [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(a.x, b.y), Vector2(b.x, b.y)]:
			var dx := arm if corner.x == a.x else -arm
			var dy := arm if corner.y == a.y else -arm
			draw_line(corner, corner + Vector2(dx, 0), col, 4.0, true)
			draw_line(corner, corner + Vector2(0, dy), col, 4.0, true)
		var c := sz * 0.5
		var holding := bool(g.get("_holding"))
		if holding:
			var half := 22.0
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var p := c + Vector2(sx * half, sy * half)
					draw_line(p, p + Vector2(-sx * 12.0, 0), UIStyle.GREEN, 3.0, true)
					draw_line(p, p + Vector2(0, -sy * 12.0), UIStyle.GREEN, 3.0, true)
		else:
			draw_arc(c, 26.0, 0.0, TAU, 40, col, 2.0, true)
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), col, 2.0, true)
			draw_line(c + Vector2(0, -8), c + Vector2(0, 8), col, 2.0, true)
		# The shutter, where a safari puts it (MobileUI's primary button spot).
		var sa := MobileUI.safe_area()
		var sc := Vector2(sz.x - sa.z - MobileUI.EDGE - MobileUI.PRIMARY_HIT_R, sz.y - sa.w - MobileUI.EDGE - MobileUI.PRIMARY_HIT_R)
		var r := MobileUI.PRIMARY_R
		draw_circle(sc, r, Color(UIStyle.WHITE, 0.9))
		draw_arc(sc, r - 3.0, 0.0, TAU, 56, Color(UIStyle.GREEN if holding else UIStyle.NAVY, 0.9), 6.0, true)
		draw_circle(sc, r * 0.62, Color(UIStyle.CREAM_DEEP, 0.95))
		# The one line of help, on a pill at the top.
		var counting := float(g.get("_count_left")) >= 0.0
		var hint := GiftConst.COUNT_TEXT if counting else GiftConst.HINT_TEXT
		var tsize := 22
		var w := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, tsize).x
		var box := Rect2(Vector2((sz.x - w) * 0.5 - 18.0, sa.y + 18.0), Vector2(w + 36.0, 40.0))
		draw_style_box(UIStyle.make_pill_style(Color(UIStyle.NAVY, 0.62), Color(UIStyle.CREAM, 0.55), 2), box)
		draw_string(font, Vector2(box.position.x + 18.0, box.position.y + 28.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, tsize, UIStyle.CREAM)
		# The self-timer's count, big, low in the frame (the faces stay clear), on a navy disc.
		if counting:
			var num := str(maxi(1, ceili(float(g.get("_count_left")))))
			var nsize := 96
			var cc := Vector2(sz.x * 0.5, sz.y * 0.80)
			draw_circle(cc, 62.0, Color(UIStyle.NAVY, 0.62))
			draw_arc(cc, 62.0, 0.0, TAU, 56, Color(UIStyle.CREAM, 0.7), 3.0, true)
			var nw := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, nsize)
			draw_string(font, Vector2(cc.x - nw.x * 0.5, cc.y + nsize * 0.34), num, HORIZONTAL_ALIGNMENT_LEFT, -1, nsize, UIStyle.CREAM)


class GiftConst:
	const HINT_TEXT := "Tap the shutter. Self-timer: 3, 2, 1!"
	const COUNT_TEXT := "Self-timer. Everyone, smile!"


# ============================================================================= DONE
func _done(toast: String) -> void:
	var runner := DialogueRunner.get_or_create(self)
	if runner != null and runner.is_active():
		runner.finish()
	if _player != null and is_instance_valid(_player):
		_player.set("input_enabled", false)
	# Out of the Fly reach, among the crowd, before the hand-back (docs/PHASE5_SPEC.md §2: control 4.5-6.5 m
	# from the pad).
	if _control_dir != Vector3.ZERO and _meeting.has_method("walk_player_to"):
		await _meeting.call("walk_player_to", _control_dir, _meeting.call("crowd_centre"))
	# The party track gives way to the Commons' own music.
	if _planet != null and _planet.data != null:
		AudioManager.play_music(_planet.data.music_track, 2.0)
	# DONE on disk before anything else can happen.
	var stage_before := _fs_int("stage")
	_sky_on = false
	if _sky_frames > 0:
		_beat("sky: a streak head in the camera's view in %d of %d HOME frames (%.0f%%)" % [_sky_frames_lit, _sky_frames,
			100.0 * float(_sky_frames_lit) / float(_sky_frames)])
	_finish_story()
	_beat("DONE stage %d->%d campaign_changed=%d can_save=%s ship_flag=%s t=%.2f hour=%.2f" % [stage_before, _fs_int("stage"),
		_campaign_changes, str(_fs_bool("can_save")), str(_fs_bool("has_ship")), _t, GameState.time_of_day])
	if _meeting.has_method("hand_back_to_rig"):
		await _meeting.call("hand_back_to_rig")
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
	var pd := _player.global_position.distance_to(_pad.global_position) if _pad != null else -1.0
	var pad_root := _pad.get_node_or_null("Pad") as Node3D if _pad != null else null
	if pad_root != null:
		pd = _player.global_position.distance_to(pad_root.global_position)
	var rk := _pad.get("rocket") as Node3D if _pad != null else null
	_beat("control t=%.2f pad_dist=%.2f input=%s modal_open=%s time_scale=%s toast=%s rocket_look=%s" % [_t, pd,
		str(_player.get("input_enabled")), str(EventBus.is_modal_open()), str(_env.get("time_scale")) if _env != null else "-",
		toast, str(rk.call("look")) if rk != null and rk.has_method("look") else "-"])
	if EventBus.campaign_changed.is_connected(_on_campaign_changed):
		EventBus.campaign_changed.disconnect(_on_campaign_changed)
	set_process(false)
	finished.emit()


func _finish_story() -> void:
	if ResourceLoader.exists(FINALE_STATE_PATH):
		load(FINALE_STATE_PATH).call("finish_story")


# ============================================================================= helpers
func _crowd_ids() -> Array:
	return _meeting.call("crowd_ids") if _meeting != null and _meeting.has_method("crowd_ids") else []


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


func _on_campaign_changed() -> void:
	_campaign_changes += 1


func _wait(seconds: float) -> void:
	var t := 0.0
	while is_inside_tree() and t < seconds:
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame


func _exit_tree() -> void:
	# Leaving mid-beat (a quit to the title, a scene change): never leave the menus locked, the astronaut
	# frozen or hidden, or the HUD in photo mode.
	if _phase != Phase.DONE and _phase != Phase.IDLE:
		_end_modal()
		if PhotoMode.active:
			PhotoMode.end()
		if _player != null and is_instance_valid(_player):
			_player.visible = true
			_player.set_physics_process(true)
			_player.set("input_enabled", true)
		_phase = Phase.DONE
	if EventBus.campaign_changed.is_connected(_on_campaign_changed):
		EventBus.campaign_changed.disconnect(_on_campaign_changed)


static func _tangent(v: Vector3, up: Vector3, fallback: Vector3) -> Vector3:
	var t := v - up * v.dot(up)
	if t.length_squared() < 1e-6:
		t = fallback - up * fallback.dot(up)
	return t.normalized()


func _fs_int(method: String) -> int:
	return int(load(FINALE_STATE_PATH).call(method)) if ResourceLoader.exists(FINALE_STATE_PATH) else -1


func _fs_bool(method: String) -> bool:
	return bool(load(FINALE_STATE_PATH).call(method)) if ResourceLoader.exists(FINALE_STATE_PATH) else false


func _beat(msg: String) -> void:
	print("HOME ", msg)
	if _trace_on and ResourceLoader.exists(FINALE_STATE_PATH):
		load(FINALE_STATE_PATH).call("trace", TRACE_TAG, msg)


# ============================================================================= test hooks
## TEST HOOK: one line for a probe or a Director "call" step.
func debug_report(tag: String = "") -> void:
	print("HOME REPORT %s phase=%s t=%.2f viewfinder=%s armed=%s fired=%s how=%s stage=%d campaign_changed=%d photo=%s" % [
		tag, phase_name(), _t, str(_viewfinder_on), str(_armed()), str(_fired), _shot_how, _fs_int("stage"),
		_campaign_changes, _photo_note])


## TEST HOOK: presses and releases the shutter with a REAL InputEvent (the F key through
## Input.parse_input_event - SYNTHESISED, no hardware), `hold_s` apart.
func debug_shutter(hold_s: float = 0.3) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F
	ev.keycode = KEY_F
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(hold_s)
	var rel := ev.duplicate() as InputEventKey
	rel.pressed = false
	Input.parse_input_event(rel)


## TEST HOOK: a real screen touch at `pos` (InputEventScreenTouch through Input.parse_input_event - still
## SYNTHESISED), `hold_s` apart.
func debug_touch_shutter(pos: Vector2, hold_s: float = 0.3) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = pos
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(hold_s)
	var rel := ev.duplicate() as InputEventScreenTouch
	rel.pressed = false
	Input.parse_input_event(rel)
