class_name GiantAsteroid
extends Node3D
## The giant asteroid of the Phase 5 ending (docs/PHASE5_SPEC.md §4 "Asteroid"). It hangs over the
## Commons for the meeting (stages 1-3) and breaks apart when the gold rocket reaches it (§2
## send-off, 11.0 s). Built once, procedural, driven by FinaleMeeting (place) and FinaleLaunch
## (break_at).
##
## FRIENDLY, NOT MENACING. It is CrashAsteroid's lumpy space potato grown up - the same recipe, the
## same lavender grey (#8a839b, S ~0.15), matte stone microsurface - hanging still and turning
## slowly. No fire, no glowing cracks, no spikes, no red. When it breaks it does not explode: ten
## pieces part a hand's width over a warm gold core, warm up and shrink (scale, never fade) into
## streak heads for the meteor shower.
##
## DRAWS. One draw before the flash (the rock), two after (the ten chunks share ONE mesh and one
## material; the core is the second). The chunks move on the CPU: the mesh stores positions in its
## own vertex stream (stride 12, normals after it), so each break_at() rewrites that stream with
## `mesh_surface_update_vertex_region`. Chunks only translate and scale uniformly about their own
## centroid, so normals, colours and UVs never change and are never re-uploaded.
##
## SHADERS. The rock and the chunks use `PlanetPropMeshes.rock_material()` (the chunk material is a
## `duplicate()` that shares its Shader and only changes emission uniforms); the core is
## `MaterialLib.glow("#ffe0a0")` duplicated for its day scale (the toon shader every NPC draws).
## No new Shader: both are drawn in Commons gameplay already. `warm_materials()` lists all three.

## The rock's nominal radius before the recipe's squash. §4 says 11 m and "~10 deg across"; the two
## disagree once the recipe is applied. MEASURED at 130 m over 24 axes and a full turn
## (showcase/finale_l1_probe.gd, report mode): 11.0 m spans 10.23-12.12 deg, because the 1.14 squash,
## the +-13% facet jitter and the shoulder lump stick out past the nominal radius. Scaling the whole
## recipe by 0.895 (an exact ratio into the 9-11 deg band, not a look tweak) puts it at 9.16-10.85.
const RADIUS := 9.85
## §4 placement, from the crowd centre: distance, elevation above its local horizontal, and the
## angle off the bearing to the pad.
const DISTANCE := 130.0
const ELEVATION_DEG := 24.0
const OFF_PAD_DEG := 20.0
## Slow turn about the rock's local up (the planet's up at the crowd). A turn about up keeps the
## recipe's dark undersides facing down; a roll would carry them over the top. <= 3 deg/s (§4).
const TUMBLE_DEG_S := 2.0

const CHUNK_COUNT := 10
## Warm glow the chunks heat to and the core's colour (§4).
const WARM := Color("#ffe0a0")
## Emission the chunks reach at full warmth. Day scale 1.0 so a noon break still reads warm.
const CHUNK_WARM_STRENGTH := 1.6
const CORE_STRENGTH := 0.6
## Core size as a fraction of RADIUS: big enough at the flash to fill every crack (so a crack shows
## gold, never sky), shrinking with the chunks so the end state is a small warm radiant.
const CORE_R0 := 0.80
const CORE_R_END := 0.30

## The break schedule, t in seconds since the flash (§2: "by 11.4 s chunks part 0.5-1.5 m over the
## gold core; by 13 s they warm, shrink and become streak heads").
## Each chunk's centroid moves out along its own direction by part_distance(t) metres.
const PART_T := 0.4
const END_T := 2.0
## MEASURED on the ten cells (showcase/finale_l1_probe.gd report, all 25 touching pairs, counting a
## vertex that three chunks share): the seam opening between two touching chunks is 0.731-1.768x the
## distance each moves. So a move of 0.5/0.731 = 0.684 m or more opens every seam at least 0.5 m, and
## 1.5/1.768 = 0.848 m or less keeps the widest one inside 1.5 m. D0 and D1 sit inside those bounds
## (round-2 fix: D1 was 0.85, which opened the one point-touching pair to 1.503 m at 0.4 s). After
## PART_T the chunks shrink into streak heads, so the gaps between them grow by design (§2).
const PART_D0 := 0.70
const PART_D1 := 0.84
const PART_D2 := 0.90
## A chunk shrinks about its centroid until its longest extent is this many metres.
const HEAD_SIZE := 0.9

