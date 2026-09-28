class_name SafariCast
extends RefCounted
## SPIKE (2026-09-21, scratch only). WHAT IS OUT THERE ON A FLIGHT, AND WHEN.
##
## Two rounds of standing-still telescope spikes measured the same thing: 99 seconds of doing in an
## 11.6-minute night. The user read it in the frames - "more like a mini-game than a core game
## loop... I'd keep trying until I get a perfect shot and be done in 3-4 minutes" - and asked for
## the opposite shape: "more like a safari or journey on rails where you have to move your scope
## around as you are travelling... and you have to move around to get the right shot before it
## passes you by".
##
## So this file is the SAFARI PARK. The flight between two worlds stops being a cutscene with a
## Skip button and becomes the run. This is the casting sheet for it.
##
## THE SHAPE OF A RUN. `t` below is seconds since the scope comes up (the pad drop is before t=0).
## Route A is 56 s of sky. Every subject has:
##
##   A WINDOW  `t_start`..`t_end`. Outside it the thing is not there. You cannot come back.
##   A PATH    az/el sweep across that window, eased so it drifts slowly while it is far ahead and
##             whips past when it is abeam. That is why a late swing misses: the thing is moving.
##   A RANGE   `focus` 0..1. The knob is a RANGE dial, not a wobble to chase: ice chunks are close,
##             a moon's rim is at infinity. It is CONSTANT per subject, so it is learnable in one
##             run, which is the whole reason the standing-still scope's drifting focus is gone.
##             With 45-60 s of sky and six things in it there is no room for a puzzle per subject.
##   A HOLD    1.0-3.2 s, from `hold_sec`. The standing scope needed 20 s of exposure. Here a shot
##             is QUICK: the difficulty is being pointed at the right thing at the right second.
##   MOMENTS   like a wildlife safari, the thing is worth more caught DOING something. A moment is
##             a sub-window with a multiplier and its own line of words. Same subject, different
##             moments; the journal keeps the best one.
##
## THE OVERLAP IS ON PURPOSE. `pod_driftlings` (t 23.0-33.0, az +62..+84) and `ice_frozen`
## (t 24.5-33.5, az -70..-88) live at the same time on OPPOSITE sides of the lane. MEASURED in the
## autopilot run: at t=30.5 they are 159 deg apart and the scope slews SLEW_MAX_DEG 55 deg/s, so
## crossing is 2.9 s of swinging and the ice then needs 2.2 s of hold inside a window that shuts at
## t=33.5. The overlap is 8.5 s wide and it does not fit. You can have one properly, or fumble at
## both. That is the user's "before it passes you by", made into one decision.
##
## HOUR GATES. `hours` is [from, to) on the 24 h clock, wrapping. The lane is the same lane; the
## sky on it is not. At night you get the aurora standing on the planet you just left; by day you
## get its dust veil lit edge-on instead. And between 02:00 and 05:00 - and only then - the green
## moon is out, BEHIND you, over your shoulder toward home. Nobody tells you that except Bolt, which
## is the user's example, verbatim.
##
## WIRE (2026-09-21): the green moon is no longer written down in this file. It is one sight, owned
## by sky_hints.gd, and it only joins this lane once Bolt has actually said so - see `hint_entries`.
## Everything a player READS about the sky lives in sky_hints.gd now; this file is pure geometry.
##
## ROUTES. Two are cast. Only `home_zorp` is flyable in the spike; `bolt_fen` exists to prove the
## cast really is per-route data and not one hard-coded list - different subjects, different lane,
## different hour gates. The spike does NOT fly it, and says so in the report.
##
## ALL STATIC. No state, no autoload, nothing to save.

# ------------------------------------------------------------------ kinds
## These are the six shapes safari_eyepiece.gdshader knows how to draw. A new subject is new DATA,
## not a new shader branch, unless it is genuinely a new SHAPE.
const K_COMET := 0
const K_POD := 1
const K_ICE := 2
const K_DERELICT := 3
const K_MOONRIM := 4
const K_LIMB := 5

const KIND_NAMES := ["Comet", "Drift pod", "Ice", "Derelict", "Moon rim", "World below"]

## rarity 1..3, the same ladder the standing scope uses (sky_print.gd prices the copy on it).
const RARITY_NAMES := ["", "Common", "Uncommon", "Rare"]

