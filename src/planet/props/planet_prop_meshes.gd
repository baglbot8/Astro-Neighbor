class_name PlanetPropMeshes
extends RefCounted
## Procedural prop meshes + materials for every biome. All meshes are cached by key so hundreds of
## instances share one ArrayMesh. Origin = ground contact, +Y up, faces -Z. Most props are a single
## vertex-colored surface (one draw call); glowing parts are extra surfaces with their own material.

const FOLIAGE_SHADER := preload("res://src/shaders/planet_foliage.gdshader")
const CRYSTAL_SHADER := preload("res://src/shaders/crystal.gdshader")
const PULSE_SHADER := preload("res://src/shaders/planet_glow_pulse.gdshader")

static var _mesh_cache: Dictionary = {}
static var _mat_cache: Dictionary = {}

## R2.9: vertex-colour alpha marker that tells `planet_foliage.gdshader` a vertex is WOOD (a trunk,
## a stem, a woody bush base) rather than a leaf, so it gets directional grain and knots instead of
## the soft plump foliage detail. A narrow window in the middle of the range: 0.0 (untinted petals
## and flower stems) and 1.0 (leaves, blades, tinted petals) both keep their existing meaning, and
## the `step(0.5, COLOR.a)` MultiMesh tint test still reads a wood vertex as "do not tint".
const WOOD_ALPHA := 0.35

## Tags a colour as wood for the foliage shader (see WOOD_ALPHA). The mesh kit preserves alpha.
static func _wood(c: Color) -> Color:
	return Color(c.r, c.g, c.b, WOOD_ALPHA)

# ============================================================================================ materials
## Vertex-colored toon for chunky props. R2.6 MATTE: rock, wood, cloth and painted surfaces get
## almost no specular — the toon fake highlight was painting a bright ellipse across every flat top
## face (crate lids, boulder shoulders, bench slats), which is what made props read as glazed.
static func prop_material() -> ShaderMaterial:
	return MaterialLib.toon_vertex_color({"rim": 0.08, "spec": 0.04, "spec_size": 120.0, "roughness": 0.95})

## R2.9 rock: boulders, pebbles and meteorites get the shared `sd_rock` microsurface — a genuinely
## rougher stone read with chipped edges and mottling at two scales, so a rock never looks like
## smooth plastic. `surface_far` is pushed out to 20 m because a boulder is a landmark you see from
## across the planet, not a small decoration.
static func rock_material() -> ShaderMaterial:
	return MaterialLib.toon_vertex_color({
		"rim": 0.08, "spec": 0.04, "spec_size": 120.0, "roughness": 0.95,
		"surface": "rock", "surface_strength": 3.2, "surface_near": 4.0, "surface_far": 22.0})

## Vertex-colored toon with a metallic sheen (robots, gears, pipes). R2.6: this is PAINTED metal, so
## it keeps only a small tight highlight; real gloss stays with the genuinely shiny things — the
## visor, the water shell and the crystal/oil materials below.
## R2.9: brushed grain, micro-scratches and a soft travelling sheen come from the shared library
## (`MaterialLib.metal()` opts in by default; `toon_vertex_color` does not, so it is asked for here).
static func metal_material() -> ShaderMaterial:
	return MaterialLib.toon_vertex_color({
		"metallic": 0.22, "roughness": 0.66, "spec": 0.20, "spec_size": 190.0, "rim": 0.18,
		"surface": "metal", "surface_strength": 0.9, "surface_near": 3.5, "surface_far": 16.0})

