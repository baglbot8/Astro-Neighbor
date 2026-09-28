class_name Telescope
extends Node3D
## SPIKE ROUND 2 (2026-09-20, scratch only). The thing you plant on the ground. Deliberately PLAIN -
## the brief says models may be rough, the sky may not. Procedural like everything else: three legs,
## a tube, a hood and an eyepiece, all primitive meshes in the Moonstone palette.
##
## ROUND 2 ADDS THE SWING. Round 1 planted the scope once, facing the forecast, and never moved it:
## the whole hunt happened in a 2D overlay while the physical scope stared at one spot. Now
## `swing(az, elev)` turns the real tube every frame the player drags, so the thing on the ground and
## the thing in the eyepiece are the same thing. `eye_point()` and `tube_forward()` let SkyWatch put
## the camera behind the eyepiece instead of blanking the world.

const BODY := Color("#e2e5ef")
const TRIM := Color("#2b3049")
const BAND := Color("#ef7f52")
const GLASS := Color("#6fa8d8")

var _yoke: Node3D
var _tube: Node3D
var _eye_node: Node3D

# Where it was planted, kept so `swing()` can re-aim without another raycast.
var _pos := Vector3.ZERO
var _up := Vector3.UP
var _east := Vector3.RIGHT
var _az := 90.0
var _elev := 25.0


func _ready() -> void:
	_build()


func _build() -> void:
	var legs := Node3D.new()
	legs.name = "Legs"
	add_child(legs)
	for i in 3:
		var leg := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.022
		cyl.bottom_radius = 0.030
		cyl.height = 0.86
		cyl.radial_segments = 8
		cyl.material = _mat(TRIM, 0.45)
		leg.mesh = cyl
		var a := TAU * float(i) / 3.0
		var lean := Vector3(sin(a), 0.0, cos(a)) * 0.20
		leg.position = Vector3(0.0, 0.43, 0.0) + lean
		leg.rotation = Vector3(cos(a) * 0.30, 0.0, -sin(a) * 0.30)
		legs.add_child(leg)

	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.075
	hs.height = 0.13
	hs.radial_segments = 14
	hs.rings = 7
	hs.material = _mat(TRIM, 0.35)
	head.mesh = hs
	head.position = Vector3(0.0, 0.88, 0.0)
	add_child(head)

	_yoke = Node3D.new()
	_yoke.name = "Yoke"
	_yoke.position = Vector3(0.0, 0.90, 0.0)
	add_child(_yoke)

	_tube = Node3D.new()
	_tube.name = "Tube"
	_yoke.add_child(_tube)

	# Tube: a cylinder lying along -Z (CylinderMesh is +Y, so the MeshInstance is pitched 90 deg).
	var body := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.105
	bc.bottom_radius = 0.105
	bc.height = 0.86
	bc.radial_segments = 18
	var tmat := _mat(BODY, 0.30)
	tmat.emission_enabled = true
	tmat.emission = BODY
	tmat.emission_energy_multiplier = 0.10
	bc.material = tmat
	body.mesh = bc
	body.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	body.position = Vector3(0.0, 0.0, -0.10)
	_tube.add_child(body)

	var band := MeshInstance3D.new()
	var bn := CylinderMesh.new()
	bn.top_radius = 0.114
	bn.bottom_radius = 0.114
	bn.height = 0.07
	bn.radial_segments = 18
	var bmat := _mat(BAND, 0.35)
	# AT NIGHT THE WHOLE SCOPE IS A SILHOUETTE. A faint warm glow on the band and the eye cup is
	# what makes it read as a telescope from the eyepiece camera, and it is the one warm thing in
	# the Moonstone night, so it also says "this is yours".
	bmat.emission_enabled = true
	bmat.emission = BAND
	bmat.emission_energy_multiplier = 0.55
	bn.material = bmat
	band.mesh = bn
	band.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	band.position = Vector3(0.0, 0.0, -0.10)
	_tube.add_child(band)

	# Hood at the sky end, with a dark glass cap so it reads as an opening.
	var hood := MeshInstance3D.new()
	var hd := CylinderMesh.new()
	hd.top_radius = 0.128
	hd.bottom_radius = 0.112
	hd.height = 0.16
	hd.radial_segments = 18
	hd.material = _mat(TRIM, 0.30)
	hood.mesh = hd
	hood.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	hood.position = Vector3(0.0, 0.0, -0.58)
	_tube.add_child(hood)

	var glass := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 0.100
	gm.bottom_radius = 0.100
	gm.height = 0.02
	gm.radial_segments = 18
	var gmat := _mat(GLASS, 0.06)
	gmat.emission_enabled = true
	gmat.emission = GLASS
	gmat.emission_energy_multiplier = 0.45
	gm.material = gmat
	glass.mesh = gm
	glass.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	glass.position = Vector3(0.0, 0.0, -0.64)
	_tube.add_child(glass)

	# Eyepiece sticking out of the near end, and a little finder scope on top.
	_eye_node = Node3D.new()
	_eye_node.name = "EyeMount"
	_eye_node.position = Vector3(0.0, 0.12, 0.42)
	_tube.add_child(_eye_node)

	var eye := MeshInstance3D.new()
	var ec := CylinderMesh.new()
	ec.top_radius = 0.040
	ec.bottom_radius = 0.050
	ec.height = 0.17
	ec.radial_segments = 12
	ec.material = _mat(TRIM, 0.30)
	eye.mesh = ec
	eye.rotation_degrees = Vector3(-55.0, 0.0, 0.0)
	eye.position = Vector3(0.0, -0.06, -0.08)
	_eye_node.add_child(eye)

	# A cream cup on the end of the eyepiece: without it the near end is a dark stub against a dark
	# sky, and the camera parked behind it has nothing that reads as "your eye goes here".
	var cup := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.064
	cc.bottom_radius = 0.042
	cc.height = 0.05
	cc.radial_segments = 14
	var cmat := _mat(BODY, 0.42)
	cmat.emission_enabled = true
	cmat.emission = BODY
	cmat.emission_energy_multiplier = 0.22
	cc.material = cmat
	cup.mesh = cc
	cup.rotation_degrees = Vector3(-55.0, 0.0, 0.0)
	cup.position = Vector3(0.0, 0.0, 0.0)
	_eye_node.add_child(cup)

	var finder := MeshInstance3D.new()
	var fc := CylinderMesh.new()
	fc.top_radius = 0.028
	fc.bottom_radius = 0.028
	fc.height = 0.30
	fc.radial_segments = 10
	fc.material = _mat(BODY, 0.28)
	finder.mesh = fc
	finder.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	finder.position = Vector3(0.0, 0.135, -0.12)
	_tube.add_child(finder)

	aim_local(45.0)


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


