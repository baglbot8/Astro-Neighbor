class_name DJFloatModel
extends ChibiModel
## The shared rig for DJ Nova as a FLOATING robot (2026-09-15, the user asked for a floating robot in
## a well-known film robot style). Built as OUR OWN robot in that sleek, glossy, simple register — never a copy: no
## white shell, no separate hovering head, no blue oval eyes, and it carries DJ gear instead.
##
## What this base owns, so the two body shapes (`dj_model.gd`, `dj_ring_model.gd`) cannot drift apart
## in manner:
##   * NO LEGS. `_leg_l` / `_leg_r` stay empty nodes. The whole body rides `hover_height` and bobs.
##   * A GLIDE instead of a walk: it leans into the direction of travel, its arms trail, and its
##     hover gear spins faster. `tick()` hands the base class a speed of 0, so the stride clock never
##     advances and no FOOTSTEP is ever emitted — a hovering robot has no feet to land.
##   * An LED FACE on a dark glossy screen: two light "pixel" eyes (no brows, no glint — they ARE the
##     light) with the cast's "^ ^" / "O O" / "- -" grammar, and a LIGHT-STRIP MOUTH. The strip is
##     this character's closed-mouth KIND (CAST_VARIETY ruling 6): at rest a short dotted line of
##     light, a smile when happy, an equalizer that bounces while it talks or dances, a small lit
##     ring when surprised and one scanning dot while it thinks. Nobody else has a mouth made of
##     light.
##   * THE BEAT. Its lights pulse at 120 bpm ("120 beats per minute. Every single time.") and it
##     nods along to it even while idle.
##
## Subclasses implement `_build_geometry()` and must, inside it:
##   * call `_add_led_eyes()` and `_add_light_strip()` on their face screen,
##   * register every beat-pulsing emissive via `_pulse()`,
##   * set `crown_top` (the highest point of the model at rest, root space, before the hover),
##   * optionally set `_spinner` (a node spun about its local Y by the glide / dance).
## and may override `_animate_parts(delta, beat)` for their own props.

## 120 bpm, in Hz. The emission pulse, the idle nod and the dance all share it.
const BEAT_HZ := 2.0
## Idle hover bob, metres. Every clearance check below subtracts this.
const HOVER_BOB := 0.022
## How far the robot rides UP while gliding, so the lean never brings its base toward the ground.
const GLIDE_LIFT := 0.035
const STRIP_PIXELS := 7
## Resting pixel half-height: a dot, so the resting strip reads as a dotted line of light.
const STRIP_DOT := 0.0062

## Resting outward roll of the arms. The fin / orb arms float clear of the body at this angle.
var arm_rest_roll: float = 0.22
## Arm roll for a raised arm (wave centre, happy and the dance's pumping arm). Per body shape: too
## high and the arm swings into a headphone cup (measured with dj_compare.gd --job=clearance).
var wave_roll: float = 2.35
var cheer_roll: float = 2.30
## Highest point at rest (root space, before `hover_height`). `marker_clearance()` reads it.
var crown_top: float = 1.0
## Head channels are multiplied by this before they reach the head node. A body shape whose head
## sits on a narrow seam opens a gap under a full villager head-roll, so it can tone them down.
var head_gain: float = 1.0
## LED colour of the eyes and the strip. Eye ink, so it is the one swatch allowed above S 0.60 —
## but it is a pale mint and stays well under it anyway.
var led_color: Color = Color("#9fe9d6")
## The strip is a touch deeper and cooler than the eyes. In the eyes' own pale mint, a row of lit
## bars in a dark screen read as TEETH on the first render (a toothy grin is a capped slot,
## CAST_VARIETY ruling 5); a coloured light reads as light.
var strip_color: Color = Color("#6fcfd6")

var _glide: float = 0.0
var _beat_t: float = 0.0
var _spin: float = 0.0
var _spinner: Node3D
var _spinner_angle: float = 0.0
var _strip: Array[MeshInstance3D] = []
var _strip_mat: ShaderMaterial
var _strip_o: Node3D
var _pulse_mats: Array[ShaderMaterial] = []
var _pulse_base: Array[float] = []


