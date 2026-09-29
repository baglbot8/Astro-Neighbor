class_name CaveWorld
extends SafariWorld
## THE CAVE ITSELF (docs/STORY_HOME_SPEC.md 9.3 and 9.4; builder CAVE 2026-09-28, rebuilt by CAVE2 the
## same day after the user's play). Built by CaveVisit (cave_visit.gd) behind the black fade, freed when
## the player leaves. It is a SafariWorld so the planet safari's camera, focus, scoring and warm-up
## (planet_safari.gd, read-only) work on it unchanged.
##
## WHERE IT IS. Far below the home planet: R metres from the planet's centre, along DOWN. The player
## walks with the planet's own radial gravity (PlanetBody), so "down" there points at the planet. Every
## vertex is WARPED (`W`) onto shells around the planet's centre, so a floor at constant local height is
## exactly level for that gravity - no free parameter, the inverse of what the gravity does. At 600 m
## the camera's far plane (300 m, camera_rig.gd) culls the whole planet: the cave costs only itself.
##
## THE LOOK (CAVE3 2026-09-28, 9.5 item 5, the user: "shades of brown but lots of crystals (like a teal
## color and occasional rainbow ones) light up the cave a lot so it's not scary ... good textures").
## WARM BROWN STONE, lit by MANY glowing TEAL crystals along every hall and an occasional RAINBOW one.
## Stone is ONE mesh with two surfaces (walls, floor), each a plain StandardMaterial3D, unshaded: the
## light is BAKED into the vertex colours when the cave is built (a soft form light, and each crystal's
## own light and glow on the rock round it, `_stone_colour`), and a procedural rock texture
## (cave_rock_tex.gd: strata, cracks, grain, pebbles; mipmapped) is laid on TRIPLANAR and multiplies
## it. No custom shader, uniform array or light, so the phone draws what the desktop draws. (The old
## cave_lit.gdshader drew a dusky violet cave on the desktop, while the user saw it white on the iPhone -
## the cause was never found; this look does not depend on anything like it.)
## U1CAVE (2026-09-29, the user: "the cave can go a bit darker but also the tunnel looks too smooth it
## needs more uneven texture"): the rock has real relief now - bumps at ~1 m and ~0.45 m and level LEDGE
## bands on the walls (`_wall_off`), humps and broken rock at the foot of the walls (`_floor_off`,
## `_build_rubble`), finer rings to carry it (RING 40, STEP_M 0.36) - baked as light too (a crevice
## darker, a lip lighter; a wall facing a crystal takes more of its light than one turned away), and a
## rougher texture (cave_rock_tex.gd). Phone frames 2556x1179: rock medians ~20-25 % darker in sRGB, the
## path and the crystals unchanged.
## C4: CaveVisit gives the camera an identity look (no ACES, grade, fog or glow); light multiplies
## LINEAR colour (`_lit`).
## Until CAVE3 the cave was bright pearly white (9.4); the white-cave notes below that talk of white
## stone describe that look's reasoning where it still applies (the form light's ratio).
##
## SOMETHING TO LOOK AT EVERY FEW STEPS (9.5 item 6, the user: "mostly walking down the long halls with
## nothing major to look at"). Besides the twelve first subjects, eight new kinds, each its own Cave page:
## glow caps (mushrooms that puff spores), pulse crystals, a drip pool, a peek mole (pops out of its
## burrow when you come near), lantern worms (glowing threads from the roof), sleepy bats (one stretches
## now and then), a rainbow geode and a rainbow spire. A kind met on two routes is two subjects filed to
## one page ("glow_caps@2" -> the "glow_caps" page, CaveStore.offer_photo). Placed along each route so a
## walker meets something new every ~8-15 m (`debug` walk in the CAVE3 report).

## THE WAY DOWN IS A TREE OF TUBES with THREE FORKS (9.4, the user: "more than just one option to take a
## turn of direction ... the road slopes downward in one and upwards in another ... or curves left and
## curves right"). Every tube is laid by `_walk` from legs of [length, turn, rise], so "slopes down" and
## "curves left" are exact numbers, not a look:
##   LANDING  glow crystals, the prism moth, 16 m on to FORK 1.
##   FORK 1   DOWN THE SLOPE (the trunk: 37 m dropping 5.6 m, the steep part 23 %, opal snail on the way)
##            or UP THE CLIMB (the up road, bearing right: 34 m rising 4.6 m, the steep part 22 %,
##            glimmer newt on the way).
##   FORK 2   (bottom of the slope) CURVING LEFT, 98 deg, on down into THE BIG CHAMBER (pool, meteor
##            piece, crystal bloom, moth dance, aurora ray: the best views and three of the rarer sights),
##            or CURVING RIGHT, 85 deg, into THE GROTTO, a short dead end with a small rare subject (the
##            rainbow beetle).
##   FORK 3   (top of the climb) CURVING RIGHT, 108 deg, past the star fossil to THE CHEST, which holds
##            the Prism Suit once (CaveStore.chest_found), or CURVING LEFT, 63 deg, and climbing another
##            2.9 m to THE JELLY LOFT, a tall room where the drift jellies float.
## (`debug_branch_shapes` measures those numbers off the built tubes.)
## Three minutes (CaveVisit) at 1.5 m/s is 270 m of walking before any photos. Each route's end is
## 72-94 m from the landing (`debug_route_len`); a synthetic walker at walking speed stopping 6 x 4 s for
## photos reached every end in 72-86 s, but the four routes add up to 317 s, and seeing all four ends
## (with the walks back to the forks) is ~350 m, 233 s of walking alone. One side of the cave (both ends
## of the down side, or both of the up side) fits in a visit; the whole cave never does.
## Signs of the way are subtle: prism motes drift on down toward the chamber; gold flecks dust the
## floor up to the chest; rainbow pebbles lie in the grotto's mouth; pale bubbles rise toward the loft.
## At FORK 1 (C4) the up road's mouth is as wide and tall as the down way's, and each mouth has a crystal
## cluster at its near lip in its route's colour: gold up to the chest, and (CAVE3, since every hall is
## now lit teal) PRISMATIC rainbow down to the chamber.
##
## Each branch's mouth is cut out of the tube it leaves (and its own start inside that tube removed)
## by dropping triangles inside the other tube (`_keep`). A pale backstop shell round the whole cave
## makes any sliver left at a seam read as more white stone, never as the space sky.

const R := 600.0
## U1CAVE (9.29, the user: "the tunnel looks too smooth it needs more uneven texture"): 30 -> 40 facets
## round a ring and 0.45 -> 0.36 m between rings, so the rock's ledges and bumps (`_wall_off`) have
## vertices to live on (a 1.1 m ledge band gets ~3 vertices up the wall instead of ~2).
const RING := 40
const STEP_M := 0.36
const END_PINCH_M := 3.0
const TUNNEL_W := 2.2
const TUNNEL_H := 3.3
const DROP_M := 0.6

# Palette (sRGB; the material converts). Warm brown stone (CAVE3), a lighter worn path. The rock
# texture (mean ~0.84) multiplies these, so they are authored a step lighter than the stone reads.
const C_WALL := Color("#bb946f")
const C_CEIL := Color("#a88262")
const C_FLOOR := Color("#c9a47f")
const C_PATH := Color("#d4b390")
## Mineral patches in the brown: ochre, rust, umber, sand - never a stain.
const C_PEARL: Array[Color] = [Color("#c79a62"), Color("#b27a60"), Color("#a38a74"), Color("#cfaa82")]
## The cave's own light: glowing teal crystals everywhere, and their light on the stone.
const C_TEAL := Color("#35d8c4")
const C_TEAL_LIGHT := Color("#8fe6da")
## The broad light a crystal throws on the stone round it: a pale, barely-teal white.
const C_CRYSTAL_WASH := Color("#f2fbf6")
const C_AQUA := Color("#86d3cc")
## The down way's rainbow marker light at FORK 1 (a soft prism pink-lilac).
const C_DOWN_LIGHT := Color("#e2b4f2")
const C_LILAC := Color("#b3a0ec")
const C_GOLD := Color("#e6c062")
const C_AMBER := Color("#f0a468")
const C_CRUST := Color("#4a4458")
const C_SEAM := Color("#f59a52")
const C_EYE := Color("#262434")
const C_WOOD := Color("#a8724a")
const C_WOOD_DK := Color("#80553a")
const C_BRASS := Color("#d6a64c")
const LIGHT := Vector3(0.3, 1.0, 0.2)
## The form light's bounce share (`_stone_colour`): kept at the white cave's measured ratio (C4:
## rho 0.80 -> indirect/direct 4.0), because the room is now lit from every side by its crystals as the
## white walls once lit it by bounce. Not re-tuned for the brown.
const FORM_AMB := 4.0
## Crystal light on the stone: each light adds albedo x its colour x (1 - d/r)^2 x k x this, and glows
## over the stone by (1 - d/r)^2 x k x CRYSTAL_HAZE.
const CRYSTAL_GAIN := 1.6
const CRYSTAL_HAZE := 0.3
## CAVE4 (9.6 item 7, the user: "darken the cave more so that the glow from the crystals pops much more").
## The cave's own light, before any crystal: the share of the form light that reaches the rock with no
## crystal near. Everything that is not itself glowing - stone, rocks, critters, the chest - is lit by
## the SAME baked light (`_light`), so a thing in a dark stretch is dark and a thing by a crystal is lit.
## An art choice, judged on phone frames (2556x1179, gl_compatibility): at 1.0/0.9 (CAVE3) the halls'
## wall median luma was 0.42-0.58; at 0.4 it was 0.28-0.38 and still read washed; at 0.17 (with WASH_K
## 0.15) 0.17-0.25, the path still the lightest band (floor median 0.24-0.42) and the crystals ~0.9.
const CAVE_AMB := 0.045
## T1CAVE (9.29, the user: "Darken the cave"): 0.17 -> 0.045, WASH_K 0.15 -> 0.06, so the rock with no
## crystal near is dark brown and the crystals are the light (phone frames: hall wall median luma was
## ~0.2-0.27 sRGB, crystal-to-median ratio 3-4.5x). Two exceptions keep the cave playable and not scary:
## the path down the middle of every floor keeps PATH_LIFT x the rock's light (you can see where to walk
## and the forks' mouths), and the things you meet and photograph (every Kit: critters, the chest, signs)
## keep KIT_AMB, so a critter in a dark stretch still reads.
const PATH_LIFT := 1.8
const KIT_AMB := 0.1
## Each wall crystal's broad pale light on the rock round it (C3 added it so teal on brown did not read
## olive). Lowered with the ambient so the light pools round the crystals instead of filling the hall.
const WASH_K := 0.06
## The glow facets keep their colour (`Kit.g`): a crystal, an eye glint or a lamp is its own light.
const C_BACKSTOP := Color("#6d5540")

## The rare windows (seconds since the visit began). A visit reaches the chamber at ~63 s at the soonest.
const BLOOM_FIRST := 64.0
const BLOOM_EVERY := 45.0
const BLOOM_LEN := 14.0
const DANCE_FIRST := 78.0
const DANCE_EVERY := 50.0
const DANCE_LEN := 15.0
const RAY_FIRST := 68.0
const RAY_EVERY := 42.0
const RAY_LEN := 24.0
const MOTH_CYCLE := 8.0
const NEWT_CYCLE := 15.0
const BEETLE_CYCLE := 10.0
const JELLY_PULSE := 5.0

## The chest (9.4): open it by walking up to it.
const CHEST_REACH_M := 1.9
## Where the prism moth circles (path metres along the trunk, before FORK 1).
const MOTH_S := 8.0
const OUTFIT_ID := "suit_prism"

var cave: Node3D
var _mat: StandardMaterial3D
var _noise: FastNoiseLite
## U1CAVE: the rock's smaller relief (bumps ~1 m) and the waver of its ledge bands (`_wall_off`).
var _noise_b: FastNoiseLite
var _noise_s: FastNoiseLite
var trunk: Tube      # landing -> FORK 1 -> down the slope -> FORK 2 -> curving left -> the chamber
var upway: Tube      # FORK 1 -> up the climb -> FORK 3 -> curving right -> the chest
var grotto: Tube     # FORK 2 -> curving right -> the beetle
var loft: Tube       # FORK 3 -> curving left, climbing -> the jelly loft
var _tubes: Array[Tube] = []
## Named control points: "trunk:fork1" -> control index (from `_walk`'s marks).
var _mk: Dictionary = {}
var _loft_c := Vector3.ZERO
var _loft_t := Vector3.FORWARD
var _tints: Array = []          # [{p: local, c: Color, r: metres, k: strength}] baked into the stone
## The tints by 4 m cell (Vector3i -> [tint]), so baking a facet reads only the lights near it.
var _tint_grid: Dictionary = {}
const TINT_CELL := 4.0
var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _start_xf := Transform3D()

# live things
var _moth: Node3D
var _moth_wings: Array[Node3D] = []
var _moth_perch := Vector3.ZERO
var _moth_centre := Vector3.ZERO
var _snail: Node3D
var _snail_stalks: Array[Node3D] = []
var _snail_a := Vector3.ZERO
var _snail_b := Vector3.ZERO
var _newt: Node3D
var _newt_body: Node3D
var _newt_home := Vector3.ZERO
var _newt_out := Vector3.ZERO
var _beetle: Node3D
var _beetle_shells: Array[Node3D] = []
var _beetle_wings: Node3D
var _beetle_rest := Vector3.ZERO
var _jellies: Node3D
var _jelly_nodes: Array[Node3D] = []
var _jelly_tails: Array[Node3D] = []
var _ray: Node3D
var _ray_wings: Array[Node3D] = []
var _bloom: Node3D
var _bloom_plain: MeshInstance3D
var _bloom_prism: MeshInstance3D
var _bloom_motes: Array[Node3D] = []
var _dance: Node3D
var _dance_moths: Array[Node3D] = []
var _motes: Array[Node3D] = []
var _mote_s0 := 0.0
var _mote_s1 := 0.0
var _bubbles: Array[Node3D] = []
var _pool_centre := Vector3.ZERO
var _chamber_c := Vector3.ZERO
var _chamber_t := Vector3.FORWARD
var _chamber_side := Vector3.RIGHT
## The pool's rim wall (see _build_pool). CaveVisit leaves it out of every photo ray.
var pool_body: StaticBody3D
var _fossil_inward := Vector3.RIGHT
var _chest: Node3D
var _chest_lid: Node3D
var _chest_bundle: Node3D
var _chest_local := Vector3.ZERO
var _chest_state := 0            # 0 closed, 1 opening/open with the suit, 2 open and empty
var _chest_open_t := -1.0
var _chest_said_empty := false


# ============================================================================== WARP AND FRAMES
## Cave-local point -> cave-local point bent onto the planet's gravity shells (see the header).
static func W(p: Vector3) -> Vector3:
	return Vector3(p.x, R, p.z).normalized() * (R + p.y) - Vector3(0.0, R, 0.0)


## Upright (for the planet's gravity) at local point p, -Z along `fwd`.
func X(p: Vector3, fwd: Vector3 = Vector3.FORWARD, s: float = 1.0) -> Transform3D:
	var q := W(p)
	var up := (q + Vector3(0.0, R, 0.0)).normalized()
	var f := fwd - up * fwd.dot(up)
	if f.length_squared() < 1e-6:
		f = Vector3.FORWARD - up * Vector3.FORWARD.dot(up)
	return Transform3D(Basis.looking_at(f.normalized(), up).scaled(Vector3.ONE * s), q)


func _world(p_local: Vector3) -> Vector3:
	return cave.global_transform * W(p_local)


## A rainbow colour: soft enough for docs/STYLE_GUIDE.md R2.6 (S ~0.58) but loud against white stone.
static func rb(h: float, s: float = 0.58, v: float = 0.96) -> Color:
	return Color.from_hsv(fposmod(h, 1.0), s, v)


# ============================================================================== THE TUBES
## One tunnel: a centreline through control points, a width and height along it (rooms widen it), and
## rings of faceted stone round it. A branch starts INSIDE its parent (`open_start`) and is cut into it.
class Tube:
	var id := ""
	var ctrl: Array[Vector3] = []
	## [control index, half-width, height, sigma (m along the path), drop (m the wall's ellipse runs below
	## the floor: bigger = a wider, flatter floor and straighter walls)]
	var rooms: Array = []
	var parent: Tube = null
	var open_start := false
	var pts := PackedVector3Array()
	var lens := PackedFloat32Array()
	var ws := PackedFloat32Array()
	var hs := PackedFloat32Array()
	var ds := PackedFloat32Array()
	## How much "room" each sample is in (1 in a room's middle, ~0 in a plain tunnel): rooms are lit
	## by their crystals, the tunnels between them a little dimmer, so a way on reads as a way on.
	var rk := PackedFloat32Array()
	var tans: Array[Vector3] = []
	var sides: Array[Vector3] = []
	var total := 0.0

	func _init(p_id: String, p_ctrl: Array[Vector3], p_rooms: Array, p_parent: Tube = null) -> void:
		id = p_id
		ctrl = p_ctrl
		rooms = p_rooms
		parent = p_parent
		open_start = p_parent != null
		_sample()

	func _sample() -> void:
		var n := ctrl.size()
		for i in range(n - 1):
			var p0: Vector3 = ctrl[maxi(i - 1, 0)]
			var p1: Vector3 = ctrl[i]
			var p2: Vector3 = ctrl[i + 1]
			var p3: Vector3 = ctrl[mini(i + 2, n - 1)]
			var steps := maxi(2, int(ceil(p1.distance_to(p2) / CaveWorld.STEP_M)))
			for k in steps:
				var t := float(k) / float(steps)
				var t2 := t * t
				var t3 := t2 * t
				pts.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
		pts.append(ctrl[n - 1])
		var acc := 0.0
		for i in pts.size():
			if i > 0:
				acc += pts[i].distance_to(pts[i - 1])
			lens.append(acc)
		total = acc
		for i in pts.size():
			var w := CaveWorld.TUNNEL_W
			var h := CaveWorld.TUNNEL_H
			var d := CaveWorld.DROP_M
			var roomy := 0.0
			for r: Array in rooms:
				var dist := pts[i].distance_to(ctrl[int(r[0])])
				var k := exp(-pow(dist / float(r[3]), 2.0))
				w = lerpf(w, float(r[1]), k)
				h = lerpf(h, float(r[2]), k)
				d = lerpf(d, float(r[4]), k)
				roomy = maxf(roomy, k)
			rk.append(roomy)
			var s := lens[i]
			var from_end := total - s
			var pinch := clampf((from_end if open_start else minf(s, from_end)) / CaveWorld.END_PINCH_M, 0.0, 1.0)
			pinch = 0.06 + 0.94 * sqrt(pinch)
			ws.append(w * pinch)
			hs.append(h * lerpf(0.55, 1.0, pinch))
			ds.append(d)
			var tn := pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]
			tn.y = 0.0
			tn = tn.normalized() if tn.length_squared() > 1e-6 else Vector3.FORWARD
			tans.append(tn)
			sides.append(tn.cross(Vector3.UP).normalized())

	func idx_at(s: float) -> int:
		var i := 0
		while i < lens.size() - 2 and lens[i + 1] < s:
			i += 1
		return i

	## The path length nearest control point `c`.
	func s_of(c: int) -> float:
		var target: Vector3 = ctrl[c]
		var best := 0
		for i in pts.size():
			if pts[i].distance_to(target) < pts[best].distance_to(target):
				best = i
		return lens[best]

	## The wall's ellipse at sample i: x = centre height, y = semi-axis. Top h + 0.6 above the floor,
	## bottom `drop` below it (the floor is cut flat at 0).
	func ell(i: int) -> Vector2:
		var top := hs[i] + 0.6
		var bot := -ds[i]
		return Vector2((top + bot) * 0.5, (top - bot) * 0.5)

	## Half-width at `y` above the floor.
	func wall_x(i: int, y: float) -> float:
		var e := ell(i)
		var q := (y - e.x) / e.y
		return ws[i] * sqrt(maxf(1.0 - q * q, 0.0))

	func nearest(p: Vector3, i0: int = 0, i1: int = -1) -> int:
		if i1 < 0:
			i1 = pts.size() - 1
		var best := i0
		var bd := INF
		for i in range(i0, i1 + 1):
			var d := pts[i].distance_squared_to(p)
			if d < bd:
				bd = d
				best = i
		return best

	## Inside this tube's open space (the un-noised ellipse scaled by `shrink`).
	func inside(p: Vector3, shrink: float, i0: int = 0, i1: int = -1) -> bool:
		var i := nearest(p, i0, i1)
		var l := p - pts[i]
		var along := l.dot(tans[i])
		if (i == 0 and along < -0.05) or (i == pts.size() - 1 and along > 0.05):
			return false
		var y := l.y
		if y < -0.25:
			return false
		var e := ell(i)
		var x := l.dot(sides[i]) / maxf(ws[i], 0.01)
		var q := (y - e.x) / e.y
		return x * x + q * q < shrink * shrink

	## Over this tube's floor (so a branch's floor there is a double floor and is dropped).
	func over_floor(p: Vector3, i0: int = 0, i1: int = -1) -> bool:
		var i := nearest(p, i0, i1)
		var l := p - pts[i]
		var along := l.dot(tans[i])
		if (i == 0 and along < -0.05) or (i == pts.size() - 1 and along > 0.05):
			return false
		return absf(l.y) < 0.7 and absf(l.dot(sides[i])) < wall_x(i, 0.0) - 0.05

	## {p (floor centre), t (heading), side (right), w, h, i}
	func at(s: float) -> Dictionary:
		var i := idx_at(s)
		return {"p": pts[i], "t": tans[i], "side": sides[i], "w": ws[i], "h": hs[i], "i": i}


# ============================================================================== BUILD
func build(s: PlanetSafari) -> void:
	safari = s
	cave = Node3D.new()
	cave.name = "Cave"
	add_child(cave)
	var centre := safari.planet.global_position if safari.planet != null else Vector3.ZERO
	cave.global_transform = Transform3D(Basis(Vector3.RIGHT, PI), centre + Vector3.DOWN * R)
	_noise = FastNoiseLite.new()
	_noise.seed = 9031
	_noise.frequency = 0.28
	_noise_b = FastNoiseLite.new()
	_noise_b.seed = 9032
	_noise_b.frequency = 0.95
	_noise_b.fractal_octaves = 2
	_noise_s = FastNoiseLite.new()
	_noise_s.seed = 9033
	_noise_s.frequency = 0.16
	_noise_s.fractal_octaves = 1
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.vertex_color_is_srgb = true
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.disable_fog = true
	_wall_mat = _stone_mat(CaveRockTex.wall())
	_floor_mat = _stone_mat(CaveRockTex.floor_tex())
	_make_tubes()
	_plan_tints()
	_plan_crystals()
	_plan_new_subjects()
	_build_stone()
	_build_backstop()
	_build_landing()
	_build_wall_crystals()
	_build_rubble()
	_build_new_subjects()
	_build_moth()
	_build_snail()
	_build_grotto()
	_build_fork_signs()
	_build_treasure_route()
	_build_chest()
	_build_chamber()
	_build_loft()
	_build_halos()
	var sp := trunk.at(1.6)
	_start_xf = cave.global_transform * X(sp["p"], sp["t"])


func start_xform() -> Transform3D:
	return _start_xf


