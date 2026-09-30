extends RefCounted
## THE SHAPES OF THE TANGLE'S SAFARI (docs/JUNGLE_PLANET_SPEC.md 4, builder J2 SAFARI). Static builders
## only, the same way Fen's are made (worlds/fen_meshes.gd): every creature and event prop is ONE
## vertex-coloured ArrayMesh made with PlanetMeshKit, drawn with the matte prop material the planets'
## own props draw with; parts that glow are separate meshes drawn with the planet's own glow material
## (PlanetPropMeshes.crystal_material, the one J1's glow beads use), and parts that move on their own (a
## hopper's throat, a glowtail's tail bulb, a bloom's petals, the grazer's neck and legs) are separate
## meshes posed by code. No class_name: the planet's own props already own `JungleMeshes`.
##
## Conventions (PlanetMeshKit's): prop-local, +Y up, origin at the ground contact (or, for a flier,
## its middle), the creature faces -Z. Colours are sRGB hex inside docs/STYLE_GUIDE.md's gates: no
## large swatch above S 0.60 (glow bulbs and eyes are small accents), nothing whiter than V 0.92.
## The Tangle is teal and green under a violet canopy (jungle.tres, jungle_props.gd), so the creatures
## separate by HUE: warm peach hoppers under a lily-leaf hat, dusk-violet glowtails with an amber tail
## lamp, cream spore-puffs, a lilac-grey grazer, magenta-dusk snail shells. Cute and structured: soft
## domes and the same small dark eyes the neighbours have (the house eye).
##
## Built once per process and cached here (a second safari reuses them).

const EYE := Color("#1e2130")
const EYE_HI := Color("#e6e2ea")
## Lily-hopper: a round peach hopper wearing a lily leaf for a hat.
const HOP := Color("#cf9a7e")          # S 0.39 V 0.81
const HOP_DARK := Color("#b07c64")
const HOP_BELLY := Color("#e6d4bf")    # V 0.90
const THROAT := Color("#e8cdb6")       # the croak sac, V 0.91
const LEAF_HAT := Color("#5e9476")     # jungle_props LILY
const LEAF_HAT_RIM := Color("#4b7a61")
const LEAF_VEIN := Color("#8fb89c")
## Glowtail: dusk-violet fur, a pale face, big soft ears and an amber lamp at the end of its tail.
const TAIL_FUR := Color("#877e9f")     # S 0.21 V 0.62 (at S 0.28 it rendered S 0.51 mean)
const TAIL_FUR_DARK := Color("#6a5f8c")
const TAIL_FACE := Color("#dcd2e2")    # V 0.89
const TAIL_EAR := Color("#c79aa8")     # inner ear, S 0.23
const TAIL_STRIPE := Color("#5b5178")
## Spore-puff: a cream seed-ball on little stalks, a teal heart.
const PUFF := Color("#e4dcb4")         # S 0.21 V 0.89
const PUFF_TIP := Color("#d8cc98")
const PUFF_CORE := Color("#9cc3b4")
## Lantern-snail: pale sage body, a dusk-magenta shell with a glowing window.
const SNAIL := Color("#aebfa2")        # S 0.15 V 0.75
const SNAIL_DARK := Color("#8c9e82")
const SHELL := Color("#9c6f8c")        # S 0.29 V 0.61 (jungle_props POD_SHELL family)
const SHELL_DARK := Color("#7c5570")
## Glimmers (the swarm): tiny amber fliers.
const GLIM := Color("#caa06a")         # S 0.47 V 0.79 (tiny)
const GLIM_WING := Color("#e4d8c0")
## The burst-bud: violet-magenta petals, a leafy stalk.
const PETAL := Color("#c08cb4")        # S 0.27 V 0.75
const PETAL_TIP := Color("#d8b0cc")
const PETAL_BASE := Color("#8a5f86")
const STALK := Color("#6d8a6c")
const STALK_LEAF := Color("#5f8f72")
## The giant bloom: warm apricot petals with a teal-lit heart.
const GIANT := Color("#d4ae92")        # S 0.31 V 0.83 (at S 0.43 it rendered S 0.52 mean, p90 0.73)
const GIANT_TIP := Color("#e2cab4")
const GIANT_BASE := Color("#a67e70")
## The canopy grazer: lilac-grey, a pale belly, leafy ear-fronds and a row of teal glow spots.
const GRAZE := Color("#8a8299")        # S 0.15 V 0.60 (renders pale under the planet light: kept low)
const GRAZE_DARK := Color("#6c6480")
const GRAZE_BELLY := Color("#b3aabb")
const GRAZE_FROND := Color("#6f9c80")
const GRAZE_HOOF := Color("#5d5566")
## The bonus pages.
const REED := Color("#aba087")         # the reed hat, S 0.21 V 0.67 (S 0.28 rendered 0.52)
const REED_DARK := Color("#94845a")
const RIBBON := Color("#9a6f8e")
const SHELL_HOUSE := Color("#cdb39a")  # an old pale shell, S 0.25 V 0.80
const SHELL_HOUSE_DARK := Color("#a88c74")
const DOOR := Color("#7a5a4c")
const WINDOW := Color("#e2c27e")
const HEART_PAD := Color("#6c9e7a")
const HEART_PAD_RIM := Color("#557f62")
const HEART_FLOWER := Color("#d8a0b8")

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


## A flat leaf disc with a notch (a lily pad), in the XZ plane at height `y`, notch toward +Z.
static func _lily_disc(kit: PlanetMeshKit, xf: Transform3D, r: float, top: Color, rim: Color, vein: Color, notch: float = 0.5) -> void:
	var c := Vector3.ZERO
	var n := 18
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		# the notch: skip the wedge round +Z
		var mid := (a0 + a1) * 0.5
		if absf(wrapf(mid - PI * 0.5, -PI, PI)) < notch * 0.5:
			continue
		var p0 := c + Vector3(cos(a0), 0.0, sin(a0)) * r
		var p1 := c + Vector3(cos(a1), 0.0, sin(a1)) * r
		kit.triangle(xf * (c + Vector3(0.0, 0.012, 0.0)), xf * p0, xf * p1, top if i % 2 == 0 else top.lerp(rim, 0.25))
		# a thin rolled rim
		kit.quad(xf * p0, xf * p1, xf * (p1 - Vector3(0.0, 0.02, 0.0)), xf * (p0 - Vector3(0.0, 0.02, 0.0)), rim)
	# veins
	for k in 5:
		var a := -PI * 0.5 + (float(k) - 2.0) * 0.55
		var d := Vector3(cos(a), 0.0, sin(a))
		var s := Vector3(-d.z, 0.0, d.x) * 0.006
		kit.quad(xf * (c + Vector3(0.0, 0.016, 0.0) - s), xf * (c + d * r * 0.85 + Vector3(0.0, 0.016, 0.0) - s),
			xf * (c + d * r * 0.85 + Vector3(0.0, 0.016, 0.0) + s), xf * (c + Vector3(0.0, 0.016, 0.0) + s), vein)


