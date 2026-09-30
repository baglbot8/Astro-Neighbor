class_name FieldNotes
extends RefCounted
## MOSS'S FIELD NOTES (GOODS, 2026-09-30; docs/JUNGLE_PLANET_SPEC.md 6.1): bought at Moss's stall for the
## day (CameraGoods.NOTES_*, `flags.field_notes_day`), then Moss asks which world and tells you, in his
## voice, which rare sight is likely there TODAY and roughly where. It must never be wrong.
##
## HOW IT IS NEVER WRONG. Every safari world has exactly two rare events (PlanetSafari's schedule, tier
## "rare" and "rare_day" in each world's MANIFEST roster): the "rare" one runs on every trip ("rare": "any",
## "when": "any"), the "rare_day" one only on the planet's rare day ("rare": "only"). Which day is a rare day
## is PlanetSafari.is_rare_day_for(pid, day, one_in) - the same static call the safari makes at its start,
## with the same `day` (GameState.day_count) and the world script's own `rare_one_in`. So:
##   rare day   -> Moss names the rare_day event (the one you cannot see tomorrow);
##   other days -> the rare event.
## WHERE and WHEN are the event's place and start time as the safari lays them out. They do not depend on
## the day (measured 2026-09-30, day 3 and day 11, bolt and jungle: identical), so they are a table here,
## taken from a probe that started each planet's safari and read PlanetSafari._events: `around` = degrees
## round the planet from the safari start, `bearing` = degrees off the start heading (+ = right),
## `metres` = the walk along the ground, `start` = seconds into the three minutes. The probe re-checks
## this table against a live safari (`dev_check` below); if a world builder moves an event, it fails.
## Names come from the planet's MANIFEST roster at run time, so a renamed event is named right.
##
## Moss never says "safari" (MossLines): a safari is "a photo trip". Every line <= 60 characters.

## pid -> { "rare": [id, around, bearing, metres, start], "rare_day": [...] }  (see header)
const PLACES := {
	"zorp": {"rare": ["great_bloom", 148.1, -165.5, 27.1, 84.0], "rare_day": ["twin_moon_glow", 96.0, -5.4, 17.6, 146.0]},
	"bolt": {"rare": ["sky_whale", 162.0, 115.0, 29.7, 8.0], "rare_day": ["great_magnet", 96.9, -34.9, 17.8, 75.0]},
	"fen": {"rare": ["arch_light", 34.6, 131.3, 7.8, 82.0], "rare_day": ["stone_heron", 29.9, -12.3, 6.8, 112.0]},
	"grig": {"rare": ["moonrise", 94.2, 47.2, 15.6, 52.0], "rare_day": ["great_stack", 150.0, -125.0, 24.9, 100.0]},
	"vela": {"rare": ["mirror_moon", 110.2, -99.2, 27.9, 60.0], "rare_day": ["aurora", 40.7, 90.4, 10.3, 96.0]},
	"jungle": {"rare": ["canopy_grazer", 53.0, 82.1, 13.0, 82.0], "rare_day": ["giant_bloom", 90.5, 118.4, 22.1, 112.0]},
}
## The picker, in the rocket map's order (space_travel.gd ORDER), two pages of the dialogue's 2-4 pills.
const PAGE_1 := ["zorp", "bolt", "fen"]
const PAGE_2 := ["grig", "vela", "jungle"]
const MORE := "More..."
const BACK := "Back"
## What Moss calls each world (and the pill's label).
const WORLD_NAMES := {
	"zorp": "Zorp's world", "bolt": "Bolt's world", "fen": "Fen's world",
	"grig": "Grig's world", "vela": "Vela's world", "jungle": "the Tangle",
}
const PILL_NAMES := {
	"zorp": "Zorp", "bolt": "Bolt", "fen": "Fen", "grig": "Grig", "vela": "Vela", "jungle": "Tangle",
}

