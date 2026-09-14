extends Node
## CamFadeProbe - repro harness for the camera near-geometry fade (CameraRig._update_occluder_fade)
## on layer-4 "decoration" props. Injected into /root/World by a Director "call" step:
##   {"call": {"node": "/root/World", "method": "_spawn_optional",
##             "args": ["res://tests/director/cam_fade_probe.tscn", "CamFadeProbe"]}}
## Then driven with further "call" steps on /root/World/CamFadeProbe.
##
## Never changes gameplay rules: it only reads state, and stages one occluder by teleporting the
## player and pointing CameraRig's _fwd/_up (the same fields the real camera reads every frame).

const OCCLUDER_LAYER_BIT := 8  # 1 << 3, matches CameraRig.OCCLUDER_MASK

var _player: Node3D
var _rig: Node3D
var _staged_prop: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_node_or_null("/root/World/Player") as Node3D
	_rig = get_node_or_null("/root/World/CameraRig") as Node3D
	print("CAMFADEPROBE ready player=%s rig=%s" % [_player != null, _rig != null])


# ============================================================================= discovery / listing
func _find_layer4(n: Node, out: Array) -> void:
	if n is CollisionObject3D and (int((n as CollisionObject3D).collision_layer) & OCCLUDER_LAYER_BIT) != 0:
		out.append(n)
	for c: Node in n.get_children():
		_find_layer4(c, out)


## Mirrors CameraRig._mark_occluder's walk-up-to-two-hops geometry collection, WITHOUT touching the
## rig's fade state (it only calls the read-only _collect_geometry helper it already has).
func _collect_like_rig(col: Node3D) -> Array:
	if _rig == null or col == null:
		return []
	var meshes: Array = _rig.call("_collect_geometry", col)
	var hops := 0
	var root: Node3D = col
	while meshes.is_empty() and hops < 2:
		var parent := root.get_parent()
		if parent == null or not (parent is Node3D) or (parent as Node3D).is_in_group("player"):
			break
		root = parent as Node3D
		meshes = _rig.call("_collect_geometry", root)
		hops += 1
	return meshes


## Lists every layer-4 collision object under `root_path`, nearest `limit` to the player first, with
## path, distance, and how many GeometryInstance3D CameraRig._mark_occluder would collect for it.
func list_occluders(root_path: String = "/root/World", limit: int = 40) -> void:
	var root := get_node_or_null(root_path)
	if root == null:
		print("CAMFADEPROBE list_occluders: no node at %s" % root_path)
		return
	var found: Array = []
	_find_layer4(root, found)
	found.sort_custom(func(a, b):
		var da := 999.0
		var db := 999.0
		if _player:
			da = (a as Node3D).global_position.distance_to(_player.global_position)
			db = (b as Node3D).global_position.distance_to(_player.global_position)
		return da < db)
	print("CAMFADEPROBE occluders total=%d under %s (showing nearest %d)" % [found.size(), root_path, mini(limit, found.size())])
	for i in range(mini(limit, found.size())):
		var col: Node3D = found[i]
		var dist := 999.0
		if _player:
			dist = col.global_position.distance_to(_player.global_position)
		var meshes := _collect_like_rig(col)
		print("  %-45s dist=%6.2f meshes=%d" % [str(col.get_path()), dist, meshes.size()])


const AUTO_BACK_M: Array[float] = [0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 1.0, 1.1, 1.2, 1.5, 1.8, 2.1, 2.4, 2.7, 3.0]


# ============================================================================= staging an occluder
## Places the player and CameraRig so that `prop` sits on the real occluder-probe capsule at the
## given `back_m` (metres from the player, along the line from the player's PRE-teleport position
## through the prop - see `stage()` for why not an arbitrary tangent), and `zoom_m` (CameraRig
## follow distance). Snaps the camera straight to its target with no easing (see `stage()`).
func _place_for(prop: Node3D, from_pos: Vector3, back_m: float, zoom_m: float) -> Dictionary:
	var pdir: Vector3 = prop.global_position.normalized()
	var out_dir: Vector3 = prop.global_position - from_pos
	out_dir -= pdir * out_dir.dot(pdir)
	if out_dir.length_squared() < 0.0001:
		out_dir = pdir.cross(Vector3.UP)
		if out_dir.length_squared() < 0.0001:
			out_dir = pdir.cross(Vector3.RIGHT)
	out_dir = out_dir.normalized()
	var radius: float = maxf(prop.global_position.length(), 0.001)
	var ang: float = back_m / radius
	var player_dir: Vector3 = (pdir * cos(ang) + out_dir * sin(ang)).normalized()
	_player.call("teleport_to_dir", player_dir)

	# Read back the player's REAL up after teleporting, rather than trusting our idealised sphere
	# radial (`player_dir`): the ground is a bumpy heightfield (planet_props.gd's `_downhill` reads
	# `planet.ground_normal`), so the true surface normal at the landing spot can differ from pure
	# radial by enough to miss a small, low prop even though a tall one (a lamp post, a tree) still
	# gets caught by the wider margin its own height gives it. Measured: every one of home's 10
	# pebble rocks (0.45m tall) missed the probe at all 12 tried distances using the idealised radial
	# up; only tall props (Lamp 2.3m, Topiary 1.6m, PuffTree ~2m) were ever confirmed to work with it.
	var real_up: Vector3 = _player.get("up")
	var up: Vector3 = real_up.normalized() if real_up.length_squared() > 0.0001 else player_dir

	# Re-derive fwd from the ACTUAL post-teleport 3D vector to the prop, not the pre-teleport
	# idealised unit-sphere tangent (`out_dir` above): `player_dir` was placed by slerp-ing on a
	# PERFECT sphere of `radius = prop.global_position.length()`, but home's meadow terrain is a
	# noisy heightfield (planet_props.gd's `_downhill` reads `planet.ground_normal`), so the real
	# surface point at that direction can sit at a different actual radius than the prop's - close in
	# angle, but the resulting camera (built from `fwd`/`up`/PIVOT_HEIGHT/pitch, all of which amplify
	# a radial mismatch through the ~cos(pitch)/sin(pitch) geometry - see `stage()`'s docstring) can
	# then look nowhere near the prop at all. MEASURED on home's Rock9 at back_m=3.0 with the
	# idealised tangent: the camera->target line's closest approach to the prop was 2.5-3.3m, almost
	# as large as the direct player-to-prop distance (3.04m) - the camera was not even roughly aimed
	# at the prop. Recomputing fwd from the real delta after teleporting fixed it (see `stage()`).
	var real_out: Vector3 = prop.global_position - _player.global_position
	real_out -= up * real_out.dot(up)
	var fwd: Vector3
	if real_out.length_squared() > 0.0001:
		fwd = -real_out.normalized()  # away from the prop
	else:
		fwd = out_dir - up * out_dir.dot(up)
		fwd = fwd.normalized() if fwd.length_squared() > 0.0001 else Vector3.FORWARD
	_player.global_transform.basis = Basis.looking_at(fwd, up)

	_rig.set("_up", up)
	_rig.set("_fwd", fwd)
	# Set both the smoothed and target distance directly (not set_zoom_distance(), which tweens over
	# 0.35s) so the capture spot is deterministic the moment we ask for it.
	_rig.set("_dist_target", zoom_m)
	_rig.set("_dist", zoom_m)
	# MEASURED: without this, _smoothed_pos (the camera's actual position, eased toward its target at
	# POS_SMOOTH=8.0) keeps whatever position it held before staging and flies to the new spot over
	# ~0.6-0.9s. During that flight it sweeps across whatever plaza props sit between the old and new
	# camera position, so a Director capture taken "about 1s after staging" can land on a transient
	# occluder mid-flight instead of the staged one - measured on a staged Topiary0: CAMFADE went
	# 0.23 -> 1.00 -> back down to an EMPTY set by ~1s later, purely from this camera drift, with the
	# player/rig _fwd/_up never moving at all (confirmed via a probe_cam() dump).
	# CameraRig._snap_to_target() is the engine's own fix for exactly this (used once on init) - it
	# recomputes _smoothed_pos/_smoothed_quat straight from pivot/_fwd/_up/_dist with no easing, so
	# calling it here lands the camera on the intended spot the same frame.
	_rig.call("_snap_to_target")
	return {"fwd": fwd, "up": up}


