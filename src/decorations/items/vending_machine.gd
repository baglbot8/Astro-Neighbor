extends DecoItem
## Robot Vending Machine — a cheerful red snack bot with a lit shelf of space treats and a pixel face.

const SHELL := Color("#d94646")
const SHELL_DARK := Color("#d13c3c")
const PANEL := Color("#cfcfdf")
const METAL := Color("#8fa3bf")
const SCREEN := Color("#1a2333")
const TREATS := [Color("#d9bf61"), Color("#65c5d9"), Color("#7ed957"), Color("#d95d7c"), Color("#845bd9"), Color("#d9822f")]


func _init() -> void:
	footprint = 0.75
	collide_radius = 0.55
	collide_height = 1.85


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.9, 0.0), Vector3(1.0, 1.72, 0.66), 0.12, SHELL)
	kit.rbox(Vector3(0.0, 0.06, 0.0), Vector3(1.08, 0.14, 0.74), 0.05, Color("#4a4655"), Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 1.03, -0.16), Vector3(0.74, 0.9, 0.1), 0.05, SCREEN)
	for e in [Vector3(0.0, 1.51, -0.3), Vector3(0.0, 0.55, -0.3)]:
		kit.rbox(e, Vector3(0.86, 0.07, 0.1), 0.03, PANEL, Basis.IDENTITY, 0)
	for s0 in [-1.0, 1.0]:
		kit.rbox(Vector3(0.4 * s0, 1.03, -0.3), Vector3(0.08, 1.02, 0.1), 0.03, PANEL, Basis.IDENTITY, 0)
	# dispensing tray
	kit.rbox(Vector3(0.0, 0.34, -0.3), Vector3(0.6, 0.24, 0.14), 0.05, SHELL_DARK)
	kit.rbox(Vector3(0.0, 0.33, -0.37), Vector3(0.5, 0.16, 0.04), 0.02, Color("#2a2f45"), Basis.IDENTITY, 0)
	# side pipes
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.52 * s, 0.4, 0.2), Vector3(0.52 * s, 1.5, 0.2), 0.05, METAL)
	# head
	kit.rbox(Vector3(0.0, 1.94, 0.0), Vector3(0.78, 0.44, 0.56), 0.13, SHELL_DARK)
	kit.rbox(Vector3(0.0, 1.94, -0.27), Vector3(0.56, 0.3, 0.06), 0.06, SCREEN, Basis.IDENTITY, 0)
	for s2 in [-1.0, 1.0]:
		kit.tube(Vector3(0.3 * s2, 2.14, 0.0), Vector3(0.38 * s2, 2.34, 0.0), 0.022, METAL)
		kit.sphere(Vector3(0.4 * s2, 2.38, 0.0), 0.055, Color("#d9822f"))
	add_body(kit.commit())

	add_glass(_window_glass(), Color("#a0bee6"), 0.22, "Window")

	var glow := DecoKit.new()
	# shelf of treats behind the glass
	for r in 3:
		for c in 2:
			var col: Color = TREATS[(r * 2 + c) % TREATS.size()]
			glow.rbox(Vector3(-0.16 + float(c) * 0.32, 0.72 + float(r) * 0.29, -0.26), Vector3(0.18, 0.2, 0.12), 0.05, col, Basis.IDENTITY, 0)
	# pixel face
	for s3 in [-1.0, 1.0]:
		glow.rbox(Vector3(0.13 * s3, 1.98, -0.3), Vector3(0.09, 0.13, 0.03), 0.02, Color("#65c5d9"), Basis.IDENTITY, 0)
	glow.rbox(Vector3(0.0, 1.86, -0.3), Vector3(0.22, 0.05, 0.03), 0.02, Color("#65c5d9"), Basis.IDENTITY, 0)
	# tray light
	glow.rbox(Vector3(0.0, 0.33, -0.375), Vector3(0.44, 0.03, 0.02), 0.01, Color("#d9bf61"), Basis.IDENTITY, 0)
	add_glow(glow.commit(), 2.2, "Lights", 1.6, 0.25)
	add_light(Vector3(0.0, 1.1, -0.5), Color("#d9af70"), 1.2, 4.0)


func _window_glass() -> ArrayMesh:
	var g := DecoKit.new()
	g.rbox(Vector3(0.0, 1.03, -0.345), Vector3(0.7, 0.88, 0.03), 0.02, Color.WHITE, Basis.IDENTITY, 0)
	return g.commit()
