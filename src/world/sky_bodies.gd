class_name SkyBodies
extends Node3D
## The three neighbouring worlds, always hanging in the sky (STYLE_GUIDE R2.1).
##
## From every planet you can see the other three as small, distinct, correctly-lit bodies that
## drift slowly across the sky: home's green world with its seas, Zorp's violet world with its
## glowing rivers, Bolt's chrome world WITH ITS RING, and Starport Plaza. They are the strongest
## "I am in space" cue in the game and they double as navigation - the world you are looking at is
## the world you can fly to.
##
## HOW THEY ARE DRAWN. Real meshes (SphereMesh + an annulus for the ring) parked at a fixed
## `BODY_DISTANCE` from the camera, using res://src/shaders/env_globe.gdshader - the ground-level
## twin of the solar-system map's globe shader, so a planet seen from the ground and the same
## planet seen from the rocket share a visual language. Meshes rather than sky-shader discs because
## Bolt's ring needs real geometry, and because the terrain then occludes a body that drops below
## the horizon for free, via the depth buffer.
##
## WHERE THEY SIT. Height is given as a FRACTION of the visible sky band - the wedge between the
## planet's limb and the top of the frame. The gameplay rig (28 deg pitch, 45 deg FOV) only ever
## shows that wedge, and it is not the same on every world: it spans ~18.5 deg above the limb on
## home (R=16), ~19.6 deg on Zorp and Bolt (R=13) and only ~15.5 deg on the hub (R=26). A fixed
## elevation that frames nicely on home clips off the top of the screen on Zorp. Fractions frame
## identically everywhere. environment.gd measures the wedge from the real camera once at load and
## `resolve_band` freezes the resulting elevations, so tilting the camera afterwards does not drag
## the worlds around the sky.
##
## Azimuth is an OFFSET from the direction the camera faced when the world loaded, not an absolute
## compass bearing. The moons use absolute azimuths tuned for "a north-facing camera", which only
## works while the spawn facing never changes - it changed twice during this build and took the
## moons' framing with it. Anchoring to the opening view instead means the three worlds are always
## in the establishing shot on every planet whatever the player builder picks for spawn_dir, and
## they still slide out of frame normally as the player turns, because the anchor is captured once
## and then held. The three offsets are spread right/centre/left and dodge the HUD chips; each
## drifts on a slow, bounded oscillation so the sky is alive without any body wandering out of the
## playable band.
##
## SIZES are derived from the solar-system map's own layout (see SYSTEM_LAYOUT) so relative
## distances read plausibly: the hub is the big cream world, Bolt is the far small one.

const BODY_SHADER := preload("res://src/shaders/env_globe.gdshader")
const RING_SHADER := preload("res://src/shaders/ring.gdshader")
## Ring geometry, as multiples of the body radius. Kept equal to src/world/planet_ring.gd's
## inner_radius/outer_radius over the planet's own radius, so the sky body and the real ring agree.
const RING_INNER_SCALE := 2.15
const RING_OUTER_SCALE := 3.00

## How far from the camera the bodies are parked. Well inside the camera's 300 m far plane and far
## beyond any terrain (the biggest planet is R=26), so the depth buffer occludes them correctly.
const BODY_DISTANCE := 140.0
## Planet ids in system order.
const ORDER: Array[String] = ["home", "zorp", "bolt", "hub"]
## Mirror of src/rocket/space_travel.gd LAYOUT (globe radius, orbit radius, orbit angle, height).
## Duplicated rather than imported so the environment never depends on the rocket scene; it is only
## used to derive plausible RELATIVE angular sizes, so small drift between the two is harmless.
const SYSTEM_LAYOUT := {
	"home": {"r": 2.2, "orbit": 20.0, "angle": 24.0, "y": 0.6},
	"zorp": {"r": 1.9, "orbit": 28.5, "angle": 118.0, "y": -1.7},
	"bolt": {"r": 1.9, "orbit": 36.5, "angle": 214.0, "y": 1.5},
	"hub": {"r": 3.2, "orbit": 47.0, "angle": 318.0, "y": -0.9},
}
## Map units -> degrees of angular diameter. Tuned so the nearest neighbour reads ~4.6 deg across
## (about 73 px tall at 720p, still clearly smaller than the 6.3 deg moon) and the furthest ~2.3 deg
## (37 px, with Bolt's ring spanning 75 px). Below about 2 deg a world reads as a dot, not a place.
const ANGULAR_SCALE := 68.0
const ANGULAR_MIN_DEG := 2.2
const ANGULAR_MAX_DEG := 4.6

