extends Building
## Starport Town Hall — a cream drum under a big teal dome with a gold finial, a projecting front
## bay with an arched wooden door, a clock tower face whose hands track GameState.time_of_day, a
## waving star flag, two lantern posts and a bulletin board.
##
## Door -> Mayor Orbit: rename your planet, planet stats, or leave.
## Bulletin board -> the daily bulletin (day count, a tip, decorations placed at home), then an
## offer to open the favours log right there.

const RENAME_POPUP := "res://src/hub/rename_popup.tscn"

const PLINTH_R := 3.40
const PLINTH_TOP := 0.30
const DRUM_BASE_R := 2.66
const DRUM_R := 2.55            # wall radius at the top of the drum
const DRUM_TOP := 3.50
const CORNICE_TOP := 3.92
const DOME_BASE := 4.34         # where the dome springs from
const DOME_R := 2.32
const DOME_H := 2.08
const BAY_HW := 1.28            # half width of the projecting entrance bay
const BAY_FACE := -2.93         # its front face
const BAY_TOP := 3.54
const DOOR_W := 1.28
const DOOR_H := 2.05
const GABLE_FACE := -2.69       # front face of the clock tower block
const GABLE_Y := 4.20
const CLOCK_R := 0.55
const FLAG_POLE := Vector3(2.44, PLINTH_TOP - 0.02, -1.34)
const FLAG_POLE_H := 5.1
const BOARD_POS := Vector3(-3.32, 0.0, -2.14)
const BOARD_YAW := 26.0
const LANTERN := Vector3(2.06, 0.0, -3.62)
const MAYOR_ACCENT := Color("#6fc3ff")

const DOME_COLOR := Color("#3f9e9a")
const DOME_SHADE := Color("#2b6a68")

var _hour_hand: Node3D
var _minute_hand: Node3D
var _board: Interactable
var _rename_popup: Node


func _init() -> void:
	building_id = "town_hall"
	display_name = "Town Hall"
	ground_sink = 0.18
	ground_radius = 26.0
	# ankle height out on the steps, so the door wins over Mayor Orbit stood in front of it
	door_local = Vector3(0.0, 0.35, BAY_FACE - 1.30)
	door_prompt = "Enter"


func _footprint_shapes() -> Array:
	return [
		[Building.cyl_shape(DRUM_R + 0.24, 5.2), Vector3(0.0, 2.4, 0.0)],
		[_box(Vector3(BAY_HW * 2.0 + 0.2, 3.7, 1.5)), Vector3(0.0, 1.8, -2.28)],
		Building.step_block(3.5, BAY_FACE, -4.05, 0.6),
		[Building.cyl_shape(0.26, 2.3), Vector3(LANTERN.x, 1.0, LANTERN.z)],
		[Building.cyl_shape(0.26, 2.3), Vector3(-LANTERN.x, 1.0, LANTERN.z)],
		[Building.cyl_shape(0.26, 5.2), Vector3(FLAG_POLE.x, 2.4, FLAG_POLE.z)],
		[Building.cyl_shape(0.85, 2.2), Vector3(BOARD_POS.x, 1.0, BOARD_POS.z)],
	]


