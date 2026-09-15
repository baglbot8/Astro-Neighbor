extends Node
## THE FINALE'S FLOW (docs/PHASE5_SPEC.md §1/§2/§6, docs/BUILD_PLAN.md Phase 5 builder K). Attached by
## `world.gd` on every planet load, guarded, after VisitorSystem:
##
##     if ResourceLoader.exists(FINALE_PATH):
##         load(FINALE_PATH).attach(self)
##
## `attach()` is the only entry point; `FinaleState` (finale_state.gd) is the pure data/rules side, this
## file is the orchestration - it decides WHAT to do this load, drives the Call itself, and on the
## Commons runs the chain through the beats the other Phase 5 builders own. INERT unless
## `CampaignData.gates_on()`: an old save, a finished story, or a Director timeline without `--campaign`
## sees no call, no toast, no per-frame work at all (see `_ready`).
##
## ============================================================================== MISSING FILES
## `finale_meeting.gd` (K2), `finale_launch.gd` (L2) and `finale_gift.gd` (G) land after this builder
## (docs/BUILD_PLAN.md Phase 5 launch order) - every load of one is guarded by `ResourceLoader.exists`,
## and a missing one logs `FINALE missing <path>`, leaves the stage exactly where it was, and lets the
## rest of the game run untouched (docs/BUILD_PLAN.md Phase 5, K's brief). The three files are loaded
## BY PATH, never by class name, so this script parses with none of them present.
##
## ============================================================================== THE MEETING OBJECT
## finale_meeting.gd is not a world.gd guarded hook - THIS file creates it, once, whenever the Commons
## is loaded at stage 1, 2 or 3: `var meeting: Node = (load(FINALE_MEETING_PATH) as GDScript).new()`,
## named "FinaleMeeting", added under the World node. It must work instanced this way (no `attach()`
## wrapper expected of it - `finale.gd` is its only caller) and must itself read `FinaleState.stage()`
## in its own `_ready` to decide what to show: stage 1 the full §3 MEETING dialogue and the ask; stage 2
## the crowd on its saved spots with the Professor's "!" re-asking; stage 3 nothing spoken at all, the
## crowd simply staged (the choice is already made) so `FinaleLaunch`/`FinaleGift` have something to
## frame. It emits `chose_send` exactly once, and only when the stage was 1 or 2 when it was created -
## `finale.gd` does not await that signal when the stage is already 3 (see `_run_meeting_chain`).

const NODE_NAME := "Finale"
const SCRIPT_PATH := "res://src/campaign/finale.gd"
const FINALE_MEETING_PATH := "res://src/campaign/finale_meeting.gd"
const FINALE_LAUNCH_PATH := "res://src/campaign/finale_launch.gd"
const FINALE_GIFT_PATH := "res://src/campaign/finale_gift.gd"
## visitor_system.gd (Phase 4, K's brief note on `_visits_on`) has no class_name, so it is loaded by
## path here too, the same way FinaleState's own `_visits_on` helper does it.
const VISITOR_SYSTEM_PATH := "res://src/campaign/visitor_system.gd"
## FinaleLines is data-only with no class_name (see its own header) - accessed through this preload,
## exactly the way its own doc comment says K will consume it. Safe to hard-reference: an L0 file,
## already landed before this builder starts (docs/BUILD_PLAN.md Phase 5 launch order).
const FinaleLines := preload("res://src/campaign/finale_lines.gd")

const HOME_ID := "home"
const COMMONS_ID := "hub"
## docs/PHASE5_SPEC.md §2 Call: "once PartCelebration's calm test holds 1.5 s."
const CALM_HOLD := 1.5
## docs/PHASE5_SPEC.md §2 Call: "hangs 1.2 m to the rocket's side" (copies intro_director.gd's own
## RADIO_SIDE_M for the campaign greeting - same shot, same reason, see `_hang_radio`).
const RADIO_SIDE_M := 1.2
## intro_director.gd `_hang_campaign_radio`'s own lift for the radio, kept identical.
const RADIO_LIFT_M := 0.30
## Framing margins for `_predict_call_shot`, in normalised device units (-1..1). The top and sides keep
## the hull 5% of the half-frame inside the edge. BOX_TOP_NDC is the dialogue box's top edge on the phone
## frame, measured: box top y = 531 of a 720-high canvas (2556x1179 --ui=mobile), 1 - 2*531/720 = -0.475;
## the hull above its lower third must clear it.
const FRAME_EDGE_NDC := 0.95
const BOX_TOP_NDC := -0.475
## Candidates whose turns differ by less than this are treated as equal, and the earlier one in
## `_hang_radio`'s list (intro_director's own rule first) is kept - so two near-identical spots never
## flip on a rounding difference.
const TURN_TIE_DEG := 3.0
const PROFESSOR_ACCENT := Color("#c9a15c")
## docs/PHASE5_SPEC.md §1's table, verbatim, for stages 1/2 when you are not on the Commons.
const ELSEWHERE_TOAST := "Everyone is waiting on the Commons."

