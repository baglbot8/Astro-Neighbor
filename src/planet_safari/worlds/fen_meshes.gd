extends RefCounted
## THE SHAPES OF FEN'S SAFARI (docs/PLANET_SAFARI_SPEC.md 12.2, builder FEN). Static builders only:
## every creature and event prop is ONE vertex-coloured ArrayMesh made with PlanetMeshKit, drawn with
## materials Fen's own world already draws with (PlanetPropMeshes.prop_material for everything solid,
## the shipped puff material for the see-through light sheets and ripple rings, the shipped star glow
## for halos). Parts that move on their own (a frog's throat, a flower's petals, the heron's wings)
## are separate meshes posed by code; a herd of any of them is one MultiMesh per part (safari_herd.gd).
##
## Conventions (PlanetMeshKit's): prop-local, +Y up, origin at the ground contact (or, for a flier,
## its middle), the creature faces -Z. Colours are sRGB hex inside docs/STYLE_GUIDE.md's gates: no
## large swatch above S 0.60 (the one copper frill is a small accent), nothing whiter than V 0.92.
## Fen's world is a warm terracotta pan under an amber sky (fen.tres), so the creatures separate by
## HUE: sage frogs, slate-blue lizards (Fen's own skin, fen_model.gd SKIN), dark violet swifts (the
## flight's own tower-swift tint, safari_catalog.gd), a pale stone heron, and the glow moths' own
## peach-gold (catch_game.gd FLAVOURS "moth"). Cute and structured: flat bases, soft domes, and the
## same small dark eyes the neighbours have (the house eye).
##
## Built once per process and cached here (a second safari reuses them).

const EYE := Color("#1e2130")
const EYE_HI := Color("#e6e2ea")
## Pool-frog: a round sage frog with a pale throat.
const FROG := Color("#8a9c74")        # S 0.26 V 0.61
const FROG_DARK := Color("#6d7e5c")
const FROG_BELLY := Color("#d6cfb8")  # V 0.84
const THROAT := Color("#e2d7bd")      # the croak sac, V 0.89
## Ruin-lizard: Fen's own slate blue with a copper frill and a pale belly.
const LIZ := Color("#7c8fae")         # S 0.29 V 0.68
const LIZ_DARK := Color("#61718d")
const LIZ_BELLY := Color("#cfcbbf")
const FRILL := Color("#c08a64")       # S 0.48 V 0.75 (a small accent)
## Mist-wisp: a pale puff with a hint of teal (the pools' own water, fen.tres water_color).
const WISP := Color("#dcdcd2")        # S 0.05 V 0.86
const WISP_TAIL := Color("#bdd0cd")
## Glow-moth (catch_game.gd FLAVOURS "moth").
const MOTH_BODY := Color("#b8a27c")
const MOTH_WING := Color("#ecddb4")   # V 0.93: small wings
const MOTH_WING_EDGE := Color("#d8c296")
## Tower swift (safari_catalog.gd tower_swifts tint_a / tint_b).
const SWIFT := Color("#6a6189")       # S 0.29 V 0.54 (safari_catalog tint_a #6a5f8c)
const SWIFT_DARK := Color("#524b6c")
const SWIFT_CHEST := Color("#cdb6a0")  # a pale buff throat (tint_b #ffcf96, muted: S 0.22)
## Little pool fish.
const FISH := Color("#c99a72")        # S 0.43 V 0.79
const FISH_FIN := Color("#e0c4a4")
## The stone heron: pale stone grey, slate wings, an ochre beak.
const HERON := Color("#b2aea6")       # S 0.07 V 0.70
const HERON_WING := Color("#8d95a4")  # S 0.14 V 0.64
const HERON_WING_TIP := Color("#666d7c")
const HERON_LEG := Color("#7a6f63")
const BEAK := Color("#c9a26a")        # S 0.47 V 0.79
## Fen's vine and its flowers (Fen's own vine colours, fen_vine_model.gd VINE; the planet's own flower
## colours, fen.tres flower_colors).
const VINE := Color("#6f8783")
const LEAF := Color("#7f9a8a")
const PETAL_A := Color("#d9b8a0")     # S 0.26 V 0.85
const PETAL_B := Color("#cfe0dd")     # S 0.08 V 0.88
const FLOWER_EYE := Color("#b98d76")

