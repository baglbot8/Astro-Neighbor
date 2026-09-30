class_name JungleLayout
extends RefCounted
## THE TANGLE (planet id "jungle", biome "jungle") - the fixed layout every jungle system reads:
## the trail network, and the stall pitch by the landing pad. docs/JUNGLE_PLANET_SPEC.md.
##
## ONE SOURCE, THREE READERS. The trails are painted by the ground shader (Planet._make_ground_material,
## "jungle" arm), kept clear of craters and props by Planet._setup_terrain (reserved samples along each
## arc, laid down BEFORE the swamp pools are dug), and avoided by the flower / tuft scatter through
## PlanetProps._on_paved (JungleProps pushes the same arcs into it). All three call `trail_arcs()`, so a
## trail can never be painted in one place and grown over in another.
##
## Everything is derived from the planet's own `spawn_dir` / `pad_dir` at call time - no hand-typed
## direction lives here except the bearings and distances below - so moving the pad in jungle.tres moves
## the stall and the trails with it.
##
## ---------------------------------------------------------------------------------------- STALL API
## For the resident builder (the swamp-folk shopkeeper, spec section 3):
##   JungleLayout.stall_dir(data)     unit direction from the planet centre to the stall pitch centre.
##                                    For jungle.tres as shipped: about (-0.659, 0.751, -0.041) - see
##                                    the note on stall_dir() for the measured numbers.
##   JungleLayout.stall_facing(data)  unit tangent the stall's FRONT should face (toward the trail that
##                                    runs from the pad to the spawn), for Planet.surface_transform(dir,
##                                    facing).
##   JungleLayout.STALL_FLAT_RADIUS   metres of flattened, reserved, prop-free ground around stall_dir.
##                                    Planet flattens it and reserves STALL_FLAT_RADIUS + STALL_MARGIN_M,
##                                    so no tree, pool, collectible or decoration lands on the pitch.
##   JungleLayout.stall_front_dir(d)  the trail end in front of the stall (where a customer stands).
## Pattern to copy: src/hub/buildings/print_table.gd (Gloop's table) places itself with
## `p.surface_transform(dir, facing)` - it does not need to clear props here, the pitch is already clear.

const STALL_ID := "moss_stall"
## Flat, prop-free disc for the stall (Gloop's table footprint is 2.3 x 0.9 m; this leaves room for a
## ~3 m stall, the keeper standing behind it and a lamp beside it).
const STALL_FLAT_RADIUS := 2.6
const STALL_MARGIN_M := 0.8
## The stall stands this far from the pad centre, `STALL_BEARING_DEG` off the pad->spawn bearing -
## outside the pad's own 5.0 m reserve (PAD_FLAT_RADIUS 4.0 + 1.0), inside the first view after landing.
const STALL_FROM_PAD_M := 7.6
const STALL_BEARING_DEG := 55.0
## Where a customer stands, measured from the stall centre toward `stall_facing`.
const STALL_FRONT_M := 2.3

## Painted trail width (ground shader) and the centreline clearance reserved along it.
const TRAIL_WIDTH := 1.6
## Metres either side of a trail centreline kept free of props and pools. `_is_free(v, c)` tests
## `distance < TRAIL_CLEAR_M + c`, so a trunk with 1.4 m clearance stands at least 2.5 m off the line and
## its canopy still arches over the path - a tunnel, never a wall.
const TRAIL_CLEAR_M := 1.1
## Spacing of the reserved samples along each arc.
const TRAIL_SAMPLE_M := 1.8


## Unit tangent at `d` pointing along the great circle toward `target`.
static func _toward(d: Vector3, target: Vector3) -> Vector3:
	var t := target - d * d.dot(target)
	if t.length_squared() < 0.000001:
		t = Vector3.RIGHT - d * d.x
	return t.normalized()


## Walk `meters` from `from` on a planet of radius `r`, on a bearing `bearing_deg` measured from the
## great circle toward `ref` (positive = clockwise seen from above, i.e. to the right of `ref`).
static func _walk(from: Vector3, ref: Vector3, bearing_deg: float, meters: float, r: float) -> Vector3:
	var d := from.normalized()
	var fwd := _toward(d, ref.normalized())
	var right := fwd.cross(d).normalized()
	var a := deg_to_rad(bearing_deg)
	var t := (fwd * cos(a) + right * sin(a)).normalized()
	var ang := meters / r
	return (d * cos(ang) + t * sin(ang)).normalized()


