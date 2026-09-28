class_name GloopModel
extends ChibiModel
## GLOOP — the slime who sells your prints (sky-watching spike, 2026-09-20).
##
## A glossy, OPAQUE jelly blob: no transparency anywhere (it is expensive on the phone and it reads
## worse at 6.5 m than a lit gloss highlight does). Everything that says "slime" here is silhouette
## or motion, not a shader:
##
##   * ONE CONTINUOUS MASS, WIDE AT THE GROUND. A lathed teardrop puddle (1.05 m wide at the base)
##     with an upper dome growing out of it. No neck, NO LEGS, no feet — the base IS the foot. Every
##     other neighbour is a standing biped, a saucer, a box or a floating egg; nobody else is a
##     ground-hugging dome, so Gloop is told apart by OUTLINE before any colour is read.
##   * A DRIP SKIRT: seven soft lobes where the jelly has spread onto the ground, each riding the
##     squash so the puddle spreads when Gloop settles and pulls in when it stretches.
##   * A DROPLET on the crown that lags the body (a spring, in `_animate_extras`) — the single
##     cheapest "this is liquid" cue there is, and it survives at gameplay distance in silhouette.
##   * SLOW SQUASH-STRETCH instead of breathing. `P.SQUASH` drives `_root.scale` as (1/sqrt(s), s,
##     1/sqrt(s)) in the base class, so the volume is preserved and it reads as jelly, not as a
##     balloon inflating. Idle 0.36 Hz, talk a 1.5 Hz wobble on top.
##   * SOMETHING SUSPENDED INSIDE. A shallow "window" low on the front of the body: a lighter-gel
##     lens ringed by a gel rim, with a small pale STAR-SEED sitting in it that drifts and turns
##     forever. The blob is opaque, so the window is geometry — a rim you look INTO — not glass.
##
## CAST_VARIETY (docs/CAST_VARIETY.md) — what Gloop does NOT take:
##   no eyestalks, no wide toothy grin, no `sd_skin` / `sd_scales` / `sd_foliage`, no lashes, and
##   ZERO of the capped hard vocabulary (no brow ridge, lid, horns, tusks, fangs, yoke — `brows` is
##   off, which is also what keeps the face in the "simple cute" register the brief asks for).
##   Its closed mouth is a KIND nobody holds: a ROUND TOOTHLESS SLOT (ruling 6 lists it; Zorp has
##   none, Fen a straight bar, Vela nothing, Grig an under-bite, DJ a light strip, Bolt/Mayor the
##   two closed arcs). At rest it is a small dark "o"; talking it opens into a circle.
##   Colour: a berry gel at H 333, the only red-violet in a cast of greens, warm browns, teals,
##   blue-lilacs and one rose-taupe (Vela, H 12 — 39 degrees away, and a completely different shape).
##
## SPIKE HONESTY: the palette gates in docs/STYLE_GUIDE.md have NOT been measured on a gameplay
## frame for this character. The swatches below are computed HSV only (every one is under S 0.60 and
## inside the V band), which is not the same thing as a measured frame.

# ---------------------------------------------------------------------------------- the palette
## The gel. H 333, S 0.372, V 0.706 — a berry jelly. Nothing else in the cast is red-violet.
const GEL := Color("#b4718f")
## The underside and the deep folds. S 0.399, V 0.541 — the dark value anchor.
const GEL_DEEP := Color("#8a536c")
## Where the light sits on top of the jelly, and the window's interior. S 0.274, V 0.773.
const GEL_LIGHT := Color("#c58fa3")
const EYE := Color("#221a26")
## The mouth slot's cavity. V 0.29 — a real dark, so the "o" reads as a hole and not a sticker.
const MOUTH := Color("#4a2436")
## The thing suspended inside: a pale star-seed. Small, so a light value is safe here.
const SEED := Color("#cbbd9c")

