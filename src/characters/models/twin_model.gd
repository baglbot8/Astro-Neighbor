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
const SCLERA := Color("#f2f4e6")     ## pale eyeball; the face's dark oval becomes the pupil
const GRIN := Color("#3a2118")
const TOOTH := Color("#f4efe2")
## R3.2 skin texture — the cellular `skin` kind, same as Zorp. See alien_model.gd for why `rock` was
## rejected. Slightly finer and weaker than his, so the twins read as smoother-skinned than he does.
const SURF_HEAD := {"surface": "skin", "surface_scale": 1.9, "surface_strength": 0.95,
	"surface_spot": 1.2, "surface_scales": 0.25, "surface_spot_radius": 0.34,
	"surface_near": 9.0, "surface_far": 26.0, "surface_macro": 0.07}
## MUCH weaker than the head, and with the cell EDGES nearly off. An arm is a small, strongly curved
## capsule, so the same settings that read as skin on a 680 mm head render as cauliflower on a 90 mm
## limb — the ridge term is what does it. Spots only here.
const SURF_LIMB := {"surface": "skin", "surface_scale": 6.5, "surface_strength": 0.75,
	"surface_spot": 0.9, "surface_scales": 0.12, "surface_spot_radius": 0.30,
	"surface_near": 7.0, "surface_far": 20.0}

## Body colour (Pip: leaf green, Pop: yellow-green).
## Which eyestalk silhouette this twin wears. "tall" gives one long stalk and one short one, an
## asymmetric pair straight off the reference sheet; "closeset" gives two short stalks side by side.
## The pair must not share a silhouette — half the point of twins is telling them apart at a glance.
@export var stalk_style: String = "tall"
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
	# R3.2 — THEIR OWN HEAD. Wider and much flatter than the shared chibi dome, which they used to
	# share as a literal cached mesh with Zorp and the Mayor. Exponent held at 3.2 rather than the
	# 3.6 first proposed: two reviewers built the higher value and rendered a faceted box, because
	# superellipsoid() samples uniform angular directions and a high exponent packs all the curvature
	# into a narrow chamfer band.
	head_semi = Vector3(0.3420, 0.2320, 0.2760)
	head_n = 3.2
	# Holds the chin exactly where it rendered before (0.945 - 0.3258 * 0.88 = 0.6583).
	head_y = 0.8903


func _build_geometry() -> void:
	var dark := skin.darkened(0.18)
	_add_torso_bean(skin)
	_add_arms(skin, skin, 0, SURF_LIMB, SURF_LIMB)
	_add_legs(dark, skin.darkened(0.34), SURF_LIMB)
	_add_head_shell(skin, SURF_HEAD)

	# R3 — LESS ANIMAL. The ears, the muzzle, the nose and the blush are all gone: those four are
	# what made the twins read as green teddy bears rather than as creatures. Against the reference
	# sheet the eyes go up on stalks and the mouth becomes a wide toothy grin, and the two of them
	# take DIFFERENT stalk silhouettes so they are still tellable apart at a glance.
	_add_face(EYE, MOUTH, BLUSH, {"mouth_inner": Color("#7a3941"), "nose": false, "blush": false})
	for b: Node3D in _brows:
		b.queue_free()
	_brows.clear()
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node != null:
		_orient_on_head(mouth_node, 0.0, -17.0, 0.004)
		mouth_node.scale = Vector3(1.75, 1.50, 1.0)
		_add_wide_grin(mouth_node, GRIN, TOOTH, Vector3(0.078, 0.030, 0.019),
			[[-0.038, 0.018], [0.004, 0.021], [0.040, 0.015]])
	var by := head_semi.y * 0.70
	var specs: Array = []
	if stalk_style == "closeset":
		# Two short stalks close together and slightly splayed — the wide-eyed one of the pair.
		specs = [
			{"base": Vector3(-0.046, by, -0.035), "tip": Vector3(-0.076, 0.359, -0.046), "r": 0.023, "splay": -0.12},
			{"base": Vector3(0.046, by, -0.035), "tip": Vector3(0.081, 0.349, -0.046), "r": 0.023, "splay": 0.12},
		]
	else:
		# One long stalk and one short — deliberately lopsided, which no animal is.
		specs = [
			{"base": Vector3(-0.086, by, -0.035), "tip": Vector3(-0.132, 0.493, -0.049), "r": 0.024, "splay": -0.22},
			{"base": Vector3(0.084, by, -0.035), "tip": Vector3(0.116, 0.356, -0.044), "r": 0.024, "splay": 0.18},
		]
	_add_eyestalks(specs, skin, SCLERA, 0.048)
	_build_apron()

	for i in maxi(antenna_count, 1):
		# +/-0.085, not +/-0.062: Pop's two antennae used to clear his eyestalks by about a
		# millimetre, and the lower crown would have pushed the bulbs straight through the stems.
		var sx2 := 0.0 if antenna_count == 1 else (-0.085 if i == 0 else 0.085)
		var tilt := 0.0 if antenna_count == 1 else (0.38 if i == 0 else -0.38)
		var a := _add_antenna(_head, Vector3(sx2, head_semi.y - 0.004, -0.030), tilt, skin.darkened(0.28), BULB, 0.15, 0.036)
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