const CLI_ARG_PREFIX := "--finale="

var _pc: PartCelebration
var _awaiting_calm := false
var _calm_t := 0.0
var _running_call := false
var _chain_running := false
var _held_time_scale := false
var _saved_time_scale := 1.0
## True when the calm wait was started by `PartCelebration.finished` (the fifth part just fitted at the
## bench), false when it was started by a load that already had five parts. Decides how the radio is
## hung (`_hang_radio`): docs/PHASE5_SPEC.md §0 "K call framing" - only the Call after the celebration
## must frame the gold rocket; a Call from a load plays wherever the astronaut stands.
var _call_after_celebration := false


# ============================================================================= entry point
## Called once per world by world.gd. Returns the host (also useful for a test rig to grab it).
static func attach(world: Node) -> Node:
	if world == null or not world.is_inside_tree():
		return null
	var existing := world.get_node_or_null(NODE_NAME)
	if existing != null:
		return existing
	var host: Node = (load(SCRIPT_PATH) as GDScript).new()
	host.name = NODE_NAME
	world.add_child(host)
	return host


func _ready() -> void:
	# After VisitorSystem's own priority (default 0) so a `--finale=` reload this frame does not race
	# it; irrelevant once running (finale.gd does no per-frame work while inert - see the class doc).
	process_priority = 1
	# docs/BUILD_PLAN.md Phase 5 round 2 ("Per-frame work while inert"): `_process` above is defined
	# on every instance of this script, on every world, at every stage - Godot runs it every frame
	# unless told not to. Off here, on only for the calm wait (`_begin_calm_wait`), off again the
	# instant the Call itself starts (`_run_call`) - the three places this file has any per-frame work
	# left to do at all.
	set_process(false)
	EventBus.planet_leave_requested.connect(_on_leave_requested)
	var cli_key := _consume_cli_key()
	if cli_key != "":
		_run_cli(cli_key)
		return  # fire-and-forget: the debug function this kicks off ends in go_to_planet either way.
	if not CampaignData.gates_on():
		return  # INERT: old save, finished story, or a Director run without --campaign.
	_run_arrival_logic()


func _exit_tree() -> void:
	# The one thing this file promises on EVERY exit it sees, not only a clean one: flying away
	# mid-call, quitting to the title, a Director forcing a scene change - all of them free this node
	# as a descendant of World, so this is the single place that has to catch every one of them.
	_restore_time_scale()


func _process(delta: float) -> void:
	if not _awaiting_calm:
		return
	if _pc != null and is_instance_valid(_pc) and _pc._can_start():
		_calm_t += delta
		if _calm_t >= CALM_HOLD:
			_awaiting_calm = false
			_run_call()
	else:
		_calm_t = 0.0


func _on_leave_requested(_planet_id: String) -> void:
	# Boarding the rocket ends the Call's freeze immediately (belt and braces with `_exit_tree`, which
	# fires a moment later once the scene actually tears down - docs/PHASE5_SPEC.md §1 checklist 5).
	_restore_time_scale()


# ============================================================================= --finale=
## Finds the `--finale=` argument, if any, and marks it consumed for the rest of THIS PROCESS (Engine
## metadata survives the scene reload the debug function itself triggers - see FinaleState's own note
## on why this is metadata and not a GameState flag). Split from actually RUNNING it (`_run_cli`
## below) so the match happens, and the flag is set, before any busy-wait - two `_ready`s racing on
## the same frame can only ever find this true for one of them.
func _consume_cli_key() -> String:
	if Engine.has_meta("finale_cli_done"):
		return ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(CLI_ARG_PREFIX):
			Engine.set_meta("finale_cli_done", true)
			return a.substr(CLI_ARG_PREFIX.length())
	return ""


