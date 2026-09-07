class_name FavorSystem
extends Node
## Generates, tracks and pays out neighbour favors (ARCHITECTURE §6). One instance per world, created
## lazily as a child of /root/World:
##
##   var favors := FavorSystem.get_or_create()
##   if favors.can_offer("zorp"):
##       var offer := favors.make_offer("zorp")     # nothing is committed yet
##       ... ask the player ...
##       favors.accept(offer)                       # or favors.decline("zorp")
##   if favors.is_ready_to_turn_in(favor): favors.complete(favor, npc)
##
## Templates
##   fetch    collect N of the collectible that grows on that NPC's own planet (extra ones are
##            spawned near the NPC so the errand is always completable)
##   bring    N of a material from anywhere in the system
##   deliver  carry "gift_<npc>" to a different neighbour, usually on another planet
##
## State lives in GameState.favors (plain dictionaries, so it saves and loads), and is restored on
## every planet load. Progress is driven by EventBus.item_added / collectible_picked.

const MATERIALS: PackedStringArray = ["stardust_shard", "moon_flower", "crystal_chunk", "gear_bit"]
const FETCH_MIN := 2
const FETCH_MAX := 4
const BRING_MIN := 2
const BRING_MAX := 3
const REWARD_STARDUST_MIN := 60
const REWARD_STARDUST_MAX := 140
const FRIENDSHIP_ON_COMPLETE := 2
const SPAWN_CLEARANCE := 0.8
const SPAWN_RADIUS_M := 9.0
const NODE_NAME := "FavorSystem"

## Trust tiers (docs/ARCHITECTURE.md §11), on top of GameState's 0-100 friendship value. Separate
## from NpcData.tier_for()'s 0-2/3-5/6+ greeting tiers on purpose — those are tuned for how fast
## dialogue should vary and would make "best friend" trivial to hit; these gate real rewards, so they
## sit higher up the same scale.
const TRUST_PAL := 15
const TRUST_BEST_FRIEND := 30
## +% reward stardust once a neighbour trusts you at each tier.
const PAL_STARDUST_BONUS := 0.2
const BEST_FRIEND_STARDUST_BONUS := 0.4
## One-time signature gift each neighbour hands over the first time they hit "best friend" — always
## granted instead of the usual random reward roll, and never again after (GameState.flags gates it).
## Every id here must exist in the Catalog with a real scene, or the block at `_award()` grants a
## decoration the player can never place. Fen and Grig take the two remaining price-0 legendaries:
## the Gravity Well Fountain for the pan of mirror pools, the Ring-Planet Globe for the ringed world.
## Vela takes the Whisper Array, which was ADDED for her: the four legendaries above were already
## spoken for, and a neighbour missing from this dict is skipped in silence at `_award()` — her
## "thanks" line promised a gift the system had no item for.
const SIGNATURE_REWARD := {
	"zorp": "deco_wish_star", "bolt": "deco_robot_dog",
	"fen": "deco_gravity_fountain", "grig": "deco_ring_globe",
	"vela": "deco_whisper_array",
}

var _rng := RandomNumberGenerator.new()
var _planet: Planet
var _forced_template: String = ""


## Finds the world's FavorSystem, creating it under /root/World the first time.
static func get_or_create() -> FavorSystem:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var host: Node = tree.root.get_node_or_null("World")
	if host == null:
		host = tree.current_scene
	if host == null:
		host = tree.root
	var existing := host.get_node_or_null(NODE_NAME)
	if existing is FavorSystem:
		return existing as FavorSystem
	var fs := FavorSystem.new()
	fs.name = NODE_NAME
	host.add_child(fs)
	return fs


func _ready() -> void:
	_rng.randomize()
	EventBus.item_added.connect(_on_item_added)
	EventBus.collectible_picked.connect(_on_collectible_picked)
	EventBus.planet_loaded.connect(_on_planet_loaded)
	_restore()


# ============================================================================= queries
## The NPC's active favor, or {} when they have none.
func active_favor_for(npc_id: String) -> Dictionary:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("npc", "")) == npc_id and str(f.get("state", "")) == "active":
			return f
	return {}


## An active delivery addressed *to* this NPC (they are the recipient), or {}.
func delivery_for(npc_id: String) -> Dictionary:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active" or str(f.get("type", "")) != "deliver":
			continue
		if str(f.get("deliver_to", "")) == npc_id:
			return f
	return {}