## Finds the first layer-4 collider under /root/World whose path or name contains `name_fragment`
## (case-insensitive) and stages it as the occluder: teleports the player near it, points
## CameraRig's _fwd/_up so the camera sits behind the player on the prop's side, and snaps the
## camera straight there (see `_place_for`).
##
## `back_m`: if >0, used as-is. If <=0 (the default), AUTO_BACK_M distances are tried in order and
## the first that makes the REAL occluder probe (CameraRig._probe_occluders, called directly, not
## waited-for on its 12.5 Hz timer) mark `prop` as wanted is kept.
##
## WHY THE DISTANCE MUST BE FOUND, NOT GUESSED. The rig's fixed viewing geometry (mobile pitch 34
## deg, follow distance ~8.6 m, PIVOT_HEIGHT 1.0 m) means the camera-to-player sight line climbs
## roughly 0.6-0.8 m of height per metre moved tangentially away from the player. A naive "2-3 m
## beyond the prop" (this file's first cut) put the line's height AT the prop's location around
## 2.0-3.0 m by the time it reached back_m=2.5 - clean past a 1.6 m topiary and grazing only the very
## top of a 2.3 m lamp post - so a short prop like a topiary or a rock needs the player MUCH closer
## (measured below: successful back_m ended up under ~1.5 m for short props, further for tall ones
## like a lamp post or a tree). Searching against the real probe function, instead of hand-deriving
## the geometry per prop shape, is also just less likely to be wrong twice.
##
## THE APPROACH DIRECTION ALSO MATTERS. Hub plaza props are scattered in a ring (Bench/FlowerBed/
## Lamp/Topiary/Bunting placed along shared spokes - planet_props.gd ~1420-1462), so an ARBITRARY
## tangent at the prop (e.g. dir.cross(UP)) walks the destination ALONG the ring and lands the player
## overlapping a NEIGHBOUR prop's collider; the character controller then pushes it clear over the
## next ~1s of physics frames, visibly sweeping the sight line across Bench -> Topiary -> empty in
## the very frames a capture wants to be stable in. Approaching along the line from the player's
## PRE-TELEPORT position instead walks in roughly radially, clear of the ring neighbours.
##
## `pitch_deg`, if >0, sets CameraRig._pitch before searching (still clamped to the player-reachable
## PITCH_MIN_DEG..PITCH_MAX_DEG range - a real player can pinch/scroll there). MEASURED NEED: at the
## mobile default pitch (34 deg) and follow distance (8.6 m), a squat prop under ~0.5 m tall (home's
## pebble Rock, 0.45 m) never intersected the real probe at ANY back_m from 0.6 (OCCLUDER_MIN_DIST,
## the game's own floor - anything closer is structurally excluded, see _probe_occluders) up to 3.0 -
## closest approach measured ~0.6-1.5m against an ~0.79m tolerance (SIGHT_RADIUS 0.34 + the rock's
## own 0.45m collision radius), i.e. consistently just short. At pitch=10 deg (still inside the
## player's real range) the same rock occluded cleanly at back_m=0.6, 0.8 and 1.0 - a shallower look
## angle climbs far less height per metre moved away from the player (see the back_m docstring
## above), which matters much more for a short object than a tall one.
func stage(name_fragment: String, back_m: float = -1.0, zoom_m: float = 8.6, pitch_deg: float = -1.0) -> Node3D:
	if _player == null or _rig == null:
		print("CAMFADEPROBE stage: missing player or rig")
		return null
	if pitch_deg > 0.0:
		_rig.set("_pitch", clampf(deg_to_rad(pitch_deg), deg_to_rad(6.0), deg_to_rad(72.0)))
	var found: Array = []
	_find_layer4(get_node("/root/World"), found)
	# Matched on the NODE'S OWN NAME (e.g. "Lamp0", "PuffTree3", "Rock2" - planet_props.gd's spawn
	# label + counter), not the full path: a path-substring match on "Rock" also matched
	# "/root/World/Rocket/Pad/RocketModel/Blocker" (a rocket hull collider) the first time this ran,
	# since "rocket" contains "rock".
	var matches: Array = []
	for col: Node3D in found:
		# A fragment starting with "/" is a node-path prefix instead (the rocket's hull collider and a
		# placed DecoItem have generic names like "Blocker").
		if name_fragment.begins_with("/"):
			if str(col.get_path()).begins_with(name_fragment):
				matches.append(col)
		elif str(col.name).to_lower().begins_with(name_fragment.to_lower()):
			matches.append(col)
	if matches.is_empty():
		print("CAMFADEPROBE stage: no layer-4 prop matching '%s' (n=%d candidates)" % [name_fragment, found.size()])
		return null
	# Try nearest-to-player matches first, not first-in-traversal-order: a planet can have dozens of
	# the same prop scattered across it, and a far one makes the search below meaningless. Try more
	# than one instance, closest few, in case OCCLUDER_MIN_DIST=0.6 (the probe never marks anything
	# within 0.6m of the player: CameraRig._probe_occluders truncates the last 0.6m of every sight
	# line before it reaches the target) plus that particular instance's exact placement (terrain
	# sink, random scatter) puts it just outside SIGHT_RADIUS=0.34 at every distance tried - measured
	# on home's pebble field, where the single nearest Rock never intersected the probe at any of 12
	# tried distances while a different nearby Rock did on the first try.
	var from_pos: Vector3 = _player.global_position
	matches.sort_custom(func(a, b):
		return (a as Node3D).global_position.distance_to(from_pos) < (b as Node3D).global_position.distance_to(from_pos))
	var candidates: Array = [back_m] if back_m > 0.0 else AUTO_BACK_M

	var prop: Node3D = null
	var chosen := -1.0
	var chosen_fwd := Vector3.FORWARD
	var chosen_up := Vector3.UP
	var all_tried: Array[String] = []
	for cand_prop: Node3D in matches.slice(0, mini(5, matches.size())):
		var tried: Array[String] = []
		for bm: float in candidates:
			var r := _place_for(cand_prop, from_pos, bm, zoom_m)
			_rig.call("_probe_occluders", (_rig.call("get_camera") as Camera3D).global_position)
			var faded: Dictionary = _rig.get("_faded")
			var id := cand_prop.get_instance_id()
			var hit := faded.has(id) and float((faded[id] as Dictionary).get("want", 0.0)) > 0.5
			tried.append("%.2f%s" % [bm, "*" if hit else ""])
			if hit:
				chosen = bm
				chosen_fwd = r["fwd"]
				chosen_up = r["up"]
				prop = cand_prop
				break
		all_tried.append("%s:[%s]" % [str(cand_prop.name), ", ".join(tried)])
		if chosen >= 0.0:
			break

	if prop == null:
		# Nothing hit anywhere: fall back to the nearest match, staged at its last (largest) tried
		# distance, for inspection - but say so loudly, since a capture off this run proves nothing
		# about the fade, only that nothing occluded.
		prop = matches[0]
		_place_for(prop, from_pos, candidates[candidates.size() - 1], zoom_m)
		print("CAMFADEPROBE stage: '%s' NEVER intersected the real occluder probe. tried: %s" % [name_fragment, "; ".join(all_tried)])
	else:
		print("CAMFADEPROBE stage: '%s' occludes at back_m=%.2f. tried: %s" % [name_fragment, chosen, "; ".join(all_tried)])
	_staged_prop = prop

	print("CAMFADEPROBE staged prop=%s prop_pos=%s player_pos=%s player_prop_dist=%.2f fwd=%s up=%s zoom=%.2f" % [
		str(prop.get_path()), str(prop.global_position.snapped(Vector3(0.01, 0.01, 0.01))),
		str(_player.global_position.snapped(Vector3(0.01, 0.01, 0.01))),
		prop.global_position.distance_to(_player.global_position), str(chosen_fwd), str(chosen_up), zoom_m])
	return prop


