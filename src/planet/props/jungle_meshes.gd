class_name JungleMeshes
extends RefCounted
## Procedural meshes for THE TANGLE (planet "jungle", docs/JUNGLE_PLANET_SPEC.md). All static, all
## cached by key, all built with PlanetMeshKit so they share the rest of the planets' vertex-colour
## conventions (sRGB in, linear baked, COLOR.a marks wood for the foliage shader).
##
## THE LAYERS, top to bottom - a jungle reads as a jungle because of the layering, not the density:
##   spire_palm     6-7.5 m emergents: a ringed, bending trunk and a crown of long serrated fronds
##                  arching down, with glow-bead vines hanging from them (surface 1 = glow).
##   parasol_tree   4-5 m canopy: a short trunk that forks into two or three branches, each carrying
##                  one wide flat umbrella tier with a dark underside (surface 1 = glow drips).
##   spiral_plant   2-3 m mid-storey: a helical stem ending in a fiddlehead curl round a glowing bud.
##   broadleaf      understory clumps of big heart-shaped leaves on stalks.
##   fiddleheads, glow_fungus, reeds, lily_pad, seed_pod - the floor.
##   root_arch      a pair of great roots arching over a trail: a gate you walk under.
## Nothing here is a ball or a bunch of balls (STYLE_GUIDE R2.3): fronds are folded blades with a
## midrib, caps are flat tiers, pods are faceted.
##
## SURFACES. Where a mesh has a glow part it is SURFACE 1 and the caller hands it a crystal material
## (PlanetPropMeshes.crystal_material), whose emission is scaled down by day (emission_day_scale) and
## runs at full strength at night - that is the whole "the plants glow at night" mechanism, and it costs
## no light.

static var _cache: Dictionary = {}
## Canopy volumes per cached mesh key: Array of Vector4(x, y, z, radius) in prop-local space, one per
## palm crown / parasol tier. JungleProps turns them into colliders on the prop's own body so the
## camera's occluder fade (CameraRig, layer 4 bodies only) sees a canopy that hangs over the sight line
## and not only the thin trunk under it.
static var canopies: Dictionary = {}


static func _cached(key: String, builder: Callable) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var m: ArrayMesh = builder.call()
	_cache[key] = m
	return m


## The low-power profile (web / phone layout): the same gate as PlanetProps._scatter_scale.
static func low_power() -> bool:
	return Platform.is_compatibility_renderer() or Platform.is_mobile()


static func _wood(c: Color) -> Color:
	return Color(c.r, c.g, c.b, PlanetPropMeshes.WOOD_ALPHA)


# ======================================================================================== builders
## A continuous tube along `pts` (parallel-transported rings, no joint gaps) with per-point radius and
## colour, closed with a short cone at the end. `segs` sides.
static func tube(kit: PlanetMeshKit, pts: PackedVector3Array, radii: PackedFloat32Array,
		cols: PackedColorArray, segs: int = 8, cap_end: bool = true) -> void:
	var n := pts.size()
	if n < 2:
		return
	var first_t := (pts[1] - pts[0]).normalized()
	var nrm := Vector3.RIGHT if absf(first_t.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	nrm = (nrm - first_t * nrm.dot(first_t)).normalized()
	var base := kit._verts.size()
	var ring := segs + 1
	var t := first_t
	for i in n:
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, n - 1)]
		t = (b - a).normalized()
		nrm = (nrm - t * nrm.dot(t))
		if nrm.length_squared() < 0.000001:
			nrm = t.cross(Vector3.UP)
		nrm = nrm.normalized()
		var bin := t.cross(nrm).normalized()
		var lc := PlanetMeshKit._lin(cols[mini(i, cols.size() - 1)])
		var r := radii[mini(i, radii.size() - 1)]
		for s in ring:
			var ang := TAU * float(s) / float(segs)
			var d := nrm * cos(ang) + bin * sin(ang)
			kit._verts.append(pts[i] + d * r)
			kit._norms.append(d)
			kit._cols.append(lc)
			kit._uvs.append(Vector2(float(s) / float(segs), float(i) / float(n - 1)))
	for i in n - 1:
		for s in segs:
			var a0 := base + i * ring + s
			var b0 := a0 + ring
			kit._idx.append_array(PackedInt32Array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1]))
	if cap_end:
		var last := n - 1
		var tip := pts[last] + t * radii[mini(last, radii.size() - 1)] * 0.9
		var tip_i := kit._verts.size()
		kit._verts.append(tip)
		kit._norms.append(t)
		kit._cols.append(PlanetMeshKit._lin(cols[mini(last, cols.size() - 1)]))
		kit._uvs.append(Vector2(0.5, 1.0))
		var lb := base + last * ring
		for s in segs:
			kit._idx.append_array(PackedInt32Array([lb + s, tip_i, lb + s + 1]))