## Runs one §10 debug function once `SceneRouter` is free to take it. docs/BUILD_PLAN.md Phase 5
## round 2 ("--finale= does nothing when the Director starts through title_screen"): a Director run
## reaches THIS `_ready` while title_screen's own `go_to_planet` is still mid-flight - calling a
## debug_start_* straight through then hits `go_to_planet`'s own "if _busy: return" and does nothing
## at all, silently. Waiting HERE (not inside FinaleState) keeps every debug_start_* function itself
## synchronous for its other caller, the dev menu, which is never invoked mid-transition.
func _run_cli(key: String) -> void:
	while SceneRouter.is_busy():
		await get_tree().process_frame
		if not is_inside_tree():
			return  # this node was freed (another reload got here first) - nothing left to finish.
	match key:
		"reset": FinaleState.debug_reset_before_finale()
		"call": FinaleState.debug_start_call()
		"meeting": FinaleState.debug_start_meeting()
		"choice": FinaleState.debug_start_choice()
		"sendoff": FinaleState.debug_start_sendoff()
		"gift": FinaleState.debug_start_gift()
		"after": FinaleState.debug_after_story()
		_: push_warning("finale.gd: unknown --finale= value '%s'" % key)


# ============================================================================= §1 table
## What to do THIS load, purely from `FinaleState.stage()` and the current planet.
func _run_arrival_logic() -> void:
	match FinaleState.stage():
		0:
			if GameState.current_planet_id == HOME_ID:
				_watch_for_call()
			elif GameState.current_planet_id == COMMONS_ID and GameState.rocket_part_count() >= CampaignData.PARTS.size():
				# docs/PHASE5_SPEC.md §1's stage-0 row, its OWN "on the Commons, write 1": the ordinary
				# path is a home load driving the Call through the calm wait, but a save can land
				# straight on the Commons with all five parts already fitted - the Call is a home-only
				# beat with nothing to wait through here, so skip straight to CALLED and run the chain
				# (docs/BUILD_PLAN.md Phase 5 round 2, "a hub save at stage 0 with 5 parts does nothing").
				FinaleState.set_stage(1)
				FinaleState.checkpoint()
				_run_meeting_chain()
		1, 2:
			if GameState.current_planet_id == COMMONS_ID:
				_run_meeting_chain()
			else:
				EventBus.toast_requested.emit(ELSEWHERE_TOAST, "star")
		3:
			if GameState.current_planet_id == COMMONS_ID:
				_run_meeting_chain()
			else:
				# Defensive only - nothing in the designed flow leaves the Commons mid-send-off. A
				# stage this far along, seen somewhere it should never be seen, downgrades rather
				# than trying (and failing) to replay a send-off with no meeting to frame it.
				FinaleState.set_stage(2)
				FinaleState.checkpoint()
				EventBus.toast_requested.emit(ELSEWHERE_TOAST, "star")
		4:
			pass  # normal game - nothing left for the finale to do, ever again.


# ============================================================================= the Call (home)
func _watch_for_call() -> void:
	_pc = get_node_or_null("/root/World/PartCelebration") as PartCelebration
	if _pc == null:
		return  # no PartCelebration in this build (or not home) - nothing to hook.
	if not _pc.finished.is_connected(_on_part_celebration_finished):
		_pc.finished.connect(_on_part_celebration_finished)
	if GameState.rocket_part_count() >= CampaignData.PARTS.size():
		_begin_calm_wait(false)


func _on_part_celebration_finished(_skipped: bool) -> void:
	if FinaleState.stage() != 0:
		return
	if GameState.rocket_part_count() >= CampaignData.PARTS.size():
		_begin_calm_wait(true)


func _begin_calm_wait(after_celebration: bool) -> void:
	if _running_call:
		return
	# A celebration that finishes while a load-started wait is still pending upgrades it: the astronaut
	# is at the bench beside the rocket now, so the Call should frame it.
	_call_after_celebration = _call_after_celebration or after_celebration
	if _awaiting_calm:
		return
	_awaiting_calm = true
	_calm_t = 0.0
	set_process(true)


