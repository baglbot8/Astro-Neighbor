extends RefCounted
## THE SHAPES OF GRIG'S SAFARI (docs/PLANET_SAFARI_SPEC.md 12.3, builder GRIG). Static builders only, the
## same recipe as bolt_meshes.gd: every creature and event prop is ONE vertex-coloured ArrayMesh made with
## PlanetMeshKit, drawn with the materials Grig's own world already draws with (PlanetPropMeshes.
## rock_material for the henge and shelves, prop_material for the lamps, pulse_material for the lamp
## glass), so no new shader. A part that must move on its own (an owl's head, a bunny's ears, a worm's
## head) is its own mesh; a herd of look-alikes is one MultiMesh per part (safari_herd.gd).
##
## Conventions (PlanetMeshKit's): prop-local, +Y up, origin at the ground contact, the creature FACES -Z.
## Colours are sRGB hex taken from Grig's own world (grig.tres: rock #aaa8a1, ground #b7b4a2 / #a29f8c,
## bank #958369, shadow #626459, sage #8c9c70; Grig's accent #c2894f), inside docs/STYLE_GUIDE.md: chalk
## greys and buffs, nothing above S 0.40 except the small warm accents (beaks, noses), nothing whiter than
## V 0.90. Cute and structured, not bubbly: flat bases, banded shells, chamfered blocks - and the house's
## small dark oval eyes with one highlight dot.
##
## Built once per process and cached (a second safari reuses them).

const CHALK := Color("#cdc6b4")        # S 0.12 V 0.80
const CHALK_DARK := Color("#9f9886")   # S 0.16 V 0.62
const STONE := Color("#aaa8a1")
const BUFF := Color("#c4b397")         # S 0.23 V 0.77
const BUFF_DARK := Color("#8f7c61")    # S 0.32 V 0.56
const SHADOW := Color("#626459")
const SAGE := Color("#8c9c70")
const ACCENT := Color("#c2894f")       # Grig's own accent (npc_data.gd), S 0.59
const BLUSH := Color("#c29a8e")        # S 0.27 V 0.76
## The pebble-bug's shell (V6GRIG, 2026-09-27): a warm buff-brown pebble with chalk bands, so it reads
## against the pale chalk ground it sits on; in chalk (#cdc6b4) it was the ground's own colour (#b7b4a2).
## Between BUFF and BUFF_DARK: S 0.22 V 0.64 (rendered on the rock material S 0.41-0.51, measured, under the 0.60 gate).
const SHELL := Color("#a4937f")
const EYE := Color("#2a2320")
const EYE_HI := Color("#e6e2d6")

## The pebble-bug's shell radius (its ball when curled) and the owl's neck height (the head's pivot).
const BUG_BALL_R := 0.13
const OWL_NECK_Y := 0.27
const OWL_SHOULDER_Y := 0.2
const BUNNY_EAR_Y := 0.27

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
	kit.cylinder(a, r, r * 0.9, l, c, Basis(x, y, z), 6)
	kit.sphere(b, r * 1.05, c, Vector3.ONE, 6)


