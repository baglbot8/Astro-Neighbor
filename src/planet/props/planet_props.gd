class_name PlanetProps
extends RefCounted
## Scatters biome props, MultiMesh foliage, ambient particles and collectibles over a Planet.
## Every placement goes through Planet.find_free_dir (reserved zones, other props, water, slopes) and
## registers its footprint so nothing overlaps. Props are placed with the surface transform (+Y = up,
## random yaw), sunk a few centimeters so slopes never show a gap.

const DECO_LAYER := 1 << 3   # physics layer 4 "decoration": player & NPCs collide with it

var planet: Planet
var data: PlanetData
var root: Node3D
var coll_root: Node3D
var rng: RandomNumberGenerator
var wr: float = -1.0
var _tile_zone_dirs: PackedVector3Array = PackedVector3Array()
var _tile_zone_radii: PackedFloat32Array = PackedFloat32Array()
var _path_a: PackedVector3Array = PackedVector3Array()
var _path_b: PackedVector3Array = PackedVector3Array()
var _path_width := 1.9
var _label_counts: Dictionary = {}
## Surface-area scale for scatter counts: 1.0 at PlanetData.REFERENCE_RADIUS, (R/16)^2 elsewhere.
## Every count in a .tres and every hard-coded count below is a DENSITY expressed at 16 m, so the
## same world at any radius keeps the same props per square metre. Without this the shrink in
## STYLE_GUIDE R2.11 would have doubled prop density and eaten the decoration placement budget,
## which the survey (showcase/planet_survey.tscn) shows as the "prop" column.
var _ascale: float = 1.0

## Scatter count `n` (authored at the reference radius) at this planet's actual size. `keep_min`
## is the floor for landmark props that must not vanish entirely on a small world.
func _n(n: int, keep_min: int = 0) -> int:
	return maxi(int(round(float(n) * _ascale)), keep_min)

func populate(p: Planet, props_root: Node3D, collectibles_root: Node3D) -> void:
	planet = p
	data = p.data
	root = props_root
	coll_root = collectibles_root
	rng = p.make_rng(1)
	wr = p.water_radius()
	_ascale = p.area_scale()
	_collect_paths()
	match data.biome:
		"violet":
			_violet()
		"chrome":
			_chrome()
		"plaza":
			_plaza()
		"flats":
			_fen()
		"chalk":
			_grig()
		"frost":
			_vela()
		_:
			_meadow()
	_collectibles()

# ============================================================================================ helpers
func _collect_paths() -> void:
	var spawn := data.spawn_dir.normalized()
	# A trodden dirt line is right on soft ground and wrong on cut stone, plating or fresh powder.
	# Fen KEEPS its path (a worn line across a blank salt pan is the strongest "someone lives here"
	# cue the game has); Grig's chalk steps do not, because the tan smear would cut straight across
	# the contours; and Vela's frost does not, because a path is an EDGE and "no edges anywhere" is
	# that world's entire claim — a warm tan arc would also be the only warm thing on a planet whose
	# one warm colour is reserved for the relay lamps.
	# NOTE: the path is drawn in TWO places. This one only feeds _on_paved() for prop avoidance; the
	# ground shader's arcs are set separately in Planet._make_ground_material(), so "chalk" and
	# "frost" have to be excluded there as well or the smear is still painted and props merely stop
	# avoiding it.
	if data.biome == "chrome" or data.biome == "violet" or data.biome == "chalk" or data.biome == "frost":
		return
	for bid in data.buildings:
		var bd := planet.building_dir(bid)
		if bd != Vector3.ZERO:
			_path_a.append(spawn)
			_path_b.append(bd)
	_path_a.append(spawn)
	_path_b.append(data.pad_dir.normalized())
	if data.biome == "plaza":
		_path_width = 2.2
		_tile_zone_dirs.append(spawn)
		_tile_zone_radii.append(Planet.HUB_SPAWN_FLAT_RADIUS - 0.8)
		_tile_zone_dirs.append(data.pad_dir.normalized())
		_tile_zone_radii.append(Planet.PAD_FLAT_RADIUS + 0.2)
		for bid in data.buildings:
			var bd := planet.building_dir(bid)
			if bd != Vector3.ZERO:
				_tile_zone_dirs.append(bd)
				_tile_zone_radii.append(4.8)

## Angular distance (radians) from d to the great-circle segment a -> b (mirrors the shader helper).
static func arc_distance(d: Vector3, a: Vector3, b: Vector3) -> float:
	var n := a.cross(b).normalized()
	var sd := d.dot(n)
	var p := (d - n * sd).normalized()
	var ab := acos(clampf(a.dot(b), -1.0, 1.0))
	var ap := acos(clampf(a.dot(p), -1.0, 1.0))
	var pb := acos(clampf(p.dot(b), -1.0, 1.0))
	if ap + pb <= ab + 0.002:
		return absf(asin(clampf(sd, -1.0, 1.0)))
	return minf(acos(clampf(d.dot(a), -1.0, 1.0)), acos(clampf(d.dot(b), -1.0, 1.0)))

## True if dir is on a path or inside a tile zone (plus margin in meters).
func _on_paved(dir: Vector3, margin: float = 0.3) -> bool:
	for i in _path_a.size():
		if arc_distance(dir, _path_a[i], _path_b[i]) * planet.radius < _path_width * 0.5 + margin:
			return true
	for i in _tile_zone_dirs.size():
		if planet.surface_distance(dir, _tile_zone_dirs[i]) < _tile_zone_radii[i] + margin:
			return true
	return false

## Point on the arc a->b at fraction t.
static func arc_point(a: Vector3, b: Vector3, t: float) -> Vector3:
	return a.slerp(b, t).normalized()

## Side-offset (meters) from a point on arc a->b, perpendicular to the arc.
func _arc_side(a: Vector3, b: Vector3, t: float, side_m: float, along_m: float = 0.0) -> Vector3:
	var p := arc_point(a, b, t)
	var tangent := (b - p * b.dot(p)).normalized()
	var side := p.cross(tangent).normalized()
	return (p + side * (side_m / planet.radius) + tangent * (along_m / planet.radius)).normalized()

func _random_tangent(dir: Vector3) -> Vector3:
	var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	v -= dir * v.dot(dir)
	if v.length_squared() < 0.001:
		return Vector3.FORWARD
	return v.normalized()

## Surface transform at dir facing `forward_hint` (or a random tangent), rotated by yaw, sunk `sink` m.
func _surface_xf(dir: Vector3, yaw: float, sink: float, align_ground: bool, forward_hint: Vector3 = Vector3.ZERO) -> Transform3D:
	var fwd := forward_hint if forward_hint != Vector3.ZERO else _random_tangent(dir)
	var xf := planet.surface_transform(dir, fwd)
	if align_ground:
		var n := planet.ground_normal(dir)
		var f := -xf.basis.z
		f = (f - n * f.dot(n)).normalized()
		xf.basis = Basis.looking_at(f, n)
	xf.basis = xf.basis * Basis(Vector3.UP, yaw)
	xf.origin -= xf.basis.y * sink
	return xf

