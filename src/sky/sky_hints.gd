class_name SkyHints
extends RefCounted
## SPIKE (2026-09-21, scratch only, label "hints"). THE NEIGHBOURS KNOW THINGS.
##
## The user's own pitch: "The neighbors might give you hints at rare sightings that they notice from
## their planets (e.g. Bolt might say he thinks he saw a green moon in the direction of your home
## planet, but he can't remember when)." Built on top of the round-2 journal (sky_journal.gd) and
## alongside the SAFARI builder's flight-as-the-game rework, without touching either safari_run.gd or
## the flight scene — the hand-off is this file's public API, below.
##
## WHAT A HINT IS. A neighbour, in their own voice (NpcData's per-character tone), mentions a rare
## sight they think they saw — a DIRECTION or a ROUTE, never a time ("toward your home planet", not
## "at 22:40"). Five hints ship here, one per world neighbour (Bolt, Fen, Grig, Vela, Zorp), each
## pointing at a different rare thing, on a different route.
##
## HEARING a hint (`maybe_hint_line`) does two things at once:
##   1. It is a line of dialogue for that neighbour to say (conversation.gd's small-talk branch).
##   2. It MAKES THE THING REAL: `mark_heard` registers the sight with SkyJournal as a page marked
##      "heard about, not seen" — what you were told, and who told you — and from that moment on,
##      `active_window_for_route` starts reporting it as live on its route. Unheard, a hint's sight
##      never appears at all: this is deliberate, so hearing feels like unlocking something, not
##      decoration on a system that was already running.
## Missing it is not a dead end: the hint is not consumed. `maybe_hint_line` keeps offering it (at
## HINT_CHANCE per talk) until the sight is actually caught — "ask the neighbour" always works.
## Once caught, the SAME function gives the neighbour a one-time reaction line instead (`catch_line`),
## then goes quiet for that hint.
##
## THE HAND-OFF (for the SAFARI builder's flight/route reader — safari_run.gd, not owned here):
##   SkyHints.active_window_for_route(from_id, to_id, day) -> Dictionary, or {} if nothing is live:
##       {hint_id, subject_id, route: [from_id, to_id], window: {hour_start, hour_end}, subject: {...}}
##   `subject` is shaped EXACTLY like a SkyEvents entry (id/title/kind/world/rarity/tint_a/tint_b/
##   az_deg/elev_deg/where/blurb) — it is a valid argument to SkyWatch.start_watch(subject) as-is, and
##   to SkyPrint.make(subject, sharpness, on_world, day, hour). Catching it is therefore just: when a
##   window is live, let the player aim at it same as any forecast sight, and let SkyWatch's own
##   print_made signal do the rest — SkyJournal already listens to that signal directly, so the page
##   fills itself, no further call into this file needed.
##
## STATE SURVIVES A RELOAD (WIRE, 2026-09-21 — it did not before). `_heard` / `_thanked` are still
## `static var`s, but they are mirrored into `GameState.flags` (F_HEARD / F_THANKED), the same plain
## Dictionary PrintBag already saves through. Hearing about the green moon is the switch that makes
## the sight exist at all, so forgetting it on reload deleted a sight the player had been told about.
## The preview IMAGE a print holds is still in-memory only (sky_journal.gd's header) — different
## thing, still true.
##
## ONE HINT SYSTEM (WIRE). Every string a player reads about a rare sight or a lane is in THIS file:
## the five gated HINTS below, and the five LANE_TIPS that moved here out of safari_cast.gd's private
## copy. `lines_ok()` measures all of them against the 60-character budget.
##
## Public API:
##   HINTS                                        the five hint definitions, read-only
##   for_npc(npc_id) -> Dictionary                 {} if this npc has no hint
##   maybe_hint_line(npc_id, rng) -> String         "" most talks; the hint line, or a catch reaction
##   is_heard(hint_id) -> bool
##   active_window_for_route(from_id, to_id, day) -> Dictionary   the SAFARI hand-off, see above
##   subject_for(hint_id) -> Dictionary
##   tips_for_route(route_id) -> Array              the small, ungated lane tips (safari_cast.gd)
##   all_lines() / lines_ok() / longest_line()      the 60-character budget, measured not claimed
##   reload_from_flags()                            after SaveManager.load_game()
##   debug_force_heard(hint_id) / debug_reset()     for captures

