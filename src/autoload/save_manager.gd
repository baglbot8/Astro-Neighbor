extends Node
## Saves/loads GameState to user://astro_neighbor_save.json, and keeps the session safe.
##
## THREE JOBS, added 2026-09-20 after "a phone browser can kill the tab at any moment and the
## whole session is gone":
##   1. AUTOSAVE at the moments that matter, throttled, silent (`_autosave`).
##   2. THE PHONE CASE: the browser hiding or unloading the page writes the save FIRST, and the
##      bytes have to survive a page reload (`_install_web_hooks`, `_mirror_write`).
##   3. NEVER HALF-WRITTEN: temp file -> verify -> rename over the real one, previous good save
##      kept as a .bak, and a load that falls back to it (`_write_atomic`, `load_game`).
##
## WHAT DOES NOT CHANGE: `save_game()` is still the manual "Save game" the pause menu and the
## player's own door call, it still emits `game_saved`, and it still returns whether it wrote. The
## callers still own the "Saved!" toast. `FinaleState.checkpoint()` still routes through it.

const SAVE_PATH := "user://astro_neighbor_save.json"
## The previous good save. Written by RENAMING the old main file, so it costs no extra serialise.
const BAK_PATH := "user://astro_neighbor_save.bak.json"
## Scratch for the atomic write. Never loaded from — a file here is by definition unverified.
const TMP_PATH := "user://astro_neighbor_save.tmp.json"

## THE BROWSER MIRROR, and it is not a nicety — it is the only thing that makes the pagehide case
## actually work. Godot's `user://` on the web is an IndexedDB filesystem (IDBFS) that flushes on
## its own asynchronous schedule; a tab that is being torn down does not get to finish an IDB
## transaction. `localStorage.setItem` is SYNCHRONOUS and durable, so the same JSON goes there too
## on every web save, and a load prefers whichever of the two is newer (`_saved_unix`).
const MIRROR_KEY := "astro_neighbor_save_v1"

## Minimum seconds between autosaves. Every write — manual, finale checkpoint, autosave — resets
## this clock, so an autosave can never land on top of another save.
const AUTOSAVE_THROTTLE := 8.0
## A plain periodic save while the player just plays and nothing else has triggered one.
const AUTOSAVE_PERIOD := 120.0
## The longest a write may be held back because a modal is in front of the player. See `_autosave`.
##
## THIS IS THE REAL WORST-CASE LOSS, not AUTOSAVE_THROTTLE. Measured 2026-09-20 at the old value of
## 45 s: a run where the guide's opening dialogue stayed open held `pending='stardust'` for 45 s
## straight with a trigger firing every second, then wrote once at the ceiling. "Worst loss 8.5 s"
## is only true outside a conversation, a shop or a cutscene — and the phone, where the tab dies, is
## exactly where a player gets interrupted mid-dialogue. So the ceiling is 20 s: a save measured
## 0.6-2.7 ms against a 50 ms frame budget, and one of those every 20 s during a long conversation
## is not something a player can see. Worst case is now ~20 s in a modal, ~8 s outside one.
const MODAL_DEFER_MAX := 20.0

## The last write's wall time: the throttle, the periodic backstop and the watchdog all measure
## from it. Set in `_ready` rather than left at "never", so the watchdog cannot fire before the
## first save has had a chance to happen, and so nothing writes during the first seconds of a load.
var _last_write_ms: int = 0
## True while `_write_atomic` is inside a write. Re-entrancy guard: an autosave can never start in
## the middle of the finale's own checkpoint write, or of a manual save.
var _writing := false
## A trigger fired while a modal was open (shop, dialogue, cutscene, pause) or inside the throttle
## window. Deferred, not dropped. `_pending_since_ms` is when the wait started, for MODAL_DEFER_MAX.
var _pending_reason := ""
var _pending_since_ms: int = 0
## One warning per session when nothing has been saved for far longer than it should have been.
## See the watchdog in `_process`: a stall here is silent by design otherwise, and a silent stall
## is indistinguishable from "the player is standing still" right up until the session is lost.
var _warned_stall := false
## `GameState.day_count` as of the last tick, so the day rolling over is a trigger. There is no
## EventBus signal for it (environment.gd:312 writes the field directly and emits nothing), and
## environment.gd is not this builder's file to edit, so this polls instead — one int compare a frame.
var _last_day := -1

