class_name AlienModel
extends ChibiModel
## Zorp — the lavender alien neighbour. ACNH villager grammar at its QUIET end (Tom Nook, not a
## preschool cartoon): a structured superellipsoid head, small dark eyes under a resting brow, a
## tiny nose, a calm smile, a restrained dusty blush, a squat bean body, stub arms with
## three-fingered mitten hands and chunky boots.
## R3 — LESS ANIMAL, MORE UNNATURAL. Against reference/'Alien References.webp': those creatures have
## EYES ON STALKS, no nose, no snout, no ears and no blush. Zorp had all four of those mammal cues —
## a muzzle plane, a nose, cheek blush, and two fins at the top corners of the head that read as
## ears — which is what made him a purple animal rather than a creature from somewhere else.
## The fins are gone and the eyes now sit on top of two soft stalks, each on a pale eyeball so the
## dark oval reads as a PUPIL. The eye nodes themselves are only repositioned, never rebuilt, so
## every blink, squint, happy-arc and surprise state still animates exactly as before.
## Kept: one antenna with a mint bulb that pulses (and droops while thinking), a striped
## space-scarf, and a 5 cm hover with a bob and a faint glow ring.

## R2.6 (PASTEL AND MATTE). Every albedo below was re-picked against the CURRENT game — the dark
## thin-atmosphere sky and the repainted pastel ground — not the old white-void showcase. The rule
## from the style guide is "desaturate toward the hue's own pastel, never toward brown, and handle
## value separately", so each swatch keeps its hue and loses chroma and top-end value:
##   skin   #a77ff5 S0.48 V0.96 -> #9a80cc S0.37 V0.80   (still lavender, no longer neon)
##   shirt  #5fd0c8 S0.55 V0.82 -> #84bdb5 S0.30 V0.74
##   scarf  #ff8fa8 S0.44 V1.00 -> #c4858f S0.32 V0.77   (V 1.0 pinks were the clipping culprits)
##   trim   #fff1e0 V1.00       -> #e8ddc9 V0.91         (style guide caps near-whites at ~0.92)
##   feet   #7449d4 S0.66       -> #665c93 S0.37 V0.58   (the dark value anchor every AC villager has)
## Measured on a real noon frame in src/world/world.tscn afterwards: head crop saturation mean
## 0.451, value mean 0.746, 0 % blown, dominant swatch #b076cf S 0.43.
const SKIN := Color("#9a80cc")
const SKIN_DARK := Color("#7c6aa6")
const EYE := Color("#221c2e")
const BULB := Color("#7fffd4")       ## an emissive bulb: a small saturated accent is allowed
const BLUSH := Color("#b3868f")      ## dusty rose, not bubblegum — R2.3 "restrained blush"
const MOUTH := Color("#472440")
const NOSE := Color("#4a3566")
const SCARF_A := Color("#c4858f")
const SCARF_B := Color("#e8ddc9")
const SHIRT := Color("#84bdb5")      ## a proper tee — every AC villager wears clothes
const SHIRT_TRIM := Color("#e8ddc9")
## R2.3: the muzzle used to be a near-white oval (#e4d2ff, V 1.00) on a purple head, which with two
## big glossy eyes is a Care Bear. It is now a lavender only ~9 % lighter than the skin, so it reads
## as a jaw plane rather than a snout patch.
const MUZZLE := Color("#ab93cf")
const FOOT := Color("#665c93")
const HOVER := 0.05
## Eyestalks. Base on the head's upper slope, tip well clear of the shell so the silhouette reads as
## "eyes on stems" from any angle — that outline is the whole point of the redesign.
const STALK_BASE_X := 0.112
const STALK_BASE_Y := 0.70          ## multiplied by HEAD_SEMI.y
const STALK_TIP_X := 0.176
const STALK_TIP_Y := 0.505
const STALK_Z := -0.045
const STALK_R := 0.030
const SCLERA := Color("#efe7f7")    ## pale eyeball, so the existing dark oval becomes a pupil
## With the eyes up on stalks the face is nearly empty, so the mouth carries it alone and sits
## lower than the chibi default (-20). At the default it floated in the middle of a blank head and
## read as a nose.
const MOUTH_PITCH_ALIEN := -31.0

var _antenna: Node3D
var _bulb_mat: ShaderMaterial
var _glow_ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _bob: float = 0.0


func _init() -> void:
	super()
	hover_height = HOVER
	# On a stalk an eye reads as a whole ball rather than a mark on a face, so it wants to be rounder
	# and larger than the chibi default.
	eye_w = 0.062
	eye_h = 0.062
	# The reference creatures' mouths run most of the way across the body. Zorp keeps a calm smile,
	# but a notably wider one — which is what fills the space the muzzle used to occupy.
	mouth_w = 0.074
	mouth_h = 0.052


