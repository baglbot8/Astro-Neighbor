extends Node
## PLANET-SIZE probe (STYLE_GUIDE R2.11). Injected into /root/World by a Director "call" step:
##   {"call": {"node": "/root/World", "method": "_spawn_optional",
##             "args": ["res://tests/director/size_probe.tscn", "SizeProbe"]}}
## then driven with further "call" steps on /root/World/SizeProbe.
##
## It answers the three questions the size change has to survive:
##   report()      is the planet the size GameState says it is, and does the geometry cache key
##                 actually move when the size level moves (a stale key would hand the resized
##                 planet the OLD mesh)?
##   seat_check()  is every prop, collectible, decoration and the player still exactly on the
##                 ground — nothing floating, nothing sunk?
##   collision()   does the physics surface agree with height_at() at the player's feet?
## Read-only apart from `set_home_size`, which is the whole point of the upgrade-path proof.

var _planet: Planet
var _player: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_planet = get_node_or_null("/root/World/Planet") as Planet
	_player = get_node_or_null("/root/World/Player") as Node3D


## One line of "what size is this planet, and by what authority".
func report(tag: String = "") -> void:
	if _planet == null:
		print("SIZE [%s] no planet" % tag)
		return
	var d := _planet.data
	print("SIZE [%s] id=%s  GameState.home_planet_size=%d  HOME_RADII=%s" % [
		tag, d.id, GameState.home_planet_size, str(PlanetData.HOME_RADII)])
	print("SIZE [%s]   planet.radius=%.3f  data.radius=%.3f  effective_radius=%.3f  vscale=%.4f ascale=%.4f" % [
		tag, _planet.radius, d.radius, PlanetData.effective_radius(d),
		_planet.vertical_scale(), _planet.area_scale()])
	print("SIZE [%s]   geo_key=%s  cached_keys=%s" % [
		tag, Planet._geo_key(d), str(Planet._geo_cache.keys())])
	var aabb: AABB = _planet.surface_mesh.mesh.get_aabb() if _planet.surface_mesh != null else AABB()
	print("SIZE [%s]   ground mesh aabb size=%s (should be ~2x radius + relief)" % [
		tag, str(aabb.size.snapped(Vector3(0.01, 0.01, 0.01)))])
	_planet.terrain_stats(3000, true)


## Every placed thing's base against height_at() along its own direction. Anything outside
## +/- `tol` metres is floating or buried; props are deliberately sunk a few cm, so a small
## NEGATIVE number is correct and a positive one is a gap.
func seat_check(tol: float = 0.25) -> void:
	if _planet == null:
		return
	var groups := {
		"props": _planet.get_node_or_null("Props"),
		"collectibles": _planet.get_node_or_null("Collectibles"),
		"decorations": get_node_or_null("/root/World/Decorations"),
		"npcs": get_node_or_null("/root/World/NPCs"),
		"buildings": get_node_or_null("/root/World/Buildings"),
	}
	for label in groups:
		var root: Node = groups[label]
		if root == null:
			continue
		var n := 0
		var worst := 0.0
		var worst_name := ""
		var bad := 0
		for child in root.get_children():
			if not (child is Node3D):
				continue
			var p: Vector3 = (child as Node3D).global_position - _planet.global_position
			if p.length_squared() < 0.01:
				continue
			n += 1
			var delta: float = p.length() - _planet.height_at(p.normalized())
			if absf(delta) > absf(worst):
				worst = delta
				worst_name = child.name
			if absf(delta) > tol:
				bad += 1
				if bad <= 5:
					print("SIZE   OFF-GROUND %s/%s  delta=%+.3f m" % [label, child.name, delta])
		if n > 0:
			print("SIZE seat %-12s n=%3d  worst=%+.3f m (%s)  outside +/-%.2f: %d" % [label, n, worst, worst_name, tol, bad])
	if _player != null:
		var pp: Vector3 = _player.global_position - _planet.global_position
		print("SIZE seat player       feet_delta=%+.3f m  (dist %.3f vs ground %.3f)" % [
			pp.length() - _planet.height_at(pp.normalized()), pp.length(), _planet.height_at(pp.normalized())])