## A fourth silhouette kind, beyond SkyEvents' AURORA/COMET/RING (0/1/2). sky_journal.gd's PageArt
## draws every kind's base tinted circle + "?" first and only ADDS kind-specific doodles after — an
## unmatched kind like this one still reads fine as "something is waiting here" with zero changes
## needed there. Rough is fine; the sky is not (STYLE_GUIDE) — this is not the sky, it is a blank page.
const KIND_MOON := 3

## SkyEvents' own kind ids, read directly (no preload; class_name is global, same pattern
## sky_journal.gd already uses for SkyEvents.AURORAS etc.) so a comet-ish or ring-ish hint still gets
## that shape's doodle on its journal page instead of only the generic silhouette. Declared here
## (ABOVE `HINTS`, which uses them) because GDScript const expressions resolve top-to-bottom.
const KIND_COMET_LOCAL := 1
const KIND_RING_LOCAL := 2
const KIND_AURORA_LOCAL := 0

## How often a talk offers an unheard hint (checked after the greeting, same slot as time/deco
## flavour — see conversation.gd's HINT_LINE_CHANCE). Not every talk: a neighbour who repeats the
## same "I think I saw something" every single conversation reads as broken, not vague.
const HINT_CHANCE := 0.35

## One day in three, same shape as SkyEvents.comet_is_dawn — deterministic per hint+day, not a coin
## flip a player could reload their way past (there is nothing to reload here anyway; it is a hint,
## not a save-scummable RNG check). Only heard hints are ever reported live regardless.
const UNLOCK_PERIOD := 3

const HINTS: Array = [
	{
		"id": "hint_bolt_moon",
		"npc_id": "bolt",
		## WIRE (2026-09-21): was ["bolt","home"] 20.0-23.5. The green moon is ONE thing now, and the
		## only place it can be caught is the lane the game actually flies, at the hour the lane's
		## own blurb always said ("it only does this before dawn"). Route and window moved here so
		## there is exactly one copy of both; safari_cast.gd reads them.
		"route": ["home", "zorp"],
		"hour_start": 2.0, "hour_end": 5.0,
		"line": "Saw a green moon out your way. Cannot say when.",
		"catch_line": "The green moon. You actually found it. Logging that.",
		"subject": {
			"id": "hint_bolt_moon", "kind": KIND_MOON, "title": "Bolt's green moon",
			"world": "zorp", "az_deg": -150.0, "elev_deg": 30.0, "where": "behind you, toward home",
			"rarity": 3, "tint_a": "#8fe0a0", "tint_b": "#d8ffe4",
			"blurb": "Bolt logged it once. Green, low, and gone fast.",
		},
	},
	{
		"id": "hint_fen_shadow",
		"npc_id": "fen",
		"route": ["fen", "zorp"],
		"hour_start": 18.5, "hour_end": 21.0,
		"line": "A second shadow crossed pool nine. Zorp's way.",
		"catch_line": "The second shadow. I will note the date this time. Truly.",
		"subject": {
			"id": "hint_fen_shadow", "kind": KIND_MOON, "title": "Fen's second shadow",
			"world": "zorp", "az_deg": 40.0, "elev_deg": 22.0, "where": "crossing low, dusk",
			"rarity": 3, "tint_a": "#5a6f96", "tint_b": "#b9c4d8",
			"blurb": "Not on any of my charts. It moved like nothing else does.",
		},
	},
	{
		"id": "hint_grig_streak",
		"npc_id": "grig",
		"route": ["grig", "vela"],
		"hour_start": 2.0, "hour_end": 4.5,
		"line": "Something bright fell past step two hundred. Vela way.",
		"catch_line": "The falling one. Step two hundred saw it first. Correctly.",
		"subject": {
			"id": "hint_grig_streak", "kind": KIND_COMET_LOCAL, "title": "Grig's falling streak",
			"world": "vela", "az_deg": -55.0, "elev_deg": 15.0, "where": "low, small hours",
			"rarity": 3, "tint_a": "#e8c98a", "tint_b": "#fff1cf",
			"blurb": "One long streak, then nothing. Grig counted the seconds. Nine.",
		},
	},
	{
		"id": "hint_vela_wink",
		"npc_id": "vela",
		"route": ["vela", "bolt"],
		"hour_start": 22.0, "hour_end": 1.0,
		"line": "The array caught a wink of light, once, toward Bolt's yard.",
		"catch_line": "The wink. On the record at last. One page thinner.",
		"subject": {
			"id": "hint_vela_wink", "kind": KIND_RING_LOCAL, "title": "Vela's wink of light",
			"world": "bolt", "az_deg": 100.0, "elev_deg": 26.0, "where": "high, brief",
			"rarity": 3, "tint_a": "#c9a9d8", "tint_b": "#f0dcff",
			"blurb": "One flash, dish four only. I have listened for it since.",
		},
	},
	{
		"id": "hint_zorp_spark",
		"npc_id": "zorp",
		"route": ["zorp", "grig"],
		"hour_start": 19.5, "hour_end": 22.5,
		"line": "A violet spark! Trailing Grig's ring! I only saw it once!",
		"catch_line": "The violet spark! You SAW it! I am vibrating with joy!",
		"subject": {
			"id": "hint_zorp_spark", "kind": KIND_AURORA_LOCAL, "title": "Zorp's violet spark",
			"world": "grig", "az_deg": 65.0, "elev_deg": 18.0, "where": "trailing the ring",
			"rarity": 3, "tint_a": "#a87cf2", "tint_b": "#f2b8ff",
			"blurb": "A single violet spark, gone before Zorp's antenna finished tingling.",
		},
	},
]

