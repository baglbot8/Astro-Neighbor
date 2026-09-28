class_name SkyEvents
extends RefCounted
## BOOK round (2026-09-21, scratch only). ONE SKY. This file used to BE a sky: nine hand-made
## events in four pools, with their own ids, their own windows and their own worlds. The safari
## ran on SafariCatalog's 51. So the game had two skies that never met: the forecast named things
## no flight could ever show you, and the flight caught things the forecast had never heard of.
## The reviewer wrote it down as blocker 2, and this is the half of the fix that lives here.
##
## WHAT THIS FILE IS NOW: A VIEW ON THE ONE CATALOG. There is no sight data left in it. Every
## forecast row is a `SafariCatalog` sight, dressed in the shape the telescope, the plan panel and
## the journal page already read (id/title/kind/world/hour_start/hour_end/az_deg/elev_deg/where/
## rarity/tint_a/tint_b/blurb). Nothing that called this file had to change: `forecast_for_day`,
## `in_window`, `peak_hour`, `timing_mult`, `can_print_here`, `plan_line` and the rest keep their
## exact signatures, and `src/sky/sky_plan.gd` (not owned this round) was not touched.
##
## THE NINE ARE RETIRED. `AURORAS` / `COMETS_DAWN` / `COMETS_NIGHT` / `RINGS` are still here as
## EMPTY arrays, so an old showcase script that reads them still parses and simply finds nothing,
## rather than failing at load. Nothing in `src/` reads them any more.
##
## WHAT SURVIVED FROM THE OLD FILE, because it was about the NIGHT and not about the sights:
##
## 1. THE NIGHT HAS THREE SLOTS, at the hours round 2 measured against the real clock:
##      early   19.9 - 23.1   opens at sunset, gone before midnight
##      middle  21.4 -  2.6   the long one, the night's main event
##      late     3.6 -  5.9   two days in three, a MORNING sight that survives sunrise
##              (2.7 -  5.2   the other day in three: no morning sight, but no empty sky either)
##    The slots are the SHAPE of the night. The catalog fills them. A sight whose own `hours` gate
##    does not overlap a slot cannot be cast in that slot, so a dawn-only sight never gets handed
##    to you at 20:00 and a dusk-only one never at 04:00.
##
## 2. PEAK, NOT JUST WINDOW, and EDGE_MULT = 2/3 exactly - the number at which peaking an Uncommon
##    just beats edging a Rare. Unchanged and still not a knob.
##
## 3. THE TRAVEL RULE. `can_print_here`: the tripod only records a sight from the world the
##    forecast names. A forecast world is now drawn from the ENDS OF THE LANES THAT SIGHT FLIES ON
##    (`worlds_for`), so "fly to Vela to record it" always names a world the thing really passes.
##
## THE RULE THE REVIEWER ASKED FOR, IN ONE FUNCTION: `producible(e)`. A sight is in the player's
## sky only if the safari could actually produce it for THIS save - it is a catalog sight, it has
## at least one lane, its story gate is met, and if it is hinted the player has heard the hint.
## `forecast_for_day` draws only from `producible_sights()` and `sky_journal.gd` builds the book
## from exactly the same list, so the book can never again list a sight the safari cannot produce.
## Day gates (`days`, day % 7) are TIME, not permanence: such a sight stays in the book and is only
## forecast on its own days.
##
## SAY WHAT IS SYNTHETIC: `az_deg` / `elev_deg` / `where` do not exist in the catalog - a lane says
## where a sight sits in the PORTHOLE, which is a different frame. They are derived here, seeded
## off the sight id, so they are stable for a given sight and repeatable for a critic, but they are
## made up, not read off data. Nothing scores on them; they only tell the player where to look.

const KIND_AURORA := 0
const KIND_COMET := 1
const KIND_RING := 2

const KIND_NAMES := ["Aurora", "Comet", "Ringed pass"]

## rarity 1..4. The catalog's own names, re-declared here because `rarity_name` is called from six
## files that only know this one.
const RARITY_NAMES := ["", "Common", "Uncommon", "Rare", "Hardly ever"]

## What an edge-of-window print is worth against a peak one. 2/3 exactly.
const EDGE_MULT := 2.0 / 3.0

## RETIRED (BOOK round). The nine hand-made events are gone; these names survive empty so any
## script still walking them parses and finds nothing instead of erroring.
const AURORAS: Array = []
const COMETS_DAWN: Array = []
const COMETS_NIGHT: Array = []
const RINGS: Array = []

