extends Building
## Suit-Up — the clothes boutique. Blush-pink walls under a lavender hipped roof, a brass porthole
## window, bunting swinging across the front, a helmet-shaped sign on the ridge, and a mannequin
## turning in the display window that changes outfit every 8 seconds.
##
## Door -> Stella: browse the rack (ShopPanel with Catalog.store_items("clothing")) or leave.
## Buying a garment adds it to GameState.wardrobe and puts it on immediately.

const SHOP_TITLE := "Suit-Up"
const KEEPER := "Stella"
const STELLA_ACCENT := Color("#e58fb4")
const OUTFIT_SECONDS := 8.0

const PINK := Color("#d29cb0")
const PINK_LIT := Color("#e2b0c0")
const PINK_DEEP := Color("#b57a90")
const LAVENDER := Color("#8a7cab")
const LAVENDER_DEEP := Color("#584d72")
const BRASS := Color("#d9a94f")

const APRON := 0.16
const BODY_TOP := 3.28
const FACE_Z := -2.02
const NICHE_Z := -1.36
const WIN_X := 1.32
const WIN_W := 1.92
const WIN_BOT := 0.30
const WIN_TOP := 2.62
const DOOR_X := -1.54
const DOOR_W := 1.18
const DOOR_H := 2.02
const PORT_X := -0.14
const PORT_Y := 1.62
const PORT_R := 0.54
const ROOF_H := 0.94
const HELMET_Y := BODY_TOP + ROOF_H + 0.62

var _turntable: Node3D
var _mannequin: AstronautModel
var _bunting: Node3D
var _outfits: Array[Dictionary] = []
var _outfit_index := -1
var _outfit_timer := 0.0


func _init() -> void:
	building_id = "clothes_store"
	display_name = SHOP_TITLE
	ground_sink = 0.16
	ground_radius = 26.0
	# ankle height out on the doorstep, so the door wins over a shopkeeper stood beside it
	door_local = Vector3(DOOR_X, 0.35, FACE_Z - 1.20)
	door_prompt = "Enter"


func _footprint_shapes() -> Array:
	return [
		[_box(Vector3(5.1, 4.3, 4.0)), Vector3(0.0, 2.0, 0.0)],
		Building.step_block(2.2, FACE_Z, -3.05, 0.55),
	]


func _box(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


# R2.9: split by material. The blush walls take the plaster preset; the lavender hipped roof is
# painted sheet metal, so it takes the panel preset with courses across the slope at shingle pitch
# (3.1 per metre = a 0.32 m course, 55 px at the door and 12 px from across the plaza); the bunting
# is cloth; the porthole ring, the dress rail and the helmet sign are metal; the door is timber.
const ROOF_OPTS := {
	"seam_mode": 1, "pitch_a": 3.1, "pitch_b": 0.55, "seam_strength": 0.75,
	"macro_scale": 3.0, "macro_amount": 0.28,
}
# Bunting pennants are ~0.3 m across, so the seam family is pitched to one seam per pennant rather
# than the awning's panel pitch.
const BUNTING_OPTS := {"pitch_b": 3.4, "seam_strength": 1.1}
# The rooftop helmet is a 1.24 m sphere seen from the whole plaza: cylindrical seams round its own
# axis, 10 gores, so it reads as a moulded shell rather than a beach ball.
const HELMET_OPTS := {"seam_mode": 2, "pitch_a": 1.6, "gores": 10.0, "seam_strength": 0.8}


func _build() -> void:
	var kit := DecoKit.new()        # blush render, stone apron, frames, sill, sign plate
	var roof := DecoKit.new()       # the lavender hipped roof and the dormer cap
	var wood := DecoKit.new()       # the door leaf
	var metal := DecoKit.new()      # brass porthole, sign hangers, dress rail, helmet sign
	var deco := DecoKit.new()       # planters and the two garments on the rail
	_build_shell(kit)
	_build_facade(kit, wood, metal)
	_build_roof(kit, roof, metal)
	_build_yard(kit, metal, deco)
	add_wall(kit.commit(), "Walls")
	add_panel(roof.commit(), "Roof", ROOF_OPTS)
	add_wood(wood.commit(), Vector3.UP, "Timber")
	add_metal(metal.commit(), "Brass")
	add_body(deco.commit(), "Props")
	_build_bunting()
	_build_helmet_sign()
	_build_mannequin()
	_build_glow()
	animate()


func _build_shell(kit: DecoKit) -> void:
	kit.rbox(Vector3(0.0, -0.34, -0.10), Vector3(5.1, 1.0, 4.2), 0.10, STONE_DEEP, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, APRON - 0.09, -0.10), Vector3(4.96, 0.18, 4.06), 0.05, STONE, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, (BODY_TOP + APRON) * 0.5, 0.24), Vector3(4.80, BODY_TOP - APRON, 3.20), 0.24, PINK, Basis.IDENTITY, 1)
	# lavender wainscot: the second colour block that makes the shop read from 20 m
	kit.rbox(Vector3(0.0, APRON + 0.34, 0.24), Vector3(4.86, 0.70, 3.26), 0.10, LAVENDER, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, APRON + 0.71, 0.24), Vector3(4.90, 0.07, 3.30), 0.03, PINK_LIT, Basis.IDENTITY, 0)
	# display niche box
	kit.rbox(Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, NICHE_Z + 0.12), Vector3(WIN_W + 0.26, WIN_TOP - WIN_BOT + 0.24, 0.28), 0.03, Color("#f3e2e8"), Basis.IDENTITY, 0)
	kit.rbox(Vector3(WIN_X, WIN_BOT + 0.04, (NICHE_Z + FACE_Z) * 0.5), Vector3(WIN_W - 0.06, 0.09, 0.66), 0.02, Color("#c9a3b2"), Basis.IDENTITY, 0)