# ============================================================================= readback / reporting
## Prints the staged prop's fade-table transparency read-back and both its and the astronaut's
## screen bounding boxes, converted to capture pixels.
## Diagnostic only: for the currently staged prop, prints the closest approach of each of the three
## camera->sight-height segments to the prop's own position, to see exactly how big a miss is (vs.
## SIGHT_RADIUS=0.34 plus whatever radius the prop's own CollisionShape3D adds).
func diag_closest() -> void:
	if _staged_prop == null or _rig == null or _player == null:
		print("CAMFADEPROBE diag_closest: nothing staged")
		return
	var cam := (_rig.call("get_camera") as Camera3D).global_position
	var feet: Vector3 = _player.global_position
	var up: Vector3 = _player.get("up")
	var q: Vector3 = _staged_prop.global_position
	for h in [0.25, 0.85, 1.45]:
		var target: Vector3 = feet + up * h
		var seg: Vector3 = target - cam
		var seg_len2 := seg.length_squared()
		var t := 0.0
		if seg_len2 > 0.000001:
			t = clampf((q - cam).dot(seg) / seg_len2, 0.0, 1.0)
		var closest: Vector3 = cam + seg * t
		var d := closest.distance_to(q)
		print("CAMFADEPROBE diag_closest h=%.2f t=%.3f closest_dist=%.3f cam=%s target=%s prop=%s" % [
			h, t, d, str(cam.snapped(Vector3(0.01,0.01,0.01))), str(target.snapped(Vector3(0.01,0.01,0.01))), str(q.snapped(Vector3(0.01,0.01,0.01)))])


## Diagnostic only: dumps the rig's live camera/player state so a drift can be timed frame by frame.
func probe_cam(tag: String = "") -> void:
	if _rig == null or _player == null:
		return
	print("CAMFADEPROBE camstate[%s] player_pos=%s player_up=%s rig_fwd=%s rig_up=%s dist=%.3f dist_target=%.3f smoothed_pos=%s cam_pos=%s moving_time=%.3f" % [
		tag, str(_player.global_position), str(_player.get("up")),
		str(_rig.get("_fwd")), str(_rig.get("_up")), float(_rig.get("_dist")), float(_rig.get("_dist_target")),
		str(_rig.get("_smoothed_pos")), str(_rig.get_camera().global_position), float(_rig.get("_moving_time"))])


func report(tag: String = "") -> void:
	if _staged_prop == null or _rig == null:
		print("CAMFADEPROBE report[%s]: nothing staged" % tag)
		return
	var meshes := _collect_like_rig(_staged_prop)
	var id := _staged_prop.get_instance_id()
	var faded: Dictionary = _rig.get("_faded")
	var t_val := -1.0
	if faded.has(id):
		t_val = float((faded[id] as Dictionary).get("t", -1.0))
	var trans_vals: Array = []
	for m: Variant in meshes:
		if is_instance_valid(m):
			trans_vals.append((m as GeometryInstance3D).transparency)
	print("CAMFADEPROBE report[%s] fade_off=%s prop=%s faded_t=%.3f n_meshes=%d transparency=%s" % [
		tag, str(_rig.get("_fade_off")), str(_staged_prop.get_path()), t_val, meshes.size(), str(trans_vals)])
	print_swaps(tag, _staged_prop)
	_print_bbox(tag, "prop", _staged_prop)
	if _player:
		_print_bbox(tag, "player", _player)


func _print_bbox(tag: String, label: String, node: Node3D) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		print("CAMFADEPROBE bbox[%s] %s: no active Camera3D" % [tag, label])
		return
	var box := _global_aabb(node)
	if box.size == Vector3.ZERO and box.position == Vector3.ZERO:
		print("CAMFADEPROBE bbox[%s] %s: no VisualInstance3D found" % [tag, label])
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var win_size: Vector2 = Vector2(DisplayServer.window_get_size())
	var scale := Vector2.ONE
	if vp_size.x > 0.0 and vp_size.y > 0.0:
		scale = Vector2(win_size.x / vp_size.x, win_size.y / vp_size.y)
	var minx := INF
	var miny := INF
	var maxx := -INF
	var maxy := -INF
	var any_in_front := false
	for i in range(8):
		var wp: Vector3 = box.get_endpoint(i)
		if cam.is_position_behind(wp):
			continue
		var p: Vector2 = cam.unproject_position(wp) * scale
		any_in_front = true
		minx = minf(minx, p.x)
		miny = minf(miny, p.y)
		maxx = maxf(maxx, p.x)
		maxy = maxf(maxy, p.y)
	if not any_in_front:
		print("CAMFADEPROBE bbox[%s] %s: all AABB corners behind camera" % [tag, label])
		return
	print("CAMFADEPROBE bbox[%s] %s px=[%.1f,%.1f,%.1f,%.1f] scale=(%.4f,%.4f) vp_size=%s win_size=%s" % [
		tag, label, minx, miny, maxx, maxy, scale.x, scale.y, str(vp_size), str(win_size)])


