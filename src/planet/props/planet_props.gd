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
## Contact-shadow blobs collected during a build; see _build_contact_shadows(). Empty on Forward+.
var _blob_dirs: PackedVector3Array = PackedVector3Array()
var _blob_rx: PackedFloat32Array = PackedFloat32Array()
var _blob_rz: PackedFloat32Array = PackedFloat32Array()
## The prop's own +X axis, so a long thin prop gets a long thin pool aimed the way the prop is.
var _blob_axes: PackedVector3Array = PackedVector3Array()
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
	_build_contact_shadows()

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
	# Contact patch: the collider cylinder AND the mesh's own extents, whichever is smaller on each
	# axis, capped by the clearance. See _note_contact_shadow() for why `footprint` alone is wrong.
	var e := _mesh_ground_extents(mesh)
	_note_contact_shadow(dir, footprint * scale,
		minf(minf(footprint, col_radius), e.x) * scale,
		minf(minf(footprint, col_radius), e.y) * scale, b.transform.basis.x)
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
		if shadow:
			var e := _mesh_ground_extents(mesh)
			_note_contact_shadow(dir, footprint * scale, minf(footprint, e.x) * scale,
				minf(footprint, e.y) * scale, n.transform.basis.x)
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
		if shadow:
			var e := _mesh_ground_extents(mesh)
			_note_contact_shadow(dir, footprint * scale, minf(footprint, e.x) * scale,
				minf(footprint, e.y) * scale, n.transform.basis.x)
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

## ============================================================ prop contact shadows (Compatibility)
##
## WHY THIS EXISTS. src/world/environment.gd::_no_cast_shadows switches the sun's shadow pass OFF
## under Compatibility. That is not a stylistic choice: the pass is combined in sRGB-ENCODED space
## on that renderer (C = s2l(l2s(ambient) + l2s(direct))), which is what put the ground 26-63 luma
## codes away from the Forward+ reference, and dropping the pass is the only fix that does not need
## a fitted constant. The trade was accepted with its cost written down, and the cost is that every
## prop lost its contact: the art review of the before/after pair said the hub plaza bench "does
## read as hovering a few centimetres above the tiles", while noting the astronaut does NOT float
## because src/player/blob_shadow.gdshader is still under its boots. So the props get the same blob.
##
## WHAT THIS IS NOT. It does not reproduce a cast shadow and no claim here says otherwise. The same
## review's first complaint — the long raking bars the six lamp posts and the bunting masts throw
## across the whole plaza at h19 — is a projection of geometry away from the prop, and nothing
## drawn at the prop's own base can bring it back. This restores CONTACT only. The raking bars stay
## lost on Compatibility until the encoded-blend bug itself is fixed engine-side.
##
## COST, MEASURED. One MultiMeshInstance3D per planet — +1 draw call for the WHOLE world, against
## the +1 draw call PER PROP a child quad each would have cost — plus 2 triangles per blob. Blobs
## drawn per world: home 39, zorp 26, bolt 32, hub 69, fen 21, grig 35, vela 21, so the worst world
## is +1 draw call and +138 triangles. The buildings and a player-placed decoration are one mesh
## each on top of that; they cannot join a batch that was sealed before they existed. The material
## is unshaded, writes no depth and casts no shadow, so the per-pixel cost is one blend.
## Build-time cost of the whole pass, including the ground sampling in fit_blob(): 3.8 ms on home,
## 4.8 ms on hub, 2.9 ms on grig, once per planet load. Nothing here runs per frame.
##
## THE BUILDING FIGURE HERE ONCE READ "+4 and +1 draw calls, 2 triangles each" WHEN THE TRUE COST
## WAS ZERO (fit_blob() rejected all five buildings outright — the origin bug written up above
## Building._add_contact_shadow()), and then read "+1 draw call and +128 triangles per pool" for
## geometry no camera could see (the shape bug written up above _contact_shadow_patch()). Both are
## fixed and this is the third measurement, taken on pools that were confirmed visible in the same
## build by the shipped-vs-suppressed A/B recorded above _contact_shadow_patch(). Compatibility,
## --stats, two runs of each configuration, all four numbers stable to the digit across runs:
##   hub_buildings --focus=deco_store --dist=12 (two pools in frame)   55 vs 53 draw calls,
##                                                                    331,366 vs 329,766 primitives
##   hub_buildings --focus=town_hall --dist=25 (four pools in frame)  101 vs 97, 379,394 vs 376,194
##   hub_buildings --home --focus=player_home --dist=10 (one pool)     43 vs 42, 249,146 vs 248,346
## That is exactly +1 draw call and +800 triangles per building pool ON SCREEN, so the hub's four
## buildings cost at most +4 / +3,200 and the home planet's habitat +1 / +800, and a pool that is off
## camera costs nothing at all. The triangles are up from the flat quad's 2 because a building's pool
## is a subdivided curved patch (BLOB_PATCH_FLAT / _IN / _OUT); 3,200 triangles against the hub's
## ~376,000 is 0.85 %, they are unshaded, depth-write-off single-blend fragments, and most of them
## are under the building and never shade a pixel. The DRAW CALL count — the number the phone's heat
## budget actually cares about — is +1 per building, which is what the old comment promised and what
## the batch above exists to avoid paying per PROP.
##
## FORWARD+ IS NOT TOUCHED. The gate below is the same `Platform.is_compatibility_renderer()` the
## environment uses. On Forward+ nothing is collected, nothing is built, and — this is the part
## that had to be right — nothing here draws from `rng` or calls `planet.register_prop`, so the
## placement stream is bit-for-bit the sequence it was before. Verified by capture at h13 on all
## seven worlds: home and bolt byte-identical whole-frame, and on hub, home and fen (the three with
## region masks) the GROUND region is byte-identical, max delta 0. The other five worlds differ on
## a few hundred to a few thousand pixels of animated content — NPCs, particles — and the SAME
## build captured twice differs by the same amount in the same places, so that is the scene's own
## frame-to-frame nondeterminism and not this change.

