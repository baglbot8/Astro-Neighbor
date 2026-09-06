class_name SpaceGlobe
extends Node3D
## One miniature planet on the solar-system map, styled from its PlanetData so the globe in space
## matches the world you land on: home is green with small blue seas and flat cloud puffs, Zorp is
## muted violet with glowing river lines and two tiny moons, Bolt is grey-blue plates with orange
## seam glow and a tilted ring, the hub is cream/green with a lit town cluster.
##
## The globe spins slowly; clouds, moons and the ring are separate children so they read as layers.

const GLOBE_SHADER := preload("res://src/rocket/globe.gdshader")
const RING_SHADER := preload("res://src/shaders/ring.gdshader")
## Ring geometry as multiples of the body radius. Kept equal to src/world/planet_ring.gd
## (28 m / 39 m on a 13 m planet) and to src/world/sky_bodies.gd, so the ringed world in the sky,
## the one on the map and the one you land on are all the same object.
const RING_INNER_SCALE := 2.15
const RING_OUTER_SCALE := 3.00
const SPIN_DEG_PER_SEC := 3.2

var planet_id: String = "home"
var display_name: String = ""
var radius: float = 2.2
var data: PlanetData

var _surface: MeshInstance3D
var _material: ShaderMaterial
var _spin: Node3D
var _moons: Array[Node3D] = []
var _clouds: Array[Node3D] = []
var _ring: Node3D
var _ring_mat: ShaderMaterial
var _ring_rest: Basis = Basis.IDENTITY
## Land albedo as the planet reads from the GROUND, and as another world's sky paints it. See
## `_apply_biome` / `set_sky_tone`.
var _land_ground := Color.WHITE
var _land_sky := Color.WHITE
var _t := 0.0


## Builds the globe. `globe_radius` is the drawn radius in map metres (home 2.2, hub 3.2, ...).
func setup(planet_data: PlanetData, globe_radius: float) -> void:
	data = planet_data
	planet_id = data.id
	display_name = data.display_name
	radius = globe_radius
	name = "Globe_" + planet_id

	_spin = Node3D.new()
	_spin.name = "Spin"
	_spin.rotation = Vector3(deg_to_rad(-14.0), randf() * TAU, deg_to_rad(6.0))
	add_child(_spin)

	_material = ShaderMaterial.new()
	_material.shader = GLOBE_SHADER
	_apply_biome()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 48
	mesh.rings = 24
	_surface = MeshInstance3D.new()
	_surface.name = "Surface"
	_surface.mesh = mesh
	_surface.material_override = _material
	_spin.add_child(_surface)

	match data.biome:
		"meadow":
			_build_clouds(5)
		"violet":
			_build_moons(2)
		"chrome":
			_build_ring()
		"plaza":
			_build_clouds(3)
			_build_town_glow()


func _process(delta: float) -> void:
	_t += delta
	if _spin != null:
		_spin.rotate_y(deg_to_rad(SPIN_DEG_PER_SEC) * delta)
	for i in _moons.size():
		var m := _moons[i]
		var speed := 0.55 + 0.22 * float(i)
		var tilt := deg_to_rad(18.0 + 26.0 * float(i))
		var a := _t * speed + float(i) * 2.4
		var orbit_r := radius * (1.8 + 0.55 * float(i))
		m.position = Vector3(cos(a) * orbit_r, sin(a) * orbit_r * sin(tilt), sin(a) * orbit_r * cos(tilt))


## Points the shader's night-side test at the sun.
func set_sun_direction(dir: Vector3) -> void:
	_material.set_shader_parameter("sun_dir", dir.normalized())


## Blends the land albedo between what the planet looks like from its own surface (0, the default,
## and what the arrival cut has to match) and the tone another world's sky paints it in (1, what the
## departure cut has to match). See `_apply_biome`.
func set_sky_tone(k: float) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("land_a", _land_ground.lerp(_land_sky, clampf(k, 0.0, 1.0)))


