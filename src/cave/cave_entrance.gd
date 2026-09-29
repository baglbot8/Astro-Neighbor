class_name CaveEntrance
extends Interactable
## THE CAVE ENTRANCE ON THE HOME PLANET (docs/STORY_HOME_SPEC.md 9.3, builder CAVE 2026-09-28): after
## the story, a meteor piece has cracked the ground open. A dark opening in a little scorched crater,
## a ring of broken rock, a few of the cave's teal and lilac crystals pushing up, and the glowing amber
## fragment that did it, stuck in the rim. "Go in" starts a CaveVisit.
##
## Placed by planet_props.gd `_cave_entrance()` (home only, story_done only) through `place`, as the
## LAST thing on the planet (after props, grass and collectibles), so nothing else moves when
## story_done flips. The spot comes from `pick_dir` (see there). The pick is made in both states and
## kept on the planet as meta (META_DIR), so a test can frame the same spot before and after.
## No Light3D (a light count change recompiles every shader): the glow is emissive materials only.

const RNG_SALT := 9031
const FOOTPRINT_M := 2.0
const META_DIR := "cave_entrance_dir"


## One candidate per draw (`find_free_dir` with tries = 1 always draws exactly three floats), so the
## pick only depends on which candidates are rejected, and every rejection rule is the same in both
## story states and on both load paths:
##   * the registry at this moment: every prop and ordinary collectible (the entrance is placed last);
##   * the stardust companions' spots, with the same clearance. They spawn at different moments on the
##     two load paths (inside `_collectibles()` when home is built in the tree, but only once the
##     prebuilt planet enters the tree, AFTER this is registered), so any companion not yet spawned is
##     placed here once with collectible.gd's own `_companion_placement_dir` and the registry is then
##     put back. Any search, a companion's or anything else's, only changes if its ACCEPTED spot falls
##     inside the entrance (a candidate it rejected before is rejected either way), so keeping the
##     entrance off every final spot is what keeps them all still;
##   * the caller's `accept` (planet_props: not on a path).
static func pick_dir(planet: Planet, coll_root: Node = null, accept: Callable = Callable()) -> Vector3:
	var pid := planet.data.id
	var avoid: Array[Vector3] = []
	var n0 := planet._prop_dirs.size()
	for i in Collectible.STARDUST_COMPANIONS:
		var cid := "%s_star%d" % [pid, i]
		if Collectible.was_picked_today(pid, cid):
			continue
		if coll_root != null and coll_root.has_node("Collectible_" + cid):
			continue   # already spawned and registered: the registry check below covers it
		avoid.append(Collectible._companion_placement_dir(planet, pid, i))
	planet._prop_dirs.resize(n0)
	planet._prop_radii.resize(n0)
	var rng := planet.make_rng(RNG_SALT)
	var d := Vector3.ZERO
	for attempt in 400:
		var c := planet.find_free_dir(rng, FOOTPRINT_M, 1)
		if c == Vector3.ZERO:
			continue
		var ok := true
		for a in avoid:
			if planet.surface_distance(c, a) < FOOTPRINT_M + 0.45:
				ok = false
				break
		if ok and accept.is_valid() and not bool(accept.call(c)):
			ok = false
		if ok:
			d = c
			break
	planet.set_meta(META_DIR, d)
	return d


static func place(planet: Planet, parent: Node3D, dir: Vector3) -> CaveEntrance:
	var e := CaveEntrance.new()
	e.name = "CaveEntrance"
	e.prompt_text = "Go in"
	e.reach = 2.3
	parent.add_child(e)
	var fwd := planet.data.spawn_dir - dir * planet.data.spawn_dir.dot(dir)
	# Props-root space, the convention every planet_props.gd prop uses (`surface_transform` -> `.transform`).
	e.transform = planet.surface_transform(dir, fwd if fwd.length_squared() > 1e-4 else Vector3.FORWARD)
	e._build(planet, dir)
	return e


## Loaded BY PATH, on the tap: planet_props.gd (every planet) names this class, and naming CaveVisit
## here would pull the whole planet-safari script graph into every planet load.
const VISIT_SCRIPT := "res://src/cave/cave_visit.gd"


func interact(p: Node3D) -> void:
	super.interact(p)
	var scr: Variant = load(VISIT_SCRIPT)
	if scr is Script:
		(scr as Script).call("request_enter", get_tree())


