extends DecoItem
## Control Console — a slanted mission-control desk with a scrolling screen and rows of blinking keys.

const SHELL := Color("#6f819c")
const SHELL_LIGHT := Color("#8fa3bf")
const TRIM := Color("#d9822f")
const SCREEN := Color("#1a2333")


func _init() -> void:
	footprint = 0.9
	collide_radius = 0.7
	collide_height = 1.0


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.34, 0.0), Vector3(1.36, 0.68, 0.66), 0.1, SHELL)
	kit.rbox(Vector3(0.0, 0.04, 0.0), Vector3(1.44, 0.1, 0.74), 0.04, Color("#4a4655"), Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.4, -0.34), Vector3(1.2, 0.1, 0.06), 0.03, TRIM, Basis.IDENTITY, 0)
	var slant := Basis(Vector3.RIGHT, deg_to_rad(24.0))
	kit.rbox(Vector3(0.0, 0.76, -0.06), Vector3(1.36, 0.16, 0.6), 0.07, SHELL_LIGHT, slant)
	kit.rbox(Vector3(0.0, 0.79, -0.08), Vector3(1.16, 0.06, 0.46), 0.03, SCREEN, slant, 0)
	# upright screen bezel
	var lean := Basis(Vector3.RIGHT, deg_to_rad(-12.0))
	kit.rbox(Vector3(0.0, 1.06, 0.2), Vector3(1.1, 0.5, 0.12), 0.06, SHELL_LIGHT, lean)
	kit.rbox(Vector3(0.0, 1.06, 0.13), Vector3(0.94, 0.36, 0.03), 0.02, SCREEN, lean, 0)
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.5 * s, 0.7, 0.14), Vector3(0.5 * s, 0.86, 0.2), 0.035, SHELL)
	add_body(kit.commit())

	var glow := DecoKit.new()
	# screen readout bars
	for i in 4:
		var w := 0.78 - float(i) * 0.16
		glow.rbox(Vector3(-0.06 + w * 0.5 - 0.39, 1.18 - float(i) * 0.1, 0.115), Vector3(w, 0.045, 0.02), 0.018, Color("#65c5d9") if i % 2 == 0 else Color("#65d9b2"), lean, 0)
	glow.extrude(DecoKit.round_rect_poly(0.2, 0.2, 0.06), 0.02, Color("#d9bf61"), Transform3D(lean, Vector3(0.36, 1.0, 0.115)))
	# keyboard lights
	for r in 2:
		for c in 6:
			var col: Color = [Color("#d94646"), Color("#7ed957"), Color("#d9bf61"), Color("#65c5d9"), Color("#d95d7c"), Color("#845bd9")][c]
			glow.rbox(slant * Vector3(-0.45 + float(c) * 0.18, 0.05, -0.1 + float(r) * 0.16) + Vector3(0.0, 0.76, -0.06), Vector3(0.1, 0.03, 0.08), 0.012, col, slant, 0)
	# big red button
	glow.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.085, 0.04), Vector2(0.0, 0.05)]), 12, Transform3D(slant, slant * Vector3(0.5, 0.06, 0.0) + Vector3(0.0, 0.76, -0.06)), Color("#d94646"))
	add_glow(glow.commit(), 2.3, "Lights", 2.6, 0.6, 1.0)
	add_light(Vector3(0.0, 1.1, 0.05), Color("#65c5d9"), 1.0, 3.6)
