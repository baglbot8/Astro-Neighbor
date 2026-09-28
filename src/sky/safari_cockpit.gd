class_name SafariCockpit
extends Control
## SPIKE (2026-09-21, scratch only). YOU ARE SITTING INSIDE THE SHIP, AND THE SKY IS UNBROKEN.
##
## The user looked at the safari frames and said the border was wrong:
##
##     "Can we make the outside borders like the white side panels of the ship but from the inside
##      so there's just a couple big buttons and knobs and sliders (nothing too busy). Instead of
##      more outer space which seems too serious in tone / empty."
##
## and then, at a frame of the first pass:
##
##     "I do like the round porthole, but just the outside of the porthole would be the inside of
##      the ship. I saw a flash on the screen of a rectangular view and wanted to clarify that."
##
## ROUND 3 IS THAT SECOND SENTENCE, FINISHED. The opening was already a true circle, but a
## ship-fixed frame was still drawn INSIDE it: three pillars, a roof lip and the ship's nose. The
## review measured what that looked like - at el +20 a dead-flat horizontal line 610 px long with
## zero curvature across the disc, at az 170 a pillar straight down the middle of it - which is the
## rectangle the user saw, just cut into pieces. So:
##
##   THE RULE, and it is absolute: NOTHING IS DRAWN INSIDE THE DISC. Not by this file, not by
##   anything. The clipped `Frame` child that used to draw the pillars is deleted, class and node,
##   so the only node that can colour a pixel inside the opening is the eyepiece shader. Every piece
##   of ship in this file is drawn on the hull, OUTSIDE the glass, framing it.
##
## AND THE WINDOW GOT BIG. The review measured the disc at 21.5% of the phone frame - 59% of the
## area an uncropped circle can have - because a 100 px rail and a 171 px console ate 271 of the
## 1180 rows. Both are gone, down to a lip and a sill (safari_run.gd RAIL_F/CONSOLE_F), the porthole
## takes 668 of 720 UI rows, and it MEASURES 31.2% of a 2556x1179 frame against a hard ceiling of
## 36.3% for any uncropped circle. Nothing was cropped and nothing was squashed to get there.
##
## WHERE THE BANDS' CONTENTS WENT: the side columns, which are 446 UI px wide each and are where
## both thumbs already are. The knob and the shutter were already there. The nameplate moved over
## the left thumb. And the heading ribbon that used to run along the top rail became
##
##   THE COLLAR. A compass engraved into the porthole's own mounting ring, reading RELATIVE bearing:
##   straight up is where you are looking, the bright notch at the top is exactly the 14 degrees the
##   glass is showing, the amber wedge is the ship's nose (where you are actually flying), the
##   coloured dabs are subjects that are up and not yet caught, and the ticks are the ship's own
##   45 degree marks, so the hull visibly turns under you when you swing. It is the same 360 degrees
##   the ribbon mapped, at 6.0 px per degree instead of 3.4, and it is around the glass instead of a
##   strip you had to look away from the glass to read.
##
## THE PITCH SCRATCH on the left of the collar is what is left of the roof lip and the nose sill:
## a bead on a scratched scale, so level is still a thing you can see. It is 3 px wide and it is
## outside the glass.
##
## A CABIN AT NIGHT, not a showroom. An early pass painted the hull straight out of the Moonstone
## panel colour and MEASURED value mean 0.86 across it, flat from corner to corner. These are the
## same hues pulled down and given somewhere to fall - the lip is in shadow, the bottom of each
## column is where the lamp is, and the two reading pools over the controls do the rest. Whole-frame
## gates in docs/STYLE_GUIDE.md R2.3/R2.6 are re-measured after every change to these.
const HULL_TOP := Color("#8b8fa3")
const HULL_MID := Color("#adb1c2")
const HULL_BOT := Color("#cfc8bd")
const HULL_LIT := Color("#e4dbcd")
const SEAM := Color("#6f7389")
const SEAM_SOFT := Color("#b6b9c8")
const INSET := Color("#8f94a8")
## The two control housings are sunk into the warm part of the panel, so they are NOT the same cool
## grey as the shadowed lip up top.
const RECESS := Color("#a8a096")
const INK := Color("#2c2f42")
const SOFT := Color("#6d7288")
const AMBER := Color("#f0a64a")
const AMBER_EDGE := Color("#c9822f")
const GOLD := Color("#ffe27a")
const LAMP := Color("#ffd9a8")

## The collar's ship-fixed marks, in degrees. Eight of them, alternating long and short.
const ROSE_TICK_DEG := 45.0
## R5's THIRD CONSTANT (SAFARI_FLIGHT_SPEC.md 6.4). This used to be a separate hardcoded 60.0 that
## someone had to remember to update by hand every time SafariRun's EL_MIN/EL_MAX moved. G1's
## tightened numbers were not readable from this scratch copy when this round started (its own
## scratch tree, not synced with G1's), so instead of guessing a fresh constant that would drift
## the moment G1 lands its change, the span is now DERIVED from `SafariRun.EL_MIN`/`EL_MAX` at draw
## time - see `_pitch_span_deg()` below, next to `_bear()`/`_ang()`. No separate number to keep in
## sync, ever again, and it self-corrects the day this file is merged with G1's.

## S3's porthole-edge half: the "something is about to be catchable, that way" cue, 1-2 s ahead of
## a sight's own window (SAFARI_FLIGHT_SPEC.md S3 - "New Snap gives an explicit on-screen
## directional prompt; the warning is UI, not luck"). G1 draws the in-glass half at the same lead;
## its exact warm-up timing was not readable from this scratch copy either (own scratch tree), so
## this is the MIDDLE of the spec's own 1-2 s band, not a fitted number. ASSUMPTION for the lead to
## reconcile against G1's actual timing - see the report.
const WARN_LEAD_SEC := 1.5

## R6's four-word ceiling (SAFARI_FLIGHT_SPEC.md - "if a control cannot be labelled in two or three
## words it is too clever"). Spec 10.3 raised it to FIVE for the boost; the boost's one word
## ("boost") is the label on its own button (safari_run.gd `_boost_btn`), so it is not repeated here -
## and while `SafariRun.BOOST_LIVE` is false (12.2: until the flight's bill is right) that button is
## hidden and the cabin shows FOUR controls. One constant per word so the legend and this comment
## cannot drift apart, and so a critic can grep for the exact words the spec asked for.
const LEGEND_FOCUS := "focus"
const LEGEND_SHUTTER := "shutter"
const LEGEND_SWING := "swing"
const LEGEND_SCOPE := "scope"
## R9: what the shutter does, beside its name. Tap takes the picture now; hold makes it bloom.
const LEGEND_SHUTTER_HOW := "tap · hold"
## Vertical gap between a column's two stacked legend words, as a multiple of font size - see
## `_legend()`'s header note on why they stack in the columns rather than share the sill.
const LEGEND_STACK_GAP := 1.55

var run: SafariRun
## EVIDENCE TOGGLE, left in on purpose (G2 builder, 2026-09-21). Flip to true and rebuild to
## reproduce the "additions off" control frame the report's evidence rules ask for - a critic can
## re-run this A/B without hand-editing the file. Ships false. Gates the elevation tag and the S3
## warning ping only; the legend and the field_half call are the requirement itself, not something
## to A/B against.
const DEBUG_EVIDENCE_OFF := false

## THE ASK IN THE SKY (F4, flight wave 4; docs/STORY_SPINE_SPEC.md 4 "the in-flight marker that says
## this one is the ask"). A sight a neighbour asked for wears a small gold four-point sparkle - the
## stardust sparkle the game already uses for money (STYLE_GUIDE: stardust `#ffe27a`, sparkle
## `#fff6c8`), so it reads as "this one is worth something" without a new colour. S 0.52 and 0.21,
## both under the 0.60 swatch cap. A navy edge keeps it readable on the light collar as well as the
## dark sky. No sight's own tint is gold-and-navy, so it cannot be mistaken for a dab.
const ASK_GOLD := Color("#ffe27a")
const ASK_SPARK := Color("#fff6c8")
const ASK_EDGE := Color("#1b1f33")