# ============================================================================================ PEBBLE-BUG
## Uncurled: a pill-bug of five chalk shell plates, each a flattened half-dome slightly overlapping the
## next, a small dark head with two short feelers, eight stubby legs. ~0.36 m long, 0.15 m tall.
static func bug_body() -> ArrayMesh:
	return _cached("bug_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var under := Color("#6f685b")
		for k in 5:
			var z := -0.11 + 0.055 * float(k)
			var w := 0.125 - 0.012 * absf(float(k) - 1.6)
			var c := SHELL if k % 2 == 0 else SHELL.darkened(0.1)
			kit.sphere(Vector3(0.0, 0.055, z), w, c, Vector3(1.0, 0.78, 0.46), 14)
			kit.torus(Vector3(0.0, 0.055, z + 0.02), w * 0.93, 0.008, CHALK, Basis(Vector3.RIGHT, PI * 0.5), 12)
		# the tail plate
		kit.sphere(Vector3(0.0, 0.045, 0.16), 0.07, SHELL.darkened(0.1), Vector3(1.0, 0.7, 0.7), 10)
		# head and feelers
		kit.sphere(Vector3(0.0, 0.05, -0.175), 0.06, under, Vector3(1.1, 0.8, 0.9), 12)
		_eyes(kit, Vector3(0.0, 0.07, -0.222), 0.062, 0.016)
		for sgn in [-1.0, 1.0]:
			_limb(kit, Vector3(0.025 * sgn, 0.085, -0.2), Vector3(0.075 * sgn, 0.13, -0.27), 0.006, under)
			for k in 4:
				var z := -0.10 + 0.07 * float(k)
				_limb(kit, Vector3(0.09 * sgn, 0.03, z), Vector3(0.14 * sgn, 0.0, z - 0.01), 0.011, under)
		return kit.commit())


## Curled: the same plates rolled into a ball - a banded chalk pebble, flat enough to sit. Origin at the
## ground, radius BUG_BALL_R.
static func bug_ball() -> ArrayMesh:
	return _cached("bug_ball", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var r := BUG_BALL_R
		kit.sphere(Vector3(0.0, r * 0.9, 0.0), r, SHELL, Vector3(1.0, 0.9, 1.05), 16)
		for k in 4:
			var a := -0.9 + 0.6 * float(k)
			var b := Basis(Vector3.RIGHT, a)
			kit.torus(Vector3(0.0, r * 0.9, 0.0), r * 0.98, 0.009, CHALK, b * Basis(Vector3.FORWARD, PI * 0.5), 16)
		return kit.commit())


# ============================================================================================ SHELF-OWL
## Body: an upright egg in buff, darker wing panels folded at the sides, a pale speckled breast, two warm
## feet on the shelf. The head is its own part (owl_head) so it can turn. ~0.30 m to the neck.
static func owl_body() -> ArrayMesh:
	return _cached("owl_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.15, 0.0), 0.14, BUFF, Vector3(1.0, 1.15, 0.92), 16)
		kit.sphere(Vector3(0.0, 0.14, -0.06), 0.105, CHALK, Vector3(1.0, 1.2, 0.6), 14)
		for i in 6:
			var a := float(i) * 1.1
			kit.sphere(Vector3(0.05 * sin(a * 2.3), 0.09 + 0.025 * float(i), -0.118), 0.011, BUFF_DARK, Vector3(1.0, 0.7, 0.5), 6)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.11 * sgn, 0.16, 0.02), 0.075, BUFF_DARK, Vector3(0.45, 1.3, 1.0), 12)
			kit.rounded_box(Vector3(0.045 * sgn, 0.012, -0.07), Vector3(0.05, 0.024, 0.07), 0.01, ACCENT.darkened(0.25))
		# a short tail
		kit.rounded_box(Vector3(0.0, 0.05, 0.12), Vector3(0.10, 0.03, 0.08), 0.012, BUFF_DARK, Basis(Vector3.RIGHT, -0.5))
		return kit.commit())


## Wings, spread for the stretch: two broad buff wings with dark flight feathers, out and up from the
## shoulders. Pivot at the shoulders (origin, which the code puts at OWL_SHOULDER_Y); scaled from 0 (folded
## away) to 1 (spread) by code.
static func owl_wings() -> ArrayMesh:
	return _cached("owl_wings", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for sgn in [-1.0, 1.0]:
			var b := Basis(Vector3.FORWARD, -0.55 * sgn)
			kit.sphere(Vector3(0.17 * sgn, 0.05, 0.02), 0.1, BUFF_DARK, Vector3(1.7, 0.75, 0.3), 12, b)
			kit.sphere(Vector3(0.24 * sgn, 0.08, 0.03), 0.07, BUFF_DARK.darkened(0.2), Vector3(1.6, 0.5, 0.28), 10, b)
			kit.sphere(Vector3(0.13 * sgn, 0.03, 0.0), 0.075, BUFF, Vector3(1.4, 0.8, 0.32), 10, b)
		return kit.commit())


