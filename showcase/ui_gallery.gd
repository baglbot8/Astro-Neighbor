extends Node3D
## UI showcase: the HUD over a REAL gameplay frame, driving every widget on a fixed schedule.
## Pair with tests/director/ui_gallery.json (taps that advance dialogue, pick a choice, navigate the
## bag / shop / pause menu):
##   tools/capture.sh showcase/ui_gallery.tscn ui 600 tests/director/ui_gallery.json
## Timings here and in the JSON are aligned; the whole tour fits in 20 s.
##
## THE BACKDROP IS THE ACTUAL GAME (docs/AGENT_WORKFLOW.md, "your showcase MUST match gameplay
## lighting"). This scene used to paint its own 2D meadow: an earth-blue #4fa8ff gradient with three
## grape-cluster cloud puffs and #7ed957 grass — every single thing R2.1 and R2.6 banned, and a lie
## to tune cream panel values against. It now assembles the same nodes as src/world/world.gd, with
## the same names ("World" root, Planet / Environment / Player / CameraRig / HUD), so a capture here
## is lit, framed and coloured exactly like the shipping game and `tools/palette.py` lands in the
## same band. `--planet=<id>` and `--time=<h>` work here as they do in the real world scene.

const PLANET_SCENE := "res://src/planet/planet.tscn"
const ENV_SCENE := "res://src/world/environment.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"
const CAMERA_SCENE := "res://src/player/camera_rig.tscn"
const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
## Backdrop planet for the tour (the Director's --planet flag overrides it).
const DEFAULT_PLANET := "home"

## Fake catalog entries so the bag and shop have variety before the decoration/hub builders land.
const DEMO_ITEMS := [
	{"id": "deco_moon_lamp", "name": "Moon Lamp", "kind": "decoration", "category": "lights", "rarity": "rare", "price": 240, "desc": "A soft glowing moon on a stick. Moths from three planets love it.", "icon_color": "#f7e27a", "footprint": 0.8},
	{"id": "deco_star_flag", "name": "Star Flag", "kind": "decoration", "category": "signs", "rarity": "common", "price": 60, "desc": "Plant it anywhere to claim the spot as yours.", "icon_color": "#ff7a59", "footprint": 0.5},
	{"id": "deco_crater_bench", "name": "Crater Bench", "kind": "decoration", "category": "furniture", "rarity": "common", "price": 120, "desc": "Carved from a friendly meteorite. Seats two and a half.", "icon_color": "#d9b98a", "footprint": 1.2},
	{"id": "deco_rocket_planter", "name": "Rocket Planter", "kind": "decoration", "category": "plants", "rarity": "uncommon", "price": 150, "desc": "A retired rocket nose full of moon ferns.", "icon_color": "#7ed957", "footprint": 0.7},
	{"id": "deco_holo_screen", "name": "Holo Screen", "kind": "decoration", "category": "tech", "rarity": "rare", "price": 320, "desc": "Plays cartoons from a galaxy far, far away.", "icon_color": "#6fc3ff", "footprint": 1.0},
	{"id": "deco_bouncy_asteroid", "name": "Bouncy Asteroid", "kind": "decoration", "category": "fun", "rarity": "uncommon", "price": 90, "desc": "Boing! Extremely bouncy. Do not stack.", "icon_color": "#b58cff", "footprint": 0.9},
	{"id": "deco_neon_sign", "name": "Neon Sign", "kind": "decoration", "category": "signs", "rarity": "rare", "price": 260, "desc": "Buzzes gently. Says OPEN, even at night.", "icon_color": "#ff6b9d", "footprint": 0.6},
	{"id": "deco_gear_chair", "name": "Gear Chair", "kind": "decoration", "category": "furniture", "rarity": "uncommon", "price": 180, "desc": "Bolt's favourite. Spins if you ask nicely.", "icon_color": "#ffb05c", "footprint": 0.8},
	{"id": "deco_comet_lamp", "name": "Comet Lamp", "kind": "decoration", "category": "lights", "rarity": "legendary", "price": 480, "desc": "A captured comet tail, still a little warm.", "icon_color": "#7fffd4", "footprint": 0.8},
	{"id": "suit_sunset", "name": "Sunset Suit", "kind": "clothing", "category": "suit", "rarity": "uncommon", "price": 200, "desc": "Warm orange with cream trim.", "icon_color": "#ff7a59", "style": {"suit_color": "#ff7a59"}},
	{"id": "hat_antenna", "name": "Antenna Cap", "kind": "clothing", "category": "hat", "rarity": "rare", "price": 140, "desc": "Picks up radio from Zorp's home world.", "icon_color": "#7fd8d0", "style": {"hat_id": "hat_antenna"}},
	{"id": "pack_jet", "name": "Jet Pack", "kind": "clothing", "category": "backpack", "rarity": "rare", "price": 300, "desc": "Purely decorative. Mostly.", "icon_color": "#8fa3bf", "style": {"backpack_id": "pack_jet"}},
]