func _box(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


# R2.9 (docs/STYLE_GUIDE.md): the shell is split by MATERIAL, not committed as one mesh, so the
# plaster drum, the painted dome, the gold ribs and the timber each carry their own character.
#
# The cream drum keeps the preset's plaster microsurface and tonal drift and adds no seams: this is
# a rendered civic building and its structure already comes from the pilasters, the skirt band and
# the cornice. Cylindrical masonry courses were tried and rejected - see `wall_material`.
const WALL_OPTS := {}
# The dome is painted metal: a soft sheen, two latitude rings and 16 gores, one between each pair of
# the eight gold ribs, so the seams line up with the ribs rather than fighting them. `seam_mode` 2
# is the cylindrical case sd_seams was written for, and its topstitch bead lands as a rivet line,
# which is exactly right on a panelled dome. Seams fade at the crown, where the gores converge and
# would otherwise moire.
const DOME_OPTS := {
	"seam_mode": 2, "pitch_a": 1.15, "gores": 16.0, "seam_strength": 0.85,
	"seam_far": 40.0, "macro_scale": 2.6, "macro_amount": 0.30,
}


func _build() -> void:
	var kit := DecoKit.new()        # plaster and cut stone
	var wood := DecoKit.new()       # door leaf, mullions, sign rims, the bulletin board
	var dome := DecoKit.new()       # the painted teal dome
	var metal := DecoKit.new()      # gold ribs, finial, brass, the lantern posts, the flag pole
	var deco := DecoKit.new()       # planters and other small mixed props (R2.9 exempts these)
	_build_plinth(kit)
	_build_drum(kit, wood)
	_build_dome(dome, metal)
	_build_front(kit, wood, metal)
	_build_yard(kit, wood, metal, deco)
	add_wall(kit.commit(), "Walls", WALL_OPTS)
	# Every timber on this building is a vertical plank - the door leaf, the window mullions, the
	# board posts and boards, the sign rim - so the grain runs up the model's own +Y.
	add_wood(wood.commit(), Vector3.UP, "Timber")
	add_panel(dome.commit(), "Dome", DOME_OPTS)
	add_metal(metal.commit(), "Brass")
	add_body(deco.commit(), "Planters")
	_build_clock()
	_build_flag()
	_build_glow()
	animate()


# ----------------------------------------------------------------------------- shell
func _build_plinth(kit: DecoKit) -> void:
	# buried apron: the ground curves ~0.25 m away under a 3.4 m plinth on the 26 m hub
	kit.cone(Vector3(0.0, -0.75, 0.0), PLINTH_R + 0.06, PLINTH_R, 0.92, STONE_DEEP, Basis.IDENTITY, 30)
	kit.cone(Vector3(0.0, 0.17, 0.0), PLINTH_R, PLINTH_R - 0.11, 0.13, STONE, Basis.IDENTITY, 30)
	kit.torus(Vector3(0.0, PLINTH_TOP - 0.03, 0.0), PLINTH_R - 0.10, 0.05, CREAM_LIT, Basis.IDENTITY, 30)


func _build_drum(kit: DecoKit, wood: DecoKit) -> void:
	kit.cone(Vector3(0.0, PLINTH_TOP - 0.04, 0.0), DRUM_BASE_R, DRUM_R, DRUM_TOP - PLINTH_TOP, CREAM, Basis.IDENTITY, 28)
	# darker skirt band at the base: a crisp plane break and a genuine dark tone
	kit.cone(Vector3(0.0, PLINTH_TOP - 0.04, 0.0), DRUM_BASE_R + 0.035, DRUM_BASE_R - 0.015, 0.62, CREAM_DEEP, Basis.IDENTITY, 28)
	kit.torus(Vector3(0.0, PLINTH_TOP + 0.58, 0.0), DRUM_BASE_R + 0.01, 0.045, CREAM_LIT, Basis.IDENTITY, 28)
	# eight pilasters, offset so none of them lands on the doorway
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var r := DRUM_BASE_R - 0.07
		var b := Basis(Vector3.UP, -a)
		kit.rbox(Vector3(sin(a) * r, PLINTH_TOP + 1.62, cos(a) * r), Vector3(0.30, 3.02, 0.24), 0.06, CREAM_LIT, b, 0)
		kit.rbox(Vector3(sin(a) * r, PLINTH_TOP + 3.16, cos(a) * r), Vector3(0.42, 0.14, 0.30), 0.04, CREAM_DEEP, b, 0)
	# arched windows between the pilasters
	for i in 8:
		var a := TAU * float(i) / 8.0
		if absf(wrapf(a, -PI, PI)) > 2.6:
			continue
		var b := Basis(Vector3.UP, PI - a)
		var p := Vector3(sin(a) * (DRUM_R + 0.03), PLINTH_TOP + 1.00, cos(a) * (DRUM_R + 0.03))
		kit.extrude(Building.arch_ring_poly(0.74, 1.22, 0.15, 8), 0.20, CREAM_DEEP, Transform3D(b, p))
		kit.extrude(Building.arch_poly(0.74, 1.22), 0.10, Color("#3b3446"), Transform3D(b, p + b * Vector3(0.0, 0.0, 0.06)))
		# wooden mullion cross, so it reads as a window and not a slot
		wood.rbox(p + b * Vector3(0.0, 0.62, -0.09), Vector3(0.05, 1.16, 0.05), 0.015, WOOD, b, 0)
		wood.rbox(p + b * Vector3(0.0, 0.62, -0.09), Vector3(0.70, 0.05, 0.05), 0.015, WOOD, b, 0)
		kit.rbox(p + b * Vector3(0.0, 0.02, -0.10), Vector3(0.86, 0.09, 0.16), 0.03, CREAM_DEEP, b, 0)
	# cornice: a wide overhanging lip with a flat dark underside
	kit.lathe(PackedVector2Array([
		Vector2(DRUM_R, 0.0), Vector2(DRUM_R + 0.34, 0.07), Vector2(DRUM_R + 0.36, 0.22),
		Vector2(DRUM_R + 0.18, 0.32), Vector2(DRUM_R - 0.04, 0.42)]),
		28, Transform3D(Basis.IDENTITY, Vector3(0.0, DRUM_TOP, 0.0)), CREAM_DEEP)
	kit.torus(Vector3(0.0, DRUM_TOP + 0.07, 0.0), DRUM_R + 0.35, 0.05, CREAM_SHADE, Basis.IDENTITY, 28)


## `kit` takes the painted dome shell (panel material: sheen + panel seams); `metal` takes the gold
## ribs, band and finial, which want brushed grain rather than paint.
func _build_dome(kit: DecoKit, metal: DecoKit) -> void:
	kit.cone(Vector3(0.0, CORNICE_TOP - 0.08, 0.0), DOME_R + 0.08, DOME_R, DOME_BASE - CORNICE_TOP + 0.08, CREAM_LIT, Basis.IDENTITY, 26)
	metal.torus(Vector3(0.0, DOME_BASE - 0.04, 0.0), DOME_R + 0.03, 0.08, GOLD, Basis.IDENTITY, 26)
	kit.dome(Vector3(0.0, DOME_BASE, 0.0), DOME_R, DOME_COLOR, DOME_H / DOME_R, Basis.IDENTITY, 26)
	kit.torus(Vector3(0.0, DOME_BASE + 0.05, 0.0), DOME_R * 0.992, 0.06, DOME_SHADE, Basis.IDENTITY, 26)
	# eight meridian ribs so the dome reads as a built structure, not a soap bubble
	for i in 8:
		var a := TAU * float(i) / 8.0
		var prev := Vector3(sin(a) * DOME_R, DOME_BASE, cos(a) * DOME_R)
		for s in range(1, 7):
			var t := PI * 0.5 * float(s) / 6.0
			var rr := DOME_R * cos(t) * 1.008
			var p := Vector3(sin(a) * rr, DOME_BASE + sin(t) * DOME_H * 1.004, cos(a) * rr)
			metal.bar(prev, p, 0.04, GOLD_DEEP, 6)
			prev = p
	var band := 0.45
	metal.torus(Vector3(0.0, DOME_BASE + sin(band) * DOME_H, 0.0), DOME_R * cos(band) * 1.012, 0.05, GOLD_DEEP, Basis.IDENTITY, 26)
	# finial: ball and spire (the star on top is emissive, see _build_glow)
	var top := DOME_BASE + DOME_H
	metal.sphere(Vector3(0.0, top + 0.13, 0.0), 0.20, GOLD, Vector3(1.0, 0.92, 1.0), 16)
	metal.cone(Vector3(0.0, top + 0.24, 0.0), 0.085, 0.025, 0.50, GOLD, Basis.IDENTITY, 12)


func _build_front(kit: DecoKit, wood: DecoKit, metal: DecoKit) -> void:
	# projecting entrance bay
	kit.rbox(Vector3(0.0, PLINTH_TOP + 1.62, -2.28), Vector3(BAY_HW * 2.0, 3.24, 1.30), 0.13, CREAM_LIT, Basis.IDENTITY, 1)
	kit.rbox(Vector3(0.0, BAY_TOP + 0.12, -2.28), Vector3(2.92, 0.24, 1.64), 0.06, CREAM_DEEP, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, BAY_TOP + 0.28, -2.28), Vector3(2.66, 0.10, 1.44), 0.04, CREAM_SHADE, Basis.IDENTITY, 0)
	build_door(kit, Vector3(0.0, PLINTH_TOP, BAY_FACE), DOOR_W, DOOR_H, CREAM_LIT, WOOD, WOOD_DARK, wood, metal)
	build_steps(kit, 3.30, BAY_FACE, 1.10, PLINTH_TOP, 0.16)

	# clock tower face standing proud of the dome drum
	kit.rbox(Vector3(0.0, GABLE_Y, -2.14), Vector3(1.64, 1.70, 1.02), 0.10, CREAM_LIT, Basis.IDENTITY, 1)
	kit.rbox(Vector3(0.0, GABLE_Y + 0.92, -2.14), Vector3(1.86, 0.15, 1.20), 0.05, CREAM_DEEP, Basis.IDENTITY, 0)
	kit.cone(Vector3(0.0, GABLE_Y + 0.99, -2.14), 1.20, 0.05, 0.46, DOME_COLOR, Basis(Vector3.UP, PI * 0.25), 4)
	# clock dial: gold surround, cream face, twelve ticks
	metal.extrude(DecoKit.round_rect_poly(CLOCK_R * 2.3, CLOCK_R * 2.3, CLOCK_R * 1.14, 6), 0.13, GOLD,
			Transform3D(Basis.IDENTITY, Vector3(0.0, GABLE_Y, GABLE_FACE - 0.045)))
	kit.disc(Vector3(0.0, GABLE_Y, GABLE_FACE - 0.115), CLOCK_R, Color("#f7f1e2"), Basis(Vector3.RIGHT, -PI * 0.5), 26)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var big := i % 3 == 0
		kit.rbox(Vector3(sin(a) * CLOCK_R * 0.82, GABLE_Y + cos(a) * CLOCK_R * 0.82, GABLE_FACE - 0.135),
				Vector3(0.05 if big else 0.032, 0.15 if big else 0.09, 0.025), 0.008, Color("#3b3352"),
				Basis(Vector3.FORWARD, -a), 0)

	# hanging sign centred over the door, under the bay cornice
	var plate := build_hanging_sign(kit, Vector3(0.0, BAY_TOP - 0.06, BAY_FACE - 0.06), 1.86, 0.58,
			CREAM_LIT, WOOD, 0.0, 0.26, wood, metal)
	add_label("TOWN HALL", plate + Vector3(0.0, 0.0, -0.10), 0.25)


