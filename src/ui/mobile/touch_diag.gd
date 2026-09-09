class_name TouchDiag
extends Control
## *** TEMPORARY INSTRUMENTATION. NOT A FEATURE. DELETE THIS FILE ONCE THE CAUSE IS KNOWN. ***
##
## WHY IT EXISTS. The player has reported the same fault five times:
##   "when I landed on the first planet, I couldnt move anymore, the move joystick just moved the
##    camera", "coming out of a spaceship on new planet still doesnt let me move", "I can move
##    again by hitting pause and resume", and finally
##   "I'm still having the problem when I start the game or land on a new planet I can't move until
##    I pause and resume."
## Four fixes have shipped against it. Every one of them was aimed at the LANDING path, and the
## last report says it also happens at game START — where there is no rocket, no landing cutscene
## and no arrival emote — so every landing-specific theory is dead and the cause is something the
## two situations share.
##
## THE REASON FOUR ROUNDS MISSED. Nothing in this project can generate a real iOS WebKit touch
## event. Every "finger" in every measurement so far has been `debug_touch` / `debug_drag` calling
## `TouchControls._pointer_down` / `_pointer_move` DIRECTLY, which never enters
## `TouchControls._input`. The entire touch EVENT path — the only path a real phone uses — has
## never been observed. So this round stops guessing and asks the phone: the player takes ONE
## screenshot while stuck and the bottom line names the fault.
##
## EVERY LINE DISTINGUISHES A DIFFERENT CANDIDATE CAUSE. That is the whole design rule:
##   line 1  mobile / visible / visible-in-tree / _process / _input          - is the node alive at all
##   line 2  EventBus modal total, NAMES and per-name COUNTS, plus `rst=`     - an unbalanced
##           open/close pins the counter above zero forever and hides the controls; `rst=` counts
##           the times `reset_modals()` cleared a live modal. That used to be SILENT, which left
##           every edge-driven listener (`Player.input_enabled`, `TouchControls.visible`) stale
##           with the gate clear — the cause of this whole bug, fixed in `EventBus.reset_modals`,
##           which now replays the lost `ui_modal_closed`. `rst>0` is therefore no longer a fault
##           by itself; `rst>0` NEXT TO `en=N` or `vis=N` with `modal=0` would mean the replay
##           did not reach a listener, and that is what the two verdict lines below still watch for
##   line 3  the `_pointers` table: id, claimed role, position, age          - a finger with no
##           entry is invisible to `_pointer_move` and `_pointer_up`
##   line 4  stick active / push, and the stick ZONE + viewport size         - a stale zone sends a
##           thumb on the drawn ring to the camera role instead ("the joystick moved the camera")
##   line 5  `Input.get_vector` over the four move actions                   - does the stick reach
##           the Input system at all
##   line 6  player input_enabled / physics / process, and get_tree().paused - the gameplay gates
##   line 7  the player's actual speed                                       - the symptom itself
##   line 8  EVENT COUNTERS from inside `_input`                             - the path no
##           measurement has ever seen: touches, drags, mouse, late adoptions, and events DROPPED
##           by the `if not visible` gate. Counted BEFORE that gate on purpose, so "no touch event
##           ever arrived" and "events arrive and are thrown away" are different readings.
##   line 9  the last pointer-down: where it landed, what role it got, whether it was claimed
##   line 10 VERDICT — the FIRST thing that is wrong, in words. The player should not have to
##           interpret the rest.
##
## HOW TO TURN IT OFF: set `ENABLED := false` below, or pass `--no-diag` after the `--` separator.
## It draws only when `MobileUI.is_mobile()`, so the desktop build is untouched either way.
##
## The two static functions are the formatter, and they are static so that a Director timeline can
## print the EXACT text the overlay draws (`TouchControls.debug_diag`) rather than a second,
## drifting copy of the same fields.

## Master switch. Flip to false (or pass `--no-diag`) to remove the readout from the game.
const ENABLED := true

