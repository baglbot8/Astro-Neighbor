extends RefCounted
## THE SHAPES OF VELA'S SAFARI (docs/PLANET_SAFARI_SPEC.md 12.4, builder VELA). Static builders only, the
## same rules as bolt_meshes.gd: every creature is ONE vertex-coloured ArrayMesh made with PlanetMeshKit
## on the shared toon material Vela's own masts already draw with (PlanetPropMeshes.prop_material), plus
## the parts that move on their own (a chime-bird's wings, a seal's front flippers). A herd of them is
## one MultiMesh per part (safari_herd.gd). Ground-hugging pieces (the ice floes, the mirror, the seal
## holes) follow the real terrain, so they are built per safari in worlds/vela.gd, not here.
##
## Conventions (PlanetMeshKit's): +Y up, origin at the ground contact, the creature faces -Z. Colours
## are sRGB hex inside docs/STYLE_GUIDE.md on a COLD world: slate and powder blues with S 0.10-0.30, the
## one warm accent is Vela's own amber #d8a25c (planet_props.gd `_vela`: "the only warm colour is the
## lamps"), used on the chime-birds' beaks and nothing bigger. Nothing whiter than V 0.92. Cute and
## calm, not bubbly: small dark house eyes, flat undersides, a few clean shapes.

const SLATE := Color("#7f93ab")        # chime-bird back      S 0.26 V 0.67
const SLATE_DARK := Color("#5f7189")   # its crest and wings  S 0.31 V 0.54
const DOWN := Color("#cfd8e0")         # bellies              S 0.08 V 0.88
const AMBER := Color("#d8a25c")        # Vela's amber: beaks  S 0.57 V 0.85 (the allowed accent)
const SEAL := Color("#9aa7b4")         # ice-seal             S 0.14 V 0.71
const SEAL_SPOT := Color("#7d8a99")
const SNOUT := Color("#d3dae0")
const MITE := Color("#d5dde6")         # snow-mite fluff      S 0.07 V 0.90
const MITE_SHADE := Color("#aebccb")
const ICE_TIP := Color("#9fb4d0")      # env_palette "frost"
const EYE := Color("#2a2f38")
const EYE_HI := Color("#e3e8ee")
const HOLE := Color("#3d4a5c")

static var _cache: Dictionary = {}


static func _cached(key: String, build: Callable) -> ArrayMesh:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


## The house eyes: two small dark ovals with a highlight dot, looking along `fwd`.
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
	kit.cylinder(a, r, r * 0.9, l, c, Basis(x, y, z), 6)
	kit.sphere(b, r * 1.05, c, Vector3.ONE, 6)


# ============================================================================================ CHIME-BIRD
## A round little slate-blue bird, 0.26 m tall, with a pale breast, an amber beak (Vela's colour: they
## sing her array's call back to it) and a two-feather crest. Origin at its feet. The wings are their own
## part (chime_wing), posed by code: folded along the body when it sits, flapping when it flies.
static func chime_body() -> ArrayMesh:
	return _cached("chime_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# body and breast
		kit.sphere(Vector3(0.0, 0.105, 0.01), 0.085, SLATE, Vector3(1.0, 0.95, 1.18), 14)
		kit.sphere(Vector3(0.0, 0.10, -0.035), 0.07, DOWN, Vector3(0.95, 0.95, 0.8), 12)
		# head, a little forward and up
		kit.sphere(Vector3(0.0, 0.195, -0.045), 0.062, SLATE, Vector3.ONE, 12)
		kit.sphere(Vector3(0.0, 0.18, -0.085), 0.04, DOWN, Vector3(1.0, 0.85, 0.6), 10)
		# the amber beak: a short cone pointing forward (-Z)
		kit.cylinder(Vector3(0.0, 0.19, -0.1), 0.02, 0.002, 0.05, AMBER, Basis(Vector3.RIGHT, -PI * 0.5), 8)
		_eyes(kit, Vector3(0.0, 0.212, -0.093), 0.06, 0.013)
		# a two-feather crest leaning back
		_limb(kit, Vector3(0.0, 0.25, -0.04), Vector3(0.0, 0.305, 0.0), 0.009, SLATE_DARK)
		_limb(kit, Vector3(0.0, 0.25, -0.03), Vector3(0.0, 0.29, 0.03), 0.008, SLATE_DARK)
		# tail: a flat fan up and back
		kit.quad(Vector3(-0.035, 0.10, 0.08), Vector3(0.035, 0.10, 0.08), Vector3(0.05, 0.15, 0.17),
			Vector3(-0.05, 0.15, 0.17), SLATE_DARK)
		# feet: two short legs with a toe each
		for sgn in [-1.0, 1.0]:
			_limb(kit, Vector3(0.03 * sgn, 0.04, 0.0), Vector3(0.03 * sgn, 0.0, -0.005), 0.007, SLATE_DARK)
			_limb(kit, Vector3(0.03 * sgn, 0.0, -0.005), Vector3(0.03 * sgn, 0.0, -0.035), 0.006, SLATE_DARK)
		return kit.commit())


