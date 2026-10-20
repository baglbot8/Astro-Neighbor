extends RefCounted
## PROBE-ONLY: a broken planet title file (wrong return types) for the data-validation cases.
static func backdrop(_block_size: Vector2, _style: Dictionary) -> Variant:
	return Control.new()


static func glyph(_ch: String, _index: int, _style: Dictionary) -> Variant:
	return 42
