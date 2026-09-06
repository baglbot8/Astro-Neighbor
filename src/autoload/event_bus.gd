extends Node
## Global signal bus. All cross-system communication goes through here.
## Systems emit; systems listen. Never hold direct references across domains
## when a signal will do.

# --- World / travel ---
signal planet_loaded(planet_id: String)          # world.tscn finished building a planet
signal planet_leave_requested(planet_id: String) # player boarded rocket
signal travel_started(from_id: String, to_id: String)
signal travel_finished(to_id: String)

# --- Player ---
signal player_spawned(player: Node3D)
signal player_style_changed()                    # suit/helmet/etc changed (astronaut model re-reads GameState.player_style)

# --- Economy / inventory ---
signal stardust_changed(new_amount: int, delta: int)
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal collectible_picked(kind: String, world_pos: Vector3)

# --- Decoration ---
signal decoration_placed(planet_id: String, instance_id: String, item_id: String)
signal decoration_removed(planet_id: String, instance_id: String)
signal placement_mode_changed(active: bool)

# --- Dialogue / NPC / favors ---
signal dialogue_started(speaker_id: String)
signal dialogue_finished(speaker_id: String)
signal favor_offered(favor_id: String, npc_id: String)
signal favor_accepted(favor_id: String)
signal favor_completed(favor_id: String, reward_item_id: String, reward_stardust: int)
signal favor_progress(favor_id: String, current: int, target: int)
signal friendship_changed(npc_id: String, level: int)

# --- Planet score / trash ---
signal trash_changed(count: int)          # a piece landed on the home planet, or was cleaned up

# --- UI ---
signal ui_modal_opened(name: String)   # inventory/shop/pause etc. Player should freeze while any modal is open.
signal ui_modal_closed(name: String)
signal toast_requested(text: String, icon: String) # small notification ("You got a Moon Lamp!")
signal interact_prompt_changed(text: String)       # "" hides the prompt

# --- Time ---
signal time_of_day_changed(hour_float: float)       # 0..24, emitted every ~0.05h
signal day_phase_changed(phase: String)              # "dawn" "day" "dusk" "night"

# --- Save ---
signal game_saved()
signal game_loaded()

var _modal_count: int = 0
var _modal_names: Dictionary = {}

func _ready() -> void:
	ui_modal_opened.connect(_on_modal_opened)
	ui_modal_closed.connect(_on_modal_closed)
	# A scene change frees whatever UI was open without it ever emitting ui_modal_closed.
	# Without this reset the modal count stays above zero forever and every gameplay input
	# in the next scene is ignored - an unrecoverable soft-lock. Found by the rocket critic:
	# opening the bag during the launch cutscene left the space map permanently input-dead.
	get_tree().node_added.connect(_on_node_added)

func _on_modal_opened(n: String) -> void:
	_modal_count += 1
	_modal_names[n] = int(_modal_names.get(n, 0)) + 1

func _on_modal_closed(n: String) -> void:
	_modal_count = max(0, _modal_count - 1)
	var left: int = int(_modal_names.get(n, 0)) - 1
	if left <= 0:
		_modal_names.erase(n)
	else:
		_modal_names[n] = left

func _on_node_added(node: Node) -> void:
	# Only react to a new scene root being installed.
	if node.get_parent() == get_tree().root:
		reset_modals()

## Clears all modal state. Called automatically on every scene change.
func reset_modals() -> void:
	if _modal_count != 0:
		push_warning("EventBus: clearing %d stale modal(s) on scene change: %s" % [_modal_count, str(_modal_names.keys())])
	_modal_count = 0
	_modal_names.clear()

## True while any menu / dialogue / shop is open. Gameplay input should be ignored.
func is_modal_open() -> bool:
	return _modal_count > 0

## Names of the currently-open modals, for debugging and for systems that care which one.
func open_modals() -> Array:
	return _modal_names.keys()