const SHOP_STOCK := ["deco_comet_lamp", "deco_holo_screen", "deco_bouncy_asteroid", "deco_crater_bench",
	"deco_neon_sign", "deco_moon_lamp", "deco_gear_chair", "deco_rocket_planter"]

## "tour" = the full widget tour (default). "stress" = edge cases: empty bag, sell mode with the bag,
## gamepad glyphs forced on, a long 3-line dialogue with a 4-way choice (showcase/ui_stress.tscn).
## "glyphs" = a static wall of every catalogued item icon so the id-keyword glyph variants can be
## checked side by side (showcase/ui_glyphs.tscn).
@export var variant: String = "tour"

## Columns / cell size of the "glyphs" wall.
const GLYPH_COLUMNS := 10
const GLYPH_CELL := Vector2(126.0, 118.0)
const GLYPH_SIZE := 62.0

var _hud: Hud
var _t := 0.0
var _steps: Array = []
var _next := 0
var planet: Planet
var player: Node3D
## CanvasLayer the showcase's own 2D overlays (the glyph wall) live on, below the HUD's layer 10.
var _overlay: Control

func _ready() -> void:
	# Node names match src/world/world.gd so Director timelines address the same paths.
	name = "World"
	# `--window=1920x1080` (user arg) resizes the window so captures can verify the UI at other resolutions.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--window="):
			var parts := a.substr(9).split("x")
			if parts.size() == 2:
				get_window().size = Vector2i(int(parts[0]), int(parts[1]))
	for def in DEMO_ITEMS:
		Catalog.register(def)
	# reset_new_game() forces current_planet_id back to "home", so remember what the Director asked
	# for (--planet) and put it back afterwards.
	var pid := GameState.current_planet_id
	var clock := GameState.time_of_day
	GameState.reset_new_game()
	GameState.current_planet_id = pid if pid != "" else DEFAULT_PLANET
	GameState.time_of_day = clock
	_build_world()
	if variant == "glyphs":
		_setup_glyph_wall()
		return
	if variant == "stress":
		_setup_stress()
		return
	GameState.add_item("deco_rocket_planter", 2)
	GameState.add_item("deco_holo_screen", 1)
	GameState.add_item("deco_bouncy_asteroid", 1)
	GameState.add_item("suit_sunset", 1)
	GameState.add_item("hat_antenna", 1)
	GameState.add_item("pack_jet", 1)
	GameState.add_item("stardust_shard", 14)
	GameState.add_item("gear_bit", 3)
	GameState.add_item("crystal_chunk", 2)
	GameState.time_of_day = 9.5
	_hud = HUD_SCENE.instantiate()
	_hud.name = "HUD"
	add_child(_hud)
	_steps = [
		[0.4, func() -> void: EventBus.planet_loaded.emit(GameState.current_planet_id)],
		[1.2, func() -> void: GameState.add_stardust(12)],
		[1.7, func() -> void: EventBus.toast_requested.emit("You got a Moon Lamp!", "deco_moon_lamp")],
		[2.1, func() -> void: EventBus.interact_prompt_changed.emit("Talk")],
		[2.3, func() -> void: EventBus.time_of_day_changed.emit(14.5)],
		[3.2, _run_dialogue],
		[11.0, func() -> void: _hud.inventory.open("all")],
		[14.0, func() -> void: _hud.shop_panel.open(SHOP_STOCK, "buy", "Cosmo Depot", "Pip & Pop, shopkeepers")],
	]

# ----------------------------------------------------------------------------- the real backdrop
## Assembles the shipping planet + environment + player + camera, exactly as src/world/world.gd
## does, so this showcase is lit and framed like the game (docs/AGENT_WORKFLOW.md).
func _build_world() -> void:
	var pid := GameState.current_planet_id
	var data_path := "res://src/planet/data/%s.tres" % pid
	var data: PlanetData = load(data_path) if ResourceLoader.exists(data_path) else PlanetData.new()
	planet = load(PLANET_SCENE).instantiate() if ResourceLoader.exists(PLANET_SCENE) else Planet.new()
	planet.name = "Planet"
	planet.data = data
	add_child(planet)
	_spawn_optional(ENV_SCENE, "Environment")
	_spawn_player(data)
	_spawn_optional(CAMERA_SCENE, "CameraRig")
	# Overlay layer for the showcase's own 2D sheets. Below the HUD's layer 10.
	var layer := CanvasLayer.new()
	layer.name = "ShowcaseOverlay"
	layer.layer = 4
	add_child(layer)
	_overlay = Control.new()
	_overlay.name = "Root"
	_overlay.theme = UIStyle.theme()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)