func _init() -> void:
	super()
	# The LED eyes are pill-shaped pixels, a touch squarer than the organic ovals. 0.040 x 0.050
	# half-extents on a ~0.72 m head is 11 % of head width by 18 % of head height — the quiet end
	# of the range R2.3 asks for, and light features read larger than dark ones, so no bigger.
	eye_w = 0.036
	eye_h = 0.046
	eye_d = 0.010


## "!" marker height: its crown plus the highest resting hover bob. npc.gd adds its own gap and
## never lets the marker drop below its 1.52 default, so this only ever lifts it.
func marker_clearance() -> float:
	return (hover_height + crown_top + HOVER_BOB) * body_scale


# ============================================================================= hover, not feet
func tick(delta: float, speed_factor: float) -> void:
	var want := speed_factor if get_state() == "walk" else 0.0
	_glide = lerpf(_glide, want, 1.0 - exp(-5.0 * delta))
	# ZERO, deliberately: the base stride clock only advances with a speed > 0.05, and it is the
	# stride clock that emits `footstep`. A gliding robot must not play footstep sounds.
	super.tick(delta, 0.0)


func _pose_idle(p: PackedFloat32Array) -> void:
	var bob := sin(TAU * _time / 2.6)
	var nod := maxf(0.0, sin(TAU * _time * BEAT_HZ))
	p[P.BODY_Y] = HOVER_BOB * bob
	p[P.TORSO_ROLL] = 0.035 * sin(TAU * _time / 4.3)
	p[P.TORSO_PITCH] = 0.018 * sin(TAU * _time / 2.6 + 1.2)
	p[P.HEAD_YAW] = _look_yaw
	p[P.HEAD_PITCH] = _look_pitch + 0.022 * nod
	p[P.HEAD_ROLL] = 0.025 * sin(TAU * _time / 5.1)
	# the arms float a beat BEHIND the body, which is what sells "hovering" over "standing"
	var lag := sin(TAU * _time / 2.6 - 0.9)
	p[P.ARM_L_ROLL] = arm_rest_roll + 0.05 * lag
	p[P.ARM_R_ROLL] = arm_rest_roll + 0.05 * lag
	p[P.ARM_L_PITCH] = 0.06 * lag
	p[P.ARM_R_PITCH] = 0.06 * lag
	p[P.EXTRA_A] = 0.0


## The glide. It leans INTO the move and rides a little higher; the arms sweep back like fins.
func _pose_walk(p: PackedFloat32Array) -> void:
	var g := clampf(_glide / 0.7, 0.0, 1.0)
	var ph := TAU * _time / 1.15
	p[P.BODY_Y] = GLIDE_LIFT * g + 0.012 * sin(ph)
	p[P.TORSO_PITCH] = -0.22 * g
	p[P.TORSO_ROLL] = 0.06 * sin(ph * 0.5)
	p[P.TORSO_YAW] = 0.05 * sin(ph * 0.5)
	p[P.HEAD_PITCH] = 0.09 * g
	p[P.HEAD_ROLL] = -0.04 * sin(ph * 0.5)
	p[P.ARM_L_ROLL] = arm_rest_roll + 0.20 * g
	p[P.ARM_R_ROLL] = arm_rest_roll + 0.20 * g
	p[P.ARM_L_PITCH] = -0.50 * g + 0.06 * sin(ph)
	p[P.ARM_R_PITCH] = -0.50 * g + 0.06 * sin(ph + 0.6)
	p[P.EXTRA_A] = g


func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	p[P.HEAD_PITCH] += 0.05 * sin(TAU * t * 1.25)
	p[P.HEAD_ROLL] += 0.05 * sin(TAU * t * 0.7)
	p[P.TORSO_ROLL] += 0.03 * sin(TAU * t * 0.9)
	p[P.MOUTH_OPEN] = 0.45 + 0.55 * maxf(0.0, sin(TAU * t * 4.2))
	# one arm talks with its, forward and out
	p[P.ARM_R_ROLL] = arm_rest_roll + 0.40 + 0.22 * sin(TAU * t * 1.15)
	p[P.ARM_R_PITCH] = 0.40 + 0.25 * sin(TAU * t * 1.7)


