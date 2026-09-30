class_name JungleProps
extends RefCounted
## The scatter for THE TANGLE (planet "jungle", biome "jungle"), called from PlanetProps._jungle().
## docs/JUNGLE_PLANET_SPEC.md section 2: "a full alien jungle - dense, layered, and strange".
##
## It borrows PlanetProps' own placement helpers (`_spawn_blocking`, `_spawn_oriented`, `_hero_dirs`,
## `_grass_tufts`, `_n`, `rng`, the contact-shadow bookkeeping) so every rule the other worlds obey -
## the reserved zones, the area scaling, the Compatibility scatter thinning, one seeded RNG stream -
## holds here too. The meshes are in JungleMeshes.
##
## ORDER MATTERS. Every find_free_dir() call consumes the shared RNG and registers a footprint, so the
## big trees go first (they own the space), then the landmarks, then the floor.
##
## DENSE BUT NEVER A WALL. Only trunks, stems, pods, rocks and the arch feet block, and each keeps
## >= 1.2 m of clear ground from every other footprint, so there is always a way between them. (Palm
## crowns and parasol tiers also carry a flat collider ABOVE head height - see `_canopy_shapes` - so the
## camera can fade them; walking never meets one, a jetpack hop can.) Everything below knee
## height - broadleaf clumps, fiddleheads, fungi, reeds, tufts - is walk-through scenery. The trails
## (JungleLayout) are reserved by Planet before anything grows, so each is a clear tunnel under the canopy.
##
## DRAW CALLS. Trees, spirals and arches are individual nodes (they must block and they must fade out of
## the camera's way - CameraRig fades layer-4 bodies that stand between the lens and the astronaut).
## The floor layers are MultiMeshes: one draw per variant per surface for the whole planet.

const DECO_LAYER := PlanetProps.DECO_LAYER

var pp: PlanetProps
var planet: Planet
var data: PlanetData
var rng: RandomNumberGenerator

# Palette - derived from the .tres where a field exists, authored here where it does not.
var _frond: Color
var _frond_light: Color
var _shade: Color
var _trunk: Color
## L1 LOOK (2026-09-29, the user: "can we make the plant colors an unused different color to make it
## seem more like an alien jungle vs just an earth jungle?"). THE TANGLE'S PALETTE IS WINE, TURQUOISE AND
## GOLD - no green anywhere. Measured against the other seven worlds' .tres foliage/ground hues (home 122-147,
## hub 124-160, Bolt 175 + 28, Fen 70-77, Grig 71-82, Vela 191-219, Zorp 270 ground / 326 pale): no world
## grows coral-magenta leaves (hue 342-354 at S 0.42-0.50) or has a wine floor (hue 330-334), and the
## turquoise and gold here are the COMPLEMENT that makes the magenta read as alien rather than autumn.
##   wine / coral-magenta  the floor (jungle.tres ground) and the emergent palm crowns (foliage a/b)
##   turquoise             the parasol canopy, the fern understory, the root-arch moss, the pools
##   gold                  spiral curls, seed pods, fiddleheads, reeds - small accents
##   indigo                trunks and roots (jungle.tres trunk), so no brown-wood Earth cue either
## Parasol tiers: turquoise, the layer between the coral crowns and the wine floor.
const PARASOL_CAP := Color("#579e9c")
const PARASOL_LIGHT := Color("#6fb2ad")
const PARASOL_UNDER := Color("#3d5866")
## Spiral plants: deep turquoise stems going gold at the curl.
const SPIRAL_STEM := Color("#3f7a80")
const SPIRAL_TIP := Color("#c7a963")
## Pods: gold husks with an indigo cap.
const POD_SHELL := Color("#9e7d4c")
const POD_CAP := Color("#4b3d5c")
## Glow colours. Amber and teal, one magenta. Small parts only - saturated accents must be small.
## K1 (2026-09-29): the night glow read WHITISH AND MOONLIT. Three causes, all in this file's material:
## the old colours were pastels (#7ff0d2 is S 0.47, #ffc46b S 0.58), the stock crystal material caps the
## emission at a peak channel of 1.6 - above the environment's glow threshold of 1.15, so every vein and
## bead bloomed and the bloom plus tonemap washed the hue toward white - and its glossy specular (0.8,
## roughness 0.2) put a sky-blue sheen on the thin strips. Now: saturated hues, a peak held just under
## the bloom threshold (GLOW_CAP), no light() specular, and less emission left in daylight.
const GLOW_AMBER := Color("#ff8f24")
const GLOW_TEAL := Color("#14c8a6")
const GLOW_MAGENTA := Color("#d8649f")
## Brightest emission channel (linear) a jungle glow may reach: under Environment glow_hdr_threshold
## 1.15, so the glow keeps its own hue instead of blooming white. The stock crystal cap is 1.6.
const GLOW_CAP := 0.9
const GLOW_DAY_SCALE := 0.10
const MOSS := Color("#5f948f")
const REED := Color("#a8925e")
const LILY := Color("#a86a7c")
## Understory: [leaf, leaf_light] per variant. Broadleaf is wine / turquoise / coral, ferns turquoise / plum.
const BROAD_COLS := [["#8f4f6a", "#b3708a"], ["#4f8f8c", "#72b0aa"], ["#a8605c", "#c88478"]]
const FERN_COLS := [["#4f8f8e", "#74b3aa"], ["#8a5a86", "#aa7aa2"]]


func _init(props: PlanetProps) -> void:
	pp = props
	planet = props.planet
	data = props.data
	rng = props.rng
	_frond = data.foliage_color_a
	_frond_light = data.foliage_color_b
	_shade = data.foliage_shadow_color
	_trunk = data.trunk_color