## Head: round, a pale face disc, two dark eyes a little bigger than the house's (an owl is its eyes),
## a small warm beak and two ear tufts. Pivot at the neck (origin); faces -Z.
static func owl_head() -> ArrayMesh:
	return _cached("owl_head", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.10, 0.0), 0.125, BUFF, Vector3(1.08, 0.95, 1.0), 16)
		kit.sphere(Vector3(0.0, 0.095, -0.075), 0.10, CHALK, Vector3(1.15, 0.9, 0.5), 14)
		_eyes(kit, Vector3(0.0, 0.11, -0.118), 0.09, 0.026)
		kit.cylinder(Vector3(0.0, 0.085, -0.12), 0.018, 0.0, 0.04, ACCENT.darkened(0.1), Basis(Vector3.RIGHT, -PI * 0.5), 6)
		for sgn in [-1.0, 1.0]:
			kit.cylinder(Vector3(0.075 * sgn, 0.19, 0.0), 0.03, 0.004, 0.07, BUFF_DARK, Basis(Vector3.FORWARD, -0.35 * sgn), 6)
		return kit.commit())


# ============================================================================================ DUST-BUNNY
## A puff of chalk with ears: a soft cluster of chalk lumps, a little darker underneath, the house's
## eyes and a small blush nose. The ears are their own part. ~0.30 m tall with the ears.
static func bunny_body() -> ArrayMesh:
	return _cached("bunny_body", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.12, 0.0), 0.13, CHALK, Vector3(1.0, 0.92, 1.05), 16)
		kit.sphere(Vector3(0.0, 0.06, 0.02), 0.12, CHALK.darkened(0.06), Vector3(1.05, 0.55, 1.0), 12)
		for i in 5:
			var a := TAU * float(i) / 5.0 + 0.4
			kit.sphere(Vector3(0.10 * cos(a), 0.12 + 0.05 * sin(a * 2.0), 0.10 * sin(a) + 0.02), 0.06, CHALK.lightened(0.04), Vector3.ONE, 10)
		kit.sphere(Vector3(0.0, 0.10, 0.13), 0.045, CHALK.lightened(0.06), Vector3.ONE, 8)
		_eyes(kit, Vector3(0.0, 0.15, -0.115), 0.085, 0.019)
		kit.sphere(Vector3(0.0, 0.115, -0.13), 0.014, BLUSH, Vector3(1.2, 0.8, 0.8), 6)
		for sgn in [-1.0, 1.0]:
			kit.sphere(Vector3(0.06 * sgn, 0.012, -0.06), 0.035, CHALK_DARK, Vector3(1.0, 0.5, 1.4), 8)
		return kit.commit())


## The two long ears, pivot at their base (origin), tipping back.
static func bunny_ears() -> ArrayMesh:
	return _cached("bunny_ears", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		for sgn in [-1.0, 1.0]:
			var b := Basis(Vector3.FORWARD, 0.22 * sgn) * Basis(Vector3.RIGHT, 0.25)
			kit.sphere(Vector3(0.045 * sgn, 0.09, 0.02), 0.035, CHALK, Vector3(0.8, 2.6, 0.55), 10, b)
			kit.sphere(Vector3(0.045 * sgn, 0.09, 0.005), 0.022, BLUSH, Vector3(0.7, 2.3, 0.3), 8, b)
		return kit.commit())


# ============================================================================================ GLOW WORMS
## One segment of a chalk-glow worm (drawn with the glow material), and its head with the house's eyes.
static func worm_segment() -> ArrayMesh:
	return _cached("worm_seg", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.045, 0.0), 0.05, Color.WHITE, Vector3(1.0, 0.85, 1.25), 10)
		return kit.commit())