## THE THREE SLOTS OF THE NIGHT, hours kept exactly as round 2 measured them.
const SLOT_EARLY := {"key": "early", "hour_start": 19.9, "hour_end": 23.1}
const SLOT_MIDDLE := {"key": "middle", "hour_start": 21.4, "hour_end": 2.6}
const SLOT_DAWN := {"key": "dawn", "hour_start": 3.6, "hour_end": 5.9}
const SLOT_LATE := {"key": "late", "hour_start": 2.7, "hour_end": 5.2}


# ------------------------------------------------------------------ what the safari can produce
## THE ONE GATE. True when this catalog sight could really be flown to on some lane, on some day,
## in this save. Hint gates and story gates are PERMANENT for now and so keep a sight out of the
## book entirely; day gates and hour gates are time and do not.
static func producible(e: Dictionary) -> bool:
	if e.is_empty():
		return false
	if Array(e.get("lanes", [])).is_empty():
		return false
	if int(e.get("needs_story", 0)) > GameState.rocket_part_count():
		return false
	if bool(e.get("needs_hint", false)) and not SafariHeard.is_heard(str(e.get("id", ""))):
		return false
	return true


## Every catalog sight the safari can produce for this save, in the catalog's own order.
static func producible_sights() -> Array:
	var out: Array = []
	for e in SafariCatalog.SIGHTS:
		if producible(e):
			out.append(e)
	return out


static func producible_ids() -> Array:
	var out: Array = []
	for e in producible_sights():
		out.append(str(e["id"]))
	return out


## SWEEP HOOK (critic checklist item 4). Every id the BOOK holds that the safari cannot produce.
## Empty is the pass. Takes the book's page ids; the journal calls it on itself.
static func unproducible_among(page_ids: Array) -> Array:
	var bad: Array = []
	for id in page_ids:
		if is_limb_page(str(id)):
			continue
		var e := SafariCatalog.by_id(str(id))
		if e.is_empty() or not producible(e):
			bad.append(str(id))
	return bad


# ------------------------------------------------------------------ the fifteenth kind: a WORLD
## THE ONE THING THE SAFARI PRODUCES THAT IS NOT CATALOG CONTENT: the world you just left and the
## world you are arriving at. `SafariLanes._world_entry` builds those two out of the world's own
## .tres on EVERY run, so they are the most producible sights in the game, and they were the one
## hole in "one sky": before this round they got a session-only page that vanished on reload,
## because `load_from_flags` could not find them in the catalog.
##
## TWO PAGES PER WORLD, NOT FOUR. A run's cast names a limb `limb_zorp_night_behind` or
## `..._ahead`; behind and ahead are the SAME FACE of the same world seen from either end of the
## trip, so they collapse onto one page id, `limb_zorp_night`. Seven worlds, two faces: 14 pages,
## and "Zorp's rivers, glowing from orbit" is a page worth having.
const LIMB_FACES := ["day", "night"]


## The run-cast id of a limb -> its page id, or "" if this is not a limb at all.
static func limb_page_id(run_id: String) -> String:
	if not run_id.begins_with("limb_"):
		return ""
	for role in ["_behind", "_ahead"]:
		if run_id.ends_with(role):
			return run_id.substr(0, run_id.length() - role.length())
	return run_id


static func is_limb_page(page_id: String) -> bool:
	if not page_id.begins_with("limb_"):
		return false
	for wid in SafariLanes.WORLD_LIMB:
		for face in LIMB_FACES:
			if page_id == "limb_%s_%s" % [str(wid), face]:
				return true
	return false


## Every limb page, in world order then day/night.
static func limb_page_ids() -> Array:
	var out: Array = []
	for wid in SafariLanes.WORLD_LIMB:
		for face in LIMB_FACES:
			if (SafariLanes.WORLD_LIMB[wid] as Dictionary).has(face):
				out.append("limb_%s_%s" % [str(wid), face])
	return out


## A limb page, in the journal's own page shape, read off SafariLanes.WORLD_LIMB - never invented.
static func limb_subject(page_id: String) -> Dictionary:
	var parts := page_id.split("_")
	if parts.size() < 3:
		return {}
	var face := str(parts[parts.size() - 1])
	var wid := page_id.substr(5, page_id.length() - 6 - face.length())
	if not SafariLanes.WORLD_LIMB.has(wid):
		return {}
	var f: Dictionary = (SafariLanes.WORLD_LIMB[wid] as Dictionary).get(face, {})
	if f.is_empty():
		return {}
	return {
		"id": page_id,
		"title": str(f.get("title", "A world")),
		"kind": KIND_AURORA,
		"kind_label": "World",
		"draw": "limb",
		"rarity": 1,
		"world": wid,
		"where": "out between the worlds",
		"blurb": str(f.get("blurb", "")),
		"silhouette": "A whole world, filling one side of the glass.",
		"tint_a": str(f.get("tint_a", "#ffffff")),
		"tint_b": str(f.get("tint_b", "#ffffff")),
	}


