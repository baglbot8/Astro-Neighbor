class_name ProjectMarkers
extends Node3D
## What a neighbour's project draws on their world (docs/BUILD_PLAN.md Phase 2, builder E):
##
##   FIND markers  a survey beacon (slate post, amber lamp, a slowly turning amber diamond above it
##                 and a thin ring on the ground). Walking up to one reports it through
##                 `marker_visited`; a found beacon keeps standing, lamp gone calm teal, diamond and
##                 ring off, so the player can see which ones are done.
##   PLACE zones   a thin amber band on the ground showing where a PLACE step wants its item. It turns
##                 teal once enough items stand inside it.
##
## This node only draws and detects. ProjectSystem (its parent) decides which markers exist, where,
## and which are already found, and it owns the saved state - so nothing here is persisted.
##
## Lives at /root/World/ProjectSystem/Markers. Its parent is a plain Node, so this Node3D keeps an
## identity transform and every position below is a world position on the planet's surface.

signal marker_visited(marker_id: String)

## Feet-to-marker distance that counts as a visit. Inside NPC.TALK_REACH (2.2 m, feet to feet), so
## "walk up to it" means the same short distance as walking up to a neighbour to talk.
const VISIT_RADIUS := 2.0
## How often the astronaut's distance is checked. A run is ~7 m/s, so 0.12 s is under 0.9 m of
## travel - far less than the 4.0 m wide visit circle, so a run straight past a marker cannot skip it.
const POLL_SEC := 0.12
## Radius (m) the beacon claims on the planet: decorations and neighbours' wander targets keep this
## far off (Planet.register_prop), and the collider is this wide so the astronaut bumps into the post
## instead of walking through it. Planet has no unregister, so a cleared beacon's 0.34 m stays claimed
## until the planet is next built (every landing) - it can only ever block a decoration's centre from
## standing exactly where a finished marker stood.
const FOOTPRINT := 0.34
const COLLIDER_RADIUS := 0.2
const COLLIDER_HEIGHT := 1.2
## Beacon proportions (metres). The astronaut is 1.4 m tall; the diamond's centre rides at 1.62 m so
## it sits just above the helmet line and clears the crown of any neighbour who walks past.
const POST_TOP := 0.9
const LAMP_Y := 0.99
const DIAMOND_Y := 1.62
## First pass was 0.15 x 0.40 m: at the 5.4 m capture (e01) it read as a flat yellow chip beside the
## lamp. 0.21 x 0.56 m is about the NPC "!"'s on-screen height at the same distance.
const DIAMOND_R := 0.21
const DIAMOND_H := 0.56
## Inverted-hull outline: the diamond drawn again this much larger, back faces only, in a dark ink.
const OUTLINE_SCALE := 1.16
const BOB_M := 0.06
const BOB_HZ := 0.7
const SPIN_RAD_S := 1.2
const RING_R := 0.62

## Colours. The diamond and its ink are the NPC "!" marker's own (npc.gd `_build_marker`: toon
## `#ffcc33`, outline `#6b5232`), so "go and look at this" speaks the one glyph language the game
## already has. The lamp is the Moonstone UI accent amber (`#f0a64a`). The ring is a GOLD, not an
## orange: the first pass used an amber-brown ring and on Bolt it melted into the orange seam lights
## (e01). The post is a mid slate - the first pass (`#46506a`) read as a black stick under the toon
## shade at gameplay distance. Teal "found" belongs to no neighbour's accent.
const GLYPH := Color("#ffcc33")
const GLYPH_INK := Color("#6b5232")
const AMBER := Color("#f0a64a")
const GOLD := Color("#d8ab3c")
const SLATE := Color("#5d6883")
const SLATE_DARK := Color("#454e68")
const FOUND := Color("#6fb8a0")
## Emission strengths. Low on purpose: STYLE_GUIDE R2.6 caps blown highlights at 5% and saturated
## accents must stay small, so the lamp glows without blooming into a white blob.
const LAMP_GLOW := 0.9
const DIAMOND_GLOW := 0.3
const FOUND_GLOW := 0.25

## PLACE zone band: dashed, so it reads as a marked-out zone and never as a crack in the ground.
const ZONE_SEGMENTS := 96
## Segments per dash and per gap: 96 / (2 + 2) = 24 dashes, each ~0.39 m long on a 3 m ring.
const ZONE_DASH := 2
const ZONE_WIDTH := 0.17
## Lift off the ground so the band never z-fights the terrain (PlacementController.RING_LIFT is 0.035).
const ZONE_LIFT := 0.04
const ZONE_ALPHA := 0.78
const ZONE_MET_ALPHA := 0.6

