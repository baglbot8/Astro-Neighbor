extends Building
## Cosmo Depot — the decoration store. A boxy-rounded shopfront in cream and burnt orange with a
## striped barrel awning, a big display window with three decorations turning slowly on a turntable,
## a rooftop satellite dish that sweeps, a sign that glows after dusk, and crates stacked outside.
##
## Door -> Pip & Pop: buy from the daily stock, sell from your bag, or leave.
## Daily stock = 8 decorations picked from a seed of GameState.day_count, plus the 3 cheapest
## (so there is always something a broke astronaut can afford).

const SHOP_TITLE := "Cosmo Depot"
const KEEPER := "Pip & Pop"
const ALIEN_ACCENT := Color("#7ad9a0")
const DAILY_PICKS := 8
const ALWAYS_STOCKED := 3

const ORANGE := Color("#bd6242")
const ORANGE_LIT := Color("#d1794b")
const STRIPE_CREAM := Color("#f0e3c6")
const APRON := 0.16             # top of the shop's stone apron
const BODY_TOP := 3.45
const FACE_Z := -2.12           # front facade plane
const NICHE_Z := -1.58          # back of the display niche
const WIN_X := -1.10
const WIN_W := 2.90
const WIN_BOT := 0.44
const WIN_TOP := 2.44
const DOOR_X := 1.52
const DOOR_W := 1.22
const DOOR_H := 2.08
const DISH_POS := Vector3(-1.55, BODY_TOP + 0.30, 0.95)

var _turntable: Node3D
var _dish_yaw: Node3D
var _dish_tilt: Node3D
var _shop_open := false


func _init() -> void:
	building_id = "deco_store"
	display_name = SHOP_TITLE
	ground_sink = 0.16
	ground_radius = 26.0
	# an ankle-height point out on the doorstep: the shopkeeper NPCs stand ~3 m in front of the
	# shop, and the player picks the CLOSEST interactable, so the door has to meet them at the step
	door_local = Vector3(DOOR_X, 0.35, FACE_Z - 1.25)
	door_prompt = "Enter"


func _footprint_shapes() -> Array:
	return [
		[_box(Vector3(5.5, 4.2, 4.3)), Vector3(0.0, 2.0, 0.0)],
		Building.step_block(2.4, FACE_Z, -3.15, 0.55),
	]


func _box(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


# R2.9: the shell is split by material. A boxy painted shopfront wants the plaster preset with no
# seams (an ACNH shop is smooth render, its structure carried by the base band, the frames and the
# fascia); the awnings want cloth with stitched panel seams; the door and the crates want timber.
#
# The awning seam pitch is set to the STRIPE pitch - 7 stripes over 3.30 m - so the seams read as
# the joins between the sewn panels rather than as an unrelated second rhythm. A 0.47 m panel is
# 82 px at the door and 19 px from across the plaza, which is why this is the term that survives.
const AWNING_OPTS := {"pitch_b": 2.12, "seam_strength": 1.5}


func _build() -> void:
	var kit := DecoKit.new()        # painted render, stone apron, frames, roof, sign plate
	var wood := DecoKit.new()       # door leaf and the supply crates
	var cloth := DecoKit.new()      # the two striped awnings
	var metal := DecoKit.new()      # sign hangers, bolt heads, the door knob
	var deco := DecoKit.new()       # planters (R2.9 exempts small props)
	_build_shell(kit)
	_build_facade(kit, wood, cloth, metal)
	_build_roof(kit, wood, metal)
	_build_yard(wood, deco)
	add_wall(kit.commit(), "Walls")
	# Crate boards and the door's planks both run vertically in model space, and the crates are
	# only yawed, so +Y is every plank's own long axis here.
	add_wood(wood.commit(), Vector3.UP, "Timber")
	add_cloth(cloth.commit(), "Awnings", AWNING_OPTS)
	add_metal(metal.commit(), "Hardware")
	add_body(deco.commit(), "Planters")
	_build_dish()
	_build_display()
	_build_glow()
	animate()


func _build_shell(kit: DecoKit) -> void:
	# buried stone apron
	kit.rbox(Vector3(0.0, -0.34, -0.10), Vector3(5.5, 1.0, 4.5), 0.10, STONE_DEEP, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, APRON - 0.09, -0.10), Vector3(5.36, 0.18, 4.36), 0.05, STONE, Basis.IDENTITY, 0)
	# main mass, its front face recessed to make the display niche
	kit.rbox(Vector3(0.0, (BODY_TOP + APRON) * 0.5, 0.16), Vector3(5.2, BODY_TOP - APRON, 3.48), 0.26, CREAM, Basis.IDENTITY, 1)
	# burnt-orange base band: a crisp horizontal plane break and a real dark tone
	kit.rbox(Vector3(0.0, APRON + 0.36, 0.20), Vector3(5.26, 0.74, 3.40), 0.10, ORANGE, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, APRON + 0.75, 0.20), Vector3(5.30, 0.07, 3.44), 0.03, CREAM_LIT, Basis.IDENTITY, 0)
	# niche back wall, floor and cheeks
	kit.rbox(Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, NICHE_Z + 0.10), Vector3(WIN_W + 0.24, WIN_TOP - WIN_BOT + 0.22, 0.26), 0.03, Color("#f2e7cc"), Basis.IDENTITY, 0)
	kit.rbox(Vector3(WIN_X, WIN_BOT + 0.05, (NICHE_Z + FACE_Z) * 0.5), Vector3(WIN_W - 0.1, 0.10, 0.60), 0.02, Color("#d9c49a"), Basis.IDENTITY, 0)
	kit.rbox(Vector3(WIN_X, WIN_TOP - 0.04, (NICHE_Z + FACE_Z) * 0.5), Vector3(WIN_W - 0.1, 0.08, 0.60), 0.02, Color("#e6d8b8"), Basis.IDENTITY, 0)