## True when this NPC may offer a new favor: at most one active, and at most one offer per game day.
func can_offer(npc_id: String) -> bool:
	if not active_favor_for(npc_id).is_empty():
		return false
	var d := GameState.npc_data(npc_id)
	return int(d.get("last_favor_day", 0)) < GameState.day_count


## True when the goods are in hand (or the delivery has arrived) and the favor can be turned in.
func is_ready_to_turn_in(favor: Dictionary) -> bool:
	if favor.is_empty():
		return false
	if str(favor.get("type", "")) == "deliver":
		return false        # completed by talking to the recipient, not the giver
	return GameState.item_count(str(favor.get("target_item", ""))) >= int(favor.get("count", 1))


## True when this neighbour should be showing the "!" marker: they can offer a favour, they have one
## ready to hand in, or a gift addressed to them is in the player's bag. One pass over GameState
## .favors instead of the three `active_favor_for` / `is_ready_to_turn_in` / `delivery_for` calls the
## marker used to make every 0.45 s per NPC.
func has_marker(npc_id: String) -> bool:
	var has_active := false
	var ready := false
	var gift_in_bag := false
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active":
			continue
		var kind := str(f.get("type", ""))
		if str(f.get("npc", "")) == npc_id:
			has_active = true
			if kind != "deliver" and GameState.item_count(str(f.get("target_item", ""))) >= int(f.get("count", 1)):
				ready = true
		elif kind == "deliver" and str(f.get("deliver_to", "")) == npc_id:
			if GameState.has_item(str(f.get("target_item", ""))):
				gift_in_bag = true
	if ready or gift_in_bag:
		return true
	if has_active:
		return false
	return int(GameState.npc_data(npc_id).get("last_favor_day", 0)) < GameState.day_count


## Short human-readable lines for the HUD / quest log, e.g. "Bolt: 2/3 Gear Bits".
func active_favors_summary() -> Array[String]:
	var out: Array[String] = []
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active":
			continue
		var who := _npc_name(str(f.get("npc", "")))
		if str(f.get("type", "")) == "deliver":
			out.append("%s: deliver a gift to %s" % [who, _npc_name(str(f.get("deliver_to", "")))])
		else:
			out.append("%s: %d/%d %s" % [who, mini(int(f.get("progress", 0)), int(f.get("count", 1))),
				int(f.get("count", 1)), _item_name(str(f.get("target_item", "")), int(f.get("count", 1)))])
	return out


# ============================================================================= offering
## Builds (but does not commit) a favor for this NPC. Returns {} when nothing sensible is available.
func make_offer(npc_id: String) -> Dictionary:
	var data := NpcData.get_data(npc_id)
	if data.is_empty():
		return {}
	var kinds := _templates_for(npc_id)
	if kinds.is_empty():
		return {}
	var kind: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
	if _forced_template != "" and kinds.has(_forced_template):
		kind = _forced_template
	var favor := {
		"id": "%s_d%d_%d" % [npc_id, GameState.day_count, _rng.randi_range(100, 999)],
		"npc": npc_id,
		"type": kind,
		"target_item": "",
		"count": 1,
		"progress": 0,
		"state": "offered",
		"reward_item": "",
		"reward_stardust": _rng.randi_range(REWARD_STARDUST_MIN, REWARD_STARDUST_MAX),
		"deliver_to": "",
	}
	match kind:
		"fetch":
			favor["target_item"] = _local_collectible(npc_id)
			favor["count"] = _rng.randi_range(FETCH_MIN, FETCH_MAX)
		"bring":
			favor["target_item"] = _foreign_material(npc_id)
			favor["count"] = _rng.randi_range(BRING_MIN, BRING_MAX)
		"deliver":
			var target := _delivery_target(npc_id)
			if target == "":
				return {}
			favor["deliver_to"] = target
			favor["target_item"] = "gift_%s" % npc_id
			favor["count"] = 1
	return favor


## The NPC's own words for this offer, with the item and count filled in.
func request_lines(favor: Dictionary) -> Array:
	var npc_id := str(favor.get("npc", ""))
	var kind := str(favor.get("type", "fetch"))
	var raw := NpcData.favor_lines(npc_id, kind)
	var count := int(favor.get("count", 1))
	var out: Array = []
	for line: Variant in raw:
		var text := str(line)
		if text.contains("%d") and text.contains("%s"):
			out.append(text % [count, _item_name(str(favor.get("target_item", "")), count)])
		elif text.contains("%s"):
			out.append(text % _npc_name(str(favor.get("deliver_to", ""))))
		else:
			out.append(text.replace("%%", "%"))
	return out


