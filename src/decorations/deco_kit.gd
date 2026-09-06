class_name DecoKit
extends PlanetMeshKit
## Mesh composer for decoration items. Extends PlanetMeshKit (sphere / capsule / cylinder / torus /
## lathe / quad, one vertex-colored surface = one draw call) with the chunky shapes decorations need:
## light rounded boxes, cones, domes, tubes between two points, extruded 2D polygons (stars, crescents,
## gears, rounded signs) and a subdivided flag panel with UVs for the wave shader.
##
##   var kit := DecoKit.new()
##   kit.rbox(Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 1.0), 0.22, Color("#ff7a59"))
##   var mesh := kit.commit()
##
## Prop-local space: +Y up, origin at the ground contact point, faces -Z. Colors are sRGB.
##
## RING RESOLUTION (docs/ARCHITECTURE.md 10: props <= 2k tris)
## Every round primitive here ends up in `lathe`, and a lathe costs `(profile - 1) * segments * 2`
## triangles, so the ring count is the single biggest lever on a decoration's budget. Decorations are
## small objects viewed from the 6.5 m gameplay camera, where the difference between a 20-sided and a
## 15-sided collar is under a pixel — so `lathe` and `sphere` scale the requested count by DETAIL
## (with a floor, so nothing ever collapses into a triangle). Ask for the resolution the shape wants;
## the kit spends what the shape is actually worth on screen.

## Ring-resolution multiplier applied to every lathed primitive and every sphere.
const DETAIL := 0.74
## Never go below this many segments, however small the caller's request. Six is the point where a
## wire or a thin strut stops reading as round; anything thicker asks for more anyway.
const MIN_SEGMENTS := 6


## Requested ring count scaled to what a prop actually needs on screen.
static func detail_segments(segments: int) -> int:
	return maxi(MIN_SEGMENTS, int(round(float(segments) * DETAIL)))


func lathe(profile: PackedVector2Array, segments: int, xf: Transform3D, color: Color, smooth: bool = true, closed_profile: bool = false) -> void:
	super(profile, detail_segments(segments), xf, color, smooth, closed_profile)


## Chunky rounded box. `level` is an icosphere subdivision: 0/1/2/3 = 20 / 80 / 320 / 1280 triangles.
## Use 1 for hero shapes and 0 for small bits; 2 is only worth it on something you stand next to.
func rbox(center: Vector3, size: Vector3, radius: float, color: Color, basis: Basis = Basis.IDENTITY, level: int = 1) -> void:
	var rr := minf(radius, minf(size.x, minf(size.y, size.z)) * 0.5)
	var inner := size * 0.5 - Vector3(rr, rr, rr)
	var topo := PlanetMeshBuilder.icosphere_topology(clampi(level, 0, 3))
	var dirs: PackedVector3Array = topo["dirs"]
	var ix: PackedInt32Array = topo["indices"]
	var base := vertex_count()
	for d in dirs:
		var p := Vector3(signf(d.x) * inner.x, signf(d.y) * inner.y, signf(d.z) * inner.z) + d * rr
		_push(basis * p + center, (basis * d).normalized(), color, Vector2.ZERO)
	_push_indices(base, ix)

## Cone / truncated cone standing on `base_pos` along the basis Y axis.
func cone(base_pos: Vector3, r_bottom: float, r_top: float, height: float, color: Color, basis: Basis = Basis.IDENTITY, segments: int = 16) -> void:
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(r_bottom, 0.0), Vector2(r_top, height)])
	if r_top > 0.001:
		prof.append(Vector2(0.0, height))
	lathe(prof, segments, Transform3D(basis, base_pos), color, false)

## Hemisphere dome sitting at `center` (flat side down), optionally squashed by `squash`.
func dome(center: Vector3, r: float, color: Color, squash: float = 1.0, basis: Basis = Basis.IDENTITY, segments: int = 16) -> void:
	var prof := PackedVector2Array()
	var rings := 6
	for i in rings + 1:
		var a := PI * 0.5 * float(i) / float(rings)
		prof.append(Vector2(cos(a) * r, sin(a) * r * squash))
	lathe(prof, segments, Transform3D(basis, center), color, true)

## Flat filled circle facing +Y (single sided, normal up).
func disc(center: Vector3, r: float, color: Color, basis: Basis = Basis.IDENTITY, segments: int = 20) -> void:
	lathe(PackedVector2Array([Vector2(r, 0.0), Vector2(0.0, 0.0)]), segments, Transform3D(basis, center), color, false)