func _build_facade(kit: DecoKit, wood: DecoKit, cloth: DecoKit, metal: DecoKit) -> void:
	var h := BODY_TOP - APRON
	var cy := (BODY_TOP + APRON) * 0.5
	var fz := (FACE_Z + NICHE_Z) * 0.5
	var fd := NICHE_Z - FACE_Z
	# facade built as four pieces so the display window is a real opening
	kit.rbox(Vector3(-2.62, cy, fz), Vector3(0.30, h, fd), 0.07, CREAM_LIT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(1.44, cy, fz), Vector3(2.42, h, fd), 0.07, CREAM_LIT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(WIN_X, (WIN_TOP + BODY_TOP) * 0.5, fz), Vector3(WIN_W, BODY_TOP - WIN_TOP, fd), 0.06, CREAM_LIT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(WIN_X, (WIN_BOT + APRON) * 0.5, fz), Vector3(WIN_W, WIN_BOT - APRON, fd), 0.06, CREAM_LIT, Basis.IDENTITY, 0)
	# chunky window frame + sill
	build_window_frame(kit, Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, FACE_Z - 0.06), WIN_W, WIN_TOP - WIN_BOT,
			0.22, 0.22, CREAM_LIT)
	kit.rbox(Vector3(WIN_X, WIN_BOT - 0.22, FACE_Z - 0.11), Vector3(WIN_W + 0.62, 0.16, 0.38), 0.05, CREAM_DEEP, Basis.IDENTITY, 0)
	# door and steps
	build_door(kit, Vector3(DOOR_X, APRON, FACE_Z), DOOR_W, DOOR_H, CREAM_LIT, WOOD, WOOD_DARK, wood, metal)
	build_steps(kit, 2.05, FACE_Z, 0.95, APRON, 0.14, DOOR_X)
	# striped awning over the display window only, the way an AC stall shades its goods
	build_awning(cloth, 3.30, 0.92, 2.60, FACE_Z - 0.02, 7, ORANGE_LIT, STRIPE_CREAM, ORANGE.darkened(0.12), WIN_X)
	# matching little awning over the door
	build_awning(cloth, 1.86, 0.62, APRON + DOOR_H + 0.52, FACE_Z - 0.02, 3, ORANGE_LIT, STRIPE_CREAM, ORANGE.darkened(0.12), DOOR_X)


func _build_roof(kit: DecoKit, wood: DecoKit, metal: DecoKit) -> void:
	kit.rbox(Vector3(0.0, BODY_TOP + 0.10, 0.16), Vector3(5.46, 0.30, 3.74), 0.07, CREAM_DEEP, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, BODY_TOP + 0.27, 0.16), Vector3(5.20, 0.07, 3.48), 0.03, ORANGE, Basis.IDENTITY, 0)
	# clerestory box: breaks the silhouette so the shop is not one flat brick
	kit.rbox(Vector3(0.35, BODY_TOP + 0.66, 0.55), Vector3(3.00, 0.80, 2.10), 0.16, CREAM_LIT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.35, BODY_TOP + 1.10, 0.55), Vector3(3.20, 0.16, 2.30), 0.05, ORANGE, Basis.IDENTITY, 0)
	# hanging sign under the roof edge, clear above the awning
	var plate := build_hanging_sign(kit, Vector3(-0.30, BODY_TOP - 0.02, FACE_Z - 0.24), 3.00, 0.66,
			STRIPE_CREAM, ORANGE, 0.0, 0.22, wood, metal)
	add_label("COSMO DEPOT", plate + Vector3(0.0, 0.0, -0.13), 0.29)
	set_meta("sign_plate", plate)


