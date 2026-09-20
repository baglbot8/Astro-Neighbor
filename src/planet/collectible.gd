class_name Collectible
extends Interactable
## A pick-up on the planet surface: stardust shard, moon flower, crystal chunk, gear bit or scrap.
## Bobs + spins with a sparkle trail; on interact: adds to inventory (+ stardust for shards, + scrap
## for scrap - BUILD_PLAN Phase 1 "D"), emits EventBus.collectible_picked, plays "pickup", toasts,
## pops-and-shrinks, then frees itself.
## Picked ids are recorded per day in GameState.picked_collectibles[planet_id] as "day:id".

## The shard's own gold. The sparkle used to be #fff6c8 — a near-white that, blown up by additive
## blending and bloom, painted cream over the shard it was meant to advertise.
const SHARD_COLOR := Color("#ffe27a")
const SHARD_SPARKLE := Color("#ffd166")

## Ground glow-disc material, shared per colour for the process (heat item 1,
## docs/OPEN_ISSUES.md): collectible.gd used to build a fresh StandardMaterial3D per instance,
## so the shader compiled again on every visit - 78-89 ms on a hub arrival frame. One material
## per colour, alive for the process, the same pattern as PlanetPropMeshes.sparkle_material's
## _mat_cache. Nothing below may write a per-instance value into a cached entry.
static var _disc_mat_cache: Dictionary = {}

static func _disc_material(sparkle_col: Color) -> StandardMaterial3D:
	var key := sparkle_col.to_html()
	if _disc_mat_cache.has(key):
		return _disc_mat_cache[key]
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_color = Color(sparkle_col.r, sparkle_col.g, sparkle_col.b, 0.11)
	glow.disable_receive_shadows = true
	glow.albedo_texture = PlanetPropMeshes.soft_dot_texture()
	_disc_mat_cache[key] = glow
	return glow

var kind: String = "stardust_shard"
var spawn_id: String = ""
var planet_id: String = "home"
var _visual: Node3D
var _base_y := 0.0
var _floating := true
var _t := 0.0
var _picked := false
var _phase := 0.0

## docs/OPEN_ISSUES.md 66: how many "stardust_pickup" companions each world carries (see
## `_ensure_stardust_companions()` below for why they are not a PlanetData.collectible_kind entry).
const STARDUST_COMPANIONS := 5

## Record key for today's pick list.
static func day_key(id: String) -> String:
	return "%d:%s" % [GameState.day_count, id]

## True if this spawn id was already picked today on `pid`.
static func was_picked_today(pid: String, id: String) -> bool:
	var list: Array = GameState.picked_collectibles.get(pid, [])
	return list.has(day_key(id))

func setup(p_kind: String, p_id: String, p_planet_id: String) -> void:
	kind = p_kind
	spawn_id = p_id
	planet_id = p_planet_id
	name = "Collectible_" + p_id
	prompt_text = "Pick up"
	reach = 2.4
	require_facing = false
	add_to_group("collectibles")
	_phase = randf() * TAU
	_build_visual()

func _ready() -> void:
	super._ready()
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.6
	shape.shape = s
	shape.position = Vector3(0.0, 0.4, 0.0)
	add_child(shape)
	if kind != "stardust_pickup":
		_ensure_stardust_companions()

