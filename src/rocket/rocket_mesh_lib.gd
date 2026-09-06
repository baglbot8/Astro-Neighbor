class_name RocketMeshLib
extends RefCounted
## Procedural mesh helpers shared by the rocket, the landing pad and the space map:
## surfaces of revolution (lathe), elliptical lofts (fins), tubes along a polyline and orbit dots.
## All meshes are indexed, smooth-shaded and use Godot's clockwise front-face winding.

## Surface of revolution around +Y. `profile` = (radius, y) pairs from bottom to top.
## Normals come from the profile tangents so bevels shade softly (cartoon-friendly).
static func lathe(profile: PackedVector2Array, segments: int = 32) -> ArrayMesh:
	var n := profile.size()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var n2 := PackedVector2Array()
	n2.resize(n)
	for i in n:
		var a := profile[maxi(i - 1, 0)]
		var b := profile[mini(i + 1, n - 1)]
		var t := b - a
		if t.length_squared() < 1e-9:
			t = Vector2(0.0, 1.0)
		t = t.normalized()
		n2[i] = Vector2(t.y, -t.x)
	for i in n:
		for s in segments + 1:
			var ang := TAU * float(s) / float(segments)
			var c := cos(ang)
			var sn := sin(ang)
			verts.append(Vector3(profile[i].x * c, profile[i].y, profile[i].x * sn))
			norms.append(Vector3(n2[i].x * c, n2[i].y, n2[i].x * sn).normalized())
			uvs.append(Vector2(float(s) / float(segments), float(i) / float(maxi(n - 1, 1))))
	for i in n - 1:
		for s in segments:
			var a := i * (segments + 1) + s
			var b := a + segments + 1
			idx.append(a)
			idx.append(a + 1)
			idx.append(b)
			idx.append(a + 1)
			idx.append(b + 1)
			idx.append(b)
	return _commit(verts, norms, uvs, idx)


## Loft of elliptical slices stacked along +Y. Each slice: {"y", "c" (center on +X), "hw" (half width
## along X), "ht" (half thickness along Z)}. Used for the swept rocket fins.
static func loft(slices: Array, sides: int = 18) -> ArrayMesh:
	var n := slices.size()
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in n:
		var sl: Dictionary = slices[i]
		var y := float(sl["y"])
		var c := float(sl["c"])
		var hw := float(sl["hw"])
		var ht := float(sl["ht"])
		for s in sides + 1:
			var ang := TAU * float(s) / float(sides)
			verts.append(Vector3(c + hw * cos(ang), y, ht * sin(ang)))
			uvs.append(Vector2(float(s) / float(sides), float(i) / float(maxi(n - 1, 1))))
	for i in n - 1:
		for s in sides:
			var a := i * (sides + 1) + s
			var b := a + sides + 1
			idx.append(a)
			idx.append(a + 1)
			idx.append(b)
			idx.append(a + 1)
			idx.append(b + 1)
			idx.append(b)
	return _commit(verts, _smooth_normals(verts, idx), uvs, idx)


## Round tube of radius r swept along a polyline (parallel-transported frames, capped ends).
static func tube(points: PackedVector3Array, r: float, sides: int = 10) -> ArrayMesh:
	var n := points.size()
	if n < 2:
		return ArrayMesh.new()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var along := (points[1] - points[0]).normalized()
	var n1 := along.cross(Vector3.UP)
	if n1.length_squared() < 0.001:
		n1 = along.cross(Vector3.RIGHT)
	n1 = n1.normalized()
	for i in n:
		var dir: Vector3
		if i == 0:
			dir = (points[1] - points[0]).normalized()
		elif i == n - 1:
			dir = (points[i] - points[i - 1]).normalized()
		else:
			dir = ((points[i + 1] - points[i]).normalized() + (points[i] - points[i - 1]).normalized()).normalized()
		n1 = (n1 - dir * n1.dot(dir)).normalized()
		var n2 := n1.cross(dir).normalized()
		for s in sides + 1:
			var ang := TAU * float(s) / float(sides)
			var nrm := (n1 * cos(ang) + n2 * sin(ang)).normalized()
			verts.append(points[i] + nrm * r)
			norms.append(nrm)
			uvs.append(Vector2(float(s) / float(sides), float(i) / float(n - 1)))
	for i in n - 1:
		for s in sides:
			var a := i * (sides + 1) + s
			var b := a + sides + 1
			idx.append(a)
			idx.append(a + 1)
			idx.append(b)
			idx.append(a + 1)
			idx.append(b + 1)
			idx.append(b)
	return _commit(verts, norms, uvs, idx)