func _run_call() -> void:
	if _running_call:
		return
	_running_call = true
	set_process(false)  # the calm wait is over; nothing left for _process to do (round 2 fix 8).
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		_running_call = false
		return
	_hold_time_scale()
	var radio := RadioSpeaker.make("mayor_orbit_radio", "%s (radio)" % Journal.npc_name("mayor_orbit"),
		"elder", PROFESSOR_ACCENT)
	_hang_radio(radio, player)
	AudioManager.play_sfx("ui_open", -8.0)
	var runner := DialogueRunner.get_or_create(self)
	runner.begin(radio, player)
	await _play_call(runner, radio)
	runner.finish()
	if is_instance_valid(radio):
		radio.queue_free()
	FinaleState.set_stage(1)
	_end_home_visit()
	FinaleState.checkpoint()
	_restore_time_scale()
	_running_call = false


## docs/PHASE5_SPEC.md §3 CALL / CALL_WHAT_IS_IT, played straight off FinaleLines (word for word, so a
## wording change goes back to the lead against the spec, never edited here). CALL's only "ask" is its
## last turn: "On my way" falls straight through (the Meeting beat picks up from there once you reach
## the Commons - see `_run_arrival_logic`'s stage-1 branch); "What is it?" plays one more line first.
func _play_call(runner: DialogueRunner, radio: Node3D) -> void:
	for turn: Dictionary in FinaleLines.CALL:
		if turn.has("ask"):
			var ask: Dictionary = turn["ask"]
			var choice: int = await runner.ask(radio, str(ask.get("prompt", "")), ask.get("options", []))
			if choice == 1:
				for turn2: Dictionary in FinaleLines.CALL_WHAT_IS_IT:
					await runner.say(radio, turn2.get("lines", []))
			return
		await runner.say(radio, turn.get("lines", []))