func _build_yard(kit: DecoKit, wood: DecoKit, metal: DecoKit, deco: DecoKit) -> void:
	build_planter(deco, Vector3(-1.66, PLINTH_TOP - 0.04, -2.90), 1.0)
	build_planter(deco, Vector3(1.66, PLINTH_TOP - 0.04, -2.90), 1.05, TERRACOTTA.darkened(0.07))
	for s in [-1.0, 1.0]:
		var p := Vector3(LANTERN.x * s, ground_y(Vector2(LANTERN.x, LANTERN.z).length()) - 0.03, LANTERN.z)
		build_lantern_post(metal, p, 2.15)
	# flag pole (standing on the plinth)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.36, 0.0), Vector2(0.33, 0.10), Vector2(0.16, 0.17), Vector2(0.0, 0.18)]),
			18, Transform3D(Basis.IDENTITY, FLAG_POLE), STONE_DEEP)
	metal.cone(FLAG_POLE + Vector3(0.0, 0.14, 0.0), 0.075, 0.05, FLAG_POLE_H - 0.14, Color("#dfe5ee"), Basis.IDENTITY, 12)
	metal.sphere(FLAG_POLE + Vector3(0.0, FLAG_POLE_H, 0.0), 0.10, GOLD, Vector3(1.0, 1.05, 1.0), 12)
	_build_board(wood, deco)