## A folded blade (frond, leaf) from `base` outward along horizontal `out`: `widths` gives the half
## width at each of the len(widths) stations (first = base, last = tip), the centreline rises by `rise`
## (a hump) and falls by `droop` (quadratic), and the midrib stands `fold` x width above the edges, so
## the two halves catch the light differently - a leaf with a spine, not a paper cut-out.
static func blade(kit: PlanetMeshKit, base: Vector3, out: Vector3, length: float, widths: PackedFloat32Array,
		rise: float, droop: float, fold: float, col_base: Color, col_tip: Color, shade: float = 0.10,
		vein: PlanetMeshKit = null) -> void:
	var o := Vector3(out.x, 0.0, out.z).normalized()
	var side := Vector3(-o.z, 0.0, o.x)
	var n := widths.size()
	var prev_l := Vector3.ZERO
	var prev_m := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_c := col_base
	for i in n:
		var t := float(i) / float(n - 1)
		var y := rise * 4.0 * t * (1.0 - t) * 0.5 + rise * t * 0.5 - droop * t * t
		var p := base + o * length * t + Vector3(0.0, y, 0.0)
		var w := widths[i]
		var m := p + Vector3(0.0, fold * w, 0.0)
		var l := p + side * w
		var r := p - side * w
		var c := col_base.lerp(col_tip, t)
		if i > 0:
			kit.quad(prev_m, prev_l, l, m, prev_c.lerp(c, 0.5))
			kit.quad(prev_r, prev_m, m, r, prev_c.lerp(c, 0.5).darkened(shade))
			if vein != null and i < n - 1:
				# A glowing midrib: a thin strip riding just above the fold (night glow, surface 1).
				var vw := side * 0.016
				var lift := Vector3(0.0, 0.006, 0.0)
				vein.quad(prev_m + lift - vw, prev_m + lift + vw, m + lift + vw, m + lift - vw, Color.WHITE)
		prev_l = l
		prev_m = m
		prev_r = r
		prev_c = c


## A vertical strand of glow beads hanging from `top`, `count` beads `step` apart (into `glow`), with
## a thin dark thread through them (into `body`).
static func bead_strand(body: PlanetMeshKit, glow: PlanetMeshKit, top: Vector3, count: int, step: float,
		bead_r: float, thread: Color) -> void:
	var bottom := top - Vector3(0.0, step * float(count), 0.0)
	body.cylinder(bottom, 0.012, 0.014, top.y - bottom.y, thread, Basis.IDENTITY, 4)
	for k in count:
		var y := top.y - step * (float(k) + 0.8)
		var r := bead_r * (1.0 - 0.35 * float(k) / float(maxi(count, 1)))
		glow.sphere(Vector3(top.x, y, top.z), r, Color.WHITE, Vector3(1.0, 1.25, 1.0), 6)


# ======================================================================================== the canopy
## Emergent SPIRE PALM, 5.6-7.2 m. Surface 0 body (foliage material; trunk marked wood), surface 1
## glow beads. ~2,400 tris.
static func spire_palm(trunk: Color, frond: Color, frond_light: Color, shadow: Color, variant: int) -> ArrayMesh:
	var key := "jpalm|%s|%s|%s|%s|%d" % [trunk.to_html(), frond.to_html(), frond_light.to_html(), shadow.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 9100 + variant
		var h := 3.5 + 0.4 * float(variant % 3)
		var bend := 0.55 + 0.2 * float(variant % 2)
		var bend_dir := Vector3(cos(1.3 * float(variant)), 0.0, sin(1.3 * float(variant)))
		# Ringed trunk: alternate stations bulge and darken, which reads as leaf scars.
		var pts := PackedVector3Array()
		var radii := PackedFloat32Array()
		var cols := PackedColorArray()
		var stations := 22
		for i in stations + 1:
			var t := float(i) / float(stations)
			pts.append(bend_dir * bend * t * t + Vector3(0.0, h * t - 0.15, 0.0))
			var r := lerpf(0.30, 0.15, pow(t, 0.8))
			var ringed := (i % 2 == 1) and i > 1 and i < stations - 1
			radii.append(r * (1.10 if ringed else 1.0))
			cols.append(_wood(trunk.darkened(0.16 if ringed else 0.0).lerp(trunk.lightened(0.06), t * 0.5)))
		tube(kit, pts, radii, cols, 9, false)
		# Splayed prop roots at the foot.
		for k in 4:
			var a := TAU * float(k) / 4.0 + 0.4 * float(variant)
			var o := Vector3(cos(a), 0.0, sin(a))
			tube(kit, PackedVector3Array([o * 0.12 + Vector3(0.0, 0.75, 0.0), o * 0.38 + Vector3(0.0, 0.30, 0.0), o * 0.62 + Vector3(0.0, -0.08, 0.0)]),
				PackedFloat32Array([0.075, 0.065, 0.05]), PackedColorArray([_wood(trunk.darkened(0.10)), _wood(trunk.darkened(0.18)), _wood(trunk.darkened(0.24))]), 6, false)
		var top := pts[stations] + Vector3(0.0, 0.10, 0.0)
		# Crown heart: a short dark cone the fronds spring from.
		kit.cylinder(top - Vector3(0.0, 0.30, 0.0), 0.20, 0.10, 0.46, shadow, Basis.IDENTITY, 10)
		# Serrated widths: alternate stations are narrower, so the edge reads as leaflets.
		var widths := PackedFloat32Array()
		for i in 9:
			var t := float(i) / 8.0
			var w := 0.34 * pow(sin(PI * (0.06 + 0.94 * t)), 0.75)
			widths.append(w * (0.72 if i % 2 == 1 else 1.0))
		var n := 9 + variant % 2
		for k in n:
			var a := TAU * float(k) / float(n) + rng.randf_range(-0.12, 0.12)
			var o := Vector3(cos(a), 0.0, sin(a))
			var length := rng.randf_range(1.7, 2.1)
			blade(kit, top + o * 0.08, o, length, widths, 0.40, rng.randf_range(0.9, 1.2), 0.35,
				frond.darkened(0.08), frond_light, 0.12)
		# Three young fronds standing up out of the crown.
		var widths_up := PackedFloat32Array()
		for i in 7:
			var t := float(i) / 6.0
			widths_up.append(0.20 * pow(sin(PI * (0.08 + 0.92 * t)), 0.8) * (0.75 if i % 2 == 1 else 1.0))
		for k in 3:
			var a := TAU * float(k) / 3.0 + 0.5
			var o := Vector3(cos(a), 0.0, sin(a))
			blade(kit, top + Vector3(0.0, 0.10, 0.0), o, 1.2, widths_up, 1.25, 0.35, 0.4,
				frond.lerp(frond_light, 0.4), frond_light.lightened(0.05), 0.10)
		# Glow-bead vines hanging off three of the fronds, part way out.
		for k in 3:
			var a := TAU * float(k * 3 + 1) / float(n)
			var o := Vector3(cos(a), 0.0, sin(a))
			var at := top + o * rng.randf_range(1.0, 1.3) + Vector3(0.0, 0.05, 0.0)
			bead_strand(kit, glow, at, 6 + (k + variant) % 4, 0.17, 0.055, shadow.darkened(0.1))
		canopies[key] = [Vector4(top.x, top.y - 0.35, top.z, 1.5)]
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)