var _planet: Planet
## marker id -> {"node": Node3D, "dir": Vector3, "found": bool, "diamond": Node3D, "lamp": MeshInstance3D, "ring": Node3D}
var _markers: Dictionary = {}
## zone id -> {"node": MeshInstance3D, "met": bool}
var _zones: Dictionary = {}
## Marker ids already registered as planet props in this world (register_prop only appends).
var _registered: Dictionary = {}
var _poll := 0.0
var _t := 0.0
var _player: Node3D


func _ready() -> void:
	set_process(false)


## Must be called once before anything is shown.
func setup(planet: Planet) -> void:
	_planet = planet


# ============================================================================= FIND markers
## Shows (or refreshes) one beacon at planet-local unit direction `dir`.
func show_marker(marker_id: String, dir: Vector3, found: bool) -> void:
	if _planet == null:
		return
	if _markers.has(marker_id):
		set_found(marker_id, found)
		return
	var d := dir.normalized()
	var root := Node3D.new()
	root.name = "Marker_" + marker_id.replace(":", "_")
	add_child(root)
	root.global_transform = _planet.surface_transform(d, Vector3.FORWARD)
	var rec := _build_beacon(root)
	rec["node"] = root
	rec["dir"] = d
	rec["found"] = false
	_markers[marker_id] = rec
	if not _registered.has(marker_id):
		_registered[marker_id] = true
		_planet.register_prop(d, FOOTPRINT)
	set_found(marker_id, found)
	set_process(true)


## Switches a beacon between its live (amber) and found (teal, diamond and ring off) looks.
func set_found(marker_id: String, found: bool) -> void:
	if not _markers.has(marker_id):
		return
	var rec: Dictionary = _markers[marker_id]
	rec["found"] = found
	(rec["diamond"] as Node3D).visible = not found
	(rec["ring"] as Node3D).visible = not found
	(rec["lamp"] as MeshInstance3D).material_override = _lamp_material(found)


func has_marker(marker_id: String) -> bool:
	return _markers.has(marker_id)


func marker_ids() -> Array:
	return _markers.keys()


## World position of a marker's ground contact, or Vector3.INF when it is not shown.
func marker_position(marker_id: String) -> Vector3:
	if not _markers.has(marker_id):
		return Vector3.INF
	return (_markers[marker_id]["node"] as Node3D).global_position


## Removes every beacon whose id starts with `prefix` ("" = all of them).
func clear_markers(prefix: String = "") -> void:
	for id: String in _markers.keys():
		if prefix != "" and not id.begins_with(prefix):
			continue
		var n: Node3D = _markers[id]["node"]
		if is_instance_valid(n):
			n.queue_free()
		_markers.erase(id)