static var _cache: Dictionary = {}


static func _cached(key: String, build: Callable) -> ArrayMesh:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


## Two small dark oval eyes with a highlight dot (the house eye).
static func _eyes(kit: PlanetMeshKit, centre: Vector3, spacing: float, r: float, fwd: Vector3 = Vector3(0, 0, -1)) -> void:
	var side := Vector3.UP.cross(fwd).normalized()
	for sgn in [-1.0, 1.0]:
		var c: Vector3 = centre + side * spacing * 0.5 * sgn
		kit.sphere(c, r, EYE, Vector3(0.75, 1.0, 0.6), 10)
		kit.sphere(c + fwd * r * 0.45 + Vector3(0.0, r * 0.35, 0.0) + side * r * 0.25, r * 0.28, EYE_HI, Vector3.ONE, 6)


static func _limb(kit: PlanetMeshKit, a: Vector3, b: Vector3, r: float, c: Color, segs: int = 8) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var y := d / l
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	kit.cylinder(a, r, r * 0.9, l, c, Basis(x, y, z), segs)
	kit.sphere(b, r * 1.05, c, Vector3.ONE, segs)


# ============================================================================================ POOL-FROG
## A round little frog, ~0.3 m wide and 0.24 m tall, big eye bumps on top, facing -Z.
static func frog() -> ArrayMesh:
	return _cached("frog", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.11, 0.02), 0.15, FROG, Vector3(1.05, 0.72, 1.12), 18)
		kit.sphere(Vector3(0.0, 0.075, -0.05), 0.11, FROG_BELLY, Vector3(0.95, 0.62, 0.8), 14)
		for sgn in [-1.0, 1.0]:
			# folded back legs and wide flat feet
			kit.sphere(Vector3(0.12 * sgn, 0.07, 0.08), 0.07, FROG_DARK, Vector3(0.85, 0.7, 1.35), 10)
			kit.sphere(Vector3(0.14 * sgn, 0.015, 0.0), 0.055, FROG_DARK, Vector3(1.1, 0.3, 1.5), 10)
			kit.sphere(Vector3(0.07 * sgn, 0.015, -0.13), 0.032, FROG_DARK, Vector3(1.1, 0.4, 1.3), 8)
			# the eye bumps
			kit.sphere(Vector3(0.065 * sgn, 0.2, -0.07), 0.052, FROG, Vector3.ONE, 12)
		_eyes(kit, Vector3(0.0, 0.205, -0.112), 0.13, 0.03)
		# a small closed smile
		kit.sphere(Vector3(0.0, 0.12, -0.155), 0.05, FROG_DARK, Vector3(1.4, 0.12, 0.3), 8)
		return kit.commit())


## The croak sac under the chin; code scales it up for a croak.
static func frog_throat() -> ArrayMesh:
	return _cached("frog_throat", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.0, 0.0), 0.06, THROAT, Vector3(1.1, 0.8, 1.0), 12)
		return kit.commit())
## Where the throat sits on the frog (frog-local).
const FROG_THROAT_AT := Vector3(0.0, 0.085, -0.13)


