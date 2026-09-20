class_name DJModel
extends DJFloatModel
## DJ Nova — the event-space DJ, rebuilt 2026-09-15 as a FLOATING ROBOT (the user asked for one in a well-known film robot
## style; this is our own robot in that sleek, simple register, never a copy). Variant A
## "THE EGG", picked over `dj_ring_model.gd` on the comparison sheet. A head-heavy egg: a wide
## pearl-lilac head fused onto a dusk-violet body that tapers to a rounded tip, riding a tiny glowing
## turntable. Fin arms float clear of its sides. Over-ear headphones with a swept fin on each cup (the
## silhouette's "ears"), a dark glossy visor band carrying mint LED eyes and a light-strip mouth, and
## a glowing collar where head meets body. All motion, the LED face and the strip live in
## `DJFloatModel` (dj_float_model.gd).
##
## NOT A COPY: the head is FUSED to the body — no floating head, no neck gap; the shell is two-tone
## lilac and violet, never white; the eyes are upright mint pills on a wide visor band, not tilting
## blue ovals; and every prop is DJ gear — finned headphones, a light-strip EQ mouth, a turntable.
## Clearly not Bolt either: Bolt is a boxy teal block that WALKS, with a pale screen and dark features.
##
## The legacy walking model this replaces had the visor equalizer on its brow; the strip mouth keeps
## "My visor shows the beat. Look! LOOK!" true.
##
## Proportions (root space, before `hover_height` 0.20): turntable 0.085 below the tip · body
## 0.00-0.50 (max r 0.245 at 0.30) · head centre 0.715, semi (0.360, 0.285, 0.320) · ear fins to
## ~1.03. Measured AABB at rest 0.100-1.231 m above the feet; `marker_clearance()` 1.292, so npc.gd's
## "!" stays at its 1.52 default. Head is 0.57 of the robot's own height: the chibi head-first read.
## Collision in dj_nova.tscn: capsule r 0.34 (fin tips at rest) x h 1.30.
##
## Palette (R2.6 pastel and matte; R2.9 metal sheen on the shell at low strength). MEASURED on the
## character's own pixels (silhouette-masked), all eight states pooled, hub 10:30, round 1.1 (H234-235):
##   Forward+       gameplay S mean 0.281 p90 0.500 V 0.576, blown 0 %, no swatch above S 0.60
##   Compatibility  gameplay S mean 0.285 p90 0.545 V 0.585, blown 0 %, no swatch above S 0.60
## Round 1.2 below only ROTATES the hue (S and V held); S/V are hue-independent so these pooled
## numbers still hold — re-render confirms (see COLOR2 sheet). The first pass used a #3d3753 cup: it
## rendered #0a0623 (S 0.80) over 5.8 % of the crop in shade, so the cups and the platter are a
## lighter grey-violet now. The visor carries a faint emission so its shaded half stays a deeper
## blue-lilac rather than collapsing to saturated navy.
## Triangles 5678 (budget 6000), 41 mesh instances (the legacy model was 5884 / 72).

const HEAD_COL := Color("#9d99c4")   ## COLOR2 round 1.2 2026-09-15: H 246 S 0.22 V 0.77 — critic1 found round-1.1's H234 only 16 deg from Grig's shaded shirt swatch (H220), under the brief's 20 deg floor; pushed further into blue-lilac (was H234, off the original H251 that shared Zorp's violet) to clear both Grig's shirt (H207-220 both renderers, now 26-39 deg) and Zorp (~H277, now 31 deg) with real margin. S/V unchanged from round 1.1 — this is a hue-only move
const BODY_COL := Color("#807e94")   ## COLOR2 round 1.2: H 246 S 0.150 V 0.580 — hue moved with HEAD_COL, S/V held at the round-1.1 values (first pass S 0.243 MEASURED a 25%-coverage S 0.60+ swatch across the torso in gameplay-lit Forward+; this hue reacts to shading more than the old violet did, so S stays pulled down)
const BODY_DARK := Color("#646278")  ## COLOR2 round 1.2: H 246 S 0.180 V 0.471 — cut with BODY_COL, same reason
const VISOR_COL := Color("#444259")  ## COLOR2 round 1.2: H 246 S 0.258 V 0.349 — hue moved with the shell, S/V unchanged
const CUP_COL := Color("#5e5a6c")
const GLOW := Color("#56b3c2")
const AMBER := Color("#d1a15f")