# ============================================================================================ LILY-HOPPER
## A round peach hopper, ~0.32 m wide, 0.3 m tall with its hat: a lily leaf worn tipped back on its
## head. Big eye bumps, a wide smile, folded legs. Faces -Z.
static func hopper() -> ArrayMesh:
	return _cached("hopper", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.115, 0.02), 0.155, HOP, Vector3(1.05, 0.74, 1.1), 18)
		kit.sphere(Vector3(0.0, 0.08, -0.05), 0.11, HOP_BELLY, Vector3(0.95, 0.62, 0.8), 14)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.125 * sgn, 0.07, 0.08), 0.072, HOP_DARK, Vector3(0.85, 0.7, 1.35), 10)
			kit.sphere(Vector3(0.145 * sgn, 0.015, 0.0), 0.056, HOP_DARK, Vector3(1.1, 0.3, 1.5), 10)
			kit.sphere(Vector3(0.07 * sgn, 0.015, -0.13), 0.032, HOP_DARK, Vector3(1.1, 0.4, 1.3), 8)
			kit.sphere(Vector3(0.068 * sgn, 0.205, -0.07), 0.054, HOP, Vector3.ONE, 12)
			# two little freckles of the jungle's teal on its cheeks
			kit.sphere(Vector3(0.1 * sgn, 0.13, -0.12), 0.018, Color("#7fb3a0"), Vector3(1.0, 1.0, 0.4), 6)
		_eyes(kit, Vector3(0.0, 0.21, -0.114), 0.136, 0.031)
		kit.sphere(Vector3(0.0, 0.125, -0.158), 0.052, HOP_DARK, Vector3(1.4, 0.12, 0.3), 8)
		# THE HAT: a lily leaf, tipped back, with a little stem curling up at the notch
		_lily_disc(kit, Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0.0, 0.245, 0.03)), 0.13, LEAF_HAT, LEAF_HAT_RIM, LEAF_VEIN, 0.6)
		_limb(kit, Vector3(0.0, 0.255, 0.13), Vector3(0.0, 0.3, 0.16), 0.008, LEAF_HAT_RIM, 5)
		return kit.commit())


## The croak sac under the chin; code scales it up for a croak.
static func hopper_throat() -> ArrayMesh:
	return _cached("hopper_throat", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3.ZERO, 0.062, THROAT, Vector3(1.1, 0.8, 1.0), 12)
		return kit.commit())
const HOPPER_THROAT_AT := Vector3(0.0, 0.09, -0.135)


# ============================================================================================ GLOWTAIL
## A small climber sitting up, ~0.42 m tall to the ear tips: a round dusk-violet body, a pale face with
## big eyes, round ears, little hands held in front, and a long striped tail curling up behind it in an
## S to one side. The lamp at the tail's end is `glowtail_bulb`, posed at GLOWTAIL_BULB_AT. Faces -Z; origin at its
## seat (for one clinging to a trunk, the trunk is behind it, at +Z).
static func glowtail() -> ArrayMesh:
	return _cached("glowtail", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# body and belly
		kit.sphere(Vector3(0.0, 0.13, 0.0), 0.12, TAIL_FUR, Vector3(1.0, 1.1, 0.95), 16)
		kit.sphere(Vector3(0.0, 0.12, -0.05), 0.085, TAIL_FACE, Vector3(0.95, 1.05, 0.6), 12)
		# head
		kit.sphere(Vector3(0.0, 0.29, -0.01), 0.1, TAIL_FUR, Vector3(1.1, 0.95, 1.0), 16)
		kit.sphere(Vector3(0.0, 0.275, -0.065), 0.075, TAIL_FACE, Vector3(1.15, 0.9, 0.62), 14)
		for sgn in [-1.0, 1.0]:
			# round ears with a pink inside
			kit.sphere(Vector3(0.095 * sgn, 0.37, 0.0), 0.058, TAIL_FUR, Vector3(1.0, 1.0, 0.45), 12)
			kit.sphere(Vector3(0.095 * sgn, 0.37, -0.018), 0.036, TAIL_EAR, Vector3(1.0, 1.0, 0.3), 10)
			# hands held in front, feet gripping
			kit.sphere(Vector3(0.05 * sgn, 0.13, -0.1), 0.028, TAIL_FUR_DARK, Vector3(1.0, 0.85, 1.0), 8)
			kit.sphere(Vector3(0.07 * sgn, 0.02, -0.06), 0.034, TAIL_FUR_DARK, Vector3(1.0, 0.55, 1.3), 8)
			# dark stripes on the flanks
			kit.sphere(Vector3(0.11 * sgn, 0.16, 0.02), 0.03, TAIL_STRIPE, Vector3(0.4, 1.3, 1.0), 6)
		_eyes(kit, Vector3(0.0, 0.29, -0.108), 0.085, 0.029)
		kit.sphere(Vector3(0.0, 0.262, -0.118), 0.014, TAIL_EAR.darkened(0.25), Vector3(1.2, 0.9, 0.8), 6)
		# the tail: from the seat, back and up in an S, striped
		# (it curls out to the side, not behind, so a glowtail clinging to a trunk shows its tail)
		# ONE smooth tapering tube with its stripes painted on (it was ten stacked beads, 2026-09-29), rooted
		# inside the body and ending inside the lamp
		var ctrl: Array = [[Vector3(0.035, 0.09, 0.035), Vector2(0.036, 0.036)]]
		for i in 6:
			var t := float(i) / 5.0
			var rr := 0.034 - 0.015 * t
			ctrl.append([Vector3(0.07 + 0.11 * sin(t * PI * 0.9), 0.05 + 0.45 * t, 0.07 - 0.03 * t), Vector2(rr, rr)])
		var g := Tube.new()
		var stripes := func(_p: Vector3, _d: Vector3, f: float) -> Color:
			var band := 0.5 + 0.5 * sin(f * TAU * 5.0)
			return TAIL_FUR.lerp(TAIL_STRIPE, smoothstep(0.35, 0.65, band) * smoothstep(0.08, 0.2, f))
		_sweep(g, _spine(ctrl, 6), 10, stripes, 1.0, 1.0)
		return g.finish(kit))


## The lamp at the end of a glowtail's tail (drawn with the glow material).
static func glowtail_bulb() -> ArrayMesh:
	return _cached("glowtail_bulb", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3.ZERO, 0.045, Color.WHITE, Vector3(1.0, 1.15, 1.0), 10)
		return kit.commit())
const GLOWTAIL_BULB_AT := Vector3(0.105, 0.53, 0.04)


