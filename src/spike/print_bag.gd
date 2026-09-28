class_name PrintBag
extends RefCounted
## THE PRINT STUB for the sky-watching spike (2026-09-20). A deliberately tiny, self-contained
## store so the GLOOP builder does not depend on the SKY builder's file existing yet.
##
## A PRINT IS A PLAIN DICTIONARY. This is the whole assumed shape — if the real telescope produces
## something different, only the four reads in `pay_for()` / `label()` have to move:
##
##   {
##     "id":        String,   unique-ish, e.g. "print_d3_002". Used as the payout seed.
##     "name":      String,   what the player sees, <= 24 chars, e.g. "Ring of Vela"
##     "rarity":    float,    0..1. How unusual the sight was.
##     "sharpness": float,    0..1. How well it was focused.
##     "when":      String,   "night" | "morning" | "dusk" | "dawn". Flavour only, never paid on.
##   }
##
## WHERE THEY LIVE. In `GameState.flags`, which is a plain Dictionary that already saves and loads:
##   flags["spike_prints"]    Array  — prints in the player's satchel, not yet handed in
##   flags["gloop_table"]     Array  — prints on Gloop's table, waiting to sell
##   flags["gloop_drop_day"]  int    — the day the table batch was handed in
##   flags["gloop_paid"]      Dict   — the last payout, so the table can re-tell it
##
## SPIKE ONLY. `flags` is meant for booleans; a real build would give prints their own field on
## GameState and their own save block. Nothing here is a contract.

const BAG := "spike_prints"
const TABLE := "gloop_table"
const DROP_DAY := "gloop_drop_day"
const PAID := "gloop_paid"

## What a print pays, in stardust. Rare and sharp pay more, and there is no free parameter beyond
## these three numbers: a worthless blur is 8, a perfect rare is 84.
const PAY_BASE := 8.0
const PAY_RARITY := 46.0
const PAY_SHARP := 30.0


## Builds a print. The SKY builder can call this or just hand over a dictionary of the same shape.
static func make(id: String, print_name: String, rarity: float, sharpness: float, when: String = "night") -> Dictionary:
	return {
		"id": id,
		"name": print_name,
		"rarity": clampf(rarity, 0.0, 1.0),
		"sharpness": clampf(sharpness, 0.0, 1.0),
		"when": when,
	}


## WIRE round (2026-09-21). A SAFARI print is priced by SafariScoring - rarity 1..4, sharpness and
## the moment it was caught in, per docs/CORE_LOOP.md's lead ruling (skill and moment swing 40.5,
## rarity 18). A TELESCOPE print has no rarity rung and no moment recorded, so it keeps the old
## three-number formula below and nothing about the tripod changes. The branch is on the data, not
## on a flag somebody has to remember to set.
static func pay_for(p: Dictionary) -> int:
	if p.has("rarity_rung"):
		return SafariScoring.price_of(int(p["rarity_rung"]), float(p.get("sharpness", 0.0)),
			float(p.get("moment_mult", 1.0)))
	return int(round(PAY_BASE + PAY_RARITY * float(p.get("rarity", 0.0)) + PAY_SHARP * float(p.get("sharpness", 0.0))))


## A short human label, for a toast or a line. Kept under the 60-character writing rule by callers.
static func label(p: Dictionary) -> String:
	return str(p.get("name", "a print"))


# -------------------------------------------------------------------------------- the satchel
static func bag() -> Array:
	var a: Variant = GameState.flags.get(BAG, [])
	return a if a is Array else []


static func add(p: Dictionary) -> void:
	var a := bag()
	a.append(p)
	GameState.flags[BAG] = a


static func bag_count() -> int:
	return bag().size()


static func clear_bag() -> void:
	GameState.flags[BAG] = []


# ---------------------------------------------------------------------------------- the table
static func table() -> Array:
	var a: Variant = GameState.flags.get(TABLE, [])
	return a if a is Array else []