## Wind-swaying vertex-colored toon (foliage). `tint` enables per-instance MultiMesh custom-data tint.
## R2.6 MATTE: rim/spec default near zero — leaves, petals and grass blades have no gloss, and the
## fake toon highlight used to paint a wet-looking ellipse across every canopy tier and flower head.
## R2.9: pass `surf` to opt into the shared surface-detail vocabulary — plump softness with a hint of
## subsurface warmth on leaves, directional grain with knots on anything marked WOOD_ALPHA. Left OFF
## by default so the grass-tuft MultiMesh (thousands of 16 cm blades, exempt under R2.9's "small
## pieces") pays nothing. Keys: strength, scale, near, far, bump, light, wood, knot, sss.
static func foliage_material(sway: float, sway_height: float, tint: bool = false, speed: float = 1.6, emission: Color = Color.BLACK, emission_strength: float = 0.0, rim: float = 0.09, spec: float = 0.04, surf: Dictionary = {}) -> ShaderMaterial:
	var key := "foliage|%.3f|%.2f|%s|%.2f|%s|%.2f|%.2f|%.2f|%s" % [sway, sway_height, tint, speed, emission.to_html(), emission_strength, rim, spec, str(surf)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = FOLIAGE_SHADER
	m.set_shader_parameter("sway_amount", sway)
	m.set_shader_parameter("sway_height", sway_height)
	m.set_shader_parameter("sway_speed", speed)
	m.set_shader_parameter("use_instance_tint", tint)
	m.set_shader_parameter("emission_color", emission)
	m.set_shader_parameter("emission_strength", emission_strength)
	m.set_shader_parameter("rim_strength", rim)
	m.set_shader_parameter("spec_strength", spec)
	if not surf.is_empty():
		m.set_shader_parameter("surface_strength", surf.get("strength", 1.0))
		m.set_shader_parameter("surface_scale", surf.get("scale", 0.35))
		m.set_shader_parameter("surface_near", surf.get("near", 4.0))
		m.set_shader_parameter("surface_far", surf.get("far", 16.0))
		m.set_shader_parameter("surface_bump", surf.get("bump", 0.10))
		m.set_shader_parameter("surface_light", surf.get("light", 0.8))
		m.set_shader_parameter("wood_strength", surf.get("wood", 1.3))
		m.set_shader_parameter("wood_knot", surf.get("knot", 0.35))
		m.set_shader_parameter("sss_strength", surf.get("sss", 0.0))
	_mat_cache[key] = m
	return m

## Faceted glowing crystal material.
static func crystal_material(albedo: Color, glow: Color, strength: float = 2.2, faceted: bool = true, core: float = 0.35) -> ShaderMaterial:
	var key := "crystal|%s|%s|%.2f|%s|%.2f" % [albedo.to_html(), glow.to_html(), strength, faceted, core]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = CRYSTAL_SHADER
	m.set_shader_parameter("albedo", albedo)
	m.set_shader_parameter("glow_color", glow)
	m.set_shader_parameter("glow_strength", strength)
	m.set_shader_parameter("faceted", faceted)
	m.set_shader_parameter("core_glow", core)
	_mat_cache[key] = m
	return m

## Pulsing/blinking emissive toon (mode 0 breathe, 1 blink, 2 steady).
static func pulse_material(emission: Color, strength: float, speed: float = 2.0, mode: int = 0, pulse_min: float = 0.2, albedo: Color = Color.WHITE) -> ShaderMaterial:
	var key := "pulse|%s|%.2f|%.2f|%d|%.2f|%s" % [emission.to_html(), strength, speed, mode, pulse_min, albedo.to_html()]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = PULSE_SHADER
	m.set_shader_parameter("emission_color", emission)
	m.set_shader_parameter("emission_strength", strength)
	m.set_shader_parameter("pulse_speed", speed)
	m.set_shader_parameter("pulse_mode", mode)
	m.set_shader_parameter("pulse_min", pulse_min)
	m.set_shader_parameter("albedo", albedo)
	_mat_cache[key] = m
	return m

## Soft additive sparkle quad material for particles.
static func sparkle_material(color: Color) -> StandardMaterial3D:
	var key := "sparkle|%s" % color.to_html()
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = color
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.disable_receive_shadows = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = soft_dot_texture()
	_mat_cache[key] = m
	return m

static var _soft_dot: ImageTexture

## 64x64 radial falloff (white, alpha) for soft particle sprites and ground glows.
static func soft_dot_texture() -> ImageTexture:
	if _soft_dot:
		return _soft_dot
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(size * 0.5, size * 0.5)) / (size * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_soft_dot = ImageTexture.create_from_image(img)
	return _soft_dot

## Soft alpha puff material (steam, dust).
static func puff_material(color: Color) -> StandardMaterial3D:
	var key := "puff|%s" % color.to_html()
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.vertex_color_use_as_albedo = true
	m.disable_receive_shadows = true
	_mat_cache[key] = m
	return m

static func _cached(key: String, builder: Callable) -> ArrayMesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m: ArrayMesh = builder.call()
	_mesh_cache[key] = m
	return m

# ============================================================================================ meadow
## Broadleaf tree, ACNH grammar: a straight tapering trunk and 2-3 stacked, slightly flattened
## canopy tiers with scalloped rims, a crisp rim edge and a genuinely dark flat underside.
## `shadow` is the underside/lower-tier colour (PlanetData.foliage_shadow_color).
static func puff_tree(trunk: Color, leaf: Color, leaf_light: Color, shadow: Color, blossom: Color, variant: int) -> ArrayMesh:
	var key := "tree|%s|%s|%s|%s|%s|%d" % [trunk.to_html(), leaf.to_html(), leaf_light.to_html(), shadow.to_html(), blossom.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# Thick straight tapering trunk with a root flare; darker at the base.
		var prof := PackedVector2Array([
			Vector2(0.0, -0.30), Vector2(0.52, -0.30), Vector2(0.40, 0.05),
			Vector2(0.33, 0.60), Vector2(0.28, 1.15), Vector2(0.26, 1.45), Vector2(0.0, 1.45)])
		# R2.9: WOOD_ALPHA in the vertex colour marks these two lathes as wood, so the foliage shader
		# gives the trunk directional grain and knots along its own +Y axis instead of leaf softness.
		kit.lathe(prof, 18, Transform3D.IDENTITY, _wood(trunk))
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.30), Vector2(0.54, -0.30), Vector2(0.44, 0.02), Vector2(0.0, 0.02)]),
			18, Transform3D.IDENTITY, _wood(trunk.darkened(0.24)))
		var tiers := 3 if variant % 3 == 0 else 2
		var ph := float(variant) * 0.9
		# Tier placement rule (learned the hard way): each upper tier's dark skirt + flat underside
		# disc MUST sit BELOW the tier under it at every lobe angle, or the disc pokes through the
		# canopy as an irregular dark patch that reads as mould. Radii/heights below are chosen so
		# every disc is buried by >= 0.1 m while the scalloped rim still emerges as a crisp tier edge.
		# Value spread between tiers stays small — the structure is the silhouette, not the shading.
		# SCALLOPED LEAF LOBES, not a smooth dome. The critic's shape sheet put our canopy next to
		# ACNH's and ours read as a plain flat-shaded hill: lobe_depth 0.12-0.14 with the default
		# lobe_taper of 1.0 killed the scallops by half way up, so the only place a lobe existed was
		# the rim, and the tier boundaries then read as irregular dark patches — camouflage, which the
		# style guide bans by name. Deeper lobes (0.20-0.23) that carry most of the way up
		# (lobe_taper 0.45) give every tier a row of leaf clumps in silhouette AND in 3-D.
		# The tier VALUES are also pulled together (0.45 -> 0.32, 0.85 -> 0.55): the top tier used to
		# be 85% of the light leaf, which under full sun landed on the ACES shoulder as a pale sage
		# cap (measured #b7c7ad S 0.13 on the crown).
		var mid := leaf.lerp(leaf_light, 0.32)
		if tiers == 3:
			kit.lobed_dome(Vector3(0.0, 1.10, 0.0), 1.26, 0.86, leaf, shadow, 8, 0.21, 0.88, ph, 36, 8, 0.14, Basis.IDENTITY, 0.45)
			kit.lobed_dome(Vector3(0.0, 1.58, 0.0), 0.86, 0.72, mid, shadow.lightened(0.06), 7, 0.22, 0.88, ph + 1.1, 34, 8, 0.10, Basis.IDENTITY, 0.45)
			kit.lobed_dome(Vector3(0.0, 1.98, 0.0), 0.56, 0.60, leaf.lerp(leaf_light, 0.55), shadow.lightened(0.12), 6, 0.23, 0.88, ph + 2.2, 30, 7, 0.08, Basis.IDENTITY, 0.45)
		else:
			kit.lobed_dome(Vector3(0.0, 1.18, 0.0), 1.36, 1.00, leaf, shadow, 8, 0.21, 0.90, ph, 36, 9, 0.16, Basis.IDENTITY, 0.45)
			kit.lobed_dome(Vector3(0.0, 1.78, 0.0), 0.92, 0.78, mid, shadow.lightened(0.08), 7, 0.22, 0.90, ph + 1.4, 32, 8, 0.10, Basis.IDENTITY, 0.45)
		if variant % 3 == 1:
			# Blossoms sit ON the tier-1 shoulder (r 1.28 -> surface y ~1.55) instead of half-buried
			# inside it, so they read as fruit on the canopy rather than specks of noise.
			for i in 6:
				var ang := ph * 1.3 + TAU * float(i) / 6.0
				kit.sphere(Vector3(cos(ang) * 1.28, 1.53 + 0.10 * sin(ang * 3.0), sin(ang) * 1.28), 0.10, blossom, Vector3(1.0, 0.7, 1.0), 8)
		return kit.commit()
	return _cached(key, build)