# ============================================================================================ SPORE-PUFF
## A drifting seed-ball ~0.34 m across: a teal heart, a ruff of short stalks each tipped with a cream
## tuft, two dark eyes. Origin at its middle, faces -Z. Its light is a glow sprite posed by code.
static func puff() -> ArrayMesh:
	return _cached("puff", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3.ZERO, 0.1, PUFF, Vector3(1.0, 0.95, 1.0), 16)
		kit.sphere(Vector3(0.0, 0.0, 0.01), 0.07, PUFF_CORE, Vector3.ONE, 10)
		# a fibonacci ruff of tufts, leaving the face clear
		var n := 30
		for i in n:
			var y := 1.0 - 2.0 * (float(i) + 0.5) / float(n)
			var rr := sqrt(maxf(1.0 - y * y, 0.0))
			var a := float(i) * 2.39996
			var d := Vector3(cos(a) * rr, y, sin(a) * rr)
			if d.z < -0.55 and absf(d.y) < 0.55:
				continue
			_limb(kit, d * 0.08, d * 0.15, 0.006, PUFF_TIP, 4)
			kit.sphere(d * 0.165, 0.028, PUFF if i % 3 else PUFF_TIP, Vector3.ONE, 7)
		kit.sphere(Vector3(0.0, 0.0, -0.085), 0.07, PUFF, Vector3(1.0, 0.95, 0.45), 12)
		_eyes(kit, Vector3(0.0, 0.015, -0.112), 0.07, 0.02)
		# a tiny smile
		kit.sphere(Vector3(0.0, -0.022, -0.113), 0.018, PUFF_CORE.darkened(0.35), Vector3(1.3, 0.25, 0.3), 6)
		return kit.commit())


# ============================================================================================ LANTERN-SNAIL
## A slow snail ~0.4 m long: a pale sage body with two eye stalks, and a round magenta-dusk shell with
## a lit window (`snail_glow`, the same frame). Faces -Z, origin at the ground.
static func snail() -> ArrayMesh:
	return _cached("snail", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.04, 0.0), 0.08, SNAIL, Vector3(1.0, 0.5, 2.4), 14)
		kit.sphere(Vector3(0.0, 0.085, -0.15), 0.065, SNAIL, Vector3(1.0, 1.0, 1.0), 12)
		for sgn in [-1.0, 1.0]:
			_limb(kit, Vector3(0.025 * sgn, 0.13, -0.16), Vector3(0.045 * sgn, 0.22, -0.18), 0.011, SNAIL_DARK, 5)
			kit.sphere(Vector3(0.045 * sgn, 0.225, -0.18), 0.024, SNAIL, Vector3.ONE, 8)
		_eyes(kit, Vector3(0.0, 0.228, -0.2), 0.09, 0.013)
		kit.sphere(Vector3(0.0, 0.07, -0.21), 0.016, SNAIL_DARK, Vector3(1.4, 0.3, 0.4), 6)
		# the shell: a stack of shrinking rings, coiled, standing on the back
		var c := Vector3(0.0, 0.17, 0.05)
		kit.sphere(c, 0.12, SHELL, Vector3(0.7, 1.0, 1.0), 16)
		for k in 3:
			var r := 0.1 - 0.028 * float(k)
			kit.torus(c + Vector3(0.045 + 0.012 * float(k), 0.0, 0.0), r, 0.022, SHELL_DARK if k % 2 == 0 else SHELL,
				Basis(Vector3.FORWARD, PI * 0.5), 14)
		return kit.commit())


## The shell's lit window (glow material), snail-local.
static func snail_glow() -> ArrayMesh:
	return _cached("snail_glow", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.082 * sgn, 0.17, 0.05), 0.05, Color.WHITE, Vector3(0.35, 1.0, 1.0), 10)
		return kit.commit())


# ============================================================================================ GLIMMER
## A tiny amber flier ~0.14 m across, a glowing tail (a glow sprite posed by code). Faces -Z, origin at
## its middle.
static func glimmer() -> ArrayMesh:
	return _cached("glimmer", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3.ZERO, 0.025, GLIM, Vector3(0.9, 0.9, 1.9), 8)
		kit.sphere(Vector3(0.0, 0.004, -0.04), 0.02, GLIM.darkened(0.2), Vector3.ONE, 8)
		_eyes(kit, Vector3(0.0, 0.01, -0.056), 0.022, 0.007)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.04 * sgn, 0.012, -0.005), 0.038, GLIM_WING, Vector3(1.0, 0.12, 0.7), 8)
		return kit.commit())


# ============================================================================================ BURST-BUD
## The stalk of a burst-bud, ~1.0 m to the bud's base, with two broad leaves. Origin at the ground.
static func bud_stalk() -> ArrayMesh:
	return _cached("bud_stalk", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# one smooth stalk (it was three stacked tubes with a bead at each joint, 2026-09-29), from just under
		# the ground up into the bud's base
		var g := Tube.new()
		var stalk := func(_p: Vector3, _d: Vector3, _f: float) -> Color:
			return STALK
		_sweep(g, _spine([[Vector3(0.0, -0.05, 0.0), Vector2(0.046, 0.046)], [Vector3(0.04, 0.35, 0.0), Vector2(0.041, 0.041)],
			[Vector3(-0.02, 0.7, 0.02), Vector2(0.034, 0.034)], [Vector3(0.0, BUD_AT.y - 0.04, 0.0), Vector2(0.028, 0.028)]], 6),
			10, stalk, 1.0, 1.0, Vector3.FORWARD)
		kit.sphere(BUD_AT - Vector3(0.0, 0.04, 0.0), 0.09, PETAL_BASE, Vector3(1.0, 0.7, 1.0), 12)
		for sgn in [-1.0, 1.0]:
			var base := Vector3(0.02 * sgn, 0.25, 0.0)
			var tip := Vector3(0.42 * sgn, 0.45, 0.08 * sgn)
			var mid := base.lerp(tip, 0.5) + Vector3(0.0, 0.08, 0.0)
			var side := Vector3(0.0, 0.0, 0.12)
			kit.quad(base, mid - side, tip, mid + side, STALK_LEAF)
			kit.quad(base, mid + side * 0.2 + Vector3(0.0, 0.01, 0.0), tip, mid - side * 0.2 + Vector3(0.0, 0.01, 0.0), STALK_LEAF.lightened(0.12))
		return g.finish(kit))
const BUD_AT := Vector3(0.0, 1.0, 0.0)


## One petal, ~0.5 m long along +Y from its base (origin), cupped toward -Z. Code turns it from closed
## (standing up) to open (laid out). `giant` = the giant bloom's colours.
static func petal(giant: bool) -> ArrayMesh:
	return _cached("petal_%s" % str(giant), func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var base_c := GIANT_BASE if giant else PETAL_BASE
		var body_c := GIANT if giant else PETAL
		var tip_c := GIANT_TIP if giant else PETAL_TIP
		var n := 6
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		for i in n + 1:
			var t := float(i) / float(n)
			var w := 0.16 * pow(sin(PI * (0.08 + 0.84 * t)), 0.7)
			var cup := -0.06 * sin(PI * t)
			var y := 0.5 * t
			var l := Vector3(-w, y, cup + 0.04 * (w / 0.16))
			var r := Vector3(w, y, cup + 0.04 * (w / 0.16))
			var mid := Vector3(0.0, y, cup)
			if i > 0:
				var c := base_c.lerp(body_c, clampf(t * 2.0, 0.0, 1.0)).lerp(tip_c, clampf(t * 2.0 - 1.0, 0.0, 1.0))
				var pmid := Vector3(0.0, 0.5 * float(i - 1) / float(n), -0.06 * sin(PI * float(i - 1) / float(n)))
				kit.quad(prev_l, l, mid, pmid, c)
				kit.quad(pmid, mid, r, prev_r, c.darkened(0.05))
			prev_l = l
			prev_r = r
		return kit.commit())


