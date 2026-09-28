class_name SkyPlan
extends RefCounted
## SPIKE round 2 (2026-09-20, scratch only). THE FORECAST PANEL - the night's travel plan.
##
## It replaces round 1's panel, which had one job per row: a "Watch now" button, or a "Wait N h"
## button that ran the clock at 220x and let the player skip the very night the game is about. Both
## of those are gone. This panel answers three questions instead, and all three are about WHERE and
## WHEN, because that is now the game:
##
##   * is it up?              counted down in REAL minutes, not game hours (WorldClock)
##   * can I record it here?  only from the world the forecast names (SkyEvents.can_print_here)
##   * when is it best?       the peak, and how long until it
##
## THE WRONG-PLACE LINE, which is the whole travel rule in one sentence the player reads:
##     row button    "Only from Vela"              (14 chars)
##     in the tube   "Too far to record. Fly to Vela."  (31 chars)
## You can still LOOK from anywhere - the button says "Look" instead of "Watch" - you just come away
## with nothing, which is the honest reading of an airless sky: the sight is right there, the
## telescope is simply not under the patch of sky the plate is cut for.
##
## Nothing here moves the clock. Time passes by flying, walking, watching and talking.
##
## Owned by the PLAN builder. `fill_panel` is the only thing SkyWatch calls.

const C_TEXT := Color("#2c2f42")
const C_SOFT := Color("#6d7288")
const C_DIM := Color("#9aa0b4")
const C_GOOD := Color("#2f7a45")
const C_WARN := Color("#9a5a17")

## Tint of a row: up and recordable here / up but wrong world / not up yet.
const T_HERE := Color("#dcefdd")
const T_ELSEWHERE := Color("#f0e6d6")
const T_LATER := Color("#e3e5ee")


## Builds the whole forecast into `panel`. `watch` is the SkyWatch (for hour(), day() and
## start_watch()); `on_close` is called by the Close button.
static func fill_panel(watch: Node, panel: PanelContainer, on_close: Callable) -> void:
	for c in panel.get_children():
		c.queue_free()
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(840, 0)
	m.add_child(col)

	var day := int(watch.call("day"))
	var h := float(watch.call("hour"))
	var here := GameState.current_planet_id

	col.add_child(_head("Tonight's plan - day %d" % day))
	col.add_child(_small("%s on %s.  %s" % [
		SkyEvents.clock_text(h), _place(here), SkyEvents.plan_line(day, h, here)]))

	for ev in SkyEvents.forecast_for_day(day):
		col.add_child(_row(watch, ev, h, here))

	col.add_child(_small("Stars are up all day out here. Nothing skips the clock."))

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	foot.add_child(_button("Close", on_close, true))


static func _row(watch: Node, ev: Dictionary, h: float, here: String) -> Control:
	var up := SkyEvents.in_window(ev, h)
	var mine := SkyEvents.can_print_here(ev, here)
	var row := PanelContainer.new()
	var tint := T_LATER
	if up:
		tint = T_HERE if mine else T_ELSEWHERE
	row.add_theme_stylebox_override("panel", UIStyle.make_panel_style(tint, 18))

	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 10)
	row.add_child(mm)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	mm.add_child(hb)

	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.add_theme_constant_override("separation", 2)
	hb.add_child(txt)
	txt.add_child(_body(str(ev["title"])))
	var tag := "MORNING" if SkyEvents.is_morning(ev) else "NIGHT"
	txt.add_child(_small("%s  %s  peaks %s  ·  %s  ·  %s" % [
		tag, SkyEvents.window_text(ev), SkyEvents.clock_text(SkyEvents.peak_hour(ev)),
		str(ev["where"]), SkyEvents.rarity_name(int(ev["rarity"]))]))
	txt.add_child(_status(ev, h, here))

	hb.add_child(_action(watch, ev, up, mine, h))
	return row


## The line under the title: real minutes, and where you have to stand.
static func _status(ev: Dictionary, h: float, here: String) -> Label:
	var w := SkyEvents.world_name(ev)
	if SkyEvents.in_window(ev, h):
		var sets := WorldClock.short_time(SkyEvents.real_seconds_left(ev, h))
		var peak := SkyEvents.real_seconds_to_peak(ev, h)
		var best := "at its best now" if peak < 12.0 else "best in %s" % WorldClock.short_time(peak)
		if SkyEvents.can_print_here(ev, here):
			return _small_col("Up here - %s, gone in %s." % [best, sets], C_GOOD)
		return _small_col("%s  Sets in %s." % [SkyEvents.here_line(ev, here), sets], C_WARN)
	var rise := WorldClock.short_time(SkyEvents.real_seconds_until(ev, h))
	return _small_col("Rises over %s in %s. Be there." % [w, rise], C_SOFT)


static func _action(watch: Node, ev: Dictionary, up: bool, mine: bool, h: float) -> Button:
	if up and mine:
		return _button("Watch", func(): watch.call("start_watch", ev), true)
	if up:
		return _button("Look", func(): watch.call("start_watch", ev), true)
	return _button(WorldClock.short_time(SkyEvents.real_seconds_until(ev, h)), Callable(), false)


## The line the eyepiece shows when you are looking from the wrong world. The AIM builder draws it
## and refuses the print; this is the only place its wording lives.
static func eyepiece_note(ev: Dictionary, here: String) -> String:
	return SkyEvents.here_line(ev, here)


static func _place(id: String) -> String:
	return "the Commons" if id == "hub" else id.capitalize()


# ------------------------------------------------------------------------------ small widgets
static func _button(text: String, cb: Callable, enabled: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 56)
	b.add_theme_font_override("font", UIStyle.ui_font())
	b.add_theme_font_size_override("font_size", 22)
	if enabled and cb.is_valid():
		b.pressed.connect(cb)
	return b


static func _head(t: String) -> Label:
	return _label(t, 30, C_TEXT)


static func _body(t: String) -> Label:
	return _label(t, 24, C_TEXT)


static func _small(t: String) -> Label:
	return _label(t, 18, C_SOFT)


static func _small_col(t: String, col: Color) -> Label:
	return _label(t, 18, col)


static func _label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
