extends DecoItem
## Meteor Rock — a chunk of space stone that came in hot: a flattened, faceted dome with a crisp
## ground contact, three punched craters and a few seams still glowing orange.
##
## SHAPE: docs/STYLE_GUIDE.md "Bushes/rocks: flattened domes with a clear ground contact and a
## slightly faceted top, not perfect spheres." The first version was four smooth spheres stacked into
## a bulbous bean, which is exactly the "bubbly" silhouette the guide calls out. It is now built from
## `faceted_blob` (hard-shaded low-poly facets with darker down-facing faces), squashed wide and low,
## with a dark skirt where it meets the ground.

const ROCK := Color("#9c94b4")
const ROCK_LIGHT := Color("#b3abc8")
const ROCK_MID := Color("#7f7896")
const ROCK_DARK := Color("#5d5772")
const SEAM := Color("#d9702b")
## Facet resolution of the main mass. 1 = 80 flat facets, which reads as carved stone at 0.5 m wide.
const FACETS := 1


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.42
	collide_height = 0.5


func _build() -> void:
	var kit := DecoKit.new()
	# Dark contact skirt: a crisp, slightly flared collar so the rock meets the grass with an edge
	# instead of fading into it.
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.52, 0.0), Vector2(0.47, 0.07), Vector2(0.0, 0.08)]), 16, Transform3D.IDENTITY, ROCK_DARK)
	# Main mass: wide, low, faceted. Squash keeps the silhouette a dome, not a ball.
	kit.faceted_blob(Vector3(0.0, 0.2, 0.0), 0.42, ROCK, Vector3(1.16, 0.66, 1.02), FACETS, 0.16, 0.0)
	# One lower shoulder, sunk into the mass, plus a couple of ejecta pebbles at the foot: it breaks
	# the outline without turning the rock back into a bunch of bubbles.
	kit.faceted_blob(Vector3(0.29, 0.1, 0.16), 0.19, ROCK_MID, Vector3(1.1, 0.62, 1.0), 0, 0.14, 11.0)
	kit.faceted_blob(Vector3(-0.44, 0.04, -0.22), 0.11, ROCK_MID, Vector3(1.2, 0.55, 1.0), 0, 0.2, 27.0)
	kit.faceted_blob(Vector3(0.16, 0.03, -0.46), 0.08, ROCK_DARK, Vector3(1.2, 0.6, 1.0), 0, 0.2, 41.0)
	# Craters on the upper surface: a raised light rim around a sunken dark floor, pressed in far
	# enough that the faceted shell never pokes back through the rim.
	var craters := [
		[Vector3(-0.16, 0.83, 0.53), 0.15],
		[Vector3(0.62, 0.72, -0.32), 0.11],
	]
	for c in craters:
		var d: Vector3 = (c[0] as Vector3).normalized()
		var r: float = c[1]
		var p := Vector3(0.0, 0.2, 0.0) + d * Vector3(0.42, 0.24, 0.42) * 0.86
		var b := DecoKit.axis_basis(d)
		kit.lathe(PackedVector2Array([Vector2(0.0, -r * 0.4), Vector2(r * 0.66, -r * 0.22), Vector2(r, 0.06)]), 10, Transform3D(b, p), ROCK_DARK)
		kit.lathe(PackedVector2Array([Vector2(r, 0.06), Vector2(r * 1.2, 0.1), Vector2(r * 1.26, 0.0)]), 10, Transform3D(b, p), ROCK_LIGHT)
	add_body(kit.commit())

	# Hot seams: a few short chunky cracks on the flanks that face the gameplay camera, rather than a
	# ring of beads buried in the silhouette.
	var glow := DecoKit.new()
	var seams := [
		[Vector3(-0.33, 0.26, 0.2), Vector3(-0.02, 0.3, 0.36)],
		[Vector3(0.06, 0.31, 0.35), Vector3(0.3, 0.24, 0.26)],
		[Vector3(-0.4, 0.19, -0.06), Vector3(-0.3, 0.28, 0.14)],
	]
	for s in seams:
		glow.tube(s[0], s[1], 0.032, SEAM, 6)
	glow.sphere(Vector3(0.34, 0.2, 0.02), 0.045, Color("#d99246"), Vector3.ONE, 7)
	add_glow(glow.commit(), 2.2, "Seams", 0.7, 0.35)
	add_ground_glow(0.9, Color("#d9822f"), 0.16)