## Lays a centreline by walking it: from `p0` facing `yaw0` (degrees; 0 = -Z, + = turning LEFT), each
## leg [length m, turn deg (+ left, - right), rise m (+ up, - down), mark] adds a control point every
## <= 4 m, turning and rising evenly along the leg. A mark names the leg's last point (`_mk`).
## Returns {pts, yaw (at the end), yaws: {mark: yaw there}}.
func _walk(id: String, p0: Vector3, yaw0: float, legs: Array) -> Dictionary:
	var pts: Array[Vector3] = [p0]
	var yaw := yaw0
	var p := p0
	var yaws := {}
	for leg: Array in legs:
		var n := maxi(1, int(ceil(float(leg[0]) / 4.0)))
		var dl := float(leg[0]) / float(n)
		for k in n:
			var a := deg_to_rad(yaw + float(leg[1]) / float(n) * 0.5)
			yaw += float(leg[1]) / float(n)
			p = p + Vector3(-sin(a) * dl, float(leg[2]) / float(n), -cos(a) * dl)
			pts.append(p)
		if str(leg[3]) != "":
			_mk["%s:%s" % [id, str(leg[3])]] = pts.size() - 1
			yaws[str(leg[3])] = yaw
	return {"pts": pts, "yaw": yaw, "yaws": yaws}


func _make_tubes() -> void:
	# THE TRUNK: the landing, FORK 1, DOWN THE SLOPE (20 %), FORK 2, then CURVING LEFT down to the chamber.
	# Every fork is LEVEL for 5 m before it and 7 m after it, on both ways: a branch's floor is dropped
	# where it lies over its parent's floor, so if either sloped inside the fork room the two floors met
	# at a ledge (measured: 0.3-0.5 m, and the walker stuck at the up road's mouth). Then they slope.
	var tw := _walk("trunk", Vector3(0, 0, 3.5), 0.0, [[3.5, 0, 0, "landing"], [12.5, 0, -0.2, "fork1"],
		[7, 8, 0, ""], [12, 8, -2.8, "slope"], [12, 9, -2.8, ""], [5, 0, 0, "fork2"],
		[7, 15, 0, ""], [27, 85, -3.4, ""], [10, 0, -0.3, "chamber"], [7, 0, 0, ""]])
	var tc: Array[Vector3] = tw["pts"]
	trunk = Tube.new("trunk", tc, [[_mk["trunk:landing"], 3.4, 4.2, 4.2, 0.6], [_mk["trunk:fork1"], 4.6, 4.8, 3.6, 0.8],
		[_mk["trunk:slope"], 3.3, 4.2, 3.0, 0.6], [_mk["trunk:fork2"], 4.8, 5.2, 3.8, 0.8],
		[_mk["trunk:chamber"], 10.5, 9.5, 7.5, 3.2]])
	# THE UP ROAD: from FORK 1 bearing right, UP THE CLIMB (20 %) to FORK 3, then CURVING RIGHT to the chest.
	var uw := _walk("upway", tc[_mk["trunk:fork1"]], float(tw["yaws"]["fork1"]) - 45.0, [[7, -5, 0, ""],
		[21, -5, 4.6, "newt"], [5, 0, 0, "fork3"], [7, -15, 0, ""], [16, -50, 0.6, "fossil"],
		[16, -45, -0.4, ""], [5, 0, 0, "chest"], [3, 0, 0, ""]])
	var uc: Array[Vector3] = uw["pts"]
	# FORK 1's up mouth (C4, the user: players walked past it). The up road leaves the fork room at
	# 45 deg, so where it crosses the trunk's wall it was a plain 2.2 m tunnel seen edge-on: a slit.
	# Its mouth now takes THE DOWN WAY'S OWN SIZE at the same distance past the fork (the trunk's half-
	# width and height there, and the slope room's 3.0 m spread), so from the approach the two ways
	# open alike and neither reads as the side passage. Nothing is chosen: every number is the trunk's.
	var f1: Vector3 = tc[_mk["trunk:fork1"]]
	var s_f1 := trunk.s_of(_mk["trunk:fork1"])
	var room_w := trunk.ws[trunk.idx_at(s_f1)]
	var mouth_c := 1
	while mouth_c < uc.size() - 1 and Vector2(uc[mouth_c].x - f1.x, uc[mouth_c].z - f1.z).length() < room_w:
		mouth_c += 1
	var down_i := trunk.idx_at(s_f1 + Vector2(uc[mouth_c].x - f1.x, uc[mouth_c].z - f1.z).length())
	upway = Tube.new("upway", uc, [[0, 2.1, 3.1, 2.0, 0.6], [mouth_c, trunk.ws[down_i], trunk.hs[down_i], 3.0, trunk.ds[down_i]],
		[_mk["upway:fork3"], 4.6, 4.8, 3.6, 0.8],
		[_mk["upway:fossil"], 3.4, 4.0, 3.4, 0.7], [_mk["upway:chest"], 3.3, 3.7, 2.6, 0.8]], trunk)
	# THE GROTTO: from FORK 2 bearing right, CURVING RIGHT, a short dead end.
	var gw := _walk("grotto", tc[_mk["trunk:fork2"]], float(tw["yaws"]["fork2"]) - 50.0, [[7, -10, 0, ""],
		[15, -70, -0.9, "nook"], [4, -10, 0, ""]])
	var gc: Array[Vector3] = gw["pts"]
	grotto = Tube.new("grotto", gc, [[0, 2.0, 3.0, 2.0, 0.6], [_mk["grotto:nook"], 2.9, 3.4, 2.4, 0.7]], trunk)
	# THE JELLY LOFT: from FORK 3 bearing left, CURVING LEFT and climbing again, a tall room at the top.
	var lw := _walk("loft", uc[_mk["upway:fork3"]], float(uw["yaws"]["fork3"]) + 50.0, [[7, 10, 0, ""],
		[15, 55, 2.9, ""], [5, 0, 0, "loft"], [3, 0, 0, ""]])
	var lc: Array[Vector3] = lw["pts"]
	loft = Tube.new("loft", lc, [[0, 2.0, 3.0, 2.0, 0.6], [_mk["loft:loft"], 3.8, 7.5, 3.5, 1.0]], upway)
	_tubes = [trunk, upway, grotto, loft]


## How much of the rock noise is kept near a junction: calm walls round a branch's mouth, so the cut
## follows the stone and no sliver opens.
func _junction_calm(p: Vector3) -> float:
	var k := 1.0
	for t: Tube in _tubes:
		if t.parent != null:
			k = minf(k, lerpf(0.25, 1.0, smoothstep(3.0, 7.0, p.distance_to(t.ctrl[0]))))
	return k


func _rock_nz(p: Vector3) -> float:
	return _noise.get_noise_3dv(p) + 0.45 * _noise.get_noise_3dv(p * 3.1 + Vector3(17.0, 3.0, 5.0))


## The tube's actual wall at path length s, `y` metres above the floor, on the right (sgn +1) or left
## (sgn -1): the same ellipse, clamp and noise the ring vertices get, so a thing set there sits on the
## rock. Local, unwarped.
func _wall_point(t: Tube, s: float, sgn: float, y: float) -> Vector3:
	var i := t.idx_at(s)
	var e := t.ell(i)
	var q := clampf((y - e.x) / e.y, -0.999, 0.999)
	var x := cos(asin(q)) * sgn
	var side := t.sides[i]
	var p: Vector3 = t.pts[i] + side * (t.ws[i] * x) + Vector3.UP * y
	var radial := (side * x + Vector3.UP * q * 0.8).normalized()
	var o := _wall_off(p, y, t.hs[i], radial, t.rk[i])
	return p + radial * (o.x + o.y)


## U1CAVE: how far the WALL at unwarped `p` (`yo` above the floor, `radial` its outward direction)
## stands off the tube's plain ellipse, along `radial` (+ = back into the rock). x: the old broad swell
## (`_rock_nz`, ~3.5 m); y: the new small relief - bumps at ~1 m and ~0.45 m, and LEDGES: the rock in
## level bands ~1.1 m tall (their heights waver), each band leaning out as it rises and stepping back at
## the next, so every band ends in a shelf lit from above, like bedded stone. The ledges are the walls'
## (not the roof's) and start a little above the floor. All of it calmed round a branch's mouth.
const LEDGE_BAND := 1.1
const LEDGE_DEPTH := 0.3
const BUMP_M := 0.2

func _wall_off(p: Vector3, yo: float, h: float, radial: Vector3, room: float) -> Vector2:
	var calm := _junction_calm(p)
	var big := _rock_nz(p) * lerpf(0.4, 0.65, clampf(yo / maxf(h, 0.1), 0.0, 1.0))
	var nb := _noise_b.get_noise_3dv(p)
	var nr := 0.5 - absf(_noise_b.get_noise_3dv(p * 2.2 + Vector3(5.0, 11.0, 2.0)))
	var bump := (nb + 0.55 * nr) * BUMP_M
	var u := (p.y + 0.7 * _noise_s.get_noise_3dv(p)) / LEDGE_BAND
	var f := u - floorf(u)
	var wallness := 1.0 - smoothstep(0.55, 0.9, absf(radial.y))
	var ledge := (0.5 - smoothstep(0.0, 0.78, f)) * LEDGE_DEPTH * wallness * smoothstep(0.15, 0.6, yo)
	return Vector2(big, (bump + ledge) * (1.0 + 0.5 * room)) * calm


## U1CAVE: the floor's rise at unwarped `p`, `fx` of the way from the middle to the wall's foot (0..1):
## the walked middle gets only a low unevenness (+-4 cm at ~1 m, calmed at the forks), and towards the
## walls the floor humps up into broken rock.
func _floor_off(p: Vector3, fx: float) -> Vector2:
	# No humps at all in a fork's room: there two tubes' floors meet edge to edge, and a hump on one
	# opened a dark seam against the other (a1 frames, FORK 1's up mouth).
	var edge := smoothstep(0.5, 0.95, fx)
	for t: Tube in _tubes:
		if t.parent != null:
			edge *= smoothstep(5.0, 11.0, p.distance_to(t.ctrl[0]))
	var nb := _noise_b.get_noise_3dv(p * 1.3 + Vector3(3.0, 0.0, 9.0))
	var mound := maxf(nb + 0.2, 0.0) * 0.26 * edge
	var calm := _junction_calm(p)
	return Vector2(_rock_nz(p) * 0.03 * calm, mound + nb * 0.04 * calm)


## A floor spot `frac` of the way to the wall (+ right, - left) at path length s.
func _floor_spot(t: Tube, s: float, frac: float) -> Dictionary:
	var a := t.at(s)
	a["q"] = (a["p"] as Vector3) + (a["side"] as Vector3) * t.wall_x(int(a["i"]), 0.0) * frac
	return a


## Path length along `t` (a branch) where its centreline leaves its parent's open space.
func _tube_mouth_s(t: Tube, par: Tube) -> float:
	var s := 0.0
	while s < t.total and par.inside(t.at(s)["p"] as Vector3 + Vector3.UP * 1.0, 1.0):
		s += 0.25
	return s


## A light baked into the stone at `p` (see `_stone_colour`); `haze` scales how much it also glows its
## colour over the rock (1 = CRYSTAL_HAZE).
func _tint(p: Vector3, c: Color, r: float, k: float, haze: float = 1.0) -> void:
	var g := {"p": p, "c": c, "r": r, "k": k, "lin": c.srgb_to_linear(), "hz": haze}
	_tints.append(g)
	var lo := Vector3i(((p - Vector3.ONE * r) / TINT_CELL).floor())
	var hi := Vector3i(((p + Vector3.ONE * r) / TINT_CELL).floor())
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				var key := Vector3i(x, y, z)
				if not _tint_grid.has(key):
					_tint_grid[key] = []
				(_tint_grid[key] as Array).append(g)


## The stone's material: unshaded, the baked vertex colour times the rock texture laid on triplanar in
## the cave's own (warped, local) space - one tile every 1 / 0.3 = 3.3 m, strata horizontal on the walls.
func _stone_mat(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false
	m.uv1_triplanar_sharpness = 3.0
	m.uv1_scale = Vector3(0.3, 0.3, 0.3)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


# ============================================================================== THE STONE
## Every tube's rings as flat-shaded triangles in ONE mesh (one draw), their colours baked (see header).
func _build_stone() -> void:
	# walls and floor: one mesh, two surfaces (two textures), one collision shape
	var wv := PackedVector3Array()
	var wn := PackedVector3Array()
	var wc := PackedColorArray()
	var fv := PackedVector3Array()
	var fnr := PackedVector3Array()
	var fc := PackedColorArray()
	for t: Tube in _tubes:
		_tube_tris(t, wv, wn, wc, fv, fnr, fc)
	var mesh := ArrayMesh.new()
	for k in 2:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = wv if k == 0 else fv
		arr[Mesh.ARRAY_NORMAL] = wn if k == 0 else fnr
		arr[Mesh.ARRAY_COLOR] = wc if k == 0 else fc
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(k, _wall_mat if k == 0 else _floor_mat)
	var v := wv.duplicate()
	v.append_array(fv)
	var mi := MeshInstance3D.new()
	mi.name = "Stone"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cave.add_child(mi)
	var body := StaticBody3D.new()
	body.name = "StoneBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(v)
	shape.backface_collision = true
	cs.shape = shape
	body.add_child(cs)
	cave.add_child(body)


func _tube_tris(t: Tube, wv: PackedVector3Array, wn: PackedVector3Array, wc: PackedColorArray,
		fv: PackedVector3Array, fnr: PackedVector3Array, fc: PackedColorArray) -> void:
	var n := t.pts.size()
	var loc := PackedVector3Array()      # unwarped
	var flo := PackedByteArray()
	var xs := PackedFloat32Array()
	# Each vertex's SMOOTH normal (the ring's own radial, UP on the floor). The stone is unshaded, so a
	# normal is used only to blend the triplanar rock texture: per-facet normals made each facet pick
	# its own projection, a shattered mosaic (CAVE3 frames); the ring's radial blends it smoothly.
	var rad := PackedVector3Array()
	# U1CAVE: each vertex's small relief, + where it sticks out into the tunnel (a ledge's lip, a hump
	# on the floor), - where it is sunk back (a crevice under a ledge): the stone is unshaded, so its
	# relief is also baked as light - a lip catches more, a crevice less (`_stone_colour` `occ`).
	var rel := PackedFloat32Array()
	for i in n:
		var c := t.pts[i]
		var side := t.sides[i]
		var w := t.ws[i]
		var h := t.hs[i]
		var e := t.ell(i)
		var fw := maxf(t.wall_x(i, 0.0) / maxf(w, 0.01), 0.05)
		for j in RING:
			var ang := TAU * float(j) / float(RING)
			var x := cos(ang)
			var y := sin(ang)
			var yo := e.x + e.y * y
			var floor_v := yo <= 0.0
			yo = maxf(yo, 0.0)
			var p := c + side * (w * x) + Vector3.UP * yo
			var radial := (side * x + Vector3.UP * y * 0.8).normalized()
			if floor_v:
				var fo := _floor_off(p, absf(x) / fw)
				p += Vector3.UP * (fo.x + fo.y)
				rel.append(fo.y)
			else:
				var o := _wall_off(p, yo, h, radial, t.rk[i])
				p += radial * (o.x + o.y)
				rel.append(-o.y)
			loc.append(p)
			rad.append(Vector3.UP if floor_v else -radial)
			flo.append(1 if floor_v else 0)
			xs.append(absf(x))
	# The junction zones this tube takes part in: [other tube, its sample range, as parent?]
	var zones: Array = []
	for o: Tube in _tubes:
		if o.parent == t:
			var j := o.ctrl[0]
			zones.append([o, j, 0, o.idx_at(18.0), true])
	if t.parent != null:
		var j := t.ctrl[0]
		var pidx := t.parent.nearest(j)
		zones.append([t.parent, j, maxi(pidx - 40, 0), mini(pidx + 40, t.parent.pts.size() - 1), false])
	var L := LIGHT.normalized()
	for i in range(n - 1):
		var e := t.ell(i)
		var ref_c := t.pts[i] + Vector3.UP * e.x
		for j in RING:
			var a0 := i * RING + j
			var a1 := i * RING + (j + 1) % RING
			var b0 := (i + 1) * RING + j
			var b1 := (i + 1) * RING + (j + 1) % RING
			for tri: Array in [[a0, b0, a1], [a1, b0, b1]]:
				var pa := loc[int(tri[0])]
				var pb := loc[int(tri[1])]
				var pc := loc[int(tri[2])]
				var cen := (pa + pb + pc) / 3.0
				var is_floor := flo[int(tri[0])] + flo[int(tri[1])] + flo[int(tri[2])] == 3
				if not _keep(cen, is_floor, zones):
					continue
				var fn := (pb - pa).cross(pc - pa)
				fn = fn.normalized() if fn.length_squared() > 1e-12 else Vector3.UP
				if fn.dot(ref_c - cen) < 0.0:
					fn = -fn
				var ax := (xs[int(tri[0])] + xs[int(tri[1])] + xs[int(tri[2])]) / 3.0
				var rv := (rel[int(tri[0])] + rel[int(tri[1])] + rel[int(tri[2])]) / 3.0
				var c := _stone_colour(cen, fn, is_floor, cen.y - t.pts[i].y, t.hs[i], ax, L, rv)
				var dim := lerpf(0.9 if is_floor else 0.8, 1.0, smoothstep(0.1, 0.7, t.rk[i]))
				c = _lit(c, dim)
				for q in 3:
					if is_floor:
						fv.append(W(loc[int(tri[q])]))
						fnr.append(Vector3.UP)
						fc.append(c)
					else:
						wv.append(W(loc[int(tri[q])]))
						wn.append(rad[int(tri[q])])
						wc.append(c)


## Cuts a branch's mouth: a parent's WALL triangle inside a child is dropped; a child's triangle inside
## its parent is dropped (its floor wherever it lies over the parent's floor, which then carries on).
func _keep(cen: Vector3, is_floor: bool, zones: Array) -> bool:
	for z: Array in zones:
		if cen.distance_to(z[1] as Vector3) > 11.0:
			continue
		var o: Tube = z[0]
		if bool(z[4]):
			if not is_floor and o.inside(cen, 0.9, int(z[2]), int(z[3])):
				return false
		else:
			if is_floor:
				if o.over_floor(cen, int(z[2]), int(z[3])):
					return false
			elif o.inside(cen, 0.97, int(z[2]), int(z[3])):
				return false
	return true


func _stone_colour(p: Vector3, fn: Vector3, is_floor: bool, y: float, h: float, ax: float, L: Vector3,
		rv: float = 0.0) -> Color:
	var c := C_WALL
	if is_floor:
		c = C_FLOOR.lerp(C_PATH, clampf(1.0 - ax * 1.7, 0.0, 1.0))
	elif y > h * 0.7:
		c = C_WALL.lerp(C_CEIL, clampf((y - h * 0.7) / (h * 0.4), 0.0, 1.0))
	# mineral patches: ochre, rust, umber or sand in the brown, never a stain
	var m := _noise.get_noise_3dv(p * 0.35 + Vector3(40, 0, 0))
	var pick := clampi(int((m * 0.5 + 0.5) * 4.0), 0, 3)
	c = c.lerp(C_PEARL[pick], smoothstep(0.05, 0.45, absf(m)) * 0.55)
	var jit := fmod(absf(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453), 1.0)
	# The form light (C4's derivation, kept): k = (amb + 2 dif) / (amb + 2), amb = FORM_AMB, a soft light
	# from above so the shape of the rock reads, and the crease where wall meets floor a little deeper.
	var dif := 0.5 + 0.5 * fn.dot(L)
	var k := (FORM_AMB + 2.0 * dif) / (FORM_AMB + 2.0) * (0.95 + 0.08 * jit)
	if is_floor:
		k *= lerpf(1.0, 0.88, smoothstep(0.75, 1.0, ax)) * lerpf(PATH_LIFT, 1.0, clampf(ax * 1.4, 0.0, 1.0))
	else:
		k *= lerpf(0.82, 1.0, smoothstep(0.0, 1.2, y))
	# U1CAVE: the relief's light - a crevice (rv < 0) sees less of the room and of its crystals, a lip
	# (rv > 0) more; and a crystal lights the faces turned to it (`fn`), not the ones turned away.
	return _lit(_light(p, c, k * CAVE_AMB, Vector3.ZERO if is_floor else fn), lerpf(0.7, 1.2, smoothstep(-0.22, 0.2, rv)))


## The cave's light at unwarped cave-local `p` on a thing of sRGB colour `c` whose own light share is
## `k` (CAVE3's crystal light, CAVE4 shared by everything): each crystal adds the thing's colour x its
## light, falling off as (1 - d/r)^2, and a glow of its colour over it. Linear light, like `_lit`.
func _light(p: Vector3, c: Color, k: float, fn: Vector3 = Vector3.ZERO) -> Color:
	var alb := c.srgb_to_linear()
	var lin := Color(alb.r * k, alb.g * k, alb.b * k)
	var haze := Color(0, 0, 0)
	var hz := 0.0
	var cell := Vector3i((p / TINT_CELL).floor())
	for g: Dictionary in _tint_grid.get(cell, []):
		var d := p.distance_to(g["p"] as Vector3)
		var r := float(g["r"])
		if d < r:
			var f := 1.0 - d / r
			var w := f * f * float(g["k"])
			if fn != Vector3.ZERO and d > 0.01:
				# U1CAVE: a wall facing the crystal takes its light, one turned away about half (the floor,
				# lit mostly from low crystals at a grazing angle, is left as it was)
				w *= 0.55 + 0.45 * maxf(fn.dot(((g["p"] as Vector3) - p) / d), 0.0)
			var gl: Color = g["lin"]
			lin.r += alb.r * gl.r * w * CRYSTAL_GAIN
			lin.g += alb.g * gl.g * w * CRYSTAL_GAIN
			lin.b += alb.b * gl.b * w * CRYSTAL_GAIN
			var wh := w * CRYSTAL_HAZE * float(g["hz"])
			haze += (g["c"] as Color) * wh
			hz += wh
	c = Color(minf(lin.r, 1.0), minf(lin.g, 1.0), minf(lin.b, 1.0)).linear_to_srgb()
	if hz > 0.0:
		c = c.lerp(haze / hz, minf(hz, 0.6))
	return c


## The backstop shell's and the view's background colour: the old pale-ceiling shade, in the cave's light.
static func backstop_colour() -> Color:
	return _lit(C_BACKSTOP, CAVE_AMB)


## Light factor `f` applied to an sRGB colour the way light works: in linear light (C4, `_stone_colour`).
static func _lit(c: Color, f: float) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * f, l.g * f, l.b * f).linear_to_srgb()


## A pale shell round the whole cave (cave-local, inside-out): a sliver at a seam shows stone, not space.
func _build_backstop() -> void:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for t: Tube in _tubes:
		for q in t.pts:
			lo = lo.min(q)
			hi = hi.max(q)
	var ctr := (lo + hi) * 0.5
	var rad := (hi - lo).length() * 0.5 + 16.0   # + the chamber's half-width and a margin
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = backstop_colour()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	var mi := MeshInstance3D.new()
	mi.name = "Backstop"
	mi.mesh = sm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cave.add_child(mi)
	mi.position = ctr