# ------------------------------------------------------------------------------- the body, in metres
## Lathe profile of the lower puddle (radius, y), ground to crown. The upper dome grows out of it
## from about y 0.42; below that the dome is INSIDE this surface, which is what makes the two parts
## one mass instead of a head on a body.
## (a `static var`, not a `const`: GDScript will not accept a PackedVector2Array built from
## Vector2() calls as a constant expression)
static var BODY_PROFILE := PackedVector2Array([
	Vector2(0.000, 0.000),
	Vector2(0.330, 0.000),
	Vector2(0.470, 0.030),
	Vector2(0.520, 0.100),
	Vector2(0.525, 0.190),
	Vector2(0.500, 0.280),
	Vector2(0.450, 0.360),
	Vector2(0.380, 0.430),
	Vector2(0.290, 0.490),
	Vector2(0.160, 0.540),
	Vector2(0.000, 0.570),
])
const BODY_SEGS := 26
## Shoulder seat for the two nub arms — on the body's own surface at that height, not the chibi
## SHOULDER constant (which is inside this blob).
const ARM_X := 0.395
const ARM_Y := 0.430
const NUB_LEN := 0.150
## The crown droplet's rest height, and how far it may lag the body.
const DROP_Y := 0.930
const DROP_LAG := 0.055
## Highest point at rest, for the "!" marker.
const CROWN := 1.045

var _skirt: Array[MeshInstance3D] = []
var _skirt_base: PackedFloat32Array = PackedFloat32Array()
var _drop: Node3D
var _drop_vel: Vector2 = Vector2.ZERO
var _drop_off: Vector2 = Vector2.ZERO
var _seed: Node3D
var _slot: Node3D
var _slot_w: float = 0.052
var _wobble: float = 0.0


func _init() -> void:
	super()
	# The upper dome. Wide, shallow and soft-cornered: a blob, not a skull.
	head_semi = Vector3(0.420, 0.350, 0.400)
	head_n = 2.3
	head_y = 0.580
	head_segs = Vector2i(34, 18)
	# Everything Gloop does is slow. It is the manner, and manner is free (CAST_VARIETY).
	anim_time_scale = 0.52
	# A long, lazy blink: roughly one every 6-9 s against the cast's 3-5.
	blink_hold = 1.9
	# Big simple eyes on a wide head: 0.104 m across is 12.4 % of the 0.84 m head width, and the
	# yaw below puts their centres 28.3 % apart (the mandated 28-35 % band).
	eye_w = 0.052
	eye_h = 0.062
	eye_d = 0.020
	mouth_w = 0.062
	mouth_h = 0.062
	mouth_d = 0.016


## The "!" never sits inside the droplet.
func marker_clearance() -> float:
	return CROWN * body_scale


# ==================================================================================== geometry
func _build_geometry() -> void:
	# Gloss is the slime tell, so this is one of the few genuinely shiny surfaces in the game (the
	# visor and water are the others). One tight highlight (spec_size 150) rather than a broad sheen,
	# which is what R2.6 actually objects to.
	var m_gel := _toon(GEL, {"spec": 0.34, "spec_size": 150.0, "rim": 0.12, "roughness": 0.26, "shade": 0.30,
		"shade_tint": Color(0.74, 0.71, 0.84)})
	var m_deep := _toon(GEL_DEEP, {"spec": 0.20, "spec_size": 130.0, "rim": 0.08, "roughness": 0.32, "shade": 0.30,
		"shade_tint": Color(0.74, 0.71, 0.84)})
	var m_light := _toon(GEL_LIGHT, {"spec": 0.30, "spec_size": 150.0, "rim": 0.10, "roughness": 0.28, "shade": 0.26,
		"shade_tint": Color(0.74, 0.71, 0.84)})

	# ---- the puddle. Lathed, because a teardrop TAPERS and a superellipsoid cannot (it is
	# symmetric about its own centre) — the same reason the floating robots are lathes.
	_mi(DJFloatModel.lathe(BODY_PROFILE, BODY_SEGS), m_gel, _torso, Vector3.ZERO, "Puddle")
	_build_skirt(m_deep)
	_build_window(m_deep, m_light)

	# ---- the upper dome, which carries the face. Its widest ring is OUTSIDE the puddle from about
	# y 0.42 up, so the two read as one continuous mass with a soft shoulder, never as a head.
	_mi(superellipsoid(head_semi, head_n, head_segs.x, head_segs.y), m_gel, _head, Vector3.ZERO, "Dome")
	_build_drop(m_gel, m_light)
	_build_face(m_light)
	_build_nubs(m_gel, m_deep)


