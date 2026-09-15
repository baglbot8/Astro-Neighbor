class_name FinaleState
extends RefCounted
## THE FINALE'S STATE MACHINE (docs/PHASE5_SPEC.md §1 "Home is here", docs/BUILD_PLAN.md Phase 5
## builder K). STATIC FUNCTIONS ONLY - like CampaignData, this is never instanced; every caller reads
## and writes through these functions rather than touching GameState.flags directly, so there is one
## place that knows the shape of "finale_stage", the save gate and the debug API.
##
## ============================================================================== THE STAGE
## `GameState.flags["finale_stage"]`, an int 0-4 (NONE, CALLED, MET, SENT, DONE - see `stage()`'s
## callers in finale.gd for the full table). JSON has no integer type, so a stage saved as 2 comes
## back from disk as the FLOAT 2.0 - every reader MUST go through `stage()`, which casts with `int()`,
## never read the flag directly (docs/PHASE5_SPEC.md §1: "read through int()").
##
## ============================================================================== SAVING
## The finale checkpoints the game itself at four moments (the user's decision, docs/BUILD_PLAN.md
## Phase 5 "USER DECISIONS"): after the call, before the choice, when the rocket launches, and at the
## very end. `checkpoint()` is the ONLY way the finale ever saves - it calls `can_save()` first, which
## refuses under a Director (unless the timeline explicitly passed `--finale-allow-save`, for a critic
## who wants to inspect the written file) and refuses for good, for the rest of THIS PROCESS, the
## instant any debug_* function below runs or `--finale=` fires (Engine meta "finale_dev_run" - chosen
## over a GameState flag because a debug run must never leave a trace that could leak into a save some
## OTHER system writes later in the same session; SaveManager itself has no guard of its own, so this
## is the only thing standing between a dev-menu poke and the player's real save file).
##
## ============================================================================== IDEMPOTENCY
## `finish_story()` may be called more than once on purpose (both `finale.gd`'s own chain and
## `finale_gift.gd`'s last box call it, belt and braces) - it is a no-op past the first call that
## actually reaches DONE, so "emits campaign_changed once" and "one checkpoint" hold either way.

const HOME_ID := "home"
## Read by DEV's dev_menu.gd via `load("res://src/campaign/finale_state.gd")`, and by finale.gd's own
## `--finale=` handling - kept here, not re-typed in three places, since this IS this file's own path.
const SCRIPT_PATH := "res://src/campaign/finale_state.gd"


# ============================================================================= stage
## The current beat: 0 NONE, 1 CALLED, 2 MET, 3 SENT, 4 DONE. Always through this - never read
## `GameState.flags["finale_stage"]` directly (see the class doc's note on JSON's float round-trip).
static func stage() -> int:
	return int(GameState.flags.get("finale_stage", 0))


## Writes the stage. Callers checkpoint separately (docs/PHASE5_SPEC.md §1's table: each row's stage
## change and its checkpoint are listed as two steps, and not every write is followed by one - the
## defensive "elsewhere" downgrade at stage 3 is a write with its own checkpoint, decided by the
## caller, not by this function).
static func set_stage(n: int) -> void:
	GameState.flags["finale_stage"] = n


## True once the ending has finished: `finish_story()` sets both this and the stage together, but a
## caller that only cares "is she a skiff yet" should ask this, not infer it from the stage number.
static func has_ship() -> bool:
	return bool(GameState.flags.get("finale_ship", false))


# ============================================================================= spots
## The meeting's crowd layout: the axis and each NPC's planet-local spot (docs/PHASE5_SPEC.md §1:
## "re-checked on load" - `finale_meeting.gd` re-validates these every time, this is just storage).
static func spots() -> Dictionary:
	var s: Variant = GameState.flags.get("finale_spots", {})
	return s if s is Dictionary else {}


static func set_spots(d: Dictionary) -> void:
	GameState.flags["finale_spots"] = d


# ============================================================================= saving
## False under a Director without the critic's own opt-in, and false for good, this process, the
## moment any debug_* function or `--finale=` has run. Neither check is about WHERE we are in the
## story - a legitimate checkpoint from a human playing the real game passes both.
static func can_save() -> bool:
	if Engine.has_meta("finale_dev_run") and bool(Engine.get_meta("finale_dev_run")):
		return false
	if Director.is_active() and not OS.get_cmdline_user_args().has("--finale-allow-save"):
		return false
	return true


## The finale's only path to SaveManager. Returns whether it actually wrote.
static func checkpoint() -> bool:
	if not can_save():
		return false
	return SaveManager.save_game()


# ============================================================================= after the story
## docs/PHASE5_SPEC.md §6: DONE sets the stage, the ship flag and story_done, emits campaign_changed
## ONCE, restores the clock and checkpoints. Idempotent (see the class doc) - safe for both finale.gd's
## own chain and finale_gift.gd to call.
static func finish_story() -> void:
	if stage() >= 4 and has_ship() and GameState.story_done:
		return
	set_stage(4)
	GameState.flags["finale_ship"] = true
	GameState.story_done = true
	EventBus.campaign_changed.emit()
	_restore_clock()
	checkpoint()


