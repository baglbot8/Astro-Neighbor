extends DecoItem
## Silver Human Award — Norm's second quiz reward (NORM_SPEC.md §6). Same goblet-on-plinth shape as
## the bronze trophy, a size step taller and re-coloured silver, so the ladder reads clearly next to
## the other two without needing a different silhouette.

const CUP := Color("#c7ced9")      ## S 0.083 V 0.851 - a cool near-white, distinct from both metals
const CUP_DARK := Color("#a3aebd") ## S 0.138 V 0.741
const PLINTH := Color("#c7b98d")   ## same plinth family as bronze/gold — only the cup changes tier
const PLINTH_DARK := Color("#b3a578")


func _init() -> void:
	footprint = 0.42
	collide_radius = 0.3
	collide_height = 0.58


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.055, 0.0), Vector3(0.44, 0.11, 0.44), 0.045, PLINTH_DARK)
	kit.rbox(Vector3(0.0, 0.145, 0.0), Vector3(0.32, 0.07, 0.32), 0.03, PLINTH)
	kit.cone(Vector3(0.0, 0.18, 0.0), 0.05, 0.032, 0.13, CUP_DARK)
	kit.sphere(Vector3(0.0, 0.32, 0.0), 0.05, CUP_DARK, Vector3.ONE, 10)
	var prof := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.085, 0.012), Vector2(0.115, 0.1),
		Vector2(0.105, 0.19), Vector2(0.07, 0.225),
	])
	kit.lathe(prof, 18, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.32, 0.0)), CUP, true)
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.11 * s, 0.4, 0.0), Vector3(0.165 * s, 0.35, 0.0), 0.016, CUP)
		kit.tube(Vector3(0.165 * s, 0.35, 0.0), Vector3(0.115 * s, 0.325, 0.0), 0.016, CUP)
	# a small star finial, silver's own extra touch
	kit.extrude(DecoKit.star_poly(0.045, 0.02, 5), 0.02, CUP_DARK,
		Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.55, 0.0)))
	add_body(kit.commit())