# ================================================================== the cabin
func _draw() -> void:
	if run == null:
		return
	var win: Rect2 = run.window_rect()
	var con: Rect2 = run.console_rect()
	var k: float = run.ui_scale()

	_hull(win, con)
	_collar(win)
	if run.hud_live():
		_ask_marks(win, k)
		_console(win, k)


## The hull that is left once the disc is cut out of the screen: a lip along the top, a sill along
## the bottom and two wide columns down the sides. A cabin at night - the lip is in shadow, the
## lamp is down where your hands are.
func _hull(win: Rect2, con: Rect2) -> void:
	var w := size.x
	var col: float = win.position.x
	# the lip over the glass
	_vgrad(Rect2(0.0, 0.0, w, win.position.y), HULL_TOP.darkened(0.10), HULL_MID)
	# the two side columns, top to bottom of the opening
	_vgrad(Rect2(0.0, win.position.y, col, win.size.y), HULL_MID, HULL_BOT)
	_vgrad(Rect2(win.end.x, win.position.y, w - win.end.x, win.size.y), HULL_MID, HULL_BOT)
	# the sill under the glass. It CONTINUES the columns instead of restarting at HULL_MID, which
	# drew a cold blue band across the bottom of the cabin with a hard seam above it.
	_vgrad(Rect2(0.0, con.position.y, w, maxf(size.y - con.position.y, 1.0)),
		HULL_BOT, HULL_BOT.lerp(HULL_LIT, 0.40))

	# THE LAMP, and it moved. It used to be a pool in the middle of a 171 px console; there is no
	# console any more, so the warm light is where the cabin still has room for it - low in each
	# side column, under the controls. Drawn as horizontal strips inside the column, so it can
	# never spill onto the glass, which is exactly what an earlier pass did.
	for cx in [col * 0.5, w - col * 0.5]:
		var strips := 26
		for i in strips:
			var t := (float(i) + 0.5) / float(strips)
			var yy: float = win.position.y + win.size.y * (0.42 + 0.64 * t)
			var dy: float = (t - 0.40) * 2.0
			var a: float = 0.130 * exp(-dy * dy * 1.7)
			var half: float = col * 0.50 * clampf(1.0 - absf(dy) * 0.40, 0.25, 1.0)
			draw_rect(Rect2(cx - half, yy, half * 2.0, win.size.y * 0.64 / float(strips) + 1.0),
				Color(LAMP.r, LAMP.g, LAMP.b, a))

	# THE TWO READING LAMPS. A soft warm pool behind each control, so the knob and the shutter sit
	# in the light instead of floating on flat panel.
	for xf in [run.knob_xf(), run.shutter_xf()]:
		var lc: Vector2 = Vector2(xf[0])
		var lr: float = float(xf[1])
		for i in 10:
			var t := float(i) / 9.0
			draw_circle(lc - Vector2(0.0, lr * 0.55 * (1.0 - t)), lr * (3.6 - 2.6 * t),
				Color(LAMP.r, LAMP.g, LAMP.b, 0.040))

	# The seams where the panels meet. THEY STOP AT THE COLUMNS: a full-width line at the top of the
	# opening is tangent to the disc, and a straight line touching the glass is the exact read this
	# round is removing.
	for y in [win.position.y, con.position.y]:
		for seg in [[0.0, col], [win.end.x, w]]:
			draw_line(Vector2(seg[0], y), Vector2(seg[1], y), Color(SEAM.r, SEAM.g, SEAM.b, 0.30), 2.0)
			draw_line(Vector2(seg[0], y + 2.0), Vector2(seg[1], y + 2.0),
				Color(1.0, 1.0, 1.0, 0.45), 2.0)
	# one panel seam per column, well clear of the porthole's collar
	for fx in [0.20, 0.80]:
		for x in [col * fx, w - col * fx]:
			draw_line(Vector2(x, win.position.y), Vector2(x, win.end.y),
				Color(SEAM.r, SEAM.g, SEAM.b, 0.20), 2.0)
			draw_line(Vector2(x + 2.0, win.position.y), Vector2(x + 2.0, win.end.y),
				Color(1.0, 1.0, 1.0, 0.30), 2.0)

	# a few quiet rivets down the side columns. Three a side, not a row of forty.
	var rr: float = maxf(col * 0.030, 2.5)
	for i in 3:
		var yy: float = win.position.y + win.size.y * (0.10 + 0.38 * float(i))
		for x in [col * 0.20, w - col * 0.20]:
			draw_circle(Vector2(x, yy), rr, Color(SEAM.r, SEAM.g, SEAM.b, 0.26))
			draw_circle(Vector2(x, yy - rr * 0.35), rr * 0.55, Color(1.0, 1.0, 1.0, 0.40))

	# TWO LITTLE SIDE PORTS, one per column. The cheapest possible answer to "you are sitting in
	# something": a second and a third window, well away from the one you are working, with the lane
	# streaming past them. They do NOT turn with the scope - they are holes in the hull, so what they
	# show is the ship's own sideways motion, which is true at every heading.
	var pr: float = maxf(col * 0.105, 16.0)
	var py: float = win.position.y + win.size.y * 0.150
	_side_port(Vector2(col * 0.50, py), pr, 1.0)
	_side_port(Vector2(w - col * 0.50, py), pr, -1.0)

	# THE CORNERS FALL OFF. One lamp low in each column means the outer corners are the darkest
	# thing in the room. Vertical strips, so it costs nothing and never touches the glass.
	var vg: int = 34
	var vw: float = col * 0.58
	for i in vg:
		var t := float(i) / float(vg - 1)
		var a: float = 0.032 * t * t * t
		var sw: float = vw / float(vg) + 1.0
		draw_rect(Rect2(vw * (1.0 - t) - sw, 0.0, sw, size.y), Color(0.06, 0.07, 0.13, a))
		draw_rect(Rect2(w - vw * (1.0 - t), 0.0, sw, size.y), Color(0.06, 0.07, 0.13, a))


# ================================================================== the collar, and what it reads
## THE PORTHOLE OPENING AND THE ONE INSTRUMENT ON IT.
##
## The shader leaves everything outside the disc transparent, so this fills the four corners of the
## bounding square with hull and then dresses the edge: a machined mounting ring standing proud of
## the panel, and engraved into that ring, the compass described in the header. Every mark is at a
## radius GREATER than the opening's, so the sky inside is never touched.
func _collar(win: Rect2) -> void:
	var c: Vector2 = win.position + win.size * 0.5
	var rad: float = win.size.x * 0.5
	var rw: float = maxf(rad * SafariRun.COLLAR_RW_FRAC, 9.0)      # how wide the ring is
	var seg := 160

	# --- the corners. A ring of quads from just inside the disc out to the square's edge, coloured
	# with the same top-to-bottom gradient the side columns use so the joins do not show.
	for i in seg:
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var i0: Vector2 = c + d0 * (rad - 1.0)
		var i1: Vector2 = c + d1 * (rad - 1.0)
		var o0: Vector2 = c + d0 * _to_square(d0, rad)
		var o1: Vector2 = c + d1 * _to_square(d1, rad)
		draw_polygon(PackedVector2Array([i0, i1, o1, o0]), PackedColorArray([
			_hull_at(i0.y, win), _hull_at(i1.y, win), _hull_at(o1.y, win), _hull_at(o0.y, win)]))

	# --- the mounting ring, standing proud of the panel. It spills a little onto the lip and the
	# sill on purpose: the porthole is bolted THROUGH the hull, not painted on it.
	for i in 7:
		var t := float(i) / 6.0
		draw_arc(c, rad + rw * (0.08 + 0.94 * t), 0.0, TAU, 170,
			HULL_LIT.lerp(HULL_MID, t * t), rw * 0.36, true)
	# four bolts, on the diagonals where the corner fill has room for them
	var bolt: float = maxf(rw * 0.24, 2.5)
	for i in 4:
		var a: float = TAU * (float(i) + 0.5) / 4.0
		var bp: Vector2 = c + Vector2(cos(a), sin(a)) * (rad + rw * 1.85)
		draw_circle(bp, bolt, Color(SEAM.r, SEAM.g, SEAM.b, 0.34))
		draw_circle(bp - Vector2(0.0, bolt * 0.35), bolt * 0.55, Color(1.0, 1.0, 1.0, 0.42))

	_rose(c, rad, rw)

	# --- the machined edge: a groove on the ring side, a shadow on the glass side, and a lit lip
	# along the bottom where the column lamps catch it.
	draw_arc(c, rad + 2.0, 0.0, TAU, 220, Color(SEAM.r, SEAM.g, SEAM.b, 0.85), 4.0, true)
	draw_arc(c, rad - 2.5, 0.0, TAU, 220, Color(0.10, 0.11, 0.17, 0.35), 5.0, true)
	draw_arc(c, rad + 5.0, PI * 0.12, PI * 0.88, 130, Color(1.0, 0.99, 0.95, 0.45), 3.0, true)

	_pitch(c, rad, rw)