# ============================================================================= PLACE zones
## Draws a band on the ground `radius_m` (straight line) from the spot at planet-local `center_dir`.
func show_zone(zone_id: String, center_dir: Vector3, radius_m: float, met: bool) -> void:
	if _planet == null:
		return
	if _zones.has(zone_id):
		set_zone_met(zone_id, met)
		return
	var mi := MeshInstance3D.new()
	mi.name = "Zone_" + zone_id.replace(":", "_")
	mi.mesh = _zone_mesh(center_dir.normalized(), radius_m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_zones[zone_id] = {"node": mi, "met": not met}
	set_zone_met(zone_id, met)


func set_zone_met(zone_id: String, met: bool) -> void:
	if not _zones.has(zone_id):
		return
	var rec: Dictionary = _zones[zone_id]
	if bool(rec["met"]) == met:
		return
	rec["met"] = met
	(rec["node"] as MeshInstance3D).material_override = _zone_material(met)


func has_zone(zone_id: String) -> bool:
	return _zones.has(zone_id)


func clear_zones(prefix: String = "") -> void:
	for id: String in _zones.keys():
		if prefix != "" and not id.begins_with(prefix):
			continue
		var n: Node3D = _zones[id]["node"]
		if is_instance_valid(n):
			n.queue_free()
		_zones.erase(id)


# ============================================================================= loop
func _process(delta: float) -> void:
	if _markers.is_empty():
		set_process(false)
		return
	_t += delta
	var bob := sin(TAU * BOB_HZ * _t) * BOB_M
	for id: String in _markers:
		var rec: Dictionary = _markers[id]
		if bool(rec["found"]):
			continue
		var dm := rec["diamond"] as Node3D
		dm.position.y = DIAMOND_Y + bob
		dm.rotation.y = fmod(_t * SPIN_RAD_S, TAU)
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = POLL_SEC
	var p := _find_player()
	if p == null:
		return
	var feet := p.global_position
	for id: String in _markers.keys():
		var rec: Dictionary = _markers[id]
		if bool(rec["found"]):
			continue
		if feet.distance_to((rec["node"] as Node3D).global_position) <= VISIT_RADIUS:
			set_found(id, true)
			_sparkle((rec["node"] as Node3D))
			marker_visited.emit(id)


func _find_player() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player


# ============================================================================= look
## Builds one beacon under `root` (whose transform is the surface frame: +Y up, origin on the ground).
func _build_beacon(root: Node3D) -> Dictionary:
	# Body: base plate, post, lamp cage and cap in one vertex-coloured mesh = one draw call.
	var kit := DecoKit.new()
	# A squat, chamfered base plate so it sits flat on the ground (STYLE_GUIDE "flat base"), and a
	# darker skirt under it so the contact line reads.
	kit.rbox(Vector3(0.0, 0.035, 0.0), Vector3(0.46, 0.07, 0.46), 0.03, SLATE_DARK)
	kit.rbox(Vector3(0.0, 0.085, 0.0), Vector3(0.3, 0.05, 0.3), 0.02, SLATE)
	kit.tube(Vector3(0.0, 0.09, 0.0), Vector3(0.0, POST_TOP, 0.0), 0.045, SLATE, 10)
	# A collar where the post meets the lamp, and a flat cap over it: tiered, not one blob (R2.3).
	kit.rbox(Vector3(0.0, POST_TOP, 0.0), Vector3(0.16, 0.04, 0.16), 0.015, SLATE_DARK)
	kit.rbox(Vector3(0.0, LAMP_Y + 0.12, 0.0), Vector3(0.28, 0.05, 0.28), 0.02, SLATE_DARK)
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = kit.commit()
	body.material_override = DecoItem.body_material()
	root.add_child(body)

	var lamp_kit := DecoKit.new()
	lamp_kit.rbox(Vector3(0.0, LAMP_Y, 0.0), Vector3(0.2, 0.18, 0.2), 0.04, Color.WHITE)
	var lamp := MeshInstance3D.new()
	lamp.name = "Lamp"
	lamp.mesh = lamp_kit.commit()
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(lamp)

	# The floating diamond: two cones base to base, six sides so it catches the light in facets, with
	# an ink outline (the "!" marker's), which is what keeps it readable against a bright sky limb.
	var dk := DecoKit.new()
	dk.cone(Vector3.ZERO, DIAMOND_R, 0.0, DIAMOND_H * 0.55, Color.WHITE, Basis.IDENTITY, 6)
	dk.cone(Vector3.ZERO, DIAMOND_R, 0.0, DIAMOND_H * 0.45, Color.WHITE, Basis(Vector3.RIGHT, PI), 6)
	var diamond_mesh := dk.commit()
	var diamond := Node3D.new()
	diamond.name = "Diamond"
	diamond.position.y = DIAMOND_Y
	root.add_child(diamond)
	var face := MeshInstance3D.new()
	face.name = "Face"
	face.mesh = diamond_mesh
	face.material_override = MaterialLib.toon(GLYPH, {"emission": GLYPH, "emission_strength": DIAMOND_GLOW,
		"shade": 0.3, "rim": 0.0, "spec": 0.0})
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	diamond.add_child(face)
	var ink := MeshInstance3D.new()
	ink.name = "Ink"
	ink.mesh = diamond_mesh
	ink.material_override = _ink_material()
	ink.scale = Vector3.ONE * OUTLINE_SCALE
	ink.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	diamond.add_child(ink)

	# Ground ring: says "this spot" from above, where the post alone is a dot.
	var rk := DecoKit.new()
	rk.torus(Vector3(0.0, 0.02, 0.0), RING_R, 0.035, GOLD, Basis.IDENTITY, 28, 4)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = rk.commit()
	ring.material_override = DecoItem.body_material()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)

	# Collider on the decoration layer (4), like DecoItem's: the astronaut and neighbours bump into
	# the post instead of walking through it (QUALITY_BAR "nothing clips").
	var body3d := StaticBody3D.new()
	body3d.name = "Collider"
	body3d.collision_layer = 1 << 3
	body3d.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = COLLIDER_RADIUS
	cap.height = COLLIDER_HEIGHT
	cs.shape = cap
	cs.position = Vector3(0.0, COLLIDER_HEIGHT * 0.5, 0.0)
	body3d.add_child(cs)
	root.add_child(body3d)
	return {"diamond": diamond, "lamp": lamp, "ring": ring}


