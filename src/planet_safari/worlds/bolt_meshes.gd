extends RefCounted
## THE SHAPES OF BOLT'S SAFARI (docs/PLANET_SAFARI_SPEC.md 5.5, builder P4). Static builders only: every
## creature and event prop is ONE vertex-coloured ArrayMesh made with PlanetMeshKit (the same kit and
## the same two shipped materials - PlanetPropMeshes.metal_material / prop_material - that Bolt's
## own props already draw with, so no new shader), plus one or two separately animated parts where a
## part has to move on its own (a crab's claws, a beetle's cog, the whale's tail). One mesh = one draw
## call; a herd of them is one MultiMesh per part (safari_herd.gd).
##
## Conventions (PlanetMeshKit's): prop-local, +Y up, origin at the ground contact, the creature faces
## -Z. Colours are sRGB hex, inside docs/STYLE_GUIDE.md: Bolt is cool blue-grey steel with warm orange
## and brass accents; no swatch above S 0.60 except the small orange accents; nothing whiter than V 0.92.
## Cute and structured, not bubbly (R2.3, "Shape language corrections"): flat bases, chamfered tiers,
## hex facets, panel bands - and the same small dark eyes the neighbours have.
##
## Built once per safari and cached here for the process (a second safari reuses them).

const STEEL := Color("#a7a89e")
const STEEL_DARK := Color("#6f6d63")
const BRASS := Color("#b8975c")
const TEAL := Color("#68a49e")
const ORANGE := Color("#dd8434")
const EYE := Color("#2a2320")
const EYE_HI := Color("#e9e6dc")

static var _cache: Dictionary = {}


static func _cached(key: String, build: Callable) -> ArrayMesh:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


## Two small dark oval eyes with a highlight dot (the house eye: small, calm, no sclera domes).
static func _eyes(kit: PlanetMeshKit, centre: Vector3, spacing: float, r: float, fwd: Vector3 = Vector3(0, 0, -1)) -> void:
	var side := Vector3.UP.cross(fwd).normalized()
	for sgn in [-1.0, 1.0]:
		var c: Vector3 = centre + side * spacing * 0.5 * sgn
		kit.sphere(c, r, EYE, Vector3(0.75, 1.0, 0.6), 10)
		kit.sphere(c + fwd * r * 0.45 + Vector3(0.0, r * 0.35, 0.0) + side * r * 0.25, r * 0.28, EYE_HI, Vector3.ONE, 6)


# ============================================================================================ NUT-CRAB
## Body, eye stalks and six legs: one mesh. A brass hex-nut shell sits on a teal-grey body; the hole
## of the nut is the crab's "hatch" (a dark recess). About 0.5 m wide, 0.32 m tall at the stalks.
static func crab_body() -> ArrayMesh:
	return _cached("crab_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var body := Color("#5f7c80")
		var leg := Color("#4a5560")
		# the soft body under the shell, flat underside
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.06), Vector2(0.17, 0.06), Vector2(0.21, 0.10),
			Vector2(0.19, 0.15), Vector2(0.0, 0.16)]), 14, Transform3D.IDENTITY, body, true)
		# the hex-nut shell: a hard six-sided ring with a chamfered top and a dark hatch in the middle
		var nut := PackedVector2Array([Vector2(0.09, 0.12), Vector2(0.23, 0.12), Vector2(0.25, 0.15),
			Vector2(0.25, 0.22), Vector2(0.21, 0.26), Vector2(0.09, 0.26)])
		kit.lathe(nut, 6, Transform3D(Basis(Vector3.UP, PI / 6.0), Vector3.ZERO), BRASS, false)
		kit.cylinder(Vector3(0.0, 0.13, 0.0), 0.10, 0.10, 0.11, Color("#3e4650"), Basis.IDENTITY, 6)
		kit.torus(Vector3(0.0, 0.245, 0.0), 0.16, 0.012, BRASS.darkened(0.25), Basis.IDENTITY, 12)
		# eye stalks and eyes, at the front
		for sgn in [-1.0, 1.0]:
			var base := Vector3(0.07 * sgn, 0.14, -0.15)
			kit.cylinder(base, 0.018, 0.015, 0.12, leg, Basis(Vector3.RIGHT, -0.25), 6)
		_eyes(kit, Vector3(0.0, 0.29, -0.19), 0.15, 0.032)
		# six legs, three a side: two segments each, flat feet
		for sgn in [-1.0, 1.0]:
			for k in 3:
				var z := -0.08 + 0.08 * float(k)
				var hip := Vector3(0.17 * sgn, 0.10, z)
				var knee := Vector3(0.28 * sgn, 0.12, z * 1.3)
				var foot := Vector3(0.33 * sgn, 0.0, z * 1.5)
				_limb(kit, hip, knee, 0.022, leg)
				_limb(kit, knee, foot, 0.018, leg)
		return kit.commit())


## The two claws (waved by code): orange-brass pincers on short arms, pivot at the origin.
static func crab_claws() -> ArrayMesh:
	return _cached("crab_claws", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var claw := Color("#a58570")
		for sgn in [-1.0, 1.0]:
			var sh := Vector3(0.13 * sgn, 0.0, -0.10)
			var el := Vector3(0.20 * sgn, 0.05, -0.20)
			_limb(kit, sh, el, 0.022, Color("#4a5560"))
			kit.sphere(el + Vector3(0.0, 0.02, -0.04), 0.06, claw, Vector3(0.8, 0.7, 1.1), 10)
			kit.sphere(el + Vector3(0.025 * sgn, 0.05, -0.09), 0.03, claw.darkened(0.1), Vector3(0.8, 0.7, 1.4), 8)
			kit.sphere(el + Vector3(-0.015 * sgn, 0.0, -0.10), 0.028, claw.darkened(0.1), Vector3(0.8, 0.7, 1.4), 8)
		return kit.commit())