## Where the radio hangs, which is also how the Call is framed: `DialogueRunner.begin` hands the rig
## ONE focus point (`CameraRig.focus_on`, re-aimed every frame from the radio's position), and the rig
## then turns its heading to look square across the astronaut-to-focus line, on whichever side of that
## line it already faces (camera_rig.gd `_process`, the `_focus_weight` branch: `best = side if
## side.dot(_fwd) >= 0 else -side`), pushes in to FOCUS_PUSH_IN of its distance at a 20 deg pitch, and
## pivots 75% of the way to the astronaut/focus midpoint. So this file never moves the camera itself -
## it only chooses the radio's spot, and the rig's own dialogue framing (exactly what every other
## conversation gets) does the rest. docs/PHASE5_SPEC.md §0 "K call framing" gives two cases:
##
## A CALL FROM A LOAD plays where the astronaut stands: intro_director.gd `_hang_campaign_radio`'s rule,
## copied - square to the camera's current heading, on the rocket's side - so the rig keeps its heading
## and only pushes in.
##
## THE CALL AFTER THE FIFTH PART'S CELEBRATION must have the gold rocket in frame. Four spots are
## scored (`_predict_call_shot`): that same camera-square spot on either side, and a spot square to the
## astronaut-to-rocket bearing on either side, which makes the rig converge on looking straight at the
## rocket. Each is scored on the shot the rig will SETTLE on (the same formulas as camera_rig.gd and
## dialogue_runner.gd, read through their public constants): is the whole hull inside the frame and
## above the dialogue box, and how far the camera has to turn. The pick frames the rocket with the least
## turn; if no spot frames it, the rocket bearing. Props are NOT scored: a box test flagged clear lines
## (a 4 m tree's box is mostly air) and a triangle test cost 90 ms in one frame, so a bush or the bench
## can still overlap part of the shot, exactly as in any other conversation at that spot. Measured on the phone frame at
## the home bench (KF report): the celebration's hand-back usually already frames the rocket, so the
## camera-square spot wins and the Call opens with no swing; where it would not, the bearing spot turns
## the rig onto the rocket.
##
## ROUND 1 (K) ALSO CALLED `CameraRig.focus_on(rocket)` here when the rocket was out of frame. That did
## nothing on screen: `runner.begin` calls `focus_on` again on the very same frame and the rig keeps a
## single `_focus_pos`, so the rocket focus was overwritten before it was drawn, and its extra
## `release_focus` after the Call only restarted the runner's own release. What DID move the camera was
## the radio hung square to the bearing for a rocket behind the lens: the rig then swung (measured
## 112.9 deg/s peak) to look further AWAY from it. Both removed.
func _hang_radio(radio: Node3D, player: Node3D) -> void:
	var host := player.get_parent()
	if host != null:
		host.add_child(radio)
	else:
		add_child(radio)
	var up := player.global_basis.y.normalized()
	if player is PlanetBody:
		up = (player as PlanetBody).up.normalized()
	var r := _find_rocket()
	var rig := get_node_or_null("/root/World/CameraRig")
	var fwd := -player.global_basis.z
	if rig != null and rig.has_method("get_camera_forward"):
		fwd = rig.call("get_camera_forward") as Vector3
	fwd = (fwd - up * fwd.dot(up)).normalized()
	var cam_side := fwd.cross(up).normalized()
	var p := player.global_position
	var lift := up * RADIO_LIFT_M
	var side := cam_side
	if r != null and (r.global_position - p).dot(cam_side) < 0.0:
		side = -cam_side
	var rule := "stand"
	var note := ""
	var best_uv: Array = []
	if _call_after_celebration and r != null and rig != null:
		var bearing := r.global_position - p
		bearing -= up * bearing.dot(up)
		var cands: Array[Dictionary] = [
			{"rule": "stand", "side": side}, {"rule": "stand", "side": -side}]
		if bearing.length() > 0.5:
			var b_side := bearing.normalized().cross(up).normalized()
			cands.append({"rule": "rocket", "side": b_side})
			cands.append({"rule": "rocket", "side": -b_side})
		var best: Dictionary = {}
		var best_key := INF
		for c: Dictionary in cands:
			var shot := _predict_call_shot(player, p + (c["side"] as Vector3) * RADIO_SIDE_M + lift, up, fwd, r, rig)
			c.merge(shot)
			# A framed spot first, then the least turn. If none frames it: the bearing when the rocket is
			# ahead of the lens, else stay put (turning square to the bearing for a rocket behind the
			# lens looks further AWAY from it - round 1's 112.9 deg/s swing).
			var key := float(shot["turn_deg"])
			if not shot["framed"]:
				key += 1000.0
				if (str(c["rule"]) == "rocket") != (bearing.dot(fwd) > 0.0):
					key += 500.0
			note += " %s%+d:f=%s t=%.0f" % [c["rule"], signi(int(signf((c["side"] as Vector3).dot(cam_side)))),
				str(shot["framed"]), shot["turn_deg"]]
			if key < best_key - TURN_TIE_DEG:
				best_key = key
				best = c
		side = best["side"]
		rule = str(best["rule"])
		best_uv = best["axis_uv"]
	radio.global_position = p + side * RADIO_SIDE_M + lift
	if best_uv.size() == 2:
		note += " picked_axis_uv=%s,%s" % [str(best_uv[0]), str(best_uv[1])]
	FinaleState.trace("K", "call framing=%s after_celebration=%s%s" % [rule, str(_call_after_celebration), note])
	print("FINALE call framing=%s%s" % [rule, note])