## The plane normal `_build_ring` gave the band, so a seam that borrowed the SKY's tilt for one
## frame can ease back to the map's own.
func ring_rest_normal() -> Vector3:
	return _ring_rest.y.normalized()


## Aims the ring's plane normal along `local_normal` (in this globe's own parent space). The journey
## uses it to line the destination's ring up with the one the real planet is about to draw, and to
## borrow the tilt the departing planet's sky was drawing, since the three scenes' world frames are
## unrelated until the seam pins them together.
func set_ring_normal(local_normal: Vector3) -> void:
	if _ring == null or local_normal.length_squared() < 0.0001:
		return
	var n := local_normal.normalized()
	var x := n.cross(Vector3.FORWARD)
	if x.length_squared() < 0.0001:
		x = n.cross(Vector3.RIGHT)
	x = x.normalized()
	_ring.basis = Basis(x, n, x.cross(n).normalized())


## Lights the ring the way src/world/planet_ring.gd::update_lighting does, so the band across the
## arrival cut is the same warm tan on both sides instead of flipping tone.
func set_ring_lighting(sun_dir: Vector3, night: float) -> void:
	if _ring_mat == null:
		return
	_ring_mat.set_shader_parameter("sun_dir", sun_dir.normalized())
	_ring_mat.set_shader_parameter("night", night)


## Hides the map-only trimmings (orbiting moons, mesh cloud puffs) so this globe can stand in for
## the real world on a seam frame, where neither of those exists. The airless worlds of R2.1 have
## no clouds and their moons live in the sky shader, not in orbit around the disc.
func set_extras_visible(on: bool) -> void:
	for m in _moons:
		m.visible = on
	for c in _clouds:
		c.visible = on


# ============================================================================= biome styling
## Biome identity anchors from STYLE_GUIDE "Color". The planet builder tunes the ground colours for
## how they read UNDER FOOT (very desaturated up close); at map scale a globe has to say "violet
## world" / "chrome world" in one glance, so each albedo is nudged this far toward its anchor while
## keeping the data's value. Amount 0 = use the PlanetData colour untouched.
const BIOME_ANCHOR := {
	"meadow": [Color("#6fbf5f"), 0.10],
	"violet": [Color("#8262a8"), 0.62],
	"chrome": [Color("#8fa3bf"), 0.50],
	"plaza": [Color("#7ec46a"), 0.14],
}


func _anchor(c: Color) -> Color:
	if not BIOME_ANCHOR.has(data.biome):
		return c
	var entry: Array = BIOME_ANCHOR[data.biome]
	return c.lerp(entry[0] as Color, float(entry[1]))