## The drip skirt: soft lobes where the jelly has spread onto the ground. Uneven on purpose — a
## symmetric ring reads as a machined flange.
func _build_skirt(m_deep: Material) -> void:
	var sizes := [0.155, 0.110, 0.140, 0.095, 0.165, 0.120, 0.130]
	var angs := [0.0, 0.78, 1.62, 2.55, 3.30, 4.25, 5.35]
	for i in sizes.size():
		var r: float = sizes[i]
		var a: float = angs[i]
		var out := 0.470 + r * 0.30
		var lobe := _mi(superellipsoid(Vector3(r, r * 0.62, r * 0.88), 2.5, 9, 5), m_deep, _torso,
			Vector3(sin(a) * out, r * 0.44, -cos(a) * out), "Drip")
		_skirt.append(lobe)
		_skirt_base.append(r)


## The window, low on the front of the body, with a star-seed suspended in it. The body is OPAQUE:
## this is a rim you look INTO (a ring, a recessed pale interior, the seed standing in front of it),
## not a pane of glass. Parented to the torso, so it does not swing with the dome.
func _build_window(m_deep: Material, m_light: Material) -> void:
	# WHERE THIS SITS, AND WHY IT IS A BLISTER AND NOT A PANE. The body is a closed opaque lathe, so
	# ANYTHING placed inside it draws nothing — round 1 put the rim 14 mm inside the surface and all
	# that rendered was a dark crescent on the belly. The window is therefore a shallow cup standing
	# PROUD of the jelly: pale floor first, rim in front of it, seed in between. The lathe's own
	# radius at y 0.33 is 0.469, which is where the -0.478 comes from — not a tuned number.
	var win := _node("Window", _torso, Vector3(0.0, 0.330, -0.478))
	_mi(sphere(1.0, 14, 8), m_light, win, Vector3.ZERO, "Inner").scale = Vector3(0.132, 0.132, 0.030)
	var rim := _mi(torus(0.120, 0.164, 18, 5), m_deep, win, Vector3(0.0, 0.0, -0.022), "Rim")
	rim.rotation.x = PI * 0.5
	rim.scale = Vector3(1.0, 1.0, 0.80)
	# THE THING INSIDE. A star-seed: a small pale bead with a four-point sparkle across it, which is
	# what makes it read as a STAR and not as a pebble at 6.5 m.
	_seed = _node("StarSeed", win, Vector3(0.0, 0.0, -0.036))
	var m_seed := _toon(SEED, {"spec": 0.25, "spec_size": 150.0, "rim": 0.10, "shade": 0.22})
	_mi(sphere(1.0, 10, 6), m_seed, _seed, Vector3.ZERO, "Bead").scale = Vector3.ONE * 0.034
	for k in 2:
		var spike := _mi(rounded_box(Vector3(0.120, 0.016, 0.016), 0.007, 6), m_seed, _seed, Vector3.ZERO, "Spike")
		spike.rotation.z = PI * 0.5 * float(k)


## The crown droplet. A spring in `_animate_extras` gives it the lag that says "liquid".
func _build_drop(m_gel: Material, m_light: Material) -> void:
	_drop = _node("Droplet", _head, Vector3(0.0, DROP_Y - head_y, 0.0))
	_mi(superellipsoid(Vector3(0.088, 0.105, 0.088), 2.2, 10, 6), m_gel, _drop, Vector3.ZERO, "Bulb")
	_mi(superellipsoid(Vector3(0.040, 0.058, 0.040), 2.0, 8, 5), m_gel, _drop, Vector3(0.0, 0.098, 0.0), "Tip")
	# one small bright bead on the very top: the gloss cue that survives at distance
	_mi(sphere(1.0, 8, 5), m_light, _drop, Vector3(-0.026, 0.062, -0.040), "Gleam").scale = Vector3.ONE * 0.022