## Global AABB of every VisualInstance3D under `node` (its own AABB is local; get_aabb() on a plain
## Node3D wrapper is empty), merged in world space.
func _global_aabb(node: Node3D) -> AABB:
	var out_box := AABB()
	var have_any := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var local_box: AABB = (n as VisualInstance3D).get_aabb()
			var gt: Transform3D = (n as Node3D).global_transform
			var world_box := AABB()
			var box_first := true
			for i in range(8):
				var wp: Vector3 = gt * local_box.get_endpoint(i)
				if box_first:
					world_box = AABB(wp, Vector3.ZERO)
					box_first = false
				else:
					world_box = world_box.expand(wp)
			if have_any:
				out_box = out_box.merge(world_box)
			else:
				out_box = world_box
				have_any = true
		for c: Node in n.get_children():
			stack.append(c)
	return out_box


# ============================================================================= shader instance census
## Once per world: counts GeometryInstance3D nodes under /root/World by the shader/material class of
## each surface material they use (mesh surface materials, surface overrides, and material_override),
## and how many of those sit inside a layer-4 occluder (the meshes CameraRig._mark_occluder would
## actually collect for a layer-4 collider). Printed sorted by key for stable diffing.
func count_shaders() -> void:
	var found: Array = []
	_find_layer4(get_node("/root/World"), found)
	var occluder_ids: Dictionary = {}
	for col: Node3D in found:
		for m: Variant in _collect_like_rig(col):
			if is_instance_valid(m):
				occluder_ids[(m as Node).get_instance_id()] = true

	var counts: Dictionary = {}
	_walk_shaders(get_node("/root/World"), counts, occluder_ids)
	var keys: Array = counts.keys()
	keys.sort()
	var total := 0
	var total_occ := 0
	for k in keys:
		total += int((counts[k] as Dictionary)["n"])
		total_occ += int((counts[k] as Dictionary)["occluder_n"])
	print("CAMFADEPROBE shader_counts n_keys=%d total_instances=%d total_in_occluders=%d" % [keys.size(), total, total_occ])
	for k in keys:
		var e: Dictionary = counts[k]
		print("  %-70s n=%d occluder_n=%d" % [k, int(e["n"]), int(e["occluder_n"])])


func _walk_shaders(n: Node, counts: Dictionary, occluder_ids: Dictionary) -> void:
	if n is GeometryInstance3D:
		var gi := n as GeometryInstance3D
		var mats := _materials_of(gi)
		var in_occ := occluder_ids.has(gi.get_instance_id())
		for mat: Material in mats:
			var key := _shader_key(mat)
			if not counts.has(key):
				counts[key] = {"n": 0, "occluder_n": 0}
			var e: Dictionary = counts[key]
			e["n"] = int(e["n"]) + 1
			if in_occ:
				e["occluder_n"] = int(e["occluder_n"]) + 1
	for c: Node in n.get_children():
		_walk_shaders(c, counts, occluder_ids)


func _materials_of(gi: GeometryInstance3D) -> Array:
	var mats: Array = []
	if gi.material_override != null:
		mats.append(gi.material_override)
		return mats
	if gi is MeshInstance3D:
		var mi := gi as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh != null:
			for s in range(mesh.get_surface_count()):
				var m: Material = mi.get_surface_override_material(s)
				if m == null:
					m = mesh.surface_get_material(s)
				if m != null:
					mats.append(m)
	return mats


func _shader_key(mat: Material) -> String:
	if mat is StandardMaterial3D:
		return "StandardMaterial3D"
	if mat is ShaderMaterial:
		var sh: Shader = (mat as ShaderMaterial).shader
		if sh == null:
			return "ShaderMaterial:no_shader"
		if sh.resource_path != "":
			return sh.resource_path
		var code: String = sh.code
		return "generated:%08x" % (hash(code) & 0xFFFFFFFF)
	return mat.get_class()


# ============================================================================= material inventory
## For every layer-4 collider CameraRig would fade, walks the SAME geometry list _mark_occluder
## builds (via _collect_like_rig) and dumps every material slot on every geometry node: owning
## script, geometry class, slot, material class, shader key, shader render_mode/ALPHA/discard/blend/
## unshaded/depth_draw, first 2 lines of shader code, and how many NON-occluder geometry nodes in
## the whole world tree share that exact Material object / Shader object. Rows are grouped by
## (owner desc, geometry class, slot, shader key) with a count, so repeated identical props collapse
## to one line. Read-only: never touches _rig fade state.
func _collect_all_geo(n: Node, out: Array) -> void:
	if n is GeometryInstance3D:
		out.append(n)
	for c: Node in n.get_children():
		_collect_all_geo(c, out)


## Ancestor-walk to find the nearest attached script (DecoItem subclass, PlanetProps-spawned node,
## ProjectMarkers, Building, ...). Falls back to the collider's own node name with trailing digits
## stripped (planet_props.gd's spawn label + counter, e.g. "Lamp0" -> "Lamp") when nothing in the
## chain has a script, which is the common case for planet-scattered props: PlanetProps is a
## RefCounted helper that builds plain StaticBody3D/MeshInstance3D trees with no script attached.
func _strip_digits(s: String) -> String:
	var nm := s
	while nm.length() > 0 and nm.unicode_at(nm.length() - 1) >= 48 and nm.unicode_at(nm.length() - 1) <= 57:
		nm = nm.substr(0, nm.length() - 1)
	return nm


## Nearest ancestor script (DecoItem subclass, ProjectMarkers, BuildingBase, ...) PLUS the
## collider's own node name with trailing digits stripped (planet_props.gd's spawn label + counter,
## e.g. "Lamp0" -> "Lamp"), so distinct props scattered by one generic script (planet.gd's Planet
## node owns every PlanetProps-scattered Lamp/Topiary/PuffTree/Rock - PlanetProps is a RefCounted
## helper with no script of its own attached to the nodes it builds) still show up as separate rows
## instead of collapsing into one "planet.gd" bucket.
func _owner_desc(col: Node3D) -> String:
	var label := _strip_digits(str(col.name))
	var n: Node = col
	var hops := 0
	while n != null and hops < 8:
		var scr: Script = n.get_script()
		if scr != null:
			var p: String = scr.resource_path
			var script_name := p.get_file() if p != "" else "inline_script"
			return "%s/%s" % [script_name, label]
		n = n.get_parent()
		hops += 1
	return "unscripted/%s(parent=%s)" % [label, str(col.get_parent().name) if col.get_parent() else "?"]