# ----------------------------------------------------------------------------- geometry
## Type size and plate padding, in the 1560x720 logical viewport a landscape phone resolves to.
## 15 px reads at about the same size as the stardust counter's digits on a 2340x1080 panel; it was
## chosen by rendering the plate at that resolution and reading the PNG, which is the only test
## that matters for something the player has to photograph.
const FONT_SIZE := 15
const LINE_H := 17.0
const PAD := Vector2(9.0, 7.0)
## Down from the safe-area top. Clear of the stardust pill (y 20..56) AND of the touch HUD row —
## bag / journal / pause sit at y 80..172 (`MobileUI.HUD_BTN_HIT_R` 46 either side of 126) — so the
## plate covers no control the player might need while taking the screenshot.
const TOP := 178.0
## MONOSPACE WITH A PROPORTIONAL FONT, and why it is done this way. The project ships exactly one
## face, Baloo 2, and it is proportional; a `SystemFont` asking for Menlo/Courier resolves on this
## Mac and NOT in the browser (the web export has no OS font enumeration), which would mean the
## capture I can read and the screenshot the player takes are different renders — the exact trap
## that has already cost four rounds. So every character is drawn into a fixed cell and CENTRED in
## it, which is real column alignment with the font we actually ship.
##
## The cell is measured over DIGITS AND THE PUNCTUATION THAT SEPARATES COLUMNS, times PITCH_SLACK.
## Measured advances at font size 15: `0`=9, `=`=8, `m`=13, `M`=12, `@`=15. Pitching on the widest
## lowercase letter would make the plate 637 px wide for a 49-character line — 41% of the 1560 px
## logical viewport — and the first capture at that pitch looked spaced-out and hard to scan. `@`
## is excluded for the same reason (it alone pushed the cell to 18 px, which is what the second
## capture showed). At an 11 px cell the widest line is 469 px, 30% of the viewport. The only cost
## is that `m`, `w` and `@` overhang their cell by 1-3 px either side; digits, which are the
## columns that actually have to line up, are exact.
const PITCH_CHARS := "0123456789=.,:-()[]/"
const PITCH_SLACK := 1.15

## A pointer held this long with the controls up is almost certainly a ghost from before a scene
## swap rather than a thumb the player is still using.
const GHOST_AGE := 30.0

var _tc: Node
var _lines: PackedStringArray = PackedStringArray()
var _verdict := ""
var _pitch := 0.0
var _plate := Rect2()


## True when the readout should be built at all. Checked by `hud.gd` before it instantiates one.
static func wanted() -> bool:
	return ENABLED and not OS.get_cmdline_user_args().has("--no-diag")


func _ready() -> void:
	name = "TouchDiag"
	# ALWAYS: the pause menu is the player's own workaround for this bug, so the readout has to
	# stay live while the tree is paused — that is one of the states worth photographing.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Sibling of TouchControls under the HUD CanvasLayer, never a CHILD of it. If the fault turns
	# out to be "a modal is stuck open so the controls are hidden", a child would be hidden too and
	# the screenshot would show nothing at all.
	_tc = get_parent().get_node_or_null("TouchControls") if get_parent() != null else null


func _process(_delta: float) -> void:
	var show := MobileUI.is_mobile()
	if visible != show:
		visible = show
	if not show:
		return
	var s: Dictionary = _tc.call("diag_state") if _tc != null and _tc.has_method("diag_state") else {}
	_lines = lines(s)
	_verdict = verdict(s)
	queue_redraw()