## THE COMPASS ON THE COLLAR. Relative bearing: straight up is where you are pointed.
##
## This is the top rail's ribbon, wrapped around the glass. It replaces it rather than joining it -
## with the rail down to a 31 px lip there is no room for a strip, and the whole point of the ribbon
## was to be readable without looking away from the sky, which a ring around the sky does better.
## 360 degrees over the ring's circumference is 6.0 px per degree on the phone frame; the ribbon
## managed 3.4.
func _rose(c: Vector2, rad: float, rw: float) -> void:
	var az: float = run.az_deg()
	# The line the marks ride on. It is INSIDE the ring's outer edge on purpose: a mark hung outside
	# the ring is a mark that leaves the screen when you look dead astern.
	#
	# 13.5: THIS ALONE WAS NOT ENOUGH. A dab's (and an S3 ping's) OWN drawing reaches further still -
	# `COLLAR_DAB_REACH_FRAC` beyond the glass, past `rr` itself - and at dead ahead or dead astern
	# that used to draw a dab as close as 9 device px from the bottom of a real 2556x1179 --ui=mobile
	# frame, under the ~34 px home indicator (this round's report). FIXED in `_layout_cockpit()`
	# (safari_run.gd), which now sizes the disc - so `rad`, and so `rr` and `rw` here - so a mark's
	# full reach clears the real bottom safe-area inset (and the plain top edge) at every bearing.
	# Nothing here has to know that happened: `rad`/`rw` just come out smaller on a phone whose inset
	# needs it, unchanged everywhere else.
	var rr: float = rad + rw * SafariRun.COLLAR_DAB_OFFSET_FRAC
	var t: float = run.run_time()

	# the trough the marks are engraved in
	draw_arc(c, rr, 0.0, TAU, 220, Color(INSET.r, INSET.g, INSET.b, 0.55), rw * 0.78, true)
	draw_arc(c, rr - rw * 0.40, 0.0, TAU, 220, Color(0.08, 0.09, 0.15, 0.30), 2.0, true)
	draw_arc(c, rr + rw * 0.40, 0.0, TAU, 220, Color(1.0, 1.0, 1.0, 0.26), 2.0, true)

	# THE SHIP'S OWN MARKS, every 45 degrees of heading. They sweep past as you swing, which is what
	# the pillars used to do - except these are on the hull, where structure belongs.
	for i in 8:
		var b: float = wrapf(ROSE_TICK_DEG * float(i) - az, -180.0, 180.0)
		var d := _bear(b)
		var long: bool = (i % 2) == 0
		draw_line(c + d * (rad + rw * 0.16), c + d * (rad + rw * (0.94 if long else 0.66)),
			Color(SEAM.r, SEAM.g, SEAM.b, 0.55 if long else 0.30), maxf(rw * 0.16, 2.0), true)

	# WHAT THE GLASS IS SHOWING RIGHT NOW: a bright notch at the top, exactly as wide as the field.
	# "Is it in the window yet" is a thing you can answer without leaving the window.
	#
	# GLASS ROUND (2026-09-21): this used to hard-code SafariCast.FIELD_HALF_DEG, which was true
	# once and false the instant the scope is raised - the window is 28 deg lowered, 7 deg raised
	# (SAFARI_FLIGHT_SPEC.md 6.2). `run.field_half_deg()` is G1's new API for that; it was not yet
	# on SafariRun in this scratch copy when this was written (G1 owns that file and is mid-edit in
	# its own scratch tree), so this is written against the contract, not tested end to end here -
	# see the report's needs_from_others.
	#
	# ROUND 2 FIX (critic blocker #1, 2026-09-21): `run.field_half_deg()` did not exist yet in this
	# scratch copy and threw 'Invalid call: Nonexistent function' on EVERY drawn frame - and because
	# a GDScript error aborts the rest of the function it is in, every line below this one in _rose()
	# (the field notch itself, every collar dab, the S3 warning ping, the S9 nose wedge) silently
	# stopped drawing for the whole run. Guarded with `has_method()` and the file's own
	# `SafariCatalog.FIELD_HALF_DEG` fallback (already imported above, already used by G1's own file
	# for the same constant) so the rest of `_rose()` keeps running - and keeps drawing - whether or
	# not G1's real wide/raised split has landed yet. Once `field_half_deg()` exists on SafariRun this
	# branch is dead code and can be deleted; it is not a permanent design, only a local stand-in for
	# a call G1 has not shipped.
	var half: float = run.window_aspect() * (
		run.field_half_deg() if run.has_method("field_half_deg") else SafariCatalog.FIELD_HALF_DEG)
	draw_arc(c, rr, _ang(-half), _ang(half), 20, Color(1.0, 0.96, 0.88, 0.46), rw * 0.64, true)

	# SUBJECTS that are up and still out there, at their bearing, in their own colour, brighter
	# while they are doing the thing worth turning for. THE CHEVRON is new this round: R1/S3's
	# "which way up" half - see `_elev_tag()`.
	for e in run.cast_list():
		if not SafariCast.is_up(e, t):
			continue
		if run.is_caught(str(e["id"])):
			continue
		var p: Vector2 = SafariCast.pos_at(e, t)
		var d2 := _bear(wrapf(p.x - az, -180.0, 180.0))
		var col := Color(str(e["tint_a"]))
		var mo: float = SafariCast.moment_strength(e, t)
		var dabc: Vector2 = c + d2 * rr
		var asked: bool = run.has_method("is_asked") and run.is_asked(str(e["id"]))
		if asked:
			# THE ASK ON THE COLLAR: a gold ring round the dab and the sparkle beside it, on the
			# clockwise side - above and below are the elevation chevron's.
			draw_arc(dabc, rw * 0.66, 0.0, TAU, 28, Color(ASK_EDGE, 0.55), maxf(rw * 0.24, 3.5), true)
			draw_arc(dabc, rw * 0.66, 0.0, TAU, 28, ASK_GOLD, maxf(rw * 0.13, 2.0), true)
		draw_circle(dabc, rw * (0.42 + 0.26 * mo), Color(col.r, col.g, col.b, 0.30 + 0.34 * mo))
		draw_circle(dabc, rw * 0.25, Color(col.r, col.g, col.b, 0.95))
		if asked:
			_sparkle(dabc + Vector2(-d2.y, d2.x) * rw * 1.20, rw * 0.62)
		if not DEBUG_EVIDENCE_OFF:
			_elev_tag(dabc, col, p.y - run.el_deg(), rw, 1.0)

	# S3's PORTHOLE-EDGE HALF: something not yet up, but about to be, inside WARN_LEAD_SEC. A ping,
	# not a dab - a hollow ring that closes in and a dim core, distinct from the solid "it is here"
	# dab above, so the two never read as the same thing. It rides `pos_at()`'s own clamp: called
	# before `t_start` it simply holds at the subject's az0/el0, which IS where it first appears, so
	# the ping already points at the right spot with no separate lookup.
	if not DEBUG_EVIDENCE_OFF:
		for e in run.cast_list():
			if SafariCast.is_up(e, t) or run.is_caught(str(e["id"])):
				continue
			var t_start: float = float(e["t_start"])
			var lead: float = t_start - t
			if lead <= 0.0 or lead > WARN_LEAD_SEC:
				continue
			var p2: Vector2 = SafariCast.pos_at(e, t)
			var d3 := _bear(wrapf(p2.x - az, -180.0, 180.0))
			var col2 := Color(str(e["tint_a"]))
			var pc: Vector2 = c + d3 * rr
			# THE ASK, already on its warning: the far mark wears the sparkle from the moment it is
			# drawn (MARK_LEAD_SEC ahead of opening), so the ping that points at it does too.
			if run.has_method("is_asked") and run.is_asked(str(e["id"])):
				_sparkle(pc + Vector2(-d3.y, d3.x) * rw * 1.20, rw * 0.62)
			var u: float = 1.0 - lead / WARN_LEAD_SEC     # 0 at first cue, 1 as it arrives
			var pulse: float = fposmod(u * 2.2, 1.0)       # a couple of pings across the lead window
			# 13.5: the ping's ring, unlike the chevron, has no shrink of its own - at its biggest
			# pulse (`COLLAR_PING_HALO_FRAC`, bigger than a dab's own halo) near dead ahead or dead
			# astern it could still reach past the disc's own safety margin (sized for a plain dab -
			# see `_layout_cockpit()`) or the real bottom safe-area inset. Capped to whatever room is
			# actually clear in every direction from `pc` - a circle needs the same room on all four
			# sides, so the smallest of them is the real limit, same idea as `_elev_tag()`'s shrink.
			var safe_r: Vector4 = MobileUI.safe_area()   # zero on desktop, on its own
			var ring_room: float = minf(minf(pc.x - safe_r.x, size.x - safe_r.z - pc.x),
				minf(pc.y - safe_r.y, size.y - safe_r.w - pc.y))
			var ping_r: float = clampf(rw * lerp(0.30, SafariRun.COLLAR_PING_HALO_FRAC, pulse),
				0.0, maxf(ring_room, 0.0))
			draw_arc(pc, ping_r, 0.0, TAU, 22,
				Color(col2.r, col2.g, col2.b, (1.0 - pulse) * 0.55), 2.0, true)
			draw_circle(pc, rw * 0.14, Color(col2.r, col2.g, col2.b, 0.45 + 0.35 * sin(u * PI)))
			_elev_tag(pc, col2, p2.y - run.el_deg(), rw, 0.75)

	# THE NOSE. Where the ship is actually flying, which is not where you are looking. The one amber
	# thing on the collar, and it points in at the glass. It rides the same ring the dabs do, so
	# when it sits in the bright notch you are looking straight down the lane.
	var nd := _bear(wrapf(-az, -180.0, 180.0))
	var np: Vector2 = c + nd * rr
	var side := Vector2(-nd.y, nd.x) * rw * 0.55
	# S9: a soft dark halo behind it. The bright notch is now up to 56 deg wide instead of 14 (the
	# wide window, G1's glass round) and far more likely to sit under the nose - without this the
	# one constant reference frame the user needs washes out into the notch it usually rides in.
	draw_circle(np, rw * 0.95, Color(0.06, 0.07, 0.13, 0.28))
	draw_colored_polygon(PackedVector2Array([
		np - nd * rw * 0.78, np + nd * rw * 0.45 + side, np + nd * rw * 0.45 - side]), AMBER)
	draw_line(np + nd * rw * 0.45 + side, np + nd * rw * 0.45 - side,
		Color(AMBER_EDGE.r, AMBER_EDGE.g, AMBER_EDGE.b, 0.80), 2.0, true)


