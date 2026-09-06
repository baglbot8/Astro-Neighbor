extends DecoItem
## Holo Sign — a projector plinth throwing up a floating cyan billboard with scrolling text bars.

const BASE := Color("#6f819c")
const BASE_LIGHT := Color("#8fa3bf")
const TRIM := Color("#d9822f")
const HOLO := Color("#65c5d9")

var _panel: Node3D


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.4
	collide_height = 0.75


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.16, 0.0), Vector3(0.96, 0.32, 0.5), 0.1, BASE)
	kit.rbox(Vector3(0.0, 0.34, 0.0), Vector3(0.7, 0.1, 0.34), 0.04, BASE_LIGHT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.04, 0.0), Vector3(1.04, 0.08, 0.58), 0.03, Color("#4a4655"), Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.38 * s, 0.3, 0.0), Vector3(0.42 * s, 0.66, 0.0), 0.035, BASE_LIGHT)
		kit.sphere(Vector3(0.42 * s, 0.68, 0.0), 0.055, TRIM)
	kit.rbox(Vector3(0.0, 0.24, -0.26), Vector3(0.4, 0.06, 0.04), 0.02, TRIM, Basis.IDENTITY, 0)
	add_body(kit.commit())

	_panel = pivot("Panel", Vector3(0.0, 1.18, 0.0))
	var glow := DecoKit.new()
	glow.extrude(DecoKit.round_rect_poly(1.28, 0.78, 0.14, 5), 0.035, HOLO, Transform3D.IDENTITY)
	glow.extrude(DecoKit.round_rect_poly(1.12, 0.62, 0.1, 5), 0.05, Color("#1a2333"), Transform3D.IDENTITY)
	for i in 3:
		var w := 0.86 - float(i) * 0.2
		glow.extrude(DecoKit.round_rect_poly(w, 0.09, 0.04), 0.07, Color("#a0bee6"), Transform3D(Basis.IDENTITY, Vector3(-0.44 + w * 0.5, 0.17 - float(i) * 0.17, 0.0)))
	glow.extrude(DecoKit.star_poly(0.11, 0.05, 5), 0.07, Color("#d9bf61"), Transform3D(Basis.IDENTITY, Vector3(0.48, 0.0, 0.0)))
	add_glow(glow.commit(), 2.6, "Holo", 3.4, 0.16, 0.0, _panel)

	# projector cone from the plinth up to the panel
	var beam := DecoKit.new()
	beam.cone(Vector3(0.0, 0.4, 0.0), 0.1, 0.62, 0.42, HOLO, Basis.IDENTITY, 14)
	var mi := add_glow(beam.commit(), 1.2, "Beam", 2.0, 0.4)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_light(Vector3(0.0, 1.1, 0.0), Color("#5db2d9"), 1.5, 5.0)
	add_ground_glow(1.2, Color("#65c5d9"), 0.22)
	animate()


func _animate(t: float, _delta: float) -> void:
	_panel.position.y = 1.18 + sin(t * 1.1) * 0.03
	_panel.rotation.y = sin(t * 0.5) * 0.09
