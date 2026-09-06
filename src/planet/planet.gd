class_name Planet
extends StaticBody3D
## A tiny walkable planet. Center = this node's global_position.
## THIS FILE IS A CONTRACT: every public method below stays consistent with the collision shape.
##
## Coordinate conventions:
##  - "dir" = unit vector from planet center (world space, planet is never rotated/scaled).
##  - height_at(dir) returns the distance from center to the ground surface along dir.
##  - surface_point(dir) = global_position + dir * height_at(dir)
##
## Generation (planet builder): icosphere displaced by seeded layered noise (rolling hills + detail),
## soft craters with rims, biome features (violet river channels), and flattened discs at the spawn,
## rocket pad and building spots. height_at() IS the displacement function, so the mesh, the trimesh
## collision, props, decorations and NPC feet all agree to the millimeter.
## A transparent water shell sits at radius + the (radius-scaled) water level (layer 6, no collision).
## Props and collectibles are scattered by PlanetProps with a reserved-zone / footprint system.

## Fixed hub building directions (unit vectors), spread 35-45 degrees around the hub spawn.
## ANGULAR, so they close up in metres as the hub shrinks. At R=21 the tightest pair (deco store to
## event space, 36.7 deg) is 13.4 m apart and the tightest disc pair (spawn plaza to town hall,
## 35 deg) is 12.8 m — which is why HUB_BUILDING_FLAT_RADIUS came down to 6 m below. Re-check both
## against the flat radii before moving the hub's radius again.
const HUB_BUILDING_DIRS := {
	"town_hall": Vector3(0.0, 1.0, 0.0),
	"deco_store": Vector3(-0.533, 0.468, 0.704),
	"clothes_store": Vector3(0.533, 0.468, 0.704),
	"event_space": Vector3(0.0, 0.258, 0.967),
}
## Player home spot on the home planet, 45 deg from the spawn. Was 32 deg, which was 8.9 m at the old
## R=16 and would have been 6.7 m at R=12 — closer than the spawn disc (3 m) plus the house plot (5 m)
## put together, so the two flattened discs would have merged into one pancake and the house would
## have stood in the middle of the spawn clearing. Angular, so a home-size upgrade only pushes it
## further out (9.4 m at R=12, 12.6 m at R=16), never closer.
const PLAYER_HOME_DIR := Vector3(-0.532, 0.707, 0.466)

## Flattened / reserved disc radii, in METRES. These are sizes of real things (a rocket pad, a house
## plot, a plaza) so they deliberately do NOT scale with the planet — see PlanetData's header.
const SPAWN_FLAT_RADIUS := 3.0
const HUB_SPAWN_FLAT_RADIUS := 7.0
const PAD_FLAT_RADIUS := 4.0
## 7.0 before R2.11. The four hub buildings reach ~4.1 m from their centres (the town hall's notice
## board and lantern are the outliers), so 6 m still leaves a ~2 m apron of level ground all round,
## and it is what lets the hub come down to R=21 without the building plots overlapping each other.
const HUB_BUILDING_FLAT_RADIUS := 6.0
## 6.0 before R2.11; the player's house reaches ~3.25 m from its centre.
const HOME_BUILDING_FLAT_RADIUS := 5.0
const FLAT_BLEND_METERS := 1.7
const RIVER_HALF_WIDTH := 0.17
## Metres deep at the reference radius (see PlanetData), scaled by `_vscale` like every other bit of
## relief. 0.52 before R2.11, which was authored against Zorp's then-radius of 13 rather than the
## reference 16 — at the new radius that left the channels shallower than the water shell they hold,
## so every stream brimmed over and the shore rule refused 9.3% of the planet. 0.52 x 16/13.
const RIVER_DEPTH := 0.64
## Zorp's glowing streams run through PART of the world, not around the whole globe. Below RIVER_MASK_LO
## of the mask noise there is no channel at all; above RIVER_MASK_HI the channel is at full depth.
## Reason: the integration critic's survey found only 20.1% of Zorp free to decorate (home 70.5%), and
## the channels plus their banks plus the shore margin were 26% of that on their own. ACNH keeps most
## of the ground open and walkable and puts the water in a readable place.
## Raised from 0.26 for R2.11: on a 10.5 m Zorp the channels, their banks and the shore margin were
## refusing 21.7% of the planet (slope 9.8 + shore 8.2 + water 3.7) against home's 7.5%, because the
## shore margin and the astronaut are fixed sizes and the world around them got smaller. A higher HI
## means the mask only opens where the mask noise is genuinely high, so there are fewer and shorter
## streams — the same "put the water in a readable place" fix as the original rescue, one notch on.
const RIVER_MASK_LO := 0.02
const RIVER_MASK_HI := 0.42
const CRATER_RIM := 0.16
const FLAT_MIN_ABOVE_WATER := 0.45
## Fraction of a plateau's angular radius used by its bank. Small = crisper cliff edge.
const PLATEAU_BANK := 0.26
## Fraction of the crater radius that is a FLAT floor (the rest is the wall) — a basin, not a dish.
const CRATER_FLOOR := 0.45

# --- ground ambient occlusion (COLOR.a) -----------------------------------------------------------
## The ground gates failed because a smooth sphere with sparse props has nothing casting shade at
## noon: the whole crop collapsed into one evenly-lit mid tone (luma range 0.43 against ACNH's 0.52).
## Cast shadows alone cannot fix that — at noon they are short. So the ground mesh now carries a baked
## occlusion term in COLOR.a which the three ground shaders multiply into the LIT result (never into
## the albedo — that is the mud trap). Three contributions, all of them real geometry:
##   * a contact pool under every registered prop (ACNH paints one under every object);
##   * the concave foot of every crater wall / plateau bank;
##   * broad low ground (valleys read darker than ridges, so the landforms model as form).
## Cell grid used to answer "which props are near this vertex" in O(1) — 6 cube faces, N x N each.
const AO_GRID := 20
## Metres of contact pool around a prop's own footprint.
const PROP_AO_MARGIN := 1.25
## Darkening right at a prop's base.
const PROP_AO_STRENGTH := 0.62
## Darkening in the concave foot of a bank / crater wall.
const LANDFORM_AO := 0.34
## Darkening of broad low ground (large-scale landform shading).
const VALLEY_AO := 0.22
## Floor so a pile-up of terms can never reach black.
const AO_MIN := 0.24

const GRASS_SHADER := preload("res://src/shaders/grass_planet.gdshader")
const PLAZA_SHADER := preload("res://src/shaders/plaza_tiles.gdshader")
const METAL_SHADER := preload("res://src/shaders/metal_plates.gdshader")
const WATER_SHADER := preload("res://src/shaders/water.gdshader")

@export var data: PlanetData

var radius: float = 16.0
var _built := false