## A crab's hidey-hole: a round floor grate with a dark mouth, flush with the ground.
static func burrow() -> ArrayMesh:
	return _cached("burrow", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.34, -0.02), Vector2(0.36, 0.03),
			Vector2(0.28, 0.05), Vector2(0.26, 0.02)]), 12, Transform3D.IDENTITY, STEEL_DARK, false)
		kit.cylinder(Vector3(0.0, -0.03, 0.0), 0.26, 0.26, 0.05, Color("#2c3038"), Basis.IDENTITY, 12)
		for i in 3:
			var b := Basis(Vector3.UP, PI / 3.0 * float(i))
			kit.rounded_box(Vector3(0.0, 0.035, 0.0), Vector3(0.50, 0.025, 0.04), 0.01, STEEL, b)
		return kit.commit())


# ============================================================================================ GEAR-BEETLE
## Body: a domed, panelled teal shell, dark head, six short legs, two antennae. ~0.36 m long.
static func beetle_body() -> ArrayMesh:
	return _cached("beetle_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var shell := Color("#5f9a92")
		var dark := Color("#46505c")
		kit.sphere(Vector3(0.0, 0.08, 0.02), 0.13, shell, Vector3(1.0, 0.62, 1.35), 14)
		kit.torus(Vector3(0.0, 0.08, 0.02), 0.125, 0.012, shell.darkened(0.3), Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, 0.0), 14)
		kit.sphere(Vector3(0.0, 0.07, -0.17), 0.075, dark, Vector3(1.0, 0.85, 0.9), 12)
		_eyes(kit, Vector3(0.0, 0.085, -0.225), 0.07, 0.018)
		for sgn in [-1.0, 1.0]:
			_limb(kit, Vector3(0.03 * sgn, 0.12, -0.21), Vector3(0.08 * sgn, 0.22, -0.27), 0.009, dark)
			kit.sphere(Vector3(0.08 * sgn, 0.22, -0.27), 0.018, ORANGE.darkened(0.1), Vector3.ONE, 6)
			for k in 3:
				var z := -0.08 + 0.09 * float(k)
				_limb(kit, Vector3(0.09 * sgn, 0.05, z), Vector3(0.17 * sgn, 0.0, z * 1.2), 0.013, dark)
		return kit.commit())


## The cog on a beetle's back (spun by code about its own Y). Brass, eight teeth, dark hub.
static func beetle_cog() -> ArrayMesh:
	return PlanetPropMeshes.gear(0.085, 8, 0.035, BRASS, STEEL_DARK)


# ============================================================================================ SKY WHALE
## The body, fins and face of the Sky Whale: one mesh, ~4.6 m nose to tail root, facing -Z. A
## plated steel-blue back with two panel bands, a cream grooved belly, small calm eyes, a blowhole,
## a row of warm port lights down each flank. The tail flukes are a separate mesh (whale_tail).
## The whale's body shape, shared by the mesh and by `whale_body_hides` (so what hides the spout in a
## photo is exactly what is drawn): a lathe profile (radius, length; length runs head -Z to tail +Z),
## squashed wider than tall, plus the cream belly keel (an ellipsoid).
const WHALE_PROFILE: Array[Vector2] = [Vector2(0.0, -2.30), Vector2(0.55, -2.18), Vector2(0.92, -1.80),
	Vector2(1.12, -1.10), Vector2(1.14, -0.40), Vector2(1.02, 0.40), Vector2(0.78, 1.20),
	Vector2(0.48, 1.85), Vector2(0.28, 2.25), Vector2(0.0, 2.35)]
const WHALE_SQUASH := Vector3(1.12, 0.86, 1.0)
const WHALE_BELLY_C := Vector3(0.0, -0.50, -0.45)
const WHALE_BELLY_R := Vector3(0.98, 0.60, 1.62)


## True when a point in the whale's own frame is inside its body or belly (fins and tail are left out:
## they are thin and do not stand between a lens and the blowhole).
static func whale_body_contains(p: Vector3) -> bool:
	var b := (p - WHALE_BELLY_C) / WHALE_BELLY_R
	if b.length_squared() < 1.0:
		return true
	var prof := WHALE_PROFILE
	if p.z <= prof[0].y or p.z >= prof[prof.size() - 1].y:
		return false
	for i in range(1, prof.size()):
		var a: Vector2 = prof[i - 1]
		var c: Vector2 = prof[i]
		if p.z <= c.y:
			var r := lerpf(a.x, c.x, (p.z - a.y) / maxf(c.y - a.y, 0.0001))
			var x := p.x / WHALE_SQUASH.x
			var y := p.y / WHALE_SQUASH.y
			return x * x + y * y < r * r
	return false


## True when the straight line between two points in the whale's own frame passes through its body.
## Sampled every 2 cm inside the body's box, so a line that only grazes less than 2 cm of the body
## counts as clear.
static func whale_body_hides(a: Vector3, b: Vector3) -> bool:
	var box := AABB(Vector3(-1.30, -1.10, -2.30), Vector3(2.60, 2.10, 4.65))
	var dist := a.distance_to(b)
	var n := int(ceil(dist / 0.02))
	for i in range(1, n):
		var q := a.lerp(b, float(i) / float(n))
		if box.has_point(q) and whale_body_contains(q):
			return true
	return false