## Bush: a CLUSTER of three clipped leaf clumps at different heights and radii, not one scalloped
## plate. The old version was a single wide dome whose scallops died out by the top (lobe_taper 1),
## so from any elevated angle its silhouette was a flat seven-pointed star with a hard rim — the
## "cardboard cut-out" the hub critic photographed. Now the lobes carry most of the way up
## (lobe_taper 0.35), the dome is taller than it is wide-and-flat, and the two side clumps break the
## outline at different heights so the shrub has a real 3-D read from above.
static func bush(leaf: Color, shadow: Color, berry: Color, variant: int) -> ArrayMesh:
	var key := "bush2|%s|%s|%s|%d" % [leaf.to_html(), shadow.to_html(), berry.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var ph := float(variant) * 1.1
		# A short woody base so the clumps sit ON something instead of hovering at ground level.
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.06), Vector2(0.30, -0.06), Vector2(0.22, 0.16), Vector2(0.0, 0.18)]),
			12, Transform3D.IDENTITY, _wood(shadow.darkened(0.10)))
		kit.lobed_dome(Vector3(0.0, 0.20, 0.0), 0.62, 0.66, leaf, shadow, 7, 0.20, 1.00, ph, 30, 6, 0.10,
			Basis.IDENTITY, 0.35)
		kit.lobed_dome(Vector3(0.33, 0.09, 0.17), 0.42, 0.50, leaf.lightened(0.06), shadow.lightened(0.05), 6, 0.22, 1.00, ph + 1.7, 26, 5, 0.08,
			Basis.IDENTITY, 0.40)
		kit.lobed_dome(Vector3(-0.26, 0.13, -0.22), 0.36, 0.44, leaf.darkened(0.06), shadow, 6, 0.22, 1.00, ph + 3.1, 24, 5, 0.08,
			Basis.IDENTITY, 0.40)
		if variant % 2 == 0:
			for i in 4:
				var ang := TAU * float(i) / 4.0 + 0.4
				kit.sphere(Vector3(cos(ang) * 0.42, 0.52 + 0.10 * sin(ang * 2.0), sin(ang) * 0.42), 0.06, berry, Vector3.ONE, 8)
		return kit.commit()
	return _cached(key, build)

## Spotted mushroom.
static func mushroom(cap: Color, stem: Color, variant: int) -> ArrayMesh:
	var key := "mush|%s|%s|%d" % [cap.to_html(), stem.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var s := 1.0 + 0.25 * float(variant % 3)
		var stem_prof := PackedVector2Array([Vector2(0.0, -0.1), Vector2(0.17, -0.1), Vector2(0.14, 0.2), Vector2(0.16, 0.4), Vector2(0.0, 0.4)])
		kit.lathe(stem_prof, 12, Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3.ZERO), stem)
		var cap_prof := PackedVector2Array([Vector2(0.0, 0.3), Vector2(0.4, 0.3), Vector2(0.46, 0.36), Vector2(0.42, 0.5), Vector2(0.26, 0.64), Vector2(0.0, 0.7)])
		kit.lathe(cap_prof, 16, Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3.ZERO), cap)
		for i in 5:
			var ang := TAU * float(i) / 5.0 + float(variant)
			var rr := 0.2 + 0.12 * float(i % 2)
			var y := 0.66 - rr * rr * 1.1
			kit.sphere(Vector3(cos(ang) * rr, y, sin(ang) * rr) * s, 0.055 * s, Color("#fff8ec"), Vector3(1.0, 0.5, 1.0), 8)
		return kit.commit()
	return _cached(key, build)

## Boulder cluster: flat-shaded faceted domes with clear ground contact and dark down-facing facets.
## Deliberately NOT spheres — the facets give it structure at gameplay distance.
static func pebble_rock(rock: Color, variant: int) -> ArrayMesh:
	var key := "rock|%s|%d" % [rock.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var yaw := Basis(Vector3.UP, 0.7 * float(variant))
		kit.faceted_blob(Vector3(0.0, 0.16, 0.0), 0.50, rock, Vector3(1.0, 0.62, 0.88), 1, 0.22, float(variant) * 3.1, yaw)
		kit.faceted_blob(Vector3(0.38, 0.10, 0.22), 0.30, rock.darkened(0.10), Vector3(1.0, 0.66, 0.9), 1, 0.26, float(variant) * 7.7, yaw)
		kit.faceted_blob(Vector3(-0.32, 0.08, -0.24), 0.25, rock.darkened(0.18), Vector3(1.0, 0.7, 1.0), 1, 0.24, float(variant) * 11.3, yaw)
		if variant % 2 == 1:
			kit.faceted_blob(Vector3(0.06, 0.36, -0.12), 0.21, rock.lightened(0.06), Vector3(1.0, 0.8, 1.0), 1, 0.3, float(variant) * 5.5, yaw)
		return kit.commit()
	return _cached(key, build)

## Single flower for MultiMesh (petals COLOR.a = 1 -> instance tint; stem/leaves/center untinted).
static func flower(stem: Color, center: Color, variant: int) -> ArrayMesh:
	var key := "flower|%s|%s|%d" % [stem.to_html(), center.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var st := Color(stem.r, stem.g, stem.b, 0.0)
		kit.cylinder(Vector3(0.0, -0.03, 0.0), 0.024, 0.02, 0.3, st, Basis.IDENTITY, 8)
		kit.sphere(Vector3(0.07, 0.12, 0.0), 0.06, st, Vector3(1.2, 0.35, 0.7), 8, Basis(Vector3.FORWARD, -0.5))
		kit.sphere(Vector3(-0.06, 0.17, 0.03), 0.055, st, Vector3(1.2, 0.35, 0.7), 8, Basis(Vector3.FORWARD, 0.6))
		var petals := 5 + (variant % 2)
		var petal_col := Color(1.0, 1.0, 1.0, 1.0)
		for i in petals:
			var ang := TAU * float(i) / float(petals)
			var basis := Basis(Vector3.UP, -ang) * Basis(Vector3.FORWARD, -0.35)
			kit.sphere(Vector3(cos(ang) * 0.085, 0.31, sin(ang) * 0.085), 0.075, petal_col, Vector3(1.15, 0.42, 0.7), 10, basis)
		kit.sphere(Vector3(0.0, 0.33, 0.0), 0.05, Color(center.r, center.g, center.b, 0.0), Vector3(1.0, 0.7, 1.0), 10)
		return kit.commit()
	return _cached(key, build)

## Grass tuft: three bent blades (double-sided). COLOR.a = 1 so instances tint via custom data.
static func grass_tuft(variant: int) -> ArrayMesh:
	var key := "tuft|%d" % variant
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var c := Color(1.0, 1.0, 1.0, 1.0)
		var blades := 3 + (variant % 2)
		for i in blades:
			var ang := TAU * float(i) / float(blades) + 0.4 * float(variant)
			var dir := Vector3(cos(ang), 0.0, sin(ang))
			var h := 0.16 + 0.04 * float((i + variant) % 3)
			var w := 0.04
			var side := Vector3(-dir.z, 0.0, dir.x) * w
			var base := dir * 0.03
			var mid := base + dir * 0.05 + Vector3(0.0, h * 0.55, 0.0)
			var tip := base + dir * 0.13 + Vector3(0.0, h, 0.0)
			var cb := c.darkened(0.15)
			cb.a = 1.0
			kit.quad(base - side - Vector3(0, 0.03, 0), base + side - Vector3(0, 0.03, 0), mid + side * 0.6, mid - side * 0.6, cb)
			kit.triangle(mid - side * 0.6, mid + side * 0.6, tip, c)
		return kit.commit()
	return _cached(key, build)

# ============================================================================================ violet
## Mushroom tree: a straight tapering stem and a WIDE, flattened, scalloped cap with a thick crisp
## rim and a dark gilled underside — a structured silhouette, not a balloon on a stick.
## `shadow` is the gill/underside colour. Glowing spots come from mushroom_tree_spots().
static func mushroom_tree(cap: Color, stem: Color, shadow: Color, variant: int) -> ArrayMesh:
	var key := "mtree|%s|%s|%s|%d" % [cap.to_html(), stem.to_html(), shadow.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var stem_prof := PackedVector2Array([
			Vector2(0.0, -0.3), Vector2(0.46, -0.3), Vector2(0.34, 0.1),
			Vector2(0.27, 0.9), Vector2(0.24, 1.65), Vector2(0.30, 1.92), Vector2(0.0, 1.92)])
		# NOT marked as wood: a mushroom stem is soft fungus, and sd_wood's grain read as engraved
		# scribbles on the pale stem. It takes the plump foliage detail like the cap does.
		kit.lathe(stem_prof, 18, Transform3D.IDENTITY, stem)
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.3), Vector2(0.48, -0.3), Vector2(0.38, 0.05), Vector2(0.0, 0.05)]),
			18, Transform3D.IDENTITY, stem.darkened(0.22))
		var ph := float(variant) * 0.8
		var tall := 1 if variant % 2 == 0 else 0
		var cap_y := 1.86 + 0.18 * float(tall)
		# Wide flat cap: thick dark rim skirt + dark flat gill disc underneath.
		kit.lobed_dome(Vector3(0.0, cap_y, 0.0), 1.34, 0.66, cap, shadow, 11, 0.055, 0.52, ph, 40, 6, 0.20)
		# Radial gill ridges on the underside so the flat disc is not a blank plate.
		for i in 16:
			var ang := TAU * float(i) / 16.0 + ph
			var dir := Vector3(cos(ang), 0.0, sin(ang))
			var side := Vector3(-dir.z, 0.0, dir.x) * 0.035
			var a := Vector3(0.0, cap_y - 0.205, 0.0) + dir * 0.26
			var b := Vector3(0.0, cap_y - 0.205, 0.0) + dir * 1.24
			kit.quad(a - side, b - side, b + side, a + side, shadow.lightened(0.16))
		if variant % 3 == 0:
			kit.lobed_dome(Vector3(0.0, cap_y + 0.52, 0.0), 0.46, 0.30, cap.lightened(0.10), shadow.lightened(0.12), 7, 0.10, 0.60, ph + 1.6, 24, 4, 0.06)
		return kit.commit()
	return _cached(key, build)