static func palm_key(trunk: Color, frond: Color, frond_light: Color, shadow: Color, variant: int) -> String:
	return "jpalm|%s|%s|%s|%s|%d" % [trunk.to_html(), frond.to_html(), frond_light.to_html(), shadow.to_html(), variant]


static func parasol_key(trunk: Color, cap: Color, cap_light: Color, under: Color, variant: int) -> String:
	return "jparasol|%s|%s|%s|%s|%d" % [trunk.to_html(), cap.to_html(), cap_light.to_html(), under.to_html(), variant]


## PARASOL TREE, 3.8-5 m: a short trunk forking into 2-3 branches, each ending in one wide flat tier.
## Surface 0 body, surface 1 glow drips under the tiers. ~3,000 tris.
static func parasol_tree(trunk: Color, cap: Color, cap_light: Color, under: Color, variant: int) -> ArrayMesh:
	var key := "jparasol|%s|%s|%s|%s|%d" % [trunk.to_html(), cap.to_html(), cap_light.to_html(), under.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 9300 + variant
		var fork := Vector3(0.0, 1.0 + 0.2 * float(variant % 2), 0.0)
		# Buttressed foot + trunk to the fork.
		tube(kit, PackedVector3Array([Vector3(0.0, -0.15, 0.0), Vector3(0.0, 0.5, 0.0), Vector3(0.05, 1.0, 0.0), fork]),
			PackedFloat32Array([0.34, 0.24, 0.21, 0.19]),
			PackedColorArray([_wood(trunk.darkened(0.2)), _wood(trunk.darkened(0.08)), _wood(trunk), _wood(trunk)]), 10, false)
		for k in 3:
			var a := TAU * float(k) / 3.0 + 0.7 * float(variant)
			var o := Vector3(cos(a), 0.0, sin(a))
			kit.cylinder(Vector3(0.0, -0.12, 0.0), 0.16, 0.05, 0.9, _wood(trunk.darkened(0.14)),
				Basis(Vector3(-o.z, 0.0, o.x), 0.55), 6)
		var tiers: Array = []
		var branches := 3 if variant % 3 != 1 else 2
		for b in branches:
			var a := TAU * float(b) / float(branches) + 0.9 * float(variant) + rng.randf_range(-0.2, 0.2)
			var o := Vector3(cos(a), 0.0, sin(a))
			var tier_h := 2.2 + 0.45 * float((b + variant) % 3) + rng.randf_range(0.0, 0.25)
			var reach := rng.randf_range(0.9, 1.35)
			var end := o * reach + Vector3(0.0, tier_h, 0.0)
			var mid := fork + o * reach * 0.35 + Vector3(0.0, (tier_h - fork.y) * 0.55, 0.0)
			tube(kit, PackedVector3Array([fork, mid, end - Vector3(0.0, 0.1, 0.0)]),
				PackedFloat32Array([0.15, 0.11, 0.08]), PackedColorArray([_wood(trunk), _wood(trunk), _wood(trunk.lightened(0.04))]), 7, false)
			var r := rng.randf_range(1.15, 1.5)
			tiers.append(Vector4(end.x, end.y, end.z, r))
			var c := cap.lerp(cap_light, 0.15 * float(b))
			kit.lobed_dome(end, r, 0.34, c, under, 9, 0.11, 0.42, rng.randf_range(0.0, TAU), 27, 4, 0.10,
				Basis.IDENTITY, 0.65, 0.10)
			# Radial vein ridges on the underside so the flat disc is not a blank plate.
			for i in 9:
				var va := TAU * float(i) / 9.0 + a
				var vd := Vector3(cos(va), 0.0, sin(va))
				var vs := Vector3(-vd.z, 0.0, vd.x) * 0.03
				var p0 := end + vd * 0.15 - Vector3(0.0, 0.105, 0.0)
				var p1 := end + vd * (r * 0.92) - Vector3(0.0, 0.105, 0.0)
				kit.quad(p0 - vs, p1 - vs, p1 + vs, p0 + vs, under.lightened(0.18))
			# Glow drips hanging from the rim.
			for i in 5:
				var da := TAU * float(i) / 5.0 + rng.randf_range(0.0, 1.0)
				var dp := end + Vector3(cos(da), 0.0, sin(da)) * r * rng.randf_range(0.55, 0.85)
				var dl := rng.randf_range(0.18, 0.40)
				glow.sphere(dp - Vector3(0.0, 0.10 + dl, 0.0), 0.05, Color.WHITE, Vector3(1.0, 1.6, 1.0), 6)
				kit.cylinder(dp - Vector3(0.0, 0.10 + dl, 0.0), 0.010, 0.012, dl, under.darkened(0.1), Basis.IDENTITY, 4)
			# A curtain of hanging vines off the rim on one side: flat tapering ribbons, two crossed
			# planes each so they read from any side.
			for i in 6:
				var va := a + PI * 0.6 + 0.22 * float(i) + rng.randf_range(-0.08, 0.08)
				var vp := end + Vector3(cos(va), 0.0, sin(va)) * r * rng.randf_range(0.80, 0.95) - Vector3(0.0, 0.10, 0.0)
				var vl := rng.randf_range(0.9, 1.9)
				var vw := 0.035
				var vc := Color("#4f827f") if i % 2 == 0 else Color("#7a6a8c")
				kit.quad(vp - Vector3(vw, 0.0, 0.0), vp + Vector3(vw, 0.0, 0.0), vp + Vector3(vw * 0.4, -vl, 0.0), vp + Vector3(-vw * 0.4, -vl, 0.0), vc)
				kit.quad(vp - Vector3(0.0, 0.0, vw), vp + Vector3(0.0, 0.0, vw), vp + Vector3(0.0, -vl, vw * 0.4), vp + Vector3(0.0, -vl, -vw * 0.4), vc.darkened(0.1))
		canopies[key] = tiers
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)


