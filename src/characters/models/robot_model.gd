class_name RobotModel
extends ChibiModel
## Bolt — the friendly teal robot. Same ACNH chibi proportions and face grammar as the organic
## villagers, only every shape is a chamfered panelled block and the face is drawn on a clean
## rounded-rectangle screen: a PALE panel carrying DARK navy features (Tom Nook's eye patch, not its
## inverse), with small oval eyes under a resting brow bar, a single "^ ^" arc, a single "O O" ring,
## a single "- -" dash, and one calm smile over a real open mouth. No blush — R2.3 asks for none on
## the robots, and two pink cheek patches painted on a display were the most Cocomelon thing here.
## Extras: one antenna with a blinking orange light, round claw hands, chunky feet, a chest dial
## that spins while he talks, a shoulder vent that puffs when he is happy, and a rear vent grille.

## R2.6 (PASTEL AND MATTE), re-measured in the current game:
##   shell  #6fcdc5 S0.46 V0.80 -> #7fb9b3 S0.31 V0.73
##   accent #f7912f S0.81 V0.97 -> #bf9a72 S0.40 V0.75  (the orange was the loudest thing on him:
##          it rendered S 0.76 and set his whole saturation p90 at 0.778)
##   screen #e2f2ef V0.95       -> #c4cec8 V0.81        (a near-white faceplate is half the
##          "cocomelon" read; it is now a soft off-white panel, still the palest thing on him)
## Measured on a real noon frame afterwards: head crop saturation mean 0.293, value mean 0.693, 0 %
## blown, dominant swatch S 0.26. He reads LOW-chroma on purpose — his face is a display panel, and
## Tom Nook is low-chroma too.
const SHELL := Color("#7fb9b3")
const SHELL_DARK := Color("#5f8c88")
const ACCENT := Color("#bf9a72")
const ACCENT_DARK := Color("#977d5e")
## The screen is a PALE panel with DARK features on it — AC grammar (Tom Nook's eye patch), not the
## light-on-dark inverse the first pass shipped.
const SCREEN := Color("#c4cec8")
const SCREEN_EDGE := Color("#2b3d4f")
const INK := Color("#232c3a")
const INK_HL := Color("#ded9ce")
const METAL := Color("#a4aebc")

## Head is a rounded box 0.660 x 0.615 x 0.560. R2.3 ("less round"): the corner radius came down
## from 0.185 to 0.118, so the head is a machined block with real chamfers and flat sides that read
## as PLATES, not a pillow. Panel seams and a jaw plate are added in `_build_geometry`.
const HEAD_SIZE := Vector3(0.660, 0.615, 0.560)
const HEAD_ROUND := 0.118
const BEZEL_Z := -0.252
const SCREEN_Z := -0.266
const FACE_Z := -0.326             ## the plane the features are drawn on (just proud of the screen)
## 0.1768 m / 0.660 m head = 26.8 % geometric. The face plane sits 0.326 m in front of the head's
## widest point, so it projects WIDER than that: 28.2 % at the 6.5 m gameplay camera, 31.9 % at a
## 2.05 m close-up and 33.9 % at 1.60 m — inside the mandated 28-35 % band at every realistic
## framing (docs/STYLE_GUIDE.md, and the orchestrator's standing ruling that 28-35 % holds).
## Nudged from 0.174 in this pass only because that measured 27.8 % at 6.5 m, a hair under the
## floor. The first pass was 0.150 m = 22.7 %.
const EYE_SPACING := 0.1768

var _screen: Node3D
var _dial: Node3D
var _vent: GPUParticles3D
var _antenna_mat: ShaderMaterial
var _screen_mat: ShaderMaterial
var _t: float = 0.0
var _vent_armed := true


func _init() -> void:
	super()
	# R2.3 ("smaller and less glossy eyes relative to the head"): scaled with the base class's
	# own 19 % reduction so the robots keep their slightly chunkier screen features without going
	# back to the baby-doll size.
	eye_w = 0.0383
	eye_h = 0.0478
	eye_d = 0.0130
	mouth_w = 0.0560
	mouth_h = 0.0460
	mouth_d = 0.0120