static func whale_body() -> ArrayMesh:
	return _cached("whale_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var back := Color("#94a9c4")
		var band := Color("#71839c")
		var belly := Color("#dcd3c0")
		var fin := Color("#6f84a0")
		# body: a lathe along the length (lathe Y -> body +Z, i.e. tail at +Z), wider than tall
		var along := Basis(Vector3.RIGHT, PI * 0.5)   # lathe +Y -> +Z
		var squash := Basis.from_scale(WHALE_SQUASH)
		kit.lathe(PackedVector2Array(WHALE_PROFILE), 20, Transform3D(squash * along, Vector3.ZERO), back, true)
		# belly: a cream keel that shows below the body's widest line (the body hides its top)
		kit.sphere(WHALE_BELLY_C, 1.0, belly, WHALE_BELLY_R, 20)
		# three soft groove rings across the keel, sunk into it so only their undersides show
		for z in [-1.2, -0.55, 0.1]:
			kit.torus(Vector3(0.0, -0.62, z), 0.55, 0.03, belly.darkened(0.12), Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(1.4, 1.0, 0.8)), 20)
		# panel bands round the body
		for z in [-1.05, 0.55]:
			var rr := 1.13 if z < 0.0 else 0.93
			kit.torus(Vector3(0.0, 0.0, z), rr, 0.045, band, Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(1.12, 1.0, 0.86)), 28)
		# blowhole and a low brass collar round it
		kit.cylinder(Vector3(0.0, 0.93, -1.25), 0.16, 0.13, 0.08, BRASS, Basis.IDENTITY, 10)
		kit.cylinder(Vector3(0.0, 0.95, -1.25), 0.10, 0.10, 0.07, Color("#2c3038"), Basis.IDENTITY, 10)
		# eyes: low on the face, calm and small for the size
		for sgn in [-1.0, 1.0]:
			var c := Vector3(0.93 * sgn, -0.05, -1.55)
			var outward := Vector3(sgn, 0.0, -0.35).normalized()
			kit.sphere(c, 0.12, EYE, Vector3(0.55, 1.0, 0.8), 10, Basis.looking_at(-outward, Vector3.UP))
			kit.sphere(c + outward * 0.06 + Vector3(0.0, 0.05, -0.02), 0.035, EYE_HI, Vector3.ONE, 6)
		# pectoral fins
		for sgn in [-1.0, 1.0]:
			var fb := Basis(Vector3.FORWARD, 0.55 * sgn) * Basis(Vector3.UP, -0.35 * sgn)
			kit.sphere(Vector3(1.15 * sgn, -0.45, -0.55), 0.55, fin, Vector3(1.0, 0.16, 0.55), 14, fb)
		# a small dorsal ridge of three plates
		for k in 3:
			kit.rounded_box(Vector3(0.0, 0.96 - 0.07 * float(k), -0.15 + 0.42 * float(k)),
				Vector3(0.10, 0.12, 0.30), 0.04, band)
		# warm port lights along each flank (small accents)
		for sgn in [-1.0, 1.0]:
			for k in 4:
				var z := -0.95 + 0.45 * float(k)
				kit.sphere(Vector3(1.06 * sgn - 0.08 * sgn * float(k) * 0.4, 0.22, z), 0.055, ORANGE, Vector3(0.6, 1.0, 1.0), 8)
		return kit.commit())


## The tail flukes, pivot at the tail root (origin), extending to +Z. Waved about X by code.
static func whale_tail() -> ArrayMesh:
	return _cached("whale_tail", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var fin := Color("#6f84a0")
		kit.sphere(Vector3(0.0, 0.0, 0.25), 0.26, Color("#7d93b0"), Vector3(1.0, 0.8, 1.3), 12)
		for sgn in [-1.0, 1.0]:
			var fb := Basis(Vector3.UP, 0.55 * sgn)
			kit.sphere(Vector3(0.45 * sgn, 0.0, 0.62), 0.62, fin, Vector3(1.0, 0.13, 0.48), 14, fb)
		return kit.commit())


# ============================================================================================ GEYSER
## The Big Geyser's mouth: a low stepped collar of plating round a dark bore, four orange hazard
## tabs, a brass lip. Sits flush on the deck; ~1.5 m across.
static func geyser_mouth() -> ArrayMesh:
	return _cached("geyser_mouth", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.10), Vector2(0.78, -0.10), Vector2(0.78, 0.04),
			Vector2(0.62, 0.10), Vector2(0.55, 0.22), Vector2(0.40, 0.26), Vector2(0.36, 0.14)]),
			16, Transform3D.IDENTITY, Color("#8d97a4"), false)
		kit.cylinder(Vector3(0.0, -0.05, 0.0), 0.37, 0.37, 0.2, Color("#262a32"), Basis.IDENTITY, 16)
		kit.torus(Vector3(0.0, 0.25, 0.0), 0.39, 0.035, BRASS, Basis.IDENTITY, 20)
		for i in 4:
			var b := Basis(Vector3.UP, TAU * float(i) / 4.0 + 0.4)
			kit.rounded_box(b * Vector3(0.0, 0.07, -0.68), Vector3(0.22, 0.07, 0.12), 0.02, ORANGE.darkened(0.1), b)
		return kit.commit())


# ============================================================================================ SCRAP SNAIL
## The kettle shell: a squat chrome kettle (stepped body, lid, brass knob, spout forward-up, an arched
## handle with a small brass bell hanging from it). Origin at the shell's base; ~0.95 m tall.
static func snail_shell() -> ArrayMesh:
	return _cached("snail_shell", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var chrome := Color("#aeb8c3")
		var trim := Color("#7f8a98")
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.40, 0.0), Vector2(0.50, 0.12),
			Vector2(0.52, 0.34), Vector2(0.44, 0.52), Vector2(0.30, 0.60), Vector2(0.0, 0.61)]),
			18, Transform3D.IDENTITY, chrome, true)
		kit.torus(Vector3(0.0, 0.12, 0.0), 0.495, 0.03, trim, Basis.IDENTITY, 24)
		kit.torus(Vector3(0.0, 0.50, 0.0), 0.41, 0.025, trim, Basis.IDENTITY, 24)
		kit.cylinder(Vector3(0.0, 0.58, 0.0), 0.27, 0.22, 0.07, trim, Basis.IDENTITY, 16)
		kit.sphere(Vector3(0.0, 0.70, 0.0), 0.07, BRASS, Vector3(1.0, 0.8, 1.0), 10)
		# spout: forward (-Z) and up
		var sb := Basis(Vector3.RIGHT, -0.95)
		kit.cylinder(Vector3(0.0, 0.26, -0.40), 0.10, 0.05, 0.42, chrome, sb, 10)
		# handle arch across the top, front to back, with a bell under it
		var prev := Vector3(0.0, 0.62, 0.30)
		for k in range(1, 9):
			var a := PI * float(k) / 8.0
			var q := Vector3(0.0, 0.62 + 0.24 * sin(a), 0.30 * cos(a))
			_limb(kit, prev, q, 0.04, Color("#3e4650"))
			prev = q
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.13), Vector2(0.075, -0.13), Vector2(0.065, -0.08),
			Vector2(0.045, -0.02), Vector2(0.0, 0.0)]), 12, Transform3D(Basis(), Vector3(0.0, 0.84, 0.0)), BRASS, true)
		return kit.commit())


