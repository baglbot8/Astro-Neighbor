class_name DecorationManager
extends Node3D
## Owns every decoration standing on the current planet (`/root/World/Decorations`).
##
## On _ready it restores `GameState.placed_decorations[GameState.current_planet_id]`; after that the
## PlacementController (its child) calls:
##   place(item_id, dir, yaw) -> String     spawn + persist + pop animation + sfx + dust puff
##   remove(instance_id)                    despawn + un-persist + return the item to the bag
##   is_spot_free(dir, footprint, ignore)   placement rules (water, reserved spots, props, npcs, spacing)
##   get_instances() -> Array               [{id, item, node, dir, footprint}, ...]
##
## Positions are stored LOCAL to the planet (which never moves), so a save round-trip is exact.
## Every placed item carries an Interactable ("Pick up", require_facing) that calls remove().

## Extra clearance between two decorations, on top of the sum of their footprints.
const MIN_GAP := 0.2
## Nothing may be placed this close to a reserved direction (spawn, rocket pad, buildings, npc homes).
const RESERVED_CLEARANCE := 3.5
## Nothing may be placed this close to a wandering neighbour.
const NPC_CLEARANCE := 1.2
const PICKUP_REACH := 2.6
const POP_UP := 0.16
const POP_DOWN := 0.13
## Steepest ground a decoration may stand on, measured as the angle between the local ground normal
## and the radial direction. Above this an item visibly leans or digs into the hillside.
const MAX_SLOPE_DEG := 16.0
## How far the ground under the footprint may deviate from the plane the item is seated on. This is
## the number that actually matters: 2.6 m of dome tent on a crater rim buries one edge and floats
## the other, which QUALITY_BAR auto-fails ("props sit exactly on the curved ground").
const MAX_GROUND_DEVIATION := 0.09
const GROUND_DEVIATION_PER_METER := 0.09
## Directions sampled around an item to test how flat its footprint is.
const SLOPE_SAMPLES := 6
## Radius (m) the ground normal is averaged over when seating an item. Smaller than a footprint on
## purpose: an item should follow the ground it actually touches, not the hill behind it.
const GROUND_NORMAL_SPAN := 0.35
## Shoreline margin: the planet's own props use water_radius + 0.18, so decorations do too. Testing
## only the centre (is_underwater) let half an item stand in the shallows.
const SHORE_MARGIN := 0.18
## Seconds a freshly placed item's "Pick up" Interactable stays inert (see `_arm_pickups`).
const PICKUP_ARM_GRACE := 0.35

signal instance_added(instance_id: String, item_id: String, node: Node3D)
signal instance_removed(instance_id: String, item_id: String)

var planet: Planet
var placement: PlacementController

var _instances: Dictionary = {}       # instance_id -> {"item": String, "node": Node3D, "dir": Vector3, "footprint": float}
var _scene_cache: Dictionary = {}     # scene path -> PackedScene
var _counter: int = 0
## Pickups waiting to be switched on: [{"area": Interactable, "t": float, "left": bool}, ...].
var _arming: Array[Dictionary] = []
## Rule inputs cached out of the hot loop (`spot_block_reason` runs every frame during placement).
var _reserved_cache: Array[Vector3] = []
var _npc_cache: Array[Node3D] = []


func _ready() -> void:
	_find_planet()
	placement = get_node_or_null("PlacementController") as PlacementController
	set_process(false)
	restore()
	refresh_rule_caches()


func _find_planet() -> void:
	var p := get_tree().get_first_node_in_group("planet")
	if p == null and get_parent():
		p = get_parent().get_node_or_null("Planet")
	planet = p as Planet


## Re-reads the things placement rules need but that never change while you are placing: the planet's
## reserved directions and the neighbours currently on the planet. Called on load and every time
## placement mode opens, so `spot_block_reason` allocates nothing per frame.
func refresh_rule_caches() -> void:
	_reserved_cache = planet.get_reserved_dirs() if planet else ([] as Array[Vector3])
	_npc_cache.clear()
	for n in get_tree().get_nodes_in_group("npc"):
		var n3 := n as Node3D
		if n3:
			_npc_cache.append(n3)


func _process(delta: float) -> void:
	_arm_pickups(delta)