func _build_yard(wood: DecoKit, deco: DecoKit) -> void:
	build_planter(deco, Vector3(2.62, ground_y(3.7) - 0.02, -2.62), 1.05)
	build_planter(deco, Vector3(-2.55, ground_y(3.5) - 0.02, -2.35), 0.95, TERRACOTTA.darkened(0.08))
	# supply crates stacked by the window - sawn boards, so they go to the timber material
	_crate(wood, Vector3(-2.96, ground_y(4.2) - 0.02, -2.98), 0.80, Color("#c99a5c"), -16.0)
	_crate(wood, Vector3(-2.88, ground_y(4.2) + 0.78, -2.94), 0.54, Color("#7fb8b4"), 12.0)
	_crate(wood, Vector3(-2.10, ground_y(4.0) - 0.02, -3.36), 0.66, Color("#b08248"), 26.0)


## A chunky wooden crate with a lid rim and cross battens.
func _crate(kit: DecoKit, at: Vector3, s: float, tint: Color, yaw_deg: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw_deg))
	kit.rbox(at + Vector3(0.0, s * 0.5, 0.0), Vector3(s, s, s), s * 0.10, tint, b, 0)
	kit.rbox(at + Vector3(0.0, s * 1.0, 0.0), Vector3(s * 1.08, s * 0.10, s * 1.08), s * 0.04, tint.darkened(0.20), b, 0)
	for sx in [-1.0, 1.0]:
		kit.rbox(at + b * Vector3(0.0, s * 0.5, s * 0.52 * sx), Vector3(s * 0.96, s * 0.11, 0.02), 0.01, tint.darkened(0.26), b, 0)
		kit.rbox(at + b * Vector3(s * 0.52 * sx, s * 0.5, 0.0), Vector3(0.02, s * 0.11, s * 0.96), 0.01, tint.darkened(0.26), b, 0)


# ----------------------------------------------------------------------------- animated parts
func _build_dish() -> void:
	_dish_yaw = pivot("DishYaw", DISH_POS)
	_dish_tilt = pivot("DishTilt", Vector3(0.0, 0.62, 0.0), _dish_yaw)
	var mast := DecoKit.new()
	mast.cone(Vector3(0.0, -0.30, 0.0), 0.16, 0.11, 0.62, METAL, Basis.IDENTITY, 12)
	mast.torus(Vector3(0.0, -0.26, 0.0), 0.19, 0.05, METAL_DARK, Basis.IDENTITY, 14)
	add_metal(mast.commit(), "DishMast", _dish_yaw)
	var dish := DecoKit.new()
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-38.0))
	dish.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.28, 0.05), Vector2(0.50, 0.16), Vector2(0.66, 0.32),
			Vector2(0.70, 0.34), Vector2(0.53, 0.20), Vector2(0.30, 0.09), Vector2(0.0, 0.04)]),
			20, Transform3D(tilt, Vector3.ZERO), Color("#eae2d2"))
	dish.bar(Vector3.ZERO, tilt * Vector3(0.0, 0.42, 0.0), 0.035, METAL_DARK, 6)
	dish.sphere(tilt * Vector3(0.0, 0.42, 0.0), 0.075, ORANGE_LIT, Vector3.ONE, 10)
	add_metal(dish.commit(), "Dish", _dish_tilt)


## Three decorations turning slowly in the window. Falls back to procedural props when the
## decoration catalog has not landed yet.
func _build_display() -> void:
	_turntable = pivot("Turntable", Vector3(WIN_X, WIN_BOT + 0.10, (NICHE_Z + FACE_Z) * 0.5 + 0.06))
	var base := DecoKit.new()
	base.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.18, 0.0), Vector2(1.14, 0.07), Vector2(0.0, 0.09)]),
			26, Transform3D.IDENTITY, Color("#b8875a"))
	add_body(base.commit(), "TurntableTop", _turntable)

	var picks := _display_items()
	for i in 3:
		var slot := pivot("Slot%d" % i, Vector3(cos(TAU * float(i) / 3.0) * 0.72, 0.09, sin(TAU * float(i) / 3.0) * 0.72), _turntable)
		if i < picks.size():
			_mount_decoration(slot, str(picks[i]))
		else:
			_fallback_prop(slot, i)