## PUBLIC (F4): where a sight's dab sits on the collar this frame, in this Control's space - the
## exact point `_rose()` draws it at, so the first lesson's pointer lands on the dab and not near it.
func dab_point(e: Dictionary) -> Vector2:
	var win: Rect2 = run.window_rect()
	var c: Vector2 = win.position + win.size * 0.5
	var rad: float = win.size.x * 0.5
	var rw: float = collar_width()
	var p: Vector2 = SafariCast.pos_at(e, run.run_time())
	return c + _bear(wrapf(p.x - run.az_deg(), -180.0, 180.0)) * (rad + rw * SafariRun.COLLAR_DAB_OFFSET_FRAC)


## PUBLIC (F4): the collar ring's width, the unit every mark on it is sized in.
func collar_width() -> float:
	return maxf(run.window_rect().size.x * 0.5 * SafariRun.COLLAR_RW_FRAC, 9.0)


## THE ASK ON ITS FAR MARK. The mark itself is the shader's; this puts the same gold sparkle the
## collar dab wears at its upper right, plus a thin gold ring just outside the mark's own ring, and
## fades both with the mark's own hand-over to the real shape (`SafariRun.ask_marks()` applies the
## same gates `_feed_marks` does). It is sky-attached - it moves with the sight, never with the ship
## - and it is only drawn where it fits wholly inside the disc, so the glass's edge stays clean.
func _ask_marks(win: Rect2, k: float) -> void:
	if not run.has_method("ask_marks"):
		return
	var c: Vector2 = win.position + win.size * 0.5
	var rad: float = win.size.x * 0.5
	for m in run.ask_marks():
		var p: Vector2 = m["p"]
		var mr: float = float(m["r"])
		var a: float = float(m["a"])
		var ring: float = mr * 1.45 + 3.0 * k
		var sr: float = maxf(mr * 0.62, 8.0 * k)
		var sp: Vector2 = p + Vector2(0.72, -0.72) * (ring + sr * 0.55)
		if p.distance_to(c) + ring > rad - 4.0 or sp.distance_to(c) + sr > rad - 4.0:
			continue
		draw_arc(p, ring, 0.0, TAU, 40, Color(ASK_EDGE, 0.40 * a), maxf(4.0 * k, 3.0), true)
		draw_arc(p, ring, 0.0, TAU, 40, Color(ASK_GOLD, 0.90 * a), maxf(2.0 * k, 1.5), true)
		_sparkle(sp, sr, a)