## --- Moss's lines (MossLines' voice rules; `longest()` checks the 60) ---------------------------------
const ASK_WORLD := "My notes, then. Which world do you want to know?"
## %s = world name, %s = the sight's name.
const SAY_RARE := "On %s today, watch for %s."
## A rare day: two lines, %s = world name, then %s = the sight's name.
const SAY_RARE_DAY := "It's a special day on %s!"
const SAY_RARE_DAY_2 := "Watch for %s. It is not there every day."
## Where, from the moment the photo trip starts (you face the same way every time).
const WHERE := "When your trip starts, it is %s."
const DIRS := {
	"ahead": "straight ahead", "ahead_right": "ahead, to your right", "right": "to your right",
	"behind_right": "behind you, on the right", "behind": "straight behind you",
	"behind_left": "behind you, on the left", "left": "to your left", "ahead_left": "ahead, to your left",
}
const FAR := {"near": "It is close by.", "mid": "It is a short walk away.", "far": "It is far, near the other side."}
const WHEN := {"early": "It comes early in the trip.", "middle": "It comes about halfway in.",
	"late": "It comes near the end. Be patient."}
const ALREADY := "You took pictures there today. It sleeps till tomorrow."
const SIGN_OFF := "The swamp says good luck."
const NOT_TODAY := "Buy my notes first. They are only good for one day."


## The rare sight of `pid` on game day `day`: {id, name, tier, rare_day, around, bearing, metres, start},
## or {} when the world has no entry here or no safari.
static func sight_for(pid: String, day: int) -> Dictionary:
	if not PLACES.has(pid) or not PlanetSafari.has_safari(pid):
		return {}
	var rare_day := PlanetSafari.is_rare_day_for(pid, day, rare_one_in(pid))
	var tier := "rare_day" if rare_day else "rare"
	var row: Array = PLACES[pid][tier]
	var id := str(row[0])
	var entry := PlanetSafari.roster_entry(pid, id)
	return {
		"id": id, "name": str(entry.get("name", id.capitalize())), "tier": tier, "rare_day": rare_day,
		"around": float(row[1]), "bearing": float(row[2]), "metres": float(row[3]), "start": float(row[4]),
	}


## The world script's `rare_one_in` (SafariWorld's default 4 unless a world overrides the default).
static func rare_one_in(pid: String) -> int:
	var path := PlanetSafari.WORLDS_DIR + pid + ".gd"
	if ResourceLoader.exists(path):
		var scr: Variant = load(path)
		if scr is Script:
			var v: Variant = (scr as Script).get_property_default_value("rare_one_in")
			if v is int and int(v) > 0:
				return int(v)
	return 4


## Eight compass words off the start heading.
static func dir_key(bearing: float) -> String:
	var b := wrapf(bearing, -180.0, 180.0)
	var keys := ["ahead", "ahead_right", "right", "behind_right", "behind", "behind_left", "left", "ahead_left"]
	var i := posmod(int(round(b / 45.0)), 8)
	return keys[i]


static func far_key(metres: float) -> String:
	if metres < 10.0:
		return "near"
	if metres < 20.0:
		return "mid"
	return "far"


## Three minutes in thirds.
static func when_key(start: float) -> String:
	var third := PlanetSafari.DURATION / 3.0
	if start < third:
		return "early"
	if start < third * 2.0:
		return "middle"
	return "late"


## Moss's lines for `pid` today (after the notes were bought).
static func lines_for(pid: String, day: int) -> Array:
	var s := sight_for(pid, day)
	if s.is_empty():
		return [NOT_TODAY]
	var world := str(WORLD_NAMES.get(pid, pid.capitalize()))
	var nm := mid_name(str(s["name"]))
	var out: Array = []
	if bool(s["rare_day"]):
		out.append(SAY_RARE_DAY % world)
		out.append(SAY_RARE_DAY_2 % nm)
	else:
		out.append(SAY_RARE % [world, nm])
	out.append(WHERE % str(DIRS[dir_key(float(s["bearing"]))]))
	out.append(str(FAR[far_key(float(s["metres"]))]))
	out.append(str(WHEN[when_key(float(s["start"]))]))
	return out


## A roster name inside a sentence: "The Sky Whale" -> "the Sky Whale".
static func mid_name(n: String) -> String:
	return "the " + n.substr(4) if n.begins_with("The ") else n


