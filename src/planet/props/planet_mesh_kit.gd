class_name PlanetMeshKit
extends RefCounted
## Composes chunky, rounded prop meshes out of primitives, lathes and rounded boxes into ONE
## vertex-colored surface, so every prop is a single draw call with MaterialLib.toon_vertex_color().
##
##   var kit := PlanetMeshKit.new()
##   kit.sphere(Vector3(0, 1, 0), 0.5, Color.RED)
##   kit.lathe(profile, 16, Transform3D.IDENTITY, Color.BROWN)
##   var mesh := kit.commit()
##
## All positions are in prop-local space: +Y up, origin at the ground contact point, faces -Z.
## Colors are given in sRGB (hex) and baked as LINEAR vertex colors, because shaders read COLOR raw.

var _verts := PackedVector3Array()
var _norms := PackedVector3Array()
var _cols := PackedColorArray()
var _uvs := PackedVector2Array()
var _idx := PackedInt32Array()

static var _prim_cache: Dictionary = {}

## Appends surface `surface` of `mesh` with transform `xf`, tinted `color`. Handles indexed & non-indexed meshes.
func add_mesh(mesh: Mesh, xf: Transform3D, color: Color, surface: int = 0) -> void:
	var arr: Array = mesh.surface_get_arrays(surface)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var base := _verts.size()
	var nb := xf.basis.inverse().transposed()
	var has_uv := uv.size() == v.size()
	var lc := _lin(color)
	for i in v.size():
		_verts.append(xf * v[i])
		_norms.append((nb * n[i]).normalized())
		_cols.append(lc)
		_uvs.append(uv[i] if has_uv else Vector2.ZERO)
	if ix.is_empty():
		for i in v.size():
			_idx.append(base + i)
	else:
		for i in ix.size():
			_idx.append(base + ix[i])

## Sphere (optionally squashed via `scale`) centered at `center`.
func sphere(center: Vector3, r: float, color: Color, scale: Vector3 = Vector3.ONE, segments: int = 20, basis: Basis = Basis.IDENTITY) -> void:
	var key := "sph|%d" % segments
	if not _prim_cache.has(key):
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = segments
		sm.rings = maxi(4, int(segments / 2))
		_prim_cache[key] = sm
	var xf := Transform3D(basis * Basis.from_scale(scale * r), center)
	add_mesh(_prim_cache[key], xf, color)

## Capsule along local Y of the given basis, centered at `center`.
func capsule(center: Vector3, r: float, height: float, color: Color, basis: Basis = Basis.IDENTITY) -> void:
	var key := "cap|%.3f|%.3f" % [r, height]
	if not _prim_cache.has(key):
		var cm := CapsuleMesh.new()
		cm.radius = r
		cm.height = height
		cm.radial_segments = 16
		cm.rings = 6
		_prim_cache[key] = cm
	add_mesh(_prim_cache[key], Transform3D(basis, center), color)

## Cylinder / truncated cone along local Y, base at `base_pos`.
func cylinder(base_pos: Vector3, r_bottom: float, r_top: float, height: float, color: Color, basis: Basis = Basis.IDENTITY, segments: int = 16) -> void:
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(r_bottom, 0.0), Vector2(r_top, height), Vector2(0.0, height)])
	lathe(prof, segments, Transform3D(basis, base_pos), color, false)

## Torus in the XZ plane centered at `center` (ring radius R, tube radius r).
func torus(center: Vector3, R: float, r: float, color: Color, basis: Basis = Basis.IDENTITY, segments: int = 24) -> void:
	var key := "tor|%.3f|%.3f|%d" % [R, r, segments]
	if not _prim_cache.has(key):
		var tm := TorusMesh.new()
		tm.inner_radius = R - r
		tm.outer_radius = R + r
		tm.rings = segments
		tm.ring_segments = 12
		_prim_cache[key] = tm
	add_mesh(_prim_cache[key], Transform3D(basis, center), color)

## Rounded box: `size` full extents, corner radius `r`, centered at `center`. Built from a warped sphere so
## all faces stay smooth and the corners are perfectly round (Minkowski sum of box and sphere).
func rounded_box(center: Vector3, size: Vector3, r: float, color: Color, basis: Basis = Basis.IDENTITY) -> void:
	var rr := minf(r, minf(size.x, minf(size.y, size.z)) * 0.5)
	var inner := size * 0.5 - Vector3(rr, rr, rr)
	var topo := PlanetMeshBuilder.icosphere_topology(2)
	var dirs: PackedVector3Array = topo["dirs"]
	var ix: PackedInt32Array = topo["indices"]
	var base := _verts.size()
	var lc := _lin(color)
	for d in dirs:
		var p := Vector3(signf(d.x) * inner.x, signf(d.y) * inner.y, signf(d.z) * inner.z) + d * rr
		_verts.append(basis * p + center)
		_norms.append((basis * d).normalized())
		_cols.append(lc)
		_uvs.append(Vector2.ZERO)
	for i in ix.size():
		_idx.append(base + ix[i])