## Commits an offer: stores it, toasts, plays the accept sting, hands over the gift for deliveries.
func accept(favor: Dictionary) -> void:
	if favor.is_empty():
		return
	var npc_id := str(favor.get("npc", ""))
	favor["state"] = "active"
	if str(favor.get("type", "")) != "deliver":
		favor["progress"] = mini(GameState.item_count(str(favor["target_item"])), int(favor["count"]))
	GameState.favors[str(favor["id"])] = favor
	GameState.npc_data(npc_id)["last_favor_day"] = GameState.day_count
	EventBus.favor_offered.emit(str(favor["id"]), npc_id)
	EventBus.favor_accepted.emit(str(favor["id"]))
	AudioManager.play_sfx("quest_accept")
	if str(favor.get("type", "")) == "deliver":
		_hand_over_gift(favor)
		EventBus.toast_requested.emit("Deliver the gift to %s" % _npc_name(str(favor["deliver_to"])), str(favor["target_item"]))
	else:
		_spawn_fetch_targets(favor)
		EventBus.toast_requested.emit("New favour: %d %s" % [int(favor["count"]),
			_item_name(str(favor["target_item"]), int(favor["count"]))], str(favor["target_item"]))


## DEBUG/TEST hook (used by tests/director/*.json): pins every following offer to one template, so an
## automated play-through is deterministic. Pass "" to go back to random. Ignored unless a Director
## timeline is running, so a stray call can never rig favours in a real save.
func debug_force_template(kind: String) -> void:
	if not Director.is_active():
		push_warning("FavorSystem.debug_force_template ignored: no Director timeline is running")
		return
	_forced_template = kind


## Deprecated name, kept because existing tests/director/*.json timelines call it. Same gate.
func force_template(kind: String) -> void:
	debug_force_template(kind)


## Player said no: the NPC will not ask again today.
func decline(npc_id: String) -> void:
	GameState.npc_data(npc_id)["last_favor_day"] = GameState.day_count


# ============================================================================= completing
## Pays out a finished favor. Returns {"item_id", "item_name", "stardust"} for the thank-you lines.
func complete(favor: Dictionary, npc: Node = null) -> Dictionary:
	var npc_id := str(favor.get("npc", ""))
	var kind := str(favor.get("type", "fetch"))
	var item_id := str(favor.get("target_item", ""))
	var count := int(favor.get("count", 1))
	if kind == "deliver":
		GameState.remove_item(item_id, 1)
		var player := _player()
		if player != null and player.has_method("set_carry_item"):
			player.call("set_carry_item", "")
	else:
		GameState.remove_item(item_id, count)

	# Trust tier is read BEFORE this completion's own friendship bump, so the bonus reflects
	# standing trust rather than the favour that just happened to tip it over.
	var trust_before := int(GameState.npc_data(npc_id).get("friendship", 0))

	var reward: Dictionary = Catalog.random_reward_decoration(_rng)
	var reward_id := str(reward.get("id", "")) if not reward.is_empty() else ""
	var reward_name := str(reward.get("name", "")) if not reward.is_empty() else ""
	var stardust := int(favor.get("reward_stardust", REWARD_STARDUST_MIN))
	if reward_id != "":
		GameState.add_item(reward_id)
	else:
		stardust += 40        # no decoration catalogue yet: pay in stardust instead
	if trust_before >= TRUST_BEST_FRIEND:
		stardust = int(round(stardust * (1.0 + BEST_FRIEND_STARDUST_BONUS)))
	elif trust_before >= TRUST_PAL:
		stardust = int(round(stardust * (1.0 + PAL_STARDUST_BONUS)))
	GameState.add_stardust(stardust)
	GameState.add_friendship(npc_id, FRIENDSHIP_ON_COMPLETE)
	var trust_after := int(GameState.npc_data(npc_id).get("friendship", 0))
	GameState.npc_data(npc_id)["favors_done"] = int(GameState.npc_data(npc_id).get("favors_done", 0)) + 1

	favor["state"] = "done"
	GameState.favors.erase(str(favor.get("id", "")))
	EventBus.favor_completed.emit(str(favor.get("id", "")), reward_id, stardust)
	AudioManager.play_sfx("quest_complete")
	if reward_id != "":
		EventBus.toast_requested.emit("You got a %s!" % reward_name, reward_id)
	EventBus.toast_requested.emit("+%d Stardust" % stardust, "stardust_shard")

	# One-time signature gift the first time trust crosses "best friend" — on top of the usual
	# reward roll above, not instead of it.
	var signature_id := str(SIGNATURE_REWARD.get(npc_id, ""))
	var signature_flag := "signature_unlocked_%s" % npc_id
	if signature_id != "" and trust_after >= TRUST_BEST_FRIEND and not GameState.flag(signature_flag):
		GameState.set_flag(signature_flag)
		GameState.add_item(signature_id)
		var signature_name := str(Catalog.get_item(signature_id).get("name", signature_id))
		EventBus.toast_requested.emit("%s trusts you completely! Bonus: %s" % [_npc_name(npc_id), signature_name], signature_id)

	if npc != null and npc.has_method("play_emote"):
		npc.call("play_emote", "happy")
	var player2 := _player()
	if player2 != null and player2.has_method("play_emote"):
		player2.call("play_emote", "happy")
	return {"item_id": reward_id, "item_name": reward_name, "stardust": stardust}