## Sky slots: [azimuth OFFSET from the opening camera bearing (deg), height as a fraction of the
## visible sky band, az drift deg, elev drift deg, drift period in game hours]. The horizontal
## half-FOV is ~36 deg, so offsets stay inside +/-33 including drift. Heights sweep low-left to
## high-centre to high-right, which threads the two fixed obstacles in the establishing shot: the
## hub's town hall fills the middle of the plaza skyline (so the centre slot rides high) and the
## arrival banner covers x 595-1160 / y 85-180 for its first few seconds (so the right slot rides
## above it rather than behind it).
const SLOTS := [
	[-27.0, 0.74, 2.5, 1.4, 27.0],
	[4.0, 0.88, 2.5, 1.1, 34.0],
	[30.0, 0.34, 3.0, 1.3, 41.0],
]
## Degrees of spin per second. Slow: at 2-3 deg across, anything faster reads as a spinning marble.
const SPIN_DEG_PER_SEC := 1.1

## Biome identity anchors, matching src/rocket/space_globe.gd so the world in the sky is the same
## world on the map. [anchor colour, blend amount].
const BIOME_ANCHOR := {
	"meadow": [Color("#6fbf5f"), 0.10],
	"violet": [Color("#8262a8"), 0.62],
	"chrome": [Color("#8fa3bf"), 0.50],
	"plaza": [Color("#7ec46a"), 0.14],
}
const BIOME_MODE := {"meadow": 0, "violet": 1, "chrome": 2, "plaza": 3}

## One entry per visible world.
class Body:
	var id: String = ""
	var node: Node3D
	var spin: Node3D
	var material: ShaderMaterial
	var ring_material: ShaderMaterial
	var slot: int = 0
	var angular_radius: float = 0.02
	## Elevation above the local horizontal (degrees), resolved from the slot's band fraction.
	var elev_deg: float = -14.0

var _bodies: Array[Body] = []
var _clock_hours: float = 0.0

## Builds the three neighbours of `current_id`. Silently builds nothing if the .tres files are
## missing (showcase scenes that run standalone).
func setup(current_id: String) -> void:
	var slot := 0
	for id in ORDER:
		if id == current_id:
			continue
		var path := "res://src/planet/data/%s.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var data: PlanetData = load(path)
		if data == null:
			continue
		_bodies.append(_build_body(data, current_id, slot))
		slot += 1
		if slot >= SLOTS.size():
			break

## Turns each slot's band fraction into an absolute elevation for THIS planet and camera. Called
## by environment.gd every frame while the camera rig settles, then left alone.
## `limb_dir` points from the eye toward the planet centre, `limb_angle` is the planet's angular
## radius and `band_top` the angle from the limb up to the top of the frame (all radians).
func resolve_band(up: Vector3, east: Vector3, az_origin: float, limb_dir: Vector3,
		limb_angle: float, band_top: float) -> void:
	var band: float = clampf(band_top, 0.02, 1.2)
	for b in _bodies:
		var spec: Array = SLOTS[b.slot]
		var az: float = az_origin + float(spec[0])
		b.elev_deg = rad_to_deg(_elev_on_cone(az, limb_angle + band * float(spec[1]), up, east, limb_dir))