# ----------------------------------------------------------------------------- formatting
## The body of the readout, one string per line. Static so `TouchControls.debug_diag` prints the
## same text a screenshot shows — see the header.
static func lines(s: Dictionary) -> PackedStringArray:
	if s.is_empty():
		return PackedStringArray(["no TouchControls found"])
	var out := PackedStringArray()
	out.append("mobile=%s vis=%s tree=%s proc=%s in=%s" % [
		_yn(s.get("mobile")), _yn(s.get("visible")), _yn(s.get("in_tree")),
		_yn(s.get("proc")), _yn(s.get("proc_in"))])
	out.append("modal=%d %s%s" % [int(s.get("modal_total", 0)), _modals(s), _resets(s)])
	out.append("ptr=%d %s" % [(s.get("pointers", []) as Array).size(), _ptrs(s)])
	var z: Rect2 = s.get("stick_zone", Rect2())
	var vp: Vector2 = s.get("size", Vector2.ZERO)
	out.append("stick act=%s push=%.2f zone %.0f,%.0f %.0fx%.0f" % [
		_yn(s.get("stick_active")), float(s.get("stick_push", 0.0)),
		z.position.x, z.position.y, z.size.x, z.size.y])
	var mv: Vector2 = s.get("move_vec", Vector2.ZERO)
	out.append("vec=%.2f (%+.2f,%+.2f) run=%s vp %.0fx%.0f" % [
		mv.length(), mv.x, mv.y, _yn(s.get("run")), vp.x, vp.y])
	out.append("player en=%s phys=%s proc=%s paused=%s" % [
		_yn(s.get("input_enabled")), _yn(s.get("phys")), _yn(s.get("pproc")),
		_yn(s.get("paused"))])
	out.append("speed=%.2f m/s" % float(s.get("speed", 0.0)))
	out.append("ev touch=%d drag=%d mouse=%d drop=%d adopt=%d" % [
		int(s.get("n_touch", 0)), int(s.get("n_drag", 0)), int(s.get("n_mouse", 0)),
		int(s.get("n_dropped", 0)), int(s.get("n_adopt", 0))])
	out.append("last down %s @%.0f,%.0f took=%s %s" % [
		str(s.get("last_down_role", "-")),
		(s.get("last_down_pos", Vector2.ZERO) as Vector2).x,
		(s.get("last_down_pos", Vector2.ZERO) as Vector2).y,
		_yn(s.get("last_down_ok")), _age(s.get("last_down_age", -1.0))])
	return out


## The FIRST thing that is wrong, in words. Order is deliberate: a cause that makes the ones below
## it unreadable has to be named first, or the player is handed a symptom instead of a cause.
static func verdict(s: Dictionary) -> String:
	if s.is_empty():
		return "STUCK: no TouchControls node"
	if not bool(s.get("mobile", false)):
		return "MODE: desktop UI, no touch controls"
	# The modal COUNTER, not the name table, is what gates the controls. They can drift apart if a
	# close is ever emitted for a name that was never opened, and then the names look innocent.
	var total := int(s.get("modal_total", 0))
	var summed := int(s.get("modal_names_sum", 0))
	if total != summed:
		return "STUCK: modal count %d but names sum %d" % [total, summed]
	if total > 0:
		var counts: Dictionary = s.get("modal_counts", {})
		var first := str(counts.keys()[0]) if not counts.is_empty() else "?"
		return "STUCK: modal '%s' x%d still open" % [first, int(counts.get(first, total))]
	if bool(s.get("paused", false)):
		return "STUCK: tree paused"
	# THE DIVERGENCE THIS ROUND WAS ASKED TO MAKE IMPOSSIBLE (see TouchControls._sync_state). Kept
	# as a verdict anyway: if it ever prints again, a second writer of `visible` has appeared.
	if not bool(s.get("proc_in", false)):
		return "STUCK: input processing off while mobile"
	if not bool(s.get("proc", false)):
		return "STUCK: _process off while mobile"
	# `visible` first, then `in_tree`: `is_visible_in_tree()` is false in BOTH cases, so testing it
	# first would report "an ancestor hid us" for a node that simply hid itself. (It did, in the
	# first fault-injection run.)
	if not bool(s.get("visible", false)):
		return "STUCK: controls hidden, no modal open"
	if not bool(s.get("in_tree", false)):
		return "STUCK: hidden by an ancestor node"
	var z: Rect2 = s.get("stick_zone", Rect2())
	if z.size.x <= 1.0 or z.size.y <= 1.0:
		return "STUCK: stick zone empty (%.0fx%.0f)" % [z.size.x, z.size.y]
	var ptrs: Array = s.get("pointers", [])
	if bool(s.get("stick_active", false)) and not _has_role(ptrs, "stick"):
		return "STUCK: stick active with no owning pointer"
	for p in ptrs:
		var d: Dictionary = p
		if str(d.get("role", "")) == "cam" and z.has_point(d.get("pos", Vector2.ZERO) as Vector2):
			return "STUCK: ptr %d role cam INSIDE stick zone" % int(d.get("id", -1))
	for p2 in ptrs:
		var d2: Dictionary = p2
		if float(d2.get("age", 0.0)) > GHOST_AGE:
			return "STUCK: ghost pointer %d:%s held %.0fs" % [
				int(d2.get("id", -1)), str(d2.get("role", "?")), float(d2.get("age", 0.0))]
	if not bool(s.get("player_found", false)):
		return "STUCK: no node in the 'player' group"
	if not bool(s.get("input_enabled", false)):
		# Naming the reset when there has been one. `reset_modals()` used to zero the gate without
		# emitting `ui_modal_closed`, and `Player.input_enabled` only ever changes on that signal,
		# so a silent reset stranded it false with `modal=0` — opening and closing the pause menu
		# being precisely the open/close pair that put it back, which is why that was the player's
		# workaround. The reset now replays those closes (`EventBus.reset_modals`), so this line
		# means the replay did not land: a NEW writer of `input_enabled` has appeared, or a listener
		# was disconnected. Kept for exactly that reason.
		if int(s.get("reset_count", 0)) > 0:
			return "STUCK: player input_enabled false after modal reset"
		return "STUCK: player input_enabled is false"
	if not bool(s.get("phys", false)):
		return "STUCK: player physics off (still frozen)"
	var push := float(s.get("stick_push", 0.0))
	var mlen := (s.get("move_vec", Vector2.ZERO) as Vector2).length()
	if push > 0.05 and mlen < 0.02:
		return "STUCK: stick push %.2f not reaching Input" % push
	if mlen > 0.20 and float(s.get("speed", 0.0)) < 0.15:
		return "STUCK: move %.2f pressed but speed %.2f" % [mlen, float(s.get("speed", 0.0))]
	# LAST, and it is a note rather than a fault: on the phone this firing after the player has
	# dragged means the touch path never reaches `_input` at all, which would be the answer. It is
	# suppressed once ANY pointer-down has been claimed, because the Director hooks call
	# `_pointer_down` directly and would otherwise pin this line over a perfectly healthy run.
	if int(s.get("n_touch", 0)) == 0 and int(s.get("n_drag", 0)) == 0 \
			and float(s.get("last_down_age", -1.0)) < 0.0:
		return "no pointer input yet - drag, then look"
	return "OK"