func build() -> void:
	_use_trails()
	_spire_palms()
	_parasols()
	_root_arches()
	_spiral_plants()
	_seed_pods()
	_mossy_rocks()
	_pool_edges()
	_giants()
	_ferns()
	_broadleaf()
	_floor_scatter()
	pp._grass_tufts(data.ground_color_a.darkened(0.10), 1.1)
	_mist()
	_motes()
	_pad_glow()


# ============================================================================================ trails
## PlanetProps._collect_paths() laid down the default straight spawn->pad arc; this world's trails are
## JungleLayout's bent network instead, so the prop avoidance (_on_paved) uses exactly the arcs the
## ground shader paints.
func _use_trails() -> void:
	pp._path_a.clear()
	pp._path_b.clear()
	for arc in JungleLayout.trail_arcs(data):
		pp._path_a.append(arc[0])
		pp._path_b.append(arc[1])
	pp._path_width = JungleLayout.TRAIL_WIDTH


# ============================================================================================ canopy
static var _glow_cache: Dictionary = {}


## The crystal shader (the "plants glow at night" mechanism, JungleMeshes header) with the jungle's own
## cap, day scale and no specular - see GLOW_CAP. Albedo is the glow hue, darker, so by day a vein or
## bead is a coloured accent and not a cream stripe. `albedo_mix` pulls the day albedo toward `base`
## (the leaf veins use the leaf's own light green so they do not stripe the fronds by day).
func _glow_mat(c: Color, strength: float = 1.6, base: Color = Color(0, 0, 0, 0), albedo_mix: float = 0.0) -> ShaderMaterial:
	var alb := c.darkened(0.55)
	if base.a > 0.0:
		alb = alb.lerp(base, albedo_mix)
	var key := "%s|%s|%.2f" % [c.to_html(), alb.to_html(), strength]
	if _glow_cache.has(key):
		return _glow_cache[key]
	var m := ShaderMaterial.new()
	m.shader = PlanetPropMeshes.CRYSTAL_SHADER
	m.set_shader_parameter("albedo", alb)
	m.set_shader_parameter("glow_color", c)
	m.set_shader_parameter("glow_strength", strength)
	m.set_shader_parameter("faceted", false)
	m.set_shader_parameter("core_glow", 0.55)
	m.set_shader_parameter("emission_cap", GLOW_CAP)
	m.set_shader_parameter("emission_day_scale", GLOW_DAY_SCALE)
	m.set_shader_parameter("spec_strength", 0.0)
	m.set_shader_parameter("pulse_amount", 0.18)
	_glow_cache[key] = m
	return m


func _body_mat(sway: float, sway_h: float) -> ShaderMaterial:
	return PlanetPropMeshes.foliage_material(sway, sway_h, false, 0.7, Color.BLACK, 0.0, 0.08, 0.03,
		{"strength": 0.7, "near": 4.5, "far": 18.0, "sss": 0.22, "wood": 0.55, "knot": 0.15})