func _build_facade(kit: DecoKit, wood: DecoKit, metal: DecoKit) -> void:
	var h := BODY_TOP - APRON
	var cy := (BODY_TOP + APRON) * 0.5
	var fz := (FACE_Z + NICHE_Z) * 0.5
	var fd := NICHE_Z - FACE_Z
	kit.rbox(Vector3(-1.20, cy, fz), Vector3(2.40, h, fd), 0.07, PINK_LIT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(2.28, cy, fz), Vector3(0.30, h, fd), 0.07, PINK_LIT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(WIN_X, (WIN_TOP + BODY_TOP) * 0.5, fz), Vector3(WIN_W, BODY_TOP - WIN_TOP, fd), 0.06, PINK_LIT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(WIN_X, (WIN_BOT + APRON) * 0.5, fz), Vector3(WIN_W, WIN_BOT - APRON, fd), 0.06, PINK_LIT, Basis.IDENTITY, 0)
	build_window_frame(kit, Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, FACE_Z - 0.06), WIN_W, WIN_TOP - WIN_BOT, 0.20, 0.22, PINK_LIT.lightened(0.20))
	kit.rbox(Vector3(WIN_X, WIN_BOT - 0.20, FACE_Z - 0.11), Vector3(WIN_W + 0.56, 0.15, 0.36), 0.05, PINK_DEEP, Basis.IDENTITY, 0)

	# brass porthole: a chunky ring, a cross mullion and a recessed dark pane
	metal.lathe(PackedVector2Array([Vector2(PORT_R, 0.0), Vector2(PORT_R + 0.15, 0.02), Vector2(PORT_R + 0.16, 0.14),
			Vector2(PORT_R + 0.02, 0.20), Vector2(PORT_R - 0.02, 0.10)]),
			24, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(PORT_X, PORT_Y, FACE_Z + 0.02)), BRASS)
	kit.disc(Vector3(PORT_X, PORT_Y, FACE_Z - 0.05), PORT_R, Color("#4d4a60"), Basis(Vector3.RIGHT, -PI * 0.5), 24)
	for k in 2:
		var rot := Basis(Vector3.FORWARD, PI * 0.5 * float(k))
		metal.rbox(Vector3(PORT_X, PORT_Y, FACE_Z - 0.10), Vector3(PORT_R * 2.0, 0.05, 0.05), 0.015, BRASS, rot, 0)
	for i in 6:
		var a := TAU * float(i) / 6.0
		metal.sphere(Vector3(PORT_X + cos(a) * (PORT_R + 0.09), PORT_Y + sin(a) * (PORT_R + 0.09), FACE_Z - 0.13), 0.036, BRASS.darkened(0.22), Vector3.ONE, 8)

	build_door(kit, Vector3(DOOR_X, APRON, FACE_Z), DOOR_W, DOOR_H, PINK_LIT.lightened(0.16), Color("#a5748a"), Color("#795061"), wood, metal)
	build_steps(kit, 2.00, FACE_Z, 0.92, APRON, 0.14, DOOR_X)
	# hanging sign over the door
	var plate := build_hanging_sign(kit, Vector3(-0.10, BODY_TOP - 0.14, FACE_Z - 0.18), 2.42, 0.62,
			Color("#fdf1e6"), LAVENDER, 0.0, 0.22, wood, metal)
	add_label("SUIT-UP", plate + Vector3(0.0, 0.0, -0.15), 0.30, Color("#7a4b64"))
	set_meta("sign_plate", plate)


