class_name TwinModel
extends ChibiModel
## Pip & Pop — the Cosmo Depot twins (our Timmy & Tommy). 80 % of a normal villager with their face
## features scaled UP 1.08x, structured green heads with the standard AC face over a muzzle only a
## shade lighter than the skin, shop aprons with a badge and a bow at the back, and antennae: Pip
## has one, Pop has two. Their ears are small raked wedges, not the teddy-bear spheres of the first
## pass. Their idle bounce runs out of phase so the pair always reads as two characters.

## R2.6 (PASTEL AND MATTE). Greens are one of the three offenders the user named by hue, and the
## twins are entirely green, so they got the biggest pull. Pip #8ed85a S0.58 V0.85 -> #93c169
## S0.46 V0.76; Pop #c2dd5c S0.59 V0.87 -> #c1ca70 S0.45 V0.79; apron #f7e8c6 V0.97 -> #d6c9a8
## V0.84 (no near-clipping whites); star #ffcc33 S0.80 -> #d9b96e S0.49. Hue is preserved in every
## case — pastel, not mud. Measured on a real noon frame afterwards: Pip head crop saturation mean
## 0.472 / value 0.739, Pop 0.394 / 0.744, 0 % blown, no dominant swatch above S 0.46.
const APRON := Color("#d6c9a8")
const APRON_TRIM := Color("#d4b87e")
const STAR := Color("#d9b96e")
const EYE := Color("#231e2a")
const MOUTH := Color("#452c20")
const NOSE := Color("#2b1d16")
## R2.3: a near-white muzzle on a green head, under two big glossy eyes, is a Care Bear. This sits
## only ~10 % lighter than the skin so it reads as a jaw plane instead of a snout patch.
const MUZZLE := Color("#bcc499")
const BLUSH := Color("#b2898a")
const BULB := Color("#b8ff8a")

## Body colour (Pip: leaf green, Pop: yellow-green).
@export var skin: Color = Color("#93c169")
## 1 for Pip, 2 for Pop.
@export var antenna_count: int = 1
## Idle-bounce phase offset in seconds so the twins never bob in sync.
@export var bounce_phase: float = 0.0

var _antennae: Array[Node3D] = []
var _bulb_mats: Array[ShaderMaterial] = []
var _t: float = 0.0


func _init() -> void:
	super()
	# 0.70 with inherited face metrics made the twins two ~3 px dark dots at the 6.5 m camera. Timmy
	# and Tommy are only a little shorter than Tom Nook and their faces are *not* scaled down with
	# them, so: a taller body, and face features scaled UP to compensate for the body scale. Their
	# eyes now render 10.6 px wide at 6.5 m against 12.3 px for a full-size villager (was ~5 px).
	# Spacing stays a fixed % of head width, so the AC grammar is unchanged; 1.08 is the largest
	# face_scale that keeps the smile inside the mandated 16-25 % of head width.
	body_scale = 0.80
	face_scale = 1.08


func _build_geometry() -> void:
	var dark := skin.darkened(0.18)
	_add_torso_bean(skin)
	_add_arms(skin, skin, 0)
	_add_legs(dark, skin.darkened(0.34))
	_add_head_shell(skin)

	# R2.3: the ears were two spheres at the top corners of a ball, which is a teddy bear. They are
	# now smaller tapered wedges with a flat inner facet, raked back so the silhouette reads as a
	# little shopkeeper rather than a plush toy — and the inner facet is a muted skin shade instead
	# of the bubblegum pink the first pass used.
	for sx: float in [-1.0, 1.0]:
		var ear := _node("Ear", _head, Vector3(HEAD_SEMI.x * 0.72 * sx, HEAD_SEMI.y * 0.72, 0.052))
		ear.rotation = Vector3(0.22, -0.30 * sx, -0.34 * sx)
		_mi(superellipsoid(Vector3(0.030, 0.070, 0.058), 2.7, 10, 6), _toon(skin, _matte({})), ear, Vector3.ZERO, "Ear")
		_mi(superellipsoid(Vector3(0.013, 0.046, 0.036), 2.6, 8, 5), _toon(dark.lerp(Color("#d8c0b6"), 0.45), _matte({"rim": 0.02})),
			ear, Vector3(-0.019 * sx, -0.002, 0.006), "Inner")

	_add_muzzle(MUZZLE, -14.5, Vector3(0.096, 0.070, 0.019))

	_add_face(EYE, MOUTH, BLUSH, {"nose_color": NOSE, "mouth_inner": Color("#7a3941")})
	_build_apron()

	for i in maxi(antenna_count, 1):
		var sx2 := 0.0 if antenna_count == 1 else (-0.062 if i == 0 else 0.062)
		var tilt := 0.0 if antenna_count == 1 else (0.38 if i == 0 else -0.38)
		var a := _add_antenna(_head, Vector3(sx2, HEAD_R * 0.92, 0.01), tilt, skin.darkened(0.28), BULB, 0.15, 0.036)
		_antennae.append(a)
		_bulb_mats.append(a.get_meta("bulb_mat") as ShaderMaterial)

	# deterministic (not random) idle phase so the pair bounces visibly out of sync
	_time = bounce_phase