## Half the glass's field of view in degrees. A subject scores as centred inside CENTRE_R of it.
## 7.0 deg against a 70 deg naked-eye camera is a 10x glass, which is why the smudge you see with
## your own eyes has to be found before it can be held.
const FIELD_HALF_DEG := 7.0


# ------------------------------------------------------------------ route A: home -> zorp
## THE LANTERN LANE. The first hop of the game, and the one the spike flies.
const CAST_HOME_ZORP: Array = [
	{
		"id": "limb_home_aur", "kind": K_LIMB, "rarity": 1, "hold_sec": 1.2,
		"title": "Home's own aurora, from above",
		"blurb": "You have never seen your planet's lights from outside.",
		"hours": [18.0, 6.0], "focus": 0.18, "scale": 1.35,
		"t_start": 3.0, "t_end": 16.0,
		"az0": 8.0, "az1": -34.0, "el0": -22.0, "el1": -41.0,
		"tint_a": "#6fd8a8", "tint_b": "#a87cf2",
		"moments": [{"t0": 7.5, "t1": 10.5, "mult": 1.5, "line": "the curtain folds over itself"}],
	},
	{
		"id": "limb_home_veil", "kind": K_LIMB, "rarity": 1, "hold_sec": 1.2,
		"title": "Home's dust veil, lit edge-on",
		"blurb": "Daylight through the thin air, seen from the side.",
		"hours": [6.0, 18.0], "focus": 0.18, "scale": 1.35,
		"t_start": 3.0, "t_end": 16.0,
		"az0": 8.0, "az1": -34.0, "el0": -22.0, "el1": -41.0,
		"tint_a": "#ffcf96", "tint_b": "#ef85bc",
		"moments": [{"t0": 7.0, "t1": 10.0, "mult": 1.5, "line": "the veil flares as you cross it"}],
	},
	{
		"id": "com_thistle", "kind": K_COMET, "rarity": 3, "hold_sec": 3.0,
		"title": "Comet Thistle crosses the lane",
		"blurb": "Straight across your bow, and gone.",
		"hours": [0.0, 24.0], "focus": 0.92, "scale": 1.00,
		"t_start": 9.0, "t_end": 19.0,
		"az0": -44.0, "az1": 30.0, "el0": 26.0, "el1": 17.0,
		"tint_a": "#8fd0ff", "tint_b": "#f0c78a",
		"moments": [{"t0": 13.0, "t1": 16.0, "mult": 1.8, "line": "the tail splits in two"}],
	},
	{
		"id": "pod_driftlings", "kind": K_POD, "rarity": 2, "hold_sec": 2.4,
		"title": "A pod of driftlings",
		"blurb": "Five of them, riding the lane the way you are.",
		"hours": [0.0, 24.0], "focus": 0.55, "scale": 1.10,
		"t_start": 23.0, "t_end": 33.0,
		"az0": 62.0, "az1": 84.0, "el0": 6.0, "el1": -3.0,
		"tint_a": "#9be8d0", "tint_b": "#cfe0ff",
		"moments": [
			{"t0": 27.0, "t1": 30.0, "mult": 2.0, "line": "one turns and looks back at you"},
			{"t0": 31.2, "t1": 32.6, "mult": 1.3, "line": "the pod closes up tight"},
		],
	},
	{
		"id": "ice_frozen", "kind": K_ICE, "rarity": 2, "hold_sec": 2.2,
		"title": "Ice, with something inside it",
		"blurb": "Chunks off an old tail. One of them is not empty.",
		"hours": [0.0, 24.0], "focus": 0.40, "scale": 0.95,
		"t_start": 24.5, "t_end": 33.5,
		"az0": -70.0, "az1": -88.0, "el0": -4.0, "el1": 9.0,
		"tint_a": "#cfe6f2", "tint_b": "#8fb6ff",
		"moments": [{"t0": 28.0, "t1": 31.0, "mult": 1.7, "line": "the sun lights what is inside"}],
	},
	## THE GREEN MOON IS NOT HERE ANY MORE (WIRE, 2026-09-21). It used to be a second, private copy
	## of the sight sky_hints.gd already owned: two ids, two titles, two windows, two green moons. It
	## is now ONE thing, defined once in SkyHints.HINTS["hint_bolt_moon"], and it is put on this lane
	## at run time by `_hint_entries` below - only after Bolt has actually told you about it.
	{
		"id": "der_kettle", "kind": K_DERELICT, "rarity": 3, "hold_sec": 3.2,
		"title": "The derelict Kettle",
		"blurb": "Someone else was stranded out here first.",
		"hours": [0.0, 24.0], "focus": 0.70, "scale": 1.05,
		"t_start": 36.0, "t_end": 46.0,
		"az0": -12.0, "az1": -31.0, "el0": -6.0, "el1": -15.0,
		"tint_a": "#c8b79a", "tint_b": "#ffd27a",
		"moments": [{"t0": 40.0, "t1": 43.0, "mult": 1.9, "line": "her lamp is still blinking"}],
	},
	{
		"id": "moon_zorp_rim", "kind": K_MOONRIM, "rarity": 1, "hold_sec": 1.4,
		"title": "First light on Zorp's moon",
		"blurb": "You arrive with the morning. So does it.",
		"hours": [0.0, 24.0], "focus": 1.00, "scale": 1.20,
		"t_start": 44.0, "t_end": 54.0,
		"az0": 20.0, "az1": 5.0, "el0": 12.0, "el1": 17.0,
		"tint_a": "#f2e2c4", "tint_b": "#b9c4d8",
		"moments": [{"t0": 48.0, "t1": 52.0, "mult": 1.4, "line": "the rim catches fire"}],
	},
]