func _display_items() -> Array:
	# small, everyday goods: a shop window shows things you can actually afford, and the modest
	# items have no sweeping beams or particle plumes to escape the case
	var pool: Array = Catalog.items_of_kind("decoration").filter(
			func(d: Dictionary) -> bool:
				return ResourceLoader.exists(str(d.get("scene", ""))) \
					and float(d.get("footprint", 1.0)) <= 0.85 \
					and str(d.get("rarity", "common")) in ["common", "uncommon"])
	if pool.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["window", GameState.day_count])
	var ids: Array = []
	var used: Dictionary = {}
	for attempt in 24:
		if ids.size() >= 3:
			break
		var d: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var id := str(d.get("id", ""))
		if used.has(id):
			continue
		used[id] = true
		ids.append(str(d.get("scene", "")))
	return ids


func _mount_decoration(slot: Node3D, scene_path: String) -> void:
	var inst: Node = load(scene_path).instantiate()
	slot.add_child(inst)
	if inst is Node3D:
		(inst as Node3D).scale = Vector3.ONE * 0.34
	# props in a shop window must never block the player or light up the plaza
	_neutralise(inst)


## Turns a decoration into a shop-window display copy: no collision, no lights cast into the plaza,
## no light beams or particle plumes escaping the case, and every emissive part switched to its
## night look so the goods read as lit merchandise rather than dark props behind glass.
func _neutralise(n: Node) -> void:
	if n is CollisionObject3D:
		(n as CollisionObject3D).collision_layer = 0
		(n as CollisionObject3D).collision_mask = 0
	if n is Light3D:
		(n as Light3D).visible = false
		(n as Light3D).light_energy = 0.0
	if n is Interactable:
		(n as Interactable).enabled = false
	if n is GPUParticles3D:
		(n as GPUParticles3D).emitting = false
		(n as GPUParticles3D).visible = false
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var sm := mi.material_override as StandardMaterial3D
		# additive beams, ground-glow pools and invisible beam cones belong outdoors, not in a case
		if sm != null and (sm.blend_mode == BaseMaterial3D.BLEND_MODE_ADD
				or (sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and sm.albedo_color.a < 0.06)):
			mi.visible = false
		else:
			mi.set_instance_shader_parameter("night_mix", 1.0)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_neutralise(c)


func _fallback_prop(slot: Node3D, i: int) -> void:
	var kit := DecoKit.new()
	match i:
		0:
			kit.cone(Vector3(0.0, 0.0, 0.0), 0.13, 0.10, 0.30, Color("#b8623f"), Basis.IDENTITY, 12)
			kit.lobed_dome(Vector3(0.0, 0.30, 0.0), 0.20, 0.17, LEAF, LEAF_UNDER, 6, 0.14, 0.72, 0.0, 16, 3, 0.02)
		1:
			kit.rbox(Vector3(0.0, 0.20, 0.0), Vector3(0.36, 0.40, 0.36), 0.06, Color("#c99a5c"), Basis.IDENTITY, 0)
			kit.rbox(Vector3(0.0, 0.41, 0.0), Vector3(0.40, 0.06, 0.40), 0.02, Color("#9c7340"), Basis.IDENTITY, 0)
		_:
			kit.cone(Vector3(0.0, 0.0, 0.0), 0.10, 0.06, 0.34, METAL, Basis.IDENTITY, 10)
			kit.sphere(Vector3(0.0, 0.44, 0.0), 0.14, Color("#ffe27a"), Vector3(1.0, 1.1, 1.0), 14)
	add_body(kit.commit(), "Prop%d" % i, slot)