## Per-frame update from environment.gd.
## `cam_pos` anchors the bodies (they never parallax), `up`/`east` are the player's local frame,
## `az_origin` is the opening camera bearing in that frame (degrees, see the header),
## `sun_dir` points toward the sun, `night` 0..1 and `hours` is the continuous game clock.
func update_state(cam_pos: Vector3, up: Vector3, east: Vector3, az_origin: float, sun_dir: Vector3,
		night: float, hours: float, sun_light: Color) -> void:
	_clock_hours = hours
	for b in _bodies:
		var spec: Array = SLOTS[b.slot]
		var az: float = az_origin + float(spec[0]) + float(spec[2]) * sin(TAU * hours / float(spec[4]))
		var elev: float = b.elev_deg + float(spec[3]) * sin(TAU * hours / (float(spec[4]) * 1.37) + 1.1)
		var dir := _sky_dir(az, elev, up, east)
		b.node.global_position = cam_pos + dir * BODY_DISTANCE
		b.material.set_shader_parameter("sun_dir", sun_dir)
		b.material.set_shader_parameter("sun_light", sun_light)
		# Slightly cooler and calmer at night so the discs sit in the night grade instead of
		# punching through it, but never dimmed to the point of vanishing.
		b.material.set_shader_parameter("exposure", lerpf(1.0, 0.86, night))
		if b.ring_material != null:
			b.ring_material.set_shader_parameter("sun_dir", sun_dir)
			b.ring_material.set_shader_parameter("night", night)

func _process(delta: float) -> void:
	for b in _bodies:
		if b.spin != null:
			b.spin.rotate_y(deg_to_rad(SPIN_DEG_PER_SEC) * delta)

## Elevation (radians, above the local horizontal) of the direction at azimuth `az_deg` that sits
## exactly `cone` radians away from `limb_dir`. Solving a*sin(e) + b*cos(e) = cos(cone) picks the
## branch above the planet rather than the mirrored one buried inside it.
static func _elev_on_cone(az_deg: float, cone: float, up: Vector3, east: Vector3, limb_dir: Vector3) -> float:
	var flat := east - up * up.dot(east)
	if flat.length_squared() < 0.0001:
		flat = Vector3.RIGHT - up * up.dot(Vector3.RIGHT)
	flat = flat.normalized().rotated(up, deg_to_rad(az_deg))
	var a := up.dot(limb_dir)
	var b := flat.dot(limb_dir)
	var r := sqrt(a * a + b * b)
	if r < 0.0001:
		return -0.25
	var phi := atan2(b, a)
	return PI - asin(clampf(cos(cone) / r, -1.0, 1.0)) - phi

## Angular radius (radians) of the body in `slot`, for tests and framing checks.
func angular_radius_of(id: String) -> float:
	for b in _bodies:
		if b.id == id:
			return b.angular_radius
	return 0.0

## World-space unit direction from the viewer to a sky body, or Vector3.ZERO if it is not drawn.
## The rocket journey aims its climb at the destination world the player can actually see, so it
## needs this rather than reaching for the "Sky_<id>" child node by name.
func direction_of(id: String) -> Vector3:
	for b in _bodies:
		if b.id == id and b.node != null and is_instance_valid(b.node):
			var d: Vector3 = b.node.global_position - global_position
			if d.length_squared() > 0.000001:
				return d.normalized()
	return Vector3.ZERO


## Ids of the worlds currently drawn in the sky.
func visible_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _bodies:
		out.append(b.id)
	return out

# ----------------------------------------------------------------------------- building
func _build_body(data: PlanetData, viewer_id: String, slot: int) -> Body:
	var b := Body.new()
	b.id = data.id
	b.slot = slot
	var diam_deg := _angular_diameter_deg(viewer_id, data.id)
	b.angular_radius = deg_to_rad(diam_deg * 0.5)
	var mesh_radius: float = BODY_DISTANCE * tan(b.angular_radius)

	b.node = Node3D.new()
	b.node.name = "Sky_" + data.id
	add_child(b.node)

	b.spin = Node3D.new()
	b.spin.name = "Spin"
	# A little axial tilt each, so the four worlds are not a row of identical globes.
	b.spin.rotation = Vector3(deg_to_rad(-16.0 + 9.0 * float(slot)), float(slot) * 2.1, deg_to_rad(7.0))
	b.node.add_child(b.spin)

	b.material = ShaderMaterial.new()
	b.material.shader = BODY_SHADER
	_apply_biome(b.material, data)

	var mesh := SphereMesh.new()
	mesh.radius = mesh_radius
	mesh.height = mesh_radius * 2.0
	mesh.radial_segments = 40
	mesh.rings = 20
	var mi := MeshInstance3D.new()
	mi.name = "Surface"
	mi.mesh = mesh
	mi.material_override = b.material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	b.spin.add_child(mi)

	if data.has_ring:
		b.ring_material = _build_ring(b.node, mesh_radius, data.ring_color)
	return b

