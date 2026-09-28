class_name PhotoAsks
extends RefCounted
## The open photo requests, in one plain flag every system shares (docs/STORY_SPINE_SPEC.md 2.3).
##
## Written by the lead, not a builder, so the draw, the pad, the story and the journal all decide
## "does this trip carry that ask?" with the SAME rule. Two builders re-implementing one rule is how
## this project has shipped two systems that disagreed before (docs/OPEN_ISSUES.md 63).
##
##   GameState.flags["photo_asks"] = {
##     "<sight id>": {"by": "<npc id, or 'professor'>", "lane": "<lane id, or '' for any>",
##                    "from": "<world id, or '' for any>", "to": "<world id, or '' for any>",
##                    "hours": [h0, h1], "one_way": <bool>, "day": <int>}
##   }
##
## * An empty "lane", "from" or "to" matches any.
## * "one_way" false (the default) matches the pair in either direction: a neighbour's ask for the
##   home <-> Zorp trip is carried going out and coming back. "one_way" true matches only
##   from -> to: the Professor's ask is carried only on the way TO the Commons, where you meet him.
## * Hours wrap midnight: [16, 7] is 16:00 through 07:00, and [0, 24] is always.

const FLAG := "photo_asks"


## Every open ask, keyed by sight id. Always a Dictionary, never null.
static func open() -> Dictionary:
	var d = GameState.flags.get(FLAG, {})
	return d if d is Dictionary else {}


static func has(sight_id: String) -> bool:
	return open().has(sight_id)


## One ask's entry, or {} when that sight is not asked for.
static func get_ask(sight_id: String) -> Dictionary:
	var e = open().get(sight_id, {})
	return e if e is Dictionary else {}


## Opens (or replaces) an ask. Stamps today's day when the caller did not.
static func add(sight_id: String, entry: Dictionary) -> void:
	var d := open().duplicate(true)
	var e := entry.duplicate(true)
	if not e.has("day"):
		e["day"] = GameState.day_count
	d[sight_id] = e
	GameState.flags[FLAG] = d


## Closes an ask. A sight that was not asked for is a no-op.
static func remove(sight_id: String) -> void:
	var d := open().duplicate(true)
	if d.erase(sight_id):
		GameState.flags[FLAG] = d


## True when `hour` (0-24, wrapped) falls inside `hours`. [0, 24] and anything spanning a whole day
## is always true; [a, b] with a > b wraps midnight.
static func in_hours(hours: Array, hour: float) -> bool:
	if hours.size() < 2:
		return true
	var a := float(hours[0])
	var b := float(hours[1])
	if b - a >= 24.0:
		return true
	var h := fposmod(hour, 24.0)
	if a <= b:
		return h >= a and h < b
	return h >= a or h < b


## THE RULE. Does a photo trip on `lane_id` from `from_id` to `to_id`, departing at `hour`, carry
## this ask? Every caller uses this; nobody re-derives it.
static func matches(entry: Dictionary, lane_id: String, from_id: String, to_id: String,
		hour: float) -> bool:
	var l := str(entry.get("lane", ""))
	if l != "" and l != lane_id:
		return false
	var f := str(entry.get("from", ""))
	var t := str(entry.get("to", ""))
	var forward := (f == "" or f == from_id) and (t == "" or t == to_id)
	var pair_ok := forward
	if not bool(entry.get("one_way", false)):
		var backward := (f == "" or f == to_id) and (t == "" or t == from_id)
		pair_ok = forward or backward
	if not pair_ok:
		return false
	var hours = entry.get("hours", [0.0, 24.0])
	return in_hours(hours if hours is Array else [0.0, 24.0], hour)


## The sight ids a trip carries, sorted so a seeded draw that consumes them stays deterministic.
static func for_trip(lane_id: String, from_id: String, to_id: String, hour: float) -> Array[String]:
	var out: Array[String] = []
	var d := open()
	for sid in d.keys():
		var e = d[sid]
		if e is Dictionary and matches(e, lane_id, from_id, to_id, hour):
			out.append(str(sid))
	out.sort()
	return out


## True when ANY open ask would be carried by SOME trip ending at `to_id`, on any lane, from
## anywhere, at `hour` - i.e. when `matches()` is true for at least one origin. Used by the one
## exception to "a trip to the Commons is an errand" (docs/STORY_SPINE_SPEC.md 2.5).
## FIXED 2026-09-22 (S1's critic): the first version checked only "to", so a TWO-WAY ask whose
## "from" is `to_id` - carried on the way back - was missed although `matches()` carries it.
static func any_to(to_id: String, hour: float) -> bool:
	var d := open()
	for sid in d.keys():
		var e = d[sid]
		if not (e is Dictionary):
			continue
		var t := str(e.get("to", ""))
		var f := str(e.get("from", ""))
		var ends_here := t == "" or t == to_id
		if not ends_here and not bool(e.get("one_way", false)):
			ends_here = f == "" or f == to_id
		if not ends_here:
			continue
		var hours = e.get("hours", [0.0, 24.0])
		if in_hours(hours if hours is Array else [0.0, 24.0], hour):
			return true
	return false
