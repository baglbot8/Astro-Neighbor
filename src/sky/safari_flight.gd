extends Node3D
## MODE round (2026-09-21, scratch only), rewritten by the DAY round the same day. The "Photo
## time!" leg: everything between the pad deciding to fly a safari and the player standing on the
## destination.
##
## Deliberately its own scene, not folded into the normal climb/cruise/descent
## (src/rocket/rocket_pad.gd -> src/rocket/space_travel.gd -> rocket_pad.gd again). The user asked
## to KEEP that whole sequence, byte for byte, for "Just travelling" — so "Photo time!" gets its own
## door instead of a branch threaded through it. `SafariRun` already plays its own 6 s "leaving the
## pad" beat (PAD_SEC) before the lane opens, so that is this leg's departure; there is no second
## boarding animation stacked in front of it.
##
## ================================================================== WHAT THE DAY ROUND CHANGED
## The reviewer's verdict was that the DAY does not hold the safari: "a player gets one minute of
## this per twenty-five". Two separate things made that true, and this file owned both ends.
##
## 1. FILM WAS A DAY BOX, SO A DAY HELD ONE FLIGHT. The WIRE round loaded a trip with whatever was
##    left in `GameState.film_left_today()`, and four plates was a DAY's ration, so the first
##    flight of the day emptied it and the pad greyed "Photo time!" out until tomorrow. The lead's
##    ruling, from the user ("You should have limited film for each trip"), is that FILM IS PER
##    TRIP: every photo flight loads a full magazine, spent plates do not carry over, and the
##    upgrade and the shop raise what a TRIP carries, never a daily allowance. So this file now
##    reads `GameState.film_capacity()` fresh on every flight, adds any spares bought on the
##    loadout card below, and books NOTHING back - `GameState.spend_film` is a no-op now.
##
## 2. SO SOMETHING ELSE HAS TO LIMIT THE DAY, AND IT IS THE CLOCK. The user: "Playing the game
##    should take up real time in the day as you fly through, so you cant infinitely play the
##    safari." MEASURED BEFORE CHANGING ANYTHING (`showcase/rocket_pad.tscn --photo=zorp --auto`):
##    the whole leg billed the day 63.5 real seconds, which is 1.50 game hours of daylight - 5.3%
##    of a 20 real-minute day, so the CLOCK would have held about fourteen flights a day. It was
##    `SafariTransit.PHOTO_TRIP_HOURS` (4.9 h) until the R4 rebuild tripled the lanes (52-78 s ->
##    156-234 s, SAFARI_FLIGHT_SPEC.md) and the flat charge could no longer clear the longest lane
##    in daylight - it is now 6.0 h (spec #6.3). The arithmetic and its consequences live in
##    safari_transit.gd, next to the constant.
##
## HOW THE CHARGE IS MADE. Two halves, and G4b (2026-09-23, SAFARI_FLIGHT_SPEC.md 12.2) rewrote how
## they add up, because the original split let the flight's real duration leak into the bill:
##   * A SMOOTH BURN, here, spread across the predicted length of the leg so the player watches it
##     happen on the cabin clock (`_build_clock_pill`) instead of landing to an unexplained jump.
##     `_begin_clock_burn` sizes it from the NOMINAL leg length (pad + `SafariLanes.seconds_for()` +
##     an assumed haul-card read); `_process` ticks it at a constant rate; `_on_landed` trues up
##     whatever the burn had not finished. This half is cosmetic pacing, not the bill - see below.
##   * THE REST, billed by `src/world/environment.gd::_charge_absence` when the arrival World's
##     Environment boots, EXACTLY as every other hop is billed ("Just travelling", a Commons errand)
##     - except this file tells it, through `Environment.override_next_absence_hours()`, precisely
##     how many hours are still owed, instead of letting it measure the real seconds this hop took.
##     THIS IS THE FIX. The old code let `_charge_absence` measure those real seconds itself, so a
##     flight that took fewer real seconds (a boost) or more (a tutorial pause, a slow haul-card
##     read) billed a different total - the smooth burn was sized for ONE assumed duration and the
##     real-time charge paid for whatever duration actually happened, and only by coincidence did
##     the two ever match. Now the "rest" is an INVERSION of the burn (`_flight_remaining_hours()`:
##     `SafariTransit.trip_hours() - _extra_hours_done`), not a second measurement, so the two halves
##     sum to `trip_hours()` by construction - the flight's own real seconds are never read at all.
##     `_charge_absence` still measures real seconds for every hop that is NOT a photo flight's own
##     landing (nothing else in the game calls the override), so "Just travelling" and a Commons
##     errand are unaffected - ledgered before and after in this round's report.
##   * THE `--trips=N` PROBE (below) never boots a World scene, so `_charge_absence` never runs for
##     it either; it now bills its own "leg" part with the SAME inversion (`_flight_remaining_hours()`)
##     instead of the wall seconds SafariRun measured, so the probe's own ledger proves the fix
##     rather than needing boost turned on to see it. Its "ground" part (the seconds it waits between
##     legs, standing in for time spent in the arrival world) is untouched and still bills real
##     seconds - that time is not the flight's, and must go on moving with real duration exactly as
##     it always has.
##
## STATE IN, STATE OUT:
##   in  - SafariTransit (src/sky/safari_transit.gd): which route, which hour. Written by
##         rocket_pad.gd's mode picker just before `SceneRouter.go_to(FLIGHT_SCENE)`.
##   out - nothing about film is written back (there is no film store left to write to), and the
##         clock is advanced as described above. Then `SceneRouter.go_to_planet(dest)` - the same
##         "legacy short arrival" a Director `go_to_planet` call or the space map's Esc already
##         use, not a new landing of its own.
##
## SAY WHAT IS SYNTHETIC: nothing here has been driven by a real finger. `SafariRun`'s own header
## says the same about its `--auto` mode; this file has been exercised by headless `--auto` runs
## through this wrapper and by `--capture-dir` phone frames of the loadout card and the cabin
## clock (this round's report has the numbers and the frames).