# ============================================================================================ RUIN-LIZARD
## A slate-blue lizard lying flat, ~0.6 m nose to tail, the head at -Z, a copper frill behind the head
## and the tail curling round at +Z. ~0.1 m tall.
static func lizard() -> ArrayMesh:
	return _cached("lizard", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# body
		kit.sphere(Vector3(0.0, 0.06, 0.02), 0.1, LIZ, Vector3(0.95, 0.55, 1.7), 16)
		kit.sphere(Vector3(0.0, 0.045, 0.01), 0.085, LIZ_BELLY, Vector3(0.9, 0.45, 1.6), 12)
		# a darker stripe down the back
		for k in 4:
			kit.sphere(Vector3(0.0, 0.11, -0.06 + 0.05 * float(k)), 0.03, LIZ_DARK, Vector3(1.2, 0.35, 1.0), 8)
		# head
		kit.sphere(Vector3(0.0, 0.075, -0.19), 0.075, LIZ, Vector3(1.0, 0.8, 1.2), 14)
		kit.sphere(Vector3(0.0, 0.06, -0.255), 0.045, LIZ, Vector3(1.1, 0.7, 1.0), 10)
		_eyes(kit, Vector3(0.0, 0.1, -0.24), 0.1, 0.022)
		# the frill: a fan of rounded copper plates round the neck
		for k in 7:
			var a := lerpf(-1.25, 1.25, float(k) / 6.0)
			var c := Vector3(sin(a) * 0.085, 0.085 + cos(a) * 0.04, -0.14)
			kit.sphere(c, 0.034, FRILL if k % 2 == 0 else FRILL.darkened(0.1), Vector3(1.0, 1.0, 0.35), 8)
		# legs: four little splayed legs
		for sz in [-0.1, 0.1]:
			for sgn in [-1.0, 1.0]:
				_limb(kit, Vector3(0.07 * sgn, 0.04, sz), Vector3(0.15 * sgn, 0.012, sz - 0.03), 0.018, LIZ_DARK, 6)
		# tail: tapering and curling round to one side
		var pts := [Vector3(0.0, 0.05, 0.16), Vector3(0.02, 0.035, 0.26), Vector3(0.07, 0.025, 0.33),
			Vector3(0.13, 0.02, 0.35), Vector3(0.17, 0.018, 0.31)]
		for i in range(1, pts.size()):
			_limb(kit, pts[i - 1], pts[i], 0.045 - 0.008 * float(i), LIZ if i % 2 == 1 else LIZ_DARK, 8)
		return kit.commit())


# ============================================================================================ MIST-WISP
## A small soft puff with a trailing wisp and two dark eyes, origin at its middle, ~0.3 m across. Its
## light is a glow sprite posed on it by code.
static func wisp() -> ArrayMesh:
	return _cached("wisp", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.0, 0.0), 0.13, WISP, Vector3(1.0, 0.95, 1.0), 16)
		kit.sphere(Vector3(0.0, -0.02, 0.1), 0.085, WISP_TAIL, Vector3(0.9, 0.8, 1.2), 12)
		kit.sphere(Vector3(0.02, -0.04, 0.2), 0.05, WISP_TAIL, Vector3(0.9, 0.8, 1.3), 10)
		kit.sphere(Vector3(0.05, -0.06, 0.27), 0.028, WISP_TAIL, Vector3.ONE, 8)
		_eyes(kit, Vector3(0.0, 0.02, -0.118), 0.085, 0.022)
		return kit.commit())


# ============================================================================================ GLOW-MOTH
## A small moth, ~0.26 m across the wings, facing -Z, origin at its middle.
static func moth() -> ArrayMesh:
	return _cached("moth", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.0, 0.0), 0.035, MOTH_BODY, Vector3(0.9, 0.9, 1.9), 10)
		kit.sphere(Vector3(0.0, 0.01, -0.055), 0.028, MOTH_BODY, Vector3.ONE, 8)
		_eyes(kit, Vector3(0.0, 0.015, -0.078), 0.03, 0.009)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.075 * sgn, 0.012, -0.01), 0.07, MOTH_WING, Vector3(1.0, 0.12, 0.8), 10)
			kit.sphere(Vector3(0.065 * sgn, 0.008, 0.055), 0.05, MOTH_WING_EDGE, Vector3(1.0, 0.12, 0.8), 8)
			# two feathery feelers
			_limb(kit, Vector3(0.01 * sgn, 0.025, -0.075), Vector3(0.04 * sgn, 0.06, -0.12), 0.005, MOTH_BODY, 4)
		return kit.commit())