## Lathe: rotates a 2D profile (x = radius, y = height, ordered bottom -> top) around local Y.
## `smooth` = smooth normals along the profile; hard rings (mushroom rims, gear teeth) use false.
func lathe(profile: PackedVector2Array, segments: int, xf: Transform3D, color: Color, smooth: bool = true, closed_profile: bool = false) -> void:
	var n := profile.size()
	if n < 2:
		return
	# Per-profile-point 2D normals.
	var pn := PackedVector2Array()
	pn.resize(n)
	for i in n:
		var t := Vector2.ZERO
		if smooth:
			var prev: Vector2 = profile[i - 1] if i > 0 else (profile[n - 1] if closed_profile else profile[i])
			var next: Vector2 = profile[i + 1] if i < n - 1 else (profile[0] if closed_profile else profile[i])
			t = (next - prev)
		if t.length_squared() < 0.000001:
			var a: int = maxi(i - 1, 0)
			var b: int = mini(i + 1, n - 1)
			t = profile[b] - profile[a]
		if t.length_squared() < 0.000001:
			t = Vector2(0.0, 1.0)
		t = t.normalized()
		pn[i] = Vector2(t.y, -t.x)
	var nb := xf.basis.inverse().transposed()
	var base := _verts.size()
	var cols := segments + 1
	var lc := _lin(color)
	if smooth:
		for i in n:
			for s in cols:
				var ang := TAU * float(s) / float(segments)
				var c := cos(ang)
				var sn := sin(ang)
				var p := Vector3(profile[i].x * c, profile[i].y, profile[i].x * sn)
				var nn := Vector3(pn[i].x * c, pn[i].y, pn[i].x * sn)
				_verts.append(xf * p)
				_norms.append((nb * nn).normalized())
				_cols.append(lc)
				_uvs.append(Vector2(float(s) / float(segments), float(i) / float(n - 1)))
		for i in n - 1:
			for s in segments:
				var a := base + i * cols + s
				var b := a + 1
				var c2 := a + cols
				var d := c2 + 1
				_idx.append_array(PackedInt32Array([a, b, c2, b, d, c2]))
	else:
		# Hard normals per profile segment (each ring band is its own strip).
		for i in n - 1:
			var p0 := profile[i]
			var p1 := profile[i + 1]
			var t := (p1 - p0)
			if t.length_squared() < 0.000001:
				continue
			t = t.normalized()
			var n2 := Vector2(t.y, -t.x)
			var band_base := _verts.size()
			for s in cols:
				var ang := TAU * float(s) / float(segments)
				var c := cos(ang)
				var sn := sin(ang)
				var nn := Vector3(n2.x * c, n2.y, n2.x * sn)
				_verts.append(xf * Vector3(p0.x * c, p0.y, p0.x * sn))
				_norms.append((nb * nn).normalized())
				_cols.append(lc)
				_uvs.append(Vector2(float(s) / float(segments), 0.0))
				_verts.append(xf * Vector3(p1.x * c, p1.y, p1.x * sn))
				_norms.append((nb * nn).normalized())
				_cols.append(lc)
				_uvs.append(Vector2(float(s) / float(segments), 1.0))
			for s in segments:
				var a := band_base + s * 2
				var b := a + 1
				var c2 := a + 2
				var d := a + 3
				_idx.append_array(PackedInt32Array([a, c2, b, b, c2, d]))

