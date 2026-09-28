extends RefCounted
## THE SHAPES OF ZORP'S SAFARI (docs/PLANET_SAFARI_SPEC.md 12.1, builder ZORP). Static builders only:
## every creature and event prop is ONE vertex-coloured ArrayMesh made with PlanetMeshKit, drawn with
## the materials Zorp's own props already draw with (PlanetPropMeshes.prop_material for the matte
## parts; PlanetPropMeshes.crystal_material with the planet's own mushroom-spot and tentacle-bulb
## keys for everything that glows), so no new shader. Parts that move on their own (a bulb's petals,
## the Great Bloom's petals) are separate meshes posed by code; a herd of any of them is one
## MultiMesh per part (safari_herd.gd).
##
## Conventions (PlanetMeshKit's): prop-local, +Y up, origin at the ground contact (or, for a flier,
## its middle), the creature faces -Z. Colours are sRGB hex inside docs/STYLE_GUIDE.md: Zorp is MUTED
## VIOLET with cyan and pink glows; no large swatch above S 0.60 (the glows are small accents), nothing
## whiter than V 0.92. Cute and structured: flat bases, soft domes, and the same small dark eyes the
## neighbours have (the house eye).
##
## Built once per process and cached here (a second safari reuses them).

const EYE := Color("#1a1233")
const EYE_HI := Color("#e6e0ee")
## Mush-hopper: a soft sage frog under a mauve toadstool cap with cream spots.
const FROG := Color("#86ab98")        # S 0.22 V 0.67
const FROG_DARK := Color("#6a8d7c")
const BELLY := Color("#cfd8c2")
const CAP := Color("#b27ea6")         # S 0.29 V 0.70
const CAP_UNDER := Color("#8e6a8c")
const SPOT := Color("#e6dccb")        # V 0.90
## The mushroom rings: the planet's own pale mauve caps and cream stems (zorp.tres foliage_color_a).
const RING_CAP := Color("#c9a3bb")
const RING_CAP_B := Color("#b690b0")
const RING_STEM := Color("#ddd2bd")
## Glow-jelly: the bell glows (crystal material); the face and frills are matte lilac.
const FRILL := Color("#b3a3d2")       # S 0.23 V 0.82
const FRILL_DARK := Color("#9483b8")
## Lantern-beetle: a dark violet shell; the lantern glows.
const SHELL := Color("#4c3f63")
## Tentacle bulbs: the planet's own tentacle-plant colours (planet_props.gd _violet: #9a56c4 / #c46fac).
const STALK := Color("#8c72a8")       # S 0.32 V 0.66
const PETAL := Color("#c296b6")       # S 0.23 V 0.76
const PETAL_TIP := Color("#d9b8cf")
## The Great Bloom.
const BLOOM_STEM := Color("#8a7ea6")
const BLOOM_LEAF := Color("#8f86b0")
const BLOOM_PETAL := Color("#c9a3c2")
const BLOOM_PETAL_TIP := Color("#dcc4d6")
## Zorp's watering can.
const CAN := Color("#8aa9bf")
const CAN_DARK := Color("#5f7890")

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


static func _limb(kit: PlanetMeshKit, a: Vector3, b: Vector3, r: float, c: Color) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var y := d / l
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	kit.cylinder(a, r, r * 0.9, l, c, Basis(x, y, z), 8)
	kit.sphere(b, r * 1.05, c, Vector3.ONE, 8)