func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var w := sin(TAU * t * 3.6)
	p[P.ARM_R_ROLL] = wave_roll + 0.35 * w
	p[P.ARM_R_PITCH] = -0.15
	p[P.ARM_R_YAW] = 0.25 * w
	p[P.HEAD_ROLL] = -0.14
	p[P.HEAD_YAW] = 0.10
	p[P.TORSO_ROLL] = 0.08
	p[P.BODY_Y] += 0.025
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.0


## Happy is a LOOP, not a hop: it rises, spins once all the way round with both arms up, and settles.
## A hop needs feet to push off; a hovering robot celebrates in the air.
func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var up := sin(PI * clampf(t / 1.25, 0.0, 1.0))
	p[P.BODY_Y] = 0.14 * up + 0.012 * sin(TAU * t * 2.5)
	p[P.ARM_L_ROLL] = cheer_roll + 0.12 * sin(TAU * t * 3.0)
	p[P.ARM_R_ROLL] = cheer_roll - 0.12 * sin(TAU * t * 3.0)
	p[P.ARM_L_PITCH] = 0.10
	p[P.ARM_R_PITCH] = 0.10
	p[P.HEAD_PITCH] = -0.10
	p[P.HEAD_ROLL] = 0.07 * sin(TAU * t * 1.6)
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.0
	p[P.EXTRA_B] = 1.0