## Every (slot_name, Material) pair on one GeometryInstance3D: material_override short-circuits
## surface materials per Godot's own precedence; material_overlay is additive so is always listed
## too; MeshInstance3D also lists per-surface overrides/mesh materials, MultiMeshInstance3D lists its
## MultiMesh.mesh's surface materials, anything else (Label3D, Sprite3D, CSGShape3D, GPUParticles3D)
## falls back to a generic get("material") probe. next_pass chains (up to 4 deep) are appended too,
## since a next_pass draws as its own extra geometry and would also need a fade hook.
func _slots_of(gi: GeometryInstance3D) -> Array:
	var out: Array = []
	var mo: Material = gi.material_override
	if mo != null:
		out.append(["material_override", mo])
	var ov: Material = gi.material_overlay
	if ov != null:
		out.append(["material_overlay", ov])
	if mo == null:
		if gi is MeshInstance3D:
			var mi := gi as MeshInstance3D
			var mesh: Mesh = mi.mesh
			if mesh != null:
				for s in range(mesh.get_surface_count()):
					var som: Material = mi.get_surface_override_material(s)
					if som != null:
						out.append(["surface_override_%d" % s, som])
					else:
						var sm: Material = mesh.surface_get_material(s)
						if sm != null:
							out.append(["mesh_surface_%d" % s, sm])
		elif gi is MultiMeshInstance3D:
			var mm: MultiMesh = (gi as MultiMeshInstance3D).multimesh
			if mm != null:
				var mesh2: Mesh = mm.mesh
				if mesh2 != null:
					for s in range(mesh2.get_surface_count()):
						var sm2: Material = mesh2.surface_get_material(s)
						if sm2 != null:
							out.append(["multimesh_surface_%d" % s, sm2])
		else:
			var maybe: Variant = gi.get("material")
			if maybe != null and maybe is Material:
				out.append(["material", maybe as Material])
	var chain_extra: Array = []
	for pair: Array in out:
		var m: Material = pair[1]
		var np: Material = m.next_pass
		var depth := 0
		while np != null and depth < 4:
			chain_extra.append(["%s.next_pass" % pair[0], np])
			np = np.next_pass
			depth += 1
	out.append_array(chain_extra)
	return out


func _extract_render_mode(code: String) -> String:
	var idx := code.find("render_mode")
	if idx == -1:
		return ""
	var semi := code.find(";", idx)
	if semi == -1:
		return code.substr(idx, mini(140, code.length() - idx))
	return code.substr(idx, semi - idx + 1)


func _extract_depth_draw(mode_str: String) -> String:
	for tok in ["depth_draw_always", "depth_draw_opaque", "depth_draw_never", "depth_draw_alpha_prepass"]:
		if mode_str.find(tok) != -1:
			return tok
	return "default(depth_draw_opaque)"


## Places a few different DecoItems near the player through DecorationManager.place() (the real
## placement API - same one the store/build-bench use), in the scratch save only, so
## dump_occluder_materials() afterward also sees DecoItem-owned occluders. Spreads them at small yaw
## offsets around the player's own surface direction so they do not stack on one spot and fail
## is_spot_free(). Read/write to the save is fine here: this whole project copy is a scratch rsync
## with its own config/name, never the user's real save.
func place_test_decos(item_ids: Array = ["deco_moon_lamp", "deco_beacon_tower", "deco_gear_fountain"]) -> void:
	var mgr := get_node_or_null("/root/World/Decorations")
	if mgr == null or _player == null:
		print("CAMFADEPROBE place_test_decos: no DecorationManager or player")
		return
	var base_dir: Vector3 = _player.global_position.normalized()
	var up: Vector3 = _player.get("up")
	if up.length_squared() < 0.0001:
		up = base_dir
	var tangent: Vector3 = up.cross(Vector3.UP)
	if tangent.length_squared() < 0.0001:
		tangent = up.cross(Vector3.RIGHT)
	tangent = tangent.normalized()
	var i := 0
	for item_id: String in item_ids:
		var ang: float = 0.15 + 0.12 * i  # radians of surface-arc offset per item, ~1.5-2.5m apart
		var dir: Vector3 = (base_dir * cos(ang) + tangent * sin(ang)).normalized()
		var iid: String = mgr.call("place", item_id, dir, 0.0)
		print("CAMFADEPROBE place_test_decos placed item=%s instance_id=%s dir=%s" % [item_id, iid, str(dir)])
		i += 1


func dump_occluder_materials(root_path: String = "/root/World") -> void:
	var root := get_node_or_null(root_path)
	if root == null:
		print("CAMFADEPROBE dump_materials: no node at %s" % root_path)
		return
	var occ_found: Array = []
	_find_layer4(root, occ_found)
	var occluder_ids: Dictionary = {}
	for col: Node3D in occ_found:
		for m: Variant in _collect_like_rig(col):
			if is_instance_valid(m):
				occluder_ids[(m as Node).get_instance_id()] = true

	var all_geo: Array = []
	_collect_all_geo(root, all_geo)

	# How many geometry nodes OUTSIDE the occluder set share the same Material instance / Shader
	# instance as a given occluder material - i.e. how collateral a per-mesh material duplication
	# would be if done by mutating the shared Material in place instead of first .duplicate()-ing it.
	var nonocc_mat_count: Dictionary = {}
	var nonocc_shader_count: Dictionary = {}
	for g: Variant in all_geo:
		if occluder_ids.has((g as Node).get_instance_id()):
			continue
		var seen_mats: Dictionary = {}
		var seen_shaders: Dictionary = {}
		for pair: Array in _slots_of(g as GeometryInstance3D):
			var m: Material = pair[1]
			seen_mats[m.get_instance_id()] = true
			if m is ShaderMaterial and (m as ShaderMaterial).shader != null:
				seen_shaders[(m as ShaderMaterial).shader.get_instance_id()] = true
		for mid in seen_mats:
			nonocc_mat_count[mid] = int(nonocc_mat_count.get(mid, 0)) + 1
		for sid in seen_shaders:
			nonocc_shader_count[sid] = int(nonocc_shader_count.get(sid, 0)) + 1

	var groups: Dictionary = {}
	var non_mesh_geo: Dictionary = {}  # geo class -> count, for occluder geometry that is not MeshInstance3D
	for col: Node3D in occ_found:
		var owner_desc := _owner_desc(col)
		for g: Variant in _collect_like_rig(col):
			if not is_instance_valid(g):
				continue
			var gi := g as GeometryInstance3D
			if not (gi is MeshInstance3D):
				non_mesh_geo[gi.get_class()] = int(non_mesh_geo.get(gi.get_class(), 0)) + 1
			for pair: Array in _slots_of(gi):
				var slot_name: String = pair[0]
				var mat: Material = pair[1]
				var shader_key := _shader_key(mat)
				var key := "%s##%s##%s##%s" % [owner_desc, gi.get_class(), slot_name, shader_key]
				if not groups.has(key):
					var row := {
						"n": 0, "owner": owner_desc, "geo": gi.get_class(), "slot": slot_name,
						"matclass": mat.get_class(), "shaderkey": shader_key,
						"other_mat_nodes": int(nonocc_mat_count.get(mat.get_instance_id(), 0)),
						"other_shader_nodes": 0,
						"render_mode": "", "writes_alpha": false, "discard": false,
						"blend_add": false, "blend_mix": false, "unshaded": false,
						"depth_draw": "", "code2": "",
					}
					if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
						var sh: Shader = (mat as ShaderMaterial).shader
						var code: String = sh.code
						var rm := _extract_render_mode(code)
						row["render_mode"] = rm
						row["writes_alpha"] = code.find("ALPHA") != -1
						row["discard"] = code.find("discard") != -1
						row["blend_add"] = rm.find("blend_add") != -1
						row["blend_mix"] = rm.find("blend_mix") != -1
						row["unshaded"] = rm.find("unshaded") != -1
						row["depth_draw"] = _extract_depth_draw(rm)
						var lines: PackedStringArray = code.split("\n")
						var l2: Array = []
						for i in range(mini(2, lines.size())):
							l2.append(lines[i].strip_edges())
						row["code2"] = " / ".join(l2)
						row["other_shader_nodes"] = int(nonocc_shader_count.get(sh.get_instance_id(), 0))
					groups[key] = row
				groups[key]["n"] = int(groups[key]["n"]) + 1

	var keys: Array = groups.keys()
	keys.sort()
	print("CAMFADEPROBE dump_materials root=%s n_occluder_colliders=%d n_groups=%d non_mesh_geo=%s" % [
		root_path, occ_found.size(), keys.size(), str(non_mesh_geo)])
	for k in keys:
		var r: Dictionary = groups[k]
		print("ROW owner=%s geo=%s slot=%s matclass=%s shader=%s n=%d other_mat_nodes=%d other_shader_nodes=%d render_mode=[%s] alpha=%s discard=%s blend_add=%s blend_mix=%s unshaded=%s depth_draw=%s code2=[%s]" % [
			r["owner"], r["geo"], r["slot"], r["matclass"], r["shaderkey"], r["n"],
			r["other_mat_nodes"], r["other_shader_nodes"], r["render_mode"], r["writes_alpha"],
			r["discard"], r["blend_add"], r["blend_mix"], r["unshaded"], r["depth_draw"], r["code2"]])