## Glowing spots on a mushroom tree cap (separate mesh: crystal shader, unfaceted).
static func mushroom_tree_spots(variant: int) -> ArrayMesh:
	var key := "mtree_spots|%d" % variant
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# Sampled from the cap surface of mushroom_tree() so the spots sit flush on the cap.
		var cap_y := 1.86 + (0.18 if variant % 2 == 0 else 0.0)
		var pts := [Vector2(0.51, 0.634), Vector2(0.87, 0.574), Vector2(1.14, 0.470), Vector2(1.27, 0.350)]
		var n := 7 + variant % 3
		for i in n:
			var ang := TAU * float(i) / float(n) + 0.3 * float(variant)
			var p: Vector2 = pts[i % pts.size()]
			var r := 0.10 + 0.045 * float(i % 3)
			kit.sphere(Vector3(cos(ang) * p.x, cap_y + p.y, sin(ang) * p.x), r, Color.WHITE, Vector3(1.0, 0.45, 1.0), 10)
		return kit.commit()
	return _cached(key, build)

## Crystal cluster: hexagonal prisms with pointed tips. Surface 0 = color A, surface 1 = color B.
static func crystal_cluster(variant: int) -> ArrayMesh:
	var key := "crystals|%d" % variant
	var build := func() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 700 + variant
		for surf in 2:
			var kit := PlanetMeshKit.new()
			var count := 2 + (variant + surf) % 2
			for i in count:
				var h := rng.randf_range(0.55, 1.15) if surf == 0 else rng.randf_range(0.35, 0.7)
				var w := h * rng.randf_range(0.2, 0.28)
				var prof := PackedVector2Array([Vector2(0.0, -0.25), Vector2(w, -0.25), Vector2(w * 1.05, h * 0.62), Vector2(0.0, h)])
				var tilt := rng.randf_range(0.1, 0.45) if not (surf == 0 and i == 0) else 0.05
				var az := rng.randf_range(0.0, TAU)
				var basis := PlanetMeshKit.tilt_basis(tilt, az, rng.randf_range(0.0, TAU))
				var off := Vector3(cos(az + PI) * 0.18, 0.0, sin(az + PI) * 0.18) * float(i)
				kit.lathe(prof, 6, Transform3D(basis, off), Color.WHITE, false)
			kit.commit(mesh)
		return mesh
	return _cached(key, build)

## Tentacle plant: curved tapered tentacles with glowing bulbs (bulbs = surface 1).
static func tentacle_plant(body: Color, tip: Color, variant: int) -> ArrayMesh:
	var key := "tentacle|%s|%s|%d" % [body.to_html(), tip.to_html(), variant]
	var build := func() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		var kit := PlanetMeshKit.new()
		var bulbs := PlanetMeshKit.new()
		var n := 3 + variant % 3
		kit.sphere(Vector3(0.0, 0.05, 0.0), 0.32, body.darkened(0.15), Vector3(1.0, 0.5, 1.0), 14)
		for i in n:
			var az := TAU * float(i) / float(n) + 0.5 * float(variant)
			var out := Vector3(cos(az), 0.0, sin(az))
			var segs := 5
			var pos := Vector3(out.x * 0.12, 0.0, out.z * 0.12)
			var tilt := 0.15
			var r := 0.11
			var seg_len := 0.28 + 0.04 * float(i % 2)
			for s in segs:
				var basis := Basis(out.cross(Vector3.UP).normalized(), -tilt)
				var axis_dir := basis * Vector3.UP
				var r_top := r * 0.78
				kit.cylinder(pos, r, r_top, seg_len, body.lerp(tip, float(s) / float(segs)), basis, 10)
				kit.sphere(pos + axis_dir * seg_len, r_top, body.lerp(tip, float(s + 1) / float(segs)), Vector3.ONE, 10)
				pos += axis_dir * seg_len
				tilt += 0.28
				r = r_top
			bulbs.sphere(pos, r * 1.9, Color.WHITE, Vector3.ONE, 10)
		kit.commit(mesh)
		bulbs.commit(mesh)
		return mesh
	return _cached(key, build)

# ============================================================================================ chrome
## Gear (flat cog): disc + rounded teeth + hub. Lies in the XZ plane, centered at origin.
static func gear(r: float, teeth: int, thickness: float, color: Color, hub_color: Color) -> ArrayMesh:
	var key := "gear|%.2f|%d|%.2f|%s|%s" % [r, teeth, thickness, color.to_html(), hub_color.to_html()]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var ht := thickness * 0.5
		var prof := PackedVector2Array([Vector2(0.0, -ht), Vector2(r, -ht), Vector2(r, ht), Vector2(0.0, ht)])
		kit.lathe(prof, 24, Transform3D.IDENTITY, color, false)
		var tw := r * 0.22
		for i in teeth:
			var ang := TAU * float(i) / float(teeth)
			var basis := Basis(Vector3.UP, -ang)
			kit.rounded_box(basis * Vector3(r + tw * 0.45, 0.0, 0.0), Vector3(tw * 1.3, thickness, tw), tw * 0.3, color, basis)
		kit.cylinder(Vector3(0.0, -ht - 0.02, 0.0), r * 0.3, r * 0.3, thickness + 0.04, hub_color, Basis.IDENTITY, 12)
		var spokes := 4
		for i in spokes:
			var ang := TAU * float(i) / float(spokes)
			var basis := Basis(Vector3.UP, -ang)
			kit.rounded_box(basis * Vector3(r * 0.5, 0.0, 0.0), Vector3(r * 0.55, thickness * 1.15, r * 0.12), 0.02, hub_color.darkened(0.1), basis)
		return kit.commit()
	return _cached(key, build)