func _build_roof(kit: DecoKit, roof: DecoKit, _metal: DecoKit) -> void:
	build_hip_roof(roof, 5.24, 3.66, ROOF_H, 2.30, BODY_TOP, 0.24, LAVENDER, LAVENDER_DEEP)
	# a tiny dormer over the display window so the roofline is not one clean wedge
	kit.rbox(Vector3(WIN_X, BODY_TOP + 0.36, -1.34), Vector3(1.10, 0.62, 0.70), 0.10, PINK_LIT, Basis.IDENTITY, 0)
	roof.cone(Vector3(WIN_X, BODY_TOP + 0.64, -1.34), 0.86, 0.05, 0.36, LAVENDER, Basis(Vector3.UP, PI * 0.25), 4)


func _build_yard(_kit: DecoKit, metal: DecoKit, deco: DecoKit) -> void:
	build_planter(deco, Vector3(-2.62, ground_y(3.7) - 0.02, -2.58), 1.0, Color("#c98aa4"), Color("#4e9a6a"), Color("#2c6448"))
	build_planter(deco, Vector3(2.60, ground_y(3.6) - 0.02, -2.42), 0.92, Color("#b57a90"))
	# a little dress rail with two hangers by the door
	var rail := Vector3(-2.72, ground_y(4.1) - 0.02, -3.10)
	for s in [-1.0, 1.0]:
		metal.cone(rail + Vector3(0.42 * s, 0.0, 0.0), 0.07, 0.05, 1.42, METAL, Basis.IDENTITY, 10)
	metal.bar(rail + Vector3(-0.44, 1.40, 0.0), rail + Vector3(0.44, 1.40, 0.0), 0.035, METAL, 8)
	for i in 2:
		var x: float = -0.20 + float(i) * 0.40
		metal.bar(rail + Vector3(x, 1.38, 0.0), rail + Vector3(x, 1.14, 0.0), 0.018, METAL_DARK, 5)
		deco.rbox(rail + Vector3(x, 0.86, 0.0), Vector3(0.30, 0.56, 0.12), 0.05,
				Color("#7fb8d8") if i == 0 else Color("#e0a05c"), Basis.IDENTITY, 0)


func _build_bunting() -> void:
	_bunting = pivot("Bunting", Vector3(0.0, 0.0, 0.0))
	var kit := DecoKit.new()
	var colors: Array[Color] = [Color("#e8a0bd"), Color("#f2d68a"), Color("#8fd0d8"), Color("#b79ade"), Color("#f0f0e2")]
	build_bunting(kit, Vector3(-2.64, BODY_TOP + 0.06, FACE_Z - 0.34), Vector3(2.64, BODY_TOP + 0.06, FACE_Z - 0.34), 0.34, 9, colors)
	add_cloth(kit.commit(), "BuntingMesh", BUNTING_OPTS, _bunting)