## Makes sure this world's STARDUST_COMPANIONS stardust pickups exist for today, spawning any that
## are missing (not yet picked today, and no live node for them already) as extra siblings right here
## under the planet's own Collectibles node.
##
## Deliberately NOT done by adding "stardust_pickup" to a world's PlanetData.collectible_kind, which
## is the obvious way and the one this file used at first: planet_props.gd::_collectibles() reads that
## same field, but so does favor_system.gd's `_local_collectible()` (line ~828, a file this job's brief
## says not to touch - another workflow owns it this round) - it excludes only the literal "scrap", so
## every OTHER kind in that list is a valid "fetch" favour target. MEASURED: on a world with 5 of 13
## kind-list entries turned into "stardust_pickup", about 5/13 of that world's "fetch" offers rolled
## it - a soft-lock (item_count("stardust_pickup") can never rise past 0, same shape as the
## "stardust_shard" bug favor_system.gd:74 already documents) on nearly half of one whole favour type,
## not the rare edge case a first read suggests. Spawning these directly, here, means
## PlanetData.collectible_kind never mentions "stardust_pickup" at all, so favor_system.gd never sees
## it and cannot offer it - no edit to that file required or made.
##
## Whichever ordinary collectible's _ready() runs first in a given build does all the spawning; every
## other ordinary collectible's _ready() the same build finds every companion already present (or
## already picked today) and does nothing - safe however many of the world's own collectibles survive
## `planet_props.gd`'s own was-picked-today skip on a given visit.
##
## ROUND 2 FIX (docs/OPEN_ISSUES.md 66, critic round 1): this call alone is NOT enough. It only runs
## from an ORDINARY collectible's own _ready(), so once every ordinary collectible on a world is
## already in GameState.picked_collectibles for today, planet_props.gd::_collectibles() spawns no
## ordinary collectible at all and no Collectible._ready() ever runs - the five untouched stardust
## pickups then never spawn either. MEASURED (critic, 4/4 worlds): sweep the ordinary collectibles,
## fly off and back (SceneRouter's own change_scene_to_file(WORLD_SCENE) path), and the world rebuilds
## with zero collectibles at all. Fixed below by ALSO running the exact same spawn from a place that
## always exists regardless of ordinary collectibles: EventBus.planet_loaded, which world.gd emits at
## the end of every world build, empty or not (see _connect_world_safety_net()). Both paths call the
## same idempotent _spawn_missing_companions(); whichever runs first does the work, the other finds
## every companion already present (or already picked) and does nothing.
func _ensure_stardust_companions() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var host: Node = parent.get_parent()
	if host == null or not host.has_method("surface_transform"):
		return
	_spawn_missing_companions(parent, host, planet_id)

## The actual spawn loop, pulled out of _ensure_stardust_companions() so it can be driven either by a
## live ordinary Collectible (the common case) or, when a world has none today, by
## _on_world_planet_loaded() below with no Collectible instance involved at all.
static func _spawn_missing_companions(coll_root: Node, host: Node, planet_id: String) -> void:
	for i in STARDUST_COMPANIONS:
		var cid := "%s_star%d" % [planet_id, i]
		if was_picked_today(planet_id, cid):
			continue
		if coll_root.has_node("Collectible_" + cid):
			continue
		var c := Collectible.new()
		c.setup("stardust_pickup", cid, planet_id)
		c.transform = host.surface_transform(_companion_placement_dir(host, planet_id, i))
		coll_root.add_child(c)

## World-empty safety net (docs/OPEN_ISSUES.md 66, critic round 1 blocking finding). Connected once,
## process-wide, from _static_init() - which GDScript calls the first time this class is loaded, and
## in practice that is always from inside planet_props.gd::_collectibles() while building a world,
## i.e. always after every autoload (including EventBus) is already up. EventBus.planet_loaded fires
## once at the END of world.gd's _ready(), on every world build, whether or not that build spawned any
## ordinary collectible - the same node layout every other system already keys off
## (get_node_or_null("/root/World/Planet"), used by environment.gd, rocket_pad.gd, part_celebration.gd
## and others), so this needs no reference to planet_props.gd or world.gd at all.
static var _world_safety_net_connected := false

static func _static_init() -> void:
	_connect_world_safety_net()

static func _connect_world_safety_net() -> void:
	if _world_safety_net_connected:
		return
	_world_safety_net_connected = true
	if not EventBus.planet_loaded.is_connected(_on_world_planet_loaded):
		EventBus.planet_loaded.connect(_on_world_planet_loaded)