## SPIRAL PLANT, 1.8-3.0 m: a helical stem climbing to a fiddlehead curl wrapped round a glowing bud.
## Surface 0 body, surface 1 bud. ~900 tris.
static func spiral_plant(stem: Color, tip: Color, leaf: Color, variant: int) -> ArrayMesh:
	var key := "jspiral|%s|%s|%s|%d" % [stem.to_html(), tip.to_html(), leaf.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var h := 1.8 + 0.4 * float(variant % 3)
		var turns := 1.5 + 0.25 * float(variant % 2)
		var ph := 1.7 * float(variant)
		var pts := PackedVector3Array()
		var radii := PackedFloat32Array()
		var cols := PackedColorArray()
		var n := 30
		for i in n + 1:
			var t := float(i) / float(n)
			var a := TAU * turns * t + ph
			var rr := 0.26 * (1.0 - 0.55 * t)
			pts.append(Vector3(cos(a) * rr, h * t - 0.08, sin(a) * rr))
			radii.append(lerpf(0.11, 0.05, t))
			cols.append(stem.lerp(tip, t * t))
		# The curl: a planar spiral rolling over the top.
		var last := pts[n]
		var fwd := Vector3(cos(TAU * turns + ph), 0.0, sin(TAU * turns + ph))
		for i in range(1, 13):
			var s := float(i) / 12.0
			var ang := s * PI * 1.7
			var rad := 0.30 * (1.0 - 0.55 * s)
			pts.append(last + fwd * sin(ang) * rad + Vector3(0.0, (1.0 - cos(ang)) * rad * 0.9, 0.0))
			radii.append(lerpf(0.05, 0.024, s))
			cols.append(tip)
		tube(kit, pts, radii, cols, 7, true)
		glow.sphere(last + fwd * 0.14 + Vector3(0.0, 0.22, 0.0), 0.16, Color.WHITE, Vector3(1.0, 1.15, 1.0), 10)
		# Three small leaves up the stem.
		var lw := PackedFloat32Array([0.03, 0.12, 0.16, 0.13, 0.07, 0.0])
		for k in 3:
			var idx := 6 + k * 7
			var p := pts[idx]
			var o := Vector3(p.x, 0.0, p.z).normalized()
			if o.length_squared() < 0.01:
				o = Vector3.RIGHT
			blade(kit, p, o, 0.62 - 0.08 * float(k), lw, 0.15, 0.22, 0.3, leaf.darkened(0.06), leaf.lightened(0.06), 0.12)
		# Foot: a small root collar.
		kit.cylinder(Vector3(0.0, -0.08, 0.0), 0.22, 0.10, 0.20, stem.darkened(0.25), Basis.IDENTITY, 8)
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)


