class_name CharacterModel
extends Node3D
## Common base for every neighbour model, so `NPC` can hold a typed reference and call the animation
## API directly instead of duck-typing through `Object.call()` twice per frame.
##
## Two families implement it:
##   * `ChibiModel`  — the procedural AC villager rig (Zorp, Bolt, Pip, Pop, Mayor Orbit, DJ Nova)
##   * `TailorModel` — Stella, who wraps the player's `AstronautModel`
##
## Everything here has a working default, so a subclass only overrides what it actually has.

## Emitted when a walk cycle plants a foot (0 = left, 1 = right).
signal footstep(foot: int)
## Emitted once when a timed emote ("wave", "happy", ...) reaches its full duration.
signal emote_finished(emote: String)

## Uniform scale of the whole model (Pip & Pop are smaller than a full villager).
@export var body_scale: float = 1.0
## Speed of the idle/walk oscillations only (state changes keep real time). Mayor Orbit is slow.
@export var anim_time_scale: float = 1.0


## Switches animation state ("idle" "walk" "talk" "wave" "happy" "think" "surprised" "dance").
func set_state(_new_state: String) -> void:
	pass


func get_state() -> String:
	return "idle"


## Seconds since the current state started.
func get_state_time() -> float:
	return 0.0


## Advances the animation. `speed_factor`: 0 = standing, 1 = walking.
func tick(_delta: float, _speed_factor: float) -> void:
	pass


## Current value of an animation channel (`ChibiModel.P`); 0 when the model has no such rig.
func pose(_channel: int) -> float:
	return 0.0


## Duration of a timed emote, or 0 for looping states (instance-side so callers can stay typed).
func emote_duration(_emote: String) -> float:
	return 0.0
