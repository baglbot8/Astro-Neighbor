extends DecoItem
## Beacon Tower — a stubby lighthouse for spaceships: striped mast, glass lantern room and a slow
## rotating beam that sweeps the ground.

const BEAM_SHADER := preload("res://src/decorations/light_beam.gdshader")
## Beam length in meters. Was 4.6, which crossed the whole frame from the gameplay camera.
const BEAM_LENGTH := 3.0
const SHELL := Color("#bebed3")
const BAND := Color("#e04a4a")
const METAL := Color("#5f7089")
const LIGHT_C := Color("#d9af4f")

var _head: Node3D


func _init() -> void:
	footprint = 0.75
	collide_radius = 0.46
	collide_height = 2.3


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.58, 0.0), Vector2(0.54, 0.12), Vector2(0.44, 0.2), Vector2(0.0, 0.22)]), 20, Transform3D.IDENTITY, METAL)
	kit.cone(Vector3(0.0, 0.18, 0.0), 0.36, 0.24, 1.55, SHELL, Basis.IDENTITY, 18)
	for i in 3:
		var y := 0.36 + float(i) * 0.44
		var r: float = lerpf(0.355, 0.253, (y - 0.18) / 1.55)
		kit.lathe(PackedVector2Array([Vector2(r + 0.012, 0.0), Vector2(r + 0.012, 0.18)]), 18, Transform3D(Basis.IDENTITY, Vector3(0.0, y, 0.0)), BAND, false)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.36, 0.0), Vector2(0.34, 0.08), Vector2(0.0, 0.08)]), 18, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.73, 0.0)), METAL)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		kit.bar(Vector3(cos(a) * 0.27, 1.81, sin(a) * 0.27), Vector3(cos(a) * 0.27, 2.26, sin(a) * 0.27), 0.028, METAL, 6)
	kit.cone(Vector3(0.0, 2.26, 0.0), 0.36, 0.05, 0.3, BAND, Basis.IDENTITY, 18)
	kit.sphere(Vector3(0.0, 2.62, 0.0), 0.06, Color("#d9822f"))
	add_body(kit.commit())

	_head = pivot("Head", Vector3(0.0, 2.02, 0.0))
	var glow := DecoKit.new()
	glow.sphere(Vector3.ZERO, 0.17, LIGHT_C, Vector3(1.0, 1.1, 1.0), 14)
	# The snout used to be near-white (#fff2c8), which read as a hue-free blob stuck on the front of
	# an otherwise golden lamp. It is the same amber family as the bulb now, just a shade brighter.
	glow.cone(Vector3(0.0, -0.02, -0.14), 0.13, 0.02, 0.3, Color("#d9ba6f"), Basis(Vector3.RIGHT, deg_to_rad(-90.0)), 10)
	add_glow(glow.commit(), 3.4, "Lantern", 0.0, 0.0, 0.0, _head)

	# Sweeping beam: an OPEN cone shell (a two-point lathe profile, so there are no end caps) whose
	# alpha falls to zero along its length and across its width in light_beam.gdshader. The old
	# version was a capped 4.6 m cone at a constant alpha 0.2 with cull_disabled — an opaque slab
	# that crossed the frame, stopped in a blunt straight edge and drew over the sky and the HUD.
	var beam := DecoKit.new()
	beam.lathe(PackedVector2Array([Vector2(0.11, 0.0), Vector2(0.5, BEAM_LENGTH)]), 14,
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-98.0)), Vector3(0.0, 0.0, -0.16)), Color.WHITE, false)
	var mi := MeshInstance3D.new()
	mi.name = "Beam"
	mi.mesh = beam.commit()
	var beam_mat := ShaderMaterial.new()
	beam_mat.shader = BEAM_SHADER
	beam_mat.set_shader_parameter("beam_color", Color(1.0, 0.86, 0.55))
	beam_mat.set_shader_parameter("peak_alpha", 0.07)
	mi.material_override = beam_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_head.add_child(mi)

	# Warm, very light glass: the old cool #cfe4ff pane at alpha 0.16 sat right over the amber bulb
	# and pulled its measured saturation down on its own.
	add_glass(_lantern_glass(), Color("#d9c093"), 0.1, "LanternGlass")
	add_light(Vector3(0.0, 2.02, 0.0), Color("#d9af70"), 2.2, 7.5)
	animate()


func _lantern_glass() -> ArrayMesh:
	var g := DecoKit.new()
	g.lathe(PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.32, 0.2), Vector2(0.3, 0.42)]), 16, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.81, 0.0)), Color.WHITE)
	return g.commit()


func _animate(t: float, _delta: float) -> void:
	_head.rotation.y = t * 0.85
