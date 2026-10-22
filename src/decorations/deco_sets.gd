extends RefCounted
## FURNITURE SETS - the registry and the rules (docs/SETS_SPEC.md 1, 4, 5). Static only; preload it by path:
##   const DecoSets := preload("res://src/decorations/deco_sets.gd")
##
## Eight sets. Five NEIGHBOUR sets come from src/decorations/sets/set_<id>.gd (6 pieces + 1 bonus + an outfit);
## three older groups are DISPLAY sets with no bonus: "cozy" (decoration_catalog.gd COZY, the Commons crowd's
## gift set), "tangle" (JUNGLE, Moss's stall) and "normal" (STAMPS, Norm's card).
##
## The registry reads the set FILES, not the Catalog, so the Sets page can name a piece whose scene is not built
## yet. Everything that HANDS OUT an item (gifts, the order book, the bonus) only uses ids the Catalog actually
## registered (decoration_catalog.gd skips a row with no scene), so nothing unplaceable is ever given.
##
## "Collected" is GameState.is_collected(id): ever owned, never undone by placing or selling.

const DecorationCatalog := preload("res://src/decorations/decoration_catalog.gd")

## The Commons crowd (and anyone else who owns no set) gives from this one.
const COMMONS_SET := "cozy"
## GameState flag per set, set the moment its bonus is granted. Saved with the other flags.
const BONUS_FLAG := "set_bonus_%s"

static var _cache: Array = []
static var _by_id: Dictionary = {}
static var _set_of: Dictionary = {}


# ============================================================================= registry
## Every set, neighbour sets first (in SET_FILES order), then cozy, tangle, normal. Each entry:
##   {"id", "name", "neighbour" (npc id or ""), "giver" (display name), "blurb", "outfit": [clothing ids],
##    "pieces": [deco ids], "names": {id: name}, "bonus": deco id or "", "bonus_name", "display_only": bool,
##    "orderable": bool, "where": "Pip & Pop · Bolt's favours"}
static func all_sets() -> Array:
	if _cache.is_empty():
		_build()
	return _cache


static func get_set(set_id: String) -> Dictionary:
	if _cache.is_empty():
		_build()
	return _by_id.get(set_id, {})


## The set an item belongs to ("" when none). Works for pieces, bonuses and outfit clothing.
static func set_of(item_id: String) -> String:
	if _cache.is_empty():
		_build()
	return str(_set_of.get(item_id, ""))


static func _build() -> void:
	_cache = []
	_by_id = {}
	_set_of = {}
	for path: String in DecorationCatalog.SET_FILES:
		if not ResourceLoader.exists(path):
			continue
		var s: Variant = load(path)
		var info: Dictionary = s.SET
		var sid := str(info.get("id", ""))
		var pieces: Array = []
		var names: Dictionary = {}
		for r: Array in (s.PIECES as Array):
			var pid := "deco_" + str(r[0])
			pieces.append(pid)
			names[pid] = str(r[1])
		var bonus_row: Array = s.BONUS
		var bonus := "deco_" + str(bonus_row[0])
		names[bonus] = str(bonus_row[1])
		var npc := str(info.get("neighbour", ""))
		var giver := _npc_name(npc)
		_add({"id": sid, "name": str(info.get("name", sid)), "neighbour": npc, "giver": giver,
			"blurb": str(info.get("blurb", "")), "outfit": (info.get("outfit", []) as Array).duplicate(),
			"pieces": pieces, "names": names, "bonus": bonus, "bonus_name": str(bonus_row[1]),
			"display_only": false, "orderable": true,
			"where": "Pip & Pop · %s's favours" % giver})
	_add(_display_set("cozy", "Cozy Home", "Pip & Pop", DecorationCatalog.COZY,
		"Soft, warm and homey. The Commons' favourite things.", true, "Pip & Pop · Commons favours"))
	_add(_display_set("tangle", "Moss's Tangle Goods", "Moss", DecorationCatalog.JUNGLE,
		"Ferns, stumps and glowing pods from the swamp.", false, "Moss's stall on the Tangle"))
	_add(_display_set("normal", "Totally Normal Collection", "Norm", DecorationCatalog.STAMPS,
		"Perfectly ordinary human things. Nothing to see here.", false, "Norm's stamp card"))


static func _display_set(sid: String, set_name: String, giver: String, rows: Array, blurb: String,
		orderable: bool, where: String) -> Dictionary:
	var pieces: Array = []
	var names: Dictionary = {}
	for r: Array in rows:
		var pid := "deco_" + str(r[0])
		pieces.append(pid)
		names[pid] = str(r[1])
	return {"id": sid, "name": set_name, "neighbour": "", "giver": giver, "blurb": blurb, "outfit": [],
		"pieces": pieces, "names": names, "bonus": "", "bonus_name": "", "display_only": true,
		"orderable": orderable, "where": where}


static func _add(entry: Dictionary) -> void:
	_cache.append(entry)
	_by_id[str(entry["id"])] = entry
	for pid: String in entry["pieces"]:
		_set_of[pid] = entry["id"]
	if str(entry["bonus"]) != "":
		_set_of[str(entry["bonus"])] = entry["id"]
	for cid: String in entry["outfit"]:
		_set_of[cid] = entry["id"]