## Gear-tree pole with base plate and a top cap (gears are separate rotating children).
static func gear_pole(color: Color, base: Color, height: float) -> ArrayMesh:
	var key := "gearpole|%s|%s|%.2f" % [color.to_html(), base.to_html(), height]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var base_prof := PackedVector2Array([Vector2(0.0, -0.2), Vector2(0.55, -0.2), Vector2(0.5, 0.08), Vector2(0.3, 0.16), Vector2(0.0, 0.16)])
		kit.lathe(base_prof, 16, Transform3D.IDENTITY, base)
		kit.cylinder(Vector3(0.0, 0.1, 0.0), 0.13, 0.11, height - 0.1, color, Basis.IDENTITY, 12)
		kit.sphere(Vector3(0.0, height, 0.0), 0.17, base, Vector3.ONE, 12)
		return kit.commit()
	return _cached(key, build)

## Antenna tower: tripod legs, mast, dish, ring. Blinking light = surface 1.
static func antenna_tower(metal: Color, accent: Color, variant: int) -> ArrayMesh:
	var key := "antenna|%s|%s|%d" % [metal.to_html(), accent.to_html(), variant]
	var build := func() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		var kit := PlanetMeshKit.new()
		var h := 3.0 + 0.4 * float(variant % 2)
		for i in 3:
			var az := TAU * float(i) / 3.0
			var foot := Vector3(cos(az) * 0.55, -0.15, sin(az) * 0.55)
			var top := Vector3(0.0, 1.1, 0.0)
			var d := (top - foot)
			var basis := Basis.looking_at(d.normalized(), Vector3.RIGHT if absf(d.normalized().dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD) * Basis(Vector3.RIGHT, PI * 0.5)
			kit.cylinder(foot, 0.08, 0.07, d.length(), metal, basis, 8)
			kit.sphere(foot, 0.12, metal.darkened(0.15), Vector3(1.0, 0.5, 1.0), 10)
		kit.sphere(Vector3(0.0, 1.1, 0.0), 0.16, accent, Vector3.ONE, 12)
		kit.cylinder(Vector3(0.0, 1.1, 0.0), 0.07, 0.05, h - 1.1, metal, Basis.IDENTITY, 10)
		# dish
		var dish_prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.3, 0.06), Vector2(0.5, 0.2), Vector2(0.52, 0.26), Vector2(0.44, 0.28), Vector2(0.26, 0.16), Vector2(0.0, 0.12)])
		var dbasis := Basis(Vector3.RIGHT, -0.9) * Basis(Vector3.UP, 0.6 * float(variant))
		kit.lathe(dish_prof, 16, Transform3D(dbasis, Vector3(0.0, h * 0.62, 0.0)), metal.lightened(0.2), true, true)
		kit.torus(Vector3(0.0, h - 0.5, 0.0), 0.22, 0.03, accent, Basis.IDENTITY, 20)
		kit.commit(mesh)
		var light := PlanetMeshKit.new()
		light.sphere(Vector3(0.0, h + 0.08, 0.0), 0.12, Color.WHITE, Vector3.ONE, 12)
		light.commit(mesh)
		return mesh
	return _cached(key, build)

## Steam pipe: vertical pipe, elbow, nozzle, bands. Steam comes from a particle node placed by PlanetProps.
static func steam_pipe(pipe: Color, band: Color, variant: int) -> ArrayMesh:
	var key := "pipe|%s|%s|%d" % [pipe.to_html(), band.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var h := 0.9 + 0.3 * float(variant % 3)
		kit.cylinder(Vector3(0.0, -0.25, 0.0), 0.17, 0.17, h + 0.25, pipe, Basis.IDENTITY, 14)
		kit.torus(Vector3(0.0, 0.1, 0.0), 0.17, 0.05, band, Basis.IDENTITY, 16)
		kit.torus(Vector3(0.0, h * 0.55, 0.0), 0.17, 0.05, band, Basis.IDENTITY, 16)
		kit.sphere(Vector3(0.0, h, 0.0), 0.2, pipe, Vector3.ONE, 14)
		var arm := Basis(Vector3.FORWARD, PI * 0.5)
		kit.cylinder(Vector3(0.0, h, 0.0), 0.17, 0.17, 0.42, pipe, arm, 14)
		var nozzle := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.24, 0.14), Vector2(0.2, 0.2), Vector2(0.0, 0.2)])
		kit.lathe(nozzle, 14, Transform3D(arm, Vector3(-0.42, h, 0.0)), band, false)
		return kit.commit()
	return _cached(key, build)

## Hex nut lying on the ground (with a bolt beside it for variant odd).
static func nut_rock(steel: Color, brass: Color, variant: int) -> ArrayMesh:
	var key := "nut|%s|%s|%d" % [steel.to_html(), brass.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var s := 0.8 + 0.25 * float(variant % 3)
		var nut := PackedVector2Array([Vector2(0.24, -0.06), Vector2(0.5, -0.06), Vector2(0.5, 0.3), Vector2(0.24, 0.3), Vector2(0.24, -0.06)])
		var basis := Basis(Vector3.UP, 0.4 * float(variant))
		kit.lathe(nut, 6, Transform3D(basis * Basis.from_scale(Vector3(s, s, s)), Vector3.ZERO), steel, false, true)
		if variant % 2 == 1:
			var bb := Basis(Vector3.UP, 1.1) * Basis(Vector3.RIGHT, PI * 0.5)
			kit.cylinder(Vector3(0.75, 0.13, 0.1), 0.12, 0.12, 0.7, brass, bb * Basis.IDENTITY, 12)
			var head := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.24, 0.16), Vector2(0.0, 0.16)])
			kit.lathe(head, 6, Transform3D(bb, Vector3(0.75, 0.13, 0.1)), brass.darkened(0.1), false)
			kit.sphere(Vector3(0.75, 0.13, 0.1), 0.14, brass.darkened(0.1), Vector3(1.0, 0.1, 1.0), 6)
		return kit.commit()
	return _cached(key, build)