# ============================================================================= progress
func _on_item_added(item_id: String, _count: int) -> void:
	refresh_progress(item_id)


func _on_collectible_picked(kind: String, _world_pos: Vector3) -> void:
	refresh_progress(kind)


## Recomputes progress for every active favour that wants `item_id`, straight from the inventory, and
## toasts when the number changed. Deliberately idempotent: item_added and collectible_picked both
## fire for one pickup, and running twice must not double-count.
func refresh_progress(item_id: String) -> void:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active" or str(f.get("type", "")) == "deliver":
			continue
		if str(f.get("target_item", "")) != item_id:
			continue
		var target := int(f.get("count", 1))
		var before := int(f.get("progress", 0))
		var now := mini(GameState.item_count(item_id), target)
		if now == before:
			continue
		f["progress"] = now
		EventBus.favor_progress.emit(key, now, target)
		if now <= before:
			continue
		if now >= target:
			EventBus.toast_requested.emit("Favour ready: talk to %s" % _npc_name(str(f.get("npc", ""))), item_id)
		else:
			EventBus.toast_requested.emit("%d/%d %s" % [now, target, _item_name(item_id, target)], item_id)


func _on_planet_loaded(_planet_id: String) -> void:
	_planet = null
	_restore()


## Re-registers runtime gift items and re-spawns fetch targets after a planet load / save load.
func _restore() -> void:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active":
			continue
		if str(f.get("type", "")) == "deliver":
			_register_gift_item(str(f.get("npc", "")))
			if GameState.has_item(str(f.get("target_item", ""))):
				var player := _player()
				if player != null and player.has_method("set_carry_item"):
					player.call("set_carry_item", str(f.get("target_item", "")))
		else:
			_spawn_fetch_targets(f)


# ============================================================================= helpers
func _templates_for(npc_id: String) -> Array:
	var out: Array = ["bring"]
	if _local_collectible(npc_id) != "":
		out.append("fetch")
	if _delivery_target(npc_id) != "":
		out.append("deliver")
	return out


## The collectible that grows on this NPC's own planet (their `fetch` errand).
func _local_collectible(npc_id: String) -> String:
	var pid := str(NpcData.get_data(npc_id).get("planet", ""))
	var data := _planet_data(pid)
	if data == null:
		return ""
	var kinds := data.collectible_kind.split(",", false)
	if kinds.is_empty():
		return ""
	return String(kinds[_rng.randi_range(0, kinds.size() - 1)]).strip_edges()


## A material that does *not* grow where this NPC lives, so `bring` means a trip.
func _foreign_material(npc_id: String) -> String:
	var local := _local_collectible(npc_id)
	var pool: Array = []
	for m: String in MATERIALS:
		if m != local:
			pool.append(m)
	if pool.is_empty():
		return "stardust_shard"
	return str(pool[_rng.randi_range(0, pool.size() - 1)])