static func _yn(v: Variant) -> String:
	return "Y" if bool(v) else "N"


static func _age(v: Variant) -> String:
	var f := float(v)
	return "never" if f < 0.0 else "%.1fs" % f


static func _has_role(ptrs: Array, role: String) -> bool:
	for p in ptrs:
		if str((p as Dictionary).get("role", "")) == role:
			return true
	return false


## Clears of the modal gate that had something to clear. See `EventBus.reset_modals`: a reset used
## to zero the counter without emitting `ui_modal_closed`, leaving `Player.input_enabled` and
## `TouchControls.visible` — both edge-driven from that signal — stale with the gate reading clear.
## `rst>0` beside `player en=N` on the player's screenshot WAS the answer, and that is the bug the
## reset's close replay now closes. It stays on the readout because it is still the counter that
## says a real close was lost: with the narrowed `_on_node_added`, a normal home -> zorp landing
## measures `rst=0` for the whole journey, so anything above zero in ordinary play names a new
## source of lost closes worth chasing.
static func _resets(s: Dictionary) -> String:
	var n := int(s.get("reset_count", 0))
	if n <= 0:
		return ""
	return " rst=%d(%s)%s" % [n, str(s.get("reset_names", "")), _age(s.get("reset_age", -1.0))]


static func _modals(s: Dictionary) -> String:
	var counts: Dictionary = s.get("modal_counts", {})
	if counts.is_empty():
		return "[]"
	var parts: Array[String] = []
	for k in counts:
		parts.append("%s x%d" % [str(k), int(counts[k])])
	return "[" + ", ".join(parts) + "]"


static func _ptrs(s: Dictionary) -> String:
	var ptrs: Array = s.get("pointers", [])
	if ptrs.is_empty():
		return "[]"
	var parts: Array[String] = []
	for p in ptrs:
		var d: Dictionary = p
		var pos: Vector2 = d.get("pos", Vector2.ZERO)
		parts.append("%d:%s@%.0f,%.0f %.0fs" % [int(d.get("id", -1)), str(d.get("role", "?")),
			pos.x, pos.y, float(d.get("age", 0.0))])
	return "[" + ", ".join(parts) + "]"