func _mesh_instance(mesh: ArrayMesh, mats: Array, scale: float, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	if mats.size() == 1:
		mi.material_override = mats[0]
	else:
		for i in mini(mats.size(), mesh.get_surface_count()):
			mi.set_surface_override_material(i, mats[i])
	mi.scale = Vector3.ONE * scale
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Blocking prop: StaticBody3D on the decoration layer with a cylinder collider.
func _spawn_blocking(mesh: ArrayMesh, mats: Array, dir: Vector3, scale: float, footprint: float, col_radius: float, col_height: float, sink: float = 0.04, align_ground: bool = false, yaw: float = NAN, forward_hint: Vector3 = Vector3.ZERO, body: StaticBody3D = null, label: String = "") -> StaticBody3D:
	var b := body if body != null else StaticBody3D.new()
	if label != "":
		b.name = label + str(_label_counts.get(label, 0))
		_label_counts[label] = int(_label_counts.get(label, 0)) + 1
	b.collision_layer = DECO_LAYER
	b.collision_mask = 0
	var mi := _mesh_instance(mesh, mats, scale)
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = col_radius * scale
	shape.height = col_height * scale
	cs.shape = shape
	cs.position = Vector3(0.0, col_height * 0.5 * scale - 0.05, 0.0)
	b.add_child(cs)
	var y := yaw if not is_nan(yaw) else rng.randf_range(0.0, TAU)
	b.transform = _surface_xf(dir, y, sink * scale, align_ground, forward_hint)
	root.add_child(b)
	planet.register_prop(dir, footprint * scale)
	return b

## Non-blocking prop (mushrooms, tufts clusters, benches' flowers...).
func _spawn_simple(mesh: ArrayMesh, mats: Array, dir: Vector3, scale: float, footprint: float, sink: float = 0.03, align_ground: bool = false, yaw: float = NAN, shadow: bool = true, label: String = "") -> Node3D:
	var n := Node3D.new()
	if label != "":
		n.name = label + str(_label_counts.get(label, 0))
		_label_counts[label] = int(_label_counts.get(label, 0)) + 1
	var mi := _mesh_instance(mesh, mats, scale, shadow)
	n.add_child(mi)
	var y := yaw if not is_nan(yaw) else rng.randf_range(0.0, TAU)
	n.transform = _surface_xf(dir, y, sink * scale, align_ground)
	root.add_child(n)
	if footprint > 0.0:
		planet.register_prop(dir, footprint * scale)
	return n

## Non-blocking prop that must FACE something (a gate across a path, a shelf across a step edge).
## _spawn_simple only takes a yaw, and that yaw is applied to a RANDOM tangent basis, so there is no
## way to aim it; this is the same body with a forward hint instead.
func _spawn_oriented(mesh: ArrayMesh, mats: Array, dir: Vector3, scale: float, footprint: float, sink: float, forward_hint: Vector3, shadow: bool = true, label: String = "") -> Node3D:
	var n := Node3D.new()
	if label != "":
		n.name = label + str(_label_counts.get(label, 0))
		_label_counts[label] = int(_label_counts.get(label, 0)) + 1
	n.add_child(_mesh_instance(mesh, mats, scale, shadow))
	n.transform = _surface_xf(dir, 0.0, sink * scale, false, forward_hint)
	root.add_child(n)
	if footprint > 0.0:
		planet.register_prop(dir, footprint * scale)
	return n

func _omni(parent: Node3D, pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	l.light_specular = 0.3
	parent.add_child(l)

## MOBILE / BROWSER PROP BUDGET. A phone draws every one of these instances and pays for the
## planet-build that creates them, and the player reported the game running hot. Small
## scatter (grass tufts, flower patches) is the one thing here that can be thinned without
## changing the composition of a planet — the trees, rocks, houses and landmarks that make
## a planet recognisable are NOT touched.
func _scatter_scale() -> float:
	return 0.35 if (Platform.is_compatibility_renderer() or Platform.is_mobile()) else 1.0


## Tiny scatter does not need to cast a shadow on a phone: each instance is drawn again into
## the shadow map, and a 12 cm flower contributes a shadow a few pixels across.
func _scatter_shadow(want: bool) -> bool:
	return want and not (Platform.is_compatibility_renderer() or Platform.is_mobile())


## One MultiMesh for many small foliage instances (flowers/tufts) tinted via custom data.
func _multimesh(mesh: ArrayMesh, xfs: Array[Transform3D], tints: PackedColorArray, material: Material, shadow: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	# WEB/COMPATIBILITY FIX. Under the Compatibility (WebGL2) renderer a MultiMesh always reads an
	# instance-colour attribute and multiplies it into COLOR. With use_colors OFF that attribute is
	# never supplied, so COLOR arrives as (0,0,0,0): the mesh's baked vertex colour is wiped and every
	# grass tuft and flower rendered as a black silhouette. Forward+ ignored the missing attribute and
	# looked fine, which is why this only ever showed up in the browser build.
	# Enabling colours and writing pure white makes the multiply a no-op, so Forward+ is unchanged and
	# Compatibility gets its vertex colours back. The per-instance TINT stays in custom data.
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, Color.WHITE)
		mm.set_instance_custom_data(i, tints[i].srgb_to_linear())
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	return mmi

func _vary(c: Color, amount: float) -> Color:
	var k := 1.0 + rng.randf_range(-amount, amount)
	return Color(clampf(c.r * k, 0.0, 1.0), clampf(c.g * k, 0.0, 1.0), clampf(c.b * k, 0.0, 1.0), 1.0)

## Deterministic ring of spots 5.5-7 m from the spawn (outside the reserved disc) so the first
## thing the player sees is never empty. Returns free dirs (may be fewer than requested).
func _hero_dirs(count: int, clearance: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var spawn := data.spawn_dir.normalized()
	var xf := planet.surface_transform(spawn, Vector3.FORWARD)
	var reserved_r := Planet.HUB_SPAWN_FLAT_RADIUS if data.biome == "plaza" else Planet.SPAWN_FLAT_RADIUS
	for i in count:
		var placed := false
		for attempt in 6:
			var ang := TAU * (float(i) + 0.5) / float(count) + rng.randf_range(-0.35, 0.35)
			var dist := reserved_r + 0.6 + clearance + rng.randf_range(0.4, 2.2)
			var off := (xf.basis.x * cos(ang) + xf.basis.z * sin(ang)) * (dist / planet.radius)
			var d := (spawn + off).normalized()
			if planet._is_free(d, clearance) and not (wr > 0.0 and planet.height_at(d) < wr + 0.2):
				out.append(d)
				placed = true
				break
		if not placed:
			continue
	return out

## True when a cliff face (a terrace riser, a crater wall, a plateau bank) is within `reach_m`.
## Grig's shelves and lamps want the step EDGE specifically, and that is the one thing a uniform
## find_free_dir will never hand you — it looks for the flattest ground it can find.
func _near_riser(dir: Vector3, reach_m: float = 1.0) -> bool:
	var xf := planet.surface_transform(dir)
	for k in 4:
		var ang := TAU * float(k) / 4.0
		var t := (xf.basis.x * cos(ang) + xf.basis.z * sin(ang)) * (reach_m / planet.radius)
		if planet.bank_weight((dir + t).normalized()) > 0.35:
			return true
	return false

## Tangential DOWNHILL direction at dir (zero on level ground). A prop that spans an elevation
## change has to know which way the ground falls; nothing else in the file needed this.
func _downhill(dir: Vector3) -> Vector3:
	var d := dir.normalized()
	var n := planet.ground_normal(d, 0.5)
	var t := n - d * n.dot(d)
	return t.normalized() if t.length_squared() > 0.0004 else Vector3.ZERO

# ============================================================================================ meadow
func _meadow() -> void:
	var trees := _n(data.tree_count, 4)
	var rocks := _n(data.rock_count, 3)
	_puff_trees(trees)
	_bushes(int(trees / 2) + 2)
	_mushrooms(int(rocks / 2) + 2)
	_pebbles(rocks)
	_flower_patches(_n(data.flower_patch_count, 3))
	_grass_tufts(data.ground_color_a.darkened(0.14), 1.0)

func _puff_trees(count: int) -> void:
	var trunk := data.trunk_color
	var leaf := data.foliage_color_a
	var leaf_light := data.foliage_color_b
	var shadow := data.foliage_shadow_color
	var blossom: Color = data.flower_colors[0] if data.flower_colors.size() > 0 else Color("#ff9ccf")
	# R2.9: plump canopy softness + a hint of sun through the leaves, and directional grain on the
	# trunk (marked with WOOD_ALPHA in the mesh). Faded out by 16 m so the fine grain never aliases.
	var mat := PlanetPropMeshes.foliage_material(0.035, 3.2, false, 1.1, Color.BLACK, 0.0, 0.08, 0.04,
		{"strength": 1.5, "near": 4.5, "far": 18.0, "sss": 0.20})
	var hero := _hero_dirs(5, 1.4)
	for i in count:
		var s := rng.randf_range(0.88, 1.18)
		var dir: Vector3 = hero[i] if i < hero.size() else planet.find_free_dir(rng, 1.4 * s, 120)
		if dir == Vector3.ZERO:
			continue
		var mesh := PlanetPropMeshes.puff_tree(trunk, leaf, leaf_light, shadow, blossom, i % 6)
		var tree := PlanetPuffTree.new()
		tree.name = "PuffTree%d" % i
		_spawn_blocking(mesh, [mat], dir, s, 1.2, 0.36, 1.7, 0.05, false, NAN, Vector3.ZERO, tree)
		tree.setup(tree.get_node("Mesh"), leaf, 1.9 * s)

func _bushes(count: int) -> void:
	var leaf := data.foliage_color_a.lightened(0.04)
	var shadow := data.foliage_shadow_color
	var berry: Color = data.flower_colors[1 % data.flower_colors.size()] if data.flower_colors.size() > 0 else Color("#ff6b9d")
	var mat := PlanetPropMeshes.foliage_material(0.03, 0.9, false, 1.4, Color.BLACK, 0.0, 0.08, 0.04,
		{"strength": 1.5, "near": 3.0, "far": 13.0, "sss": 0.22})
	for i in count:
		var s := rng.randf_range(0.8, 1.2)
		var dir := planet.find_free_dir(rng, 0.7 * s)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.bush(leaf, shadow, berry, i), [mat], dir, s, 0.7, 0.5, 0.8, 0.08, false, NAN, Vector3.ZERO, null, "Bush")

func _mushrooms(count: int) -> void:
	var caps: Array[Color] = [Color("#d9584d"), Color("#dd9738"), Color("#ddd6c6")]
	var mat := PlanetPropMeshes.prop_material()
	for i in count:
		var s := rng.randf_range(0.7, 1.1)
		var dir := planet.find_free_dir(rng, 0.5)
		if dir == Vector3.ZERO:
			continue
		var cap: Color = caps[i % caps.size()]
		_spawn_simple(PlanetPropMeshes.mushroom(cap, Color("#e2d5b8"), i), [mat], dir, s, 0.45, 0.05, false, NAN, true, "Mushroom")

func _pebbles(count: int) -> void:
	var mat := PlanetPropMeshes.rock_material()
	for i in count:
		var s := rng.randf_range(0.7, 1.35)
		var dir := planet.find_free_dir(rng, 0.7 * s, 48, true)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.pebble_rock(data.rock_color, i), [mat], dir, s, 0.65, 0.45, 0.5, 0.12, true, NAN, Vector3.ZERO, null, "Rock")

func _flower_patches(count: int, stem: Color = Color("#3d7f38"), center: Color = Color("#e0b34f")) -> void:
	if data.flower_colors.is_empty():
		return
	var xfs: Array[Transform3D] = []
	var tints := PackedColorArray()
	var mesh := PlanetPropMeshes.flower(stem, center, 0)
	for i in count:
		var cdir := planet.find_free_dir(rng, 1.1)
		if cdir == Vector3.ZERO:
			continue
		planet.register_prop(cdir, 1.0)
		var col_a: Color = data.flower_colors[rng.randi_range(0, data.flower_colors.size() - 1)]
		var col_b: Color = data.flower_colors[rng.randi_range(0, data.flower_colors.size() - 1)]
		var n := rng.randi_range(9, 15)
		var xf0 := planet.surface_transform(cdir)
		for k in n:
			var ang := rng.randf_range(0.0, TAU)
			var rad := sqrt(rng.randf()) * 1.05
			var off := (xf0.basis.x * cos(ang) + xf0.basis.z * sin(ang)) * (rad / planet.radius)
			var fdir := (cdir + off).normalized()
			if wr > 0.0 and planet.height_at(fdir) < wr + 0.25:
				continue
			if _on_paved(fdir, 0.1):
				continue
			var s := rng.randf_range(0.85, 1.2)
			var xf := _surface_xf(fdir, rng.randf_range(0.0, TAU), 0.02, false)
			xf.basis = xf.basis.scaled(Vector3.ONE * s)
			xfs.append(xf)
			tints.append(_vary(col_a if rng.randf() < 0.6 else col_b, 0.06))
	if xfs.is_empty():
		return
	_multimesh(mesh, xfs, tints, PlanetPropMeshes.foliage_material(0.02, 0.35, true, 2.0), _scatter_shadow(true))

## Thousands of tiny swaying tufts on grass only (not sand, water, paths, tiles, or inside props).
func _grass_tufts(color: Color, density_m2: float) -> void:
	var area := 4.0 * PI * planet.radius * planet.radius
	# 6000 tufts per planet is a desktop number. See _scatter_scale().
	var target := int(mini(int(area / density_m2), 6000) * _scatter_scale())
	var xfs0: Array[Transform3D] = []
	var xfs1: Array[Transform3D] = []
	var tints0 := PackedColorArray()
	var tints1 := PackedColorArray()
	var light := color.lightened(0.08)
	# Just above the sand band (which ends at water_level + 0.24): the old +0.62 kept tufts off more
	# than half the planet, so the meadow lost most of its fine dark speckle.
	var sand_limit := wr + 0.30 if wr > 0.0 else -INF
	var tries := 0
	while xfs0.size() + xfs1.size() < target and tries < target * 8:
		tries += 1
		var v := Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if v.length_squared() < 0.001:
			continue
		v = v.normalized()
		if planet.height_at(v) < sand_limit:
			continue
		if _on_paved(v, 0.15):
			continue
		if planet.nearest_prop_distance(v) < 0.05:
			continue
		# Grass never grows on the bare-earth cliff face of a plateau bank or crater wall.
		if planet.bank_weight(v) > 0.34:
			continue
		var xf := _surface_xf(v, rng.randf_range(0.0, TAU), 0.02, false)
		var s := rng.randf_range(0.7, 1.15)
		xf.basis = xf.basis.scaled(Vector3(s, s * rng.randf_range(0.85, 1.2), s))
		var tint := _vary(color if rng.randf() < 0.7 else light, 0.07)
		if tries % 2 == 0:
			xfs0.append(xf); tints0.append(tint)
		else:
			xfs1.append(xf); tints1.append(tint)
	var mat := PlanetPropMeshes.foliage_material(0.02, 0.2, true, 2.4, Color.BLACK, 0.0, 0.0, 0.0)
	if not xfs0.is_empty():
		_multimesh(PlanetPropMeshes.grass_tuft(0), xfs0, tints0, mat, false)
	if not xfs1.is_empty():
		_multimesh(PlanetPropMeshes.grass_tuft(1), xfs1, tints1, mat, false)

# ============================================================================================ violet
func _violet() -> void:
	var cap := data.foliage_color_a
	var stem := data.foliage_color_b
	var body_mat := PlanetPropMeshes.foliage_material(0.02, 3.0, false, 0.9, Color.BLACK, 0.0, 0.09, 0.04,
		{"strength": 1.4, "near": 4.5, "far": 18.0, "sss": 0.18})
	var spot_mat := PlanetPropMeshes.crystal_material(Color("#7fd8c8"), Color("#5fd8b4"), 0.7, false, 0.35)
	var hero := _hero_dirs(5, 1.6)
	var trees := _n(data.tree_count, 4)
	var rocks := _n(data.rock_count, 3)
	for i in trees:
		var s := rng.randf_range(0.85, 1.2)
		var dir: Vector3 = hero[i] if i < hero.size() else planet.find_free_dir(rng, 1.6 * s, 120)
		if dir == Vector3.ZERO:
			continue
		var body := _spawn_blocking(PlanetPropMeshes.mushroom_tree(cap, stem, data.foliage_shadow_color, i), [body_mat], dir, s, 1.4, 0.45, 2.0, 0.06, false, NAN, Vector3.ZERO, null, "MushroomTree")
		var spots := _mesh_instance(PlanetPropMeshes.mushroom_tree_spots(i), [spot_mat], s)
		spots.name = "Spots"
		body.add_child(spots)
	# Violet boulders: Zorp was the emptiest planet in the game, and a rock is the cheapest thing that
	# puts a real occluder and a cast shadow on open ground.
	var rock_mat := PlanetPropMeshes.rock_material()
	for i in int(rocks / 2) + 3:
		var rs := rng.randf_range(0.8, 1.4)
		var rdir := planet.find_free_dir(rng, 0.75 * rs, 48, true)
		if rdir != Vector3.ZERO:
			_spawn_blocking(PlanetPropMeshes.pebble_rock(data.rock_color, i), [rock_mat], rdir, rs, 0.7, 0.45, 0.5, 0.12, true, NAN, Vector3.ZERO, null, "Rock")
	# Low violet shrubs between the mushroom trees.
	var shrub_mat := PlanetPropMeshes.foliage_material(0.03, 0.9, false, 1.3, Color.BLACK, 0.0, 0.08, 0.03,
		{"strength": 1.5, "near": 3.0, "far": 13.0, "sss": 0.22})
	for i in int(trees / 2) + 2:
		var bs := rng.randf_range(0.8, 1.2)
		var bdir := planet.find_free_dir(rng, 0.7 * bs)
		if bdir != Vector3.ZERO:
			_spawn_blocking(PlanetPropMeshes.bush(Color("#9a7ab8"), Color("#5d4677"), Color("#7fd8c8"), i), [shrub_mat], bdir, bs, 0.7, 0.5, 0.8, 0.08, false, NAN, Vector3.ZERO, null, "Shrub")
	# crystal clusters
	var cyan := PlanetPropMeshes.crystal_material(Color("#2b87b0"), Color("#42afd0"), 0.45, true, 0.12)
	var pink := PlanetPropMeshes.crystal_material(Color("#ad3e8f"), Color("#d05cab"), 0.45, true, 0.12)
	for i in rocks:
		var s := rng.randf_range(0.8, 1.3)
		var dir := planet.find_free_dir(rng, 0.8 * s, 48, true)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.crystal_cluster(i), [cyan, pink], dir, s, 0.75, 0.5, 0.9, 0.1, true, NAN, Vector3.ZERO, null, "Crystal")
	# tentacle plants
	var tent_mat := PlanetPropMeshes.foliage_material(0.14, 1.5, false, 1.0, Color.BLACK, 0.0, 0.09, 0.04,
		{"strength": 1.3, "near": 3.0, "far": 13.0, "sss": 0.24})
	var bulb_mat := PlanetPropMeshes.crystal_material(Color("#d692c4"), Color("#d066ae"), 0.8, false, 0.35)
	for i in _n(data.flower_patch_count, 3) + 2:
		var s := rng.randf_range(0.8, 1.25)
		var dir := planet.find_free_dir(rng, 0.7 * s)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.tentacle_plant(Color("#9a56c4"), Color("#c46fac"), i), [tent_mat, bulb_mat], dir, s, 0.7, 0.3, 0.9, 0.05, false, NAN, Vector3.ZERO, null, "Tentacle")
	# Zorp's tufts are thin blades: most of their area is the toon shade side, so a tint darker than
	# the ground rendered them as several thousand near-black specks and they, not the ground, were
	# what pinned the planet's luma p05. Tinted at the ground tone they read as texture, not dirt.
	_grass_tufts(data.ground_color_a.lightened(0.04), 1.4)
	_spores()

