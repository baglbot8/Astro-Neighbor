extends Node3D
## Showcase for the MOBILE front end (docs/STYLE_GUIDE.md R2.10).
##
## It instantiates the REAL `src/world/world.tscn` rather than staging a lookalike. AGENT_WORKFLOW
## is blunt about why: "a showcase whose lighting differs from the game is worse than no showcase".
## Two builders have already been failed for tuning art against a staged scene, and the whole point
## of this one is to judge translucent controls AGAINST the planet behind them - which only means
## anything with the game's own sky, sun and ground.
##
## What it forces, so a desktop reviewer sees what a phone sees:
##   * `Platform.set_mobile(true, false)` - mobile layout regardless of the machine, and NOT
##     remembered, so running the showcase cannot leave a saved `ui_mode` behind.
##   * a landscape phone's safe-area inset (notch on the left, home indicator at the bottom),
##     because macOS reports only its menu bar and the insets would otherwise all read zero.
##   * a slow loop through the states worth looking at: controls idle, stick pushed to a walk,
##     stick pushed to a run, the action cluster held, and then the idle fade.
##
## View it at a real phone aspect:
##   godot --path . res://showcase/ui_mobile.tscn --resolution 2340x1080 -- --skip-title --new-game
## or with the timelines: tests/director/ui_mobile_play.json / ui_mobile_panels.json.

## Landscape phone insets: a notch on the left edge, a home indicator along the bottom, in the
## 1560x720 logical viewport a 2340x1080 screen resolves to.
const SHOWCASE_SAFE_AREA := Vector4(64.0, 0.0, 20.0, 26.0)

## Seconds per state in the demo loop.
const STEP := 3.0

var _world: Node
var _touch: Node
var _t := 0.0
var _state := -1


func _ready() -> void:
	# The mode has to be set BEFORE the world (and therefore the HUD) is built: every mobile layout
	# is decided in a `_ready`, so flipping afterwards would need a rebuild to show. Deferred, and
	# set again in `_install_world`, because `Platform._ready` re-runs detection and would otherwise
	# be free to land after this and put the mode back.
	call_deferred("_install_world")


func _install_world() -> void:
	var plat: Node = get_tree().root.get_node_or_null("Platform")
	if plat != null:
		plat.call("set_mobile", true, false)
		plat.call("set_debug_safe_area", SHOWCASE_SAFE_AREA)
	var packed: PackedScene = load("res://src/world/world.tscn")
	_world = packed.instantiate()
	_world.name = "World"
	# Parented to the SceneTree root, not to this node, so every absolute path the game relies on
	# (/root/World/Player, /root/World/HUD/...) resolves exactly as it does in the real game.
	get_tree().root.add_child(_world)


func _process(delta: float) -> void:
	if _touch == null:
		_touch = get_tree().root.get_node_or_null("World/HUD/TouchControls")
		if _touch == null:
			return
	_t += delta
	var want := int(_t / STEP)
	if want == _state:
		return
	_state = want
	match want % 5:
		0:
			_release()
		1:
			_touch.call("debug_stick", 0.35, -0.94, 0.45, true)
		2:
			_touch.call("debug_stick", 0.35, -0.94, 1.0, true)
		3:
			_touch.call("debug_stick", 0.0, 0.0, 0.0, false)
			_touch.call("debug_widget", "boost", true)
		4:
			_release()
	_touch.call("debug_report", "showcase_%d" % (want % 5))


func _release() -> void:
	_touch.call("debug_stick", 0.0, 0.0, 0.0, false)
	for w in ["boost", "jump", "primary"]:
		_touch.call("debug_widget", w, false)
