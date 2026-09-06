extends DecoItem
## Crystal Cluster Lamp — a moon-rock clump sprouting fat violet crystals that breathe with light.

const ROCK := Color("#8fa3bf")
const ROCK_DARK := Color("#6f819c")
const C1 := Color("#845bd9")
const C2 := Color("#65c5d9")
const C3 := Color("#d95d7c")


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.4
	collide_height = 0.9


func _build() -> void:
	var kit := DecoKit.new()
	kit.sphere(Vector3(0.0, 0.1, 0.0), 0.4, ROCK, Vector3(1.0, 0.55, 0.95))
	kit.sphere(Vector3(0.24, 0.08, 0.16), 0.24, ROCK_DARK, Vector3(1.0, 0.6, 1.0))
	kit.sphere(Vector3(-0.26, 0.07, -0.14), 0.2, ROCK_DARK, Vector3(1.0, 0.62, 1.0))
	add_body(kit.commit())

	var glow := DecoKit.new()
	var specs := [
		[Vector3(0.0, 0.18, 0.0), 0.16, 0.66, 0.0, 0.0, C1],
		[Vector3(0.24, 0.16, 0.1), 0.11, 0.44, 0.32, 0.7, C2],
		[Vector3(-0.22, 0.14, 0.14), 0.1, 0.38, 0.3, 3.4, C3],
		[Vector3(0.06, 0.15, -0.26), 0.09, 0.32, 0.34, 4.7, C2],
	]
	for s in specs:
		var basis := DecoKit.tilt_basis(s[3], s[4])
		glow.cone(s[0], s[1], s[1] * 0.18, s[2], s[5], basis, 7)
		glow.cone(s[0] + basis * Vector3(0.0, s[2], 0.0), s[1] * 0.18, 0.0, s[1] * 0.7, s[5], basis, 7)
	add_glow(glow.commit(), 2.4, "Crystals", 1.1, 0.3)

	add_light(Vector3(0.0, 0.7, 0.0), Color("#9d79d9"), 1.7, 5.5)
	add_ground_glow(1.2, Color("#845bd9"), 0.24)