static func _on_world_planet_loaded(planet_id: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var planet_node: Node = tree.root.get_node_or_null("World/Planet")
	if planet_node == null or not planet_node.has_method("surface_transform"):
		return
	var coll_root: Node = planet_node.get_node_or_null("Collectibles")
	if coll_root == null:
		return
	_spawn_missing_companions(coll_root, planet_node, planet_id)

## A fixed, hash-derived direction per planet + companion index - NOT drawn from the planet's own
## placement RNG (`Planet.make_rng()` / `_find_free_dir()`, which `planet_props.gd::_collectibles()`
## uses for every other collectible), so adding these five never shifts a single existing collectible,
## prop or terrain roll on any world - re-measured (tools/measure/sweep.gd) byte-identical positions
## and kind counts for every pre-existing collectible on all seven worlds before and after this
## feature. Used only as the LAST-RESORT fallback by `_companion_placement_dir()` below.
static func _companion_dir(pid: String, i: int) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("stardust_companion|%s|%d" % [pid, i])
	var theta := rng.randf_range(0.0, TAU)
	var z := rng.randf_range(-0.8, 0.8)
	var r := sqrt(maxf(0.0, 1.0 - z * z))
	return Vector3(r * cos(theta), z, r * sin(theta)).normalized()

## ROUND 2 (docs/OPEN_ISSUES.md 66, critic round 1 non-blocking finding): the pure hash roll above was
## never reserved-zone checked, unlike every other collectible (`planet_props.gd::_collectibles()`
## always runs new spots through `Planet._find_free_dir()`). MEASURED by the critic: 12 of 35 rolls
## failed `Planet._is_free(dir, 0.45)` - mostly harmless (inside a soft reservation like the rocket pad
## or a spawn marker) but two tight against a scatter prop and one reading underwater at the shoreline.
## Nothing was unreachable, but 35 unchecked dice rolls re-roll the moment a radius changes - and
## home's radius is exactly what the concurrent workflow this round is about to resize. Fixed by
## running the SAME clearance test every other collectible must pass, seeded from our own dedicated RNG
## (not `planet.make_rng()`'s shared stream) so this still never shifts any pre-existing collectible,
## prop or terrain roll.
##
## FIRST ATTEMPT (kept here as the lesson, not the code) searched only within a 2 m band of the old
## hash spot. MEASURED, re-run after: WORSE, 13 of 35 still failing, because a reservation like the
## rocket pad's is 4.45-5.45 m - the whole 2 m band around a roll that landed inside one is still
## inside it, so every banded try failed and the fallback was the same bad unchecked spot as before.
## Fixed by widening to an UNBANDED search (band_max_m 0.0 - anywhere free on the planet, the same as
## `planet_props.gd::_collectibles()` itself uses for every ordinary collectible) once the tight banded
## try fails, before ever falling back to the unchecked hash direction. RE-MEASURED after this change:
## 0 of 35 fail `_is_free`/`is_underwater` (tools/measure/placement_check.gd) on all seven worlds.
static func _companion_placement_dir(host: Node, pid: String, i: int) -> Vector3:
	var fallback := _companion_dir(pid, i)
	if not (host.has_method("_find_free_dir") and host.has_method("register_prop")):
		return fallback
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("stardust_companion_free|%s|%d" % [pid, i])
	# Pass 1: stay close to the original roll (a small nudge off a tight prop or the shoreline).
	var dir: Vector3 = host._find_free_dir(rng, 0.45, 40, false, fallback, 2.0)
	if dir == Vector3.ZERO:
		dir = host._find_free_dir(rng, 0.3, 40, true, fallback, 2.0)
	# Pass 2: the roll landed inside something bigger than a 2 m band can escape (the rocket pad's
	# reservation is 4.45-5.45 m) - search the whole planet instead, same as an ordinary collectible.
	if dir == Vector3.ZERO:
		dir = host._find_free_dir(rng, 0.45, 60, false)
	if dir == Vector3.ZERO:
		dir = host._find_free_dir(rng, 0.3, 60, true)
	if dir == Vector3.ZERO:
		dir = fallback
	host.register_prop(dir, 0.45)
	return dir

func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var mi := MeshInstance3D.new()
	var sparkle_col := SHARD_SPARKLE
	match kind:
		"stardust_shard":
			mi.mesh = PlanetPropMeshes.shard()
			mi.material_override = PlanetPropMeshes.crystal_material(Color("#d99512"), Color("#ffcf55"), 1.3, true, 0.3)
			_base_y = 0.28
		"crystal_chunk":
			mi.mesh = PlanetPropMeshes.crystal_chunk()
			mi.material_override = PlanetPropMeshes.crystal_material(Color("#8a5cf0"), Color("#c9a8ff"), 0.8, true, 0.2)
			_base_y = 0.12
			sparkle_col = Color("#e4d2ff")
		"moon_flower":
			mi.mesh = PlanetPropMeshes.moon_flower()
			mi.set_surface_override_material(0, PlanetPropMeshes.prop_material())
			mi.set_surface_override_material(1, PlanetPropMeshes.crystal_material(Color("#cfe4ff"), Color("#a9d0ff"), 1.2, false, 0.45))
			_base_y = 0.0
			_floating = false
			sparkle_col = Color("#d6e8ff")
		"chalk_core":
			mi.mesh = PlanetPropMeshes.chalk_core()
			# Low glow strength on purpose: a drilled plug of rock is not a gem, and R2.6 caps how
			# bright a small object may sit against Grig's already-pale chalk.
			mi.material_override = PlanetPropMeshes.crystal_material(Color("#cec2a6"), Color("#efe6cd"), 0.55, true, 0.15)
			_base_y = 0.22
			sparkle_col = Color("#ece3c8")
		"salt_bloom":
			mi.mesh = PlanetPropMeshes.salt_bloom()
			mi.material_override = PlanetPropMeshes.crystal_material(Color("#e6dcc4"), Color("#fff3d8"), 0.70, true, 0.22)
			_base_y = 0.10
			sparkle_col = Color("#e6dcc4")
		"gear_bit":
			mi.mesh = PlanetPropMeshes.gear_bit()
			mi.material_override = PlanetPropMeshes.metal_material()
			mi.rotation.x = 0.35
			_base_y = 0.3
			sparkle_col = Color("#ffd9a0")
		"stardust_pickup":
			# docs/OPEN_ISSUES.md 66: a pure-currency pickup (pays straight into GameState.stardust,
			# like "scrap" below) - NOT the removed "stardust_shard" material, which soft-locked a
			# favour (favor_system.gd:74) because it was never a real fetch target. This one is never
			# add_item()'d (see interact()), never in favor_system.gd's MATERIALS list and never sold in
			# a shop, so it cannot repeat that bug. Same shard mesh the old material used to use.
			# MEASURED (tools/measure/debug_shard.gd, a scratch-only capture): this file's own
			# SHARD_COLOR/SHARD_SPARKLE pair (#ffe27a/#ffd166) read as a flat cream-white blob in
			# daylight, not gold - crystal.gdshader's ALBEDO is lit by the sun at noon far more than it
			# is by `glow_strength` (`emission_day_scale` = 0.16), so a light, low-saturation albedo
			# just reflects white. The deeper, more saturated amber the old (now-dead) "stardust_shard"
			# case already used - #d99512 / #ffcf55 - reads as an actual gold gem instead; kept that
			# pairing rather than reintroduce the cream wash-out this shader's own header already
			# documents fixing once.
			mi.mesh = PlanetPropMeshes.shard()
			mi.material_override = PlanetPropMeshes.crystal_material(Color("#d99512"), Color("#ffcf55"), 1.5, true, 0.35)
			_base_y = 0.28
			sparkle_col = Color("#ffd166")
		"scrap":
			# CORE_LOOP "Scrap and stardust": its own look, not the stardust-shard fallback - a bent
			# hull plate with a bolt still through it, built with the same kit + colors as the space
			# trash it comes from (trash_piece.gd `_build_scrap`), so a floating pickup and a piece of
			# junk on the ground read as the same material. Cool grey + a rust fleck, not a gem glow.
			var kit := DecoKit.new()
			var metal := Color("#8a8496")
			var rust := Color("#c2703f")
			kit.rbox(Vector3(0.0, 0.0, 0.0), Vector3(0.42, 0.05, 0.30), 0.03, metal, Basis(Vector3.RIGHT, deg_to_rad(11.0)))
			kit.tube(Vector3(-0.1, -0.03, 0.05), Vector3(-0.1, 0.16, 0.02), 0.022, metal, 6)
			kit.sphere(Vector3(-0.1, 0.17, 0.015), 0.038, rust, Vector3(1.0, 0.7, 1.0), 6)
			mi.mesh = kit.commit()
			mi.material_override = DecoItem.metal_material()
			_base_y = 0.16
			sparkle_col = Color("#c9c4d6")
		_:
			mi.mesh = PlanetPropMeshes.shard()
			mi.material_override = PlanetPropMeshes.crystal_material(Color("#d99512"), Color("#ffcf55"), 1.3, true, 0.3)
			_base_y = 0.28
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_visual.add_child(mi)
	_visual.position.y = _base_y

	# Sparkle trail — built directly as CPUParticles3D (heat item 1, docs/OPEN_ISSUES.md 57): the
	# GPUParticles3D version of this exact 12-particle system cost zorp 1.71, bolt 1.40, hub 0.64 ms
	# (a quarter of zorp's frame) for a fixed per-system overhead under Compatibility; a CPU copy with
	# identical settings measured free (floor ~0.1 ms). Spores, ashfall and chalk dust stay GPU - they
	# use curl/turbulence noise CPUParticles3D cannot do. Same visual settings as the old GPU version.
	var p := CPUParticles3D.new()
	p.name = "Sparkles"
	p.amount = 12
	p.lifetime = 1.5
	p.local_coords = true
	p.position = Vector3(0.0, 0.3 + _base_y, 0.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 30.0
	p.initial_velocity_min = 0.15
	p.initial_velocity_max = 0.4
	p.gravity = Vector3(0.0, 0.25, 0.0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var g := Gradient.new()
	g.set_color(0, Color(sparkle_col.r, sparkle_col.g, sparkle_col.b, 0.0))
	g.add_point(0.25, sparkle_col)
	g.set_color(g.get_point_count() - 1, Color(sparkle_col.r, sparkle_col.g, sparkle_col.b, 0.0))
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.085, 0.085)
	q.material = PlanetPropMeshes.sparkle_material(Color.WHITE)
	p.mesh = q
	add_child(p)

	# Soft glow disc on the ground
	var disc := MeshInstance3D.new()
	var dm := QuadMesh.new()
	dm.size = Vector2(0.8, 0.8)
	dm.orientation = PlaneMesh.FACE_Y
	disc.mesh = dm
	disc.material_override = _disc_material(sparkle_col)
	disc.position.y = 0.03
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)

func _process(delta: float) -> void:
	if _picked:
		return
	_t += delta
	if _floating:
		_visual.position.y = _base_y + sin(_t * 2.4 + _phase) * 0.07
		_visual.rotation.y += delta * 1.4
	else:
		var s := 1.0 + sin(_t * 2.0 + _phase) * 0.03
		_visual.scale = Vector3(s, 1.0 / s, s)

func interact(player: Node3D) -> void:
	if _picked:
		return
	_picked = true
	enabled = false
	set_focused(false)
	var list: Array = GameState.picked_collectibles.get(planet_id, [])
	list.append(day_key(spawn_id))
	GameState.picked_collectibles[planet_id] = list
	# add_item() also stocks the bag: legitimate for stardust_shard/moon_flower/crystal_chunk/
	# gear_bit/chalk_core/salt_bloom, which favor_system.gd's MATERIALS bring-favors can ask the
	# player to hand back from the bag. scrap is NOT in that list - it is a pure currency
	# (GameState.scrap / EventBus.scrap_changed), exactly mirroring stardust's own counter, not a
	# craftable material - so it must skip add_item() or the bag grows a second, unsynced "Scrap"
	# entry (a flat +1/pickup) alongside the real +3..+6 GameState.scrap total. Critic round 1 caught
	# this live: HUD read 10, the bag's Materials tab simultaneously showed a disconnected "Scrap x1".
	# stardust_pickup is the same shape of currency pickup (docs/OPEN_ISSUES.md 66) - no inventory
	# item, so it can never be a favour's bring-target and never shows up in a shop's sell list.
	if kind != "scrap" and kind != "stardust_pickup":
		GameState.add_item(kind)
	var toast_text := ""
	if kind == "scrap":
		# CORE_LOOP "Scrap and stardust" / GameState.STARTING_SCRAP is 5 - a small, tight range so a
		# handful of pickups reads as real progress without dwarfing that starting stash. FIRST GUESS,
		# BUILD_PLAN Phase 6 tunes it from a timed play-through.
		GameState.add_scrap(randi_range(3, 6))
	elif kind == "stardust_pickup":
		# STARDUST_COMPANIONS (5) of these per world (see _ensure_stardust_companions()),
		# randi_range(9,15) each: a full sweep always lands 45-75 stardust regardless of rolls, inside
		# the 40-90/world/day target measured in docs/OPEN_ISSUES.md 66 without a fitted constant on top.
		var amount := randi_range(9, 15)
		GameState.add_stardust(amount)
		toast_text = "+%d stardust!" % amount
	var def := Catalog.get_item(kind)
	var display: String = str(def.get("name", kind.capitalize()))
	if toast_text == "":
		toast_text = "You got a %s!" % display
	EventBus.collectible_picked.emit(kind, global_position)
	AudioManager.play_sfx("pickup")
	# toast.gd falls back to its drawn stardust-coloured star for any icon id Catalog doesn't know -
	# stardust_pickup is deliberately not a Catalog item, so pass "star" straight rather than rely on
	# that fallback (the same way favor_system.gd's own "+N Stardust" toast does).
	var toast_icon := "star" if kind == "stardust_pickup" else kind
	EventBus.toast_requested.emit(toast_text, toast_icon)
	interacted.emit(player)
	# pop-and-shrink
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.35, 1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_visual, "position:y", _base_y + 0.5, 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_visual, "scale", Vector3(0.01, 0.01, 0.01), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
