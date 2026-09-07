class_name MayorModel
extends ChibiModel
## Mayor Orbit — the elder brass robot who runs the Town Hall. Same chibi villager silhouette and the
## same AC face as everyone else: two dark eyes sitting ON a pair of SMOKED goggle lenses inside
## thin brass rims (never behind tinted glass, and never white sclera domes), muted bone brow
## ridges, a calm smile, no blush, a bone chin beard, and the goggle strap around the back of his
## head. His head is panelled like the automaton he is: a riveted brow band and a chin plate.
## A small top hat, a waistcoat with a bow tie, and a walking cane finish the grandfather read.
## Everything he does is slow and gentle (anim_time_scale 0.62).

## R2.6. Mayor Orbit was the worst offender in the cast: his brass measured S 0.76 across 41 % of
## his own crop and pushed his saturation mean to 0.627 against a 0.36-0.48 target. Pulled toward
## aged brass — same hue, much less chroma, a little less value — never toward brown:
##   brass  #c09449 S0.62 V0.75 -> #b7a179 S0.34 V0.72
##   gold   #d9ae4e S0.64       -> #bfa87d S0.35
##   vest   #394d75 S0.51       -> #475269 S0.32
##   lens   #f7f0dd V0.97       -> #c2b59b V0.76  (see `_build_face`: this is the white sclera fix)
## Measured on a real noon frame afterwards: saturation mean 0.465 (was 0.627), value mean 0.708,
## 0 % blown, dominant swatch #d0b675 S 0.44 (was #d9a434 S 0.76 across 41 % of the crop).
const BRASS := Color("#b7a179")
const BRASS_DARK := Color("#8d7f66")
const BRONZE := Color("#75634c")
## Smoked amber goggle glass — the eye sits ON it, never behind it. R2.3 forbids "giant white
## sclera domes", and a near-white disc under a black pupil is exactly that; a warm smoked lens
## keeps the eye the darkest thing on the face without pretending to be an eyeball.
const LENS := Color("#c2b59b")
const EYE := Color("#241a12")
## Elder trim (brow ridges, beard). Was #f6efe0, a pure cream that read as clown brows and teeth.
const WHITE := Color("#bcb29c")
const MOUTH := Color("#4e3020")
const VEST := Color("#475269")
const HAT := Color("#2b2438")
const GOLD := Color("#bfa87d")

var _cane: Node3D
var _t: float = 0.0


func _init() -> void:
	super()
	anim_time_scale = 0.62
	# R2.3 ("smaller and less glossy eyes relative to the head"): scaled with the base class's
	# own 19 % reduction so the robots keep their slightly chunkier screen features without going
	# back to the baby-doll size.
	eye_w = 0.0371
	eye_h = 0.0462
	eye_d = 0.0170
	mouth_w = 0.0540
	mouth_h = 0.0450
	mouth_d = 0.0160