## Two nub arms growing straight out of the jelly — no sleeve, no cuff, no mitten (`_add_arms`
## builds all three and they would read as clothes on a blob).
func _build_nubs(m_gel: Material, m_deep: Material) -> void:
	_arm_l.position = Vector3(-ARM_X, ARM_Y, 0.0)
	_arm_r.position = Vector3(ARM_X, ARM_Y, 0.0)
	for side: Array in [[-1.0, _arm_l], [1.0, _arm_r]]:
		var sx: float = side[0]
		var arm: Node3D = side[1]
		_mi(superellipsoid(Vector3(0.105, 0.098, 0.100), 2.4, 10, 6), m_gel, arm, Vector3.ZERO, "Root")
		_mi(capsule(0.062, NUB_LEN, 10, 3), m_gel, arm, Vector3(0.0, -NUB_LEN * 0.48, 0.0), "Nub")
		var hand := _node("Hand", arm, Vector3(0.0, -NUB_LEN - 0.020, 0.0))
		_mi(superellipsoid(Vector3(0.070, 0.062, 0.066), 2.3, 10, 6), m_gel, hand, Vector3.ZERO, "Blob")
		# one drip under each hand, so even the arms look like they are melting a little
		_mi(superellipsoid(Vector3(0.026, 0.040, 0.026), 2.1, 7, 4), m_deep, hand, Vector3(0.012 * sx, -0.062, 0.0), "Drip")
		if sx < 0.0:
			_hand_l = hand
		else:
			_hand_r = hand


## The face: two big soft eyes and a round toothless slot. No brow, no nose, no blush, no muzzle —
## every one of those would pull Gloop toward the villager faces the rest of the cast already wears.
func _build_face(m_light: Material) -> void:
	_add_face(EYE, MOUTH, Color.TRANSPARENT, {
		"nose": false, "blush": false, "mouth": false, "brows": false,
		"eyes": [
			{"yaw": -17.0, "pitch": 8.0, "inset": 0.004},
			{"yaw": 17.0, "pitch": 8.0, "inset": 0.004},
		],
	})
	# THE ROUND SLOT. Built here rather than through `_add_mouth` (which builds the cast's smile arc
	# plus an ellipse, i.e. two of the shapes this character is specifically not allowed). Driven
	# whole in `_animate_extras`: a small dark "o" at rest, a full circle while talking.
	var mouth := _node("Mouth", _face, Vector3.ZERO)
	_orient_on_head(mouth, 0.0, -10.0, 0.004)
	_slot = _node("Slot", mouth, Vector3(0.0, 0.0, -0.004))
	var m_slot := _toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.08})
	_mi(sphere(1.0, 14, 8), m_slot, _slot, Vector3.ZERO, "Hole")
	# a thin pale lip around the slot, so the hole has an edge instead of being a smudge
	var lip := _mi(torus(0.80, 1.14, 16, 5), m_light, _slot, Vector3(0.0, 0.0, 0.10), "Lip")
	lip.rotation.x = PI * 0.5
	lip.scale = Vector3(1.0, 1.0, 0.45)
	_slot_w = mouth_w * face_scale
	_slot.scale = Vector3(_slot_w, _slot_w * 0.46, mouth_d)


# =================================================================================== animation
## A slime has no feet. Handing the base class a speed of 0 keeps the stride clock — and therefore
## the `footstep` signal, which is what plays the footstep SFX — from ever advancing.
func tick(delta: float, speed_factor: float) -> void:
	super.tick(delta, 0.0)
	_wobble = maxf(0.0, _wobble - delta * 1.6)
	if speed_factor > 0.05 and get_state() == "walk":
		_wobble = maxf(_wobble, 0.35)


