class_name AstroShapes
extends RefCounted
## Procedural meshes for the astronaut: the BUBBLE helmet shell with its big tilted front window,
## the OPAQUE navy pane that fills it, the raised accent rim, the two comma highlights, the rear
## shell segment, the two-tone torso bean, and the ball-cap dome.
##
## The base surface is a SUPERELLIPSOID (see `SHELL_EXP`) — a near-sphere with a softly flattened
## crown and faceplate rather than a true ball. Every helmet mesh here, and every piece of hardware
## astronaut_model.gd plants on the shell (ear pods, lamp), is placed through `surface_point` /
## `surface_normal`, so they all share one form.
##
## Everything front-facing is built as a surface of revolution around the character's FORWARD axis
## (-Z) so the visor window stays a clean circle no matter how coarse the tessellation
## is. `alpha` is the angle away from -Z (0 = dead centre of the visor), `beta` runs around it
## (90° = up, 180° = the character's own right). Rotate the node that owns the mesh to aim that
## axis somewhere else: with -Z along +X the alpha rings become the sagittal meridian, with -Z
## along +Y they become latitude bands (which is how the rear shell segment is built).
##
## `tilt` (radians, positive = aim DOWN) pitches that cap axis without touching the dome. Every
## reference astronaut in reference/"astronaut 1-3.jpeg" has its visor low on the bubble with a
## clean crown of shell above it; a window centred on the dome's own equator is a DIVE MASK, which
## is exactly what docs/STYLE_GUIDE.md R2.7 is about. Rotating the node instead would tilt the
## bubble itself (and the ear pods, and the crown), so the tilt lives in the direction lookup and
## the superellipsoid stays upright.
##
## Meshes are cached by parameters: every astronaut in a scene shares one helmet mesh.
##
##   AstroShapes.helmet_shell(HELMET_R, WINDOW_ANGLE, 0.014, 30, 11, -1, WINDOW_TILT)
##   AstroShapes.glass_cap(HELMET_R - thick, WINDOW_ANGLE, 30, 3, WINDOW_TILT)    # the navy pane
##   AstroShapes.cap_tube(r, alpha, 0.0, TAU, 0.0105, 0.0072, 26, 3, false, tilt) # rim (narrow!)
##   AstroShapes.cap_patch(r, a0, a1, b0, b1)                        # any WIDE flat panel
##   AstroShapes.cap_band(r, alpha, b0, b1, hw, true)                # highlight streak
##   AstroShapes.hair_cap(r + 0.019, 0.016, {...})                   # ball-cap dome (radii, not scalar)
##   AstroShapes.split_box(Vector3(0.49, 0.39, 0.375), 0.16, 5)      # two-tone torso bean

## Godot treats a triangle as front-facing when cross(b - a, c - a) points AGAINST the shading
## normal (clockwise winding seen from outside). Verified against SphereMesh's own arrays.
const WINDING_SIGN := -1.0

## ---- The helmet is a SUPERELLIPSOID, not an ellipsoid (docs/STYLE_GUIDE.md R2.3: *"Less round …
## If a form can be described as 'a ball', rebuild it"*). The base surface is
##     |x/a|^n + |y/b|^n + |z/c|^n = 1
## and `SHELL_EXP` is n. n = 2 is the old sphere; n = 2.4 keeps every edge soft but flattens the
## crown, the sides and the faceplate into readable planes joined by wide chamfers, so the dome
## carries a shading break of its own and the silhouette is a squircle rather than a circle.
## Everything on the helmet — shell, visor pane, rim, streak, patches, tubes and the surface-planted
## hardware in astronaut_model.gd — is placed through `surface_point` / `surface_normal`, so the whole
## family follows one number and nothing can drift off the shell.
## Cost: zero triangles (the parameterisation is unchanged, only where each vertex lands).
##
## REVISION 2 / R2.7 pulled this down from 2.4 to 2.1. 2.4 gave a squircle with genuinely flat
## sides and a flat crown — a good answer to R2.3 ("if a form can be described as a ball, rebuild
## it") but the wrong form for this object: every astronaut reference is a **rigid pressure bubble**,
## and the flat-sided version read as a moulded hood. 2.1 keeps a soft flattening of the crown and
## faceplate (so the dome still carries its own shading break) while the silhouette goes back to a
## bubble, and it is what lets the collar ring clamp cleanly around the narrowing base.
const SHELL_EXP := 2.1