## Lamp post: pole + boxy head; the glowing panel is surface 1.
static func lamp_post(pole: Color, head: Color, height: float, round_globe: bool) -> ArrayMesh:
	var key := "lamp|%s|%s|%.2f|%s" % [pole.to_html(), head.to_html(), height, round_globe]
	var build := func() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		var kit := PlanetMeshKit.new()
		var base_prof := PackedVector2Array([Vector2(0.0, -0.2), Vector2(0.3, -0.2), Vector2(0.26, 0.1), Vector2(0.14, 0.2), Vector2(0.0, 0.2)])
		kit.lathe(base_prof, 14, Transform3D.IDENTITY, pole.darkened(0.1))
		kit.cylinder(Vector3(0.0, 0.15, 0.0), 0.09, 0.075, height - 0.15, pole, Basis.IDENTITY, 12)
		kit.torus(Vector3(0.0, height - 0.35, 0.0), 0.09, 0.03, head, Basis.IDENTITY, 14)
		if round_globe:
			kit.sphere(Vector3(0.0, height + 0.05, 0.0), 0.14, head, Vector3(1.0, 0.5, 1.0), 12)
		else:
			kit.rounded_box(Vector3(0.0, height + 0.02, 0.0), Vector3(0.36, 0.06, 0.36), 0.02, head)
			kit.rounded_box(Vector3(0.0, height + 0.36, 0.0), Vector3(0.52, 0.08, 0.52), 0.03, head.darkened(0.1))
			for cx in [-0.19, 0.19]:
				for cz in [-0.19, 0.19]:
					kit.rounded_box(Vector3(cx, height + 0.19, cz), Vector3(0.05, 0.3, 0.05), 0.02, head)
		kit.commit(mesh)
		var glow := PlanetMeshKit.new()
		if round_globe:
			glow.sphere(Vector3(0.0, height + 0.38, 0.0), 0.3, Color.WHITE, Vector3.ONE, 16)
		else:
			glow.rounded_box(Vector3(0.0, height + 0.19, 0.0), Vector3(0.4, 0.28, 0.4), 0.06, Color.WHITE)
		glow.commit(mesh)
		return mesh
	return _cached(key, build)

## Supply crate: a chamfered container with corner posts, a lid rim and a stencilled band. Bolt's
## yard needs things with FLAT PANELS and hard edges standing on it, not only poles — a deck with
## nothing but masts on it reads as a golf ball with pins in it.
static func supply_crate(body: Color, trim: Color, variant: int) -> ArrayMesh:
	var key := "crate|%s|%s|%d" % [body.to_html(), trim.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var w := 0.95 + 0.22 * float(variant % 3)
		var hgt := 0.72 + 0.16 * float((variant + 1) % 3)
		var d := 0.85
		kit.rounded_box(Vector3(0.0, hgt * 0.5, 0.0), Vector3(w, hgt, d), 0.06, body)
		# corner posts + lid rim
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				kit.rounded_box(Vector3(sx * (w * 0.5 - 0.05), hgt * 0.5, sz * (d * 0.5 - 0.05)),
					Vector3(0.13, hgt + 0.03, 0.13), 0.03, trim)
		kit.rounded_box(Vector3(0.0, hgt + 0.03, 0.0), Vector3(w + 0.07, 0.10, d + 0.07), 0.03, trim)
		kit.rounded_box(Vector3(0.0, hgt * 0.62, d * 0.5 + 0.01), Vector3(w * 0.62, 0.14, 0.03), 0.01, trim.lightened(0.16))
		if variant % 2 == 1:
			# a second, smaller crate stacked off-centre — a readable stepped silhouette
			kit.rounded_box(Vector3(w * 0.16, hgt + 0.36, -0.08), Vector3(w * 0.62, 0.58, d * 0.66), 0.05, body.lightened(0.07))
			kit.rounded_box(Vector3(w * 0.16, hgt + 0.66, -0.08), Vector3(w * 0.66, 0.08, d * 0.70), 0.03, trim)
		return kit.commit()
	return _cached(key, build)

## Cooling radiator: a low plinth carrying a row of thin vertical fins. Flat planes and hard edges,
## and the fin row throws a striped shadow across the deck at any sun angle.
static func radiator(metal: Color, fin: Color, variant: int) -> ArrayMesh:
	var key := "radiator|%s|%s|%d" % [metal.to_html(), fin.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var n := 6 + variant % 3
		var span := 1.5
		kit.rounded_box(Vector3(0.0, 0.13, 0.0), Vector3(span + 0.18, 0.26, 0.62), 0.05, metal.darkened(0.14))
		for i in n:
			var t := (float(i) + 0.5) / float(n) - 0.5
			kit.rounded_box(Vector3(t * span, 0.72, 0.0), Vector3(0.075, 0.94, 0.52), 0.02, fin)
		kit.rounded_box(Vector3(0.0, 1.22, 0.0), Vector3(span + 0.12, 0.10, 0.56), 0.03, metal)
		kit.cylinder(Vector3(-span * 0.5 - 0.12, 0.20, 0.0), 0.09, 0.09, 0.9, metal, Basis.IDENTITY, 10)
		return kit.commit()
	return _cached(key, build)

## Vent stack: a squat flared chimney with reinforcing bands and a grille cap.
static func vent_stack(metal: Color, accent: Color, variant: int) -> ArrayMesh:
	var key := "vent|%s|%s|%d" % [metal.to_html(), accent.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var h := 1.35 + 0.30 * float(variant % 3)
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.08), Vector2(0.54, -0.08), Vector2(0.46, 0.16), Vector2(0.0, 0.16)]),
			14, Transform3D.IDENTITY, metal.darkened(0.16), false)
		kit.cylinder(Vector3(0.0, 0.10, 0.0), 0.30, 0.26, h, metal, Basis.IDENTITY, 14)
		kit.torus(Vector3(0.0, h * 0.45, 0.0), 0.28, 0.045, accent, Basis.IDENTITY, 16)
		kit.lathe(PackedVector2Array([Vector2(0.0, h + 0.10), Vector2(0.26, h + 0.10), Vector2(0.42, h + 0.30), Vector2(0.40, h + 0.38), Vector2(0.0, h + 0.38)]),
			14, Transform3D.IDENTITY, metal.lightened(0.10), false)
		for i in 4:
			var ang := TAU * float(i) / 4.0 + 0.4 * float(variant)
			kit.rounded_box(Vector3(cos(ang) * 0.36, h + 0.36, sin(ang) * 0.36), Vector3(0.12, 0.06, 0.12), 0.02, accent.darkened(0.10))
		return kit.commit()
	return _cached(key, build)

