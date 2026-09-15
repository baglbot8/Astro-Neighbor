class_name SkipConfirm
extends RefCounted
## THE ONE PLACE every skip in the game asks "are you sure?" (2026-09-14, the user's request #2:
## "I accidentally skipped the intro before"). A travel builder's speed-up/skip control and the
## finale's send-off call this exact API - do not build a second confirm path for a skip.
##
## API:
##   var go: bool = await SkipConfirm.ask(host, "Skip this?", "Skip", "Keep watching")
## `host` is any Node currently in the tree (a Node3D cutscene, a Control, anything - a CanvasLayer
## is added under it and freed again once answered, so nothing is left behind either way). Returns
## true only on an actual confirm; false for "Keep watching" AND for every abort (host left the
## tree before an answer came back, or was freed outright while the question was open). Awaiting it
## a second time while one is already open for that same `host` is refused (returns false at once)
## rather than stacking a second question.
##
## CALLER CONTRACT - the cutscene HOLDS ITS OWN CLOCK while this is open. That is the simpler of the
## two safe options the brief offered (the alternative, "keep playing behind it", means every reader
## of the shot's clock - camera solve, particle timers, the finish-reveal swap - has to be re-checked
## for "is it still exactly right if 4 seconds of real time pass with `_t` frozen mid-frame", and one
## missed spot is a silent desync). So: gate whatever advances your shot's clock behind your own
## "confirming" flag (or phase) for as long as `ask()` is awaiting, exactly the way you already gate
## it behind "skipping" - see `CrashIntro._skip()` / `PartCelebration._skip()` for the pattern. Because
## the clock is frozen, "the cutscene ends while the pop-up is open" cannot happen from your own timer;
## it can still happen from someone freeing your node outright (quit to title), which is handled below
## (see "FREED WHILE OPEN").
##
## THE THREE GUARANTEES the critic measures with real InputEvents (never `Input.action_press`, which
## sends none):
##  1. "Keep watching" is focused by default - `ConfirmPopup.ask(..., default_yes = false)`.
##  2. THE PRESS THAT OPENED THE POPUP CAN NEVER CONFIRM IT, AND NEITHER CAN A RAPID TAP TRAIN LANDING
##     ON THE SAME SPOT. `_Guard` re-evaluates "am I armed" AT EVERY PRESS EDGE (2026-09-14 round 2 -
##     the round 1 version latched "a release happened, ever" plus one 400 ms window since open, which
##     a 10-taps/s train cleared after its 4th tap and then stayed armed forever). The rule now: a
##     press arms the guard only if BOTH (a) at least `MIN_ARM_MS` has passed since this popup opened,
##     and (b) at least `MIN_ARM_MS` has passed since the input stream's last press-or-release of
##     anything (key, pointer, pad button) - i.e. the stream has actually gone quiet before this press,
##     not merely "some time has passed since open". `armed()` just returns whatever the most recent
##     press computed; a release never sets it (see guarantee 3). The opening tap's own press is never
##     seen by `_Guard` at all (it happens before the guard exists - the popup is created IN RESPONSE
##     to it), so the stored flag starts at its default (unarmed) and a same-spot 10-taps/s train can
##     never open a gap of `MIN_ARM_MS` between any two of its presses, so it can never arm. An
##     isolated, deliberate press after a real pause clears both gaps immediately and still confirms
##     with no extra delay beyond `MIN_ARM_MS` - see `_mark_press` for the one same-frame exception
##     this needs (Godot's own touch-to-mouse emulation double-fires every tap as two press edges).
##  3. A HELD KEY, A HELD TOUCH, OR OS KEY-REPEAT CAN NEVER CONFIRM. An echo (or a held touch, which
##     sends no repeat events at all) never opens a `MIN_ARM_MS` gap against the immediately preceding
##     event - a genuine key held down fires an echo roughly every 30-50 ms, far under the window, so
##     the guard is re-armed-false on every single echo and can never go quiet long enough to arm.
##
## A DIRECTOR TIMELINE'S `tap` sends no InputEvent at all (`Input.action_press`/`action_release` -
## see `src/autoload/director.gd`), so `_Guard` also polls `Input.is_action_just_pressed` /
## `is_action_just_released()` for the action names CrashIntro/PartCelebration's own SKIP_ACTIONS use
## plus the popup's own accept/cancel actions, feeding them through the exact same press/release edges
## as a real InputEvent - so a scripted Director tap train is gated identically to a real one.
##
## FREED WHILE OPEN (2026-09-14 round 2, critic finding 2): `layer` is a child of `host`, so
## `queue_free()`-ing `host` (or a scene change tearing down the whole branch, e.g. quit to title)
## frees `layer` and everything under it too. `queue_free()` only QUEUES the deletion - every node in
## the doomed branch still gets its `tree_exiting` while still a fully valid object, before any of
## them are actually deallocated - so `ask()` connects `layer.tree_exiting` to close the question out
## right there: if the popup is still open (nobody answered it), it emits `EventBus.ui_modal_closed`
## itself (nothing else will - the popup's own `_answer()`, which normally does that, is never going
## to run), drops `host` from `_open_for`, and answers the popup's `answered` signal `false` directly -
## which resumes the coroutine suspended on `await popup.ask(...)` below with `go = false`, so `ask()`
## returns false exactly like a decline, instead of hanging forever (a signal await on an object that
## is then deallocated without ever firing its signal never resumes - which is exactly how this used
## to go stale: `_open_for` kept a dead host and the modal count/input-lock the popup opened with it
## were never released, freezing the player for good). `is_open()` additionally drops any invalid host
## it finds on every call, as a second line of defence for a host freed by some other path.