func _build_geometry() -> void:
	_add_torso_bean(SHIRT, {"chamfer_color": SHIRT.darkened(0.20)})
	# hem: a band of bare skin under the tee so the bean still reads as a body. Superellipsoid, so
	# the tee ends on a hard horizontal edge instead of fading into another sphere.
	_mi(superellipsoid(Vector3(TORSO_RX * 0.93, TORSO_RY * 0.44, TORSO_RZ * 0.95), 2.9, 16, 8),
		_toon(SKIN, _matte({})), _torso, Vector3(0.0, TORSO_Y - 0.142, 0.0), "Hem")
	# chest motif, the way AC tees carry one — a flat chamfered badge with a bevelled rim, not the
	# six-ball star the first pass used (R2.3: "if a form can be described as a bunch of balls...").
	var emblem := _node("Emblem", _torso, Vector3(0.0, TORSO_Y + 0.012, -TORSO_RZ * 0.93))
	_mi(rounded_box(Vector3(0.108, 0.108, 0.020), 0.030, 12), _toon(SHIRT_TRIM, _matte({"rim": 0.03})),
		emblem, Vector3.ZERO, "Badge").rotation.z = PI * 0.25
	_mi(rounded_box(Vector3(0.062, 0.062, 0.022), 0.016, 10), _toon(SHIRT.darkened(0.22), _matte({})),
		emblem, Vector3(0.0, 0.0, -0.006), "Inlay").rotation.z = PI * 0.25
	_add_arms(SHIRT, SKIN, 3)
	_add_legs(SKIN_DARK, FOOT)
	_add_head_shell(SKIN)

	# R3: two fins used to sit here and they read as EARS. The muzzle, the nose and the blush are
	# gone for the same reason. Eyestalks instead — built AFTER the face, so the eye nodes exist to
	# be lifted onto them.
	# `nose: false` and `blush: false` are the switches the robots already use. Passing a
	# transparent blush colour instead does NOT work — the toon material is opaque, so an alpha-0
	# colour renders as two BLACK ovals on the cheeks, which is what the first attempt did.
	_add_face(EYE, MOUTH, BLUSH, {"mouth_inner": Color("#6e3049"), "nose": false, "blush": false})
	_build_eyestalks()
	# BROWS OFF. They are drawn on the head, and with the real eyes lifted onto stalks the two
	# dark brow bars were the only marks left up there — so they read as a second pair of eyes,
	# which put the animal face straight back. The reference creatures have no brows at all.
	for b: Node3D in _brows:
		b.queue_free()
	_brows.clear()
	# Drop the mouth down the now-empty face.
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node != null:
		_orient_on_head(mouth_node, 0.0, MOUTH_PITCH_ALIEN, 0.004)

	_build_scarf()

	_antenna = _add_antenna(_head, Vector3(0.045, HEAD_R * 0.88, 0.015), -0.20, SKIN_DARK, BULB, 0.085, 0.052)
	_bulb_mat = _antenna.get_meta("bulb_mat") as ShaderMaterial

	_build_glow_ring()