const FILL_LAYER := CrashAsteroid.FILL_LAYER
const ENV_PATH := "/root/World/Environment"

var _spin: Node3D
var _rock: MeshInstance3D
var _core: MeshInstance3D
var _fill: DirectionalLight3D
var _mesh: ArrayMesh
var _rest_pos := PackedVector3Array()
## Per chunk: first vertex, vertex count, rest centroid, unit direction, head scale.
var _chunk_first := PackedInt32Array()
var _chunk_count := PackedInt32Array()
var _chunk_centroid := PackedVector3Array()
var _chunk_dir := PackedVector3Array()
var _chunk_head_scale := PackedFloat32Array()
var _warm_mat: ShaderMaterial
var _core_mat: ShaderMaterial
var _whole_tri_hash := 0
var _chunk_tri_hash := 0
var _broken := false
var _pose := PackedVector3Array()
var _break_t := -1.0
var _tumble_on := true
var _tumble_t := 0.0
var _fill_on := true
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D


func _ready() -> void:
	if _spin == null:
		_build()


func _build() -> void:
	_spin = Node3D.new()
	_spin.name = "Spin"
	add_child(_spin)
	_build_rock()
	_build_core()
	_build_fill()


## The materials this rock will ever draw, for a warm-up quad (§7). The chunk material differs from
## the rock's only in uniforms, but is listed so a caller can draw exactly what the break draws.
static func warm_materials() -> Array[Material]:
	return [PlanetPropMeshes.rock_material(), _make_warm_material(), _make_core_material()]


## Hangs the rock over the Commons. `crowd_centre` is a world point; `axis` is the meeting axis (a
## unit vector from the pad out toward the crowd, §2); `planet` is the Commons' Planet. The pad
## bearing is taken from the planet's real pad position when it has one, otherwise from -axis.
func place(crowd_centre: Vector3, axis: Vector3, planet: Node3D) -> void:
	if _spin == null:
		_build()
	var up := Vector3.UP
	if planet != null:
		var r := crowd_centre - planet.global_position
		if r.length_squared() > 0.0001:
			up = r.normalized()
		# Measure from the ground under the crowd, not a head-height point: the far side of the Commons
		# is only ~1 m inside §4's 162 m at 130 m out, and 1.5 m of eye height would push it past.
		if planet.has_method("surface_point"):
			crowd_centre = planet.surface_point(r)
	var bearing := -axis
	if planet != null and planet.has_method("surface_point") and "data" in planet and planet.data != null:
		var pad: Vector3 = planet.surface_point(planet.data.pad_dir)
		var to_pad := pad - crowd_centre
		if (to_pad - up * to_pad.dot(up)).length_squared() > 0.01:
			bearing = to_pad
	bearing = bearing - up * bearing.dot(up)
	if bearing.length_squared() < 0.0001:
		bearing = up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD)
	bearing = bearing.normalized().rotated(up, deg_to_rad(OFF_PAD_DEG))
	var el := deg_to_rad(ELEVATION_DEG)
	var dir := (bearing * cos(el) + up * sin(el)).normalized()
	var pos := crowd_centre + dir * DISTANCE
	# Local +Y = the planet's up at the crowd (dark undersides face the ground); -Z faces the crowd
	# (bearing is the horizontal direction from the crowd toward the rock).
	var x := up.cross(bearing).normalized()
	global_transform = Transform3D(Basis(x, up, bearing), pos)
	# Planetshine fill from the crowd centre toward the rock: its -Z is the direction light travels.
	_fill.global_transform = Transform3D(Basis.looking_at(dir, up if absf(dir.dot(up)) < 0.99 else x), pos)
	_update_fill()