# ----------------------------------------------------------------------------- draw
func _draw() -> void:
	var f := UIStyle.font()
	if f == null:
		return
	if _pitch <= 0.0:
		for i in PITCH_CHARS.length():
			_pitch = maxf(_pitch, f.get_string_size(PITCH_CHARS[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
		_pitch = ceilf(_pitch * PITCH_SLACK)
	var rows := PackedStringArray(_lines)
	rows.append("VERDICT: " + _verdict)
	var cols := 0
	for r in rows:
		cols = maxi(cols, r.length())
	var sa := MobileUI.safe_area()
	var org := Vector2(sa.x + MobileUI.EDGE, sa.y + TOP)
	_plate = Rect2(org, Vector2(float(cols) * _pitch + PAD.x * 2.0,
		float(rows.size()) * LINE_H + PAD.y * 2.0))
	# Dark plate, deliberately near-opaque: R2.10's transparency rule is about CONTROLS you look
	# past, and this is text the player has to photograph and read back to us.
	draw_rect(_plate, Color(0.03, 0.04, 0.09, 0.82))
	draw_rect(_plate, Color(UIStyle.YELLOW, 0.55), false, 1.5)
	# Three states, not two: GREEN "OK", RED for a real fault, and YELLOW for a NOTICE that is not
	# a fault ("no pointer input yet", "desktop UI"). A red line that only means "you have not
	# touched the screen yet" would train the player to ignore the one line that matters.
	var fault := _verdict.begins_with("STUCK")
	var ok := _verdict == "OK"
	for i in rows.size():
		var last := i == rows.size() - 1
		var col: Color = UIStyle.CREAM
		if last:
			col = UIStyle.RED if fault else (UIStyle.GREEN if ok else UIStyle.YELLOW)
		# Baseline: LINE_H per row, and FONT_SIZE * 0.78 puts the first row's baseline just inside
		# the padding rather than on it.
		var base := org + PAD + Vector2(0.0, float(i) * LINE_H + float(FONT_SIZE) * 0.78)
		_draw_mono(f, base, rows[i], col)
		if last and fault:
			# One-pixel double strike: the verdict is the only line that has to survive a photo of
			# a phone screen, and the shipped font has no bold face.
			_draw_mono(f, base + Vector2(0.7, 0.0), rows[i], col)


# ----------------------------------------------------------------------------- invariant matrix
## PROVES THE PART-2 FIX, and it lives here so it is deleted with the rest of the scaffolding.
##
## The bug being closed is that `visible` and `is_processing_input()` could disagree: `_apply_mode`
## was the only writer of the processing flags and `_on_modal_changed` was a second, independent
## writer of `visible`. Anything that reaches one path without the other could leave a joystick
## drawn on screen that no touch can reach. A single before/after measurement cannot show that a
## divergence is IMPOSSIBLE, only that it did not happen once — so this drives the mode path and
## the modal path against each other in every order it can construct (all sequences of length
## `MATRIX_LEN` over the seven operations below, 2401 of them at length 4) and checks all three
## invariants after EVERY step:
##     is_processing_input() == MobileUI.is_mobile()      (and the same for is_processing())
##     visible               == mobile and not modal_open
##     Player.input_enabled  == not modal_open
##
## `modal_reset` AND THE THIRD INVARIANT WERE ADDED FOR THIS ROUND'S FIX. `EventBus.reset_modals()`
## clears the gate and replays a `ui_modal_closed` per cleared modal so the edge-driven listeners
## recompute; before that, a reset left `visible` false and `input_enabled` false with the gate
## already clear, and only an open/close pair put them back (the player's pause-and-resume). A
## single before/after run shows that one ordering is fixed. This shows there is no ordering of
## reset / open / close / mode-change in which a listener is left disagreeing with the gate — which
## includes the two cases the fix had to get right by hand: a reset with NOTHING open must be a
## no-op, and two resets in a row must not double-anything. Both appear in these sequences.
##
## The player invariant is only checked while the astronaut is UNFROZEN (`is_physics_processing()`),
## because `RocketPad._freeze_player` and the dialogue runner write `input_enabled` too and neither
## is modal-driven; on the home planet with no cutscene running, nothing else touches it.
## Restores the mode, the modal counter and the control state before it returns.
const MATRIX_OPS: PackedStringArray = ["mobile_on", "mobile_off", "modal_open", "modal_close",
	"apply_mode", "modal_changed", "modal_reset"]
const MATRIX_LEN := 4


func debug_mode_matrix() -> void:
	if _tc == null:
		print("MATRIX: no TouchControls")
		return
	var plat := get_tree().root.get_node_or_null("Platform")
	var was_mobile: bool = plat != null and bool(plat.call("is_mobile"))
	var n := MATRIX_OPS.size()
	var total := int(pow(n, MATRIX_LEN))
	var steps := 0
	var bad_proc := 0
	var bad_vis := 0
	var bad_player := 0
	var first_fail := ""
	for seq in total:
		# Let the frame end every so often. `Platform.set_mobile` emits `mode_changed`, and the HUD's
		# handler `queue_free`s and rebuilds the hint row — queue_free only takes effect at the end
		# of a frame, so running all 1296 sequences inside ONE frame piled up thousands of pending
		# nodes and the run never finished (it was still going after five minutes). Yielding every
		# 32 sequences drains them: 41 frames, well under a second.
		if seq % 32 == 0:
			await get_tree().process_frame
		# Reset to a known state: mobile, no modals.
		while EventBus.is_modal_open():
			EventBus.ui_modal_closed.emit("matrix")
		if plat != null:
			plat.call("set_mobile", true, false)
		_tc.call("_apply_mode")
		var trail: Array[String] = []
		var v := seq
		for _i in MATRIX_LEN:
			var op := MATRIX_OPS[v % n]
			v /= n
			trail.append(op)
			_matrix_apply(op, plat)
			steps += 1
			var mobile: bool = plat != null and bool(plat.call("is_mobile"))
			var want_vis: bool = mobile and not EventBus.is_modal_open()
			var ok_proc: bool = bool(_tc.call("is_processing_input")) == mobile \
				and bool(_tc.call("is_processing")) == mobile
			var ok_vis: bool = bool(_tc.get("visible")) == want_vis
			var pl := get_tree().get_first_node_in_group("player")
			var ok_player := true
			if pl != null and pl.is_physics_processing():
				ok_player = bool(pl.get("input_enabled")) == (not EventBus.is_modal_open())
			if not ok_proc:
				bad_proc += 1
			if not ok_vis:
				bad_vis += 1
			if not ok_player:
				bad_player += 1
			if (not ok_proc or not ok_vis or not ok_player) and first_fail == "":
				first_fail = "%s -> mobile=%s modal=%s vis=%s proc_in=%s en=%s" % [
					" ".join(trail), str(mobile), str(EventBus.is_modal_open()),
					str(_tc.get("visible")), str(_tc.call("is_processing_input")),
					"-" if pl == null else str(pl.get("input_enabled"))]
	while EventBus.is_modal_open():
		EventBus.ui_modal_closed.emit("matrix")
	if plat != null:
		plat.call("set_mobile", was_mobile, false)
	_tc.call("_apply_mode")
	print("MATRIX sequences=%d steps=%d proc_divergences=%d vis_divergences=%d player_divergences=%d %s" % [
		total, steps, bad_proc, bad_vis, bad_player,
		"PASS" if bad_proc == 0 and bad_vis == 0 and bad_player == 0 else "FAIL first: " + first_fail])


func _matrix_apply(op: String, plat: Node) -> void:
	match op:
		"mobile_on":
			if plat != null:
				plat.call("set_mobile", true, false)
		"mobile_off":
			if plat != null:
				plat.call("set_mobile", false, false)
		"modal_open":
			EventBus.ui_modal_opened.emit("matrix")
		"modal_close":
			EventBus.ui_modal_closed.emit("matrix")
		"apply_mode":
			_tc.call("_apply_mode")
		"modal_changed":
			_tc.call("_on_modal_changed")
		"modal_reset":
			# The real thing, not a stand-in: this is the function under test.
			EventBus.reset_modals()


# ----------------------------------------------------------------------------- draw helper
## One row, each character centred in a fixed cell so the columns line up with a proportional
## font. See PITCH_CHARS for why we are not simply using a monospace face.
func _draw_mono(f: Font, base: Vector2, text: String, col: Color) -> void:
	for i in text.length():
		var ch := text[i]
		if ch == " ":
			continue
		var w := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		draw_char(f, base + Vector2(float(i) * _pitch + (_pitch - w) * 0.5, 0.0), ch,
			FONT_SIZE, col)