# --- radius-relative scales ----------------------------------------------------------------------
## Everything in a .tres is authored at PlanetData.REFERENCE_RADIUS (see that file's header). These
## two numbers turn it into the planet we actually have, and they are recomputed from `radius` in
## `_setup_terrain`, never baked, so a home-planet size upgrade rescales the world for free.
##   _vscale  vertical amplitudes and horizontal landform sizes  (linear in radius)
##   _ascale  scatter counts                                     (radius^2 — surface area)
var _vscale: float = 1.0
var _ascale: float = 1.0
## data.water_level rescaled to this radius; -99 (no water) passes through untouched.
var _water_level: float = -99.0

# --- terrain internals -------------------------------------------------------------------------
var _noise_hill: FastNoiseLite
var _noise_detail: FastNoiseLite
var _noise_river: FastNoiseLite
var _noise_river_mask: FastNoiseLite
var _has_rivers := false
var _crater_dirs := PackedVector3Array()
var _crater_ang := PackedFloat32Array()
var _crater_depth := PackedFloat32Array()
var _plateau_dirs := PackedVector3Array()
var _plateau_ang := PackedFloat32Array()
var _plateau_h := PackedFloat32Array()
var _flat_dirs := PackedVector3Array()
var _flat_in := PackedFloat32Array()
var _flat_out := PackedFloat32Array()
var _flat_h := PackedFloat32Array()
# --- reservations & props ------------------------------------------------------------------------
var _reserved_ids: PackedStringArray = PackedStringArray()
var _reserved_dirs := PackedVector3Array()
var _reserved_radii := PackedFloat32Array()
var _prop_dirs := PackedVector3Array()
var _prop_radii := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
## cube-face cell key -> prop indices whose contact pool touches that cell (see AO_GRID).
var _ao_cells: Dictionary = {}

var surface_mesh: MeshInstance3D
var water_mesh: MeshInstance3D
var ground_material: ShaderMaterial
var props_root: Node3D
var collectibles_root: Node3D

func _ready() -> void:
	if data == null:
		data = PlanetData.new()
	# Resolves the home planet's radius from GameState.home_planet_size and writes it back onto the
	# resource, so world.gd, environment.gd, the rocket and the geometry cache key all agree.
	radius = PlanetData.resolve_size(data)
	collision_layer = 1
	collision_mask = 0
	add_to_group("planet")
	_setup_terrain()
	if not _built:
		_build()

# ============================================================================================ terrain
func _setup_terrain() -> void:
	_vscale = radius / PlanetData.REFERENCE_RADIUS
	_ascale = _vscale * _vscale
	_water_level = data.water_level * _vscale if data.water_level > -90.0 else data.water_level
	_rng.seed = data.seed
	_noise_hill = FastNoiseLite.new()
	_noise_hill.seed = data.seed
	_noise_hill.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_hill.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise_hill.fractal_octaves = 3
	_noise_hill.fractal_gain = 0.45
	_noise_hill.fractal_lacunarity = 2.1
	_noise_hill.frequency = data.hill_frequency / radius
	_noise_detail = FastNoiseLite.new()
	_noise_detail.seed = data.seed + 101
	_noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise_detail.fractal_octaves = 2
	_noise_detail.frequency = 7.0 / radius
	_noise_river = FastNoiseLite.new()
	_noise_river.seed = data.seed + 202
	_noise_river.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_river.fractal_type = FastNoiseLite.FRACTAL_NONE
	_noise_river.frequency = 1.0 / radius
	_noise_river_mask = FastNoiseLite.new()
	_noise_river_mask.seed = data.seed + 303
	_noise_river_mask.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_river_mask.fractal_type = FastNoiseLite.FRACTAL_NONE
	_noise_river_mask.frequency = 0.62 / radius
	_has_rivers = data.biome == "violet"

	_reserved_ids.clear(); _reserved_dirs.clear(); _reserved_radii.clear()
	_crater_dirs.clear(); _crater_ang.clear(); _crater_depth.clear()
	_plateau_dirs.clear(); _plateau_ang.clear(); _plateau_h.clear()
	_flat_dirs.clear(); _flat_in.clear(); _flat_out.clear(); _flat_h.clear()

	var is_hub := data.biome == "plaza"
	var spawn := data.spawn_dir.normalized()
	var pad := data.pad_dir.normalized()
	_add_reserved("spawn", spawn, (HUB_SPAWN_FLAT_RADIUS if is_hub else SPAWN_FLAT_RADIUS) + 0.6)
	_add_reserved("pad", pad, PAD_FLAT_RADIUS + 1.0)
	for bid in data.buildings:
		var bd := building_dir(bid)
		if bd != Vector3.ZERO:
			_add_reserved(bid, bd, (HUB_BUILDING_FLAT_RADIUS if bid != "player_home" else HOME_BUILDING_FLAT_RADIUS) + 1.0)
	_reserve_npc_homes()

	# Craters: soft bowls with a raised rim, away from every reserved zone. Radius AND depth scale
	# together — scaling only the radius (which is what this did before R2.11) turns a crater on a
	# smaller planet into a canyon, because the wall gets the same drop over a shorter run.
	for i in data.crater_count:
		var cr := _rng.randf_range(2.2, 3.4) * _vscale
		var cd := _find_free_dir(_rng, cr + 1.2, 40, true)
		if cd == Vector3.ZERO:
			continue
		_crater_dirs.append(cd)
		_crater_ang.append(cr / radius)
		_crater_depth.append(_rng.randf_range(1.0, 1.3) * _vscale)
		# craters must not overlap each other: temporarily treat as reserved for the next picks
		_add_reserved("crater_%d" % i, cd, cr * 1.3)

	# Plateaus: flat-topped raised landforms with a crisp bank (the ACNH cliff). Placed after the
	# craters so the two never overlap; both are dropped from the reserved list afterwards because
	# props are welcome on their flat tops.
	for i in data.plateau_count:
		var pr := data.plateau_radius * _vscale * _rng.randf_range(0.85, 1.2)
		var pd := _find_free_dir(_rng, pr + 1.0, 40, true)
		if pd == Vector3.ZERO:
			continue
		_plateau_dirs.append(pd)
		_plateau_ang.append(pr / radius)
		_plateau_h.append(data.plateau_height * _vscale * _rng.randf_range(0.85, 1.15))
		_add_reserved("plateau_%d" % i, pd, pr * 1.25)
	# craters and plateaus are not reserved for props (props sit on rims / flat tops) — drop them
	var keep := _reserved_ids.size() - _crater_dirs.size() - _plateau_dirs.size()
	_reserved_ids.resize(keep); _reserved_dirs.resize(keep); _reserved_radii.resize(keep)

	# Flattened discs (after craters so their target height is final).
	_add_flat(spawn, HUB_SPAWN_FLAT_RADIUS if is_hub else SPAWN_FLAT_RADIUS)
	_add_flat(pad, PAD_FLAT_RADIUS)
	for bid in data.buildings:
		var bd := building_dir(bid)
		if bd != Vector3.ZERO:
			_add_flat(bd, HUB_BUILDING_FLAT_RADIUS if bid != "player_home" else HOME_BUILDING_FLAT_RADIUS)