## World-space centre of the rock.
func centre() -> Vector3:
	return global_position


## Longest half-extent of the unbroken rock in metres (for camera framing).
func bounding_radius() -> float:
	var r := 0.0
	for p in _rest_pos:
		r = maxf(r, p.length())
	return r


## Poses the break deterministically, `t` in seconds since the flash. t < 0 restores the whole rock.
## 0: the chunks have parted PART_D0 over the core; PART_T: parted PART_D1, not yet shrunk;
## END_T: parted PART_D2, fully warm, shrunk to HEAD_SIZE (held for any later t).
func break_at(t: float) -> void:
	if _spin == null:
		_build()
	if t < 0.0:
		_break_t = -1.0
		_write_positions(_rest_pos)
		_rock.material_override = PlanetPropMeshes.rock_material()
		_core.visible = false
		_broken = false
		return
	# Past END_T the pose is fixed: skip the ~76 us rewrite (measured, Compatibility, Mac).
	if _broken and t >= END_T and _break_t >= END_T:
		_break_t = t
		return
	_break_t = t
	if not _broken:
		_rock.material_override = _warm_mat
		_core.visible = true
		_broken = true
	var d := part_distance(t)
	var k := shrink_weight(t)
	var out := PackedVector3Array()
	for i in CHUNK_COUNT:
		var s := lerpf(1.0, _chunk_head_scale[i], k)
		var c := _chunk_centroid[i]
		# p' = c + s (p - c) + dir d
		var xf := Transform3D(Basis.from_scale(Vector3(s, s, s)), c * (1.0 - s) + _chunk_dir[i] * d)
		out.append_array(xf * _rest_pos.slice(_chunk_first[i], _chunk_first[i] + _chunk_count[i]))
	_write_positions(out)
	_warm_mat.set_shader_parameter("emission_strength", CHUNK_WARM_STRENGTH * warm_weight(t))
	var cr := lerpf(CORE_R0, CORE_R_END, k)
	_core.scale = Vector3(cr, cr, cr)


## World-space centroid of each chunk in its current pose (rest centroids before any break).
func chunk_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	var d := part_distance(_break_t) if _break_t >= 0.0 else 0.0
	for i in CHUNK_COUNT:
		out.append(_spin.global_transform * (_chunk_centroid[i] + _chunk_dir[i] * d))
	return out


## Chunks parted by this many metres along their own direction at t (0 before the flash).
static func part_distance(t: float) -> float:
	if t < 0.0:
		return 0.0
	if t <= PART_T:
		var a := t / PART_T
		return lerpf(PART_D0, PART_D1, 1.0 - (1.0 - a) * (1.0 - a))
	return lerpf(PART_D1, PART_D2, smoothstep(PART_T, END_T, t))


## 0 until PART_T, 1 at END_T: how far the chunks and core have shrunk.
static func shrink_weight(t: float) -> float:
	return smoothstep(PART_T, END_T, t)


## 0 at the flash, 1 at END_T. Eased in, so the pieces are still stone-grey while they part.
static func warm_weight(t: float) -> float:
	var a := clampf(t / END_T, 0.0, 1.0)
	return a * a


## Slow turn on/off (FinaleLaunch may freeze it for a deterministic send-off).
func set_tumble_enabled(on: bool) -> void:
	_tumble_on = on


## Sets the turn directly: `seconds` of TUMBLE_DEG_S.
func set_tumble_time(seconds: float) -> void:
	_tumble_t = seconds
	_spin.basis = Basis(Vector3.UP, deg_to_rad(TUMBLE_DEG_S) * _tumble_t)


## The planetshine fill on/off (test hook for "the fill lights only the rock").
func set_fill_enabled(on: bool) -> void:
	_fill_on = on
	_update_fill()