## Gantry: two braced legs and a truss beam overhead — the yard's big silhouette. It reads from a
## long way off and lays a long shadow bar across the deck, which is where Bolt's tonal range lives.
static func gantry(metal: Color, accent: Color, span: float, variant: int) -> ArrayMesh:
	var key := "gantry|%s|%s|%.2f|%d" % [metal.to_html(), accent.to_html(), span, variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var h := 2.5 + 0.3 * float(variant % 2)
		for sx: float in [-1.0, 1.0]:
			var x := sx * span * 0.5
			kit.lathe(PackedVector2Array([Vector2(0.0, -0.1), Vector2(0.36, -0.1), Vector2(0.30, 0.12), Vector2(0.0, 0.12)]),
				12, Transform3D.IDENTITY * Transform3D(Basis.IDENTITY, Vector3(x, 0.0, 0.0)), metal.darkened(0.12), false)
			kit.rounded_box(Vector3(x, h * 0.5, 0.0), Vector3(0.24, h, 0.24), 0.05, metal)
			kit.rounded_box(Vector3(x - sx * 0.30, h * 0.28, 0.0), Vector3(0.62, 0.12, 0.12), 0.03, metal.darkened(0.08), Basis(Vector3.FORWARD, sx * 0.75))
		kit.rounded_box(Vector3(0.0, h + 0.10, 0.0), Vector3(span + 0.35, 0.22, 0.26), 0.05, metal)
		kit.rounded_box(Vector3(0.0, h - 0.32, 0.0), Vector3(span - 0.15, 0.12, 0.16), 0.03, metal.darkened(0.10))
		var braces := 5
		for i in braces:
			var t := (float(i) + 0.5) / float(braces) - 0.5
			kit.rounded_box(Vector3(t * (span - 0.2), h - 0.11, 0.0), Vector3(0.10, 0.44, 0.12), 0.02, metal.darkened(0.06),
				Basis(Vector3.FORWARD, (0.55 if i % 2 == 0 else -0.55)))
		kit.rounded_box(Vector3(0.0, h + 0.26, 0.0), Vector3(0.5, 0.12, 0.3), 0.03, accent)
		return kit.commit()
	return _cached(key, build)

# ============================================================================================ plaza
## Topiary: pot, short trunk, and one or two clipped tiers (flattened lobed domes with dark undersides).
static func topiary(pot: Color, leaf: Color, shadow: Color, trunk: Color, variant: int) -> ArrayMesh:
	var key := "topiary|%s|%s|%s|%s|%d" % [pot.to_html(), leaf.to_html(), shadow.to_html(), trunk.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var pot_prof := PackedVector2Array([Vector2(0.0, -0.05), Vector2(0.34, -0.05), Vector2(0.4, 0.4), Vector2(0.44, 0.44), Vector2(0.44, 0.52), Vector2(0.3, 0.52), Vector2(0.0, 0.52)])
		kit.lathe(pot_prof, 16, Transform3D.IDENTITY, pot, false)
		kit.cylinder(Vector3(0.0, 0.45, 0.0), 0.3, 0.3, 0.06, Color("#4a3122"), Basis.IDENTITY, 14)
		kit.cylinder(Vector3(0.0, 0.5, 0.0), 0.07, 0.06, 0.55, trunk, Basis.IDENTITY, 10)
		if variant % 2 == 0:
			kit.lobed_dome(Vector3(0.0, 0.98, 0.0), 0.66, 0.66, leaf, shadow, 8, 0.08, 0.78, 0.0, 28, 5, 0.12)
		else:
			kit.lobed_dome(Vector3(0.0, 0.92, 0.0), 0.56, 0.50, leaf, shadow, 7, 0.09, 0.72, 0.4, 26, 5, 0.10)
			kit.cylinder(Vector3(0.0, 1.42, 0.0), 0.06, 0.05, 0.3, trunk, Basis.IDENTITY, 8)
			kit.lobed_dome(Vector3(0.0, 1.70, 0.0), 0.40, 0.40, leaf.lightened(0.08), shadow.lightened(0.06), 6, 0.10, 0.72, 1.3, 24, 4, 0.08)
		return kit.commit()
	return _cached(key, build)

## Bench: rounded slats, backrest, thick legs.
static func bench(wood: Color, frame: Color) -> ArrayMesh:
	var key := "bench|%s|%s" % [wood.to_html(), frame.to_html()]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for x in [-0.6, 0.6]:
			kit.rounded_box(Vector3(x, 0.22, 0.0), Vector3(0.14, 0.48, 0.5), 0.05, frame)
			kit.rounded_box(Vector3(x, 0.55, -0.22), Vector3(0.12, 0.62, 0.12), 0.05, frame, Basis(Vector3.RIGHT, -0.18))
		for z in [-0.16, 0.02, 0.2]:
			kit.rounded_box(Vector3(0.0, 0.47, z), Vector3(1.5, 0.08, 0.16), 0.035, wood)
		for y in [0.7, 0.86]:
			kit.rounded_box(Vector3(0.0, y, -0.25 - (y - 0.7) * 0.28), Vector3(1.5, 0.12, 0.07), 0.03, wood, Basis(Vector3.RIGHT, -0.18))
		return kit.commit()
	return _cached(key, build)

## Flower bed border: stone ring + dark soil disc (flowers are a MultiMesh on top).
static func flower_bed(stone: Color, soil: Color, r: float) -> ArrayMesh:
	var key := "bed|%s|%s|%.2f" % [stone.to_html(), soil.to_html(), r]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.torus(Vector3(0.0, 0.1, 0.0), r, 0.16, stone, Basis.IDENTITY, 28)
		kit.cylinder(Vector3(0.0, -0.1, 0.0), r, r, 0.22, soil, Basis.IDENTITY, 28)
		return kit.commit()
	return _cached(key, build)

## Fountain: basin, column, upper bowl, finial. Water discs are separate meshes (water shader).
static func fountain(stone: Color, accent: Color) -> ArrayMesh:
	var key := "fountain|%s|%s" % [stone.to_html(), accent.to_html()]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var basin := PackedVector2Array([Vector2(0.0, -0.15), Vector2(1.9, -0.15), Vector2(2.0, 0.35), Vector2(1.95, 0.55), Vector2(1.7, 0.55), Vector2(1.65, 0.2), Vector2(0.0, 0.2)])
		kit.lathe(basin, 32, Transform3D.IDENTITY, stone, false)
		kit.torus(Vector3(0.0, 0.55, 0.0), 1.82, 0.12, accent, Basis.IDENTITY, 32)
		var column := PackedVector2Array([Vector2(0.0, 0.2), Vector2(0.5, 0.2), Vector2(0.32, 0.5), Vector2(0.26, 1.1), Vector2(0.4, 1.25), Vector2(0.0, 1.25)])
		kit.lathe(column, 18, Transform3D.IDENTITY, stone)
		var bowl := PackedVector2Array([Vector2(0.0, 1.2), Vector2(0.85, 1.25), Vector2(0.95, 1.45), Vector2(0.85, 1.55), Vector2(0.75, 1.42), Vector2(0.0, 1.4)])
		kit.lathe(bowl, 24, Transform3D.IDENTITY, stone, false)
		kit.cylinder(Vector3(0.0, 1.4, 0.0), 0.16, 0.12, 0.45, stone, Basis.IDENTITY, 12)
		kit.sphere(Vector3(0.0, 1.95, 0.0), 0.22, accent, Vector3.ONE, 14)
		return kit.commit()
	return _cached(key, build)

## Flat water disc (for fountain basin / bowl) at height y with radius r.
static func water_disc(r: float, y: float) -> ArrayMesh:
	var key := "wdisc|%.2f|%.2f" % [r, y]
	var build := func() -> ArrayMesh:
		# profile from rim to center -> normal points up
		var kit := PlanetMeshKit.new()
		var prof := PackedVector2Array([Vector2(r, y), Vector2(0.0, y)])
		kit.lathe(prof, 32, Transform3D.IDENTITY, Color(0.4, 0.4, 0.4, 1.0), false)
		return kit.commit()
	return _cached(key, build)

## Bunting: two poles with a sagging string of triangle flags between them (span along X).
static func bunting(pole: Color, colors: PackedColorArray, span: float) -> ArrayMesh:
	var key := "bunting|%s|%s|%.2f" % [pole.to_html(), str(colors), span]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var h := 2.7
		for x in [-span * 0.5, span * 0.5]:
			kit.cylinder(Vector3(x, -0.2, 0.0), 0.08, 0.06, h + 0.2, pole, Basis.IDENTITY, 10)
			kit.sphere(Vector3(x, h + 0.05, 0.0), 0.11, colors[0] if colors.size() > 0 else pole, Vector3.ONE, 10)
		var segs := 12
		var pts: Array[Vector3] = []
		for i in segs + 1:
			var t := float(i) / float(segs)
			var x := lerpf(-span * 0.5, span * 0.5, t)
			var sag := 0.45 * (1.0 - pow(2.0 * t - 1.0, 2.0))
			pts.append(Vector3(x, h - sag, 0.0))
		var string_col := Color("#f4e9d2")
		for i in segs:
			var a := pts[i]
			var b := pts[i + 1]
			var d := b - a
			var basis := Basis.looking_at(d.normalized(), Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
			kit.cylinder(a, 0.018, 0.018, d.length(), string_col, basis, 6)
		var nflags := 7
		for i in nflags:
			var t := (float(i) + 0.5) / float(nflags)
			var x := lerpf(-span * 0.5, span * 0.5, t)
			var sag := 0.45 * (1.0 - pow(2.0 * t - 1.0, 2.0))
			var top := Vector3(x, h - sag, 0.0)
			var c: Color = colors[i % colors.size()] if colors.size() > 0 else Color.WHITE
			var w := 0.17
			kit.triangle(top + Vector3(-w, 0.0, 0.0), top + Vector3(w, 0.0, 0.0), top + Vector3(0.0, -0.3, 0.0), c)
		return kit.commit()
	return _cached(key, build)

# ============================================================================================ collectibles
## Stardust shard — the most-collected object in the game, so it has to read as "a thing you want"
## from the gameplay camera. Cut like a gem rather than a bipyramid: a pavilion with a break in it, a
## thin vertical GIRDLE band that catches a bright edge all the way round, a crown and a small flat
## table. 10 segments x 6 bands, so a facet is never more than ~36 degrees wide and the silhouette
## shows five or six differently-lit planes from any angle. The old version was a 6-segment
## bipyramid: from most angles it presented one flat plane and read as litter.
##
## Vertex colour is WHITE on purpose. crystal.gdshader computes `albedo * COLOR`, so white is the
## identity and the gold comes from the material's `albedo` uniform (#f7b928), which is where a
## collectible's colour belongs — the mesh is shared by every shard and cached by key. What actually
## killed the gold was the flat-normal sign bug in crystal.gdshader; see the note at the top of it.
static func shard() -> ArrayMesh:
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var prof := PackedVector2Array([
			Vector2(0.000, 0.000),   # pavilion tip
			Vector2(0.115, 0.180),   # pavilion break
			Vector2(0.195, 0.290),   # girdle bottom
			Vector2(0.202, 0.336),   # girdle top (thin vertical band = crisp bright edge)
			Vector2(0.115, 0.520),   # crown
			Vector2(0.050, 0.600),   # table edge
			Vector2(0.000, 0.605)])  # table
		kit.lathe(prof, 10, Transform3D.IDENTITY, Color.WHITE, false)
		return kit.commit()
	return _cached("shard", build)

## Crystal chunk: three small prisms.
static func crystal_chunk() -> ArrayMesh:
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for i in 3:
			var az := TAU * float(i) / 3.0
			var h := 0.42 - 0.08 * float(i)
			var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.1, h * 0.65), Vector2(0.0, h)])
			var basis := PlanetMeshKit.tilt_basis(0.25 + 0.1 * float(i), az)
			kit.lathe(prof, 6, Transform3D(basis, Vector3(cos(az) * 0.07, 0.0, sin(az) * 0.07)), Color.WHITE, false)
		return kit.commit()
	return _cached("chunk", build)