const SAFARI_RUN_SCRIPT := preload("res://src/sky/safari_run.gd")
## `environment.gd` has no `class_name` (it would collide with the engine's own `Environment`), so
## it is reached the same way `SAFARI_RUN_SCRIPT` above is: a preloaded script reference, which
## GDScript lets call a `static func` on directly - `ENVIRONMENT_SCRIPT.override_next_absence_hours(...)`
## below. Confirmed against a throwaway two-script scene before relying on it (this round's report).
const ENVIRONMENT_SCRIPT := preload("res://src/world/environment.gd")

## Real seconds of haul-card reading assumed when sizing the surcharge. It is NOT itself a charge -
## since G4b (13.3: "the loadout card is part of the trip"), `_charge_absence` no longer bills the
## haul card's own real time on top of anything; the whole trip, loadout card to haul card, bills
## exactly `PHOTO_TRIP_HOURS` and nothing else. This constant is only used to decide how fast the
## extra hours tick. Wrong in either direction it costs nothing: the true-up in `_on_landed` lands
## the total on `PHOTO_TRIP_HOURS` regardless.
const HAUL_READ_SEC := 10.0

## ------------------------------------------------------------------ SYNTHETIC TEST HOOKS ONLY
## None of these is reachable from the game: they are OS user args, the same way `safari_run.gd`
## takes `--film=` and `--heard=`, so a headless probe can fly the REAL leg - the real film store,
## the real clock arithmetic, the real run - several times in one process and print a day's ledger.
## A real flight never sets any of them.
##   --hour=H        start the day clock at H (a real flight inherits whatever the day is at)
##   --trip=a_b      fly this pair instead of whatever SafariTransit carries
##   --trips=N       fly N legs back to back, turning round at each end, INSTEAD of landing in a world
##   --ground=S      real seconds to bill between those legs for the landing and the two pad cards
##   --extra-wait=S  after landing, before the scene change, really wait S seconds (real OS time,
##                   `ignore_time_scale` so it cannot be shrunk by the engine's own `--time-scale`
##                   flag) before handing off to the destination world - standing in for a slow
##                   haul-card read or a tutorial pause, real seconds no lane-speed knob touches at
##                   all. Godot's own `--time-scale <X>` (before the `--`, no flag needed here) does
##                   the other half of 12.2's proof - it makes the SAME lane land in fewer or more
##                   REAL seconds without changing anything this file or `safari_run.gd` compute in
##                   simulated seconds, which is exactly the boost/pause distinction the spec asks
##                   for, without touching `BOOST_LIVE` (confirmed: a 168 s lane landed in 7.7 real
##                   seconds at `--time-scale 25`, this round's report).
## In `--trips` mode nothing ever builds a World scene, so `environment.gd::_charge_absence` never
## runs and this file bills the leg's own real seconds itself - with the SAME inversion
## `_flight_remaining_hours()` uses for the override, so the ledger is the arithmetic the game does,
## not a copy of it (see the file header).
var _probe_trips := 0
var _probe_ground := 12.0
var _probe_flown := 0
var _probe_extra_wait := 0.0