# ============================================================================================ TOWER SWIFT
## A dark swift gliding, ~0.4 m across its crescent wings, a forked tail, facing -Z, origin at its
## middle.
static func swift() -> ArrayMesh:
	return _cached("swift", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# a slim teardrop body, a round head, a pale throat
		kit.sphere(Vector3(0.0, 0.0, 0.01), 0.045, SWIFT, Vector3(0.85, 0.75, 2.0), 12)
		kit.sphere(Vector3(0.0, 0.006, -0.08), 0.033, SWIFT, Vector3.ONE, 10)
		kit.sphere(Vector3(0.0, -0.012, -0.075), 0.022, SWIFT_CHEST, Vector3(0.9, 0.7, 1.0), 8)
		_eyes(kit, Vector3(0.0, 0.014, -0.106), 0.034, 0.009)
		for sgn in [-1.0, 1.0]:
			# a long swept crescent: six flattened lobes along a curve, tapering and sweeping back
			for k in 6:
				var t := float(k) / 5.0
				var c := Vector3(sgn * (0.03 + 0.21 * t), 0.004, -0.02 + 0.11 * t * t)
				kit.sphere(c, 0.042 - 0.024 * t, SWIFT if k < 3 else SWIFT_DARK, Vector3(1.5, 0.16, 0.85), 8)
			# the forked tail: two slim prongs
			_limb(kit, Vector3(0.01 * sgn, 0.0, 0.08), Vector3(0.04 * sgn, 0.0, 0.17), 0.012, SWIFT_DARK, 6)
		return kit.commit())


# ============================================================================================ POOL FISH
## A little round fish, ~0.2 m, facing -Z, origin at its middle.
static func fish() -> ArrayMesh:
	return _cached("fish", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.0, 0.0), 0.06, FISH, Vector3(0.7, 0.95, 1.4), 12)
		kit.sphere(Vector3(0.0, 0.03, 0.02), 0.03, FISH_FIN, Vector3(0.25, 1.2, 1.2), 8)
		kit.sphere(Vector3(0.0, 0.0, 0.1), 0.04, FISH_FIN, Vector3(0.2, 1.2, 0.8), 8)
		_eyes(kit, Vector3(0.0, 0.012, -0.06), 0.06, 0.012)
		return kit.commit())


## A thin flat ring of radius 1 (scaled by code), pale water-teal and half see-through, for the puff
## material (vertex alpha).
static func ripple_ring() -> ArrayMesh:
	return _cached("ripple_ring", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.torus(Vector3.ZERO, 1.0, 0.035, Color(0.86, 0.95, 0.93, 0.55), Basis.from_scale(Vector3(1.0, 0.25, 1.0)), 32)
		return kit.commit())


# ============================================================================================ STONE HERON
## The heron standing: long legs, a round body, an S-curved neck, a dagger beak and a dark crest.
## ~1.45 m tall, facing -Z. The wings are separate (heron_wing), rooted at HERON_SHOULDER.
static func heron_body() -> ArrayMesh:
	return _cached("heron_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for sgn in [-1.0, 1.0]:
			_limb(kit, Vector3(0.06 * sgn, 0.0, 0.0), Vector3(0.065 * sgn, 0.36, 0.02), 0.018, HERON_LEG, 6)
			_limb(kit, Vector3(0.065 * sgn, 0.36, 0.02), Vector3(0.06 * sgn, 0.68, 0.06), 0.02, HERON_LEG, 6)
			# three long toes
			for a in [-0.5, 0.0, 0.5]:
				_limb(kit, Vector3(0.06 * sgn, 0.012, 0.0), Vector3(0.06 * sgn + sin(a) * 0.11, 0.008, -cos(a) * 0.11), 0.01, HERON_LEG, 4)
		# body: a soft egg leaning forward
		kit.sphere(Vector3(0.0, 0.84, 0.04), 0.2, HERON, Vector3(0.85, 0.85, 1.35), 18, Basis(Vector3.RIGHT, 0.35))
		kit.sphere(Vector3(0.0, 0.8, -0.07), 0.15, HERON.lightened(0.08), Vector3(0.8, 0.9, 1.0), 14)
		# neck: an S of tapering segments
		var neck := [Vector3(0.0, 0.92, -0.14), Vector3(0.0, 1.06, -0.12), Vector3(0.0, 1.18, -0.04),
			Vector3(0.0, 1.3, -0.06), Vector3(0.0, 1.38, -0.13)]
		for i in range(1, neck.size()):
			_limb(kit, neck[i - 1], neck[i], 0.055 - 0.006 * float(i), HERON.lightened(0.04), 10)
		# head, eyes, beak, crest
		kit.sphere(Vector3(0.0, 1.4, -0.16), 0.065, HERON.lightened(0.06), Vector3(0.9, 0.9, 1.15), 14)
		_eyes(kit, Vector3(0.0, 1.425, -0.2), 0.085, 0.017)
		kit.cylinder(Vector3(0.0, 1.39, -0.2), 0.022, 0.004, 0.22, BEAK, Basis(Vector3.RIGHT, -PI * 0.5 - 0.12), 8)
		_limb(kit, Vector3(0.0, 1.45, -0.13), Vector3(0.0, 1.47, 0.02), 0.012, HERON_WING_TIP, 6)
		_limb(kit, Vector3(0.0, 1.47, 0.02), Vector3(0.0, 1.44, 0.1), 0.009, HERON_WING_TIP, 6)
		# the tail: a short fan
		kit.sphere(Vector3(0.0, 0.8, 0.3), 0.09, HERON_WING, Vector3(0.9, 0.3, 1.4), 10)
		return kit.commit())