## The ask's glyph: a four-point sparkle, navy-edged gold with a pale heart.
func _sparkle(p: Vector2, r: float, a: float = 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var ang: float = TAU * float(i) / 8.0 - PI * 0.5
		var rr: float = r if i % 2 == 0 else r * 0.34
		pts.append(p + Vector2(cos(ang), sin(ang)) * rr)
	var edge := PackedVector2Array(pts)
	edge.append(pts[0])
	draw_polyline(edge, Color(ASK_EDGE, 0.60 * a), maxf(r * 0.22, 2.0), true)
	draw_colored_polygon(pts, Color(ASK_GOLD, a))
	draw_circle(p, r * 0.20, Color(ASK_SPARK, a))


## THE PITCH SCRATCH. What is left of the roof lip and the nose sill, moved off the glass: a scale
## scratched into the hull beside the collar with a bead on it, so level is still something you can
## see. Three pixels wide, and the closest it comes to the disc is a clear band of hull.
func _pitch(c: Vector2, rad: float, rw: float) -> void:
	var x: float = c.x - rad - rw * 1.70 - 8.0
	var half: float = rad * 0.46
	draw_line(Vector2(x, c.y - half), Vector2(x, c.y + half), Color(SEAM.r, SEAM.g, SEAM.b, 0.30), 3.0)
	draw_line(Vector2(x + 2.0, c.y - half), Vector2(x + 2.0, c.y + half), Color(1.0, 1.0, 1.0, 0.22), 2.0)
	for i in 5:
		var yy: float = c.y - half + half * 0.5 * float(i)
		var tw: float = 9.0 if i == 2 else 5.0
		draw_line(Vector2(x - tw, yy), Vector2(x + tw, yy),
			Color(SEAM.r, SEAM.g, SEAM.b, 0.42 if i == 2 else 0.22), 2.0)
	var by: float = c.y - half * clampf(run.el_deg() / _pitch_span_deg(), -1.0, 1.0)
	draw_circle(Vector2(x + 1.0, by), 6.0, Color(AMBER.r, AMBER.g, AMBER.b, 0.22))
	draw_circle(Vector2(x + 1.0, by), 3.4, AMBER)


## A point on the bounding square in direction `d`, so the corner fill stops exactly at the edge.
static func _to_square(d: Vector2, half: float) -> float:
	return minf(half / maxf(absf(d.x), 0.0001), half / maxf(absf(d.y), 0.0001))


## A relative bearing, as a direction on the collar: 0 is straight up (where you are looking) and
## positive is clockwise, which is starboard. The same convention a chart has.
static func _bear(deg: float) -> Vector2:
	var r := deg_to_rad(deg)
	return Vector2(sin(r), -cos(r))


## The same bearing as an angle draw_arc() understands.
static func _ang(deg: float) -> float:
	return deg_to_rad(deg) - PI * 0.5


## R5's third constant, derived rather than hardcoded (see the const block up top). Symmetric about
## level (0 deg) and sized to the larger of the two limits, so a bead at a genuine extreme reading
## still lands inside the scratch rather than running off the end.
static func _pitch_span_deg() -> float:
	return maxf(absf(SafariRun.EL_MIN), absf(SafariRun.EL_MAX))


## R1/S3's other half: WHICH WAY UP. The collar already said which way ROUND an uncaught sight is
## (azimuth, via `_bear`); it never said whether it was above or below the player, which is exactly
## the user's "I couldn't tell if I was looking up or down". This draws a small solid arrowhead
## beside a dab (or a ping): apex above the dot and pointing up for a sight above the player's own
## elevation, apex below and pointing down for one below. Screen-absolute up/down, not
## azimuth-relative - "look up" means the same thing at every heading, same convention the pitch
## scratch already uses. Distance from the dot grows with `_pitch_span_deg()` toward the far end of
## the reachable sky, so the SAME glance answers both "which way" and "how far", the same "bead on
## a scale" idiom the pitch scratch already established - no new visual language, just reused.
## `del` is the sight's elevation minus the player's own (`run.el_deg()`); `a` fades a ping's tag in
## with the ping itself rather than snapping on at full strength (0.75 for a warning, 1.0 for a live
## dab, so the two never look like the same weight of information).
func _elev_tag(dot: Vector2, tint: Color, del: float, rw: float, a: float) -> void:
	if absf(del) < 1.0:
		return   # near enough level with the player that a tag would only be noise
	var up: bool = del > 0.0
	var mag: float = clampf(absf(del) / _pitch_span_deg(), 0.0, 1.0)
	var s: float = -1.0 if up else 1.0
	var near_o: float = rw * 0.62
	var far_o: float = lerp(rw * 1.05, rw * 1.85, mag)
	var hw: float = rw * 0.30

	# THE CLIPPED CHEVRON FIX (SAFARI_FLIGHT_SPEC.md 7.5, G6 wave 2). `far_o` reached up to 1.85*rw
	# past `dot` in screen-absolute Y with nothing stopping it - and `dot` itself can sit within a
	# few px of the frame's own top or bottom edge near dead-astern (`_rose()`'s own comment: the
	# ring reaches row 1171 of 1180 there). MEASURED, 2026-09-22, a `--fake-sight=0:0 --pose=...:180:20`
	# capture with the dot pinned at the bottom of the ring: the old code drew almost the entire
	# down-pointing tag off the bottom of the canvas, a bare sliver of its dark outline surviving
	# inside the frame (`before_astern_down.png` in the report). The same dot with an UP-pointing tag
	# (`before_astern_up.png`) had the whole porthole above it and was never clipped - the defect is
	# one-sided, exactly as reported.
	#
	# Fix: shrink the WHOLE tag - `near_o`, `far_o` and `hw` together, so the triangle keeps its
	# shape - by whatever fraction of the room it actually wants the frame has to give, measured
	# from `dot` to the real edge of `size` (this Control IS the full screen: `_hull()` reads the
	# same `size.x`/`size.y` as the canvas it paints, for the same reason). No fitted constant: the
	# shrink is the exact ratio of room-available to room-wanted, a 1.0 no-op at every bearing this
	# was ever seen to render correctly, and it only bites at the extreme that broke it.
	#
	# 13.5: "the real edge of `size`" is not the real edge on a phone - the bottom ~34 device px are
	# the home indicator (`MobileUI.safe_area()`, zero on desktop). `_layout_cockpit()` already sizes
	# the DISC for a dab's own reach clearing it; this tag reaches further still at the extreme
	# elevations, so it needs the same real limit, not the literal canvas row.
	var margin: float = maxf(rw * 0.18, 3.0)   # clears the tag's own 1.6px dark outline
	var safe: Vector4 = MobileUI.safe_area()   # zero on desktop, on its own
	var room_y: float = maxf((dot.y - margin - safe.y) if up else (size.y - margin - safe.w - dot.y), 0.0)
	var room_x: float = maxf(minf(dot.x - margin - safe.x, size.x - margin - safe.z - dot.x), 0.0)
	var shrink: float = 1.0
	if far_o > room_y:
		shrink = minf(shrink, room_y / far_o)
	if hw > room_x:
		shrink = minf(shrink, room_x / hw)
	if shrink <= 0.02:
		return   # no room at all for a tag at this dot - the dab itself still shows which way round
	near_o *= shrink
	far_o *= shrink
	hw *= shrink

	var apex: Vector2 = dot + Vector2(0.0, s * far_o)
	var base_y: float = dot.y + s * near_o
	var poly := PackedVector2Array([apex, Vector2(dot.x - hw, base_y), Vector2(dot.x + hw, base_y)])
	# a dark edge first, so the tag reads over both the light hull and a bright collar dab alike
	draw_polyline(PackedVector2Array([apex, Vector2(dot.x - hw, base_y), Vector2(dot.x + hw, base_y), apex]),
		Color(0.08, 0.09, 0.15, 0.55 * a), 1.6, true)
	draw_colored_polygon(poly, Color(tint.r, tint.g, tint.b, 0.92 * a))


## The side columns' vertical gradient, sampled at a y, so the corner fill matches them.
func _hull_at(y: float, win: Rect2) -> Color:
	return HULL_MID.lerp(HULL_BOT, clampf((y - win.position.y) / maxf(win.size.y, 1.0), 0.0, 1.0))


# ================================================================== the console
func _console(win: Rect2, k: float) -> void:
	var hold: float = run.lead_hold()
	_knob(k)
	_shutter(hold, k)
	_nameplate(win, k)
	_legend(win, k)
	_flight_clock(k)


# ================================================================== R13: the flight clock
## HOW MUCH OF THE FLIGHT IS LEFT, at a glance, all the time (spec 10.3). A plate in the top-right
## corner of the lip, the mirror of the Skip button: the lip is the one strip of hull that is clear
## of the porthole AND of both thumbs, and it is where the eye already goes for "how long is this".
## It reads "Zorp  2:41", and the plate fills with a pale wash from left to right as the lane is
## flown, so the fraction is readable without the digits. It never fades; it goes with the rest of
## the console when the haul card comes up.
##
## THE BOOST (R13) IS HIDDEN (12.2, `SafariRun.BOOST_LIVE = false`) until the flight's bill is right.
## While it is hidden the clock takes the corner itself - its right edge where the boost button's
## is - instead of leaving a button-wide hole beside it (the gap F4 was asked to close). When the
## boost goes live the clock sits just left of the button again, and then its digits are LANE
## seconds: they run BOOST_X times faster while boosting and the plate turns amber, which is the
## most direct proof on screen that the boost is doing something.
func _flight_clock(k: float) -> void:
	if not run.has_method("flight_left_sec"):
		return
	var font: Font = UIStyle.ui_font()
	var br: Rect2 = run.boost_rect()
	if br.size.x < 1.0:
		return
	var left: float = run.flight_left_sec()
	var total: float = maxf(run.flight_seconds(), 1.0)
	var secs: int = int(ceil(left))
	var txt := "%s  %d:%02d" % [run.dest_name(), secs / 60, secs % 60]
	var fs: int = int(maxf(24.0 * k, 20.0))
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pad: float = 12.0 * k
	var h: float = br.size.y
	var r := Rect2(_clock_right(br, k) - tw - pad * 2.0, br.position.y, tw + pad * 2.0, h)
	var boosting: bool = run.boost_on()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(HULL_LIT.r, HULL_LIT.g, HULL_LIT.b, 0.92)
	sb.border_color = AMBER_EDGE if boosting else Color(SEAM.r, SEAM.g, SEAM.b, 0.70)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(h * 0.5))
	draw_style_box(sb, r)
	# the flown part of the lane, as a wash inside the plate
	var done: float = clampf(1.0 - left / total, 0.0, 1.0)
	if done > 0.0:
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Color(AMBER.r, AMBER.g, AMBER.b, 0.40 if boosting else 0.22)
		fsb.set_corner_radius_all(int(h * 0.5))
		draw_style_box(fsb, Rect2(r.position + Vector2(2.0, 2.0),
			Vector2(maxf((r.size.x - 4.0) * done, h - 4.0), r.size.y - 4.0)))
	var asc: float = font.get_ascent(fs)
	var desc: float = font.get_descent(fs)
	var base_y: float = r.position.y + (h + asc - desc) * 0.5
	draw_string(font, Vector2(r.position.x + pad, base_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs,
		AMBER_EDGE.darkened(0.35) if boosting else INK)


## PUBLIC, for a critic: where the flight clock is drawn this frame, in this Control's space.
func flight_clock_rect() -> Rect2:
	var br: Rect2 = run.boost_rect()
	var font: Font = UIStyle.ui_font()
	var k: float = run.ui_scale()
	var secs: int = int(ceil(run.flight_left_sec()))
	var txt := "%s  %d:%02d" % [run.dest_name(), secs / 60, secs % 60]
	var fs: int = int(maxf(24.0 * k, 20.0))
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pad: float = 12.0 * k
	return Rect2(_clock_right(br, k) - tw - pad * 2.0, br.position.y, tw + pad * 2.0, br.size.y)


## Where the clock plate's right edge goes: the boost button's own right edge while the button is
## hidden, and 10 px short of its left edge while it is shown.
func _clock_right(br: Rect2, k: float) -> float:
	if run.has_method("boost_shown") and not run.boost_shown():
		return br.end.x
	return br.position.x - 10.0 * k


## THE RANGE KNOB. The one thing kept whole from the brass spyglass, because the warmth of it was
## the part that worked: a lathed dial with a milled edge and a gold pip, sunk into the panel.
func _knob(k: float) -> void:
	var xf: Array = run.knob_xf()
	var c: Vector2 = xf[0]
	var r: float = xf[1]

	draw_circle(c + Vector2(0.0, r * 0.06), r * 1.30, Color(0.44, 0.40, 0.36, 0.16))
	draw_circle(c, r * 1.26, RECESS)
	draw_arc(c, r * 1.26, 0.0, TAU, 64, Color(SEAM.r, SEAM.g, SEAM.b, 0.60), 2.5, true)
	# the dial: warm metal, dark at the rim and lit from above
	for i in 10:
		var t := float(i) / 9.0
		draw_circle(c - Vector2(0.0, r * 0.05 * t),
			r * lerp(1.06, 0.62, t), Color("#c89a5e").lerp(Color("#f0d09a"), t))
	draw_arc(c, r * 1.04, 0.0, TAU, 64, Color("#8a6534"), 3.0, true)
	# milled edge
	for i in 28:
		var a := TAU * float(i) / 28.0 + deg_to_rad(-140.0 + 280.0 * run.focus_value()) * 0.35
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * r * 0.86, c + d * r * 1.02, Color(0.42, 0.31, 0.17, 0.40), 2.5, true)
	draw_circle(c, r * 0.42, Color("#a87f4c"))
	draw_circle(c, r * 0.36, Color("#d8b47e"))
	# the pip: where the knob IS, never where sharp would be
	var ka := deg_to_rad(-140.0 + 280.0 * run.focus_value())
	var kd := Vector2(cos(ka), sin(ka))
	draw_line(c + kd * r * 0.20, c + kd * r * 0.80, Color("#5d431f"), maxf(5.0 * k, 4.0), true)
	draw_circle(c + kd * r * 0.80, r * 0.13, GOLD)
	# the two ends of its travel, scratched into the panel. No numbers.
	for s in [-1.0, 1.0]:
		var ea := deg_to_rad(-140.0) if s < 0.0 else deg_to_rad(140.0)
		var ed := Vector2(cos(ea), sin(ea))
		draw_line(c + ed * r * 1.32, c + ed * r * 1.46, Color(SEAM.r, SEAM.g, SEAM.b, 0.55), 3.0, true)