## The shot the rig settles on for a radio hung at `radio_pos` (see `_hang_radio`): the same maths as
## camera_rig.gd `_process` (focus branch, converged: `_fwd` = the chosen square-on heading) and
## dialogue_runner.gd `_focus_point` (FOCUS_REACH past the radio, lifted FOCUS_LIFT along world up,
## because a RadioSpeaker is not a PlanetBody), through their public constants. Terrain avoidance and
## smoothing are left out - they only shorten or lift the arm near slopes. Returns `framed` (every hull
## point in front, inside the frame's width and top, and the hull's lower third above the dialogue box),
## and `turn_deg`, plus `axis_uv` (the hull axis's base and top in 0-1 screen units, for the trace).
func _predict_call_shot(player: Node3D, radio_pos: Vector3, up: Vector3, fwd: Vector3, r: Node3D, rig: Node) -> Dictionary:
	var p := player.global_position
	var focus := p + (radio_pos - p) * DialogueRunner.FOCUS_REACH + Vector3.UP * DialogueRunner.FOCUS_LIFT
	var to_focus := focus - p
	to_focus -= up * to_focus.dot(up)
	var look := fwd
	if to_focus.length_squared() > 0.01:
		var sq := to_focus.normalized().cross(up)
		look = sq if sq.dot(fwd) >= 0.0 else -sq
	var mid := (p + up * 0.9 + focus + up * 0.9) * 0.5
	var pivot := (p + up * CameraRig.PIVOT_HEIGHT).lerp(mid, 0.75)
	var dist := float(rig.call("get_zoom_distance")) * CameraRig.FOCUS_PUSH_IN if rig.has_method("get_zoom_distance") else 6.0
	var pitch := deg_to_rad(20.0)
	var eye := pivot - look * cos(pitch) * dist + up * sin(pitch) * dist
	var basis := Basis.looking_at((pivot - eye).normalized(), up)
	var cam_fwd := -basis.z
	var tan_v := tan(deg_to_rad(DialogueRunner.FOCUS_FOV) * 0.5)
	var vr := get_viewport().get_visible_rect().size
	var aspect := vr.x / maxf(vr.y, 1.0)
	var h := float(r.call("model_height")) if r.has_method("model_height") else 3.2
	var rb := r.global_basis.orthonormalized()
	var framed := true
	for hy: float in [0.0, h / 3.0, h]:
		for sx: float in [-RocketModel.HULL_R, RocketModel.HULL_R]:
			var q := r.global_position + rb.y * hy + basis.x * sx
			var v := q - eye
			var z := v.dot(cam_fwd)
			if z < 0.2:
				framed = false
				break
			var nx := v.dot(basis.x) / (z * tan_v * aspect)
			var ny := v.dot(basis.y) / (z * tan_v)
			if absf(nx) > FRAME_EDGE_NDC or ny > FRAME_EDGE_NDC or (hy > 0.0 and ny < BOX_TOP_NDC):
				framed = false
				break
		if not framed:
			break
	# The hull axis's base and top on screen, for the trace (compared against the rendered frame).
	var axis_px: Array = []
	for hy2: float in [0.0, h]:
		var v2 := r.global_position + rb.y * hy2 - eye
		var z2 := maxf(v2.dot(cam_fwd), 0.01)
		axis_px.append(Vector2(0.5 + 0.5 * v2.dot(basis.x) / (z2 * tan_v * aspect), 0.5 - 0.5 * v2.dot(basis.y) / (z2 * tan_v)))
	return {"framed": framed, "turn_deg": rad_to_deg(fwd.angle_to(look)), "axis_uv": axis_px}


func _find_rocket() -> Node3D:
	var pad := get_node_or_null("/root/World/Rocket")
	if pad == null:
		return null
	return pad.get("rocket") as Node3D


## docs/PHASE5_SPEC.md §1 checklist 5 ("no visitor stands at home in stages 1-3"). `VisitorSystem.
## visits_on()` already returns false at stages 1-3 (L0's report), but that only stops a NEW day's
## visit being ROLLED - it does nothing about one already standing when the Call starts, or already
## WRITTEN for today (docs/BUILD_PLAN.md Phase 5 round 2: "a visitor already there stays after the
## call, and today's record brings them back on reload"). Two calls fix both halves: the static
## `mark_left` ends today's record for good, so `ensure_today` (which returns an already-written
## record UNCHANGED, `visits_on()` or not) never brings them back on a later load the same day; the
## live world's own `restage()` re-derives from that record THIS load, despawning whoever is standing
## there right now with no reload required.
func _end_home_visit() -> void:
	if not ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		return
	load(VISITOR_SYSTEM_PATH).call("mark_left", "the finale call started")
	var vs := get_node_or_null("/root/World/VisitorSystem")
	if vs != null and vs.has_method("restage"):
		vs.call("restage")


# ============================================================================= the clock
func _hold_time_scale() -> void:
	if _held_time_scale:
		return
	var env := get_node_or_null("/root/World/Environment")
	if env == null:
		return
	_saved_time_scale = env.get("time_scale")
	env.set("time_scale", 0.0)
	_held_time_scale = true


func _restore_time_scale() -> void:
	if not _held_time_scale:
		return
	var env := get_node_or_null("/root/World/Environment")
	if env != null:
		env.set("time_scale", _saved_time_scale)
	_held_time_scale = false