## The snail's soft body: a long flat foot, a head with two eye stalks and eyes. Faces -Z; the foot is
## 1.5 m long. Code stretches it (the crawl) and bobs the stalks with the whole mesh.
static func snail_body() -> ArrayMesh:
	return _cached("snail_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var skin := Color("#7fa39f")
		var under := Color("#5f7f7c")
		kit.sphere(Vector3(0.0, 0.10, 0.05), 0.5, skin, Vector3(0.62, 0.26, 1.55), 16)
		kit.rounded_box(Vector3(0.0, 0.02, 0.05), Vector3(0.62, 0.05, 1.45), 0.025, under)
		# neck and head, rising at the front
		kit.sphere(Vector3(0.0, 0.30, -0.62), 0.22, skin, Vector3(1.0, 1.05, 1.0), 14)
		kit.sphere(Vector3(0.0, 0.20, -0.72), 0.16, skin, Vector3(1.0, 0.8, 1.0), 12)
		for sgn in [-1.0, 1.0]:
			var base := Vector3(0.09 * sgn, 0.44, -0.66)
			var tip := Vector3(0.16 * sgn, 0.78, -0.74)
			_limb(kit, base, tip, 0.035, skin)
			kit.sphere(tip, 0.075, skin, Vector3.ONE, 10)
			kit.sphere(tip + Vector3(0.0, 0.0, -0.06), 0.04, EYE, Vector3(0.8, 1.0, 0.6), 8)
			kit.sphere(tip + Vector3(0.015 * sgn, 0.02, -0.095), 0.012, EYE_HI, Vector3.ONE, 5)
		# a calm little mouth line
		kit.rounded_box(Vector3(0.0, 0.18, -0.87), Vector3(0.10, 0.012, 0.012), 0.005, Color("#3e4650"))
		return kit.commit())


# ============================================================================================ MAGNET
## The Great Magnet: a big brick-red horseshoe with steel poles, on a squat plinth. ~2.1 m tall.
static func magnet() -> ArrayMesh:
	return _cached("magnet", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# Rendered under Bolt's warm sun this albedo gains a lot of saturation, so it starts pale. Measured
		# on the magnet's own red pixels (shown-minus-hidden mask, phone renderer, 2556x1179, four views;
		# docs/STYLE_GUIDE.md gate: no swatch above S 0.60): #b36a58 (S 0.51) drew S 0.78; #9a6f66 (S 0.34)
		# drew S 0.66-0.69 median; #9a807a drew 0.53-0.56; this one (S 0.17) draws 0.49-0.51, p90 <= 0.56,
		# and still reads brick-red (Q4, 2026-09-24).
		var red := Color("#9a8680")
		var pole := Color("#c9ccc4")
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.62, 0.0), Vector2(0.58, 0.18),
			Vector2(0.44, 0.26), Vector2(0.0, 0.26)]), 8, Transform3D.IDENTITY, Color("#6f7784"), false)
		# the U: an arc of overlapping capsules and two straight legs, a round section
		var r_arc := 0.55
		var top := 1.55
		var n_seg := 14
		for k in n_seg:
			var a0 := PI * float(k) / float(n_seg)
			var a1 := PI * float(k + 1) / float(n_seg)
			var p0 := Vector3(r_arc * cos(a0), top - r_arc * sin(a0), 0.0)
			var p1 := Vector3(r_arc * cos(a1), top - r_arc * sin(a1), 0.0)
			var y := (p1 - p0).normalized()
			var x := y.cross(Vector3.BACK).normalized()
			kit.capsule((p0 + p1) * 0.5, 0.16, (p1 - p0).length() + 0.32, red, Basis(x, y, x.cross(y)))
		for sgn in [-1.0, 1.0]:
			kit.capsule(Vector3(r_arc * sgn, top + 0.25, 0.0), 0.16, 0.82, red)
			kit.cylinder(Vector3(r_arc * sgn, top + 0.50, 0.0), 0.165, 0.165, 0.24, pole, Basis.IDENTITY, 14)
			kit.sphere(Vector3(r_arc * sgn, top + 0.74, 0.0), 0.165, pole, Vector3(1.0, 0.35, 1.0), 14)
		# a stubby stem from plinth to the bottom of the U
		kit.cylinder(Vector3(0.0, 0.2, 0.0), 0.16, 0.14, top - r_arc - 0.1, Color("#6f7784"), Basis.IDENTITY, 10)
		return kit.commit())


## A loose bolt (hex head + shank) and a loose nut, for the Magnet's floating scrap. ~0.22 m.
static func loose_bolt() -> ArrayMesh:
	return _cached("loose_bolt", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.075, 0.0), Vector2(0.075, 0.05), Vector2(0.0, 0.05)]),
			6, Transform3D.IDENTITY, BRASS, false)
		kit.cylinder(Vector3(0.0, 0.05, 0.0), 0.035, 0.035, 0.17, STEEL, Basis.IDENTITY, 8)
		return kit.commit())


static func loose_nut() -> ArrayMesh:
	return _cached("loose_nut", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.lathe(PackedVector2Array([Vector2(0.04, 0.0), Vector2(0.10, 0.0), Vector2(0.10, 0.06),
			Vector2(0.04, 0.06), Vector2(0.04, 0.0)]), 6, Transform3D.IDENTITY, STEEL, false, true)
		return kit.commit())


