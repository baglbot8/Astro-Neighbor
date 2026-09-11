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

var kind: String = "stardust_shard"
var spawn_id: String = ""
var planet_id: String = "home"
var _visual: Node3D
var _base_y := 0.0
var _floating := true
var _t := 0.0
var _picked := false
var _phase := 0.0

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

	# Sparkle trail
	var p := GPUParticles3D.new()
	p.name = "Sparkles"
	p.amount = 12
	p.lifetime = 1.5
	p.local_coords = true
	p.position = Vector3(0.0, 0.3 + _base_y, 0.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 30.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.4
	pm.gravity = Vector3(0.0, 0.25, 0.0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var g := Gradient.new()
	g.set_color(0, Color(sparkle_col.r, sparkle_col.g, sparkle_col.b, 0.0))
	g.add_point(0.25, sparkle_col)
	g.set_color(g.get_point_count() - 1, Color(sparkle_col.r, sparkle_col.g, sparkle_col.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.085, 0.085)
	q.material = PlanetPropMeshes.sparkle_material(Color.WHITE)
	p.draw_pass_1 = q
	add_child(p)

	# Soft glow disc on the ground
	var disc := MeshInstance3D.new()
	var dm := QuadMesh.new()
	dm.size = Vector2(0.8, 0.8)
	dm.orientation = PlaneMesh.FACE_Y
	disc.mesh = dm
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_color = Color(sparkle_col.r, sparkle_col.g, sparkle_col.b, 0.11)
	glow.disable_receive_shadows = true
	glow.albedo_texture = PlanetPropMeshes.soft_dot_texture()
	disc.material_override = glow
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
	if kind != "scrap":
		GameState.add_item(kind)
	if kind == "stardust_shard":
		GameState.add_stardust(randi_range(8, 15))
	elif kind == "scrap":
		# CORE_LOOP "Scrap and stardust" / GameState.STARTING_SCRAP is 5 - a small, tight range so a
		# handful of pickups reads as real progress without dwarfing that starting stash. FIRST GUESS,
		# BUILD_PLAN Phase 6 tunes it from a timed play-through.
		GameState.add_scrap(randi_range(3, 6))
	var def := Catalog.get_item(kind)
	var display: String = str(def.get("name", kind.capitalize()))
	EventBus.collectible_picked.emit(kind, global_position)
	AudioManager.play_sfx("pickup")
	EventBus.toast_requested.emit("You got a %s!" % display, kind)
	interacted.emit(player)
	# pop-and-shrink
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.35, 1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_visual, "position:y", _base_y + 0.5, 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_visual, "scale", Vector3(0.01, 0.01, 0.01), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
