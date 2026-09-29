class_name MeteorVantage
extends RefCounted
## THE LOOKOUTS (builder METEOR3, docs/STORY_HOME_SPEC.md 9.6.4; the user: "at least 2 higher up things you can
## climb on (or rocky ramps) to get a better look at what's around you ... conveniently placed always where theres a
## beacon spot nearby in the distance"). Made small by builder LOOKOUT (the 5 m crag hid the glow behind it), then
## rebuilt as a ROCKY RISE by builder RISE (2026-09-29; the user on the stair towers: "the current ramp looks really
## huge and unnatural. Definitely make it more natural and not stairs. Find another way to guide players to it that
## isnt so obvious. Its polish looks low as well").
##
## Now: a tongue of cooled lava rock pushed up out of the crust - a long gentle back you walk up (no steps), a
## small crest TOP_M over the ground, and a short broken cliff on the far side. It is the crust itself: drawn with
## meteor_crust.gdshader in the rock's own object space (so the ground's plates, tones and grain run straight up
## onto it with no seam), with `rise_mode` on for what only a rise has - layered strata on its steep faces, a dark
## contact where it meets the ground, the lava damped on its back, and the GUIDE: one faint teal crystal vein that
## runs up the walkable back to a lone glowing crystal on the crest. Boulders sit against its flanks and scree
## trails out from the foot toward where players come from. No flag, no glowing step edges.
##
## Why TOP_M is enough (builder LOOKOUT's sums, unchanged): on this 22 m rock the horizon from an eye `h` over the
## ground is acos(R / (R + h)) of arc away. Eye 1.1 m (standing): 17.8 deg. Eye 4.1 m (on a 3 m crest): 32.5 deg.
##
## Built in the rock's own frame (Y = the rock's up at the rise's centre, -Z = the way the walkable back runs OUT)
## against the real ground (`height_at`). Mesh vertices are written in the ROCK's space (the mesh node is top-level
## at identity) because the crust shader reads object space as rock space; the collider stays in the local frame.

## The crest's height over the ground at the centre (m), and its roughly level top's radius.
const TOP_M := 3.0
const CREST_R := 1.1
## The walkable back: its mean slope against the ground's own level halfway up (deg). The foot is eased into the
## ground, so the steepest part is ~1.2x this; plus the surface's own lumps. The player walks up to 62 deg.
const SLOPE_DEG := 21.0
## The far side: a short broken cliff, this far out past the crest (m).
const BACK_RUN_M := 1.5
## Half-width across the ridge at the crest and at the foot (m), and how wide its shoulders roll off.
const HALF_W_TOP := 1.8
const HALF_W_FOOT := 2.5
const SHOULDER_TOP := 1.15
const SHOULDER_FOOT := 1.9
## Grid spacing of the heightfield (m).
const CELL_M := 0.26
## Lumps: big and small, metres. Damped along the walk line so it stays an easy walk.
const LUMP_BIG := 0.30
const LUMP_SMALL := 0.11
const PATH_DAMP := 0.6
## The flanks' ledges: layer height (m) and how far the flank is pulled toward them (0 = smooth, 1 = benches).
const LEDGE_M := 0.45
const LEDGE_BLEND := 0.45
## The guide crystal on the crest.
const CRYSTAL := Color("#3fae9f")
const CRYSTAL_GLOW := Color("#7fe3d2")
const CRUST_SHADER := preload("res://src/meteor_survey/meteor_crust.gdshader")