# ============================================================================================ public API
## Rebuilds every decoration recorded for the current planet. Safe to call twice.
func restore() -> void:
	for id in _instances.keys():
		var n: Node3D = _instances[id]["node"]
		if is_instance_valid(n):
			n.queue_free()
	_instances.clear()
	if planet == null:
		return
	var list: Array = GameState.placed_decorations.get(GameState.current_planet_id, [])
	var orphans: Array[String] = []
	for entry in list:
		var item_id := str(entry.get("item", ""))
		var pos: Vector3 = GameState.vec3_from_array(entry.get("pos", [0.0, 0.0, 0.0]))
		# Re-seat onto the CURRENT ground before spawning. A saved position is a fixed distance
		# from the planet's centre, so anything that changes the surface height under it would
		# otherwise leave the item floating or buried: the "expand your planet" upgrade
		# (GameState.home_planet_size) is the case this exists for - growing home from 12 m to
		# 14 m would drop every placed decoration 2 m underground. Direction and yaw are
		# preserved; only the distance is corrected, so nothing visibly moves when the radius
		# has not changed.
		pos = planet.reseat_local(pos)
		var basis: Basis = GameState.basis_from_array(entry.get("basis", [1, 0, 0, 0, 1, 0, 0, 0, 1]))
		if _spawn(str(entry.get("id", "")), item_id, Transform3D(basis, pos), false) == null:
			orphans.append(str(entry.get("id", "")))
	# A save that names an item whose scene has gone would otherwise warn on every planet load
	# forever and keep a slot the player can never reach. Drop it once and refund the item.
	for id in orphans:
		GameState.remove_placed_decoration(GameState.current_planet_id, id)
	if not orphans.is_empty():
		push_warning("DecorationManager: dropped %d saved decoration(s) with no scene" % orphans.size())


## Spawns `item_id` at `dir` with `yaw` (radians around the surface normal), persists it and plays the
## placement feedback. Returns the new instance id, or "" if the item has no usable scene.
func place(item_id: String, dir: Vector3, yaw: float = 0.0) -> String:
	if planet == null:
		_find_planet()
		if planet == null:
			return ""
	var xf := surface_transform_for(dir, yaw)
	var local := Transform3D(planet.global_transform.basis.inverse() * xf.basis, planet.to_local(xf.origin))
	var id := _new_instance_id(item_id)
	var node := _spawn(id, item_id, local, true)
	if node == null:
		return ""
	GameState.add_placed_decoration(GameState.current_planet_id, id, item_id, local.origin, local.basis)
	AudioManager.play_sfx_at("place", xf.origin)
	_dust_puff(xf.origin, xf.basis.y)
	return id


## Removes a placed decoration, gives the item back to the bag and shrinks it away.
func remove(instance_id: String) -> void:
	if not _instances.has(instance_id):
		return
	var rec: Dictionary = _instances[instance_id]
	var node: Node3D = rec["node"]
	var item_id: String = rec["item"]
	_instances.erase(instance_id)
	GameState.remove_placed_decoration(GameState.current_planet_id, instance_id)
	GameState.add_item(item_id)
	var def := Catalog.get_item(item_id)
	var display := str(def.get("name", item_id))
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit("Picked up %s." % display, item_id)
	instance_removed.emit(instance_id, item_id)
	if not is_instance_valid(node):
		return
	for it in _interactables_of(node):
		it.enabled = false
		it.set_focused(false)
		for i in range(_arming.size() - 1, -1, -1):
			if _arming[i]["area"] == it:
				_arming.remove_at(i)
	_dust_puff(node.global_position, node.global_transform.basis.y)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector3(1.18, 0.82, 1.18), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector3(0.01, 0.01, 0.01), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(node.queue_free)


## Placement rules. `ignore_id` skips one existing instance (used when re-seating an item).
func is_spot_free(dir: Vector3, footprint: float, ignore_id: String = "") -> bool:
	return spot_block_reason(dir, footprint, ignore_id) == ""


## "" when the spot is usable, otherwise why not: "no_planet", "water", "shore", "slope",
## "reserved", "prop", "crowded" or "npc". The placement controller only needs the bool; this exists
## so the reason is inspectable from tests and future UI hints.
## Allocates nothing (see `refresh_rule_caches`) because it runs once per frame while placing.
func spot_block_reason(dir: Vector3, footprint: float, ignore_id: String = "") -> String:
	if planet == null:
		return "no_planet"
	var d := dir.normalized()
	if planet.is_underwater(d):
		return "water"
	for r in _reserved_cache:
		if planet.surface_distance(d, r) < RESERVED_CLEARANCE:
			return "reserved"
	if planet.nearest_prop_distance(d) < footprint:
		return "prop"
	for id in _instances:
		if id == ignore_id:
			continue
		var rec: Dictionary = _instances[id]
		if planet.surface_distance(d, rec["dir"]) < footprint + float(rec["footprint"]) + MIN_GAP:
			return "crowded"
	var here := planet.surface_point(d)
	for n3 in _npc_cache:
		if is_instance_valid(n3) and n3.global_position.distance_to(here) < NPC_CLEARANCE + footprint:
			return "npc"
	return ground_block_reason(d, footprint)