## The day/night clock, back to its ordinary speed. A blunt, stateless "back to 1.0" - by the time
## DONE is reached the story is over for good, so there is no earlier value worth remembering here
## (contrast finale.gd's own hold/restore around the Call, which DOES remember what it interrupted).
static func _restore_clock() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var env := tree.root.get_node_or_null("World/Environment")
	if env != null:
		env.set("time_scale", 1.0)


# ============================================================================= debug API (§10)
## Every function below: sets `finale_dev_run` (so `can_save()` is false for the rest of this process),
## returns the toast text for the caller to show (DEV's dev_menu.gd - these do NOT toast themselves,
## so a caller that wants no toast, or a different one, is free not to show it), and travels with
## `SceneRouter.go_to_planet` (fire-and-forget - these are synchronous functions, and the transition's
## fade plays out on its own after this returns).

static func debug_reset_before_finale() -> String:
	Engine.set_meta("finale_dev_run", true)
	# The gift shortcut's one-shot "skip the send-off" meta belongs to a later beat than a reset lands
	# on. `debug_start_gift` sets it and only the Commons chain consumes it - if that chain never got
	# that far (a reset straight after, or the meeting file missing), it stayed set and the NEXT natural
	# stage-3 chain in this process skipped the send-off. Cleared here like `_ensure_campaign_running`
	# clears it for every debug_start_* (docs/BUILD_PLAN.md Phase 5, KF (b)).
	Engine.remove_meta("finale_skip_sendoff")
	GameState.campaign_active = true
	GameState.story_done = false
	var ids := _part_ids()
	# Parts 1-4: every part but the last (CampaignData.PARTS is Zorp, Bolt, Fen, Grig, Vela in order).
	GameState.rocket_parts = ids.slice(0, maxi(0, ids.size() - 1))
	var last_id: String = ids[ids.size() - 1] if not ids.is_empty() else ""
	# "Vela's part and its scrap in the bag": the finished part sits in the inventory, exactly the way
	# ProjectSystem hands it over on the last talk (project_system.gd `_reward_part` etc. both call
	# `GameState.add_item(part_id)`) - ready to fit at the bench without playing her whole project.
	if last_id != "" and not GameState.rocket_parts.has(last_id) and not GameState.has_item(last_id):
		GameState.add_item(last_id)
	# docs/BUILD_PLAN.md Phase 5 round 2: fitting the last part at the bench spends its own
	# "scrap_cost" (project_system.gd registers part_fit_scrap into Catalog; part_vela's is 8) -
	# STARTING_SCRAP is 5, so a bare reset left the 5th part impossible to fit (5th part stayed
	# unfitted; the caller measured this as "scrap stays 5, part_vela costs 8"). Top up, never take
	# away - a player who already has more scrap than that keeps every bit of it.
	if last_id != "":
		var fit_cost := int(Catalog.get_item(last_id).get("scrap_cost", 0))
		GameState.scrap = maxi(GameState.scrap, fit_cost)
	set_stage(0)
	GameState.flags.erase("finale_ship")
	GameState.flags.erase("finale_spots")
	EventBus.rocket_parts_changed.emit(GameState.rocket_part_count())
	EventBus.campaign_changed.emit()
	SceneRouter.go_to_planet(HOME_ID)
	return "Reset for the finale - four parts fitted, the last one waiting in your bag. Landing home."


static func debug_start_call() -> String:
	Engine.set_meta("finale_dev_run", true)
	_ensure_campaign_running()
	_ensure_all_parts_fitted()
	set_stage(0)
	SceneRouter.go_to_planet(HOME_ID)
	return "All five parts fitted. The call should start once things go quiet."


static func debug_start_meeting() -> String:
	Engine.set_meta("finale_dev_run", true)
	_ensure_campaign_running()
	_ensure_all_parts_fitted()
	set_stage(1)
	SceneRouter.go_to_planet("hub")
	return "Stage set to CALLED. Landing on the Commons for the meeting."


static func debug_start_choice() -> String:
	Engine.set_meta("finale_dev_run", true)
	_ensure_campaign_running()
	_ensure_all_parts_fitted()
	set_stage(2)
	SceneRouter.go_to_planet("hub")
	return "Stage set to MET. Landing on the Commons - the Professor should re-ask."


static func debug_start_sendoff() -> String:
	Engine.set_meta("finale_dev_run", true)
	_ensure_campaign_running()
	_ensure_all_parts_fitted()
	set_stage(3)
	SceneRouter.go_to_planet("hub")
	return "Stage set to SENT. Landing on the Commons for the send-off."