# ============================================================================================ MUSH-HOPPER
## A round little frog wearing a toadstool cap pulled down to its eyes. ~0.42 m tall, 0.4 m wide,
## facing -Z. When it tucks its legs in and squats (code: scale Y down) it reads as one more mushroom.
static func hopper() -> ArrayMesh:
	return _cached("hopper", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# body and belly, a flat underside
		kit.sphere(Vector3(0.0, 0.14, 0.01), 0.17, FROG, Vector3(1.08, 0.82, 1.12), 18)
		kit.sphere(Vector3(0.0, 0.11, -0.07), 0.13, BELLY, Vector3(0.92, 0.72, 0.78), 14)
		# back legs folded at the sides, big flat feet
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.14 * sgn, 0.08, 0.07), 0.08, FROG_DARK, Vector3(0.8, 0.65, 1.3), 10)
			kit.sphere(Vector3(0.16 * sgn, 0.018, -0.03), 0.06, FROG_DARK, Vector3(1.0, 0.35, 1.5), 10)
			# front feet
			kit.sphere(Vector3(0.075 * sgn, 0.02, -0.15), 0.035, FROG_DARK, Vector3(1.0, 0.45, 1.3), 8)
		# the face: two eyes low on the front, under the cap's rim
		_eyes(kit, Vector3(0.0, 0.17, -0.175), 0.13, 0.034)
		# the cap: a wide soft dome with a pale underside, pulled down to just above the eyes
		var cap_xf := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.20, 0.035))
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.01), Vector2(0.19, 0.01), Vector2(0.22, 0.035)]), 18, cap_xf, CAP_UNDER, false)
		kit.lathe(PackedVector2Array([Vector2(0.22, 0.035), Vector2(0.225, 0.06), Vector2(0.20, 0.12),
			Vector2(0.13, 0.18), Vector2(0.0, 0.205)]), 18, cap_xf, CAP, true)
		for i in 6:
			var ang := TAU * float(i) / 6.0 + 0.4
			var rr := 0.09 + 0.06 * float(i % 2)
			var y := 0.20 + 0.20 - rr * rr * 2.6
			kit.sphere(Vector3(cos(ang) * rr, y, sin(ang) * rr + 0.035), 0.028, SPOT, Vector3(1.0, 0.45, 1.0), 8)
		return kit.commit())


## A fairy ring: nine small toadstools in a circle of radius ~1.1 m round the origin (one mesh).
static func mushroom_ring() -> ArrayMesh:
	return _cached("mushroom_ring", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 23_12_1
		var n := 9
		for i in n:
			var ang := TAU * float(i) / float(n) + rng.randf_range(-0.12, 0.12)
			var r := 1.1 + rng.randf_range(-0.12, 0.12)
			var s := rng.randf_range(0.55, 0.95)
			var c := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
			var cap := RING_CAP if i % 2 == 0 else RING_CAP_B
			kit.lathe(PackedVector2Array([Vector2(0.0, -0.05), Vector2(0.07, -0.05), Vector2(0.06, 0.12),
				Vector2(0.065, 0.2), Vector2(0.0, 0.2)]).duplicate(), 10, Transform3D(Basis.from_scale(Vector3.ONE * s), c), RING_STEM, true)
			kit.lathe(PackedVector2Array([Vector2(0.0, 0.17), Vector2(0.17, 0.17), Vector2(0.19, 0.2),
				Vector2(0.16, 0.26), Vector2(0.09, 0.31), Vector2(0.0, 0.325)]), 12, Transform3D(Basis.from_scale(Vector3.ONE * s), c), cap, true)
			kit.sphere(c + Vector3(0.05, 0.29, 0.03) * s, 0.025 * s, SPOT, Vector3(1.0, 0.5, 1.0), 6)
		return kit.commit())


# ============================================================================================ GLOW-JELLY
## The bell, origin at the jelly's middle: a soft dome 0.52 m across, drawn in the planet's own
## glowing mushroom-spot material (cyan). Vertex colour white: the material's colour is the colour.
static func jelly_bell() -> ArrayMesh:
	return _cached("jelly_bell", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.20, -0.04), Vector2(0.26, -0.03),
			Vector2(0.255, 0.05), Vector2(0.22, 0.14), Vector2(0.14, 0.215), Vector2(0.0, 0.24)]), 18,
			Transform3D.IDENTITY, Color.WHITE, true)
		return kit.commit())