## Capsule-ended tube between two points (pipes, cables, chair frames). `from`/`to` are the tips.
## Lathed rather than using CapsuleMesh: ~100 triangles instead of ~450, which matters because a
## single item can use a dozen of them. `caps` is the rings per end cap — 2 is indistinguishable from
## 3 on anything thinner than a wrist, and saves 2 of every 7 triangles in the tube.
func tube(from: Vector3, to: Vector3, r: float, color: Color, segments: int = 10, caps: int = 2) -> void:
	var d := to - from
	var len := d.length()
	if len < 0.0001:
		return
	var body := maxf(len - 2.0 * r, 0.0)
	var prof := PackedVector2Array()
	for i in caps + 1:
		var a := PI * 0.5 * float(i) / float(caps)
		prof.append(Vector2(sin(a) * r, r - cos(a) * r))
	for i in caps + 1:
		var a2 := PI * 0.5 * float(i) / float(caps)
		prof.append(Vector2(cos(a2) * r, r + body + sin(a2) * r))
	lathe(prof, segments, Transform3D(axis_basis(d), from), color, true)


## Torus in the plane of the basis. Lathed instead of TorusMesh (~160 triangles instead of ~580).
## `rings` is the tube cross-section resolution: 4 is plenty for a collar or a rim you never stand
## inside, 6 for a hero ring. Cost is rings * segments * 2 triangles.
func torus(center: Vector3, R: float, r: float, color: Color, basis: Basis = Basis.IDENTITY, segments: int = 18, rings: int = 5) -> void:
	var prof := PackedVector2Array()
	for i in rings + 1:
		var a := TAU * float(i) / float(rings)
		prof.append(Vector2(R + cos(a) * r, sin(a) * r))
	lathe(prof, segments, Transform3D(basis, center), color, true, true)


## Sphere with a decoration-friendly default resolution (10 segments instead of the base 20). A
## decoration sphere is usually a knob, a berry or a foot; 10x5 reads identically to 12x6 at the
## gameplay camera and costs a third less.
func sphere(center: Vector3, r: float, color: Color, scale: Vector3 = Vector3.ONE, segments: int = 10, basis: Basis = Basis.IDENTITY) -> void:
	super(center, r, color, scale, detail_segments(segments), basis)

## Straight bar (no rounded ends) between two points.
func bar(from: Vector3, to: Vector3, r: float, color: Color, segments: int = 10) -> void:
	var d := to - from
	var len := d.length()
	if len < 0.0001:
		return
	cone(from, r, r, len, color, axis_basis(d), segments)

## A basis whose Y axis points along `dir` (used for tubes, bars and spin axes).
static func axis_basis(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var ref := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)

# ============================================================================================ 2D polygons
## Extrudes a closed 2D polygon (XY plane) to `thickness` along Z, centered on the plane.
## Gives crisp chunky signs, stars, crescents and gears in one call.
func extrude(points: PackedVector2Array, thickness: float, color: Color, xf: Transform3D = Transform3D.IDENTITY) -> void:
	var n := points.size()
	if n < 3:
		return
	var pts := points
	if _signed_area(pts) < 0.0:
		var rev := PackedVector2Array()
		for i in n:
			rev.append(pts[n - 1 - i])
		pts = rev
	var tri := Geometry2D.triangulate_polygon(pts)
	var hz := thickness * 0.5
	var nb := xf.basis.inverse().transposed()
	# front cap (+Z) and back cap (-Z)
	for side in 2:
		var z := hz if side == 0 else -hz
		var nrm: Vector3 = (nb * Vector3(0.0, 0.0, 1.0 if side == 0 else -1.0)).normalized()
		var base := vertex_count()
		for p in pts:
			_push(xf * Vector3(p.x, p.y, z), nrm, color, Vector2(p.x, p.y))
		var idx := PackedInt32Array()
		var i := 0
		while i < tri.size():
			if side == 0:
				idx.append_array(PackedInt32Array([tri[i], tri[i + 2], tri[i + 1]]))
			else:
				idx.append_array(PackedInt32Array([tri[i], tri[i + 1], tri[i + 2]]))
			i += 3
		_push_indices(base, idx)
	# side wall
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var e := b - a
		if e.length_squared() < 0.000001:
			continue
		var wn: Vector3 = (nb * Vector3(e.y, -e.x, 0.0).normalized()).normalized()
		var base2 := vertex_count()
		_push(xf * Vector3(a.x, a.y, hz), wn, color, Vector2.ZERO)
		_push(xf * Vector3(b.x, b.y, hz), wn, color, Vector2.ZERO)
		_push(xf * Vector3(b.x, b.y, -hz), wn, color, Vector2.ZERO)
		_push(xf * Vector3(a.x, a.y, -hz), wn, color, Vector2.ZERO)
		_push_indices(base2, PackedInt32Array([0, 2, 1, 0, 3, 2]))