static var _cache: Dictionary = {}


## Unit direction at (alpha, beta) around the forward axis. alpha 0 = -Z, beta 90° = +Y.
## `tilt` pitches the whole cap frame about +X; positive aims it DOWN (see the header).
static func front_dir(alpha: float, beta: float, tilt: float = 0.0) -> Vector3:
	var sa := sin(alpha)
	var d := Vector3(sa * cos(beta), sa * sin(beta), -cos(alpha))
	if is_zero_approx(tilt):
		return d
	var c := cos(tilt)
	var s := sin(tilt)
	return Vector3(d.x, d.y * c + d.z * s, -d.y * s + d.z * c)


## Point where the ray along unit `d` leaves the superellipsoid of radii `r`. With SHELL_EXP == 2
## this is exactly the old ellipsoid point `d * r`, so the whole helmet family degrades gracefully.
static func surface_point(r: Vector3, d: Vector3) -> Vector3:
	var n := SHELL_EXP
	var s := pow(absf(d.x), n) + pow(absf(d.y), n) + pow(absf(d.z), n)
	var t := pow(maxf(s, 1e-9), -1.0 / n)
	return Vector3(t * d.x * r.x, t * d.y * r.y, t * d.z * r.z)


## Outward unit normal of that superellipsoid at the same direction. It is the gradient of
## |x/a|^n + |y/b|^n + |z/c|^n, which reduces to (dx/a, dy/b, dz/c) — the ellipsoid normal — at n = 2.
static func surface_normal(r: Vector3, d: Vector3) -> Vector3:
	var e := SHELL_EXP - 1.0
	var g := Vector3(
			signf(d.x) * pow(absf(d.x), e) / r.x,
			signf(d.y) * pow(absf(d.y), e) / r.y,
			signf(d.z) * pow(absf(d.z), e) / r.z)
	if g.length_squared() < 1e-12:
		return d.normalized()
	return g.normalized()


# ============================================================================= helmet
## Opaque helmet shell: an ellipsoid of radii `r` with a circular window of half-angle `hole`
## punched out of the front and walled with `thick`, so the window sits in a real recess.
##
## The window is filled by an OPAQUE pane (`visor_cap` at radius r - thick, same `hole` angle and
## the same `segs`), which shares the rim wall's inner edge exactly. Shell + rim wall + pane is a
## closed solid, so the dome needs no inner lining at all — that lining used to be half the mesh
## (2,112 of 4,224 tris) and existed only because you could see through the tinted glass.
##
## `split_ring` colour-blocks the dome: rings BEFORE it go to surface 0 (the light suit shell) and
## rings from it to the back pole go to surface 1. Since alpha is measured from the window centre,
## surface 1 is the rear/upper-back of the helmet — the part the gameplay camera looks at almost
## all the time, and the cheapest possible way to break up the single white mass (zero extra tris).
## Pass -1 for a single-surface dome.
static func helmet_shell(r: Vector3, hole: float, thick: float, segs: int = 44, rings: int = 24,
		split_ring: int = -1, tilt: float = 0.0) -> ArrayMesh:
	var key := "shell|%s|%.4f|%.4f|%d|%d|%d|%.4f" % [str(r), hole, thick, segs, rings, split_ring, tilt]
	if _cache.has(key):
		return _cache[key]
	var ri := Vector3(r.x - thick, r.y - thick, r.z - thick)
	var split := rings if split_ring < 0 or split_ring > rings else split_ring
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_emit_cap_range(st, r, hole, PI, segs, rings, 0, split, false, tilt)
	# rim wall closing the window edge (part of the front shell surface)
	for j in segs:
		var b0 := TAU * float(j) / float(segs)
		var b1 := TAU * float(j + 1) / float(segs)
		var n0 := -_alpha_tangent(r, hole, b0, tilt)
		var n1 := -_alpha_tangent(r, hole, b1, tilt)
		_quad(st, _pt(ri, hole, b0, tilt), _pt(ri, hole, b1, tilt), _pt(r, hole, b1, tilt), _pt(r, hole, b0, tilt), n0, n1, n1, n0)
	var m: ArrayMesh = st.commit()
	if split < rings:
		var st_back := SurfaceTool.new()
		st_back.begin(Mesh.PRIMITIVE_TRIANGLES)
		_emit_cap_range(st_back, r, hole, PI, segs, rings, split, rings, false, tilt)
		st_back.commit(m)
	_cache[key] = m
	return m