## The face and frills (matte lilac): two eyes on the bell's front, a scalloped rim under it and five
## short wavy ribbon-arms hanging down (to about -0.34 m).
static func jelly_frills() -> ArrayMesh:
	return _cached("jelly_frills", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		_eyes(kit, Vector3(0.0, 0.06, -0.245), 0.12, 0.03)
		kit.torus(Vector3(0.0, -0.035, 0.0), 0.235, 0.03, FRILL, Basis.IDENTITY, 18)
		for i in 5:
			var ang := TAU * float(i) / 5.0 + 0.3
			var o := Vector3(cos(ang), 0.0, sin(ang)) * 0.13
			var a := o + Vector3(0.0, -0.04, 0.0)
			var b := o * 1.2 + Vector3(0.025, -0.16, 0.0)
			var c := o * 1.0 + Vector3(-0.02, -0.30, 0.0)
			_limb(kit, a, b, 0.024, FRILL)
			_limb(kit, b, c, 0.019, FRILL_DARK)
		return kit.commit())


# ============================================================================================ LANTERN-BEETLE
## A tiny dark beetle (~0.13 m) with two stubby wings; its glowing lantern is `beetle_lantern`.
static func beetle() -> ArrayMesh:
	return _cached("lantern_beetle", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.0, -0.01), 0.04, SHELL, Vector3(1.0, 0.8, 1.2), 10)
		kit.sphere(Vector3(0.0, 0.0, -0.058), 0.026, SHELL.darkened(0.2), Vector3.ONE, 8)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.035 * sgn, 0.03, 0.0), 0.035, FRILL_DARK, Vector3(1.0, 0.25, 0.7), 8)
		return kit.commit())


## The lantern: a round glowing tail (in the warm lantern material; vertex colour white).
static func beetle_lantern() -> ArrayMesh:
	return _cached("beetle_lantern", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, -0.005, 0.045), 0.036, Color.WHITE, Vector3(1.0, 0.9, 1.1), 10)
		return kit.commit())


# ============================================================================================ BULB BEDS
## One tentacle bulb's stalk: a soft base and a curling stalk 0.55 m tall, the bulb's seat at its top
## (BULB_TOP). Matte, in the planet's tentacle colours.
const BULB_TOP := Vector3(0.0, 0.58, 0.02)


static func bulb_stalk() -> ArrayMesh:
	return _cached("bulb_stalk", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.03, 0.0), 0.13, STALK.lightened(0.08), Vector3(1.0, 0.35, 1.0), 12)
		var pts := [Vector3(0.0, 0.0, 0.0), Vector3(0.03, 0.2, -0.02), Vector3(-0.02, 0.4, 0.03), BULB_TOP]
		for i in range(1, pts.size()):
			_limb(kit, pts[i - 1], pts[i], 0.045 - 0.008 * float(i), STALK.lerp(PETAL, 0.15 * float(i)))
		# two little curled leaves at the foot
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.1 * sgn, 0.05, 0.02), 0.07, STALK, Vector3(1.4, 0.35, 0.8), 10)
		return kit.commit())


## One petal, its root at the origin, pointing up +Y (code tilts it out to open it).
static func bulb_petal() -> ArrayMesh:
	return _cached("bulb_petal", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.09, 0.0), 0.1, PETAL, Vector3(0.62, 1.0, 0.24), 12)
		kit.sphere(Vector3(0.0, 0.15, -0.012), 0.045, PETAL_TIP, Vector3(0.9, 0.9, 0.3), 8)
		return kit.commit())


## The glowing heart of a bulb (the planet's pink tentacle-bulb material; vertex colour white).
static func bulb_core() -> ArrayMesh:
	return _cached("bulb_core", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.05, 0.0), 0.06, Color.WHITE, Vector3.ONE, 12)
		return kit.commit())


## Zorp's watering can: a round steel-blue can, a long spout toward -Z, a handle. ~0.3 m.
static func watering_can() -> ArrayMesh:
	return _cached("watering_can", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		_can_parts(kit, Transform3D.IDENTITY)
		return kit.commit())