## THE SHUTTER. Big, round, under the right thumb, amber when there is something to take. Its ring
## IS the hold meter, and the fireflies come home to it.
func _shutter(hold: float, k: float) -> void:
	var xf: Array = run.shutter_xf()
	var c: Vector2 = xf[0]
	var r: float = xf[1]
	var flash: float = run.flash_value()
	# R9: the cap is lit when a TAP WOULD TAKE A PICTURE this instant (something centred and sharp
	# enough, and film left) or while a plate is blooming under the thumb. It used to light only once
	# a passive exposure was already running, which is why it looked dead to a player whose knob was
	# never going to get there.
	var armed: bool = hold > 0.02
	if run.has_method("shutter_ready"):
		armed = run.shutter_ready() or run.shutter_blooming()
	var press: float = run.shutter_press()

	# the fireflies land in an arc over the button
	for i in run.ff_count():
		var s: float = run.ff_settle(i)
		var e2: float = s * s * (3.0 - 2.0 * s)
		var slot := _ff_slot(i, c, r)
		var wan := _ff_wander(i, c, r)
		var p: Vector2 = wan.lerp(slot, e2)
		var sd: float = run.ff_seed(i)
		var pulse: float = 0.70 + 0.30 * sin(run.run_time() * 2.3 + sd * 1.9)
		var rr: float = lerp(3.0, 8.0, e2) * (0.86 + 0.22 * pulse) * (1.0 + 1.1 * flash) * k
		var a: float = minf(1.0, lerp(0.30, 1.0, e2) * pulse * (1.0 + 0.9 * flash))
		draw_circle(p, rr * 2.6, Color(GOLD.r, GOLD.g, GOLD.b, 0.075 * a))
		draw_circle(p, rr * 1.7, Color(AMBER.r, AMBER.g, AMBER.b, 0.20 * a))
		draw_circle(p, rr, Color(1.0, 0.93, 0.76, 0.95 * a))

	# the housing, sunk into the panel
	var sink: float = r * 0.055 * press
	draw_circle(c + Vector2(0.0, r * 0.07), r * 1.30, Color(0.44, 0.40, 0.36, 0.18))
	draw_circle(c, r * 1.26, RECESS)
	draw_arc(c, r * 1.26, 0.0, TAU, 72, Color(SEAM.r, SEAM.g, SEAM.b, 0.60), 2.5, true)
	# the hold ring: fills clockwise from the top. This is the only meter in the cabin.
	draw_arc(c, r * 1.15, 0.0, TAU, 72, Color(SEAM.r, SEAM.g, SEAM.b, 0.28), maxf(6.0 * k, 5.0), true)
	if hold > 0.004:
		draw_arc(c, r * 1.15, -PI * 0.5, -PI * 0.5 + TAU * clampf(hold, 0.0, 1.0), 72,
			Color(AMBER.r, AMBER.g, AMBER.b, 0.95), maxf(6.0 * k, 5.0), true)
	# the cap
	var cc := c + Vector2(0.0, sink)
	# RESTING IS WARM, NOT DEAD. A grey cap read as a disabled button; this is an unlit brass one.
	var cap_a: Color = Color("#b8793a") if armed else Color("#8d8377")
	var cap_b: Color = Color("#ffc074") if armed else Color("#c6bcab")
	for i in 10:
		var t := float(i) / 9.0
		draw_circle(cc - Vector2(0.0, r * 0.06 * t * (1.0 - press)),
			r * lerp(1.00, 0.52, t), cap_a.lerp(cap_b, t))
	draw_arc(cc, r * 0.99, 0.0, TAU, 72,
		Color(0.36, 0.24, 0.10, 0.45) if armed else Color(SEAM.r, SEAM.g, SEAM.b, 0.55), 3.0, true)
	# the aperture glyph on the cap: six soft blades. Not a crosshair, not a camera icon.
	var blade: Color = Color(1.0, 0.96, 0.88, 0.80) if armed else Color(1.0, 1.0, 1.0, 0.55)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.26
		var d1 := Vector2(cos(a), sin(a))
		var d2 := Vector2(cos(a + TAU / 6.0), sin(a + TAU / 6.0))
		draw_line(cc + d1 * r * 0.44, cc + d2 * r * 0.44, blade, maxf(3.0 * k, 2.5), true)
	if flash > 0.002:
		draw_circle(cc, r * (1.30 + 0.30 * (1.0 - flash)), Color(1.0, 0.92, 0.72, 0.30 * flash))