## Two soft stalks off the head's upper slope, each carrying one of the face's existing eye nodes at
## its tip. The eyes are MOVED, not rebuilt: `_eyes[i]` keeps all of its children (oval, glint, happy
## arc, round surprise, flat squint) so `_apply_face` drives them exactly as it always did.
func _build_eyestalks() -> void:
	var m_stalk := _toon(SKIN, _matte({"spec": 0.05}))
	var m_sclera := _toon(SCLERA, _matte({"spec": 0.04, "rim": 0.02}))
	for i in _eyes.size():
		var sx := -1.0 if i == 0 else 1.0
		var base := Vector3(STALK_BASE_X * sx, HEAD_SEMI.y * STALK_BASE_Y, STALK_Z)
		var tip := Vector3(STALK_TIP_X * sx, STALK_TIP_Y, STALK_Z - 0.012)
		var span := tip - base
		var length := span.length()
		# A capsule runs along its own +Y, so build a basis whose Y follows the stalk.
		var yv := span.normalized()
		var xv := Vector3.RIGHT if absf(yv.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var zv := xv.cross(yv).normalized()
		xv = yv.cross(zv).normalized()
		var stalk := _node("EyeStalk%d" % i, _head, base + span * 0.5)
		stalk.basis = Basis(xv, yv, zv)
		_mi(capsule(STALK_R, maxf(0.02, length - STALK_R * 2.0), 8, 2), m_stalk, stalk, Vector3.ZERO, "Stem")
		# A pale ball at the tip; the face's dark oval sits proud of it and becomes the pupil.
		_mi(sphere(0.062, 14, 8), m_sclera, _head, tip, "Eyeball%d" % i)
		# Aim each eye forward but splayed a little outward and down — two stalks staring dead ahead
		# in parallel look like a toy rather than a creature.
		var eye: Node3D = _eyes[i]
		eye.basis = Basis.looking_at(Vector3(0.20 * sx, -0.14, -1.0).normalized(), Vector3.UP)
		eye.position = tip + eye.basis.z * -0.052


## Striped space-scarf where a neck would be (there is none — it sits on the shoulders).
func _build_scarf() -> void:
	var m_a := _toon(SCARF_A, _matte({"spec": 0.03}))
	var m_b := _toon(SCARF_B, _matte({"spec": 0.03}))
	var scarf := _node("Scarf", _torso, Vector3(0.0, TORSO_Y + TORSO_RY * 0.74, 0.0))
	# one collar with a flat top face and a chamfered edge, wrapped by thin stripes: fabric with a
	# fold in it, not a stack of donuts
	_mi(superellipsoid(Vector3(0.176, 0.076, 0.160), 3.0, 14, 8), m_a, scarf, Vector3(0.0, -0.012, 0.0), "Collar")
	for i in 3:
		var stripe := _mi(torus(0.150, 0.188, 18, 5), m_b, scarf, Vector3(0.0, 0.012 - 0.034 * i, 0.0), "Stripe")
		stripe.scale = Vector3(0.99 - 0.05 * i, 0.30, 0.90 - 0.05 * i)
	# a short tail hanging over the left shoulder
	var tail := _node("Tail", scarf, Vector3(-0.115, -0.048, -0.115))
	tail.rotation = Vector3(-0.22, 0.30, 0.30)
	for i in 3:
		var seg := _mi(rounded_box(Vector3(0.075, 0.052, 0.032), 0.016, 10), m_b if i % 2 == 0 else m_a, tail, Vector3(0.008 * i, -0.05 * i, 0.0), "Seg")
		seg.rotation.z = 0.06 * i


func _build_glow_ring() -> void:
	var q := QuadMesh.new()
	q.size = Vector2(0.72, 0.72)
	q.orientation = PlaneMesh.FACE_Y
	_glow_ring = MeshInstance3D.new()
	_glow_ring.name = "HoverGlow"
	_glow_ring.mesh = q
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_mat.albedo_color = Color(BULB.r, BULB.g, BULB.b, 0.30)
	_ring_mat.albedo_texture = soft_dot_texture()
	_ring_mat.disable_receive_shadows = true
	_glow_ring.material_override = _ring_mat
	_glow_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow_ring.position = Vector3(0.0, 0.012, 0.0)
	add_child(_glow_ring)


func _animate_extras(delta: float) -> void:
	_bob += delta
	# soft hover bob (the whole model floats; the glow ring stays on the ground)
	_root.position.y = hover_height + sin(TAU * _bob / 2.6) * 0.022
	var droop := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
	var perk := clampf(pose(P.EXTRA_A), 0.0, 1.0)
	if _antenna:
		var rest: float = _antenna.get_meta("rest_tilt", -0.16)
		_antenna.rotation.z = rest - 0.95 * droop + 0.10 * perk
		_antenna.rotation.x = 0.55 * droop + 0.06 * sin(TAU * _bob * 0.7)
	if _bulb_mat:
		var rate := 1.6 if perk > 0.4 else 2.6
		var pulse := 0.5 + 0.5 * sin(TAU * _bob / rate)
		_bulb_mat.set_shader_parameter("emission_strength", (0.6 + 1.2 * pulse) * (1.0 - 0.6 * droop))
	if _ring_mat:
		var a := 0.24 + 0.10 * sin(TAU * _bob / 2.6 + 1.2)
		_ring_mat.albedo_color = Color(BULB.r, BULB.g, BULB.b, a)


## Small radial falloff texture used for the hover glow (shared, generated once).
static var _dot_tex: ImageTexture

static func soft_dot_texture() -> ImageTexture:
	if _dot_tex:
		return _dot_tex
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / n * 2.0 - 1.0
			var v := (float(y) + 0.5) / n * 2.0 - 1.0
			var d := sqrt(u * u + v * v)
			var a := clampf(1.0 - smoothstep(0.15, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
	_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex
