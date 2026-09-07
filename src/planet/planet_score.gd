class_name PlanetScore
extends RefCounted
## Turns the home planet's state into a 0-100 score and a 1-5 star rating (docs/ARCHITECTURE.md §11).
## Pure function of GameState — nothing here is stored; call compute() whenever you need a fresh
## number (HUD, Town Hall stats, a future rating popup). Cheap: a handful of dictionary reads.
##
## Score = decor points (rarity-weighted, capped) + variety bonus (categories covered)
##       + trust bonus (how much your neighbours like you) - trash penalty (junk piled up at home).

const RARITY_POINTS := {"common": 2, "uncommon": 4, "rare": 7, "legendary": 12}
const MAX_DECOR_POINTS := 50.0
const CATEGORY_BONUS := 5.0
const MAX_VARIETY_POINTS := 30.0
const MAX_TRUST_POINTS := 10.0
const TRASH_PENALTY_PER_PIECE := 5.0
## Every neighbour whose friendship counts toward the home rating. DELIBERATE REBALANCE, AND THE
## SECOND ONE: Fen and Grig took the divisor at `trust_points` from 2 to 4, and Vela takes it from
## 4 to 5. Each step dilutes the trust component of every existing save's rating until the player
## has met the new neighbour. That is the intended cost of the system growing - their friendship
## should count too - and the whole component is at most 10 points of a 100-point score, so the
## worst case here is a 2-point dip. Anything reading this list (Town Hall's stats readout) must
## LOOP, not name names.
const TRUST_NPCS: PackedStringArray = ["zorp", "bolt", "fen", "grig", "vela"]

const STAR_THRESHOLDS := [20.0, 40.0, 60.0, 80.0]   # score >= threshold -> that many stars past 1


## {"score": float 0-100, "stars": int 1-5, "decor_points", "variety_points", "trust_points",
##  "trash_penalty", "trash_count"} — the breakdown is there so UI/dialogue can explain the number.
static func compute(planet_id: String = "home") -> Dictionary:
	var placed: Array = GameState.placed_decorations.get(planet_id, [])
	var decor_points := 0.0
	var categories: Dictionary = {}
	for entry in placed:
		var def := Catalog.get_item(str(entry.get("item", "")))
		if def.is_empty():
			continue
		decor_points += float(RARITY_POINTS.get(str(def.get("rarity", "common")), 2))
		categories[str(def.get("category", ""))] = true
	decor_points = minf(decor_points, MAX_DECOR_POINTS)
	var variety_points: float = minf(categories.size() * CATEGORY_BONUS, MAX_VARIETY_POINTS)

	var trust_sum := 0.0
	for npc_id in TRUST_NPCS:
		trust_sum += float(GameState.npc_data(npc_id).get("friendship", 0))
	var trust_points: float = minf((trust_sum / TRUST_NPCS.size()) / 100.0 * MAX_TRUST_POINTS, MAX_TRUST_POINTS)

	var trash_count: int = GameState.trash_home.size() if planet_id == "home" else 0
	var trash_penalty: float = trash_count * TRASH_PENALTY_PER_PIECE

	var score := clampf(decor_points + variety_points + trust_points - trash_penalty, 0.0, 100.0)
	return {
		"score": score,
		"stars": stars_for(score),
		"decor_points": decor_points,
		"variety_points": variety_points,
		"trust_points": trust_points,
		"trash_penalty": trash_penalty,
		"trash_count": trash_count,
	}


static func stars_for(score: float) -> int:
	var stars := 1
	for t in STAR_THRESHOLDS:
		if score >= t:
			stars += 1
	return stars


## "3.5 stars" style not needed — stars are whole. This gives the little filled/empty glyph string,
## e.g. "★★★☆☆", for anywhere that just wants to print a rating without building UI.
static func star_glyphs(stars: int) -> String:
	var s := ""
	for i in 5:
		s += "★" if i < stars else "☆"
	return s