## THE NAMEPLATE. What is in the glass, in words, on the LEFT PANEL over the range knob. It was
## pinned to the far left edge (away from both hands), then centred in a console that no longer
## exists; over a thumb, one glance from the glass, is the version that survives the big window.
## The right panel is deliberately left clear - that is where the film magazine goes.
func _nameplate(win: Rect2, k: float) -> void:
	var span: Array = run.nameplate_span()
	var x0: float = float(span[0])
	var w: float = maxf(float(span[1]), 150.0)
	var font: Font = UIStyle.ui_font()

	var info: Dictionary = run.glass_info()
	var title: String = str(info.get("title", ""))
	var sub: String = str(info.get("sub", ""))
	var dim: bool = bool(info.get("dim", true))
	var got: bool = bool(info.get("got", false))
	if title == "":
		title = "nothing in the glass"
		sub = ""
		dim = true

	# the plate itself, so the words sit ON something instead of floating on bare panel. Light:
	# a filled white card here reads as a pop-up over the cabin instead of a plate screwed to it.
	var y: float = win.position.y + win.size.y * 0.335
	var ph := Rect2(x0 - 6.0, y - 26.0 * k, w + 12.0, 102.0 * k)
	draw_rect(ph, Color(HULL_LIT.r, HULL_LIT.g, HULL_LIT.b, 0.17))
	draw_rect(ph, Color(SEAM.r, SEAM.g, SEAM.b, 0.22), false, 2.0)
	for sx in [ph.position.x + 9.0, ph.end.x - 9.0]:
		for sy in [ph.position.y + 9.0, ph.end.y - 9.0]:
			draw_circle(Vector2(sx, sy), maxf(2.6 * k, 2.0), Color(SEAM.r, SEAM.g, SEAM.b, 0.30))

	# WIRE round: the lane's own name, off SafariLanes, not safari_cast.gd's two-route table - which
	# answered "Home to Zorp, the Lantern Lane" for every trip in the game, including Vela's.
	var route := str((run.lane() as Dictionary).get("name", ""))
	# THE ASK IN THE GLASS (F4): when the plate names a sight somebody asked for, its top line says
	# who - "The Professor's ask" - in the cabin's amber ink, a size up from the lane name it
	# replaces for as long as that sight is the one named, with the ask's sparkle before it.
	var ask: String = str(info.get("ask", ""))
	if ask != "":
		var afs: int = _fit(font, ask, w - 30.0 * k, 19.0 * k, 12.0)
		var aw: float = font.get_string_size(ask, HORIZONTAL_ALIGNMENT_LEFT, -1, afs).x
		var ax: float = x0 + w * 0.5 - aw * 0.5 + 12.0 * k
		_sparkle(Vector2(ax - 16.0 * k, y - afs * 0.32), 9.0 * k)
		draw_string(font, Vector2(ax, y), ask, HORIZONTAL_ALIGNMENT_LEFT, -1.0, afs,
			AMBER_EDGE.darkened(0.30))
	else:
		draw_string(font, Vector2(x0, y), route, HORIZONTAL_ALIGNMENT_CENTER, w,
			_fit(font, route, w, 15.0 * k, 10.0), Color(SOFT.r, SOFT.g, SOFT.b, 0.90))
	var tc: Color = INK if not dim else Color(INK.r, INK.g, INK.b, 0.55)
	draw_string(font, Vector2(x0, y + 32.0 * k), title, HORIZONTAL_ALIGNMENT_CENTER, w,
		_fit(font, title, w, 24.0 * k, 15.0), tc)
	if sub != "":
		var sc: Color = AMBER_EDGE if not dim else SOFT
		draw_string(font, Vector2(x0, y + 58.0 * k), sub, HORIZONTAL_ALIGNMENT_CENTER, w,
			_fit(font, sub, w, 18.0 * k, 12.0), sc)
	# a plate just went in the box: one warm underline, no badge and no word "captured"
	if got:
		var uw: float = w * 0.30
		draw_line(Vector2(x0 + w * 0.5 - uw * 0.5, y + 68.0 * k),
			Vector2(x0 + w * 0.5 + uw * 0.5, y + 68.0 * k), Color(AMBER.r, AMBER.g, AMBER.b, 0.85),
			maxf(3.0 * k, 2.5), true)


## THE LONGEST SUBJECT NAME HAS TO FIT. The plate is as wide as the side column lets it be - 383 px
## on the phone, 263 on a 1280x720 desktop - and the cast writes lines up to 29 characters ("Home's
## own aurora, from above"), which clipped to "Home's own aurora, fr" the first time this was
## measured on the desktop. So the size is the biggest one that FITS, found by measuring the string
## rather than by guessing a constant, and floored so it never becomes unreadable.
static func _fit(font: Font, text: String, w: float, want: float, floor_px: float) -> int:
	var sz: float = want
	while sz > floor_px and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(sz)).x > w:
		sz -= 1.0
	return int(maxf(sz, floor_px))


# ================================================================== R6: the permanent legend
## THE CONTROL LEGEND. PERMANENT - THE 9-SECOND FADE IS DELETED. The user played twice and "didn't
## know how to take pictures"; the one line that ever said what a control did used to fade out
## before either of their flights passed nine seconds.
##
## Four words, the ceiling this round set (SAFARI_FLIGHT_SPEC.md 6.2/R6: "each labelled in one
## word"). Each sits next to what it names rather than all four in one line to read once and
## forget: "focus" over the knob, "shutter" over the shutter - both already where a thumb rests, so
## the word arrives with the control instead of off on its own. "swing" and "scope" are things you
## do TO THE GLASS, not to a separate widget, so they share the sill - the one strip of hull between
## the two side columns that touches neither thumb's rest zone.
##
## "scope" dims to a plain ink word lowered and lights amber raised, the same "resting is warm, not
## dead" idiom `_shutter()` already uses for its cap - free feedback for a control this file only
## labels; it does not own the raise/lower input itself (that is `run`'s, G1's file).
##
## MEASURED, and moved once (real 2556x1179 --ui=mobile captures, Compatibility renderer). The
## first version put "swing · scope" on the sill as one line, the way the old fading hint sat. Two
## things failed there: at a font size that cleared R6's 22 device px gate the glyph tops landed
## within a couple of px of the collar ring above them (measured: the ring-to-hull transition
## finishes at row ~1139, the sill's own text started at row ~1137), and pushing the line down for
## ring clearance ate the margin to the literal bottom edge instead. The sill is only ~34 device px
## tall once the collar ring's own bleed is subtracted - not enough room for a legible line AND
## clearance on both sides. So "swing" and "scope" moved into the side columns instead, stacked
## above "focus" and "shutter" - the same columns that already cleared the gate with room either
## side, and still one glass-gesture word per thumb.
func _legend(win: Rect2, k: float) -> void:
	var font: Font = UIStyle.ui_font()
	# MEASURED, twice. 15 UI px looked plenty big on screen but the actual glyph ink - cropped
	# tight, outline halo excluded, separated from neighbouring elements - measured only ~18 device
	# px tall, under R6's 22 px gate. 23 measured 27-30 px on both the knob and shutter columns,
	# comfortably clear; see the report for the row-by-row measurement.
	var fs: float = maxf(23.0 * k, 19.0)
	var gap: float = fs * LEGEND_STACK_GAP

	_legend_over(font, run.knob_xf(), LEGEND_FOCUS, fs, INK, 0.0)
	# R9 item 6: tap and hold now do different things, so the shutter's legend says both. The word
	# "shutter" stays (the four-word legend is a contract); the two verbs sit after it on the same
	# line in the softer ink, so it is one line and three words: "shutter  tap · hold".
	_legend_pair(font, run.shutter_xf(), LEGEND_SHUTTER, LEGEND_SHUTTER_HOW, fs)
	_legend_over(font, run.knob_xf(), LEGEND_SWING, fs, INK, gap)
	# ROUND 2 FIX (critic blocker #2, 2026-09-21): same failure mode as `_rose()` above -
	# `run.scope_raised()` did not exist yet in this scratch copy, threw on every frame, and aborted
	# `_legend()` before the "scope" word below was ever drawn - so one of R6's four required control
	# labels silently never appeared in any frame. Guarded with `has_method()`; while G1's real raise
	# state is not wired, "scope" falls back to its resting/lowered colour (INK) rather than being
	# skipped, matching "lowered is the default" (SAFARI_FLIGHT_SPEC.md 6.2). Dead code once
	# `scope_raised()` ships on SafariRun.
	var scope_col: Color = AMBER_EDGE if (run.has_method("scope_raised") and run.scope_raised()) else INK
	_legend_over(font, run.shutter_xf(), LEGEND_SCOPE, fs, scope_col, gap)