func _build_geometry() -> void:
	# R2.6: painted/patinated brass is matte. spec 0.16-0.22 was putting a wet white ellipse on the
	# top of his head and his shoulders; only the gold trim keeps any sheen, and much less of it.
	var m_dark := _toon(BRASS_DARK, _matte({"spec": 0.05}))
	var m_bronze := _toon(BRONZE, _matte({"spec": 0.05}))
	var m_vest := _toon(VEST, _matte({"spec": 0.03}))
	var m_hat := _toon(HAT, _matte({"spec": 0.06}))
	var m_gold := _toon(GOLD, {"spec": 0.22, "spec_size": 150.0, "metallic": 0.25, "rim": 0.16, "roughness": 0.55})

	# ---- a heavier, more slab-sided bean than the young villagers
	_add_torso_bean(BRASS, {"spec": 0.05, "spec_size": 90.0, "chamfer_color": BRASS_DARK, "size_mul": Vector3(1.08, 1.0, 1.06)})
	# waistcoat: a flat front panel with a hard edge, so the bean silhouette survives and the chest
	# reads as a garment rather than a second balloon
	_mi(superellipsoid(Vector3(TORSO_RX * 0.92, TORSO_RY * 0.78, TORSO_RZ * 0.82), 3.1, 14, 8),
		m_vest, _torso, Vector3(0.0, TORSO_Y + 0.005, -0.056), "Waistcoat")
	_mi(rounded_box(Vector3(0.052, 0.330, 0.030), 0.012, 10), _toon(VEST.lightened(0.10), _matte({})),
		_torso, Vector3(0.0, TORSO_Y + 0.005, -TORSO_RZ - 0.026), "Placket")
	for i in 3:
		_mi(superellipsoid(Vector3(0.016, 0.016, 0.008), 2.6, 8, 5), m_gold, _torso,
			Vector3(0.0, TORSO_Y + 0.045 - 0.058 * i, -TORSO_RZ - 0.040), "Button")
	# bow tie right under the head
	var tie := _node("BowTie", _torso, Vector3(0.0, TORSO_Y + 0.170, -TORSO_RZ - 0.010))
	for sx: float in [-1.0, 1.0]:
		var wing := _mi(superellipsoid(Vector3(0.048, 0.034, 0.022), 2.6, 8, 5), _toon(Color("#7f4552"), _matte({})),
			tie, Vector3(0.048 * sx, 0.0, 0.0), "Wing")
		wing.rotation.z = 0.35 * sx
	_mi(superellipsoid(Vector3(0.020, 0.022, 0.018), 2.8, 8, 5), _toon(Color("#663542"), _matte({})), tie, Vector3.ZERO, "Knot")

	_add_arms(BRASS, BRASS_DARK, 0)
	_add_legs(BRASS_DARK, BRONZE)
	_add_head_shell(BRASS, {"spec": 0.05, "spec_size": 90.0, "seam_color": BRASS_DARK})
	# R2.3 ("less round, more structure"): he is an automaton, so his head is PANELLED — a brow band
	# running temple to temple with rivets on it, and a chin plate under the beard. Without these the
	# superellipsoid still read as one smooth gourd from the front.
	var brow_band := _node("BrowBand", _face, Vector3.ZERO)
	_orient_on_head(brow_band, 0.0, EYE_PITCH + 40.0, 0.010)
	_mi(rounded_box(Vector3(0.430, 0.052, 0.030), 0.014, 14), m_dark, brow_band, Vector3(0.0, 0.0, -0.008), "Band")
	for i in 3:
		var rv := _node("Rivet", _face, Vector3.ZERO)
		_orient_on_head(rv, -28.0 + 28.0 * float(i), EYE_PITCH + 40.0, 0.004)
		_mi(cylinder(0.013, 0.013, 0.010, 8), m_bronze, rv, Vector3(0.0, 0.0, -0.012), "Head").rotation.x = PI * 0.5
	var chin := _node("ChinPlate", _face, Vector3.ZERO)
	_orient_on_head(chin, 0.0, -56.0, 0.008)
	_mi(rounded_box(Vector3(0.290, 0.088, 0.030), 0.020, 14), m_dark, chin, Vector3(0.0, 0.0, -0.006), "Plate")
	# side plates instead of ears
	for sx2: float in [-1.0, 1.0]:
		var cap := _mi(cylinder(0.062, 0.062, 0.042, 14), m_dark, _head, Vector3(0.336 * sx2, -0.03, 0.02), "SidePlate")
		cap.rotation.z = PI * 0.5
		var bolt := _mi(cylinder(0.024, 0.024, 0.050, 8), m_bronze, _head, Vector3(0.348 * sx2, -0.03, 0.02), "Bolt")
		bolt.rotation.z = PI * 0.5

	# rear detail: a brass wind-up key and a hallmark plate, so the back is not a blank dome
	var key := _node("WindUpKey", _torso, Vector3(0.0, TORSO_Y + 0.055, TORSO_RZ + 0.030))
	_mi(cylinder(0.028, 0.028, 0.052, 12), m_bronze, key, Vector3.ZERO, "Boss").rotation.x = PI * 0.5
	for i in 2:
		var wing := _mi(rounded_box(Vector3(0.026, 0.108, 0.020), 0.010, 10), m_gold, key, Vector3(0.0, 0.0, 0.030), "Wing")
		wing.rotation.z = PI * 0.5 * float(i)
	_mi(rounded_box(Vector3(0.120, 0.070, 0.018), 0.014, 10), m_dark, _torso, Vector3(0.0, TORSO_Y - 0.075, TORSO_RZ * 0.92), "Hallmark")
	_mi(sphere(0.018, 10, 5), m_gold, _torso, Vector3(0.0, TORSO_Y - 0.075, TORSO_RZ * 0.96), "Seal")
	_mi(rounded_box(Vector3(0.230, 0.030, 0.026), 0.012, 10), m_dark, _head, Vector3(0.0, -0.02, HEAD_R * 0.86), "BackSeam")

	_build_face(m_dark, m_gold)
	_build_top_hat(m_hat, m_bronze)
	_build_cane(m_bronze, m_dark)