## The visor pane: a cap of half-angle `cap` on the front of an ellipsoid of radii `r`. Give it the
## shell's `segs` and `r - thick` and it seals the window recess seamlessly.
static func glass_cap(r: Vector3, cap: float, segs: int = 40, rings: int = 12, tilt: float = 0.0) -> ArrayMesh:
	var key := "glass|%s|%.4f|%d|%d|%.4f" % [str(r), cap, segs, rings, tilt]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_emit_cap(st, r, 0.0, cap, segs, rings, false, tilt)
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


## Flat band lying on the ellipsoid surface, centred on the ring alpha = `alpha_c` and running from
## beta `b0` to `b1` with half-width `hw` (radians of alpha). With `taper` the width falls to a
## point at both ends — that is the crisp diagonal highlight streak on the visor glass.
static func cap_band(r: Vector3, alpha_c: float, b0: float, b1: float, hw: float, taper: bool, segs: int = 28,
		tilt: float = 0.0) -> ArrayMesh:
	var key := "band|%s|%.4f|%.4f|%.4f|%.4f|%s|%d|%.4f" % [str(r), alpha_c, b0, b1, hw, taper, segs, tilt]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in segs:
		var t0 := float(j) / float(segs)
		var t1 := float(j + 1) / float(segs)
		var bb0 := lerpf(b0, b1, t0)
		var bb1 := lerpf(b0, b1, t1)
		var w0 := hw * (pow(sin(PI * t0), 0.55) if taper else 1.0)
		var w1 := hw * (pow(sin(PI * t1), 0.55) if taper else 1.0)
		var p00 := _pt(r, alpha_c - w0, bb0, tilt)
		var p01 := _pt(r, alpha_c + w0, bb0, tilt)
		var p11 := _pt(r, alpha_c + w1, bb1, tilt)
		var p10 := _pt(r, alpha_c - w1, bb1, tilt)
		var n0 := _nm(r, alpha_c, bb0, tilt)
		var n1 := _nm(r, alpha_c, bb1, tilt)
		_quad(st, p00, p01, p11, p10, n0, n0, n1, n1)
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


## A single-sided patch of the ellipsoid surface: the (alpha, beta) rectangle [a0, a1] x [b0, b1].
## Use this, not `cap_tube`, for any WIDE flat panel. cap_tube approximates its cross-section with
## `sides` straight ribs, and a chord across 30 deg of a 0.37 m dome sags 12 mm through the shell —
## which is exactly the sawtooth z-fight a wide low tube produces. A patch has every vertex on the
## surface, so it hugs the dome at any width and costs segs * rings * 2 triangles.
static func cap_patch(r: Vector3, a0: float, a1: float, b0: float, b1: float, segs: int = 20, rings: int = 5,
		tilt: float = 0.0) -> ArrayMesh:
	var key := "patch|%s|%.4f|%.4f|%.4f|%.4f|%d|%d|%.4f" % [str(r), a0, a1, b0, b1, segs, rings, tilt]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings:
		var aa0 := lerpf(a0, a1, float(i) / float(rings))
		var aa1 := lerpf(a0, a1, float(i + 1) / float(rings))
		for j in segs:
			var bb0 := lerpf(b0, b1, float(j) / float(segs))
			var bb1 := lerpf(b0, b1, float(j + 1) / float(segs))
			_quad(st, _pt(r, aa0, bb0, tilt), _pt(r, aa1, bb0, tilt), _pt(r, aa1, bb1, tilt), _pt(r, aa0, bb1, tilt),
					_nm(r, aa0, bb0, tilt), _nm(r, aa1, bb0, tilt), _nm(r, aa1, bb1, tilt), _nm(r, aa0, bb1, tilt))
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