## Chalk core (Grig): a drilled plug of step. A squat faceted cylinder with a chamfer top and
## bottom and one recessed band around the waist, so it reads as a cut sample rather than a pebble
## -- flat planes and a panel line, per R2.3. 8 radial segments, flat-shaded.
static func chalk_core() -> ArrayMesh:
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var prof := PackedVector2Array([
			Vector2(0.000, 0.000),   # base
			Vector2(0.086, 0.000),   # base rim
			Vector2(0.104, 0.036),   # bottom chamfer out
			Vector2(0.104, 0.112),   # wall up to the groove
			Vector2(0.088, 0.132),   # groove in  (the drill mark Grig numbers)
			Vector2(0.104, 0.152),   # groove out
			Vector2(0.104, 0.232),   # wall
			Vector2(0.086, 0.268),   # top chamfer in
			Vector2(0.000, 0.268)])  # flat top face
		kit.lathe(prof, 8, Transform3D.IDENTITY, Color.WHITE, false)
		return kit.commit()
	return _cached("chalkcore", build)

## Salt bloom (Fen): a crust flower off a pool rim. Six flat tapered plates fanned out of a low
## centre, all under 0.15 m tall -- a mineral rosette, deliberately NOT a dome. Flat triangles, so
## it stays crisp under the raking 11-degree sun that is Fen's whole identity.
static func salt_bloom() -> ArrayMesh:
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for i in 6:
			var ang := TAU * float(i) / 6.0 + 0.18 * float(i % 2)
			var reach := 0.150 - 0.020 * float(i % 3)
			var lift := 0.090 + 0.032 * float(i % 3)
			var c := Vector3(cos(ang), 0.0, sin(ang))
			var t := Vector3(-sin(ang), 0.0, cos(ang))
			kit.triangle(c * 0.030 + t * 0.032, c * 0.030 - t * 0.032,
				c * reach + Vector3(0.0, lift, 0.0), Color.WHITE)
		# A small flat cap so the rosette has a centre to grow out of instead of a hole.
		kit.cylinder(Vector3(0.0, 0.0, 0.0), 0.052, 0.040, 0.046, Color.WHITE, Basis.IDENTITY, 6)
		return kit.commit()
	return _cached("saltbloom", build)

## Moon flower: pale bloom with a glowing center (surface 1).
static func moon_flower() -> ArrayMesh:
	var build := func() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		var kit := PlanetMeshKit.new()
		var stem := Color("#7fb8c9")
		kit.cylinder(Vector3(0.0, -0.05, 0.0), 0.03, 0.025, 0.32, stem, Basis.IDENTITY, 8)
		kit.sphere(Vector3(0.09, 0.12, 0.0), 0.08, stem, Vector3(1.2, 0.35, 0.7), 8, Basis(Vector3.FORWARD, -0.5))
		var petal := Color("#dfeaff")
		for i in 6:
			var ang := TAU * float(i) / 6.0
			var basis := Basis(Vector3.UP, -ang) * Basis(Vector3.FORWARD, -0.55)
			kit.sphere(Vector3(cos(ang) * 0.11, 0.34, sin(ang) * 0.11), 0.1, petal, Vector3(1.2, 0.4, 0.7), 10, basis)
		kit.commit(mesh)
		var core := PlanetMeshKit.new()
		core.sphere(Vector3(0.0, 0.37, 0.0), 0.07, Color.WHITE, Vector3(1.0, 0.8, 1.0), 12)
		core.commit(mesh)
		return mesh
	return _cached("moonflower", build)

## Gear bit: small brass cog.
static func gear_bit() -> ArrayMesh:
	return gear(0.16, 8, 0.07, Color("#e0aa5a"), Color("#c48a3e"))