## Goggles built as a THIN BRASS RIM around two fully visible AC eyes.
##
## R2.3, "no giant white sclera domes": the lenses used to be near-white (#f7f0dd, V 0.97) discs
## 0.082 x 0.088 with a black oval on each, which is a pair of cartoon eyeballs, not goggles. They
## are now SMOKED AMBER (V 0.80, a value step below the brass rather than the brightest thing on
## him), 14 % smaller, and much flatter (z 0.022 -> 0.011) so they sit IN the rim as glass instead
## of bulging out of it. The eye stays the darkest shape on the face, which is the AC grammar.
func _build_face(_m_frame: Material, m_gold: Material) -> void:
	var m_lens := _toon(LENS, {"spec": 0.20, "spec_size": 150.0, "rim": 0.04, "shade": 0.14})

	# the smoked lens disc sits UNDER each eye, so the eye is the darkest thing on the face
	for sx: float in [-1.0, 1.0]:
		var lens := _node("Lens", _face, Vector3.ZERO)
		_orient_on_head(lens, EYE_YAW * sx, EYE_PITCH, 0.005)
		_mi(superellipsoid(Vector3(0.070, 0.075, 0.011), 2.5, 12, 7), m_lens, lens, Vector3.ZERO, "Glass")
		var rim := _mi(torus(0.069, 0.086, 20, 5), m_gold, lens, Vector3(0.0, 0.0, -0.009), "Rim")
		rim.rotation.x = PI * 0.5
	# thin bridge bar joining the two rims
	var bridge := _node("Bridge", _face, Vector3.ZERO)
	_orient_on_head(bridge, 0.0, EYE_PITCH, 0.010)
	_mi(rounded_box(Vector3(0.120, 0.018, 0.020), 0.007, 10), m_gold, bridge, Vector3(0.0, 0.006, -0.010), "Bar")
	# strap running back around the head, so the goggles read as goggles from every angle
	for sx2: float in [-1.0, 1.0]:
		var strap := _node("Strap", _head, Vector3(0.0, 0.02, 0.0))
		strap.rotation.y = 1.05 * sx2
		var seg := _mi(rounded_box(Vector3(0.150, 0.048, 0.030), 0.010, 12), _toon(BRONZE, _matte({})), strap, Vector3(0.0, 0.0, -0.335), "Seg")
		seg.rotation.y = 0.30 * sx2

	# R2.3: no blush on the robots. He is a brass automaton; two rouge patches read as a doll.
	_add_face(EYE, MOUTH, Color.TRANSPARENT, {
		"nose": false, "blush": false, "mouth_inner": Color("#6f3529"),
		"eye_inset": -0.006, "brow_color": WHITE.darkened(0.10),
	})
	# R3 — LESS ANIMAL. He already had no nose and no blush; what still read as a woodland creature
	# was the chibi head with nothing on it but a beard. Two short blunt HORNS fix that in one
	# stroke: no animal in this cast has them, they sit clear of the goggles and the hat brim, and on
	# an elder statesman they read as authority rather than as a monster. Swept back and out, with a
	# darker tip, so the silhouette still reads at gameplay distance.
	for sxh: float in [-1.0, 1.0]:
		# Set WIDE and low on the temples, and raked well out, so they clear the hat brim — the first
		# pass tucked them under it and they were invisible from the front, which is the only angle
		# that matters for reading a character.
		# ANGLE IS EVERYTHING HERE. Raked out near horizontal they read as EARS, which is the exact
		# thing this change exists to remove. They have to rise: set high on the crown with only a
		# modest outward roll, so the silhouette goes UP and back.
		var horn := _node("Horn", _head, Vector3(HEAD_SEMI.x * 0.62 * sxh, HEAD_SEMI.y * 0.68, 0.010))
		horn.rotation = Vector3(-0.34, 0.0, -0.40 * sxh)
		_mi(superellipsoid(Vector3(0.042, 0.132, 0.042), 2.6, 10, 6), _toon(BRASS, _matte({"rim": 0.02})),
			horn, Vector3.ZERO, "Horn")
		_mi(superellipsoid(Vector3(0.024, 0.062, 0.024), 2.5, 8, 5), _toon(BRASS_DARK, _matte({})),
			horn, Vector3(0.0, 0.116, 0.0), "Tip")

	# elder brow ridges above the rims: thinner (tube 0.014 -> 0.0085), narrower and a muted bone
	# rather than pure cream, so they read as a heavy brow instead of two clown eyebrows
	for sx3: float in [-1.0, 1.0]:
		var brow := _node("BrowRidge", _face, Vector3.ZERO)
		_orient_on_head(brow, (EYE_YAW + 1.0) * sx3, EYE_PITCH + 16.5, 0.004)
		var barc := _mi(arc_tube(0.050, 0.0085, deg_to_rad(34.0), deg_to_rad(146.0), 12, 6),
			_toon(WHITE, _matte({"rim": 0.02})), brow, Vector3.ZERO, "Arc")
		barc.rotation.z = deg_to_rad(-9.0 * sx3)

	# Chin beard, one continuous chamfered wedge instead of five balls. It used to be five bright
	# cream spheres sitting directly under the mouth, which read as a set of teeth; it is now a
	# single tapered plate in muted bone, dropped 6 deg lower and clear of the smile.
	var beard := _node("Beard", _face, Vector3.ZERO)
	_orient_on_head(beard, 0.0, -43.0, 0.004)
	var m_white := _toon(WHITE, {"spec": 0.02, "rim": 0.02, "shade": 0.20})
	_mi(superellipsoid(Vector3(0.104, 0.036, 0.022), 2.7, 12, 7), m_white, beard, Vector3(0.0, 0.006, -0.004), "Plate")
	_mi(superellipsoid(Vector3(0.052, 0.034, 0.019), 2.6, 8, 5), m_white, beard, Vector3(0.0, -0.028, -0.002), "Tip")