static func _lamp_material(found: bool) -> ShaderMaterial:
	var c := FOUND if found else AMBER
	return MaterialLib.toon(c, {"emission": c, "emission_strength": FOUND_GLOW if found else LAMP_GLOW,
		"shade": 0.2, "rim": 0.0})


static var _ink_mat: StandardMaterial3D
static var _zone_mats: Dictionary = {}


## Back faces only, unshaded: the classic inverted-hull outline, cached (one per game).
static func _ink_material() -> StandardMaterial3D:
	if _ink_mat == null:
		_ink_mat = StandardMaterial3D.new()
		_ink_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ink_mat.albedo_color = GLYPH_INK
		_ink_mat.cull_mode = BaseMaterial3D.CULL_FRONT
		_ink_mat.disable_receive_shadows = true
	return _ink_mat


## A one-shot sparkle when a beacon is found, in the same painted-sparkle language as a pickup.
func _sparkle(at: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.name = "FoundSparkle"
	p.amount = 16
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.9
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.18
	pm.direction = Vector3.UP
	pm.spread = 55.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(0.0, -1.2, 0.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(FOUND.r, FOUND.g, FOUND.b, 0.9))
	g.set_color(1, Color(FOUND.r, FOUND.g, FOUND.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	q.material = DecoItem.sparkle_material()
	p.draw_pass_1 = q
	add_child(p)
	p.global_position = at.global_position + at.global_transform.basis.y * LAMP_Y
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)
	AudioManager.play_sfx_at("pickup", at.global_position, -4.0)


## The PLACE band, built on the real ground so it never floats over a dip or cuts into a rise.
## The step's check is a STRAIGHT-LINE distance (`radius_m`), so the band is drawn at the ARC length
## whose chord is exactly `radius_m`: 2 R asin(r / 2R). On level ground the drawn edge is the edge the
## check uses, with no fudge factor.
func _zone_mesh(c: Vector3, radius_m: float) -> ArrayMesh:
	var r_planet := _planet.radius
	var arc := 2.0 * r_planet * asin(clampf(radius_m / (2.0 * r_planet), 0.0, 1.0))
	var xf := _planet.surface_transform(c, Vector3.FORWARD)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner: Array[Vector3] = []
	var outer: Array[Vector3] = []
	for k in ZONE_SEGMENTS + 1:
		var ang := TAU * float(k) / float(ZONE_SEGMENTS)
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		inner.append(_ground_at(c, tangent, arc - ZONE_WIDTH * 0.5))
		outer.append(_ground_at(c, tangent, arc + ZONE_WIDTH * 0.5))
	for k in ZONE_SEGMENTS:
		if k % (ZONE_DASH * 2) >= ZONE_DASH:
			continue
		st.add_vertex(inner[k])
		st.add_vertex(outer[k])
		st.add_vertex(outer[k + 1])
		st.add_vertex(inner[k])
		st.add_vertex(outer[k + 1])
		st.add_vertex(inner[k + 1])
	return st.commit()


## The ground point `arc_m` metres along the surface from `c` toward `tangent`, lifted ZONE_LIFT.
func _ground_at(c: Vector3, tangent: Vector3, arc_m: float) -> Vector3:
	var a := arc_m / _planet.radius
	var d := (c * cos(a) + tangent * sin(a)).normalized()
	return _planet.surface_point(d) + d * ZONE_LIFT


## Cached per state (two materials per game), so recolouring a ring allocates nothing.
static func _zone_material(met: bool) -> StandardMaterial3D:
	if _zone_mats.has(met):
		return _zone_mats[met]
	var c := FOUND if met else GLYPH
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(c.r, c.g, c.b, ZONE_MET_ALPHA if met else ZONE_ALPHA)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	_zone_mats[met] = m
	return m