static func _npc_name(npc_id: String) -> String:
	var d: Dictionary = NpcData.get_data(npc_id)
	return str(d.get("display_name", npc_id.capitalize())) if not d.is_empty() else npc_id.capitalize()


# ============================================================================= progress
## How many of the set's pieces (never the bonus, never the outfit) have ever been collected.
static func collected_count(set_id: String) -> int:
	var n := 0
	for pid: String in get_set(set_id).get("pieces", []):
		if GameState.is_collected(pid):
			n += 1
	return n


static func piece_total(set_id: String) -> int:
	return (get_set(set_id).get("pieces", []) as Array).size()


static func is_complete(set_id: String) -> bool:
	var total := piece_total(set_id)
	return total > 0 and collected_count(set_id) >= total


static func bonus_earned(set_id: String) -> bool:
	return GameState.flag(BONUS_FLAG % set_id)


## "Tinker Workshop 3/6" for a set piece (or its bonus/outfit), "" for anything else.
static func progress_text(item_id: String) -> String:
	var sid := set_of(item_id)
	if sid == "":
		return ""
	var s := get_set(sid)
	# Outfit clothes do not count toward n/6, so "Gearworks Suit! (Tinker Workshop 0/6)" read wrong.
	if str(Catalog.get_item(item_id).get("kind", "")) == "clothing":
		return str(s.get("name", sid))
	return "%s %d/%d" % [str(s.get("name", sid)), collected_count(sid), piece_total(sid)]


## A toast line with the set suffix: "You got a Cog Clock! (Tinker Workshop 3/6)".
static func with_progress(line: String, item_id: String) -> String:
	var p := progress_text(item_id)
	return line if p == "" else "%s (%s)" % [line, p]


## "a Cog Clock" / "an Oil-Can Lamp".
static func a_an(item_name: String) -> String:
	var vowel := item_name != "" and "AEIOUaeiou".contains(item_name.left(1))
	return ("an " if vowel else "a ") + item_name


# ============================================================================= gifts (SETS_SPEC 4.1)
## The set a neighbour gives from: their own set, else the Commons' Cozy Home set.
static func gift_set_for(npc_id: String) -> String:
	for s: Dictionary in all_sets():
		if str(s.get("neighbour", "")) == npc_id and npc_id != "":
			return str(s["id"])
	return COMMONS_SET


## Ids a favour from `npc_id` may pay: pieces of their set plus its outfit, registered in the Catalog and never
## collected. Never the bonus. Empty = fall back to the old random roll.
static func gift_pool(npc_id: String) -> Array:
	var s := get_set(gift_set_for(npc_id))
	var out: Array = []
	for id: String in (s.get("pieces", []) as Array) + (s.get("outfit", []) as Array):
		if Catalog.has_item(id) and not GameState.is_collected(id):
			out.append(id)
	return out


# ============================================================================= order book (SETS_SPEC 4.3)
## Every orderable piece of every set with at least one piece collected: a real Catalog def, a real price, no
## "source" (so never a bonus, Moss's or Norm's goods). Ordered set by set, cheapest first inside a set.
static func order_book() -> Array:
	var out: Array = []
	for s: Dictionary in all_sets():
		if not bool(s.get("orderable", false)) or collected_count(str(s["id"])) <= 0:
			continue
		var defs: Array = []
		for pid: String in s["pieces"]:
			var def: Dictionary = Catalog.get_item(pid)
			if def.is_empty() or int(def.get("price", 0)) <= 0 or str(def.get("source", "")) != "":
				continue
			defs.append(def)
		defs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("price", 0)) < int(b.get("price", 0)))
		out.append_array(defs)
	return out


# ============================================================================= set bonus (SETS_SPEC 4.2)
## Called by GameState the first time an id is recorded as collected. When that makes a neighbour set complete,
## the bonus goes into the bag ONCE (flag first, so the bonus's own add_item cannot re-enter), then a toast and
## the quest_complete sound on the next frame - after whatever toast the caller (a favour, a purchase) emits.
## Returns the bonus id granted, or "".
static func on_collected(item_id: String) -> String:
	var sid := set_of(item_id)
	if sid == "":
		return ""
	var s := get_set(sid)
	var bonus := str(s.get("bonus", ""))
	if bonus == "" or bonus_earned(sid) or not is_complete(sid):
		return ""
	if not Catalog.has_item(bonus):
		push_warning("DecoSets: %s is complete but its bonus %s has no catalog entry yet" % [sid, bonus])
		return ""
	GameState.set_flag(BONUS_FLAG % sid)
	GameState.add_item(bonus, 1)
	var line := "%s complete! %s sent %s" % [str(s.get("name", sid)), str(s.get("giver", "")),
		a_an(str(Catalog.get_item(bonus).get("name", s.get("bonus_name", ""))))]
	(func() -> void:
		EventBus.toast_requested.emit(line, bonus)
		AudioManager.play_sfx("quest_complete")).call_deferred()
	print("[DecoSets] bonus %s granted for %s" % [bonus, sid])
	return bonus