## Bolt's ring. Same proportions and tilt as the map globe so it is recognisably the same world.
func _build_ring(parent: Node3D, body_radius: float, ring_color: Color) -> ShaderMaterial:
	var ring := Node3D.new()
	ring.name = "Ring"
	ring.rotation = Vector3(deg_to_rad(-24.0), 0.0, deg_to_rad(17.0))
	parent.add_child(ring)
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter("ring_color", ring_color.darkened(0.26))
	mat.set_shader_parameter("ring_shade", ring_color.darkened(0.60))
	mat.set_shader_parameter("opacity", 0.92)
	mat.set_shader_parameter("tonemap_white", 6.0)
	# Kept far under the glow threshold: a blooming ring would smear a warm smudge over the sky.
	mat.set_shader_parameter("display_cap", 0.44)
	var mi := MeshInstance3D.new()
	mi.name = "Band"
	# Matched to the real PlanetRing on Bolt (inner 28 m / outer 39 m on a 13 m planet = 2.15x /
	# 3.00x). These were 1.32x / 2.05x, which made the ringed world in the sky visibly different
	# from the one you land on and left a delta at the rocket journey's departure cut.
	mi.mesh = _annulus(body_radius * RING_INNER_SCALE, body_radius * RING_OUTER_SCALE, 64)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	ring.add_child(mi)
	return mat

func _apply_biome(mat: ShaderMaterial, data: PlanetData) -> void:
	var mode: int = int(BIOME_MODE.get(data.biome, 3))
	mat.set_shader_parameter("mode", mode)
	# The hub's ground_color_a is its lawn, but most of what you actually see from orbit is the
	# cream plaza paving, which is set on the material and never reaches PlanetData - so the hub
	# rendered green-and-tan in the sky while being cream on the ground. PlanetData.surface_color
	# carries each planet's dominant visible tone; prefer it when a planet declares one.
	var land: Color = data.surface_color if data.surface_color.a > 0.0 else data.ground_color_a
	mat.set_shader_parameter("land_a", _anchor(land, data.biome).darkened(0.04))
	mat.set_shader_parameter("land_b", _anchor(data.ground_color_b, data.biome).darkened(0.10))
	mat.set_shader_parameter("low_color", data.ground_color_low.darkened(0.08))
	mat.set_shader_parameter("sea_color", data.water_color.darkened(0.32))
	mat.set_shader_parameter("sea_deep", data.water_deep_color.darkened(0.32))
	mat.set_shader_parameter("shade_tint", Color(0.46, 0.44, 0.70))
	mat.set_shader_parameter("shade_strength", 0.50)
	# The night side keeps a third of the lit tone. Explicit, not a shader default: a crushed dark
	# side is what made the map globes read as bitten discs (docs/OPEN_ISSUES notes on globe.gdshader).
	mat.set_shader_parameter("shade_floor", 0.36)
	mat.set_shader_parameter("ramp_softness", 0.16)
	mat.set_shader_parameter("tonemap_white", 6.0)
	mat.set_shader_parameter("display_cap", 0.58)
	match data.biome:
		"meadow":
			mat.set_shader_parameter("sea_level", 0.455)
			mat.set_shader_parameter("pattern_scale", 1.55)
			mat.set_shader_parameter("accent", Color("#ffe27a"))
			mat.set_shader_parameter("accent_glow", 0.0)
			mat.set_shader_parameter("cloud_amount", 0.55)
			mat.set_shader_parameter("rim_color", Color("#9fd0ff"))
			mat.set_shader_parameter("rim_strength", 0.30)
		"violet":
			mat.set_shader_parameter("pattern_scale", 3.2)
			mat.set_shader_parameter("accent", Color("#5bb8dd"))
			mat.set_shader_parameter("accent_glow", 0.42)
			mat.set_shader_parameter("cloud_amount", 0.0)
			mat.set_shader_parameter("rim_color", Color("#c9a6ff"))
			mat.set_shader_parameter("rim_strength", 0.28)
		"chrome":
			mat.set_shader_parameter("pattern_scale", 1.35)
			mat.set_shader_parameter("accent", Color("#ff8a3d"))
			mat.set_shader_parameter("accent_glow", 0.48)
			mat.set_shader_parameter("cloud_amount", 0.0)
			mat.set_shader_parameter("rim_color", Color("#ffb27a"))
			mat.set_shader_parameter("rim_strength", 0.24)
		_:
			mat.set_shader_parameter("pattern_scale", 1.7)
			mat.set_shader_parameter("accent", Color("#ffd98a"))
			mat.set_shader_parameter("accent_glow", 0.85)
			mat.set_shader_parameter("cloud_amount", 0.32)
			mat.set_shader_parameter("rim_color", Color("#9fd0ff"))
			mat.set_shader_parameter("rim_strength", 0.28)