## ONE wing, spreading along +X from its shoulder at the origin; the left wing is the same mesh mirrored.
static func chime_wing() -> ArrayMesh:
	return _cached("chime_wing", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.quad(Vector3(0.0, 0.0, -0.035), Vector3(0.13, 0.0, -0.01), Vector3(0.12, 0.0, 0.05),
			Vector3(0.0, 0.0, 0.05), SLATE_DARK)
		kit.triangle(Vector3(0.06, 0.0, 0.04), Vector3(0.12, 0.0, 0.05), Vector3(0.085, 0.0, 0.09), SLATE)
		return kit.commit())


# ============================================================================================ ICE-SEAL
## A plump grey seal, 0.95 m long and 0.4 m tall at the head, lying on its belly: a pale snout with a dark
## nose, the house eyes, a few soft spots, a tail fan. Origin under its belly; it faces -Z. The front
## flippers are their own part (seal_flippers) so it can clap.
static func seal_body() -> ArrayMesh:
	return _cached("seal_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.17, 0.06), 0.2, SEAL, Vector3(1.25, 0.85, 2.05), 16)
		kit.sphere(Vector3(0.0, 0.08, 0.05), 0.2, SNOUT, Vector3(1.05, 0.35, 1.8), 12)
		# the head, raised at the front
		kit.sphere(Vector3(0.0, 0.3, -0.3), 0.155, SEAL, Vector3(1.0, 0.95, 1.0), 14)
		kit.sphere(Vector3(0.0, 0.265, -0.43), 0.075, SNOUT, Vector3(1.15, 0.78, 0.9), 12)
		kit.sphere(Vector3(0.0, 0.29, -0.495), 0.022, EYE, Vector3(1.3, 0.9, 0.8), 8)
		_eyes(kit, Vector3(0.0, 0.345, -0.43), 0.13, 0.024)
		# whisker dots
		for sgn in [-1.0, 1.0]:
			for k in 2:
				kit.sphere(Vector3(0.04 * sgn, 0.255 - 0.02 * float(k), -0.49), 0.006, SEAL_SPOT, Vector3.ONE, 5)
		# soft spots on the back
		for sp: Vector3 in [Vector3(0.1, 0.3, 0.05), Vector3(-0.12, 0.28, 0.18), Vector3(0.06, 0.27, 0.32),
				Vector3(-0.05, 0.33, -0.08)]:
			kit.sphere(sp, 0.035, SEAL_SPOT, Vector3(1.0, 0.35, 1.0), 8)
		# the tail fan
		for sgn in [-1.0, 1.0]:
			kit.triangle(Vector3(0.0, 0.07, 0.42), Vector3(0.16 * sgn, 0.05, 0.6), Vector3(0.05 * sgn, 0.05, 0.62), SEAL_SPOT)
		return kit.commit())


## Both front flippers, sloping down from the shoulders; the code squeezes them together to clap.
static func seal_flippers() -> ArrayMesh:
	return _cached("seal_flippers", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.2 * sgn, 0.07, -0.02), 0.06, SEAL_SPOT, Vector3(1.6, 0.35, 0.9), 10)
		return kit.commit())


## A seal's breathing hole in the ice: a dark round of water with a pale rim.
static func seal_hole() -> ArrayMesh:
	return _cached("seal_hole", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.cylinder(Vector3(0.0, 0.0, 0.0), 0.3, 0.3, 0.025, HOLE, Basis.IDENTITY, 16)
		kit.torus(Vector3(0.0, 0.025, 0.0), 0.31, 0.035, DOWN, Basis.IDENTITY, 16)
		return kit.commit())


