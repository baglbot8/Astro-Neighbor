class_name DJModel
extends ChibiModel
## DJ Nova — the event-space robot (our K.K. Slider). Sleek purple shell, oversized round headphones
## with glowing cups, soft rim lights, and a live equalizer visor across her BROW. The AC face comes
## first and fills the front of her head: a pale rounded-rectangle panel with two small dark eyes
## under resting brow bars, a calm smile and a real open mouth — she reads as a neighbour who
## happens to own a sound system. No blush (R2.3: none on the robots). (The first pass never called
## `_add_mouth`, so she literally had no mouth and the equalizer sat where one should be, reading as
## a barcode.)

## R2.6. DJ Nova was the second worst offender: her violet shell measured S 0.89 across 35 % of her
## own crop (saturation mean 0.611, p90 0.906) — a neon body under a near-white face panel.
##   shell  #6446b6 S0.62 V0.71 -> #7d70a4 S0.32 V0.64   (dusty violet: same hue, half the chroma)
##   trim   #f77ecf S0.49 V0.97 -> #bf90a4 S0.25 V0.75
##   panel  #efe6ff V1.00       -> #b6b0c6 V0.78         (no near-clipping whites)
## Measured on a real noon frame afterwards: gameplay crop saturation mean 0.378, value mean 0.564,
## 0 % blown, dominant swatch S 0.50.
## The neon accents stay saturated on purpose: R2.6 allows small bright accents (a seam light, a
## screen), just not whole surfaces.
const SHELL := Color("#7d70a4")
const SHELL_DARK := Color("#574e75")
const TRIM := Color("#bf90a4")
const NEON := Color("#4fb5cf")
const PANEL := Color("#b6b0c6")     ## pale face panel; the features on it are dark, like K.K.'s
const PANEL_EDGE := Color("#413a5e")
const INK := Color("#272338")
const CUP := Color("#453d63")
const BOOT := Color("#6a5f8f")

const HEAD_SIZE := Vector3(0.655, 0.615, 0.565)
## R2.3: 0.185 -> 0.118, same as Bolt. Her head is a machined block with chamfers and panel lines.
const HEAD_ROUND := 0.118
const BEZEL_Z := -0.254
const PANEL_Z := -0.268
const FACE_Z := -0.328
## 0.1754 m / 0.655 m head = 26.8 % geometric; the face plane is 0.328 m proud of the head's widest
## point, so it projects to 28.2 % at 6.5 m, 32.0 % at 2.05 m and 34.0 % at 1.60 m — inside the
## mandated 28-35 % band. (0.1725 measured 27.7 % at 6.5 m, a hair under.) The first pass was
## 0.196 m = 29.9 % geometric but with no mouth at all.
const EYE_SPACING := 0.1754
const BARS := 7

var _visor_bars: Array[MeshInstance3D] = []
var _bar_mats: Array[ShaderMaterial] = []
var _rim_mats: Array[ShaderMaterial] = []
var _cans: Array[Node3D] = []
var _face_plate: Node3D
var _t: float = 0.0


func _init() -> void:
	super()
	# R2.3 ("smaller and less glossy eyes relative to the head"): scaled with the base class's
	# own 19 % reduction so the robots keep their slightly chunkier screen features without going
	# back to the baby-doll size.
	eye_w = 0.0379
	eye_h = 0.0474
	eye_d = 0.0130
	mouth_w = 0.0555
	mouth_h = 0.0455
	mouth_d = 0.0120


