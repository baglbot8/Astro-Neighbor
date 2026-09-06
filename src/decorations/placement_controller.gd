class_name PlacementController
extends Node3D
## Placement mode: pick a decoration in the bag, walk around with a translucent ghost floating on the
## ground a few meters ahead of you (FORWARD_DIST), spin it in 15 degree steps, and press interact to
## drop it.
##
## Flow
##   Inventory.item_chosen(item_id, "place")  ->  begin_placement(item_id)
##   the bag closes, EventBus.placement_mode_changed(true) fires, the HUD stops opening menus
##   `rotate_left/right`  turn (tap = one 15 deg step, hold = continuous), `rotate` sfx
##   `interact`           confirm on a free spot (place + consume the item + toast) — stays in
##                        placement mode while you still have another copy, otherwise exits
##                        on a blocked spot: `blocked` sfx + a quick wobble, nothing is placed
##   `cancel`             leave placement mode
##
## HOW THE PLAYER'S OWN INTERACT IS KEPT QUIET (asked for in the brief)
## Player.gd polls `Input.is_action_pressed("interact")` in _physics_process and fires at its current
## Interactable, and the Director drives tests through `Input.action_press`, which never produces an
## InputEvent — so consuming events in _unhandled_input would not work here. Instead, entering
## placement mode disables every node in the "interactables" group (remembering exactly which ones we
## switched off, and re-disabling any Interactable created by a placement), which makes the player's
## finder return null, so its `interact` press does nothing. Leaving placement mode restores them.
## As a side effect the interact prompt would be cleared by the player, so we re-assert our own prompt
## whenever something else overwrites it.

const GHOST_SHADER := preload("res://src/decorations/ghost.gdshader")
const RING_SHADER := preload("res://src/decorations/placement_ring.gdshader")
## Kept short on purpose: the pill is bottom-CENTRE and the toast stack is bottom-RIGHT, so a long
## prompt ("Place · Q/R rotate · Esc cancel", 29 chars) ran underneath a toast and lost its tail.
const PROMPT := "Place · Q/R turn"
## Distance in front of the player where the ghost sits. At the old 2.4 m the ghost's base and most
## of the ring projected onto the astronaut's helmet from the gameplay camera (6.5 m, 28 deg) and you
## could not see what you were placing. It is also deliberately just past the longest possible pickup
## reach (DecorationManager.PICKUP_REACH 2.6 + the largest footprint 1.3 / 2 = 3.25 m), so the player
## never finishes a placement already standing inside the new item's "Pick up" range.
const FORWARD_DIST := 3.35
const YAW_STEP := deg_to_rad(15.0)
## Ghost rotation smoothing rate. Fast enough that the drawn angle is on the 15 deg step within about
## a tenth of a second, which matters because the item is placed at exactly the angle you can see.
const YAW_LERP := 22.0
const HOLD_DELAY := 0.32
const HOLD_REPEAT := 0.06
const RING_SEGMENTS := 44
const RING_LIFT := 0.035
## The ring mesh is only rebuilt when the target has moved at least this far (meters of arc).
const RING_REBUILD_EPS := 0.012
const FREE_TINT := Color(0.42, 0.93, 1.0, 0.95)
const BLOCKED_TINT := Color(1.0, 0.3, 0.34, 0.97)

var manager: DecorationManager
var planet: Planet

var _active := false
var _item_id := ""
var _footprint := 0.7
var _ghost: Node3D
var _ghost_mat: ShaderMaterial
var _ring: MeshInstance3D
var _ring_mesh: ImmediateMesh
var _ring_mat: ShaderMaterial
var _dir := Vector3.UP
var _yaw := 0.0
var _yaw_target := 0.0
var _free := true
var _wobble := 0.0
var _hold := 0.0
var _hold_dir := 0
var _t := 0.0
var _suppressed: Array[Interactable] = []
var _reasserting := false
var _connect_retried := false
## Direction the ring mesh was last built for (it is only rebuilt when the target actually moves).
var _ring_dir := Vector3.ZERO


func _ready() -> void:
	manager = get_parent() as DecorationManager
	planet = manager.planet if manager else null
	set_process(false)
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	_connect_inventory.call_deferred()


func is_active() -> bool:
	return _active


## Why the ghost's current spot is refused; "" when it is placeable or placement is not running.
## The HUD reads this to show the player a plain-language reason ("That spot's reserved",
## "Ground's too steep here"). It deliberately calls the same DecorationManager query the ghost's
## red tint uses, so the pill and the tint can never disagree.
func blocked_reason() -> String:
	if not _active or manager == null:
		return ""
	return manager.spot_block_reason(_dir, _footprint)


func current_item() -> String:
	return _item_id


# ============================================================================================ wiring
func _connect_inventory() -> void:
	var inv := get_node_or_null("/root/World/HUD/Inventory")
	if inv == null:
		# The HUD may still be spawning (or absent in an isolated showcase). Try once more, then stop.
		if not _connect_retried:
			_connect_retried = true
			_connect_inventory.call_deferred()
		return
	if inv.has_signal("item_chosen") and not inv.item_chosen.is_connected(_on_item_chosen):
		inv.item_chosen.connect(_on_item_chosen)