const MIN_ARM_MS := 400

## True while a SkipConfirm popup is on screen for `host` (or any host, if none is given) - lets a
## caller that polls its own skip input skip the poll entirely rather than trying to reason about
## re-entrancy.
static var _open_for: Array[Node] = []

static func is_open(host: Node = null) -> bool:
	_prune()
	if host == null:
		return not _open_for.is_empty()
	return _open_for.has(host)

## Drops any host that was freed without going through `ask()`'s own `tree_exiting` cleanup (belt and
## braces - the normal path already erases its host before that can matter).
static func _prune() -> void:
	var i := _open_for.size() - 1
	while i >= 0:
		if not is_instance_valid(_open_for[i]):
			_open_for.remove_at(i)
		i -= 1


## Awaitable: true only if the player confirmed. False for "Keep watching" or any abort.
static func ask(host: Node, text: String = "Skip this?", yes: String = "Skip", no: String = "Keep watching") -> bool:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return false
	_prune()
	if _open_for.has(host):
		return false # already asking this host something; never stack a second question
	_open_for.append(host)

	var layer := CanvasLayer.new()
	layer.name = "SkipConfirmLayer"
	layer.layer = 150 # over the HUD (10), dialogue (10), CrashIntro's captions (95) and SceneRouter's fade (100)
	host.add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	layer.add_child(root)
	MobileUI.apply_theme(root)
	var popup := ConfirmPopup.new()
	root.add_child(popup)
	var watch := _Guard.new()
	layer.add_child(watch)

	# See "FREED WHILE OPEN" above. `layer` (and therefore `popup`) is still a fully valid object at
	# the instant its own `tree_exiting` fires, so this can still answer the question honestly instead
	# of leaving it to hang.
	layer.tree_exiting.connect(func() -> void:
		if is_instance_valid(popup) and popup.is_open():
			EventBus.ui_modal_closed.emit("confirm")
			_open_for.erase(host)
			popup.answered.emit(false)
	)

	var go: bool = await popup.ask(text, yes, no, -1, false, Callable(watch, "armed"))

	_open_for.erase(host)
	if is_instance_valid(layer):
		layer.queue_free()
	return go and is_instance_valid(host) and host.is_inside_tree()


