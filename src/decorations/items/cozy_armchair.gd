extends DecoItem
## Cozy Armchair (cozy home set) - a fat dusty-rose armchair with rolled arms, a leaning back with two
## button tufts, a plump seat cushion, a mustard pillow sat crooked in the corner and a striped blanket
## thrown over one arm. Stubby wooden feet. Faces -Z.

const ROSE := Color("#cf8f86")
const ROSE_DARK := Color("#b3746d")
const ROSE_LIGHT := Color("#dba39a")
const WOOD_DARK := Color("#93775a")
const PILLOW := Color("#d9c27a")
const PILLOW_DARK := Color("#bfa55c")
const BLANKET := Color("#7fb5ad")
const BLANKET_STRIPE := Color("#e3d7bc")


func _init() -> void:
	footprint = 0.75
	collide_radius = 0.55
	collide_height = 0.95


func _build() -> void:
	var kit := DecoKit.new()
	# --- four stubby feet ----------------------------------------------------------------------------
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.cone(Vector3(0.36 * sx, 0.0, 0.3 * sz), 0.045, 0.07, 0.13, WOOD_DARK, Basis.IDENTITY, 8)
	# --- the base and the seat cushion ---------------------------------------------------------------
	kit.rbox(Vector3(0.0, 0.27, 0.0), Vector3(0.94, 0.32, 0.84), 0.12, ROSE_DARK)
	kit.rbox(Vector3(0.0, 0.46, -0.07), Vector3(0.6, 0.16, 0.62), 0.075, ROSE_LIGHT)
	# --- the back: leaning a little, with a fat top roll and two tufts --------------------------------
	var lean := Basis(Vector3.RIGHT, 0.16)
	kit.rbox(Vector3(0.0, 0.7, 0.33), Vector3(0.86, 0.78, 0.26), 0.13, ROSE, lean)
	kit.tube(Vector3(-0.36, 1.07, 0.39), Vector3(0.36, 1.07, 0.39), 0.11, ROSE_LIGHT, 10, 3)
	for sx in [-1.0, 1.0]:
		kit.sphere(Vector3(0.15 * sx, 0.8, 0.205), 0.03, ROSE_DARK, Vector3(1.0, 1.0, 0.5), 6)
	# --- arms: a slab with a roll on top -------------------------------------------------------------
	for sx in [-1.0, 1.0]:
		kit.rbox(Vector3(0.41 * sx, 0.44, -0.02), Vector3(0.2, 0.4, 0.78), 0.09, ROSE)
		kit.tube(Vector3(0.41 * sx, 0.64, -0.42), Vector3(0.41 * sx, 0.64, 0.3), 0.115, ROSE_LIGHT, 10, 3)
		kit.sphere(Vector3(0.41 * sx, 0.64, -0.425), 0.06, ROSE_DARK, Vector3(1.0, 1.0, 0.4), 8)
	# --- a pillow sat crooked in the left corner --------------------------------------------------------
	var pb := Basis(Vector3.UP, 0.5) * Basis(Vector3.RIGHT, 0.3) * Basis(Vector3.BACK, 0.35)
	kit.rbox(Vector3(-0.13, 0.68, 0.1), Vector3(0.3, 0.3, 0.13), 0.06, PILLOW, pb)
	kit.sphere(Vector3(-0.13, 0.68, 0.1) + pb * Vector3(0.0, 0.0, -0.065), 0.03, PILLOW_DARK, Vector3(1.0, 1.0, 0.5), 6, pb)
	# --- a blanket over the right arm: wrapped over the roll, hanging down the outside -----------------
	kit.tube(Vector3(0.41, 0.645, -0.28), Vector3(0.41, 0.645, 0.1), 0.135, BLANKET, 10, 2)
	kit.rbox(Vector3(0.535, 0.44, -0.09), Vector3(0.05, 0.44, 0.36), 0.022, BLANKET, Basis.IDENTITY, 0)
	for k in 3:
		var z := -0.2 + 0.11 * float(k)
		kit.torus(Vector3(0.41, 0.645, z), 0.137, 0.012, BLANKET_STRIPE, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 12, 3)
		kit.rbox(Vector3(0.563, 0.44, z), Vector3(0.012, 0.42, 0.03), 0.005, BLANKET_STRIPE, Basis.IDENTITY, 0)
	for k in 6:
		var z2 := -0.24 + 0.06 * float(k)
		kit.tube(Vector3(0.54, 0.235, z2), Vector3(0.545, 0.15, z2), 0.012, BLANKET_STRIPE, 5, 1)
	add_body(kit.commit())
