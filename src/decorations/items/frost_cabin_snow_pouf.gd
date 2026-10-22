extends DecoItem
## Snowball Pouf (Frost Cabin set) - a knee-high knitted snowball to sit on: a soft squashed ball of white
## yarn wearing the set's cranberry knit band round its middle, a little fringe of ice drips under the band,
## a navy button base so it does not roll away, and a white pom-pom on top.

const FC := preload("res://src/decorations/sets/set_frost_cabin.gd")
const R := 0.3
const CY := 0.22


func _init() -> void:
	footprint = 0.45
	collide_radius = 0.3
	collide_height = 0.44


func _build() -> void:
	var kit := DecoKit.new()
	# a low navy foot ring the ball sits in
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.215, 0.025), Vector2(0.19, 0.05), Vector2(0.0, 0.05)]),
		16, Transform3D.IDENTITY, FC.NAVY)
	# the snowball: a soft squashed sphere, slightly shaded underneath so it reads round, not flat
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.02), Vector2(0.17, 0.035), Vector2(0.26, 0.09), Vector2(R, CY - 0.02),
		Vector2(R - 0.005, CY + 0.06), Vector2(0.27, CY + 0.13), Vector2(0.2, CY + 0.19),
		Vector2(0.1, CY + 0.215), Vector2(0.0, CY + 0.22)]), 20, Transform3D.IDENTITY, FC.SNOW)
	# the set's knit band round the middle, and its ice fringe just below
	FC.knit_band(kit, Vector3(0.0, CY - 0.055, 0.0), R - 0.004, 0.11, 20)
	FC.icicle_fringe(kit, Vector3(0.0, CY - 0.05, 0.0), R + 0.012, 8, 0.04, 0.085, 0.018, FC.ICE)
	# a pom-pom on top, and a sunken knitted dimple where it is sewn on
	kit.sphere(Vector3(0.0, CY + 0.25, 0.0), 0.065, FC.SNOW, Vector3(1.0, 0.85, 1.0), 10)
	kit.torus(Vector3(0.0, CY + 0.214, 0.0), 0.06, 0.014, FC.SNOW_SHADE, Basis.IDENTITY, 12, 3)
	add_body(kit.commit())