# ============================================================================= the Commons chain
## Attaches the meeting (if its file exists) and, once it has chosen, runs steps 2-6 of K's brief:
## write stage 3 + checkpoint, the send-off, the gift, then `finish_story` and clean-up. At stage 3
## already (a reload after "Send her" checkpointed but before the ending finished) the meeting is
## still attached - `FinaleLaunch`/`FinaleGift` need it for the crowd, axis and camera - but nothing
## is awaited from it: the choice is already made, so this jumps straight to the send-off.
func _run_meeting_chain() -> void:
	if _chain_running:
		return
	_chain_running = true
	var meeting := _attach_meeting()
	if meeting == null:
		_chain_running = false
		return  # missing file already logged by `_attach_meeting`; stage left exactly where it was.
	var stage_at_entry := FinaleState.stage()
	if stage_at_entry < 3:
		if meeting.has_signal("chose_send"):
			await Signal(meeting, "chose_send")
		FinaleState.set_stage(3)
		FinaleState.checkpoint()
	await _run_send_and_gift(meeting)
	_chain_running = false


func _attach_meeting() -> Node:
	if not ResourceLoader.exists(FINALE_MEETING_PATH):
		_log_missing(FINALE_MEETING_PATH)
		return null
	var world := get_parent()
	if world == null:
		return null
	var existing := world.get_node_or_null("FinaleMeeting")
	if existing != null:
		return existing
	var meeting: Node = (load(FINALE_MEETING_PATH) as GDScript).new()
	meeting.name = "FinaleMeeting"
	world.add_child(meeting)
	return meeting


## Steps 3-6 of K's brief. `FinaleState.consume_skip_sendoff()` is only ever true right after
## `debug_start_gift` - it makes both the send-off beat and the launch's own play-through a no-op,
## going straight to `apply_end_state()` (documented idempotent, safe with no prior `play()`) so the
## gift has the post-launch world to frame without waiting through 22 s of shot it already saw play.
##
## MISSING FILES (docs/BUILD_PLAN.md Phase 5 round 2, "Missing-file rule broken"): either
## `finale_launch.gd` or `finale_gift.gd` missing means there is no way to reach DONE honestly - the
## end state was never applied and/or the gift was never shown. `_instantiate_guarded` has already
## logged `FINALE missing <path>`; this function's own job is to STOP right there, calling neither
## `finish_story()` nor `stop_stragglers()` nor `release()`, leaving the stage exactly at 3 (the
## caller's checkpoint from before this ran) so a later load with the file present picks the chain
## back up instead of the story being marked done on a stub.
func _run_send_and_gift(meeting: Node) -> void:
	var skip_sendoff := FinaleState.consume_skip_sendoff()
	if not skip_sendoff and meeting.has_method("play_send_beat"):
		await meeting.call("play_send_beat")

	var launch := _instantiate_guarded(FINALE_LAUNCH_PATH, "FinaleLaunch")
	if launch == null:
		return  # missing file already logged; stage stays at 3, nothing marked done.
	if skip_sendoff and launch.has_method("apply_end_state"):
		launch.call("apply_end_state")
	elif launch.has_method("play"):
		launch.call("play", meeting)
		if launch.has_signal("finished"):
			await Signal(launch, "finished")

	var gift := _instantiate_guarded(FINALE_GIFT_PATH, "FinaleGift")
	if gift == null:
		return  # missing file already logged; stage stays at 3, nothing marked done.
	if gift.has_method("play"):
		gift.call("play", meeting)
		if gift.has_signal("finished"):
			await Signal(gift, "finished")

	FinaleState.finish_story()
	if is_instance_valid(launch) and launch.has_method("stop_stragglers"):
		launch.call("stop_stragglers")
	if is_instance_valid(meeting) and meeting.has_method("release"):
		meeting.call("release")


## Guarded load + instance under World, or null (and logged) if the file is missing.
func _instantiate_guarded(path: String, node_name: String) -> Node:
	if not ResourceLoader.exists(path):
		_log_missing(path)
		return null
	var world := get_parent()
	if world == null:
		return null
	var existing := world.get_node_or_null(node_name)
	if existing != null:
		return existing
	var inst: Node = (load(path) as GDScript).new()
	inst.name = node_name
	world.add_child(inst)
	return inst


func _log_missing(path: String) -> void:
	print("FINALE missing %s" % path)


# ============================================================================= test hooks
## TEST HOOK (a Director "call" step needs a live node - FinaleState.debug_report is static). Not
## used anywhere in the shipped game; matches the shape of PartCelebration's own `debug_report`.
func debug_report(tag: String = "") -> void:
	FinaleState.debug_report(tag)