## The rooftop sign: an astronaut helmet the size of a beach ball, so Suit-Up is unmistakable from
## across the plaza.
func _build_helmet_sign() -> void:
	var post := DecoKit.new()
	post.cone(Vector3(0.0, BODY_TOP + ROOF_H - 0.12, 0.10), 0.13, 0.10, 0.60, METAL, Basis.IDENTITY, 12)
	# the sign is a giant painted helmet: panelled metal, so it gets the sheen and the seams
	post.sphere(Vector3(0.0, HELMET_Y, 0.10), 0.62, Color("#f2ede2"), Vector3(1.06, 0.96, 1.0), 22)
	post.lathe(PackedVector2Array([Vector2(0.38, 0.0), Vector2(0.46, 0.04), Vector2(0.44, 0.13)]),
			22, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.0, HELMET_Y, -0.40)), Color("#e08fae"))
	post.sphere(Vector3(0.0, HELMET_Y + 0.60, 0.10), 0.09, Color("#e08fae"), Vector3.ONE, 10)
	post.rbox(Vector3(0.0, HELMET_Y - 0.60, 0.10), Vector3(0.90, 0.14, 0.62), 0.05, Color("#e8a0bd"), Basis.IDENTITY, 0)
	add_panel(post.commit(), "HelmetSign", HELMET_OPTS)
	var visor := DecoKit.new()
	visor.sphere(Vector3(0.0, HELMET_Y, -0.34), 0.40, Color("#8fd8ff"), Vector3(1.0, 0.92, 0.55), 20)
	add_glass(visor.commit(), Color("#8fd8ff"), 0.55, "HelmetVisor")


## The mannequin: a real AstronautModel with follow_game_state off, turning on a turntable and
## changing outfit every OUTFIT_SECONDS.
func _build_mannequin() -> void:
	_turntable = pivot("Turntable", Vector3(WIN_X, WIN_BOT + 0.09, (NICHE_Z + FACE_Z) * 0.5 + 0.08))
	var disc := DecoKit.new()
	disc.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.62, 0.0), Vector2(0.58, 0.08), Vector2(0.0, 0.10)]),
			24, Transform3D.IDENTITY, Color("#c98aa4"))
	disc.torus(Vector3(0.0, 0.03, 0.0), 0.60, 0.035, BRASS, Basis.IDENTITY, 22)
	add_body(disc.commit(), "TurntableTop", _turntable)

	_outfits = _outfit_list()
	if not ResourceLoader.exists("res://src/player/astronaut_model.tscn"):
		return
	_mannequin = load("res://src/player/astronaut_model.tscn").instantiate()
	_mannequin.name = "Mannequin"
	_mannequin.follow_game_state = false
	_turntable.add_child(_mannequin)
	_mannequin.position = Vector3(0.0, 0.10, 0.0)
	_next_outfit()


## Five outfits pulled from the clothing catalog (falling back to hand-picked styles), each with a
## strong secondary colour so the mannequin reads as dressed, not as a white blob.
func _outfit_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hats: Array[String] = ["", "hat_cap", "", "hat_crown", "hat_antenna"]
	var packs: Array[String] = ["pack_basic", "pack_rocket", "pack_jet", "pack_basic", "pack_rocket"]
	var suits: Array = Catalog.items_of_kind("clothing").filter(
			func(d: Dictionary) -> bool: return str(d.get("category", "")) == "suit" and int(d.get("price", 0)) > 0)
	suits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("price", 0)) > int(b.get("price", 0)))
	for i in 5:
		var style: Dictionary = {}
		if i < suits.size():
			style = (suits[i].get("style", {}) as Dictionary).duplicate()
		else:
			style = {"suit_color": "#e8b6c6", "accent_color": "#5d4b85", "visor_tint": "#ffd6f2"}
		style["hat_id"] = hats[i]
		style["backpack_id"] = packs[i]
		out.append(style)
	return out


func _next_outfit() -> void:
	if _mannequin == null or _outfits.is_empty():
		return
	_outfit_index = (_outfit_index + 1) % _outfits.size()
	_mannequin.apply_style(_outfits[_outfit_index])
	_mannequin.set_state("wave" if _outfit_index % 2 == 0 else "happy")