func _add_reserved(id: String, dir: Vector3, radius_m: float) -> void:
	_reserved_ids.append(id)
	_reserved_dirs.append(dir.normalized())
	_reserved_radii.append(radius_m)

func _add_flat(dir: Vector3, radius_m: float) -> void:
	var d := dir.normalized()
	var h := _raw_offset(d)
	var lo := (_water_level + FLAT_MIN_ABOVE_WATER * _vscale) if _water_level > -90.0 else -0.4 * _vscale
	h = clampf(h, lo, 0.55 * _vscale)
	_flat_dirs.append(d)
	_flat_in.append(radius_m / radius)
	_flat_out.append((radius_m + FLAT_BLEND_METERS) / radius)
	_flat_h.append(h)

## Best-effort: reserve NPC home spots from the character builder's npc_data.gd (if present).
func _reserve_npc_homes() -> void:
	const NPC_DATA := "res://src/characters/npc_data.gd"
	if data.npcs.is_empty() or not ResourceLoader.exists(NPC_DATA):
		return
	var script: Variant = load(NPC_DATA)
	if not (script is GDScript):
		return
	var inst: Variant = script.new()
	for npc_id in data.npcs:
		var d: Variant = null
		for m in ["get_npc", "get_data", "data_for", "npc", "data"]:
			if inst.has_method(m):
				d = inst.call(m, npc_id)
				break
		if d is Dictionary and d.has("home_dir"):
			var hd: Variant = d["home_dir"]
			var v := Vector3.ZERO
			if hd is Vector3:
				v = hd
			elif hd is Array and hd.size() == 3:
				v = Vector3(hd[0], hd[1], hd[2])
			if v.length_squared() > 0.01:
				_add_reserved("npc_" + npc_id, v.normalized(), 3.2)
	if inst is Node:
		inst.free()

## Quantises a smooth height into flat terraces separated by crisp banks. This is what turns rolling
## noise into ACNH ground: large calm level areas, and every elevation change reads as a deliberate
## step instead of a bump. Continuous (band ends meet exactly), so the mesh stays watertight.
func _terrace(h: float) -> float:
	var step := data.terrace_step * _vscale
	if step <= 0.001:
		return h
	var f := h / step
	var k := floorf(f)
	var w := clampf(data.terrace_band, 0.02, 0.5)
	var t := smoothstep(0.5 - w, 0.5 + w, f - k)
	return (k + t) * step

## Terrain offset without flattening (terraced noise + plateaus + biome carving + craters).
func _raw_offset(d: Vector3) -> float:
	var p := d * radius
	var h := _terrace(data.hill_amplitude * _vscale * _noise_hill.get_noise_3dv(p))
	h += data.detail_amplitude * _vscale * _noise_detail.get_noise_3dv(p)
	for i in _plateau_dirs.size():
		var pang := acos(clampf(d.dot(_plateau_dirs[i]), -1.0, 1.0))
		var pa := _plateau_ang[i]
		if pang < pa:
			h += _plateau_h[i] * (1.0 - smoothstep(pa * (1.0 - PLATEAU_BANK), pa, pang))
	if _has_rivers:
		var n := absf(_noise_river.get_noise_3dv(p))
		var band := 1.0 - smoothstep(0.0, RIVER_HALF_WIDTH, n)
		var mask := smoothstep(RIVER_MASK_LO, RIVER_MASK_HI, _noise_river_mask.get_noise_3dv(p))
		h -= RIVER_DEPTH * _vscale * band * band * (3.0 - 2.0 * band) * mask
	for i in _crater_dirs.size():
		var ang := acos(clampf(d.dot(_crater_dirs[i]), -1.0, 1.0))
		var ca := _crater_ang[i]
		if ang < ca * 1.25:
			var t := ang / ca
			if t < 1.0:
				# Flat basin floor out to CRATER_FLOOR, then a crisp wall up to the rim.
				h -= _crater_depth[i] * (1.0 - smoothstep(CRATER_FLOOR, 0.94, t))
			var rt := (t - 0.99) / 0.22
			if absf(rt) < 1.0:
				var b := 1.0 - rt * rt
				h += CRATER_RIM * _vscale * b * b
	return h

## Final terrain offset (meters relative to radius) including flattened discs.
func _terrain_offset(d: Vector3) -> float:
	var h := _raw_offset(d)
	for i in _flat_dirs.size():
		var ang := acos(clampf(d.dot(_flat_dirs[i]), -1.0, 1.0))
		if ang < _flat_out[i]:
			var w := 1.0 - smoothstep(_flat_in[i], _flat_out[i], ang)
			h = lerpf(h, _flat_h[i], w)
	return h

## Weight in [0,1] of the exposed earth band (cliff face) at `dir` — 1 in the middle of a plateau
## bank or crater wall, 0 on flat ground. The ground shaders paint this with `bank_color`, and
## PlanetProps uses it to keep grass tufts off the bare earth.
func bank_weight(dir: Vector3) -> float:
	var d := dir.normalized()
	var bw := 0.0
	for i in _crater_dirs.size():
		var ang := acos(clampf(d.dot(_crater_dirs[i]), -1.0, 1.0))
		var t := ang / _crater_ang[i]
		if t < 1.0:
			var w := 1.0 - smoothstep(CRATER_FLOOR, 0.94, t)
			bw = maxf(bw, 4.0 * w * (1.0 - w) * 0.75)
	for i in _plateau_dirs.size():
		var pang := acos(clampf(d.dot(_plateau_dirs[i]), -1.0, 1.0))
		var pa := _plateau_ang[i]
		if pang < pa:
			var w := 1.0 - smoothstep(pa * (1.0 - PLATEAU_BANK), pa, pang)
			bw = maxf(bw, 4.0 * w * (1.0 - w))
	var fw := 0.0
	for i in _flat_dirs.size():
		var ang := acos(clampf(d.dot(_flat_dirs[i]), -1.0, 1.0))
		if ang < _flat_out[i]:
			fw = maxf(fw, 1.0 - smoothstep(_flat_in[i], _flat_out[i], ang))
	return clampf(bw * (1.0 - fw), 0.0, 1.0)