const HERON_SHOULDER := Vector3(0.14, 0.94, -0.02)


## One wing SPREAD, rooted at the origin and reaching out along +X * sgn (about 0.85 m); code folds it
## back along the body (a turn about +Y and a shorter span) and spreads it for a landing or a stretch.
static func heron_wing(sgn: float) -> ArrayMesh:
	return _cached("heron_wing_%d" % int(sgn), func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for k in 4:
			var c := Vector3(sgn * (0.1 + 0.21 * float(k)), -0.01 * float(k), 0.05 * float(k))
			kit.sphere(c, 0.14 - 0.016 * float(k), HERON_WING if k < 3 else HERON_WING_TIP, Vector3(1.35, 0.16, 1.25), 10)
		return kit.commit())


# ============================================================================================ FEN'S VINE
## A climbing vine on Fen's arch, in the ARCH'S OWN (unscaled) frame: planet_props.gd `_resonator_arch`
## (legs at x = +-0.95 up to y 2.2, a half-circle span of radius 0.95 over them, the arch in the XY
## plane). The vine winds up the left leg, over the span and a little way down the right, with leaves;
## the flowers are posed along it by code at `vine_points`.
static func vine() -> ArrayMesh:
	return _cached("fen_vine", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var pts := vine_path()
		for i in range(1, pts.size()):
			_limb(kit, pts[i - 1], pts[i], 0.028, VINE, 6)
		var rng := RandomNumberGenerator.new()
		rng.seed = 612
		for i in range(1, pts.size() - 1):
			if i % 2 == 0:
				continue
			var p: Vector3 = pts[i]
			var side := 1.0 if i % 4 == 1 else -1.0
			var out := Vector3(0.0, 0.0, 0.12 * side) + Vector3(rng.randf_range(-0.05, 0.05), 0.0, 0.0)
			kit.sphere(p + out, 0.075, LEAF if i % 3 else LEAF.darkened(0.12), Vector3(1.2, 0.25, 0.8), 8,
				Basis(Vector3.RIGHT, 0.6 * side))
		return kit.commit())


## The vine's centre line (arch frame): up the left leg's face, over the span, down the right a way.
static func vine_path() -> Array:
	var out: Array = []
	var leg := 0.95
	var face := 0.19
	for k in 9:
		var y := 0.1 + 2.1 * float(k) / 8.0
		out.append(Vector3(-leg + 0.06 * sin(float(k) * 1.7), y, face * (1.0 if k % 2 == 0 else -1.0)))
	for k in range(1, 12):
		var a := PI * (1.0 - float(k) / 11.0)
		var r := 0.95 + 0.14
		out.append(Vector3(cos(a) * r, 2.2 + sin(a) * r, face * (1.0 if k % 2 == 0 else -1.0)))
	for k in range(1, 5):
		var y := 2.2 - 0.35 * float(k)
		out.append(Vector3(leg + 0.06 * sin(float(k) * 2.1), y, face * (1.0 if k % 2 == 0 else -1.0)))
	return out