static func worm_head() -> ArrayMesh:
	return _cached("worm_head", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3(0.0, 0.05, 0.0), 0.058, Color("#dfe6d6"), Vector3(1.0, 0.95, 1.1), 12)
		_eyes(kit, Vector3(0.0, 0.07, -0.05), 0.045, 0.012)
		return kit.commit())


# ============================================================================================ HENGE HUM
## A glowing collar for a monolith: two square bands (the stone is a 4-sided lathe, a square standing on
## its diagonal, so the bands are boxes turned 45 degrees like its own groove), sized to sit just proud of
## the stone at `y_lo` / `y_hi` where its half-diagonal is `r_lo` / `r_hi`.
static func hum_collar(r_lo: float, y_lo: float, r_hi: float, y_hi: float) -> ArrayMesh:
	return _cached("hum|%.3f|%.3f|%.3f|%.3f" % [r_lo, y_lo, r_hi, y_hi], func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var q := Basis(Vector3.UP, PI * 0.25)
		for row: Vector2 in [Vector2(r_lo, y_lo), Vector2(r_hi, y_hi)]:
			var side := row.x * 1.414 + 0.05
			kit.rounded_box(Vector3(0.0, row.y, 0.0), Vector3(side, 0.07, side), 0.015, Color.WHITE, q)
		return kit.commit())


## A flat ring lying on the ground (the hum's ripple), radius 1, 4 cm wide.
static func ground_ring() -> ArrayMesh:
	return _cached("ground_ring", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.torus(Vector3(0.0, 0.03, 0.0), 1.0, 0.035, Color.WHITE, Basis.from_scale(Vector3(1.0, 0.3, 1.0)), 40)
		return kit.commit())


# ============================================================================================ THE BIG MOON
## A chalk moon: a sphere of radius 1 with a few soft grey seas and a scatter of crater rings, in the
## colours of Grig's own ground and rock. Scaled up in the world.
static func moon() -> ArrayMesh:
	return _cached("moon", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		kit.sphere(Vector3.ZERO, 1.0, Color("#d3cdbd"), Vector3.ONE, 32)
		var seas := [[Vector3(-0.3, 0.35, -0.9), 0.34], [Vector3(0.35, -0.2, -0.92), 0.26], [Vector3(-0.1, -0.5, -0.86), 0.2],
			[Vector3(0.45, 0.45, -0.77), 0.16]]
		for s: Array in seas:
			var n := (s[0] as Vector3).normalized()
			kit.sphere(n * 0.93, float(s[1]), Color("#b3ad9d"), Vector3(1.0, 1.0, 0.35), 14, _facing(n))
		for c: Vector3 in [Vector3(0.1, 0.62, -0.78), Vector3(-0.6, -0.1, -0.79), Vector3(0.62, 0.1, -0.78), Vector3(-0.35, -0.72, -0.6)]:
			var n := c.normalized()
			kit.torus(n * 0.985, 0.075, 0.02, Color("#bdb6a4"), _facing(n) * Basis(Vector3.RIGHT, PI * 0.5), 12)
		return kit.commit())


## A basis whose +Z points along `n` (for flattening a sphere onto the moon's face).
static func _facing(n: Vector3) -> Basis:
	var up := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := up.cross(n).normalized()
	var y := n.cross(x).normalized()
	return Basis(x, y, n)


# ============================================================================== THE BONUS PAGES (15.5)
## Pale chalk for scratched and drawn lines: lighter than the stone and the ground it is on, so it reads,
## and still inside the palette caps (S 0.09, V 0.87).
const CHALK_LINE := Color("#ded8c9")