func _on_item_chosen(item_id: String, action: String) -> void:
	if action != "place":
		return
	var inv := get_node_or_null("/root/World/HUD/Inventory")
	if inv and inv.has_method("close"):
		inv.close()
	begin_placement.call_deferred(item_id)


# ============================================================================================ mode
## Enters placement mode with `item_id`. Ignored when the item has no scene or is already active.
func begin_placement(item_id: String) -> void:
	if manager == null:
		return
	if planet == null:
		planet = manager.planet
		if planet == null:
			return
	if manager.scene_for(item_id) == null:
		push_warning("PlacementController: '%s' has no scene" % item_id)
		return
	if _active:
		end_placement()
	_item_id = item_id
	_active = true
	_t = 0.0
	_wobble = 0.0
	_yaw = 0.0
	_yaw_target = 0.0
	var player := _player()
	if player:
		_dir = planet.dir_of(player.global_position)
	manager.refresh_rule_caches()
	_build_ghost()
	_build_ring()
	_suppress_interactables()
	set_process(true)
	EventBus.placement_mode_changed.emit(true)
	EventBus.interact_prompt_changed.emit(PROMPT)


## Leaves placement mode and cleans up the ghost and the ring.
func end_placement() -> void:
	if not _active:
		return
	_active = false
	_item_id = ""
	set_process(false)
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	if is_instance_valid(_ring):
		_ring.queue_free()
	_ring = null
	_ring_mesh = null
	_ring_dir = Vector3.ZERO
	_restore_interactables()
	EventBus.placement_mode_changed.emit(false)
	EventBus.interact_prompt_changed.emit("")


# ============================================================================================ loop
func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	if EventBus.is_modal_open():
		return
	_update_target(delta)
	_update_rotation(delta)
	_free = manager.is_spot_free(_dir, _footprint)
	_apply_ghost_transform()
	_update_ring()
	_ghost_mat.set_shader_parameter("tint", FREE_TINT if _free else BLOCKED_TINT)
	_ring_mat.set_shader_parameter("tint", FREE_TINT if _free else BLOCKED_TINT)
	if _wobble > 0.0:
		_wobble = maxf(_wobble - delta * 3.4, 0.0)
	if Input.is_action_just_pressed("cancel"):
		AudioManager.play_sfx("ui_cancel")
		end_placement()
		return
	if Input.is_action_just_pressed("interact"):
		_confirm()


func _update_target(delta: float) -> void:
	var player := _player()
	if player == null:
		return
	var ahead: Vector3 = player.global_position + player.surface_forward() * FORWARD_DIST
	var want := planet.dir_of(ahead)
	var k := 1.0 - exp(-18.0 * delta)
	_dir = _dir.slerp(want, clampf(k, 0.0, 1.0)).normalized()


func _update_rotation(delta: float) -> void:
	var left := Input.is_action_pressed("rotate_left")
	var right := Input.is_action_pressed("rotate_right")
	var dir := (1 if left else 0) - (1 if right else 0)
	if dir == 0:
		_hold = 0.0
		_hold_dir = 0
	else:
		if dir != _hold_dir:
			_hold_dir = dir
			_hold = -HOLD_DELAY
			_step_yaw(dir)
		else:
			_hold += delta
			if _hold >= HOLD_REPEAT:
				_hold = 0.0
				_step_yaw(dir)
	_yaw = lerp_angle(_yaw, _yaw_target, clampf(delta * YAW_LERP, 0.0, 1.0))


func _step_yaw(dir: int) -> void:
	_yaw_target = wrapf(_yaw_target + YAW_STEP * float(dir), -PI, PI)
	AudioManager.play_sfx("rotate", -6.0, 0.06)


func _confirm() -> void:
	if not _free:
		AudioManager.play_sfx("blocked", -3.0)
		_wobble = 1.0
		return
	var item_id := _item_id
	var def := Catalog.get_item(item_id)
	var display := str(def.get("name", item_id))
	# Place at _yaw, not _yaw_target: the ghost draws the smoothed angle, so confirming right after a
	# rotate tap used to snap the item up to one full 15 deg step away from the preview.
	var id := manager.place(item_id, _dir, _yaw)
	if id == "":
		AudioManager.play_sfx("blocked", -3.0)
		_wobble = 1.0
		return
	GameState.remove_item(item_id)
	EventBus.toast_requested.emit("Placed %s" % display, item_id)
	# The new item's own "Pick up" Interactable is already disarmed by DecorationManager; this pass
	# catches anything else that appeared (e.g. a favour reward spawning while we place).
	_suppress_interactables()
	if GameState.item_count(item_id) > 0:
		_yaw = 0.0
		_yaw_target = 0.0
		EventBus.interact_prompt_changed.emit(PROMPT)
	else:
		end_placement()


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