## One flower, facing +Y (its root at the origin): five round petals and a warm eye. A closed bud is the
## same mesh scaled small by code, and the petals open by scaling out.
static func flower(variant: int) -> ArrayMesh:
	return _cached("fen_flower_%d" % variant, func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var pc := PETAL_A if variant == 0 else PETAL_B
		for k in 5:
			var a := TAU * float(k) / 5.0
			kit.sphere(Vector3(cos(a) * 0.075, 0.02, sin(a) * 0.075), 0.06, pc, Vector3(1.0, 0.22, 0.75), 10,
				Basis(Vector3.UP, -a))
		kit.sphere(Vector3(0.0, 0.035, 0.0), 0.035, FLOWER_EYE, Vector3(1.0, 0.6, 1.0), 10)
		return kit.commit())


# ============================================================================================ THE ARCH LIGHT
## The light filling the arch's opening (arch frame, unscaled): a see-through warm sheet, brightest in
## the middle and fading to nothing at the legs and the span, for the puff material (vertex alpha).
static func arch_sheet(colour: Color) -> ArrayMesh:
	return _cached("arch_sheet|" + colour.to_html(), func() -> ArrayMesh:
		var inner := 0.95 - 0.16
		var nx := 12
		var ny := 8
		var grid: Array = []
		for iy in ny + 1:
			var row: Array = []
			for ix in nx + 1:
				var x := lerpf(-inner, inner, float(ix) / float(nx))
				var top := 2.2 + sqrt(maxf(inner * inner - x * x, 0.0))
				var y := top * float(iy) / float(ny)
				var ex := clampf((1.0 - absf(x) / inner) * 1.8, 0.0, 1.0)
				var ey := clampf((top - y) / 0.8, 0.0, 1.0) * clampf(y / 0.45, 0.0, 1.0)
				row.append([Vector3(x, y, 0.0), Color(colour.r, colour.g, colour.b, 0.55 * ex * ey)])
			grid.append(row)
		return sheet_from_grid(grid))


