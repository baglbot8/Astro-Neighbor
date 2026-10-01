extends Control
## THE STAMPS CHIP: a small HUD pill beside the scrap counter - Norm's stamp and today's "1/3" (a
## tick once the day's stamp is earned). Tap or click it to open the Stamps view.
##
## Built and placed by StampSystem (src/stamps/stamp_system.gd) inside the HUD's WorldChrome layer,
## so it fades with the other pills (a modal, the safari, the arrival hold) without hud.gd knowing
## about it. It follows the scrap pill's real right edge and scale every frame, because that pill
## moves with the digit count and the platform (hud.gd `_position_scrap_pill`).
##
## TOUCH: the pill sits in the top row, left of centre and above TouchControls' HUD buttons - a part
## of the screen none of its zones claim (the same reasoning as the home album's Camera button,
## home_album_camera.gd `_place_idle_button`), so a tap falls through to the Button here.

const StampCard := preload("res://src/stamps/stamp_card.gd")
const StampArt := preload("res://src/stamps/stamp_art.gd")
const PANEL_PATH := "res://src/stamps/stamp_panel.gd"
const GAP := 18.0            # hud.gd SCRAP_PILL_GAP
const NODE_NAME := "StampChip"

var _hud: Node
var _pill: PanelContainer
var _label: Label
var _button: Button
var _shown_text := ""


func _ready() -> void:
	name = NODE_NAME
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIStyle.theme()
	_pill = PanelContainer.new()
	_pill.theme_type_variation = "HudPill"
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.add_child(row)
	row.add_child(StampArt.make("mark", 30.0))
	_label = UIStyle.make_label("", "Header")
	row.add_child(_label)
	_button = Button.new()
	_button.flat = true
	_button.focus_mode = Control.FOCUS_NONE
	for sb: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		_button.add_theme_stylebox_override(sb, StyleBoxEmpty.new())
	_button.pressed.connect(_on_pressed)
	add_child(_button)
	_pill.resized.connect(_fit)
	refresh()


func bind(hud: Node) -> void:
	_hud = hud


func refresh() -> void:
	if _label == null:
		return
	var t := "Card"
	if StampCard.is_on():
		t = "Done" if StampCard.stamped_today() else "%d/%d" % [mini(StampCard.done_count(), StampCard.NEED), StampCard.NEED]
	if t != _shown_text:
		_shown_text = t
		_label.text = t
		_pill.reset_size()
		_fit()


func _fit() -> void:
	size = _pill.size
	# A thumb-sized target on a phone: the button reaches past the pill on every side but the top.
	var pad := 14.0 if MobileUI.is_mobile() else 0.0
	_button.position = Vector2(-pad, -4.0)
	_button.size = _pill.size + Vector2(pad * 2.0, pad + 4.0)


func _process(_delta: float) -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	var scrap: Variant = _hud.get("_scrap_pill")
	if not (scrap is Control):
		return
	var sp := scrap as Control
	scale = sp.scale
	position = Vector2(sp.position.x + sp.size.x * sp.scale.x + GAP * sp.scale.x, sp.position.y)


func _on_pressed() -> void:
	# The chrome is faded out while a modal or the safari owns the screen; a faded pill is not a button.
	if EventBus.is_modal_open() or PhotoMode.active or SceneRouter.is_busy():
		return
	if ResourceLoader.exists(PANEL_PATH):
		load(PANEL_PATH).call("open_over", self)