var _run: SafariRun
var _origin_id := ""
var _dest_id := ""
var _plates_loaded := 0
var _spares_bought := 0
var _returning := false

# ------------------------------------------------------------------ the clock surcharge
var _extra_hours_total := 0.0
var _extra_hours_done := 0.0
var _extra_rate := 0.0
var _burning := false
var _depart_hour := 0.0
var _depart_day := 1

# ------------------------------------------------------------------ this scene's own UI
var _card: CanvasLayer
var _card_spare_row: HBoxContainer
var _card_spare_lbl: Label
var _card_plates_lbl: Label
var _card_up_row: HBoxContainer
var _card_up_lbl: Label
var _card_up_btn: Button
var _card_minus: Button
var _card_plus: Button
var _pill_layer: CanvasLayer
var _pill_root: Control
var _pill: PanelContainer
var _pill_clock: Label


func _ready() -> void:
	name = "SafariFlight"
	# WIRE round: the trip is TWO WORLD IDS, both directions distinct, all 21 pairs live
	# (SafariLanes). The old `route_id` lookup could only name one flyable route.
	var origin := SafariTransit.origin_id
	_dest_id = SafariTransit.dest_id
	if origin == "" or _dest_id == "" or SafariTransit.route_id_for(origin, _dest_id) == "":
		# Defensive only: the pad never offers "Photo time!" where `photo_possible` says no, so
		# this means the scene was entered some other way (a Director timeline, a direct `--path`
		# run). Fall back to the short hop off the doorstep rather than crash on an empty cast.
		push_warning("SafariFlight: no usable SafariTransit trip - defaulting to home -> zorp.")
		origin = "home"
		_dest_id = "zorp"
	_origin_id = origin
	_parse_probe_args()
	if _auto_flag():
		# `--auto` is the autopilot the run itself reads, and a headless probe must not stall on a
		# card that waits for a press, so `--auto` skips the card and flies with the default load.
		# A capture of the card is therefore a run WITHOUT `--auto` (this round's frames are).
		_start_flight()
	else:
		_build_loadout_card()


static func _auto_flag() -> bool:
	for a in OS.get_cmdline_user_args():
		if a == "--auto":
			return true
	return false


func _parse_probe_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hour="):
			GameState.time_of_day = fposmod(float(a.substr(7)), 24.0)
			SafariTransit.hour = GameState.time_of_day
		elif a.begins_with("--trip="):
			var bits := a.substr(7).split("_", false)
			if bits.size() == 2:
				_origin_id = bits[0]
				_dest_id = bits[1]
		elif a.begins_with("--trips="):
			_probe_trips = maxi(1, int(a.substr(8)))
		elif a.begins_with("--ground="):
			_probe_ground = maxf(0.0, float(a.substr(9)))
		elif a.begins_with("--extra-wait="):
			_probe_extra_wait = maxf(0.0, float(a.substr(13)))


