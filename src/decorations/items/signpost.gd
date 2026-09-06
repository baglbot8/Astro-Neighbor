extends DecoItem
## Wayfinder Signpost — two fat arrow boards pointing opposite ways, with a little lamp on top.
##
## SHAPE: the ACNH campsite sign is a FRAMED board — a darker border all the way round the panel,
## visible screw heads at the corners, and a post with a flared foot and a capped top. The first
## version was the same thin rod as the string-lights pole with two flat plates stuck through it. Now
## each arrow is a dark backing board with a lighter face inset inside it and four screws, the post
## has a stepped foot, a mid collar and a mounting bracket at each board, and the lamp has a hood.

const POST := Color("#cbbb8b")
const POST_DARK := Color("#a8956c")
const BOARD_A := Color("#d96143")
const BOARD_A_FACE := Color("#e8896e")
const BOARD_B := Color("#4fa79f")
const BOARD_B_FACE := Color("#7fd8d0")
const METAL := Color("#5f7089")
const SCREW := Color("#b8c4d6")


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.26
	collide_height = 1.5


func _build() -> void:
	var kit := DecoKit.new()
	# --- stepped foot ----------------------------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.32, 0.0), Vector2(0.3, 0.06),
		Vector2(0.2, 0.1), Vector2(0.19, 0.16), Vector2(0.11, 0.2), Vector2(0.0, 0.21)]),
		16, Transform3D.IDENTITY, METAL)
	kit.torus(Vector3(0.0, 0.06, 0.0), 0.3, 0.032, POST_DARK, Basis.IDENTITY, 16, 4)
	# --- post with a mid collar ------------------------------------------------------------------
	kit.cone(Vector3(0.0, 0.18, 0.0), 0.082, 0.066, 1.44, POST, Basis.IDENTITY, 12)
	kit.torus(Vector3(0.0, 0.62, 0.0), 0.09, 0.026, POST_DARK, Basis.IDENTITY, 14, 4)
	# --- lamp on top: collar, hood, housing ------------------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.11, 0.05), Vector2(0.0, 0.06)]),
		14, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.6, 0.0)), METAL)
	kit.cone(Vector3(0.0, 1.86, 0.0), 0.17, 0.04, 0.11, METAL, Basis.IDENTITY, 12)
	add_body(kit.commit())

	var boards := DecoKit.new()
	_board(boards, Transform3D(Basis(Vector3.UP, deg_to_rad(14.0)), Vector3(0.28, 1.3, 0.0)), BOARD_A, BOARD_A_FACE)
	_board(boards, Transform3D(Basis(Vector3.UP, deg_to_rad(180.0 - 22.0)), Vector3(-0.28, 0.95, 0.0)), BOARD_B, BOARD_B_FACE)
	add_body(boards.commit(), "Boards")

	var glow := DecoKit.new()
	glow.sphere(Vector3(0.0, 1.78, 0.0), 0.11, Color("#d9bf61"), Vector3(1.0, 1.2, 1.0), 10)
	for i in 3:
		glow.rbox(Vector3(0.28, 1.3, 0.06) + Vector3(0.14 + float(i) * 0.16, 0.0, 0.0), Vector3(0.11, 0.05, 0.02), 0.02, Color("#e6d99c"), Basis(Vector3.UP, deg_to_rad(14.0)), 0)
	for i in 3:
		glow.rbox(Vector3(-0.28, 0.95, -0.06) - Vector3(0.14 + float(i) * 0.16, 0.0, 0.0), Vector3(0.11, 0.05, 0.02), 0.02, Color("#e6d99c"), Basis(Vector3.UP, deg_to_rad(-22.0)), 0)
	add_glow(glow.commit(), 2.4, "Lamp", 0.8, 0.15)
	add_light(Vector3(0.0, 1.78, 0.0), Color("#d9bd79"), 1.3, 4.5)


## One framed arrow board: dark backing, lighter inset face, four screws and a mounting bracket.
func _board(kit: DecoKit, xf: Transform3D, frame: Color, face: Color) -> void:
	kit.extrude(_arrow(1.0), 0.1, frame, xf)
	kit.extrude(_arrow(0.8), 0.13, face, xf)
	for p in [Vector2(0.1, 0.09), Vector2(0.1, -0.09), Vector2(0.44, 0.09), Vector2(0.44, -0.09)]:
		kit.sphere(xf * Vector3(p.x, p.y, 0.06), 0.021, SCREW, Vector3(1.0, 1.0, 0.5), 6, xf.basis)
	kit.rbox(xf * Vector3(0.02, 0.0, 0.0), Vector3(0.09, 0.2, 0.16), 0.03, METAL, xf.basis, 0)


## Chunky right-pointing arrow board (origin at the tail). `k` shrinks it toward its own centre line
## so the same outline can be reused as the inset face inside the frame.
func _arrow(k: float) -> PackedVector2Array:
	var i := (1.0 - k) * 0.06
	return PackedVector2Array([
		Vector2(0.0 + i, -0.15 * k), Vector2(0.52 - i * 0.4, -0.15 * k), Vector2(0.52 - i * 0.4, -0.24 * k),
		Vector2(0.78 - i * 1.6, 0.0), Vector2(0.52 - i * 0.4, 0.24 * k), Vector2(0.52 - i * 0.4, 0.15 * k), Vector2(0.0 + i, 0.15 * k),
	])