## A floor hatch the Magnet rises out of: a round plate with a seam and four bolts.
static func hatch() -> ArrayMesh:
	return _cached("hatch", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.03), Vector2(0.85, -0.03), Vector2(0.85, 0.02),
			Vector2(0.78, 0.05), Vector2(0.0, 0.05)]), 16, Transform3D.IDENTITY, Color("#6f7784"), false)
		kit.rounded_box(Vector3(0.0, 0.055, 0.0), Vector3(1.4, 0.012, 0.03), 0.005, Color("#3e4650"))
		for i in 4:
			var b := Basis(Vector3.UP, TAU * float(i) / 4.0 + PI / 4.0)
			kit.sphere(b * Vector3(0.0, 0.05, -0.66), 0.05, BRASS, Vector3(1.0, 0.5, 1.0), 6)
		return kit.commit())


# ============================================================================================ SPARK-MOTH
## A spark-moth: a slim warm body and two swept, pointed wings (one mesh; the beat is a scale in
## code). Deliberately small and plain: at night the moth is read by its glow (a star sprite drawn
## with it), and a big pale round wing read as an eye.
static func moth() -> ArrayMesh:
	return _cached("moth", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var wing := Color("#c99a5e")
		kit.sphere(Vector3.ZERO, 0.022, Color("#8a6a4a"), Vector3(0.8, 0.8, 2.2), 8)
		for sgn in [-1.0, 1.0]:
			kit.triangle(Vector3(0.012 * sgn, 0.0, -0.02), Vector3(0.11 * sgn, 0.0, 0.03), Vector3(0.02 * sgn, 0.0, 0.05), wing)
			kit.triangle(Vector3(0.012 * sgn, 0.0, 0.01), Vector3(0.07 * sgn, 0.0, 0.08), Vector3(0.015 * sgn, 0.0, 0.07), wing.darkened(0.15))
		return kit.commit())


# ============================================================================================ SPRING-HOPPER
## (builder R4, 2026-09-24: spec 11.2's "one new small critter that roams the whole planet". It lives
## under the deck plates everywhere and comes up where you are - the curious scouts of worlds/bolt.gd -
## rather than roaming the surface: every surface population tried made the planet too common.)
## A little copper can of a creature with a domed lid, a cream face plate, the house eyes and a brass
## band, that gets about on ONE coiled spring instead of legs - boing, sit, look about, boing. Two
## parts so the spring can squash and stretch on its own: the body (origin at the spring's top, where
## it sits) and the spring (origin on the ground, +Y up, SPRING_H tall at rest).
## Colours: a dusty rose-copper body #9c8880 (S 0.18 V 0.61; an earlier pass of this comment named
## #9c7c70, S 0.28, which is not what the code draws). Bolt's warm light pushes it hard: the
## first pass, #b87a55 (S 0.54), rendered at median S 0.78 on the phone renderer, above the crabs' own
## shell (0.73); #a47a6a (S 0.35) rendered at 0.63. Cream
## face #d9cdb4 (S 0.17 V 0.85), brass band and steel spring from the shared swatches, one small orange
## knob on the antenna (the allowed accent).
const HOPPER_SPRING_H := 0.13
const HOPPER_COPPER := Color("#9c8880")
const HOPPER_FACE := Color("#d9cdb4")


static func hopper_body() -> ArrayMesh:
	return _cached("hopper_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# the can: flat underside, straight sides, a chamfer, then a low domed lid
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.145, 0.025),
			Vector2(0.15, 0.12), Vector2(0.135, 0.165), Vector2(0.10, 0.205), Vector2(0.05, 0.228),
			Vector2(0.0, 0.232)]), 16, Transform3D.IDENTITY, HOPPER_COPPER, true)
		# a brass band round the middle and a dark rivet on the lid
		kit.torus(Vector3(0.0, 0.06, 0.0), 0.149, 0.012, BRASS, Basis.IDENTITY, 16)
		kit.sphere(Vector3(0.0, 0.232, 0.0), 0.03, STEEL_DARK, Vector3(1.0, 0.6, 1.0), 8)
		# a springy little antenna with an orange knob, leaning back
		_limb(kit, Vector3(0.0, 0.235, 0.02), Vector3(0.0, 0.33, 0.06), 0.008, STEEL_DARK)
		kit.sphere(Vector3(0.0, 0.335, 0.062), 0.024, ORANGE.darkened(0.08), Vector3.ONE, 8)
		# the face: a cream plate on the front (-Z) with the house eyes on it
		kit.sphere(Vector3(0.0, 0.115, -0.118), 0.085, HOPPER_FACE, Vector3(1.0, 0.82, 0.36), 12)
		_eyes(kit, Vector3(0.0, 0.13, -0.148), 0.085, 0.026)
		# two small side bolts, like ears
		for sgn in [-1.0, 1.0]:
			kit.cylinder(Vector3(0.148 * sgn, 0.14, 0.0), 0.022, 0.022, 0.03, STEEL,
				Basis(Vector3.FORWARD, -PI * 0.5 * sgn), 6)
		return kit.commit())


## The coil: three turns of steel wire from a flat foot to a top plate, HOPPER_SPRING_H tall at rest.
static func hopper_spring() -> ArrayMesh:
	return _cached("hopper_spring", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.cylinder(Vector3(0.0, 0.0, 0.0), 0.075, 0.07, 0.018, STEEL_DARK, Basis.IDENTITY, 10)
		var turns := 3.0
		var steps := 24
		var r := 0.052
		var y0 := 0.018
		var y1 := HOPPER_SPRING_H - 0.012
		var prev := Vector3(r, y0, 0.0)
		for i in range(1, steps + 1):
			var f := float(i) / float(steps)
			var a := TAU * turns * f
			var q := Vector3(cos(a) * r, lerpf(y0, y1, f), sin(a) * r)
			var d := q - prev
			var y := d.normalized()
			var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
			kit.cylinder(prev, 0.011, 0.011, d.length() + 0.004, STEEL, Basis(x, y, x.cross(y).normalized()), 5)
			prev = q
		kit.cylinder(Vector3(0.0, y1, 0.0), 0.06, 0.06, 0.012, STEEL_DARK, Basis.IDENTITY, 10)
		return kit.commit())