## Points the tube at `elev_deg` above local horizontal, keeping the current yaw.
func aim_local(elev_deg: float) -> void:
	if _tube != null:
		_tube.rotation_degrees = Vector3(clampf(elev_deg, 0.0, 85.0), 0.0, 0.0)


## Plants the scope on the sphere at `pos` with `up` as the local normal, and swings it toward the
## forecast's azimuth (degrees from local east toward north) and elevation.
func plant(pos: Vector3, up: Vector3, east: Vector3, az_deg: float, elev_deg: float) -> void:
	var e := (east - up * up.dot(east))
	if e.length_squared() < 0.0001:
		e = Vector3.RIGHT - up * up.dot(Vector3.RIGHT)
	_pos = pos
	_up = up.normalized()
	_east = e.normalized()
	swing(az_deg, elev_deg)


## Re-aims the planted scope. Cheap enough to call every frame: one Basis.looking_at, one local
## rotation, no raycast and no allocation. The scale is re-applied after the global_transform write,
## because global_transform takes an orthonormal basis and drops any scale that was on the node.
func swing(az_deg: float, elev_deg: float) -> void:
	_az = az_deg
	_elev = clampf(elev_deg, 2.0, 82.0)
	var north := _up.cross(_east).normalized()
	var face := (_east * cos(deg_to_rad(_az)) + north * sin(deg_to_rad(_az))).normalized()
	# Basis.looking_at, not a hand-built Basis: -Z has to face `face` AND the basis has to stay
	# right-handed, or the whole model is mirrored.
	var s := scale
	global_transform = Transform3D(Basis.looking_at(face, _up), _pos)
	scale = s
	aim_local(_elev)


func aim_az() -> float:
	return _az


func aim_elev() -> float:
	return _elev


## Global position of the eye cup. SkyWatch parks the watch camera just behind this.
func eye_point() -> Vector3:
	if _eye_node == null:
		return global_position + _up * 1.1
	return _eye_node.global_position


## Global unit vector the tube points along, toward the sky (the hood end).
func tube_forward() -> Vector3:
	if _tube == null:
		return _up
	return -_tube.global_transform.basis.z.normalized()


func local_up() -> Vector3:
	return _up