# ============================================================================== MESH KIT
## Flat-shaded triangles with the light baked into their colours (the header). `glow` 0..1 is how much
## a facet ignores the soft top light (a crystal core, an eye glint). `iri` >= 0 paints every facet a
## hue from its own normal - the rainbow, iridescent look of the cave's critters.
class Kit:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	## each vertex's glow (CAVE4): how much of its colour is its own light, kept when the cave lights it
	var g := PackedFloat32Array()
	## set while `gem` draws a glowing crystal: every facet of it is its own light (g = 1)
	var _lamp := false
	## set while `_shadow` draws: g = -darkness, and `_cave_lit` darkens the lit floor under it by that
	var shade := 0.0
	var iri := -1.0
	var iri_span := 0.5
	var iri_s := 0.58
	var iri_v := 0.96

	func tri(a: Vector3, b: Vector3, d: Vector3, col: Color, glow: float = 0.0) -> void:
		var nn := (b - a).cross(d - a)
		nn = nn.normalized() if nn.length_squared() > 1e-12 else Vector3.UP
		var cc := col
		if iri >= 0.0:
			var hue := iri + iri_span * (0.5 * nn.x + 0.35 * nn.z + 0.3 * nn.y)
			cc = CaveWorld.rb(hue, iri_s, iri_v)
		var lit := 0.8 + 0.2 * absf(nn.dot(Vector3(0.3, 1.0, 0.2).normalized()))
		var k := lerpf(lit, 1.0, clampf(glow, 0.0, 1.0))
		cc = Color(minf(cc.r * k + glow * 0.06, 1.0), minf(cc.g * k + glow * 0.06, 1.0), minf(cc.b * k + glow * 0.06, 1.0))
		v.append_array([a, b, d])
		n.append_array([nn, nn, nn])
		c.append_array([cc, cc, cc])
		var gg := -shade if shade > 0.0 else (1.0 if _lamp else clampf(glow, 0.0, 1.0))
		g.append_array([gg, gg, gg])

	func quad(a: Vector3, b: Vector3, d: Vector3, e: Vector3, col: Color, glow: float = 0.0) -> void:
		tri(a, b, d, col, glow)
		tri(a, d, e, col, glow)

	## A six-sided crystal: prism from `xf` origin up its Y by `h`, radius `r`, pointed tip.
	func gem(xf: Transform3D, r: float, h: float, col: Color, glow: float) -> void:
		var sides := 6
		_lamp = glow > 0.0
		var tip := xf * Vector3(0, h, 0)
		for k in sides:
			var a0 := TAU * float(k) / float(sides)
			var a1 := TAU * float(k + 1) / float(sides)
			var b0 := xf * Vector3(cos(a0) * r, 0.0, sin(a0) * r)
			var b1 := xf * Vector3(cos(a1) * r, 0.0, sin(a1) * r)
			var u0 := xf * Vector3(cos(a0) * r * 1.04, h * 0.68, sin(a0) * r * 1.04)
			var u1 := xf * Vector3(cos(a1) * r * 1.04, h * 0.68, sin(a1) * r * 1.04)
			var shade := 0.9 + 0.2 * float(k % 2)
			quad(b0, u0, u1, b1, Color(minf(col.r * shade, 1.0), minf(col.g * shade, 1.0), minf(col.b * shade, 1.0)), glow)
			tri(u0, tip, u1, col.lightened(0.5 if _lamp else 0.15), glow)
		_lamp = false

	## A low-poly faceted ellipsoid (never a smooth ball: STYLE_GUIDE "not bubbly"). `top_only` stops
	## at the equator (a jelly's bell, a beetle's shell).
	func blob(centre: Vector3, radii: Vector3, col: Color, glow: float = 0.0, lat: int = 4, lon: int = 7,
			basis: Basis = Basis(), shade_under: float = 0.2, top_only: bool = false) -> void:
		var i0 := lat / 2 if top_only else 0
		for i in range(i0, lat):
			var t0 := PI * float(i) / float(lat) - PI * 0.5
			var t1 := PI * float(i + 1) / float(lat) - PI * 0.5
			for j in lon:
				var p0 := TAU * float(j) / float(lon)
				var p1 := TAU * float(j + 1) / float(lon)
				var q := func(t: float, p: float) -> Vector3:
					return centre + basis * Vector3(cos(t) * cos(p) * radii.x, sin(t) * radii.y, cos(t) * sin(p) * radii.z)
				var k := float(i) / float(maxi(lat - 1, 1))
				var cc := col.darkened(shade_under * (1.0 - k))
				var a: Vector3 = q.call(t0, p0)
				var b: Vector3 = q.call(t1, p0)
				var d: Vector3 = q.call(t1, p1)
				var e: Vector3 = q.call(t0, p1)
				if i == 0:
					tri(a, b, d, cc, glow)
				elif i == lat - 1:
					tri(a, b, e, cc, glow)
				else:
					quad(a, b, d, e, cc, glow)

	## An axis-aligned box (centre, size) in the kit's space.
	func box(ce: Vector3, sz: Vector3, col: Color, glow: float = 0.0) -> void:
		var h := sz * 0.5
		var p := func(x: float, y: float, z: float) -> Vector3:
			return ce + Vector3(x * h.x, y * h.y, z * h.z)
		quad(p.call(-1, 1, -1), p.call(1, 1, -1), p.call(1, 1, 1), p.call(-1, 1, 1), col, glow)
		quad(p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, -1, -1), col.darkened(0.15), glow)
		quad(p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(-1, 1, -1), col.darkened(0.04), glow)
		quad(p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, -1, 1), col.darkened(0.08), glow)
		quad(p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(-1, 1, 1), p.call(-1, -1, 1), col.darkened(0.1), glow)
		quad(p.call(1, -1, -1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(1, 1, -1), col.darkened(0.06), glow)

	func mesh(cols: PackedColorArray = PackedColorArray()) -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = cols if cols.size() == v.size() else c
		var m := ArrayMesh.new()
		if v.size() > 0:
			m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return m


func _mi(parent: Node3D, kit: Kit, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = kit.mesh(_cave_lit(parent, kit))
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## CAVE4: a kit's colours lit by the cave's baked light where it stands (`_light`, the stone's own), each
## facet at its centre, mixed back toward its own colour by its glow. The kit is left as it is.
func _cave_lit(parent: Node3D, kit: Kit) -> PackedColorArray:
	var xf := Transform3D()
	var nd: Node = parent
	while nd != null and nd != cave:
		if nd is Node3D:
			xf = (nd as Node3D).transform * xf
		nd = nd.get_parent()
	if nd != cave:
		return kit.c
	var out := kit.c.duplicate()
	var has_g := kit.g.size() == kit.c.size()
	for i in range(0, kit.v.size() - 2, 3):
		var gl := kit.g[i] if has_g else 0.0
		if gl >= 0.999:
			continue
		var q := _unwarp(xf * ((kit.v[i] + kit.v[i + 1] + kit.v[i + 2]) / 3.0))
		if gl < 0.0:
			# a contact shadow: the textured floor's light there, darkened
			var sc := _light(q, _lit(C_FLOOR, _floor_tex_mean()), CAVE_AMB * PATH_LIFT).darkened(-gl)
			for j in 3:
				out[i + j] = sc
			continue
		for j in 3:
			var own := kit.c[i + j]
			out[i + j] = _light(q, own, KIT_AMB).lerp(own, gl)
	return out


## A kit built in cave-local UNWARPED metres (the chamber's and the loft's crystals), bent onto the gravity
## shells vertex by vertex (`W`) like the stone. CAVE3: they were drawn in the unwarped frame at the
## origin, so everything far from it stood above its warped floor by ~d^2 / 2R (about 3 m in the
## chamber): spires floating over the floor, a stalactite standing on it - hidden in the all-white cave,
## plain once the floor and wall read apart.
func _mi_warped(kit: Kit, nm: String) -> MeshInstance3D:
	for i in kit.v.size():
		kit.v[i] = W(kit.v[i])
	return _mi(cave, kit, nm)


func _node(nm: String, xf: Transform3D, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	(parent if parent != null else cave).add_child(n)
	n.transform = xf
	return n


## CAVE4 (9.6 item 8, the user: crystals on "a smooth flat pedestal ... pop up straight from the ground
## instead of at angles", so they look like trophies): a cluster GROWS out of the rock. The whole group
## leans one way (`lean` rad about a random axis), every crystal splays out from the shared root at its
## own angle (the tallest too), each is sunk into the rock by as much as its tilt lifts its base's edge,
## and `rock` scatters broken stone round the root instead of a smooth slab and a shadow disc.
func _cluster(kit: Kit, rng: RandomNumberGenerator, count: int, hmin: float, hmax: float, spread: float,
		col: Color, glow: float, rock: bool = true, lean: float = 0.22) -> void:
	var laz := rng.randf_range(0.0, TAU)
	var lb := Basis(Vector3(-sin(laz), 0.0, cos(laz)), lean)
	for k in count:
		var h := rng.randf_range(hmin, hmax) * (1.0 if k > 0 else 1.2)
		var az := rng.randf_range(0.0, TAU)
		var off := Vector3(cos(az), 0.0, sin(az)) * spread * (rng.randf_range(0.0, 0.2) if k == 0 else rng.randf_range(0.35, 1.0))
		var tilt := rng.randf_range(0.1, 0.25) if k == 0 else rng.randf_range(0.35, 0.8)
		var b := lb * Basis(Vector3(-sin(az), 0.0, cos(az)), -tilt)   # splays OUT from the root
		var r := h * rng.randf_range(0.17, 0.24)
		var c := col.lerp(col.lightened(0.3), rng.randf())
		var sink := 0.05 + r * sin(minf(tilt + lean, 1.2))
		kit.gem(Transform3D(b, lb * off - Vector3(0, sink, 0)), r, h, c, glow)
	if rock:
		_rubble(kit, rng, spread + 0.15, 6)


## Broken stone round a crystal root (kit space, y = 0 the floor): low faceted chunks of the cave's own
## rock, each turned and half sunk - never one smooth slab.
func _rubble(kit: Kit, rng: RandomNumberGenerator, spread: float, count: int) -> void:
	for i in count:
		var a := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / float(count)
		var d := spread * rng.randf_range(0.45, 1.0)
		var r := rng.randf_range(0.08, 0.17) * clampf(spread / 0.5, 0.7, 1.6)
		var col := C_WALL.lerp(C_FLOOR, rng.randf()).darkened(rng.randf_range(0.05, 0.22))
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.4, 0.4))
		kit.blob(Vector3(cos(a) * d, r * 0.2, sin(a) * d), Vector3(r * rng.randf_range(1.0, 1.5), r * rng.randf_range(0.55, 0.9), r),
			col, 0.0, 2, 5, b, 0.25)


func _body_cyl(parent: Node3D, r: float, h: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 3
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = h
	cs.shape = cyl
	cs.position = Vector3(0, h * 0.5, 0)
	body.add_child(cs)
	parent.add_child(body)


## A soft contact shadow on the floor (kit space, y = 0 is the floor): two rings, darker inside. Without
## it anything standing on white stone looks like it floats.
## CAVE4: its facets carry g = -darkness (`Kit.shade`), and `_cave_lit` makes each the floor's own light
## there (C_FLOOR x the floor texture's mean, `_floor_tex_mean`) darkened by that - lit on its own, the
## disc read as a pale plate on the darker floor.
func _shadow(kit: Kit, ce: Vector3, rx: float, rz: float, dark: float = 0.22) -> void:
	var inner := C_FLOOR.darkened(dark)
	var outer := C_FLOOR.darkened(dark * 0.45)
	var n := 12
	for j in n:
		var a0 := TAU * float(j) / float(n)
		var a1 := TAU * float(j + 1) / float(n)
		var i0 := ce + Vector3(cos(a0) * rx * 0.75, 0.012, sin(a0) * rz * 0.75)
		var i1 := ce + Vector3(cos(a1) * rx * 0.75, 0.012, sin(a1) * rz * 0.75)
		var o0 := ce + Vector3(cos(a0) * rx * 1.15, 0.01, sin(a0) * rz * 1.15)
		var o1 := ce + Vector3(cos(a1) * rx * 1.15, 0.01, sin(a1) * rz * 1.15)
		kit.shade = dark
		kit.tri(ce + Vector3(0, 0.013, 0), i0, i1, inner, 1.0)
		kit.shade = dark * 0.45
		kit.quad(i0, o0, o1, i1, outer, 1.0)
		kit.shade = 0.0


static var _ftm := -1.0

## The floor texture's mean in linear light (a shadow's colour, `_shadow`), measured off its image once.
static func _floor_tex_mean() -> float:
	if _ftm < 0.0:
		var img := CaveRockTex.floor_tex().get_image().duplicate() as Image
		if img.is_compressed():
			img.decompress()
		var sum := 0.0
		var n := 0
		for y in range(0, img.get_height(), 4):
			for x in range(0, img.get_width(), 4):
				var c := img.get_pixel(x, y).srgb_to_linear()
				sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
				n += 1
		_ftm = clampf(sum / maxf(float(n), 1.0), 0.2, 1.0)
	return _ftm


# ============================================================================== PLANNING THE TINTS
## Where the crystals will stand, decided before the stone is baked so their pastel light is in it.
var _plan: Dictionary = {}

func _plan_tints() -> void:
	var gc := _floor_spot(trunk, 4.6, -0.78)
	_plan["glow_crystals"] = gc
	_tint((gc["q"] as Vector3) + Vector3.UP * 0.6, C_AQUA, 4.5, 0.55)
	var sky := trunk.at(0.9)
	_tint((sky["p"] as Vector3) + Vector3.UP * 4.0, Color("#cfe0f2"), 3.5, 0.6)
	var mo := _floor_spot(trunk, MOTH_S, 0.62)
	_plan["moth"] = mo
	_tint((mo["q"] as Vector3) + Vector3.UP * 0.5, C_LILAC, 3.5, 0.5)
	# the chamber
	var a := trunk.at(trunk.s_of(_mk["trunk:chamber"]))
	_chamber_c = a["p"]
	_chamber_t = a["t"]
	_chamber_side = a["side"]
	_pool_centre = _chamber_c - _chamber_side * 5.2 - _chamber_t * 1.0
	_tint(_pool_centre + Vector3.UP * 0.4, C_AQUA, 5.5, 0.5)
	_tint(_chamber_c + _chamber_side * 6.0 + _chamber_t * 1.5 + Vector3.UP * 1.0, C_LILAC, 6.0, 0.3)
	_tint(_chamber_c + _chamber_t * 3.5 + Vector3.UP * 0.8, C_AMBER, 4.5, 0.25)
	# T1CAVE: one light at the foot of each glowing spire (`_build_chamber`, same angles and radii; the
	# spire stands within its +-0.6 m jitter of it), in the spire's own colour.
	for k in 9:
		var ang := TAU * float(k) / 9.0 + 0.3
		if absf(sin(ang)) > 0.85 and sin(ang) < 0.0:
			continue
		var pp := _chamber_c + (_chamber_side * cos(ang) * 7.0 + _chamber_t * sin(ang) * 5.6)
		_tint(pp + Vector3.UP * 1.0, _spire_colour(k).lightened(0.3), 4.0, 1.0)
	# the grotto's end: the beetle's perch
	_tint(grotto.pts[grotto.pts.size() - 8] + Vector3.UP * 0.6, rb(0.8, 0.3, 0.97), 3.0, 0.4)
	# the chest room: a warm glow round the chest
	var ch := upway.at(upway.total - 2.3)
	_chest_local = ch["p"]
	_tint(_chest_local + Vector3.UP * 0.6, Color("#f3dca6"), 3.2, 0.5)
	# the jelly loft: a cool aqua and lilac wash up its tall walls
	var lf := loft.at(loft.s_of(_mk["loft:loft"]))
	_loft_c = lf["p"]
	_loft_t = lf["t"]
	_tint(_loft_c + Vector3.UP * 5.0, C_AQUA, 5.0, 0.4)
	_tint(_loft_c + (lf["side"] as Vector3) * 3.0 + Vector3.UP * 2.0, C_LILAC, 4.0, 0.4)
	_tint(_loft_c - (lf["side"] as Vector3) * 3.0 + Vector3.UP * 2.5, rb(0.9, 0.3, 0.97), 4.0, 0.35)
	# FORK 1's two mouths (C4): each way wears the colour its route already carries - the up road the
	# chest way's gold (its floor flecks, the chest's warmth), the down way the aqua of the wall crystals
	# that follow it to the chamber. A small crystal cluster stands at each mouth's near lip, where the
	# approach looks, and its glow washes the rock round it and a little way inside, so the opening
	# reads as a lit way on instead of white stone against white stone.
	var s1 := trunk.s_of(_mk["trunk:fork1"])
	var lip := s1 - 4.0
	while lip < s1 + 10.0 and not upway.inside(_wall_point(trunk, lip + 0.25, 1.0, 1.0), 1.0):
		lip += 0.25
	var up_m := _floor_spot(trunk, lip - 0.6, 0.72)
	var up_in := upway.at(_tube_mouth_s(upway, trunk) + 2.5)
	var down_m := _floor_spot(trunk, lip + 1.0, -0.72)
	_plan["mouth_up"] = up_m
	_plan["mouth_down"] = down_m
	_tint((up_m["q"] as Vector3) + Vector3.UP * 0.7, C_GOLD, 3.2, 0.8)
	_tint((up_in["p"] as Vector3) + Vector3.UP * 1.4, Color("#f3dca6"), 3.4, 0.5)
	_tint((down_m["q"] as Vector3) + Vector3.UP * 0.7, C_DOWN_LIGHT, 3.2, 0.8)
	# FORK 3: a faint gold warmth on the chest's side, a faint aqua on the loft's
	_tint(upway.pts[upway.idx_at(upway.s_of(_mk["upway:fork3"]) + 5.0)] + Vector3.UP * 1.2, Color("#f3dca6"), 2.6, 0.3)
	_tint(loft.pts[loft.idx_at(5.0)] + Vector3.UP * 1.2, C_AQUA, 2.6, 0.3)


# ============================================================================== THE LANDING
func _build_landing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# Where you came in: a pale patch of daylight in the roof above the start.
	var a := trunk.at(0.9)
	var k := Kit.new()
	for j in 9:
		var a0 := TAU * float(j) / 9.0
		var a1 := TAU * float(j + 1) / 9.0
		k.tri(Vector3.ZERO, Vector3(cos(a0) * 0.9, 0, sin(a0) * 0.9), Vector3(cos(a1) * 0.9, 0, sin(a1) * 0.9), Color("#bcd3ee"), 1.0)
	var roof_y := float(a["h"]) + 0.2
	_mi(_node("WayOut", X((a["p"] as Vector3) + Vector3.UP * roof_y, a["t"])), k, "Mesh")
	# THE GLOW CRYSTALS: the first thing you see, on the left of the landing.
	var f: Dictionary = _plan["glow_crystals"]
	var kc := Kit.new()
	_cluster(kc, rng, 8, 0.45, 1.05, 0.55, C_AQUA, 0.55)
	var n := _node("GlowCrystals", X(f["q"], f["t"]))
	_halos.append([(f["q"] as Vector3) + Vector3.UP * 0.55, 1.1, C_AQUA])
	_mi(n, kc, "Mesh")
	_body_cyl(n, 0.6, 1.2)
	safari.add_subject({"id": "glow_crystals", "name": "Glow crystals", "tier": "sight", "node": n,
		"offset": Vector3(0, 0.55, 0), "radius": 0.85, "band": Vector2(0.25, 0.75), "kind": "sight"})


# ============================================================================== WALL CRYSTALS
## CAVE3 (9.5 item 5, "lots of crystals (like a teal color and occasional rainbow ones) light up the cave a
## lot so it's not scary"): glowing clusters on alternate walls every ~3 m of EVERY hall, most teal, one in
## seven rainbow, some low at the foot of the wall and some higher. Planned before the stone is baked so
## their light is in it; never in a branch's mouth (a wall point inside another tube), never on top of a
## subject. All in ONE mesh (one draw).
var _crystals: Array = []


## Path spots taken by subjects, [tube, s, side (0 = either)], that the wall crystals keep clear of.
func _taken_spots() -> Array:
	var out := [[trunk, 4.6, -1.0], [trunk, MOTH_S, 1.0], [trunk, trunk.s_of(_mk["trunk:slope"]), -1.0],
		[upway, upway.s_of(_mk["upway:newt"]) - 10.0, 1.0], [upway, upway.s_of(_mk["upway:fossil"]) + 0.5, -1.0],
		[upway, upway.total - 2.3, 0.0], [grotto, grotto.total - 2.6, 0.0], [loft, loft.s_of(_mk["loft:loft"]), 0.0]]
	for d: Array in _new_defs():
		out.append([_tube(str(d[1])), float(d[2]), float(d[3])])
	return out


func _tube(id: String) -> Tube:
	for t: Tube in _tubes:
		if t.id == id:
			return t
	return trunk


func _plan_crystals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	var taken := _taken_spots()
	var n := 0
	for t: Tube in _tubes:
		var s := 2.4
		var side := -1.0
		while s < t.total - 1.2:
			var y := rng.randf_range(0.05, 1.5) if rng.randf() < 0.7 else rng.randf_range(0.05, 0.3)
			var p := _wall_point(t, s, side, y)
			var ok := true
			for o: Tube in _tubes:
				if o != t and o.inside(p + Vector3.UP * 0.2, 1.12):
					ok = false
			for tk: Array in taken:
				if tk[0] == t and absf(float(tk[1]) - s) < 2.4 and (float(tk[2]) == 0.0 or float(tk[2]) == side):
					ok = false
			if ok:
				var rainbow := n % 7 == 4
				var a := t.at(s)
				var inward := -(a["side"] as Vector3) * side
				var hue := rng.randf()
				_crystals.append({"t": t, "s": s, "side": side, "y": y, "p": p, "rainbow": rainbow, "hue": hue,
					"big": y < 0.35})
				# two lights: a broad pale one that brightens the brown (teal light on brown alone reads
				# olive), and a tight glow of the crystal's own colour on the rock right round it
				var lp := p + inward * 0.35 + Vector3.UP * 0.3
				_tint(lp, C_CRYSTAL_WASH, 4.6 if y < 0.35 else 4.2, WASH_K, 0.25)
				_tint(lp, rb(hue, 0.6, 1.0) if rainbow else C_TEAL, 2.4, 0.9, 1.8)
				n += 1
			side = -side
			s += rng.randf_range(2.4, 3.4)


## U1CAVE (9.29, the user: the tunnel "looks too smooth it needs more uneven texture"): broken rock
## fallen along the foot of every wall - one to three faceted chunks every ~1 m on each side, low and
## close to the wall so the walked middle stays clear, never in a branch's mouth or on a subject's spot.
## The stone's own rock texture and light (`_wall_mat`, `_light` with the facet's normal), so a chunk is
## the same rock as the wall it fell from; the ones in a dark stretch are dark. ONE mesh, one draw, no
## collision (the chunks are ankle-high and sit where the wall already stops your feet).
func _build_rubble() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	var taken := _taken_spots()
	var k := Kit.new()
	var cols := PackedColorArray()
	var L := LIGHT.normalized()
	for t: Tube in _tubes:
		for sgn: float in [-1.0, 1.0]:
			var s := rng.randf_range(0.4, 1.2)
			while s < t.total - 1.2:
				var s0 := s
				s += rng.randf_range(0.7, 1.4)
				if (s0 < 1.2 and not t.open_start) or rng.randf() < 0.22:
					continue
				var a := t.at(s0)
				var i := int(a["i"])
				var ctr: Vector3 = a["p"]
				var side: Vector3 = a["side"]
				var fw := t.wall_x(i, 0.0)
				var ok := true
				for tk: Array in taken:
					if tk[0] == t and absf(float(tk[1]) - s0) < 1.6 and (float(tk[2]) == 0.0 or float(tk[2]) == sgn):
						ok = false
				var q := ctr + side * sgn * fw * rng.randf_range(0.8, 0.95)
				for o: Tube in _tubes:
					if o != t and o.inside(q + Vector3.UP * 0.3, 1.08):
						ok = false
				if not ok:
					continue
				for c in rng.randi_range(1, 3):
					var r := rng.randf_range(0.09, 0.24) * (1.0 + 0.6 * t.rk[i])
					var ce := q + (a["t"] as Vector3) * rng.randf_range(-0.45, 0.45) - side * sgn * rng.randf_range(0.0, 0.3)
					var lat := (ce - ctr).dot(side)
					var fo := _floor_off(Vector3(ce.x, ctr.y, ce.z), absf(lat) / maxf(fw, 0.05))
					ce.y = ctr.y + fo.x + fo.y + r * 0.12
					var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.5, 0.5))
					var col := C_WALL.lerp(C_FLOOR, rng.randf()).lerp(C_PEARL[rng.randi() % 4], rng.randf() * 0.4)
					var v0 := k.v.size()
					k.blob(ce, Vector3(r * rng.randf_range(1.0, 1.6), r * rng.randf_range(0.5, 0.85), r), col, 0.0, 3, 5, b, 0.0)
					for vi in range(v0, k.v.size(), 3):
						var cen := (k.v[vi] + k.v[vi + 1] + k.v[vi + 2]) / 3.0
						var nn := k.n[vi] if k.n[vi].dot(cen - ce) >= 0.0 else -k.n[vi]
						var dif := 0.5 + 0.5 * nn.dot(L)
						var fk := (FORM_AMB + 2.0 * dif) / (FORM_AMB + 2.0) * lerpf(0.55, 1.0, smoothstep(-0.4, 0.3, nn.y))
						var lc := _light(cen, col, CAVE_AMB * fk, nn)
						cols.append_array([lc, lc, lc])
	for vi in k.v.size():
		k.v[vi] = W(k.v[vi])
	var mi := MeshInstance3D.new()
	mi.name = "Rubble"
	mi.mesh = k.mesh(cols)
	mi.material_override = _wall_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cave.add_child(mi)