## Smooth cubic Bezier polyline (for hoses and flight paths).
static func bezier_points(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, steps: int = 16) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in steps + 1:
		out.append(p0.bezier_interpolate(p1, p2, p3, float(i) / float(steps)))
	return out


## Sphere-cap "sag": how far the ground drops below the tangent plane at distance r from the pad center.
static func sag(r: float, planet_radius: float) -> float:
	return planet_radius - sqrt(maxf(planet_radius * planet_radius - r * r, 0.0))


static func _smooth_normals(verts: PackedVector3Array, idx: PackedInt32Array) -> PackedVector3Array:
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	norms.fill(Vector3.ZERO)
	var tri := idx.size() / 3
	for t in tri:
		var a := idx[t * 3]
		var b := idx[t * 3 + 1]
		var c := idx[t * 3 + 2]
		# clockwise front faces: normal = (c - a) x (b - a)
		var fn := (verts[c] - verts[a]).cross(verts[b] - verts[a])
		norms[a] += fn
		norms[b] += fn
		norms[c] += fn
	for i in norms.size():
		norms[i] = norms[i].normalized() if norms[i].length_squared() > 1e-12 else Vector3.UP
	return norms


static func _commit(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array, idx: PackedInt32Array) -> ArrayMesh:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


## Convenience: MeshInstance3D child with a material, position and name.
static func mi(mesh: Mesh, mat: Material, parent: Node, pos: Vector3 = Vector3.ZERO, n: String = "") -> MeshInstance3D:
	var m := MeshInstance3D.new()
	if n != "":
		m.name = n
	m.mesh = mesh
	if mat != null:
		m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m


static func sphere(r: float, seg: int = 24, rings: int = 12) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = rings
	return s


static func cylinder(rt: float, rb: float, h: float, seg: int = 24) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func torus(inner: float, outer: float, rings: int = 32, sides: int = 10) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = rings
	t.ring_segments = sides
	return t


static func capsule(r: float, h: float, seg: int = 14, rings: int = 4) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = seg
	c.rings = rings
	return c


## Flat-shaded extruded polygon with a chamfered rim — the shape used for rocket fins, the hatch
## plate and pad signs. `points` is a CCW polygon in the XY plane, extruded along Z by
## +/- `half_thickness`; `chamfer` insets the two flat faces so the rim reads as a crisp bevel.
static func prism(points: PackedVector2Array, half_thickness: float, chamfer: float = 0.0) -> ArrayMesh:
	var n := points.size()
	if n < 3:
		return ArrayMesh.new()
	var centroid := Vector2.ZERO
	for p in points:
		centroid += p
	centroid /= float(n)
	var inner := PackedVector2Array()
	for p in points:
		var to_c := centroid - p
		var l := to_c.length()
		var q := p
		if l > 0.0001:
			q = p + (to_c / l) * minf(chamfer, l * 0.6)
		inner.append(q)
	var tris := PackedVector3Array()
	var front := PackedVector3Array()
	var back := PackedVector3Array()
	var rim := PackedVector3Array()
	for i in n:
		front.append(Vector3(inner[i].x, inner[i].y, half_thickness))
		back.append(Vector3(inner[i].x, inner[i].y, -half_thickness))
		rim.append(Vector3(points[i].x, points[i].y, 0.0))
	# caps (fan from vertex 0)
	for i in range(1, n - 1):
		tris.append(front[0]); tris.append(front[i + 1]); tris.append(front[i])
		tris.append(back[0]); tris.append(back[i]); tris.append(back[i + 1])
	# chamfered rim: front -> outline -> back
	for i in n:
		var j := (i + 1) % n
		tris.append(front[i]); tris.append(front[j]); tris.append(rim[i])
		tris.append(front[j]); tris.append(rim[j]); tris.append(rim[i])
		tris.append(rim[i]); tris.append(rim[j]); tris.append(back[i])
		tris.append(rim[j]); tris.append(back[j]); tris.append(back[i])
	return commit_flat(tris)