## ACNH canopy/bush/cap tier: a slightly flattened dome with a scalloped (lobed) rim, a hard colour
## break at that rim and a FLAT underside disc in `under_color`. This is the shape language the style
## guide asks for — a readable silhouette with structure and a dark underside — as opposed to a
## cluster of overlapping spheres.
##   center     rim centre (the underside disc sits here, the dome rises to center.y + height)
##   radius     rim radius before lobing
##   height     dome height
##   lobes      number of scallops around the rim (0 = perfectly round)
##   lobe_depth scallop amplitude as a fraction of radius
##   flatness   < 1 flattens the top (0.6 = quite flat cap, 1.0 = ellipsoid dome)
##   skirt      how far the rim edge drops straight down before the underside disc (a visible thick edge)
##   lobe_taper how fast the scallops fade going up. 1.0 = gone by the top (a tiered canopy);
##              lower values carry them up the dome so it reads as a cluster of leaf clumps in 3D
##              instead of a smooth cap with a star-shaped outline (the "cardboard cut-out" bush).
func lobed_dome(center: Vector3, radius: float, height: float, top_color: Color, under_color: Color,
		lobes: int = 8, lobe_depth: float = 0.10, flatness: float = 0.72, phase: float = 0.0,
		segments: int = 32, rings: int = 5, skirt: float = 0.0, basis: Basis = Basis.IDENTITY,
		lobe_taper: float = 1.0, crown_shade: float = 0.16) -> void:
	var cols := segments + 1
	var lc_under := _lin(under_color)
	var nb := basis.inverse().transposed()
	# --- lobed dome shell -----------------------------------------------------------------------
	var dome_base := _verts.size()
	for j in rings + 1:
		var t := float(j) / float(rings)
		for s in cols:
			var th := TAU * float(s) / float(segments)
			var p := _dome_point(radius, height, lobes, lobe_depth, flatness, phase, t, th, lobe_taper)
			# Normal from the parametric surface (finite differences, degenerate apex -> +Y).
			var n := Vector3.UP
			if t < 0.999:
				var dt := _dome_point(radius, height, lobes, lobe_depth, flatness, phase, minf(t + 0.02, 1.0), th, lobe_taper) - p
				var dth := _dome_point(radius, height, lobes, lobe_depth, flatness, phase, t, th + 0.02, lobe_taper) - p
				n = dth.cross(dt)
				if n.length_squared() < 0.000001:
					n = Vector3.UP
				n = n.normalized()
				if n.y < 0.0:
					n = -n
			# CANOPY SHADING, arrived at by isolating each term with debug renders.
			# 1) The rim barely darkens. The render's response to canopy albedo is brutally steep at
			#    the dark end (a rim tone 25% below the crown came back 10x darker), and the old ramp
			#    — under_color to top_color by t = 0.16, then flat to the crown — printed a dark outer
			#    ring plus one big flat cap. That was the "#a1b691 S 0.20 pale sage cap over ~25% of
			#    the canopy" defect: two posterised bands with no gradient between them.
			# 2) The crown is PAINTED DOWN. It is the part of a tier that faces the sun squarely, so
			#    it lands on the ACES shoulder where chroma collapses; every shader lever moves it
			#    barely, while its own albedo moves it directly. Hand-painting a canopy darker where
			#    the light is strongest is what the reference does too.
			# The genuinely dark tone still exists, on the skirt and the underside disc below: that
			# is where ACNH puts it, as a crisp line separating the tiers.
			var c := under_color.lerp(top_color, 0.86).lerp(top_color, smoothstep(0.0, 0.72, t))
			c = c.lerp(top_color.darkened(crown_shade), smoothstep(0.18, 0.86, t))
			_verts.append(basis * p + center)
			_norms.append((nb * n).normalized())
			_cols.append(_lin(c))
			_uvs.append(Vector2(float(s) / float(segments), t))
	for j in rings:
		for s in segments:
			var a := dome_base + j * cols + s
			_idx.append_array(PackedInt32Array([a, a + 1, a + cols, a + 1, a + cols + 1, a + cols]))
	# --- straight skirt: a thick, crisp rim edge in the dark colour ------------------------------
	var rim_base := _verts.size()
	if skirt > 0.0:
		for s in cols:
			var th := TAU * float(s) / float(segments)
			var p := _dome_point(radius, height, lobes, lobe_depth, flatness, phase, 0.0, th, lobe_taper)
			var outn := Vector3(p.x, 0.0, p.z).normalized()
			for k in 2:
				_verts.append(basis * (p - Vector3(0.0, skirt * float(k), 0.0)) + center)
				_norms.append((nb * outn).normalized())
				_cols.append(lc_under)
				_uvs.append(Vector2(float(s) / float(segments), float(k)))
		for s in segments:
			var a := rim_base + s * 2
			_idx.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	# --- flat underside disc ---------------------------------------------------------------------
	# Clearly lighter than the skirt: the rim stays the crisp dark line that separates the tiers,
	# while the disc reads as a shaded underside rather than the "solid black underside slab" the
	# integration critic photographed. The disc faces straight down, so it gets no sun and almost no
	# sky — whatever value it has has to be in the vertex colour.
	var lc_disc := _lin(under_color.lightened(0.26))
	var under_base := _verts.size()
	var down := (nb * Vector3.DOWN).normalized()
	_verts.append(basis * Vector3(0.0, -skirt, 0.0) + center)
	_norms.append(down)
	_cols.append(lc_disc)
	_uvs.append(Vector2(0.5, 0.5))
	for s in cols:
		var th := TAU * float(s) / float(segments)
		var p := _dome_point(radius, height, lobes, lobe_depth, flatness, phase, 0.0, th, lobe_taper) - Vector3(0.0, skirt, 0.0)
		_verts.append(basis * p + center)
		_norms.append(down)
		_cols.append(lc_disc)
		_uvs.append(Vector2(float(s) / float(segments), 0.0))
	for s in segments:
		_idx.append_array(PackedInt32Array([under_base, under_base + 1 + s + 1, under_base + 1 + s]))