## `xf` = the rise's centre on the planet (surface_transform at its direction, -Z = the way the back runs out).
## `looks` = world positions of what the crest looks out on (the cracks), so the crystal stands out of those views.
static func build(rock: Planet, xf: Transform3D, rng: RandomNumberGenerator, looks: Array = []) -> Node3D:
	var root := Node3D.new()
	root.name = "Lookout"
	root.global_transform = xf
	var inv := xf.affine_inverse()
	# The ground's height straight below local (x, z) - along the rise's own up, not along the ray from the rock's
	# centre (that one lands nearer the middle: at 13 m out it read 1.1 m high, and the scree trail floated).
	var centre := inv * Vector3.ZERO
	var ground_y := func(p: Vector3) -> float:
		var y := 0.0
		for k in range(3):
			var d := (xf * Vector3(p.x, y, p.z)).normalized()
			var h := rock.height_at(d)
			var dx := p.x - centre.x
			var dz := p.z - centre.z
			y = centre.y + sqrt(maxf(h * h - dx * dx - dz * dz, 0.0))
		return y
	var n_big := FastNoiseLite.new()
	n_big.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_big.seed = rng.randi()
	n_big.frequency = 0.55
	var n_small := FastNoiseLite.new()
	n_small.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_small.seed = rng.randi()
	n_small.frequency = 1.7
	var n_shape := FastNoiseLite.new()
	n_shape.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_shape.seed = rng.randi()
	n_shape.frequency = 0.35
	# ---- the foot: the nearest point out along the ground where the back's mean slope, measured against the
	# ground's level halfway up (the rock's up tilts 1 rad per 22 m), is no steeper than SLOPE_DEG.
	var u_foot := CREST_R + 2.0
	while u_foot < CREST_R + 14.0:
		var g := float(ground_y.call(Vector3(0.0, 0.0, -u_foot)))
		var tilt := (u_foot + CREST_R) * 0.5 / rock.radius
		if atan2(TOP_M - g, u_foot - CREST_R) - tilt <= deg_to_rad(SLOPE_DEG):
			break
		u_foot += 0.1
	var g_foot := float(ground_y.call(Vector3(0.0, 0.0, -u_foot)))
	# The ridge line bends a little (m sideways at `u`), so the back is not a straight chute.
	var ridge_x := func(u: float) -> float:
		return 0.35 * n_shape.get_noise_1d(u * 0.8 + 11.0) * smoothstep(0.0, 2.0, u)
	# ---- the shape: fraction 0..1 of the way from the ground to the crest height at local (x, z).
	var frac := func(x: float, z: float) -> float:
		var u := -z
		var p := 1.0
		var s := 0.0
		if u > CREST_R:
			s = clampf((u - CREST_R) / (u_foot - CREST_R), 0.0, 1.0)
			# Straight in the middle, eased into the ground over its last 30%.
			var t := 1.0 - s
			var w := 0.3
			var e := t - w * 0.5 if t >= w else t * t / (2.0 * w)
			p = e / (1.0 - w * 0.5)
		elif z > CREST_R:
			var q := (z - CREST_R) / BACK_RUN_M
			p = 0.0 if q >= 1.0 else 1.0 - pow(q, 1.6)
		else:
			p = 1.0 - 0.04 * (x * x + z * z) / (CREST_R * CREST_R)
		var hw := lerpf(HALF_W_TOP, HALF_W_FOOT, s) * (1.0 + 0.16 * n_shape.get_noise_2d(z * 1.3, 3.0))
		if z > CREST_R:
			hw *= 1.0 - 0.25 * clampf((z - CREST_R) / BACK_RUN_M, 0.0, 1.0)
		var sw := lerpf(SHOULDER_TOP, SHOULDER_FOOT, s)
		# Round the crest the top stays level at least CREST_R to each side, so a player standing there looks out
		# over a small plateau, not straight down a shoulder (first crest frames: the shoulder began 0.4 m from the
		# middle and filled the bottom of the look toward crack 5 as a dark facet).
		var inner := hw - sw
		var plateau := CREST_R * (1.0 - smoothstep(CREST_R, CREST_R + 2.0, absf(z)))
		if inner < plateau:
			hw += plateau - inner
			inner = plateau
		var ax := absf(x - float(ridge_x.call(u)))
		var lat := 1.0 - smoothstep(inner, hw, ax)
		return clampf(p, 0.0, 1.0) * lat
	# ---- the heightfield, in the local frame.
	var x_max := HALF_W_FOOT * 1.25 + 0.6
	var z_min := -(u_foot + 0.8)
	var z_max := CREST_R + BACK_RUN_M + 0.5
	var nx := int(ceil(2.0 * x_max / CELL_M))
	var nz := int(ceil((z_max - z_min) / CELL_M))
	var pts: Array = []    # [row][col] -> Vector3 local
	var fr: Array = []     # [row][col] -> frac
	for j in range(nz + 1):
		var prow: Array = []
		var frow: Array = []
		for i in range(nx + 1):
			var x := -x_max + float(i) * CELL_M
			var z := z_min + float(j) * CELL_M
			var f := float(frac.call(x, z))
			var g := float(ground_y.call(Vector3(x, 0.0, z)))
			var y := g + (TOP_M - g) * f
			# Lumps, fading out at the ground edge and damped along the walk line (crest and back).
			var u := -z
			var on_path := (1.0 - smoothstep(0.55, 1.2, absf(x - float(ridge_x.call(u))))) * (1.0 if u > -CREST_R else 0.0)
			# The crest (where players stand and look out) is calmer still.
			var crest_k := 1.0 - smoothstep(CREST_R * 0.7, CREST_R * 1.4, Vector2(x, z).length())
			var env := smoothstep(0.04, 0.35, f) * (1.0 - PATH_DAMP * on_path) * (1.0 - 0.5 * crest_k)
			y += (LUMP_BIG * n_big.get_noise_2d(x, z) + LUMP_SMALL * n_small.get_noise_2d(x, z)) * env
			# The flanks (off the walk line) are rougher and settle into wandering ledges: cooled flow layers, not steps.
			var flank := (1.0 - on_path) * smoothstep(0.08, 0.3, f) * (1.0 - smoothstep(0.9, 1.0, f))
			y += 0.16 * n_big.get_noise_2d(x * 1.6 + 20.0, z * 1.6) * flank
			var hy := (y - g) / LEDGE_M + 0.35 * n_shape.get_noise_2d(x * 2.0, z * 0.7)
			var tq: float = (floor(hy) + smoothstep(0.55, 1.0, fposmod(hy, 1.0))) * LEDGE_M + g - 0.35 * n_shape.get_noise_2d(x * 2.0, z * 0.7) * LEDGE_M
			y = lerpf(y, tq, LEDGE_BLEND * flank)
			# Tucked under the ground at the edge so the join never shows a gap or a flicker.
			y -= 0.3 * (1.0 - smoothstep(0.0, 0.1, f))
			# Steep parts jostle sideways a little (a heightfield's walls are otherwise combed straight).
			var steep := smoothstep(0.1, 0.6, f) * (1.0 - smoothstep(0.85, 1.0, f)) * (1.0 - on_path)
			var jx := 0.09 * n_small.get_noise_2d(x * 1.7 + 40.0, z * 1.7) * steep
			var jz := 0.09 * n_small.get_noise_2d(x * 1.7, z * 1.7 + 40.0) * steep
			prow.append(Vector3(x + jx, y, z + jz))
			frow.append(f)
		pts.append(prow)
		fr.append(frow)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for j in range(nz):
		for i in range(nx):
			var fmax := maxf(maxf(float(fr[j][i]), float(fr[j][i + 1])), maxf(float(fr[j + 1][i]), float(fr[j + 1][i + 1])))
			if fmax <= 0.001:
				continue
			var q := [[j, i], [j, i + 1], [j + 1, i + 1], [j + 1, i]]
			# Split each cell along the diagonal that follows the surface better (fewer ridges across the walk).
			var a: Vector3 = pts[j][i]
			var b: Vector3 = pts[j][i + 1]
			var c: Vector3 = pts[j + 1][i + 1]
			var d: Vector3 = pts[j + 1][i]
			var tris := [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]
			if absf(a.y - c.y) > absf(b.y - d.y):
				tris = [[q[0], q[1], q[3]], [q[1], q[2], q[3]]]
			for tri: Array in tris:
				# Every one of these index orders winds clockwise seen from above on the plain grid (Godot's front face),
				# so the skin faces out everywhere. Never flipped by the lumped geometry: a flip chosen from each
				# triangle's own normal turned a few near-vertical cliff triangles inward, and from the crest one read
				# as a big black wedge in the look toward crack 5 (first frames).
				var order := [0, 1, 2]
				for o: int in order:
					var kk: Array = tri[o]
					var lp: Vector3 = pts[kk[0]][kk[1]]
					var lu := -lp.z
					# UV: (across the ridge line, along the back from the crest centre) for the vein; UV2.x: the
					# fraction of the way up (the ground contact), UV2.y 0 = the rise's own skin.
					st.set_uv(Vector2(lp.x - float(ridge_x.call(lu)), lu))
					st.set_uv2(Vector2(float(fr[kk[0]][kk[1]]), 0.0))
					st.add_vertex(xf * lp)
					faces.append(lp)
	st.generate_normals()
	var mat := ShaderMaterial.new()
	mat.shader = CRUST_SHADER
	mat.set_shader_parameter("rise_mode", 1.0)
	mat.set_shader_parameter("vein_len", u_foot - 1.6)
	var skin := MeshInstance3D.new()
	skin.name = "Rise"
	skin.top_level = true
	skin.mesh = st.commit()
	skin.material_override = mat
	root.add_child(skin)
	# ---- boulders against the flanks and the cliff, scree at their feet, and a thin trail of stones out from the
	# foot toward where players come from. One mesh, same crust skin (UV2.y 1 = loose stone: no vein, no strata).
	var sb := SurfaceTool.new()
	sb.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stones: Array = []   # [local centre, radius, squash]
	for i in range(11):
		if i < 3:
			# Fallen from the cliff, at its foot.
			var r := rng.randf_range(0.4, 0.85)
			var bx := rng.randf_range(-HALF_W_TOP * 0.8, HALF_W_TOP * 0.8)
			stones.append([Vector3(bx, 0.0, CREST_R + BACK_RUN_M * 0.75 + r * 0.3), r, rng.randf_range(0.55, 0.8)])
		elif i < 9:
			# Big blocks half-buried in a flank, beside the back but never on the walk line.
			var r := rng.randf_range(0.5, 1.0)
			var sx := -1.0 if i % 2 == 0 else 1.0
			var bz := rng.randf_range(-u_foot * 0.65, CREST_R)
			stones.append([Vector3(sx * (frac_edge(frac, bz, sx, x_max) - r * 0.2), 0.0, bz), r, rng.randf_range(0.6, 0.85)])
		else:
			# A block on each shoulder of the back, below the crest (out of every view from the crest, which looks out
			# the other way), breaking the ridge's skyline from the side.
			var sx := -1.0 if i % 2 == 0 else 1.0
			var bz := -rng.randf_range(CREST_R + 1.4, CREST_R + 3.2)
			stones.append([Vector3(sx * rng.randf_range(1.35, 1.6), 0.0, bz), rng.randf_range(0.3, 0.42), rng.randf_range(0.6, 0.85)])
	for i in range(34):
		# Scree: small stones round the base, a third of them under the cliff.
		var p := Vector3.ZERO
		if i % 3 == 0:
			p = Vector3(rng.randf_range(-HALF_W_TOP, HALF_W_TOP), 0.0, CREST_R + BACK_RUN_M * rng.randf_range(0.75, 1.3))
		else:
			var sx := -1.0 if i % 2 == 0 else 1.0
			var sz := rng.randf_range(-u_foot * 0.75, CREST_R + 0.6)
			p = Vector3(sx * (frac_edge(frac, sz, sx, x_max) + rng.randf_range(-0.15, 0.8)), 0.0, sz)
		stones.append([p, rng.randf_range(0.07, 0.2), rng.randf_range(0.5, 0.8)])
	for i in range(14):
		# The trail: loose stones strung out past the foot, as if rolled down the back.
		var u := u_foot - 0.6 + float(i) * 0.45 + rng.randf_range(-0.2, 0.2)
		var x := float(ridge_x.call(u)) + rng.randf_range(-0.9, 0.9) * (0.5 + float(i) / 14.0)
		stones.append([Vector3(x, 0.0, -u), rng.randf_range(0.06, 0.16) * (1.0 - float(i) / 20.0), rng.randf_range(0.5, 0.8)])
	for s: Array in stones:
		var c: Vector3 = s[0]
		var r: float = s[1]
		# Sat on the surface below it (the rise or the ground), sunk a third.
		c.y = maxf(float(ground_y.call(c)), _surface_y(pts, fr, c, x_max, z_min)) - r * 0.35
		_stone(sb, faces if r > 0.34 else null, xf, c, r, float(s[2]), rng)
	sb.generate_normals()
	var loose_mat := ShaderMaterial.new()
	loose_mat.shader = CRUST_SHADER
	loose_mat.set_shader_parameter("rise_mode", 1.0)
	loose_mat.set_shader_parameter("vein_len", 0.0)
	var loose := MeshInstance3D.new()
	loose.name = "Boulders"
	loose.top_level = true
	loose.mesh = sb.commit()
	loose.material_override = loose_mat
	root.add_child(loose)
	# ---- the guide on the crest: a lone small cluster of glowing crystal at the near edge, where the vein ends.
	var cr := Node3D.new()
	cr.name = "Crystal"
	# At the crest's rim on the near (walk-up) side, beside the walk line, turned as far as it can be from every
	# look the crest is for: from the middle of the crest it sits behind the viewer's shoulder, never in a view.
	var look_a: Array = []
	for w: Vector3 in looks:
		var lp := inv * w
		look_a.append(atan2(lp.z, lp.x))
	var best_a := -PI * 0.5 + deg_to_rad(35.0)
	var best_gap := -1.0
	for k in range(-5, 6):
		if absi(k) < 2:
			continue
		var a := -PI * 0.5 + deg_to_rad(15.0 * k)
		var gap := PI
		for la: float in look_a:
			gap = minf(gap, absf(angle_difference(a, la)))
		if gap > best_gap + 0.01:
			best_gap = gap
			best_a = a
	var cx := cos(best_a) * CREST_R * 1.05
	var cz := sin(best_a) * CREST_R * 1.05
	cr.position = Vector3(cx, _surface_y(pts, fr, Vector3(cx, 0.0, cz), x_max, z_min) - 0.05, cz)
	root.set_meta("crystal_off_look_deg", rad_to_deg(best_gap))
	var cmat := MeteorProps._crystal(CRYSTAL, CRYSTAL_GLOW)
	for k: Array in [[0.62, 0.17, Vector3.ZERO, Vector3(0.12, 0.0, -0.16)], [0.4, 0.13, Vector3(0.16, 0.0, 0.08),
			Vector3(-0.1, 0.0, 0.42)], [0.3, 0.11, Vector3(-0.12, 0.0, 0.1), Vector3(0.3, 0.0, -0.35)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = MeteorProps.shard_mesh(rng, float(k[0]), float(k[1]), 6, 0.12)
		mi.material_override = cmat
		mi.position = k[2]
		mi.rotation = k[3]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cr.add_child(mi)
	root.add_child(cr)
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)
	# For the level and its tests (local): the foot of the back, the crest, and a walk from one to the other.
	var top_c := Vector3(0.0, TOP_M, 0.0)
	root.set_meta("foot", Vector3(float(ridge_x.call(u_foot + 0.3)), g_foot, -u_foot - 0.3))
	root.set_meta("top", top_c)
	root.set_meta("top_r", CREST_R)
	root.set_meta("reach_r", u_foot)
	var path: Array = []
	for u: float in [u_foot + 0.6, u_foot * 0.7, u_foot * 0.4, CREST_R * 0.8, 0.0]:
		path.append(Vector3(float(ridge_x.call(u)), 0.0, -u))
	path[path.size() - 1] = top_c
	root.set_meta("path", path)
	return root


## How far out from the ridge (x, on side `sx`) the rise's skin meets the ground at `z`: the first grid-free
## search outward where the shape fraction drops under 0.12.
static func frac_edge(frac: Callable, z: float, sx: float, x_max: float) -> float:
	var x := 0.0
	while x < x_max:
		if float(frac.call(sx * x, z)) < 0.12:
			return x
		x += 0.1
	return x_max


## The heightfield's own height (local) under `p`, bilinear; -INF outside it.
static func _surface_y(pts: Array, fr: Array, p: Vector3, x_max: float, z_min: float) -> float:
	var fi := (p.x + x_max) / CELL_M
	var fj := (p.z - z_min) / CELL_M
	var i := int(floor(fi))
	var j := int(floor(fj))
	if j < 0 or i < 0 or j >= pts.size() - 1 or i >= (pts[0] as Array).size() - 1:
		return -INF
	var tx := fi - i
	var tz := fj - j
	var y0 := lerpf((pts[j][i] as Vector3).y, (pts[j][i + 1] as Vector3).y, tx)
	var y1 := lerpf((pts[j + 1][i] as Vector3).y, (pts[j + 1][i + 1] as Vector3).y, tx)
	return lerpf(y0, y1, tz)


## One lumpy stone: a once-subdivided octahedron pushed in and out, squashed, turned. Flat facets (chipped rock).
## Written in the rock's space; its faces also go into the collider (local) when `faces` is given.
static func _stone(st: SurfaceTool, faces: Variant, xf: Transform3D, c: Vector3, r: float, squash: float,
		rng: RandomNumberGenerator) -> void:
	var base := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	var tris := [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [0, 4, 3], [4, 1, 3], [1, 5, 3], [5, 0, 3]]
	var verts: Array = base.duplicate()
	var mids := {}
	var fine: Array = []
	for t: Array in tris:
		var m: Array = []
		for e: Array in [[t[0], t[1]], [t[1], t[2]], [t[2], t[0]]]:
			var key := "%d_%d" % [mini(e[0], e[1]), maxi(e[0], e[1])]
			if not mids.has(key):
				mids[key] = verts.size()
				verts.append(((verts[e[0]] as Vector3) + (verts[e[1]] as Vector3)).normalized())
			m.append(mids[key])
		fine.append_array([[t[0], m[0], m[2]], [m[0], t[1], m[1]], [m[2], m[1], t[2]], [m[0], m[1], m[2]]])
	var rot := Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3))
	var pos: Array = []
	for v: Vector3 in verts:
		var k := rng.randf_range(0.78, 1.12)
		var q := Vector3(v.x * k, v.y * k * squash, v.z * k) * r
		pos.append(c + rot * q)
	for t: Array in fine:
		var a: Vector3 = pos[t[0]]
		var b: Vector3 = pos[t[1]]
		var d: Vector3 = pos[t[2]]
		var order := [a, d, b] if (b - a).cross(d - a).dot((a + b + d) / 3.0 - c) > 0.0 else [a, b, d]
		for v: Vector3 in order:
			st.set_uv(Vector2(99.0, 99.0))
			st.set_uv2(Vector2(0.5, 1.0))
			st.add_vertex(xf * v)
			if faces != null:
				(faces as PackedVector3Array).append(v)