## Watches raw input while the popup is open and decides, per press, whether that press is allowed to
## arm a confirm/decline. See guarantee 2/3 above for the algorithm; nothing here is a one-way latch
## any more (round 2) - every press re-evaluates from scratch.
class _Guard extends Node:
	## Union of CrashIntro/PartCelebration's SKIP_ACTIONS and UIFocus's accept/cancel actions - the
	## action names a Director timeline's synthetic `tap` (no InputEvent) can move, so this class of
	## press/release still goes through the same gap check as a real one.
	const WATCH_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "cancel", "pause", "ui_cancel"]

	## The flag `armed()` returns - written ONLY at a press edge, from the two gaps described above.
	## Defaults false: the popup starts unarmed and stays that way until a press proves the stream has
	## actually gone quiet first.
	var _armed_now := false
	var _opened_ms := 0
	## Timestamp of the last press OR release of anything (key, pointer, pad button) this guard has
	## seen - what a fresh press's "has it been quiet" gap is measured against. Seeded to `_opened_ms`
	## so a press arriving before any other event is measured against "since open", which the
	## MIN_ARM_MS-since-open check already covers on its own.
	var _last_event_ms := 0
	## The process frame `_mark_press` last actually recomputed on - see `_mark_press` for why a
	## second press this same frame is not a second edge.
	var _last_press_frame := -1

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_opened_ms = Time.get_ticks_msec()
		_last_event_ms = _opened_ms
		set_process_input(true)
		set_process(true)

	## Catches a Director timeline's `tap`, which is `Input.action_press`/`action_release` and sends
	## no InputEvent - `_input` below would never see it.
	func _process(_delta: float) -> void:
		for a in WATCH_ACTIONS:
			if not InputMap.has_action(a):
				continue
			if Input.is_action_just_pressed(a):
				_mark_press()
			if Input.is_action_just_released(a):
				_mark_event()

	func _input(event: InputEvent) -> void:
		if event is InputEventKey:
			_edge((event as InputEventKey).pressed)
		elif event is InputEventMouseButton:
			_edge((event as InputEventMouseButton).pressed)
		elif event is InputEventScreenTouch:
			_edge((event as InputEventScreenTouch).pressed)
		elif event is InputEventJoypadButton:
			_edge((event as InputEventJoypadButton).pressed)

	func _edge(pressed: bool) -> void:
		if pressed:
			_mark_press()
		else:
			_mark_event()

	## A press edge (a genuine down, a Director `press`, or an OS-repeat echo - an echo is still a
	## fresh "pressed = true" edge and must reset the quiet-gap exactly like any other press, which is
	## what keeps a held key from ever arming) recomputes `_armed_now` from the two gaps, THEN updates
	## the "last event" clock to itself, so the very next press is measured against this one.
	##
	## ONE REAL EXCEPTION (2026-09-14, measured while re-proving round 2's fix - a genuine deliberate
	## tap was found to never confirm at all, not just a rapid train): Godot's default
	## `emulate_mouse_from_touch` fires a synthetic `InputEventMouseButton` for every
	## `InputEventScreenTouch`, dispatched synchronously in the same call and landing in the same
	## process frame - one physical tap therefore reaches `_input` as TWO press edges 0-1 ms apart,
	## and without this guard the second one always recomputed `since_last` against the first as ~0 ms
	## and stamped the whole tap unarmed, even after a long real quiet gap. `Engine.get_process_frames()`
	## is a hard structural fact (both edges land before the next frame is processed), not a fitted
	## delay, so a second press this same frame is treated as the SAME gesture and changes nothing.
	func _mark_press() -> void:
		var frame := Engine.get_process_frames()
		if frame == _last_press_frame:
			return
		_last_press_frame = frame
		var now := Time.get_ticks_msec()
		var since_open := now - _opened_ms
		var since_last := now - _last_event_ms
		_armed_now = since_open >= MIN_ARM_MS and since_last >= MIN_ARM_MS
		_last_event_ms = now

	## A release only advances the "last event" clock - it never arms anything itself, so the release
	## half of a tap can't arm what its own press didn't (a tap's press and release are ~40-150 ms
	## apart, far under MIN_ARM_MS, so the release never sees a chance to matter here either way).
	func _mark_event() -> void:
		_last_event_ms = Time.get_ticks_msec()

	## The guard `ConfirmPopup._answer()` calls: whatever the most recent press computed.
	func armed() -> bool:
		return _armed_now
