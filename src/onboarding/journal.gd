class_name Journal
extends RefCounted
## The quest log's data layer: turns `GameState.favors` into rows a panel can draw, and — the bit the
## integration critic asked for — works out **where the thing actually is**.
##
## Zorp asks for Stardust Shards and Stardust Shards do not grow on Zorp. That is good design (it is
## a reason to fly home), but until now nothing on screen said so. `where_line()` reads every
## `PlanetData.collectible_kind` and answers "Found on: Little Orbit, Starport Plaza".
##
##   for row in Journal.entries():
##       print(row["who"], row["title"], row["progress_text"], row["where"])
##
## Pure data: no nodes, no signals. `src/ui/journal/journal_panel.gd` draws it; anything else
## (a Town Hall bulletin, a HUD tracker) can read the same rows.

const PLANET_DATA_DIR := "res://src/planet/data/"

## planet id -> Array[String] of collectible ids that grow there. Built once per run.
static var _grows: Dictionary = {}


# ============================================================================= rows
## One row per active favour, in a stable order (ready-to-hand-in first, then by neighbour name).
## Keys: id, npc, who, who_planet, kind, title, item, count, progress, progress_text, ratio,
##       ready, where, accent.
static func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active":
			continue
		out.append(_row(key, f))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["ready"]) != bool(b["ready"]):
			return bool(a["ready"])
		return str(a["who"]) < str(b["who"]))
	return out


## Number of favours the player has promised.
static func active_count() -> int:
	var n := 0
	for key: String in GameState.favors:
		if str(GameState.favors[key].get("state", "")) == "active":
			n += 1
	return n


## Favours whose goods are already in the bag, waiting to be handed in.
static func ready_count() -> int:
	var n := 0
	for e: Dictionary in entries():
		if bool(e["ready"]):
			n += 1
	return n


static func _row(key: String, f: Dictionary) -> Dictionary:
	var npc_id := str(f.get("npc", ""))
	var kind := str(f.get("type", "fetch"))
	var item := str(f.get("target_item", ""))
	var count := maxi(1, int(f.get("count", 1)))
	var progress := clampi(int(f.get("progress", 0)), 0, count)
	var row := {
		"id": key,
		"npc": npc_id,
		"who": npc_name(npc_id),
		"who_planet": planet_name(npc_planet(npc_id)),
		"kind": kind,
		"item": item,
		"count": count,
		"progress": progress,
		"accent": npc_accent(npc_id),
	}
	if kind == "deliver":
		var to_id := str(f.get("deliver_to", ""))
		var have := GameState.has_item(item)
		row["title"] = "%s's parcel for %s" % [row["who"], npc_name(to_id)]
		row["progress_text"] = "In your bag" if have else "Not in your bag"
		row["ratio"] = 1.0 if have else 0.0
		row["ready"] = have
		row["where"] = "%s is on %s" % [npc_name(to_id), planet_name(npc_planet(to_id))]
		# A delivery is handed to the RECIPIENT, never back to the neighbour who asked — which is
		# exactly the mistake a generic "take it to <who>" line would make.
		row["next"] = ("Take it to %s on %s" % [npc_name(to_id), planet_name(npc_planet(to_id))]) if have \
			else "Ask %s for the parcel again." % row["who"]
	else:
		row["title"] = "%d %s for %s" % [count, item_name(item, count), row["who"]]
		row["progress_text"] = "%d of %d" % [progress, count]
		row["ratio"] = float(progress) / float(count)
		row["ready"] = progress >= count
		row["where"] = where_line(item)
		row["next"] = ("Ready! Take them to %s on %s" % [row["who"], row["who_planet"]]) if progress >= count \
			else where_line(item)
	return row


## One line telling the player what to do next with this row.
static func next_step(row: Dictionary) -> String:
	return str(row.get("next", row.get("where", "")))


# ============================================================================= where things grow
## "Found on: Little Orbit, Starport Plaza" — the answer to "Zorp wants shards, but where ARE they?".
static func where_line(item_id: String) -> String:
	var places := sources_for(item_id)
	if places.is_empty():
		return "Ask around — nobody knows where these come from."
	if places.size() == 1:
		return "Found on %s" % places[0]
	return "Found on %s" % ", ".join(places)


## Display names of every planet whose surface grows `item_id`, home planet first.
static func sources_for(item_id: String) -> PackedStringArray:
	_build_grow_table()
	var out: PackedStringArray = []
	for pid: String in GameState.PLANET_IDS:
		var kinds: Array = _grows.get(pid, [])
		if kinds.has(item_id):
			out.append(planet_name(pid))
	return out


## Every collectible in the game with the planets it grows on — the empty-state "field guide".
## Array of {"item": id, "name": String, "where": String, "color": String}.
static func field_guide() -> Array[Dictionary]:
	_build_grow_table()
	var seen: Dictionary = {}
	var out: Array[Dictionary] = []
	for pid: String in GameState.PLANET_IDS:
		for item: String in _grows.get(pid, []):
			if seen.has(item):
				continue
			seen[item] = true
			var def := Catalog.get_item(item)
			out.append({
				"item": item,
				"name": item_name(item, 2),
				"where": where_line(item),
				"planets": ", ".join(sources_for(item)),
				"color": str(def.get("icon_color", "#ffe27a")),
			})
	return out


static func _build_grow_table() -> void:
	if not _grows.is_empty():
		return
	for pid: String in GameState.PLANET_IDS:
		var path := PLANET_DATA_DIR + pid + ".tres"
		if not ResourceLoader.exists(path):
			continue
		var data: Resource = load(path)
		if data == null:
			continue
		var kinds: Array = []
		for raw: String in str(data.get("collectible_kind")).split(",", false):
			var k := raw.strip_edges()
			if k != "":
				kinds.append(k)
		_grows[pid] = kinds


# ============================================================================= names
## Planet display name. "home" follows whatever the player named it at the Town Hall.
static func planet_name(planet_id: String) -> String:
	if planet_id == "":
		return "somewhere out there"
	if planet_id == "home":
		return GameState.home_planet_name
	var path := PLANET_DATA_DIR + planet_id + ".tres"
	if ResourceLoader.exists(path):
		var data: Resource = load(path)
		if data != null and data.get("display_name") != null and str(data.get("display_name")) != "":
			return str(data.get("display_name"))
	return planet_id.capitalize()


static func npc_name(npc_id: String) -> String:
	if npc_id == "":
		return "someone"
	return str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))


static func npc_planet(npc_id: String) -> String:
	return str(NpcData.get_data(npc_id).get("planet", ""))


static func npc_accent(npc_id: String) -> Color:
	return Color(str(NpcData.get_data(npc_id).get("accent", "#4c6fff")))


## "3 Gear Bits" / "1 Gear Bit" — pluralised only when the catalogue has no plural of its own.
static func item_name(item_id: String, count: int) -> String:
	var def := Catalog.get_item(item_id)
	var base := str(def.get("name", UIStyle.pretty_id(item_id)))
	if count > 1 and not base.ends_with("s"):
		return base + "s"
	return base