## Distinct from `debug_start_sendoff`: this jumps PAST the send-off shot itself, straight to the gift
## (docs/PHASE5_SPEC.md §10: "stage 3, send-off ended"). finale.gd reads `consume_skip_sendoff()` once,
## the first time it builds the chain after this runs, and calls `FinaleLaunch.apply_end_state()`
## instead of `play()` - kept in Engine metadata, like `finale_dev_run`, NEVER in GameState.flags, so a
## debug shortcut can never leak into a real save some other system happens to write later.
static func debug_start_gift() -> String:
	Engine.set_meta("finale_dev_run", true)
	_ensure_campaign_running()
	_ensure_all_parts_fitted()
	set_stage(3)
	Engine.set_meta("finale_skip_sendoff", true)
	SceneRouter.go_to_planet("hub")
	return "Send-off already played. Landing straight on the gift."


static func debug_after_story() -> String:
	Engine.set_meta("finale_dev_run", true)
	_ensure_campaign_running()
	_ensure_all_parts_fitted()
	finish_story()
	SceneRouter.go_to_planet(HOME_ID)
	return "Story marked done - every world open, the skiff on the pad. Landing home."


## One line for a timeline to assert on: `FINALE <tag> stage= planet= parts= story_done= ship= gates=
## visits= can_save=` (docs/PHASE5_SPEC.md §10, verbatim).
static func debug_report(tag: String = "") -> void:
	print("FINALE %s stage=%d planet=%s parts=%d story_done=%s ship=%s gates=%s visits=%s can_save=%s" % [
		tag, stage(), GameState.current_planet_id, GameState.rocket_part_count(),
		str(GameState.story_done), str(has_ship()), str(CampaignData.gates_on()),
		str(_visits_on()), str(can_save()),
	])


# ============================================================================= debug helpers
## finale.gd calls this once per chain attempt; it is true only immediately after `debug_start_gift`,
## and only for the very next read (never GameState, never the save - see `debug_start_gift`'s note).
static func consume_skip_sendoff() -> bool:
	var v := Engine.has_meta("finale_skip_sendoff") and bool(Engine.get_meta("finale_skip_sendoff"))
	Engine.remove_meta("finale_skip_sendoff")
	return v


static func _ensure_campaign_running() -> void:
	GameState.campaign_active = true
	GameState.story_done = false
	# docs/BUILD_PLAN.md Phase 5 round 2 ("Debug API leaks state"): every debug_start_* jump is a
	# FRESH beat - `finale_ship` and the gift-skip meta belong to a LATER stage than any debug_start_*
	# lands on, and leaking either one past a jump backwards (e.g. debug_start_call right after
	# debug_after_story) left the ship flag true at stage 0 (k3_seq). Cleared here, the one helper
	# every debug_start_* below calls, rather than repeated in each - `debug_start_gift` re-sets the
	# skip meta itself immediately after, which is fine, that one call site means it on purpose.
	GameState.flags.erase("finale_ship")
	Engine.remove_meta("finale_skip_sendoff")


static func _ensure_all_parts_fitted() -> void:
	if GameState.rocket_part_count() >= CampaignData.PARTS.size():
		return
	GameState.rocket_parts = _part_ids()
	EventBus.rocket_parts_changed.emit(GameState.rocket_part_count())
	EventBus.campaign_changed.emit()


static func _part_ids() -> Array:
	var out: Array = []
	for p: Dictionary in CampaignData.PARTS:
		out.append(str(p.get("id", "")))
	return out


# ============================================================================= --finale-trace=
## docs/BUILD_PLAN.md Phase 5: "--finale-trace= names one file that K2, L2 and G each append to under
## their own tag." Does nothing without the flag (checked fresh every call - this fires only a
## handful of times per run, at beat boundaries, never per-frame, so re-parsing `OS.get_cmdline_user_
## args()` each time costs nothing worth caching). One shared file: each caller passes its own tag so
## the lines interleave in call order without stepping on each other (single-threaded, no locking
## needed) - "K2 ask stage=1", "L2 ignite t=1.00", "G tarp_off t=4.10", one per line.
static func trace(tag: String, text: String) -> void:
	var path := _trace_path()
	if path == "":
		return
	var f: FileAccess
	if FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("FinaleState.trace: could not open '%s'" % path)
		return
	f.store_line("%s %s" % [tag, text])
	f.close()


static func _trace_path() -> String:
	const ARG := "--finale-trace="
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(ARG):
			return a.substr(ARG.length())
	return ""


# ============================================================================= misc helpers
## `VisitorSystem.visits_on()` by path - visitor_system.gd has no class_name (see its own header), and
## it is a Phase 4 file this static class has no need to depend on hard.
static func _visits_on() -> bool:
	const VS_PATH := "res://src/campaign/visitor_system.gd"
	if not ResourceLoader.exists(VS_PATH):
		return false
	return bool(load(VS_PATH).call("visits_on"))