## A bloom's glowing heart (glow material): a ring of stamens round a soft dome.
static func bloom_heart() -> ArrayMesh:
	return _cached("bloom_heart", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3.ZERO, 0.07, Color.WHITE, Vector3(1.0, 0.6, 1.0), 12)
		for k in 7:
			var a := TAU * float(k) / 7.0
			var o := Vector3(cos(a), 0.0, sin(a))
			_limb(kit, o * 0.03, o * 0.1 + Vector3(0.0, 0.1, 0.0), 0.006, Color.WHITE, 4)
			kit.sphere(o * 0.1 + Vector3(0.0, 0.1, 0.0), 0.016, Color.WHITE, Vector3.ONE, 6)
		return kit.commit())


# ============================================================================================ GIANT BLOOM
## The giant bloom's base: a squat knot of roots and three huge leaves, ~0.7 m tall. The petals
## (`petal(true)`, scaled up) and the heart are posed by code at GIANT_HEART_AT.
static func giant_base() -> ArrayMesh:
	return _cached("giant_base", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.25, 0.0), 0.42, STALK.darkened(0.1), Vector3(1.0, 0.75, 1.0), 16)
		kit.sphere(Vector3(0.0, 0.52, 0.0), 0.3, GIANT_BASE, Vector3(1.0, 0.55, 1.0), 14)
		for k in 5:
			var a := TAU * float(k) / 5.0 + 0.3
			var o := Vector3(cos(a), 0.0, sin(a))
			_limb(kit, o * 0.3 + Vector3(0.0, 0.2, 0.0), o * 0.75 + Vector3(0.0, -0.05, 0.0), 0.07, STALK.darkened(0.2), 7)
		for k in 3:
			var a := TAU * float(k) / 3.0
			var o := Vector3(cos(a), 0.0, sin(a))
			var s := Vector3(-o.z, 0.0, o.x)
			var b := o * 0.3 + Vector3(0.0, 0.3, 0.0)
			var tip := o * 1.6 + Vector3(0.0, 0.1, 0.0)
			var mid := b.lerp(tip, 0.45) + Vector3(0.0, 0.18, 0.0)
			kit.quad(b, mid - s * 0.45, tip, mid + s * 0.45, STALK_LEAF)
			kit.quad(b + Vector3(0.0, 0.01, 0.0), mid + s * 0.08 + Vector3(0.0, 0.02, 0.0), tip, mid - s * 0.08 + Vector3(0.0, 0.02, 0.0), STALK_LEAF.lightened(0.12))
		return kit.commit())
const GIANT_HEART_AT := Vector3(0.0, 0.62, 0.0)


# ============================================================================================ SMOOTH TUBES
## ONE-PIECE SHAPES (builder L2 GRAZER, 2026-09-29). The user: "the dinosaur is all in pieces and not fully
## smoothly connected". The old grazer was stacked flat-ended cylinders (PlanetMeshKit.cylinder is a
## hard-banded lathe), a belly ball whose rim showed as a skirt, dapples and glow spots floating off the
## barrel's ends, and legs and neck hinged at points ON the body's skin, so every swing opened a seam.
## Now a creature's trunk is ONE swept tube (body into tail, neck, each leg) with smooth normals and round
## caps, its colours painted on the vertices (the belly, the dapples, the hooves) instead of stuck on as
## extra balls, and every moving part pivots on a ball buried inside the body.

## A tube accumulator merged into a PlanetMeshKit's surface (one mesh, one draw call).
class Tube:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var ix := PackedInt32Array()

	## The kit's shapes plus these tubes, as one ArrayMesh surface.
	func finish(kit: PlanetMeshKit) -> ArrayMesh:
		var km := kit.commit()
		var V := PackedVector3Array()
		var N := PackedVector3Array()
		var C := PackedColorArray()
		var UV := PackedVector2Array()
		var I := PackedInt32Array()
		if km.get_surface_count() > 0:
			var a := km.surface_get_arrays(0)
			V = a[Mesh.ARRAY_VERTEX]
			N = a[Mesh.ARRAY_NORMAL]
			C = a[Mesh.ARRAY_COLOR]
			UV = a[Mesh.ARRAY_TEX_UV]
			I = a[Mesh.ARRAY_INDEX]
		var base := V.size()
		V.append_array(v)
		N.append_array(n)
		C.append_array(c)
		for k in v.size():
			UV.append(Vector2.ZERO)
		for k in ix:
			I.append(base + k)
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = V
		arrays[Mesh.ARRAY_NORMAL] = N
		arrays[Mesh.ARRAY_COLOR] = C
		arrays[Mesh.ARRAY_TEX_UV] = UV
		arrays[Mesh.ARRAY_INDEX] = I
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m


static func _cr3(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)


static func _cr2(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)


## A Catmull-Rom spine through `ctrl` ([point, Vector2(half-width, half-height)] each), `steps` samples a span.
static func _spine(ctrl: Array, steps: int) -> Array:
	var ps := PackedVector3Array()
	var rs := PackedVector2Array()
	var m := ctrl.size()
	for i in m - 1:
		var a: Array = ctrl[maxi(i - 1, 0)]
		var b: Array = ctrl[i]
		var cc: Array = ctrl[i + 1]
		var d: Array = ctrl[mini(i + 2, m - 1)]
		for s in steps:
			var t := float(s) / float(steps)
			ps.append(_cr3(a[0], b[0], cc[0], d[0], t))
			rs.append(_cr2(a[1], b[1], cc[1], d[1], t))
	ps.append(ctrl[m - 1][0])
	rs.append(ctrl[m - 1][1])
	return [ps, rs]