func _build_top_hat(m_hat: Material, m_band: Material) -> void:
	var hat := _node("TopHat", _head, Vector3(0.0, HEAD_R * 0.83, 0.015))
	hat.rotation.x = -0.10
	hat.rotation.z = 0.09
	_mi(cylinder(0.158, 0.174, 0.022, 18), m_hat, hat, Vector3.ZERO, "Brim")
	_mi(cylinder(0.100, 0.108, 0.135, 16), m_hat, hat, Vector3(0.0, 0.078, 0.0), "Crown")
	_mi(cylinder(0.110, 0.113, 0.030, 16), m_band, hat, Vector3(0.0, 0.026, 0.0), "Band")
	_mi(cylinder(0.100, 0.100, 0.010, 14), _toon(HAT.lightened(0.12), _matte({"spec": 0.05})), hat, Vector3(0.0, 0.147, 0.0), "Top")


func _build_cane(m_shaft: Material, m_tip: Material) -> void:
	if _hand_r == null:
		return
	_cane = _node("Cane", _hand_r, Vector3(0.0, 0.0, -0.030))
	_mi(capsule(0.021, 0.30, 10, 2), m_shaft, _cane, Vector3(0.0, -0.150, 0.0), "Shaft")
	var hook := _node("Hook", _cane, Vector3(0.0, -0.002, 0.0))
	_mi(arc_tube(0.052, 0.021, deg_to_rad(5.0), deg_to_rad(180.0), 10, 6), m_shaft, hook, Vector3(0.052, 0.0, 0.0), "Hook")
	var ferrule := _mi(sphere(0.028, 10, 5), m_tip, _cane, Vector3(0.0, -0.296, 0.0), "Ferrule")
	ferrule.scale = Vector3(1.0, 0.7, 1.0)


func _animate_extras(delta: float) -> void:
	_t += delta
	if _cane:
		# keep the cane upright no matter what the arm does (no ground clipping while he waddles)
		_cane.rotation = Vector3(-pose(P.ARM_R_PITCH), pose(P.ARM_R_YAW), -pose(P.ARM_R_ROLL))