# ==================================================================== THE LOADOUT CARD (the shop)
## WHAT A PLAYER SEES BEFORE A SAFARI, and why this screen exists at all.
##
## Film is per trip now, so "how many plates am I carrying" is a decision that belongs to THIS
## flight and to no other moment. There was nowhere to make it: the only film shop in the game was
## the haul card's upgrade offer, which only appears AFTER you have run out, and the pad's mode
## card is another builder's file. So the flight opens with its own kit card - the lane, the
## plates, the two ways to carry more, and what the trip will cost the day.
##
## IT COSTS ONE TAP, and I am saying so rather than hiding it: a photo flight is now pad card ->
## mode card -> this. An errand is still one tap (SafariTransit.photo_possible is false for the
## Commons, so the pad never opens any card). If the lead would rather fold this into the mode
## card, everything it needs is a static call away - `SafariTransit.trip_cost_line()`,
## `GameState.film_capacity()`, `SafariScoring.film_buy_cost()` - and this file drops back to
## flying straight away.
func _build_loadout_card() -> void:
	var mobile := MobileUI.is_mobile()
	_card = CanvasLayer.new()
	_card.name = "Loadout"
	_card.layer = 45
	add_child(_card)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIStyle.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(root)

	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(0.03, 0.035, 0.08, 1.0)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(centre)

	var panel := PanelContainer.new()
	panel.name = "Card"
	panel.add_theme_stylebox_override("panel",
		UIStyle.make_panel_style(UIStyle.CREAM, UIStyle.RADIUS, UIStyle.CREAM_EDGE, 3, 18, 22.0))
	centre.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(UIStyle.make_label("Load the camera", "Header", HORIZONTAL_ALIGNMENT_CENTER))
	var lane: Dictionary = SafariLanes.lane_for(_origin_id, _dest_id)
	box.add_child(UIStyle.make_label("%s — %s to %s" % [
		str(lane.get("name", "the lane")),
		Journal.planet_name(_origin_id), Journal.planet_name(_dest_id)],
		"Small", HORIZONTAL_ALIGNMENT_CENTER))

	box.add_child(HSeparator.new())

	_card_plates_lbl = UIStyle.make_label("", "", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_card_plates_lbl)

	# THE SHOP, HALF ONE: spare plates, stardust, THIS TRIP ONLY. SafariScoring owns the price
	# (FILM_BUY_PRICE 23 a plate, FILM_BUY_MAX 4 - was 3/69 dust before the spec 6.3 film-cast
	# rebuild raised FILM_BASE to 10; fixed 2026-09-23, G4b) and I have not touched it: 23 sits above
	# every bad catch (22) and below every average one (24), so a spare pays for itself only if you
	# expect the catch to be worth having. Four of them is 92 dust against a steady trip of 74-97
	# and a great one of 151-162 (safari_scoring.gd's own measured bands) - most of an ordinary
	# trip's takings for 40% more film, which is the bet it is meant to be.
	var spare_row := HBoxContainer.new()
	spare_row.alignment = BoxContainer.ALIGNMENT_CENTER
	spare_row.add_theme_constant_override("separation", 10)
	box.add_child(spare_row)
	_card_spare_row = spare_row
	_card_minus = UIStyle.make_button("-", "Pill")
	_card_minus.pressed.connect(func() -> void: _set_spares(_spares_bought - 1))
	spare_row.add_child(_card_minus)
	_card_spare_lbl = UIStyle.make_label("", "", HORIZONTAL_ALIGNMENT_CENTER)
	_card_spare_lbl.custom_minimum_size = Vector2(340.0, 0.0)
	spare_row.add_child(_card_spare_lbl)
	_card_plus = UIStyle.make_button("+", "Pill")
	_card_plus.pressed.connect(func() -> void: _set_spares(_spares_bought + 1))
	spare_row.add_child(_card_plus)
	if mobile:
		for b: Button in [_card_minus, _card_plus]:
			b.custom_minimum_size = Vector2(MobileUI.MIN_TOUCH, MobileUI.MIN_TOUCH)

	# THE SHOP, HALF TWO: the permanent camera upgrade. SCRAP, SafariScoring's price (400 then
	# 850), +1 plate on EVERY trip for ever - the difference between the two halves is the point:
	# dust buys this flight, scrap buys all of them.
	_card_up_row = HBoxContainer.new()
	_card_up_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_up_row.add_theme_constant_override("separation", 10)
	box.add_child(_card_up_row)
	_card_up_lbl = UIStyle.make_label("", "Small", HORIZONTAL_ALIGNMENT_CENTER)
	_card_up_row.add_child(_card_up_lbl)
	_card_up_btn = UIStyle.make_button("Buy", "Pill")
	_card_up_btn.pressed.connect(func() -> void:
		if GameState.buy_film_upgrade():
			UIStyle.play_confirm()
			_refresh_card())
	_card_up_row.add_child(_card_up_btn)
	if mobile:
		_card_up_btn.custom_minimum_size = Vector2(MobileUI.MIN_TOUCH * 1.6, MobileUI.MIN_TOUCH)

	box.add_child(HSeparator.new())

	# THE CLOCK COST, SAID OUT LOUD BEFORE YOU AGREE TO IT. This is the whole of point 2 made
	# visible: the player reads "about 5 hours of the day", flies, and watches the cabin clock
	# prove it.
	box.add_child(UIStyle.make_label(SafariTransit.trip_cost_line(), "Small",
		HORIZONTAL_ALIGNMENT_CENTER))

	var fly := UIStyle.make_button("Fly", "Pill")
	fly.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fly.pressed.connect(_start_flight)
	if mobile:
		fly.custom_minimum_size = Vector2(MobileUI.MIN_TOUCH * 2.4, MobileUI.MIN_TOUCH)
	box.add_child(fly)

	_refresh_card()
	UIStyle.pop_in(panel, 0.30)
	fly.call_deferred("grab_focus")


func _set_spares(n: int) -> void:
	var want := clampi(n, 0, GameState.film_spare_max())
	# Pay as you add, refund as you take back: the dust leaves your pocket on the card, so the
	# plate count and the stardust you are holding can never disagree on the way into the flight.
	while want > _spares_bought:
		if not GameState.spend_stardust(SafariScoring.FILM_BUY_PRICE):
			break
		_spares_bought += 1
		UIStyle.play_tick()
	while want < _spares_bought:
		GameState.add_stardust(SafariScoring.FILM_BUY_PRICE)
		_spares_bought -= 1
		UIStyle.play_tick()
	_refresh_card()


func _refresh_card() -> void:
	var spare_cap := GameState.film_spare_max()
	# BUY THE SPARES FIRST, THEN THE UPGRADE, AND THE HEADROOM SHRINKS UNDER YOUR FEET: two spares
	# on an un-upgraded camera is 7 plates, and a tier bought on the same card would make it 8 -
	# past PLATES_MAX, and past what the cabin can draw. Hand the dust back for any spare the
	# upgrade has just made unnecessary rather than silently keeping it.
	while _spares_bought > spare_cap:
		GameState.add_stardust(SafariScoring.FILM_BUY_PRICE)
		_spares_bought -= 1
	_card_plates_lbl.text = "%d plates. Every trip starts full." % (
		GameState.film_capacity() + _spares_bought)
	_card_spare_lbl.text = "Spare plates: %d  (%d dust each)" % [
		_spares_bought, SafariScoring.FILM_BUY_PRICE]
	_card_spare_row.visible = spare_cap > 0
	_card_minus.disabled = _spares_bought <= 0
	_card_plus.disabled = _spares_bought >= spare_cap \
		or not GameState.can_afford(SafariScoring.FILM_BUY_PRICE)
	if GameState.film_upgrade_available():
		var cost := SafariScoring.film_upgrade_cost(GameState.film_upgrades)
		_card_up_row.visible = true
		_card_up_lbl.text = "Bigger magazine: +1 plate a trip, %d scrap" % cost
		_card_up_btn.disabled = not GameState.can_afford_scrap(cost)
	else:
		_card_up_row.visible = false