# ------------------------------------------------------------------ route B: bolt -> fen
## THE CHALK RUN. Cast only - the spike does not fly it. It exists so "the cast changes with the
## route" is a measurable claim and not a promise: different subjects, a lane that runs INSIDE a
## ring system, and a gate that only opens in Fen's long dusk.
const CAST_BOLT_FEN: Array = [
	{
		"id": "ring_gap", "kind": K_ICE, "rarity": 1, "hold_sec": 1.3,
		"title": "Through the gap in Bolt's ring",
		"blurb": "Ice the size of houses, going the other way.",
		"hours": [0.0, 24.0], "focus": 0.25, "scale": 1.40,
		"t_start": 2.0, "t_end": 13.0,
		"az0": -20.0, "az1": 18.0, "el0": 4.0, "el1": -6.0,
		"tint_a": "#dfe6f2", "tint_b": "#cfbb96",
		"moments": [{"t0": 6.0, "t1": 9.0, "mult": 1.6, "line": "one tumbles end over end"}],
	},
	{
		"id": "shepherd", "kind": K_MOONRIM, "rarity": 2, "hold_sec": 2.0,
		"title": "The shepherd moon in the gap",
		"blurb": "A small grey thing keeping the gap open.",
		"hours": [0.0, 24.0], "focus": 0.88, "scale": 0.85,
		"t_start": 10.0, "t_end": 20.0,
		"az0": 44.0, "az1": 66.0, "el0": 9.0, "el1": 3.0,
		"tint_a": "#c9ccd6", "tint_b": "#eef1f7",
		"moments": [{"t0": 13.5, "t1": 16.5, "mult": 1.7, "line": "ice piles up against its edge"}],
	},
	{
		"id": "pod_kite", "kind": K_POD, "rarity": 3, "hold_sec": 2.8,
		"title": "Kites feeding on the ring",
		"blurb": "Flat, wide, and they only come for the ice.",
		"hours": [0.0, 24.0], "focus": 0.50, "scale": 1.15,
		"t_start": 14.0, "t_end": 24.0,
		"az0": -58.0, "az1": -92.0, "el0": -2.0, "el1": 10.0,
		"tint_a": "#ef85bc", "tint_b": "#ffcf96",
		"moments": [{"t0": 18.0, "t1": 21.0, "mult": 2.1, "line": "one folds its wing right past you"}],
	},
	{
		"id": "der_anvil", "kind": K_DERELICT, "rarity": 2, "hold_sec": 2.4,
		"title": "Bolt's old lifter, the Anvil",
		"blurb": "He will not talk about why it is still up there.",
		"hours": [0.0, 24.0], "focus": 0.62, "scale": 1.00,
		"t_start": 26.0, "t_end": 36.0,
		"az0": 14.0, "az1": 34.0, "el0": -12.0, "el1": -20.0,
		"tint_a": "#b8a37f", "tint_b": "#ffd27a",
		"moments": [{"t0": 30.0, "t1": 33.0, "mult": 1.8, "line": "the hold doors swing open"}],
	},
	{
		"id": "com_marrow", "kind": K_COMET, "rarity": 3, "hold_sec": 3.0,
		"title": "Comet Marrow, running ahead",
		"blurb": "Same direction as you, and faster.",
		"hours": [0.0, 24.0], "focus": 0.96, "scale": 0.95,
		"t_start": 33.0, "t_end": 44.0,
		"az0": -8.0, "az1": 4.0, "el0": 30.0, "el1": 26.0,
		"tint_a": "#f0c78a", "tint_b": "#8fd0ff",
		"moments": [{"t0": 37.0, "t1": 40.0, "mult": 1.9, "line": "the dust tail curls right over"}],
	},
	{
		"id": "limb_fen_dusk", "kind": K_LIMB, "rarity": 2, "hold_sec": 1.6,
		"title": "Fen's long dusk from above",
		"blurb": "The sun never climbs, so the shadow never ends.",
		"hours": [15.0, 22.0], "focus": 0.20, "scale": 1.45,
		"t_start": 42.0, "t_end": 54.0,
		"az0": -4.0, "az1": 16.0, "el0": -30.0, "el1": -44.0,
		"tint_a": "#ef85bc", "tint_b": "#ffcf96",
		"moments": [{"t0": 46.0, "t1": 50.0, "mult": 1.6, "line": "the terminator crawls over a sea"}],
	},
	{
		"id": "limb_fen_night", "kind": K_LIMB, "rarity": 1, "hold_sec": 1.4,
		"title": "Fen's night side, lamps on",
		"blurb": "Every tower Fen ever lit, in one line.",
		"hours": [22.0, 15.0], "focus": 0.20, "scale": 1.45,
		"t_start": 42.0, "t_end": 54.0,
		"az0": -4.0, "az1": 16.0, "el0": -30.0, "el1": -44.0,
		"tint_a": "#ffd27a", "tint_b": "#a87cf2",
		"moments": [{"t0": 45.0, "t1": 49.0, "mult": 1.4, "line": "a whole coast lights at once"}],
	},
]