# ============================================================================= dither read-back
## The rig's fade entry for `prop` (keyed by the collider's instance id), or {}.
func _entry_for(prop: Node3D) -> Dictionary:
	if prop == null or not is_instance_valid(prop):
		return {}
	var faded: Dictionary = _rig.get("_faded")
	var id := prop.get_instance_id()
	return faded[id] if faded.has(id) else {}


## What one swap record's copy is fading with: "0.900" for a dithering copy's cam_fade, "a0.046" for
## an alpha-blend StandardMaterial3D copy's albedo alpha (camera_rig.gd `_is_alpha_blended`).
func _copy_fade_text(sw: Dictionary) -> String:
	var copy: Variant = sw["copy"]
	if copy is BaseMaterial3D:
		return "a%.3f" % (copy as BaseMaterial3D).albedo_color.a
	var cf: Variant = (copy as ShaderMaterial).get_shader_parameter(&"cam_fade")
	return "%.3f" % float(cf if cf != null else -1.0)


func _slot_now(sw: Dictionary) -> Material:
	var g: Variant = sw["g"]
	if not is_instance_valid(g):
		return null
	return _rig.call("_get_slot", g, int(sw["slot"]), int(sw["surf"]))


## Material slots of the rig's entry: mode, swap count, and per slot whether it holds the rig's copy,
## the original, or something else (game code), plus cam_fade on each copy. Forward+ prints mode
## transparency and swaps=0 (no "swaps" key is ever created there).
var _remembered: Array = []  # swap records captured by remember_swaps(), for check_restore()

func print_swaps(tag: String, prop: Node3D) -> void:
	var e := _entry_for(prop)
	var mode := "dither" if (_rig.get("_dither_fade") == true) else "transparency"
	if e.is_empty() or not e.has("swaps"):
		print("CAMFADEPROBE swaps[%s] mode=%s entry=%s swaps=0" % [tag, mode, str(not e.is_empty())])
		return
	var n_copy := 0
	var n_orig := 0
	var n_other := 0
	var fades: Dictionary = {}
	var slot_names := ["override", "surface", "overlay"]
	var kinds: Dictionary = {}
	for sw: Dictionary in (e["swaps"] as Array):
		var cur := _slot_now(sw)
		if cur == sw["copy"]:
			n_copy += 1
		elif cur == sw["restore"] or cur == sw["orig"]:
			n_orig += 1
		else:
			n_other += 1
		var key := _copy_fade_text(sw)
		fades[key] = int(fades.get(key, 0)) + 1
		var sk := "alpha-blend %s" % (sw["orig"] as Object).get_class()
		if sw["orig"] is ShaderMaterial:
			var sh: Shader = (sw["orig"] as ShaderMaterial).shader
			sk = sh.resource_path.get_file() if sh.resource_path != "" else "generated"
		var k2 := "%s:%s" % [slot_names[int(sw["slot"])], sk]
		kinds[k2] = int(kinds.get(k2, 0)) + 1
	print("CAMFADEPROBE swaps[%s] mode=%s t=%.3f value=%.3f swaps=%d holds_copy=%d holds_orig=%d holds_other=%d live=%d solid_geo=%d solid_kinds=%s cam_fade_on_copies=%s slots=%s" % [
		tag, mode, float(e["t"]), float(e["value"]), (e["swaps"] as Array).size(), n_copy, n_orig, n_other,
		int(_rig.call("_live_swaps", e)), int(e["solid"]), str(e.get("solid_kinds", {})), str(fades), str(kinds)])


## Every rig fade entry right now: prop name, t, want, swaps and live count.
func faded_summary(tag: String = "") -> void:
	var faded: Dictionary = _rig.get("_faded")
	var rows: Array[String] = []
	for id: int in faded:
		var e: Dictionary = faded[id]
		var nm := "?"
		var meshes: Array = e["meshes"]
		if not meshes.is_empty() and is_instance_valid(meshes[0]):
			nm = str((meshes[0] as Node).get_parent().name)
		elif meshes.is_empty():
			nm = "(no meshes)"
		else:
			nm = "(freed)"
		var sw := "-"
		if e.has("swaps"):
			var cf := "?"
			for s: Dictionary in (e["swaps"] as Array):
				if bool(s["live"]):
					cf = _copy_fade_text(s)
					break
			sw = "%d/live%d/cf%s" % [(e["swaps"] as Array).size(), int(_rig.call("_live_swaps", e)), cf]
		rows.append("%s t=%.2f want=%.1f swaps=%s" % [nm, float(e["t"]), float(e["want"]), sw])
	rows.sort()
	print("CAMFADEPROBE faded[%s] frame=%d n=%d %s" % [tag, Engine.get_process_frames(), faded.size(), " | ".join(rows)])