## A flat chalk stroke on the ground (the XZ plane) from `a` to `b` (x, z), `w` wide, lying just proud.
## `bend_r` > 0: each piece is lowered by the planet's curve at its middle (x^2 + z^2) / (2 R), so a drawing on
## a small world lies on the ground instead of floating off it at the edges (1 cm at 0.45 m on Grig's).
static func _ground_stroke(kit: PlanetMeshKit, a: Vector2, b: Vector2, w: float, c: Color, bend_r: float = 0.0) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var mid := (a + b) * 0.5
	var yaw := atan2(-d.y, d.x)
	kit.rounded_box(Vector3(mid.x, 0.004 - _sag(mid, bend_r), mid.y), Vector3(l + w * 0.6, 0.008, w), 0.003, c, Basis(Vector3.UP, yaw))


## A chalk ring on the ground: centre (x, z), radius `r`, stretched by `sx`/`sz`.
static func _ground_ring(kit: PlanetMeshKit, c2: Vector2, r: float, w: float, c: Color, sx: float = 1.0, sz: float = 1.0,
		bend_r: float = 0.0) -> void:
	kit.torus(Vector3(c2.x, 0.004 - _sag(c2, bend_r), c2.y), r, w * 0.5, c, Basis.from_scale(Vector3(sx, 0.3, sz)), 28)


static func _sag(xz: Vector2, bend_r: float) -> float:
	return xz.length_squared() / (2.0 * bend_r) if bend_r > 0.0 else 0.0


## GRIG'S TALLY MARKS: groups of five scratched strokes (four down, one across) in two rows, the way Grig
## counts everything - 3 fives on top, one five and three more below: 23. Drawn in a FACE FRAME: X across
## the stone's face, Y up it, +Z out of it; origin at the panel's middle, the strokes lying on Z = 0 and
## standing 6 mm proud. ~0.42 x 0.40 m, sized for one flat face of a monolith (0.55 m wide at that height).
static func tally_marks() -> ArrayMesh:
	return _cached("tally", func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 23
		var pitch := 0.03
		var gap := 0.05
		var stroke_h := 0.15
		var rows := [[5, 5, 5], [5, 3]]
		var row_y := [0.095, -0.105]
		for ri in rows.size():
			var groups: Array = rows[ri]
			var width := 0.0
			for g: int in groups:
				width += float(mini(g, 4) - 1) * pitch + 0.02
			width += gap * float(groups.size() - 1)
			var x := -width * 0.5 + 0.01
			for g: int in groups:
				var x0 := x
				for k in mini(g, 4):
					var tilt := rng.randf_range(-0.07, 0.07)
					var hh := stroke_h * rng.randf_range(0.92, 1.04)
					kit.rounded_box(Vector3(x, float(row_y[ri]) + rng.randf_range(-0.006, 0.006), 0.003),
						Vector3(0.017, hh, 0.006), 0.003, CHALK_LINE, Basis(Vector3.BACK, tilt))
					x += pitch
				if g >= 5:
					# the fifth stroke goes across the four
					var span := x - pitch - x0
					var l := sqrt(span * span + stroke_h * stroke_h) * 0.95
					kit.rounded_box(Vector3((x0 + x - pitch) * 0.5, float(row_y[ri]), 0.006),
						Vector3(0.017, l, 0.006), 0.003, CHALK_LINE, Basis(Vector3.BACK, -atan2(span, stroke_h)))
				x += gap - pitch + 0.02
		return kit.commit())