## Raycasts onto the real collision shape from above the player and compares the hit radius with
## height_at(). They must agree — that equality is the contract the whole planet is built on.
func collision() -> void:
	if _planet == null or _player == null:
		return
	var space := _planet.get_world_3d().direct_space_state
	var dir: Vector3 = (_player.global_position - _planet.global_position).normalized()
	var hits := 0
	var worst := 0.0
	for i in 24:
		var a := TAU * float(i) / 24.0
		var xf := _planet.surface_transform(dir)
		var t: Vector3 = (dir + (xf.basis.x * cos(a) + xf.basis.z * sin(a)) * (2.5 / _planet.radius)).normalized()
		var from: Vector3 = _planet.global_position + t * (_planet.radius + 6.0)
		var to: Vector3 = _planet.global_position + t * (_planet.radius - 4.0)
		var q := PhysicsRayQueryParameters3D.create(from, to, 1)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		hits += 1
		var delta: float = (hit["position"] as Vector3).distance_to(_planet.global_position) - _planet.height_at(t)
		if absf(delta) > absf(worst):
			worst = delta
	print("SIZE collision rays=%d/24 hit, worst |mesh - height_at| = %+.4f m" % [hits, worst])


## Proves the PREBUILD cache (the rocket warms it mid-cruise) cannot hand a resized planet the old
## mesh: prebuild at the current level, then move the level and ask whether it is still prebuilt.
func cache_probe() -> void:
	var d: PlanetData = load("res://src/planet/data/home.tres")
	var start: int = GameState.home_planet_size
	Planet.prebuild(d)
	print("SIZE cache  level=%d key=%s is_prebuilt=%s" % [start, Planet._geo_key(d), str(Planet.is_prebuilt(d))])
	for level in [start + 1, start + 2]:
		GameState.home_planet_size = level
		print("SIZE cache  level=%d key=%s is_prebuilt=%s  (false = the resize invalidated it)" % [
			level, Planet._geo_key(d), str(Planet.is_prebuilt(d))])
	GameState.home_planet_size = start
	print("SIZE cache  back to level=%d key=%s is_prebuilt=%s  (true = the original bake is still valid)" % [
		start, Planet._geo_key(d), str(Planet.is_prebuilt(d))])


## Wall-clock cost of baking one planet's geometry (mesh + trimesh + prop scatter), which is the
## hitch the rocket's `prebuild` exists to hide. Smaller planets carry fewer props, so this should
## have gone DOWN with R2.11 even though the mesh subdivision is unchanged.
func build_one(id: String) -> void:
	var d: PlanetData = load("res://src/planet/data/%s.tres" % id)
	Planet._geo_cache.erase(Planet._geo_key(d))
	var t := Time.get_ticks_usec()
	Planet.prebuild(d)
	print("SIZE build %-5s R=%.1f  %.0f ms" % [id, PlanetData.effective_radius(d), (Time.get_ticks_usec() - t) / 1000.0])


func build_time() -> void:
	for id in ["home", "zorp", "bolt", "hub", "fen", "grig", "vela"]:
		var d: PlanetData = load("res://src/planet/data/%s.tres" % id)
		Planet._geo_cache.erase(Planet._geo_key(d))
		var t := Time.get_ticks_usec()
		Planet.prebuild(d)
		print("SIZE build %-5s R=%.1f  %.0f ms" % [id, PlanetData.effective_radius(d), (Time.get_ticks_usec() - t) / 1000.0])


## The upgrade itself, as a data change. Level only — nothing else in the game moves.
func set_home_size(level: int) -> void:
	GameState.home_planet_size = level
	print("SIZE set home_planet_size=%d -> home radius %.1f m" % [level, PlanetData.home_radius_for_level(level)])


## Places one of everything the player starts with, in a ring `dist_m` in front of the spawn, so a
## frame can answer "is a placed decoration still legible at this planet size".
func place_starter_ring(dist_m: float = 3.6) -> void:
	var deco := get_node_or_null("/root/World/Decorations")
	if deco == null or _planet == null:
		return
	var spawn: Vector3 = _planet.data.spawn_dir.normalized()
	var xf := _planet.surface_transform(spawn, Vector3.FORWARD)
	var items := ["deco_moon_lamp", "deco_star_flag", "deco_crater_bench"]
	for i in items.size():
		# -Z is the facing the player spawns with, so fan the ring out in front of them.
		var a := deg_to_rad(-38.0 + 38.0 * float(i))
		var off: Vector3 = (-xf.basis.z * cos(a) + xf.basis.x * sin(a)) * (dist_m / _planet.radius)
		var d: Vector3 = (spawn + off).normalized()
		var id: String = deco.place(items[i], d, 0.0)
		print("SIZE placed %s -> %s (%.1f m from spawn)" % [items[i], id, _planet.surface_distance(spawn, d)])