## Whether autosave is allowed AT ALL in this process. Decided once in `_ready` from the command
## line and the display server; see `_decide_session`.
var _autosave_enabled := false
## Latched off for the rest of the process the moment the dev menu is opened. `dev_menu.gd` says
## "Nothing here saves" on its own front page and that has to stay true — but the dev menu's edits
## (add scrap, set the day, grant a part) go through the same GameState setters that fire the
## triggers below, so suppressing only *while it is open* would just move the write to the next
## trigger after it closes. Once this session has touched the dev menu it is a dev session.
var _dev_latched := false
## `--allow-autosave`: this run's Director timeline IS the test, so the Director gate below is
## lifted too. Same shape and same reason as `--finale-allow-save` in src/campaign/finale_state.gd.
var _force_allow := false
## Why autosave is off, for `debug_status()` and the one startup print.
var _off_reason := "not decided"

## Set when `load_game` had to fall back. Shown as one short line the first time a planet finishes
## loading, because a load happens at the title screen where there is no HUD to toast into.
var _pending_notice := ""

## True once a planet has finished loading, false again at the title. THE TITLE MUST NOT AUTOSAVE:
## a fresh boot sits there with a default GameState, and a desktop alt-tab (focus-out) would write
## that default over nothing and hand the player a "Continue" button into a game they never started.
const TITLE_SCENE := "res://src/ui/title/title_screen.tscn"
var _started := false

## Held so the browser keeps the listeners alive; a freed callback stops firing. Untyped on
## purpose — `JavaScriptObject` is a web-only class and this file is parsed on every platform.
var _web_cb = null
var _web_win = null
var _web_doc = null

## Counters the critic's probes read back. Cheap and always on.
var autosaves_written := 0
var saves_written := 0
var last_write_ms_cost := 0.0
## See `_write_failed`. A failing `user://` fails on every attempt, so the count is kept and the
## ERROR is said once.
var write_failures := 0
var _write_error_said := false
## The .bak roll failing does NOT fail the write, so it cannot share the flag above (a successful
## write re-arms that one, and this would then speak on every single save). Its own latch, never
## re-armed.
var _bak_warn_said := false


func _ready() -> void:
	# Autoloads pause with the tree by default; the lifecycle hook and the day poll must not.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_write_ms = Time.get_ticks_msec()
	_decide_session()
	print("[SaveManager] autosave: %s (%s)" % ["on" if _autosave_enabled else "OFF", _off_reason])
	_connect_triggers()
	_install_web_hooks()


# ============================================================================== is this a real game
## AUTOSAVE IS OFF UNLESS THIS IS A PERSON PLAYING, and this gate is an ALLOWLIST on purpose.
##
## IT USED TO BE A BLOCKLIST and that was wrong in the most expensive possible way. It named the
## Director and capture flags and probe scenes, and it therefore said "on (interactive session)" for
## the two commands CLAUDE.md itself tells agents to type — `godot --path <copy> res://src/world/
## world.tscn -- --planet=zorp` and `godot --path . -- --skip-title --planet=bolt`. Measured
## 2026-09-20: one 22 s world.tscn run rolled a real day-120 save into the .bak and then wrote a
## default new game over both copies. world.tscn never loads a save, so there was nothing to get
## back. With docs/OPEN_ISSUES.md 51 (an rsync re-sync puts the real `config/name` back into a
## scratch copy) that made OPEN_ISSUES 42 a one-command accident. A blocklist can only ever name the
## test runs someone thought of; the set of test runs grows every week.
##
## SO THE TEST IS POSITIVE, and it is the two things that are true of a real player and of nothing
## else: the boot scene is the project's own main scene, and the process carries no user arg. Every
## other shape of run — a scene named on the command line, --skip-title, --planet=, --new-game,
## --time=, --ui=mobile, a Director timeline, headless — is a test run until it says otherwise with
## `--allow-autosave`. Failing closed costs a test run nothing; failing open costs the user the save.
##
## `--allow-autosave` after the `--` forces it on (the tests for this feature have to drive ordinary
## play from a timeline; same shape as `--finale-allow-save` in src/campaign/finale_state.gd).
## `--no-autosave` forces it off and wins over everything.