## C1: snapshot the staged prop's swap records (node, slot, original, the value the slot held before).
func remember_swaps(tag: String = "") -> void:
	_remembered.clear()
	var e := _entry_for(_staged_prop)
	if e.has("swaps"):
		for sw: Dictionary in (e["swaps"] as Array):
			_remembered.append(sw.duplicate())
	print("CAMFADEPROBE remember[%s] n=%d" % [tag, _remembered.size()])


## C1/C3: after the fade has gone back to 0, each remembered slot must hold the object it held before
## the fade (instance ids), the effective material must be the original, no copy may remain anywhere
## on the prop's geometry, and the entry must be gone. A slot a test handed to "game code" is reported
## separately (`game`), and must still hold the game material.
func check_restore(tag: String = "") -> void:
	var ok := 0
	var bad := 0
	var game := 0
	var details: Array[String] = []
	var copy_ids: Dictionary = {}
	for sw: Dictionary in _remembered:
		copy_ids[(sw["copy"] as Object).get_instance_id()] = true
	for sw: Dictionary in _remembered:
		var cur := _slot_now(sw)
		var want: Material = sw["restore"]
		var eff: Material = cur
		var g := sw["g"] as GeometryInstance3D
		if int(sw["slot"]) == 1 and cur == null:
			eff = (g as MeshInstance3D).mesh.surface_get_material(int(sw["surf"]))
		if sw.has("game_mat"):
			if cur == sw["game_mat"]:
				game += 1
			else:
				bad += 1
				details.append("game slot clobbered: now=%s" % str(cur))
			continue
		if cur == want and eff == sw["orig"]:
			ok += 1
		else:
			bad += 1
			details.append("slot=%d surf=%d now_id=%s want_id=%s orig_id=%d" % [int(sw["slot"]), int(sw["surf"]),
				str(cur.get_instance_id() if cur else 0), str(want.get_instance_id() if want else 0), (sw["orig"] as Object).get_instance_id()])
	var copies_left := 0
	if _staged_prop != null and is_instance_valid(_staged_prop):
		for g: Variant in _collect_like_rig(_staged_prop):
			var gi := g as GeometryInstance3D
			var mats: Array = [gi.material_override, gi.material_overlay]
			if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
				for i in range((gi as MeshInstance3D).mesh.get_surface_count()):
					mats.append((gi as MeshInstance3D).get_surface_override_material(i))
			for m: Variant in mats:
				if m != null and copy_ids.has((m as Object).get_instance_id()):
					copies_left += 1
	var e := _entry_for(_staged_prop)
	print("CAMFADEPROBE restore[%s] remembered=%d restored_ok=%d bad=%d game_kept=%d copies_left=%d entry_present=%s %s" % [
		tag, _remembered.size(), ok, bad, game, copies_left, str(not e.is_empty()), "; ".join(details)])


## Moves the camera off the staged prop's sight line (turns the heading 180 deg) so it fades back.
func look_away() -> void:
	var f: Vector3 = _rig.get("_fwd")
	_rig.set("_fwd", -f)
	_rig.call("_snap_to_target")
	print("CAMFADEPROBE look_away")


## C3: game code takes over one swapped slot mid-fade. Puts a DUPLICATE of the original (hookable,
## so a stray write would show up as cam_fade != 0 on it) into the slot of the first remembered swap.
func game_takes_slot(tag: String = "") -> void:
	if _remembered.is_empty():
		print("CAMFADEPROBE game_takes_slot[%s]: nothing remembered" % tag)
		return
	# A dithering (ShaderMaterial) slot: an alpha-blend glass copy has no cam_fade to read back.
	var sw: Dictionary = _remembered[0]
	for cand: Dictionary in _remembered:
		if cand["orig"] is ShaderMaterial:
			sw = cand
			break
	var gm := (sw["orig"] as Material).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"cam_fade", 0.0)
	_rig.call("_set_slot", sw["g"], int(sw["slot"]), int(sw["surf"]), gm)
	sw["game_mat"] = gm
	print("CAMFADEPROBE game_takes_slot[%s] slot=%d surf=%d geo=%s" % [tag, int(sw["slot"]), int(sw["surf"]), str((sw["g"] as Node).name)])


func game_slot_state(tag: String = "") -> void:
	for sw: Dictionary in _remembered:
		if sw.has("game_mat"):
			var gm := sw["game_mat"] as ShaderMaterial
			print("CAMFADEPROBE game_slot[%s] slot_holds_game=%s game_mat_cam_fade=%.3f" % [tag, str(_slot_now(sw) == gm), float(gm.get_shader_parameter(&"cam_fade"))])
	print_swaps(tag, _staged_prop)


## C2: frees the staged prop mid-fade, then reports the fade table on the next three frames.
func free_staged(tag: String = "") -> void:
	if _staged_prop == null or not is_instance_valid(_staged_prop):
		print("CAMFADEPROBE free_staged[%s]: nothing staged" % tag)
		return
	faded_summary(tag + "_before")
	var id := _staged_prop.get_instance_id()
	var victim: Node = _staged_prop
	print("CAMFADEPROBE free_staged[%s] freeing=%s" % [tag, str(victim.get_path())])
	victim.queue_free()
	_staged_prop = null
	for i in range(3):
		await get_tree().process_frame
		var faded: Dictionary = _rig.get("_faded")
		print("CAMFADEPROBE free_staged[%s] +%d frames entry_present=%s" % [tag, i + 1, str(faded.has(id))])
		faded_summary("%s_+%d" % [tag, i + 1])


## C2 (beacons): clears the project find markers mid-fade, if the node exists.
func clear_markers(tag: String = "") -> void:
	var pm := _project_markers()
	if pm == null:
		print("CAMFADEPROBE clear_markers[%s]: no ProjectMarkers node" % tag)
		return
	faded_summary(tag + "_before")
	pm.call("clear_markers")
	for i in range(3):
		await get_tree().process_frame
		faded_summary("%s_+%d" % [tag, i + 1])


## C4: counts swap/restore cycles by watching entries gain and lose "swaps" every frame.
var _cycle_watch := false
var _cycle_seen: Dictionary = {}
var _swap_cycles := 0
var _restore_cycles := 0

func watch_cycles(on: bool) -> void:
	_cycle_watch = on
	print("CAMFADEPROBE cycles watch=%s swaps_started=%d restored=%d" % [str(on), _swap_cycles, _restore_cycles])