func _process(delta: float) -> void:
	if _tumble_on:
		set_tumble_time(_tumble_t + delta)
	_update_fill()


## Energy and colour of the brighter of the sun and the moon (§4 "planetshine, no fitted ratio").
func _update_fill() -> void:
	if _fill == null:
		return
	if _sun == null or not is_instance_valid(_sun) or _moon == null or not is_instance_valid(_moon):
		var env := get_node_or_null(ENV_PATH)
		if env != null:
			_sun = env.get_node_or_null("Sun") as DirectionalLight3D
			_moon = env.get_node_or_null("MoonLight") as DirectionalLight3D
	var e := 0.0
	if _sun != null and is_instance_valid(_sun) and _sun.visible:
		e = _sun.light_energy
	if _moon != null and is_instance_valid(_moon) and _moon.visible:
		e = maxf(e, _moon.light_energy)
	# Colour stays white: planetshine is light thrown back off the Commons' cream paving, not the
	# key light's tint. MEASURED: taking the moon's colour turned the whole rock blue at 23:00.
	_fill.visible = _fill_on and visible and e > 0.0
	_fill.light_energy = e


# ------------------------------------------------------------------------------------------ build
func _build_rock() -> void:
	# The chunks are cut from the kit's own float arrays, not from a read-back of the committed mesh:
	# a read-back normal has been through the 16-bit octahedral encoding once already, and encoding it
	# again drifts ~1e-4, which would make the chunk vertices differ from the whole rock's.
	var kit := _rock_kit()
	var v: PackedVector3Array = kit._verts
	var n: PackedVector3Array = kit._norms
	var col: PackedColorArray = kit._cols
	var uv: PackedVector2Array = kit._uvs
	var ix: PackedInt32Array = kit._idx
	var whole := kit.commit()
	var wa: Array = whole.surface_get_arrays(0)
	_whole_tri_hash = _tri_multiset_hash(wa[Mesh.ARRAY_VERTEX], wa[Mesh.ARRAY_NORMAL], wa[Mesh.ARRAY_COLOR], wa[Mesh.ARRAY_INDEX])
	# Ten chunk directions, evenly spread (Fibonacci sphere), in the unsquashed frame.
	var dirs := PackedVector3Array()
	for i in CHUNK_COUNT:
		var yy := 1.0 - 2.0 * (float(i) + 0.5) / float(CHUNK_COUNT)
		var rr := sqrt(maxf(0.0, 1.0 - yy * yy))
		var ph := float(i) * PI * (3.0 - sqrt(5.0))
		dirs.append(Vector3(rr * cos(ph), yy, rr * sin(ph)))
	var tris: Array[PackedInt32Array] = []
	for i in CHUNK_COUNT:
		tris.append(PackedInt32Array())
	var sq := CrashAsteroid.SQUASH
	var t := 0
	while t < ix.size():
		var cen := (v[ix[t]] + v[ix[t + 1]] + v[ix[t + 2]]) / 3.0
		var u := (cen / sq).normalized()
		var best := 0
		var best_dot := -2.0
		for i in CHUNK_COUNT:
			var dd := u.dot(dirs[i])
			if dd > best_dot:
				best_dot = dd
				best = i
		tris[best].append_array(PackedInt32Array([ix[t], ix[t + 1], ix[t + 2]]))
		t += 3
	# Triangle soup ordered by chunk: every chunk vertex is a whole-mesh vertex, unchanged.
	var sv := PackedVector3Array()
	var sn := PackedVector3Array()
	var sc := PackedColorArray()
	var su := PackedVector2Array()
	for i in CHUNK_COUNT:
		_chunk_first.append(sv.size())
		var acc := Vector3.ZERO
		for j in tris[i]:
			sv.append(v[j])
			sn.append(n[j])
			sc.append(col[j])
			su.append(uv[j])
			acc += v[j]
		var cnt := tris[i].size()
		_chunk_count.append(cnt)
		var c := acc / float(maxi(cnt, 1))
		_chunk_centroid.append(c)
		_chunk_dir.append(c.normalized() if c.length_squared() > 0.0001 else dirs[i])
		var ext := 0.0
		for j in tris[i]:
			ext = maxf(ext, (v[j] - c).length())
		_chunk_head_scale.append(clampf(HEAD_SIZE / maxf(2.0 * ext, 0.001), 0.0, 1.0))
	_rest_pos = sv
	var soup: Array = []
	soup.resize(Mesh.ARRAY_MAX)
	soup[Mesh.ARRAY_VERTEX] = sv
	soup[Mesh.ARRAY_NORMAL] = sn
	soup[Mesh.ARRAY_COLOR] = sc
	soup[Mesh.ARRAY_TEX_UV] = su
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, soup)
	# Hash the soup as the mesh stores it (read back, like the whole mesh), before any pose is written.
	var back: Array = _mesh.surface_get_arrays(0)
	var ident := PackedInt32Array()
	ident.resize(sv.size())
	for i in sv.size():
		ident[i] = i
	_chunk_tri_hash = _tri_multiset_hash(back[Mesh.ARRAY_VERTEX], back[Mesh.ARRAY_NORMAL], back[Mesh.ARRAY_COLOR], ident)
	_rock = MeshInstance3D.new()
	_rock.name = "Rock"
	_rock.mesh = _mesh
	_rock.material_override = PlanetPropMeshes.rock_material()
	_rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Positions change in place, so the mesh's own AABB goes stale: a fixed box that holds any pose.
	var b := RADIUS * 1.6
	_rock.custom_aabb = AABB(Vector3(-b, -b, -b), Vector3(2.0 * b, 2.0 * b, 2.0 * b))
	# Also on FILL_LAYER, which only this rock's fill light lights.
	_rock.layers = 1 | (1 << (FILL_LAYER - 1))
	_spin.add_child(_rock)
	_warm_mat = _make_warm_material()