# ========================================================================= THE FLIGHT ITSELF
func _start_flight() -> void:
	if _run != null:
		return
	UIStyle.play_confirm()
	if _card != null:
		_card.queue_free()
		_card = null

	# PER TRIP, FULL, EVERY TIME. `film_capacity()` has no day box behind it any more, so this is
	# the same number on the third flight of a day as on the first.
	_plates_loaded = GameState.film_capacity() + _spares_bought

	_run = SAFARI_RUN_SCRIPT.new() as SafariRun
	_run.name = "Run"
	_run.from_id = _origin_id
	_run.to_id = _dest_id
	_run.route_id = "%s_%s" % [_origin_id, _dest_id]
	_run.hour = SafariTransit.hour if SafariTransit.hour > 0.0 else GameState.time_of_day
	_run.film_start = _plates_loaded
	_run.landed.connect(_on_landed)
	add_child(_run)

	_begin_clock_burn()


## Sizes the surcharge and starts it ticking. See the file header for why there are two halves and
## which one this is.
func _begin_clock_burn() -> void:
	_depart_hour = GameState.time_of_day
	_depart_day = GameState.day_count
	# The part of the leg I can predict: the pad beat and the lane. The haul card's own real time is
	# NOT billed separately any more (13.3: G4b's override replaces the whole absence, loadout card
	# to haul card) - `HAUL_READ_SEC` below only paces how fast the surcharge ticks, on a number that
	# does not change what the trip totals.
	var leg_sec: float = SafariRun.PAD_SEC + SafariLanes.seconds_for(_origin_id, _dest_id)
	var wall_hours: float = WorldClock.hours_for_seconds(_depart_hour, leg_sec + HAUL_READ_SEC)
	_extra_hours_total = maxf(0.0, SafariTransit.trip_hours() - wall_hours)
	_extra_hours_done = 0.0
	_extra_rate = _extra_hours_total / maxf(leg_sec, 1.0)
	_burning = true
	print("SAFARI_FLIGHT depart %s->%s hour=%05.2f day=%d plates=%d (%d + %d spare) trip=%.2fh leg=%.1fs=%.2fh extra=%.2fh" % [
		_origin_id, _dest_id, _depart_hour, _depart_day, _plates_loaded,
		GameState.film_capacity(), _spares_bought, SafariTransit.trip_hours(),
		leg_sec, wall_hours, _extra_hours_total])


func _process(delta: float) -> void:
	if _burning and _extra_hours_done < _extra_hours_total:
		var step: float = minf(_extra_rate * delta, _extra_hours_total - _extra_hours_done)
		GameState.advance_clock(step)
		_extra_hours_done += step
	_update_pill()


# ---------------------------------------------------------------- the cabin clock (what is seen)
## A DAY BURNING IS ONLY REAL IF THE PLAYER WATCHES IT BURN. Two rounds of this spike shipped
## features nobody could see, so the surcharge gets a face: a small cream plate low in the LEFT
## hull column, under the range knob, showing the day clock - which visibly runs three to four
## times normal speed for the whole flight and reads an hour later every fifteen seconds.
##
## WHERE, and why it is safe to place it from another builder's file: the numbers below come from
## `SafariRun`'s public geometry API (`window_rect`, `ui_scale`) and from the two factors its own
## `_ctrl_y()` / `_ctrl_r()` use, never from its internals. The left column's UPPER band is taken
## (the decorative side port, then the subject nameplate) and the right column belongs to the film
## magazine, but BELOW the two thumb controls both columns are empty down to the console lip -
## measured on the 2556x1179 phone frame and on the 1280x720 desktop one, and captured in this
## round's report. If the cockpit builder moves the knob, this moves with it.
func _build_clock_pill() -> void:
	_pill_layer = CanvasLayer.new()
	_pill_layer.name = "CabinClock"
	_pill_layer.layer = 41
	add_child(_pill_layer)

	_pill_root = Control.new()
	_pill_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pill_root.theme = UIStyle.theme()
	_pill_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill_layer.add_child(_pill_root)

	_pill = PanelContainer.new()
	_pill.name = "Plate"
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.add_theme_stylebox_override("panel",
		UIStyle.make_panel_style(SafariRun.C_CREAM, 8, SafariRun.C_BRASS, 2, 6, 0.0))
	_pill_root.add_child(_pill)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.add_child(col)

	_pill_clock = _plate_label("", 24, SafariRun.C_TEXT)
	col.add_child(_pill_clock)
	col.add_child(_plate_label("the day goes by", 14, SafariRun.C_SOFT))