## Spots around the pad (outside its reserve) so the view on landing is framed by trees, not empty.
func _pad_ring(count: int, clearance: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var pad := data.pad_dir.normalized()
	var xf := planet.surface_transform(pad, Vector3.FORWARD)
	for i in count:
		for attempt in 6:
			var ang := TAU * (float(i) + 0.5) / float(count) + rng.randf_range(-0.4, 0.4)
			var dist := Planet.PAD_FLAT_RADIUS + 1.0 + clearance + rng.randf_range(0.3, 2.0)
			var off := (xf.basis.x * cos(ang) + xf.basis.z * sin(ang)) * (dist / planet.radius)
			var d := (pad + off).normalized()
			if planet._is_free(d, clearance) and not (pp.wr > 0.0 and planet.height_at(d) < pp.wr + 0.25):
				out.append(d)
				break
	return out


func _spire_palms() -> void:
	var body := _body_mat(0.10, 5.0)
	var glow := _glow_mat(GLOW_TEAL, 1.5)
	var hero := pp._hero_dirs(3, 1.3)
	hero.append_array(_pad_ring(4, 1.3))
	var count := pp._n(26, 10)
	for i in count:
		var s := rng.randf_range(0.9, 1.1)
		var dir: Vector3 = hero[i] if i < hero.size() else planet.find_free_dir(rng, 1.2, 120)
		if dir == Vector3.ZERO:
			continue
		var mesh := JungleMeshes.spire_palm(_trunk, _frond, _frond_light, _shade, i % 5)
		var b := pp._spawn_blocking(mesh, [body, glow], dir, s, 1.1, 0.30, 3.2, 0.05, false, NAN, Vector3.ZERO, null, "SpirePalm")
		_canopy_shapes(b, JungleMeshes.palm_key(_trunk, _frond, _frond_light, _shade, i % 5), s)


func _parasols() -> void:
	var body := _body_mat(0.05, 3.5)
	var glow := _glow_mat(GLOW_AMBER, 1.7)
	# No hero ring and nothing near a trail: the gameplay camera rides ~5 m up over the trail behind
	# the astronaut, i.e. just above a 2.2-3.2 m parasol tier, and a tier within reach of the trail
	# filled a quarter of the frame as a flat purple slab (captured, J1 round 9). Palms, whose crowns are
	# open fronds, take the trail edges instead.
	var count := pp._n(30, 10)
	for i in count:
		var s := rng.randf_range(0.88, 1.12)
		var dir := Vector3.ZERO
		for attempt in 10:
			var d := planet.find_free_dir(rng, 1.3, 60)
			if d != Vector3.ZERO and not pp._on_paved(d, 2.6):
				dir = d
				break
		if dir == Vector3.ZERO:
			continue
		var mesh := JungleMeshes.parasol_tree(_trunk, PARASOL_CAP, PARASOL_LIGHT, PARASOL_UNDER, i % 4)
		var b := pp._spawn_blocking(mesh, [body, glow], dir, s, 1.2, 0.30, 2.0, 0.05, false, NAN, Vector3.ZERO, null, "Parasol")
		_canopy_shapes(b, JungleMeshes.parasol_key(_trunk, PARASOL_CAP, PARASOL_LIGHT, PARASOL_UNDER, i % 4), s)


## Adds one flat cylinder per canopy (palm crown / parasol tier) to the tree's own StaticBody3D, so
## CameraRig's occluder probe - which only sees layer-4 BODIES - fades a canopy that hangs over the
## line from the lens to the astronaut, not just the trunk. The discs sit above head height (the
## lowest parasol tier is ~2.1 m); a jetpack hop can bump into one, the way it would a real canopy.
func _canopy_shapes(b: StaticBody3D, key: String, s: float) -> void:
	if b == null or not JungleMeshes.canopies.has(key):
		return
	for c: Vector4 in JungleMeshes.canopies[key]:
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = c.w * 0.85 * s
		shape.height = 0.5 * s
		cs.shape = shape
		cs.position = Vector3(c.x, c.y + 0.05, c.z) * s
		b.add_child(cs)


## Root arches straddle the trails: the walk goes UNDER them. Placed on fixed fractions of four
## trail arcs, oriented across the trail. Not blocking in the middle; each foot gets its own collider.
func _root_arches() -> void:
	var body := _body_mat(0.0, 10.0)
	var glow := _glow_mat(GLOW_TEAL, 1.4)
	var arcs := JungleLayout.trail_arcs(data)
	var spots := [[0, 0.36], [1, 0.55], [3, 0.45], [6, 0.55]]
	var k := 0
	for spot: Array in spots:
		var arc: PackedVector3Array = arcs[int(spot[0])]
		var t := float(spot[1])
		var d := PlanetProps.arc_point(arc[0], arc[1], t)
		if pp.wr > 0.0 and planet.height_at(d) < pp.wr + 0.3:
			continue
		var along := arc[1] - arc[0]
		var n := pp._spawn_oriented(JungleMeshes.root_arch(_trunk, MOSS, k), [body, glow], d, 1.0, 0.0, 0.06,
			along, true, "RootArch")
		_sight_dirs.append(d)
		_arch_feet(n)
		k += 1


## Two small colliders at the arch feet (local X = +-1.65 m) so the roots are solid but the gap under
## the span stays open.
func _arch_feet(n: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Feet"
	body.collision_layer = DECO_LAYER
	body.collision_mask = 0
	for side in [-1.0, 1.0]:
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.38
		shape.height = 1.6
		cs.shape = shape
		cs.position = Vector3(side * 1.65, 0.75, 0.0)
		body.add_child(cs)
		# Local maths, not to_global(): the scatter can run on Planet.prebuild()'s out-of-tree planet,
		# and props are laid out in planet-local space with the planet at the origin.
		planet.register_prop((n.transform * Vector3(side * 1.65, 0.0, 0.0)).normalized(), 0.6)
	n.add_child(body)


func _spiral_plants() -> void:
	var body := _body_mat(0.06, 3.0)
	var glow := _glow_mat(GLOW_AMBER, 1.9)
	var count := pp._n(28, 10)
	for i in count:
		var s := rng.randf_range(0.85, 1.15)
		var dir := planet.find_free_dir(rng, 0.8, 80)
		if dir == Vector3.ZERO:
			continue
		var mesh := JungleMeshes.spiral_plant(SPIRAL_STEM, SPIRAL_TIP, _frond_light, i % 4)
		pp._spawn_blocking(mesh, [body, glow], dir, s, 0.7, 0.22, 2.2, 0.03, false, NAN, Vector3.ZERO, null, "Spiral")


# ============================================================================================ giants
## L1 LOOK. Giant blooms and tube clusters, ringed round the LANDING VIEW (the gameplay camera at the
## spawn looking down the main trail toward the pad) so the first frame on this world is framed by alien
## growth left, right and on the skyline past the pad; and a handful more across the rest of the planet.
##
## OWN RNG. They are placed from a separate seeded stream, after the trees, pods, rocks and pool rims
## have taken theirs, so every one of those keeps its exact spot (only the understory, placed after, shifts).
## They block like a tree (a trunk collider, a canopy disc for the camera fade) and keep the trail clearance
## every trunk keeps (JungleLayout.TRAIL_CLEAR_M + GIANT_CLEAR_M from each trail centreline), so the trails,
## the pad and the stall stay open and the astronaut is never under one on a trail.
const BLOOM_STALK := Color("#3f7a80")
const BLOOM_PETAL := Color("#9a4f86")
const BLOOM_PETAL_LIGHT := Color("#c886a8")
const TUBE_COL := Color("#a8606c")
const TUBE_LIP := Color("#c7a963")
const GIANT_CLEAR_M := 1.1
## The landing framers may stand closer to the palms and parasols already there (a layered canopy is the
## point); measured: at the full 1.1 m only 4 of the 9 windows found a spot among the trees.
const LANDING_PROP_CLEAR_M := 0.45
## Landing-view windows: [bearing from the spawn->pad line (deg, + = right), bearing spread, metres from
## the spawn, metres spread, kind (0 bloom, 1 tubes)]. Near pairs frame the left and right of the first
## frame; the far ones stand past the pad on the planet's limb, where they are silhouettes against space.
## (No mid-distance pair: 8-12 m out the main trail, the west spur and the east loop leave no spot 2.5 m
## from every centreline - measured, 0 of 60 candidates.)
const LANDING_WINDOWS := [
	[-48.0, 16.0, 5.6, 1.2, 0], [42.0, 12.0, 5.4, 1.0, 0],
	[-100.0, 18.0, 6.2, 1.0, 1], [100.0, 18.0, 6.2, 1.0, 1],
	[-14.0, 8.0, 19.0, 2.0, 0], [14.0, 8.0, 19.5, 2.0, 0], [0.0, 10.0, 22.5, 2.0, 1],
]


func _giants() -> void:
	var grng := RandomNumberGenerator.new()
	grng.seed = data.seed * 7919 + 41
	var bloom_body := _body_mat(0.04, 4.5)
	var tube_body := _body_mat(0.0, 10.0)
	var bloom_glow := _glow_mat(GLOW_AMBER, 1.6)
	var tube_glow := _glow_mat(GLOW_TEAL, 1.5)
	var s := data.spawn_dir.normalized()
	var p := data.pad_dir.normalized()
	var r := planet.radius
	var placed := 0
	for w: Array in LANDING_WINDOWS:
		for attempt in 30:
			var bearing := float(w[0]) + grng.randf_range(-1.0, 1.0) * float(w[1])
			var dist := float(w[2]) + grng.randf_range(-1.0, 1.0) * float(w[3])
			var d := JungleLayout._walk(s, p, bearing, dist, r)
			if _giant_ok(d, LANDING_PROP_CLEAR_M):
				# Blooms lean in toward the main trail so their bells hang over the view like a proscenium.
				var aim := PlanetProps.arc_point(s, p, clampf(dist / (acos(clampf(s.dot(p), -1.0, 1.0)) * r), 0.0, 1.0))
				_giant(d, int(w[4]), placed, grng, JungleLayout._toward(d, aim), bloom_body, bloom_glow, tube_body, tube_glow)
				placed += 1
				break
	# The rest of the planet: a few of each, anywhere open.
	var extra := pp._n(14, 8)
	for i in extra:
		for attempt in 30:
			var v := Vector3(grng.randfn(), grng.randfn(), grng.randfn())
			if v.length_squared() < 0.001:
				continue
			v = v.normalized()
			if _giant_ok(v, GIANT_CLEAR_M):
				var t := Vector3(grng.randfn(), grng.randfn(), grng.randfn())
				_giant(v, i % 2, placed, grng, (t - v * v.dot(t)).normalized(), bloom_body, bloom_glow, tube_body, tube_glow)
				placed += 1
				break


func _giant_ok(d: Vector3, prop_clear: float) -> bool:
	if pp.wr > 0.0 and planet.height_at(d) < pp.wr + 0.3:
		return false
	# The trail margin never shrinks: 2.5 m from any trail centreline to the stalk.
	if pp._on_paved(d, GIANT_CLEAR_M + 0.6):
		return false
	return planet._is_free(d, prop_clear)


func _giant(d: Vector3, kind: int, idx: int, grng: RandomNumberGenerator, fwd: Vector3, bloom_body: Material,
		bloom_glow: Material, tube_body: Material, tube_glow: Material) -> void:
	var sc := grng.randf_range(0.9, 1.1)
	if kind == 0:
		var v := idx % 3
		var mesh := JungleMeshes.giant_bloom(BLOOM_STALK, BLOOM_PETAL, BLOOM_PETAL_LIGHT, Color(BROAD_COLS[1][0]), v)
		var b := pp._spawn_blocking(mesh, [bloom_body, bloom_glow], d, sc, 0.9, 0.24, 3.0, 0.05, false, 0.0, fwd, null, "GiantBloom")
		_canopy_shapes(b, JungleMeshes.bloom_key(BLOOM_STALK, BLOOM_PETAL, BLOOM_PETAL_LIGHT, Color(BROAD_COLS[1][0]), v), sc)
	else:
		var mesh := JungleMeshes.tube_cluster(TUBE_COL, TUBE_LIP, GLOW_TEAL, idx % 3)
		# Aimed with a forward hint (not a yaw on a random tangent) so the main RNG stream is not touched.
		pp._spawn_blocking(mesh, [tube_body, tube_glow], d, sc, 0.9, 0.6, 2.6, 0.05, false, 0.0,
			fwd.rotated(d, grng.randf_range(0.0, TAU)), null, "TubeCluster")


# ============================================================================================ floor
## MultiMeshes, surfaces keep their own materials (set on the cached mesh). Same Compatibility colour
## fix as PlanetProps._multimesh (use_colors on, white).
##
## CHUNKED BY CUBE FACE. A MultiMesh is culled as ONE box, so a planet-wide batch draws every instance
## on the far side of the world too. Measured on the first build (landing view, gl_compatibility,
## 2556x1179): 571k primitives in frame against the hub's 433k and Fen's 184k, most of it understory
## behind the planet. Splitting each batch by the dominant axis of the instance's direction (six chunks)
## lets the camera cull the far faces; it costs up to five extra draws per batch, most of them culled.
func _multi(mesh: ArrayMesh, mats: Array, xfs: Array[Transform3D], shadow: bool, label: String) -> void:
	if xfs.is_empty():
		return
	for i in mini(mats.size(), mesh.get_surface_count()):
		mesh.surface_set_material(i, mats[i])
	var chunks: Dictionary = {}
	for xf in xfs:
		var o := xf.origin
		var a := o.abs()
		var face := 0
		if a.x >= a.y and a.x >= a.z:
			face = 0 if o.x >= 0.0 else 1
		elif a.y >= a.z:
			face = 2 if o.y >= 0.0 else 3
		else:
			face = 4 if o.z >= 0.0 else 5
		if not chunks.has(face):
			chunks[face] = [] as Array[Transform3D]
		(chunks[face] as Array[Transform3D]).append(xf)
	for face: int in chunks:
		_multi_chunk(mesh, chunks[face], shadow, "%s_%d" % [label, face])


func _multi_chunk(mesh: ArrayMesh, xfs: Array[Transform3D], shadow: bool, label: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, Color.WHITE)
		mm.set_instance_custom_data(i, Color.WHITE)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = label
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pp.root.add_child(mmi)


func _xf(dir: Vector3, s: float, sink: float) -> Transform3D:
	var xf := pp._surface_xf(dir, rng.randf_range(0.0, TAU), sink * s, false)
	xf.basis = xf.basis.scaled(Vector3.ONE * s)
	return xf


## Seed pods: instanced visuals, one collider body each.
func _seed_pods() -> void:
	var body := _body_mat(0.0, 10.0)
	var glow := _glow_mat(GLOW_MAGENTA, 1.5)
	var per: Array = [[], [], []]
	var count := pp._n(12, 5)
	for i in count:
		var s := rng.randf_range(0.8, 1.2)
		var dir := planet.find_free_dir(rng, 0.8 * s, 60)
		if dir == Vector3.ZERO:
			continue
		var v := i % 3
		(per[v] as Array).append(_xf(dir, s, 0.10))
		planet.register_prop(dir, 0.7 * s)
		pp._note_contact_shadow(dir, 0.7 * s, 0.45 * s, 0.45 * s, Vector3.RIGHT)
		_collider(dir, 0.42 * s, 1.0 * s)
	for v in 3:
		var xfs: Array[Transform3D] = []
		xfs.assign(per[v])
		_multi(JungleMeshes.seed_pod(POD_SHELL, POD_CAP, v), [body, glow], xfs, pp._scatter_shadow(true), "SeedPods%d" % v)


func _collider(dir: Vector3, r: float, h: float) -> void:
	var b := StaticBody3D.new()
	b.name = "PodBody"
	b.collision_layer = DECO_LAYER
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r
	shape.height = h
	cs.shape = shape
	cs.position = Vector3(0.0, h * 0.5 - 0.05, 0.0)
	b.add_child(cs)
	b.transform = planet.surface_transform(dir)
	pp.root.add_child(b)


func _mossy_rocks() -> void:
	var mat := PlanetPropMeshes.rock_material()
	for i in pp._n(data.rock_count, 4):
		var s := rng.randf_range(0.7, 1.3)
		var dir := planet.find_free_dir(rng, 0.7 * s, 48, true)
		if dir == Vector3.ZERO:
			continue
		pp._spawn_blocking(PlanetPropMeshes.pebble_rock(data.rock_color, i), [mat], dir, s, 0.65, 0.45, 0.5, 0.12, true, NAN, Vector3.ZERO, null, "Rock")


## Reeds round the rim of every swamp pool and lily pads floating inside it.
func _pool_edges() -> void:
	var craters := planet.crater_dirs()
	if craters.is_empty() or pp.wr <= 0.0:
		return
	var reed_mat := PlanetPropMeshes.foliage_material(0.05, 1.0, false, 1.2, Color.BLACK, 0.0, 0.06, 0.02)
	var lily_mat := PlanetPropMeshes.foliage_material(0.0, 1.0, false, 1.0, Color.BLACK, 0.0, 0.06, 0.05)
	var reeds: Array = [[], []]
	var pads: Array = [[], [], []]
	var per_rim := 9 if pp._scatter_scale() >= 0.9 else 6
	for i in craters.size():
		var cd := craters[i].normalized()
		var rim_m := planet.crater_angle(i) * planet.radius
		var xf0 := planet.surface_transform(cd, Vector3.FORWARD)
		var phase := rng.randf_range(0.0, TAU)
		# Reeds just above the waterline, in clumps round the rim.
		for k in per_rim:
			var ang := TAU * float(k) / float(per_rim) + phase + rng.randf_range(-0.2, 0.2)
			for tries in 4:
				var m := rim_m * rng.randf_range(0.55, 1.0)
				var off := (xf0.basis.x * cos(ang) + xf0.basis.z * sin(ang)) * (m / planet.radius)
				var d := (cd + off).normalized()
				var h := planet.height_at(d)
				if h < pp.wr + 0.02 or h > pp.wr + 0.45:
					continue
				if pp._on_paved(d, 0.2):
					break
				(reeds[k % 2] as Array).append(_xf(d, rng.randf_range(0.8, 1.25), 0.02))
				break
		# Lily pads on the water surface over the deep middle.
		var n_pads := 5 + i % 3
		for k in n_pads:
			var ang := rng.randf_range(0.0, TAU)
			var m := rim_m * sqrt(rng.randf()) * 0.6
			var off := (xf0.basis.x * cos(ang) + xf0.basis.z * sin(ang)) * (m / planet.radius)
			var d := (cd + off).normalized()
			if planet.height_at(d) > pp.wr - 0.08:
				continue
			var xf := planet.surface_transform(d, pp._random_tangent(d))
			xf.origin = planet.global_position + d * (pp.wr + 0.012)
			var s := rng.randf_range(0.8, 1.3)
			xf.basis = xf.basis.scaled(Vector3.ONE * s)
			(pads[k % 3] as Array).append(xf)
	for v in 2:
		var xfs: Array[Transform3D] = []
		xfs.assign(reeds[v])
		_multi(JungleMeshes.reeds(REED, Color("#6b5448"), v), [reed_mat], xfs, false, "Reeds%d" % v)
	for v in 3:
		var xfs: Array[Transform3D] = []
		xfs.assign(pads[v])
		_multi(JungleMeshes.lily_pad(LILY, LILY.darkened(0.2), v), [lily_mat], xfs, false, "LilyPads%d" % v)


## Broadleaf clumps: the understory. Walk-through, never on a trail.
func _broadleaf() -> void:
	var mat := PlanetPropMeshes.foliage_material(0.05, 1.2, false, 1.0, Color.BLACK, 0.0, 0.08, 0.03,
		{"strength": 1.2, "near": 3.0, "far": 12.0, "sss": 0.26})
	var per: Array = [[], [], []]
	var count := pp._n(560, 130)
	for i in count:
		var dir := _understory_dir(0.8, POOL_GAP_M)
		if dir == Vector3.ZERO or not _thin_keep(dir):
			continue
		var n := _open_n(dir)
		# Height in metres at the leaf tops (mesh 0.84-0.96 m tall), width from the clump's spread.
		var top := lerpf(BROAD_TOP_NEAR, BROAD_TOP_FAR, n) * rng.randf_range(0.88, 1.08)
		var w := lerpf(0.85, 1.05, n) * rng.randf_range(0.9, 1.1)
		var xf := _xf(dir, 1.0, 0.02)
		xf.basis = xf.basis.scaled(Vector3(w, top / 0.92, w))
		(per[i % 3] as Array).append(xf)
		_under_add(dir)
		planet.register_prop(dir, 0.25)
	for v in 3:
		var xfs: Array[Transform3D] = []
		xfs.assign(per[v])
		var c: Array = [Color(BROAD_COLS[v][0]), Color(BROAD_COLS[v][1])]
		_multi(JungleMeshes.broadleaf(c[0], c[1], _shade.lightened(0.1), v), [mat, _glow_mat(GLOW_TEAL, 1.1, c[0], 0.3)], xfs, pp._scatter_shadow(true), "Broadleaf%d" % v)


# ============================================================================== the floor's height budget
## K1 (2026-09-29). The critics measured the off-trail floor CHEST-HIGH: broadleaf clumps 0.6-0.9 m and
## ferns 0.8-1.08 m against a 1.25 m astronaut, so after 4 s off the trail only the helmet showed, and
## in the safari's first-person view (FOV 45, 12 deg down) they filled the lower half of every frame
## and buried the subjects. The floor is now a height BUDGET: knee-high where people walk and look
## (trails, the pad, the spawn glade, the stall, the pools and the root-arch sights), thigh-high
## elsewhere, never above the astronaut's belt. The spread is kept, so from above it still reads as an
## unbroken jungle floor; and near the places people stand it is also THINNER (`_thin_keep`).
const FERN_TOP_NEAR := 0.34
const FERN_TOP_FAR := 0.48
const BROAD_TOP_NEAR := 0.36
const BROAD_TOP_FAR := 0.50
## Metres past a trail edge / pad reserve / pool shore / sight where the budget reaches FAR.
const OPEN_RAMP_M := 3.5
## Metres of bare shore kept round every pool for the tall understory (reeds and lilies own it).
const POOL_GAP_M := 1.2
## Clear-ish ring round each root arch (the sights stand on trails; the arch itself spans 3.2 m).
const SIGHT_GAP_M := 1.9
## Fraction of understory kept right at a trail edge / pad / pool (rising to all of it at OPEN_RAMP_M).
const NEAR_KEEP := 0.8

var _sight_dirs := PackedVector3Array()


## Metres from `dir` to the nearest place people walk or look: a trail edge, the pad or stall reserve,
## the spawn glade, a pool's shore, a root arch.
func _open_m(dir: Vector3) -> float:
	var r := planet.radius
	var best := 1e9
	for i in pp._path_a.size():
		best = minf(best, PlanetProps.arc_distance(dir, pp._path_a[i], pp._path_b[i]) * r - pp._path_width * 0.5)
	best = minf(best, planet.surface_distance(dir, data.pad_dir.normalized()) - (Planet.PAD_FLAT_RADIUS + 1.0))
	best = minf(best, planet.surface_distance(dir, data.spawn_dir.normalized()) - 2.0)
	best = minf(best, planet.surface_distance(dir, JungleLayout.stall_dir(data))
		- (JungleLayout.STALL_FLAT_RADIUS + JungleLayout.STALL_MARGIN_M))
	var craters := planet.crater_dirs()
	for i in craters.size():
		best = minf(best, planet.surface_distance(dir, craters[i]) - planet.crater_angle(i) * r)
	for d in _sight_dirs:
		best = minf(best, planet.surface_distance(dir, d) - SIGHT_GAP_M)
	return best


## 0 at a trail edge / pad / pool / sight, 1 at OPEN_RAMP_M and beyond.
func _open_n(dir: Vector3) -> float:
	return smoothstep(0.3, OPEN_RAMP_M, _open_m(dir))


## Thins the understory near the open places: keeps NEAR_KEEP of it at the edge, all of it at the ramp.
func _thin_keep(dir: Vector3) -> bool:
	var deep := LOW_DEEP_KEEP if JungleMeshes.low_power() else 1.0
	return rng.randf() < lerpf(NEAR_KEEP, deep, _open_n(dir))


## A spot for walk-through understory: off the trails and reserved zones, above the water, not on a
## trunk, and `spacing` metres from other understory - but free to crowd in under a canopy, which
## `find_free_dir` (clearance from every registered footprint) would never allow.
var _under_grid: Dictionary = {}
var _solid_grid: Dictionary = {}
var _res_dirs := PackedVector3Array()
var _res_radii := PackedFloat32Array()
var _grid_ready := false
const _CELL_M := 1.0


func _cell(v: Vector3) -> Vector3i:
	var p := v * (planet.radius / _CELL_M)
	return Vector3i(floori(p.x), floori(p.y), floori(p.z))


func _grid_add(grid: Dictionary, v: Vector3) -> void:
	var c := _cell(v)
	if not grid.has(c):
		grid[c] = PackedVector3Array()
	var arr: PackedVector3Array = grid[c]
	arr.append(v)
	grid[c] = arr


## True if any point in `grid` lies within `dist_m` of v (dist_m <= _CELL_M).
func _grid_near(grid: Dictionary, v: Vector3, dist_m: float) -> bool:
	var c := _cell(v)
	var min_dot := cos(dist_m / planet.radius)
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var k := Vector3i(c.x + x, c.y + y, c.z + z)
				if not grid.has(k):
					continue
				for u: Vector3 in grid[k]:
					if u.dot(v) > min_dot:
						return true
	return false


func _prepare_grids() -> void:
	_grid_ready = true
	for i in planet._reserved_dirs.size():
		var rid := planet._reserved_ids[i]
		if rid == "trail":
			continue
		_res_dirs.append(planet._reserved_dirs[i])
		# Walk-through understory may creep into the spawn glade (it is where the trails meet, not a
		# landing pad) - only the middle stays open. The pad and the stall pitch keep their full disc.
		_res_radii.append(2.0 if rid == "spawn" else planet._reserved_radii[i])
	for i in planet._prop_dirs.size():
		# Trunks, stems, pods, rocks: anything registered with a big footprint is something solid.
		if planet._prop_radii[i] >= 0.6:
			_grid_add(_solid_grid, planet._prop_dirs[i])


func _understory_dir(spacing: float, pool_margin: float = 0.6, tries: int = 24) -> Vector3:
	if not _grid_ready:
		_prepare_grids()
	var craters := planet.crater_dirs()
	for attempt in tries:
		var v := Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if v.length_squared() < 0.001:
			continue
		v = v.normalized()
		if pp.wr > 0.0 and planet.height_at(v) < pp.wr + 0.22:
			continue
		if pp._on_paved(v, 0.45):
			continue
		var ok := true
		for i in _res_dirs.size():
			if planet.surface_distance(v, _res_dirs[i]) < _res_radii[i] + 0.2:
				ok = false
				break
		# Keep the swamp pools open to view: nothing tall right on the rim (the reeds own it).
		for i in craters.size():
			if not ok:
				break
			if planet.surface_distance(v, craters[i]) < planet.crater_angle(i) * planet.radius + pool_margin:
				ok = false
		for d in _sight_dirs:
			if not ok:
				break
			if planet.surface_distance(v, d) < SIGHT_GAP_M:
				ok = false
		if not ok:
			continue
		if _grid_near(_solid_grid, v, 0.55) or _grid_near(_under_grid, v, spacing):
			continue
		return v
	return Vector3.ZERO


func _under_add(v: Vector3) -> void:
	_grid_add(_under_grid, v)


## PHONE HEAT (2026-09-30, the user: "I'm worried about heat on mobile from all the plants on the planet").
## Measured at the landing view (gl_compatibility, --ui=mobile, 2556x1179): The Tangle drew 553k primitives
## and 551 draws a frame against the hub's 407k / 428, home 279k / 255, Fen 202k / 360, Zorp 174k / 327 -
## the busiest world by a third. 85% of the jungle's instanced triangles were the floor: 441 tall ferns
## (~480 tris each, 212k) and 407 broadleaf clumps (~390 each, 157k).
## On the low-power profile (web and the phone layout - JungleMeshes.low_power(), the same gate as
## PlanetProps._scatter_scale) the floor is thinned where nobody stands: it keeps NEAR_KEEP at a trail
## edge, the pad, a pool or a sight, exactly as on desktop, and falls to LOW_DEEP_KEEP deep in the
## undergrowth (OPEN_RAMP_M and beyond). A flat 0.55 cut was tried first and emptied the trail edges in
## the landing view (captured); the deep floor is seen from further off, where fewer, overlapping fronds
## still read as a carpet. The desktop build is untouched.
const LOW_DEEP_KEEP := 0.4


## Tall ferns: the bulk of the floor. Walk-through.
func _ferns() -> void:
	var mat := PlanetPropMeshes.foliage_material(0.06, 1.6, false, 0.9, Color.BLACK, 0.0, 0.08, 0.03,
		{"strength": 0.6, "near": 3.0, "far": 12.0, "sss": 0.26})
	var per: Array = [[], []]
	var count := pp._n(600, 140)
	for i in count:
		var dir := _understory_dir(0.9, POOL_GAP_M + 0.3)
		if dir == Vector3.ZERO or not _thin_keep(dir):
			continue
		var n := _open_n(dir)
		# The fern mesh stands 0.80 m at its frond arches; squash it to the height budget and keep the
		# spread, so the floor stays a full carpet of fronds seen from above but is never a wall at eye height.
		var top := lerpf(FERN_TOP_NEAR, FERN_TOP_FAR, n) * rng.randf_range(0.88, 1.08)
		var w := lerpf(0.85, 1.0, n) * rng.randf_range(0.9, 1.1)
		var xf := _xf(dir, 1.0, 0.03 * w)
		xf.basis = xf.basis.scaled(Vector3(w, top / 0.80, w))
		(per[i % 2] as Array).append(xf)
		_under_add(dir)
	for v in 2:
		var xfs: Array[Transform3D] = []
		xfs.assign(per[v])
		var c: Array = [Color(FERN_COLS[v][0]), Color(FERN_COLS[v][1])]
		_multi(JungleMeshes.tall_fern(c[0], c[1], _shade.darkened(0.1), v), [mat, _glow_mat(GLOW_AMBER, 1.0, c[0], 0.3)], xfs, pp._scatter_shadow(true), "TallFern%d" % v)


## Fiddleheads and glow fungi, clustered round tree feet where they would grow.
func _floor_scatter() -> void:
	var fid_mat := PlanetPropMeshes.foliage_material(0.02, 0.5, false, 1.4, Color.BLACK, 0.0, 0.06, 0.03)
	var stem_mat := PlanetPropMeshes.foliage_material(0.0, 1.0, false, 1.0, Color.BLACK, 0.0, 0.05, 0.02)
	var glow := _glow_mat(GLOW_TEAL, 1.6)
	var glow2 := _glow_mat(GLOW_AMBER, 1.6)
	var fid: Array = [[], []]
	var fun: Array = [[], []]
	var scale := pp._scatter_scale()
	var n_fid := int(pp._n(60, 20) * scale)
	var n_fun := int(pp._n(90, 30) * maxf(scale, 0.7))
	for i in n_fid:
		var dir := planet.find_free_dir(rng, 0.15, 24)
		if dir == Vector3.ZERO or pp._on_paved(dir, 0.3):
			continue
		(fid[i % 2] as Array).append(_xf(dir, rng.randf_range(0.6, 0.9), 0.02))
	for i in n_fun:
		var dir := planet.find_free_dir(rng, 0.10, 24)
		if dir == Vector3.ZERO or pp._on_paved(dir, 0.2):
			continue
		(fun[i % 2] as Array).append(_xf(dir, rng.randf_range(0.9, 1.5), 0.01))
	for v in 2:
		var xfs: Array[Transform3D] = []
		xfs.assign(fid[v])
		_multi(JungleMeshes.fiddleheads(Color("#8a7048"), Color("#c7a963"), v), [fid_mat], xfs, false, "Fiddleheads%d" % v)
		var xfs2: Array[Transform3D] = []
		xfs2.assign(fun[v])
		_multi(JungleMeshes.glow_fungus(Color("#b7ad9a"), v), [stem_mat, glow if v == 0 else glow2], xfs2, false, "GlowFungus%d" % v)


# ============================================================================================ air
## MIST over the swamp pools: one GPUParticles3D for the whole planet, emitting from points sampled
## just above every pool's surface. Soft, low, slow. Its own tiny shader so it can fade and cool at
## night from `astro_night` instead of glowing like an unshaded quad would.
const MIST_SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
global uniform float astro_night;
uniform vec4 day_color : source_color = vec4(0.86, 0.82, 0.88, 1.0);
uniform vec4 night_color : source_color = vec4(0.36, 0.50, 0.58, 1.0);
uniform float strength = 0.075;
void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = mv;
}
void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = 1.0 - smoothstep(0.15, 1.0, d);
	a = a * a * COLOR.a * strength * mix(1.0, 0.65, astro_night);
	ALBEDO = mix(day_color.rgb, night_color.rgb, astro_night);
	ALPHA = a;
}
"""


func _mist() -> void:
	var craters := planet.crater_dirs()
	if craters.is_empty() or pp.wr <= 0.0:
		return
	var pts := PackedVector3Array()
	for i in craters.size():
		var cd := craters[i].normalized()
		var rim_m := planet.crater_angle(i) * planet.radius
		var xf0 := planet.surface_transform(cd, Vector3.FORWARD)
		for k in 16:
			var ang := rng.randf_range(0.0, TAU)
			var m := rim_m * sqrt(rng.randf()) * 1.05
			var off := (xf0.basis.x * cos(ang) + xf0.basis.z * sin(ang)) * (m / planet.radius)
			var d := (cd + off).normalized()
			pts.append(d * (pp.wr + 0.35))
	var img := Image.create(pts.size(), 1, false, Image.FORMAT_RGBF)
	for i in pts.size():
		img.set_pixel(i, 0, Color(pts[i].x, pts[i].y, pts[i].z))
	var tex := ImageTexture.create_from_image(img)
	var p := GPUParticles3D.new()
	p.name = "PoolMist"
	p.amount = mini(pts.size(), 150)
	p.lifetime = 11.0
	p.preprocess = 11.0
	p.local_coords = true
	p.visibility_aabb = AABB(Vector3.ONE * -(planet.radius + 3.0), Vector3.ONE * (planet.radius + 3.0) * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	pm.emission_point_texture = tex
	pm.emission_point_count = pts.size()
	pm.direction = Vector3.ZERO
	pm.spread = 180.0
	pm.initial_velocity_min = 0.03
	pm.initial_velocity_max = 0.10
	pm.gravity = Vector3.ZERO
	pm.scale_min = 2.2
	pm.scale_max = 3.4
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	g.add_point(0.3, Color(1.0, 1.0, 1.0, 1.0))
	g.add_point(0.7, Color(1.0, 1.0, 1.0, 0.8))
	g.set_color(g.get_point_count() - 1, Color(1.0, 1.0, 1.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 0.6)
	var sh := Shader.new()
	sh.code = MIST_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	q.material = mat
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pp.root.add_child(p)


## Drifting spores and firefly-like motes. Scenery only - photo subjects exist only in safari mode.
func _motes() -> void:
	var p := GPUParticles3D.new()
	p.name = "JungleMotes"
	p.amount = 120
	p.lifetime = 10.0
	p.preprocess = 10.0
	p.local_coords = true
	p.visibility_aabb = AABB(Vector3.ONE * -(planet.radius + 5.0), Vector3.ONE * (planet.radius + 5.0) * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	pm.emission_sphere_radius = planet.radius + 1.6
	pm.direction = Vector3.ZERO
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.18
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.5
	pm.turbulence_noise_scale = 3.0
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(GLOW_AMBER.r, GLOW_AMBER.g, GLOW_AMBER.b, 0.0))
	g.add_point(0.25, GLOW_AMBER)
	g.add_point(0.6, GLOW_TEAL)
	g.set_color(g.get_point_count() - 1, Color(GLOW_TEAL.r, GLOW_TEAL.g, GLOW_TEAL.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	q.material = PlanetPropMeshes.sparkle_material(Color(1.0, 1.0, 1.0, 0.75))
	p.draw_pass_1 = q
	pp.root.add_child(p)


## One warm lamp at the pad, as on Fen: arrival needs a pool of light to land in under the canopy.
func _pad_glow() -> void:
	var pad := data.pad_dir.normalized()
	var n := Node3D.new()
	n.name = "PadGlow"
	n.transform = planet.surface_transform(pad, data.spawn_dir.normalized() - pad)
	pp.root.add_child(n)
	pp._omni(n, Vector3(0.0, 2.6, 0.0), Color("#ffcf8a"), 0.9, 6.5)