## CrashAsteroid's recipe (src/onboarding/crash_asteroid.gd `_build_body`) scaled to RADIUS: the
## squashed faceted blob, a sunk shoulder and a knuckle, and three pressed-in craters.
static func _rock_kit() -> PlanetMeshKit:
	var k := RADIUS / CrashAsteroid.RADIUS
	var body := CrashAsteroid.BODY
	var light := CrashAsteroid.BODY_LIGHT
	var dark := CrashAsteroid.BODY_DARK
	var sq := CrashAsteroid.SQUASH
	var kit := PlanetMeshKit.new()
	kit.faceted_blob(Vector3.ZERO, RADIUS, body, sq, 2, 0.26, 3.7)
	kit.faceted_blob(Vector3(0.40, -0.16, 0.20) * k, RADIUS * 0.50, body.lerp(dark, 0.35),
		Vector3(1.0, 0.82, 0.92), 1, 0.22, 9.1)
	kit.faceted_blob(Vector3(-0.34, 0.20, -0.26) * k, RADIUS * 0.38, light, Vector3.ONE, 1, 0.24, 17.3)
	var craters := [
		[Vector3(-0.18, 0.78, 0.60), 0.20],
		[Vector3(0.66, 0.40, -0.52), 0.15],
		[Vector3(0.30, 0.10, 0.95), 0.17],
	]
	for c: Array in craters:
		var d: Vector3 = (c[0] as Vector3).normalized()
		var r: float = float(c[1]) * k
		var p := d * RADIUS * sq * 0.90
		var bs := CrashAsteroid.axis_basis(d)
		kit.lathe(PackedVector2Array([Vector2(0.0, -r * 0.35), Vector2(r * 0.66, -r * 0.20),
			Vector2(r, 0.05)]), 10, Transform3D(bs, p), dark)
		kit.lathe(PackedVector2Array([Vector2(r, 0.05), Vector2(r * 1.22, 0.10),
			Vector2(r * 1.30, 0.0)]), 10, Transform3D(bs, p), light)
	return kit