## USER ARGS A REAL PLAYER SESSION CARRIES. Measured 2026-09-20: none. The shipped web build
## (tools/publish_web.sh, the iPhone's build) passes no user args, and neither does an exported
## desktop binary — every `--` arg in this project belongs to a tool or a test. The empty list is
## the point; if a shipped build ever needs one, add it HERE and nowhere else.
const PLAYER_USER_ARGS := []

## Engine-side flags that are never a person playing. Checked with `begins_with` so the `=value`
## spelling cannot slip past.
const DEV_ENGINE_FLAGS := [
	"--write-movie", "--quit-after", "--quit", "--fixed-fps", "--headless", "--import",
	"--export-release", "--export-debug", "--export-pack", "--doctool", "--script", "--check-only",
]


func _decide_session() -> void:
	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--no-autosave"):
		_off_reason = "--no-autosave"
		return
	if user_args.has("--allow-autosave"):
		_autosave_enabled = true
		_force_allow = true
		_off_reason = "--allow-autosave"
		return
	if DisplayServer.get_name() == "headless" or OS.has_feature("headless"):
		_off_reason = "headless run"
		return
	# 1. NO USER ARG. One unknown `--` arg is enough to call the whole run a test.
	for a in user_args:
		if not PLAYER_USER_ARGS.has(a):
			_off_reason = "dev user arg %s (add --allow-autosave to save anyway)" % a
			return
	# 2. THE BOOT SCENE IS THE MAIN SCENE. `run/main_scene` is res://src/ui/title/title_screen.tscn;
	# a scene named on the command line that is not that one is a probe, a showcase or a direct
	# world.tscn run, none of which is the game a player started.
	var main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	for a in OS.get_cmdline_args():
		for flag: String in DEV_ENGINE_FLAGS:
			if a.begins_with(flag):
				_off_reason = "dev engine flag %s" % a
				return
		var low := a.to_lower()
		if low.ends_with(".tscn") or low.ends_with(".scn"):
			if a != main_scene:
				_off_reason = "boot scene %s is not the main scene" % a
				return
	_autosave_enabled = true
	_off_reason = "interactive session"


## Every check that has to hold at the moment of the write, not just at boot.
func autosave_allowed() -> bool:
	if not _autosave_enabled or _dev_latched or not _started:
		return false
	if not _force_allow and Director != null and Director.is_active():
		return false
	# The finale's own rule, borrowed rather than duplicated: any `debug_*` on FinaleState sets
	# this meta for the rest of the process, and a session that has used the finale debug API is
	# a dev session whatever else it looks like.
	if Engine.has_meta("finale_dev_run") and bool(Engine.get_meta("finale_dev_run")):
		return false
	return true


# ============================================================================== triggers
## THE TRIGGER LIST, all from signals `event_bus.gd` already declares (nothing was added there):
##   travel_started / travel_finished   leaving a planet, and arriving on the next one
##   stardust_changed / scrap_changed   buying, selling, a favour's payout, the planet upgrade
##                                      (`GameState.grow_home` pays through `spend_scrap`, so this
##                                      IS the planet-upgrade trigger — it has no signal of its own)
##   item_added                         a Norm reward (`norm_rewards.gd` grants through add_item),
##                                      a gift, a shop purchase's goods
##   decoration_placed / removed        placing or picking up a decoration
##   favor_completed                    a favour finished
##   project_step_completed / project_completed / rocket_part_fitted / campaign_changed
##                                      a story step, a neighbour's part, the finale's own stages
##   friendship_changed                 a conversation that moved a neighbour
##   day_count (polled, see `_last_day`) the day rolling over
##   AUTOSAVE_PERIOD                    plain periodic, while the player just plays
##
## Several of these fire together (a purchase is stardust_changed + item_added), and cheap ones fire
## often (a collectible pick is stardust_changed). That is what AUTOSAVE_THROTTLE is for: the
## trigger list is deliberately generous and the throttle is the only thing deciding how often the
## disk is actually touched.
func _connect_triggers() -> void:
	EventBus.travel_started.connect(func(_f: String, _t: String) -> void: _autosave("leave_planet"))
	EventBus.travel_finished.connect(func(_t: String) -> void: _autosave("arrive_planet"))
	EventBus.stardust_changed.connect(func(_n: int, _d: int) -> void: _autosave("stardust"))
	EventBus.scrap_changed.connect(func(_n: int, _d: int) -> void: _autosave("scrap"))
	EventBus.item_added.connect(func(_i: String, _c: int) -> void: _autosave("item"))
	EventBus.decoration_placed.connect(func(_p: String, _i: String, _t: String) -> void: _autosave("deco_placed"))
	EventBus.decoration_removed.connect(func(_p: String, _i: String) -> void: _autosave("deco_removed"))
	EventBus.favor_completed.connect(func(_f: String, _r: String, _s: int) -> void: _autosave("favor"))
	EventBus.project_step_completed.connect(func(_n: String, _i: int) -> void: _autosave("story_step"))
	EventBus.project_completed.connect(func(_n: String, _p: String) -> void: _autosave("project"))
	EventBus.rocket_part_fitted.connect(func(_p: String) -> void: _autosave("part_fitted"))
	EventBus.campaign_changed.connect(func() -> void: _autosave("campaign"))
	EventBus.friendship_changed.connect(func(_n: String, _l: int) -> void: _autosave("friendship"))
	# See `_dev_latched`.
	EventBus.ui_modal_opened.connect(_on_modal_opened)
	# The recovery line needs a HUD to land in; a load happens at the title, which has none.
	EventBus.planet_loaded.connect(_on_planet_loaded)