func _merge(dst: Kit, src: Kit, xf: Transform3D) -> void:
	for i in src.v.size():
		dst.v.append(xf * src.v[i])
		dst.n.append((xf.basis * src.n[i]).normalized())
		dst.c.append(src.c[i])
		dst.g.append(src.g[i] if i < src.g.size() else 0.0)


func _build_wall_crystals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var all := Kit.new()
	for c: Dictionary in _crystals:
		var t: Tube = c["t"]
		var side: float = c["side"]
		var a := t.at(float(c["s"]))
		var p: Vector3 = (c["p"] as Vector3) - (a["side"] as Vector3) * side * 0.08
		var k := Kit.new()
		if bool(c["rainbow"]):
			k.iri = float(c["hue"])
			k.iri_span = 0.9
			k.iri_s = 0.5
		var big := bool(c["big"])
		_cluster(k, rng, rng.randi_range(4, 7) if big else rng.randi_range(3, 5), 0.3 if big else 0.2,
			0.95 if big else 0.55, 0.34 if big else 0.24, C_TEAL, 0.7, false)
		var inward := -(a["side"] as Vector3) * side
		var xf := X(p, a["t"])
		var tilt_axis := xf.basis.y.cross(inward)
		if tilt_axis.length_squared() > 1e-4:
			xf.basis = Basis(tilt_axis.normalized(), 0.3 if big else 0.6) * xf.basis
		xf.origin = W(p)
		_merge(all, k, xf)
		_halos.append([p + inward * 0.3 + Vector3.UP * (0.35 if big else 0.25), 0.95 if big else 0.7,
			rb(float(c["hue"]), 0.6, 1.0) if bool(c["rainbow"]) else C_TEAL])
	_mi(cave, all, "WallCrystals")


# ============================================================================== SOFT GLOW
## T1CAVE (the user, 9.29: "darken the cave"; before: "so that the glow from the crystals pops much more").
## With the rock dark, a crystal is the light, and a light has a soft glow in the air round it: one faint
## ADDITIVE camera-facing disc per wall crystal cluster, chamber spire and the landing's glow crystals,
## [cave-local unwarped centre, radius m, colour]. All in ONE MultiMesh (one draw), a StandardMaterial3D
## (unshaded, additive, billboard) - no custom shader, so the phone draws what the desktop draws. Depth-
## tested, so rock in front hides it; its centre sits off the wall so the wall cuts it only where it is faint.
var _halos: Array = []
const HALO_ALPHA := 0.6


func _build_halos() -> void:
	if _halos.is_empty():
		return
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	q.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = q
	mm.instance_count = _halos.size()
	for i in _halos.size():
		var h: Array = _halos[i]
		var r := float(h[1])
		var c: Color = h[2]
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(r, r, r)), W(h[0] as Vector3)))
		mm.set_instance_color(i, Color(c.r, c.g, c.b, HALO_ALPHA))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "CrystalGlow"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cave.add_child(mmi)


# ============================================================================== THE PRISM MOTH
## A pearly moth with rainbow fan wings. Returns its two wing hinges.
func _moth_mesh(parent: Node3D, hue0: float) -> Array[Node3D]:
	var body := Kit.new()
	body.blob(Vector3(0, 0, 0.02), Vector3(0.05, 0.048, 0.075), Color("#f4f0f8"), 0.0, 3, 6)
	body.blob(Vector3(0, -0.004, 0.11), Vector3(0.04, 0.036, 0.07), rb(hue0 + 0.55), 0.2, 3, 6)
	body.blob(Vector3(0, 0.012, -0.075), Vector3(0.058, 0.055, 0.055), Color("#f7f4fb"), 0.0, 3, 6)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		body.blob(Vector3(0.026 * s, 0.027, -0.118), Vector3(0.014, 0.016, 0.01), C_EYE, 0.0, 2, 5)
		body.blob(Vector3(0.022 * s, 0.033, -0.124), Vector3(0.004, 0.004, 0.003), Color.WHITE, 1.0, 2, 4)
		# feathery antennae with a rainbow bead
		body.quad(Vector3(0.012 * s, 0.05, -0.1), Vector3(0.016 * s, 0.05, -0.1), Vector3(0.06 * s, 0.13, -0.16),
			Vector3(0.056 * s, 0.13, -0.16), Color("#d9d2e6"))
		body.blob(Vector3(0.058 * s, 0.132, -0.16), Vector3(0.012, 0.012, 0.012), rb(hue0 + 0.3), 0.5, 2, 5)
	_mi(parent, body, "Body")
	var wings: Array[Node3D] = []
	for sgn in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "Wing"
		parent.add_child(hinge)
		var wk := Kit.new()
		var s := float(sgn)
		var root := Vector3(0.01 * s, 0.0, -0.01)
		var rim := [Vector3(0.1 * s, 0, -0.16), Vector3(0.24 * s, 0, -0.15), Vector3(0.31 * s, 0, -0.04),
			Vector3(0.28 * s, 0, 0.08), Vector3(0.17 * s, 0, 0.16), Vector3(0.05 * s, 0, 0.12)]
		for q in rim.size() - 1:
			wk.tri(root, rim[q], rim[q + 1], rb(hue0 + 0.15 * float(q)), 0.25)
		# a pearl eye-spot on each wing
		var sp := Vector3(0.19 * s, 0.002, -0.02)
		for q in 5:
			var a0 := TAU * float(q) / 5.0
			var a1 := TAU * float(q + 1) / 5.0
			wk.tri(sp, sp + Vector3(cos(a0) * 0.035, 0, sin(a0) * 0.035), sp + Vector3(cos(a1) * 0.035, 0, sin(a1) * 0.035),
				Color("#fbf8ff"), 0.6)
		_mi(hinge, wk, "Mesh")
		wings.append(hinge)
	return wings


func _build_moth() -> void:
	var f: Dictionary = _plan["moth"]
	_moth_perch = (f["q"] as Vector3) + Vector3.UP * 1.05
	_moth_centre = (f["p"] as Vector3) + Vector3.UP * 1.6
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var k := Kit.new()
	_cluster(k, rng, 4, 0.35, 0.7, 0.3, C_LILAC, 0.55)
	var perch := _node("MothPerch", X(f["q"], f["t"]))
	_mi(perch, k, "Mesh")
	_body_cyl(perch, 0.35, 0.9)
	_moth = _node("PrismMoth", X(_moth_centre))
	_moth_wings = _moth_mesh(_moth, 0.0)
	safari.add_subject({"id": "prism_moth", "name": "Prism moth", "tier": "creature", "kind": "creature",
		"node": _moth, "radius": 0.3, "band": Vector2(0.12, 0.45),
		"front": SafariWorld.front_of(_moth, Vector3(0, 0, -1)), "moment": _moth_moment})


func _moth_resting(t: float) -> bool:
	return fmod(t, MOTH_CYCLE) >= 6.0


func _tick_moth(t: float) -> void:
	var c := fmod(t, MOTH_CYCLE)
	var p: Vector3
	var fwd: Vector3
	var flap := 0.0
	if c < 6.0:
		var a := c / 6.0 * TAU
		p = _moth_centre + Vector3(sin(a) * 1.3, 0.35 * sin(a * 2.0), sin(a * 2.0) * 0.8)
		var a2 := a + 0.05
		fwd = (_moth_centre + Vector3(sin(a2) * 1.3, 0.35 * sin(a2 * 2.0), sin(a2 * 2.0) * 0.8)) - p
		p = p.lerp(_moth_perch, maxf(smoothstep(5.2, 6.0, c), 1.0 - smoothstep(0.0, 0.8, c)))
		flap = sin(t * 26.0) * 0.9
	else:
		p = _moth_perch + Vector3.UP * 0.02 * sin(t * 3.0)
		fwd = _moth_centre - _moth_perch
		fwd.y = 0.0
		flap = -0.35 + 0.08 * sin(t * 2.0)
	_moth.transform = X(p, fwd if fwd.length_squared() > 1e-5 else Vector3.FORWARD, 1.2)
	if _moth_wings.size() == 2:
		_moth_wings[0].rotation = Vector3(0, 0, -flap)
		_moth_wings[1].rotation = Vector3(0, 0, flap)


# ============================================================================== THE OPAL SNAIL (the hall)
func _build_snail() -> void:
	var s_hall := trunk.s_of(_mk["trunk:slope"])
	var s0 := _floor_spot(trunk, s_hall - 2.5, -0.4)
	var s1 := _floor_spot(trunk, s_hall + 2.8, -0.5)
	_snail_a = s0["q"]
	_snail_b = s1["q"]
	_snail = _node("OpalSnail", X(_snail_a, _snail_b - _snail_a, 1.4))
	var sk := Kit.new()
	var skin := Color("#f3ece6")
	_shadow(sk, Vector3(0, 0, 0.02), 0.12, 0.24, 0.2)
	sk.blob(Vector3(0, 0.035, 0.0), Vector3(0.07, 0.04, 0.2), skin, 0.0, 3, 7)
	sk.blob(Vector3(0, 0.075, -0.16), Vector3(0.06, 0.055, 0.055), skin.lightened(0.2), 0.0, 3, 6)
	# the opal shell: a spiral of rainbow whorls, each its own iridescent band
	# a big faceted whorl, then two smaller ones curling up out of it to a tip
	sk.iri = 0.55
	sk.iri_span = 0.8
	sk.blob(Vector3(0, 0.13, 0.05), Vector3(0.11, 0.11, 0.13), Color.WHITE, 0.25, 5, 8)
	sk.iri = 0.8
	sk.blob(Vector3(0.03, 0.2, 0.07), Vector3(0.07, 0.065, 0.075), Color.WHITE, 0.25, 4, 7)
	sk.iri = 0.05
	sk.blob(Vector3(0.045, 0.245, 0.08), Vector3(0.035, 0.035, 0.035), Color.WHITE, 0.3, 3, 6)
	sk.iri = -1.0
	for sx in [-1.0, 1.0]:
		sk.blob(Vector3(0.028 * float(sx), 0.06, -0.205), Vector3(0.012, 0.01, 0.006), Color("#f2b6c4"), 0.0, 2, 5)
	_mi(_snail, sk, "Body")
	for sgn in [-1.0, 1.0]:
		var stalk := _node("Stalk", Transform3D(Basis(), Vector3(0.025 * float(sgn), 0.1, -0.18)), _snail)
		var tk := Kit.new()
		tk.blob(Vector3(0, 0.04, 0), Vector3(0.009, 0.045, 0.009), skin, 0.0, 2, 5)
		_mi(stalk, tk, "Mesh")
		var eye := _node("Eye", Transform3D(Basis(), Vector3(0, 0.09, 0)), stalk)
		var ek := Kit.new()
		ek.blob(Vector3.ZERO, Vector3(0.02, 0.02, 0.02), C_EYE, 0.0, 3, 6)
		ek.blob(Vector3(0.006, 0.008, -0.016), Vector3(0.006, 0.006, 0.004), Color.WHITE, 1.0, 2, 5)
		_mi(eye, ek, "Mesh")
		_snail_stalks.append(stalk)
	safari.add_subject({"id": "opal_snail", "name": "Opal snail", "tier": "creature", "kind": "creature",
		"node": _snail, "offset": Vector3(0, 0.12, 0), "radius": 0.3, "band": Vector2(0.15, 0.5),
		"front": SafariWorld.front_of(_snail, Vector3(0, 0, -1)), "moment": _snail_moment})


func _snail_stretch(t: float) -> float:
	var c := fmod(t, 12.0)
	return smoothstep(8.0, 8.8, c) * (1.0 - smoothstep(10.6, 11.4, c))


func _tick_snail(t: float) -> void:
	var d := _snail_a.distance_to(_snail_b)
	var st := _snail_stretch(t)
	var along := fmod(t * 0.09, d * 2.0)
	var fwd := _snail_b - _snail_a
	var u := along / d
	if along > d:
		u = 2.0 - u
		fwd = -fwd
	_snail.transform = X(_snail_a.lerp(_snail_b, u), fwd, 1.4)
	for i in _snail_stalks.size():
		var sy := 1.0 + 0.9 * st
		_snail_stalks[i].scale = Vector3(1.0, sy, 1.0)
		_snail_stalks[i].rotation = Vector3(-0.3 * st + 0.08 * sin(t * 2.0 + float(i)), 0, 0)
		var eye := _snail_stalks[i].get_node("Eye") as Node3D
		eye.scale = Vector3(1.0, 1.0 / sy, 1.0)


# ============================================================================== THE GROTTO: RAINBOW BEETLE
func _build_grotto() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	# the perch near the end: a low pastel crystal stump
	var f := _floor_spot(grotto, grotto.total - 2.6, 0.0)
	var perch := _node("BeetlePerch", X(f["q"], f["t"]))
	var pk := Kit.new()
	_cluster(pk, rng, 5, 0.3, 0.55, 0.35, C_LILAC.lerp(C_AQUA, 0.4), 0.5)
	pk.blob(Vector3(0, 0.3, 0), Vector3(0.3, 0.3, 0.3), C_WALL.darkened(0.05), 0.0, 3, 7)
	_mi(perch, pk, "Mesh")
	_body_cyl(perch, 0.45, 0.6)
	_beetle_rest = (f["q"] as Vector3) + Vector3.UP * 0.6
	_beetle = _node("RainbowBeetle", X(_beetle_rest, -(f["t"] as Vector3), 1.3))
	var bk := Kit.new()
	var shell_dk := Color("#3d3552")
	bk.blob(Vector3(0, 0.05, 0.01), Vector3(0.075, 0.045, 0.1), shell_dk, 0.0, 3, 7)
	bk.blob(Vector3(0, 0.055, -0.1), Vector3(0.045, 0.038, 0.035), shell_dk.lightened(0.08), 0.0, 3, 6)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		bk.blob(Vector3(0.024 * s, 0.07, -0.128), Vector3(0.013, 0.013, 0.008), Color("#f7f4ff"), 0.9, 2, 5)
		bk.blob(Vector3(0.024 * s, 0.071, -0.134), Vector3(0.007, 0.008, 0.004), C_EYE, 0.0, 2, 4)
		bk.quad(Vector3(0.018 * s, 0.08, -0.12), Vector3(0.022 * s, 0.08, -0.12), Vector3(0.06 * s, 0.15, -0.19),
			Vector3(0.056 * s, 0.15, -0.19), shell_dk)
		bk.blob(Vector3(0.058 * s, 0.152, -0.19), Vector3(0.011, 0.011, 0.011), rb(0.12), 0.6, 2, 5)
		for lg in 3:
			var z := -0.05 + 0.05 * float(lg)
			bk.quad(Vector3(0.05 * s, 0.03, z), Vector3(0.05 * s, 0.03, z + 0.012), Vector3(0.11 * s, -0.005, z + 0.02),
				Vector3(0.11 * s, -0.005, z + 0.008), shell_dk.darkened(0.2))
	_mi(_beetle, bk, "Body")
	# the two wing cases: iridescent domes on hinges, and the rainbow wings under them
	for sgn in [-1.0, 1.0]:
		var s := float(sgn)
		var hinge := _node("Case", Transform3D(Basis(), Vector3(0.005 * s, 0.075, -0.06)), _beetle)
		var ck := Kit.new()
		ck.iri = 0.72 if s < 0.0 else 0.3
		ck.iri_span = 0.9
		ck.iri_s = 0.62
		ck.blob(Vector3(0.042 * s, 0.0, 0.075), Vector3(0.048, 0.045, 0.1), Color.WHITE, 0.25, 4, 7, Basis(), 0.1, true)
		_mi(hinge, ck, "Mesh")
		_beetle_shells.append(hinge)
	_beetle_wings = _node("Wings", Transform3D(Basis(), Vector3(0, 0.1, -0.03)), _beetle)
	var wk := Kit.new()
	for sgn in [-1.0, 1.0]:
		var s := float(sgn)
		for q in 4:
			var a0 := -0.3 + 0.25 * float(q)
			var a1 := a0 + 0.25
			wk.tri(Vector3.ZERO, Vector3(sin(a0) * 0.2 * s, 0.02, cos(a0) * 0.2),
				Vector3(sin(a1) * 0.2 * s, 0.02, cos(a1) * 0.2), rb(0.55 + 0.12 * float(q), 0.45, 0.98), 0.6)
	_mi(_beetle_wings, wk, "Mesh")
	_beetle_wings.visible = false
	safari.add_subject({"id": "rainbow_beetle", "name": "Rainbow beetle", "tier": "rare", "kind": "rare",
		"node": _beetle, "offset": Vector3(0, 0.06, 0), "radius": 0.2, "band": Vector2(0.1, 0.4),
		"front": SafariWorld.front_of(_beetle, Vector3(0, 0, -1)), "moment": _beetle_moment})


func _beetle_open(t: float) -> float:
	var c := fmod(t, BEETLE_CYCLE)
	return smoothstep(5.5, 6.2, c) * (1.0 - smoothstep(8.8, 9.5, c))


func _tick_beetle(t: float) -> void:
	var o := _beetle_open(t)
	for i in _beetle_shells.size():
		var s := -1.0 if i == 0 else 1.0
		_beetle_shells[i].rotation = Vector3(-0.35 * o, 0, -0.9 * o * s)
	_beetle_wings.visible = o > 0.3
	_beetle_wings.rotation = Vector3(0, 0, 0.3 * sin(t * 30.0) * o)
	var lift := 0.16 * o + 0.01 * sin(t * 2.0)
	var yaw := 0.4 * sin(t * 0.5)
	var f := _floor_spot(grotto, grotto.total - 2.6, 0.0)
	var face := -(f["t"] as Vector3).rotated(Vector3.UP, yaw)
	_beetle.transform = X(_beetle_rest + Vector3.UP * lift, face, 1.3)


# ============================================================================== THE FORK SIGNS
func _build_fork_signs() -> void:
	# FORK 1, the grotto's mouth: a scatter of rainbow pebbles (the beetle's colours).
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var pk := Kit.new()
	for i in 14:
		var s := rng.randf_range(1.5, grotto.total - 3.0)
		var f := _floor_spot(grotto, s, rng.randf_range(-0.6, 0.6))
		var q: Vector3 = f["q"]
		pk.iri = rng.randf()
		pk.iri_span = 0.6
		var r := rng.randf_range(0.035, 0.06)
		pk.blob(q + Vector3.UP * r * 0.4, Vector3(r, r * 0.6, r * 1.2), Color.WHITE, 0.3, 2, 5, Basis(Vector3.UP, rng.randf() * TAU))
	_mi(cave, pk, "RainbowPebbles")
	# FORK 1's mouth markers (C4, planned in `_plan_tints`): gold at the up road's lip, aqua at the down way's.
	# Their own seed, so the pebbles and flecks below keep the positions they had.
	var mrng := RandomNumberGenerator.new()
	mrng.seed = 83
	for m: Array in [["mouth_up", C_GOLD, "MouthCrystalsUp"], ["mouth_down", C_LILAC, "MouthCrystalsDown"]]:
		var f: Dictionary = _plan[m[0]]
		var mk := Kit.new()
		# CAVE3: the down way's marker is PRISMATIC now - the halls are all lit teal, so an aqua marker
		# would read as one more wall crystal. Gold up (to the chest), rainbow down (to the chamber, the
		# prism motes' way).
		if m[0] == "mouth_down":
			mk.iri = 0.0
			mk.iri_span = 1.0
			mk.iri_s = 0.5
		_cluster(mk, mrng, 6, 0.4, 0.95, 0.32, m[1], 0.8, false, 0.3)
		mk.iri = -1.0
		_rubble(mk, mrng, 0.5, 6)
		_mi(_node(m[2], X(f["q"], f["t"])), mk, "Mesh")
	# FORK 1 and FORK 2, toward the chamber: prism motes drifting on down the way, never still.
	_mote_s0 = trunk.s_of(_mk["trunk:fork1"]) + 1.5
	_mote_s1 = trunk.s_of(_mk["trunk:fork2"]) + 1.5
	for i in 12:
		var mk := Kit.new()
		mk.iri = float(i % 6) / 6.0
		mk.iri_span = 0.4
		mk.blob(Vector3.ZERO, Vector3(0.035, 0.035, 0.035), Color.WHITE, 0.8, 2, 4)
		var n := _node("PrismMote%d" % i, Transform3D())
		_mi(n, mk, "Mesh")
		_motes.append(n)
	# FORK 3, toward the loft: pale bubbles rising slowly out of its mouth (the jellies' own shimmer).
	for i in 6:
		var bk := Kit.new()
		bk.iri = 0.45 + 0.05 * float(i)
		bk.iri_span = 0.3
		bk.iri_s = 0.3
		bk.blob(Vector3.ZERO, Vector3(0.05, 0.05, 0.05), Color.WHITE, 0.7, 2, 5)
		var n := _node("LoftBubble%d" % i, Transform3D())
		_mi(n, bk, "Mesh")
		_bubbles.append(n)
	# FORK 1 and FORK 3, toward the chest: gold flecks in the floor, as if someone came this way with a sack.
	var gk := Kit.new()
	var s2 := 1.5
	while s2 < upway.total - 2.8:
		var f := _floor_spot(upway, s2, rng.randf_range(-0.35, 0.35))
		var q: Vector3 = (f["q"] as Vector3) + Vector3.UP * 0.035
		var r := rng.randf_range(0.03, 0.05)
		var a := rng.randf() * TAU
		gk.tri(q + Vector3(cos(a), 0, sin(a)) * r, q + Vector3(cos(a + 2.1), 0, sin(a + 2.1)) * r,
			q + Vector3(cos(a + 4.2), 0, sin(a + 4.2)) * r, C_GOLD.lightened(0.15), 0.9)
		if rng.randf() < 0.5:
			var q2 := q + Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
			gk.tri(q2 + Vector3(0.02, 0, 0), q2 + Vector3(-0.012, 0, 0.018), q2 + Vector3(-0.012, 0, -0.018), C_GOLD, 0.9)
		s2 += rng.randf_range(1.2, 2.0)
	_mi(cave, gk, "GoldFlecks")