func _spores() -> void:
	var p := GPUParticles3D.new()
	p.name = "Spores"
	p.amount = 110
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.local_coords = true
	p.visibility_aabb = AABB(Vector3.ONE * -(planet.radius + 4.0), Vector3.ONE * (planet.radius + 4.0) * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	pm.emission_sphere_radius = planet.radius + 1.3
	pm.direction = Vector3(0.0, 0.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.08
	pm.initial_velocity_max = 0.25
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 4.0
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var g := Gradient.new()
	var c := Color("#9fffe8")
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.2, c)
	g.add_point(0.5, Color("#ffb3f0"))
	g.set_color(g.get_point_count() - 1, Color(c.r, c.g, c.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.11)
	q.material = PlanetPropMeshes.sparkle_material(Color(1.0, 1.0, 1.0, 0.7))
	p.draw_pass_1 = q
	root.add_child(p)

# ============================================================================================ chrome
func _chrome() -> void:
	var metal := PlanetPropMeshes.metal_material()
	var steel := Color("#a7a89e")
	var dark := Color("#6f6d63")
	var brass := Color("#b8975c")
	var teal := Color("#68a49e")
	var orange := Color("#dd8434")
	# gear trees
	var hero := _hero_dirs(4, 1.1)
	for i in _n(data.tree_count, 4):
		var s := rng.randf_range(0.9, 1.2)
		var dir: Vector3 = hero[i] if i < hero.size() else planet.find_free_dir(rng, 1.1 * s, 120)
		if dir == Vector3.ZERO:
			continue
		var h := 2.4 + 0.3 * float(i % 3)
		var tree := PlanetGearTree.new()
		tree.name = "GearTree%d" % i
		_spawn_blocking(PlanetPropMeshes.gear_pole(steel, dark, h), [metal], dir, s, 0.9, 0.3, h, 0.05, false, NAN, Vector3.ZERO, tree)
		var gear_defs := [[0.55, 10, 0.16, brass, dark], [0.42, 8, 0.14, teal, dark], [0.32, 7, 0.12, orange, dark]]
		var ys := [h * 0.4, h * 0.66, h * 0.88]
		for k in 3:
			var gd: Array = gear_defs[(k + i) % 3]
			var gm := PlanetPropMeshes.gear(gd[0], gd[1], gd[2], gd[3], gd[4])
			var gi := _mesh_instance(gm, [metal], s)
			gi.name = "Gear%d" % k
			gi.position = Vector3(0.0, ys[k] * s, 0.0)
			gi.rotation.y = rng.randf_range(0.0, TAU)
			tree.add_child(gi)
			tree.add_gear(gi, (0.9 + 0.35 * float(k)) * (1.0 if k % 2 == 0 else -1.0))
	# antenna towers
	var blink := PlanetPropMeshes.pulse_material(Color("#e04e34"), 1.5, 2.6, 1, 0.05, Color("#d96a4e"))
	for i in _n(4, 2):
		var s := rng.randf_range(0.9, 1.1)
		var dir := planet.find_free_dir(rng, 1.0 * s)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.antenna_tower(steel, orange, i), [metal, blink], dir, s, 0.9, 0.6, 1.2, 0.08, false, NAN, Vector3.ZERO, null, "Antenna")
	# steam pipes
	for i in _n(data.flower_patch_count, 3):
		var s := rng.randf_range(0.9, 1.15)
		var dir := planet.find_free_dir(rng, 0.6 * s)
		if dir == Vector3.ZERO:
			continue
		var pipe := _spawn_blocking(PlanetPropMeshes.steam_pipe(Color("#8b8b83"), orange, i), [metal], dir, s, 0.6, 0.25, 1.2, 0.05, false, NAN, Vector3.ZERO, null, "Pipe")
		var h := (0.9 + 0.3 * float(i % 3)) * s
		_steam(pipe, Vector3(-0.62 * s, h, 0.0))
	# nut & bolt rocks
	for i in _n(data.rock_count, 3):
		var s := rng.randf_range(0.8, 1.2)
		var dir := planet.find_free_dir(rng, 0.7 * s, 48, true)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.nut_rock(steel, brass, i), [metal], dir, s, 0.7, 0.5, 0.35, 0.06, true, NAN, Vector3.ZERO, null, "Nut")
	# orange lamp posts
	var panel := PlanetPropMeshes.pulse_material(Color("#e07a33"), 1.1, 1.2, 0, 0.75, Color("#d99a63"))
	for i in _n(6, 3):
		var dir := planet.find_free_dir(rng, 0.5)
		if dir == Vector3.ZERO:
			continue
		var lamp := _spawn_blocking(PlanetPropMeshes.lamp_post(Color("#8c8a80"), Color("#7a7768"), 2.3, false), [metal, panel], dir, 1.0, 0.45, 0.16, 2.3, 0.05, false, NAN, Vector3.ZERO, null, "Lamp")
		_omni(lamp, Vector3(0.0, 2.35, 0.0), Color("#e08a4d"), 1.1, 5.0)
	# --- machinery -------------------------------------------------------------------------------
	# Bolt was a deck with a handful of poles on it, which is why it read as a golf ball. These are
	# the things that give the yard mass: boxy crates, fin radiators, vent stacks, and gantries whose
	# beams lay a long shadow bar across the plating.
	# LIGHTENED. MEASURED on the documented Bolt ground crop: the crates' shaded sides were rendering
	# #15182a-#222134, i.e. luma 0.08-0.11, and were 7.7% of the crop below luma 0.15 all on their own
	# — the yard's landmark props were reading as holes cut in the deck, not as boxes. The shaded side
	# of a toon prop lands far below its albedo, so a mid blue-grey is already a near-black in shade.
	var crate_body := Color("#9dabbd")
	var crate_trim := Color("#7d8794")
	var fin := Color("#a3b1c1")
	# Gantries first: they need the most room, and they are the yard's landmark silhouette.
	var gantry_hero := _hero_dirs(2, 2.4)
	for i in _n(3, 2):
		var s := rng.randf_range(0.95, 1.2)
		var dir: Vector3 = gantry_hero[i] if i < gantry_hero.size() else planet.find_free_dir(rng, 2.4 * s, 90)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.gantry(steel.darkened(0.05), orange, 2.9, i), [metal], dir, s, 1.9, 0.35, 2.7, 0.06, false, NAN, Vector3.ZERO, null, "Gantry")
	for i in _n(7, 3):
		var s := rng.randf_range(0.9, 1.15)
		var dir := planet.find_free_dir(rng, 0.9 * s, 80)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.supply_crate(crate_body, crate_trim, i), [metal], dir, s, 0.85, 0.6, 1.0, 0.05, false, NAN, Vector3.ZERO, null, "Crate")
	for i in _n(5, 2):
		var s := rng.randf_range(0.9, 1.15)
		var dir := planet.find_free_dir(rng, 1.0 * s, 80)
		if dir == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.radiator(steel, fin, i), [metal], dir, s, 1.0, 0.85, 1.3, 0.05, false, NAN, Vector3.ZERO, null, "Radiator")
	for i in _n(5, 2):
		var s := rng.randf_range(0.9, 1.2)
		var dir := planet.find_free_dir(rng, 0.7 * s, 80)
		if dir == Vector3.ZERO:
			continue
		var vent := _spawn_blocking(PlanetPropMeshes.vent_stack(steel.darkened(0.04), orange, i), [metal], dir, s, 0.7, 0.5, 1.7, 0.05, false, NAN, Vector3.ZERO, null, "Vent")
		if i % 2 == 0:
			_steam(vent, Vector3(0.0, (1.55 + 0.30 * float(i % 3)) * s, 0.0))