## Sweeps an elliptical tube along a spine (from `_spine`), the spine lying in a plane square to `side`
## (every tube here runs in the creature's mid-plane or parallel to it, so the cross-section's "up" never
## twists). `cap0` / `cap1` round the ends off (1 = a half ball, 0.4 = a flattened sole, 0 = open).
## `paint(p, radial, f)` gives each vertex its sRGB colour from its position, its outward direction and
## how far along the spine it is (0..1). Normals come from the finished surface itself, so the shading is
## smooth across the whole tube and its caps. Returns the rings [centre, tangent, side, up, rx, ry].
static func _sweep(g: Tube, spine: Array, segs: int, paint: Callable, cap0: float = 1.0, cap1: float = 1.0, side: Vector3 = Vector3.RIGHT) -> Array:
	var ps: PackedVector3Array = spine[0]
	var rs: PackedVector2Array = spine[1]
	var cnt := ps.size()
	var rings: Array = []
	for i in cnt:
		var t := (ps[mini(i + 1, cnt - 1)] - ps[maxi(i - 1, 0)]).normalized()
		var s := (side - t * side.dot(t)).normalized()
		rings.append([ps[i], t, s, s.cross(t), rs[i].x, rs[i].y, float(i) / float(cnt - 1)])
	var all: Array = []
	const CAP := 6
	if cap0 > 0.0:
		var r0: Array = rings[0]
		var len0 := cap0 * (float(r0[4]) + float(r0[5])) * 0.5
		for k in range(CAP, 0, -1):
			var ph := PI * 0.5 * float(k) / float(CAP)
			all.append([r0[0] - r0[1] * len0 * sin(ph), r0[1], r0[2], r0[3], float(r0[4]) * cos(ph), float(r0[5]) * cos(ph), 0.0])
	all.append_array(rings)
	if cap1 > 0.0:
		var r1: Array = rings[cnt - 1]
		var len1 := cap1 * (float(r1[4]) + float(r1[5])) * 0.5
		for k in range(1, CAP + 1):
			var ph := PI * 0.5 * float(k) / float(CAP)
			all.append([r1[0] + r1[1] * len1 * sin(ph), r1[1], r1[2], r1[3], float(r1[4]) * cos(ph), float(r1[5]) * cos(ph), 1.0])
	var nr := all.size()
	var grid: Array = []
	for ri in nr:
		var r: Array = all[ri]
		var row := PackedVector3Array()
		for j in segs:
			var a := TAU * float(j) / float(segs)
			row.append(r[0] + (r[2] * cos(a) * float(r[4]) + r[3] * sin(a) * float(r[5])))
		grid.append(row)
	var base := g.v.size()
	for ri in nr:
		var r: Array = all[ri]
		var row: PackedVector3Array = grid[ri]
		var prev: PackedVector3Array = grid[maxi(ri - 1, 0)]
		var next: PackedVector3Array = grid[mini(ri + 1, nr - 1)]
		var degenerate := float(r[4]) < 0.0005 and float(r[5]) < 0.0005
		for j in segs:
			var a := TAU * float(j) / float(segs)
			var radial: Vector3 = (r[2] * cos(a) + r[3] * sin(a)).normalized()
			var nn: Vector3
			if degenerate:
				nn = -r[1] if ri == 0 else r[1]
			else:
				var da := row[(j + 1) % segs] - row[(j - 1 + segs) % segs]
				var ds := next[j] - prev[j]
				nn = da.cross(ds).normalized()
				if nn.dot(radial) < 0.0:
					nn = -nn
			var p := row[j]
			g.v.append(p)
			g.n.append(nn)
			g.c.append(PlanetMeshKit._lin(paint.call(p, radial, float(r[6]))))
	for ri in nr - 1:
		for j in segs:
			var a := base + ri * segs + j
			var b := base + ri * segs + (j + 1) % segs
			var cc := a + segs
			var d := b + segs
			# wind each triangle the way the kit does (front = clockwise seen from outside)
			var geo := (g.v[cc] - g.v[a]).cross(g.v[b] - g.v[a])
			if geo.dot(g.n[a] + g.n[b] + g.n[cc]) >= 0.0:
				g.ix.append_array(PackedInt32Array([a, b, cc, b, d, cc]))
			else:
				g.ix.append_array(PackedInt32Array([a, cc, b, b, cc, d]))
	return rings


## The point on a swept tube's skin at ring `ri`, `ang` radians round from its side (0 = +side,
## PI/2 = up), and the outward normal there. `inset` pushes it into the skin (a fraction of the eye/spot
## radius is sunk so nothing floats).
static func _skin(rings: Array, ri: int, ang: float, inset: float = 0.0) -> Array:
	var r: Array = rings[clampi(ri, 0, rings.size() - 1)]
	var s: Vector3 = r[2]
	var u: Vector3 = r[3]
	var rx := float(r[4])
	var ry := float(r[5])
	var p: Vector3 = r[0] + s * cos(ang) * rx + u * sin(ang) * ry
	var nn := (s * cos(ang) / maxf(rx, 0.001) + u * sin(ang) / maxf(ry, 0.001)).normalized()
	return [p - nn * inset, nn]


## The ring of `rings` nearest along the spine to `z` (body-local Z).
static func _ring_at_z(rings: Array, z: float) -> int:
	var best := 0
	var bd := INF
	for i in rings.size():
		var d := absf((rings[i][0] as Vector3).z - z)
		if d < bd:
			bd = d
			best = i
	return best