# ============================================================================================ SIGHTS AND BONUS
## THE SCRAPBOOK'S NEW PAGES (docs/PLANET_SAFARI_SPEC.md 15.5; builder BOLTC, 2026-09-26): Bolt's Workshop (a
## sight) and the three collector's things (a lost sock, "Bolt No. 1", a welded smiley). Same kit, same two
## shipped materials, same conventions (origin at the ground or at the hang point, +Y up, the front
## faces -Z). Colours from the shared swatches plus three muted ones: a cream (the hopper's face,
## S 0.17), a dusty orange (S 0.40) and a slate teal (S 0.31) - nothing whiter than V 0.92. Bolt's warm
## light pushes oranges hard (the hopper's note above): a first pass at #c7875a (S 0.55) rendered at
## S 0.82 in the awning's stripes on the phone renderer, and the brass-bright shank and weld beads
## (S 0.46-0.47) at 0.61-0.76; these are the lowered swatches, re-measured in the report.
const CREAM := Color("#d9cdb4")
const DUSTY_ORANGE := Color("#b5876c")
const SLATE_TEAL := Color("#5f8a86")
const WORKSHOP_W := 2.0
const WORKSHOP_D := 1.25
const WORKSHOP_H := 2.2


## BOLT'S WORKSHOP: an open-fronted lean-to - a striped awning over a pegboard hung with his tools, a
## steel bench with a vice, a half-mended spring-hopper and a mug on it, a stool, a toolbox and a
## hanging lamp. About 2.0 m wide, 1.25 m deep, 2.2 m tall at the back; the open side faces -Z.
static func workshop() -> ArrayMesh:
	return _cached("workshop", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var hw := WORKSHOP_W * 0.5
		var hd := WORKSHOP_D * 0.5
		var frame := STEEL_DARK
		# the floor plate and its rim
		kit.rounded_box(Vector3(0.0, 0.03, 0.0), Vector3(WORKSHOP_W, 0.06, WORKSHOP_D), 0.02, Color("#7b7a72"))
		# four posts: the back ones taller, so the roof slopes down to the open front
		var front_h := 1.95
		for sx: float in [-1.0, 1.0]:
			kit.cylinder(Vector3(sx * (hw - 0.04), 0.05, -hd + 0.05), 0.045, 0.04, front_h - 0.05, frame, Basis.IDENTITY, 8)
			kit.cylinder(Vector3(sx * (hw - 0.04), 0.05, hd - 0.05), 0.045, 0.04, WORKSHOP_H - 0.05, frame, Basis.IDENTITY, 8)
		# the pegboard back wall, with a grid of dark holes, and a half-height side wall on the right
		kit.rounded_box(Vector3(0.0, 1.08, hd - 0.06), Vector3(WORKSHOP_W - 0.14, 1.95, 0.07), 0.02, SLATE_TEAL)
		for ix in 7:
			for iy in 4:
				kit.sphere(Vector3(-0.66 + 0.22 * float(ix), 1.18 + 0.16 * float(iy), hd - 0.10), 0.012,
					Color("#34403f"), Vector3(1.0, 1.0, 0.4), 6)
		kit.rounded_box(Vector3(hw - 0.05, 0.56, 0.0), Vector3(0.06, 1.0, WORKSHOP_D - 0.12), 0.02, Color("#8f9189"))
		# THE AWNING: six stripes, cream and dusty orange, sloping down to the front, a scalloped edge
		var slope := atan((WORKSHOP_H - front_h) / WORKSHOP_D)
		var roof := Basis(Vector3.RIGHT, -slope)
		var sw := (WORKSHOP_W + 0.2) / 6.0
		for k in 6:
			var x := -(WORKSHOP_W + 0.2) * 0.5 + sw * (float(k) + 0.5)
			kit.rounded_box(Vector3(x, (WORKSHOP_H + front_h) * 0.5 + 0.04, 0.0), Vector3(sw + 0.002, 0.05, WORKSHOP_D + 0.22),
				0.015, CREAM if k % 2 == 0 else DUSTY_ORANGE, roof)
			kit.sphere(Vector3(x, front_h - 0.02, -hd - 0.11), sw * 0.5, CREAM if k % 2 == 0 else DUSTY_ORANGE,
				Vector3(1.0, 0.55, 0.25), 10)
		# the sign board over the pegboard: a brass plate with a hex nut on it
		kit.rounded_box(Vector3(0.0, 1.9, hd - 0.12), Vector3(0.62, 0.17, 0.03), 0.02, BRASS)
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.06, 0.03), Vector2(0.0, 0.03)]), 6,
			Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.0, 1.9, hd - 0.135)), STEEL_DARK, false, true)
		# tools on the pegboard: a spanner, a hammer, a spare gear
		var wall_z := hd - 0.12
		kit.rounded_box(Vector3(0.52, 1.42, wall_z), Vector3(0.05, 0.36, 0.02), 0.01, STEEL)
		kit.torus(Vector3(0.52, 1.64, wall_z), 0.055, 0.018, STEEL, Basis(Vector3.RIGHT, PI * 0.5), 10)
		kit.rounded_box(Vector3(0.16, 1.38, wall_z), Vector3(0.04, 0.34, 0.03), 0.01, BRASS.darkened(0.15))
		kit.rounded_box(Vector3(0.16, 1.57, wall_z), Vector3(0.17, 0.065, 0.06), 0.015, STEEL_DARK)
		kit.torus(Vector3(-0.42, 1.5, wall_z), 0.11, 0.028, BRASS, Basis(Vector3.RIGHT, PI * 0.5), 14)
		for t in 8:
			var a := TAU * float(t) / 8.0
			kit.rounded_box(Vector3(-0.42 + cos(a) * 0.145, 1.5 + sin(a) * 0.145, wall_z), Vector3(0.05, 0.05, 0.04), 0.01,
				BRASS, Basis(Vector3.FORWARD, a))
		kit.sphere(Vector3(-0.42, 1.5, wall_z - 0.01), 0.035, STEEL_DARK, Vector3(1.0, 1.0, 0.5), 8)
		# THE BENCH: a steel top on four legs, a lower shelf, a vice on its left end
		var top_y := 0.86
		var bz := hd - 0.42
		kit.rounded_box(Vector3(0.0, top_y, bz), Vector3(1.5, 0.08, 0.56), 0.02, Color("#9a9b92"))
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				kit.cylinder(Vector3(sx * 0.66, 0.06, bz + sz * 0.22), 0.035, 0.03, top_y - 0.1, frame, Basis.IDENTITY, 6)
		kit.rounded_box(Vector3(0.0, 0.32, bz), Vector3(1.38, 0.04, 0.46), 0.01, Color("#85867e"))
		kit.rounded_box(Vector3(-0.6, top_y + 0.09, bz - 0.2), Vector3(0.2, 0.1, 0.08), 0.015, STEEL_DARK)
		kit.rounded_box(Vector3(-0.6, top_y + 0.09, bz - 0.33), Vector3(0.2, 0.1, 0.05), 0.015, STEEL_DARK)
		kit.cylinder(Vector3(-0.6, top_y + 0.07, bz - 0.36), 0.015, 0.015, 0.16, STEEL, Basis(Vector3.RIGHT, -PI * 0.5), 6)
		kit.cylinder(Vector3(-0.7, top_y + 0.07, bz - 0.5), 0.012, 0.012, 0.2, STEEL, Basis(Vector3.FORWARD, PI * 0.5), 6)
		# on the bench: a half-mended spring-hopper (its lid off, a spare spring beside it), a mug, an oil can
		var hx := 0.18
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.145, 0.025), Vector2(0.15, 0.13),
			Vector2(0.0, 0.13)]), 14, Transform3D(Basis.IDENTITY, Vector3(hx, top_y + 0.04, bz)), HOPPER_COPPER, true)
		kit.sphere(Vector3(hx, top_y + 0.13, bz - 0.12), 0.08, HOPPER_FACE, Vector3(1.0, 0.8, 0.36), 10)
		_eyes(kit, Vector3(hx, top_y + 0.145, bz - 0.15), 0.08, 0.024)
		kit.sphere(Vector3(hx + 0.24, top_y + 0.05, bz + 0.08), 0.1, HOPPER_COPPER, Vector3(1.0, 0.25, 1.0), 12)
		for c in 3:
			kit.torus(Vector3(hx - 0.25, top_y + 0.06 + 0.035 * float(c), bz + 0.05), 0.05, 0.009, STEEL, Basis.IDENTITY, 10)
		kit.cylinder(Vector3(0.52, top_y + 0.04, bz - 0.06), 0.045, 0.045, 0.1, CREAM, Basis.IDENTITY, 10)
		kit.torus(Vector3(0.575, top_y + 0.09, bz - 0.06), 0.028, 0.009, CREAM, Basis(Vector3.RIGHT, PI * 0.5), 8)
		kit.cylinder(Vector3(0.62, top_y + 0.04, bz + 0.12), 0.06, 0.05, 0.12, TEAL, Basis.IDENTITY, 10)
		kit.cylinder(Vector3(0.62, top_y + 0.15, bz + 0.12), 0.012, 0.006, 0.14, STEEL_DARK, Basis(Vector3.RIGHT, -0.9), 6)
		# the hanging lamp: a cord, a steel shade, a pale bulb (no light: vertex colour only)
		kit.cylinder(Vector3(0.0, 1.62, bz), 0.006, 0.006, (WORKSHOP_H + front_h) * 0.5 - 1.62, STEEL_DARK, Basis.IDENTITY, 4)
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.12), Vector2(0.03, 0.12), Vector2(0.15, 0.0), Vector2(0.13, 0.0),
			Vector2(0.0, 0.1)]), 14, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.5, bz)), STEEL_DARK, false)
		kit.sphere(Vector3(0.0, 1.52, bz), 0.05, Color("#e6d9b3"), Vector3.ONE, 8)
		# a stool out front, and a toolbox on the floor
		kit.cylinder(Vector3(-0.3, 0.46, -hd + 0.3), 0.16, 0.16, 0.05, DUSTY_ORANGE.darkened(0.1), Basis.IDENTITY, 12)
		for t in 3:
			var a := TAU * float(t) / 3.0 + 0.3
			_limb(kit, Vector3(-0.3 + cos(a) * 0.1, 0.46, -hd + 0.3 + sin(a) * 0.1),
				Vector3(-0.3 + cos(a) * 0.17, 0.06, -hd + 0.3 + sin(a) * 0.17), 0.018, frame)
		kit.rounded_box(Vector3(0.62, 0.17, -hd + 0.32), Vector3(0.38, 0.2, 0.22), 0.03, Color("#a97b62"))
		kit.rounded_box(Vector3(0.62, 0.275, -hd + 0.32), Vector3(0.39, 0.02, 0.23), 0.01, Color("#86604c"))
		kit.torus(Vector3(0.62, 0.3, -hd + 0.32), 0.07, 0.012, STEEL_DARK, Basis(Vector3.RIGHT, PI * 0.5), 10)
		return kit.commit())