## The can's parts, placed by `xf` (identity = the can Zorp carries).
static func _can_parts(kit: PlanetMeshKit, xf: Transform3D) -> void:
	kit.cylinder(xf * Vector3(0.0, -0.08, 0.0), 0.1, 0.09, 0.15, CAN, xf.basis, 14)
	kit.torus(xf * Vector3(0.0, 0.07, 0.0), 0.085, 0.012, CAN_DARK, xf.basis, 14)
	kit.torus(xf * Vector3(0.0, 0.07, 0.04), 0.07, 0.014, CAN_DARK, xf.basis * Basis(Vector3.FORWARD, PI * 0.5) * Basis(Vector3.UP, PI * 0.5), 12)
	kit.cylinder(xf * Vector3(0.0, -0.04, -0.07), 0.025, 0.016, 0.2, CAN, xf.basis * Basis(Vector3.RIGHT, -1.0), 8)
	kit.sphere(xf * Vector3(0.0, 0.07, -0.24), 0.03, CAN_DARK, Vector3(1.0, 1.0, 0.6), 8, xf.basis)


# ============================================================================================ SCRAPBOOK (15.5)
## THE SIGHTS AND THE BONUS ITEMS of spec 15.5 - all matte on the prop toon, with a few glowing bits in the
## planet's own cyan mushroom-spot material (the key the mushroom trees' spots already draw with). New
## colours, each inside docs/STYLE_GUIDE.md (S <= 0.60, V <= 0.92):
const GNOME_BODY := Color("#bfb3d0")   # S 0.14 V 0.82: spore fluff, lilac-cream (a shade under the beard)
const GNOME_BEARD := Color("#e0d8e6")  # S 0.06 V 0.90
const GNOME_BOOT := Color("#7a6a94")   # S 0.29 V 0.58
const SPROUT := Color("#86ab98")       # the hoppers' sage (S 0.22 V 0.67)
## The great ring's stems: a shade under the fairy rings' RING_STEM (V 0.87), which on seven stems a
## metre tall read near-white in the phone frame (c2zorp_out/shots_day2/great_ring_viewfinder.png).
const GREAT_STEM := Color("#cbbfae")   # S 0.14 V 0.80


## THE GREAT MUSHROOM RING (a sight): seven big toadstools (0.45-0.85 m) round a circle of radius
## GREAT_RING_R and a small one between each pair. Origin at the ring's middle, on the ground. One mesh;
## its glowing cap spots are `great_ring_spots`. (A low mossy rim of squashed spheres was tried and read
## as flat purple saucers on the phone frame - c2zorp_out/shots_day/great_ring_viewfinder.png - so it went.)
const GREAT_RING_R := 1.35
const GREAT_RING_N := 7


static func _great_toadstool(i: int) -> Dictionary:
	var ang := TAU * float(i) / float(GREAT_RING_N) + 0.2 * sin(float(i) * 2.3)
	var h := 0.45 + 0.4 * (0.5 + 0.5 * sin(float(i) * 1.7 + 0.6))
	var cap_r := 0.2 + 0.18 * h
	return {"at": Vector3(cos(ang), 0.0, sin(ang)) * GREAT_RING_R, "h": h, "cap_r": cap_r}