# ============================================================================================ SNOW-MITE
## A snowball with feet: a round fluff of powder 0.26 m across with a few tufts, the house eyes (a size
## up: it is the smallest thing on the planet), four little dark legs and one frosty feeler. Origin at
## its feet. Squashed and stretched by code as it hops.
static func mite() -> ArrayMesh:
	return _cached("mite", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.13, 0.0), 0.115, MITE, Vector3(1.0, 0.92, 1.0), 14)
		for tf: Vector3 in [Vector3(0.07, 0.2, 0.05), Vector3(-0.08, 0.19, 0.03), Vector3(0.0, 0.23, 0.06),
				Vector3(0.09, 0.12, 0.07), Vector3(-0.09, 0.11, 0.07)]:
			kit.sphere(tf, 0.045, MITE, Vector3.ONE, 8)
		kit.sphere(Vector3(0.0, 0.06, 0.0), 0.1, MITE_SHADE, Vector3(1.0, 0.45, 1.0), 10)
		_eyes(kit, Vector3(0.0, 0.15, -0.105), 0.07, 0.019)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_limb(kit, Vector3(0.05 * sx, 0.05, 0.04 * sz), Vector3(0.075 * sx, 0.0, 0.06 * sz), 0.011, EYE)
		_limb(kit, Vector3(0.0, 0.235, -0.02), Vector3(0.0, 0.31, -0.06), 0.007, MITE_SHADE)
		kit.sphere(Vector3(0.0, 0.315, -0.062), 0.018, ICE_TIP, Vector3.ONE, 6)
		return kit.commit())


# ============================================================================================ STAR-KRILL
const KRILL := Color("#b7c9de")        # star-krill shell     S 0.18 V 0.87
const KRILL_BELLY := Color("#d2dce6")  # its underside        S 0.09 V 0.90


## A star-krill, 0.17 m nose to tail: a little curled shrimp of four shrinking pale-ice segments, a
## fan tail, the house eyes a size up (it is tiny), two feelers swept back and a fringe of legs. It
## swims level and faces -Z; origin at its middle (it lives in the air over the ice, not on it). Its
## glow is a separate sprite the herd poses on it.
static func krill() -> ArrayMesh:
	return _cached("krill", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# the head and three body segments, curling gently down toward the tail
		kit.sphere(Vector3(0.0, 0.0, -0.045), 0.036, KRILL, Vector3(1.0, 0.92, 1.15), 12)
		kit.sphere(Vector3(0.0, -0.004, 0.0), 0.031, KRILL, Vector3(1.0, 0.9, 1.2), 10)
		kit.sphere(Vector3(0.0, -0.012, 0.038), 0.025, KRILL, Vector3(1.0, 0.9, 1.2), 10)
		kit.sphere(Vector3(0.0, -0.024, 0.07), 0.018, KRILL, Vector3(1.0, 0.9, 1.2), 8)
		kit.sphere(Vector3(0.0, -0.02, -0.02), 0.028, KRILL_BELLY, Vector3(0.9, 0.55, 1.6), 10)
		# the fan tail
		for sgn in [-1.0, 1.0]:
			kit.triangle(Vector3(0.0, -0.028, 0.08), Vector3(0.03 * sgn, -0.036, 0.115), Vector3(0.006 * sgn, -0.034, 0.12), ICE_TIP)
		_eyes(kit, Vector3(0.0, 0.012, -0.074), 0.036, 0.011)
		# feelers, swept back over the body
		for sgn in [-1.0, 1.0]:
			_limb(kit, Vector3(0.012 * sgn, 0.02, -0.07), Vector3(0.035 * sgn, 0.06, -0.02), 0.003, ICE_TIP)
			_limb(kit, Vector3(0.035 * sgn, 0.06, -0.02), Vector3(0.05 * sgn, 0.07, 0.04), 0.0025, ICE_TIP)
		# a fringe of little legs underneath
		for k in 3:
			for sgn in [-1.0, 1.0]:
				_limb(kit, Vector3(0.012 * sgn, -0.03, -0.03 + 0.025 * float(k)), Vector3(0.022 * sgn, -0.05, -0.034 + 0.025 * float(k)), 0.0025, ICE_TIP)
		return kit.commit())


