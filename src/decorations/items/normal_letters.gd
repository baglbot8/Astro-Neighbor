extends RefCounted
## Chunky pixel letters for "Norm's Totally Normal Collection" (docs/DAILY_STAMPS_SPEC.md 3): the
## houseplant's PLANT label and the rug's NORMAL. Everything in this game is procedural, so a word is
## a handful of flat quads baked into the item's one body mesh: no font, no texture, no extra draw
## call. One quad (2 triangles) per horizontal run of lit cells; PLANT costs 54 triangles.
##
##   const Letters := preload("res://src/decorations/items/normal_letters.gd")
##   Letters.draw(kit, "PLANT", xf, 0.034, INK)
##
## `xf` places the word: origin = the centre of the word, basis.x = reading direction, basis.y = up
## the letters, basis.z = out of the surface toward the reader. Models face -Z, so a label on an
## item's front uses FRONT; a word lying on the ground, read from the front, uses FLOOR.

## Reading direction -X (the reader stands at -Z), letters up +Y, facing -Z.
const FRONT := Basis(Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, -1.0))
## Reading direction -X, letters "up" pointing away from the reader (+Z), facing the sky.
const FLOOR := Basis(Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 1.0, 0.0))

## Five rows tall, top row first. Only the letters the collection uses.
const GLYPHS := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
	"N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
	"O": ["###", "#.#", "#.#", "#.#", "###"],
	"P": ["###", "#.#", "###", "#..", "#.."],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
}
const ROWS := 5


## Width of `text` in cells (one blank cell between letters).
static func cells_wide(text: String) -> int:
	var w := 0
	for i in text.length():
		var g: Array = GLYPHS.get(text[i], [])
		w += (str(g[0]).length() if not g.is_empty() else 2) + (1 if i > 0 else 0)
	return w


## Bakes `text` into `kit` as flat single-sided quads, `cell` metres per pixel.
static func draw(kit: DecoKit, text: String, xf: Transform3D, cell: float, color: Color) -> void:
	var u := -float(cells_wide(text)) * cell * 0.5
	var top := float(ROWS) * cell * 0.5
	for i in text.length():
		var g: Array = GLYPHS.get(text[i], [])
		if g.is_empty():
			u += 3.0 * cell
			continue
		var cols := str(g[0]).length()
		for r in ROWS:
			var row := str(g[r])
			var c := 0
			while c < cols:
				if row[c] != "#":
					c += 1
					continue
				var c0 := c
				while c < cols and row[c] == "#":
					c += 1
				var u0 := u + float(c0) * cell
				var u1 := u + float(c) * cell
				var v1 := top - float(r) * cell
				var v0 := v1 - cell
				kit.quad(xf * Vector3(u0, v0, 0.0), xf * Vector3(u0, v1, 0.0), xf * Vector3(u1, v1, 0.0), xf * Vector3(u1, v0, 0.0), color, false)
		u += float(cols + 1) * cell