const ROUTES := {
	"home_zorp": {
		"from": "home", "to": "zorp", "name": "Home to Zorp, the Lantern Lane",
		"seconds": 56.0, "cast": "home_zorp", "flyable": true,
	},
	"bolt_fen": {
		"from": "bolt", "to": "fen", "name": "Bolt to Fen, the Chalk Run",
		"seconds": 58.0, "cast": "bolt_fen", "flyable": false,
	},
}


# ------------------------------------------------------------- neighbour hints (WIRE: not here)
## THIS FILE NO LONGER HOLDS A SINGLE LINE OF DIALOGUE. It used to keep its own HINTS array, six
## strings, alongside sky_hints.gd's five — two hint systems, two voices for Bolt, and the green
## moon written out twice. sky_hints.gd is the one owner now: it is what conversation.gd rolls
## against and what the journal shows on a "heard about, not seen" page, so it is the copy that was
## already wired to the player. These two functions are thin forwards, kept so callers do not care.
##
## The two halves, for the reader:
##   SkyHints.LANE_TIPS   ungated flavour about a subject this file already casts.
##   SkyHints.HINTS       a rare sight that DOES NOT EXIST until a neighbour mentions it. Where it
##                        sits on the lane is this file's business (HINT_LANE, below); what it is,
##                        who says so, and when its window opens is SkyHints'.
static func hints_for(route_id: String, known: Array = []) -> Array:
	return SkyHints.tips_for_route(route_id, known)


## Kept for the run's report. Measures every line in SkyHints, hints and tips both.
static func hint_lines_ok() -> bool:
	return SkyHints.lines_ok()