func _build_geometry() -> void:
	# R2.6: the painted shell is matte (spec 0.24 -> 0.05). The only gloss left on her is the visor
	# glass over the equalizer, which is genuinely a screen.
	var m_shell := _toon(SHELL, _matte({"spec": 0.05, "spec_size": 120.0, "roughness": 0.8}))
	var m_dark := _toon(SHELL_DARK, _matte({"spec": 0.04}))
	var m_trim := _toon(TRIM, _matte({"spec": 0.04}))
	var m_cup := _toon(CUP, _matte({"spec": 0.05}))
	var m_seam := _toon(SHELL_DARK.darkened(0.16), _matte({"spec": 0.0}))

	# ---- torso: a chamfered block with a chest plate and side seams, not a squared balloon
	_mi(rounded_box(Vector3(0.450, 0.465, 0.380), 0.110, 18), m_shell, _torso, Vector3(0.0, TORSO_Y, 0.0), "Torso")
	_mi(rounded_box(Vector3(0.320, 0.290, 0.060), 0.032, 14), _toon(SHELL.lightened(0.06), _matte({"spec": 0.05})),
		_torso, Vector3(0.0, TORSO_Y + 0.015, -0.172), "ChestPlate")
	for sx1: float in [-1.0, 1.0]:
		_mi(rounded_box(Vector3(0.026, 0.330, 0.300), 0.010, 10), m_seam, _torso, Vector3(0.218 * sx1, TORSO_Y + 0.010, 0.0), "SideSeam")
	_mi(rounded_box(Vector3(0.392, 0.048, 0.330), 0.014, 12), m_trim, _torso, Vector3(0.0, TORSO_Y - 0.115, 0.0), "Belt")
	_mi(rounded_box(Vector3(0.325, 0.048, 0.280), 0.014, 12), m_trim, _torso, Vector3(0.0, TORSO_Y + 0.200, 0.0), "Collar")
	# soft rim lights down both sides of the chest
	for sx: float in [-1.0, 1.0]:
		var strip := _mi(rounded_box(Vector3(0.026, 0.24, 0.026), 0.012, 10), _lit(NEON, 1.6), _torso, Vector3(0.196 * sx, TORSO_Y + 0.015, -0.132), "RimLight")
		strip.rotation.z = 0.08 * sx
	_mi(torus(0.050, 0.072, 22, 6), _lit(TRIM, 1.4), _torso, Vector3(0.0, TORSO_Y + 0.02, -0.196), "ChestRing").rotation.x = PI * 0.5
	_mi(sphere(0.034, 14, 7), _lit(NEON, 1.8), _torso, Vector3(0.0, TORSO_Y + 0.02, -0.196), "ChestCore")

	_add_arms(SHELL, TRIM, 0)
	_add_legs(SHELL_DARK, BOOT)
	for leg: Node3D in [_leg_l, _leg_r]:
		var sole := _mi(rounded_box(Vector3(0.135, 0.016, 0.185), 0.007, 10), _lit(NEON, 1.4), leg, Vector3(0.0, -HIP_Y + 0.010, -0.022), "SoleGlow")
		sole.scale = Vector3(0.95, 1.0, 0.95)

	# ---- head
	_mi(rounded_box(HEAD_SIZE, HEAD_ROUND, 30), m_shell, _head, Vector3.ZERO, "HeadShell")
	# crown plate + jaw chamfer, so the block reads as panelled hardware
	_mi(rounded_box(Vector3(0.500, 0.052, 0.430), 0.018, 14), m_seam, _head, Vector3(0.0, 0.292, 0.010), "CrownSeam")
	_mi(rounded_box(Vector3(0.440, 0.060, 0.370), 0.016, 14), _toon(SHELL.lightened(0.07), _matte({"spec": 0.05})),
		_head, Vector3(0.0, 0.302, 0.010), "CrownPlate")
	var jaw := _mi(rounded_box(Vector3(0.556, 0.088, 0.400), 0.028, 14), m_dark, _head, Vector3(0.0, -0.278, -0.020), "JawPlate")
	jaw.rotation.x = deg_to_rad(-7.0)
	# rear detail: a ponytail-style aerial fin and two glowing tail lights
	var fin := _node("Fin", _head, Vector3(0.0, 0.085, 0.250))
	fin.rotation.x = -0.42
	for i in 3:
		var seg := _mi(rounded_box(Vector3(0.115 - 0.026 * i, 0.052, 0.150), 0.024, 12), m_dark, fin, Vector3(0.0, 0.040 * i, 0.060 * i), "Seg")
		seg.rotation.x = 0.22 * i
	for sx: float in [-1.0, 1.0]:
		_mi(rounded_box(Vector3(0.030, 0.130, 0.028), 0.013, 10), _lit(TRIM, 1.4), _head, Vector3(0.150 * sx, -0.070, 0.276), "TailLight")
	_build_headphones(m_dark, m_cup, m_trim)
	_build_face()


## Oversized round headphones: a band arcing left-to-right over the head, big cups on the sides.
func _build_headphones(m_band: Material, m_cup: Material, m_trim: Material) -> void:
	var band := _node("Band", _head, Vector3(0.0, 0.0, 0.02))
	_mi(arc_tube(0.325, 0.030, deg_to_rad(14.0), deg_to_rad(166.0), 18, 8), m_band, band, Vector3.ZERO, "Band")
	for sx: float in [-1.0, 1.0]:
		var can := _node("Can", _head, Vector3(0.318 * sx, -0.045, 0.02))
		can.rotation.z = PI * 0.5
		_mi(cylinder(0.132, 0.132, 0.090, 24), m_cup, can, Vector3(0.0, 0.030 * sx, 0.0), "Cup")
		_mi(torus(0.128, 0.158, 24, 8), m_trim, can, Vector3(0.0, 0.030 * sx, 0.0), "CupRim")
		_mi(torus(0.082, 0.102, 22, 6), _lit(NEON, 1.7), can, Vector3(0.0, 0.076 * sx, 0.0), "CupGlow")
		_mi(cylinder(0.074, 0.074, 0.028, 18), m_trim, can, Vector3(0.0, 0.084 * sx, 0.0), "CupCap")
		_cans.append(can)