## Raised tube following the ring alpha = `alpha_c` (the accent rim around the visor window, the
## helmet's dorsal panel). Cross-section is an ellipse `hw` wide along the surface and `hh` tall off
## it, and — unlike `cap_band`, whose quads are flat chords that sink inside the sphere as soon as
## the band is more than a couple of degrees wide — every rib is re-projected onto the surface, so
## a WIDE panel still hugs the dome — but only if `sides` is large enough that the straight ribs do
## not chord across the curvature. Rule of thumb: keep `hw / r` under ~0.15 rad, or use `cap_patch`.
## With `taper` the whole profile shrinks to nothing at both ends, turning the strip into a fin
## that melts back into the shell.
static func cap_tube(r: Vector3, alpha_c: float, b0: float, b1: float, hw: float, hh: float, segs: int = 44, sides: int = 8, taper: bool = false,
		tilt: float = 0.0) -> ArrayMesh:
	var key := "tube|%s|%.4f|%.4f|%.4f|%.4f|%.4f|%d|%d|%s|%.4f" % [str(r), alpha_c, b0, b1, hw, hh, segs, sides, taper, tilt]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[PackedVector3Array] = []
	var nrm: Array[PackedVector3Array] = []
	for j in segs + 1:
		var t := float(j) / float(segs)
		var b := lerpf(b0, b1, t)
		var k_taper := pow(sin(PI * t), 0.55) if taper else 1.0
		var ring := PackedVector3Array()
		var rn := PackedVector3Array()
		for k in sides + 1:
			var phi := TAU * float(k) / float(sides)
			# Slide along the SURFACE by hw * cos(phi) (a change in alpha), then lift off it, so a
			# wide cross-section follows the curvature instead of cutting a chord through it.
			var da := hw * k_taper * cos(phi) / maxf(_alpha_scale(r, alpha_c, b, tilt), 1e-4)
			var base := _pt(r, alpha_c + da, b, tilt)
			var bn := _nm(r, alpha_c + da, b, tilt)
			var bt := _alpha_tangent(r, alpha_c + da, b, tilt)
			ring.append(base + bn * (hh * k_taper * sin(phi)))
			rn.append((bn * sin(phi) + bt * cos(phi)).normalized())
		pts.append(ring)
		nrm.append(rn)
	for j in segs:
		for k in sides:
			_quad(st, pts[j][k], pts[j][k + 1], pts[j + 1][k + 1], pts[j + 1][k],
					nrm[j][k], nrm[j][k + 1], nrm[j + 1][k + 1], nrm[j + 1][k])
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


# ============================================================================= hair
## A chunky shell over the top of the head whose lower edge dips lower at the front (with
## `scallops` soft points and a side part) than at the sides and back — originally the astronaut's
## bowl-cut hair, which went with the face in REVISION 2; the ball cap still uses it. `r` is the
## outer radius, `thick` the wall so the open edge shows a solid lip, not a paper-thin sliver.
## opts: front_deg, side_deg, back_deg, scallop_deg, scallops, part_deg (all floats/ints).
##
## `r` is a Vector3 of superellipsoid radii, not a scalar: the helmet is a squircle now (SHELL_EXP),
## so a spherical cap of any single radius either floats 4 cm off the flat sides or is punched
## through by the shell at the chamfers. Pass the shell radii inflated by the clearance you want.
static func hair_cap(r: Vector3, thick: float, opts: Dictionary = {}, segs: int = 44, rings: int = 16) -> ArrayMesh:
	var front := deg_to_rad(float(opts.get("front_deg", 63.0)))
	var side := deg_to_rad(float(opts.get("side_deg", 100.0)))
	var back := deg_to_rad(float(opts.get("back_deg", 116.0)))
	var scal := deg_to_rad(float(opts.get("scallop_deg", 11.0)))
	var lobes := int(opts.get("scallops", 3))
	var part := deg_to_rad(float(opts.get("part_deg", 7.0)))
	var key := "hair|%s|%.4f|%.3f|%.3f|%.3f|%.3f|%d|%.3f|%d|%d" % [str(r), thick, front, side, back, scal, lobes, part, segs, rings]
	if _cache.has(key):
		return _cache[key]
	var edge := PackedFloat32Array()
	edge.resize(segs + 1)
	for j in segs + 1:
		var phi := TAU * float(j) / float(segs)
		var cf := cos(phi)
		var f := maxf(cf, 0.0)
		var tmax := side + (front - side) * f + (back - side) * maxf(-cf, 0.0)
		tmax += scal * pow(f, 1.2) * absf(sin(float(lobes) * phi))
		tmax += part * sin(phi) * f
		edge[j] = tmax
	var ri := Vector3(r.x - thick, r.y - thick, r.z - thick)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_emit_hair_surface(st, r, edge, segs, rings, false)
	_emit_hair_surface(st, ri, edge, segs, rings, true)
	for j in segs:
		var pa := _hair_pt(r, edge[j], TAU * float(j) / float(segs))
		var pb := _hair_pt(r, edge[j + 1], TAU * float(j + 1) / float(segs))
		var qa := _hair_pt(ri, edge[j], TAU * float(j) / float(segs))
		var qb := _hair_pt(ri, edge[j + 1], TAU * float(j + 1) / float(segs))
		var na := _hair_dir(edge[j] + 0.4, TAU * float(j) / float(segs))
		var nb := _hair_dir(edge[j + 1] + 0.4, TAU * float(j + 1) / float(segs))
		_quad(st, qa, qb, pb, pa, na, nb, nb, na)
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