## A double-sided mesh from a grid of [position, colour] rows (sRGB colours with alpha), normals +Z.
static func sheet_from_grid(grid: Array) -> ArrayMesh:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var rows := grid.size()
	var cols := (grid[0] as Array).size()
	for side in 2:
		var base := v.size()
		for r in rows:
			for k in cols:
				var cell: Array = grid[r][k]
				v.append(cell[0])
				var lc := (cell[1] as Color).srgb_to_linear()
				lc.a = (cell[1] as Color).a
				c.append(lc)
				n.append(Vector3(0.0, 0.0, 1.0 if side == 0 else -1.0))
		for r in rows - 1:
			for k in cols - 1:
				var a := base + r * cols + k
				var b := a + 1
				var d := a + cols
				var e := d + 1
				if side == 0:
					idx.append_array(PackedInt32Array([a, d, b, b, d, e]))
				else:
					idx.append_array(PackedInt32Array([a, b, d, b, e, d]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_COLOR] = c
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# ============================================================================================ BONUS (spec 15.5)
# The three collector's pages: small, still, hidden in plain sight. Stone in Fen's own rock colour
# (fen.tres rock_color #9c9186), the planet's own flower colours for the crown, the pools' teal for glass.
const CARVE := Color("#b0a597")       # the fish's raised face, a shade paler than the stone (S 0.14 V 0.69)
const CARVE_GROOVE := Color("#7c7268") # the cut round it and the lines on it (S 0.16 V 0.49)
const STATUE := Color("#a69c91")      # S 0.13 V 0.65
const STATUE_DARK := Color("#877d73")
const MOSS := Color("#7f8c6c")        # a little moss on its back (S 0.23 V 0.55)
const CROWN_C := Color("#b98d76")     # fen.tres flower_colors[2] (S 0.36 V 0.73)
const GLASS := Color(0.62, 0.78, 0.76, 0.42)     # the pools' own teal, see-through
const GLASS_HI := Color(0.86, 0.92, 0.90, 0.62)  # a highlight streak along the glass (V 0.92)
const SCROLL := Color("#e2d5b6")      # V 0.89
## The low warm sun roughly doubles saturation on the toon material: an authored cork at S 0.42 rendered
## at S 0.79 on the phone renderer (bottle_note_zoom, c2fen_out/shots2). So both accents are muted here.
const RIBBON := Color("#7c8fae")      # Fen's own slate blue (S 0.29 V 0.68), cool against the warm pan
const CORK := Color("#8f8170")        # S 0.22 V 0.56


## A FISH CARVED INTO A COLUMN: a low relief ~0.34 m nose to tail in the XY plane, sticking out toward
## -Z by ~3 cm, its nose at -X, origin at its middle on the stone's face.
static func fish_carving() -> ArrayMesh:
	return _cached("fen_fish_carving", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# the cut round it: a dark flat oval just proud of the face, a little bigger than the fish
		kit.sphere(Vector3(0.01, 0.0, 0.0), 0.12, CARVE_GROOVE, Vector3(1.35, 0.72, 0.1), 16)
		kit.sphere(Vector3(0.155, 0.0, 0.0), 0.075, CARVE_GROOVE, Vector3(0.6, 1.05, 0.1), 10)
		# the body
		kit.sphere(Vector3(-0.01, 0.0, -0.008), 0.11, CARVE, Vector3(1.3, 0.62, 0.2), 16)
		# the tail: two lobes fanning back
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.16, 0.035 * sgn, -0.006), 0.05, CARVE, Vector3(0.75, 0.55, 0.2), 10,
				Basis(Vector3(0, 0, 1), 0.55 * sgn))
		# a fin on the back and one under
		kit.sphere(Vector3(0.0, 0.066, -0.006), 0.035, CARVE, Vector3(1.4, 0.5, 0.2), 8)
		kit.sphere(Vector3(0.03, -0.062, -0.006), 0.025, CARVE, Vector3(1.3, 0.5, 0.2), 8)
		# the eye, the gill line and three scale arcs, cut in
		kit.sphere(Vector3(-0.09, 0.018, -0.03), 0.014, CARVE_GROOVE, Vector3(1.0, 1.0, 0.5), 8)
		kit.sphere(Vector3(-0.055, 0.0, -0.028), 0.05, CARVE_GROOVE, Vector3(0.08, 0.9, 0.2), 8)
		for k in 3:
			kit.sphere(Vector3(-0.005 + 0.04 * float(k), 0.0, -0.027), 0.036, CARVE_GROOVE, Vector3(0.07, 0.75, 0.2), 8)
		# a little smile
		kit.sphere(Vector3(-0.128, -0.012, -0.026), 0.012, CARVE_GROOVE, Vector3(1.4, 0.4, 0.5), 6)
		return kit.commit())


## A FROG STATUE IN A FLOWER CROWN: a stone frog ~0.42 m wide on a low round plinth, facing -Z, a ring of
## the planet's own flowers on its head. Origin at the plinth's foot. ~0.42 m tall with the crown. Two
## meshes: the stone (drawn with the standing stones' own rock material, so it reads as carved stone, not
## a pale frog) and the crown (the matte prop material, so the flowers are not mottled like rock).
const STATUE_CROWN_AT := Vector3(0.0, 0.08 + 0.265 * 1.35, 0.0)


static func frog_statue() -> ArrayMesh:
	return _cached("fen_frog_statue", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.cylinder(Vector3.ZERO, 0.22, 0.2, 0.08, STATUE_DARK, Basis.IDENTITY, 14)
		var o := Vector3(0.0, 0.08, 0.0)
		var s := 1.35
		kit.sphere(o + Vector3(0.0, 0.11, 0.02) * s, 0.15 * s, STATUE, Vector3(1.05, 0.72, 1.12), 18)
		kit.sphere(o + Vector3(0.0, 0.075, -0.05) * s, 0.11 * s, STATUE.lightened(0.06), Vector3(0.95, 0.62, 0.8), 14)
		kit.sphere(o + Vector3(0.03, 0.2, 0.09) * s, 0.06 * s, MOSS, Vector3(1.3, 0.35, 1.0), 10)
		for sgn in [-1.0, 1.0]:
			kit.sphere(o + Vector3(0.12 * sgn, 0.07, 0.08) * s, 0.07 * s, STATUE_DARK, Vector3(0.85, 0.7, 1.35), 10)
			kit.sphere(o + Vector3(0.14 * sgn, 0.015, 0.0) * s, 0.055 * s, STATUE_DARK, Vector3(1.1, 0.3, 1.5), 10)
			kit.sphere(o + Vector3(0.07 * sgn, 0.015, -0.13) * s, 0.032 * s, STATUE_DARK, Vector3(1.1, 0.4, 1.3), 8)
			kit.sphere(o + Vector3(0.065 * sgn, 0.2, -0.07) * s, 0.052 * s, STATUE, Vector3.ONE, 12)
			# stone eyes: closed, a calm curved lid line
			kit.sphere(o + Vector3(0.065 * sgn, 0.215, -0.118) * s, 0.026 * s, STATUE_DARK, Vector3(1.2, 0.35, 0.5), 8)
		kit.sphere(o + Vector3(0.0, 0.12, -0.155) * s, 0.05 * s, STATUE_DARK, Vector3(1.4, 0.12, 0.3), 8)
		return kit.commit())


