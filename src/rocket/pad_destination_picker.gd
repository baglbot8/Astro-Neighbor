class_name PadDestinationPicker
extends CanvasLayer
## "Where to?" — the destination is chosen ON THE PAD, before the rocket ever leaves the ground.
##
## The old flow put this choice in the solar-system map, which meant the trip had to stop dead in a
## separate screen half way through. Asking at the pad turns the whole flight into one uninterrupted
## move (docs/STYLE_GUIDE.md R2.5): you pick a world, you climb toward it, you land on it.
##
## THIS IS A MENU, AND IT HAS TO LOOK LIKE ONE. The first version of this card was wired correctly
## and still failed, because the player came away believing the game had picked a planet at random:
##
##   * it showed ONE destination at a time with three small dots as the only sign there were others,
##     so it read as a caption on a cutscene rather than as a choice;
##   * it sat low and centred, BEHIND the ghosted rocket and the astronaut, so it read as scenery;
##   * the player had just pressed E to interact and the natural next input is E again — which
##     launched immediately, to whatever happened to be showing. That is exactly "it just picks a
##     random planet";
##   * the walk keys double as the chooser, and nothing said the card was waiting for input.
##
## So, in order: every destination is on screen AT ONCE as its own tile, with a painted globe in the
## planet's real colour (Bolt keeps its ring) so the choice is visible as a choice; the selected
## tile is raised, brighter, ringed in yellow and carries the launch verb ITSELF; a dim scrim pushes
## the world back so the panel is unmistakably foreground UI; and `interact` is DEAD for
## ARM_SECONDS after the card opens, so the E that opened it can never also fly the rocket.
##
## Input is read directly rather than through Interactable because the pad raises the "cutscene"
## modal while this is open (so bag / decorate / pause cannot fire and strand the player mid-launch).
## `cancel` always closes it, so the modal can never outlive the card.

signal chosen(planet_id: String)
signal cancelled()

const EDGE := 22.0
const TILE := Vector2(196.0, 236.0)
const TILE_GAP := 14.0
const DISC := 84.0
const ORDER: Array[String] = ["home", "zorp", "bolt", "hub"]
## One line of flavour per world - the same copy the map card used.
const BLURB := {
	"home": "Home sweet orbit.",
	"zorp": "Zorp's violet world. Glowing rivers!",
	"bolt": "Bolt's chrome world. Mind the gears.",
	"hub": "Starport Plaza. Shops & town hall.",
}
## Seconds `interact` is ignored after the card opens. The player just pressed E to board; without
## this, pressing it again — the most natural thing in the world — launches before they have read
## anything, which is how the destination came to feel random.
const ARM_SECONDS := 0.5
## Scrim over the world. Enough to push the pad and the ghosted rocket behind the panel without
## hiding them: the rocket standing in front of you is half the charm of choosing here.
const SCRIM := Color(0.06, 0.05, 0.16, 0.46)

var _options: Array[String] = []
var _index := 0
var _tiles: Array[PanelContainer] = []
var _discs: Array[Control] = []
var _names: Array[Label] = []
var _launch_pills: Array[PanelContainer] = []
var _card: PanelContainer
var _scrim: ColorRect
var _desc_label: Label
var _hint: PanelContainer
var _armed := false
var _arm_timer := 0.0
var _closing := false