# ======================================================================================== understory
## BROADLEAF CLUMP, 0.9-1.5 m: five to seven heart-shaped leaves on arching stalks. One surface.
## Instanced through a MultiMesh; the caller passes no instance tint.
static func broadleaf(leaf: Color, leaf_light: Color, stalk: Color, variant: int) -> ArrayMesh:
	# PHONE HEAT (2026-09-30): the 2 cm leaf stalks were 5-sided tubes, ~120 of a clump's ~390 tris. On the
	# low-power profile they are 3-sided (a stalk that thin reads the same either way).
	var stalk_sides := 3 if low_power() else 5
	var key := "jbroad|%s|%s|%s|%d|%d" % [leaf.to_html(), leaf_light.to_html(), stalk.to_html(), variant, stalk_sides]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var veins: PlanetMeshKit = PlanetMeshKit.new() if variant == 0 else null
		var rng := RandomNumberGenerator.new()
		rng.seed = 9500 + variant
		var n := 5 + variant % 3
		# Heart: wide lobes at the base, widest a third along, a drawn-out tip.
		var widths := PackedFloat32Array([0.05, 0.21, 0.25, 0.21, 0.12, 0.0])
		for k in n:
			var a := TAU * float(k) / float(n) + rng.randf_range(-0.25, 0.25)
			var o := Vector3(cos(a), 0.0, sin(a))
			var sh := rng.randf_range(0.45, 0.95)
			var top := o * (0.10 + 0.25 * sh) + Vector3(0.0, 0.35 + 0.55 * sh, 0.0)
			tube(kit, PackedVector3Array([o * 0.03, o * 0.05 + Vector3(0.0, top.y * 0.55, 0.0), top]),
				PackedFloat32Array([0.022, 0.018, 0.014]), PackedColorArray([stalk.darkened(0.15), stalk, stalk]), stalk_sides, false)
			var sc := rng.randf_range(0.8, 1.15)
			var ws := PackedFloat32Array()
			for w in widths:
				ws.append(w * sc)
			blade(kit, top, o, 0.62 * sc, ws, 0.10, 0.30, 0.28, leaf, leaf_light if k % 2 == 0 else leaf.lerp(leaf_light, 0.4), 0.14, veins)
		var mesh := kit.commit()
		if veins != null:
			veins.commit(mesh)
		return mesh
	return _cached(key, build)


## FIDDLEHEADS, 0.3-0.5 m: a tight cluster of curled fern croziers. One surface.
static func fiddleheads(stem: Color, curl: Color, variant: int) -> ArrayMesh:
	var key := "jfiddle|%s|%s|%d" % [stem.to_html(), curl.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var n := 3 + variant % 2
		for k in n:
			var a := TAU * float(k) / float(n) + 0.9 * float(variant)
			var o := Vector3(cos(a), 0.0, sin(a))
			var h := 0.30 + 0.07 * float((k + variant) % 3)
			var pts := PackedVector3Array()
			var radii := PackedFloat32Array()
			var cols := PackedColorArray()
			for i in 6:
				var t := float(i) / 5.0
				pts.append(o * (0.05 + 0.06 * t) + Vector3(0.0, h * t - 0.03, 0.0))
				radii.append(0.022)
				cols.append(stem.lerp(curl, t * 0.6))
			var top := pts[5]
			for i in range(1, 9):
				var s := float(i) / 8.0
				var ang := s * PI * 1.8
				var rad := 0.075 * (1.0 - 0.6 * s)
				pts.append(top + o * sin(ang) * rad + Vector3(0.0, (1.0 - cos(ang)) * rad, 0.0))
				radii.append(lerpf(0.022, 0.012, s))
				cols.append(curl)
			tube(kit, pts, radii, cols, 5, true)
		return kit.commit()
	return _cached(key, build)


## GLOW FUNGUS: three to five small flat-capped fungi. Surface 0 stems + gill rims, surface 1 caps.
static func glow_fungus(stem: Color, variant: int) -> ArrayMesh:
	var key := "jfungus|%s|%d" % [stem.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var n := 3 + variant % 3
		for k in n:
			var a := TAU * float(k) / float(n) + 1.3 * float(variant)
			var d := 0.05 + 0.09 * float(k % 3)
			var p := Vector3(cos(a) * d, 0.0, sin(a) * d)
			var h := 0.10 + 0.07 * float((k * 2 + variant) % 4)
			var r := 0.06 + 0.025 * float((k + variant) % 3)
			kit.cylinder(p - Vector3(0.0, 0.03, 0.0), 0.022, 0.016, h + 0.03, stem, Basis.IDENTITY, 6)
			kit.cylinder(p + Vector3(0.0, h - 0.012, 0.0), r * 0.35, r, 0.014, stem.darkened(0.25), Basis.IDENTITY, 10)
			glow.lathe(PackedVector2Array([Vector2(0.0, h), Vector2(r, h), Vector2(r * 0.9, h + r * 0.28), Vector2(r * 0.45, h + r * 0.46), Vector2(0.0, h + r * 0.5)]),
				10, Transform3D.IDENTITY, Color.WHITE, false)
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)


## SEED POD, 0.9-1.4 m: a faceted ribbed ovoid half-sunk in the moss, with a glowing seam (surface 1).
static func seed_pod(shell: Color, cap: Color, variant: int) -> ArrayMesh:
	var key := "jpod|%s|%s|%d" % [shell.to_html(), cap.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var s := 0.85 + 0.2 * float(variant % 3)
		var prof := PackedVector2Array([Vector2(0.0, -0.12), Vector2(0.36, -0.10), Vector2(0.50, 0.28),
			Vector2(0.48, 0.66), Vector2(0.34, 1.00), Vector2(0.14, 1.18), Vector2(0.0, 1.22)])
		for i in prof.size():
			prof[i] = prof[i] * s
		var tilt := Basis(Vector3(1.0, 0.0, 0.3).normalized(), 0.10 + 0.08 * float(variant % 2))
		kit.lathe(prof, 8, Transform3D(tilt, Vector3.ZERO), shell, false)
		# A darker husk collar at the foot, and a tuft at the tip.
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.12), Vector2(0.56 * s, -0.12), Vector2(0.46 * s, 0.14 * s), Vector2(0.0, 0.14 * s)]),
			8, Transform3D(tilt, Vector3.ZERO), shell.darkened(0.22), false)
		kit.cylinder(tilt * Vector3(0.0, 1.16 * s, 0.0), 0.06 * s, 0.02 * s, 0.22 * s, cap, tilt, 6)
		# Glowing seams down two of the facet edges.
		for k in 2:
			var a := TAU * (float(k) * 0.5 + 0.0625)
			for j in 5:
				var t := 0.2 + 0.15 * float(j)
				var y := lerpf(0.30, 0.95, t) * s
				var rr := (0.50 - 0.25 * t * t) * s
				glow.sphere(tilt * Vector3(cos(a) * rr, y, sin(a) * rr), 0.035 * s, Color.WHITE, Vector3(1.0, 2.2, 1.0), 6, tilt)
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)