## The bulletin board is all sawn timber - posts, boards, roof slabs and ridge - so it goes to the
## wood material whole. Only the paper notices stay plain (R2.9: small pieces are exempt, and wood
## grain on a sheet of paper would be wrong anyway).
func _build_board(kit: DecoKit, deco: DecoKit) -> void:
	var base := Vector3(BOARD_POS.x, ground_y(Vector2(BOARD_POS.x, BOARD_POS.z).length()) - 0.02, BOARD_POS.z)
	var yaw := Basis(Vector3.UP, deg_to_rad(BOARD_YAW))
	for s in [-1.0, 1.0]:
		kit.cone(base + yaw * Vector3(0.58 * s, -0.3, 0.0), 0.09, 0.075, 1.62, WOOD_DARK, Basis.IDENTITY, 10)
	kit.rbox(base + yaw * Vector3(0.0, 1.42, 0.0), Vector3(1.56, 1.06, 0.16), 0.05, WOOD, yaw, 0)
	kit.rbox(base + yaw * Vector3(0.0, 1.42, -0.10), Vector3(1.30, 0.82, 0.05), 0.03, Color("#7d6244"), yaw, 0)
	# little pitched roof: two slanted slabs and a ridge
	for s in [-1.0, 1.0]:
		var tilt := Basis(Vector3.FORWARD, deg_to_rad(26.0 * s))
		kit.rbox(base + yaw * Vector3(0.42 * s, 2.06, 0.0), Vector3(0.95, 0.10, 0.62), 0.03, WOOD_DEEP, yaw * tilt, 0)
	kit.rbox(base + yaw * Vector3(0.0, 2.26, 0.0), Vector3(0.20, 0.09, 0.66), 0.035, WOOD_DARK, yaw, 0)
	# five notices, varied sizes and tilts so the board never reads as a checkerboard
	var notes: Array[Vector3] = [Vector3(-0.41, 1.55, -0.15), Vector3(-0.03, 1.62, -0.15), Vector3(0.38, 1.50, -0.15),
			Vector3(-0.26, 1.20, -0.15), Vector3(0.28, 1.15, -0.15)]
	var sizes: Array[Vector2] = [Vector2(0.30, 0.24), Vector2(0.24, 0.30), Vector2(0.28, 0.22), Vector2(0.34, 0.20), Vector2(0.26, 0.26)]
	var tints: Array[Color] = [Color("#f8f2e0"), Color("#ffe6a8"), Color("#f8f2e0"), Color("#d8ecff"), Color("#ffd8d0")]
	var tilts: Array[float] = [-4.0, 3.0, -2.0, 5.0, -3.0]
	for i in notes.size():
		var tl := Basis(Vector3.FORWARD, deg_to_rad(tilts[i]))
		deco.rbox(base + yaw * notes[i], Vector3(sizes[i].x, sizes[i].y, 0.02), 0.015, tints[i], yaw * tl, 0)
		deco.sphere(base + yaw * (notes[i] + Vector3(0.0, sizes[i].y * 0.42, -0.02)), 0.024, Color("#d8564f"), Vector3.ONE, 8)