func _build_glow() -> void:
	var glow := DecoKit.new()
	# a warm halo BEHIND the sign plate, never in front of the lettering
	var plate: Vector3 = get_meta("sign_plate", Vector3(-0.30, 2.7, FACE_Z - 0.4))
	glow.extrude(DecoKit.round_rect_poly(3.24, 0.92, 0.16, 5), 0.05, Color("#ffcf82"),
			Transform3D(Basis.IDENTITY, plate + Vector3(0.0, 0.0, 0.10)))
	add_glow(glow.commit(), 2.2, "SignGlow", 0.0, 0.0)

	# display case light: a glowing ceiling panel and a warm back wall, on at every hour, so the
	# window is never a dark hole. No lamp goes inside the case (see the note above).
	var strip := DecoKit.new()
	strip.rbox(Vector3(WIN_X, WIN_TOP - 0.10, (NICHE_Z + FACE_Z) * 0.5 + 0.04), Vector3(WIN_W - 0.34, 0.07, 0.50), 0.025, Color("#fff3d6"), Basis.IDENTITY, 0)
	strip.rbox(Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, NICHE_Z + 0.02), Vector3(WIN_W - 0.22, WIN_TOP - WIN_BOT - 0.14, 0.05), 0.02, Color("#f6e2b6"), Basis.IDENTITY, 0)
	var strip_mi := add_glow(strip.commit(), 1.15, "CaseLight", 0.0, 0.0)
	strip_mi.set_instance_shader_parameter("force_on", 1.0)
	# The case lamp is buried deep inside the shop body: a lamp in open air renders a dark sphere
	# at its own position (see Building.add_light), and lights here cast no shadows, so a lamp
	# inside the wall lights the goods exactly the same.
	add_interior_light(Vector3(WIN_X, 1.60, -0.90), Color("#fff0dc"), 2.6, 4.4)

	var panes := DecoKit.new()
	for i in 3:
		var x: float = -1.3 + float(i) * 1.3
		panes.rbox(Vector3(x, BODY_TOP + 0.62, 0.55 - 1.06), Vector3(0.62, 0.42, 0.06), 0.05, WINDOW_WARM, Basis.IDENTITY, 0)
	add_glow(panes.commit(), 1.35, "Clerestory", 0.0, 0.0, 1.0)

	# sign lamp, buried in the roof parapet
	add_light(Vector3(-0.30, BODY_TOP + 0.10, 0.16), Color("#ffd9a0"), 1.6, 7.5)

	# display glass, last so it draws over the props
	var glass := DecoKit.new()
	glass.rbox(Vector3(WIN_X, (WIN_TOP + WIN_BOT) * 0.5, FACE_Z - 0.02), Vector3(WIN_W - 0.06, WIN_TOP - WIN_BOT - 0.06, 0.03), 0.02, Color.WHITE, Basis.IDENTITY, 0)
	add_glass(glass.commit(), Color("#cfe8ff"), 0.13, "DisplayGlass")


func _animate(t: float, _delta: float) -> void:
	if _turntable:
		_turntable.rotation.y = t * 0.42
	if _dish_yaw:
		_dish_yaw.rotation.y = sin(t * 0.22) * 0.9
	if _dish_tilt:
		_dish_tilt.rotation.x = sin(t * 0.15) * 0.10


# ----------------------------------------------------------------------------- shop flow
func _on_door(player: Node3D) -> void:
	if not begin_flow(player):
		return
	await say(KEEPER, [
		"Welcome to Cosmo Depot! I'm Pip...",
		"...and I'm Pop! We sell EVERYTHING. Almost.",
	], "alien", ALIEN_ACCENT)
	while true:
		var choice: int = await ask("What'll it be?", ["Buy", "Sell", "Leave"])
		if choice == 0:
			await _open_shop(daily_stock(), "buy")
		elif choice == 1:
			await _open_shop([], "sell")
		else:
			break
	await say(KEEPER, ["Come back tomorrow — the stock rotates!"], "alien", ALIEN_ACCENT)
	AudioManager.play_sfx("door_close", -8.0)
	end_flow()


func _open_shop(items: Array, mode: String) -> void:
	var panel := shop()
	if panel == null:
		await say(KEEPER, ["Oh dear, the till is broken. Try again later!"], "alien", ALIEN_ACCENT)
		return
	_shop_open = true
	panel.open(items, mode, SHOP_TITLE, KEEPER)
	await panel.closed
	_shop_open = false
	await get_tree().process_frame


## Eight decorations seeded by the day, plus the three cheapest so there is always something
## affordable. Ordered cheapest first, the way a friendly shop lays out its shelves.
func daily_stock() -> Array:
	var pool: Array = Catalog.store_items("decoration")
	if pool.size() <= DAILY_PICKS + ALWAYS_STOCKED:
		return pool
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("price", 0)) < int(b.get("price", 0)))
	var chosen: Array = []
	var used: Dictionary = {}
	for i in ALWAYS_STOCKED:
		chosen.append(pool[i])
		used[str(pool[i].get("id", ""))] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["cosmo_depot", GameState.day_count])
	var guard := 0
	while chosen.size() < DAILY_PICKS + ALWAYS_STOCKED and guard < 200:
		guard += 1
		var d: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var id := str(d.get("id", ""))
		if used.has(id):
			continue
		used[id] = true
		chosen.append(d)
	chosen.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("price", 0)) < int(b.get("price", 0)))
	return chosen