## REEDS: five to seven tall thin blades, two with a dark seed head. One surface.
static func reeds(blade_col: Color, head: Color, variant: int) -> ArrayMesh:
	# PHONE HEAT (2026-09-30): the cattail head was a stock CapsuleMesh (64 sides) - ~450 tris for a 3 cm
	# knob, so one reed clump cost 1,374 tris, more than three tall ferns. On the low-power profile it is an
	# 8-sided stretched sphere (~100 tris); the silhouette at 3 cm across is the same.
	var low := low_power()
	var key := "jreeds|%s|%s|%d|%s" % [blade_col.to_html(), head.to_html(), variant, low]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var n := 5 + variant % 3
		for k in n:
			var a := TAU * float(k) / float(n) + 0.7 * float(variant)
			var o := Vector3(cos(a), 0.0, sin(a))
			var side := Vector3(-o.z, 0.0, o.x) * 0.022
			var h := 0.62 + 0.14 * float((k * 3 + variant) % 4)
			var lean := 0.10 + 0.04 * float(k % 3)
			var b := o * 0.04 - Vector3(0.0, 0.04, 0.0)
			var m := o * (0.04 + lean * 0.4) + Vector3(0.0, h * 0.5, 0.0)
			var t := o * (0.04 + lean) + Vector3(0.0, h, 0.0)
			kit.quad(b - side, b + side, m + side * 0.8, m - side * 0.8, blade_col.darkened(0.12))
			kit.triangle(m - side * 0.8, m + side * 0.8, t, blade_col)
			if k % 3 == 0:
				var hb := Basis(o.cross(Vector3.UP).normalized(), -lean * 1.2)
				if low:
					kit.sphere(m + (t - m) * 0.55, 0.03, head, Vector3(1.0, 0.17 / 0.06, 1.0), 8, hb)
				else:
					kit.capsule(m + (t - m) * 0.55, 0.03, 0.17, head, hb)
		return kit.commit()
	return _cached(key, build)