func _pose_think(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var u := clampf(t / 0.4, 0.0, 1.0)
	# one arm comes up under its screen, the other hangs; its head tips away from it
	var tp := _think_arm_pose()
	p[P.ARM_R_ROLL] = lerpf(arm_rest_roll, tp.x, u)
	p[P.ARM_R_PITCH] = tp.y * u
	p[P.ARM_R_YAW] = tp.z * u
	p[P.HEAD_ROLL] = 0.20 * u + 0.03 * sin(TAU * t * 0.8)
	p[P.HEAD_PITCH] = -0.10 * u
	p[P.HEAD_YAW] = -0.14 * u
	p[P.TORSO_ROLL] = -0.05 * u
	p[P.BROW] = u
	p[P.MOUTH_OPEN] = 0.0


## THE DANCE (the finale gift scene plays it). Four things on the beat at once, so it reads
## from across the plaza: the whole body bounces and sways, one arm holds a headphone cup to its
## head while the other pumps the air (they swap halfway), its head nods, and on the last bar it
## spins once all the way round. The equalizer mouth and every light pulse to the same 120 bpm.
func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	var beat := TAU * t * BEAT_HZ
	var bounce := absf(sin(beat))
	var alt := sin(beat * 0.5)
	var lt := fmod(t, 2.8)
	var side := 1.0 if lt < 1.4 else -1.0
	p[P.BODY_Y] = 0.030 + 0.060 * bounce
	p[P.SQUASH] = 1.0 + 0.025 * sin(beat * 2.0)
	p[P.TORSO_ROLL] = 0.15 * alt
	p[P.TORSO_YAW] = 0.20 * alt
	p[P.TORSO_PITCH] = -0.05 * bounce
	# the head tips AWAY from the arm holding the cup (tipping toward it pushes the cup into the arm)
	p[P.HEAD_ROLL] = -0.06 * side + 0.03 * alt
	p[P.HEAD_PITCH] = 0.10 * bounce - 0.03
	var hold := _headphone_hold_pose()
	var pump_roll := cheer_roll + 0.10 * bounce
	if side > 0.0:
		p[P.ARM_L_ROLL] = hold.x
		p[P.ARM_L_PITCH] = hold.y
		p[P.ARM_L_YAW] = hold.z
		p[P.ARM_R_ROLL] = pump_roll
		p[P.ARM_R_PITCH] = -0.10 + 0.40 * bounce
	else:
		p[P.ARM_R_ROLL] = hold.x
		p[P.ARM_R_PITCH] = hold.y
		p[P.ARM_R_YAW] = hold.z
		p[P.ARM_L_ROLL] = pump_roll
		p[P.ARM_L_PITCH] = -0.10 + 0.40 * bounce
	p[P.MOUTH_OPEN] = 0.75
	p[P.EYE_HAPPY] = 1.0
	p[P.EXTRA_A] = 1.0
	p[P.EXTRA_B] = 1.0


## (roll, pitch, yaw) of the arm raised to its "chin" (under the screen) for think.
func _think_arm_pose() -> Vector3:
	return Vector3(-0.55, 1.45, 0.0)


## (roll, pitch, yaw) that brings an arm up beside the headphone cup without entering it. Per body
## shape, because the arm length and the cup position differ. Measured on renders, not derived.
func _headphone_hold_pose() -> Vector3:
	return Vector3(2.10, -0.20, 0.0)


## Surprised: a jolt UP and BACK, arms flung out, "O O" eyes and an "o" on the strip.
func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	var k := clampf(t / 0.22, 0.0, 1.0)
	var jolt := sin(k * PI * 0.5)
	var settle := clampf((t - 0.5) / 0.7, 0.0, 1.0)
	p[P.BODY_Y] = 0.12 * jolt * (1.0 - 0.5 * settle)
	p[P.BODY_Z] = 0.16 * k
	p[P.TORSO_PITCH] = 0.10 * jolt
	p[P.HEAD_PITCH] = -0.08 * jolt
	p[P.ARM_L_ROLL] = 1.30
	p[P.ARM_R_ROLL] = 1.30
	p[P.ARM_L_PITCH] = 0.35
	p[P.ARM_R_PITCH] = 0.35
	p[P.EYE_ROUND] = 1.0
	p[P.EYE_WIDE] = 1.25
	p[P.MOUTH_OPEN] = 1.0
	p[P.EXTRA_B] = 1.0


# ============================================================================= face
## Two LED eyes on a face screen. Same five-array contract as `_add_flat_eyes` (plus the "- -" dash
## array), but NO brow and NO glint: the eye is the light source, a highlight on it would be a
## second light, and a brow drawn on a visor reads as a sticker. The quiet register R2.3 asks for
## comes from the size and the calm resting strip instead.
## `z_of` returns the screen's front surface z at a given (x, y), so each eye sits ON a curved
## screen instead of on a flat plane that sinks into its sides.
func _add_led_eyes(parent: Node3D, spacing: float, y_off: float, z_of: Callable, m_led: Material) -> void:
	var fs := face_scale
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var x := spacing * 0.5 * sx
		var z: float = z_of.call(x, y_off)
		var eye := _node("Eye%d" % i, parent, Vector3(x, y_off, z))
		_eyes.append(eye)
		var oval := _mi(_eye_mesh("bar"), m_led, eye, Vector3.ZERO, "Oval")
		oval.scale = Vector3(eye_w * fs, eye_h * fs, eye_d)
		_eye_ovals.append(oval)
		_eye_size.append(Vector3(eye_w, eye_h, eye_d))
		var happy := _node("Happy", eye, Vector3(0.0, -0.008 * fs, -0.002))
		_mi(arc_tube(eye_w * fs * 1.15, eye_w * fs * 0.34, deg_to_rad(22.0), deg_to_rad(158.0), 12, 6), m_led, happy, Vector3.ZERO, "Arc")
		happy.visible = false
		_eye_happy.append(happy)
		var round_eye := _node("Round", eye, Vector3(0.0, 0.002, -0.002))
		var ring := _mi(torus(eye_w * fs * 0.62, eye_w * fs * 1.22, 16, 5), m_led, round_eye, Vector3.ZERO, "Ring")
		ring.rotation.x = PI * 0.5
		ring.scale = Vector3(1.0, 1.0, 1.10)
		round_eye.visible = false
		_eye_round.append(round_eye)
		var flat := _node("Flat", eye, Vector3(0.0, -0.006 * fs, -0.002))
		var dash := _mi(rounded_box(Vector3(eye_w * fs * 2.2, eye_h * fs * 0.40, eye_d * 1.4), eye_h * fs * 0.19, 12), m_led, flat, Vector3.ZERO, "Dash")
		dash.rotation.z = deg_to_rad(-6.0 * sx)
		flat.visible = false
		_eye_flat.append(flat)


## The light-strip mouth: STRIP_PIXELS rounded pixels in a row. Its whole behaviour is in
## `_animate_strip`. Width: 6 gaps of `pitch` plus one pixel, so pitch 0.026 on a 0.72 m head is
## 0.166 m = 23 % of head width — inside the cast's 16-25 % mouth band.
func _add_light_strip(parent: Node3D, y_off: float, z_of: Callable, pitch: float) -> void:
	_strip_mat = lit_material(strip_color, 1.6).duplicate() as ShaderMaterial
	var strip := _node("LightStrip", parent, Vector3(0.0, y_off, 0.0))
	strip.set_meta("pitch", pitch)
	for i in STRIP_PIXELS:
		var x := (float(i) - (STRIP_PIXELS - 1) * 0.5) * pitch
		var z: float = z_of.call(x, y_off)
		var px := _mi(pixel_mesh(), _strip_mat, strip, Vector3(x, 0.0, z), "Pixel")
		px.scale = Vector3(pitch * 0.28, STRIP_DOT, 0.006)
		px.set_meta("x", x)
		px.set_meta("z", z)
		_strip.append(px)
	# surprised: a small lit ring, NOT three tall bars (which also read as teeth)
	_strip_o = _node("O", strip, Vector3(0.0, 0.0, float(z_of.call(0.0, y_off)) - 0.002))
	var ring := _mi(torus(pitch * 0.55, pitch * 0.95, 16, 5), _strip_mat, _strip_o, Vector3.ZERO, "Ring")
	ring.rotation.x = PI * 0.5
	ring.scale = Vector3(1.0, 1.0, 1.25)
	_strip_o.visible = false


## A beat-pulsing emissive (a duplicate, so its strength can move without touching the cache).
func _pulse(c: Color, strength: float) -> ShaderMaterial:
	var m := lit_material(c, strength).duplicate() as ShaderMaterial
	_pulse_mats.append(m)
	_pulse_base.append(strength)
	return m


## The front-surface z of a superellipsoid (centre `c`, half-extents `semi`, exponent `n`) at
## (x, y), or `fallback` outside it. Negative, because the model faces -Z.
static func se_front_z(x: float, y: float, c: Vector3, semi: Vector3, n: float, fallback: float) -> float:
	var s := 1.0 - pow(absf(x - c.x) / semi.x, n) - pow(absf(y - c.y) / semi.y, n)
	if s <= 0.0:
		return fallback
	return c.z - semi.z * pow(s, 1.0 / n)


## A LATHE: `profile` is (radius, y) pairs from bottom to top, spun about Y into `segs` columns.
## Every body in the floating robots is one of these, because an egg and a bullet taper — which a
## superellipsoid, being symmetric about its centre, cannot. Wound GODOT's way (clockwise from
## outside; see the winding note in chibi_model.gd): the first quad is tested and the whole index
## order flipped if it came out inside-out, so this cannot silently render back faces.
static func lathe(profile: PackedVector2Array, segs: int) -> ArrayMesh:
	var key := "lathe|%s|%d" % [str(profile), segs]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var n := profile.size()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var n2: Array[Vector2] = []
	for i in n:
		var a := profile[maxi(i - 1, 0)]
		var b := profile[mini(i + 1, n - 1)]
		var tg := (b - a).normalized()
		n2.append(Vector2(tg.y, -tg.x))
	for j in segs + 1:
		var ang := TAU * float(j) / float(segs)
		var ca := cos(ang)
		var sa := sin(ang)
		for i in n:
			var pr := profile[i]
			verts.append(Vector3(pr.x * ca, pr.y, pr.x * sa))
			norms.append(Vector3(n2[i].x * ca, n2[i].y, n2[i].x * sa).normalized())
			uvs.append(Vector2(float(j) / segs, float(i) / (n - 1)))
	var idx := PackedInt32Array()
	for j in segs:
		for i in n - 1:
			var a0 := j * n + i
			var a1 := j * n + i + 1
			var b0 := (j + 1) * n + i
			var b1 := (j + 1) * n + i + 1
			idx.append_array([a0, a1, b1, a0, b1, b0])
	# Winding check against the profile's own outward NORMALS (not the radial direction: a flat
	# bottom disc has a downward normal and no radial component, and testing it radially flipped a
	# whole head inside-out on the first render). Godot's front face is clockwise, i.e. the
	# geometric cross product points INWARD, against the shading normal.
	for q in range(0, idx.size(), 3):
		var v0 := verts[idx[q]]
		var v1 := verts[idx[q + 1]]
		var v2 := verts[idx[q + 2]]
		var cr := (v1 - v0).cross(v2 - v0)
		if cr.length_squared() < 1e-10:
			continue
		var outward := norms[idx[q]] + norms[idx[q + 1]] + norms[idx[q + 2]]
		if cr.dot(outward) > 0.0:
			for t in range(0, idx.size(), 3):
				var tmp := idx[t + 1]
				idx[t + 1] = idx[t + 2]
				idx[t + 2] = tmp
		break
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mesh_cache[key] = am
	return am


# ============================================================================= per frame
func _animate_extras(delta: float) -> void:
	_beat_t += delta * anim_time_scale
	var beat := TAU * _beat_t * BEAT_HZ
	var hg := head_gain
	if not is_equal_approx(hg, 1.0):
		_head.rotation *= hg
	_animate_strip(beat)
	var pulse := 0.5 + 0.5 * sin(beat)
	var lift := 1.0 + 0.6 * clampf(pose(P.EXTRA_B), 0.0, 1.0)
	for i in _pulse_mats.size():
		_pulse_mats[i].set_shader_parameter("emission_strength", _pulse_base[i] * (0.70 + 0.55 * pulse) * lift)
	_animate_spin(delta)
	if _spinner:
		var rate := 1.2 + 5.0 * clampf(pose(P.EXTRA_A), 0.0, 1.0)
		_spinner_angle = wrapf(_spinner_angle + rate * delta, 0.0, TAU)
		_spinner.rotation.y = _spinner_angle
	_animate_parts(delta, beat)


## Per-body props (fins, rings). Called last every frame.
func _animate_parts(_delta: float, _beat: float) -> void:
	pass


## The whole-body spin for "happy" (once, rising) and "dance" (once, on the last bar). Driven from
## the state clock rather than a pose channel: a lerped channel would unwind the full turn backwards
## on the way out. `lerp_angle` takes the short way home when the state changes mid-spin.
func _animate_spin(delta: float) -> void:
	var st := get_state()
	var t := get_state_time()
	var want := -1.0
	if st == "happy":
		want = TAU * smoothstep(0.15, 1.05, t)
	elif st == "dance":
		var lt := fmod(t, 2.8)
		want = TAU * smoothstep(1.95, 2.65, lt)
	if want >= 0.0:
		_spin = want
	else:
		_spin = lerp_angle(_spin, 0.0, 1.0 - exp(-8.0 * delta))
	_body.rotation.y = _spin


func _animate_strip(beat: float) -> void:
	if _strip.is_empty():
		return
	var mo := clampf(pose(P.MOUTH_OPEN), 0.0, 1.0)
	var happy := pose(P.EYE_HAPPY) > 0.5
	var round_eye := pose(P.EYE_ROUND) > 0.5
	var think := pose(P.BROW) > 0.5
	var half := (STRIP_PIXELS - 1) * 0.5
	var scan := int(round((sin(get_state_time() * 3.2) * 0.5 + 0.5) * float(STRIP_PIXELS - 1)))
	var talk_glow := 1.2
	for i in STRIP_PIXELS:
		var px := _strip[i]
		var u := (float(i) - half) / half
		var h := STRIP_DOT
		var y := 0.0
		var show := absf(u) < 0.75
		if round_eye:
			show = false
			talk_glow = 2.0
		elif mo > 0.02:
			var ph := float(i) * 0.9
			var eq := absf(sin(beat * 0.5 + ph) * cos(beat * 0.23 + ph * 1.7))
			h = STRIP_DOT + 0.015 * mo * (0.30 + 0.70 * eq)
			show = true
			talk_glow = 1.4 + 1.0 * mo
		elif think:
			show = i == scan
			h = STRIP_DOT * 1.2
		elif happy:
			show = true
			y = 0.016 * u * u - 0.004
		px.visible = show
		if show:
			px.scale.y = h
			px.position.y = y
	_strip_o.visible = round_eye
	_strip_mat.set_shader_parameter("emission_strength", talk_glow)