## THE TALK: Moss asks which world (two pages of pills) and tells. Awaitable. Returns the chosen pid or "".
static func run(runner: DialogueRunner, npc: Node3D) -> String:
	var page := 0
	var pid := ""
	while pid == "":
		var ids: Array = PAGE_1 if page == 0 else PAGE_2
		var opts: Array = []
		for id: String in ids:
			opts.append(str(PILL_NAMES[id]))
		opts.append(MORE if page == 0 else BACK)
		var c: int = await runner.ask(npc, ASK_WORLD, opts)
		if c < 0:
			return ""
		if c >= ids.size():
			page = 1 - page
			continue
		pid = str(ids[c])
	var day := GameState.day_count
	if PlanetSafari.ran_today(pid):
		await runner.say(npc, [ALREADY])
		return pid
	var lines := lines_for(pid, day)
	lines.append(SIGN_OFF)
	print("FIELDNOTES pid=%s day=%d sight=%s" % [pid, day, str(sight_for(pid, day))])
	await runner.say(npc, lines)
	return pid


## Longest line any world can produce (the <= 60 rule), for the probe.
static func longest() -> Dictionary:
	var worst := {"n": 0, "line": ""}
	var cands: Array = [ASK_WORLD, ALREADY, SIGN_OFF, NOT_TODAY]
	for v: Variant in FAR.values() + WHEN.values():
		cands.append(str(v))
	for d: Variant in DIRS.values():
		cands.append(WHERE % str(d))
	for pid: String in PLACES:
		for tier: String in ["rare", "rare_day"]:
			var id := str(PLACES[pid][tier][0])
			var nm := str(PlanetSafari.roster_entry(pid, id).get("name", id))
			if tier == "rare":
				cands.append(SAY_RARE % [WORLD_NAMES[pid], mid_name(nm)])
			else:
				cands.append(SAY_RARE_DAY % WORLD_NAMES[pid])
				cands.append(SAY_RARE_DAY_2 % mid_name(nm))
	for l: Variant in cands:
		if str(l).length() > int(worst["n"]):
			worst = {"n": str(l).length(), "line": str(l)}
	return worst


## DEV (synthetic, no input): compares this table with a LIVE safari's schedule. Call while a safari is
## AWAKE; prints one FIELDNOTES CHECK line per rare event and returns false on any mismatch of an event that
## runs today (id, tier, place more than 2 degrees / start more than 0.5 s off), or when the notes name a
## sight not eligible today.
static func dev_check(s: PlanetSafari) -> bool:
	var ok := true
	var pid := s.planet_id
	var want := sight_for(pid, s.day)
	var found_want := false
	for ev: Dictionary in s._events:
		var tier := str(ev.get("tier", ""))
		if tier == "":
			tier = str(PlanetSafari.roster_entry(pid, str(ev["id"])).get("tier", ""))
		if tier != "rare" and tier != "rare_day":
			continue
		var d: Vector3 = ev["dir"]
		var around := rad_to_deg(s.start_dir.angle_to(d))
		var h := d - s.start_dir * d.dot(s.start_dir)
		var bearing := 0.0
		if h.length() > 1e-4:
			bearing = -rad_to_deg(s.start_fwd.signed_angle_to(h.normalized(), s.start_dir))
		var row: Array = PLACES.get(pid, {}).get(tier, [])
		var good := not row.is_empty() and str(row[0]) == str(ev["id"]) and absf(around - float(row[1])) < 2.0 \
			and absf(wrapf(bearing - float(row[2]), -180.0, 180.0)) < 2.0 and absf(float(ev["start"]) - float(row[4])) < 0.5
		if str(ev["id"]) == str(want.get("id", "")):
			found_want = bool(ev["eligible"])
		print("FIELDNOTES CHECK pid=%s day=%d rare_day=%s ev=%s tier=%s eligible=%s around=%.1f bearing=%.1f start=%.1f table=%s -> %s" % [
			pid, s.day, str(s.is_rare_day), ev["id"], tier, str(ev["eligible"]), around, bearing, float(ev["start"]), str(row),
			"OK" if good else "MISMATCH"])
		# Only what can run today counts: a rare-day event is laid out elsewhere (or not at all) on other days.
		if bool(ev["eligible"]):
			ok = ok and good
	print("FIELDNOTES CHECK pid=%s notes_name=%s eligible_today=%s" % [pid, str(want.get("id", "")), str(found_want)])
	return ok and found_want