## One word, centred, clear of a control's outer housing - `xf` is a `knob_xf()`/`shutter_xf()` pair
## [centre, radius]. `extra` stacks a second word further up the same column (0.0 for the one right
## over the control). Measured and placed by hand rather than handed to `draw_string`'s own CENTER
## alignment: that treats `pos` as the LEFT edge of the box, not the point to centre ON, and the
## first render of this centred "focus" over the knob and clipped "shutter" clean off the right edge
## of a real 2556x1179 capture - see the report.
func _legend_over(font: Font, xf: Array, word: String, fs: float, col: Color, extra: float) -> void:
	var c: Vector2 = xf[0]
	var r: float = xf[1]
	var fsi := int(fs)
	var w: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsi).x
	_legend_draw(font, Vector2(c.x - w * 0.5, c.y - r * 1.42 - extra), word, fs, col)


## A control's word and, after it, how to use it in the softer ink - centred as ONE line on the
## control, the same place `_legend_over` puts a single word.
func _legend_pair(font: Font, xf: Array, word: String, how: String, fs: float) -> void:
	var c: Vector2 = xf[0]
	var r: float = xf[1]
	var fsi := int(fs)
	var sep := "  "
	var w1: float = font.get_string_size(word + sep, HORIZONTAL_ALIGNMENT_LEFT, -1, fsi).x
	var w2: float = font.get_string_size(how, HORIZONTAL_ALIGNMENT_LEFT, -1, fsi).x
	var x0: float = c.x - (w1 + w2) * 0.5
	var y: float = c.y - r * 1.42
	_legend_draw(font, Vector2(x0, y), word, fs, INK)
	_legend_draw(font, Vector2(x0 + w1, y), how, fs, SOFT.darkened(0.25))


## PUBLIC (SAFARI_FLIGHT_SPEC.md 7.3, G6 wave 2). The highest y this Control's own space reaches
## for the two-word legend stack over `xf` (`knob_xf()`/`shutter_xf()`) - the exact `c.y - r*1.42 -
## gap` `_legend_over()` places its stacked ("swing"/"scope") word at, so `safari_run.gd::
## _layout_cockpit()` can keep the film grid clear of it without a second copy of this arithmetic
## drifting out of sync the way the port's `0.150`/`0.105` already had to be flagged once, above.
## MEASURED WHY IT NEEDS ITS OWN MARGIN: `draw_string`'s `pos` is the text BASELINE, not its visual
## top, so this backs off by a full `fs` past the baseline - more than the real glyph ascent, on
## purpose, so the clearance survives hinting or a future font swap rather than being tuned to the
## current one's metrics.
func legend_clear_y(xf: Array) -> float:
	var c: Vector2 = xf[0]
	var r: float = xf[1]
	var k: float = run.ui_scale()
	var fs: float = maxf(23.0 * k, 19.0)
	var gap: float = fs * LEGEND_STACK_GAP
	return c.y - r * 1.42 - gap - fs


## A light halo first, then the ink word on top - the same "outline halo keeps a label readable over
## anything" idiom `touch_button.gd` already uses, because the legend sits on a hull that runs from
## lit lamp-pool to shadowed corner and a flat colour would vanish into part of it. Always
## left-aligned at an already-measured `pos` - see `_legend_over()` for why this stopped trusting
## `draw_string`'s own CENTER alignment.
func _legend_draw(font: Font, pos: Vector2, text: String, fs: float, col: Color) -> void:
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(fs), 5,
		Color(HULL_LIT.r, HULL_LIT.g, HULL_LIT.b, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(fs), col)


# ================================================================== bits
## The fireflies settle into an arc OVER the shutter, and they stay on the panel: the wander is
## kept near the button so they are never confused with something in the sky.
func _ff_slot(i: int, c: Vector2, r: float) -> Vector2:
	var n: float = maxf(float(run.ff_count()), 1.0)
	var a: float = deg_to_rad(-166.0 + 152.0 * (float(i) + 0.5) / n)
	return c + Vector2(cos(a), sin(a)) * (r * 1.38)


func _ff_wander(i: int, c: Vector2, r: float) -> Vector2:
	var s: float = run.ff_seed(i)
	var ph: float = run.run_time() * (0.27 + 0.045 * float(i)) + s
	var wr: float = r * (1.30 + 0.30 * sin(ph * 0.63 + s))
	return c + Vector2(cos(ph) * wr * 1.10, sin(ph * 0.81 + s * 0.7) * wr * 0.34 - r * 0.42)


## A small round port in a side panel: navy glass, a handful of stars streaming past, a cream rim
## with bolts. `side` is +1 on the left panel and -1 on the right, so the stars stream the same way
## relative to the nose in both of them.
func _side_port(c: Vector2, r: float, side: float) -> void:
	var tt: float = run.run_time()
	draw_circle(c + Vector2(0.0, r * 0.06), r * 1.22, Color(0.30, 0.28, 0.26, 0.16))
	draw_circle(c, r * 1.14, HULL_LIT.lerp(HULL_MID, 0.35))
	draw_arc(c, r * 1.14, 0.0, TAU, 64, Color(SEAM.r, SEAM.g, SEAM.b, 0.55), 2.5, true)
	draw_circle(c, r, Color("#151a2c"))
	for i in 9:
		var sd: float = float(i) * 2.73 + 0.41
		var u: float = fposmod(sd * 0.37 + tt * (0.055 + 0.030 * fmod(sd, 1.0)) * side, 1.0)
		var sx: float = (u * 2.0 - 1.0) * r * 0.94
		var sy: float = (fmod(sd * 1.61, 1.0) * 2.0 - 1.0) * r * 0.80
		if sx * sx + sy * sy > r * r * 0.86:
			continue
		var br: float = 0.45 + 0.55 * fmod(sd * 2.13, 1.0)
		draw_circle(c + Vector2(sx, sy), maxf(r * 0.030 * br, 1.0),
			Color(0.90, 0.92, 1.0, 0.55 + 0.45 * br))
	# the recess it is set into, and the lamp catching the bottom of the rim
	draw_arc(c, r - 1.5, 0.0, TAU, 64, Color(0.08, 0.09, 0.15, 0.40), 4.0, true)
	draw_arc(c, r + 2.0, 0.0, TAU, 64, Color(SEAM.r, SEAM.g, SEAM.b, 0.70), 2.5, true)
	draw_arc(c, r * 1.07, PI * 0.14, PI * 0.86, 48, Color(1.0, 0.94, 0.84, 0.40), 2.5, true)
	var bb: float = maxf(r * 0.070, 2.0)
	for i in 6:
		var a: float = TAU * (float(i) + 0.5) / 6.0
		var bp: Vector2 = c + Vector2(cos(a), sin(a)) * (r * 1.07)
		draw_circle(bp, bb, Color(SEAM.r, SEAM.g, SEAM.b, 0.32))
		draw_circle(bp - Vector2(0.0, bb * 0.35), bb * 0.55, Color(1.0, 1.0, 1.0, 0.40))


func _vgrad(r: Rect2, a: Color, b: Color, steps: int = 14) -> void:
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y * t0,
			r.size.x, r.size.y * (t1 - t0) + 1.0), a.lerp(b, (t0 + t1) * 0.5))