## `origin_id` is the planet we are standing on; every other world becomes an option.
func setup(origin_id: String) -> void:
	_options.clear()
	for id in ORDER:
		if id == origin_id:
			continue
		if ResourceLoader.exists("res://src/planet/data/%s.tres" % id):
			_options.append(id)


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_arm_timer = ARM_SECONDS
	if _options.is_empty():
		# Nowhere to go (a showcase with no PlanetData, a stripped build). `_process` bails on an
		# empty list, so without this the pad would sit `_busy` behind a cutscene modal the player
		# cannot dismiss — stranded on a rocket pad forever.
		_closing = true
		cancelled.emit.call_deferred()
		queue_free.call_deferred()
		return
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	add_child(root)

	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = SCRIM
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.modulate.a = 0.0
	root.add_child(_scrim)
	var fade := _scrim.create_tween()
	fade.tween_property(_scrim, "modulate:a", 1.0, 0.22)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 12)
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	column.offset_top = -470.0
	column.offset_bottom = -EDGE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)

	_card = PanelContainer.new()
	_card.name = "DestinationCard"
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_card.add_theme_stylebox_override("panel",
		UIStyle.make_panel_style(UIStyle.CREAM, UIStyle.RADIUS, UIStyle.CREAM_EDGE, 3, 16, 22.0))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(box)

	# "Where to?" is the question; "pick one" is the instruction. Both, because the whole failure
	# was a player who did not know they were being asked anything.
	var title := UIStyle.make_label("Where to?", "Header", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)

	var row := HBoxContainer.new()
	row.name = "Tiles"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(TILE_GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)

	row.add_child(_make_chevron("◀"))
	for i in _options.size():
		row.add_child(_make_tile(_options[i], i))
	row.add_child(_make_chevron("▶"))

	_desc_label = UIStyle.make_label("", "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(0.0, 24.0)
	box.add_child(_desc_label)

	_hint = PanelContainer.new()
	_hint.name = "Hint"
	_hint.theme_type_variation = "HudPillSoft"
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_child(UIStyle.make_label("◀ ▶ choose  ·  E launch  ·  Esc stay here", "Hint",
		HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_hint)

	_refresh()
	UIStyle.pop_in(_card, 0.32)


## A destination tile: painted globe, name, and — on the selected one — the launch verb itself.
func _make_tile(id: String, index: int) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.name = "Tile_" + id
	tile.custom_minimum_size = TILE
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	# The card is keyboard/pad driven, but a player who reads this as a menu may well reach for the
	# mouse, so a click selects and launches. Deliberately NOT on hover: the Director drives every
	# test with a cursor parked wherever the window opened, and a hover-select would let the mouse
	# silently change which planet a test timeline flies to.
	tile.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_select(index, true)
			_confirm())

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(inner)

	var disc := PlanetDisc.new()
	disc.custom_minimum_size = Vector2(DISC, DISC)
	disc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.apply(id)
	inner.add_child(disc)
	_discs.append(disc)

	var label := UIStyle.make_label(Hud.planet_display_name(id), "", HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_size_override("font_size", 19)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TILE.x - 26.0, 52.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	inner.add_child(label)
	_names.append(label)

	# The verb lives ON the choice, not only in the hint strip underneath: a player looking at the
	# highlighted tile can see what pressing E will do to THAT tile.
	var pill := PanelContainer.new()
	pill.name = "Launch"
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel",
		UIStyle.make_pill_style(UIStyle.YELLOW, UIStyle.YELLOW_EDGE, 3, 4, 16.0, 5.0))
	var pill_label := UIStyle.make_label("E  Launch", "Hint", HORIZONTAL_ALIGNMENT_CENTER)
	pill_label.add_theme_color_override("font_color", UIStyle.FOCUS_ON_WARM)
	pill.add_child(pill_label)
	inner.add_child(pill)
	_launch_pills.append(pill)

	_tiles.append(tile)
	return tile


func _make_chevron(glyph: String) -> Label:
	var l := UIStyle.make_label(glyph, "", HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", UIStyle.TEXT_SOFT)
	l.custom_minimum_size = Vector2(34.0, 0.0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _process(delta: float) -> void:
	if _closing or _options.is_empty():
		return
	if not _armed:
		_arm_timer -= delta
		if _arm_timer <= 0.0:
			_armed = true
			_refresh_pills()
	if Input.is_action_just_pressed("cancel"):
		_close()
		cancelled.emit()
		UIStyle.play_cancel()
		return
	if Input.is_action_just_pressed("interact"):
		_confirm()
		return
	var step := 0
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("camera_right"):
		step = 1
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("camera_left"):
		step = -1
	if step != 0:
		_select(wrapi(_index + step, 0, _options.size()), true)


func _confirm() -> void:
	# Ignored until armed. Silently, on purpose: a buzz or a shake here would read as "that input
	# was wrong" when in fact it was just early, and the pill lighting up says the same thing better.
	if _closing or not _armed or _options.is_empty():
		return
	var id := _options[_index]
	_close()
	UIStyle.play_confirm()
	chosen.emit(id)


func _select(index: int, click: bool) -> void:
	if index == _index or index < 0 or index >= _options.size():
		return
	_index = index
	_refresh()
	if click:
		UIStyle.play_tick()


## Current highlighted world (used by the pad to point the beacon at it before you even launch).
func current_id() -> String:
	return _options[_index] if _index < _options.size() else ""


func _refresh() -> void:
	if _options.is_empty():
		return
	_desc_label.text = str(BLURB.get(_options[_index], ""))
	for i in _tiles.size():
		var on := i == _index
		var tile := _tiles[i]
		tile.add_theme_stylebox_override("panel", UIStyle.make_panel_style(
			UIStyle.WHITE if on else UIStyle.CREAM_INSET, UIStyle.RADIUS_CARD,
			UIStyle.YELLOW_EDGE if on else UIStyle.CREAM_EDGE, 4 if on else 2,
			10 if on else 0, 12.0))
		_names[i].add_theme_color_override("font_color",
			UIStyle.TEXT_BROWN if on else UIStyle.TEXT_SOFT)
		# The unselected worlds stay legible but clearly stand back, so the eye lands on the choice.
		tile.modulate.a = 1.0 if on else 0.72
		var want := Vector2.ONE * (1.05 if on else 1.0)
		if tile.scale != want:
			tile.pivot_offset = tile.size * 0.5
			var t := tile.create_tween()
			t.tween_property(tile, "scale", want, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_pills()


func _refresh_pills() -> void:
	for i in _launch_pills.size():
		var on := i == _index
		# Faded, never hidden: `visible = false` takes the pill out of the VBox and the tiles then
		# centre their contents differently, which slides the unselected globes down half a row.
		_launch_pills[i].modulate.a = (1.0 if _armed else 0.3) if on else 0.0


func _close() -> void:
	_closing = true
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "offset", Vector2(0.0, 300.0), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(_scrim, "modulate:a", 0.0, 0.18)
	t.chain().tween_callback(queue_free)


# ================================================================================ the painted globe
## A tiny painted planet: the world's real surface colour with a crescent of its own night side, and
## Bolt's ring drawn behind and in front of the globe so it reads as a ring rather than a halo.
## The point is recognition — the player should see the world they are choosing, not a coloured dot.
class PlanetDisc extends Control:
	var body := Color("#7ec46a")
	var shade := Color("#2f5a3a")
	var ring := false
	var ring_color := Color("#ffcf8a")

	func apply(id: String) -> void:
		var path := "res://src/planet/data/%s.tres" % id
		if not ResourceLoader.exists(path):
			return
		var data := load(path) as PlanetData
		if data == null:
			return
		body = data.surface_color
		shade = data.surface_color.darkened(0.42)
		shade.h = data.ground_shadow_color.h
		ring = data.has_ring
		ring_color = data.ring_color
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.40
		if ring:
			_draw_ring(c, r, false)
		# The night side is a full disc of shadow with the lit disc drawn back over it, offset up and
		# left: two circles, one crescent, no clipping.
		draw_circle(c, r, shade)
		draw_circle(c + Vector2(-r * 0.13, -r * 0.13), r * 0.93, body)
		if ring:
			_draw_ring(c, r, true)

	## `front` picks the half of the ellipse that passes in front of the globe.
	func _draw_ring(c: Vector2, r: float, front: bool) -> void:
		var pts := PackedVector2Array()
		var tilt := deg_to_rad(-16.0)
		var steps := 40
		for i in steps + 1:
			var a := TAU * float(i) / float(steps)
			var p := Vector2(cos(a) * r * 2.05, sin(a) * r * 0.52).rotated(tilt)
			if (p.y > 0.0) == front:
				pts.append(c + p)
			elif pts.size() > 1:
				draw_polyline(pts, ring_color, 3.0, true)
				pts.clear()
			else:
				pts.clear()
		if pts.size() > 1:
			draw_polyline(pts, ring_color, 3.0, true)