# ============================================================================================ LIGHT
## A ring of light: a thin torus of radius 1 m in the XZ plane, scaled by code as it spreads.
static func ring() -> ArrayMesh:
	return _cached("ring", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.torus(Vector3.ZERO, 1.0, 0.035, Color.WHITE, Basis.IDENTITY, 40)
		return kit.commit())


## An aurora curtain: a wavy vertical ribbon `w` metres wide and `h` tall in the XY plane, bright at its
## foot and fading to nothing at its top (vertex alpha), for an additive unshaded material.
static func curtain(w: float, h: float, variant: int) -> ArrayMesh:
	return _cached("curtain_%d" % variant, func() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 24
		var foot := Color("#6fb89a")    # a sea-green          S 0.40 V 0.72
		var top := Color("#8a83c4")     # fading to a lilac    S 0.33 V 0.77
		for i in n:
			var f0 := float(i) / float(n)
			var f1 := float(i + 1) / float(n)
			var z0 := 0.6 * sin(f0 * TAU * 1.2 + float(variant))
			var z1 := 0.6 * sin(f1 * TAU * 1.2 + float(variant))
			var x0 := (f0 - 0.5) * w
			var x1 := (f1 - 0.5) * w
			var edge0 := sin(f0 * PI)
			var edge1 := sin(f1 * PI)
			var a := Vector3(x0, 0.0, z0)
			var b := Vector3(x1, 0.0, z1)
			var c := Vector3(x1, h, z1 * 1.4)
			var d := Vector3(x0, h, z0 * 1.4)
			var ca := Color(foot, 0.6 * edge0)
			var cb := Color(foot, 0.6 * edge1)
			var cc := Color(top, 0.0)
			var cd := Color(top, 0.0)
			# a middle row, so the colour turns from green to lilac half-way up
			var am := a.lerp(d, 0.45)
			var bm := b.lerp(c, 0.45)
			var cam := Color(foot.lerp(top, 0.6), 0.3 * edge0)
			var cbm := Color(foot.lerp(top, 0.6), 0.3 * edge1)
			for tri: Array in [[a, ca, b, cb, bm, cbm], [a, ca, bm, cbm, am, cam], [am, cam, bm, cbm, c, cc], [am, cam, c, cc, d, cd]]:
				for k in 3:
					st.set_color(tri[k * 2 + 1])
					st.set_normal(Vector3(0, 0, 1))
					st.add_vertex(tri[k * 2])
		return st.commit())


## The Mirror Moon's moonbeam: ONE vertical ribbon (the code turns it to face the lens) `h` tall and `w` wide, brightest at the foot
## and fading to nothing at the top and the sides (vertex alpha), for the additive unshaded material.
static func beam(h: float, w: float) -> ArrayMesh:
	return _cached("beam", func() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var moon := Color("#cfd9e8")   # S 0.12 V 0.91
		var rows := 6
		var cols := 6
		for side in 1:
			var ax := Vector3(1, 0, 0)
			for r in rows:
				for c in cols:
					var pts: Array = []
					for q: Vector2 in [Vector2(c, r), Vector2(c + 1, r), Vector2(c + 1, r + 1), Vector2(c, r + 1)]:
						var fx := q.x / float(cols)
						var fy := q.y / float(rows)
						var a := sin(fx * PI) * pow(1.0 - fy, 1.6) * 0.8
						pts.append([ax * (fx - 0.5) * w + Vector3(0, fy * h, 0), Color(moon, a)])
					for k: int in [0, 1, 2, 0, 2, 3]:
						st.set_color(pts[k][1])
						st.set_normal(Vector3.UP)
						st.add_vertex(pts[k][0])
		return st.commit())