# ----------------------------------------------------------------------------- clock / flag / glow
func _build_clock() -> void:
	var hub := pivot("ClockHands", Vector3(0.0, GABLE_Y, GABLE_FACE - 0.17))
	_hour_hand = pivot("Hour", Vector3.ZERO, hub)
	_minute_hand = pivot("Minute", Vector3(0.0, 0.0, -0.025), hub)
	var hk := DecoKit.new()
	hk.rbox(Vector3(0.0, CLOCK_R * 0.22, 0.0), Vector3(0.08, CLOCK_R * 0.68, 0.04), 0.02, Color("#3b3352"), Basis.IDENTITY, 0)
	add_body(hk.commit(), "HourMesh", _hour_hand)
	var mk := DecoKit.new()
	mk.rbox(Vector3(0.0, CLOCK_R * 0.34, 0.0), Vector3(0.052, CLOCK_R * 0.98, 0.04), 0.015, Color("#5b5273"), Basis.IDENTITY, 0)
	add_body(mk.commit(), "MinuteMesh", _minute_hand)
	var ck := DecoKit.new()
	ck.sphere(Vector3(0.0, 0.0, -0.04), 0.06, GOLD, Vector3.ONE, 10)
	add_body(ck.commit(), "ClockPin", hub)
	_tick_clock()