static func great_ring() -> ArrayMesh:
	return _cached("great_ring", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var caps := [RING_CAP, CAP, RING_CAP_B]
		for i in GREAT_RING_N:
			var t := _great_toadstool(i)
			var c: Vector3 = t["at"]
			var h := float(t["h"])
			var cr := float(t["cap_r"])
			# a slightly bulging stem, then a soft domed cap with a pale gill ring
			kit.lathe(PackedVector2Array([Vector2(0.0, -0.05), Vector2(0.1, -0.05), Vector2(0.085, h * 0.45),
				Vector2(0.07, h), Vector2(0.0, h)]), 12, Transform3D(Basis.IDENTITY, c), GREAT_STEM, true)
			kit.lathe(PackedVector2Array([Vector2(0.0, h - 0.03), Vector2(cr * 0.95, h - 0.03), Vector2(cr, h)]), 16,
				Transform3D(Basis.IDENTITY, c), CAP_UNDER, false)
			kit.lathe(PackedVector2Array([Vector2(cr, h), Vector2(cr * 0.98, h + 0.05), Vector2(cr * 0.8, h + cr * 0.45),
				Vector2(cr * 0.45, h + cr * 0.68), Vector2(0.0, h + cr * 0.74)]), 16, Transform3D(Basis.IDENTITY, c), caps[i % 3], true)
			# the little one between this and the next
			var a2 := TAU * (float(i) + 0.5) / float(GREAT_RING_N)
			var c2 := Vector3(cos(a2), 0.0, sin(a2)) * GREAT_RING_R * 1.04
			kit.lathe(PackedVector2Array([Vector2(0.0, -0.03), Vector2(0.045, -0.03), Vector2(0.035, 0.14), Vector2(0.0, 0.14)]),
				8, Transform3D(Basis.IDENTITY, c2), RING_STEM, true)
			kit.lathe(PackedVector2Array([Vector2(0.0, 0.12), Vector2(0.11, 0.12), Vector2(0.09, 0.17), Vector2(0.0, 0.2)]),
				10, Transform3D(Basis.IDENTITY, c2), caps[(i + 1) % 3], true)
		return kit.commit())


## The big toadstools' glowing cap spots (the planet's cyan spot material; vertex colour white).
static func great_ring_spots() -> ArrayMesh:
	return _cached("great_ring_spots", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for i in GREAT_RING_N:
			var t := _great_toadstool(i)
			var c: Vector3 = t["at"]
			var h := float(t["h"])
			var cr := float(t["cap_r"])
			for k in 4:
				var a := TAU * float(k) / 4.0 + float(i)
				var rr := cr * (0.55 if k % 2 == 0 else 0.3)
				var y := h + cr * 0.74 * sqrt(maxf(1.0 - pow(rr / cr, 2.0), 0.0))
				kit.sphere(c + Vector3(cos(a) * rr, y, sin(a) * rr), 0.035 + 0.01 * float(k % 2), Color.WHITE, Vector3(1.0, 0.45, 1.0), 8)
		return kit.commit())


## A TINY GNOME MADE OF SPORES (a bonus item): a round fluffy body, a big fluffy beard, a tall mauve
## toadstool hat, two little boots, the house eyes. ~0.26 m tall, facing -Z, origin at its feet. Its
## glowing spores (on the hat and floating round it) are `spore_gnome_glow`.
static func spore_gnome() -> ArrayMesh:
	return _cached("spore_gnome", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.03 * sgn, 0.012, -0.012), 0.022, GNOME_BOOT, Vector3(1.0, 0.6, 1.4), 8)
		# the body: a few overlapping puffs, so it reads as a cloud of spores, not a ball
		kit.sphere(Vector3(0.0, 0.065, 0.0), 0.058, GNOME_BODY, Vector3(1.0, 0.95, 0.95), 12)
		for k in 5:
			var a := TAU * float(k) / 5.0 + 0.4
			kit.sphere(Vector3(cos(a) * 0.045, 0.06 + 0.012 * float(k % 2), sin(a) * 0.04), 0.028, GNOME_BODY, Vector3.ONE, 8)
		# the head and the beard (the beard spills down the front)
		kit.sphere(Vector3(0.0, 0.14, 0.0), 0.042, GNOME_BODY, Vector3.ONE, 12)
		for k in 7:
			var x := (float(k) - 3.0) * 0.013
			kit.sphere(Vector3(x, 0.112 - 0.012 * absf(float(k) - 3.0) * 0.4, -0.032), 0.02 + 0.004 * float(k % 2), GNOME_BEARD, Vector3(1.0, 1.1, 0.8), 8)
		kit.sphere(Vector3(0.0, 0.085, -0.045), 0.022, GNOME_BEARD, Vector3(1.0, 1.2, 0.8), 8)
		kit.sphere(Vector3(0.0, 0.14, -0.042), 0.013, PETAL, Vector3.ONE, 8)   # the nose
		_eyes(kit, Vector3(0.0, 0.155, -0.036), 0.036, 0.009)
		# the hat: a floppy toadstool cone with a pale band
		kit.torus(Vector3(0.0, 0.168, 0.0), 0.04, 0.008, CAP_UNDER, Basis.IDENTITY, 12)
		kit.lathe(PackedVector2Array([Vector2(0.046, 0.165), Vector2(0.042, 0.2), Vector2(0.028, 0.235),
			Vector2(0.012, 0.26), Vector2(0.0, 0.268)]), 12, Transform3D(Basis(Vector3.RIGHT, 0.15), Vector3.ZERO), CAP, true)
		return kit.commit())