## LILY PAD, flat on the water: a notched disc with a slightly raised rim. One surface.
static func lily_pad(pad: Color, rim: Color, variant: int) -> ArrayMesh:
	var key := "jlily|%s|%s|%d" % [pad.to_html(), rim.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var r := 0.26 + 0.07 * float(variant % 3)
		var segs := 14
		var notch := 0.42
		var centre := Vector3(0.0, 0.01, 0.0)
		for i in segs:
			var a0 := notch * 0.5 + (TAU - notch) * float(i) / float(segs)
			var a1 := notch * 0.5 + (TAU - notch) * float(i + 1) / float(segs)
			var p0 := Vector3(cos(a0) * r, 0.025, sin(a0) * r)
			var p1 := Vector3(cos(a1) * r, 0.025, sin(a1) * r)
			kit.triangle(centre, p0, p1, pad.darkened(0.04 * float(i % 2)), false)
			var q0 := Vector3(cos(a0) * r * 1.04, 0.045, sin(a0) * r * 1.04)
			var q1 := Vector3(cos(a1) * r * 1.04, 0.045, sin(a1) * r * 1.04)
			kit.quad(p0, p1, q1, q0, rim)
		if variant % 3 == 0:
			kit.cylinder(Vector3(r * 0.25, 0.02, 0.0), 0.05, 0.015, 0.12, rim.lightened(0.25), Basis.IDENTITY, 6)
		return kit.commit()
	return _cached(key, build)



## TALL FERN, 1.4-2.2 m: a rosette of long serrated fronds springing up and arching out from a dark
## crown - the bulk of the understory, the thing that makes the floor read as jungle and not lawn.
## One surface; instanced through a MultiMesh.
static func tall_fern(frond: Color, frond_light: Color, crown: Color, variant: int) -> ArrayMesh:
	var key := "jfern|%s|%s|%s|%d" % [frond.to_html(), frond_light.to_html(), crown.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var veins: PlanetMeshKit = PlanetMeshKit.new() if variant == 1 else null
		var rng := RandomNumberGenerator.new()
		rng.seed = 9700 + variant
		kit.cylinder(Vector3(0.0, -0.05, 0.0), 0.16, 0.08, 0.22, crown, Basis.IDENTITY, 7)
		var widths := PackedFloat32Array()
		for i in 7:
			var t := float(i) / 6.0
			widths.append(0.19 * pow(sin(PI * (0.05 + 0.95 * t)), 0.7) * (0.62 if i % 2 == 1 else 1.0))
		var n := 7 + variant % 3
		for k in n:
			var a := TAU * float(k) / float(n) + rng.randf_range(-0.2, 0.2)
			var o := Vector3(cos(a), 0.0, sin(a))
			var length := rng.randf_range(1.3, 1.8)
			blade(kit, Vector3(0.0, 0.10, 0.0) + o * 0.05, o, length, widths, rng.randf_range(0.95, 1.2),
				rng.randf_range(0.85, 1.05), 0.35, frond.darkened(0.10), frond_light, 0.12, veins)
		var mesh := kit.commit()
		if veins != null:
			veins.commit(mesh)
		return mesh
	return _cached(key, build)

# ======================================================================================== giants
## L1 LOOK (2026-09-29): the lead's read of the landing view was "a green planet with some arches, not a
## full alien jungle". The two shapes below have no Earth analogue - they are the silhouettes that say
## "alien" before the colour does - and JungleProps puts a ring of them round the landing view.

## GIANT BLOOM, 4-5 m: a thick stalk that climbs, arcs over and hooks down, hanging one huge bell of
## drooping petals with glowing stamens dangling out of it; three broad blades at the foot. The hook leans
## along local -Z (the `forward_hint` of the caller), so a bloom can be aimed to arch toward a view.
## Surface 0 body (foliage material), surface 1 stamen beads. ~2,000 tris.
static func giant_bloom(stalk: Color, petal: Color, petal_light: Color, leaf: Color, variant: int) -> ArrayMesh:
	var key := bloom_key(stalk, petal, petal_light, leaf, variant)
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 9900 + variant
		var h := 3.7 + 0.35 * float(variant % 3)
		var lean := 1.3 + 0.25 * float(variant % 2)
		var fwd := Vector3(0.0, 0.0, -1.0)
		var pts := PackedVector3Array()
		var radii := PackedFloat32Array()
		var cols := PackedColorArray()
		var n := 22
		for i in n + 1:
			var t := float(i) / float(n)
			# Rises, leans over, and the last quarter hooks down under its own bloom.
			var y := h * sin(t * PI * 0.62) / sin(PI * 0.62) - 0.12
			var hook := maxf(t - 0.78, 0.0) / 0.22
			y -= hook * hook * 0.55
			pts.append(fwd * lean * pow(t, 1.6) + Vector3(0.0, y, 0.0))
			radii.append(lerpf(0.21, 0.085, pow(t, 0.7)))
			var ring := (i % 3 == 1) and i < n - 1
			cols.append(stalk.lerp(stalk.lightened(0.18), t).darkened(0.10 if ring else 0.0))
		tube(kit, pts, radii, cols, 8, false)
		var head := pts[n]
		# Calyx: a short dark cone the petals spring from.
		kit.cylinder(head - Vector3(0.0, 0.16, 0.0), 0.12, 0.24, 0.22, stalk.darkened(0.2), Basis.IDENTITY, 10)
		var widths := PackedFloat32Array([0.10, 0.24, 0.30, 0.28, 0.20, 0.08, 0.0])
		var np := 7 + variant % 2
		for k in np:
			var a := TAU * float(k) / float(np) + rng.randf_range(-0.1, 0.1)
			var o := Vector3(cos(a), 0.0, sin(a))
			blade(kit, head + o * 0.10 - Vector3(0.0, 0.02, 0.0), o, rng.randf_range(0.95, 1.15), widths,
				0.18, rng.randf_range(0.95, 1.2), 0.28, petal.darkened(0.08), petal_light, 0.16)
		# Stamens dangling out of the bell.
		for k in 5:
			var a := TAU * float(k) / 5.0 + 0.3
			var at := head + Vector3(cos(a), 0.0, sin(a)) * 0.14 - Vector3(0.0, 0.08, 0.0)
			bead_strand(kit, glow, at, 2 + (k + variant) % 3, 0.2, 0.06, stalk.darkened(0.25))
		# Three broad blades at the foot.
		var lw := PackedFloat32Array([0.06, 0.22, 0.28, 0.24, 0.14, 0.0])
		for k in 3:
			var a := TAU * float(k) / 3.0 + 0.6 + 0.4 * float(variant)
			var o := Vector3(cos(a), 0.0, sin(a))
			blade(kit, o * 0.12 + Vector3(0.0, 0.05, 0.0), o, 1.25, lw, 0.55, 0.75, 0.3, leaf.darkened(0.06), leaf.lightened(0.08), 0.14)
		canopies[key] = [Vector4(head.x, head.y - 0.35, head.z, 1.1)]
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)


static func bloom_key(stalk: Color, petal: Color, petal_light: Color, leaf: Color, variant: int) -> String:
	return "jbloom|%s|%s|%s|%s|%d" % [stalk.to_html(), petal.to_html(), petal_light.to_html(), leaf.to_html(), variant]


## TUBE CLUSTER, 1.2-3.4 m: a stand of ringed hollow tubes (organ-pipe coral on land), each flaring to a
## lip with a glowing throat. Surface 0 body, surface 1 the throats. ~1,500 tris.
static func tube_cluster(tube_col: Color, lip: Color, throat: Color, variant: int) -> ArrayMesh:
	var key := "jtubes|%s|%s|%s|%d" % [tube_col.to_html(), lip.to_html(), throat.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 9950 + variant
		var n := 5 + variant % 3
		for k in n:
			var a := TAU * float(k) / float(n) + rng.randf_range(-0.3, 0.3)
			var d := 0.0 if k == 0 else rng.randf_range(0.35, 0.65)
			var base := Vector3(cos(a) * d, -0.10, sin(a) * d)
			var h := (3.3 if k == 0 else rng.randf_range(1.2, 2.7)) + 0.15 * float(variant % 2)
			var lean := Vector3(cos(a), 0.0, sin(a)) * (0.0 if k == 0 else rng.randf_range(0.15, 0.40))
			var r0 := (0.24 if k == 0 else rng.randf_range(0.13, 0.19))
			var pts := PackedVector3Array()
			var radii := PackedFloat32Array()
			var cols := PackedColorArray()
			var st := 12
			for i in st + 1:
				var t := float(i) / float(st)
				pts.append(base + lean * t * t + Vector3(0.0, h * t, 0.0))
				var ringed := i % 2 == 1 and i < st - 1
				var r := r0 * lerpf(1.25, 0.78, t) * (1.08 if ringed else 1.0)
				if i == st:
					r = r0 * 1.10
				radii.append(r)
				cols.append((tube_col.darkened(0.22).lerp(tube_col.lightened(0.06), t) if i < st else lip).darkened(0.10 if ringed else 0.0))
			tube(kit, pts, radii, cols, 9, false)
			var top := pts[st]
			# A dark plug just inside the lip (the tube is single-sided) and the glowing throat on it.
			kit.cylinder(top - Vector3(0.0, 0.10, 0.0), r0 * 1.02, r0 * 1.05, 0.06, tube_col.darkened(0.55), Basis.IDENTITY, 9)
			glow.cylinder(top - Vector3(0.0, 0.05, 0.0), r0 * 0.75, r0 * 0.75, 0.02, Color.WHITE, Basis.IDENTITY, 9)
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)


# ======================================================================================== landmarks
## ROOT ARCH: two great roots rising from either side of a trail and twisting together overhead,
## span 3.2 m along local X, apex ~2.9 m. Surface 0 body (wood-marked), surface 1 glow beads.
## Oriented with the span ACROSS the trail (-Z along it).
static func root_arch(bark: Color, moss: Color, variant: int) -> ArrayMesh:
	var key := "jarch|%s|%s|%d" % [bark.to_html(), moss.to_html(), variant]
	var build := func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var glow := PlanetMeshKit.new()
		var span := 1.65
		var apex := 2.85 + 0.2 * float(variant % 2)
		var main := PackedVector3Array()
		var mr := PackedFloat32Array()
		var mc := PackedColorArray()
		var twin := PackedVector3Array()
		var tr := PackedFloat32Array()
		var tc := PackedColorArray()
		var n := 26
		for i in n + 1:
			var t := float(i) / float(n)
			var ang := PI * t
			var p := Vector3(-cos(ang) * span, sin(ang) * apex - 0.18, 0.08 * sin(3.0 * ang + float(variant)))
			main.append(p)
			var foot := absf(t - 0.5) * 2.0
			mr.append(lerpf(0.16, 0.30, pow(foot, 2.2)))
			mc.append(_wood(bark.lerp(moss, clampf(sin(ang) - 0.55, 0.0, 1.0) * 0.9)))
			# The second root winds round the first.
			var w := TAU * 2.2 * t
			twin.append(p + Vector3(0.0, cos(w) * 0.22, sin(w) * 0.24) + Vector3(0.0, 0.0, 0.0))
			tr.append(lerpf(0.08, 0.13, pow(foot, 2.0)))
			tc.append(_wood(bark.darkened(0.12).lerp(moss, clampf(sin(ang) - 0.65, 0.0, 1.0))))
		tube(kit, main, mr, mc, 10, false)
		tube(kit, twin, tr, tc, 7, false)
		# Splayed feet: three root fingers on each side.
		for side in [-1.0, 1.0]:
			for k in 3:
				var a := (float(k) - 1.0) * 0.8
				var o := Vector3(side * cos(a), 0.0, sin(a))
				var f0 := Vector3(side * span, 0.35, 0.0)
				tube(kit, PackedVector3Array([f0, f0 + o * 0.35 + Vector3(0.0, -0.20, 0.0), f0 + o * 0.70 + Vector3(0.0, -0.48, 0.0)]),
					PackedFloat32Array([0.13, 0.09, 0.05]), PackedColorArray([_wood(bark), _wood(bark.darkened(0.1)), _wood(bark.darkened(0.2))]), 6, false)
		# Hanging moss beards under the span.
		for k in 7:
			var t := 0.22 + 0.56 * float(k) / 6.0
			var ang := PI * t
			var p := Vector3(-cos(ang) * span, sin(ang) * apex - 0.18 - 0.24, 0.0)
			var l := 0.35 + 0.30 * float((k * 5 + variant) % 3) * 0.5
			var s := Vector3(0.05, 0.0, 0.0)
			kit.quad(p - s, p + s, p + s * 0.3 - Vector3(0.0, l, 0.0), p - s * 0.3 - Vector3(0.0, l, 0.0), moss.darkened(0.12))
			kit.quad(p - Vector3(0.0, 0.0, 0.05), p + Vector3(0.0, 0.0, 0.05), p + Vector3(0.0, -l * 0.8, 0.015), p + Vector3(0.0, -l * 0.8, -0.015), moss.darkened(0.2))
		# Glow beads studding the top of the span.
		for k in 9:
			var t := 0.18 + 0.64 * float(k) / 8.0
			var p := main[int(round(t * float(n)))]
			var r := mr[int(round(t * float(n)))]
			var nrm := Vector3.UP
			var off := Vector3(0.0, 0.0, 0.16 if k % 2 == 0 else -0.16)
			glow.sphere(p + nrm * r * 0.85 + off, 0.045, Color.WHITE, Vector3(1.0, 0.8, 1.0), 6)
		var mesh := kit.commit()
		glow.commit(mesh)
		return mesh
	return _cached(key, build)