# ------------------------------------------------------------------ where a sight can be recorded
## THE WORLDS AT THE ENDS OF EVERY LANE THIS SIGHT FLIES ON, sorted, no duplicates. This is the
## honest answer to "where do I stand to record it": the thing goes past on that road, so it is in
## the sky of the worlds the road joins.
static func worlds_for(e: Dictionary) -> Array:
	var seen: Dictionary = {}
	for lane_id in Array(e.get("lanes", [])):
		if not SafariLanes.LANES.has(str(lane_id)):
			continue
		var lane: Dictionary = SafariLanes.LANES[str(lane_id)]
		for pair in Array(lane.get("pairs", [])):
			seen[str(pair[0])] = true
			seen[str(pair[1])] = true
	var out: Array = seen.keys()
	out.sort()
	return out


# ------------------------------------------------------------------ a catalog sight as an event
## A catalog sight dressed as the forecast row every other file already reads. `slot` supplies the
## window; `world` is picked (seeded) out of `worlds_for` unless the caller names one.
static func event_from(e: Dictionary, slot: Dictionary, day: int, world_id: String = "") -> Dictionary:
	var win := _window_in_slot(e, slot)
	var w := world_id
	if w == "":
		var ws := worlds_for(e)
		if not ws.is_empty():
			w = str(ws[posmod(_id_hash(str(e["id"])) + day, ws.size())])
	var ah := _aim_for(str(e["id"]))
	return {
		"id": str(e["id"]),
		"title": str(e.get("name", "A sight")),
		"kind": SafariHeard.page_kind(e),
		"kind_label": SafariCatalog.kind_name(str(e.get("kind", "creature"))),
		"draw": str(e.get("draw", "pod")),
		"world": w,
		"hour_start": float(win[0]),
		"hour_end": float(win[1]),
		"az_deg": float(ah[0]),
		"elev_deg": float(ah[1]),
		"where": str(ah[2]),
		"rarity": clampi(int(e.get("rarity", 1)), 1, 4),
		"tint_a": str(e.get("tint_a", "#ffffff")),
		"tint_b": str(e.get("tint_b", "#ffffff")),
		"blurb": str(e.get("blurb", "")),
		"silhouette": str(e.get("silhouette", "")),
		"scale": float(e.get("scale", 1.0)),
	}


## The window this sight actually gets inside a slot: the slot itself for an ungated sight, or the
## longest overlap between the sight's own `hours` gate and the slot. [-1, -1] means it cannot be
## cast in this slot at all.
static func _window_in_slot(e: Dictionary, slot: Dictionary) -> Array:
	var s0 := float(slot["hour_start"])
	var s1 := float(slot["hour_end"])
	var hrs: Array = e.get("hours", [0.0, 24.0])
	var a := float(hrs[0])
	var b := float(hrs[1])
	if is_equal_approx(a, 0.0) and is_equal_approx(b, 24.0):
		return [s0, s1]
	var best: Array = [-1.0, -1.0]
	var best_len := 0.0
	for sa in _unwrap(s0, s1):
		for ea in _unwrap(a, b):
			var lo: float = maxf(float(sa[0]), float(ea[0]))
			var hi: float = minf(float(sa[1]), float(ea[1]))
			if hi - lo > best_len:
				best_len = hi - lo
				best = [lo, hi]
	# A sliver is not a window. Under six minutes of game clock and the sight is simply not on.
	if best_len < 0.1:
		return [-1.0, -1.0]
	return best


## A possibly-wrapping [from, to) as one or two plain intervals inside [0, 24].
static func _unwrap(a: float, b: float) -> Array:
	if a <= b:
		return [[a, b]]
	return [[a, 24.0], [0.0, b]]


## Deterministic, stable-per-sight aim. Made up - see the header.
static func _aim_for(sight_id: String) -> Array:
	var h := _id_hash(sight_id)
	var az := float(h % 360) - 180.0
	var el := 6.0 + float((h / 360) % 29)
	return [az, el, _where_words(az, el)]


