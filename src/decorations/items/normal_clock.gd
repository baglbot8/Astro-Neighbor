extends DecoItem
## Time Circle Tower (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a tall
## wooden pendulum clock. Norm wound it himself, so both hands hurry round the wrong way.

const WOOD := Color("#967c6a")
const WOOD_DARK := Color("#7a6458")
const WOOD_LIGHT := Color("#bea78a")
const RECESS := Color("#332e3a")
const BRASS := Color("#cdbb8c")
const FACE := Color("#e6dcc0")
const INK := Color("#3a3550")
const FACE_AT := Vector3(0.0, 1.74, -0.225)
const SWING_AT := Vector3(0.0, 1.2, -0.2)
## Seconds per backward turn of each hand.
const MINUTE_TURN_SEC := 6.0
const HOUR_TURN_SEC := 40.0

var _minute: Node3D
var _hour: Node3D
var _swing: Node3D


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.38
	collide_height = 2.1


func _build() -> void:
	var kit := DecoKit.new()
	# --- case: plinth, trunk with a pendulum window, head, cornice ------------------------------
	kit.rbox(Vector3(0.0, 0.1, 0.0), Vector3(0.66, 0.2, 0.46), 0.05, WOOD_DARK)
	kit.rbox(Vector3(0.0, 0.8, 0.0), Vector3(0.48, 1.26, 0.34), 0.06, WOOD)
	kit.rbox(Vector3(0.0, 0.8, -0.16), Vector3(0.38, 0.92, 0.04), 0.04, WOOD_LIGHT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.8, -0.168), Vector3(0.31, 0.84, 0.04), 0.03, RECESS, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 1.36, 0.0), Vector3(0.6, 0.08, 0.42), 0.03, WOOD_DARK, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 1.74, 0.0), Vector3(0.72, 0.72, 0.42), 0.1, WOOD)
	kit.rbox(Vector3(0.0, 2.12, 0.0), Vector3(0.82, 0.1, 0.5), 0.04, WOOD_DARK)
	kit.rbox(Vector3(0.0, 2.2, 0.0), Vector3(0.5, 0.1, 0.36), 0.04, WOOD)
	kit.sphere(Vector3(0.0, 2.3, 0.0), 0.07, BRASS, Vector3.ONE, 8)
	# brass ring round the face, and twelve tick marks on it
	kit.torus(FACE_AT + Vector3(0.0, 0.0, 0.01), 0.275, 0.032, BRASS, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 18, 4)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var big := i % 3 == 0
		var r0 := 0.17 if big else 0.2
		var hw := 0.016 if big else 0.01
		var dir := Vector3(sin(a), cos(a), 0.0)
		var side := Vector3(cos(a), -sin(a), 0.0) * hw
		var z := Vector3(0.0, 0.0, -0.014)
		kit.quad(FACE_AT + dir * r0 - side + z, FACE_AT + dir * 0.235 - side + z, FACE_AT + dir * 0.235 + side + z, FACE_AT + dir * r0 + side + z, INK, true)
	add_body(kit.commit())

	# the face is softly lit after dark
	var face := DecoKit.new()
	face.disc(FACE_AT + Vector3(0.0, 0.0, -0.008), 0.26, FACE, Basis(Vector3.RIGHT, deg_to_rad(-90.0)), 18)
	add_glow(face.commit(), 1.5, "Face")

	_hour = pivot("Hour", FACE_AT + Vector3(0.0, 0.0, -0.024))
	_minute = pivot("Minute", FACE_AT + Vector3(0.0, 0.0, -0.036))
	var hk := DecoKit.new()
	hk.rbox(Vector3(0.0, 0.055, 0.0), Vector3(0.05, 0.17, 0.012), 0.006, INK, Basis.IDENTITY, 0)
	add_body(hk.commit(), "HourHand", _hour)
	var mk := DecoKit.new()
	mk.rbox(Vector3(0.0, 0.085, 0.0), Vector3(0.034, 0.23, 0.012), 0.006, INK, Basis.IDENTITY, 0)
	mk.sphere(Vector3.ZERO, 0.03, BRASS, Vector3(1.0, 1.0, 0.5), 8)
	add_body(mk.commit(), "MinuteHand", _minute)
	_hour.rotation.z = -2.2

	_swing = pivot("Pendulum", SWING_AT)
	var pk := DecoKit.new()
	pk.rbox(Vector3(0.0, -0.3, 0.0), Vector3(0.022, 0.6, 0.014), 0.006, BRASS, Basis.IDENTITY, 0)
	pk.sphere(Vector3(0.0, -0.62, 0.0), 0.065, BRASS, Vector3(1.0, 1.0, 0.3), 10)
	add_body(pk.commit(), "Bob", _swing)
	animate()


## Seen from the front (the reader stands at -Z), a NEGATIVE turn about Z runs anticlockwise.
func _animate(t: float, _delta: float) -> void:
	_minute.rotation.z = -t * TAU / MINUTE_TURN_SEC
	_hour.rotation.z = -2.2 - t * TAU / HOUR_TURN_SEC
	_swing.rotation.z = sin(t * 2.4) * 0.13