func _build_flag() -> void:
	var cloth := DecoKit.new()
	var origin := FLAG_POLE + Vector3(0.07, FLAG_POLE_H - 0.80, 0.0)
	var w := 1.55
	var h := 0.92
	cloth.flag_panel(origin, w, h, Color("#e0713d"), 14, 4)
	_flag_star(cloth, origin, w, h, 0.29, Color("#f7ecd2"))
	add_flag(cloth.commit(), "Flag", 0.10, 2.1)


## A star sewn onto the flag. `extrude()` writes UV = the 2D polygon point, so the polygon is built
## in the flag's own UV space and scaled back to metres by the transform. Every star vertex then
## carries the cloth's UV and the wave shader bends the star with the flag instead of leaving it
## hanging in mid-air.
func _flag_star(kit: DecoKit, origin: Vector3, w: float, h: float, r: float, color: Color) -> void:
	var poly := DecoKit.star_poly(r, r * 0.44, 5)
	var uv := PackedVector2Array()
	for p in poly:
		uv.append(Vector2(0.5 + p.x / w, 0.5 - p.y / h))
	var xf := Transform3D(Basis.from_scale(Vector3(w, -h, 1.0)), origin + Vector3(0.0, h * 0.5, 0.0))
	kit.extrude(uv, 0.03, color, xf)