## Terrain half of the placement rules: "water" (centre submerged), "shore" (any of the footprint in
## or too near the water), "slope" (too steep, or too uneven to seat the item flat), or "".
## Split out so a critic timeline can probe the terrain rule on its own.
func ground_block_reason(dir: Vector3, footprint: float) -> String:
	var d := dir.normalized()
	var wr := planet.water_radius()
	var h0 := planet.height_at(d)
	if wr > 0.0 and h0 < wr + SHORE_MARGIN:
		return "shore"
	var n := planet.ground_normal(d, maxf(footprint, 0.3))
	if n.dot(d) < cos(deg_to_rad(MAX_SLOPE_DEG)):
		return "slope"
	# How far the ground under the footprint strays from the plane the item will be seated on. An
	# item is only "flat on the ground" if every sample around its rim is within a centimetre or two
	# of that plane; a plateau bank or a crater rim fails here long before the pure slope test does.
	var r := maxf(footprint, 0.3)
	var xf := planet.surface_transform(d)
	var p0 := d * h0
	var tolerance := MAX_GROUND_DEVIATION + r * GROUND_DEVIATION_PER_METER
	var e := r / planet.radius
	for k in SLOPE_SAMPLES:
		var ang := TAU * float(k) / float(SLOPE_SAMPLES)
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		var dd := (d + tangent * e).normalized()
		var hh := planet.height_at(dd)
		if wr > 0.0 and hh < wr + SHORE_MARGIN:
			return "shore"
		if absf((dd * hh - p0).dot(n)) > tolerance:
			return "slope"
	return ""


## [{id, item, node, dir, footprint}, ...] for every decoration currently standing.
func get_instances() -> Array:
	var out: Array = []
	for id in _instances:
		var rec: Dictionary = _instances[id]
		out.append({"id": id, "item": rec["item"], "node": rec["node"], "dir": rec["dir"], "footprint": rec["footprint"]})
	return out


func has_instance(instance_id: String) -> bool:
	return _instances.has(instance_id)


## QA helper for Director timelines: one line saying what is actually standing on the planet.
##   {"t": 5, "call": {"node": "/root/World/Decorations", "method": "debug_report", "args": ["after"]}}
func debug_report(tag: String = "") -> void:
	var ids: Array = []
	for id in _instances:
		ids.append("%s@[%s]" % [_instances[id]["item"], str(_instances[id]["dir"]).replace(" ", "")])
	print("DECO %s standing=%d pending_arm=%d bag_bench=%d %s" % [
		tag, _instances.size(), _arming.size(), GameState.item_count("deco_crater_bench"), str(ids)])


## World transform for an item sitting on the surface at `dir`, turned `yaw` radians around the
## normal. Up is the GROUND normal (`Planet.ground_normal`), not the radial direction: on anything
## other than dead-level ground the radial up left benches teetering on one foot pad and tent skirts
## cutting into the slope. `yaw` stays measured about the radial axis so a saved rotation is exact.
func surface_transform_for(dir: Vector3, yaw: float) -> Transform3D:
	var d := dir.normalized()
	var xf := planet.surface_transform(d, Vector3.FORWARD)
	xf.basis = xf.basis * Basis(Vector3.UP, yaw)
	var n := planet.ground_normal(d, GROUND_NORMAL_SPAN)
	var axis := xf.basis.y.cross(n)
	if axis.length_squared() > 0.000001:
		var ang := acos(clampf(xf.basis.y.dot(n), -1.0, 1.0))
		xf.basis = Basis(axis.normalized(), minf(ang, deg_to_rad(MAX_SLOPE_DEG))) * xf.basis
	xf.basis = xf.basis.orthonormalized()
	return xf


