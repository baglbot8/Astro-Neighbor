extends RefCounted
## PROBE-ONLY: a planet title file whose backdrop has no "size" meta and whose glyph returns a Node3D.
static func backdrop(_block_size: Vector2, _style: Dictionary) -> Variant:
	var n := Node2D.new()
	n.set_meta("size", "big")
	return n


static func glyph(_ch: String, _index: int, _style: Dictionary) -> Variant:
	return Node3D.new()