const HOVER := 0.20
const BODY_TOP := 0.50
const BODY_RMAX := 0.245
const BODY_YMAX := 0.30
const HEAD_Y_A := 0.715
const HEAD_SEMI_A := Vector3(0.360, 0.285, 0.320)
const HEAD_N_A := 2.5
## The visor is a second, flatter superellipsoid pushed forward through the head: where it breaks
## the shell it draws a band that follows the head's own curvature, with no decal and no z-fight.
const VISOR_C := Vector3(0.0, -0.022, -0.222)
const VISOR_SEMI := Vector3(0.270, 0.190, 0.120)
const VISOR_N := 2.6
## Centres 0.210 m apart on a 0.720 m head = 29.2 % geometric (the 28-35 % band).
const EYE_SPACING_A := 0.210
const EYE_Y_A := 0.012
const STRIP_Y_A := -0.078
const SHOULDER_A := Vector3(0.290, 0.405, 0.0)
const FIN_SEMI := Vector3(0.042, 0.140, 0.080)

var _cups: Array[Node3D] = []
var _ear_fins: Array[Node3D] = []


func _init() -> void:
	super()
	hover_height = HOVER
	head_y = HEAD_Y_A
	arm_rest_roll = 0.20
	wave_roll = 1.95
	cheer_roll = 2.05
	crown_top = HEAD_Y_A + HEAD_SEMI_A.y + 0.07


func _build_geometry() -> void:
	# "Sleek, glossy" within R2.6: a tight, soft highlight (spec 0.16 at size 150 is a small sheen,
	# not a wet blob) plus R2.9's brushed-metal surface at low strength for a travelling sheen.
	var shell_opts := _matte({"spec": 0.16, "spec_size": 150.0, "rim": 0.10, "roughness": 0.45,
		"surface": "metal", "surface_scale": 2.4, "surface_strength": 0.18})
	var m_head := _toon(HEAD_COL, shell_opts)
	var m_body := _toon(BODY_COL, shell_opts)
	var m_dark := _toon(BODY_DARK, _matte({"spec": 0.08}))
	var m_cup := _toon(CUP_COL, _matte({"spec": 0.10, "spec_size": 140.0}))
	# the visor is the one genuinely glossy surface: a screen
	var m_visor := _toon(VISOR_COL, {"spec": 0.45, "spec_size": 170.0, "rim": 0.18, "roughness": 0.25, "shade": 0.10,
		"emission": Color("#575470"), "emission_strength": 0.9})  ## COLOR2 round 1.2: H 246 (was H253), S/V unchanged — moved with the shell hue
	var m_led := lit_material(led_color, 1.5)

	# ---- body: an egg that tapers to a rounded tip
	_mi(lathe(_egg_profile(), 26), m_body, _torso, Vector3.ZERO, "Body")
	# the glowing collar that hides the head/body join
	_mi(torus(0.192, 0.236, 24, 6), _pulse(GLOW, 1.5), _torso, Vector3(0.0, 0.466, 0.0), "Collar")
	# a small chest light, its "on air" pip
	var pip := _mi(sphere(0.022, 12, 6), _pulse(AMBER, 1.4), _torso, Vector3(0.0, 0.330, 0.0), "OnAir")
	pip.position.z = -_body_r(0.330) - 0.004
	pip.scale = Vector3(1.0, 1.0, 0.55)

	# ---- mini turntable it hovers on: a dark platter, a glowing rim, a label and two orbiting pips
	var deck := _node("Turntable", _torso, Vector3(0.0, -0.085, 0.0))
	_mi(cylinder(0.122, 0.122, 0.016, 26), m_cup, deck, Vector3.ZERO, "Platter")
	_mi(torus(0.116, 0.146, 26, 5), _pulse(GLOW, 1.8), deck, Vector3.ZERO, "Rim")
	_mi(cylinder(0.034, 0.034, 0.020, 14), _toon(AMBER, _matte({"spec": 0.04})), deck, Vector3.ZERO, "Label")
	for k in 2:
		var a := PI * float(k)
		_mi(sphere(0.012, 8, 4), _pulse(AMBER, 1.6), deck, Vector3(cos(a) * 0.082, 0.010, sin(a) * 0.082), "Groove")
	_spinner = deck

	# ---- fin arms: flat teardrop fins that float just clear of its sides
	for arm: Node3D in [_arm_l, _arm_r]:
		var sx := -1.0 if arm == _arm_l else 1.0
		arm.position = Vector3(SHOULDER_A.x * sx, SHOULDER_A.y, SHOULDER_A.z)
		var fin := _mi(superellipsoid(FIN_SEMI, 2.2, 22, 11), m_body, arm, Vector3(0.0, -0.125, 0.0), "Fin")
		fin.rotation.z = 0.10 * sx
		_mi(rounded_box(Vector3(0.012, 0.120, 0.050), 0.006, 8), _pulse(GLOW, 1.3), arm,
			Vector3(FIN_SEMI.x * 0.92 * sx, -0.120, 0.0), "FinStripe").rotation.z = 0.10 * sx

	# ---- head: fused to the body, no neck
	_mi(superellipsoid(HEAD_SEMI_A, HEAD_N_A, 52, 26), m_head, _head, Vector3.ZERO, "HeadShell")
	_mi(superellipsoid(VISOR_SEMI, VISOR_N, 48, 24), m_visor, _head, VISOR_C, "Visor")
	_build_headphones(m_cup, m_dark, m_body)

	var z_of := func(x: float, y: float) -> float:
		return se_front_z(x, y, VISOR_C, VISOR_SEMI, VISOR_N, VISOR_C.z - VISOR_SEMI.z) - 0.004
	_add_led_eyes(_face, EYE_SPACING_A, EYE_Y_A, z_of, m_led)
	_add_light_strip(_face, STRIP_Y_A, z_of, 0.026)


