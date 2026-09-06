extends Node
## Item catalog. Decoration builder fills DECORATIONS; hub/clothes builder fills CLOTHING.
## Each item definition is a Dictionary:
## {
##   "id": "deco_moon_lamp", "name": "Moon Lamp", "kind": "decoration" | "clothing" | "collectible" | "favor_item",
##   "category": "lights" | "furniture" | "plants" | "tech" | "signs" | "fun" | "suit" | "hat" | "backpack" | "material",
##   "rarity": "common" | "uncommon" | "rare" | "legendary",
##   "price": 240,                      # stardust; 0 = not sold in store
##   "desc": "A soft glowing moon on a stick.",
##   "scene": "res://src/decorations/items/moon_lamp.tscn",  # decorations only. Root must be Node3D, origin at ground contact.
##   "footprint": 0.8,                  # approximate radius in meters for placement collision
##   "icon_color": "#f7e27a",           # used for inventory swatches when no icon texture
##   "style": {...}                     # clothing only: keys merged into GameState.player_style
## }

var _items: Dictionary = {}

func _ready() -> void:
	_register_builtin()
	for path in ["res://src/decorations/decoration_catalog.gd", "res://src/hub/clothing_catalog.gd"]:
		if ResourceLoader.exists(path):
			var script = load(path)
			if script:
				var list: Array = script.new().get_items()
				for it in list:
					register(it)

func _register_builtin() -> void:
	register({"id": "stardust_shard", "name": "Stardust Shard", "kind": "collectible", "category": "material", "rarity": "common", "price": 0, "desc": "Glittering dust that fell from a passing comet.", "icon_color": "#ffe27a"})
	register({"id": "moon_flower", "name": "Moon Flower", "kind": "collectible", "category": "material", "rarity": "common", "price": 0, "desc": "A pale bloom that only opens under starlight.", "icon_color": "#cfe4ff"})
	register({"id": "crystal_chunk", "name": "Crystal Chunk", "kind": "collectible", "category": "material", "rarity": "uncommon", "price": 0, "desc": "Hums faintly when you hold it.", "icon_color": "#b58cff"})
	register({"id": "gear_bit", "name": "Gear Bit", "kind": "collectible", "category": "material", "rarity": "common", "price": 0, "desc": "A little brass gear. Bolt would love this.", "icon_color": "#ffb05c"})

func register(def: Dictionary) -> void:
	assert(def.has("id") and def.has("name") and def.has("kind"), "Catalog item missing id/name/kind")
	_items[def["id"]] = def

func get_item(id: String) -> Dictionary:
	return _items.get(id, {})

func has_item(id: String) -> bool:
	return _items.has(id)

func all_items() -> Array:
	return _items.values()

func items_of_kind(kind: String) -> Array:
	return _items.values().filter(func(d): return d.get("kind", "") == kind)

func store_items(kind: String) -> Array:
	return _items.values().filter(func(d): return d.get("kind", "") == kind and int(d.get("price", 0)) > 0)

const RARITY_WEIGHTS := {"common": 60, "uncommon": 28, "rare": 10, "legendary": 2}

## Weighted random decoration, used for favor rewards. Never returns an item the player owns 3+ of.
func random_reward_decoration(rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool: Array = items_of_kind("decoration")
	if pool.is_empty():
		return {}
	var candidates: Array = pool.filter(func(d): return GameState.item_count(d["id"]) < 3)
	if candidates.is_empty():
		candidates = pool
	var total := 0
	for d in candidates:
		total += int(RARITY_WEIGHTS.get(d.get("rarity", "common"), 10))
	var roll := rng.randi_range(0, max(0, total - 1))
	for d in candidates:
		roll -= int(RARITY_WEIGHTS.get(d.get("rarity", "common"), 10))
		if roll < 0:
			return d
	return candidates.back()