func _build_glow() -> void:
	# window panes: dark slate glass by day, warm and lit after dusk
	var panes := DecoKit.new()
	for i in 8:
		var a := TAU * float(i) / 8.0
		if absf(wrapf(a, -PI, PI)) > 2.6:
			continue
		var b := Basis(Vector3.UP, PI - a)
		var p := Vector3(sin(a) * (DRUM_R + 0.055), PLINTH_TOP + 1.00, cos(a) * (DRUM_R + 0.055))
		panes.extrude(Building.arch_poly(0.66, 1.15), 0.05, WINDOW_WARM, Transform3D(b, p))
	add_glow(panes.commit(), 2.1, "Windows", 0.0, 0.0, 1.0)

	# lamps and the finial star: warm at any hour, brilliant at night
	var lamp_y := ground_y(Vector2(LANTERN.x, LANTERN.z).length()) - 0.03 + 1.95
	var glow := DecoKit.new()
	for s in [-1.0, 1.0]:
		glow.sphere(Vector3(LANTERN.x * s, lamp_y, LANTERN.z), 0.135, Color("#ffd89a"), Vector3(1.0, 1.15, 1.0), 12)
	glow.extrude(DecoKit.star_poly(0.25, 0.10, 5), 0.07, Color("#ffe27a"),
			Transform3D(Basis.IDENTITY, Vector3(0.0, DOME_BASE + DOME_H + 0.78, 0.0)))
	add_glow(glow.commit(), 2.6, "Lamps", 0.8, 0.14)
	for s in [-1.0, 1.0]:
		add_light(Vector3(LANTERN.x * s, lamp_y, LANTERN.z), Color("#ffd9a0"), 1.6, 6.5)
	# buried inside the entrance bay: lights the porch without showing the lamp artifact
	add_light(Vector3(0.0, PLINTH_TOP + 2.30, -2.45), Color("#ffe3b8"), 1.2, 6.0)
	# ...but `add_light` only comes up at dusk, and the entrance bay is in its OWN shadow all day.
	# Mayor Orbit stands right there, so by daylight he rendered as a formless tan blob against a
	# black doorway (integration critic, capOcc/11_town_hall.png). This is the always-on variant,
	# buried behind the door head, so the porch and whoever is standing in it always have a soft
	# warm fill. Deliberately gentle: the plaza already sits near the top of its value band.
	add_interior_light(Vector3(0.0, PLINTH_TOP + 1.72, BAY_FACE + 0.66), Color("#ffe9c6"), 1.05, 6.4)


func _animate(_t: float, _delta: float) -> void:
	_tick_clock()


## Hands follow the in-game clock. Seen from -Z (the plaza), +Z rotation reads as clockwise.
func _tick_clock() -> void:
	if _hour_hand == null:
		return
	var h := GameState.time_of_day
	_hour_hand.rotation.z = fposmod(h, 12.0) / 12.0 * TAU
	_minute_hand.rotation.z = fposmod(h, 1.0) * TAU


# ----------------------------------------------------------------------------- interaction
func _ready() -> void:
	super()
	var base_y := ground_y(Vector2(BOARD_POS.x, BOARD_POS.z).length())
	var yaw := Basis(Vector3.UP, deg_to_rad(BOARD_YAW))
	_board = add_interactable("Bulletin", Vector3(BOARD_POS.x, base_y + 1.42, BOARD_POS.z) + yaw * Vector3(0.0, 0.0, -0.6),
			"Read", 2.5, _on_board)


## The name on the dialogue pill. CORE_LOOP "Changed after the build plan": Orbit is shown as
## Professor Comet and the id mayor_orbit stays. Read from NpcData so the pill always matches his
## name tag - this door (reach 3.0 m) sits 0.9 m from him and usually wins over his own TalkArea
## (2.6 m), so a hardcoded "Mayor Orbit" here was the name most players saw at the Commons.
## The mayor ROLE (rename, stats) is BUILD_PLAN Phase 4 builder I's.
func _prof_name() -> String:
	return str(NpcData.get_data("mayor_orbit").get("display_name", "Professor Comet"))


func _on_door(player: Node3D) -> void:
	if not begin_flow(player):
		return
	await say(_prof_name(),[
		"Ah! Our newest neighbour. Come in, come in.",
		"The Starport is yours to shape, you know.",
	], "elder", MAYOR_ACCENT)
	while true:
		var choice: int = await ask("How can I help?", ["Rename my planet", "Planet stats", "Leave"])
		if choice == 0:
			await _rename_flow()
		elif choice == 1:
			await _stats_flow()
		else:
			break
	await say(_prof_name(),["Mind the step on your way out!"], "elder", MAYOR_ACCENT)
	AudioManager.play_sfx("door_close", -8.0)
	end_flow()