## A basis whose +Z is `nrm` (for a flattened ball laid on a skin: scale z small).
static func _on_skin(nrm: Vector3) -> Basis:
	var up := Vector3.UP if absf(nrm.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	var x := up.cross(nrm).normalized()
	return Basis(x, nrm.cross(x).normalized(), nrm)


## A painted soft spot: 1 inside `r0`, fading to 0 at `r1`.
static func _dab(p: Vector3, centre: Vector3, r0: float, r1: float) -> float:
	return 1.0 - smoothstep(r0, r1, p.distance_to(centre))


# ============================================================================================ CANOPY GRAZER
## A big, gentle long-neck, ~3 m long nose to tail and 3.5 m to the top of its head (x GRAZER_SCALE in the
## world): a round lilac-grey barrel that runs on into a tapering tail (one tube), a pale belly painted on,
## soft darker dapples, a ridge of little teal leaf-plates down the back, four stubby column legs with dark
## round feet, and a smooth neck up to a big round head with big eyes and leafy ear-fronds. Faces -Z,
## origin at the ground. The neck (grazer_neck) pivots at GRAZER_SHOULDER and each leg (grazer_leg) at
## its GRAZER_HIPS point: all five pivots are balls buried inside the barrel, so a swing never opens a gap.
const GRAZER_SHOULDER := Vector3(0.0, 1.5, -0.62)
const GRAZER_HIPS := [Vector3(-0.3, 1.12, -0.36), Vector3(0.3, 1.12, -0.36), Vector3(-0.3, 1.12, 0.5), Vector3(0.3, 1.12, 0.5)]
## Neck-local (the shoulder pivot is the origin): the middle of the head.
const GRAZER_HEAD := Vector3(0.0, 1.98, -0.58)
const GRAZER_LEG_R := 0.2


## The barrel-and-tail spine, cached so the glow spots sit on the same skin the body is built from.
static func _grazer_body_rings() -> Array:
	if _cache.has("grazer_rings"):
		return _cache["grazer_rings"]
	var spine := _spine([
		[Vector3(0.0, 1.36, -0.62), Vector2(0.44, 0.42)],
		[Vector3(0.0, 1.32, -0.3), Vector2(0.6, 0.56)],
		[Vector3(0.0, 1.3, 0.12), Vector2(0.66, 0.6)],
		[Vector3(0.0, 1.32, 0.55), Vector2(0.58, 0.55)],
		[Vector3(0.0, 1.3, 0.92), Vector2(0.4, 0.4)],
		[Vector3(0.0, 1.14, 1.26), Vector2(0.22, 0.22)],
		[Vector3(0.0, 0.9, 1.56), Vector2(0.13, 0.13)],
		[Vector3(0.0, 0.76, 1.84), Vector2(0.085, 0.085)],
		[Vector3(0.0, 0.8, 2.06), Vector2(0.06, 0.06)],
	], 5)
	var g := Tube.new()
	# dapple centres ON the skin: high on each flank, alternating up and down along the barrel
	var sp_ps: PackedVector3Array = spine[0]
	var sp_rs: PackedVector2Array = spine[1]
	var dapples: Array = []
	for k in 5:
		var z := -0.35 + 0.26 * float(k)
		var bi := 0
		for i in sp_ps.size():
			if absf(sp_ps[i].z - z) < absf(sp_ps[bi].z - z):
				bi = i
		var a := 0.42 + 0.16 * float(k % 2)
		for sgn in [-1.0, 1.0]:
			dapples.append(sp_ps[bi] + Vector3(sgn * sp_rs[bi].x * cos(a), sp_rs[bi].y * sin(a), 0.0))
	var paint := func(p: Vector3, d: Vector3, _f: float) -> Color:
		var col := GRAZE
		# the belly: pale underneath, fading out toward the chest and the tail
		var belly := smoothstep(-0.2, -0.7, d.y) * (1.0 - smoothstep(0.7, 1.15, p.z)) * smoothstep(-0.75, -0.4, p.z)
		col = col.lerp(GRAZE_BELLY, belly)
		# the tail darkens toward its tip
		col = col.lerp(GRAZE_DARK, smoothstep(1.2, 1.95, p.z) * 0.7)
		# soft darker dapples high on the flanks (painted, so none can float off the skin)
		for q: Vector3 in dapples:
			col = col.lerp(GRAZE_DARK, _dab(p, q, 0.06, 0.13) * 0.6)
		return col
	var rings := _sweep(g, spine, 34, paint, 1.0, 1.0)
	_cache["grazer_rings"] = rings
	_cache["grazer_body_tube"] = g
	return rings


static func grazer_body() -> ArrayMesh:
	return _cached("grazer_body", func() -> ArrayMesh:
		var rings := _grazer_body_rings()
		var g: Tube = _cache["grazer_body_tube"]
		var kit := PlanetMeshKit.new()
		# the back's ridge of little leaf-plates, each sunk half into the skin along the top line
		for k in 7:
			var z := -0.4 + 0.2 * float(k)
			var h := 0.15 - 0.015 * absf(float(k) - 3.0)
			var sk := _skin(rings, _ring_at_z(rings, z), -PI * 0.5, h * 0.3)   # the body runs +Z, so -PI/2 is its back
			kit.sphere(sk[0], h, GRAZE_FROND if k % 2 == 0 else GRAZE_FROND.lightened(0.1), Vector3(0.32, 1.0, 0.85), 10,
				Basis(Vector3.RIGHT, 0.25))
		return g.finish(kit))


## The glow spots along the grazer's flanks (glow material), body-local: flat ovals laid ON the skin.
static func grazer_spots() -> ArrayMesh:
	return _cached("grazer_spots", func() -> ArrayMesh:
		var rings := _grazer_body_rings()
		var kit := PlanetMeshKit.new()
		for k in 5:
			var z := -0.4 + 0.24 * float(k)
			var ri := _ring_at_z(rings, z)
			for sgn in [-1.0, 1.0]:
				# a little below the flank's widest line, alternating up and down
				var ang: float = (0.0 if sgn > 0.0 else PI) + sgn * (-0.18 + 0.12 * float(k % 2))
				var sk := _skin(rings, ri, ang, 0.012)
				kit.sphere(sk[0], 0.05, Color.WHITE, Vector3(0.75, 1.0, 0.3), 8, _on_skin(sk[1]))
		return kit.commit())


## The neck and head, neck-local (origin = the shoulder pivot, buried in the chest): one smooth neck that
## starts as a ball inside the chest, rises and leans forward, and ends inside a big round head with a
## pale muzzle, big dark eyes, a little smile and two leafy ear-fronds. The head points -Z.
static func grazer_neck() -> ArrayMesh:
	return _cached("grazer_neck", func() -> ArrayMesh:
		var h := GRAZER_HEAD
		var g := Tube.new()
		var spine := _spine([
			[Vector3(0.0, -0.05, 0.08), Vector2(0.34, 0.34)],
			[Vector3(0.0, 0.4, -0.22), Vector2(0.28, 0.29)],
			[Vector3(0.0, 0.95, -0.46), Vector2(0.22, 0.23)],
			[Vector3(0.0, 1.45, -0.56), Vector2(0.18, 0.185)],
			# the top flares out into the back of the head's underside, so the head grows out of the neck
			# instead of sitting on it like a ball on a stick
			[h + Vector3(0.0, -0.24, 0.07), Vector2(0.2, 0.2)],
			[h + Vector3(0.0, -0.06, 0.05), Vector2(0.25, 0.24)],
		], 6)
		var paint_neck := func(_p: Vector3, d: Vector3, f: float) -> Color:
			# the throat: the belly's pale line carried up the front of the neck, fading in above the chest
			var throat := smoothstep(0.35, 0.8, -d.z) * smoothstep(0.15, 0.4, f)
			return GRAZE.lerp(GRAZE_BELLY, throat * 0.85)
		_sweep(g, spine, 22, paint_neck, 1.0, 1.0)
		# the head: a round crown and a softer muzzle, both painted by ONE rule of position, so where the two
		# meet there is a crease but no colour seam
		var paint_head := func(p: Vector3) -> Color:
			var muzzle := smoothstep(-0.12, -0.3, p.z - h.z) * smoothstep(0.1, -0.06, p.y - h.y)
			return GRAZE.lerp(GRAZE_BELLY, muzzle)
		var crown := [h, Vector3(0.36, 0.33, 0.35)]
		var snout := [h + Vector3(0.0, -0.1, -0.26), Vector3(0.25, 0.2, 0.24)]
		for part: Array in [crown, snout]:
			_ellipsoid(g, part[0], part[1], 22, 12, paint_head)
		var kit := PlanetMeshKit.new()
		# eyes: big and dark, sunk a third into the crown, looking forward and a little out
		for sgn in [-1.0, 1.0]:
			var d := Vector3(0.52 * sgn, 0.22, -0.83).normalized()
			var sk := _ell_skin(crown[0], crown[1], d)
			var er := 0.085
			var ec: Vector3 = sk[0] - (sk[1] as Vector3) * er * 0.25
			kit.sphere(ec, er, EYE, Vector3(0.8, 1.0, 0.55), 12, _on_skin(sk[1]))
			kit.sphere(ec + (sk[1] as Vector3) * er * 0.42 + Vector3(-0.01 * sgn, er * 0.38, 0.0), er * 0.3, EYE_HI, Vector3.ONE, 6)
			# nostril dots on the muzzle
			var nd := _ell_skin(snout[0], snout[1], Vector3(0.28 * sgn, 0.3, -0.91).normalized())
			kit.sphere(nd[0], 0.018, GRAZE_DARK, Vector3(1.0, 0.7, 0.4), 6, _on_skin(nd[1]))
			# leafy ear-fronds: a leaf rooted in each side of the crown, sweeping out, up and back
			var ed := Vector3(0.8 * sgn, 0.5, 0.3).normalized()
			var es := _ell_skin(crown[0], crown[1], ed)
			var leaf_dir := Vector3(0.9 * sgn, 0.3, 0.3).normalized()
			var lb := _leaf_basis(leaf_dir, Vector3(0.0, 1.0, 0.0))
			kit.sphere(es[0] + leaf_dir * 0.12, 0.16, GRAZE_FROND, Vector3(0.55, 0.12, 1.0), 12, lb)
			kit.sphere(es[0] + leaf_dir * 0.13 + Vector3(0.0, 0.014, 0.0), 0.12, GRAZE_FROND.lightened(0.12), Vector3(0.12, 0.1, 1.0), 8, lb)
		# a small smile, sunk into the muzzle's front
		var sm := _ell_skin(snout[0], snout[1], Vector3(0.0, -0.25, -0.97).normalized())
		kit.sphere(sm[0], 0.05, GRAZE_DARK, Vector3(1.5, 0.28, 0.35), 8, _on_skin(sm[1]))
		return g.finish(kit))


## A basis for a leaf ball: its long axis (+Z) along `along`, its flat face (+Y small) facing `face_up`.
static func _leaf_basis(along: Vector3, face_up: Vector3) -> Basis:
	var z := along.normalized()
	var x := face_up.cross(z).normalized()
	return Basis(x, z.cross(x).normalized(), z)


## A smooth ellipsoid (radii `r`) into a Tube, each vertex painted by `paint(p)`.
static func _ellipsoid(g: Tube, centre: Vector3, r: Vector3, segs: int, rings_n: int, paint: Callable) -> void:
	var base := g.v.size()
	for i in rings_n + 1:
		var th := PI * float(i) / float(rings_n)
		for j in segs + 1:
			var ph := TAU * float(j) / float(segs)
			var u := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			var p := centre + u * r
			g.v.append(p)
			g.n.append(Vector3(u.x / r.x, u.y / r.y, u.z / r.z).normalized())
			g.c.append(PlanetMeshKit._lin(paint.call(p)))
	for i in rings_n:
		for j in segs:
			var a := base + i * (segs + 1) + j
			var b := a + 1
			var cc := a + segs + 1
			var d := cc + 1
			var geo := (g.v[cc] - g.v[a]).cross(g.v[b] - g.v[a])
			if geo.dot(g.n[a] + g.n[b] + g.n[cc] + g.n[d]) >= 0.0:
				g.ix.append_array(PackedInt32Array([a, b, cc, b, d, cc]))
			else:
				g.ix.append_array(PackedInt32Array([a, cc, b, b, cc, d]))


## Where direction `d` from an ellipsoid's centre meets its skin, and the outward normal there.
static func _ell_skin(centre: Vector3, r: Vector3, d: Vector3) -> Array:
	var k := 1.0 / sqrt(pow(d.x / r.x, 2.0) + pow(d.y / r.y, 2.0) + pow(d.z / r.z, 2.0))
	var p := d * k
	return [centre + p, Vector3(p.x / (r.x * r.x), p.y / (r.y * r.y), p.z / (r.z * r.z)).normalized()]


## A stubby column leg, leg-local (origin = the hip pivot, a ball buried in the belly), straight down -Y
## to a round dark foot with three pale toenails. One tube, capped round at the top and flattened at
## the sole, which sits at y = -GRAZER_HIPS.y.
static func grazer_leg() -> ArrayMesh:
	return _cached("grazer_leg", func() -> ArrayMesh:
		var hip_y: float = (GRAZER_HIPS[0] as Vector3).y
		var r := GRAZER_LEG_R
		var sole := -hip_y + r * 1.05 * 0.45
		var g := Tube.new()
		var spine := _spine([
			[Vector3(0.0, 0.05, 0.0), Vector2(r * 1.05, r * 1.05)],
			[Vector3(0.0, -0.45, 0.01), Vector2(r * 0.96, r * 0.96)],
			[Vector3(0.0, sole + 0.2, 0.0), Vector2(r * 0.92, r * 0.92)],
			[Vector3(0.0, sole, -0.02), Vector2(r * 1.05, r * 1.05)],
		], 4)
		var paint_leg := func(p: Vector3, _d: Vector3, _f: float) -> Color:
			var col := GRAZE.lerp(GRAZE_DARK, smoothstep(-0.5, -0.9, p.y) * 0.6)
			return col.lerp(GRAZE_HOOF, smoothstep(sole + 0.1, sole + 0.05, p.y))
		_sweep(g, spine, 16, paint_leg, 1.0, 0.45)
		var kit := PlanetMeshKit.new()
		for k in 3:
			var a := -PI * 0.5 + (float(k) - 1.0) * 0.55
			var d := Vector3(cos(a), 0.0, sin(a))
			kit.sphere(Vector3(0.0, sole + 0.02, -0.02) + d * r * 1.0, 0.045, GRAZE_BELLY, Vector3(1.0, 0.75, 0.8), 8)
		return g.finish(kit))


# ============================================================================================ BONUS PAGES
## A tiny woven reed hat with a ribbon (someone's - Moss's?), ~0.3 m across. Origin at the brim's middle:
## hung with the brim's back flat to a trunk and the crown standing out toward -Z.
static func reed_hat() -> ArrayMesh:
	return _cached("reed_hat", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# the brim (a flat woven disc, its back against the trunk) and the crown standing out of it
		kit.cylinder(Vector3(0.0, 0.0, 0.0), 0.15, 0.14, 0.018, REED, Basis(Vector3.RIGHT, -PI * 0.5), 18)
		kit.sphere(Vector3(0.0, 0.0, -0.035), 0.078, REED, Vector3(1.0, 1.0, 0.95), 14)
		kit.sphere(Vector3(0.0, 0.0, -0.1), 0.03, REED_DARK, Vector3(1.0, 1.0, 0.5), 8)
		for k in 3:
			kit.torus(Vector3(0.0, 0.0, -0.02), 0.1 + 0.017 * float(k), 0.006, REED_DARK, Basis(Vector3.RIGHT, PI * 0.5), 18)
		# a ribbon band round the crown, its two tails hanging down the brim
		kit.torus(Vector3(0.0, 0.0, -0.03), 0.076, 0.013, RIBBON, Basis(Vector3.RIGHT, PI * 0.5), 14)
		_limb(kit, Vector3(0.04, -0.06, -0.04), Vector3(0.07, -0.17, -0.03), 0.011, RIBBON, 5)
		_limb(kit, Vector3(-0.04, -0.06, -0.04), Vector3(-0.06, -0.18, -0.02), 0.011, RIBBON, 5)
		return kit.commit())


## An old empty snail shell made into a house: a round door and a lit window, a tiny chimney.
## ~0.45 m tall, door facing -Z, origin at the ground.
static func shell_house() -> ArrayMesh:
	return _cached("shell_house", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var c := Vector3(0.0, 0.23, 0.02)
		kit.sphere(c, 0.22, SHELL_HOUSE, Vector3(1.0, 1.0, 0.8), 18)
		# the whorl, facing out the front: rings shrinking and climbing toward the middle
		for k in 4:
			var r := 0.19 - 0.045 * float(k)
			kit.torus(c + Vector3(0.02 * float(k), 0.015 * float(k), -0.13 - 0.02 * float(k)), r, 0.022 - 0.003 * float(k),
				SHELL_HOUSE_DARK if k % 2 == 0 else SHELL_HOUSE.darkened(0.05), Basis(Vector3.RIGHT, PI * 0.5), 18)
		kit.sphere(c + Vector3(0.06, 0.045, -0.2), 0.035, SHELL_HOUSE_DARK, Vector3(1.0, 1.0, 0.6), 10)
		# the door, arched, low on the front, with a knob and a step
		kit.sphere(Vector3(-0.07, 0.1, -0.175), 0.075, DOOR, Vector3(0.85, 1.2, 0.35), 12)
		kit.sphere(Vector3(-0.04, 0.1, -0.2), 0.011, WINDOW, Vector3.ONE, 6)
		kit.cylinder(Vector3(-0.07, 0.0, -0.21), 0.085, 0.085, 0.025, SHELL_HOUSE_DARK.darkened(0.1), Basis.IDENTITY, 12)
		# a round lit window up on the whorl's shoulder
		kit.sphere(Vector3(0.11, 0.3, -0.17), 0.036, WINDOW, Vector3(1.0, 1.0, 0.4), 10)
		kit.torus(Vector3(0.11, 0.3, -0.18), 0.04, 0.009, DOOR, Basis(Vector3.RIGHT, PI * 0.5), 12)
		# a tiny chimney with a leaf on top
		kit.cylinder(Vector3(-0.1, 0.36, 0.05), 0.03, 0.028, 0.13, DOOR, Basis.IDENTITY, 8)
		kit.sphere(Vector3(-0.1, 0.5, 0.05), 0.035, STALK_LEAF, Vector3(1.4, 0.35, 0.8), 8)
		return kit.commit())


## A heart-shaped lily pad with one small pink flower, ~0.4 m across, floating (origin at the water).
## The heart's point is toward -Z.
static func heart_lily() -> ArrayMesh:
	return _cached("heart_lily", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# the heart: a polar curve, fanned from the middle
		var n := 28
		var prev := Vector3.ZERO
		for i in n + 1:
			var t := TAU * float(i) / float(n)
			# classic heart curve, point at -Z, lobes at +Z
			var x := 16.0 * pow(sin(t), 3.0)
			var z := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
			var p := Vector3(x, 0.0, z) * 0.012
			if i > 0:
				kit.triangle(Vector3(0.0, 0.012, 0.0), prev, p, HEART_PAD if i % 2 == 0 else HEART_PAD.lightened(0.06))
				kit.quad(prev, p, p - Vector3(0.0, 0.02, 0.0), prev - Vector3(0.0, 0.02, 0.0), HEART_PAD_RIM)
			prev = p
		# a little flower sitting on it
		for k in 6:
			var a := TAU * float(k) / 6.0
			kit.sphere(Vector3(cos(a) * 0.035, 0.035, sin(a) * 0.035 + 0.02), 0.028, HEART_FLOWER, Vector3(1.0, 0.45, 0.7), 8)
		kit.sphere(Vector3(0.0, 0.045, 0.02), 0.02, WINDOW, Vector3.ONE, 8)
		return kit.commit())


# ============================================================================================ POOL-PEEPER
## A pool dweller's head, peeking up out of the water: a round dusky-blue dome ~0.3 m across with two
## eyes up on short stalks, a little pale snout and two frilly gill-fronds. Origin at the waterline (the
## head rises from it), faces -Z. Its bubble is `peeper_bubble`, posed at PEEPER_BUBBLE_AT.
const PEEP := Color("#8490a6")         # S 0.20 V 0.65 (at S 0.34 it rendered S 0.69 over the teal water: kept low)
const PEEP_DARK := Color("#687289")
const PEEP_SNOUT := Color("#c9d3dc")   # V 0.86
const PEEP_GILL := Color("#c58aa6")    # S 0.30 V 0.77
const BUBBLE := Color("#d0e4e6")       # S 0.10 V 0.90

static func peeper() -> ArrayMesh:
	return _cached("peeper", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.08, 0.0), 0.15, PEEP, Vector3(1.0, 0.95, 1.0), 18)
		kit.sphere(Vector3(0.0, 0.0, 0.0), 0.14, PEEP_DARK, Vector3(1.05, 0.35, 1.05), 14)
		# the snout
		kit.sphere(Vector3(0.0, 0.05, -0.13), 0.06, PEEP_SNOUT, Vector3(1.2, 0.75, 0.7), 12)
		kit.sphere(Vector3(0.0, 0.05, -0.17), 0.012, PEEP_DARK, Vector3(2.0, 0.6, 0.5), 6)
		for sgn in [-1.0, 1.0]:
			# eye stalks and eyes
			_limb(kit, Vector3(0.05 * sgn, 0.18, -0.03), Vector3(0.075 * sgn, 0.27, -0.05), 0.024, PEEP, 8)
			kit.sphere(Vector3(0.075 * sgn, 0.28, -0.05), 0.045, PEEP_SNOUT, Vector3.ONE, 12)
			kit.sphere(Vector3(0.075 * sgn, 0.285, -0.088), 0.024, EYE, Vector3(0.8, 1.0, 0.5), 8)
			kit.sphere(Vector3(0.07 * sgn, 0.295, -0.1), 0.008, EYE_HI, Vector3.ONE, 5)
			# frilly gill fronds, swept back
			for k in 3:
				var b := Vector3(0.13 * sgn, 0.1 - 0.035 * float(k), 0.02)
				_limb(kit, b, b + Vector3(0.08 * sgn, 0.03 - 0.02 * float(k), 0.07), 0.016, PEEP_GILL, 6)
		return kit.commit())


static func peeper_bubble() -> ArrayMesh:
	return _cached("peeper_bubble", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3.ZERO, 0.05, BUBBLE, Vector3.ONE, 12)
		kit.sphere(Vector3(-0.018, 0.02, -0.035), 0.012, Color.WHITE.darkened(0.08), Vector3.ONE, 6)
		return kit.commit())
const PEEPER_BUBBLE_AT := Vector3(0.0, 0.06, -0.2)