## Idle: a slow squash-stretch and a lean, nothing else. The volume-preserving squash in
## `_apply_pose` does all the work.
func _pose_idle(p: PackedFloat32Array) -> void:
	var s := sin(TAU * _time * 0.36)
	p[P.SQUASH] = 1.0 + 0.052 * s
	p[P.BODY_Y] = -0.010 * s
	p[P.TORSO_ROLL] = 0.030 * sin(TAU * _time * 0.21)
	p[P.HEAD_YAW] = _look_yaw * 0.7
	p[P.HEAD_PITCH] = _look_pitch * 0.7 + 0.020 * s
	p[P.HEAD_ROLL] = 0.035 * sin(TAU * _time * 0.17)
	# the nubs drift a beat behind the mass
	var lag := sin(TAU * _time * 0.36 - 1.0)
	p[P.ARM_L_ROLL] = 0.34 + 0.07 * lag
	p[P.ARM_R_ROLL] = 0.34 + 0.07 * lag
	p[P.ARM_L_PITCH] = 0.05 * lag
	p[P.ARM_R_PITCH] = 0.05 * lag


## The scoot. No legs: Gloop pumps itself forward, squashing on the push and stretching on the
## glide, leaning into the direction of travel.
func _pose_walk(p: PackedFloat32Array) -> void:
	var ph := TAU * _time * 0.95
	p[P.SQUASH] = 1.0 - 0.085 * maxf(0.0, sin(ph))
	p[P.BODY_Y] = 0.030 * maxf(0.0, sin(ph + PI))
	p[P.TORSO_PITCH] = -0.16
	p[P.TORSO_ROLL] = 0.05 * sin(ph * 0.5)
	p[P.HEAD_PITCH] = 0.07
	p[P.ARM_L_ROLL] = 0.44
	p[P.ARM_R_ROLL] = 0.44
	p[P.ARM_L_PITCH] = -0.22 + 0.16 * sin(ph)
	p[P.ARM_R_PITCH] = -0.22 + 0.16 * sin(ph + 0.7)


## Talk: the whole body wobbles. A slime has no jaw to work, so the wobble IS the talking, and the
## slot opens and closes on top of it.
func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var w := sin(TAU * t * 1.5)
	p[P.SQUASH] += 0.046 * w
	p[P.TORSO_ROLL] += 0.055 * sin(TAU * t * 0.95)
	p[P.HEAD_ROLL] += 0.060 * w
	p[P.HEAD_PITCH] += 0.035 * sin(TAU * t * 1.15)
	p[P.MOUTH_OPEN] = 0.45 + 0.55 * maxf(0.0, sin(TAU * t * 3.4))
	p[P.ARM_R_ROLL] = 0.34 + 0.34 + 0.18 * sin(TAU * t * 1.1)
	p[P.ARM_R_PITCH] = 0.30 + 0.20 * sin(TAU * t * 1.6)


func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var w := sin(TAU * t * 2.8)
	p[P.ARM_R_ROLL] = 1.85 + 0.30 * w
	p[P.ARM_R_PITCH] = -0.10
	p[P.ARM_R_YAW] = 0.20 * w
	p[P.HEAD_ROLL] = -0.12
	p[P.SQUASH] = 1.0 + 0.030 * w
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.25


## Happy: a proper jelly bounce — stretch tall, squash flat, settle. No hop; there are no feet to
## push off with, and a blob leaving the ground reads as a balloon.
func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var b := sin(TAU * t * 1.35)
	p[P.SQUASH] = 1.0 + 0.150 * b
	p[P.BODY_Y] = 0.045 * maxf(0.0, b)
	p[P.ARM_L_ROLL] = 1.55 + 0.18 * b
	p[P.ARM_R_ROLL] = 1.55 - 0.18 * b
	p[P.ARM_L_PITCH] = 0.10
	p[P.ARM_R_PITCH] = 0.10
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.55