func _tick_motes(t: float) -> void:
	var half := _motes.size() / 2
	for i in _motes.size():
		var j := i % half
		var ph := fmod(t * 0.07 + float(j) / float(half), 1.0)
		var a := trunk.at((_mote_s0 if i < half else _mote_s1) + ph * 10.0)
		var p: Vector3 = (a["p"] as Vector3) + Vector3.UP * (1.3 + 0.5 * sin(t * 0.9 + float(i) * 1.7)) \
			+ (a["side"] as Vector3) * 0.8 * sin(t * 0.4 + float(i) * 2.3)
		_motes[i].transform = X(p, a["t"], 0.6 + 0.4 * sin(ph * PI))
	for i in _bubbles.size():
		var ph := fmod(t * 0.09 + float(i) / float(_bubbles.size()), 1.0)
		var a := loft.at(1.5 + ph * 8.0)
		var p: Vector3 = (a["p"] as Vector3) + Vector3.UP * (0.6 + 2.6 * ph) \
			+ (a["side"] as Vector3) * 0.7 * sin(t * 0.5 + float(i) * 2.1)
		_bubbles[i].transform = X(p, a["t"], 0.5 + 0.7 * sin(ph * PI))


# ============================================================================== THE TREASURE ROUTE
func _build_treasure_route() -> void:
	# THE GLIMMER NEWT: a nook low in the right wall, a third of the way along.
	var s_n := upway.s_of(_mk["upway:newt"]) - 10.0
	var a := upway.at(s_n)
	var side := 1.0
	var wall_p := _wall_point(upway, s_n, side, 0.15)
	wall_p.y = (a["p"] as Vector3).y + 0.14
	_newt_out = -(a["side"] as Vector3) * side
	_newt_home = wall_p + _newt_out * 0.1
	var hk := Kit.new()
	for j in 10:
		var a0 := PI * float(j) / 10.0
		var a1 := PI * float(j + 1) / 10.0
		hk.tri(Vector3.ZERO, Vector3(cos(a0) * 0.28, sin(a0) * 0.26, 0), Vector3(cos(a1) * 0.28, sin(a1) * 0.26, 0), Color("#6f6a80"))
	for j in 6:
		var aa := PI * (float(j) + 0.5) / 6.0
		hk.blob(Vector3(cos(aa) * 0.31, sin(aa) * 0.3, 0.02), Vector3(0.07, 0.06, 0.06), C_WALL.darkened(0.04), 0.0, 2, 5)
	_mi(_node("Nook", X(_newt_home - _newt_out * 0.12, -_newt_out)), hk, "Mesh")
	_newt = _node("GlimmerNewt", X(_newt_home, _newt_out))
	_newt_body = _node("Body", Transform3D(), _newt)
	var nk := Kit.new()
	# head first (-Z): big and round, then a rainbow of shrinking segments to the tail
	_shadow(nk, Vector3(0, 0, 0.04), 0.1, 0.24, 0.2)
	nk.blob(Vector3(0, 0.07, -0.12), Vector3(0.075, 0.06, 0.07), rb(0.93, 0.5), 0.1, 3, 7)
	var segs := [[-0.04, 0.058, 0.03], [0.04, 0.052, 0.1], [0.11, 0.042, 0.2], [0.17, 0.032, 0.33], [0.22, 0.022, 0.5], [0.26, 0.014, 0.68]]
	for sg: Array in segs:
		var r: float = sg[1]
		nk.blob(Vector3(0, 0.045 + r * 0.35, float(sg[0])), Vector3(r, r * 0.8, r * 1.25), rb(float(sg[2])), 0.1, 3, 6)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		nk.blob(Vector3(0.042 * s, 0.1, -0.16), Vector3(0.024, 0.026, 0.016), C_EYE, 0.0, 3, 6)
		nk.blob(Vector3(0.036 * s, 0.11, -0.173), Vector3(0.007, 0.007, 0.004), Color.WHITE, 1.0, 2, 4)
		nk.blob(Vector3(0.06 * s, 0.058, -0.15), Vector3(0.014, 0.008, 0.006), Color("#f5a9bd"), 0.2, 2, 5)
		for z in [-0.02, 0.1]:
			nk.blob(Vector3(0.06 * s, 0.018, float(z)), Vector3(0.022, 0.016, 0.02), rb(0.15 + float(z)), 0.0, 2, 5)
	_mi(_newt_body, nk, "Mesh")
	safari.add_subject({"id": "glimmer_newt", "name": "Glimmer newt", "tier": "creature", "kind": "creature",
		"node": _newt, "offset": Vector3(0, 0.06, 0), "radius": 0.2, "band": Vector2(0.12, 0.45),
		"awake": _newt_awake, "front": SafariWorld.front_of(_newt, Vector3(0, 0, -1)), "moment": _newt_moment})
	# THE STAR FOSSIL: pressed into the left wall of the treasure way's middle room, past FORK 3.
	_build_fossil(upway.s_of(_mk["upway:fossil"]) + 0.5)


func _newt_out_k(t: float) -> float:
	var c := fmod(t, NEWT_CYCLE)
	return smoothstep(1.5, 2.6, c) * (1.0 - smoothstep(12.5, 13.6, c))


func _tick_newt(t: float) -> void:
	var c := fmod(t, NEWT_CYCLE)
	var out := _newt_out_k(t)
	_newt.visible = out > 0.02
	var p := _newt_home + _newt_out * (0.7 * out) - _newt_out * 0.25 * (1.0 - out)
	var face := _newt_out
	var cam := safari.rig.get_view_camera() if safari != null and safari.rig != null else null
	if cam != null and out > 0.9 and c > 5.0 and c < 10.0:
		var tc := cave.global_transform.affine_inverse() * cam.global_position - W(p)
		if tc.length() < 8.0 and tc.length_squared() > 1e-4:
			face = _newt_out.slerp(tc.normalized(), 0.8)
	_newt.transform = X(p, face, 1.35)
	var wig := sin(t * 9.0) * 0.15 * (1.0 - smoothstep(4.0, 5.0, c) * (1.0 - smoothstep(10.0, 11.0, c)))
	_newt_body.rotation = Vector3(0, wig, 0)


func _build_fossil(sf: float) -> void:
	var y := 1.25
	var a2 := upway.at(sf)
	var du := _wall_point(upway, sf, -1.0, y + 0.3) - _wall_point(upway, sf, -1.0, y - 0.3)
	var ds := _wall_point(upway, sf + 0.3, -1.0, y) - _wall_point(upway, sf - 0.3, -1.0, y)
	var inward: Vector3 = ds.cross(du).normalized()
	if inward.dot(a2["side"] as Vector3) < 0.0:
		inward = -inward
	var wall_p: Vector3 = _wall_point(upway, sf, -1.0, y) + inward * 0.03
	# A low stone nodule the colour of the wall, a star carved in relief on it in pale gold stone: a
	# ridge down each arm with two faces, segment grooves across each arm, a gold pinprick at the centre.
	var fk := Kit.new()
	var frng := RandomNumberGenerator.new()
	frng.seed = 53
	var stone := C_WALL.darkened(0.04)
	var fossil_col := C_WALL.lerp(C_GOLD, 0.45)
	var groove := fossil_col.darkened(0.3)
	var nod_n := 11
	var nod := []
	for j in nod_n:
		var ang := TAU * float(j) / float(nod_n)
		var rr := 0.44 * (1.0 + 0.12 * sin(ang * 3.0 + 1.3) + frng.randf_range(-0.05, 0.05))
		nod.append(Vector3(cos(ang) * rr, sin(ang) * rr * 0.9, 0.30))
	var nod_mid := []
	for j in nod_n:
		nod_mid.append(Vector3((nod[j] as Vector3).x * 0.78, (nod[j] as Vector3).y * 0.78, -0.05))
	for j in nod_n:
		var j1 := (j + 1) % nod_n
		fk.quad(nod[j], nod_mid[j], nod_mid[j1], nod[j1], stone.darkened(0.04 * float(j % 3)), 0.0)
		fk.tri(Vector3(0, 0, -0.056), nod_mid[j1], nod_mid[j], stone, 0.0)
	var zf := -0.055
	var tips := []
	var vals := []
	for j in 5:
		var ang := TAU * float(j) / 5.0 + PI * 0.5
		tips.append(Vector3(cos(ang) * 0.29, sin(ang) * 0.29, zf - 0.012))
		var va := ang + TAU / 10.0
		vals.append(Vector3(cos(va) * 0.085, sin(va) * 0.085, zf - 0.006))
	var ctr := Vector3(0, 0, zf - 0.034)
	for j in 5:
		var tip: Vector3 = tips[j]
		var v_l: Vector3 = vals[(j + 4) % 5]
		var v_r: Vector3 = vals[j]
		fk.tri(ctr, v_l, tip, fossil_col, 0.3)
		fk.tri(ctr, tip, v_r, fossil_col.darkened(0.14), 0.3)
		var down := Vector3(0, 0, 0.02)
		fk.quad(v_l, v_l + down, tip + down, tip, fossil_col.darkened(0.28), 0.0)
		fk.quad(tip, tip + down, v_r + down, v_r, fossil_col.darkened(0.28), 0.0)
		for g in 3:
			var f0 := 0.30 + 0.2 * float(g)
			var on_ridge := ctr.lerp(tip, f0)
			var half := 0.034 * (1.0 - f0 * 0.8)
			var side_l := on_ridge + (v_l - on_ridge).normalized() * half
			var side_r := on_ridge + (v_r - on_ridge).normalized() * half
			var lift := Vector3(0, 0, -0.0015)
			var along := (tip - ctr).normalized() * 0.006
			fk.quad(side_l + lift, on_ridge + lift, on_ridge + along + lift, side_l + along + lift, groove, 0.0)
			fk.quad(on_ridge + lift, side_r + lift, side_r + along + lift, on_ridge + along + lift, groove, 0.0)
	for j in 5:
		var a0 := TAU * float(j) / 5.0
		var a1 := TAU * float(j + 1) / 5.0
		fk.tri(ctr + Vector3(0, 0, -0.002), ctr + Vector3(cos(a0) * 0.02, sin(a0) * 0.02, 0.004),
			ctr + Vector3(cos(a1) * 0.02, sin(a1) * 0.02, 0.004), C_GOLD, 1.0)
	var up_here := (W(wall_p) + Vector3(0, R, 0)).normalized()
	var fossil := _node("StarFossil", Transform3D(Basis.looking_at(inward, up_here), W(wall_p)))
	_mi(fossil, fk, "Mesh")
	_fossil_inward = inward
	safari.add_subject({"id": "star_fossil", "name": "Star fossil", "tier": "rare", "kind": "rare",
		"node": fossil, "radius": 0.36, "band": Vector2(0.15, 0.55), "front": _fossil_front})


# ============================================================================== THE CHEST
func _build_chest() -> void:
	var a := upway.at(upway.total - 2.3)
	# faces back up the route, the way you come in
	_chest = _node("TreasureChest", X(_chest_local, -(a["t"] as Vector3)))
	var k := Kit.new()
	var wd := 0.9
	var dp := 0.58
	var bh := 0.46
	_shadow(k, Vector3.ZERO, wd * 0.7, dp * 0.8, 0.28)
	# an open-topped box: four outer sides, and inside a darker lining and floor
	var hx := wd * 0.5
	var hz := dp * 0.5
	var inset := 0.035
	var c4 := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	var i4 := [Vector3(-hx + inset, 0, -hz + inset), Vector3(hx - inset, 0, -hz + inset), Vector3(hx - inset, 0, hz - inset),
		Vector3(-hx + inset, 0, hz - inset)]
	var up := Vector3(0, bh, 0)
	for q in 4:
		var ca: Vector3 = c4[q]
		var cb: Vector3 = c4[(q + 1) % 4]
		var ia: Vector3 = i4[q]
		var ib: Vector3 = i4[(q + 1) % 4]
		k.quad(ca, cb, cb + up, ca + up, C_WOOD.darkened(0.04 * float(q % 2)))
		k.quad(ib + Vector3(0, 0.08, 0), ia + Vector3(0, 0.08, 0), ia + up, ib + up, C_WOOD_DK.darkened(0.15))
		k.quad(ca + up, cb + up, ib + up, ia + up, C_WOOD.lightened(0.06))
	k.quad(i4[0] + Vector3(0, 0.08, 0), i4[1] + Vector3(0, 0.08, 0), i4[2] + Vector3(0, 0.08, 0), i4[3] + Vector3(0, 0.08, 0),
		C_WOOD_DK.darkened(0.25))
	for py in [0.15, 0.31]:
		k.box(Vector3(0, float(py), -dp * 0.5 - 0.004), Vector3(wd * 0.98, 0.012, 0.006), C_WOOD_DK)
	# brass bands: thin plates on the outside only, so nothing crosses the open top
	for bx in [-0.3, 0.3]:
		for zs in [-1.0, 1.0]:
			k.box(Vector3(float(bx), bh * 0.5, float(zs) * (hz + 0.006)), Vector3(0.06, bh + 0.01, 0.012), C_BRASS, 0.15)
	for zs in [-1.0, 1.0]:
		k.box(Vector3(0, bh * 0.5, float(zs) * (hz + 0.008)), Vector3(wd + 0.012, 0.05, 0.012), C_BRASS.darkened(0.1), 0.1)
	for xs in [-1.0, 1.0]:
		k.box(Vector3(float(xs) * (hx + 0.006), bh * 0.5, 0), Vector3(0.012, 0.05, dp + 0.012), C_BRASS.darkened(0.1), 0.1)
	# a little rainbow gem set in the lock plate
	k.box(Vector3(0, bh - 0.06, -dp * 0.5 - 0.012), Vector3(0.12, 0.14, 0.02), C_BRASS, 0.2)
	k.iri = 0.8
	k.iri_span = 0.9
	k.blob(Vector3(0, bh - 0.06, -dp * 0.5 - 0.03), Vector3(0.032, 0.032, 0.02), Color.WHITE, 0.6, 2, 6)
	k.iri = -1.0
	_mi(_chest, k, "Base")
	# the lid: a faceted half-barrel on a hinge along the back top edge
	_chest_lid = _node("Lid", Transform3D(Basis(), Vector3(0, bh, dp * 0.5)), _chest)
	var lk := Kit.new()
	var rr := dp * 0.5
	var segs := 6
	for j in segs:
		var a0 := PI * float(j) / float(segs)
		var a1 := PI * float(j + 1) / float(segs)
		var p0 := Vector3(0, sin(a0) * rr * 0.75, -rr + cos(a0) * rr)
		var p1 := Vector3(0, sin(a1) * rr * 0.75, -rr + cos(a1) * rr)
		lk.quad(p0 + Vector3(-wd * 0.5, 0, 0), p1 + Vector3(-wd * 0.5, 0, 0), p1 + Vector3(wd * 0.5, 0, 0),
			p0 + Vector3(wd * 0.5, 0, 0), C_WOOD.lightened(0.04 * float(j % 2)))
		for ex in [-1.0, 1.0]:
			lk.tri(Vector3(float(ex) * wd * 0.5, 0, -rr), p0 + Vector3(float(ex) * wd * 0.5, 0, 0),
				p1 + Vector3(float(ex) * wd * 0.5, 0, 0), C_WOOD_DK)
		for bx in [-0.3, 0.3]:
			var o := Vector3(float(bx), 0, 0)
			var lift0 := p0 * 1.03 + Vector3(0, 0, rr * 0.03)
			var lift1 := p1 * 1.03 + Vector3(0, 0, rr * 0.03)
			lk.quad(lift0 + o + Vector3(-0.03, 0, 0), lift1 + o + Vector3(-0.03, 0, 0), lift1 + o + Vector3(0.03, 0, 0),
				lift0 + o + Vector3(0.03, 0, 0), C_BRASS, 0.15)
	_mi(_chest_lid, lk, "Mesh")
	# the suit inside: folded pearl and violet, with a shimmer of rainbow on top
	_chest_bundle = _node("Bundle", Transform3D(Basis(), Vector3(0, bh - 0.02, 0)), _chest)
	var sk := Kit.new()
	sk.box(Vector3(0, 0.03, 0), Vector3(0.5, 0.06, 0.34), Color("#efebf5"), 0.3)
	sk.box(Vector3(0, 0.065, 0.02), Vector3(0.44, 0.02, 0.28), Color("#8f6fd6"), 0.3)
	sk.box(Vector3(0, 0.09, 0), Vector3(0.4, 0.04, 0.26), Color("#f4f1f9"), 0.35)
	for i in 7:
		var ang := TAU * float(i) / 7.0
		var q := Vector3(cos(ang) * 0.14, 0.113, sin(ang) * 0.08)
		sk.tri(q + Vector3(0.025, 0, 0), q + Vector3(-0.012, 0, 0.022), q + Vector3(-0.012, 0, -0.022), rb(float(i) / 7.0, 0.5, 1.0), 1.0)
	_mi(_chest_bundle, sk, "Mesh")
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 3
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(wd + 0.05, 0.8, dp + 0.08)
	cs.shape = bs
	cs.position = Vector3(0, 0.4, 0)
	body.add_child(cs)
	_chest.add_child(body)
	if CaveStore.chest_found():
		_chest_state = 2
		_chest_lid.rotation = Vector3(1.95, 0, 0)
		_chest_bundle.visible = false


func _tick_chest(t: float) -> void:
	if _chest == null:
		return
	if _chest_state == 1 and _chest_open_t >= 0.0:
		var k := clampf((t - _chest_open_t) / 0.9, 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		_chest_lid.rotation = Vector3(1.95 * k, 0, 0)
		_chest_bundle.position.y = 0.44 + 0.12 * sin(k * PI) + 0.02 * sin(t * 2.0)
		if t - _chest_open_t > 5.0:
			_chest_bundle.visible = false
			_chest_state = 2
	if safari.phase != PlanetSafari.Phase.AWAKE or safari.player == null:
		return
	var d := safari.player.global_position.distance_to(_world(_chest_local))
	if d > CHEST_REACH_M:
		return
	if _chest_state == 0:
		_open_chest(t)
	elif _chest_state == 2 and not _chest_said_empty:
		_chest_said_empty = true
		safari.announce("The chest is empty now. You found its treasure already!", 3.0)


## THE FIND (9.4): the suit goes into the bag and the wardrobe at once, and the chest is marked found
## in the save (CaveStore.CHEST_FLAG), so it is never filled again.
func _open_chest(t: float) -> void:
	_chest_state = 1
	_chest_open_t = t
	var nm := "Prism Suit"
	var def: Dictionary = Catalog.get_item(OUTFIT_ID) if Catalog.has_item(OUTFIT_ID) else {}
	if not def.is_empty():
		nm = str(def.get("name", nm))
	CaveStore.take_chest(OUTFIT_ID)
	# SAVED AT ONCE (C4, 2026-09-28): the chest is found once ever, so the find must not wait for the
	# next periodic autosave - closing the app right after would lose the suit. The cave's normal save
	# call (the same gate and call CaveVisit uses when the visit starts): a player's session writes the
	# file now; an agent/dev run, where autosave is off, writes nothing.
	if SaveManager.has_method("autosave_allowed") and SaveManager.autosave_allowed():
		SaveManager.save_game()
	AudioManager.play_sfx("quest_complete", -4.0)
	safari.announce("Treasure! You found the %s. It's in your bag now." % nm, 4.5)
	print("[CaveWorld] chest opened at t=%.1f: %s given (wardrobe=%s)" % [t, OUTFIT_ID, str(GameState.wardrobe)])


# ============================================================================== THE BIG CHAMBER
## T1CAVE: the chamber's spires glow like the halls' crystals - teal, one in three a rainbow hue.
static func _spire_colour(k: int) -> Color:
	return rb(float(k) / 9.0 + 0.1, 0.55, 0.97) if k % 3 == 1 else C_TEAL


func _build_chamber() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 131
	var c := _chamber_c
	var t := _chamber_t
	var sd := _chamber_side
	var i := trunk.idx_at(trunk.s_of(_mk["trunk:chamber"]))
	var e := trunk.ell(i)
	var w := trunk.ws[i]
	var ceil_at := func(x: float) -> float:
		var q := clampf(x / w, -0.99, 0.99)
		return e.x + e.y * sqrt(1.0 - q * q)
	# tall pastel crystal spires round the edge, and white stalagmites
	var sk := Kit.new()
	for k in 9:
		var ang := TAU * float(k) / 9.0 + 0.3
		var rx := 7.2 + rng.randf_range(-0.6, 0.6)
		var rz := 5.8 + rng.randf_range(-0.6, 0.6)
		var p := c + sd * cos(ang) * rx + t * sin(ang) * rz
		if absf(sin(ang)) > 0.85 and sin(ang) < 0.0:
			continue   # keep the way in clear
		var col := _spire_colour(k)
		var h := rng.randf_range(1.6, 4.2)
		# CAVE4: each spire leans (0.2-0.45 rad), sunk by what its tilt lifts; its young crystals splay out
		var tl := rng.randf_range(0.2, 0.45)
		var xf := Transform3D(Basis(Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(), tl),
			p - Vector3.UP * (0.08 + h * 0.16 * sin(tl)))
		sk.gem(xf, h * 0.16, h, col, 1.0)
		_halos.append([p + Vector3.UP * h * 0.45, h * 0.5, col])
		for m in 3:
			var off := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
			var h2 := h * rng.randf_range(0.3, 0.55)
			var t2 := rng.randf_range(0.45, 0.85)
			sk.gem(Transform3D(Basis(off.cross(Vector3.UP).normalized() if off.length() > 0.05 else Vector3.RIGHT, -t2),
				p + off - Vector3.UP * (0.06 + h2 * 0.18 * sin(t2))), h2 * 0.18, h2, col.lightened(0.1), 1.0)
	for k in 7:
		var p := c + sd * rng.randf_range(-7.5, 7.5) + t * rng.randf_range(-5.0, 6.0)
		if p.distance_to(c) < 3.5 or p.distance_to(_pool_centre) < 2.4:
			continue
		var h := rng.randf_range(0.5, 1.4)
		sk.gem(Transform3D(Basis(), p - Vector3(0, 0.05, 0)), h * 0.3, h, C_WALL.darkened(0.03), 0.0)
	# stalactites hanging from the dome
	for k in 12:
		var x := rng.randf_range(-6.5, 6.5)
		var z := rng.randf_range(-4.5, 6.0)
		var p := c + sd * x + t * z
		var top := float(ceil_at.call(x)) - 0.15
		var h := rng.randf_range(0.8, 2.4)
		sk.gem(Transform3D(Basis(Vector3.RIGHT, PI), p + Vector3.UP * (top + 0.3)), h * 0.18, h, C_CEIL.lightened(0.03), 0.0)
	_mi_warped(sk, "ChamberCrystals")
	_build_pool(rng)
	_build_meteor_piece(rng)
	_build_bloom(rng)
	_build_ray()


func _build_pool(rng: RandomNumberGenerator) -> void:
	var pk := Kit.new()
	var rx := 1.7
	var rz := 1.25
	var segs := 16
	for j in segs:
		var a0 := TAU * float(j) / float(segs)
		var a1 := TAU * float(j + 1) / float(segs)
		pk.tri(Vector3(0, 0.03, 0), Vector3(cos(a0) * rx, 0.03, sin(a0) * rz), Vector3(cos(a1) * rx, 0.03, sin(a1) * rz),
			Color("#8fcfd0"), 0.4)
		pk.blob(Vector3(cos(a0) * (rx + 0.12), 0.03, sin(a0) * (rz + 0.12)), Vector3(0.16, 0.08, 0.13), C_WALL.darkened(0.05), 0.0, 3, 6)
	for j in 26:
		var a := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf()) * 0.85
		var p := Vector3(cos(a) * rx * r, 0.034, sin(a) * rz * r)
		var sz := rng.randf_range(0.03, 0.07)
		pk.tri(p + Vector3(-sz, 0, 0), p + Vector3(0, 0, sz), p + Vector3(sz, 0, 0), rb(rng.randf(), 0.4, 1.0), 1.0)
	for j in 3:
		var a := rng.randf_range(0.0, TAU)
		pk.gem(Transform3D(Basis(Vector3(-sin(a), 0, cos(a)), 0.35), Vector3(cos(a) * rx * 0.95, 0.0, sin(a) * rz * 0.95)),
			0.07, rng.randf_range(0.35, 0.6), C_AQUA, 0.6)
	var pool := _node("CrystalPool", X(_pool_centre, _chamber_t))
	_mi(pool, pk, "Mesh")
	# THE POOL STOPS YOU AT ITS RIM (CAVEPOL): a low elliptic wall through the rim stones' centres.
	# Photo and focus rays skip it (CaveVisit._exclude).
	pool_body = StaticBody3D.new()
	pool_body.name = "PoolRim"
	pool_body.collision_layer = 1 << 3
	pool_body.collision_mask = 0
	var pcs := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	var hp := PackedVector3Array()
	for j in segs:
		var a := TAU * float(j) / float(segs)
		for yy in [-0.3, 0.9]:
			hp.append(Vector3(cos(a) * (rx + 0.12), yy, sin(a) * (rz + 0.12)))
	hull.points = hp
	pcs.shape = hull
	pool_body.add_child(pcs)
	pool.add_child(pool_body)
	safari.add_subject({"id": "crystal_pool", "name": "Crystal pool", "tier": "sight", "kind": "sight",
		"node": pool, "offset": Vector3(0, 0.1, 0), "radius": 1.55, "band": Vector2(0.35, 0.95)})
	# THE MOTH DANCE: five prism moths spiral over the pool now and then.
	_dance = _node("MothDance", X(_pool_centre + Vector3.UP * 1.8, _chamber_t))
	for i in 5:
		var hold := _node("Moth%d" % i, Transform3D(), _dance)
		var wings := _moth_mesh(hold, float(i) * 0.2)
		hold.set_meta("wings", wings)
		_dance_moths.append(hold)
	_dance.visible = false
	safari.add_subject({"id": "moth_dance", "name": "Moth dance", "tier": "rare", "kind": "rare",
		"node": _dance, "radius": 1.0, "band": Vector2(0.3, 0.85), "awake": _dance_awake, "moment": _dance_moment})