func _on_modal_opened(n: String) -> void:
	if n == "dev_menu" and not _dev_latched:
		_dev_latched = true
		_pending_reason = ""
		print("[SaveManager] dev menu opened — autosave off for the rest of this session.")


func _on_planet_loaded(_planet_id: String) -> void:
	_started = true
	if _pending_notice == "":
		return
	var msg := _pending_notice
	_pending_notice = ""
	EventBus.toast_requested.emit(msg, "warn")


func _process(_delta: float) -> void:
	# The title screen is not the game — see `_started`. Checked before anything else so
	# quit-to-title turns autosave off again for the rest of the time spent there.
	var tree := get_tree()
	if tree != null and tree.current_scene != null and tree.current_scene.scene_file_path == TITLE_SCENE:
		_started = false
		_pending_reason = ""
	# THE WATCHDOG, and it is here because this feature fails SILENTLY. A session where the gate
	# below is stuck shut looks exactly like a session where the player is standing still — right
	# up to the moment the tab dies and the save turns out to be twenty minutes old. In ordinary
	# play the periodic save writes every AUTOSAVE_PERIOD, so twice that with nothing written means
	# something is wrong, and this is the one line that says so. Once per session; the condition
	# deliberately sits OUTSIDE `autosave_allowed()` so it can report that gate being the cause.
	if _autosave_enabled and _started and not _dev_latched and not _warned_stall \
			and Time.get_ticks_msec() - _last_write_ms > int(AUTOSAVE_PERIOD * 2.0 * 1000.0):
		_warned_stall = true
		push_warning("SaveManager: nothing saved for %.0f s — %s, modals %s" % [
			AUTOSAVE_PERIOD * 2.0, str(debug_status()), str(EventBus.open_modals())])
	if not autosave_allowed():
		return
	# THE DAY ROLLING OVER. No signal exists for it, so this compares the field. First tick just
	# records where we are, so loading a save on day 12 is not read as eleven days passing.
	if _last_day < 0:
		_last_day = GameState.day_count
	elif GameState.day_count != _last_day:
		_last_day = GameState.day_count
		_autosave("new_day")
	# THE BACKSTOP, measured off the wall clock rather than off time spent inside this gate: if the
	# gate was shut for a while (a cutscene, a scene change), the periodic save is due the moment it
	# reopens, not AUTOSAVE_PERIOD later.
	if Time.get_ticks_msec() - _last_write_ms >= int(AUTOSAVE_PERIOD * 1000.0):
		_autosave("periodic")
	# THE ONE PLACE A DEFERRED WRITE LANDS. `_autosave` never drops a trigger: whatever stopped it
	# (a modal in front of the player, or the throttle window) it leaves the reason here, and this
	# picks it up on the first frame both are clear. That is what makes the worst possible loss
	# exactly one throttle window rather than "until something else happens to fire".
	if _pending_reason != "":
		_autosave(_pending_reason)