## Another known neighbour, preferring one on a different planet (that is the point of a delivery).
func _delivery_target(npc_id: String) -> String:
	var home := str(NpcData.get_data(npc_id).get("planet", ""))
	var far: Array = []
	var near: Array = []
	for other: String in NpcData.ids():
		if other == npc_id:
			continue
		var p := str(NpcData.get_data(other).get("planet", ""))
		if p == home:
			near.append(other)
		else:
			far.append(other)
	if not far.is_empty():
		return str(far[_rng.randi_range(0, far.size() - 1)])
	if not near.is_empty():
		return str(near[_rng.randi_range(0, near.size() - 1)])
	return ""


## Registers "gift_<npc>" in the Catalog at runtime and puts it in the player's hands.
func _hand_over_gift(favor: Dictionary) -> void:
	var npc_id := str(favor.get("npc", ""))
	var item_id := _register_gift_item(npc_id)
	GameState.add_item(item_id)
	var player := _player()
	if player != null and player.has_method("set_carry_item"):
		player.call("set_carry_item", item_id)


func _register_gift_item(npc_id: String) -> String:
	var item_id := "gift_%s" % npc_id
	if not Catalog.has_item(item_id):
		var who := _npc_name(npc_id)
		Catalog.register({
			"id": item_id,
			"name": "%s's Gift" % who,
			"kind": "favor_item",
			"category": "material",
			"rarity": "common",
			"price": 0,
			"desc": "A wrapped parcel from %s. Do not shake it." % who,
			"icon_color": str(NpcData.get_data(npc_id).get("accent", "#ffe27a")),
		})
	return item_id


## Scatters extra collectibles of the favour's kind near the NPC so the errand is always finishable.
func _spawn_fetch_targets(favor: Dictionary) -> void:
	if str(favor.get("type", "")) != "fetch":
		return
	var kind := str(favor.get("target_item", ""))
	var pid := str(NpcData.get_data(str(favor.get("npc", ""))).get("planet", ""))
	if pid != GameState.current_planet_id:
		return
	var planet := _find_planet()
	if planet == null or planet.collectibles_root == null:
		return
	var needed := int(favor.get("count", 1)) - int(favor.get("progress", 0))
	if needed <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([str(favor.get("id", "")), GameState.day_count])
	var home: Vector3 = _home_dir(str(favor.get("npc", "")), planet)
	for i in needed + 1:
		var spawn_id := "favor_%s_%d" % [str(favor.get("id", "")), i]
		if Collectible.was_picked_today(pid, spawn_id):
			continue
		if planet.collectibles_root.has_node("Collectible_" + spawn_id):
			continue
		var dir := planet.find_free_dir_near(rng, home, SPAWN_RADIUS_M, SPAWN_CLEARANCE, 40)
		if dir == Vector3.ZERO:
			dir = planet.find_free_dir(rng, SPAWN_CLEARANCE, 40, true)
		if dir == Vector3.ZERO:
			continue
		var c := Collectible.new()
		c.setup(kind, spawn_id, pid)
		c.transform = planet.surface_transform(dir, Vector3.FORWARD)
		planet.collectibles_root.add_child(c)


func _home_dir(npc_id: String, planet: Planet) -> Vector3:
	var d := NpcData.get_data(npc_id)
	var hd: Variant = d.get("home_dir", Vector3.UP)
	var v: Vector3 = hd if hd is Vector3 else Vector3.UP
	var building := str(d.get("building", ""))
	if building != "" and planet.has_method("building_dir"):
		var bd: Vector3 = planet.building_dir(building)
		if bd != Vector3.ZERO:
			v = bd
	return v.normalized()


func _find_planet() -> Planet:
	if _planet != null and is_instance_valid(_planet):
		return _planet
	var p := get_tree().get_first_node_in_group("planet")
	_planet = p as Planet
	return _planet


func _planet_data(planet_id: String) -> PlanetData:
	if planet_id == "":
		return null
	var path := "res://src/planet/data/%s.tres" % planet_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as PlanetData


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


static func _npc_name(npc_id: String) -> String:
	var d := NpcData.get_data(npc_id)
	return str(d.get("display_name", npc_id.capitalize()))


## "3 Gear Bits" / "1 Gear Bit" — the plural is only added when the catalogue has no plural of its own.
static func _item_name(item_id: String, count: int) -> String:
	var def := Catalog.get_item(item_id)
	var base := str(def.get("name", item_id.capitalize().replace("_", " ")))
	if count > 1 and not base.ends_with("s"):
		return base + "s"
	return base