# ------------------------------------------------------------------ where a hint sits on the lane
## A hint's SIGHT belongs to sky_hints.gd. Its PATH belongs here, because a path is lane geometry —
## the same az/el sweep, hold and moment every other subject on this sheet has, in the same units.
## Keyed by SkyHints hint id. A hint with no entry here simply cannot be caught in flight (it is
## then a telescope sight), which is why this is data and not a fallback.
const HINT_LANE := {
	"hint_bolt_moon": {
		"kind": K_MOONRIM, "hold_sec": 2.6, "focus": 0.95, "scale": 1.15,
		"t_start": 30.0, "t_end": 38.5,
		"az0": -150.0, "az1": -172.0, "el0": 30.0, "el1": 23.0,
		"blurb": "Bolt was right. It only does this before dawn.",
		"moments": [{"t0": 33.0, "t1": 36.0, "mult": 2.2, "line": "it goes green as it clears the dust"}],
	},
	"hint_fen_shadow": {
		"kind": K_LIMB, "hold_sec": 2.2, "focus": 0.30, "scale": 1.25,
		"t_start": 18.0, "t_end": 27.0,
		"az0": 40.0, "az1": 74.0, "el0": 22.0, "el1": 11.0,
		"blurb": "Not on any chart. It moves like nothing else does.",
		"moments": [{"t0": 21.0, "t1": 24.0, "mult": 2.0, "line": "the second shadow crosses the first"}],
	},
	"hint_grig_streak": {
		"kind": K_COMET, "hold_sec": 3.0, "focus": 0.90, "scale": 0.95,
		"t_start": 12.0, "t_end": 22.0,
		"az0": -55.0, "az1": -18.0, "el0": 15.0, "el1": 24.0,
		"blurb": "One long streak, then nothing. Grig counted nine.",
		"moments": [{"t0": 16.0, "t1": 19.0, "mult": 1.9, "line": "it breaks in half as it falls"}],
	},
	"hint_vela_wink": {
		"kind": K_DERELICT, "hold_sec": 2.8, "focus": 0.72, "scale": 0.90,
		"t_start": 33.0, "t_end": 42.0,
		"az0": 100.0, "az1": 126.0, "el0": 26.0, "el1": 18.0,
		"blurb": "One flash, dish four only. Vela has listened since.",
		"moments": [{"t0": 36.0, "t1": 39.0, "mult": 2.1, "line": "it winks once, right at you"}],
	},
	"hint_zorp_spark": {
		"kind": K_ICE, "hold_sec": 2.0, "focus": 0.45, "scale": 0.85,
		"t_start": 8.0, "t_end": 17.0,
		"az0": 65.0, "az1": 92.0, "el0": 18.0, "el1": 8.0,
		"blurb": "A violet spark, gone before an antenna can tingle.",
		"moments": [{"t0": 11.0, "t1": 14.0, "mult": 2.2, "line": "the spark splits into three"}],
	},
}


## The hint sights that are LIVE on this route, this day, this hour, as ordinary cast entries.
## Everything a subject needs is merged from the two owners and nothing is duplicated:
##   from SkyHints   id, title, rarity, tints  (and whether it is live at all)
##   from HINT_LANE  the path, the hold, the range dial, the moment
## `day` < 0 means "do not ask" — the hour-only callers (the cast report, review_measure.gd) get the
## static sheet exactly as before.
static func hint_entries(route_id: String, hour: float, day: int) -> Array:
	if day < 0:
		return []
	var r := route(route_id)
	var w: Dictionary = SkyHints.active_window_for_route(
		str(r.get("from", "")), str(r.get("to", "")), day)
	if w.is_empty():
		return []
	var win: Dictionary = w.get("window", {})
	if not hour_in(float(win.get("hour_start", 0.0)), float(win.get("hour_end", 24.0)), hour):
		return []
	var lane: Dictionary = HINT_LANE.get(str(w.get("hint_id", "")), {})
	if lane.is_empty():
		return []
	var subj: Dictionary = w.get("subject", {})
	var e: Dictionary = lane.duplicate(true)
	e["id"] = str(subj.get("id", ""))
	e["title"] = str(subj.get("title", "Something rare"))
	e["rarity"] = int(subj.get("rarity", 3))
	e["tint_a"] = str(subj.get("tint_a", "#ffffff"))
	e["tint_b"] = str(subj.get("tint_b", "#ffffff"))
	e["hours"] = [float(win.get("hour_start", 0.0)), float(win.get("hour_end", 24.0))]
	e["hint_id"] = str(w.get("hint_id", ""))
	return [e]


# ------------------------------------------------------------------ casting
static func route(route_id: String) -> Dictionary:
	return ROUTES.get(route_id, ROUTES["home_zorp"])


static func _cast_table(key: String) -> Array:
	if key == "bolt_fen":
		return CAST_BOLT_FEN
	return CAST_HOME_ZORP