## Curved shell panel (rocket hatch, hull plates): a box wrapped onto a cylinder of radius `r_in`
## with wall thickness `r_out - r_in`, spanning `y0..y1` and +/- `half_angle` radians around -Z.
## The curved faces are smooth-shaded, the four borders are flat.
static func curved_panel(r_in: float, r_out: float, y0: float, y1: float, half_angle: float, seg: int = 12) -> ArrayMesh:
	var tris := PackedVector3Array()
	var norms := PackedVector3Array()
	var pt := func(rr: float, th: float, yy: float) -> Vector3:
		return Vector3(rr * sin(th), yy, -rr * cos(th))
	var radial := func(th: float) -> Vector3:
		return Vector3(sin(th), 0.0, -cos(th))
	for s in seg:
		var t0 := lerpf(-half_angle, half_angle, float(s) / float(seg))
		var t1 := lerpf(-half_angle, half_angle, float(s + 1) / float(seg))
		var n0: Vector3 = radial.call(t0)
		var n1: Vector3 = radial.call(t1)
		# outer face (normal outward)
		_quad(tris, norms, pt.call(r_out, t0, y1), pt.call(r_out, t1, y1), pt.call(r_out, t1, y0), pt.call(r_out, t0, y0), [n0, n1, n1, n0])
		# inner face (normal inward)
		_quad(tris, norms, pt.call(r_in, t0, y0), pt.call(r_in, t1, y0), pt.call(r_in, t1, y1), pt.call(r_in, t0, y1), [-n0, -n1, -n1, -n0])
		# top / bottom rims
		_quad(tris, norms, pt.call(r_in, t0, y1), pt.call(r_in, t1, y1), pt.call(r_out, t1, y1), pt.call(r_out, t0, y1), [Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
		_quad(tris, norms, pt.call(r_out, t0, y0), pt.call(r_out, t1, y0), pt.call(r_in, t1, y0), pt.call(r_in, t0, y0), [Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN])
	for sgn: float in [-1.0, 1.0]:
		var th := half_angle * sgn
		var side := Vector3(cos(th), 0.0, sin(th)) * sgn
		_quad(tris, norms, pt.call(r_in, th, y0), pt.call(r_in, th, y1), pt.call(r_out, th, y1), pt.call(r_out, th, y0), [side, side, side, side])
	return commit_raw(tris, norms)


## Annulus in the XZ plane (facing +Y) split into `segments` wedges that cycle through `colors` as
## vertex colors — the pad's yellow/charcoal hazard stripe. When `curve_r` > 0 the ring is dropped
## onto a sphere of that radius (see `sag`) so it hugs a planet surface instead of floating.
static func striped_annulus(r_in: float, r_out: float, segments: int, colors: PackedColorArray, curve_r: float = 0.0) -> ArrayMesh:
	var tris := PackedVector3Array()
	var cols := PackedColorArray()
	var yi := 0.0
	var yo := 0.0
	if curve_r > 0.0:
		yi = -sag(r_in, curve_r)
		yo = -sag(r_out, curve_r)
	for s in segments:
		var a0 := TAU * float(s) / float(segments)
		var a1 := TAU * float(s + 1) / float(segments)
		var c := colors[s % colors.size()]
		var i0 := Vector3(r_in * cos(a0), yi, r_in * sin(a0))
		var i1 := Vector3(r_in * cos(a1), yi, r_in * sin(a1))
		var o0 := Vector3(r_out * cos(a0), yo, r_out * sin(a0))
		var o1 := Vector3(r_out * cos(a1), yo, r_out * sin(a1))
		for v in [i0, o0, i1, o0, o1, i1]:
			tris.append(v)
			cols.append(c)
	var norms := PackedVector3Array()
	norms.resize(tris.size())
	norms.fill(Vector3.UP)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = tris
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


## Dashed circle as a line loop (orbit rings in the space map). Radius `r` in the XZ plane.
static func dashed_ring(r: float, dashes: int, fill: float = 0.5, steps_per_dash: int = 3) -> ArrayMesh:
	var verts := PackedVector3Array()
	for d in dashes:
		var a0 := TAU * float(d) / float(dashes)
		var a1 := a0 + TAU * fill / float(dashes)
		for k in steps_per_dash:
			var t0 := lerpf(a0, a1, float(k) / float(steps_per_dash))
			var t1 := lerpf(a0, a1, float(k + 1) / float(steps_per_dash))
			verts.append(Vector3(r * cos(t0), 0.0, r * sin(t0)))
			verts.append(Vector3(r * cos(t1), 0.0, r * sin(t1)))
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
	return am


## Rounded-rectangle outline (CCW) for prism(): signs, hatch plates, screens.
static func rounded_rect(w: float, h: float, corner: float, steps: int = 4) -> PackedVector2Array:
	var out := PackedVector2Array()
	var hw := w * 0.5 - corner
	var hh := h * 0.5 - corner
	var centers := [Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh), Vector2(-hw, -hh)]
	for i in 4:
		var base := -PI * 0.5 + PI * 0.5 * float(i)
		for k in steps + 1:
			var a := base + PI * 0.5 * float(k) / float(steps)
			out.append((centers[i] as Vector2) + Vector2(cos(a), sin(a)) * corner)
	return out


## Appends a quad (a,b,c,d) with per-corner normals `n`. The winding is chosen automatically so the
## triangles face the same way as the supplied normals — the caller never has to think about it.
static func _quad(tris: PackedVector3Array, norms: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Array) -> void:
	var want: Vector3 = (n[0] + n[1] + n[2] + n[3])
	var face := (c - a).cross(b - a)
	if face.dot(want) < 0.0:
		tris.append(a); tris.append(d); tris.append(c)
		norms.append(n[0]); norms.append(n[3]); norms.append(n[2])
		tris.append(a); tris.append(c); tris.append(b)
		norms.append(n[0]); norms.append(n[2]); norms.append(n[1])
		return
	tris.append(a); tris.append(b); tris.append(c)
	norms.append(n[0]); norms.append(n[1]); norms.append(n[2])
	tris.append(a); tris.append(c); tris.append(d)
	norms.append(n[0]); norms.append(n[2]); norms.append(n[3])


## Unindexed triangle soup with per-face (flat) normals — crisp edges, no smoothing.
static func commit_flat(tris: PackedVector3Array) -> ArrayMesh:
	var norms := PackedVector3Array()
	norms.resize(tris.size())
	for t in range(0, tris.size(), 3):
		var a := tris[t]
		var b := tris[t + 1]
		var c := tris[t + 2]
		var fn := (c - a).cross(b - a)
		fn = fn.normalized() if fn.length_squared() > 1e-12 else Vector3.UP
		norms[t] = fn
		norms[t + 1] = fn
		norms[t + 2] = fn
	return commit_raw(tris, norms)


## Unindexed triangle soup with explicit normals.
static func commit_raw(tris: PackedVector3Array, norms: PackedVector3Array) -> ArrayMesh:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = tris
	arr[Mesh.ARRAY_NORMAL] = norms
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am