## Contact shadows are only drawn where the real cast shadows are gone.
func _contact_shadows_on() -> bool:
	return Platform.is_compatibility_renderer()

## Two jobs, and they are both "too small to be worth a draw call". As the GATE in
## _note_contact_shadow() it is tested against the prop's registered `footprint`: a prop the
## placement grid did not even keep a quarter-metre clear of is scatter, and the small scatter it
## would cover (grass, flowers) is already MultiMesh'd in its thousands. As the floor on the fitted
## blob it drops a pool the sag fit has shrunk past the point of reading as anything but a smudge —
## dropping it is the right answer there, because the alternative is a blob that clips.
const BLOB_MIN_R := 0.25
## A blob is a FLAT quad and the ground is not flat, so the quad and the ground pull apart away from
## the contact point. Two numbers bound that, and they are the same two the first build used — what
## has changed is that the ground they are measured against is now SAMPLED instead of assumed.
##
##   BLOB_MAX_SAG  the ground RELIEF the quad may span: (highest - lowest) ground sample under it.
##   BLOB_LIFT     the clearance held above the HIGHEST of those samples.
##
## The quad is placed at (highest sample + BLOB_LIFT), so nothing the fit sampled can rise through
## it, and the worst hover — at the lowest sample, which for a round blob on a round planet is the
## rim — is their sum. Hover there is invisible: the rim's alpha is zero (a*a of a smoothstep that
## has just reached 1.0). Poke-through would not be invisible, which is why the lower bound is a
## hard yes/no rather than a tolerance: the moment the ground rises through the quad the depth test
## cuts it along the intersection line and leaves a hard edge with no falloff.
##
## HONEST NOTE ON WHY THIS IS HERE. The art review of the first build reported the hub grass-ring
## patches (0 -> 62 codes across three pixels, peak 75) AS clipping, and asked for exactly this
## measurement. The measurement was built and it says the diagnosis was wrong: casting a ray at
## every one of 512 points per blob against the planet's own trimesh — the same geometry the depth
## buffer holds — found 0 of 69 hub blobs cut by the ground, and a dense analytic sweep of the
## height field agreed. The real cause was size, not sag: see _note_contact_shadow(). This rule is
## kept anyway because it is a genuine invariant a flat quad on a curved noisy planet can violate,
## it is now measured rather than assumed, and it costs 3-5 ms once per planet load. It is not what
## fixed the reported defect and nothing here should claim it was.
##
## What the first build actually got wrong HERE was narrower: it took the sphere-sag identity
## r*r/(2R), solved it for one global r_max = sqrt(2*R*BLOB_MAX_SAG) and applied that single number
## to every blob on the planet — and applied it to the batch only, never to the one-off quads in
## contact_shadow_quad(), so a building's 2.5 x 2.0 m half-extents were bounded by nothing at all.
## On ground that really is a sphere fit_blob() returns the identical answer the closed form did
## (relief r*r/(2R) <= 0.04 at R = 16 gives 1.13 m); on the flat-zone blend in
## Planet._terrain_offset(), where the plaza meets the grass ring, it returns a smaller one, and no
## closed form for a sphere can.
const BLOB_MAX_SAG := 0.04
const BLOB_LIFT := 0.02
## Sag fit sampling. Two rings, because a bank crossing a blob raises the ground in a BAND and 8 rim
## spokes alone straddle it; the inner ring is also the one that would matter for how a poke-through
## READS, since alpha is a*a and is still near full at 0.55r while it is zero at the rim. BLOB_LIFT
## doubles as the margin against relief BETWEEN the samples. The bisection is on the blob's scale
## and 6 steps resolve it to 1/64 of the footprint, well under a pixel of blob edge at any distance
## the game frames a prop from.
const BLOB_FIT_SPOKES := 8
const BLOB_FIT_INNER := 0.55
const BLOB_FIT_ITERS := 6
## Penumbra width in METRES, not as a fraction of the blob. A prop's contact shadow has a soft edge
## whose width is set by the light source, not by how big the prop is, so a 0.3 m bench blob is all
## penumbra and a 1.1 m fountain blob keeps a core. That is the whole reason softness is per-instance
## custom data instead of a uniform: one number here, one batch, correct edge on every footprint.
const BLOB_PENUMBRA := 0.30
## Floor on `softness`, which is the smoothstep width as a FRACTION of the blob radius, so a big
## blob would otherwise get BLOB_PENUMBRA/r -> a thin edge: the 2.5 m half-extent of a default
## building works out at 0.12, and at the 22 m review distance that falloff spans about two pixels
## and reads as a DRAWN LINE around the building rather than as shade. It is the same complaint the
## sag rule above exists to prevent, arriving through the alpha ramp instead of through the depth
## test, so it gets the same answer: never let the edge be less than ~a quarter of the blob. This
## is an authored art floor, not a derived quantity — it is the one number in this feature that a
## measurement did not set, and it only ever makes a blob SOFTER, never darker or larger.
const BLOB_SOFT_MIN := 0.3
## PEAK OCCLUSION, and the reason the blob is BLACK rather than the planet's ground_shadow_color.
## The first build tinted it with data.ground_shadow_color and it was wrong on sight: over the hub's
## warm tan tiles a mid-value teal at 26% reads as a green STAIN, not as shade, because a blend_mix
## toward a mid value barely darkens and drags the hue instead. A contact shadow is not a colour
## laid on the ground, it is light that did not arrive, and the operator for that is multiplicative.
## Mixing toward black IS that operator: out = ground * (1 - ALPHA), hue-preserving by construction
## on any world, so nothing here has to know what colour the ground under a given prop is. The one
## authored number left is the peak, and it is deliberately low — the user's standing note is
## "shadows look too dark and leave notably dark places and lines", so trading the hover for a hard
## dark disc would trade one complaint for another. 0.26 against the player blob's 0.5 (which is a
## navy, not a black): the astronaut is the thing you look at, a bench is not.
## What this does NOT reproduce is the sky-ambient tint the Forward+ shadow picks up; that colour
## comes from the light that DOES arrive and is not available to an unlit blend. Measured cost is
## in the round report.
## KNOWN DIVERGENCE, WRITTEN DOWN BECAUSE NOBODY HAD: this alpha is constant over the clock. At
## 02:00 the Forward+ reference has essentially no cast shadow at all (the moon's is off under
## Compatibility and weak under Forward+), yet the blobs are still at full 0.26. Captured at hub
## h02 before/after/Forward+ by the art review: the pools are soft and read fine — they land as
## ground contact rather than as sun shadow, which is what a contact term is — so this is recorded
## as a divergence and not a defect. Anything that faded it with the clock would need a curve
## fitted to the sun, and this project has already reverted three of those.
const BLOB_ALPHA := 0.26