## Does this hour fall inside [from, to)? Wraps over midnight.
static func hour_in(from_h: float, to_h: float, h: float) -> bool:
	if is_equal_approx(from_h, 0.0) and is_equal_approx(to_h, 24.0):
		return true
	var x := fposmod(h, 24.0)
	if from_h <= to_h:
		return x >= from_h and x < to_h
	return x >= from_h or x < to_h


## THE SKY YOU ACTUALLY GET. Route plus hour plus DAY in, cast list out, sorted by when it opens.
## The day is what lets a heard hint's sight join the lane (see `hint_entries`); pass -1 and you get
## the static sheet alone, which is what the cast report and the reviewer's probe want.
static func cast_for(route_id: String, hour: float, day: int = -1) -> Array:
	var tbl := _cast_table(str(route(route_id).get("cast", "home_zorp")))
	var out: Array = []
	for e in tbl:
		var hrs: Array = e.get("hours", [0.0, 24.0])
		if hour_in(float(hrs[0]), float(hrs[1]), hour):
			out.append(e)
	out.append_array(hint_entries(route_id, hour, day))
	out.sort_custom(func(a, b): return float(a["t_start"]) < float(b["t_start"]))
	return out


## Where a subject is, in degrees, at run time `t`. Eased: slow while it is still far ahead of you,
## quick as it comes abeam. That is the parallax of flying past something, and it is what makes a
## late swing genuinely too late instead of merely inelegant.
static func pos_at(e: Dictionary, t: float) -> Vector2:
	var t0 := float(e["t_start"])
	var t1 := float(e["t_end"])
	var u := clampf((t - t0) / maxf(t1 - t0, 0.001), 0.0, 1.0)
	# smootherstep, weighted late: u^2 * (3 - 2u) would be symmetric; this leans the speed into the
	# second half so the thing is hardest to hold just before it leaves.
	var w: float = u * u * (3.0 - 2.0 * u)
	w = lerp(u, w, 0.55) * 0.5 + (u * u * u) * 0.5
	return Vector2(
		lerp(float(e["az0"]), float(e["az1"]), w),
		lerp(float(e["el0"]), float(e["el1"]), w))


static func is_up(e: Dictionary, t: float) -> bool:
	return t >= float(e["t_start"]) and t <= float(e["t_end"])


## The moment running right now, or {}. Moments never overlap inside one subject.
static func moment_at(e: Dictionary, t: float) -> Dictionary:
	for m in e.get("moments", []):
		if t >= float(m["t0"]) and t <= float(m["t1"]):
			return m
	return {}


## 0..1: how deep into a moment we are, for the shader to open the thing up and close it again.
static func moment_strength(e: Dictionary, t: float) -> float:
	var m := moment_at(e, t)
	if m.is_empty():
		return 0.0
	var t0 := float(m["t0"])
	var t1 := float(m["t1"])
	var u := clampf((t - t0) / maxf(t1 - t0, 0.001), 0.0, 1.0)
	return sin(u * PI)


static func kind_name(k: int) -> String:
	return KIND_NAMES[clampi(k, 0, KIND_NAMES.size() - 1)]


static func rarity_name(r: int) -> String:
	return RARITY_NAMES[clampi(r, 1, 3)]


## What a shot is worth. rarity x how well you held it x the moment you caught it in. No fitted
## constants: the moment multiplier is the data's, and holding is 0..1.
static func value_of(e: Dictionary, hold_quality: float, moment_mult: float) -> float:
	return float(e["rarity"]) * clampf(hold_quality, 0.0, 1.0) * maxf(moment_mult, 1.0)


## The overlap in this cast, as [id_a, id_b, seconds]. Used by the report to prove the forced
## choice is real, and by nothing in the game.
static func overlaps(cast: Array) -> Array:
	var out: Array = []
	for i in cast.size():
		for j in range(i + 1, cast.size()):
			var a: Dictionary = cast[i]
			var b: Dictionary = cast[j]
			var lo: float = maxf(float(a["t_start"]), float(b["t_start"]))
			var hi: float = minf(float(a["t_end"]), float(b["t_end"]))
			if hi - lo > 0.5:
				out.append([str(a["id"]), str(b["id"]), hi - lo,
					absf(float(a["az0"]) - float(b["az0"]))])
	return out