func _build_glow() -> void:
	var glow := DecoKit.new()
	var plate: Vector3 = get_meta("sign_plate", Vector3(DOOR_X, 2.6, FACE_Z - 0.3))
	glow.extrude(DecoKit.round_rect_poly(2.66, 0.90, 0.18, 5), 0.05, Color("#ffd0e4"),
			Transform3D(Basis.IDENTITY, plate + Vector3(0.0, 0.0, 0.10)))
	glow.disc(Vector3(PORT_X, PORT_Y, FACE_Z - 0.06), PORT_R - 0.03, Color("#ffd9a8"), Basis(Vector3.RIGHT, -PI * 0.5), 22)
	add_glow(glow.commit(), 2.2, "SignGlow", 0.0, 0.0, 0.0)

	# display case: emissive panels only (a lamp inside a sealed niche renders as a dark orb)
	var case_light := DecoKit.new()
	case_light.rbox(Vector3(WIN_X, WIN_TOP - 0.10, (NICHE_Z + FACE_Z) * 0.5 + 0.04), Vector3(WIN_W - 0.30, 0.07, 0.54), 0.025, Color("#fff2e2"), Basis.IDENTITY, 0)
	case_light.rbox(Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, NICHE_Z + 0.02), Vector3(WIN_W - 0.16, WIN_TOP - WIN_BOT - 0.16, 0.05), 0.02, Color("#f7dfe6"), Basis.IDENTITY, 0)
	var mi := add_glow(case_light.commit(), 1.15, "CaseLight", 0.0, 0.0)
	mi.set_instance_shader_parameter("force_on", 1.0)
	# a shop lamp OUTSIDE the window throws light onto the mannequin without entering the niche
	add_interior_light(Vector3(WIN_X, 1.62, -0.55), Color("#fff0e0"), 2.6, 4.4)
	add_light(Vector3(DOOR_X, BODY_TOP - 0.35, -1.20), Color("#ffd0d8"), 1.4, 6.5)

	var glass := DecoKit.new()
	glass.rbox(Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, FACE_Z - 0.02), Vector3(WIN_W - 0.06, WIN_TOP - WIN_BOT - 0.06, 0.03), 0.02, Color.WHITE, Basis.IDENTITY, 0)
	add_glass(glass.commit(), Color("#ffe4ee"), 0.11, "DisplayGlass")


func _animate(t: float, delta: float) -> void:
	if _turntable:
		_turntable.rotation.y = sin(t * 0.35) * 1.15
	if _bunting:
		_bunting.rotation.z = sin(t * 1.1) * 0.012
	if _mannequin:
		_mannequin.tick(delta, 0.0)
		_outfit_timer += delta
		if _outfit_timer >= OUTFIT_SECONDS:
			_outfit_timer = 0.0
			_next_outfit()


# ----------------------------------------------------------------------------- shop flow
func _on_door(player: Node3D) -> void:
	if not begin_flow(player):
		return
	await say(KEEPER, [
		"Darling! Look at you. Look at that helmet.",
		"Come in, I have new arrivals from three planets.",
	], "astro", STELLA_ACCENT)
	while true:
		var choice: int = await ask("Shall we dress you up?", ["Browse", "Leave"])
		if choice != 0:
			break
		await _browse()
	await say(KEEPER, ["Wear it well, darling. Off you go!"], "astro", STELLA_ACCENT)
	AudioManager.play_sfx("door_close", -8.0)
	end_flow()


func _browse() -> void:
	var panel := shop()
	if panel == null:
		await say(KEEPER, ["The rack is out for cleaning. Come back soon!"], "astro", STELLA_ACCENT)
		return
	var bought: Array[String] = []
	var on_buy := func(item_id: String) -> void:
		bought.append(item_id)
		_wear(item_id)
	panel.purchased.connect(on_buy)
	panel.open(Catalog.store_items("clothing"), "buy", SHOP_TITLE, KEEPER)
	await panel.closed
	if panel.purchased.is_connected(on_buy):
		panel.purchased.disconnect(on_buy)
	await get_tree().process_frame
	if not bought.is_empty():
		var def: Dictionary = Catalog.get_item(bought.back())
		await say(KEEPER, [
			"The %s! Oh, that is SO you." % str(def.get("name", "new look")),
			"Twirl for me. ... Perfect.",
		], "astro", STELLA_ACCENT)


## Adds a garment to the wardrobe and puts it on right away.
func _wear(item_id: String) -> void:
	var def: Dictionary = Catalog.get_item(item_id)
	if def.is_empty():
		return
	if not GameState.wardrobe.has(item_id):
		GameState.wardrobe.append(item_id)
	var style: Dictionary = def.get("style", {})
	for k: Variant in style.keys():
		GameState.player_style[k] = style[k]
	EventBus.player_style_changed.emit()
	toast("Now wearing the %s!" % str(def.get("name", "new outfit")), item_id)