## LANE TIPS (WIRE, 2026-09-21). MOVED HERE FROM safari_cast.gd, which kept a second, private copy
## of the hint strings. A tip is the small half of a hint: a neighbour telling you what is normally
## out on a lane. It does NOT gate anything - the subject it names is in the route's cast whether
## you heard the tip or not - so it needs no subject, no window and no "heard" state. The five big
## HINTS above are the other half: a sight that does not exist until somebody mentions it.
##
## One file, one set of player words. `lines_ok()` checks every string in BOTH tables against the
## 60-character budget.
const LANE_TIPS: Array = [
	{"npc_id": "zorp", "route_id": "home_zorp", "points_to": "pod_driftlings",
		"line": "A pod swam past my window. Right side, mid-way."},
	{"npc_id": "grig", "route_id": "home_zorp", "points_to": "der_kettle",
		"line": "There is an old ship out there. It still blinks."},
	{"npc_id": "vela", "route_id": "home_zorp", "points_to": "ice_frozen",
		"line": "Look inside the ice. I heard one is not empty."},
	{"npc_id": "fen", "route_id": "bolt_fen", "points_to": "pod_kite",
		"line": "Kites come for the ice. Left of the gap, early."},
	{"npc_id": "bolt", "route_id": "bolt_fen", "points_to": "der_anvil",
		"line": "Do not photograph my old lifter. Please."},
]

## The 60-character budget for everything a player reads out of this file.
const LINE_MAX := 60

## Session-only stores (see header "STATE IS SESSION-ONLY").
static var _heard: Dictionary = {}    # hint_id -> {"day": int}
static var _thanked: Dictionary = {}  # hint_id -> true once the catch reaction has been said


static func for_npc(npc_id: String) -> Dictionary:
	for h in HINTS:
		if str(h.get("npc_id", "")) == npc_id:
			return h
	return {}


static func subject_for(hint_id: String) -> Dictionary:
	for h in HINTS:
		if str(h.get("id", "")) == hint_id:
			return (h["subject"] as Dictionary).duplicate(true)
	return {}


static func is_heard(hint_id: String) -> bool:
	_hydrate()
	return _heard.has(hint_id)