## A LOST SOCK, snagged by its cuff: cream with dusty-orange stripes, a slate-teal heel and toe. Origin at
## the cuff (where it hangs from), the leg hanging down -Y, the foot pointing -Z. About 0.27 m long.
static func sock() -> ArrayMesh:
	return _cached("sock", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var r := 0.045
		kit.torus(Vector3(0.0, -0.012, 0.0), r, 0.012, CREAM.darkened(0.06), Basis.IDENTITY, 12)
		kit.cylinder(Vector3(0.0, -0.2, 0.0), r * 0.95, r, 0.19, CREAM, Basis.IDENTITY, 12)
		for k in 3:
			kit.torus(Vector3(0.0, -0.05 - 0.045 * float(k), 0.0), r * 1.01, 0.011, DUSTY_ORANGE, Basis.IDENTITY, 12)
		kit.sphere(Vector3(0.0, -0.205, 0.0), r * 1.05, SLATE_TEAL, Vector3(1.0, 1.0, 1.1), 10)
		kit.cylinder(Vector3(0.0, -0.205, 0.0), r * 0.95, r * 0.9, 0.08, CREAM, Basis(Vector3.RIGHT, -PI * 0.5), 10)
		kit.sphere(Vector3(0.0, -0.205, -0.085), r * 0.95, SLATE_TEAL, Vector3(1.0, 0.95, 1.2), 10)
		return kit.commit())