## Per-vertex bake: R = flatten weight, G = exposed bank/cliff-face weight, B = crater floor weight,
## A = ambient occlusion (1 = open sky, < 1 = contact shade). The ground shaders paint G with
## `bank_color` so every crisp elevation change reads as an ACNH cliff face (earth band) instead of
## stretched grass, and multiply the LIT colour by A so props and landforms sit in real contact shade.
func _bake_color(d: Vector3) -> Color:
	var fw := 0.0
	for i in _flat_dirs.size():
		var ang := acos(clampf(d.dot(_flat_dirs[i]), -1.0, 1.0))
		if ang < _flat_out[i]:
			fw = maxf(fw, 1.0 - smoothstep(_flat_in[i], _flat_out[i], ang))
	var cw := 0.0
	var conc := 0.0
	for i in _crater_dirs.size():
		var ang := acos(clampf(d.dot(_crater_dirs[i]), -1.0, 1.0))
		var t := ang / _crater_ang[i]
		if t < 1.0:
			var w := clampf(1.0 - smoothstep(CRATER_FLOOR, 0.94, t), 0.0, 1.0)
			cw = maxf(cw, w)
			# Concave foot of the crater wall: peaks where the flat basin turns up into the wall.
			var u := smoothstep(0.60, 1.0, w)
			conc = maxf(conc, 4.0 * u * (1.0 - u))
	for i in _plateau_dirs.size():
		var pang := acos(clampf(d.dot(_plateau_dirs[i]), -1.0, 1.0))
		var pa := _plateau_ang[i]
		if pang < pa:
			# Concave foot of the bank: peaks just outside the bottom of the cliff face.
			var w := 1.0 - smoothstep(pa * (1.0 - PLATEAU_BANK), pa, pang)
			var u := smoothstep(0.0, 0.42, w)
			conc = maxf(conc, 4.0 * u * (1.0 - u))
	# Broad landform shading: low ground reads darker than ridges, so the hills model as form even
	# when the sun is high enough that nothing casts a long shadow.
	var valley := 1.0 - smoothstep(-0.34, 0.20, _noise_hill.get_noise_3dv(d * radius))
	# Flattened discs (spawn, pad, building plots) are groomed level ground: they keep their contact
	# pools but lose the landform shading, so the hero framing stays open and readable.
	var terrain_ao := (LANDFORM_AO * conc + VALLEY_AO * valley) * (1.0 - 0.85 * fw)
	var ao := 1.0 - (PROP_AO_STRENGTH * _prop_occlusion(d) + terrain_ao) * data.ground_ao
	return Color(fw, bank_weight(d), cw, clampf(ao, AO_MIN, 1.0))

# --- ambient-occlusion index ---------------------------------------------------------------------
## Cube face of a unit dir plus its gnomonic (u, v) in [-1, 1]: returns Vector3(face, u, v).
static func _face_uv(d: Vector3) -> Vector3:
	var a := d.abs()
	if a.x >= a.y and a.x >= a.z:
		return Vector3(0.0 if d.x > 0.0 else 1.0, d.y / a.x, d.z / a.x)
	if a.y >= a.z:
		return Vector3(2.0 if d.y > 0.0 else 3.0, d.x / a.y, d.z / a.y)
	return Vector3(4.0 if d.z > 0.0 else 5.0, d.x / a.z, d.y / a.z)

## Inverse of _face_uv. (u, v) may leave [-1, 1]; the result then lands on the neighbouring face,
## which is exactly how a prop's pool is indexed across a cube seam.
static func _dir_from_face_uv(face: int, u: float, v: float) -> Vector3:
	match face:
		0: return Vector3(1.0, u, v).normalized()
		1: return Vector3(-1.0, u, v).normalized()
		2: return Vector3(u, 1.0, v).normalized()
		3: return Vector3(u, -1.0, v).normalized()
		4: return Vector3(u, v, 1.0).normalized()
		_: return Vector3(u, v, -1.0).normalized()

static func _cell_key(d: Vector3) -> int:
	var f := _face_uv(d)
	var iu := clampi(int((f.y * 0.5 + 0.5) * AO_GRID), 0, AO_GRID - 1)
	var iv := clampi(int((f.z * 0.5 + 0.5) * AO_GRID), 0, AO_GRID - 1)
	return int(f.x) * 1024 + iv * 32 + iu

## Buckets every registered prop into the cells its contact pool can reach, so the per-vertex bake is
## a single dictionary lookup instead of a scan over every prop.
func _build_ao_index() -> void:
	_ao_cells.clear()
	var step := 2.0 / float(AO_GRID)
	for i in _prop_dirs.size():
		var d := _prop_dirs[i]
		var f := _face_uv(d)
		var face := int(f.x)
		var ang := (_prop_radii[i] + PROP_AO_MARGIN) / radius
		# Gnomonic scale at this point is 1 / cos^2(theta), and cos(theta) is the dominant component.
		var cs := maxf(d.abs()[maxi(face / 2, 0)], 0.5)
		var n := maxi(1, int(ceil(ang * 1.3 / (cs * cs) / step)))
		for dv in range(-n, n + 1):
			for du in range(-n, n + 1):
				var key := _cell_key(_dir_from_face_uv(face, f.y + float(du) * step, f.z + float(dv) * step))
				var arr: PackedInt32Array = _ao_cells.get(key, PackedInt32Array())
				if arr.find(i) < 0:
					arr.append(i)
					_ao_cells[key] = arr

## Contact-pool weight in [0, 1] at `d` (1 = right at a prop's base).
func _prop_occlusion(d: Vector3) -> float:
	var arr: PackedInt32Array = _ao_cells.get(_cell_key(d), PackedInt32Array())
	var best := 0.0
	for i in arr:
		var r := (_prop_radii[i] + PROP_AO_MARGIN) / radius
		var dt := d.dot(_prop_dirs[i])
		if dt <= 0.0:
			continue
		# Small-angle chord -> angle; avoids an acos per prop per vertex.
		var ang := sqrt(maxf(2.0 * (1.0 - dt), 0.0))
		if ang < r:
			best = maxf(best, 1.0 - smoothstep(0.0, 1.0, ang / r))
	return best

# ============================================================================================ build
## Builds ground mesh + trimesh collision, water shell, ground material, props and collectibles.
# ---------------------------------------------------------------------------------- prebuild cache
## Ground mesh, its trimesh shape and the water mesh, keyed by everything that determines them.
## Building a planet costs 400-750 ms on the main thread inside `_ready`, which the rocket builder
## measured as the single remaining hitch in the launch-to-landing journey: the trip is a locked
## 60 fps everywhere except the two scene swaps, and the arrival swap is almost entirely this.
## The rocket knows its destination ~16 s before it lands, so it calls `prebuild()` during the
## cruise - dead time - and the arrival then just picks the geometry up.
static var _geo_cache: Dictionary = {}
## Guards against two prebuilds of the same planet overlapping.
static var _geo_pending: Dictionary = {}