func _steam(parent: Node3D, pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.name = "Steam"
	p.amount = 8
	p.lifetime = 2.2
	p.local_coords = true
	p.position = pos
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(-1.0, 0.4, 0.0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0.0, 0.9, 0.0)
	pm.damping_min = 0.3
	pm.damping_max = 0.5
	pm.scale_min = 0.4
	pm.scale_max = 0.7
	var sc := CurveTexture.new()
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 1.6))
	sc.curve = curve
	pm.scale_curve = sc
	var g := Gradient.new()
	g.set_color(0, Color(0.95, 0.96, 1.0, 0.0))
	g.add_point(0.15, Color(0.95, 0.96, 1.0, 0.4))
	g.set_color(g.get_point_count() - 1, Color(0.95, 0.96, 1.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.55, 0.55)
	var qm := PlanetPropMeshes.puff_material(Color.WHITE).duplicate() as StandardMaterial3D
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.albedo_texture = PlanetPropMeshes.soft_dot_texture()
	q.material = qm
	p.draw_pass_1 = q
	parent.add_child(p)

# ============================================================================================ plaza
func _plaza() -> void:
	var spawn := data.spawn_dir.normalized()
	var town := planet.building_dir("town_hall")
	if town == Vector3.ZERO:
		town = data.pad_dir.normalized()
	# R2.6: the plaza's loudest swatches measured S 0.65-0.79 in the render (the bench read as a
	# traffic cone). Same hues, pastel chroma — warm painted wood and brass, not poster paint.
	var stone := Color("#b8a37c")
	var accent := Color("#c49b6c")
	var wood := Color("#b8977a")
	var frame := Color("#ac9a72")
	var prop_mat := PlanetPropMeshes.prop_material()

	# Fountain in the central plaza, 4 m toward the town hall so the spawn point stays clear.
	var fdir := planet.step_dir(spawn, town, 4.0)
	var fountain := _spawn_blocking(PlanetPropMeshes.fountain(stone, accent), [prop_mat], fdir, 1.0, 2.2, 2.0, 0.6, 0.02, false, 0.0, (spawn - fdir), null, "Fountain")
	_fountain_water(fountain)

	# Benches + flower beds ring the fountain.
	var bench_mesh := PlanetPropMeshes.bench(wood, frame)
	# Warm dark earth in the beds. R2.6: #8d6a4c (S 0.46) came out of the tonemapper as a saturated
	# chocolate slab — the single loudest thing on the plaza. Same hue, less chroma: still clearly
	# soil, no longer a bar of confectionery. It is still one of the plaza's genuine dark tones.
	var bed_mesh := PlanetPropMeshes.flower_bed(stone.darkened(0.12), Color("#907e6f"), 1.0)
	var flower_xfs: Array[Transform3D] = []
	var flower_tints := PackedColorArray()
	var fxf := planet.surface_transform(fdir, spawn - fdir)
	for k in 8:
		var ang := TAU * float(k) / 8.0 + PI / 8.0
		var off := (fxf.basis.x * cos(ang) + fxf.basis.z * sin(ang))
		var d := (fdir + off * (4.6 / planet.radius)).normalized()
		if k % 2 == 0:
			_spawn_blocking(bench_mesh, [prop_mat], d, 1.0, 0.9, 0.7, 0.9, 0.03, false, 0.0, (fdir - d), null, "Bench")
		else:
			_spawn_simple(bed_mesh, [prop_mat], d, 1.0, 1.1, 0.06, false, NAN, true, "FlowerBed")
			_fill_flowers(d, 0.78, 10, flower_xfs, flower_tints)

	# Lamp posts along every path (one each side at 45% and 75%).
	var globe := PlanetPropMeshes.pulse_material(Color("#f2c473"), 0.7, 1.0, 2, 1.0, Color("#e8cea0"))
	var lamp_mesh := PlanetPropMeshes.lamp_post(Color("#b2a07c"), Color("#8c7444"), 2.6, true)
	for i in _path_a.size():
		for t in [0.45, 0.75]:
			for side in [-1.0, 1.0]:
				var d := _arc_side(_path_a[i], _path_b[i], t, side * 1.7)
				if planet.reserved_zone_at(d) != "" and planet.surface_distance(d, spawn) < Planet.HUB_SPAWN_FLAT_RADIUS:
					continue
				var lamp := _spawn_blocking(lamp_mesh, [prop_mat, globe], d, 1.0, 0.4, 0.16, 2.6, 0.05, false, 0.0, Vector3.ZERO, null, "Lamp")
				if t == 0.45:
					_omni(lamp, Vector3(0.0, 2.9, 0.0), Color("#e8c491"), 0.9, 6.0)

	# Topiaries flank each building's front (toward the spawn) and bunting near the event space.
	var top_leaf := data.foliage_color_a
	var top_shade := data.foliage_shadow_color
	# Terracotta pots, pulled back from #bd775a (S 0.52) to a matte pastel terracotta. R2.6.
	var top_mesh0 := PlanetPropMeshes.topiary(Color("#b98a76"), top_leaf, top_shade, Color("#8e6f57"), 0)
	var top_mesh1 := PlanetPropMeshes.topiary(Color("#b98a76"), top_leaf, top_shade, Color("#8e6f57"), 1)
	var bunting_mesh := PlanetPropMeshes.bunting(Color("#b2a07c"), PackedColorArray([Color("#e06a4c"), Color("#e0b02c"), Color("#4257d6"), Color("#5fb5ad")]), 3.6)
	var bi := 0
	for bid in data.buildings:
		var bd := planet.building_dir(bid)
		if bd == Vector3.ZERO:
			continue
		for side in [-1.0, 1.0]:
			var d := _arc_side(bd, spawn, 5.6 / planet.surface_distance(bd, spawn), side * 3.4)
			_spawn_blocking(top_mesh0 if bi % 2 == 0 else top_mesh1, [prop_mat], d, 1.0, 0.55, 0.4, 1.6, 0.03, false, 0.0, (spawn - d), null, "Topiary")
		if bid == "event_space":
			for side in [-1.0, 1.0]:
				var d := _arc_side(bd, spawn, 6.4 / planet.surface_distance(bd, spawn), side * 5.2)
				_spawn_blocking(bunting_mesh, [prop_mat], d, 1.0, 1.9, 0.1, 2.7, 0.05, false, 0.0, (spawn - d), null, "Bunting")
		bi += 1
	# bunting across the plaza entrance from the pad path
	var pd := _arc_side(spawn, data.pad_dir.normalized(), 0.32, 0.0)
	_spawn_blocking(bunting_mesh, [prop_mat], pd, 1.0, 1.9, 0.1, 2.7, 0.05, false, 0.0, (data.pad_dir.normalized() - pd).normalized(), null, "Bunting")

	if not flower_xfs.is_empty():
		_multimesh(PlanetPropMeshes.flower(Color("#3d7f38"), Color("#e0b34f"), 0), flower_xfs, flower_tints, PlanetPropMeshes.foliage_material(0.02, 0.35, true, 2.0), _scatter_shadow(true))

	# Lawn life outside the paved areas.
	var trees := _n(data.tree_count, 4)
	_puff_trees(trees)
	_bushes(int(trees / 2) + 2)
	_pebbles(int(_n(data.rock_count, 3) / 2))
	_flower_patches(_n(data.flower_patch_count, 3))
	_grass_tufts(data.ground_color_a.darkened(0.14), 1.2)

func _fill_flowers(center: Vector3, r: float, n: int, xfs: Array[Transform3D], tints: PackedColorArray) -> void:
	var xf0 := planet.surface_transform(center)
	var cols := data.flower_colors if not data.flower_colors.is_empty() else PackedColorArray([Color("#ff6b9d"), Color("#ffd166"), Color("#ffffff")])
	for k in n:
		var ang := rng.randf_range(0.0, TAU)
		var rad := sqrt(rng.randf()) * r
		var off := (xf0.basis.x * cos(ang) + xf0.basis.z * sin(ang)) * (rad / planet.radius)
		var fdir := (center + off).normalized()
		var xf := _surface_xf(fdir, rng.randf_range(0.0, TAU), -0.1, false)
		xf.basis = xf.basis.scaled(Vector3.ONE * rng.randf_range(0.9, 1.15))
		xfs.append(xf)
		tints.append(_vary(cols[k % cols.size()], 0.05))

func _fountain_water(fountain: Node3D) -> void:
	var wm := ShaderMaterial.new()
	wm.shader = Planet.WATER_SHADER
	wm.set_shader_parameter("shallow_color", Color("#6fd6ff"))
	wm.set_shader_parameter("deep_color", Color("#3aa8f0"))
	wm.set_shader_parameter("alpha_shallow", 0.8)
	wm.set_shader_parameter("alpha_deep", 0.9)
	wm.set_shader_parameter("foam_width", 0.12)
	wm.set_shader_parameter("wave_scale", 3.0)
	wm.set_shader_parameter("wave_speed", 0.8)
	wm.set_shader_parameter("sparkle_strength", 2.4)
	wm.set_shader_parameter("bob", 0.0)
	for def in [[1.68, 0.44], [0.8, 1.43]]:
		var mi := MeshInstance3D.new()
		mi.mesh = PlanetPropMeshes.water_disc(def[0], def[1])
		mi.material_override = wm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fountain.add_child(mi)
	var p := GPUParticles3D.new()
	p.name = "Droplets"
	p.amount = 48
	p.lifetime = 1.3
	p.local_coords = true
	p.position = Vector3(0.0, 2.05, 0.0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 22.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 2.6
	pm.gravity = Vector3(0.0, -7.0, 0.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.95, 1.0, 0.9))
	g.set_color(1, Color(0.85, 0.95, 1.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = PlanetPropMeshes.puff_material(Color.WHITE)
	p.draw_pass_1 = sm
	fountain.add_child(p)

# ============================================================================================ flats
## FEN'S LONG DUSK. `sun_peak_elev_deg` is 11, so every shadow on this pan is 5.1x its caster and the
## world is read through CAST SHADOWS instead of through relief (there is none: hill_amplitude 0.035
## is a pan, and the 14 craters are pools, not hills). Two rules come straight out of that:
##
##   * NOTHING HERE IS OVER 4.5 m TALL. environment.gd sets directional_shadow_max_distance = 25 and
##     a 4.5 m prop at 11 degrees already lays a 23 m shadow; anything taller has its own shadow cut
##     off in the middle of the pan, which is the one thing this world cannot afford.
##   * The identity rides on LARGE props. _scatter_scale() thins small scatter to 35% under
##     Compatibility/mobile, so a pan whose character came from pebbles would simply empty out.
##
## Two patterned placements carry it: the seven-stone colonnade along the spawn -> pad great circle,
## and a graded ring of spires around every crater pool. Everything is drawn from the seeded `rng`
## only — Planet.prebuild() builds a throwaway planet WITH props during the rocket cruise and bakes
## AO off it, so a non-deterministic placement here bakes shadows for props that never appear.
func _fen() -> void:
	var rock_mat := PlanetPropMeshes.rock_material()
	var spawn := data.spawn_dir.normalized()
	var pad := data.pad_dir.normalized()

	# 1. THE STONE LINE. Seven slabs alternating sides of the walk to the rocket, the first PATTERNED
	# scatter in the game outside the hub's fountain ring. Under an 11-degree sun each 2.4-3.2 m slab
	# lays a 12-16 m shadow bar across the pan, so the walk is a colonnade of alternating stripes —
	# this is the establishing shot of the world. Deterministic by construction (_arc_side, not
	# find_free_dir), which is what makes it survive Planet.prebuild()'s AO bake unchanged.
	#
	# THE ARITHMETIC THE SPEC MISSED. Spawn and pad are 14.0 m apart, but planet.gd reserves
	# SPAWN_FLAT_RADIUS + 0.6 = 3.6 m and PAD_FLAT_RADIUS + 1.0 = 5.0 m, so the spec's t = 0.14 +
	# 0.12i at 3.2 m to the side puts FOUR of the seven inside a reserved disc and _is_free drops
	# them — a three-stone colonnade. Widening the offsets to 4.2/4.4 m buys the run back (the
	# exclusion is radial, so a stone further off the centreline may sit closer along it) and 0.093
	# per step then spaces same-side neighbours 2.6 m apart, clear of the 1.9 m two props need.
	for i in 7:
		var t := 0.14 + 0.093 * float(i)
		var side := 4.4 if i % 2 == 0 else -4.2
		var h := 2.4 + 0.28 * float(i % 4)
		var d := Vector3.ZERO
		# (metres along the arc, side-offset multiplier). A pool or a neighbour's disc can sit on any
		# one slot; stepping along the line first and standing further off it second keeps the row
		# whole instead of leaving a hole in the middle of the establishing shot.
		for off: Vector2 in [Vector2(0.0, 1.0), Vector2(0.8, 1.0), Vector2(-0.8, 1.0),
				Vector2(0.0, 1.28), Vector2(1.7, 1.0), Vector2(-1.7, 1.0), Vector2(0.0, 0.78)]:
			var c := _arc_side(spawn, pad, t, side * off.y, off.x)
			if not planet._is_free(c, 1.0):
				continue
			if wr > 0.0 and planet.height_at(c) < wr + 0.30:   # never in a pool
				continue
			if planet.bank_weight(c) > 0.40:                   # never on a crater wall
				continue
			d = c
			break
		if d == Vector3.ZERO:
			continue
		# Face the walk, so the broad 0.62 m plane is what the player and the sun both see. A random
		# yaw turns a third of the colonnade edge-on and the shadow bars go thin.
		var toward := arc_point(spawn, pad, t) - d
		_spawn_blocking(_standing_stone(data.rock_color, data.bank_color, h, i), [rock_mat], d,
			1.0, 0.9, 0.42, h, 0.10, false, rng.randf_range(-0.16, 0.16), toward, null, "StandingStone")

	# 2. THE ARCH at the far end of the avenue. The project has no arch, monolith, obelisk or ruin
	# anywhere — gantry() is the only span structure and it is Bolt's. Deliberately NOT a blocking
	# prop: it is a gate you walk through, and a cylinder collider in a 1.6 m opening blocks it.
	# t = 0.56 is as close to the pad as the 6.0 m pad exclusion allows.
	for nudge: float in [0.0, -1.1, 1.1]:
		var ad := _arc_side(spawn, pad, 0.56, 0.0, nudge)
		if not planet._is_free(ad, 0.9):
			continue
		if wr > 0.0 and planet.height_at(ad) < wr + 0.30:
			continue
		_spawn_oriented(_resonator_arch(data.rock_color, data.bank_color), [rock_mat], ad,
			1.0, 1.4, 0.06, pad - ad, true, "Arch")
		break

	# 3. GRADED RINGS around the pools (see _pool_rings).
	_pool_rings(data.rock_color, data.ground_color_low)

	# 4. SALT SCRUB. Low and sparse on purpose: nothing on this world is allowed to compete with the
	# stones for silhouette, and a 0.34 m blade still throws 1.7 m of shadow here.
	var scrub_mat := PlanetPropMeshes.foliage_material(0.05, 0.7, false, 0.8, Color.BLACK, 0.0, 0.06, 0.03,
		{"strength": 1.2, "near": 3.0, "far": 13.0, "sss": 0.14})
	for i in _n(data.tree_count, 3):
		var s := rng.randf_range(0.85, 1.25)
		var d := planet.find_free_dir(rng, 0.6 * s)
		if d == Vector3.ZERO:
			continue
		_spawn_simple(_salt_scrub(data.foliage_color_a, data.foliage_shadow_color, i), [scrub_mat],
			d, s, 0.55, 0.04, false, NAN, _scatter_shadow(true), "SaltScrub")

	# 5-6. A pan is strewn: rock_count 24 is the highest in the game.
	_pebbles(_n(data.rock_count, 6))
	var petal: Color = data.flower_colors[0] if data.flower_colors.size() > 0 else Color("#d9b8a0")
	_flower_patches(_n(data.flower_patch_count, 2), data.foliage_color_a, petal)

	# 7. THE SPARSEST TUFTS IN THE GAME. `density_m2` is a DIVISOR (planet_props.gd `area / density`),
	# so a SMALLER number means MORE tufts: the spec's 0.55 would have carpeted a dead salt pan with
	# ~3800 tufts, seven times home's density and the exact opposite of what it asked for. 3.2 gives
	# ~660 on 2124 m² (0.31/m² against home's 1.0/m²). Tinted at the SALT colour, not the ground
	# colour, so they read as dry crust whiskers rather than as a lawn (the Zorp lesson below).
	_grass_tufts(data.ground_color_low.darkened(0.10), 3.2)
	_ashfall()

	# 8. ONE lamp at the pad. Home and Zorp have no point lights at all; on a world where the sun
	# never gets off the horizon, arrival needs a warm pool to land in.
	var pad_node := Node3D.new()
	pad_node.name = "PadGlow"
	pad_node.transform = planet.surface_transform(pad, spawn - pad)
	root.add_child(pad_node)
	_omni(pad_node, Vector3(0.0, 2.4, 0.0), Color("#ffb46e"), 1.0, 6.0)

## A ring of spires around every crater pool, graded in height around the circle. Fen has 14 pools
## and nothing in the game is scattered in a PATTERN except the hub's fountain ring and the colonnade
## above — ringing the rims is what makes the craters read as designed features instead of scenery.
## The grade (tall on one side, short on the other, sweeping smoothly between) is what stops it
## reading as a fence. Uses Planet.crater_dirs()/crater_angle(), which exist for exactly this.
func _pool_rings(stone: Color, salt: Color) -> void:
	var craters := planet.crater_dirs()
	if craters.is_empty():
		return
	# Small scatter, so it pays the mobile budget: 5 per pool on desktop, 3 under Compatibility.
	var per_pool := 5 if _scatter_scale() >= 0.9 else 3
	var xfs_a: Array[Transform3D] = []
	var xfs_b: Array[Transform3D] = []
	var tints_a := PackedColorArray()
	var tints_b := PackedColorArray()
	for i in craters.size():
		var cd := craters[i].normalized()
		# crater_angle is the ANGULAR rim radius; +0.75 m clears the 0.13 m lip onto the flat pan.
		var rim_m := planet.crater_angle(i) * planet.radius + 0.75
		var xf0 := planet.surface_transform(cd, Vector3.FORWARD)
		var phase := rng.randf_range(0.0, TAU)
		for k in per_pool:
			var ang := TAU * float(k) / float(per_pool) + phase
			var off := (xf0.basis.x * cos(ang) + xf0.basis.z * sin(ang)) * (rim_m / planet.radius)
			var d := (cd + off).normalized()
			if not planet._is_free(d, 0.5):
				continue
			if wr > 0.0 and planet.height_at(d) < wr + 0.22:
				continue
			var grade := 0.58 + 0.72 * (0.5 + 0.5 * cos(ang - phase))
			var xf := _surface_xf(d, rng.randf_range(0.0, TAU), 0.05, false)
			xf.basis = xf.basis.scaled(Vector3(0.86 + 0.16 * grade, grade, 0.86 + 0.16 * grade))
			planet.register_prop(d, 0.42)
			if k % 2 == 0:
				xfs_a.append(xf)
				tints_a.append(Color.WHITE)
			else:
				xfs_b.append(xf)
				tints_b.append(Color.WHITE)
	# One MultiMesh per variant: ~70 spires for two draw calls. They still register a footprint each
	# so the DecorationManager does not drop a chair inside a ring.
	var mat := PlanetPropMeshes.rock_material()
	if not xfs_a.is_empty():
		_multimesh(_pool_spire(stone, salt, 0), xfs_a, tints_a, mat, _scatter_shadow(true))
	if not xfs_b.is_empty():
		_multimesh(_pool_spire(stone.darkened(0.07), salt, 1), xfs_b, tints_b, mat, _scatter_shadow(true))

## Suspended warm dust, deliberately NOT Zorp's _spores(): slower (0.02-0.10 vs 0.08-0.25), longer
## lived (14 s vs 9), much higher off the ground (radius + 3.4 vs + 1.3) and barely turbulent, so it
## hangs in the raking light as a haze instead of swirling like spores.
func _ashfall() -> void:
	var p := GPUParticles3D.new()
	p.name = "Ashfall"
	p.amount = 90
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.local_coords = true
	p.visibility_aabb = AABB(Vector3.ONE * -(planet.radius + 6.0), Vector3.ONE * (planet.radius + 6.0) * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	pm.emission_sphere_radius = planet.radius + 3.4
	pm.direction = Vector3.ZERO
	pm.spread = 180.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.10
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.25
	pm.turbulence_noise_scale = 1.6
	pm.scale_min = 0.7
	pm.scale_max = 1.6
	var g := Gradient.new()
	var warm := Color("#e8d8bc")
	g.set_color(0, Color(warm.r, warm.g, warm.b, 0.0))
	g.add_point(0.18, warm)
	g.add_point(0.55, Color("#c9a184"))
	g.set_color(g.get_point_count() - 1, Color(warm.r, warm.g, warm.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	q.material = PlanetPropMeshes.sparkle_material(Color(1.0, 1.0, 1.0, 0.45))
	p.draw_pass_1 = q
	root.add_child(p)

# ============================================================================================ chalk
## GRIG'S CHALK STEPS. A 9.5 m ball cut into five concentric shelves at a 0.279 m riser. Everything
## here is arranged against HORIZONTALS: the world is nothing but contour lines, so the props that
## matter are the ones that stand up (the henge, the spindle trees) or the ones that deliberately
## span a step (the shelves). No trodden paths — see _collect_paths().
func _grig() -> void:
	var stone_mat := PlanetPropMeshes.rock_material()
	var prop_mat := PlanetPropMeshes.prop_material()
	var spawn := data.spawn_dir.normalized()

	# 1. THE HENGE. Nine monoliths in a ring around the landing point, heights graded 2.2 -> 3.4 ->
	# 2.2 around the circle so it reads as built rather than scattered. _hero_dirs is already a
	# deterministic ring 5.5-7 m out; on a world with a 59.7 m circumference it is visible in one
	# glance from almost anywhere. Each one faces the middle, which is what makes it a henge.
	var ring := _hero_dirs(9, 1.4)
	for i in ring.size():
		var t := float(i) / maxf(1.0, float(ring.size() - 1))
		var h := 2.2 + 1.2 * (1.0 - absf(2.0 * t - 1.0))
		var mesh := _step_monolith(data.rock_color, data.ground_color_low, data.ground_shadow_color, h, i)
		# Footprints on this world are deliberately tight to the stone the prop actually stands on.
		# MEASURED with showcase/planet_survey.tscn: Grig is 1134 m², the smallest world in the game,
		# and the reserved discs already take 10.1% of it, so a generous footprint here costs several
		# points of decorable ground apiece. A 0.8 m slab gets 1.0, not the 1.2 a puff tree gets.
		_spawn_blocking(mesh, [stone_mat], ring[i], 1.0, 1.0, 0.40, h, 0.10, false,
			0.0, spawn - ring[i], null, "Monolith")

	# 2. CHALK SHELVES. The only props in the game that span an elevation change, and what makes the
	# staircase read as inhabited rather than geological. allow_slope is on because they are MEANT to
	# sit on a step edge, and the span is turned across the contour so it actually bridges the riser.
	var shelf_mesh := _chalk_shelf(data.rock_color.lightened(0.04), data.ground_shadow_color, 2.6)
	for i in 3:
		var d := Vector3.ZERO
		for attempt in 5:
			var c := planet.find_free_dir(rng, 1.4, 64, true)
			if c == Vector3.ZERO:
				continue
			d = c
			if _near_riser(c, 1.0):
				break
		if d == Vector3.ZERO:
			continue
		var down := _downhill(d)
		var hint := d.cross(down) if down != Vector3.ZERO else Vector3.ZERO
		_spawn_blocking(shelf_mesh, [stone_mat], d, 1.0, 1.2, 0.85, 0.78, 0.05, false,
			0.0 if hint != Vector3.ZERO else NAN, hint, null, "ChalkShelf")

	# 3. SPINDLE TREES: one straight tapered trunk under a FLAT table of foliage. Tall and thin on
	# purpose — they are the only verticals on a world made entirely of horizontals.
	var tree_mat := PlanetPropMeshes.foliage_material(0.030, 3.4, false, 1.0, Color.BLACK, 0.0, 0.08, 0.04,
		{"strength": 1.4, "near": 4.5, "far": 18.0, "sss": 0.16})
	for i in _n(data.tree_count, 4):
		var s := rng.randf_range(0.90, 1.12)
		var d := planet.find_free_dir(rng, 1.1 * s, 96)
		if d == Vector3.ZERO:
			continue
		# 0.85, not the 1.0 the spec proposed: the trunk is 0.2 m and the table of foliage is 3 m up,
		# so a chair genuinely fits under one. On a 9.5 m world that difference is a point of budget.
		_spawn_blocking(_spindle_tree(data.trunk_color, data.foliage_color_a, data.foliage_shadow_color, i),
			[tree_mat], d, s, 0.85, 0.28, 3.0, 0.05, false, NAN, Vector3.ZERO, null, "SpindleTree")

	# 4. Quarry spoil (pebble_rock in rock_color, allow_slope already true inside _pebbles).
	_pebbles(_n(data.rock_count, 3))

	# 5. FOUR LAMPS on riser tops. The steps have to be readable at night, and only chrome and plaza
	# use point lights today.
	var lamp_mesh := PlanetPropMeshes.lamp_post(Color("#8a8171"), Color("#6f6759"), 2.4, false)
	var glow := PlanetPropMeshes.pulse_material(Color("#ffd0a0"), 1.0, 1.1, 0, 0.75, Color("#e8cea0"))
	for i in 4:
		var d := Vector3.ZERO
		for attempt in 5:
			var c := planet.find_free_dir(rng, 0.55, 48)
			if c == Vector3.ZERO:
				continue
			d = c
			if _near_riser(c, 1.2):
				break
		if d == Vector3.ZERO:
			continue
		var lamp := _spawn_blocking(lamp_mesh, [prop_mat, glow], d, 1.0, 0.45, 0.16, 2.4, 0.05,
			false, NAN, Vector3.ZERO, null, "Lamp")
		_omni(lamp, Vector3(0.0, 2.45, 0.0), Color("#ffd0a0"), 0.9, 5.0)

	# 6. Lichen cushions and the one place chroma is allowed on this world.
	_bushes(4)
	var petal: Color = data.flower_colors[1 % data.flower_colors.size()] if data.flower_colors.size() > 0 else Color("#d8cba4")
	_flower_patches(_n(data.flower_patch_count, 3), data.foliage_color_a, petal)

	# SPARSE LICHEN, NOT A LAWN. Same divisor trap as Fen above: the authored 0.55 would have put
	# ~2060 tufts on 1134 m², the densest field in the game, on a world described as bare stone.
	# 3.0 gives ~380 (0.33/m²). Tinted LIGHTER than the ground per the Zorp luma lesson: these blades
	# are mostly toon-shade side, so a tint darker than the ground reads as several thousand
	# near-black specks and pins the planet's luma p05 outside the R2.6 window. _grass_tufts already
	# skips anything with bank_weight > 0.34, so the risers stay bare stone by themselves.
	_grass_tufts(Color("#9aa88a"), 3.0)
	_chalk_dust()

## Chalk powder drifting along the terrace floors. A GROUND-HUGGING layer (radius + 0.4) against
## Zorp's spores at + 1.3 and Fen's ashfall at + 3.4 — on a staircase the dust sits in the treads.
func _chalk_dust() -> void:
	var p := GPUParticles3D.new()
	p.name = "ChalkDust"
	p.amount = 70
	p.lifetime = 11.0
	p.preprocess = 11.0
	p.local_coords = true
	p.visibility_aabb = AABB(Vector3.ONE * -(planet.radius + 3.0), Vector3.ONE * (planet.radius + 3.0) * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	pm.emission_sphere_radius = planet.radius + 0.4
	pm.direction = Vector3.ZERO
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.18
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.35
	pm.turbulence_noise_scale = 2.0
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var g := Gradient.new()
	var c := Color("#ddd2bd")
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.30, c)
	g.set_color(g.get_point_count() - 1, Color(c.r, c.g, c.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	q.material = PlanetPropMeshes.sparkle_material(Color(1.0, 1.0, 1.0, 0.40))
	p.draw_pass_1 = q
	root.add_child(p)


# ============================================================================================ frost
## VELA'S STILL FROST. A 14.5 m ball of deep wind-smoothed powder with NO EDGES ANYWHERE: no water,
## no craters, no plateaus, no terraces and no trodden path, so `bank_weight()` is zero over the
## entire sphere and every boundary the other five worlds are read through is simply absent here.
## MEASURED: 1.78 m of relief across ~2.7 crests per great circle (the largest smooth relief and by
## far the fewest undulations in the game — Fen 44 crests, home 43, Grig 34 before terracing), mean
## slope 2.9 deg and a maximum of 14.5 deg, so NOTHING on this planet is refused for slope. The
## placement survey comes back at 86.6% free at a 0.6 m footprint with slope refusal 0.0% (home
## 65.3%, Fen 66.8%, Grig 53.5%) — this is at once the quietest world in the game and by a wide
## margin the most decorable one, which is the right trade for a cosy game: the empty snowfield is
## the invitation, and the player's own furniture is what is meant to fill it.
##
## Three rules follow from that, and they are the whole composition:
##
##   * EVERYTHING IS HALF-BURIED. Every prop below is sunk 0.14-0.38 m rather than the usual
##     0.03-0.12, so the powder swallows its feet and nothing has a visible ground contact edge.
##     This is free — `sink` is already a parameter on all three spawn helpers — and it is the
##     single strongest cue that the ground is deep rather than painted.
##   * THE ONLY WARM COLOUR IS THE LAMPS. The .tres palette is blue from end to end (the first cool
##     ground in the game); the amber that shows up on the relay masts is Vela's own #d8a25c, the
##     same colour as the seven rim lamps she talks with. Nothing else here is allowed to be warm,
##     which is why this world takes no trodden path (a tan arc would break it twice over: it is an
##     edge, and it is warm).
##   * SOFT IS FOR WEATHER, HARD IS FOR MACHINERY. R2.3 asks for flat planes and chamfers, not
##     blobs, and every BUILT thing here obeys it — the masts are faceted shafts with flat panels,
##     the dishes are struck cones with a hard rim. The drift fins are the deliberate exception:
##     they ARE the weather, and a wind ridge with a chamfer on it is simply wrong.
##
## The sun sits at 78 deg, so every shadow is only 0.21x its caster and shadow reach is a non-issue
## (Fen's 4.5 m ceiling does not apply). Determinism: Planet.prebuild() builds a throwaway planet
## WITH props during the rocket cruise and bakes AO from it, so everything here comes off the seeded
## `rng` or off `_arc_side`, never off the clock.
func _vela() -> void:
	# Vela's own AMBER (vela_model.gd:64). Deliberately the same swatch, so the field lamps and the
	# lamps she speaks with are one colour and the player reads them as hers.
	var amber := Color("#d8a25c")
	var metal_mat := PlanetPropMeshes.prop_material()
	var spawn := data.spawn_dir.normalized()
	var pad := data.pad_dir.normalized()

	# 1. THE LONG ARRAY. Eight relay masts in ONE straight run down one side of the walk to the
	# rocket, all the same height and all canted to the same patch of sky. That sameness is the
	# point and it is the opposite of Fen's colonnade, which alternates sides and grades its heights
	# 2.4 -> 3.2: a row of IDENTICAL verticals is a measuring stick, and on a world whose only
	# feature is a 1.78 m swell it is the one thing that makes the ground's rise and fall legible.
	# Deterministic by construction (_arc_side, not find_free_dir) so the AO prebake matches.
	#
	# THE ARITHMETIC. spawn -> pad is 16.72 m and planet.gd reserves SPAWN_FLAT_RADIUS + 0.6 = 3.6 m
	# and PAD_FLAT_RADIUS + 1.0 = 5.0 m at the ends. Standing the line 5.0 m off the centreline
	# clears both discs at every t used below (t = 0.06 is 5.10 m from spawn, t = 0.788 is 6.13 m
	# from the pad) and leaves 1.74 m between neighbours, comfortably past the 1.60 m that a 0.80 m
	# footprint plus a 0.80 m clearance needs.
	var mast_h := 3.05
	var lamp_glow := PlanetPropMeshes.pulse_material(amber, 0.85, 0.9, 0, 0.72, amber.darkened(0.34))
	for i in 8:
		var t := 0.06 + 0.104 * float(i)
		var d := Vector3.ZERO
		# (metres along the arc, side-offset multiplier). Vela's home disc is 21 m from spawn so it
		# never touches the run, but a collectible or the neighbour's wander target can, and a hole
		# in the middle of a row of identical masts is far more visible than a hole in a scatter.
		for off: Vector2 in [Vector2(0.0, 1.0), Vector2(0.0, 1.22), Vector2(0.75, 1.0),
				Vector2(-0.75, 1.0), Vector2(0.0, 0.80)]:
			var c := _arc_side(spawn, pad, t, 5.0 * off.y, off.x)
			if not planet._is_free(c, 0.80):
				continue
			d = c
			break
		if d == Vector3.ZERO:
			continue
		# Aim every mast along the run and then yaw them all by the SAME 0.55 rad, so the vanes are
		# three-quarters on to the walk: face-on they would overlap into one wall, edge-on they would
		# vanish. A random yaw would destroy the whole read.
		var toward := arc_point(spawn, pad, minf(t + 0.09, 1.0)) - d
		var mast := _spawn_blocking(_relay_mast(data.rock_color, data.ground_color_low, mast_h, i),
			[metal_mat, lamp_glow], d, 1.0, 0.80, 0.24, mast_h, 0.30, false, 0.55, toward, null, "RelayMast")
		# Three real lights, not eight: the amber has to read as a warm accent on a cold world, and
		# eight overlapping pools would wash the powder between them into a continuous glow. The
		# other five masts still carry the emissive lamp head, which is a material and costs nothing.
		if i == 1 or i == 4 or i == 7:
			_omni(mast, Vector3(0.0, mast_h + 0.08, 0.0), amber, 0.85, 5.5)

	# 2. THE DISHES. Three of them, tipped at three different angles and buried to the rim on the low
	# side — this is where "everything half-buried" is stated at full size. Vela's dialogue names
	# "dish four" and "dish nine", so the array she keeps has to exist on the ground; and because SHE
	# is a parabola, these are deliberately built as struck cones with a hard rim rather than as
	# copies of her face.
	#
	# CLUSTERED, not scattered. A plain find_free_dir samples the whole sphere uniformly, and the
	# first build put all three 27-30 m from spawn — over the horizon of a 14.5 m world, so the mast
	# line read as a row of poles leading nowhere and the dishes read as three unrelated props. They
	# are one INSTALLATION, so they are seeded around a point just beyond the far end of the mast
	# run, on the opposite side of it from the walk.
	var array_anchor := _arc_side(spawn, pad, 0.62, 10.5)
	for i in 3:
		var d := planet.find_free_dir_near(rng, array_anchor, 8.0, 1.5, 64)
		if d == Vector3.ZERO:
			d = planet.find_free_dir(rng, 1.5, 96)
		if d == Vector3.ZERO:
			continue
		_spawn_blocking(_relay_dish(data.rock_color, data.ground_color_low, data.ground_shadow_color, i),
			[metal_mat], d, 1.0, 1.4, 0.80, 1.20, 0.38, false, NAN, Vector3.ZERO, null, "ArrayDish")

	# 3. DRIFT FINS — the first ALIGNED scatter in the game. Fen's colonnade and pool rings are
	# patterned but each prop still takes a random yaw; here every fin is turned to the SAME wind
	# axis, which is what makes a featureless snowfield read as wind-smoothed rather than as a
	# smooth sphere. Non-blocking and only 0.39 m proud, so they are ground, not scenery.
	_drift_field(Vector3(0.62, 0.18, -0.76).normalized())

	# 4. HALF-BURIED ERRATICS. _pebbles() would do the job but it sinks its rocks 0.12 m, which on
	# this world leaves a visible contact edge on the one prop that has the most of them. Same mesh,
	# same material, 0.30 m of sink.
	var rock_mat := PlanetPropMeshes.rock_material()
	for i in _n(data.rock_count, 4):
		var s := rng.randf_range(0.85, 1.45)
		var d := planet.find_free_dir(rng, 0.7 * s)
		if d == Vector3.ZERO:
			continue
		_spawn_blocking(PlanetPropMeshes.pebble_rock(data.rock_color, i), [rock_mat], d, s,
			0.60, 0.42, 0.5, 0.30, true, NAN, Vector3.ZERO, null, "FrostStone")

	# 5. RIME BLOOMS — two patches, and the only chroma on the planet that is not amber.
	var petal: Color = data.flower_colors[0] if data.flower_colors.size() > 0 else Color("#c6d3e2")
	_flower_patches(_n(data.flower_patch_count, 2), data.foliage_color_a, petal)

	# 6. THE SPARSEST TUFTS IN THE GAME. `density_m2` is a DIVISOR (area / density), so a BIGGER
	# number means FEWER: 4.8 puts ~550 on 2642 m² (0.21/m²) against Fen's 0.31 and home's 1.0. They
	# are rime whiskers, not a lawn.
	# THE TINT IS THE OPPOSITE OF GRIG'S, AND FOR THE SAME REASON. Grig tints its lichen LIGHTER than
	# the ground because a dark speck field pinned its luma p05 too LOW. Vela measures the other way
	# round: it lands at p05 0.303 against a 0.30-0.42 window, i.e. it is short of darkness rather
	# than short of light, so these are tinted a little DARKER and a good deal more chromatic than the
	# powder. They read as blue rime instead of as scraps of white paper (which is exactly what a
	# near-white tint looked like in the first capture), and with no crater, no waterline and no path
	# they are one of very few sources of fine tonal speckle anywhere on the planet.
	_grass_tufts(Color("#76849f"), 4.8)
	_diamond_dust()

## Wind-carved drift ridges, all turned to one axis. A ridge is a soft form on purpose (see the
## R2.3 note on _vela): the built things on this world carry the flat planes, the weather does not.
## One MultiMesh per variant, and each fin registers a footprint so the DecorationManager does not
## seat a chair inside a drift.
func _drift_field(wind: Vector3) -> void:
	var count := 22 if _scatter_scale() >= 0.9 else 12
	var xfs_a: Array[Transform3D] = []
	var xfs_b: Array[Transform3D] = []
	var tints_a := PackedColorArray()
	var tints_b := PackedColorArray()
	for i in count:
		var d := planet.find_free_dir(rng, 1.1, 64)
		if d == Vector3.ZERO:
			continue
		# The wind axis projected onto the tangent plane. Near the two points where the axis is
		# vertical this degenerates, so those fins are simply dropped rather than spun at random —
		# ONE misaligned ridge is enough to break the read the other fifteen are paying for.
		var t := wind - d * wind.dot(d)
		if t.length_squared() < 0.05:
			continue
		var xf := planet.surface_transform(d, t.normalized())
		var s := 0.80 + rng.randf_range(0.0, 0.55)
		xf.basis = xf.basis.scaled(Vector3(s, 0.85 + rng.randf_range(0.0, 0.35), s * rng.randf_range(0.9, 1.35)))
		xf.origin -= xf.basis.y.normalized() * 0.16
		planet.register_prop(d, 0.90)
		if i % 2 == 0:
			xfs_a.append(xf)
			tints_a.append(Color.WHITE)
		else:
			xfs_b.append(xf)
			tints_b.append(Color.WHITE)
	var mat := PlanetPropMeshes.rock_material()
	if not xfs_a.is_empty():
		_multimesh(_drift_fin(data.ground_color_a.lightened(0.10), data.ground_shadow_color, 0),
			xfs_a, tints_a, mat, _scatter_shadow(true))
	if not xfs_b.is_empty():
		_multimesh(_drift_fin(data.ground_color_a.lightened(0.06), data.ground_shadow_color, 1),
			xfs_b, tints_b, mat, _scatter_shadow(true))

## Diamond dust: airborne ice crystals in still, very cold air. The third member of the suspended-
## particle family and deliberately the slowest and least turbulent of the three — Zorp's spores
## swirl (0.08-0.25 m/s, turbulence 0.6), Fen's ashfall drifts (0.02-0.10, 0.25), Grig's chalk dust
## hugs the treads at radius + 0.4. This hangs at radius + 1.8 at 0.01-0.06 m/s and barely moves at
## all, which is what "the quietest world in the game" has to look like.
func _diamond_dust() -> void:
	var p := GPUParticles3D.new()
	p.name = "DiamondDust"
	p.amount = 55
	p.lifetime = 18.0
	p.preprocess = 18.0
	p.local_coords = true
	p.visibility_aabb = AABB(Vector3.ONE * -(planet.radius + 4.0), Vector3.ONE * (planet.radius + 4.0) * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	pm.emission_sphere_radius = planet.radius + 1.8
	pm.direction = Vector3.ZERO
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.06
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.12
	pm.turbulence_noise_scale = 1.1
	pm.scale_min = 0.5
	pm.scale_max = 1.1
	var g := Gradient.new()
	var ice := Color("#e8f0ff")
	g.set_color(0, Color(ice.r, ice.g, ice.b, 0.0))
	g.add_point(0.25, ice)
	g.add_point(0.62, Color("#c2d2ea"))
	g.set_color(g.get_point_count() - 1, Color(ice.r, ice.g, ice.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	# 0.34 against Fen's 0.45 and Grig's 0.40: on a pale ground a bright particle is the easiest way
	# there is to push the blown-highlight count, and this world starts closest to that ceiling.
	q.material = PlanetPropMeshes.sparkle_material(Color(1.0, 1.0, 1.0, 0.34))
	p.draw_pass_1 = q
	root.add_child(p)
# ============================================================================================ meshes for the newer worlds
## Meshes for "flats", "chalk" and "frost". They live here rather than in PlanetPropMeshes because
## those worlds were built in parallel with that file and none of these forms existed in it; the cache
## below mirrors PlanetPropMeshes._cached() so repeated builds (and Planet.prebuild's throwaway
## planet) share one ArrayMesh per key. Everything is flat planes, chamfers, tapers and panel lines
## per R2.3 — no blobs, and every prop stays under the ~2k triangle budget in ARCHITECTURE.md.
static var _extra_mesh_cache: Dictionary = {}

static func _cached_mesh(key: String, builder: Callable) -> ArrayMesh:
	if _extra_mesh_cache.has(key):
		return _extra_mesh_cache[key]
	var m: ArrayMesh = builder.call()
	_extra_mesh_cache[key] = m
	return m

## A flat-sided (optionally tapered) beam between two points in the XZ=0 plane, `hd` deep in Z.
## 24 tris; a lintel built out of these is a tenth of the cost of one built out of rounded boxes,
## and it is genuinely faceted cut stone rather than a tube.
static func _beam(kit: PlanetMeshKit, a: Vector3, b: Vector3, hw_a: float, hw_b: float, hd: float, color: Color) -> void:
	var axis := b - a
	if axis.length_squared() < 0.000001:
		return
	axis = axis.normalized()
	var side := Vector3(-axis.y, axis.x, 0.0)
	if side.length_squared() < 0.000001:
		side = Vector3(1.0, 0.0, 0.0)
	side = side.normalized()
	var dep := Vector3(0.0, 0.0, hd)
	var a0 := a + side * hw_a + dep
	var a1 := a - side * hw_a + dep
	var a2 := a - side * hw_a - dep
	var a3 := a + side * hw_a - dep
	var b0 := b + side * hw_b + dep
	var b1 := b - side * hw_b + dep
	var b2 := b - side * hw_b - dep
	var b3 := b + side * hw_b - dep
	kit.quad(a0, a1, a2, a3, color)
	kit.quad(b3, b2, b1, b0, color)
	kit.quad(a0, b0, b1, a1, color)
	kit.quad(a1, b1, b2, a2, color)
	kit.quad(a2, b2, b3, a3, color)
	kit.quad(a3, b3, b0, a0, color)

## Fen's standing slab: three stacked slabs of shrinking width, a chamfered top cut and one mineral
## inlay band across the middle. ~1290 tris. Total height stays at `height` + 0.14, and `height` is
## capped at 3.24 by the caller, which keeps the 11-degree shadow inside the 25 m shadow distance.
static func _standing_stone(rock: Color, vein: Color, height: float, variant: int) -> ArrayMesh:
	var key := "fen_stone|%s|%s|%.3f|%d" % [rock.to_html(), vein.to_html(), height, variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var widths := PackedFloat32Array([0.62, 0.50, 0.38])
		var tops := PackedFloat32Array([0.42, 0.76, 1.00])
		var lean := (0.020 + 0.012 * float(variant % 3)) * (1.0 if variant % 2 == 0 else -1.0)
		var prev := 0.0
		for k in 3:
			var y0 := prev * height
			var y1 := tops[k] * height
			var cy := (y0 + y1) * 0.5
			kit.rounded_box(Vector3(lean * cy, cy, 0.0), Vector3(widths[k], y1 - y0, 0.24 - 0.02 * float(k)),
				0.05, rock.darkened(0.06 - 0.03 * float(k)))
			prev = tops[k]
		var by := 0.62 * height
		kit.rounded_box(Vector3(lean * by, by, 0.0), Vector3(0.54, 0.055, 0.27), 0.015, vein)
		# Chamfered crown: two triangles slicing the top back, so the silhouette ends on an angle
		# rather than on a flat lid (R2.3 "flat planes, chamfers and hard edges").
		var back := 1.0 if variant % 2 == 0 else -1.0
		var xo := lean * height
		kit.quad(
			Vector3(xo - 0.19, height + 0.14, back * 0.10),
			Vector3(xo + 0.19, height + 0.14, back * 0.10),
			Vector3(xo + 0.19, height - 0.02, -back * 0.10),
			Vector3(xo - 0.19, height - 0.02, -back * 0.10),
			rock.lightened(0.05))
		return kit.commit()
	return _cached_mesh(key, build)

## Fen's salt scrub: five flat tapered blades in a splayed rosette, none over 0.335 m. 12 tris.
static func _salt_scrub(leaf: Color, shadow: Color, variant: int) -> ArrayMesh:
	var key := "fen_scrub|%s|%s|%d" % [leaf.to_html(), shadow.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for k in 5:
			var a := TAU * float(k) / 5.0 + 0.7 * float(variant)
			var outw := Vector3(cos(a), 0.0, sin(a))
			var side := Vector3(-sin(a), 0.0, cos(a)) * 0.038
			var base := outw * 0.035
			var hgt := 0.200 + 0.045 * float((k * 2 + variant) % 4)
			var tip := base + outw * (0.16 + 0.05 * float((k + variant) % 3)) + Vector3(0.0, hgt, 0.0)
			kit.triangle(base - side, base + side, tip, leaf if k % 2 == 0 else leaf.lerp(shadow, 0.45))
		kit.cylinder(Vector3(0.0, -0.015, 0.0), 0.062, 0.050, 0.035, shadow, Basis.IDENTITY, 8)
		return kit.commit()
	return _cached_mesh(key, build)

## Fen's pool spire: a slim hard-faceted mineral spike with a salt crust at the foot, ~1.05 m tall
## before the ring grades it 0.58-1.30. ~100 tris, and it is instanced through a MultiMesh.
static func _pool_spire(stone: Color, salt: Color, variant: int) -> ArrayMesh:
	var key := "fen_spire|%s|%s|%d" % [stone.to_html(), salt.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.135, 0.0), Vector2(0.105, 0.30),
			Vector2(0.052, 0.74), Vector2(0.0, 1.05)])
		if variant % 2 == 1:
			prof = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.150, 0.0), Vector2(0.088, 0.42),
				Vector2(0.070, 0.62), Vector2(0.0, 0.92)])
		kit.lathe(prof, 7, Transform3D.IDENTITY, stone, false)
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.175, 0.0), Vector2(0.150, 0.075),
			Vector2(0.0, 0.075)]), 7, Transform3D.IDENTITY, salt, false)
		return kit.commit()
	return _cached_mesh(key, build)

## Fen's resonator arch: two tapered legs and a faceted span, 3.42 m to the top of the keystone (the
## 4.5 m shadow ceiling). Clear opening ~1.6 m, and it is spawned without a collider so the walk to
## the rocket goes straight through it. ~240 tris.
static func _resonator_arch(stone: Color, vein: Color) -> ArrayMesh:
	var key := "fen_arch|%s|%s" % [stone.to_html(), vein.to_html()]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var leg_y := 2.20
		var span_r := 0.95
		for sx: float in [-1.0, 1.0]:
			_beam(kit, Vector3(sx * span_r, 0.0, 0.0), Vector3(sx * span_r, leg_y, 0.0), 0.22, 0.16, 0.17, stone)
			_beam(kit, Vector3(sx * span_r - sx * 0.03, 1.34, 0.0), Vector3(sx * span_r - sx * 0.03, 1.46, 0.0),
				0.20, 0.20, 0.19, vein)
		var segs := 6
		for i in segs:
			var a0 := PI * (1.0 - float(i) / float(segs))
			var a1 := PI * (1.0 - float(i + 1) / float(segs))
			var p0 := Vector3(cos(a0) * span_r, leg_y + sin(a0) * span_r, 0.0)
			var p1 := Vector3(cos(a1) * span_r, leg_y + sin(a1) * span_r, 0.0)
			_beam(kit, p0, p1, 0.16, 0.16, 0.17, stone.lightened(0.03) if i % 2 == 0 else stone)
		_beam(kit, Vector3(0.0, leg_y + span_r - 0.06, 0.0), Vector3(0.0, leg_y + span_r + 0.27, 0.0),
			0.17, 0.13, 0.15, vein)
		return kit.commit()
	return _cached_mesh(key, build)

## Grig's step monolith: a FOUR-SIDED tapered shaft (a 4-segment lathe with hard normals, so the
## sides are genuine flat planes), one scribed groove band and a flat chamfered cap. ~700 tris.
static func _step_monolith(stone: Color, cap: Color, shadow: Color, height: float, variant: int) -> ArrayMesh:
	var key := "grig_mono|%s|%s|%s|%.3f|%d" % [stone.to_html(), cap.to_html(), shadow.to_html(), height, variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var r0 := 0.40 + 0.03 * float(variant % 3)
		var r_top := r0 * 0.74
		kit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(r0, 0.0),
			Vector2(r0 * 0.94, height * 0.26),
			Vector2(r_top, height * 0.90),
			Vector2(0.0, height * 0.90)]), 4, Transform3D.IDENTITY, stone, false)
		# A 4-segment lathe is a square standing on its diagonal, so a matching box is rotated 45 deg
		# and sized side = radius * sqrt(2). Groove band first, then the overhanging cap.
		var gy := height * (0.56 + 0.06 * float(variant % 2))
		var gr := lerpf(r0 * 0.94, r_top, clampf((gy - height * 0.26) / (height * 0.64), 0.0, 1.0))
		var q := Basis(Vector3.UP, PI * 0.25)
		kit.rounded_box(Vector3(0.0, gy, 0.0), Vector3(gr * 1.470, 0.062, gr * 1.470), 0.012, shadow, q)
		kit.rounded_box(Vector3(0.0, height * 0.935, 0.0), Vector3(r_top * 1.78, 0.095, r_top * 1.78), 0.022, cap, q)
		return kit.commit()
	return _cached_mesh(key, build)

## Grig's chalk shelf: a flat deck on two chamfered piers with a step block at one end. ~1300 tris.
## Placed across a riser, it is the only prop in the game that spans an elevation change.
static func _chalk_shelf(stone: Color, shadow: Color, span: float) -> ArrayMesh:
	var key := "grig_shelf|%s|%s|%.2f" % [stone.to_html(), shadow.to_html(), span]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.rounded_box(Vector3(0.0, 0.62, 0.0), Vector3(span, 0.16, 0.86), 0.035, stone)
		for sx: float in [-1.0, 1.0]:
			kit.rounded_box(Vector3(sx * (span * 0.5 - 0.30), 0.28, 0.0), Vector3(0.32, 0.56, 0.62),
				0.04, stone.darkened(0.12))
		kit.rounded_box(Vector3(span * 0.5 - 0.06, 0.30, 0.0), Vector3(0.24, 0.34, 0.72), 0.03, shadow.lightened(0.22))
		return kit.commit()
	return _cached_mesh(key, build)

## Grig's spindle tree: one straight tapered trunk under a FLAT horizontal table of foliage with a
## dark bracket underneath. ~300 tris. The trunk carries PlanetPropMeshes.WOOD_ALPHA so the foliage
## shader gives it directional grain instead of plump leaf softness (R2.9).
static func _spindle_tree(trunk: Color, frond: Color, shadow: Color, variant: int) -> ArrayMesh:
	var key := "grig_spindle|%s|%s|%s|%d" % [trunk.to_html(), frond.to_html(), shadow.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var h := 2.80 + 0.28 * float(variant % 3)
		var wood := Color(trunk.r, trunk.g, trunk.b, PlanetPropMeshes.WOOD_ALPHA)
		kit.cylinder(Vector3(0.0, -0.05, 0.0), 0.20, 0.085, h + 0.05, wood, Basis.IDENTITY, 9)
		kit.cylinder(Vector3(0.0, h - 0.10, 0.0), 0.26, 0.98, 0.12, shadow, Basis.IDENTITY, 14)
		kit.cylinder(Vector3(0.0, h + 0.02, 0.0), 1.00, 0.92, 0.10, frond, Basis.IDENTITY, 14)
		kit.cylinder(Vector3(0.0, h + 0.12, 0.0), 0.58, 0.36, 0.09, frond.lightened(0.07), Basis.IDENTITY, 12)
		return kit.commit()
	return _cached_mesh(key, build)


## Vela's relay mast: a hexagonal tapered shaft, two flat cross-arms with guy struts, a flat
## reflector vane canted ~60 degrees at the sky, and an amber lamp box on top. The lamp is SURFACE 1
## so the caller can hand it a pulse material exactly as Grig's lamp posts do. ~1000 tris, most of
## it in the two rounded boxes — everything structural is `_beam`, which is 24 tris apiece.
static func _relay_mast(metal: Color, trim: Color, height: float, variant: int) -> ArrayMesh:
	var key := "vela_mast|%s|%s|%.3f|%d" % [metal.to_html(), trim.to_html(), height, variant]
	var build := func() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		var kit := PlanetMeshKit.new()
		# Foot plate. It ends up 0.30 m under the powder, which is the point — and is also why this
		# is the cheapest place on the prop to spend a rounded box.
		kit.rounded_box(Vector3(0.0, 0.05, 0.0), Vector3(0.62, 0.11, 0.62), 0.03, metal.darkened(0.12))
		# SIX-SIDED shaft with hard normals, so the sides are real flat planes. Deliberately not
		# Grig's four (a square shaft is his monolith) and deliberately not a smooth tube.
		kit.lathe(PackedVector2Array([
			Vector2(0.0, 0.02), Vector2(0.118, 0.02),
			Vector2(0.100, height * 0.30),
			Vector2(0.062, height * 0.88),
			Vector2(0.0, height * 0.88)]), 6, Transform3D.IDENTITY, metal, false)
		# Two cross-arms at heights that shift per variant, so a row of identical masts still has a
		# little joinery variety when the player walks right up to one.
		var a0 := height * (0.34 + 0.04 * float(variant % 3))
		var a1 := height * (0.56 + 0.03 * float((variant + 1) % 3))
		_beam(kit, Vector3(-0.34, a0, 0.0), Vector3(0.34, a0, 0.0), 0.035, 0.035, 0.045, metal.lightened(0.05))
		_beam(kit, Vector3(-0.27, a1, 0.0), Vector3(0.27, a1, 0.0), 0.030, 0.030, 0.040, metal.lightened(0.05))
		# Guy struts from the arm ends back down to the shaft. The diagonals are what stop a bare
		# pole reading as a stick.
		_beam(kit, Vector3(-0.34, a0, 0.0), Vector3(-0.075, a0 - 0.52, 0.0), 0.022, 0.022, 0.026, metal.darkened(0.08))
		_beam(kit, Vector3(0.34, a0, 0.0), Vector3(0.075, a0 - 0.52, 0.0), 0.022, 0.022, 0.026, metal.darkened(0.08))
		# THE VANE: a flat rectangular reflector panel tipped back so its face looks 54-66 degrees up.
		# A double-sided quad and one spar — four triangles for the largest visual element on the
		# prop, and the sameness of the angle across all eight masts is what makes them read as ONE
		# instrument pointed at one patch of sky rather than as eight fence posts.
		var cant := 0.95 + 0.10 * float(variant % 3)
		var vc := Vector3(0.0, height * 0.70, -0.15)
		var vu := Vector3(0.0, cos(cant), sin(cant))
		var hw := 0.38
		var hh := 0.27
		kit.quad(vc - Vector3(hw, 0.0, 0.0) - vu * hh, vc + Vector3(hw, 0.0, 0.0) - vu * hh,
			vc + Vector3(hw, 0.0, 0.0) + vu * hh, vc - Vector3(hw, 0.0, 0.0) + vu * hh, trim)
		var spar := vc - vu * 0.03
		_beam(kit, spar - Vector3(hw, 0.0, 0.0), spar + Vector3(hw, 0.0, 0.0), 0.026, 0.026, 0.020, metal.lightened(0.08))
		# Feed on a short boom standing off the vane's face. `Basis(RIGHT, cant - PI/2)` maps +Y onto
		# the panel normal (0, sin(cant), -cos(cant)); a long boom is a thin spike that flickers on a
		# phone, so it is kept to 0.28 m.
		var fb := Basis(Vector3.RIGHT, cant - PI * 0.5)
		kit.cylinder(vc, 0.020, 0.014, 0.28, metal.darkened(0.10), fb, 5)
		kit.rounded_box(vc + Vector3(0.0, sin(cant), -cos(cant)) * 0.30, Vector3(0.09, 0.09, 0.09),
			0.022, metal.darkened(0.16), fb)
		_beam(kit, Vector3(0.0, height * 0.88, 0.0), Vector3(0.0, height - 0.10, 0.0), 0.052, 0.062, 0.052, metal.darkened(0.06))
		kit.commit(mesh)
		# Surface 1: the lamp. Small, because it is the only warm thing on the planet and it has to
		# read as a signal rather than as a floodlight.
		var glow := PlanetMeshKit.new()
		glow.rounded_box(Vector3(0.0, height, 0.0), Vector3(0.15, 0.13, 0.15), 0.03, Color.WHITE)
		glow.commit(mesh)
		return mesh
	return _cached_mesh(key, build)

## Vela's array dish: a faceted lens on a hexagonal plinth, tipped so the low rim goes under the
## powder. ONE closed lathe traversed axis -> rim along the back and rim -> axis along the face, with
## hard normals, which gives a struck, faceted dish with a genuine cut rim for ~200 tris; a lathed
## parabola with a lip costs five times that. ~700 tris in total.
##
## The traversal order is load-bearing. PlanetMeshKit.lathe derives its normal as (t.y, -t.x) from
## the segment tangent, so a profile walked COUNTER-CLOCKWISE in (radius, height) — out along the
## bottom, up the rim, back in along the top — gives outward normals on every band, and the same
## profile walked the other way lights the dish inside out.
static func _relay_dish(metal: Color, face: Color, shadow: Color, variant: int) -> ArrayMesh:
	var key := "vela_dish|%s|%s|%s|%d" % [metal.to_html(), face.to_html(), shadow.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var hub := 0.95
		# Three genuinely different attitudes: an array that all points one way reads as a repeated
		# prop, and these are the one thing on this world the player walks between.
		var tilt := 0.52 + 0.13 * float(variant % 3)
		var swing := 0.9 * float(variant % 3)
		kit.cylinder(Vector3.ZERO, 0.44, 0.36, 0.34, shadow.lightened(0.12), Basis.IDENTITY, 6)
		var basis := Basis(Vector3.UP, swing) * Basis(Vector3.RIGHT, -tilt)
		var hub_pos := Vector3(0.0, hub, 0.0)
		# Yoke: two flat struts from the plinth up to the hub.
		_beam(kit, Vector3(-0.30, 0.28, 0.0), Vector3(-0.10, hub - 0.06, 0.0), 0.055, 0.045, 0.045, metal.darkened(0.10))
		_beam(kit, Vector3(0.30, 0.28, 0.0), Vector3(0.10, hub - 0.06, 0.0), 0.055, 0.045, 0.045, metal.darkened(0.10))
		var xf := Transform3D(basis, hub_pos)
		kit.lathe(PackedVector2Array([
			Vector2(0.0, -0.02), Vector2(0.52, 0.13), Vector2(1.02, 0.29),   # back, walking outward
			Vector2(1.02, 0.38),                                             # the cut rim
			Vector2(0.52, 0.27), Vector2(0.0, 0.10)]),                       # face, walking back in
			16, xf, face, false)
		# The underside again, inset a hair so it never z-fights, in the dark tone. Same outward
		# traversal, so it takes the same downward normals as the band it covers.
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.028), Vector2(0.51, 0.121), Vector2(1.00, 0.281)]),
			16, xf, metal.darkened(0.14), false)
		kit.torus(hub_pos + basis * Vector3(0.0, 0.335, 0.0), 1.02, 0.038, metal.lightened(0.06), basis, 16)
		# Centre-fed: one short boom up the dish axis to a feed block at the focus.
		kit.cylinder(hub_pos + basis * Vector3(0.0, 0.09, 0.0), 0.030, 0.022, 0.62, metal.darkened(0.10), basis, 6)
		kit.rounded_box(hub_pos + basis * Vector3(0.0, 0.74, 0.0), Vector3(0.17, 0.15, 0.17), 0.04,
			shadow.lightened(0.26), basis)
		return kit.commit()
	return _cached_mesh(key, build)