func _rename_flow() -> void:
	var popup := _get_rename_popup()
	if popup == null:
		await say(_prof_name(),["The paperwork seems to have wandered off. Try again later!"], "elder", MAYOR_ACCENT)
		return
	var new_name: String = await popup.ask(GameState.home_planet_name)
	if new_name == "" or new_name == GameState.home_planet_name:
		await say(_prof_name(),["Keeping the old name? A classic choice."], "elder", MAYOR_ACCENT)
		return
	GameState.home_planet_name = new_name
	toast("Your planet is now %s!" % new_name, "stardust")
	AudioManager.play_sfx("quest_complete", -4.0)
	await say(_prof_name(),[
		"Stamped, sealed and filed.",
		"Welcome home to %s." % new_name,
	], "elder", MAYOR_ACCENT)


func _stats_flow() -> void:
	var placed: int = (GameState.placed_decorations.get("home", []) as Array).size()
	var rating := PlanetScore.compute("home")
	var lines: Array[String] = [
		"Day %d on %s." % [GameState.day_count, GameState.home_planet_name],
		"Stardust in the bank: %d." % GameState.stardust,
		"Decorations placed at home: %d." % placed,
	]
	lines.append_array(_trust_lines())
	lines.append("Planet rating: %s (%d/100)." %
		[PlanetScore.star_glyphs(int(rating["stars"])), int(rating["score"])])
	var trash_count := int(rating["trash_count"])
	if trash_count > 0:
		lines.append("There's %d piece%s of space junk lying around. Might want to clean that up!" %
			[trash_count, "" if trash_count == 1 else "s"])
	await say(_prof_name(),lines, "elder", MAYOR_ACCENT)


## The Mayor reads out the same neighbours PlanetScore actually averages, so the readout can never
## drift from the number underneath it. This was two hardcoded names; the list is five now and will
## grow again, so it LOOPS. Two per dialogue line - a typewriter box chewing through five names at
## once reads as a wall of text, and the box is sized for about that much. An odd count simply
## leaves the last line carrying one name, which is what the `i + 1 < parts.size()` test is for.
func _trust_lines() -> Array[String]:
	var parts: Array[String] = []
	for npc_id: String in PlanetScore.TRUST_NPCS:
		var who := str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))
		var friendship: int = int(GameState.npc_data(npc_id).get("friendship", 0))
		parts.append("%s likes you %d%%." % [who, friendship])
	var out: Array[String] = []
	var i := 0
	while i < parts.size():
		var line: String = parts[i]
		if i + 1 < parts.size():
			line += " " + parts[i + 1]
		out.append(line)
		i += 2
	return out


func _on_board(player: Node3D) -> void:
	if not begin_flow(player):
		return
	var placed: int = (GameState.placed_decorations.get("home", []) as Array).size()
	var tips: Array[String] = [
		"Tip: press Tab to decorate anywhere on your planet.",
		"Tip: Cosmo Depot restocks every single morning.",
		"Tip: neighbours pay well for little favours.",
		"Tip: stardust regrows overnight. Sweep the hills!",
		"Tip: the rocket pad will take you anywhere. Even home.",
	]
	await say("Bulletin Board", [
		"~ STARPORT DAILY, day %d ~" % GameState.day_count,
		tips[GameState.day_count % tips.size()],
		"Decorations placed at home so far: %d." % placed,
	], "astro", Color("#c88a3f"))
	# docs/OPEN_ISSUES.md #11: the board is the favours log's second, diegetic home (the other is
	# the J hotkey and the pause menu). Offered rather than forced, so reading the daily notice
	# never costs you a menu you did not ask for.
	var choice: int = await ask("Check your favours log?", ["Open the log", "Not now"])
	end_flow()
	if choice == 0 and is_inside_tree():
		JournalPanel.open_over(self)


func _get_rename_popup() -> Node:
	if _rename_popup != null and is_instance_valid(_rename_popup):
		return _rename_popup
	if not ResourceLoader.exists(RENAME_POPUP):
		return null
	var hud := get_node_or_null("/root/World/HUD")
	_rename_popup = load(RENAME_POPUP).instantiate()
	if hud:
		hud.add_child(_rename_popup)
	else:
		get_tree().root.add_child(_rename_popup)
	return _rename_popup