## Cache key for a planet's baked geometry. THE RADIUS IS PART OF IT, and it is the RESOLVED radius
## (PlanetData.effective_radius), not the authored one — a home-planet size upgrade changes the key,
## so the cache misses and the new, larger mesh is built instead of the old one being handed over.
static func _geo_key(d: PlanetData) -> String:
	return "%s|%d|%d|%.3f" % [d.id, d.seed, d.mesh_subdivisions, PlanetData.effective_radius(d)]


## Builds and caches a planet's geometry ahead of time. Safe to call more than once; the second
## call is free. Call it as early as the destination is known.
static func prebuild(d: PlanetData) -> void:
	if d == null:
		return
	var key := _geo_key(d)
	if _geo_cache.has(key) or _geo_pending.has(key):
		return
	_geo_pending[key] = true
	# A detached Planet gives us the real terrain functions without entering the tree. Props are
	# scattered into a throwaway root because the ground bake needs their contact-shade pools, and
	# they are deterministic (seeded RNG), so the geometry matches what the live planet will build.
	# The scratch planet has to be IN the tree: prop placement reads global transforms, and a
	# detached node returns identity plus an error per call. It is parented off-screen, never
	# rendered (`_built` is pre-set so `_ready` does not build it a second time), and freed
	# immediately. Everything it produces is deterministic, so the geometry matches what the live
	# planet will build.
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		_geo_pending.erase(key)
		return
	var tmp := Planet.new()
	tmp.data = d
	tmp.radius = PlanetData.resolve_size(d)
	tmp._built = true
	tmp.visible = false
	tmp.collision_layer = 0
	loop.root.add_child(tmp)
	tmp._setup_terrain()
	var junk_props := Node3D.new()
	var junk_coll := Node3D.new()
	tmp.add_child(junk_props)
	tmp.add_child(junk_coll)
	var props := PlanetProps.new()
	props.populate(tmp, junk_props, junk_coll)
	tmp._build_ao_index()
	var mesh := PlanetMeshBuilder.build(d.mesh_subdivisions, tmp.height_at, tmp._bake_color)
	_geo_cache[key] = {"mesh": mesh, "shape": mesh.create_trimesh_shape()}
	_geo_pending.erase(key)
	loop.root.remove_child(tmp)
	tmp.queue_free()


## True when `prebuild` has already done the work for this planet.
static func is_prebuilt(d: PlanetData) -> bool:
	return d != null and _geo_cache.has(_geo_key(d))


func _build() -> void:
	_built = true
	# Props are scattered FIRST (they only need height_at, never the mesh) so the ground bake can put
	# a real contact-shade pool under every one of them — see _bake_color / COLOR.a.
	props_root = Node3D.new()
	props_root.name = "Props"
	add_child(props_root)
	collectibles_root = Node3D.new()
	collectibles_root.name = "Collectibles"
	add_child(collectibles_root)
	var props := PlanetProps.new()
	props.populate(self, props_root, collectibles_root)
	_build_ao_index()

	var key := _geo_key(data)
	var cached: Dictionary = _geo_cache.get(key, {})
	var mesh: ArrayMesh = cached.get("mesh", null)
	if mesh == null:
		mesh = PlanetMeshBuilder.build(data.mesh_subdivisions, height_at, _bake_color)
	surface_mesh = MeshInstance3D.new()
	surface_mesh.name = "Surface"
	surface_mesh.mesh = mesh
	ground_material = _make_ground_material()
	surface_mesh.material_override = ground_material
	surface_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(surface_mesh)
	move_child(surface_mesh, 0)

	var col := CollisionShape3D.new()
	col.name = "SurfaceCollision"
	# The trimesh shape is the second-most expensive step, so it is cached alongside the mesh.
	var shape: Shape3D = cached.get("shape", null)
	col.shape = shape if shape != null else mesh.create_trimesh_shape()
	add_child(col)

	_build_water()

func _build_water() -> void:
	if _water_level <= -90.0:
		return
	var wr := radius + _water_level
	var depth_func := func(d: Vector3) -> Color:
		return Color(clampf((wr - height_at(d)) / 4.0, 0.0, 1.0), 0.0, 0.0, 1.0)
	var wmesh := PlanetMeshBuilder.build(maxi(data.mesh_subdivisions - 1, 3), func(_d: Vector3) -> float: return wr, depth_func)
	water_mesh = MeshInstance3D.new()
	water_mesh.name = "Water"
	water_mesh.mesh = wmesh
	water_mesh.layers = 1 << 5
	water_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = WATER_SHADER
	m.set_shader_parameter("shallow_color", data.water_color)
	m.set_shader_parameter("deep_color", data.water_deep_color)
	match data.biome:
		"violet":
			m.set_shader_parameter("glow_color", Color("#3ec6ff"))
			m.set_shader_parameter("glow_strength", 0.7)
			m.set_shader_parameter("alpha_shallow", 0.7)
			m.set_shader_parameter("sparkle_strength", 2.2)
		"chrome":
			m.set_shader_parameter("sheen_strength", 0.35)
			m.set_shader_parameter("alpha_shallow", 0.9)
			m.set_shader_parameter("alpha_deep", 0.97)
			m.set_shader_parameter("foam_color", Color("#3a3f52"))
			m.set_shader_parameter("streak_strength", 0.08)
			m.set_shader_parameter("sparkle_strength", 0.9)
			m.set_shader_parameter("wave_speed", 0.12)
			m.set_shader_parameter("wave_strength", 0.15)
			m.set_shader_parameter("bob", 0.004)
	water_mesh.material_override = m
	add_child(water_mesh)

