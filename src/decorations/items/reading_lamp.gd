extends DecoItem
## Reading Lamp (cozy home set) - a brass floor lamp under a big cream fabric shade with rose trim and a
## pull chain, and a little round tray halfway up the pole holding a stack of books and a mug. The shade
## glows warm at night and throws a pool of reading light.

const BASE := Color("#6f6a80")
const BRASS := Color("#c9ad6a")
const BRASS_DARK := Color("#a88d52")
const SHADE := Color("#e6d6a8")
const TRIM := Color("#cf8f86")
const WOOD := Color("#b89a74")
const WOOD_DARK := Color("#93775a")
const BOOK_A := Color("#7fb5ad")
const BOOK_B := Color("#c9805e")
const PAGES := Color("#e6dcc6")
const MUG := Color("#a595cf")
const SHADE_Y := 1.34
const SHADE_H := 0.36
const TRAY := Vector3(0.24, 0.66, -0.04)


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.3
	collide_height = 1.7


func _build() -> void:
	var kit := DecoKit.new()
	# --- a weighted foot --------------------------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.27, 0.0), Vector2(0.26, 0.05), Vector2(0.15, 0.085), Vector2(0.06, 0.1),
		Vector2(0.05, 0.16), Vector2(0.0, 0.16)]), 18, Transform3D.IDENTITY, BASE)
	kit.torus(Vector3(0.0, 0.05, 0.0), 0.255, 0.026, BRASS_DARK, Basis.IDENTITY, 18, 4)
	# --- the pole, with collars ---------------------------------------------------------------------
	kit.cone(Vector3(0.0, 0.14, 0.0), 0.036, 0.028, SHADE_Y, BRASS, Basis.IDENTITY, 10)
	kit.torus(Vector3(0.0, 0.3, 0.0), 0.04, 0.02, BRASS_DARK, Basis.IDENTITY, 12, 4)
	kit.torus(Vector3(0.0, 1.18, 0.0), 0.034, 0.018, BRASS_DARK, Basis.IDENTITY, 12, 4)
	# --- the tray: a bracket, a dished wooden disc, two books and a mug ---------------------------------
	kit.tube(Vector3(0.0, TRAY.y - 0.1, 0.0), Vector3(TRAY.x, TRAY.y - 0.02, TRAY.z), 0.02, BRASS_DARK, 6, 1)
	kit.torus(Vector3(0.0, TRAY.y - 0.1, 0.0), 0.036, 0.018, BRASS_DARK, Basis.IDENTITY, 12, 4)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.03), Vector2(0.19, -0.03), Vector2(0.23, -0.005), Vector2(0.23, 0.02), Vector2(0.2, 0.02),
		Vector2(0.2, 0.0), Vector2(0.0, 0.0)]), 18, Transform3D(Basis.IDENTITY, TRAY), WOOD)
	var bk := Basis(Vector3.UP, 0.35)
	kit.rbox(TRAY + Vector3(-0.02, 0.03, 0.04), Vector3(0.2, 0.05, 0.15), 0.012, BOOK_A, bk, 0)
	kit.rbox(TRAY + Vector3(-0.012, 0.03, 0.036), Vector3(0.19, 0.034, 0.14), 0.008, PAGES, bk, 0)
	var bk2 := Basis(Vector3.UP, -0.2)
	kit.rbox(TRAY + Vector3(-0.02, 0.077, 0.04), Vector3(0.17, 0.04, 0.13), 0.012, BOOK_B, bk2, 0)
	kit.rbox(TRAY + Vector3(-0.014, 0.077, 0.037), Vector3(0.162, 0.026, 0.12), 0.008, PAGES, bk2, 0)
	var mug := TRAY + Vector3(0.07, 0.0, -0.1)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.042, 0.0), Vector2(0.046, 0.085), Vector2(0.036, 0.085), Vector2(0.036, 0.07),
		Vector2(0.0, 0.07)]), 12, Transform3D(Basis.IDENTITY, mug), MUG)
	kit.torus(mug + Vector3(0.055, 0.045, 0.0), 0.022, 0.008, MUG, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 8, 3)
	# --- shade fittings: the spider under the shade, the trims, a finial, the pull chain ---------------
	kit.torus(Vector3(0.0, SHADE_Y, 0.0), 0.325, 0.02, TRIM, Basis.IDENTITY, 22, 4)
	kit.torus(Vector3(0.0, SHADE_Y + SHADE_H, 0.0), 0.185, 0.016, TRIM, Basis.IDENTITY, 18, 4)
	kit.sphere(Vector3(0.0, SHADE_Y + SHADE_H + 0.05, 0.0), 0.04, BRASS, Vector3.ONE, 8)
	kit.bar(Vector3(0.0, SHADE_Y + SHADE_H - 0.02, 0.0), Vector3(0.0, SHADE_Y + SHADE_H + 0.04, 0.0), 0.014, BRASS_DARK, 6)
	kit.bar(Vector3(-0.12, SHADE_Y + 0.02, -0.1), Vector3(-0.12, SHADE_Y - 0.2, -0.1), 0.006, BRASS_DARK, 6)
	kit.sphere(Vector3(-0.12, SHADE_Y - 0.22, -0.1), 0.026, TRIM, Vector3.ONE, 6)
	add_body(kit.commit())

	# --- the shade itself glows: outside wall, inside wall, and the bulb under it ----------------------
	var glow := DecoKit.new()
	glow.lathe(PackedVector2Array([
		Vector2(0.32, 0.0), Vector2(0.18, SHADE_H), Vector2(0.16, SHADE_H), Vector2(0.3, 0.0)]),
		22, Transform3D(Basis.IDENTITY, Vector3(0.0, SHADE_Y, 0.0)), SHADE, true, true)
	glow.sphere(Vector3(0.0, SHADE_Y + 0.12, 0.0), 0.075, Color("#ead9a0"), Vector3(1.0, 1.2, 1.0), 10)
	add_glow(glow.commit(), 2.0, "Shade", 0.0, 0.0)
	add_light(Vector3(0.0, SHADE_Y - 0.05, 0.0), Color("#e0c487"), 2.2, 6.0)
	add_ground_glow(1.5, Color("#e0c487"), 0.26)
