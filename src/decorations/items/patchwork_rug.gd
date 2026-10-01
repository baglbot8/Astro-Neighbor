extends DecoItem
## Patchwork Rug (cozy home set) - a rectangular rug sewn from six soft squares, with a stitched star,
## moon and heart-leaf on three of them and mustard tassels on both short ends. Non-blocking: you walk
## right over it. The round Nebula Rug is deep space; this one is somebody's living room.

const BASE := Color("#cdbf9f")
const STITCH := Color("#a8946c")
const PATCHES := [Color("#cf8f86"), Color("#e3d7bc"), Color("#7fb5ad"), Color("#d9c27a"), Color("#a595cf"), Color("#c9805e")]
const MOTIF := Color("#efe6d0")
const TASSEL := Color("#d2b262")
const W := 1.8
const D := 1.14


func _init() -> void:
	footprint = 1.0
	blocking = false
	collide_radius = 0.9
	collide_height = 0.06


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.025, 0.0), Vector3(W, 0.05, D), 0.025, BASE)
	# --- six patches, 3 x 2, each a hair different in height so the seams catch the light -------------
	var pw := (W - 0.16) / 3.0
	var pd := (D - 0.16) / 2.0
	var flat := Basis(Vector3.RIGHT, deg_to_rad(-90.0))
	# extruded rounded rectangles, not level-0 rounded boxes: a 20-triangle rbox this flat shades as
	# diagonal facets (it read as satin with a sheen); an extrude has one flat top and takes the colour
	for row in 2:
		for col in 3:
			var i := row * 3 + col
			var c := Vector3((float(col) - 1.0) * pw, 0.05 + 0.004 * float(i % 2), (float(row) - 0.5) * pd)
			kit.extrude(DecoKit.round_rect_poly(pw - 0.03, pd - 0.03, 0.04, 2), 0.024, PATCHES[i], Transform3D(flat, c))
	# --- the seams ---------------------------------------------------------------------------------
	for sx in [-0.5, 0.5]:
		kit.rbox(Vector3(sx * pw, 0.05, 0.0), Vector3(0.016, 0.02, D - 0.14), 0.006, STITCH, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.05, 0.0), Vector3(W - 0.14, 0.02, 0.016), 0.006, STITCH, Basis.IDENTITY, 0)
	# --- stitched motifs, laid flat ----------------------------------------------------------------
	kit.extrude(DecoKit.star_poly(0.15, 0.07, 5), 0.012, MOTIF,
		Transform3D(flat * Basis(Vector3.FORWARD, 0.3), Vector3(-pw, 0.07, -pd * 0.5)))
	kit.extrude(DecoKit.crescent_poly(0.14, 0.115, 0.08, 10), 0.012, MOTIF,
		Transform3D(flat * Basis(Vector3.FORWARD, -0.5), Vector3(pw, 0.07, pd * 0.5)))
	kit.torus(Vector3(0.0, 0.066, -pd * 0.5), 0.1, 0.014, STITCH, Basis.IDENTITY, 14, 3)
	kit.sphere(Vector3(0.0, 0.066, -pd * 0.5), 0.045, STITCH, Vector3(1.0, 0.3, 1.0), 8)
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		kit.sphere(Vector3(-pw + cos(a) * 0.12, 0.068, pd * 0.5 + sin(a) * 0.12), 0.035, MOTIF, Vector3(1.0, 0.3, 1.0), 6)
	kit.sphere(Vector3(-pw, 0.068, pd * 0.5), 0.045, TASSEL, Vector3(1.0, 0.3, 1.0), 6)
	# --- tassels on both short ends ------------------------------------------------------------------
	for s in [-1.0, 1.0]:
		for k in 9:
			var z := lerpf(-D * 0.5 + 0.08, D * 0.5 - 0.08, float(k) / 8.0)
			kit.tube(Vector3(W * 0.5 * s - 0.02 * s, 0.022, z), Vector3(W * 0.5 * s + 0.1 * s, 0.014, z + 0.012 * float(k % 3 - 1)),
				0.014, TASSEL, 5, 1)
	add_body(kit.commit())