func _make_ground_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var wr := radius + _water_level if _water_level > -90.0 else radius - 50.0
	var spawn := data.spawn_dir.normalized()
	match data.biome:
		"chrome":
			m.shader = METAL_SHADER
			m.set_shader_parameter("plate_a", data.ground_color_a)
			m.set_shader_parameter("plate_b", data.ground_color_b)
			m.set_shader_parameter("plate_c", data.ground_color_a.lightened(0.15))
			# The ONLY saturated accent on Bolt: warm orange seam lights (STYLE_GUIDE #ff8a3d).
			m.set_shader_parameter("seam_light", Color("#ff8a3d"))
			m.set_shader_parameter("seam_dark", data.ground_color_b)
			# Rare desaturated dark slate-teal maintenance hatch — a dark tone, not a colour accent.
			m.set_shader_parameter("plate_panel", Color("#5f7f8c"))
			m.set_shader_parameter("oil_color", data.water_deep_color)
			m.set_shader_parameter("oil_ring", data.water_color.lightened(0.16))
			m.set_shader_parameter("bank_color", data.bank_color)
			m.set_shader_parameter("grime_color", data.ground_shadow_color)
			# Bolt's tower shadows were near-black hard-edged slabs (4.7-7.5% of the documented ground
			# crop under luma 0.15, against a lit deck at luma 0.59), which is what pinned its luma p05
			# at 0.105. The deck is a hard, sky-facing metal plate, so it takes the most skylight fill
			# of any surface in the game — this is where the tinted-shadow fix does the most work.
			m.set_shader_parameter("shadow_fill_color", Color("#93b2dd"))
			m.set_shader_parameter("shadow_fill", 0.31)
			m.set_shader_parameter("planet_radius", radius)
			m.set_shader_parameter("water_radius", wr)
		"plaza":
			m.shader = PLAZA_SHADER
			m.set_shader_parameter("lawn_a", data.ground_color_a)
			m.set_shader_parameter("lawn_b", data.ground_color_b)
			m.set_shader_parameter("lawn_c", data.ground_color_a.lightened(0.10))
			m.set_shader_parameter("lawn_shadow", data.ground_shadow_color)
			m.set_shader_parameter("bank_color", data.bank_color)
			# Warm cream sandstone. R2.6 pulled the VALUE down (the plaza was the brightest surface in
			# the game at V 0.91) while keeping — actually slightly raising — the warm gold chroma, so
			# it reads as sun-warmed stone rather than the pale putty a straight desaturation gave.
			# The plaza's dark values still come from grout, the edge-AO pool, cast shadows and limb
			# darkening — NOT from a brown albedo.
			# The hub is "the big CREAM world" (its own description, and the sky body that samples these
			# colours reads green-and-tan because of them). #d4b165 was a gold that had drifted a long
			# way from cream, and it also cost the plaza its bright end: the ground crop's luma p95 fell
			# to 0.77, which is what collapsed the tonal range. Back to a warm sun-bleached sandstone —
			# lighter and less chromatic — with the dark values still coming from grout, the edge AO
			# pool, the baked contact shade and limb darkening, never from the base colour.
			m.set_shader_parameter("tile_a", Color("#d7c08a"))
			m.set_shader_parameter("tile_b", Color("#cbae77"))
			m.set_shader_parameter("tile_shadow", Color("#b09b78"))
			m.set_shader_parameter("grout_color", Color("#9d8e73"))
			m.set_shader_parameter("curb_color", Color("#d0b580"))
			# The hub already runs BRIGHT (luma p05 0.43-0.52 against a 0.30-0.42 window), so its cast
			# shadows get only a token lift — just enough that the awnings and the town hall throw a
			# warm-grey shadow instead of a black one.
			m.set_shader_parameter("shadow_fill_color", Color("#c2c6d4"))
			m.set_shader_parameter("shadow_fill", 0.04)
			m.set_shader_parameter("sand_color", data.ground_color_low)
			m.set_shader_parameter("shore_color", data.ground_color_low.darkened(0.28))
			m.set_shader_parameter("planet_radius", radius)
			m.set_shader_parameter("water_radius", wr)
			var zones := PackedVector3Array()
			var radii := PackedFloat32Array()
			zones.append(spawn); radii.append(HUB_SPAWN_FLAT_RADIUS - 0.8)
			zones.append(data.pad_dir.normalized()); radii.append(PAD_FLAT_RADIUS + 0.2)
			var pa := PackedVector3Array()
			var pb := PackedVector3Array()
			for bid in data.buildings:
				var bd := building_dir(bid)
				if bd == Vector3.ZERO:
					continue
				zones.append(bd); radii.append(4.8)
				pa.append(spawn); pb.append(bd)
			pa.append(spawn); pb.append(data.pad_dir.normalized())
			m.set_shader_parameter("zone_count", zones.size())
			m.set_shader_parameter("zone_dirs", _pad_v3(zones))
			m.set_shader_parameter("zone_radii", _pad_f(radii))
			m.set_shader_parameter("path_count", pa.size())
			m.set_shader_parameter("path_a", _pad_v3(pa))
			m.set_shader_parameter("path_b", _pad_v3(pb))
		_:
			m.shader = GRASS_SHADER
			m.set_shader_parameter("color_a", data.ground_color_a)
			m.set_shader_parameter("color_b", data.ground_color_b)
			# Violet needs luma RANGE more than it needs brightness, so its light triangles reach
			# further above the base tone than the meadow's do (set per biome below).
			m.set_shader_parameter("color_c", data.ground_color_a.lightened(0.24 if data.biome == "violet" else 0.10))
			m.set_shader_parameter("shadow_color", data.ground_shadow_color)
			m.set_shader_parameter("bank_color", data.bank_color)
			m.set_shader_parameter("sand_color", data.ground_color_low)
			m.set_shader_parameter("shore_color", data.ground_color_low.darkened(0.28))
			# The trodden path is a WARM EARTH tan, not the pale beach sand it shares a source colour
			# with. Measured: the old path covered 32% of the documented ground crop at V 0.85 / S 0.21
			# — a putty band that flattened the whole tonal range. ACNH's dirt is warmer and a notch
			# darker (#d89c63 family), which is chroma, not mud.
			m.set_shader_parameter("path_color", Color("#c3a171"))
			m.set_shader_parameter("path_edge_color", Color("#a8875c"))
			m.set_shader_parameter("path_width", 1.5)
			m.set_shader_parameter("shadow_fill_color", Color("#b8cdf0"))
			m.set_shader_parameter("shadow_fill", 0.26)
			m.set_shader_parameter("planet_radius", radius)
			m.set_shader_parameter("water_radius", wr)
			var pa2 := PackedVector3Array()
			var pb2 := PackedVector3Array()
			if data.biome == "violet":
				m.set_shader_parameter("river_color", Color("#3ec6ff"))
				m.set_shader_parameter("riverbed_color", Color("#3f95b4"))
				m.set_shader_parameter("river_glow", 0.5)
				m.set_shader_parameter("speck_strength", 0.8)
				m.set_shader_parameter("crater_color", Color("#a894c4"))
				m.set_shader_parameter("shade_tint", Color(0.70, 0.63, 0.88))
				# Zorp failed value mean and luma p05 LOW: a macro shadow tone over 44% of the surface
				# plus a violet base is simply a dark planet. The dark tones now come from the baked
				# contact shade instead, which is localised and reads as occlusion rather than gloom.
				# Violet is squeezed between the value-mean ceiling and the luma-range floor: HSV value
				# on a violet is its blue channel, while luma is mostly green, so a brighter violet
				# costs value mean without buying much luma. A narrow, strong sunlit patch buys the
				# top of the range where a broad lift cannot.
				m.set_shader_parameter("sun_patch", 1.72)
				m.set_shader_parameter("sun_patch_lo", 0.58)
				m.set_shader_parameter("sun_patch_amt", 0.95)
				m.set_shader_parameter("sun_patch_tint", Color(1.0, 1.14, 0.84))
				# Zorp had no dark tones AT ALL (luma p05 0.470, range 0.387 - both outside the
				# window in the wrong direction) because an earlier pass stripped every source of
				# darkness to chase the value-mean ceiling. The range comes back from SHADOW AND
				# STRUCTURE, not from washing the violet out: a real macro shade tone again (over a
				# darker, still-violet shadow colour), a proper limb, and PlanetData.ground_ao raised
				# from 0.04 to 0.52 so props and landforms sit in contact shade like every other world.
				m.set_shader_parameter("shadow_patch", 0.20)
				m.set_shader_parameter("limb_darken", 0.42)
				# Violet takes a violet-tinted fill: with ground_ao raised, an unfilled mushroom-tree
				# shadow rendered #221554 (luma 0.09, S 0.76) over 12% of the ground crop — the exact
				# black-hole defect this fix exists to remove, just in lavender.
				m.set_shader_parameter("shadow_fill_color", Color("#b6a8dc"))
				m.set_shader_parameter("shadow_fill", 0.34)
			else:
				m.set_shader_parameter("crater_color", data.bank_color.lightened(0.12))
				m.set_shader_parameter("sun_patch", 1.30)
				m.set_shader_parameter("sun_patch_lo", 0.48)
				m.set_shader_parameter("sun_patch_amt", 0.72)
				for bid in data.buildings:
					var bd := building_dir(bid)
					if bd != Vector3.ZERO:
						pa2.append(spawn); pb2.append(bd)
				pa2.append(spawn); pb2.append(data.pad_dir.normalized())
			m.set_shader_parameter("path_count", pa2.size())
			m.set_shader_parameter("path_a", _pad_v3(pa2))
			m.set_shader_parameter("path_b", _pad_v3(pb2))
	return m