static var _blob_shader: Shader
static var _blob_mesh: QuadMesh

## Shared 2x2 quad in the XY plane. Sized 2x2 so a basis scaled by r gives a blob of RADIUS r.
static func _blob_quad() -> QuadMesh:
	if _blob_mesh == null:
		_blob_mesh = QuadMesh.new()
		_blob_mesh.size = Vector2(2.0, 2.0)
	return _blob_mesh

## Batched material. `instanced = 1.0` is what makes blob_shadow.gdshader read softness from
## INSTANCE_CUSTOM.x; see the comment block at the top of that file. The SHADER is shared (one
## compile); a fresh material per planet costs nothing and keeps showcase/planets.tscn — several
## live worlds at once — from sharing mutable shader state.
static func contact_shadow_material() -> ShaderMaterial:
	if _blob_shader == null:
		_blob_shader = load("res://src/player/blob_shadow.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _blob_shader
	m.set_shader_parameter("instanced", 1.0)
	m.set_shader_parameter("strength", 1.0)
	m.set_shader_parameter("color", Color(0.0, 0.0, 0.0, BLOB_ALPHA))
	return m

## MEASURED SAG FIT, and the placement that goes with it. Returns
##   .x  the scale in (0, 1] to apply to a candidate blob of world half-extents `rx`/`rz`, or 0.0
##       when even a BLOB_MIN_R blob cannot meet the rule at BLOB_MAX_SAG — on ground that rough the
##       honest answer is NO blob, not a clipped one;
##   .y  the height above `o`, along `n`, to put the quad at, which is BLOB_LIFT above the highest
##       ground sample under the fitted blob and therefore never less than BLOB_LIFT.
## `o` is the ground contact point in world space, `n` the ground normal there, `ax`/`az` the blob's
## two in-plane axes (unit). A null `ground` means flat ground — the decoration and building
## galleries — where there is nothing to fit, so it returns (1.0, BLOB_LIFT) unchanged.
##
## Cost is build-time only; nothing here runs per frame. The common case — a prop whose blob already
## fits — is one _blob_relief() call, 16 height samples, and returns 1.0; only a blob straddling a
## bank or a hill pays the six bisection steps on top.
static func fit_blob(ground: Planet, o: Vector3, n: Vector3, ax: Vector3, az: Vector3, rx: float, rz: float,
		base_dev: float = 0.0) -> Vector2:
	if ground == null:
		return Vector2(1.0, BLOB_LIFT)
	var d := _blob_relief(ground, o, n, ax, az, rx, rz, base_dev)
	if d.y - d.x <= BLOB_MAX_SAG:
		return Vector2(1.0, d.y + BLOB_LIFT)
	# Smallest scale worth keeping: the one that lands the blob's SHORT axis on BLOB_MIN_R.
	var k_min := BLOB_MIN_R / maxf(minf(rx, rz), 0.0001)
	if k_min >= 1.0:
		return Vector2.ZERO
	d = _blob_relief(ground, o, n, ax, az, rx * k_min, rz * k_min, base_dev)
	if d.y - d.x > BLOB_MAX_SAG:
		return Vector2.ZERO
	var lo := k_min          # known to fit
	var hi := 1.0            # known not to
	var lift := d.y + BLOB_LIFT
	for _i in BLOB_FIT_ITERS:
		var mid := 0.5 * (lo + hi)
		var m := _blob_relief(ground, o, n, ax, az, rx * mid, rz * mid, base_dev)
		if m.y - m.x <= BLOB_MAX_SAG:
			lo = mid
			lift = m.y + BLOB_LIFT
		else:
			hi = mid
	return Vector2(lo, lift)

## (lowest, highest) ground sample under the candidate blob, as signed heights above the tangent
## plane through `o` along `n`. The contact point itself is height 0 by construction and is included
## in both, so a blob on flat ground gets exactly (0, 0) and the placement collapses to BLOB_LIFT —
## the behaviour every prop on a flat plaza had before the fit existed. The half-spoke offset on the
## inner ring staggers the two rings so sixteen samples cover sixteen bearings rather than eight.
static func _blob_relief(ground: Planet, o: Vector3, n: Vector3, ax: Vector3, az: Vector3, rx: float, rz: float,
		base_dev: float = 0.0) -> Vector2:
	var lo := base_dev
	var hi := base_dev
	for ring in 2:
		var k := 1.0 if ring == 0 else BLOB_FIT_INNER
		for i in BLOB_FIT_SPOKES:
			var a := TAU * (float(i) + 0.5 * float(ring)) / float(BLOB_FIT_SPOKES)
			var p := o + ax * (cos(a) * rx * k) + az * (sin(a) * rz * k)
			var g := ground.surface_point(p - ground.global_position)
			var dev := (g - o).dot(n)
			lo = minf(lo, dev)
			hi = maxf(hi, dev)
	return Vector2(lo, hi)

## The Planet whose surface `node` stands on, or null. Ancestors first, because every prop, building
## and decoration is parented under the planet it was placed on; the "planet" group is the fallback
## for a node re-parented elsewhere, and it picks the NEAREST planet because showcase/planets.tscn
## has several live worlds in one tree at once.
static func planet_under(node: Node3D) -> Planet:
	var a := node.get_parent()
	while a != null:
		if a is Planet:
			return a
		a = a.get_parent()
	var best: Planet = null
	var best_d := INF
	for p in node.get_tree().get_nodes_in_group("planet"):
		if p is Planet:
			var d: float = node.global_position.distance_squared_to((p as Planet).global_position)
			if d < best_d:
				best_d = d
				best = p
	return best

## ONE-OFF contact shadow for a prop that cannot join a planet's batch. The hub buildings
## (src/hub/building_base.gd) and the placeable decorations (src/decorations/deco_item.gd) are each
## their own scene, added and removed at runtime by the DecorationManager long after PlanetProps has
## finished, so there is no batch to append to; they get a child quad instead. That IS one draw call
## and two triangles each, which is exactly what the batch above exists to avoid — it is affordable
## here only because the counts are small (single-digit buildings per world) and because a
## decoration the player placed is a thing they are looking at. If a garden ever grows to hundreds
## of decorations this is the first thing that should become a batch.
##
## `rx`/`rz` are the half-extents of the prop's ground rectangle IN THE PARENT'S LOCAL UNITS, so a
## wide building gets an ellipse rather than a disc — the shader's radial falloff is in UV space, so
## a non-uniform scale is free. Returns null on Forward+ (real cast shadows are still on there) and
## for anything too small to read. The caller parents it at its own origin, which is the ground
## contact point by convention.
##
## `base_xf` is the WORLD transform of that contact point: origin ON THE GROUND, basis.y the up
## axis, basis.x / basis.z the two axes rx and rz are measured along. It is what feeds the same
## measured sag fit the batch uses — the first build of this feature applied the cap to the batch
## and NOT here, which left a default building's 2.5 x 2.0 m quad bounded by nothing at all. It
## must be the transform the prop ENDS UP with: both callers place their node after add_child(), so
## both defer this past _ready(); see the notes there. Pass Transform3D.IDENTITY with a null
## `ground` only where the ground really is flat (the galleries); the fit is then a no-op.
## `base_xf.basis` may carry the parent's scale: its column LENGTHS convert rx/rz to world metres
## for the fit, and the scale that comes back is dimensionless, so it applies straight to the local
## half-extents.
##
## "ORIGIN ON THE GROUND" IS LOAD-BEARING AND WAS SILENTLY VIOLATED. fit_blob() measures ground
## relief as signed heights above this origin, and _blob_relief() used to SEED its running (lo, hi)
## at (0, 0) on the assumption that the contact point is height 0 by construction — true for the
## batch, where `o` is literally `planet.surface_point(dir)`. building_base.gd used to pass the
## building's local y = 0, which attach_to_planet() has already sunk `ground_sink` (0.16 m, an
## @export any subclass may change) below the surface, so every one of the sixteen samples came back
## at about +0.16, the span blew past BLOB_MAX_SAG, and — the offset being a constant bias that does
## not shrink when the blob shrinks — the k_min probe failed too. fit_blob() returned ZERO and every
## building on every world got no pool at all, with nothing printed. Measured before the fix, on the
## real hub: `lo 0.0000 hi 0.1795`, `hi 0.1595` x3, `hi 0.1395` — never a fit.
##
## BOTH ENDS OF THAT ARE FIXED, and it took both. The caller (Building._add_contact_shadow) now
## projects its footprint centre onto the planet and hands over the real surface point, which is
## what the contract always asked for. And the ASSUMPTION ITSELF IS GONE from the fit: fit_blob()
## and _blob_relief() take a `base_dev` seed, and the line above measures it here instead of
## assuming it. That matters because the assumption failed for a caller other than the buildings
## too — instrumented on tests/director/critic_deco_stress.json, a handful of placed decorations
## come out 0.55-0.65 m above the height field (an item set down on a bank or on top of another
## item), and every one of them was silently getting no pool for exactly the same reason. They fit
## now.
##
## THE BATCH IS BYTE-IDENTICAL BY CONSTRUCTION, NOT BY MEASUREMENT, and that is why `base_dev` is a
## parameter with a 0.0 default rather than a sample taken inside _blob_relief(). _build_contact_
## shadows() does not pass it, so its arithmetic is the literal 0.0 it always was. Sampling inside
## would instead re-project `o` — already `planet.surface_point(dir)` — through a re-normalised
## direction and come back a float ulp or two off zero, moving every batched blob's fitted lift by
## ~1e-7 on a path this change has to keep stable.
##
## Note for anyone reading this while looking at a building: the caller-side half of the fix is,
## on its own, INERT for a building's shipped pixels. A building takes the `curved` branch, which
## returns before fit_blob() is reached, and the curved patch measures the ground at every one of
## its own vertices, so it lands in the same place either way. It is kept because it is the contract,
## and because the flat path is one `curved = false` away.
##
## `curved` picks the CURVED PATCH instead of a flat quad, and only the buildings ask for it. A flat
## quad on a sphere can only be as big as BLOB_MAX_SAG allows — on the 21 m hub that is a 1.30 m
## half-extent (sqrt(2*R*SAG)), which is fine for a 0.7 m bench and useless for a building, because
## a 2.56 x 2.10 m pool centred under a 5.1 x 4.0 m shop is entirely HIDDEN BY THE SHOP. Measured:
## with the origin bug fixed and the flat path kept, all four hub buildings fitted at scale 0.457 and
## rendered no visible pool whatsoever at h6.5 / h13 / h19.3. Simply letting the flat quad run at full
## size is not the answer either — it would hover 0.155 m off the tiles right where the wall meets the
## ground (d^2/2R at d = 2.55), which is a worse version of the float this feature exists to remove.
## So a building's pool is a subdivided patch whose every vertex is placed BLOB_LIFT above its own
## ground sample: it follows the flattened disc, the disc's blend into the grass ring and any bank
## under it, poke-through is impossible by construction rather than by a size cap, and no sag fit is
## needed. Props and decorations keep the flat quad — theirs already fit at scale 1.0.
static func contact_shadow_quad(rx: float, rz: float, ground: Planet = null,
		base_xf: Transform3D = Transform3D.IDENTITY, curved: bool = false) -> MeshInstance3D:
	if not Platform.is_compatibility_renderer():
		return null
	var sx: float = maxf(base_xf.basis.x.length(), 0.0001)
	var sz: float = maxf(base_xf.basis.z.length(), 0.0001)
	if curved and ground != null:
		if minf(rx * sx, rz * sz) < BLOB_MIN_R:
			return null
		return _contact_shadow_patch(rx, rz, ground, base_xf, sx, sz)
	# rx/rz arrive as the prop's CONTACT half-extents; the visible pool is that plus the soft ring.
	# See _note_contact_shadow() for why a pool the size of the base alone is invisible.
	rx += BLOB_PENUMBRA / sx
	rz += BLOB_PENUMBRA / sz
	# The contact point's OWN height above the ground, which is the seed the relief fit measures
	# every other sample against. Zero for a caller that honours the "origin on the ground" contract
	# above; the reason it is measured rather than assumed is written up there too.
	var up := base_xf.basis.y.normalized()
	var dev := 0.0
	if ground != null:
		dev = (ground.surface_point(base_xf.origin - ground.global_position) - base_xf.origin).dot(up)
	var fit := fit_blob(ground, base_xf.origin, up,
		base_xf.basis.x / sx, base_xf.basis.z / sz, rx * sx, rz * sz, dev)
	if fit.x <= 0.0:
		return null
	rx *= fit.x
	rz *= fit.x
	# fit.y is in world metres; the quad's own y is in the parent's local units.
	var lift: float = fit.y / maxf(base_xf.basis.y.length(), 0.0001)
	if minf(rx * sx, rz * sz) < BLOB_MIN_R:
		return null
	var mi := MeshInstance3D.new()
	mi.name = "ContactShadow"
	mi.mesh = _blob_quad()
	var m := contact_shadow_material()
	# Not batched: one material per prop, so softness is a uniform and INSTANCE_CUSTOM stays unread.
	# Softness is a fraction of the blob, so it is measured on the WORLD half-extents.
	m.set_shader_parameter("instanced", 0.0)
	m.set_shader_parameter("softness", clampf(BLOB_PENUMBRA / minf(rx * sx, rz * sz), BLOB_SOFT_MIN, 1.0))
	mi.material_override = m
	# QuadMesh lies in XY facing +Z; -90 deg about X lays it flat with its normal along +Y.
	mi.transform = Transform3D(
		Basis(Vector3(rx, 0.0, 0.0), Vector3(0.0, 0.0, -rz), Vector3(0.0, 1.0, 0.0)),
		Vector3(0.0, lift, 0.0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Subdivision of a curved contact patch, per HALF axis. Three zones, because the patch has three
## jobs across its width and they want very different sample spacings.
##
## BLOB_PATCH_FLAT covers centre -> (footprint - ring), where alpha is ZERO and the only thing the
## subdivision has to buy is following the ground: the patch is a chord between its samples, so
## between two samples h metres apart it dips h*h/(8R) below a sphere of radius R and that dip has to
## stay inside BLOB_LIFT (0.02 m). The widest flat zone in the game is the event space's 2.96 m half,
## so h = 1.48 m and the dip is 1.48^2/(8*21.2) = 0.013 m. Two segments is enough and one is not.
##
## BLOB_PATCH_IN and BLOB_PATCH_OUT carry the two halves of the alpha BAND (see _contact_shadow_patch
## for why it is a band and not a filled disc), and they have to resolve a RAMP, not a surface. The
## ramp is baked per vertex, so it interpolates linearly across a cell and too few cells show as
## facets. The narrowest ring in the game is the home habitat's 1.02 m: four segments put a vertex
## every 0.26 m, which at the 8 m review distance is under two pixels of ramp per cell. Three was
## visibly banded on the h13 capture of the town hall, where the ring is 1.58 m and the camera close.
##
## Cost: (2*(2+4+4)+1)^2 = 441 vertices and 2*(2*10)^2 = 800 triangles per building, built once at
## load and drawn in the ONE draw call the pool already cost. The interior of the grid is alpha 0 and
## is under the building anyway, so it is not overdraw anybody pays for. See the cost paragraph at
## the top of this section for the measured draw-call and primitive numbers.
const BLOB_PATCH_FLAT := 2
const BLOB_PATCH_IN := 4
const BLOB_PATCH_OUT := 4

## A contact pool that FOLLOWS the ground instead of hovering over it — see the `curved` paragraph
## on contact_shadow_quad() for why a building cannot use the flat quad. Every grid vertex is
## dropped onto the planet with the same radial projection _blob_relief() samples with, then raised
## BLOB_LIFT along the local up axis, so the ground can never rise through the patch and there is
## no sag rule left to fail. Measured on showcase/hub_buildings.tscn, every vertex of all four hub
## patches sits between 0.020 and 0.370 m above the height field it was built from.
##
## Returned with an IDENTITY basis and a ZERO origin: the vertices already carry the full offset
## from `base_xf.origin`, expressed in the PARENT's local units (world metres divided by the
## parent's own column scales), so the caller places the node at the local coordinates of
## `base_xf.origin` and nothing else. That is why Building._add_contact_shadow() adds `q.position.y`
## to the ground's local y rather than overwriting it — the flat quad carries its lift there, this
## one carries zero.
##
## `cx`/`cz` are the half-extents of the GROUND CONTACT RECTANGLE — for a building, the rectangle its
## own geometry actually stands in, measured off its vertices by Building._ground_contact_rect().
##
## ======================= WHY THIS IS A BAND ROUND A RECTANGLE, NOT A FILLED ELLIPSE ==============
## The build before this one made this patch a filled ellipse — r = patch / (1 - BLOB_SOFT_MIN), the
## shader's radial-in-UV falloff, core semi-axes landing on the footprint — and an art review found
## the pools INVISIBLE on every building, then proved it: with the material forced to opaque red the
## deco store's 7.9 x 6.1 m disc showed a 2 px sliver, the town hall's 8.0 m disc showed nothing at
## all, and a shipped-vs-suppressed A/B at nine camera/hour combinations moved zero ground pixels.
## Three separate faults, all of them about SHAPE rather than size, and all three are fixed here.
##
## 1. THE PATCH WAS SIZED OFF THE COLLIDER, WHICH IS SMALLER THAN THE BUILDING AND NOT CONCENTRIC
##    WITH IT. That half is fixed at the call site; the measurements are in the block above
##    Building._ground_contact_rect(). Short version: the plinths, aprons and steps that actually
##    meet the tiles stick out past `_primary_footprint()` by 0.6-2.5 m and sit up to 1.7 m off its
##    centre, so the old ellipse had its whole soft ring INSIDE the building on the deep side.
##
## 2. AN ELLIPSE THROUGH A RECTANGLE'S SIDES MISSES ITS CORNERS COMPLETELY. With the core ellipse
##    inscribed in the footprint, a point at the footprint's CORNER sits at UV radius
##    sqrt(2) * (1 - soft) = 0.99 of the way to the rim, so alpha there is (1 - smoothstep(0.7, 1,
##    0.99))^2 = 0.001 % — nothing. A rectangular shop would have had a pool at the middle of each
##    wall and none at the four corners it is most obviously standing on. Growing the ellipse until
##    it circumscribes the rectangle instead throws the mid-side ring out to 1.41 * patch, which on
##    the event space is 5.9 m of darkened plaza on a side with nothing standing on it.
##
## 3. A FILLED CORE STAINS ANY DECK THE BUILDING DOES NOT COVER. Two of the five buildings stand on
##    a flat deck that is level with the plaza — the event space's 8.1 x 9.4 m dance floor and the
##    town hall's stone plinth — and a pool at full BLOB_ALPHA over its whole footprint paints that
##    deck, which is lit ground, a flat 26 % darker. Captured at h19.3 on the event space and it is
##    exactly the "shadows leave notably dark places" note the user has standing.
##
## So the field is the DISTANCE TO THE FOOTPRINT RECTANGLE'S EDGE, with rounded corners, and alpha
## peaks ON that edge and falls to zero over one ring width in BOTH directions. That is what a
## contact shadow is: the ground is darkest where the building touches it. Inwards the falloff is
## invisible on a solid building (the mass is standing on it) and is exactly what saves the two
## decks; outwards it is the pool the plaza sees. Both halves are one ring wide, so the band hugs
## the building on all four sides and round the corners at one constant width.
##
## It costs no shader change and no per-frame work. `blob_shadow.gdshader` computes its ramp from
## `length(UV - 0.5) * 2`, and NOTHING says that has to be the geometric radius. Each vertex is given
## the UV (0.5 + 0.5 * r, 0.5), so that expression returns exactly `r`, and `r` is written as
## (1 - soft) + soft * t with t the normalised distance from the footprint EDGE. The shader then maps
## t = 0 (on the edge) to full alpha and t = 1 (a ring width away, either side) to zero, with its own
## smoothstep-squared in between, unchanged. Putting every UV on the v = 0.5 line with u >= 0.5 is
## what makes this exact rather than approximate: `length` of a linearly interpolated UV is not the
## interpolation of the lengths in general, but on that line it is u - 0.5, which is linear. It is
## also why the two ramps need their own segment counts — the falloff is piecewise linear in the
## vertices now instead of per-fragment radial.
##
## RING WIDTH. One width all the way round, from the same BLOB_SOFT_MIN the ellipse used, applied to
## the SHORT half-extent so a long building does not get a wider skirt on its long side than its
## short one: ring = patch_min * soft / (1 - soft) = 0.43 * patch_min, floored at BLOB_PENUMBRA so a
## small building can never end up tighter than a prop. Measured: home habitat 1.02 m, Suit-Up
## 1.11 m, deco store 1.28 m, town hall 1.58 m, event space 1.73 m. That is the right direction for
## the user's standing note — penumbra width scales with the occluder, so the biggest thing on the
## plaza gets the softest edge, and the peak stays at the props' own BLOB_ALPHA rather than going
## darker.
static func _contact_shadow_patch(cx: float, cz: float, ground: Planet, base_xf: Transform3D,
		sx: float, sz: float) -> MeshInstance3D:
	var soft := BLOB_SOFT_MIN
	# Ring width in the PARENT's local units, like cx/cz; sx/sz turn it into metres for the floor.
	var ring: float = maxf(minf(cx * sx, cz * sz) * soft / (1.0 - soft), BLOB_PENUMBRA)
	var ring_x: float = ring / sx
	var ring_z: float = ring / sz
	var sy: float = maxf(base_xf.basis.y.length(), 0.0001)
	var ax := base_xf.basis.x / sx
	var up := base_xf.basis.y / sy
	var az := base_xf.basis.z / sz
	var o := base_xf.origin
	# Graded coordinate table per axis: a coarse flat interior, then the two ramps. Built per axis so
	# the two footprint half-extents can differ while the band keeps one width.
	var col := _patch_coords(cx, ring_x)
	var row := _patch_coords(cz, ring_z)
	var n := col.size()
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for j in n:
		for i in n:
			var x: float = col[i]
			var z: float = row[j]
			var p := o + ax * (x * sx) + az * (z * sz)
			var g := ground.surface_point(p - ground.global_position)
			verts.append(Vector3(x, ((g - o).dot(up) + BLOB_LIFT) / sy, z))
			# Distance from the footprint rectangle's EDGE, in metres. Outside: the straight-line
			# distance to the rectangle, which rounds the corners. Inside: the distance to the
			# nearest side. Zero exactly on the edge, which is where the band peaks.
			var ex: float = maxf(absf(x) - cx, 0.0) * sx
			var ez: float = maxf(absf(z) - cz, 0.0) * sz
			var d: float = sqrt(ex * ex + ez * ez)
			if d <= 0.0:
				d = minf((cx - absf(x)) * sx, (cz - absf(z)) * sz)
			var t: float = clampf(d / ring, 0.0, 1.0)
			uvs.append(Vector2(0.5 + 0.5 * ((1.0 - soft) + soft * t), 0.5))
	for j in n - 1:
		for i in n - 1:
			var a := j * n + i
			idx.append_array([a, a + n, a + 1, a + 1, a + n, a + n + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "ContactShadow"
	mi.mesh = mesh
	var m := contact_shadow_material()
	# Not batched: softness is a uniform here. It is no longer a fraction of a radius — the UVs above
	# are written so that the shader's own `1 - smoothstep(1 - soft, 1, r)` reads the baked ramp
	# parameter directly — but it still has to MATCH the number they were written against.
	m.set_shader_parameter("instanced", 0.0)
	m.set_shader_parameter("softness", soft)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Sample coordinates along one axis of a contact patch, from -(half + ring) to +(half + ring),
## graded into the three zones the band needs. Symmetric, and it always lands a vertex exactly on the
## footprint edge (index +/- (BLOB_PATCH_FLAT + BLOB_PATCH_IN)), which is what keeps the peak of the
## band square with the building instead of stepping across it. `half - ring` clamps at zero for a
## building small enough that the inward ramp reaches its centre.
static func _patch_coords(half: float, ring: float) -> PackedFloat32Array:
	var inner: float = maxf(half - ring, 0.0)
	var out := PackedFloat32Array()
	var n := BLOB_PATCH_FLAT + BLOB_PATCH_IN + BLOB_PATCH_OUT
	for k in range(-n, n + 1):
		var a := absf(float(k))
		var d := 0.0
		if a <= float(BLOB_PATCH_FLAT):
			d = inner * a / float(BLOB_PATCH_FLAT)
		elif a <= float(BLOB_PATCH_FLAT + BLOB_PATCH_IN):
			d = inner + (half - inner) * (a - float(BLOB_PATCH_FLAT)) / float(BLOB_PATCH_IN)
		else:
			d = half + ring * (a - float(BLOB_PATCH_FLAT + BLOB_PATCH_IN)) / float(BLOB_PATCH_OUT)
		out.append(d if k >= 0 else -d)
	return out

## Half-extents of a prop's own geometry on the ground, from its mesh, in the mesh's own units and
## its own axes: (x, z). Per axis and not a single radius, because a bench is 1.4 m long and 0.5 m
## deep and a disc that covers it also covers a metre of lit tile either side of it.
static func _mesh_ground_extents(mesh: Mesh) -> Vector2:
	var ab := mesh.get_aabb()
	return Vector2(maxf(absf(ab.position.x), absf(ab.end.x)), maxf(absf(ab.position.z), absf(ab.end.z)))

## Called by the three spawners with the CONTACT radius of the prop they just placed. Collect only;
## the batch is built once, after the biome has finished placing.
##
## THE RADIUS IS NOT THE `footprint` THE PROP REGISTERED, and the first build of this feature made
## exactly that mistake. `footprint` is a CLEARANCE: Planet.register_prop() uses it to keep the next
## placement away, so it is deliberately larger than the prop and, for anything tall and thin, very
## much larger. The hub's bunting masts are the extreme case — footprint 1.90 m around a pole whose
## collider is 0.10 m — and a 3.8 m wide pool under a 20 cm pole is not a contact shadow, it is a
## dark patch on the grass with no visible owner. That is what an art review found on the hub grass
## ring and reported as clipping (0 -> 62 codes across three pixels, peak 75); the geometry turned
## out to be fine, and a ray cast against the planet's own trimesh at 512 points per blob confirmed
## that not one blob was cut by the ground. The blob was simply far too big for its prop, and the
## hard edge was the ground's own relief occluding a huge quad at a grazing angle.
##
## So the size is MEASURED off the prop instead, from whichever of the two descriptions of it is
## real: `col_radius` for a blocking prop (that cylinder is the ground the prop stands on, authored
## per prop and already trusted by physics) AND the mesh's own XZ half-extents, whichever is smaller
## on each axis, capped by `footprint`, which stays an upper bound. Measured on the hub plaza:
## bunting 1.90 -> 0.10, lamp post 0.40 -> 0.16, bench 0.90 -> 0.70 x 0.25, fountain 2.20 -> 2.00,
## potted trees 1.07-1.38 -> 0.32-0.41.
##
## PER AXIS, and that is what closed the noon regression the first build caused. A bench is 1.4 m
## long and 0.5 m deep; a disc big enough to cover it also covers a metre of LIT tile either side,
## and at 13:00 the Forward+ shadow is short and tight under the bench, so every one of those
## pixels is a 40-code error against the reference. Measured on showcase/planet_hub.tscn at 13:00,
## ground region against the Forward+ capture: MAE 4.43 with no blobs at all, 5.89 with the round-1
## disc, 4.81 with this ellipse; p95 13.0 / 50.0 / 22.0. The ellipse is aimed down the PROP's own
## X axis (see _build_contact_shadows), which costs one more PackedVector3Array at build time and
## nothing at all per frame.
##
## THE BLOB IS THAT CONTACT PATCH PLUS ONE BLOB_PENUMBRA, and it has to be: a pool exactly the size
## of the prop's base is hidden UNDER the prop and does nothing. Sizing the potted trees at their
## collider alone was captured and looked at — the pot covers its own pool completely and the tree
## reads exactly as it did with no blob at all. The ring that reads as contact is the soft edge, so
## the blob is the core plus the soft edge, and the width of that edge is already a measured number
## with a reason attached (BLOB_PENUMBRA, below). No new constant. Same construction for the
## one-off quads in contact_shadow_quad(), which take contact half-extents and add the same ring.
##
## `footprint` is still the GATE — a prop too small to have been given clearance is too small to be
## worth a draw — but it no longer sets the size.
##
## AND THE ORDER OF THOSE TWO LINES BELOW MATTERS, because a round-1 report got it backwards and
## claimed the hub's ten lamp posts and three bunting masts end up with NO pool at all, their
## 0.16 m and 0.10 m contact patches falling under BLOB_MIN_R. They do not. BLOB_PENUMBRA (0.30 m)
## is added HERE, when the blob is collected, and _build_contact_shadows() only tests
## `minf(rx, rz) < BLOB_MIN_R` afterwards, on the summed radius. All thirteen are kept — instrumented
## on showcase/planet_hub.tscn, the 69 batched blobs include rx 0.460 ten times (lamp posts) and
## rx 0.400 three times (masts), both comfortably over the 0.25 m floor. Nothing needs fixing; do not
## "restore" a pool that was never missing.
func _note_contact_shadow(dir: Vector3, footprint: float, cx: float, cz: float, axis: Vector3) -> void:
	if not _contact_shadows_on() or footprint < BLOB_MIN_R:
		return
	_blob_dirs.append(dir)
	_blob_rx.append(cx + BLOB_PENUMBRA)
	_blob_rz.append(cz + BLOB_PENUMBRA)
	_blob_axes.append(axis)

## One MultiMesh for every prop blob on the planet.
func _build_contact_shadows() -> void:
	if _blob_dirs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	# Same WEB/COMPATIBILITY reason as _multimesh() above: with use_colors off, Compatibility feeds
	# COLOR as (0,0,0,0). This shader never reads COLOR, but the attribute is still bound, and
	# leaving it unsupplied is the configuration that black-silhouetted the grass. White = no-op.
	mm.use_colors = true
	mm.mesh = _blob_quad()
	# Two passes: fit every candidate first, because a blob the fit rejects must not take an instance
	# slot. instance_count is set once and MultiMesh has no "skip this one" — a leftover slot would
	# draw the identity quad at the planet's centre.
	var xfs: Array[Transform3D] = []
	var softs: PackedFloat32Array = PackedFloat32Array()
	for i in _blob_dirs.size():
		var dir: Vector3 = _blob_dirs[i]
		# Lie in the local ground plane, not the sphere's tangent plane, so a blob on a slope stays
		# in contact with the slope. ground_normal() samples the height field either side of dir.
		var n := planet.ground_normal(dir)
		# Aim the ellipse down the PROP's own X axis, projected into that plane, so a bench's pool
		# lies along the bench. Nothing here may touch `rng`: the placement stream has to stay
		# identical to the Forward+ build, which never runs this function at all.
		var tx: Vector3 = _blob_axes[i]
		tx = tx - n * tx.dot(n)
		if tx.length_squared() < 1e-6:
			tx = n.cross(Vector3.UP)
			if tx.length_squared() < 1e-6:
				tx = n.cross(Vector3.RIGHT)
		tx = tx.normalized()
		var tz := n.cross(tx)
		var o := planet.surface_point(dir)
		var fit := fit_blob(planet, o, n, tx, tz, _blob_rx[i], _blob_rz[i])
		var rx: float = _blob_rx[i] * fit.x
		var rz: float = _blob_rz[i] * fit.x
		if minf(rx, rz) < BLOB_MIN_R:
			continue
		xfs.append(Transform3D(Basis(tx * rx, tz * rz, n), o + n * fit.y))
		softs.append(clampf(BLOB_PENUMBRA / minf(rx, rz), BLOB_SOFT_MIN, 1.0))
	if xfs.is_empty():
		return
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, Color.WHITE)
		mm.set_instance_custom_data(i, Color(softs[i], 0.0, 0.0, 0.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ContactShadows"
	mmi.multimesh = mm
	mmi.material_override = contact_shadow_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)

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