func _spawn_optional(path: String, node_name: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var n: Node = load(path).instantiate()
	n.name = node_name
	add_child(n)
	return n

func _spawn_player(data: PlanetData) -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		return
	player = load(PLAYER_SCENE).instantiate()
	player.name = "Player"
	add_child(player)
	if player is PlanetBody:
		player.planet = planet
		player.place_on_planet(data.spawn_dir.normalized())
	EventBus.player_spawned.emit(player)

## Edge cases: starts with an EMPTY bag (opened at 0.6 s), then fills it and opens the shop in sell mode,
## then a maximal 3-line dialogue with a 4-way choice. Gamepad glyphs are forced so the controller look shows.
func _setup_stress() -> void:
	GameState.inventory = {}
	KeyGlyph.force_gamepad_all = 1
	_hud = HUD_SCENE.instantiate()
	_hud.name = "HUD"
	add_child(_hud)
	_steps = [
		[0.6, func() -> void: _hud.inventory.open("all")],
		[3.4, func() -> void: _hud.inventory.close()],
		[3.8, func() -> void:
			GameState.add_item("deco_moon_lamp", 2)
			GameState.add_item("deco_gear_chair", 1)
			GameState.add_item("suit_sunset", 1)
			GameState.add_item("stardust_shard", 5)
			_hud.shop_panel.open([], "sell", "Cosmo Depot", "Buying back at 40%")],
		[8.0, func() -> void: _hud.shop_panel.close_panel()],
		[8.6, func() -> void:
			_hud.dialogue_box.show_lines("Mayor Orbit", [
				"Welcome, welcome! I am Mayor Orbit, keeper of the plaza, counter of comets, and very slow walker.",
				"The Town Hall can rename your planet, and the bulletin lists everything that happened today.",
				"Now then. Would you like to hear the rules? There are only forty-two.",
			], "elder", Color("#ff9f43"))],
		[16.0, func() -> void: _hud.dialogue_box.show_choice("Hear the rules?", ["Yes please", "Just the first one", "Maybe tomorrow", "Absolutely not"])],
	]

## Static sheet of every catalogued item icon plus two uncatalogued ids, so the id-keyword glyph
## table (ItemGlyph.ID_GLYPHS) and the warm fallback swatch can be reviewed in one frame.
func _setup_glyph_wall() -> void:
	var ids: Array = []
	for def in Catalog.all_items():
		ids.append(str(def.get("id", "")))
	ids.sort()
	# Two ids the Catalog does not know: they must still get a warm swatch and a matching glyph
	# (ItemGridPanel.def_for -> ItemGlyph.category_for_id / fallback_color). Shown first.
	ids.push_front("deco_mystery_rack")
	ids.push_front("deco_future_mailbox")
	var panel := Panel.new()
	panel.theme_type_variation = "Modal"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 12.0
	panel.offset_top = 12.0
	panel.offset_right = -12.0
	panel.offset_bottom = -12.0
	_overlay.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = maxi(GLYPH_COLUMNS, int((float(get_window().size.x) - 64.0) / GLYPH_CELL.x))
	grid.position = Vector2(20.0, 16.0)
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	panel.add_child(grid)
	for id in ids:
		var cell := Control.new()
		cell.custom_minimum_size = GLYPH_CELL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(cell)
		var g := ItemGlyph.new()
		g.position = Vector2((GLYPH_CELL.x - GLYPH_SIZE) * 0.5, 4.0)
		g.size = Vector2(GLYPH_SIZE, GLYPH_SIZE)
		g.set_def(ItemGridPanel.def_for(str(id)))
		cell.add_child(g)
		var l := UIStyle.make_label(UIStyle.pretty_id(str(id)), "CardName", HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(4.0, GLYPH_SIZE + 8.0)
		l.size = Vector2(GLYPH_CELL.x - 8.0, 40.0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.max_lines_visible = 2
		l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		cell.add_child(l)

func _exit_tree() -> void:
	KeyGlyph.force_gamepad_all = -1

func _run_dialogue() -> void:
	var box := _hud.dialogue_box
	EventBus.interact_prompt_changed.emit("")
	await box.show_lines("Zorp", [
		"Oh! An Earth creature! Do you photosynthesize?",
		"My antenna says a comet passed by last night.",
		"Stardust everywhere! Want to help me collect some?",
	], "alien", Color("#8a4fe8"))
	var choice: int = await box.show_choice("Help me collect stardust?", ["Of course!", "Maybe later.", "What's stardust?"])
	if choice == 0:
		EventBus.toast_requested.emit("Zorp is thrilled!", "heart")
	elif choice == 1:
		EventBus.toast_requested.emit("Zorp: \"Later is fine, friend!\"", "heart")
	else:
		EventBus.toast_requested.emit("Zorp explains stardust. At length.", "star")

func _process(delta: float) -> void:
	_t += delta
	while _next < _steps.size() and float(_steps[_next][0]) <= _t:
		var cb: Callable = _steps[_next][1]
		_next += 1
		cb.call()