## "BOLT No. 1": a giant brass bolt standing head-up on a stone plinth, a hex nut run half-way down its
## thread, a brass plaque with a "1" on the plinth's front (-Z). About 1.45 m tall, 0.8 m across.
static func bolt_no_1() -> ArrayMesh:
	return _cached("bolt_no_1", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var stone := Color("#948f84")
		kit.rounded_box(Vector3(0.0, 0.08, 0.0), Vector3(0.8, 0.16, 0.8), 0.03, stone.darkened(0.14))
		kit.rounded_box(Vector3(0.0, 0.39, 0.0), Vector3(0.62, 0.46, 0.62), 0.03, stone)
		kit.rounded_box(Vector3(0.0, 0.655, 0.0), Vector3(0.72, 0.08, 0.72), 0.03, stone.lightened(0.08))
		# the plaque and its "1" (a bar, a flag, a foot), with a rivet at each corner
		kit.rounded_box(Vector3(0.0, 0.4, -0.315), Vector3(0.34, 0.22, 0.02), 0.01, BRASS.darkened(0.08))
		var ink := Color("#3e3a34")
		kit.rounded_box(Vector3(0.0, 0.4, -0.328), Vector3(0.032, 0.13, 0.01), 0.004, ink)
		# the front faces -Z, so mesh +X is the viewer's LEFT: the flag sits at +X and its outer (+X) end dips,
		# sloping down-left as seen from the front (a mirrored "1" was the round-1 critic's catch)
		kit.rounded_box(Vector3(0.022, 0.452, -0.328), Vector3(0.05, 0.022, 0.01), 0.004, ink, Basis(Vector3.FORWARD, 0.6))
		kit.rounded_box(Vector3(0.0, 0.338, -0.328), Vector3(0.08, 0.02, 0.01), 0.004, ink)
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				kit.sphere(Vector3(sx * 0.14, 0.4 + sy * 0.08, -0.328), 0.012, BRASS.darkened(0.3), Vector3(1.0, 1.0, 0.5), 6)
		# the bolt: a threaded shank (rings), a hex nut part-way down, a washer and the hex head on top
		var shank := Color("#b8a37e")
		kit.cylinder(Vector3(0.0, 0.69, 0.0), 0.095, 0.095, 0.6, shank, Basis.IDENTITY, 14)
		for k in 9:
			kit.torus(Vector3(0.0, 0.73 + 0.055 * float(k), 0.0), 0.097, 0.011, shank.darkened(0.12), Basis.IDENTITY, 14)
		kit.lathe(PackedVector2Array([Vector2(0.1, 0.0), Vector2(0.2, 0.0), Vector2(0.21, 0.02), Vector2(0.21, 0.1),
			Vector2(0.2, 0.12), Vector2(0.1, 0.12)]), 6, Transform3D(Basis(Vector3.UP, PI / 6.0), Vector3(0.0, 0.8, 0.0)),
			STEEL, false, true)
		kit.cylinder(Vector3(0.0, 1.27, 0.0), 0.2, 0.2, 0.025, BRASS.darkened(0.1), Basis.IDENTITY, 16)
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.25, 0.02), Vector2(0.25, 0.12),
			Vector2(0.22, 0.16), Vector2(0.0, 0.17)]), 6, Transform3D(Basis(Vector3.UP, PI / 6.0), Vector3(0.0, 1.29, 0.0)),
			BRASS, false, true)
		return kit.commit())


## A SMILEY WELDED ONTO A CRATE: a ring of brass weld beads with two bead eyes and a bead smile, on a
## dark scorch mark. Origin on the crate's face, the beads toward -Z (out of the face). 0.34 m across.
static func crate_smiley() -> ArrayMesh:
	return _cached("crate_smiley", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var bead := Color("#bca98a")
		var out := Basis(Vector3.RIGHT, -PI * 0.5)
		kit.cylinder(Vector3(0.0, 0.0, 0.0), 0.17, 0.17, 0.006, Color("#55524c"), out, 20)
		for k in 22:
			var a := TAU * float(k) / 22.0
			kit.sphere(Vector3(cos(a) * 0.13, sin(a) * 0.13, -0.012), 0.017, bead, Vector3(1.0, 1.0, 0.6), 6)
		for sx: float in [-1.0, 1.0]:
			kit.sphere(Vector3(sx * 0.045, 0.04, -0.014), 0.027, bead, Vector3(0.8, 1.0, 0.6), 8)
		for k in 9:
			var a := deg_to_rad(205.0 + 130.0 * float(k) / 8.0)
			kit.sphere(Vector3(cos(a) * 0.075, 0.005 + sin(a) * 0.075, -0.012), 0.016, bead, Vector3(1.0, 1.0, 0.6), 6)
		return kit.commit())


# ============================================================================================ helpers
static func _limb(kit: PlanetMeshKit, a: Vector3, b: Vector3, r: float, c: Color) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var y := d / l
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	kit.cylinder(a, r, r * 0.9, l, c, Basis(x, y, z), 6)
	kit.sphere(b, r * 1.05, c, Vector3.ONE, 6)