static func _pad_v3(a: PackedVector3Array, n: int = 8) -> PackedVector3Array:
	var out := a.duplicate()
	while out.size() < n:
		out.append(Vector3.UP)
	out.resize(n)
	return out

static func _pad_f(a: PackedFloat32Array, n: int = 8) -> PackedFloat32Array:
	var out := a.duplicate()
	while out.size() < n:
		out.append(0.0)
	out.resize(n)
	return out

# ============================================================================================ public API
## How this planet's radius rescales content authored at PlanetData.REFERENCE_RADIUS. Linear for
## anything measured in metres of relief, squared for anything counted per unit of surface.
func vertical_scale() -> float:
	return _vscale

func area_scale() -> float:
	return _ascale

## Re-seats a position stored in the planet's LOCAL space onto the current ground. Existing saves
## hold decorations as a local transform, which is a fixed distance from the centre — so if the
## planet's radius ever changes under them (the R2.11 "expand your planet" upgrade) every one of
## them ends up buried or floating by the size difference. Whoever ships that upgrade should run
## each stored position through here on load. Direction and yaw are preserved exactly; only the
## distance from the centre is corrected.
func reseat_local(local_pos: Vector3) -> Vector3:
	if local_pos.length_squared() < 0.000001:
		return local_pos
	var d := local_pos.normalized()
	return d * height_at(d)

func up_at(world_pos: Vector3) -> Vector3:
	var d := world_pos - global_position
	if d.length_squared() < 0.000001:
		return Vector3.UP
	return d.normalized()

func dir_of(world_pos: Vector3) -> Vector3:
	return up_at(world_pos)

## Distance from center to ground along dir. This is the exact displacement used to build the mesh
## and its trimesh collision, so anything placed with it sits precisely on the ground.
func height_at(dir: Vector3) -> float:
	if _noise_hill == null:
		return radius
	return radius + _terrain_offset(dir.normalized())

func surface_point(dir: Vector3) -> Vector3:
	var d := dir.normalized()
	return global_position + d * height_at(d)

## Transform on the surface at dir, with Y = up and -Z facing forward_hint (projected onto the tangent plane).
func surface_transform(dir: Vector3, forward_hint: Vector3 = Vector3.FORWARD) -> Transform3D:
	var d := dir.normalized()
	var fwd := forward_hint - d * forward_hint.dot(d)
	if fwd.length_squared() < 0.0001:
		fwd = Vector3.RIGHT - d * Vector3.RIGHT.dot(d)
		if fwd.length_squared() < 0.0001:
			fwd = Vector3.FORWARD - d * Vector3.FORWARD.dot(d)
	fwd = fwd.normalized()
	var basis := Basis.looking_at(fwd, d)
	return Transform3D(basis, surface_point(d))

func spawn_transform() -> Transform3D:
	return surface_transform(data.spawn_dir.normalized(), Vector3.FORWARD)

func pad_transform() -> Transform3D:
	return surface_transform(data.pad_dir.normalized(), Vector3.FORWARD)

## Random unit direction at least min_angle_deg away from every dir in avoid.
func random_surface_dir(rng: RandomNumberGenerator, avoid: Array = [], min_angle_deg: float = 12.0) -> Vector3:
	var min_dot := cos(deg_to_rad(min_angle_deg))
	for attempt in 64:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if v.length_squared() < 0.001:
			continue
		v = v.normalized()
		var ok := true
		for a in avoid:
			if v.dot(a) > min_dot:
				ok = false
				break
		if ok:
			return v
	return Vector3.UP

## Great-circle distance (meters) along the surface between two dirs.
func surface_distance(dir_a: Vector3, dir_b: Vector3) -> float:
	return acos(clampf(dir_a.normalized().dot(dir_b.normalized()), -1.0, 1.0)) * radius

## Rotates dir toward target_dir by `meters` along the surface (great circle). Used by NPC wandering.
func step_dir(dir: Vector3, target_dir: Vector3, meters: float) -> Vector3:
	var a := dir.normalized()
	var b := target_dir.normalized()
	var ang := acos(clampf(a.dot(b), -1.0, 1.0))
	if ang < 0.0001:
		return a
	var t := clampf(meters / radius / ang, 0.0, 1.0)
	return a.slerp(b, t).normalized()

## True if the ground at dir is under water (only meaningful when the planet has water).
func is_underwater(dir: Vector3) -> bool:
	if _water_level < -90.0:
		return false
	return height_at(dir) < radius + _water_level - 0.05

## Water shell radius (distance from center), or -1 when the planet has no water.
func water_radius() -> float:
	return radius + _water_level if _water_level > -90.0 else -1.0

## Fixed direction for a building id ("town_hall", "deco_store", "clothes_store", "event_space",
## "player_home"). Returns Vector3.ZERO for unknown ids.
func building_dir(id: String) -> Vector3:
	if HUB_BUILDING_DIRS.has(id):
		return (HUB_BUILDING_DIRS[id] as Vector3).normalized()
	if id == "player_home":
		return PLAYER_HOME_DIR.normalized()
	return Vector3.ZERO