## Over-ear cans on the sides of the head, a slim band over the crown, and a swept fin rising off
## each cup — the fins are what make the silhouette unmistakable at 8 m.
func _build_headphones(m_cup: Material, m_band: Material, m_fin: Material) -> void:
	var band := _node("Band", _head, Vector3(0.0, 0.0, 0.035))
	band.scale = Vector3(1.0, 0.76, 1.0)
	_mi(arc_tube(0.392, 0.024, deg_to_rad(12.0), deg_to_rad(168.0), 20, 8), m_band, band, Vector3.ZERO, "Band")
	for sx: float in [-1.0, 1.0]:
		var can := _node("Can", _head, Vector3(0.352 * sx, -0.010, 0.030))
		var body := _node("CupAxis", can, Vector3.ZERO)
		body.rotation.z = PI * 0.5
		_mi(cylinder(0.118, 0.126, 0.080, 26), m_cup, body, Vector3(0.0, -0.030 * sx, 0.0), "Cup")
		_mi(torus(0.070, 0.092, 24, 6), _pulse(GLOW, 1.7), body, Vector3(0.0, -0.072 * sx, 0.0), "CupGlow")
		_mi(cylinder(0.062, 0.062, 0.012, 18), m_band, body, Vector3(0.0, -0.072 * sx, 0.0), "CupCap")
		# the swept fin: a flattened teardrop leaning back off the top of the cup
		var ear := _node("EarFin", can, Vector3(0.045 * sx, 0.080, 0.040))
		ear.rotation = Vector3(0.55, 0.0, -0.14 * sx)
		_mi(superellipsoid(Vector3(0.030, 0.135, 0.066), 2.3, 18, 9), m_fin, ear, Vector3(0.0, 0.095, 0.0), "Fin")
		_mi(rounded_box(Vector3(0.012, 0.120, 0.020), 0.006, 8), _pulse(GLOW, 1.4), ear,
			Vector3(0.026 * sx, 0.095, -0.036), "FinLight")
		_cups.append(can)
		_ear_fins.append(ear)


## Radius of the egg at height y (0 = tip, BODY_TOP = where the head swallows it).
static func _body_r(y: float) -> float:
	if y <= BODY_YMAX:
		var d := (BODY_YMAX - y) / BODY_YMAX
		return BODY_RMAX * sqrt(maxf(0.0, 1.0 - d * d))
	var d2 := (y - BODY_YMAX) / 0.33
	return BODY_RMAX * sqrt(maxf(0.0, 1.0 - d2 * d2))


static func _egg_profile() -> PackedVector2Array:
	var pr := PackedVector2Array()
	var rows := 13
	for i in rows + 1:
		# cosine spacing packs rows toward the tip, where the curvature is
		var s := 0.5 - 0.5 * cos(PI * float(i) / rows)
		var y := s * BODY_TOP
		pr.append(Vector2(_body_r(y), y))
	pr[0] = Vector2(0.0, 0.0)
	pr.append(Vector2(0.0, BODY_TOP))
	return pr


func _headphone_hold_pose() -> Vector3:
	return Vector3(2.36, 0.0, 0.0)


func _think_arm_pose() -> Vector3:
	return Vector3(-0.15, 1.45, 0.0)


func _animate_parts(_delta: float, beat: float) -> void:
	# the ear fins twitch on the beat, a little more while it dances
	var amt := 0.04 + 0.10 * clampf(pose(P.EXTRA_B), 0.0, 1.0)
	for i in _ear_fins.size():
		var sx := -1.0 if i == 0 else 1.0
		_ear_fins[i].rotation.x = 0.55 + amt * maxf(0.0, sin(beat + 0.4 * sx))