## THE TINY TENTH STONE: one of the henge's monoliths (planet_props.gd `_step_monolith`, the same recipe -
## a four-sided taper standing on its diagonal, a dark groove band and an overhanging cap) at a sixth of
## the size, with three pebbles set round its foot as if someone put it there on purpose. Origin at the
## ground; 0.40 m tall. `stone`, `cap`, `shadow` are Grig's own rock, low-ground and shadow colours.
static func tenth_stone(stone: Color, cap: Color, shadow: Color) -> ArrayMesh:
	return _cached("tenth|%s|%s|%s" % [stone.to_html(), cap.to_html(), shadow.to_html()], func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var h := 0.40
		var r0 := 0.075
		var r_top := r0 * 0.74
		kit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(r0, 0.0),
			Vector2(r0 * 0.94, h * 0.26),
			Vector2(r_top, h * 0.90),
			Vector2(0.0, h * 0.90)]), 4, Transform3D.IDENTITY, stone, false)
		var gy := h * 0.56
		var gr := lerpf(r0 * 0.94, r_top, clampf((gy - h * 0.26) / (h * 0.64), 0.0, 1.0))
		var q := Basis(Vector3.UP, PI * 0.25)
		kit.rounded_box(Vector3(0.0, gy, 0.0), Vector3(gr * 1.470, 0.014, gr * 1.470), 0.003, shadow, q)
		kit.rounded_box(Vector3(0.0, h * 0.935, 0.0), Vector3(r_top * 1.78, 0.022, r_top * 1.78), 0.005, cap, q)
		for k in 3:
			var a := TAU * float(k) / 3.0 + 0.5
			kit.sphere(Vector3(0.14 * cos(a), 0.018, 0.14 * sin(a)), 0.03 + 0.006 * float(k), CHALK_DARK if k != 1 else stone,
				Vector3(1.2, 0.7, 1.0), 8)
		return kit.commit())


## A CHALK DRAWING OF YOU, on the ground: the astronaut as a child draws one - a round helmet with its
## visor and ear-pods, a body, one arm waving - with a star beside it and, under the feet, a single tally
## stroke (Grig counted you). Flat on the XZ plane, 8 mm proud; the picture's top points along -Z.
## ~0.62 x 0.86 m.
static func chalk_you(bend_r: float = 0.0) -> ArrayMesh:
	return _cached("chalk_you|%.2f" % bend_r, func() -> ArrayMesh:
		var kit := PlanetMeshKit.new()
		var w := 0.028
		var c := CHALK_LINE
		# helmet, visor, ear-pods
		_ground_ring(kit, Vector2(0.0, -0.40), 0.15, w, c, 1.0, 1.0, bend_r)
		_ground_ring(kit, Vector2(0.0, -0.41), 0.085, w * 0.9, c, 1.0, 0.6, bend_r)
		for sgn in [-1.0, 1.0]:
			_ground_ring(kit, Vector2(0.175 * sgn, -0.40), 0.03, w * 0.8, c, 1.0, 1.0, bend_r)
		# body: an oval
		_ground_ring(kit, Vector2(0.0, -0.07), 0.14, w, c, 0.9, 1.1, bend_r)
		# legs and feet
		for sgn in [-1.0, 1.0]:
			_ground_stroke(kit, Vector2(0.06 * sgn, 0.07), Vector2(0.08 * sgn, 0.24), w, c, bend_r)
			_ground_stroke(kit, Vector2(0.08 * sgn, 0.24), Vector2(0.14 * sgn, 0.25), w, c, bend_r)
		# one arm down, one arm waving
		_ground_stroke(kit, Vector2(-0.12, -0.12), Vector2(-0.23, 0.0), w, c, bend_r)
		_ground_stroke(kit, Vector2(0.12, -0.13), Vector2(0.24, -0.30), w, c, bend_r)
		_ground_ring(kit, Vector2(0.255, -0.33), 0.03, w * 0.8, c, 1.0, 1.0, bend_r)
		# a star beside it
		var sc := Vector2(0.30, -0.52)
		var pts: Array[Vector2] = []
		for k in 5:
			var a := -PI * 0.5 + TAU * float(k) / 5.0
			pts.append(sc + Vector2(cos(a), sin(a)) * 0.075)
		for k in 5:
			_ground_stroke(kit, pts[k], pts[(k + 2) % 5], w * 0.8, c, bend_r)
		# Grig counted you: one tally stroke under the feet
		_ground_stroke(kit, Vector2(-0.05, 0.31), Vector2(0.05, 0.31), w, c, bend_r)
		return kit.commit())