## All reserved directions: spawn, pad, buildings, npc homes (nothing procedural is placed there).
func get_reserved_dirs() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for d in _reserved_dirs:
		out.append(d)
	return out

## Surface distance (meters) from dir to the nearest procedural prop; INF when there are none.
func nearest_prop_distance(dir: Vector3) -> float:
	var d := dir.normalized()
	var best := INF
	for i in _prop_dirs.size():
		best = minf(best, surface_distance(d, _prop_dirs[i]) - _prop_radii[i])
	return best

## True inside one of the flattened discs (spawn, pad, building spots), where the ground is level.
func is_flat_zone(dir: Vector3) -> bool:
	var d := dir.normalized()
	for i in _flat_dirs.size():
		if acos(clampf(d.dot(_flat_dirs[i]), -1.0, 1.0)) < _flat_in[i]:
			return true
	return false

## Reserved-zone id containing dir, or "" if free.
func reserved_zone_at(dir: Vector3) -> String:
	var d := dir.normalized()
	for i in _reserved_dirs.size():
		if surface_distance(d, _reserved_dirs[i]) < _reserved_radii[i]:
			return _reserved_ids[i]
	return ""

## Approximate ground normal at dir (finite differences on height_at). Radial `dir` on flat ground.
func ground_normal(dir: Vector3, eps_m: float = 0.25) -> Vector3:
	var d := dir.normalized()
	var xf := surface_transform(d)
	var e := eps_m / radius
	var dx := (d + xf.basis.x * e).normalized()
	var dz := (d + xf.basis.z * e).normalized()
	var p0 := d * height_at(d)
	var px := dx * height_at(dx)
	var pz := dz * height_at(dz)
	var n := (pz - p0).cross(px - p0).normalized()
	if n.dot(d) < 0.0:
		n = -n
	return n

## Registers a placed prop so later placements and decorations avoid it.
func register_prop(dir: Vector3, footprint_m: float) -> void:
	_prop_dirs.append(dir.normalized())
	_prop_radii.append(footprint_m)

## Finds a random free direction with `clearance_m` of room: outside reserved zones, away from
## registered props, not under water, and (unless allow_slope) not on a steep slope.
## Returns Vector3.ZERO if nothing suitable was found within `tries`.
func _find_free_dir(rng: RandomNumberGenerator, clearance_m: float, tries: int = 48, allow_slope: bool = false, band_center: Vector3 = Vector3.ZERO, band_max_m: float = 0.0) -> Vector3:
	var wr := water_radius()
	for attempt in tries:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if v.length_squared() < 0.001 or v.length_squared() > 1.0:
			continue
		v = v.normalized()
		if band_max_m > 0.0 and surface_distance(v, band_center) > band_max_m:
			continue
		if not _is_free(v, clearance_m):
			continue
		var h := height_at(v)
		if wr > 0.0 and h < wr + 0.18:
			continue
		if not allow_slope:
			var xf := surface_transform(v)
			var e := maxf(clearance_m, 0.4) / radius
			var e_near := 0.45 / radius
			var hmin := h
			var hmax := h
			var nmin := h
			var nmax := h
			for k in 6:
				var ang := k * PI / 3.0
				var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
				var hh := height_at((v + tangent * e).normalized())
				hmin = minf(hmin, hh)
				hmax = maxf(hmax, hh)
				if wr > 0.0 and hh < wr + 0.1:
					hmin = -INF
				var hn := height_at((v + tangent * e_near).normalized())
				nmin = minf(nmin, hn)
				nmax = maxf(nmax, hn)
			if hmin == -INF or hmax - hmin > 0.28 + clearance_m * 0.12 or nmax - nmin > 0.13:
				continue
		return v
	return Vector3.ZERO

func _is_free(v: Vector3, clearance_m: float) -> bool:
	for i in _reserved_dirs.size():
		if surface_distance(v, _reserved_dirs[i]) < _reserved_radii[i] + clearance_m:
			return false
	for i in _prop_dirs.size():
		if surface_distance(v, _prop_dirs[i]) < _prop_radii[i] + clearance_m:
			return false
	return true

## Public wrapper used by PlanetProps and available to other builders (e.g. NPC wander targets).
func find_free_dir(rng: RandomNumberGenerator, clearance_m: float, tries: int = 48, allow_slope: bool = false) -> Vector3:
	return _find_free_dir(rng, clearance_m, tries, allow_slope)

## Free dir within `max_m` surface meters of `center` (for clustering props like flower patches).
func find_free_dir_near(rng: RandomNumberGenerator, center: Vector3, max_m: float, clearance_m: float, tries: int = 32) -> Vector3:
	return _find_free_dir(rng, clearance_m, tries, false, center.normalized(), max_m)

## Deterministic RNG seeded from the planet seed (props, collectibles).
func make_rng(salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([data.seed, data.id, salt])
	return r

## Debug/QA helper: samples the terrain and returns {"min","max","mean","underwater_pct","hill_min","hill_max"}.
## Also printed when `verbose` is true (Director: call /root/.../Planet.terrain_stats).
func terrain_stats(samples: int = 4000, verbose: bool = true) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var mn := INF
	var mx := -INF
	var sum := 0.0
	var below := 0
	var nmin := INF
	var nmax := -INF
	var wl := _water_level
	for i in samples:
		var v := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var h := height_at(v) - radius
		mn = minf(mn, h)
		mx = maxf(mx, h)
		sum += h
		if wl > -90.0 and h < wl:
			below += 1
		var z := _noise_hill.get_noise_3dv(v * radius)
		nmin = minf(nmin, z)
		nmax = maxf(nmax, z)
	var out := {"min": mn, "max": mx, "mean": sum / samples, "underwater_pct": 100.0 * below / samples, "hill_min": nmin, "hill_max": nmax}
	if verbose:
		print("Planet[%s] R=%.1f (vscale %.3f, ascale %.3f) terrain: min %.2f max %.2f mean %.2f underwater %.1f%% hill-noise [%.2f, %.2f] flats=%d craters=%d plateaus=%d props=%d" % [data.id, radius, _vscale, _ascale, mn, mx, sum / samples, out["underwater_pct"], nmin, nmax, _flat_dirs.size(), _crater_dirs.size(), _plateau_dirs.size(), _prop_dirs.size()])
		if surface_mesh:
			print("  ground mesh aabb: %s" % str(surface_mesh.mesh.get_aabb()))
		if water_mesh:
			print("  water mesh aabb: %s  water_radius=%.2f water_level=%.2f" % [str(water_mesh.mesh.get_aabb()), water_radius(), _water_level])
	return out
