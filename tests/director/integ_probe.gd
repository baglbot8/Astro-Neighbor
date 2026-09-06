extends Node
## Integration-critic probe. Injected into /root/World by a Director "call" step:
##   {"call": {"node": "/root/World", "method": "_spawn_optional",
##             "args": ["res://tests/director/integ_probe.tscn", "IntegProbe"]}}
## Then driven with further "call" steps on /root/World/IntegProbe.
##
## It never changes gameplay rules; it only reports state and teleports the player so a
## timeline can reach a collectible / NPC / pad without a 60 s walk.

var _player: Node3D
var _planet: Node
var _hud: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_node_or_null("/root/World/Player") as Node3D
	_planet = get_node_or_null("/root/World/Planet")
	_hud = get_node_or_null("/root/World/HUD")
	EventBus.ui_modal_opened.connect(func(n: String) -> void: print("PROBE modal+ %s count=%d" % [n, EventBus._modal_count]))
	EventBus.ui_modal_closed.connect(func(n: String) -> void: print("PROBE modal- %s count=%d" % [n, EventBus._modal_count]))
	EventBus.favor_offered.connect(func(fid: String, npc: String) -> void: print("PROBE favor_offered %s by %s" % [fid, npc]))
	EventBus.favor_accepted.connect(func(fid: String) -> void: print("PROBE favor_accepted %s" % fid))
	EventBus.favor_progress.connect(func(fid: String, c: int, t: int) -> void: print("PROBE favor_progress %s %d/%d" % [fid, c, t]))
	EventBus.favor_completed.connect(func(fid: String, item: String, sd: int) -> void: print("PROBE favor_completed %s reward=%s +%d" % [fid, item, sd]))
	EventBus.toast_requested.connect(func(t: String, i: String) -> void: print("PROBE toast: %s" % t))
	EventBus.decoration_placed.connect(func(p: String, i: String, it: String) -> void: print("PROBE deco_placed %s %s %s" % [p, i, it]))
	EventBus.decoration_removed.connect(func(p: String, i: String) -> void: print("PROBE deco_removed %s %s" % [p, i]))
	EventBus.stardust_changed.connect(func(n: int, d: int) -> void: print("PROBE stardust %d (%+d)" % [n, d]))
	print("PROBE ready player=%s planet=%s hud=%s" % [_player != null, _planet != null, _hud != null])
	dump("ready")


func dump(tag: String = "") -> void:
	var pos := Vector3.ZERO
	var d := Vector3.ZERO
	if _player != null:
		pos = _player.global_position
		d = pos.normalized()
	print("PROBE [%s] planet=%s modal=%d open=%s paused=%s busy=%s pos=%s stardust=%d inv=%s placed=%s favors=%s style_suit=%s name=%s tod=%.2f day=%d" % [
		tag, GameState.current_planet_id, EventBus._modal_count, str(EventBus.open_modals()),
		str(get_tree().paused), str(SceneRouter.is_busy()), str(pos.snapped(Vector3(0.01, 0.01, 0.01))),
		GameState.stardust, str(GameState.inventory),
		str(_placed_counts()), str(GameState.favors),
		str(GameState.player_style.get("suit_color")), GameState.home_planet_name,
		GameState.time_of_day, GameState.day_count])


func _placed_counts() -> Dictionary:
	var out := {}
	for k in GameState.placed_decorations.keys():
		out[k] = (GameState.placed_decorations[k] as Array).size()
	return out


## Lists every node in `group` with its surface distance from the player.
func list_group(group: String) -> void:
	var nodes := get_tree().get_nodes_in_group(group)
	print("PROBE group '%s' n=%d" % [group, nodes.size()])
	for n in nodes:
		if n is Node3D:
			var dist := 999.0
			if _player != null:
				dist = (n as Node3D).global_position.distance_to(_player.global_position)
			print("   %s  pos=%s  dist=%.2f  path=%s" % [n.name, str((n as Node3D).global_position.snapped(Vector3(0.1, 0.1, 0.1))), dist, n.get_path()])