func _process(_delta: float) -> void:
	if _pinned != null and is_instance_valid(_pinned) and _rig != null:
		_rig.call("_mark_occluder", _pinned)
	if not _cycle_watch or _rig == null:
		return
	var faded: Dictionary = _rig.get("_faded")
	var now: Dictionary = {}
	for id: int in faded:
		if (faded[id] as Dictionary).has("swaps"):
			now[id] = true
			if not _cycle_seen.has(id):
				_swap_cycles += 1
	for id: int in _cycle_seen:
		if not now.has(id):
			_restore_cycles += 1
	_cycle_seen = now


## C4 end state: no layer-4 geometry anywhere may still show a cam_fade > 0 in any slot.
func scan_dithered(tag: String = "") -> void:
	var found: Array = []
	_find_layer4(get_node("/root/World"), found)
	var n_geo := 0
	var n_dithered := 0
	for col: Node3D in found:
		for g: Variant in _collect_like_rig(col):
			var gi := g as GeometryInstance3D
			n_geo += 1
			var mats: Array = [gi.material_override, gi.material_overlay]
			if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
				for i in range((gi as MeshInstance3D).mesh.get_surface_count()):
					mats.append((gi as MeshInstance3D).get_surface_override_material(i))
			for m: Variant in mats:
				if m is ShaderMaterial:
					var v: Variant = (m as ShaderMaterial).get_shader_parameter(&"cam_fade")
					if v != null and float(v) > 0.0:
						n_dithered += 1
	print("CAMFADEPROBE scan_dithered[%s] geo=%d slots_with_cam_fade_gt0=%d faded_entries=%d" % [tag, n_geo, n_dithered, (_rig.get("_faded") as Dictionary).size()])


## C1 (SYNTHESISED exit from the sight line): excludes the staged prop's collider from the rig's
## sight-line query, so the probe stops hitting it and it fades back WITHOUT anything physical changing
## (an earlier version cleared its collision layer; the astronaut, no longer blocked, shifted and the
## camera followed, so the "restored" frame was not comparable to the "off" frame). The camera stays
## put, so the "restored" frame is comparable to the same run's "off" frame.
func drop_from_probe() -> void:
	if _staged_prop == null or not (_staged_prop is CollisionObject3D):
		print("CAMFADEPROBE drop_from_probe: staged prop is not a CollisionObject3D")
		return
	var q: PhysicsShapeQueryParameters3D = _rig.get("_sight_query")
	q.exclude = [(_staged_prop as CollisionObject3D).get_rid()]
	print("CAMFADEPROBE drop_from_probe excluded rid of %s" % str(_staged_prop.name))


## C2 helper (SYNTHESISED): keeps a second prop marked as an occluder every frame, after the rig's own
## probe has run (process priority 11 > the rig's 10), so two props fade at once without hunting for a
## spot where two really overlap. Nearest layer-4 prop whose node name starts with `name_fragment`.
var _pinned: Node3D = null

func pin_prop(name_fragment: String) -> void:
	var found: Array = []
	_find_layer4(get_node("/root/World"), found)
	var best: Node3D = null
	var best_d := INF
	for col: Node3D in found:
		if col == _staged_prop or not str(col.name).to_lower().begins_with(name_fragment.to_lower()):
			continue
		var d := col.global_position.distance_to(_player.global_position)
		if d < best_d:
			best_d = d
			best = col
	_pinned = best
	process_priority = 11
	print("CAMFADEPROBE pin_prop %s dist=%.2f" % [str(best.get_path()) if best else "none", best_d])


## Finds the first find beacon's collider under ProjectMarkers and stages it (OPEN_ISSUES 53's case).
func stage_marker(zoom_m: float = 8.6) -> void:
	var pm := _project_markers()
	if pm == null:
		print("CAMFADEPROBE stage_marker: no ProjectMarkers node")
		return
	for c: Node in pm.get_children():
		var col := c.find_child("Collider", true, false)
		if col != null:
			print("CAMFADEPROBE stage_marker using %s" % str(col.get_path()))
			stage(str(col.get_path()), -1.0, zoom_m)
			return
	print("CAMFADEPROBE stage_marker: ProjectMarkers has no beacon with a Collider (children=%d)" % pm.get_child_count())


## The live ProjectMarkers node (ProjectSystem names it "Markers"), or null.
func _project_markers() -> Node:
	var ps: Variant = ProjectSystem.get_or_create()
	if ps == null:
		return null
	return (ps as Node).get_node_or_null("Markers")


## B3/C2 (SYNTHESISED start): puts Bolt's project on step 0 and asks it, the way the first talk would,
## so the step's find beacons are drawn. Needs --campaign (gates on) and a scratch save.
func start_project_step0(npc_id: String = "bolt") -> void:
	var ps: ProjectSystem = ProjectSystem.get_or_create()
	var d: Dictionary = ps.definition_for(npc_id)
	if d.is_empty():
		print("CAMFADEPROBE start_project_step0: no definition for %s (gates_on=%s)" % [npc_id, str(CampaignData.gates_on())])
		return
	ps.call("_start", npc_id)
	ps.call("_ask", npc_id, d, 0)
	var pm := _project_markers()
	print("CAMFADEPROBE start_project_step0 %s markers=%s" % [npc_id, str(pm.call("marker_ids")) if pm else "none"])


## B3: names the geometry of the staged prop's entry that got NO dithering copy (what stays solid), with
## the class of each material it draws with, and every MultiMeshInstance3D with whether it was swapped.
func list_solid(tag: String = "") -> void:
	var e := _entry_for(_staged_prop)
	if e.is_empty() or not e.has("swaps"):
		print("CAMFADEPROBE solid[%s]: no swapped entry" % tag)
		return
	var swapped: Dictionary = {}
	for sw: Dictionary in (e["swaps"] as Array):
		if is_instance_valid(sw["g"]):
			swapped[(sw["g"] as Object).get_instance_id()] = true
	for g: Variant in (e["meshes"] as Array):
		if not is_instance_valid(g):
			continue
		var gi := g as GeometryInstance3D
		var is_mm := gi is MultiMeshInstance3D
		if swapped.has(gi.get_instance_id()) and not is_mm:
			continue
		var mats: Array[String] = []
		for pair: Array in _slots_of(gi):
			var m: Material = pair[1]
			mats.append("%s=%s" % [pair[0], _shader_key(m)])
		var extra := ""
		if is_mm:
			var mm := (gi as MultiMeshInstance3D).multimesh
			extra = " multimesh instances=%d surfaces=%d" % [mm.instance_count if mm else -1, mm.mesh.get_surface_count() if mm and mm.mesh else -1]
		print("CAMFADEPROBE solid[%s] %s %s swapped=%s visible=%s%s mats=%s" % [tag, str(_staged_prop.get_path_to(gi)), gi.get_class(),
			str(swapped.has(gi.get_instance_id())), str(gi.is_visible_in_tree()), extra, ", ".join(mats)])


## C1: lets the rig's sight-line query see the staged prop again (undoes drop_from_probe).
func undrop() -> void:
	var q: PhysicsShapeQueryParameters3D = _rig.get("_sight_query")
	q.exclude = []
	print("CAMFADEPROBE undrop")