func _plate_label(t: String, px: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _update_pill() -> void:
	if _run == null or _returning:
		return
	var win: Rect2 = _run.window_rect()
	if win.size.x < 8.0:
		return
	if _pill_layer == null:
		_build_clock_pill()
	_pill_clock.text = UIStyle.format_clock(GameState.time_of_day)
	var vs: Vector2 = _pill_root.size
	if vs.y < 8.0:
		return
	var k: float = _run.ui_scale()
	# The same two factors safari_run.gd's `_ctrl_y()` / `_ctrl_r()` use for the thumb controls, so
	# the plate sits under the knob wherever the knob ends up, on any frame size.
	var ctrl_y: float = vs.y * 0.655
	var ctrl_r: float = clampf(vs.y * 0.086, 42.0, 112.0)
	var w: float = maxf(win.position.x * 0.86, 120.0 * k)
	_pill.custom_minimum_size = Vector2(w, 0.0)
	_pill.size = Vector2(w, _pill.size.y)
	_pill.position = Vector2(win.position.x * 0.5 - w * 0.5, ctrl_y + ctrl_r * 1.22)


# ---------------------------------------------------------------------------------- the landing
## The game-hours still owed so the whole flight sums to EXACTLY `SafariTransit.trip_hours()`, given
## what the smooth burn has already advanced. An INVERSION, not a measurement: it never reads
## `wall_seconds`, `Time.get_ticks_msec()`, or anything else that moves with how long the flight
## really took - that independence is the entire fix (12.2). `_extra_hours_done` is pinned at
## `_extra_hours_total` by the true-up in `_on_landed` before this is ever called, and
## `_extra_hours_total` was itself fixed at departure (`_begin_clock_burn`), so this number is
## decided before the lane even opens and cannot move for any reason the lane, the haul card or a
## pause introduces afterward.
func _flight_remaining_hours() -> float:
	return maxf(0.0, SafariTransit.trip_hours() - _extra_hours_done)


## `wall_seconds` is real seconds since `_run._ready()` (PAD + RUN + however long the player sat on
## the haul card) - logged always, but no longer charged from directly (see the file header and
## `_flight_remaining_hours()` above): this is the fix for SAFARI_FLIGHT_SPEC.md 12.2.
func _on_landed(wall_seconds: float) -> void:
	if _returning:
		return
	_returning = true
	_burning = false
	# TRUE-UP. If the flight ended early (the Skip button, a short lane, a `--quit-at` probe) the
	# smooth burn has not finished ticking. Pay the rest in one go, so `_extra_hours_done` always
	# lands on exactly `_extra_hours_total` by the time `_flight_remaining_hours()` reads it below -
	# skipping the lane never buys the day back, and never overpays it either.
	var rest: float = maxf(0.0, _extra_hours_total - _extra_hours_done)
	if rest > 0.0:
		GameState.advance_clock(rest)
		_extra_hours_done += rest
	# THE REST OF THE BILL, decided now (an inversion of the burn above), spent below. Fixed the
	# instant it is read: nothing from here to the scene change - the SYNTHETIC `--extra-wait=`
	# probe hook included - can change it, because nothing here measures real time.
	var remaining: float = _flight_remaining_hours()
	# DAY round: NOTHING IS BOOKED BACK. Film is per trip, so a landed flight owes no day box
	# anything; `used` is printed only so a test can read what the flight actually spent.
	var used: int = maxi(0, _plates_loaded - _run.film_left())
	var dest := _dest_id if _dest_id != "" else GameState.current_planet_id

	# SYNTHETIC: the `--trips=N` ledger. Turn round and fly back instead of landing in a world.
	if _probe_trips > 0:
		_probe_flown += 1
		# THE FIX, in the probe: this used to be `WorldClock.hours_for_seconds(hour, wall_seconds)`
		# - the flight's own real seconds, which is exactly what 12.2 says must not set the bill.
		# It now bills `remaining`, the SAME inversion the real (non-probe) path hands to
		# `Environment.override_next_absence_hours()` below, so `_extra_hours_done + leg_h` is
		# `trip_hours()` BY CONSTRUCTION, whatever `wall_seconds` turns out to be - proving the fix
		# without a World scene, and without touching `BOOST_LIVE`.
		var leg_h: float = remaining
		GameState.advance_clock(leg_h)
		# `ground_h` is the probe's OWN invention - simulated seconds standing in for the moment
		# spent in the world you land in before turning round - and it is NOT part of the flight,
		# so it stays billed on real seconds exactly as before. Conflating the two is the mistake
		# the ledger baseline made (SAFARI_FLIGHT_SPEC.md 12.2's "0.28h is the probe's own 12s").
		var ground_h: float = WorldClock.hours_for_seconds(GameState.time_of_day, _probe_ground)
		GameState.advance_clock(ground_h)
		print("DAYLEDGER trip=%d %s->%s plates=%d used=%d clock %05.2f -> %05.2f day %d -> %d flight=%.2fh (extra %.2f + leg %.2f) + ground %.2fh = cost %.2fh; wall=%.1fs" % [
			_probe_flown, _origin_id, dest, _plates_loaded, used, _depart_hour,
			GameState.time_of_day, _depart_day, GameState.day_count,
			_extra_hours_done + leg_h, _extra_hours_done, leg_h, ground_h,
			_extra_hours_done + leg_h + ground_h, wall_seconds])
		if _probe_flown >= _probe_trips:
			print("DAYLEDGER done: %d trips, ended day %d at %05.2f" % [
				_probe_flown, GameState.day_count, GameState.time_of_day])
			get_tree().quit()
			return
		var swap := _origin_id
		_origin_id = dest
		_dest_id = swap
		_run.queue_free()
		_run = null
		_returning = false
		call_deferred("_start_flight")
		return

	SafariTransit.clear()
	# Tell environment.gd EXACTLY what the rest of this hop costs, before the scene change that will
	# make it ask - so real seconds it did not measure (a boosted lane, or the SYNTHETIC
	# `--extra-wait=` below standing in for a slow haul-card read) cannot change the answer.
	ENVIRONMENT_SCRIPT.override_next_absence_hours(remaining)
	if _probe_extra_wait > 0.0:
		# SYNTHETIC ONLY (see the test-hooks block above): really wait, in wall-clock time, standing
		# in for the tutorial's pauses or a player reading the haul card slowly. `ignore_time_scale`
		# so a process also started with Godot's own `--time-scale <X>` engine flag cannot shrink
		# this back down - the two are meant to probe opposite directions (faster than assumed,
		# slower than assumed) and must not cancel each other out by accident.
		await get_tree().create_timer(_probe_extra_wait, true, false, true).timeout
	print("SAFARI_FLIGHT landed dest=%s wall=%.1fs plates_used=%d/%d next_trip_loads=%d clock %05.2f -> %05.2f day %d -> %d (+%.2fh billed here, %.2fh handed to environment.gd on arrival, trip_hours=%.2f)" % [
		dest, wall_seconds, used, _plates_loaded, GameState.film_capacity(),
		_depart_hour, GameState.time_of_day, _depart_day, GameState.day_count,
		_extra_hours_done, remaining, SafariTransit.trip_hours()])
	SceneRouter.go_to_planet(dest, true)