# ============================================================================================ SCRAPBOOK EXTRAS
## (builder VELAC, 2026-09-26; spec 15.5.) The three collector's things and the ice skin a brought seal
## surfaces through. Same rules as above: one vertex-coloured mesh each on the shared toon material, cold
## slate-and-powder colours inside the palette gates, Vela's amber only as a thin accent.
const SNOW := Color("#d3dbe3")         # snow-astronaut        S 0.07 V 0.89
const SNOW_SHADE := Color("#b1becb")   # its underside ring    S 0.13 V 0.80
const SHELL := Color("#a9b5c3")        # helmet and pack       S 0.13 V 0.76
const SHELL_DARK := Color("#8391a3")   # neck ring             S 0.20 V 0.64
const VISOR := Color("#2d3a58")        # OPAQUE NAVY visor (STYLE_GUIDE R2.2: no face inside)  S 0.49 V 0.35
const PORCELAIN := Color("#d6dde5")    # Vela's teacup         S 0.07 V 0.90
const TEA := Color("#8a6c50")          # cold tea              S 0.42 V 0.54
const STAR_GOLD := Color("#dcc38e")    # the frozen star       S 0.35 V 0.86
const STAR_PALE := Color("#e8dbb8")    # its raised middle     S 0.21 V 0.91
const ICE_SKIN := Color("#a6bbd0")     # a seal's ice skin     S 0.20 V 0.82
const ICE_SKIN_RIM := Color("#93a8bf") #                       S 0.23 V 0.75


## A SNOW-ASTRONAUT, 0.95 m tall: two packed snowballs (a little faceted, flat-bottomed), a round helmet
## with an OPAQUE NAVY visor and a neck ring, a small pack on its back, wire arms (one up in a wave), three
## pebble buttons, and a stub antenna with one amber bead. Someone built it for Vela. Origin at the snow;
## it faces -Z (the visor).
static func snow_astronaut() -> ArrayMesh:
	return _cached("snow_astronaut", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		# a soft shaded ring where it stands, then the two snowballs (10-12 segments: faceted, not bubbles)
		kit.sphere(Vector3(0.0, 0.02, 0.0), 0.3, SNOW_SHADE, Vector3(1.0, 0.12, 1.0), 12)
		kit.sphere(Vector3(0.0, 0.22, 0.0), 0.27, SNOW, Vector3(1.0, 0.8, 1.0), 12)
		kit.sphere(Vector3(0.0, 0.52, 0.0), 0.19, SNOW, Vector3(1.0, 0.88, 1.0), 11)
		# pebble buttons down the front
		for k in 3:
			kit.sphere(Vector3(0.0, 0.6 - 0.09 * float(k), -0.176 + 0.012 * float(k)), 0.018, EYE, Vector3(1.0, 1.0, 0.6), 6)
		# the helmet: shell, neck ring, and the visor across the front
		kit.torus(Vector3(0.0, 0.665, 0.0), 0.125, 0.026, SHELL_DARK, Basis.IDENTITY, 14)
		kit.sphere(Vector3(0.0, 0.8, 0.0), 0.165, SHELL, Vector3.ONE, 14)
		kit.sphere(Vector3(0.0, 0.8, -0.075), 0.135, VISOR, Vector3(1.1, 0.86, 0.72), 14)
		kit.sphere(Vector3(-0.06, 0.85, -0.163), 0.024, EYE_HI, Vector3(1.6, 0.7, 0.4), 6)
		# the pack on its back
		kit.rounded_box(Vector3(0.0, 0.54, 0.19), Vector3(0.22, 0.22, 0.09), 0.025, SHELL)
		# wire arms: one waving, one down; two-pronged hands
		_limb(kit, Vector3(0.16, 0.56, 0.0), Vector3(0.3, 0.72, -0.02), 0.013, SLATE_DARK)
		_limb(kit, Vector3(0.3, 0.72, -0.02), Vector3(0.33, 0.8, -0.03), 0.009, SLATE_DARK)
		_limb(kit, Vector3(0.3, 0.72, -0.02), Vector3(0.37, 0.75, -0.03), 0.009, SLATE_DARK)
		_limb(kit, Vector3(-0.16, 0.55, 0.0), Vector3(-0.3, 0.42, -0.02), 0.013, SLATE_DARK)
		_limb(kit, Vector3(-0.3, 0.42, -0.02), Vector3(-0.35, 0.37, -0.03), 0.009, SLATE_DARK)
		_limb(kit, Vector3(-0.3, 0.42, -0.02), Vector3(-0.31, 0.35, -0.03), 0.009, SLATE_DARK)
		# a stub antenna with Vela's amber bead
		_limb(kit, Vector3(0.07, 0.93, 0.03), Vector3(0.1, 1.02, 0.05), 0.008, SLATE_DARK)
		kit.sphere(Vector3(0.1, 1.03, 0.05), 0.02, AMBER, Vector3.ONE, 8)
		return kit.commit())