func _dance_k(t: float) -> float:
	if t < DANCE_FIRST:
		return 0.0
	var c := fmod(t - DANCE_FIRST, DANCE_EVERY)
	return 0.0 if c > DANCE_LEN else sin(c / DANCE_LEN * PI)


func _tick_dance(t: float) -> void:
	var k := _dance_k(t)
	_dance.visible = k > 0.02
	if not _dance.visible:
		return
	var r := lerpf(2.2, 0.6, k)
	for i in _dance_moths.size():
		var m := _dance_moths[i]
		var a := TAU * float(i) / 5.0 + t * 1.3
		var p := Vector3(cos(a) * r, 0.25 * sin(t * 2.0 + float(i)) + (1.0 - k) * 1.2, sin(a) * r)
		m.transform = Transform3D(Basis.looking_at(Vector3(-sin(a), 0.0, cos(a)), Vector3.UP).scaled(Vector3.ONE * 1.1), p)
		var wings: Array = m.get_meta("wings", [])
		var flap := sin(t * 24.0 + float(i)) * 0.9
		if wings.size() == 2:
			(wings[0] as Node3D).rotation = Vector3(0, 0, -flap)
			(wings[1] as Node3D).rotation = Vector3(0, 0, flap)


func _build_meteor_piece(rng: RandomNumberGenerator) -> void:
	var mk := Kit.new()
	var lat := 5
	var lon := 9
	var radii := Vector3(1.05, 0.85, 0.9)
	var centre := Vector3(0, 0.45, 0)
	for i in lat:
		for j in lon:
			var t0 := PI * float(i) / float(lat) - PI * 0.5
			var t1 := PI * float(i + 1) / float(lat) - PI * 0.5
			var p0 := TAU * float(j) / float(lon)
			var p1 := TAU * float(j + 1) / float(lon)
			var q := func(t: float, p: float) -> Vector3:
				var jig := 1.0 + 0.16 * sin(p * 3.0 + t * 5.0) + 0.1 * cos(p * 5.0 - t * 2.0)
				return centre + Vector3(cos(t) * cos(p) * radii.x, sin(t) * radii.y, cos(t) * sin(p) * radii.z) * jig
			var seam := rng.randf() < 0.45 and i > 0 and i < lat - 1
			var col := C_CRUST.lightened(rng.randf_range(0.0, 0.1))
			var a: Vector3 = q.call(t0, p0)
			var b: Vector3 = q.call(t1, p0)
			var d: Vector3 = q.call(t1, p1)
			var e: Vector3 = q.call(t0, p1)
			if i == 0:
				mk.tri(a, b, d, col)
			elif i == lat - 1:
				mk.tri(a, b, e, col)
			elif seam:
				var k := 0.16
				if rng.randf() < 0.5:
					var a2 := a + (b - a) * k
					var e2 := e + (d - e) * k
					mk.quad(a, a2, e2, e, C_SEAM, 1.0)
					mk.quad(a2, b, d, e2, col)
				else:
					var a3 := a + (e - a) * k
					var b3 := b + (d - b) * k
					mk.quad(a, b, b3, a3, C_SEAM, 1.0)
					mk.quad(a3, b3, d, e, col)
			else:
				mk.quad(a, b, d, e, col)
	for j in 12:
		var a := TAU * float(j) / 12.0 + rng.randf_range(-0.1, 0.1)
		var rr := rng.randf_range(1.5, 1.9)
		mk.blob(Vector3(cos(a) * rr, 0.05, sin(a) * rr), Vector3(0.28, 0.14, 0.22), C_WALL.darkened(0.1), 0.0, 3, 6,
			Basis(Vector3.UP, a))
	for j in 5:
		var a := rng.randf_range(0.0, TAU)
		mk.gem(Transform3D(Basis(Vector3(-sin(a), 0, cos(a)), 0.4), Vector3(cos(a) * 1.3, 0.0, sin(a) * 1.3)), 0.06,
			rng.randf_range(0.3, 0.55), C_AMBER.lerp(C_GOLD, 0.5), 0.7)
	var piece := _node("MeteorPiece", X(_chamber_c + _chamber_t * 3.5, _chamber_t))
	_mi(piece, mk, "Mesh")
	_body_cyl(piece, 1.05, 1.4)
	safari.add_subject({"id": "meteor_piece", "name": "The meteor piece", "tier": "uncommon", "kind": "sight",
		"node": piece, "offset": Vector3(0, 0.5, 0), "radius": 1.2, "band": Vector2(0.35, 0.9)})


func _build_bloom(rng: RandomNumberGenerator) -> void:
	var p := _chamber_c + _chamber_side * 6.0 + _chamber_t * 1.5
	_bloom = _node("CrystalBloom", X(p, -_chamber_side))
	# in full bloom the same cluster turns prismatic: two meshes from one seed, the second repainted
	var seed := rng.randi()
	var r3 := RandomNumberGenerator.new()
	r3.seed = seed
	var r4 := RandomNumberGenerator.new()
	r4.seed = seed
	var kn := Kit.new()
	var kp := Kit.new()
	var kb := Kit.new()
	var rr := RandomNumberGenerator.new()
	rr.seed = 1907
	_rubble(kb, rr, 1.05, 9)
	_mi(_bloom, kb, "Base")
	_cluster(kn, r3, 12, 0.8, 1.7, 0.9, C_LILAC, 0.5, false)
	_cluster(kp, r4, 12, 0.8, 1.7, 0.9, C_LILAC, 0.5, false)
	_bloom_plain = _mi(_bloom, kn, "Plain")
	var pc := kp.c
	for q in range(0, pc.size(), 3):
		var nn := kp.n[q]
		var cc := rb(0.5 + 0.8 * (0.5 * nn.x + 0.4 * nn.z) + float(q) * 0.0007, 0.5, 1.0)
		pc[q] = cc
		pc[q + 1] = cc
		pc[q + 2] = cc
	kp.c = pc
	_bloom_prism = _mi(_bloom, kp, "Prism")
	_bloom_prism.visible = false
	_body_cyl(_bloom, 0.95, 1.7)
	for i in 8:
		var mk := Kit.new()
		mk.iri = float(i) / 8.0
		mk.blob(Vector3.ZERO, Vector3(0.04, 0.04, 0.04), Color.WHITE, 1.0, 2, 4)
		var mote := _node("Mote%d" % i, Transform3D(), _bloom)
		_mi(mote, mk, "Mesh")
		mote.visible = false
		_bloom_motes.append(mote)
	safari.add_subject({"id": "crystal_bloom", "name": "Crystal bloom", "tier": "rare", "kind": "rare",
		"node": _bloom, "offset": Vector3(0, 0.9, 0), "radius": 1.2, "band": Vector2(0.3, 0.85),
		"awake": _bloom_awake, "moment": _bloom_moment})


func _bloom_k(t: float) -> float:
	if t < BLOOM_FIRST:
		return 0.0
	var c := fmod(t - BLOOM_FIRST, BLOOM_EVERY)
	return 0.0 if c > BLOOM_LEN else sin(c / BLOOM_LEN * PI)


func _tick_bloom(t: float) -> void:
	var b := _bloom_k(t)
	_bloom.scale = Vector3.ONE * (1.0 + 0.1 * b)
	_bloom_prism.visible = b > 0.35
	_bloom_plain.visible = not _bloom_prism.visible
	for i in _bloom_motes.size():
		var m := _bloom_motes[i]
		m.visible = b > 0.05
		if m.visible:
			var ph := fmod(t * 0.35 + float(i) / 8.0, 1.0)
			var a := TAU * float(i) / 8.0 + t * 0.4
			m.position = Vector3(cos(a) * 0.8, 0.6 + ph * 2.0, sin(a) * 0.8)
			m.scale = Vector3.ONE * ((1.0 - ph) * b + 0.01)


# ============================================================================== THE JELLY LOFT
## The top of the left-hand climb from FORK 3: a tall, narrow room of pale aqua and lilac, a ring of slim
## crystals round its floor, and the drift jellies floating in the air above them.
func _build_loft() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 151
	var sd := _loft_t.cross(Vector3.UP).normalized()
	var k := Kit.new()
	for q in 7:
		var ang := TAU * float(q) / 7.0 + 0.5
		if sin(ang) < -0.75:
			continue   # keep the way in clear
		var p := _loft_c + sd * cos(ang) * 2.6 + _loft_t * sin(ang) * 2.2
		var h := rng.randf_range(0.9, 2.2)
		var col := C_AQUA if q % 2 == 0 else C_LILAC
		var tl := rng.randf_range(0.2, 0.45)
		k.gem(Transform3D(Basis(Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(), tl),
			p - Vector3(0, 0.06 + h * 0.14 * sin(tl), 0)), h * 0.14, h, col.lightened(0.15), 0.5)
	_mi_warped(k, "LoftCrystals")
	_build_jellies()


# ------------------------------------------------------------------------------ DRIFT JELLIES
func _build_jellies() -> void:
	_jellies = _node("DriftJellies", X(_loft_c + Vector3.UP * 3.2))
	for j in 3:
		var hold := _node("Jelly%d" % j, Transform3D(), _jellies)
		var k := Kit.new()
		k.iri = 0.45 + 0.3 * float(j)
		k.iri_span = 0.9
		k.iri_s = 0.55
		var rad := 0.34 - 0.05 * float(j)
		k.blob(Vector3.ZERO, Vector3(rad, rad * 0.8, rad), Color.WHITE, 0.35, 4, 8, Basis(), 0.0, true)
		k.iri = -1.0
		# the bell's pale underside and two sleepy eyes
		for q in 8:
			var a0 := TAU * float(q) / 8.0
			var a1 := TAU * float(q + 1) / 8.0
			k.tri(Vector3(0, 0.005, 0), Vector3(cos(a1) * rad, 0.0, sin(a1) * rad), Vector3(cos(a0) * rad, 0.0, sin(a0) * rad),
				rb(0.45 + 0.3 * float(j) + 0.12 * float(q), 0.4, 1.0), 0.7)
		for sx in [-1.0, 1.0]:
			k.blob(Vector3(0.09 * float(sx) * rad / 0.34, rad * 0.35, -rad * 0.86), Vector3(0.022, 0.03, 0.01), C_EYE, 0.0, 2, 5)
		_mi(hold, k, "Bell")
		var tails := _node("Tails", Transform3D(), hold)
		var tk := Kit.new()
		for q in 5:
			var a := TAU * float(q) / 5.0 + 0.3
			var base := Vector3(cos(a) * rad * 0.6, 0.0, sin(a) * rad * 0.6)
			var across := Vector3(-sin(a), 0, cos(a)) * 0.02
			for sgm in 4:
				var y0 := -0.18 * float(sgm)
				var y1 := y0 - 0.18
				var sw0 := Vector3(0.03 * sin(float(sgm) * 1.3 + a), 0, 0)
				var sw1 := Vector3(0.03 * sin(float(sgm + 1) * 1.3 + a), 0, 0)
				tk.quad(base + sw0 + Vector3(0, y0, 0) - across, base + sw0 + Vector3(0, y0, 0) + across,
					base + sw1 + Vector3(0, y1, 0) + across, base + sw1 + Vector3(0, y1, 0) - across,
					rb(0.45 + 0.3 * float(j) + 0.1 * float(sgm), 0.45, 0.98), 0.6)
		_mi(tails, tk, "Mesh")
		_jelly_nodes.append(hold)
		_jelly_tails.append(tails)
	safari.add_subject({"id": "drift_jellies", "name": "Drift jellies", "tier": "creature", "kind": "creature",
		"node": _jellies, "radius": 1.3, "band": Vector2(0.2, 0.75), "moment": _jelly_moment})


func _jelly_pulse(t: float, j: int) -> float:
	var c := fmod(t + float(j) * 0.35, JELLY_PULSE)
	return smoothstep(0.0, 0.3, c) * (1.0 - smoothstep(0.3, 1.2, c))


func _tick_jellies(t: float) -> void:
	# the trio drifts round the loft together, slowly, each bobbing on its own
	var a := t * 0.12
	var sd := _loft_t.cross(Vector3.UP).normalized()
	var ctr := _loft_c + sd * cos(a) * 1.3 + _loft_t * sin(a) * 1.1 + Vector3.UP * (3.3 + 0.5 * sin(t * 0.3))
	_jellies.transform = X(ctr, sd * -sin(a) + _loft_t * cos(a))
	for j in _jelly_nodes.size():
		var pu := _jelly_pulse(t, j)
		var off := Vector3((float(j) - 1.0) * 0.9, 0.35 * sin(t * 0.8 + float(j) * 2.0) + 0.25 * pu + (0.3 if j == 1 else 0.0), 0.3 * float(j % 2))
		_jelly_nodes[j].position = off
		_jelly_nodes[j].scale = Vector3(1.0 + 0.12 * pu, 1.0 - 0.15 * pu, 1.0 + 0.12 * pu)
		_jelly_tails[j].rotation = Vector3(0.12 * sin(t * 1.1 + float(j)), 0, 0.1 * sin(t * 0.9 + float(j) * 1.7))


# ------------------------------------------------------------------------------ THE AURORA RAY
func _build_ray() -> void:
	_ray = _node("AuroraRay", X(_chamber_c + Vector3.UP * 6.0))
	var k := Kit.new()
	# the body: a flat diamond, pale, with a rainbow ridge
	var nose := Vector3(0, 0.02, -0.55)
	var tail := Vector3(0, 0.0, 0.45)
	var l := Vector3(-0.28, 0, -0.05)
	var r := Vector3(0.28, 0, -0.05)
	var top := Vector3(0, 0.12, -0.08)
	k.tri(nose, l, top, rb(0.7, 0.4), 0.2)
	k.tri(nose, top, r, rb(0.62, 0.4), 0.2)
	k.tri(top, l, tail, rb(0.78, 0.4), 0.2)
	k.tri(top, tail, r, rb(0.55, 0.4), 0.2)
	k.tri(nose, r, tail, rb(0.66, 0.3, 1.0), 0.3)
	k.tri(nose, tail, l, rb(0.6, 0.3, 1.0), 0.3)
	for sx in [-1.0, 1.0]:
		k.blob(Vector3(0.09 * float(sx), 0.07, -0.34), Vector3(0.035, 0.035, 0.025), C_EYE, 0.0, 2, 5)
		k.blob(Vector3(0.08 * float(sx), 0.085, -0.36), Vector3(0.01, 0.01, 0.008), Color.WHITE, 1.0, 2, 4)
	# the long tail streamer, a rainbow
	for q in 6:
		var z0 := 0.45 + 0.22 * float(q)
		var z1 := z0 + 0.22
		var w0 := 0.04 * (1.0 - float(q) / 6.0)
		var w1 := 0.04 * (1.0 - float(q + 1) / 6.0)
		k.quad(Vector3(-w0, 0, z0), Vector3(w0, 0, z0), Vector3(w1, 0, z1), Vector3(-w1, 0, z1), rb(float(q) / 6.0), 0.5)
	_mi(_ray, k, "Body")
	for sgn in [-1.0, 1.0]:
		var s := float(sgn)
		var hinge := _node("Wing", Transform3D(Basis(), Vector3(0.26 * s, 0, -0.05)), _ray)
		var wk := Kit.new()
		var rim := [Vector3(0, 0, -0.35), Vector3(0.45 * s, 0.02, -0.28), Vector3(0.95 * s, 0.05, -0.02),
			Vector3(0.7 * s, 0.02, 0.18), Vector3(0.3 * s, 0, 0.3), Vector3(0, 0, 0.28)]
		var root := Vector3(0, 0.02, -0.02)
		for q in rim.size() - 1:
			var hue := 0.62 - 0.16 * float(q)
			wk.tri(root, rim[q], rim[q + 1], rb(hue, 0.55), 0.35)
			wk.tri(root - Vector3(0, 0.01, 0), rim[q + 1] - Vector3(0, 0.01, 0), rim[q] - Vector3(0, 0.01, 0), rb(hue + 0.05, 0.38, 1.0), 0.45)
		_mi(hinge, wk, "Mesh")
		_ray_wings.append(hinge)
	_ray.visible = false
	safari.add_subject({"id": "aurora_ray", "name": "Aurora ray", "tier": "rare", "kind": "rare",
		"node": _ray, "radius": 1.4, "band": Vector2(0.2, 0.7), "awake": _ray_awake, "moment": _ray_moment,
		"front": SafariWorld.front_of(_ray, Vector3(0, 0, -1))})


## 0..RAY_LEN while the ray is out, else -1.
func _ray_t(t: float) -> float:
	if t < RAY_FIRST:
		return -1.0
	var c := fmod(t - RAY_FIRST, RAY_EVERY)
	return c if c <= RAY_LEN else -1.0


func _ray_pos(u: float) -> Vector3:
	# a wide loop under the dome, swooping low over the floor near the pool once a lap
	var a := u * 0.36 + 1.2
	var low := exp(-pow((fposmod(a, TAU) - PI) / 0.6, 2.0))
	return _chamber_c + _chamber_side * cos(a) * 5.5 + _chamber_t * sin(a) * 4.2 + Vector3.UP * (6.2 - 3.4 * low)


func _tick_ray(t: float) -> void:
	var u := _ray_t(t)
	_ray.visible = u >= 0.0
	if not _ray.visible:
		return
	var p := _ray_pos(u)
	var fwd := _ray_pos(u + 0.1) - p
	var grow := smoothstep(0.0, 1.2, u) * (1.0 - smoothstep(RAY_LEN - 1.2, RAY_LEN, u))
	_ray.transform = X(p, fwd, 1.7 * maxf(grow, 0.02))
	# bank into the turn
	_ray.transform.basis = _ray.transform.basis * Basis(Vector3.FORWARD, -0.25)
	var flap := 0.32 * sin(t * 2.2)
	if _ray_wings.size() == 2:
		_ray_wings[0].rotation = Vector3(0, 0, flap)
		_ray_wings[1].rotation = Vector3(0, 0, -flap)


func _ray_low(t: float) -> bool:
	var u := _ray_t(t)
	if u < 0.0:
		return false
	return (_ray_pos(u).y - _chamber_c.y) < 3.6


# ============================================================================== THE NEW SUBJECTS (CAVE3)
## 9.5 item 6: something new to look at every ~10-15 s of walking. [kind, tube, s (m along it), side
## (+1 right, -1 left, 0 the roof)]. A kind on a second route is a second subject filed to the same page
## (id "kind@2", CaveStore.offer_photo). Spots: each route's gaps measured on the C4 cave (the CAVE3 walk).
func _new_defs() -> Array:
	return [
		["glow_caps", "trunk", 22.0, -1.0],
		["sleepy_bats", "trunk", 29.0, 0.0],
		["pulse_crystals", "trunk", 45.0, 1.0],
		["drip_pool", "trunk", 63.0, -1.0],
		["peek_mole", "trunk", 74.0, 1.0],
		["lantern_worms", "upway", 7.0, 0.0],
		["peek_mole", "upway", 13.0, -1.0],
		["rainbow_spire", "upway", 26.0, -1.0],
		["pulse_crystals", "upway", 44.0, 1.0],
		["sleepy_bats", "upway", 66.0, 0.0],
		["geode", "grotto", 9.0, -1.0],
		["glow_caps", "grotto", 16.0, 1.0],
		["glow_caps", "loft", 8.0, 1.0],
		["lantern_worms", "loft", 17.0, 0.0],
	]


const NEW_NAMES := {"glow_caps": "Glow caps", "pulse_crystals": "Pulse crystals", "drip_pool": "Drip pool",
	"peek_mole": "Peek mole", "lantern_worms": "Lantern worms", "sleepy_bats": "Sleepy bats",
	"geode": "Rainbow geode", "rainbow_spire": "Rainbow spire"}
const C_CAP_STEM := Color("#efe2d2")
const C_FUR := Color("#b9a6c8")
const C_NOSE := Color("#f2a2b6")
const C_BAT := Color("#9d8cb4")
const C_WING := Color("#6c5a86")
const C_WORM := Color("#b8f4de")

var _new_ticks: Array[Callable] = []
## id -> {tube, s, node}: for debug_view("new:<id>").
var _new_spots: Dictionary = {}
## Unique subject ids, in _new_defs order (kind, kind@2, ...).
var _new_ids: Array[String] = []


func _plan_new_subjects() -> void:
	var seen := {}
	for d: Array in _new_defs():
		var kind := str(d[0])
		seen[kind] = int(seen.get(kind, 0)) + 1
		_new_ids.append(kind if int(seen[kind]) == 1 else "%s@%d" % [kind, int(seen[kind])])
		var t := _tube(str(d[1]))
		var s := float(d[2])
		var side := float(d[3])
		var a := t.at(s)
		var q: Vector3 = (a["p"] as Vector3) + (a["side"] as Vector3) * t.wall_x(int(a["i"]), 0.0) * 0.6 * side
		match kind:
			"glow_caps":
				_tint(q + Vector3.UP * 0.4, C_TEAL_LIGHT.lerp(C_LILAC, 0.35), 3.4, 0.7)
			"pulse_crystals":
				_tint(q + Vector3.UP * 0.9, C_TEAL_LIGHT, 4.2, 0.8)
			"drip_pool":
				_tint(q + Vector3.UP * 0.3, C_AQUA, 3.0, 0.6)
			"lantern_worms", "sleepy_bats":
				_tint((a["p"] as Vector3) + Vector3.UP * (float(a["h"]) + 0.2), C_WORM if kind == "lantern_worms" else C_LILAC, 3.4, 0.6)
			"geode":
				_tint(_wall_point(t, s, side, 1.0), C_DOWN_LIGHT, 3.2, 0.8)
			"rainbow_spire":
				_tint(q + Vector3.UP * 1.3, C_DOWN_LIGHT, 3.6, 0.6)
				_tint(q + Vector3.UP * 0.3, C_TEAL_LIGHT, 2.6, 0.4)


