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
		_:
			_meadow()
	_collectibles()

# ============================================================================================ helpers
func _collect_paths() -> void:
	var spawn := data.spawn_dir.normalized()
	if data.biome == "chrome" or data.biome == "violet":
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

## One MultiMesh for many small foliage instances (flowers/tufts) tinted via custom data.
func _multimesh(mesh: ArrayMesh, xfs: Array[Transform3D], tints: PackedColorArray, material: Material, shadow: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
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
	_multimesh(mesh, xfs, tints, PlanetPropMeshes.foliage_material(0.02, 0.35, true, 2.0), true)

## Thousands of tiny swaying tufts on grass only (not sand, water, paths, tiles, or inside props).
func _grass_tufts(color: Color, density_m2: float) -> void:
	var area := 4.0 * PI * planet.radius * planet.radius
	var target := mini(int(area / density_m2), 6000)
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
		_multimesh(PlanetPropMeshes.flower(Color("#3d7f38"), Color("#e0b34f"), 0), flower_xfs, flower_tints, PlanetPropMeshes.foliage_material(0.02, 0.35, true, 2.0), true)

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