static func _emit_hair_surface(st: SurfaceTool, r: Vector3, edge: PackedFloat32Array, segs: int, rings: int, flip: bool) -> void:
	for j in segs:
		var b0 := TAU * float(j) / float(segs)
		var b1 := TAU * float(j + 1) / float(segs)
		for i in rings:
			var t0 := float(i) / float(rings)
			var t1 := float(i + 1) / float(rings)
			var a00 := edge[j] * t0
			var a01 := edge[j] * t1
			var a10 := edge[j + 1] * t0
			var a11 := edge[j + 1] * t1
			var s := -1.0 if flip else 1.0
			_quad(st, _hair_pt(r, a00, b0), _hair_pt(r, a01, b0), _hair_pt(r, a11, b1), _hair_pt(r, a10, b1),
					_hair_nm(r, a00, b0) * s, _hair_nm(r, a01, b0) * s, _hair_nm(r, a11, b1) * s, _hair_nm(r, a10, b1) * s)


## Direction at polar angle `theta` from +Y and azimuth `phi` (0 = the character's front, -Z).
static func _hair_dir(theta: float, phi: float) -> Vector3:
	var stt := sin(theta)
	return Vector3(stt * sin(phi), cos(theta), -stt * cos(phi))


static func _hair_pt(r: Vector3, theta: float, phi: float) -> Vector3:
	return surface_point(r, _hair_dir(theta, phi))


## Superellipsoid normal in the hair frame (polar angle from +Y), matching `_nm` in the cap frame.
static func _hair_nm(r: Vector3, theta: float, phi: float) -> Vector3:
	return surface_normal(r, _hair_dir(theta, phi))


# ============================================================================= colour-blocked body
## A rounded box (the chibi torso bean) cut into TWO surfaces by a perfectly flat horizontal seam,
## so one clean silhouette carries two colour blocks — an Animal Crossing jacket that ends at the
## hip with trousers taking over below it. Surface 0 is everything above the seam, surface 1
## everything below.
##
## The generating grid is a UV sphere pushed out to the box corners, so every latitude ring is a
## horizontal circle and the seam at ring `split_ring` (1 .. rings-1, counted from the top pole) is
## exactly level — no stair-stepping, no z-fighting decal shell over the torso.
##   AstroShapes.split_box(Vector3(0.49, 0.39, 0.375), 0.16, 7)
static func split_box(size: Vector3, radius: float, split_ring: int, segs: int = 26, rings: int = 13) -> ArrayMesh:
	var key := "sbox|%s|%.4f|%d|%d|%d" % [str(size), radius, split_ring, segs, rings]
	if _cache.has(key):
		return _cache[key]
	var half := size * 0.5
	var r: float = minf(radius, minf(half.x, minf(half.y, half.z)))
	var cut: int = clampi(split_ring, 1, rings - 1)
	var pts: Array[PackedVector3Array] = []
	var nrm: Array[PackedVector3Array] = []
	for i in rings + 1:
		var theta := PI * float(i) / float(rings)
		var row := PackedVector3Array()
		var nrow := PackedVector3Array()
		for j in segs + 1:
			var phi := TAU * float(j) / float(segs)
			var n := Vector3(sin(theta) * sin(phi), cos(theta), -sin(theta) * cos(phi)).normalized()
			row.append(box_point(n, half, r))
			nrow.append(n)
		pts.append(row)
		nrm.append(nrow)
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bottom := SurfaceTool.new()
	bottom.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings:
		var st: SurfaceTool = top if i < cut else bottom
		for j in segs:
			_quad(st, pts[i][j], pts[i + 1][j], pts[i + 1][j + 1], pts[i][j + 1],
					nrm[i][j], nrm[i + 1][j], nrm[i + 1][j + 1], nrm[i][j + 1])
	var m: ArrayMesh = top.commit()
	bottom.commit(m)
	_cache[key] = m
	return m