## VELA'S TEACUP, left on a mast's cross-arm: a porcelain cup on its saucer, a thin amber band, cold tea to
## the brim, a loop handle, two grains of frost on the saucer. 0.08 m tall. Origin under the saucer.
static func teacup() -> ArrayMesh:
	return _cached("teacup", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.cylinder(Vector3.ZERO, 0.05, 0.075, 0.012, PORCELAIN, Basis.IDENTITY, 16)
		kit.cylinder(Vector3(0.0, 0.012, 0.0), 0.032, 0.048, 0.058, PORCELAIN, Basis.IDENTITY, 16)
		kit.torus(Vector3(0.0, 0.058, 0.0), 0.0455, 0.0045, AMBER, Basis.IDENTITY, 16)
		kit.cylinder(Vector3(0.0, 0.0705, 0.0), 0.043, 0.043, 0.002, TEA, Basis.IDENTITY, 14)
		kit.torus(Vector3(0.055, 0.042, 0.0), 0.017, 0.0055, PORCELAIN, Basis(Vector3.RIGHT, PI * 0.5), 10)
		kit.sphere(Vector3(-0.058, 0.014, 0.02), 0.008, ICE_TIP, Vector3.ONE, 5)
		kit.sphere(Vector3(0.02, 0.014, -0.06), 0.006, ICE_TIP, Vector3.ONE, 5)
		return kit.commit())


## A STAR FROZEN IN THE ICE: a flat five-pointed star, 0.34 m tip to tip, pale gold with a paler raised
## middle, lying in the ice (the ice patch it lies in follows the terrain and is built in worlds/vela.gd).
## Origin at the ice; it lies in the XZ plane.
static func frozen_star() -> ArrayMesh:
	return _cached("frozen_star", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		_star(kit, 0.004, 0.17, 0.07, STAR_GOLD)
		_star(kit, 0.008, 0.095, 0.04, STAR_PALE)
		return kit.commit())


static func _star(kit: PlanetMeshKit, y: float, r_out: float, r_in: float, c: Color) -> void:
	var centre := Vector3(0.0, y + 0.002, 0.0)
	for k in 10:
		var a0 := TAU * float(k) / 10.0
		var a1 := TAU * float(k + 1) / 10.0
		var r0 := r_out if k % 2 == 0 else r_in
		var r1 := r_out if (k + 1) % 2 == 0 else r_in
		kit.triangle(centre, Vector3(sin(a0) * r0, y, -cos(a0) * r0), Vector3(sin(a1) * r1, y, -cos(a1) * r1), c)


## A brought seal's BREATHING HOLE IN A SKIN OF ICE (spec 16: "the seals on the ice"): a rounded, lobed
## patch of pale ice 1.3 m across with the dark hole in it and a pale rim. It replaces the bare hole for
## every seal (on a floe the skin is the floe's own colour and reads as the floe).
static func seal_ice_hole() -> ArrayMesh:
	return _cached("seal_ice_hole", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.cylinder(Vector3(0.0, -0.01, 0.0), 0.6, 0.58, 0.02, ICE_SKIN_RIM, Basis.IDENTITY, 18)
		for k in 5:
			var a := TAU * float(k) / 5.0 + 0.4
			kit.cylinder(Vector3(sin(a) * 0.36, -0.008, cos(a) * 0.36), 0.3, 0.28, 0.02, ICE_SKIN_RIM, Basis.IDENTITY, 12)
		kit.cylinder(Vector3(0.0, -0.004, 0.0), 0.5, 0.48, 0.02, ICE_SKIN, Basis.IDENTITY, 18)
		kit.cylinder(Vector3(0.0, 0.0, 0.0), 0.3, 0.3, 0.025, HOLE, Basis.IDENTITY, 16)
		kit.torus(Vector3(0.0, 0.025, 0.0), 0.31, 0.035, DOWN, Basis.IDENTITY, 16)
		return kit.commit())