# ============================================================================================ ghost
func _build_ghost() -> void:
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	var scene := manager.scene_for(_item_id)
	_ghost = scene.instantiate()
	_ghost.name = "Ghost"
	add_child(_ghost)
	_footprint = float(_ghost.get_meta("footprint", DecorationManager.footprint_for(_item_id)))
	_ghost_mat = ShaderMaterial.new()
	_ghost_mat.shader = GHOST_SHADER
	_ghost_mat.set_shader_parameter("tint", FREE_TINT)
	_ghost_mat.set_shader_parameter("fill", 0.38)
	_ghostify(_ghost)
	# DecoItem re-asserts lamp energy and ground-glow alpha whenever the clock ticks, which used to
	# switch the hologram's real lamp light back on and pool warm light on the grass under it.
	var item := _ghost as DecoItem
	if item:
		item.set_ghost_mode(true)
	_apply_ghost_transform()


## Strips a freshly instanced item down to a harmless hologram.
func _ghostify(node: Node) -> void:
	for c in node.get_children():
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.name == "GroundGlow":
				mi.visible = false
			else:
				mi.material_override = _ghost_mat
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif c is GPUParticles3D:
			(c as GPUParticles3D).emitting = false
			(c as Node3D).visible = false
		elif c is Light3D:
			(c as Light3D).visible = false
		elif c is Interactable:
			var it := c as Interactable
			it.enabled = false
			it.set_deferred("monitorable", false)
		elif c is CollisionObject3D:
			var co := c as CollisionObject3D
			co.collision_layer = 0
			co.collision_mask = 0
		_ghostify(c)


func _apply_ghost_transform() -> void:
	if not is_instance_valid(_ghost) or planet == null:
		return
	var wob := sin(_t * 42.0) * _wobble * 0.22
	var xf := manager.surface_transform_for(_dir, _yaw + wob)
	if _wobble > 0.0:
		var s := 1.0 + _wobble * 0.05 * sin(_t * 34.0)
		xf.basis = xf.basis.scaled(Vector3(s, 2.0 - s, s))
	_ghost.global_transform = xf


# ============================================================================================ ring
func _build_ring() -> void:
	if is_instance_valid(_ring):
		_ring.queue_free()
	_ring_mesh = ImmediateMesh.new()
	_ring = MeshInstance3D.new()
	_ring.name = "PlacementRing"
	_ring.mesh = _ring_mesh
	_ring.top_level = true
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring_mat = ShaderMaterial.new()
	_ring_mat.shader = RING_SHADER
	_ring_mat.set_shader_parameter("tint", FREE_TINT)
	_ring_mat.set_shader_parameter("dashes", float(maxi(10, int(_footprint * 22.0))))
	_ring.material_override = _ring_mat
	_ring.extra_cull_margin = 4.0
	add_child(_ring)


## Rebuilds the dashed annulus so it follows the curved, bumpy ground exactly. Only when the target
## has actually moved — the dashes themselves animate in the shader, so standing still costs nothing.
func _update_ring() -> void:
	if _ring_mesh == null or planet == null:
		return
	if _ring_dir != Vector3.ZERO and planet.surface_distance(_dir, _ring_dir) < RING_REBUILD_EPS:
		return
	_ring_dir = _dir
	var d := _dir
	var t1 := d.cross(Vector3.UP)
	if t1.length_squared() < 0.001:
		t1 = d.cross(Vector3.RIGHT)
	t1 = t1.normalized()
	var t2 := d.cross(t1).normalized()
	var r_in := _footprint * 0.86
	var r_out := _footprint * 1.16
	_ring_mesh.clear_surfaces()
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in RING_SEGMENTS + 1:
		var u := float(i) / float(RING_SEGMENTS)
		var a := u * TAU
		var tang := t1 * cos(a) + t2 * sin(a)
		for k in 2:
			var arc: float = r_in if k == 0 else r_out
			var theta := arc / maxf(planet.radius, 0.001)
			var dd := (d * cos(theta) + tang * sin(theta)).normalized()
			_ring_mesh.surface_set_uv(Vector2(u, float(k)))
			_ring_mesh.surface_set_normal(dd)
			_ring_mesh.surface_add_vertex(planet.surface_point(dd) + dd * RING_LIFT)
	_ring_mesh.surface_end()


# ============================================================================================ interactable suppression
func _suppress_interactables() -> void:
	for n in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.enabled:
			continue
		it.enabled = false
		it.set_focused(false)
		if not _suppressed.has(it):
			_suppressed.append(it)


func _restore_interactables() -> void:
	for it in _suppressed:
		# Never blanket-restore: a pickup created by this very placement is still counting down its
		# arming grace (DecorationManager._arm_pickups) and switching it on here is exactly what let
		# a held `interact` place an item and pick it straight back up.
		if is_instance_valid(it) and not manager.is_pickup_arming(it):
			it.enabled = true
	_suppressed.clear()


func _on_prompt_changed(text: String) -> void:
	if not _active or text == PROMPT or _reasserting:
		return
	_reasserting = true
	_reassert_prompt.call_deferred()


func _reassert_prompt() -> void:
	_reasserting = false
	if _active:
		EventBus.interact_prompt_changed.emit(PROMPT)