func _build_geometry() -> void:
	# R2.6: painted robot shell is MATTE. spec was 0.22-0.25, which painted a wet white ellipse on
	# the top of his head and both shoulders in every daylight frame. Only the screen is glossy now.
	var m_shell := _toon(SHELL, _matte({"spec": 0.04, "spec_size": 70.0}))
	var m_dark := _toon(SHELL_DARK, _matte({"spec": 0.04}))
	var m_accent := _toon(ACCENT, _matte({"spec": 0.05}))
	var m_seam := _toon(SHELL_DARK.darkened(0.18), _matte({"spec": 0.0}))
	var m_metal := MaterialLib.metal(METAL, {"spec": 0.22, "rim": 0.16, "metallic": 0.45})

	# ---- torso: a machined rounded box with a chest plate, a shoulder yoke and side seams
	_mi(rounded_box(Vector3(0.445, 0.465, 0.375), 0.105, 18), m_shell, _torso, Vector3(0.0, TORSO_Y, 0.0), "Torso")
	_mi(rounded_box(Vector3(0.330, 0.300, 0.060), 0.038, 14), _toon(SHELL.lightened(0.05), _matte({"spec": 0.04})),
		_torso, Vector3(0.0, TORSO_Y + 0.020, -0.170), "ChestPlate")
	for sx0: float in [-1.0, 1.0]:
		_mi(rounded_box(Vector3(0.026, 0.330, 0.300), 0.010, 10), m_seam, _torso, Vector3(0.216 * sx0, TORSO_Y + 0.010, 0.0), "SideSeam")
	_mi(rounded_box(Vector3(0.405, 0.052, 0.345), 0.016, 12), m_accent, _torso, Vector3(0.0, TORSO_Y - 0.140, 0.0), "Belt")
	_mi(rounded_box(Vector3(0.325, 0.048, 0.280), 0.014, 12), m_accent, _torso, Vector3(0.0, TORSO_Y + 0.200, 0.0), "Collar")
	# chest dial (spins while talking)
	_dial = _node("Dial", _torso, Vector3(0.0, TORSO_Y + 0.010, -0.196))
	_mi(cylinder(0.075, 0.075, 0.028, 20), m_dark, _dial, Vector3(0.0, 0.0, 0.0), "Bezel").rotation.x = PI * 0.5
	var face_disc := _mi(cylinder(0.058, 0.058, 0.030, 20), MaterialLib.glow(Color("#ffd98a"), 1.1, Color("#3a2c18")), _dial, Vector3(0.0, 0.0, -0.004), "Face")
	face_disc.rotation.x = PI * 0.5
	var needle := _node("Needle", _dial, Vector3(0.0, 0.0, -0.022))
	_mi(rounded_box(Vector3(0.012, 0.05, 0.008), 0.004, 10), m_accent, needle, Vector3(0.0, 0.022, 0.0), "Needle")
	_mi(sphere(0.014, 10, 5), m_metal, needle, Vector3.ZERO, "Hub")
	# shoulder vent
	var vent := _node("Vent", _torso, Vector3(0.150, TORSO_Y + 0.150, 0.115))
	for i in 3:
		_mi(rounded_box(Vector3(0.085, 0.014, 0.03), 0.006, 10), m_dark, vent, Vector3(0.0, -0.022 * i, 0.0), "Slat")
	_build_vent_puff(vent)

	_add_arms(SHELL, ACCENT, 0)
	_build_claws()
	_add_legs(SHELL_DARK, ACCENT_DARK)

	# ---- head: a chamfered block with real panel lines, screen face on the front
	_mi(rounded_box(HEAD_SIZE, HEAD_ROUND, 30), m_shell, _head, Vector3.ZERO, "HeadShell")
	# crown plate: a slightly inset flat top panel with a seam around it, so the top reads as a plate
	_mi(rounded_box(Vector3(0.510, 0.052, 0.430), 0.020, 14), m_seam, _head, Vector3(0.0, 0.290, 0.010), "CrownSeam")
	_mi(rounded_box(Vector3(0.450, 0.060, 0.370), 0.018, 14), _toon(SHELL.lightened(0.06), _matte({"spec": 0.04})),
		_head, Vector3(0.0, 0.300, 0.010), "CrownPlate")
	_mi(rounded_box(Vector3(0.30, 0.048, 0.26), 0.014, 12), m_accent, _head, Vector3(0.0, 0.332, 0.0), "Crest")
	# jaw chamfer: a wedge under the faceplate that gives the head a chin plane instead of a pillow
	var jaw := _mi(rounded_box(Vector3(0.560, 0.090, 0.400), 0.030, 14), m_dark, _head, Vector3(0.0, -0.278, -0.020), "JawPlate")
	jaw.rotation.x = deg_to_rad(-7.0)
	# side seams so the temples are panelled, not blank
	for sx1: float in [-1.0, 1.0]:
		_mi(rounded_box(Vector3(0.028, 0.400, 0.330), 0.010, 10), m_seam, _head, Vector3(0.324 * sx1, 0.010, 0.010), "TempleSeam")
	# back plate: a vent grille and a charge socket so the rear view is not a blank teal box
	_mi(rounded_box(Vector3(0.335, 0.230, 0.055), 0.026, 14), m_dark, _head, Vector3(0.0, -0.020, 0.268), "BackPlate")
	for i in 3:
		_mi(rounded_box(Vector3(0.255, 0.026, 0.045), 0.010, 10), m_seam, _head, Vector3(0.0, 0.048 - 0.062 * i, 0.288), "BackSlat")
	_mi(cylinder(0.048, 0.048, 0.030, 14), m_accent, _head, Vector3(0.0, -0.150, 0.292), "Socket").rotation.x = PI * 0.5
	for sx: float in [-1.0, 1.0]:
		var ear := _mi(cylinder(0.062, 0.062, 0.05, 14), m_metal, _head, Vector3(0.330 * sx, -0.01, 0.02), "EarCap")
		ear.rotation.z = PI * 0.5
		_mi(cylinder(0.03, 0.03, 0.056, 10), m_accent, _head, Vector3(0.340 * sx, -0.01, 0.02), "EarBolt").rotation.z = PI * 0.5
	_build_screen_face()
	var ant := _add_antenna(_head, Vector3(-0.050, 0.295, 0.02), -0.16, METAL, ACCENT, 0.115, 0.042)
	_antenna_mat = ant.get_meta("bulb_mat") as ShaderMaterial