## The gnome's glowing spores: dots on its hat and a few floating round it (vertex colour white).
static func spore_gnome_glow() -> ArrayMesh:
	return _cached("spore_gnome_glow", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for p: Vector3 in [Vector3(0.025, 0.2, -0.012), Vector3(-0.022, 0.215, 0.0), Vector3(0.006, 0.238, -0.002)]:
			kit.sphere(p, 0.008, Color.WHITE, Vector3.ONE, 6)
		for p: Vector3 in [Vector3(0.09, 0.16, -0.02), Vector3(-0.08, 0.2, 0.03), Vector3(0.06, 0.27, 0.04),
				Vector3(-0.05, 0.1, -0.07), Vector3(0.1, 0.07, 0.05)]:
			kit.sphere(p, 0.011, Color.WHITE, Vector3.ONE, 6)
		return kit.commit())


## ZORP'S WATERING CAN, UPSIDE DOWN (a bonus item): the can he carries, left upside down in the grass -
## its dark base on top, the spout's nose down in the grass - with tiny toadstools and a sprout grown up
## round it. The spout points along -Z, so seen from the side (local +-X) it is a can standing on its head.
## Origin on the ground.
static func can_upside_down() -> ArrayMesh:
	return _cached("can_upside_down", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# flipped about its spout's axis, sat on its rim and tipped onto the spout's nose
		var xf := Transform3D(Basis(Vector3.RIGHT, -0.22) * Basis(Vector3.FORWARD, PI), Vector3(0.0, 0.1, 0.0)).scaled_local(Vector3.ONE * 1.3)
		_can_parts(kit, xf)
		# the can's base, now its top: a dark disc, so it reads as a can the wrong way up
		kit.cylinder(xf * Vector3(0.0, -0.085, 0.0), 0.095, 0.095, 0.012, CAN_DARK, xf.basis * Basis(Vector3.RIGHT, PI), 14)
		for k in 4:
			var a: float = [0.2, 2.9, 3.5, 1.2][k]
			var c: Vector3 = Vector3(cos(a), 0.0, sin(a)) * float([0.2, 0.19, 0.24, 0.21][k])
			var sc: float = [0.7, 0.9, 0.55, 0.6][k]
			kit.lathe(PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.03, -0.02), Vector2(0.024, 0.09), Vector2(0.0, 0.09)]),
				8, Transform3D(Basis.from_scale(Vector3.ONE * sc), c), RING_STEM, true)
			kit.lathe(PackedVector2Array([Vector2(0.0, 0.075), Vector2(0.075, 0.075), Vector2(0.06, 0.11), Vector2(0.0, 0.13)]),
				10, Transform3D(Basis.from_scale(Vector3.ONE * sc), c), [RING_CAP, CAP, RING_CAP_B, CAP][k], true)
		# a sprout poking up beside it
		_limb(kit, Vector3(-0.17, 0.0, 0.08), Vector3(-0.18, 0.11, 0.09), 0.008, SPROUT)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(-0.18 + 0.025 * sgn, 0.115, 0.09), 0.022, SPROUT, Vector3(1.2, 0.3, 0.7), 8, Basis(Vector3.FORWARD, 0.4 * sgn))
		return kit.commit())