func _build_new_subjects() -> void:
	var defs := _new_defs()
	for i in defs.size():
		var d: Array = defs[i]
		var id := _new_ids[i]
		var t := _tube(str(d[1]))
		var s := float(d[2])
		var side := float(d[3])
		var node: Node3D
		match str(d[0]):
			"glow_caps":
				node = _build_caps(id, t, s, side)
			"pulse_crystals":
				node = _build_pulse(id, t, s, side)
			"drip_pool":
				node = _build_drip(id, t, s, side)
			"peek_mole":
				node = _build_mole(id, t, s, side)
			"lantern_worms":
				node = _build_worms(id, t, s)
			"sleepy_bats":
				node = _build_bats(id, t, s)
			"geode":
				node = _build_geode(id, t, s, side)
			"rainbow_spire":
				node = _build_spire(id, t, s, side)
		_new_spots[id] = {"t": t, "s": s, "node": node}


## A basis whose +Y is `dir` (a gem grows along +Y).
static func _basis_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(x, y, x.cross(y).normalized())


func _seeded(id: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(id) & 0x7fffffff
	return r


## A roof point over path length s (the tube's own noised ellipse top), local and unwarped.
func _roof(t: Tube, s: float) -> Vector3:
	var i := t.idx_at(s)
	var e := t.ell(i)
	return _wall_point(t, s, 1.0, e.x + e.y - 0.001)


## A plain vertex-colour material whose albedo_color the tick pulses (it only darkens: authored bright).
func _pulse_mat() -> StandardMaterial3D:
	var m := _mat.duplicate() as StandardMaterial3D
	m.albedo_color = Color(0.8, 0.8, 0.8)
	return m


# ------------------------------------------------------------------------------ GLOW CAPS
## A patch of glowing mushrooms at the foot of the wall; now and then they puff a cloud of glow spores.
func _build_caps(id: String, t: Tube, s: float, side: float) -> Node3D:
	var rng := _seeded(id)
	var f := _floor_spot(t, s, 0.72 * side)
	var node := _node("GlowCaps_" + id, X(f["q"], f["t"]))
	var sk := Kit.new()
	_shadow(sk, Vector3.ZERO, 0.62, 0.5, 0.22)
	_mi(node, sk, "Shadow")
	var caps := _node("Caps", Transform3D(), node)
	var k := Kit.new()
	var tops: Array[Vector3] = []
	for i in 7:
		var a := rng.randf() * TAU
		var r := 0.0 if i == 0 else rng.randf_range(0.14, 0.46)
		var base := Vector3(cos(a) * r, 0.0, sin(a) * r * 0.8)
		var hgt := rng.randf_range(0.13, 0.26) * (1.7 if i == 0 else 1.0)
		var cr := hgt * rng.randf_range(0.6, 0.85)
		var lean := Vector3(rng.randf_range(-0.04, 0.04), 0.0, rng.randf_range(-0.04, 0.04))
		k.blob(base + Vector3(0, hgt * 0.5, 0) + lean * 0.5, Vector3(cr * 0.2, hgt * 0.52, cr * 0.2), C_CAP_STEM, 0.4, 2, 6)
		var col := C_TEAL if i % 3 != 1 else C_LILAC.lerp(C_TEAL, 0.25)
		var top := base + lean + Vector3(0, hgt, 0)
		# the underside: a darker gilled disc
		for q in 8:
			var a0 := TAU * float(q) / 8.0
			var a1 := TAU * float(q + 1) / 8.0
			k.tri(top + Vector3(0, -0.005, 0), top + Vector3(cos(a1) * cr, -0.01, sin(a1) * cr),
				top + Vector3(cos(a0) * cr, -0.01, sin(a0) * cr), col.darkened(0.35), 0.4)
		k.blob(top, Vector3(cr, cr * 0.55, cr), col.lightened(0.12), 0.85, 4, 8, Basis(), 0.0, true)
		for q in 3:
			var aa := rng.randf() * TAU
			var rr := cr * rng.randf_range(0.3, 0.7)
			k.blob(top + Vector3(cos(aa) * rr, cr * 0.5 * sqrt(1.0 - pow(rr / cr, 2.0)), sin(aa) * rr),
				Vector3(cr * 0.14, cr * 0.06, cr * 0.14), Color("#f4fbf8"), 1.0, 2, 5)
		tops.append(top)
	_mi(caps, k, "Mesh")
	var spores: Array[Node3D] = []
	for j in 8:
		var mk := Kit.new()
		mk.blob(Vector3.ZERO, Vector3(0.03, 0.03, 0.03), C_TEAL_LIGHT.lightened(0.3), 1.0, 2, 4)
		var sp := _node("Spore%d" % j, Transform3D(), node)
		_mi(sp, mk, "Mesh")
		sp.visible = false
		spores.append(sp)
	var ph := rng.randf_range(0.0, 8.0)
	var puff := func(tt: float) -> float:
		var c := fmod(tt + ph, 8.0)
		return -1.0 if c < 5.0 else (c - 5.0) / 3.0
	_new_ticks.append(func(tt: float) -> void:
		var b := sin(tt * 1.3 + ph)
		caps.scale = Vector3(1.0 + 0.03 * b, 1.0 - 0.04 * b, 1.0 + 0.03 * b)
		var u: float = puff.call(tt)
		for j in spores.size():
			var sp := spores[j]
			sp.visible = u >= 0.0
			if u >= 0.0:
				var o: Vector3 = tops[j % tops.size()]
				var a := float(j) * 2.4 + tt * 0.6
				sp.position = o + Vector3(cos(a) * 0.12 * u, 0.1 + 1.1 * u, sin(a) * 0.12 * u)
				sp.scale = Vector3.ONE * (0.6 + 0.8 * sin(u * PI)))
	safari.add_subject({"id": id, "name": NEW_NAMES["glow_caps"], "tier": "sight", "kind": "sight", "node": node,
		"offset": Vector3(0, 0.22, 0), "radius": 0.5, "band": Vector2(0.15, 0.6),
		"moment": func(tt: float) -> Dictionary:
			var u: float = puff.call(tt)
			return {"mult": 1.6, "line": "puffing glow spores!"} if u > 0.1 and u < 0.8 else {"mult": 1.0, "line": ""}})
	return node


# ------------------------------------------------------------------------------ PULSE CRYSTALS
## A tall teal formation that glows up bright and fades, slowly, like breathing.
func _build_pulse(id: String, t: Tube, s: float, side: float) -> Node3D:
	var rng := _seeded(id)
	var f := _floor_spot(t, s, 0.6 * side)
	var node := _node("PulseCrystals_" + id, X(f["q"], f["t"]))
	var bk := Kit.new()
	_rubble(bk, rng, 0.62, 7)
	_mi(node, bk, "Base")
	var k := Kit.new()
	_cluster(k, rng, 9, 0.6, 1.5, 0.5, C_TEAL.lightened(0.12), 1.0, false)
	var mat := _pulse_mat()
	var mi := _mi(node, k, "Crystals")
	mi.material_override = mat
	_body_cyl(node, 0.5, 1.6)
	var ph := rng.randf_range(0.0, 4.5)
	var glow := func(tt: float) -> float:
		var c := fmod(tt + ph, 4.5)
		return exp(-pow((c - 1.2) / 0.7, 2.0))
	_new_ticks.append(func(tt: float) -> void:
		var g: float = glow.call(tt)
		var v := lerpf(0.66, 1.0, g)
		mat.albedo_color = Color(v, v, v))
	safari.add_subject({"id": id, "name": NEW_NAMES["pulse_crystals"], "tier": "sight", "kind": "sight", "node": node,
		"offset": Vector3(0, 0.7, 0), "radius": 0.8, "band": Vector2(0.25, 0.8),
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 1.6, "line": "glowing bright!"} if float(glow.call(tt)) > 0.7 else {"mult": 1.0, "line": ""}})
	return node


# ------------------------------------------------------------------------------ DRIP POOL
## A stalactite drips a glowing drop into a small pool now and then; rings spread where it lands.
func _build_drip(id: String, t: Tube, s: float, side: float) -> Node3D:
	var rng := _seeded(id)
	var i := t.idx_at(s)
	var e := t.ell(i)
	var frac := 0.6
	var top := _wall_point(t, s, side, e.x + e.y * sqrt(1.0 - frac * frac))
	var floor_y := t.pts[i].y
	var q := Vector3(top.x, floor_y, top.z)
	var a := t.at(s)
	var node := _node("DripPool_" + id, X(q, a["t"]))
	var k := Kit.new()
	var rx := 0.8
	var rz := 0.6
	for j in 14:
		var a0 := TAU * float(j) / 14.0
		var a1 := TAU * float(j + 1) / 14.0
		k.tri(Vector3(0, 0.035, 0), Vector3(cos(a1) * rx, 0.035, sin(a1) * rz), Vector3(cos(a0) * rx, 0.035, sin(a0) * rz),
			Color("#7fd6cf"), 0.6)
		k.blob(Vector3(cos(a0) * (rx + 0.08), 0.04, sin(a0) * (rz + 0.08)), Vector3(0.11, 0.07, 0.09), C_WALL.darkened(0.1), 0.0, 3, 5)
	for j in 3:
		var aa := rng.randf() * TAU
		k.gem(Transform3D(Basis(Vector3(-sin(aa), 0, cos(aa)), 0.4), Vector3(cos(aa) * rx * 1.05, 0.0, sin(aa) * rz * 1.05)),
			0.05, rng.randf_range(0.2, 0.35), C_TEAL, 0.8)
	_mi(node, k, "Pool")
	# the stalactite, hanging from the roof right over the pool (it starts 0.3 m up inside the rock)
	var drop_len := (top.y - floor_y) - 0.95
	var sk := Kit.new()
	sk.gem(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, drop_len + 1.25, 0)), 0.16, 1.25, C_CEIL.lightened(0.05), 0.0)
	sk.gem(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, drop_len + 0.3, 0)), 0.05, 0.3, C_TEAL, 0.9)
	_mi(node, sk, "Stalactite")
	var drop := _node("Drop", Transform3D(), node)
	var dk := Kit.new()
	dk.blob(Vector3.ZERO, Vector3(0.045, 0.06, 0.045), C_TEAL_LIGHT.lightened(0.25), 1.0, 3, 6)
	_mi(drop, dk, "Mesh")
	var ring := _node("Ripple", Transform3D(), node)
	var rk := Kit.new()
	for j in 16:
		var a0 := TAU * float(j) / 16.0
		var a1 := TAU * float(j + 1) / 16.0
		rk.quad(Vector3(cos(a0) * 0.9, 0.045, sin(a0) * 0.9), Vector3(cos(a1) * 0.9, 0.045, sin(a1) * 0.9),
			Vector3(cos(a1), 0.045, sin(a1)), Vector3(cos(a0), 0.045, sin(a0)), Color("#e6fbf6"), 1.0)
	_mi(ring, rk, "Mesh")
	ring.visible = false
	var cyc := 3.2
	var fall := sqrt(2.0 * maxf(drop_len, 0.1) / 9.8)
	var ph := rng.randf_range(0.0, cyc)
	_new_ticks.append(func(tt: float) -> void:
		var c := fmod(tt + ph, cyc)
		var grow_t := cyc - 1.0
		if c < grow_t:
			# the drop swells at the tip
			drop.visible = c > grow_t - 1.2
			drop.position = Vector3(0, drop_len, 0)
			drop.scale = Vector3.ONE * clampf((c - (grow_t - 1.2)) / 1.2, 0.05, 1.0)
		elif c < grow_t + fall:
			var u := c - grow_t
			drop.visible = true
			drop.scale = Vector3.ONE
			drop.position = Vector3(0, drop_len - 0.5 * 9.8 * u * u, 0)
		else:
			drop.visible = false
		var sp := fmod(tt + ph - grow_t - fall + cyc * 4.0, cyc)
		ring.visible = sp < 0.9
		if ring.visible:
			var r := lerpf(0.08, 0.55, sp / 0.9)
			ring.scale = Vector3(r, 1.0, r * 0.8))
	safari.add_subject({"id": id, "name": NEW_NAMES["drip_pool"], "tier": "sight", "kind": "sight", "node": node,
		"offset": Vector3(0, 0.4, 0), "radius": 0.75, "band": Vector2(0.2, 0.7),
		"moment": func(tt: float) -> Dictionary:
			var sp := fmod(tt + ph - (cyc - 1.0) - fall + cyc * 4.0, cyc)
			return {"mult": 1.5, "line": "a drop just splashed!"} if sp < 0.7 else {"mult": 1.0, "line": ""}})
	return node


# ------------------------------------------------------------------------------ PEEK MOLE
## A round little mole with a crystal on its head. It hides in its burrow and pops up to look at you
## when you come near; it ducks back now and then and pops up again.
func _build_mole(id: String, t: Tube, s: float, side: float) -> Node3D:
	var f := _floor_spot(t, s, 0.55 * side)
	var home: Vector3 = f["q"]
	var burrow := _node("Burrow_" + id, X(home, f["t"]))
	var bk := Kit.new()
	var rng := _seeded(id)
	for j in 12:
		var a0 := TAU * float(j) / 12.0
		var a1 := TAU * float(j + 1) / 12.0
		bk.tri(Vector3(0, 0.03, 0), Vector3(cos(a1) * 0.2, 0.03, sin(a1) * 0.2), Vector3(cos(a0) * 0.2, 0.03, sin(a0) * 0.2),
			Color("#3a2b22"), 0.0)
	for j in 9:
		var a := TAU * float(j) / 9.0 + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(0.26, 0.33)
		bk.blob(Vector3(cos(a) * r, 0.03, sin(a) * r), Vector3(0.1, 0.07, 0.09), C_FLOOR.darkened(0.22), 0.0, 3, 5, Basis(Vector3.UP, a))
	_mi(burrow, bk, "Mesh")
	var mole := _node("PeekMole_" + id, X(home), null)
	var body := _node("Body", Transform3D(), mole)
	var k := Kit.new()
	k.blob(Vector3(0, 0.0, 0), Vector3(0.17, 0.2, 0.16), C_FUR, 0.0, 4, 8)
	k.blob(Vector3(0, -0.02, -0.1), Vector3(0.11, 0.13, 0.07), C_FUR.lightened(0.3), 0.1, 3, 7)
	k.blob(Vector3(0, 0.05, -0.17), Vector3(0.045, 0.035, 0.035), C_NOSE, 0.2, 3, 6)
	for sx in [-1.0, 1.0]:
		var sg := float(sx)
		k.blob(Vector3(0.06 * sg, 0.1, -0.13), Vector3(0.018, 0.02, 0.012), C_EYE, 0.0, 3, 5)
		k.blob(Vector3(0.056 * sg, 0.108, -0.141), Vector3(0.006, 0.006, 0.004), Color.WHITE, 1.0, 2, 4)
		k.blob(Vector3(0.1 * sg, 0.06, -0.12), Vector3(0.02, 0.012, 0.008), Color("#f2b6c4"), 0.2, 2, 5)
		# two pink paws resting on the rim
		k.blob(Vector3(0.09 * sg, -0.13, -0.14), Vector3(0.045, 0.025, 0.04), Color("#f0c2cc"), 0.1, 2, 6)
	k.gem(Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(0.0, 0.17, 0.02)), 0.035, 0.14, C_TEAL, 0.9)
	k.gem(Transform3D(Basis(Vector3.FORWARD, 0.5), Vector3(0.04, 0.16, 0.05)), 0.022, 0.08, C_TEAL.lightened(0.2), 0.9)
	_mi(body, k, "Mesh")
	var out_k := [0.0]
	var clock := [0.0]
	var last_t := [0.0]
	_new_ticks.append(func(tt: float) -> void:
		var dt := clampf(tt - float(last_t[0]), 0.0, 0.1)
		last_t[0] = tt
		var near := false
		if safari.player != null:
			near = safari.player.global_position.distance_to(_world(home)) < 10.0
		var want := 0.0
		if near:
			clock[0] = float(clock[0]) + dt
			want = 1.0 if fmod(float(clock[0]), 8.5) < 6.0 else 0.0
		else:
			clock[0] = 0.0
		out_k[0] = move_toward(float(out_k[0]), want, dt * (3.5 if want > 0.5 else 2.5))
		var o := float(out_k[0])
		mole.visible = o > 0.02
		var pop := sin(minf(o, 1.0) * PI * 0.5)
		var p := home + Vector3.UP * lerpf(-0.3, 0.2, pop)
		var face := -(f["t"] as Vector3)
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if cam != null:
			var tc := _unwarp(cave.global_transform.affine_inverse() * cam.global_position) - p
			tc.y = 0.0
			if tc.length_squared() > 1e-4:
				face = tc.normalized()
		mole.transform = X(p, face, 1.0)
		body.rotation = Vector3(0, 0, 0.12 * sin(tt * 2.3) * o))
	safari.add_subject({"id": id, "name": NEW_NAMES["peek_mole"], "tier": "creature", "kind": "creature", "node": mole,
		"offset": Vector3(0, 0.05, 0), "radius": 0.22, "band": Vector2(0.12, 0.45),
		"awake": func() -> bool: return float(out_k[0]) > 0.5,
		"front": SafariWorld.front_of(mole, Vector3(0, 0, -1)),
		"moment": func(_tt: float) -> Dictionary:
			return {"mult": 1.8, "line": "peeking out at you!"} if float(out_k[0]) > 0.95 else {"mult": 1.0, "line": ""}})
	return mole


# ------------------------------------------------------------------------------ LANTERN WORMS
## Glowing threads hanging from the roof, beaded with light; a shimmer runs down them now and then.
func _build_worms(id: String, t: Tube, s: float) -> Node3D:
	var rng := _seeded(id)
	var a := t.at(s)
	var i := int(a["i"])
	var e := t.ell(i)
	var w := t.ws[i]
	var roof := _roof(t, s)
	var node := _node("LanternWorms_" + id, X(Vector3(roof.x, t.pts[i].y, roof.z), a["t"]))
	var mat := _pulse_mat()
	var groups: Array[Node3D] = []
	var lowest := INF
	for g in 3:
		var gn := _node("Group%d" % g, Transform3D(), node)
		var k := Kit.new()
		for j in 4:
			var x := rng.randf_range(-0.75, 0.75)
			var z := rng.randf_range(-0.6, 0.6) + (float(g) - 1.0) * 0.5
			var qx := clampf(x / w, -0.95, 0.95)
			var ceil_y := e.x + e.y * sqrt(1.0 - qx * qx) + (roof.y - t.pts[i].y - (e.x + e.y)) + 0.3
			var ln := rng.randf_range(0.7, 1.6)
			var bot := ceil_y - ln
			lowest = minf(lowest, bot)
			for side_a in [0.0, PI * 0.5]:
				var dx := Vector3(cos(float(side_a)), 0.0, sin(float(side_a))) * 0.008
				k.quad(Vector3(x, ceil_y, z) - dx, Vector3(x, ceil_y, z) + dx, Vector3(x, bot, z) + dx, Vector3(x, bot, z) - dx, C_WORM.darkened(0.2), 0.6)
			var beads := rng.randi_range(4, 6)
			for b in beads:
				var u := float(b + 1) / float(beads)
				var r := lerpf(0.018, 0.04, u)
				k.blob(Vector3(x, lerpf(ceil_y - 0.3, bot, u), z), Vector3(r, r * 1.3, r), C_WORM.lerp(C_TEAL_LIGHT, u), 1.0, 2, 5)
		var mi := _mi(gn, k, "Mesh")
		mi.material_override = mat
		groups.append(gn)
	var ph := rng.randf_range(0.0, 7.0)
	var shimmer := func(tt: float) -> float:
		var c := fmod(tt + ph, 7.0)
		return exp(-pow((c - 2.0) / 0.8, 2.0))
	_new_ticks.append(func(tt: float) -> void:
		var v := lerpf(0.72, 1.0, float(shimmer.call(tt)))
		mat.albedo_color = Color(v, v, v)
		for g in groups.size():
			groups[g].rotation = Vector3(0.025 * sin(tt * 0.7 + float(g) * 1.9), 0, 0.03 * sin(tt * 0.55 + float(g) * 2.7)))
	safari.add_subject({"id": id, "name": NEW_NAMES["lantern_worms"], "tier": "sight", "kind": "sight", "node": node,
		"offset": Vector3(0, lowest + 0.45, 0), "radius": 0.8, "band": Vector2(0.2, 0.7),
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 1.5, "line": "shimmering!"} if float(shimmer.call(tt)) > 0.6 else {"mult": 1.0, "line": ""}})
	return node