func _build_claws() -> void:
	var m_claw := _toon(ACCENT_DARK, _matte({"spec": 0.05}))
	for hand: Node3D in [_hand_l, _hand_r]:
		if hand == null:
			continue
		for sx: float in [-1.0, 1.0]:
			var claw := _node("Claw", hand, Vector3(HAND_R * 0.55 * sx, -HAND_R * 0.55, -0.012))
			claw.rotation.z = 0.45 * sx
			# a tapered chamfered pincer, not a stretched ball
			_mi(superellipsoid(Vector3(0.024, 0.045, 0.027), 2.7, 10, 6), m_claw, claw, Vector3.ZERO, "Tip")


## The AC face on a clean rounded-rectangle faceplate. Bezel and screen are rounded boxes coaxial
## with the head's own rounded box, so the visible mask is a symmetric rounded rectangle — not the
## sphere-through-box intersection curve (with horn notches at the temples) the first pass shipped.
## The screen is pale and the features are dark navy, matching Tom Nook's eye patch.
func _build_screen_face() -> void:
	# the screen is the ONE genuinely shiny surface on him, so it keeps its gloss while the painted
	# shell went matte (R2.6: "reserve real gloss for genuinely shiny things")
	var m_bezel := _toon(SCREEN_EDGE, _matte({"spec": 0.26, "spec_size": 110.0}))
	_mi(rounded_box(Vector3(0.436, 0.316, 0.125), 0.040, 20), m_bezel, _head, Vector3(0.0, 0.010, BEZEL_Z), "Bezel")
	# the panel glows very gently, so it is a lit screen at night and still a matte face by day.
	# 0.55 -> 0.34: at 0.55 the pale panel was the brightest thing in the frame at noon.
	_screen_mat = lit_material(SCREEN, 0.34, Color("#e6f0ec")).duplicate() as ShaderMaterial
	_mi(rounded_box(Vector3(0.390, 0.272, 0.125), 0.032, 20), _screen_mat, _head, Vector3(0.0, 0.010, SCREEN_Z), "Screen")

	_screen = _node("ScreenFace", _face, Vector3(0.0, 0.010, FACE_Z))
	var m_ink := _toon(INK, {"spec": 0.0, "rim": 0.0, "shade": 0.08})
	var m_hl := _toon(INK_HL, {"spec": 0.0, "rim": 0.0, "shade": 0.02})
	_add_flat_eyes(_screen, EYE_SPACING, 0.042, m_ink, m_hl)
	_add_flat_mouth(_screen, -0.058, m_ink, Color("#6f3247"))
	# R2.3: "restrained blush (or none on the robots)". Bolt is a machine with a display for a face;
	# two pink cheek patches painted on a screen was the single most Cocomelon thing about him.


func _build_vent_puff(parent: Node3D) -> void:
	_vent = GPUParticles3D.new()
	_vent.name = "VentPuff"
	_vent.emitting = false
	_vent.one_shot = true
	_vent.amount = 10
	_vent.lifetime = 0.7
	_vent.explosiveness = 0.9
	_vent.local_coords = false
	_vent.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.04
	pm.direction = Vector3(0.5, 1.0, 0.2)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.3
	pm.gravity = Vector3(0.0, 0.4, 0.0)
	pm.damping_min = 2.0
	pm.damping_max = 3.5
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.2))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.75))
	grad.set_color(1, Color(0.88, 0.96, 1.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	_vent.process_material = pm
	var s := SphereMesh.new()
	s.radius = 0.05
	s.height = 0.1
	s.radial_segments = 8
	s.rings = 4
	var mat := MaterialLib.flat_unlit(Color(1, 1, 1, 0.8)).duplicate() as StandardMaterial3D
	mat.vertex_color_use_as_albedo = true
	s.material = mat
	_vent.draw_pass_1 = s
	_vent.position = Vector3(0.0, 0.02, 0.04)
	parent.add_child(_vent)


func _animate_extras(delta: float) -> void:
	_t += delta
	if _antenna_mat:
		var blink := 1.0 if fmod(_t, 1.5) < 0.22 else 0.0
		_antenna_mat.set_shader_parameter("emission_strength", 0.6 + 2.6 * blink)
	if _dial:
		var talking := pose(P.EXTRA_A) > 0.4
		_dial.rotation.z += delta * (5.5 if talking else 0.35)
	if _vent:
		var want := pose(P.EXTRA_B) > 0.5
		if want and _vent_armed:
			_vent_armed = false
			_vent.restart()
			_vent.emitting = true
		elif not want:
			_vent_armed = true