func _pose_think(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var u := clampf(t / 0.5, 0.0, 1.0)
	p[P.ARM_R_ROLL] = lerpf(0.34, -0.20, u)
	p[P.ARM_R_PITCH] = 1.30 * u
	p[P.HEAD_ROLL] = 0.22 * u
	p[P.HEAD_YAW] = -0.16 * u
	p[P.SQUASH] = 1.0 + 0.030 * sin(TAU * t * 0.5)
	p[P.BROW] = u
	p[P.MOUTH_OPEN] = 0.0


## Surprised: the whole blob pulls UP into a tall column and the skirt snaps in.
func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	var k := clampf(t / 0.18, 0.0, 1.0)
	var settle := clampf((t - 0.45) / 0.7, 0.0, 1.0)
	p[P.SQUASH] = 1.0 + (0.190 * k) * (1.0 - 0.6 * settle)
	p[P.BODY_Z] = 0.10 * k
	p[P.ARM_L_ROLL] = 1.10
	p[P.ARM_R_ROLL] = 1.10
	p[P.ARM_L_PITCH] = 0.30
	p[P.ARM_R_PITCH] = 0.30
	p[P.EYE_ROUND] = 1.0
	p[P.EYE_WIDE] = 1.25
	p[P.MOUTH_OPEN] = 1.0


func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	var beat := TAU * t * 1.6
	p[P.SQUASH] = 1.0 + 0.120 * sin(beat)
	p[P.TORSO_ROLL] = 0.20 * sin(beat * 0.5)
	p[P.TORSO_YAW] = 0.18 * sin(beat * 0.5)
	p[P.HEAD_ROLL] = -0.10 * sin(beat * 0.5)
	p[P.ARM_L_ROLL] = 1.40 + 0.30 * sin(beat)
	p[P.ARM_R_ROLL] = 1.40 - 0.30 * sin(beat)
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.70


# ------------------------------------------------------------------------------ the liquid parts
func _animate_extras(delta: float) -> void:
	var sq := pose(P.SQUASH)
	# THE SKIRT. The puddle spreads as the body squashes (sq < 1) and pulls in as it stretches, so
	# the lobes belong to the same body of jelly instead of being seven beads stuck on.
	var spread := clampf((1.0 - sq) * 2.4, -0.28, 0.40)
	for i in _skirt.size():
		var lobe := _skirt[i]
		lobe.scale = Vector3(1.0 + spread * 0.55, 1.0 - spread * 0.50, 1.0 + spread * 0.55)

	# THE DROPLET. A damped spring driven by the body's own motion (squash + roll), which is what
	# makes it LAG rather than follow — the cue that says liquid and not rubber.
	var drive := Vector2(-_pose[P.TORSO_ROLL] * 1.4 - _pose[P.HEAD_ROLL], (sq - 1.0) * 1.2)
	var stiff := 42.0
	var damp := 7.0
	_drop_vel += (drive - _drop_off) * stiff * delta
	_drop_vel *= exp(-damp * delta)
	_drop_off += _drop_vel * delta
	_drop_off = _drop_off.limit_length(1.0)
	if _drop:
		_drop.position.x = _drop_off.x * DROP_LAG
		_drop.position.y = (DROP_Y - head_y) + _drop_off.y * DROP_LAG * 0.7
		_drop.rotation.z = -_drop_off.x * 0.55
		# it stretches thin when the body stretches: a droplet being pulled
		_drop.scale = Vector3(1.0 - (sq - 1.0) * 0.9, 1.0 + (sq - 1.0) * 1.6, 1.0 - (sq - 1.0) * 0.9)

	# THE SUSPENDED SEED. It drifts on its own slow orbit and turns, so it never looks welded on.
	if _seed:
		var st := _time * 0.42
		_seed.position = Vector3(sin(st) * 0.030, cos(st * 0.77) * 0.026, -0.036)
		_seed.rotation = Vector3(0.0, 0.0, st * 0.55)

	# THE ROUND SLOT. Resting: a small flat "o". Talking: it opens to a full circle and a little
	# past it. Never a line, never an arc — this is the one closed-mouth kind nobody else holds.
	if _slot:
		var mo := clampf(pose(P.MOUTH_OPEN), 0.0, 1.0)
		var h := _slot_w * (0.70 + 0.85 * mo)   # 0.70 -> a round-ish "o" at rest; 0.34 rendered as a flat BAR, which is Fen's mouth kind, not this one
		var w := _slot_w * (1.0 + 0.10 * mo)
		_slot.scale = Vector3(w, h, mouth_d)