## N-pointed star polygon (point up).
static func star_poly(r_outer: float, r_inner: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(3, points)
	for i in n * 2:
		var r: float = r_outer if i % 2 == 0 else r_inner
		var a := PI * 0.5 + TAU * float(i) / float(n * 2)
		out.append(Vector2(cos(a) * r, sin(a) * r))
	return out

## Crescent moon polygon: circle of radius R minus a circle of radius r offset by d on +X.
## Extruding costs ~4 triangles per point, so `segments` is the single biggest knob on a moon lamp.
static func crescent_poly(R: float, r: float, d: float, segments: int = 18) -> PackedVector2Array:
	var out := PackedVector2Array()
	var x := clampf((d * d + R * R - r * r) / maxf(2.0 * d, 0.0001), -R, R)
	var y := sqrt(maxf(R * R - x * x, 0.0))
	var t0 := atan2(y, x)
	var p0 := atan2(y, x - d)
	for i in segments + 1:
		var a: float = lerpf(t0, TAU - t0, float(i) / float(segments))
		out.append(Vector2(cos(a) * R, sin(a) * R))
	# walk the cutting circle the LONG way (through 180 deg) so the bite is concave, not a full disc
	for i in segments + 1:
		var a2: float = lerpf(-p0, p0 - TAU, float(i) / float(segments))
		out.append(Vector2(d + cos(a2) * r, sin(a2) * r))
	return out

## Rounded rectangle polygon centered on the origin.
static func round_rect_poly(w: float, h: float, r: float, corner_steps: int = 4) -> PackedVector2Array:
	var out := PackedVector2Array()
	var rr := minf(r, minf(w, h) * 0.5)
	var cx := w * 0.5 - rr
	var cy := h * 0.5 - rr
	var centers := [Vector2(cx, cy), Vector2(-cx, cy), Vector2(-cx, -cy), Vector2(cx, -cy)]
	for c in 4:
		var start := PI * 0.5 * float(c)
		for i in corner_steps + 1:
			var a: float = start + PI * 0.5 * float(i) / float(corner_steps)
			out.append(centers[c] + Vector2(cos(a), sin(a)) * rr)
	return out

## Gear polygon with rounded-ish teeth.
static func gear_poly(r: float, tooth: float, teeth: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(4, teeth)
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var step := TAU / float(n)
		for s in 4:
			var frac: float = [0.06, 0.2, 0.3, 0.44][s]
			var rad: float = r + tooth if s == 1 or s == 2 else r
			var a: float = a0 + step * frac
			out.append(Vector2(cos(a) * rad, sin(a) * rad))
		for s in 2:
			var a2: float = a0 + step * [0.56, 0.94][s]
			out.append(Vector2(cos(a2) * r, sin(a2) * r))
	return out

static func _signed_area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var q := p[i]
		var w := p[(i + 1) % p.size()]
		a += q.x * w.y - w.x * q.y
	return a * 0.5

# ============================================================================================ flag
## Subdivided flag panel hanging on +X from the pole, spanning `w` x `h`, centered vertically at `center`.
## UV.x = 0 at the pole -> 1 at the free edge, so flag_wave.gdshader can bend it.
func flag_panel(center: Vector3, w: float, h: float, color: Color, cols: int = 10, rows: int = 3, basis: Basis = Basis.IDENTITY) -> void:
	var base := vertex_count()
	var nb := basis
	for r in rows + 1:
		for c in cols + 1:
			var u := float(c) / float(cols)
			var v := float(r) / float(rows)
			var p := Vector3(u * w, (0.5 - v) * h, 0.0)
			_push(nb * p + center, (nb * Vector3(0.0, 0.0, 1.0)).normalized(), color, Vector2(u, v))
	var idx := PackedInt32Array()
	for r in rows:
		for c in cols:
			var a := r * (cols + 1) + c
			var b := a + 1
			var d := a + cols + 1
			var e := d + 1
			idx.append_array(PackedInt32Array([a, b, d, b, e, d]))
	_push_indices(base, idx)
	# back face (mirrored winding + normal) so the flag is visible from both sides
	var base2 := vertex_count()
	for r in rows + 1:
		for c in cols + 1:
			var u := float(c) / float(cols)
			var v := float(r) / float(rows)
			var p := Vector3(u * w, (0.5 - v) * h, 0.0)
			_push(nb * p + center, (nb * Vector3(0.0, 0.0, -1.0)).normalized(), color, Vector2(u, v))
	var idx2 := PackedInt32Array()
	for r in rows:
		for c in cols:
			var a := r * (cols + 1) + c
			var b := a + 1
			var d := a + cols + 1
			var e := d + 1
			idx2.append_array(PackedInt32Array([a, d, b, b, d, e]))
	_push_indices(base2, idx2)

# ============================================================================================ internals
func _push(v: Vector3, n: Vector3, c: Color, uv: Vector2) -> void:
	# Reuses the parent's arrays through the only public door it offers: a one-triangle-free append.
	_verts.append(v)
	_norms.append(n)
	_cols.append(PlanetMeshKit._lin(c))
	_uvs.append(uv)

func _push_indices(base: int, ix: PackedInt32Array) -> void:
	for i in ix.size():
		_idx.append(base + ix[i])