static func _where_words(az: float, el: float) -> String:
	var a := fposmod(az + 180.0, 360.0) - 180.0
	var face := "south"
	if a >= -45.0 and a < 45.0:
		face = "north"
	elif a >= 45.0 and a < 135.0:
		face = "east"
	elif a >= -135.0 and a < -45.0:
		face = "west"
	if el >= 24.0:
		return "high in the %s" % face
	if el >= 14.0:
		return "%s, half-way up" % face
	return "low in the %s" % face


static func _id_hash(s: String) -> int:
	return int(abs(hash(s))) % 100003


# ------------------------------------------------------------------ the forecast
## True when today's late sight is a MORNING one. Two days in three. Unchanged.
static func comet_is_dawn(day: int) -> bool:
	return posmod(day * 2 + 1, 3) != 0


## The slots this day runs, in the order you would chase them.
static func slots_for_day(day: int) -> Array:
	return [SLOT_EARLY, SLOT_MIDDLE, SLOT_DAWN if comet_is_dawn(day) else SLOT_LATE]


## THREE SIGHTS, THREE DIFFERENT WORLDS, drawn from the catalog. Seeded off the day number, so a
## day's forecast is the same every time it is read and the same for a critic re-running a capture.
## Weighted by the sight's own `weight`, so an everyday sight is usually what is up and a rarity-4
## one hardly ever is - the same likelihoods the flight draws on.
static func forecast_for_day(day: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5C1E5 + day * 7919
	var pool := producible_sights()
	var used_worlds: Array[String] = []
	var used_ids: Dictionary = {}
	var out: Array = []
	for slot in slots_for_day(day):
		var ev := _pick_for_slot(pool, slot, day, rng, used_worlds, used_ids)
		if ev.is_empty():
			continue
		used_worlds.append(str(ev["world"]))
		used_ids[str(ev["id"])] = true
		out.append(ev)
	return out


static func _pick_for_slot(pool: Array, slot: Dictionary, day: int, rng: RandomNumberGenerator,
		used_worlds: Array[String], used_ids: Dictionary) -> Dictionary:
	# Every (sight, world) pair that could fill this slot and does not repeat a world already cast.
	var cands: Array = []
	var total := 0.0
	for e in pool:
		if used_ids.has(str(e["id"])):
			continue
		var days: Array = e.get("days", [])
		if not days.is_empty() and not days.has(day % 7):
			continue
		var win := _window_in_slot(e, slot)
		if float(win[0]) < 0.0:
			continue
		for w in worlds_for(e):
			if used_worlds.has(str(w)):
				continue
			var wt: float = maxf(float(e.get("weight", 10)), 1.0)
			cands.append({"e": e, "w": str(w), "wt": wt})
			total += wt
	if cands.is_empty():
		return {}
	var roll := rng.randf() * total
	for c in cands:
		roll -= float(c["wt"])
		if roll <= 0.0:
			return event_from(c["e"], slot, day, str(c["w"]))
	var last: Dictionary = cands[cands.size() - 1]
	return event_from(last["e"], slot, day, str(last["w"]))


## The forecast row for one sight id today, or {} if it is not forecast today.
static func forecast_entry(day: int, sight_id: String) -> Dictionary:
	for ev in forecast_for_day(day):
		if str(ev.get("id", "")) == sight_id:
			return ev
	return {}


# ------------------------------------------------------------------ windows and clocks (unchanged)
## Is this sight up at `hour`? Windows wrap past midnight (21.4 -> 2.6).
static func in_window(ev: Dictionary, hour: float) -> bool:
	var h := fposmod(hour, 24.0)
	var a := float(ev["hour_start"])
	var b := float(ev["hour_end"])
	if a <= b:
		return h >= a and h <= b
	return h >= a or h <= b


static func hours_until(ev: Dictionary, hour: float) -> float:
	if in_window(ev, hour):
		return 0.0
	return fposmod(float(ev["hour_start"]) - fposmod(hour, 24.0), 24.0)


static func hours_left(ev: Dictionary, hour: float) -> float:
	if not in_window(ev, hour):
		return 0.0
	return fposmod(float(ev["hour_end"]) - fposmod(hour, 24.0), 24.0)


static func real_seconds_until(ev: Dictionary, hour: float) -> float:
	if in_window(ev, hour):
		return 0.0
	return WorldClock.real_seconds_between(hour, float(ev["hour_start"]))


static func real_seconds_left(ev: Dictionary, hour: float) -> float:
	if not in_window(ev, hour):
		return 0.0
	return WorldClock.real_seconds_between(hour, float(ev["hour_end"]))


static func real_seconds_to_peak(ev: Dictionary, hour: float) -> float:
	return WorldClock.real_seconds_between(hour, peak_hour(ev))


## A sight is best when it is HIGHEST: the middle of its window. Derived, never stored.
static func peak_hour(ev: Dictionary) -> float:
	var a := float(ev["hour_start"])
	return fposmod(a + fposmod(float(ev["hour_end"]) - a, 24.0) * 0.5, 24.0)


## EDGE_MULT as it rises and sets, 1.0 at the top. The curve is the sight's altitude, not a fitted
## falloff, so there is no free parameter beyond EDGE_MULT itself.
static func timing_mult(ev: Dictionary, hour: float) -> float:
	if not in_window(ev, hour):
		return EDGE_MULT
	var a := float(ev["hour_start"])
	var span := fposmod(float(ev["hour_end"]) - a, 24.0)
	var prog: float = clampf(fposmod(fposmod(hour, 24.0) - a, 24.0) / maxf(span, 0.0001), 0.0, 1.0)
	return EDGE_MULT + (1.0 - EDGE_MULT) * sin(PI * prog)


## THE TRAVEL RULE. The tripod only records a sight from the world the forecast names.
static func can_print_here(ev: Dictionary, planet_id: String) -> bool:
	return str(ev.get("world", "")) == planet_id


static func world_name(ev: Dictionary) -> String:
	var w := str(ev.get("world", ""))
	return "the Commons" if w == "hub" else w.capitalize()


## The one line the player reads about being in the wrong place. Under 60 characters.
static func here_line(ev: Dictionary, planet_id: String) -> String:
	if can_print_here(ev, planet_id):
		return ""
	return "Hazy from here - caps at 58%%. Fly to %s." % world_name(ev)


static func short_here(ev: Dictionary, planet_id: String) -> String:
	if can_print_here(ev, planet_id):
		return ""
	return "Caps at 58%% - best from %s" % world_name(ev)


## Tonight in one line, for the top of the panel and for a neighbour to say. Under 60 characters.
static func plan_line(day: int, hour: float, planet_id: String) -> String:
	var f := forecast_for_day(day)
	if f.is_empty():
		return "Nothing out tonight. Fly and see."
	for ev in f:
		if in_window(ev, hour):
			if can_print_here(ev, planet_id):
				return "Up now, right here: %s." % kind_label(ev).to_lower()
			return "%s up. %s." % [kind_label(ev), short_here(ev, planet_id)]
	var best: Dictionary = f[0]
	var best_s := 1.0e9
	for ev in f:
		var s := real_seconds_until(ev, hour)
		if s < best_s:
			best_s = s
			best = ev
	return "%s over %s in %s." % [
		kind_label(best), world_name(best), WorldClock.short_time(best_s)]


static func window_text(ev: Dictionary) -> String:
	return "%s - %s" % [clock_text(float(ev["hour_start"])), clock_text(float(ev["hour_end"]))]


static func clock_text(hour: float) -> String:
	var h := fposmod(hour, 24.0)
	var hh := int(floor(h))
	var mm := int(round((h - float(hh)) * 60.0))
	if mm >= 60:
		mm -= 60
		hh = (hh + 1) % 24
	return "%02d:%02d" % [hh, mm]


static func rarity_name(r: int) -> String:
	return RARITY_NAMES[clampi(r, 1, 4)]


## LEGACY. The silhouette's three drawing kinds, not the catalog's eight words. `kind_label` is
## what a player should read now; this is kept because sky_plan.gd and two showcases call it.
static func kind_name(k: int) -> String:
	return KIND_NAMES[clampi(k, 0, 2)]


## WHAT THE PLAYER READS a sight is: the CATALOG's word ("Creature", "Wreck", "Ice", ...), carried
## on every event and every journal page this round builds. Falls back to the old three-name list
## for anything built before this round.
static func kind_label(ev: Dictionary) -> String:
	var s := str(ev.get("kind_label", ""))
	if s != "":
		return s
	return kind_name(int(ev.get("kind", 0)))


## True when the window sits across FIRST LIGHT - a morning sight.
static func is_morning(ev: Dictionary) -> bool:
	var a := float(ev["hour_start"])
	var b := float(ev["hour_end"])
	return a <= b and a >= 3.5 and b <= 9.0