## A HEART-SHAPED CRYSTAL (a bonus item): two rounded lobes over a point, upright, facing -Z, ~0.22 m
## tall, with two little shards at its foot. Drawn in the planet's own pink crystal material (vertex
## colour white), so it is one of the planet's crystals, not a new material.
static func heart_crystal() -> ArrayMesh:
	return _cached("heart_crystal", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var flat := Vector3(1.0, 1.0, 0.5)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.05 * sgn, 0.16, 0.0), 0.062, Color.WHITE, flat, 10)
		# the point: a cone from the lobes down to the tip, flattened like the lobes
		kit.cylinder(Vector3(0.0, 0.03, 0.0), 0.004, 0.1, 0.13, Color.WHITE, Basis.from_scale(Vector3(1.0, 1.0, 0.5)), 10)
		for sgn in [-1.0, 1.0]:
			kit.lathe(PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.02, -0.02), Vector2(0.022, 0.05), Vector2(0.0, 0.09)]), 6,
				Transform3D(Basis(Vector3.FORWARD, 0.4 * sgn), Vector3(0.07 * sgn, 0.0, 0.03)), Color.WHITE, false)
		return kit.commit())


# ============================================================================================ THE GREAT BLOOM
## The stem, 2.4 m tall with two broad leaves at its foot; the head's seat is at BLOOM_HEAD.
const BLOOM_HEAD := Vector3(0.0, 2.4, 0.0)


static func bloom_stem() -> ArrayMesh:
	return _cached("bloom_stem", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.05, 0.0), 0.34, BLOOM_STEM.darkened(0.12), Vector3(1.0, 0.4, 1.0), 14)
		var pts := [Vector3.ZERO, Vector3(0.06, 0.8, 0.02), Vector3(-0.05, 1.65, -0.03), BLOOM_HEAD]
		for i in range(1, pts.size()):
			_limb(kit, pts[i - 1], pts[i], 0.12 - 0.02 * float(i), BLOOM_STEM)
		for sgn in [-1.0, 1.0]:
			var b := Basis(Vector3.FORWARD, 0.55 * sgn)
			kit.sphere(Vector3(0.42 * sgn, 0.28, 0.0), 0.36, BLOOM_LEAF, Vector3(1.4, 0.18, 0.6), 14, b)
		# the calyx under the head
		kit.sphere(BLOOM_HEAD + Vector3(0.0, -0.08, 0.0), 0.2, BLOOM_STEM, Vector3(1.0, 0.6, 1.0), 12)
		return kit.commit())


## One big petal, its root at the origin, pointing up +Y, its face toward -Z. ~1.1 m long.
static func bloom_petal() -> ArrayMesh:
	return _cached("bloom_petal", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.5, 0.0), 0.5, BLOOM_PETAL, Vector3(0.62, 1.1, 0.16), 16)
		kit.sphere(Vector3(0.0, 0.82, -0.03), 0.24, BLOOM_PETAL_TIP, Vector3(0.95, 0.9, 0.2), 12)
		return kit.commit())


## The Great Bloom's glowing heart (the planet's cyan mushroom-spot material; vertex colour white).
static func bloom_core() -> ArrayMesh:
	return _cached("bloom_core", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.1, 0.0), 0.3, Color.WHITE, Vector3(1.0, 0.55, 1.0), 16)
		for i in 7:
			var ang := TAU * float(i) / 7.0
			kit.sphere(Vector3(cos(ang) * 0.22, 0.26, sin(ang) * 0.22), 0.05, Color.WHITE, Vector3.ONE, 8)
		return kit.commit())

