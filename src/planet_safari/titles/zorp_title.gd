extends RefCounted
## ZORP'S TITLE SHAPES (TitleLettering, THE PLANET INTERFACE). Which shapes are drawn follows the style key
## "title_preset", set by worlds/zorp.gd TITLE_PRESET (change that one value to switch the look):
##   "crest"       (M1, the default) `backdrop` = the violet mushroom crest behind the two lines
##   "mushroom_t"  (M2) `glyph` = the T as a little mushroom; no backdrop
##   "plaque"      (M3) `backdrop` = a deep-violet location plaque with a gold border and a mushroom-ring foot
##   "plain"       nothing: the stroke lettering alone
## The full-size stills of all three are TitleMockups.crest() / mushroom_t() / plaque() (title_mockups.gd).

const Shapes := preload("res://src/planet_safari/title_mockups.gd")
const Z := preload("res://src/planet_safari/worlds/zorp_meshes.gd")
const PX := TitleLettering.BUILD_CAP_PX


static func _preset(style: Dictionary) -> String:
	return str(style.get("title_preset", "crest"))


static func backdrop(block_size: Vector2, style: Dictionary) -> Node2D:
	match _preset(style):
		"crest":
			return _crest(block_size)
		"plaque":
			return _plaque(block_size)
	return null


## M1: a tall violet cap with gills and spots on a short stalk, centred on the block (sitting on the gap between the
## two lines; the stalk shows below the second).
static func _crest(block_size: Vector2) -> Node2D:
	var sh := Shapes._Shapes.new()
	var cap_w := block_size.x * 0.58
	# Lower than M1's still (0.95): with the block at the screen's upper third, a 0.95 dome ran off the top of the
	# frame at both 2556x1179 and 1280x720 (its top spots cut); 0.75 keeps the whole crest in frame.
	var cap_h := block_size.y * 0.75
	var c := Vector2(0.0, block_size.y * 0.02)
	var stalk_top := c.y + cap_h * 0.1
	# The stalk stops at about the subtitle (M1's 0.78 ran down onto the subject in the game frames).
	var stalk_h := block_size.y * 0.6
	# A THICK stalk, as wide as HOLLOW, so the second line has the crest behind it too: with M1's thin stalk the real
	# toadstool's stalk showed through between H, O and L at full strength (the critic, 2026-10-20). Inside the same
	# extent, so the same atlas cell (no memory change).
	sh.add_stalk(c + Vector2(0.0, cap_h * 0.1), cap_w * 0.5, stalk_h, Z.STALK, Shapes.PLUM_DARK)
	sh.add_dome(c, cap_w, cap_h, Z.SHELL, Shapes.PLUM_DARK, 9)
	sh.add_crown(c, cap_w, cap_h, Z.SHELL.lerp(Z.STALK, 0.55), 1.0)   # the stills' 0.55 sheen, pre-blended: opaque, AA edge
	sh.add_gills(c, cap_w * 0.97, cap_h * 0.13, Z.CAP_UNDER, Shapes.PLUM_DARK)
	for sp: Vector3 in [Vector3(-0.62, -0.42, 0.06), Vector3(-0.3, -0.8, 0.055), Vector3(0.18, -0.9, 0.05),
			Vector3(0.55, -0.62, 0.065), Vector3(0.84, -0.22, 0.045), Vector3(-0.86, -0.15, 0.04)]:
		sh.add_spot(c + Vector2(sp.x * cap_w, sp.y * cap_h), sp.z * cap_w, Z.SPOT, Color(0, 0, 0, 0))
	# Its extent round the centre (the bake cell): the cap's width plus its rim; from the crown (c.y - cap_h) to the
	# stalk's foot (its outline reaches 2% past `stalk_h`), whichever is further, both ways.
	var half_h := maxf(cap_h - c.y, stalk_top + stalk_h * 1.04) + PX * 0.05
	sh.set_meta("size", Vector2(cap_w * 2.0 + PX * 0.1, half_h * 2.0))
	return sh


## M3: the plaque round the letters, a mushroom ring either side of its foot, four amber spores.
static func _plaque(block_size: Vector2) -> Node2D:
	var sh := Shapes._Shapes.new()
	# Taller below than above, so the subtitle (SafariIntro puts it ~0.6 cap heights under the block) sits ON the plaque,
	# not across its border (seen in the first in-game frame).
	var size := block_size + Vector2(PX * 1.1, PX * 1.6)
	var c := Vector2(0.0, PX * 0.3)
	sh.add_shadow_rrect(c + Vector2(0.0, PX * 0.08), size + Vector2(PX * 0.2, PX * 0.2), Color(Shapes.PLUM_DARK, 0.45))
	sh.add_plaque(c, size, PX * 0.42, Shapes.PLUM_DARK, Z.SHELL, Shapes.AMBER, Shapes.AMBER_DEEP)
	var foot := c.y + size.y * 0.5 - PX * 0.2
	for side in [-1.0, 1.0]:
		for i in 4:
			var u := 0.36 + 0.035 * float(i)
			sh.add_tiny_mushroom(Vector2(side * u * size.x, foot), PX * (0.16 + 0.04 * float(i)),
				Z.CAP if i % 2 == 0 else Z.RING_CAP, Z.RING_STEM, Z.SHELL)
	for sp: Vector3 in [Vector3(-0.46, -0.36, 2.6), Vector3(0.45, -0.34, 2.2)]:
		sh.add_spore(Vector2(sp.x * size.x, sp.y * size.y) + c, sp.z, Shapes.AMBER)
	sh.set_meta("size", size + Vector2(PX * 0.5, PX * 0.6 + absf(c.y) * 2.0))
	return sh


## M2: the T as a little mushroom: a flat cap level with the letters' tops (the bar), a stalk in the letters' own
## core and outline (the stem). Other letters (and every letter in the other looks) keep the stroke glyph.
static func glyph(ch: String, _index: int, style: Dictionary) -> Node2D:
	if ch != "T" or _preset(style) != "mushroom_t":
		return null
	var sh := Shapes._Shapes.new()
	var hw := PX * 0.4
	var h := PX * 0.34
	var c := Vector2(0.0, -PX * 0.7)
	sh.add_stalk(c, PX * 0.1, PX * 0.7, style.get("core", Z.FRILL), style.get("outline_col", Z.SHELL))
	sh.add_dome(c, hw, h, Z.CAP, Z.SHELL, 5)
	sh.add_crown(c, hw, h, Z.PETAL_TIP)
	sh.add_gills(c, hw * 0.97, h * 0.2, Z.CAP_UNDER, Z.SHELL)
	for sp: Vector3 in [Vector3(-0.5, -0.4, 0.13), Vector3(0.05, -0.72, 0.12), Vector3(0.52, -0.38, 0.11)]:
		sh.add_spot(c + Vector2(sp.x * hw, sp.y * h), sp.z * hw, Shapes.AMBER, Color(Shapes.AMBER, 0.35))
	sh.set_meta("w", 0.66)
	return sh