## The statue's crown: seven small flowers and leaves in a ring round the top of its head, behind the
## eyes, in the statue's own frame.
static func frog_statue_crown() -> ArrayMesh:
	return _cached("fen_frog_statue_crown", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var cc := STATUE_CROWN_AT
		var cols := [Color("#d9b8a0"), Color("#cfe0dd"), CROWN_C]
		for k in 7:
			var a := TAU * float(k) / 7.0 + 0.2
			var p := cc + Vector3(cos(a) * 0.105, 0.0, sin(a) * 0.09 + 0.02)
			kit.sphere(p + Vector3(cos(a + 0.45) * 0.03, -0.01, sin(a + 0.45) * 0.03), 0.022, Color("#7f9a8a"),
				Vector3(1.6, 0.35, 0.8), 6, Basis(Vector3.UP, -a))
			var fc: Color = cols[k % 3]
			for q in 5:
				var b := TAU * float(q) / 5.0
				kit.sphere(p + Vector3(cos(b) * 0.018, 0.012, sin(b) * 0.018), 0.016, fc, Vector3(1.0, 0.45, 1.0), 6)
			kit.sphere(p + Vector3(0.0, 0.02, 0.0), 0.011, Color("#c9a26a"), Vector3.ONE, 6)
		return kit.commit())


## A MESSAGE IN A BOTTLE, floating on its side along X (the neck at -X), origin at its middle, ~0.3 m
## long. Two meshes: the see-through glass (the puff material: vertex alpha, unshaded) and what is solid
## - the rolled note tied with a ribbon inside, and the cork.
static func bottle_glass() -> ArrayMesh:
	return _cached("fen_bottle_glass", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.03, 0.0, 0.0), 0.075, GLASS, Vector3(1.55, 1.0, 1.0), 16)
		kit.cylinder(Vector3(-0.07, 0.0, 0.0), 0.05, 0.026, 0.06, GLASS, Basis(Vector3(0, 0, 1), PI * 0.5), 12)
		kit.cylinder(Vector3(-0.13, 0.0, 0.0), 0.026, 0.026, 0.04, GLASS, Basis(Vector3(0, 0, 1), PI * 0.5), 12)
		# a streak of light along its top
		kit.sphere(Vector3(0.02, 0.058, -0.02), 0.03, GLASS_HI, Vector3(3.2, 0.25, 0.6), 8)
		return kit.commit())


static func bottle_note() -> ArrayMesh:
	return _cached("fen_bottle_note", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.cylinder(Vector3(0.1, -0.01, 0.0), 0.028, 0.028, 0.15, SCROLL, Basis(Vector3(0, 0, 1), PI * 0.5), 10)
		kit.sphere(Vector3(0.1, -0.01, 0.0), 0.03, SCROLL.darkened(0.08), Vector3(0.3, 1.0, 1.0), 8)
		kit.torus(Vector3(0.025, -0.01, 0.0), 0.03, 0.006, RIBBON, Basis(Vector3(0, 0, 1), PI * 0.5), 10)
		kit.cylinder(Vector3(-0.17, 0.0, 0.0), 0.024, 0.029, 0.045, CORK, Basis(Vector3(0, 0, 1), PI * 0.5), 10)
		return kit.commit())