## SILENT. No toast, no sound, nothing that interrupts play — that is a rule of this feature, and
## it is why the "Saved!" toast stays in the callers rather than moving in here.
##
## DEFERRED, NEVER DROPPED. Two things hold a write back and both only delay it (see `_process`):
##   * A MODAL IS OPEN. A shop purchase fires its triggers with the panel in front of the player,
##     and the finale runs behind a "cutscene" modal for minutes at a time — that is the one place
##     a hitch would be visible, and a finale checkpoint may be mid-flight.
##   * THE THROTTLE. Several triggers fire together (a purchase is stardust_changed + item_added)
##     and cheap ones fire often, so the disk is touched at most once per AUTOSAVE_THROTTLE.
func _autosave(reason: String) -> void:
	if not autosave_allowed() or _writing:
		return
	var now := Time.get_ticks_msec()
	if EventBus.is_modal_open():
		_hold(reason, now)
		# THE CEILING ON THE MODAL DEFER, and it is not a nicety. "Wait for the modal to close" is
		# only safe while something is going to close it. A modal left open by a bug pins the gate
		# open forever (event_bus.gd's `reset_modals` exists because that has happened in this game
		# before), and a finale cutscene can legitimately hold one for minutes. Either way the
		# session would go unsaved, which is the exact failure this whole feature exists to stop.
		# A save measured 0.6-2.7 ms; one of those every 45 s, against a 50 ms frame budget, is not
		# something a player can see, and it beats losing the session every time.
		if now - _pending_since_ms < int(MODAL_DEFER_MAX * 1000.0):
			return
	elif now - _last_write_ms < int(AUTOSAVE_THROTTLE * 1000.0):
		_hold(reason, now)
		return
	_pending_reason = ""
	if _write_atomic("auto:" + reason):
		autosaves_written += 1


func _hold(reason: String, now: int) -> void:
	if _pending_reason == "":
		_pending_since_ms = now
	_pending_reason = reason


# ============================================================================== the public API
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BAK_PATH) or _mirror_read() != ""


## The manual "Save game". Unchanged in what it means to its callers: writes now, returns whether
## it wrote, emits `game_saved`.
func save_game() -> bool:
	if not _write_atomic("manual"):
		return false
	saves_written += 1
	EventBus.game_saved.emit()
	return true


## MAIN -> the interrupted write's temp file -> .bak -> browser mirror, and on the web whichever of
## the file and the mirror carries the newer `_saved_unix` wins outright (IDBFS can be behind by a
## whole session). Returns false only when there is nothing loadable anywhere, which is the caller's
## cue to start a new game — `title_screen.gd` already does exactly that.
func load_game() -> bool:
	var from_file: Dictionary = _read_dict(SAVE_PATH)
	var source := "main"
	if from_file.is_empty():
		# THE TEMP FILE IS NOT JUNK IN THIS ONE WINDOW, and the window is real: 1 of 50 kill tests
		# landed between the two renames, leaving main MISSING, a good .bak, and a complete temp file
		# on disk. `_write_atomic_inner` read that temp file back and parsed it BEFORE it started
		# renaming, so it is a verified save and it is newer than the .bak. Until 2026-09-20 this
		# skipped straight to the .bak and told the player "damaged" — losing a good session and
		# saying the wrong thing about it. `_read_dict` still has to pass it, so a temp file left by a
		# write that failed VERIFICATION (the other reason one exists) is rejected here as before.
		var tmp: Dictionary = _read_dict(TMP_PATH)
		var bak: Dictionary = _read_dict(BAK_PATH)
		if not tmp.is_empty() and (bak.is_empty() \
				or float(tmp.get("_saved_unix", 0.0)) >= float(bak.get("_saved_unix", 0.0))):
			from_file = tmp
			source = "tmp"
			# Deliberately no notice. Nothing was damaged and nothing was lost — the write simply did
			# not get to finish, and finishing it below is the whole repair.
			_finish_interrupted_write()
		elif not bak.is_empty():
			from_file = bak
			source = "bak"
			_pending_notice = "Your last save was damaged — carried on from the backup."
	var mirror: Dictionary = _parse_dict(_mirror_read())
	var chosen := from_file
	if not mirror.is_empty():
		if from_file.is_empty():
			chosen = mirror
			source = "browser"
			_pending_notice = "Recovered your game from the browser's copy."
		elif float(mirror.get("_saved_unix", 0.0)) > float(from_file.get("_saved_unix", 0.0)) + 1.0:
			chosen = mirror
			source = "browser(newer)"
	if chosen.is_empty():
		push_warning("SaveManager: no loadable save (main, bak and browser copy all unusable).")
		return false
	GameState.from_dict(chosen)
	_last_day = GameState.day_count
	_last_write_ms = Time.get_ticks_msec()
	print("[SaveManager] loaded from %s (day %d, %d stardust)" % [source, GameState.day_count, GameState.stardust])
	EventBus.game_loaded.emit()
	return true