static func _anchor(c: Color, biome: String) -> Color:
	if not BIOME_ANCHOR.has(biome):
		return c
	var entry: Array = BIOME_ANCHOR[biome]
	return c.lerp(entry[0] as Color, float(entry[1]))

# ----------------------------------------------------------------------------- geometry
## Angular diameter in degrees of `target` seen from `viewer`, derived from the map layout.
static func _angular_diameter_deg(viewer: String, target: String) -> float:
	if not SYSTEM_LAYOUT.has(viewer) or not SYSTEM_LAYOUT.has(target):
		return 2.2
	var a: Vector3 = _layout_pos(viewer)
	var b: Vector3 = _layout_pos(target)
	var dist: float = maxf(a.distance_to(b), 1.0)
	var radius: float = float((SYSTEM_LAYOUT[target] as Dictionary)["r"])
	return clampf(ANGULAR_SCALE * radius / dist, ANGULAR_MIN_DEG, ANGULAR_MAX_DEG)

static func _layout_pos(id: String) -> Vector3:
	var e: Dictionary = SYSTEM_LAYOUT[id]
	var a := deg_to_rad(float(e["angle"]))
	var r := float(e["orbit"])
	return Vector3(cos(a) * r, float(e["y"]), sin(a) * r)

## Unit direction at `az_deg` (from local east toward north) and `elev_deg` above local horizontal.
static func _sky_dir(az_deg: float, elev_deg: float, up: Vector3, east: Vector3) -> Vector3:
	var flat := east - up * up.dot(east)
	if flat.length_squared() < 0.0001:
		flat = Vector3.RIGHT - up * up.dot(Vector3.RIGHT)
	flat = flat.normalized().rotated(up, deg_to_rad(az_deg))
	var e := deg_to_rad(elev_deg)
	return (up * sin(e) + flat * cos(e)).normalized()

## Flat annulus in the XZ plane with UV.x = normalized radius (what ring.gdshader expects).
static func _annulus(r_in: float, r_out: float, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for s in segments + 1:
		var a := TAU * float(s) / float(segments)
		var c := cos(a)
		var sn := sin(a)
		verts.append(Vector3(r_in * c, 0.0, r_in * sn))
		uvs.append(Vector2(0.0, float(s) / float(segments)))
		verts.append(Vector3(r_out * c, 0.0, r_out * sn))
		uvs.append(Vector2(1.0, float(s) / float(segments)))
		norms.append(Vector3.UP)
		norms.append(Vector3.UP)
	for s in segments:
		var a0 := s * 2
		idx.append(a0)
		idx.append(a0 + 1)
		idx.append(a0 + 2)
		idx.append(a0 + 1)
		idx.append(a0 + 3)
		idx.append(a0 + 2)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am
