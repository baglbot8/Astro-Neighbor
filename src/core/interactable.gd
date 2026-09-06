class_name Interactable
extends Area3D
## Anything the player can press "interact" on. Put on layer 5.
## Subclass and override interact(), or connect to `interacted`.
## The player's interaction finder picks the closest Interactable in front of them within `reach`.

signal interacted(player: Node3D)
signal focus_changed(focused: bool)

@export var prompt_text: String = "Talk"
@export var reach: float = 2.6
@export var enabled: bool = true
## If true, the player must be facing roughly toward this (dot > 0.2). Off for big things like buildings.
@export var require_facing: bool = false

var _focused := false

func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("interactables")

func set_focused(f: bool) -> void:
	if f == _focused:
		return
	_focused = f
	focus_changed.emit(f)

func is_focused() -> bool:
	return _focused

func interact(player: Node3D) -> void:
	interacted.emit(player)