## Teleports the player to a spot `back_m` metres from the nearest member of `group`,
## facing it. Use before an `interact` tap.
func goto_group(group: String, index: int = 0, back_m: float = 1.4) -> void:
	var nodes := get_tree().get_nodes_in_group(group)
	var list: Array = []
	for n in nodes:
		if n is Node3D:
			list.append(n)
	if list.is_empty():
		print("PROBE goto_group: '%s' empty" % group)
		return
	list.sort_custom(func(a, b): return a.global_position.distance_to(_player.global_position) < b.global_position.distance_to(_player.global_position))
	index = clampi(index, 0, list.size() - 1)
	var target: Node3D = list[index]
	_goto_node(target, back_m)


## Matches against the full node PATH, so "town_hall/Door" picks one of four doors.
func goto_named(group: String, path_fragment: String, back_m: float = 1.4) -> void:
	for n in get_tree().get_nodes_in_group(group):
		if n is Node3D and str(n.get_path()).to_lower().contains(path_fragment.to_lower()):
			_goto_node(n as Node3D, back_m)
			return
	print("PROBE goto_named: no '%s' in '%s'" % [path_fragment, group])


## Pins the next favour offer to one template ("fetch" | "bring" | "deliver").
func force_favor(kind: String) -> void:
	var fs := get_tree().get_first_node_in_group("favor_system")
	if fs == null:
		fs = get_node_or_null("/root/World/FavorSystem")
	if fs == null:
		for n in get_tree().root.get_children():
			var c := n.get_node_or_null("FavorSystem")
			if c != null:
				fs = c
				break
	if fs != null and fs.has_method("debug_force_template"):
		fs.call("debug_force_template", kind)
		print("PROBE force_favor %s on %s" % [kind, fs.get_path()])
	else:
		print("PROBE force_favor: no FavorSystem found")


func _goto_node(target: Node3D, back_m: float) -> void:
	var tdir: Vector3 = target.global_position.normalized()
	var pdir: Vector3 = _player.global_position.normalized()
	var away: Vector3 = (pdir - tdir * pdir.dot(tdir))
	if away.length_squared() < 0.0001:
		away = tdir.cross(Vector3.UP)
		if away.length_squared() < 0.0001:
			away = tdir.cross(Vector3.RIGHT)
	away = away.normalized()
	var radius: float = target.global_position.length()
	var ang: float = back_m / maxf(radius, 0.001)
	var dest: Vector3 = (tdir * cos(ang) + away * sin(ang)).normalized()
	_player.call("teleport_to_dir", dest)
	# Face the target across the sphere.
	var up: Vector3 = dest
	var fwd: Vector3 = (target.global_position - _player.global_position)
	fwd = (fwd - up * fwd.dot(up)).normalized()
	if fwd.length_squared() > 0.001:
		_player.global_transform.basis = Basis.looking_at(fwd, up)
		# Snap the follow camera behind the player too. Without this the rig keeps its old yaw
		# (it only auto-recentres while walking) and the capture looks at empty scenery.
		var rig := get_node_or_null("/root/World/CameraRig")
		if rig != null:
			rig.set("_fwd", fwd)
			rig.set("_up", up)
	print("PROBE goto %s -> player at %s (dist %.2f)" % [target.name, str(_player.global_position.snapped(Vector3(0.1, 0.1, 0.1))), _player.global_position.distance_to(target.global_position)])


## Teleports to the rocket pad direction from PlanetData.
func goto_pad(back_m: float = 2.0) -> void:
	var rocket := get_node_or_null("/root/World/Rocket")
	if rocket == null:
		print("PROBE goto_pad: no /root/World/Rocket")
		return
	var inter: Node = null
	for n in get_tree().get_nodes_in_group("interactables"):
		if rocket.is_ancestor_of(n):
			inter = n
			break
	if inter is Node3D:
		_goto_node(inter as Node3D, back_m)
	elif rocket is Node3D:
		_goto_node(rocket as Node3D, back_m)