## Vela's drift fin: a long low wind ridge — one soft crest with a shorter lee lobe behind it, never
## mirror-symmetric, because real sastrugi are not. ~340 tris, instanced through a MultiMesh.
##
## THE ONE DELIBERATE R2.3 EXCEPTION on this planet. Everything BUILT here is flat planes, chamfers
## and cut rims; this is weather, and putting a chamfer on drifted snow is the single most wrong
## thing it is possible to do to this world.
static func _drift_fin(powder: Color, shade: Color, variant: int) -> ArrayMesh:
	var key := "vela_drift|%s|%s|%d" % [powder.to_html(), shade.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var long := 1.30 + 0.28 * float(variant % 2)
		kit.sphere(Vector3.ZERO, 1.0, powder, Vector3(0.42, 0.55, long), 14)
		# The lee lobe sits downwind (+Z is behind the fin's facing direction) and a touch to one
		# side. `add_mesh` uses the inverse-transpose basis, so the squashed normals are correct.
		kit.sphere(Vector3(0.09 * (1.0 if variant % 2 == 0 else -1.0), -0.06, long * 0.52), 1.0,
			shade.lerp(powder, 0.62), Vector3(0.27, 0.34, long * 0.46), 12)
		return kit.commit()
	return _cached_mesh(key, build)
# ============================================================================================ collectibles
func _collectibles() -> void:
	var kinds := data.collectible_kind.split(",", false)
	if kinds.is_empty():
		kinds = PackedStringArray(["stardust_shard"])
	var crng := planet.make_rng(7)
	var dirs: Array[Vector3] = []
	for i in data.collectible_count:
		var d := planet._find_free_dir(crng, 0.7, 40, false)
		if d == Vector3.ZERO:
			d = planet._find_free_dir(crng, 0.4, 40, true)
		if d == Vector3.ZERO:
			continue
		planet.register_prop(d, 0.45)
		dirs.append(d)
	for i in dirs.size():
		var id := "%s_%d" % [data.id, i]
		if Collectible.was_picked_today(data.id, id):
			continue
		var kind := String(kinds[i % kinds.size()]).strip_edges()
		var c := Collectible.new()
		c.setup(kind, id, data.id)
		c.transform = planet.surface_transform(dirs[i], _random_tangent(dirs[i]))
		coll_root.add_child(c)