func _apply_biome() -> void:
	# Albedos are pulled down slightly from the ground colours: on a globe you read the FORM, and the
	# light (not the albedo) supplies the brightness — see STYLE_GUIDE "MEASURED art-direction". The
	# old -14%/-20% left Zorp's LIT side at 0.110 luma, which is why its night side then had nowhere
	# left to go but black.
	# TWO land tones, because the two things this globe has to stand in for disagree.
	# `ground_color_a` is what the planet you LAND on looks like, and the arrival cut hands this
	# globe straight over to it. `PlanetData.surface_color` is the planet's dominant tone as
	# src/world/sky_bodies.gd paints it in another world's SKY, which is what the DEPARTURE cut has
	# to match — and for the hub the two are a whole hue apart (green lawn underfoot, cream plaza
	# from orbit). `set_sky_tone` blends between them; the seam picks, and the default is the
	# ground's, because that is the seam that lasts longer on screen.
	_land_ground = _anchor(data.ground_color_a).darkened(0.04)
	_land_sky = _anchor(data.surface_color).darkened(0.04) if data.surface_color.a > 0.0 else _land_ground
	var a := _land_ground
	var b := _anchor(data.ground_color_b).darkened(0.10)
	_material.set_shader_parameter("land_a", a)
	_material.set_shader_parameter("land_b", b)
	_material.set_shader_parameter("low_color", data.ground_color_low.darkened(0.06))
	_material.set_shader_parameter("sea_color", data.water_color.darkened(0.30))
	_material.set_shader_parameter("sea_deep", data.water_deep_color.darkened(0.30))
	_material.set_shader_parameter("shade_tint", Color(0.46, 0.44, 0.70))
	# Explicit, not left on the shader defaults: the night side is art direction, not an accident.
	_material.set_shader_parameter("shade_strength", 0.45)
	_material.set_shader_parameter("shade_floor", 0.60)
	_material.set_shader_parameter("ramp_softness", 0.42)
	match data.biome:
		"meadow":
			_material.set_shader_parameter("mode", 0)
			_material.set_shader_parameter("sea_level", 0.455)
			_material.set_shader_parameter("pattern_scale", 1.55)
			_material.set_shader_parameter("accent", Color("#ffe27a"))
			_material.set_shader_parameter("accent_glow", 0.55)
			_material.set_shader_parameter("rim_color", Color("#9fd0ff"))
			_material.set_shader_parameter("rim_strength", 0.30)
		"violet":
			_material.set_shader_parameter("mode", 1)
			# 1.45 made the "rivers" giant neon amoebas covering ~25% of the disc. At 3.6 the ridge
			# noise finally has the frequency to draw thin water courses (STYLE_GUIDE: Zorp is a
			# MUTED violet world, not a neon one).
			_material.set_shader_parameter("pattern_scale", 3.6)
			_material.set_shader_parameter("accent", Color("#5bb8dd"))
			_material.set_shader_parameter("accent_glow", 0.40)
			_material.set_shader_parameter("rim_color", Color("#c9a6ff"))
			_material.set_shader_parameter("rim_strength", 0.28)
		"chrome":
			_material.set_shader_parameter("mode", 2)
			_material.set_shader_parameter("pattern_scale", 1.35)
			_material.set_shader_parameter("accent", Color("#ff8a3d"))
			_material.set_shader_parameter("accent_glow", 0.55)
			_material.set_shader_parameter("rim_color", Color("#ffb27a"))
			_material.set_shader_parameter("rim_strength", 0.24)
		_:
			_material.set_shader_parameter("mode", 3)
			_material.set_shader_parameter("pattern_scale", 1.7)
			_material.set_shader_parameter("accent", Color("#ffd98a"))
			_material.set_shader_parameter("accent_glow", 2.4)
			_material.set_shader_parameter("rim_color", Color("#9fd0ff"))
			_material.set_shader_parameter("rim_strength", 0.28)