## A pale rounded-rectangle face panel carrying the full AC face — two big dark eyes, blush and a
## real smile. The first pass gave her two pale rectangles and a 7-bar equalizer where a mouth
## should be, and never called `_add_mouth` at all, so `_mouth_smile`/`_mouth_open` stayed null and
## the whole mouth block in `_apply_face` was skipped. The equalizer is now a brow visor above the
## eyes, where it reads as her DJ headgear instead of as a barcode mouth.
func _build_face() -> void:
	_mi(rounded_box(Vector3(0.432, 0.330, 0.125), 0.040, 20), _toon(PANEL_EDGE, _matte({"spec": 0.24})), _head, Vector3(0.0, -0.014, BEZEL_Z), "Bezel")
	# 0.5 -> 0.32 day emission: at 0.5 the pale panel was the brightest thing in a noon frame
	_mi(rounded_box(Vector3(0.386, 0.286, 0.125), 0.030, 20), lit_material(PANEL, 0.32, Color("#e6e0f2")), _head, Vector3(0.0, -0.014, PANEL_Z), "Panel")

	_face_plate = _node("FacePlate", _face, Vector3(0.0, -0.014, FACE_Z))
	var m_ink := _toon(INK, {"spec": 0.0, "rim": 0.0, "shade": 0.08})
	var m_hl := _toon(GLINT, {"spec": 0.0, "rim": 0.0, "shade": 0.02})
	_add_flat_eyes(_face_plate, EYE_SPACING, 0.046, m_ink, m_hl)
	_add_flat_mouth(_face_plate, -0.054, m_ink, Color("#6d3055"))
	# R2.3: no blush on the robots — two pink cheek patches painted on a display panel were the
	# strongest "preschool cartoon" cue she had.

	# equalizer visor across the BROW, above the eyes — her headgear, not her mouth
	_mi(rounded_box(Vector3(0.330, 0.076, 0.070), 0.022, 16), _toon(SHELL_DARK, _matte({"spec": 0.06})), _head, Vector3(0.0, 0.176, -0.256), "VisorFrame")
	_mi(rounded_box(Vector3(0.286, 0.050, 0.070), 0.024, 16), _toon(PANEL_EDGE, {"spec": 0.4, "spec_size": 140.0, "rim": 0.10, "shade": 0.08}), _head, Vector3(0.0, 0.176, -0.264), "VisorGlass")
	var eq := _node("Equalizer", _face, Vector3(0.0, 0.176, -0.302))
	for i in BARS:
		var m := _lit(NEON.lerp(TRIM, float(i) / float(BARS - 1)), 1.8)
		_bar_mats.append(m)
		var bar := _mi(pixel_mesh(), m, eq, Vector3((float(i) - (BARS - 1) * 0.5) * 0.036, 0.0, 0.0), "Bar")
		bar.scale = Vector3(0.0115, 0.014, 0.008)
		_visor_bars.append(bar)


## An animatable (duplicated) emissive material, registered for the beat pulse.
func _lit(c: Color, strength: float) -> ShaderMaterial:
	var m := lit_material(c, strength).duplicate() as ShaderMaterial
	_rim_mats.append(m)
	return m


func _animate_extras(delta: float) -> void:
	_t += delta
	var beat := TAU * _t * 2.0            # 120 bpm
	for i in _visor_bars.size():
		var phase := float(i) * 0.7
		var h := 0.006 + 0.014 * absf(sin(beat * 0.5 + phase) * cos(beat * 0.23 + phase * 1.7))
		_visor_bars[i].scale.y = h
		_bar_mats[i].set_shader_parameter("emission_strength", 1.0 + 1.4 * (h - 0.006) / 0.014)
	var pulse := 0.5 + 0.5 * sin(beat)
	for m: ShaderMaterial in _rim_mats:
		if _bar_mats.has(m):
			continue
		m.set_shader_parameter("emission_strength", 1.1 + 1.0 * pulse)
	# head nods to the beat on top of whatever the pose says
	_head.rotation.x += 0.045 * sin(beat)
	_head.rotation.z += 0.030 * sin(beat * 0.5)
	for i in _cans.size():
		var sx := -1.0 if i == 0 else 1.0
		_cans[i].position.z = 0.02 + 0.006 * sin(beat + sx)