## Prints whether the player is still functional: can move, has input, can reach a menu.
func liveness(tag: String) -> void:
	var ok_input: Variant = _player.get("input_enabled") if _player != null else null
	var pm: Node = _hud.get_node_or_null("PauseMenu") if _hud != null else null
	var inv: Node = _hud.get_node_or_null("Inventory") if _hud != null else null
	print("PROBE liveness[%s] input_enabled=%s modal=%d(%s) paused=%s busy=%s pause_menu=%s inventory=%s deco_placing=%s" % [
		tag, str(ok_input), EventBus._modal_count, str(EventBus.open_modals()), str(get_tree().paused),
		str(SceneRouter.is_busy()), str(pm != null and pm.get("is_open")),
		str(inv != null and inv.get("is_open")), str(_placement_active())])


func _placement_active() -> bool:
	var d := get_node_or_null("/root/World/Decorations")
	if d == null:
		return false
	var pc := d.get_node_or_null("PlacementController")
	if pc == null:
		for c in d.get_children():
			if c.has_method("is_active"):
				pc = c
				break
	return pc != null and pc.has_method("is_active") and pc.call("is_active")


## Records the player's position so a later call can prove it moved.
var _mark := Vector3.ZERO
func mark() -> void:
	_mark = _player.global_position if _player != null else Vector3.ZERO
	print("PROBE mark %s" % str(_mark.snapped(Vector3(0.01, 0.01, 0.01))))


func moved(tag: String) -> void:
	var now: Vector3 = _player.global_position if _player != null else Vector3.ZERO
	print("PROBE moved[%s] delta=%.3f m  (from %s to %s)" % [tag, now.distance_to(_mark), str(_mark.snapped(Vector3(0.01, 0.01, 0.01))), str(now.snapped(Vector3(0.01, 0.01, 0.01)))])


func give(item_id: String, count: int = 1) -> void:
	GameState.add_item(item_id, count)
	print("PROBE give %s x%d" % [item_id, count])


func set_stardust(n: int) -> void:
	GameState.stardust = n
	EventBus.stardust_changed.emit(n, 0)
	print("PROBE set_stardust %d" % n)


## Exercises the same seam the clothes store uses: rewrite player_style and shout about it.
func set_suit(hex: String) -> void:
	GameState.player_style["suit_color"] = hex
	GameState.player_style["trouser_color"] = "#2f6f4a"
	GameState.player_style["panel_color"] = "#d0603a"
	GameState.player_style["accent_color"] = "#ffd447"
	if not GameState.wardrobe.has("suit_critic"):
		GameState.wardrobe.append("suit_critic")
	EventBus.player_style_changed.emit()
	print("PROBE set_suit %s" % hex)


func set_planet_name(n: String) -> void:
	GameState.home_planet_name = n
	print("PROBE set_planet_name %s" % n)


## Straight scene change to another planet, bypassing the rocket. Exercises the same
## SceneRouter path a flight ends with, so decorations / clock / favours can be checked
## across a planet change while the rocket domain is mid-rebuild.
func goto_planet(id: String) -> void:
	print("PROBE goto_planet %s (tod=%.2f)" % [id, GameState.time_of_day])
	SceneRouter.go_to_planet(id, false)


func save_now() -> void:
	print("PROBE save_game -> %s" % str(SaveManager.save_game()))


func dump_save() -> void:
	var f := FileAccess.open("user://astro_neighbor_save.json", FileAccess.READ)
	if f == null:
		print("PROBE dump_save: no file")
		return
	print("PROBE SAVEFILE: " + f.get_as_text().replace("\n", " ").replace("\t", ""))
	f.close()