func _build_core() -> void:
	var kit := PlanetMeshKit.new()
	# Unit-radius faceted blob in the rock's squash, scaled by break_at.
	kit.faceted_blob(Vector3.ZERO, RADIUS, WARM, CrashAsteroid.SQUASH, 1, 0.12, 5.3)
	_core = MeshInstance3D.new()
	_core.name = "Core"
	_core.mesh = kit.commit()
	_core_mat = _make_core_material()
	_core.material_override = _core_mat
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_core.scale = Vector3(CORE_R0, CORE_R0, CORE_R0)
	_core.visible = false
	_spin.add_child(_core)


func _build_fill() -> void:
	_fill = DirectionalLight3D.new()
	_fill.name = "PlanetshineFill"
	_fill.light_cull_mask = 1 << (FILL_LAYER - 1)
	_fill.shadow_enabled = false
	_fill.light_specular = 0.0
	_fill.visible = false
	add_child(_fill)


static func _make_warm_material() -> ShaderMaterial:
	var m := PlanetPropMeshes.rock_material().duplicate() as ShaderMaterial
	m.set_shader_parameter("emission_color", WARM)
	m.set_shader_parameter("emission_strength", 0.0)
	m.set_shader_parameter("emission_day_scale", 1.0)
	return m


static func _make_core_material() -> ShaderMaterial:
	var m := MaterialLib.glow(WARM, CORE_STRENGTH).duplicate() as ShaderMaterial
	m.set_shader_parameter("emission_day_scale", 1.0)
	return m


func _write_positions(p: PackedVector3Array) -> void:
	if _mesh == null or p.size() != _rest_pos.size():
		return
	_pose = p
	RenderingServer.mesh_surface_update_vertex_region(_mesh.get_rid(), 0, 0, p.to_byte_array())


# ------------------------------------------------------------------------------------------ debug
## Order-free hash of a triangle list (position, normal, colour per corner), so the whole mesh and
## the chunk soup can be compared regardless of vertex order.
static func _tri_multiset_hash(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, ix: PackedInt32Array) -> int:
	var hs: Array[int] = []
	var t := 0
	while t < ix.size():
		hs.append(str([v[ix[t]], n[ix[t]], c[ix[t]], v[ix[t + 1]], n[ix[t + 1]], c[ix[t + 1]],
			v[ix[t + 2]], n[ix[t + 2]], c[ix[t + 2]]]).hash())
		t += 3
	hs.sort()
	return str(hs).hash()


## The chunk vertex positions last written to the mesh (rock-local, chunk order), and each chunk's
## vertex range, so a test can measure the real pose rather than the schedule.
func debug_pose() -> Dictionary:
	return {"pos": _pose if not _pose.is_empty() else _rest_pos, "rest": _rest_pos,
		"first": _chunk_first, "count": _chunk_count}


## Numbers for the critic: triangle counts, the whole-vs-chunk vertex hash, shaders, chunk sizes.
func debug_report() -> Dictionary:
	var tris := _rest_pos.size() / 3
	var core_tris := _core.mesh.get_faces().size() / 3
	var shaders := {}
	for m: Material in [PlanetPropMeshes.rock_material(), _warm_mat, _core_mat]:
		shaders[(m as ShaderMaterial).shader.get_rid().get_id()] = true
	return {
		"rock_tris": tris, "core_tris": core_tris, "total_tris": tris + core_tris,
		"whole_hash": _whole_tri_hash, "chunk_hash": _chunk_tri_hash,
		"hash_equal": _whole_tri_hash == _chunk_tri_hash,
		"rock_shader_shared": _warm_mat.shader == PlanetPropMeshes.rock_material().shader,
		"shaders": shaders.size(), "chunk_tris": Array(_chunk_count).map(func(x: int) -> int: return x / 3),
		"bounding_radius": bounding_radius(),
	}