# ------------------------------------------------------------------------------ SLEEPY BATS
## Four round bats asleep upside down under the roof; every so often one stretches its wings and blinks.
func _build_bats(id: String, t: Tube, s: float) -> Node3D:
	var a := t.at(s)
	var i := int(a["i"])
	var roof := _roof(t, s)
	# faces (-Z) toward the way you come in
	var node := _node("SleepyBats_" + id, X(Vector3(roof.x, t.pts[i].y, roof.z), -(a["t"] as Vector3)))
	var top_y := roof.y - t.pts[i].y
	var bats: Array[Dictionary] = []
	for b in 4:
		var x := (float(b) - 1.5) * 0.36
		var z := 0.12 * sin(float(b) * 2.1)
		var hang := top_y - 0.4 - 0.08 * float(b % 2)
		var bn := _node("Bat%d" % b, Transform3D(Basis().scaled(Vector3.ONE * 1.4), Vector3(x * 1.35, hang, z)), node)
		var k := Kit.new()
		# upside down: feet up at the roof, head down
		k.quad(Vector3(-0.012, 0.3, 0), Vector3(0.012, 0.3, 0), Vector3(0.012, 0.1, 0), Vector3(-0.012, 0.1, 0), C_WING, 0.0)
		k.blob(Vector3(0, 0.0, 0), Vector3(0.12, 0.13, 0.11), C_BAT, 0.0, 4, 8)
		k.blob(Vector3(0, -0.02, -0.07), Vector3(0.075, 0.08, 0.05), C_BAT.lightened(0.25), 0.1, 3, 6)
		for sx in [-1.0, 1.0]:
			var sg := float(sx)
			# ears point DOWN (the bat hangs upside down)
			k.tri(Vector3(0.04 * sg, -0.1, -0.02), Vector3(0.1 * sg, -0.2, -0.02), Vector3(0.08 * sg, -0.08, 0.0), C_BAT.darkened(0.1), 0.0)
			k.blob(Vector3(0.1 * sg, 0.02, 0.0), Vector3(0.05, 0.11, 0.07), C_WING, 0.0, 3, 6)
			k.blob(Vector3(0.1 * sg, 0.02, 0.0), Vector3(0.05, 0.11, 0.07), C_WING, 0.0, 3, 6)
		_mi(bn, k, "Body")
		var closed := Kit.new()
		for sx in [-1.0, 1.0]:
			closed.blob(Vector3(0.04 * float(sx), -0.03, -0.108), Vector3(0.022, 0.006, 0.006), C_EYE, 0.0, 2, 5)
		var cn := _node("Closed", Transform3D(), bn)
		_mi(cn, closed, "Mesh")
		var opn := Kit.new()
		for sx in [-1.0, 1.0]:
			opn.blob(Vector3(0.04 * float(sx), -0.03, -0.105), Vector3(0.018, 0.02, 0.01), C_EYE, 0.0, 3, 5)
			opn.blob(Vector3(0.036 * float(sx), -0.04, -0.115), Vector3(0.005, 0.005, 0.003), Color.WHITE, 1.0, 2, 4)
		var on := _node("Open", Transform3D(), bn)
		_mi(on, opn, "Mesh")
		on.visible = false
		var wings: Array[Node3D] = []
		for sx in [-1.0, 1.0]:
			var sg := float(sx)
			var hinge := _node("Wing", Transform3D(Basis(), Vector3(0.09 * sg, 0.06, 0.0)), bn)
			var wk := Kit.new()
			var rim := [Vector3(0, 0.02, 0), Vector3(0.14 * sg, 0.06, 0), Vector3(0.26 * sg, 0.0, 0), Vector3(0.22 * sg, -0.1, 0),
				Vector3(0.12 * sg, -0.07, 0), Vector3(0.04 * sg, -0.12, 0)]
			for q in rim.size() - 1:
				wk.tri(Vector3.ZERO, rim[q], rim[q + 1], C_WING.lerp(C_LILAC, 0.25 * float(q % 2)), 0.1)
			_mi(hinge, wk, "Mesh")
			hinge.visible = false
			wings.append(hinge)
		bats.append({"n": bn, "closed": cn, "open": on, "wings": wings})
	var stretch := func(tt: float) -> Vector2:
		# (which bat, how far into its stretch 0..1) or x = -1 when none
		var c := fmod(tt, 10.0)
		if c < 6.0 or c > 9.0:
			return Vector2(-1.0, 0.0)
		return Vector2(float(int(tt / 10.0) % 4), (c - 6.0) / 3.0)
	_new_ticks.append(func(tt: float) -> void:
		var st: Vector2 = stretch.call(tt)
		for b in bats.size():
			var bd: Dictionary = bats[b]
			var bn: Node3D = bd["n"]
			var on := int(st.x) == b
			var k := sin(st.y * PI) if on else 0.0
			bn.rotation = Vector3(0.06 * sin(tt * 0.8 + float(b) * 1.7), 0, 0.05 * sin(tt * 0.6 + float(b)))
			bn.scale = Vector3.ONE * 1.4
			(bd["open"] as Node3D).visible = on and k > 0.3
			(bd["closed"] as Node3D).visible = not (bd["open"] as Node3D).visible
			var wings: Array[Node3D] = bd["wings"]
			for wi in wings.size():
				var sg := -1.0 if wi == 0 else 1.0
				wings[wi].visible = k > 0.05
				wings[wi].rotation = Vector3(0, sg * (1.0 - k) * 1.3, 0))
	safari.add_subject({"id": id, "name": NEW_NAMES["sleepy_bats"], "tier": "creature", "kind": "creature", "node": node,
		"offset": Vector3(0, top_y - 0.5, 0), "radius": 0.8, "band": Vector2(0.18, 0.65),
		"moment": func(tt: float) -> Dictionary:
			var st: Vector2 = stretch.call(tt)
			return {"mult": 1.9, "line": "one is stretching its wings!"} if st.x >= 0.0 and st.y > 0.2 and st.y < 0.8 \
				else {"mult": 1.0, "line": ""}})
	return node


# ------------------------------------------------------------------------------ RAINBOW GEODE
## A round stone split open in the wall, lined with rainbow crystal points round a glowing heart.
func _build_geode(id: String, t: Tube, s: float, side: float) -> Node3D:
	var rng := _seeded(id)
	var y := 0.95
	var a := t.at(s)
	var du := _wall_point(t, s, side, y + 0.3) - _wall_point(t, s, side, y - 0.3)
	var ds := _wall_point(t, s + 0.3, side, y) - _wall_point(t, s - 0.3, side, y)
	var inward: Vector3 = ds.cross(du).normalized()
	if inward.dot(-(a["side"] as Vector3) * side) < 0.0:
		inward = -inward
	var wall_p: Vector3 = _wall_point(t, s, side, y) + inward * 0.16
	var k := Kit.new()
	var rr := 0.6
	# the hollow, set back into the wall: a deep violet with its own soft glow
	for j in 14:
		var a0 := TAU * float(j) / 14.0
		var a1 := TAU * float(j + 1) / 14.0
		k.tri(Vector3(0, 0, 0.16), Vector3(cos(a1) * rr, sin(a1) * rr * 0.85, 0.02), Vector3(cos(a0) * rr, sin(a0) * rr * 0.85, 0.02),
			Color("#6d5596"), 0.6)
	# the broken shell: a pale crystalline band inside a rough brown rim
	for j in 18:
		var a0 := TAU * float(j) / 18.0
		var a1 := TAU * float(j + 1) / 18.0
		var o0 := Vector3(cos(a0) * (rr + 0.1), sin(a0) * (rr + 0.1) * 0.85, -0.03)
		var o1 := Vector3(cos(a1) * (rr + 0.1), sin(a1) * (rr + 0.1) * 0.85, -0.03)
		var i0 := Vector3(cos(a0) * rr, sin(a0) * rr * 0.85, 0.0)
		var i1 := Vector3(cos(a1) * rr, sin(a1) * rr * 0.85, 0.0)
		k.quad(o0, o1, i1, i0, Color("#efe6f4"), 0.7)
	for j in 15:
		var ang := TAU * float(j) / 15.0 + rng.randf_range(-0.1, 0.1)
		k.blob(Vector3(cos(ang) * (rr + 0.17), sin(ang) * (rr + 0.17) * 0.85, 0.0), Vector3(0.12, 0.1, 0.09),
			C_WALL.darkened(rng.randf_range(0.05, 0.2)), 0.0, 3, 5, Basis(Vector3.BACK, ang))
	# the lining: rainbow points pointing in toward the heart
	k.iri = rng.randf()
	k.iri_span = 1.0
	k.iri_s = 0.5
	for j in 60:
		var ang := rng.randf() * TAU
		var r := rr * sqrt(rng.randf_range(0.15, 0.95))
		var base := Vector3(cos(ang) * r, sin(ang) * r * 0.85, 0.12 - 0.1 * (r / rr))
		var to_c := (Vector3(0, 0, -0.05) - base).normalized()
		k.gem(Transform3D(_basis_y(to_c), base), 0.03, rng.randf_range(0.09, 0.2), Color.WHITE, 0.8)
	k.iri = -1.0
	k.blob(Vector3(0, 0, 0.04), Vector3(0.13, 0.12, 0.07), Color("#fbeefe"), 1.0, 3, 6)
	var up_here := (W(wall_p) + Vector3(0, R, 0)).normalized()
	var node := _node("Geode_" + id, Transform3D(Basis.looking_at(inward, up_here), W(wall_p)))
	_mi(node, k, "Mesh")
	var sparks: Array[Node3D] = []
	for j in 5:
		var sk := Kit.new()
		sk.blob(Vector3.ZERO, Vector3(0.02, 0.02, 0.02), Color.WHITE, 1.0, 2, 4)
		var sp := _node("Spark%d" % j, Transform3D(Basis(), Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.25, 0.25), -0.05)), node)
		_mi(sp, sk, "Mesh")
		sparks.append(sp)
	_new_ticks.append(func(tt: float) -> void:
		for j in sparks.size():
			var tw := maxf(sin(tt * 2.2 + float(j) * 1.9), 0.0)
			sparks[j].scale = Vector3.ONE * (0.2 + 1.2 * tw * tw))
	var inw := inward
	safari.add_subject({"id": id, "name": NEW_NAMES["geode"], "tier": "uncommon", "kind": "sight", "node": node,
		"radius": 0.65, "band": Vector2(0.15, 0.6),
		"front": func() -> Vector3: return (cave.global_transform.basis * inw).normalized()})
	return node


# ------------------------------------------------------------------------------ RAINBOW SPIRE
## One tall prismatic crystal on the climb, its light a soft rainbow, motes spiralling up round it.
func _build_spire(id: String, t: Tube, s: float, side: float) -> Node3D:
	var rng := _seeded(id)
	var f := _floor_spot(t, s, 0.6 * side)
	var node := _node("RainbowSpire_" + id, X(f["q"], f["t"]))
	var k := Kit.new()
	_rubble(k, rng, 0.58, 7)
	k.iri = 0.0
	k.iri_span = 1.2
	k.iri_s = 0.5
	k.gem(Transform3D(Basis(Vector3(1, 0, 0.3).normalized(), 0.14), Vector3(0, -0.1, 0)), 0.2, 2.3, Color.WHITE, 0.75)
	for j in 5:
		var aa := TAU * float(j) / 5.0 + rng.randf_range(-0.3, 0.3)
		var off := Vector3(cos(aa), 0, sin(aa)) * rng.randf_range(0.25, 0.42)
		var h := rng.randf_range(0.4, 0.95)
		k.gem(Transform3D(Basis(Vector3(-sin(aa), 0, cos(aa)), rng.randf_range(0.35, 0.7)), off - Vector3(0, 0.12, 0)), h * 0.18, h, Color.WHITE, 0.7)
	k.iri = -1.0
	_mi(node, k, "Mesh")
	_body_cyl(node, 0.42, 2.3)
	var motes: Array[Node3D] = []
	for j in 7:
		var mk := Kit.new()
		mk.iri = float(j) / 7.0
		mk.blob(Vector3.ZERO, Vector3(0.035, 0.035, 0.035), Color.WHITE, 1.0, 2, 4)
		var mn := _node("Mote%d" % j, Transform3D(), node)
		_mi(mn, mk, "Mesh")
		motes.append(mn)
	_new_ticks.append(func(tt: float) -> void:
		for j in motes.size():
			var ph := fmod(tt * 0.12 + float(j) / float(motes.size()), 1.0)
			var ang := TAU * float(j) / float(motes.size()) + tt * 0.5
			motes[j].position = Vector3(cos(ang) * 0.5, 0.3 + 2.2 * ph, sin(ang) * 0.5)
			motes[j].scale = Vector3.ONE * sin(ph * PI))
	safari.add_subject({"id": id, "name": NEW_NAMES["rainbow_spire"], "tier": "uncommon", "kind": "sight", "node": node,
		"offset": Vector3(0, 1.1, 0), "radius": 1.0, "band": Vector2(0.3, 0.9)})
	return node


# ============================================================================== MOMENTS AND AWAKE
func _moth_moment(t: float) -> Dictionary:
	return {"mult": 1.9, "line": "resting on a crystal!"} if _moth_resting(t) else {"mult": 1.0, "line": ""}


func _snail_moment(t: float) -> Dictionary:
	return {"mult": 1.7, "line": "stretching up tall!"} if _snail_stretch(t) > 0.7 else {"mult": 1.0, "line": ""}


func _newt_awake() -> bool:
	return _newt.visible


func _newt_moment(t: float) -> Dictionary:
	var c := fmod(t, NEWT_CYCLE)
	return {"mult": 1.8, "line": "looking right at you!"} if c > 5.3 and c < 9.8 else {"mult": 1.0, "line": ""}


func _beetle_moment(t: float) -> Dictionary:
	return {"mult": 2.1, "line": "wings open!"} if _beetle_open(t) > 0.7 else {"mult": 1.0, "line": ""}


func _jelly_moment(t: float) -> Dictionary:
	return {"mult": 1.6, "line": "all pulsing at once!"} if _jelly_pulse(t, 1) > 0.5 else {"mult": 1.0, "line": ""}


func _ray_awake() -> bool:
	return _ray_t(safari.elapsed) >= 1.0 and _ray_t(safari.elapsed) <= RAY_LEN - 1.0


func _ray_moment(t: float) -> Dictionary:
	return {"mult": 2.2, "line": "swooping low!"} if _ray_low(t) else {"mult": 1.0, "line": ""}


func _bloom_awake() -> bool:
	return _bloom_k(safari.elapsed) > 0.05


func _bloom_moment(t: float) -> Dictionary:
	return {"mult": 2.0, "line": "in full bloom!"} if _bloom_k(t) > 0.8 else {"mult": 1.0, "line": ""}


func _dance_awake() -> bool:
	return _dance_k(safari.elapsed) > 0.1


func _dance_moment(t: float) -> Dictionary:
	return {"mult": 2.1, "line": "all five together!"} if _dance_k(t) > 0.85 else {"mult": 1.0, "line": ""}


func _fossil_front() -> Vector3:
	return (cave.global_transform.basis * _fossil_inward).normalized()


# ============================================================================== TICK
func tick(t: float, _delta: float) -> void:
	_tick_moth(t)
	_tick_snail(t)
	_tick_beetle(t)
	_tick_motes(t)
	_tick_newt(t)
	_tick_chest(t)
	_tick_bloom(t)
	_tick_dance(t)
	_tick_jellies(t)
	_tick_ray(t)
	for f: Callable in _new_ticks:
		f.call(t)


## Leaving: nothing puffs or hides - the cave just fades out (CaveVisit).
func go_to_sleep() -> bool:
	return true


# ============================================================================== FOR TESTS
## A standing view (world transform + pitch in degrees) of a named place: landing, moth, snail, newt,
## beetle, jellies, ray, bloom, dance, fossil, chamber, chamber_wide, chest, loft_room; the forks (fork1,
## fork2, fork3: from just before, both ways in view); and each branch looking along itself so its slope
## or curve shows (down, up, chamberway, grotto, treasureway, loftway).
func debug_view(nm: String) -> Dictionary:
	var stand := Vector3.ZERO
	var look := Vector3.ZERO
	var s1 := trunk.s_of(_mk["trunk:fork1"])
	var s2 := trunk.s_of(_mk["trunk:fork2"])
	var s3 := upway.s_of(_mk["upway:fork3"])
	if nm.begins_with("new:") and _new_spots.has(nm.substr(4)):
		var sp: Dictionary = _new_spots[nm.substr(4)]
		var t: Tube = sp["t"]
		var sub: Dictionary = safari._subjects.get("cave:" + nm.substr(4), {})
		stand = t.at(float(sp["s"]) - 4.0)["p"]
		var tgt := (sp["node"] as Node3D).global_transform * (sub.get("offset", Vector3.ZERO) as Vector3)
		look = _unwarp(cave.global_transform.affine_inverse() * tgt)
	match nm:
		"landing":
			var a := trunk.at(1.6)
			stand = a["p"]
			look = (a["p"] as Vector3) + (a["t"] as Vector3) * 5.0 + Vector3.UP * 1.0
		"fork1", "fork2", "fork3":
			var par: Tube = upway if nm == "fork3" else trunk
			var ch: Tube = {"fork1": upway, "fork2": grotto, "fork3": loft}[nm]
			var sf: float = {"fork1": s1, "fork2": s2, "fork3": s3}[nm]
			stand = par.at(sf - 5.0)["p"]
			look = ((par.at(sf + 6.0)["p"] as Vector3) + (ch.at(6.0)["p"] as Vector3)) * 0.5 + Vector3.UP * 1.0
		"down", "chamberway":
			var s0 := s1 + 6.0 if nm == "down" else s2 + 3.0
			stand = trunk.at(s0)["p"]
			look = (trunk.at(s0 + 11.0)["p"] as Vector3) + Vector3.UP * 1.1
		"up", "treasureway":
			var s0 := 6.0 if nm == "up" else s3 + 3.0
			stand = upway.at(s0)["p"]
			look = (upway.at(s0 + 11.0)["p"] as Vector3) + Vector3.UP * 1.1
		"grotto":
			stand = grotto.at(3.0)["p"]
			look = (grotto.at(12.0)["p"] as Vector3) + Vector3.UP * 1.0
		"wall", "floor":
			# U1CAVE: close to the right wall on the slope past FORK 1, looking along it (wall) or at
			# its foot, where the floor meets the rock (floor)
			var sw := s1 + (9.0 if nm == "wall" else 14.0)
			var a := trunk.at(sw)
			stand = (a["p"] as Vector3) + (a["side"] as Vector3) * (trunk.wall_x(int(a["i"]), 0.0) * (0.5 if nm == "wall" else 0.1))
			look = _wall_point(trunk, sw + (4.0 if nm == "wall" else 2.5), 1.0, 1.3 if nm == "wall" else 0.05)
		"loftway":
			stand = loft.at(3.0)["p"]
			look = (loft.at(13.0)["p"] as Vector3) + Vector3.UP * 1.1
		"chamber":
			var a := trunk.at(trunk.s_of(_mk["trunk:chamber"]) - 10.0)
			stand = a["p"]
			look = _chamber_c + _chamber_t * 4.0 + Vector3.UP * 3.5
		"chamber_wide":
			stand = _chamber_c - _chamber_t * 4.5 + _chamber_side * 4.5
			look = _chamber_c + _chamber_t * 3.0 - _chamber_side * 3.0 + Vector3.UP * 2.6
		"chest":
			var a := upway.at(upway.total - 5.6)
			stand = a["p"]
			look = _chest_local + Vector3.UP * 0.35
		"beetle":
			var a := grotto.at(grotto.total - 4.4)
			stand = a["p"]
			look = _beetle_rest + Vector3.UP * 0.05
		"newt":
			var sn := upway.s_of(_mk["upway:newt"]) - 10.0
			stand = _newt_home + _newt_out * 2.3 + upway.tans[upway.idx_at(sn)] * 0.8
			stand.y = upway.pts[upway.idx_at(sn)].y
			look = _newt_home + _newt_out * 0.6
		"fossil":
			var sf := upway.s_of(_mk["upway:fossil"]) + 0.5
			var a := upway.at(sf)
			stand = (a["p"] as Vector3) + (a["side"] as Vector3) * 1.2 - (a["t"] as Vector3) * 0.6
			look = _wall_point(upway, sf, -1.0, 1.25)
		"jellies", "loft_room":
			stand = loft.at(loft.s_of(_mk["loft:loft"]) - 5.0)["p"]
			look = _unwarp(cave.global_transform.affine_inverse() * _jellies.global_position) if nm == "jellies" \
				else _loft_c + Vector3.UP * 3.0
		"ray":
			stand = _chamber_c - _chamber_t * 5.0 - _chamber_side * 2.0
			look = _unwarp(cave.global_transform.affine_inverse() * _ray.global_position)
		"moth":
			var a := trunk.at(MOTH_S - 3.7)
			stand = a["p"]
			look = _moth_perch
		"snail":
			var ss := trunk.s_of(_mk["trunk:slope"])
			stand = _snail_a + (_snail_b - _snail_a) * 0.2 - trunk.sides[trunk.idx_at(ss)] * -2.2
			stand.y = trunk.pts[trunk.idx_at(ss)].y
			look = _unwarp(cave.global_transform.affine_inverse() * _snail.global_position)
		"bloom":
			stand = _chamber_c + _chamber_side * 1.5
			look = _chamber_c + _chamber_side * 6.0 + _chamber_t * 1.5 + Vector3.UP * 1.0
		"dance":
			stand = _chamber_c - _chamber_side * 1.0 - _chamber_t * 3.0
			look = _pool_centre + Vector3.UP * 1.6
		"crystals":
			# close up on the first big (low) wall cluster down the slope past FORK 1
			for c: Dictionary in _crystals:
				if c["t"] == trunk and float(c["s"]) > s1 + 4.0 and bool(c["big"]):
					var a := trunk.at(float(c["s"]) - 1.8)
					stand = (a["p"] as Vector3) - (a["side"] as Vector3) * float(c["side"]) * 0.5
					look = (c["p"] as Vector3) + Vector3.UP * 0.3
					break
	var fwd := look - stand
	var eye_y := stand.y + 1.1
	var hz := Vector2(fwd.x, fwd.z).length()
	return {"xf": cave.global_transform * X(stand + Vector3.UP * 0.1, fwd), "pitch": rad_to_deg(atan2(look.y - eye_y, maxf(hz, 0.01)))}


## Warped cave-local -> unwarped cave-local (the inverse of W).
func _unwarp(q: Vector3) -> Vector3:
	var r := (q + Vector3(0.0, R, 0.0))
	var len_r := r.length()
	var dir := r / len_r
	var flat := dir * (R / maxf(dir.y, 1e-4))
	return Vector3(flat.x, len_r - R, flat.z)


## The four routes, each [tube, from s, to s] legs from the landing to its end: "chamber" (to the middle
## of the chamber), "grotto" (to the beetle's perch), "chest" (to reaching distance of the chest) and
## "loft" (to the middle of the jelly loft).
const ROUTES: Array[String] = ["chamber", "grotto", "chest", "loft"]

func _route_legs(target: String) -> Array:
	var s1 := trunk.s_of(_mk["trunk:fork1"])
	var s2 := trunk.s_of(_mk["trunk:fork2"])
	var s3 := upway.s_of(_mk["upway:fork3"])
	match target:
		"chamber":
			return [[trunk, 1.6, trunk.s_of(_mk["trunk:chamber"])]]
		"grotto":
			return [[trunk, 1.6, s2], [grotto, 1.0, grotto.total - 3.6]]
		"chest":
			return [[trunk, 1.6, s1], [upway, 1.0, upway.total - 3.4]]
		"loft":
			return [[trunk, 1.6, s1], [upway, 1.0, s3], [loft, 1.0, loft.s_of(_mk["loft:loft"])]]
	return []


## World points along the floor (lifted 0.1 m), about 1 m apart, for a synthetic walk of a route.
func debug_route(target: String) -> PackedVector3Array:
	var out := PackedVector3Array()
	for leg: Array in _route_legs(target):
		var t: Tube = leg[0]
		var s: float = leg[1]
		while s < float(leg[2]):
			out.append(_world((t.at(s)["p"] as Vector3) + Vector3.UP * 0.1))
			s += 1.0
		out.append(_world((t.at(float(leg[2]))["p"] as Vector3) + Vector3.UP * 0.1))
	return out


## Its centreline length in metres (the walk's floor distance, slopes included).
func debug_route_len(target: String) -> float:
	var pts := debug_route(target)
	var d := 0.0
	for i in range(1, pts.size()):
		d += pts[i].distance_to(pts[i - 1])
	return d


## Per tube: [length m, rise m from start to end, turn deg from start to end (+ left)] - the numbers
## behind "slopes down", "climbs", "curves left/right".
func debug_branch_shapes() -> Dictionary:
	var out := {}
	var spans := {"down": [trunk, trunk.s_of(_mk["trunk:fork1"]), trunk.s_of(_mk["trunk:fork2"])],
		"chamberway": [trunk, trunk.s_of(_mk["trunk:fork2"]), trunk.s_of(_mk["trunk:chamber"])],
		"grotto": [grotto, 0.0, grotto.total],
		"up": [upway, 0.0, upway.s_of(_mk["upway:fork3"])],
		"treasureway": [upway, upway.s_of(_mk["upway:fork3"]), upway.total],
		"loftway": [loft, 0.0, loft.total]}
	for k: String in spans:
		var sp: Array = spans[k]
		var t: Tube = sp[0]
		var a := t.at(float(sp[1]) + 0.5)
		var b := t.at(float(sp[2]) - 0.5)
		var ta: Vector3 = a["t"]
		var tb: Vector3 = b["t"]
		var turn := rad_to_deg(atan2(ta.cross(tb).y, ta.dot(tb)))
		out[k] = [snappedf(float(sp[2]) - float(sp[1]), 0.1), snappedf((b["p"] as Vector3).y - (a["p"] as Vector3).y, 0.1),
			snappedf(turn, 1.0)]
	return out


## Path metres of the named marks along each tube, and each tube's length (for placing and reports).
func debug_marks() -> Dictionary:
	var out := {}
	for k: String in _mk:
		var tid := k.get_slice(":", 0)
		out[k] = snappedf(_tube(tid).s_of(int(_mk[k])), 0.1)
	for t: Tube in _tubes:
		out[t.id + ":total"] = snappedf(t.total, 0.1)
	return out


func debug_new_ids() -> Array[String]:
	return _new_ids


func debug_chest_world() -> Vector3:
	return _world(_chest_local)


func debug_chest_state() -> int:
	return _chest_state