## Moves the whole satchel onto Gloop's table and stamps today's date on it.
static func drop_all() -> Array:
	var moved := bag()
	if moved.is_empty():
		return []
	var on_table := table()
	on_table.append_array(moved)
	GameState.flags[TABLE] = on_table
	GameState.flags[DROP_DAY] = GameState.day_count
	clear_bag()
	return moved


static func drop_day() -> int:
	return int(GameState.flags.get(DROP_DAY, 0))


static func clear_table() -> void:
	GameState.flags[TABLE] = []
	GameState.flags[DROP_DAY] = 0


## True when there is a batch on the table that was handed in on an EARLIER day, i.e. Gloop has had
## a night to sell it.
static func payout_ready() -> bool:
	return not table().is_empty() and GameState.day_count > drop_day() and drop_day() > 0


# ------------------------------------------------------- GLUE (sky-review, 2026-09-20)
## The SKY builder's telescope makes a `SkyPrint` OBJECT (title, rarity 1..3, a preview Image).
## Gloop's table stores plain Dictionaries in `GameState.flags` so they survive a save. This is the
## one seam between the two spikes: it flattens the object into the table's shape.
##
## rarity: the forecast's 1..3 becomes 0..1 (common 0.0, uncommon 0.5, rare 1.0), so the pay rule
## (8 + 46*rarity + 30*sharpness) is unchanged and a perfect rare is still 84.
static func from_sky(p: SkyPrint) -> Dictionary:
	var nm := p.title
	if nm.length() > 24:
		nm = nm.substr(0, 23).strip_edges() + "."
	var d := {
		"id": "%s_d%d_%02d" % [p.event_id, p.day, int(p.hour)],
		"name": nm,
		"rarity": clampf((float(p.rarity) - 1.0) / 3.0, 0.0, 1.0),
		"sharpness": p.sharpness,
		"when": "morning" if p.hour < 9.0 else "night",
		"grade": p.grade,
	}
	# WIRE round: a SAFARI catch carries its rung and its moment, which is what `pay_for` prices on.
	# A tripod print sets neither flag and is untouched. `rarity` above stays the old 0..1 float so
	# an already-saved table still sells the old way - over FOUR rungs now, because rarity 4 exists.
	if p.from_safari:
		d["rarity_rung"] = p.rarity
		d["moment_mult"] = p.moment_mult
	return d


## What the telescope calls. One line, and the print is in the satchel Gloop reads.
static func take_sky_print(p: SkyPrint) -> Dictionary:
	var d := from_sky(p)
	add(d)
	return d


# ------------------------------------------------------- GLUE (STORY_HOME_SPEC ruling 13, 5.8)
## Gloop sells copies of your planet photos too. `photo` is one entry of PlanetSafari.last_session's
## "photos" (planet_safari.gd, THE END): its rarity (1..4), craft (0..1, the planet's own CRAFT) and
## moment_mult already price it exactly as the review card showed it (SafariScoring.price_of), so
## `pay_for` on the print this makes returns that same number - one price list, same as `from_sky`.
static func from_planet_photo(photo: Dictionary, planet_id: String, is_night: bool = false) -> Dictionary:
	var nm := str(photo.get("subject_name", ""))
	if nm == "":
		nm = "A planet photo"
	if nm.length() > 24:
		nm = nm.substr(0, 23).strip_edges() + "."
	return {
		"id": "%s_ps%d_%02d" % [planet_id, int(photo.get("t", 0.0)), int(photo.get("index", 0))],
		"name": nm,
		"rarity": clampf((float(photo.get("rarity", 1)) - 1.0) / 3.0, 0.0, 1.0),
		"sharpness": clampf(float(photo.get("craft", 0.0)), 0.0, 1.0),
		"when": "night" if is_night else "morning",
		"grade": str(photo.get("grade", "")),
		"rarity_rung": int(photo.get("rarity", 1)),
		"moment_mult": float(photo.get("moment_mult", 1.0)),
	}