## Complete the rename the kill interrupted, so the next boot finds an ordinary main file instead of
## walking this path again. The dictionary has already been read into memory by the caller, so a
## failure here costs nothing but a repeat.
func _finish_interrupted_write() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if dir.rename(TMP_PATH, SAVE_PATH) == OK:
		print("[SaveManager] finished an interrupted write (temp file promoted to the main save).")


## DELETES THE WHOLE SAVE, all three copies. The .bak and the browser mirror have to go with the
## main file or "Start a brand new planet?" would hand the old game straight back on the next load
## — the recovery path cannot tell a deliberate delete from a corrupt file.
func delete_save() -> void:
	for p in [SAVE_PATH, BAK_PATH, TMP_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_mirror_clear()
	_last_write_ms = Time.get_ticks_msec()
	_pending_notice = ""


# ============================================================================== the atomic write
## NEVER HALF-WRITTEN. The sequence, and every step of it is load-bearing:
##   1. serialise to a string (so a failure here never touches a file at all)
##   2. write it to TMP_PATH and close
##   3. READ TMP BACK AND PARSE IT. A short write, a full disk or a dying tab all show up here,
##      and none of them get to reach the real file.
##   4. rename the existing main file to .bak  (a rename, so the previous good save costs nothing)
##   5. rename TMP over the main file — POSIX rename(2) is atomic, so a reader sees the old file
##      or the new one, never a partial one
## Killed anywhere in that sequence: before 4 the main file is untouched; between 4 and 5 the main
## file is missing and .bak holds the previous good save, which `load_game` falls back to; after 5
## both are good. There is no window where the only copy is a partial file.
##
## FIRST SAVE: there is no main file to rename, so the .bak is written from the same string. That
## is the one save that pays for two writes, and it is what makes "a .bak is always present after
## the first save" true.
func _write_atomic(tag: String) -> bool:
	if _writing:
		push_warning("SaveManager: re-entrant save ignored (%s)" % tag)
		return false
	_writing = true
	var t0 := Time.get_ticks_usec()
	var ok := _write_atomic_inner(tag)
	_writing = false
	if not ok:
		return false
	last_write_ms_cost = float(Time.get_ticks_usec() - t0) * 0.001
	_last_write_ms = Time.get_ticks_msec()
	# Re-arm the one-per-session write ERROR: a condition that cleared and comes back is news again.
	_write_error_said = false
	_last_day = GameState.day_count
	_warned_stall = false
	# ANY write satisfies every outstanding trigger — a save is the whole of GameState, not a diff
	# of whatever fired. Clearing it here is what stops a manual save or a lifecycle write leaving a
	# stale reason behind that writes the identical bytes again one throttle window later.
	_pending_reason = ""
	print("[SaveManager] wrote %s in %.2f ms" % [tag, last_write_ms_cost])
	return true


## SAY IT ONCE. An unwritable `user://` — a full disk, a read-only home, a browser that revoked
## storage quota — does not fail once, it fails on every attempt, and the autosave path attempts
## often. Measured 2026-09-20 with the user dir chmod 500: a save-every-frame probe pushed 482
## identical `ERROR: SaveManager: cannot open the temp save for writing: 12` lines in 8 seconds. The
## save itself survived untouched, so this was only noise — but it is the exact pattern
## `tools/check.sh` greps for, and a wall of ERROR reads as a broken game. So the first failure is a
## real `push_error` and the rest are counted (`write_failures`, in `debug_status`). A successful
## write re-arms it, so a condition that comes back after it cleared is reported again.
func _write_failed(msg: String) -> void:
	write_failures += 1
	if _write_error_said:
		return
	_write_error_said = true
	push_error("SaveManager: %s — saving will keep retrying; this is reported once per session." % msg)


func _write_atomic_inner(tag: String) -> bool:
	var d := GameState.to_dict()
	# Which copy is newer, for the web mirror comparison in `load_game`. `from_dict` reads named
	# keys and ignores anything else, so this is invisible to GameState.
	d["_saved_unix"] = Time.get_unix_time_from_system()
	var text := JSON.stringify(d, "\t")
	if text == "":
		_write_failed("refusing to write an empty save (%s)" % tag)
		return false

	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		_write_failed("cannot open the temp save for writing (error %d)" % FileAccess.get_open_error())
		return false
	f.store_string(text)
	f.close()

	# Step 3: the temp file has to be readable and parse as a dictionary before it is allowed
	# anywhere near the real save.
	if _read_dict(TMP_PATH).is_empty():
		_write_failed("the temp save did not verify — the real save was left untouched (%s)" % tag)
		return false

	var dir := DirAccess.open("user://")
	if dir == null:
		_write_failed("cannot open user:// to rename the save")
		return false
	# THE .bak IS ONLY EVER A GOOD SAVE. Rolling the main file in blind would, in the one case the
	# backup exists for, destroy it: recover from the .bak, play on, and the next save promotes the
	# still-truncated main file over the good backup. So the main file has to parse before it is
	# allowed to become the backup. That costs one 1.5 KB read and parse per save (measured below in
	# `last_write_ms_cost`, which includes it), and it is the difference between a backup and a
	# second copy of the damage.
	if not _read_dict(SAVE_PATH).is_empty():
		# Overwrites any older .bak. POSIX rename replaces the target.
		var e := dir.rename(SAVE_PATH, BAK_PATH)
		if e != OK:
			# Not fatal — the new save still goes into place; only the backup is stale.
			if not _bak_warn_said:
				_bak_warn_said = true
				push_warning("SaveManager: could not roll the old save into the .bak (error %d); "
					% e + "the backup may be stale. Reported once per session.")
	elif not FileAccess.file_exists(BAK_PATH):
		# First save of a brand new game (or the main file is damaged and there is no backup at
		# all): seed the .bak from the same bytes that are about to become the main save.
		var bf := FileAccess.open(BAK_PATH, FileAccess.WRITE)
		if bf != null:
			bf.store_string(text)
			bf.close()
	var err := dir.rename(TMP_PATH, SAVE_PATH)
	if err != OK:
		_write_failed("could not move the new save into place (error %d)" % err)
		return false

	_mirror_write(text)
	return true


## Parses a file into a Dictionary, or returns {} for missing / unreadable / truncated / not-a-dict.
## `{}` doubles as "unusable" on purpose: a real save always has `version` and `day_count` in it.
func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	return _parse_dict(txt)


func _parse_dict(txt: String) -> Dictionary:
	if txt.strip_edges() == "":
		return {}
	# `JSON.parse_string` PUSHES AN ENGINE ERROR on bad input, and a corrupt save is an expected,
	# handled condition here, not a fault: the truncated-save test printed two `ERROR: Parse JSON
	# failed` lines while recovering perfectly, which reads as a broken game and is exactly the
	# pattern `tools/check.sh` greps for. `JSON.new().parse()` returns the error instead.
	var j := JSON.new()
	if j.parse(txt) != OK:
		return {}
	if typeof(j.data) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = j.data
	# A save from before 2026-09-20 has no `_saved_unix` and that is fine, but every save this game
	# has ever written has `day_count`. A JSON object that does not is not one of ours.
	if not d.has("day_count"):
		return {}
	return d


# ============================================================================== the phone case
## THE BROWSER IS ABOUT TO TAKE THE TAB AWAY. Three hooks, because no one of them fires everywhere:
##   * `visibilitychange` on `document` — the iPhone's real "the player switched apps" event, and
##     on iOS Safari it is very often the LAST event a page gets. Saves when hidden.
##   * `pagehide` on `window` — a navigation or a tab close. `beforeunload`/`unload` are
##     deliberately not used: iOS Safari does not fire them reliably and they block the bfcache.
##   * Godot's own `NOTIFICATION_APPLICATION_FOCUS_OUT` / `NOTIFICATION_WM_WINDOW_FOCUS_OUT`
##     (see `_notification`) — covers the desktop build and any case where the browser blurs the
##     canvas without hiding the page.
## All three land on `save_now("lifecycle")`, which bypasses the throttle and the modal defer: there
## may be no next frame.
func _install_web_hooks() -> void:
	if not OS.has_feature("web"):
		return
	_web_cb = JavaScriptBridge.create_callback(_on_web_lifecycle)
	_web_win = JavaScriptBridge.get_interface("window")
	_web_doc = JavaScriptBridge.get_interface("document")
	if _web_doc != null:
		_web_doc.addEventListener("visibilitychange", _web_cb)
	if _web_win != null:
		_web_win.addEventListener("pagehide", _web_cb)
		_web_win.addEventListener("blur", _web_cb)
	print("[SaveManager] web lifecycle hooks installed")


func _on_web_lifecycle(args: Array) -> void:
	var kind := "blur"
	if args.size() > 0 and args[0] != null:
		var t: Variant = args[0].type
		if t != null:
			kind = str(t)
	if kind == "visibilitychange":
		var vis: Variant = JavaScriptBridge.eval("document.visibilityState === 'hidden' ? 1 : 0", true)
		if int(vis if vis != null else 0) != 1:
			return
	save_now("lifecycle:" + kind)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_now("focus_out")


## One "the player left" moment arrives as SEVERAL events, and that is measured, not guessed: a
## desktop alt-tab raises both NOTIFICATION_APPLICATION_FOCUS_OUT and NOTIFICATION_WM_WINDOW_FOCUS_OUT
## (logged as two `wrote focus_out` lines 0.3 ms apart on the first run of this feature), and a
## browser going to the background fires `blur` and then `visibilitychange`. They all describe the
## same state, so `save_now` drops the second one inside half a second. This is NOT the autosave
## throttle — a genuine lifecycle event always writes.
const LIFECYCLE_COALESCE_MS := 500


## Write right now, throttle and modal defer both ignored, no toast, no `game_saved`. For the
## lifecycle hooks only: there may not be another frame. Still respects `autosave_allowed()`, so an
## agent's Director run that loses focus does not write a save, and coalesces the duplicate events
## described above.
func save_now(reason: String) -> bool:
	if not autosave_allowed() or _writing:
		return false
	if Time.get_ticks_msec() - _last_write_ms < LIFECYCLE_COALESCE_MS:
		return false
	if not _write_atomic(reason):
		return false
	autosaves_written += 1
	return true


## The synchronous, durable copy — see the note on MIRROR_KEY. base64 so no quoting or unicode
## escape in the save text can ever break the eval, and so a planet name with a quote in it cannot
## corrupt the mirror.
func _mirror_write(text: String) -> void:
	if not OS.has_feature("web"):
		return
	var b64 := Marshalls.utf8_to_base64(text)
	JavaScriptBridge.eval("try{window.localStorage.setItem('%s','%s');}catch(e){}" % [MIRROR_KEY, b64], true)


func _mirror_read() -> String:
	if not OS.has_feature("web"):
		return ""
	var res: Variant = JavaScriptBridge.eval(
		"(function(){try{return window.localStorage.getItem('%s')||'';}catch(e){return '';}})()" % MIRROR_KEY, true)
	if res == null:
		return ""
	var b64 := str(res)
	if b64 == "":
		return ""
	return Marshalls.base64_to_utf8(b64)


func _mirror_clear() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("try{window.localStorage.removeItem('%s');}catch(e){}" % MIRROR_KEY, true)


# ============================================================================== debug / probes
## What this session decided and what it has written. Read by the save tests; safe to call anywhere.
func debug_status() -> Dictionary:
	return {
		"autosave_enabled": _autosave_enabled,
		"allowed_now": autosave_allowed(),
		"off_reason": _off_reason,
		"dev_latched": _dev_latched,
		"autosaves": autosaves_written,
		"manual_saves": saves_written,
		"last_write_ms": last_write_ms_cost,
		"write_failures": write_failures,
		"pending": _pending_reason,
		"started": _started,
		"main": FileAccess.file_exists(SAVE_PATH),
		"bak": FileAccess.file_exists(BAK_PATH),
		"tmp": FileAccess.file_exists(TMP_PATH),
	}


## Fire a trigger by hand from a Director timeline or a probe, so the autosave path itself can be
## driven without having to reproduce a shop purchase. Goes through every gate `_autosave` does.
func debug_trigger(reason: String = "debug") -> void:
	_autosave(reason)


## `debug_status()` on one line, for a Director timeline, which has no way to print a return value.
func debug_print_status(tag: String = "") -> void:
	print("[SaveManager] status %s %s" % [tag, str(debug_status())])