## The one entry point conversation.gd needs. "" most talks. Otherwise either the hint (and the
## sight becomes real — see header) or, once, the catch reaction. Never both in one call.
static func maybe_hint_line(npc_id: String, rng: RandomNumberGenerator = null) -> String:
	_hydrate()
	# WIRE round (2026-09-21). THE CATALOG IS THE CONTENT NOW. SafariCatalog carries ten hinted
	# rares, each with its own neighbour and its own half-memory of a line; this file's own five
	# were an earlier, smaller copy of the same idea (four of them are literally the same sights,
	# and its green moon shares a line word for word with the catalog's `green_moon`). So the
	# catalog's hints are asked FIRST, through src/sky/safari_heard.gd, which owns the heard set in
	# the catalog's own ids - the ids SafariLanes.draw_cast gates on.
	#
	# This file stays the MOUTH: conversation.gd calls exactly this function and does not have to
	# learn a second one. Its own five HINTS remain below as the fallback for any npc the catalog
	# does not name, so nothing that already worked stopped working.
	var from_catalog := SafariHeard.line_for(npc_id, HINT_CHANCE, rng)
	if from_catalog != "":
		return from_catalog
	if not SafariHeard.sights_of(npc_id).is_empty():
		# The catalog owns this neighbour's sky talk. Do not let the old table speak over it.
		return ""
	var h := for_npc(npc_id)
	if h.is_empty():
		return ""
	var hint_id := str(h["id"])
	var subject_id := str(h["subject"]["id"])
	var caught := _subject_caught(subject_id)
	if caught:
		if _thanked.get(hint_id, false):
			return ""
		_thanked[hint_id] = true
		_persist()
		return str(h.get("catch_line", "You found it. I knew it was real."))
	var roll: float = rng.randf() if rng != null else randf()
	if roll >= HINT_CHANCE:
		return ""
	mark_heard(hint_id)
	return str(h.get("line", ""))


## Registers a hint as heard: idempotent, and tells SkyJournal (if it exists yet) to add a
## "heard about, not seen" page. Safe to call from anywhere, any order — same defensive pattern as
## SkyJournal.attach_watch finding SkyWatch by name.
static func mark_heard(hint_id: String) -> void:
	_hydrate()
	if _heard.has(hint_id):
		return
	var h := {}
	for cand in HINTS:
		if str(cand.get("id", "")) == hint_id:
			h = cand
			break
	if h.is_empty():
		return
	_heard[hint_id] = {"day": GameState.day_count}
	_persist()
	var journal := _find_journal()
	if journal != null and journal.has_method("register_hint"):
		journal.call("register_hint", (h["subject"] as Dictionary).duplicate(true), {
			"npc_id": str(h.get("npc_id", "")),
			"line": str(h.get("line", "")),
			"day": GameState.day_count,
		})


static func _subject_caught(subject_id: String) -> bool:
	var journal := _find_journal()
	if journal == null or not journal.has_method("has_shot"):
		return false
	return bool(journal.call("has_shot", subject_id))


## THE HAND-OFF. {} when nothing is live on this route today, or the hint has not been heard yet.
## `from_id`/`to_id` match either direction of travel — the user's example is "toward home", which
## reads the same leaving Bolt's world or, later, heading back out from home past it.
static func active_window_for_route(from_id: String, to_id: String, day: int) -> Dictionary:
	_hydrate()
	for h in HINTS:
		var hint_id := str(h["id"])
		if not is_heard(hint_id):
			continue
		var route: Array = h.get("route", [])
		if route.size() != 2:
			continue
		var a := str(route[0])
		var b := str(route[1])
		var on_route := (a == from_id and b == to_id) or (a == to_id and b == from_id)
		if not on_route:
			continue
		if not _unlocked_today(hint_id, day):
			continue
		return {
			"hint_id": hint_id,
			"subject_id": str(h["subject"]["id"]),
			"route": [from_id, to_id],
			"window": {"hour_start": float(h["hour_start"]), "hour_end": float(h["hour_end"])},
			"subject": (h["subject"] as Dictionary).duplicate(true),
		}
	return {}