## World height of the seam produced by `split_box`, relative to the box centre — so the waistband
## belt can be placed exactly on it instead of by eye.
static func split_box_seam_y(size: Vector3, radius: float, split_ring: int, rings: int = 13) -> float:
	var half := size * 0.5
	var r: float = minf(radius, minf(half.x, minf(half.y, half.z)))
	var ny := cos(PI * float(clampi(split_ring, 1, rings - 1)) / float(rings))
	return ny * r + signf(ny) * (half.y - r)


## Half-extents of a `split_box` / rounded box at the ring whose normal has y = `ny`.
static func split_box_ring_extent(size: Vector3, radius: float, ny: float) -> Vector2:
	var half := size * 0.5
	var r: float = minf(radius, minf(half.x, minf(half.y, half.z)))
	var s := sqrt(maxf(1.0 - ny * ny, 0.0))
	return Vector2(s * r + (half.x - r), s * r + (half.z - r))


## Surface point of a rounded box for the sphere normal `n` (Minkowski sum of the box and a sphere).
static func box_point(n: Vector3, half: Vector3, r: float) -> Vector3:
	var p := n * r
	p.x += 0.0 if absf(n.x) < 0.02 else signf(n.x) * (half.x - r)
	p.y += 0.0 if absf(n.y) < 0.02 else signf(n.y) * (half.y - r)
	p.z += 0.0 if absf(n.z) < 0.02 else signf(n.z) * (half.z - r)
	return p


# ============================================================================= shared helpers
static func _pt(r: Vector3, a: float, b: float, tilt: float = 0.0) -> Vector3:
	return surface_point(r, front_dir(a, b, tilt))


static func _nm(r: Vector3, a: float, b: float, tilt: float = 0.0) -> Vector3:
	return surface_normal(r, front_dir(a, b, tilt))


## Unit surface tangent in the direction of increasing alpha.
static func _alpha_tangent(r: Vector3, a: float, b: float, tilt: float = 0.0) -> Vector3:
	var e := 0.004
	return (_pt(r, a + e, b, tilt) - _pt(r, a - e, b, tilt)).normalized()


## Metres of arc travelled per radian of alpha at (a, b) — lets a caller specify a tube's half-width
## in metres and convert it into the alpha step that walks that far along the surface.
static func _alpha_scale(r: Vector3, a: float, b: float, tilt: float = 0.0) -> float:
	var e := 0.004
	return (_pt(r, a + e, b, tilt) - _pt(r, a - e, b, tilt)).length() / (2.0 * e)


static func _emit_cap(st: SurfaceTool, r: Vector3, a0: float, a1: float, segs: int, rings: int, flip: bool,
		tilt: float = 0.0) -> void:
	_emit_cap_range(st, r, a0, a1, segs, rings, 0, rings, flip, tilt)


## `_emit_cap` restricted to the ring band [i0, i1), so one cap can be split across two surfaces.
static func _emit_cap_range(st: SurfaceTool, r: Vector3, a0: float, a1: float, segs: int, rings: int,
		i0: int, i1: int, flip: bool, tilt: float = 0.0) -> void:
	var s := -1.0 if flip else 1.0
	for i in range(i0, i1):
		var aa0 := lerpf(a0, a1, float(i) / float(rings))
		var aa1 := lerpf(a0, a1, float(i + 1) / float(rings))
		for j in segs:
			var b0 := TAU * float(j) / float(segs)
			var b1 := TAU * float(j + 1) / float(segs)
			_quad(st, _pt(r, aa0, b0, tilt), _pt(r, aa1, b0, tilt), _pt(r, aa1, b1, tilt), _pt(r, aa0, b1, tilt),
					_nm(r, aa0, b0, tilt) * s, _nm(r, aa1, b0, tilt) * s, _nm(r, aa1, b1, tilt) * s, _nm(r, aa0, b1, tilt) * s)


static func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		n0: Vector3, n1: Vector3, n2: Vector3, n3: Vector3) -> void:
	_tri(st, p0, p1, p2, n0, n1, n2)
	_tri(st, p0, p2, p3, n0, n2, n3)


## Emits one triangle with the winding Godot needs for the given shading normals (degenerates
## at the poles are dropped).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var g := (b - a).cross(c - a)
	if g.length_squared() < 1e-12:
		return
	var ref := na + nb + nc
	if g.dot(ref) * WINDING_SIGN < 0.0:
		var tp := b
		b = c
		c = tp
		var tn := nb
		nb = nc
		nc = tn
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)