static func _dome_point(radius: float, height: float, lobes: int, lobe_depth: float, flatness: float,
		phase: float, t: float, th: float, lobe_taper: float = 1.0) -> Vector3:
	var lobe := 1.0 + lobe_depth * cos(float(lobes) * th + phase) * (1.0 - t * lobe_taper)
	var rr := radius * lobe * cos(t * PI * 0.5)
	var yy := height * pow(sin(t * PI * 0.5), flatness)
	return Vector3(rr * cos(th), yy, rr * sin(th))

## Flat-shaded faceted blob (rocks, boulders): a low-poly icosphere with hashed per-vertex radial
## jitter and hard normals, squashed by `scale`. Reads as a carved stone, not a soap bubble.
func faceted_blob(center: Vector3, radius: float, color: Color, scale: Vector3 = Vector3.ONE,
		subdivisions: int = 1, jitter: float = 0.16, seed_off: float = 0.0, basis: Basis = Basis.IDENTITY) -> void:
	var topo := PlanetMeshBuilder.icosphere_topology(subdivisions)
	var dirs: PackedVector3Array = topo["dirs"]
	var ix: PackedInt32Array = topo["indices"]
	var pts := PackedVector3Array()
	pts.resize(dirs.size())
	for i in dirs.size():
		var d := dirs[i]
		var raw := sin(d.x * 12.9898 + d.y * 78.233 + d.z * 37.719 + seed_off) * 43758.5453
		var h := raw - floorf(raw)
		pts[i] = basis * ((d * (radius * (1.0 + (h - 0.5) * jitter))) * scale) + center
	var lit := _lin(color)
	var dark := _lin(color.darkened(0.3))
	var i2 := 0
	while i2 < ix.size():
		var a := pts[ix[i2]]
		var b := pts[ix[i2 + 1]]
		var c := pts[ix[i2 + 2]]
		var n := (c - a).cross(b - a)
		if n.length_squared() < 0.0000001:
			i2 += 3
			continue
		n = n.normalized()
		# Down-facing facets get the dark tone so the rock has a grounded, readable underside.
		var col := dark if n.y < -0.15 else lit
		var base := _verts.size()
		for p in [a, b, c]:
			_verts.append(p)
			_norms.append(n)
			_cols.append(col)
			_uvs.append(Vector2.ZERO)
		_idx.append_array(PackedInt32Array([base, base + 1, base + 2]))
		i2 += 3

## Flat double-sided triangle (for flags, blades). Front face = a,b,c clockwise (Godot convention);
## the normal points toward the viewer of that clockwise side. Adds the mirrored back side too.
func triangle(a: Vector3, b: Vector3, c: Vector3, color: Color, double_sided: bool = true) -> void:
	var nrm := (c - a).cross(b - a).normalized()
	var base := _verts.size()
	var lc := _lin(color)
	for p in [a, b, c]:
		_verts.append(p)
		_norms.append(nrm)
		_cols.append(lc)
		_uvs.append(Vector2.ZERO)
	_idx.append_array(PackedInt32Array([base, base + 1, base + 2]))
	if double_sided:
		var base2 := _verts.size()
		for p in [a, c, b]:
			_verts.append(p)
			_norms.append(-nrm)
			_cols.append(lc)
			_uvs.append(Vector2.ZERO)
		_idx.append_array(PackedInt32Array([base2, base2 + 1, base2 + 2]))

## Quad from four corners (a,b,c,d counter-clockwise).
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, double_sided: bool = true) -> void:
	triangle(a, b, c, color, double_sided)
	triangle(a, c, d, color, double_sided)

## sRGB -> linear, alpha preserved (alpha is used as a tint mask by the foliage shader).
static func _lin(c: Color) -> Color:
	var l := c.srgb_to_linear()
	l.a = c.a
	return l

## Number of vertices so far (for budgeting).
func vertex_count() -> int:
	return _verts.size()

## Finishes the mesh. Pass an existing ArrayMesh to append as a new surface (for multi-material props).
func commit(into: ArrayMesh = null) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = _norms
	arrays[Mesh.ARRAY_COLOR] = _cols
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_INDEX] = _idx
	var mesh := into if into != null else ArrayMesh.new()
	if _verts.size() > 0:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## Static helper: a basis tilted from +Y by `tilt_rad` around a random horizontal axis given by `azimuth`.
static func tilt_basis(tilt_rad: float, azimuth: float, yaw: float = 0.0) -> Basis:
	var axis := Vector3(cos(azimuth), 0.0, sin(azimuth))
	return Basis(axis, tilt_rad) * Basis(Vector3.UP, yaw)