## Deterministic, seeded off the hint id and the day — one day in UNLOCK_PERIOD, same shape as
## SkyEvents.comet_is_dawn. No RandomNumberGenerator object needed for a single yes/no per day.
static func _unlocked_today(hint_id: String, day: int) -> bool:
	return posmod(int(hash(hint_id)) + day, UNLOCK_PERIOD) == 0


static func _find_journal() -> Node:
	var loop := Engine.get_main_loop()
	if loop == null or not (loop is SceneTree):
		return null
	return (loop as SceneTree).root.find_child("SkyJournal", true, false)


# ------------------------------------------------------------------ tips, budget (WIRE)
## The tips a player could have heard for this route. `known` is the set of npc ids the player has
## befriended; empty means everybody, which is what the spike uses. Deterministic - no randomness,
## so a capture is repeatable. safari_cast.gd calls this instead of holding its own list.
static func tips_for_route(route_id: String, known: Array = []) -> Array:
	var out: Array = []
	for t in LANE_TIPS:
		if str(t["route_id"]) != route_id:
			continue
		if known.is_empty() or known.has(str(t["npc_id"])):
			out.append(t)
	return out


## Every player-facing string in this file, as {who, kind, text}. The budget check reads THIS, so a
## new line cannot be added without being measured.
static func all_lines() -> Array:
	var out: Array = []
	for h in HINTS:
		out.append({"who": str(h["npc_id"]), "kind": "hint", "text": str(h.get("line", ""))})
		out.append({"who": str(h["npc_id"]), "kind": "catch", "text": str(h.get("catch_line", ""))})
	for t in LANE_TIPS:
		out.append({"who": str(t["npc_id"]), "kind": "tip", "text": str(t.get("line", ""))})
	return out


static func lines_ok() -> bool:
	return longest_line() <= LINE_MAX


static func longest_line() -> int:
	var n := 0
	for l in all_lines():
		n = maxi(n, str(l["text"]).length())
	return n


# ------------------------------------------------------------------ state (WIRE: it now survives)
## WAS SESSION-ONLY, AND THAT BROKE THE CHAIN. "Heard" is the switch that makes a rare sight exist
## at all; forgetting it on reload meant a player could be told about the green moon, quit, and have
## the sight silently vanish from the lane. It lives in GameState.flags now, the same plain
## Dictionary PrintBag uses, so it saves and loads with everything else. The IMAGES a print holds
## are still session-only (sky_journal.gd's header) - that is a different thing and still true.
const F_HEARD := "sky_hints_heard"
const F_THANKED := "sky_hints_thanked"
static var _hydrated := false


static func _hydrate() -> void:
	if _hydrated:
		return
	_hydrated = true
	var h: Variant = GameState.flags.get(F_HEARD, {})
	if h is Dictionary:
		for k in (h as Dictionary):
			if not _heard.has(k):
				_heard[k] = (h as Dictionary)[k]
	var t: Variant = GameState.flags.get(F_THANKED, {})
	if t is Dictionary:
		for k in (t as Dictionary):
			_thanked[k] = true


static func _persist() -> void:
	GameState.flags[F_HEARD] = _heard.duplicate(true)
	GameState.flags[F_THANKED] = _thanked.duplicate(true)


## Called after a load, so the next read picks the loaded flags up instead of this session's cache.
static func reload_from_flags() -> void:
	_heard.clear()
	_thanked.clear()
	_hydrated = false
	_hydrate()


# ------------------------------------------------------------------ debug hooks (captures)
## SYNTHETIC — jumps straight to "heard", bypassing the conversation and its HINT_CHANCE roll, for a
## repeatable capture of one page in one call.
static func debug_force_heard(hint_id: String) -> void:
	mark_heard(hint_id)


## SYNTHETIC — clears all session state, so a capture script can run every hint from a clean start
## without relaunching the game.
static func debug_reset() -> void:
	_heard.clear()
	_thanked.clear()
	_hydrated = true
	_persist()
