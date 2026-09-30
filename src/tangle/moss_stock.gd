class_name MossStock
extends RefCounted
## MOSS'S SHELF (docs/JUNGLE_PLANET_SPEC.md 3): jungle-only goods, 5 shown a day out of 8, rotating by
## the game day, priced by the economy tiers (docs/ECONOMY_REPORT.md "Rulings").
##
## JUNGLE-ONLY, AND HOW. Every Moss item is registered in the ordinary catalogs
## (decoration_catalog.gd, clothing_catalog.gd - so placing, the bag and saving all work as for any
## other item) with `"price": 0` and `"source": "moss"`, the same shape as Norm's rewards
## (src/campaign/norm_rewards.gd):
##   * price 0  -> Catalog.store_items() skips it, so Cosmo Depot and Suit-Up never stock it;
##   * source   -> Catalog.random_reward_decoration() skips it, so no favour ever gives one away.
## The real price lives in `"stall_price"` and is stamped onto a copy of the def here, which is what
## the ShopPanel charges (ShopPanel.price_for reads the def it was handed).
## The cost of doing it this way: Pip & Pop's SELL list skips price-0 items, so a jungle item cannot be
## sold back (a Norm trophy cannot either). The lead can change that with one line in
## Catalog.store_items (skip `source` != "") and a real `price` - see the J3 report.
##
## THE TIERS (D ~ 800, a mixed player's day):
##   everyday 0.3-0.5 D (240-400)   Spiral Fern 320, Lily Pad Suit 360, Lily-Pad Lamp 380
##   most     1-2 D     (800-1600)  Mossy Stump Seat 1000, Bog Moss Suit 1200, Glow Pod 1400
##   rare     3-5 D     (2400-4000) Swamp Night Suit 2800, Glow-Vine Arch 3200
## (no showpiece: a stall in a swamp is not where the 7 D things are.)

const SOURCE := "moss"
## Items shown per day.
const SHOWN := 5
## The day's shelf always carries at least this many everyday items, so a new visitor can buy
## something (Cosmo Depot's "always stock the cheapest" rule, scaled to a five-item shelf).
const MIN_EVERYDAY := 1
const EVERYDAY_MAX := 400

## Tier of a price, by the rulings' bands.
static func tier_of(price: int) -> String:
	if price <= 0:
		return "none"
	if price <= 400:
		return "everyday"
	if price <= 1600:
		return "most"
	if price <= 4000:
		return "rare"
	return "showpiece"


## Every Moss item in the catalog (decorations and clothes), as registered.
static func pool() -> Array:
	var out: Array = []
	for d: Dictionary in Catalog.all_items():
		if str(d.get("source", "")) == SOURCE and int(d.get("stall_price", 0)) > 0:
			out.append(d)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", "")))
	return out


## A copy of `def` carrying its stall price as "price" - what the ShopPanel charges and shows.
static func priced(def: Dictionary) -> Dictionary:
	var d := def.duplicate(true)
	d["price"] = int(def.get("stall_price", 0))
	return d


## Today's shelf: SHOWN items seeded by the day, at least MIN_EVERYDAY of them everyday-priced, and
## at least one decoration and one piece of clothing when the pool has both. Cheapest first, the way
## every shelf in the game is laid out. Same day -> same shelf, however often you ask.
static func today(day: int = -1) -> Array:
	if day < 0:
		day = GameState.day_count
	var all := pool()
	if all.size() <= SHOWN:
		return _finish(all)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["moss_stall", day])
	var shuffled := all.duplicate()
	# Fisher-Yates with the day's rng, so the pick does not depend on Array.shuffle's global seed.
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = t
	var chosen: Array = []
	var used: Dictionary = {}
	# 1. the everyday guarantee
	for d: Dictionary in shuffled:
		if chosen.size() >= MIN_EVERYDAY:
			break
		if int(d.get("stall_price", 0)) <= EVERYDAY_MAX:
			chosen.append(d)
			used[d["id"]] = true
	# 2. one of each kind
	for kind: String in ["decoration", "clothing"]:
		var has_kind := chosen.any(func(c: Dictionary) -> bool: return str(c.get("kind", "")) == kind)
		if has_kind:
			continue
		for d: Dictionary in shuffled:
			if not used.has(d["id"]) and str(d.get("kind", "")) == kind:
				chosen.append(d)
				used[d["id"]] = true
				break
	# 3. fill
	for d: Dictionary in shuffled:
		if chosen.size() >= SHOWN:
			break
		if not used.has(d["id"]):
			chosen.append(d)
			used[d["id"]] = true
	return _finish(chosen)


static func _finish(defs: Array) -> Array:
	var out: Array = []
	for d: Dictionary in defs:
		out.append(priced(d))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("price", 0)) < int(b.get("price", 0)))
	return out