## Loads (and caches) the scene for an item id. Returns null when the catalog has no scene.
func scene_for(item_id: String) -> PackedScene:
	var def := Catalog.get_item(item_id)
	var path := str(def.get("scene", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path]


## Footprint radius for an item id (catalog value, falling back to a sane default).
static func footprint_for(item_id: String) -> float:
	var def := Catalog.get_item(item_id)
	return float(def.get("footprint", 0.7))


# ============================================================================================ internals
func _spawn(instance_id: String, item_id: String, local_xf: Transform3D, pop: bool) -> Node3D:
	var scene := scene_for(item_id)
	if scene == null:
		push_warning("DecorationManager: no scene for item '%s'" % item_id)
		return null
	var node: Node3D = scene.instantiate()
	node.name = "Deco_" + instance_id
	add_child(node)
	node.transform = Transform3D(planet.global_transform.basis * local_xf.basis, planet.to_global(local_xf.origin))
	var fp := float(node.get_meta("footprint", footprint_for(item_id)))
	_instances[instance_id] = {
		"item": item_id,
		"node": node,
		"dir": planet.dir_of(node.global_position),
		"footprint": fp,
	}
	_add_pickup(node, instance_id, fp, not pop)
	if pop:
		_pop(node)
	instance_added.emit(instance_id, item_id, node)
	return node


## Attaches the "Pick up" Interactable. `armed` = usable immediately (restored from a save);
## a freshly PLACED item starts disarmed — see `_arm_pickups` for why.
func _add_pickup(node: Node3D, instance_id: String, fp: float, armed: bool) -> void:
	var area := Interactable.new()
	area.name = "PickUp"
	# Two words, like the rocket's "Fly" and an NPC's "Talk". "Pick up Space Dome Tent" was 23
	# characters, and the bottom-centre prompt pill shares that strip with the rocket compass pill and
	# the bottom-right toast stack: at that length all three collided and the tail was unreadable.
	area.prompt_text = "Pick up"
	area.reach = PICKUP_REACH + fp * 0.5
	area.require_facing = true
	# No CollisionShape3D: Interactable._ready sets monitoring = false, nothing masks physics layer 5
	# and the player finds targets by group + distance, so a shape here was a physics object per
	# decoration that never reported anything.
	area.interacted.connect(func(_player: Node3D) -> void: remove(instance_id))
	node.add_child(area)
	if armed:
		return
	area.enabled = false
	_arming.append({"area": area, "t": 0.0, "left": false})
	set_process(true)


## Switches freshly placed pickups back on once it is safe.
##
## THE BUG THIS FIXES: `interact` both confirms a placement and, one physics tick later, picks the
## item straight back up. Player.gd polls `Input.is_action_pressed("interact")` in _physics_process,
## the new item's pickup reach (2.6 + footprint/2) always exceeds the 3.3 m the ghost sits ahead of
## you, and placing your LAST copy leaves placement mode and re-enabled every Interactable while the
## key was still down. On a new save (exactly one of each starter item) that undid the player's very
## first placement, every time.
##
## So a new pickup stays inert until the key that placed it is released AND either the player has
## left its reach once or a short grace has passed.
func _arm_pickups(delta: float) -> void:
	if _arming.is_empty():
		set_process(false)
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var placing := placement != null and placement.is_active()
	var held := Input.is_action_pressed("interact")
	for i in range(_arming.size() - 1, -1, -1):
		var rec: Dictionary = _arming[i]
		var area := rec["area"] as Interactable
		if not is_instance_valid(area):
			_arming.remove_at(i)
			continue
		if placing:
			# Placement mode mutes every Interactable anyway; hold the grace open until it ends.
			rec["t"] = 0.0
			continue
		rec["t"] = float(rec["t"]) + delta
		if player and player.global_position.distance_to(area.global_position) > area.reach:
			rec["left"] = true
		if held:
			continue
		if bool(rec["left"]) or float(rec["t"]) >= PICKUP_ARM_GRACE:
			area.enabled = true
			_arming.remove_at(i)


## True while `it` is a pickup that has not been switched on yet (PlacementController must not
## blanket-restore it when placement mode ends).
func is_pickup_arming(it: Interactable) -> bool:
	for rec in _arming:
		if rec["area"] == it:
			return true
	return false


func _pop(node: Node3D) -> void:
	node.scale = Vector3(0.02, 0.02, 0.02)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector3(1.1, 1.1, 1.1), POP_UP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector3(0.94, 1.06, 0.94), POP_DOWN * 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector3.ONE, POP_DOWN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _dust_puff(pos: Vector3, up: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.name = "Puff"
	p.amount = 14
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.92
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = up
	pm.emission_ring_radius = 0.35
	pm.emission_ring_inner_radius = 0.1
	pm.emission_ring_height = 0.05
	pm.direction = up
	pm.spread = 65.0
	pm.initial_velocity_min = 0.9
	pm.initial_velocity_max = 1.7
	pm.gravity = -up * 1.4
	pm.damping_min = 2.0
	pm.damping_max = 3.5
	pm.scale_min = 0.7
	pm.scale_max = 1.5
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.96, 0.86, 0.85))
	g.set_color(1, Color(1.0, 0.93, 0.78, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.3)
	q.material = DecoItem.sparkle_material()
	p.draw_pass_1 = q
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)


func _new_instance_id(item_id: String) -> String:
	var stamp := int(Time.get_unix_time_from_system()) % 100000
	var candidate := ""
	for _attempt in 10000:
		_counter += 1
		candidate = "%s@%d_%d" % [item_id, stamp, _counter]
		if not _instances.has(candidate):
			break
	return candidate


static func _interactables_of(node: Node) -> Array[Interactable]:
	var out: Array[Interactable] = []
	for c in node.get_children():
		if c is Interactable:
			out.append(c)
		if c is Node:
			out.append_array(_interactables_of(c))
	return out