## Flat cloud puffs — a defined silhouette with a flat base, hugging the globe (STYLE_GUIDE: clouds
## are flat puffs with a crisp outline, never grape clusters of spheres).
func _build_clouds(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(planet_id) + 7
	# White and fluffy, like AC clouds. #a3b1c4 read as flat grey-blue scabs stuck on the green.
	var mat := MaterialLib.toon(Color("#f6f8fb"), {"shade": 0.34, "rim": 0.14, "spec": 0.0,
		"shade_tint": Color(0.72, 0.78, 0.94), "softness": 0.45})
	for i in count:
		var dir := Vector3(rng.randfn(), rng.randfn() * 0.6, rng.randfn()).normalized()
		var puff := Node3D.new()
		puff.name = "Cloud%d" % i
		puff.transform = Transform3D(Basis.looking_at(dir.cross(Vector3.UP).normalized(), dir), dir * radius * 1.012)
		_spin.add_child(puff)
		var lobes := rng.randi_range(2, 4)
		var span := radius * 0.088
		for k in lobes:
			var r := radius * rng.randf_range(0.075, 0.108)
			var mi := RocketMeshLib.mi(RocketMeshLib.sphere(r, 12, 6), mat, puff,
				Vector3((float(k) - float(lobes - 1) * 0.5) * span, 0.0, rng.randf_range(-0.04, 0.04) * radius), "Lobe%d" % k)
			# Flat pancake with a flat base — a defined silhouette, not a ball.
			mi.scale = Vector3(1.30, 0.46, 1.0)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_clouds.append(puff)


func _build_moons(count: int) -> void:
	var mat := MaterialLib.toon(Color("#8c86a8"), {"shade": 0.62, "rim": 0.3})
	for i in count:
		var moon := Node3D.new()
		moon.name = "Moon%d" % i
		add_child(moon)
		RocketMeshLib.mi(RocketMeshLib.sphere(radius * (0.16 - 0.04 * float(i)), 14, 8), mat, moon,
			Vector3.ZERO, "Body")
		_moons.append(moon)


func _build_ring() -> void:
	var ring := Node3D.new()
	ring.name = "Ring"
	# Same tilt the real world's ring is built with, so the map's Bolt and the Bolt you land on are
	# the same object from the same angle (STYLE_GUIDE R2.1: "share the look").
	ring.rotation = Vector3(deg_to_rad(RocketJourney.RING_TILT_DEG), 0.0,
		deg_to_rad(RocketJourney.RING_ROLL_DEG))
	add_child(ring)
	_ring = ring
	_ring_rest = ring.basis
	# Same proportions as the real world's ring AND as the one the environment hangs in the sky:
	# src/world/planet_ring.gd is 28 m / 39 m on a 13 m planet, and src/world/sky_bodies.gd mirrors
	# that as RING_INNER_SCALE / RING_OUTER_SCALE. This was 1.7 / 2.9, which is why Bolt's band
	# changed size across BOTH journey cuts and had to be faded in to hide it.
	var mesh := _annulus_uv(radius * RING_INNER_SCALE, radius * RING_OUTER_SCALE, 72)
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	# Colours and opacity lifted from src/world/planet_ring.gd, so the band reads the same warm tan
	# in the map as it does from the ground and across the arrival cut.
	mat.set_shader_parameter("ring_color", data.ring_color.lightened(0.06))
	mat.set_shader_parameter("ring_shade", data.ring_color.darkened(0.32).lerp(Color("#8a6ab0"), 0.4))
	mat.set_shader_parameter("night", 0.42)
	mat.set_shader_parameter("opacity", 0.98)
	var mi := RocketMeshLib.mi(mesh, mat, ring, Vector3.ZERO, "Band")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring_mat = mat


func _build_town_glow() -> void:
	var mat := MaterialLib.glow(Color("#ffd98a"), 3.2, Color("#b08a4a")).duplicate() as ShaderMaterial
	mat.set_shader_parameter("emission_day_scale", 1.0)
	var cluster := Node3D.new()
	cluster.name = "Starport"
	var dir := Vector3(0.42, 0.72, 0.55).normalized()
	cluster.position = dir * radius * 1.005
	_spin.add_child(cluster)
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	for i in 8:
		var off := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * 0.15
		var d := (dir + off).normalized()
		var mi := RocketMeshLib.mi(RocketMeshLib.sphere(radius * rng.randf_range(0.022, 0.036), 8, 4), mat,
			cluster, d * radius * 1.008 - cluster.position, "Light%d" % i)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# One soft halo so the starport is legible from across the system.
	var quad := QuadMesh.new()
	quad.size = Vector2(radius * 0.34, radius * 0.34)
	quad.material = MaterialLib.glow_sprite(Color("#ffd98a"), 1.4, {"softness": 0.5, "core": 0.3})
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = quad
	halo.position = dir * radius * 0.05
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cluster.add_child(halo)


## Flat annulus in the XZ plane with UV.x = normalized radius (what ring.gdshader expects).
static func _annulus_uv(r_in: float, r_out: float, segments: int) -> ArrayMesh:
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
		idx.append(a0); idx.append(a0 + 1); idx.append(a0 + 2)
		idx.append(a0 + 1); idx.append(a0 + 3); idx.append(a0 + 2)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am