func _build(planet: Planet, _dir: Vector3) -> void:
	var rock_col: Color = planet.data.rock_color.darkened(0.3)
	var rock_mat := PlanetPropMeshes.rock_material()
	# the scorched crater floor
	_disc(1.75, 0.012, MaterialLib.toon(Color("#6b5a52"), {"spec": 0.02, "rim": 0.05}), 16)
	# the cracked mound the fragment split open, set back so its doorway faces the way home (-Z)
	var kit := PlanetMeshKit.new()
	kit.faceted_blob(Vector3(0, 0.02, 0.3), 1.0, rock_col, Vector3(1.2, 0.85, 1.0), 1, 0.18, 3.0)
	kit.faceted_blob(Vector3(0.55, 0.05, 0.75), 0.55, rock_col.darkened(0.08), Vector3(1.0, 0.8, 1.0), 1, 0.22, 7.0)
	kit.faceted_blob(Vector3(-0.6, 0.02, 0.6), 0.5, rock_col.lightened(0.04), Vector3(1.0, 0.7, 1.0), 1, 0.22, 11.0)
	# the dark doorway: an arch leaning back into the mound's face
	var arch_b := Basis(Vector3.RIGHT, -0.32)
	var arch_o := Vector3(0, 0.0, -0.66)
	var dark := Color("#141019")
	var segs := 10
	var m := kit.commit()
	var mound := MeshInstance3D.new()
	mound.name = "Mound"
	mound.mesh = m
	mound.material_override = rock_mat
	add_child(mound)
	mound.transform = _ground_xf(planet, Vector3.ZERO, 0.0, 1.0)
	# The doorway: unlit near-black, so it reads as a hole at any time of day.
	var dk := PlanetMeshKit.new()
	for j in segs:
		var a0 := PI * float(j) / float(segs)
		var a1 := PI * float(j + 1) / float(segs)
		dk.triangle(arch_o + Vector3(0, 0, -0.01), arch_o + arch_b * Vector3(cos(a1) * 0.48, sin(a1) * 0.78, -0.01),
			arch_o + arch_b * Vector3(cos(a0) * 0.48, sin(a0) * 0.78, -0.01), dark)
	_mesh(dk.commit(), MaterialLib.flat_unlit(dark), mound.transform)
	for sx in [-1.0, 1.0]:
		_mesh(PlanetPropMeshes.pebble_rock(rock_col, 1 if sx > 0 else 3), rock_mat,
			_ground_xf(planet, Vector3(0.62 * sx, 0.0, -0.72), 0.8 * sx, 0.55))
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 3
	body.collision_mask = 0
	add_child(body)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.05
	cyl.height = 1.3
	cs.shape = cyl
	cs.position = Vector3(0, 0.6, 0.35)
	body.add_child(cs)
	# the crater's broken rim, open at the front
	var n := 10
	for i in n:
		var a := TAU * float(i) / float(n) + 0.15 * sin(float(i) * 2.3)
		var fx := cos(a)
		var fz := sin(a)
		if fz < -0.75:
			continue
		var p := Vector3(fx * 1.75, 0.0, fz * 1.75)
		var s := 0.45 + 0.1 * float(i % 3)
		_mesh(PlanetPropMeshes.pebble_rock(rock_col, i % 4), rock_mat, _ground_xf(planet, p, a * 1.7, s))
		var rc := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = 0.22 * s / 0.5
		rc.shape = sph
		rc.position = p + Vector3.UP * 0.1
		body.add_child(rc)
	# the cave's own crystals pushing up through the mound
	var teal := PlanetPropMeshes.crystal_material(Color("#3f8f96"), Color("#72cfc4"), 0.9, true, 0.3)
	var lilac := PlanetPropMeshes.crystal_material(Color("#6f5fa8"), Color("#ab96e6"), 0.9, true, 0.3)
	for c in [[Vector3(0.75, 0.25, 0.1), 0.8, 0], [Vector3(-0.8, 0.2, 0.25), 0.7, 1], [Vector3(-0.2, 0.55, 0.85), 0.75, 2]]:
		_mesh(PlanetPropMeshes.crystal_cluster(int(c[2])), null, _ground_xf(planet, c[0], 1.3 * float(c[2]), float(c[1])).translated_local(Vector3(0, (c[0] as Vector3).y / float(c[1]), 0)), [teal, lilac])
	# the fragment itself, stuck in the top
	var amber := PlanetPropMeshes.crystal_material(Color("#b86a3c"), Color("#eea06a"), 1.3, true, 0.45)
	var fxf := _ground_xf(planet, Vector3(0.15, 0.0, 0.35), 0.4, 2.0)
	fxf.origin += fxf.basis.y.normalized() * 0.62
	fxf.basis = fxf.basis * Basis(Vector3(1, 0, 0.4).normalized(), 0.45)
	_mesh(PlanetPropMeshes.crystal_chunk(), amber, fxf)


func _disc(r: float, lift: float, mat: Material, segs: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for j in segs:
		var a0 := TAU * float(j) / float(segs)
		var a1 := TAU * float(j + 1) / float(segs)
		var k0 := 1.0 + 0.08 * sin(a0 * 3.0)
		var k1 := 1.0 + 0.08 * sin(a1 * 3.0)
		st.add_vertex(Vector3(0, lift, 0))
		st.add_vertex(Vector3(cos(a1) * r * k1, lift, sin(a1) * r * k1))
		st.add_vertex(Vector3(cos(a0) * r * k0, lift, sin(a0) * r * k0))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## A local transform on the ground at local offset `p` (the planet curves away under a 1.5 m ring).
func _ground_xf(planet: Planet, p: Vector3, yaw: float, s: float) -> Transform3D:
	var wp := transform * p
	var d := planet.dir_of(wp)
	var sxf := planet.surface_transform(d, -transform.basis.z)
	var local := transform.affine_inverse() * sxf
	local.origin -= local.basis.y * 0.04
	return Transform3D(local.basis * Basis(Vector3.UP, yaw) * Basis().scaled(Vector3.ONE * s), local.origin)


func _mesh(m: Mesh, mat: Material, xf: Transform3D, surf_mats: Array = []) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	if mat != null:
		mi.material_override = mat
	for i in surf_mats.size():
		if i < m.get_surface_count():
			mi.set_surface_override_material(i, surf_mats[i])
	add_child(mi)
	mi.transform = xf