## Cream shop apron with a trim band and a star logo, plus a bow where the strings tie at the back.
func _build_apron() -> void:
	_build_apron_bow()
	var m_apron := _toon(APRON, _matte({"spec": 0.02}))
	var m_trim := _toon(APRON_TRIM, _matte({}))
	# the apron is a flat-fronted bib with a hard edge, not a second bean stuck on the first
	_mi(superellipsoid(Vector3(TORSO_RX * 0.94, TORSO_RY * 0.80, TORSO_RZ * 0.95), 3.1, 16, 9),
		m_apron, _torso, Vector3(0.0, TORSO_Y - 0.035, -0.028), "Apron")
	var band := _mi(torus(0.155, 0.205, 20, 6), m_trim, _torso, Vector3(0.0, TORSO_Y + 0.135, 0.0), "Neckband")
	band.scale = Vector3(1.0, 0.6, 1.0)
	_mi(rounded_box(Vector3(0.30, 0.045, 0.30), 0.014, 12), m_trim, _torso, Vector3(0.0, TORSO_Y - 0.16, 0.0), "Hem")
	# shop badge — a chamfered plate with an inlay, replacing the six-ball star (R2.3)
	var logo := _node("Logo", _torso, Vector3(0.0, TORSO_Y - 0.01, -TORSO_RZ - 0.008))
	var m_star := _toon(STAR, _matte({"spec": 0.05}))
	_mi(rounded_box(Vector3(0.086, 0.086, 0.016), 0.024, 12), m_star, logo, Vector3.ZERO, "Badge").rotation.z = PI * 0.25
	_mi(rounded_box(Vector3(0.046, 0.046, 0.018), 0.012, 10), _toon(APRON.darkened(0.24), _matte({})),
		logo, Vector3(0.0, 0.0, -0.004), "Inlay").rotation.z = PI * 0.25


## Rear detail: the apron's waist strings tied in a bow, so the back view is not a blank green bean.
func _build_apron_bow() -> void:
	var m_trim := _toon(APRON_TRIM, _matte({}))
	var bow := _node("ApronBow", _torso, Vector3(0.0, TORSO_Y - 0.045, TORSO_RZ + 0.010))
	_mi(rounded_box(Vector3(0.300, 0.048, 0.030), 0.012, 12), m_trim, _torso, Vector3(0.0, TORSO_Y - 0.045, TORSO_RZ * 0.86), "WaistTie")
	for sx: float in [-1.0, 1.0]:
		var loop := _mi(superellipsoid(Vector3(0.050, 0.036, 0.024), 2.8, 8, 5), m_trim, bow, Vector3(0.052 * sx, 0.010, 0.0), "Loop")
		loop.rotation.z = 0.42 * sx
		var tail := _mi(rounded_box(Vector3(0.036, 0.090, 0.024), 0.010, 10), m_trim, bow, Vector3(0.038 * sx, -0.062, 0.0), "Tail")
		tail.rotation.z = 0.26 * sx
	_mi(rounded_box(Vector3(0.046, 0.040, 0.028), 0.012, 10), _toon(STAR, _matte({"rim": 0.02})), bow, Vector3.ZERO, "Knot")


func _animate_extras(delta: float) -> void:
	_t += delta
	var wob := sin(TAU * (_t + bounce_phase) / 1.7)
	for i in _antennae.size():
		var a := _antennae[i]
		var rest: float = a.get_meta("rest_tilt", 0.0)
		var droop := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
		a.rotation.z = rest + 0.10 * wob * (1.0 if i == 0 else -1.0) - 0.75 * droop
	for m: ShaderMaterial in _bulb_mats:
		m.set_shader_parameter("emission_strength", 0.6 + 1.0 * (0.5 + 0.5 * sin(TAU * (_t + bounce_phase) / 2.2)))
