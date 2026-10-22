extends DecoItem
## Icicle Lamp (Frost Cabin set) - a navy lamp post a little taller than the astronaut, standing in a heap of
## knitted snow and wearing the set's cranberry knit band like a scarf. At the top a round navy hood with snow
## on its roof, and from its rim hangs a ring of fat icicles round one long central drip: the icicles are the
## bulbs, pale ice by day, glowing ice-blue at night.

const FC := preload("res://src/decorations/sets/set_frost_cabin.gd")
const HOOD_Y := 1.5


func _init() -> void:
	footprint = 0.4
	collide_radius = 0.24
	collide_height = 1.7


func _build() -> void:
	var kit := DecoKit.new()
	# --- a weighted navy foot buried in a heap of snow ----------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.22, 0.0), Vector2(0.21, 0.05), Vector2(0.1, 0.09), Vector2(0.0, 0.09)]),
		16, Transform3D.IDENTITY, FC.NAVY_DARK)
	FC.snow_lump(kit, Vector3(0.0, 0.03, 0.0), 0.17, Basis.IDENTITY, 0)
	# --- the post, with the scarf band and a collar under the hood ----------------------------------
	kit.cone(Vector3(0.0, 0.08, 0.0), 0.042, 0.032, HOOD_Y - 0.08, FC.NAVY, Basis.IDENTITY, 10)
	FC.knit_band(kit, Vector3(0.0, 0.62, 0.0), 0.04, 0.2, 12)
	kit.torus(Vector3(0.0, HOOD_Y - 0.04, 0.0), 0.05, 0.02, FC.NAVY_DARK, Basis.IDENTITY, 12, 4)
	# --- the hood: a shallow navy bell with a snow roof and a finial ---------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.02), Vector2(0.26, -0.02), Vector2(0.27, 0.0), Vector2(0.24, 0.05), Vector2(0.14, 0.1),
		Vector2(0.0, 0.11)]), 18, Transform3D(Basis.IDENTITY, Vector3(0.0, HOOD_Y, 0.0)), FC.NAVY)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.1), Vector2(0.15, 0.1), Vector2(0.22, 0.06), Vector2(0.255, 0.05), Vector2(0.235, 0.08),
		Vector2(0.16, 0.135), Vector2(0.06, 0.16), Vector2(0.0, 0.16)]), 18,
		Transform3D(Basis.IDENTITY, Vector3(0.0, HOOD_Y, 0.0)), FC.SNOW)
	kit.sphere(Vector3(0.0, HOOD_Y + 0.2, 0.0), 0.045, FC.SNOW, Vector3.ONE, 8)
	add_body(kit.commit())

	# --- the icicles are the light: a ring of seven round a long central one ---------------------------
	var glow := DecoKit.new()
	FC.icicle_fringe(glow, Vector3(0.0, HOOD_Y - 0.02, 0.0), 0.2, 9, 0.13, 0.3, 0.036, FC.ICE_GLOW)
	FC.icicle(glow, Vector3(0.0, HOOD_Y - 0.02, 0.0), 0.4, 0.05, FC.ICE_GLOW)
	add_glow(glow.commit(), 3.0, "Icicles", 0.6, 0.15)
	add_light(Vector3(0.0, HOOD_Y - 0.2, 0.0), Color("#a9d4ea"), 2.2, 6.0)
	add_ground_glow(1.5, Color("#9ccbe6"), 0.28)