static func _radius(data: PlanetData) -> float:
	return PlanetData.effective_radius(data) if data != null else PlanetData.REFERENCE_RADIUS


## Stall pitch centre. For jungle.tres as shipped (R 14, spawn (0, 0.9397, 0.3419), pad
## (-0.4301, 0.7339, -0.5257)) this is (-0.659, 0.751, -0.041), measured in engine: 7.6 m from the
## pad centre, 11.3 m from the spawn, 6.2 m off the main trail. Its pitch is flat (height spread
## 0.000 m over a 2 m ring) and no prop node stands within 4.97 m of it (measured, J1 probe).
static func stall_dir(data: PlanetData) -> Vector3:
	var pad := data.pad_dir.normalized()
	return _walk(pad, data.spawn_dir.normalized(), STALL_BEARING_DEG, STALL_FROM_PAD_M, _radius(data))


## The trail end in front of the stall.
static func stall_front_dir(data: PlanetData) -> Vector3:
	var sd := stall_dir(data)
	return _walk(sd, _stall_look_target(data), 0.0, STALL_FRONT_M, _radius(data))


## What the stall's front looks at: a point a little way down the pad->spawn trail, so the counter
## faces the player walking off the pad rather than the jungle behind it.
static func _stall_look_target(data: PlanetData) -> Vector3:
	var pad := data.pad_dir.normalized()
	return pad.slerp(data.spawn_dir.normalized(), 0.28).normalized()


## Unit tangent at stall_dir() for the stall's front (use as `forward_hint`).
static func stall_facing(data: PlanetData) -> Vector3:
	var sd := stall_dir(data)
	return _toward(sd, _stall_look_target(data))


## The trail network as great-circle arcs [a, b]. EIGHT, which is the ground shader's path_a/path_b
## array size - one more and the ninth would be reserved and scatter-free but never painted.
##   0    spawn -> pad (STRAIGHT)         the main walk. Straight on purpose: RocketPad lays its own
##                                        stepping stones and the FLY sign on the straight pad->spawn
##                                        great circle, so a bent main trail left them in the ferns.
##   1-3  spawn -> east loop -> pad       a second, winding way round, past the swamp pools
##   4    pad -> stall front              the short spur to the shop
##   5-6  spawn -> back trail             into the far side of the jungle
##   7    main trail -> west spur         a dead-end nook off the main walk
static func trail_arcs(data: PlanetData) -> Array[PackedVector3Array]:
	var r := _radius(data)
	var s := data.spawn_dir.normalized()
	var p := data.pad_dir.normalized()
	var e1 := _walk(s, p, 74.0, 7.4, r)
	var e2 := _walk(s, p, 30.0, 12.6, r)
	var b1 := _walk(s, p, 196.0, 7.6, r)
	var b2 := _walk(b1, s, 160.0, 7.8, r)
	var m := s.slerp(p, 0.42).normalized()
	var w1 := _walk(m, p, -78.0, 6.8, r)
	var out: Array[PackedVector3Array] = []
	out.append(PackedVector3Array([s, p]))
	out.append(PackedVector3Array([s, e1]))
	out.append(PackedVector3Array([e1, e2]))
	out.append(PackedVector3Array([e2, p]))
	out.append(PackedVector3Array([p, stall_front_dir(data)]))
	out.append(PackedVector3Array([s, b1]))
	out.append(PackedVector3Array([b1, b2]))
	out.append(PackedVector3Array([m, w1]))
	return out


## Points every `step_m` along every trail arc, ends included.
static func trail_samples(data: PlanetData, step_m: float = TRAIL_SAMPLE_M) -> PackedVector3Array:
	var r := _radius(data)
	var out := PackedVector3Array()
	for arc in trail_arcs(data):
		var a := arc[0]
		var b := arc[1]
		var len_m := acos(clampf(a.dot(b), -1.0, 1.0)) * r
		var n := maxi(int(ceil(len_m / maxf(step_m, 0.2))), 1)
		for i in n + 1:
			out.append(a.slerp(b, float(i) / float(n)).normalized())
	return out
