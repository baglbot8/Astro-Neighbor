class_name StarShower
extends MultiMeshInstance3D
## THE METEOR SHOWER of the Phase 5 send-off (docs/PHASE5_SPEC.md §4 "Shower", §2 send-off 12.5-22 s).
## Owned and driven by FinaleLaunch (finale_launch.gd); after the shot it keeps running on its own
## clock for the stragglers until `stop_stragglers()`.
##
## A METEOR SHOWER, NOT FIREWORKS. Every streak moves in a straight line directly away from the
## radiant (the giant asteroid's centre): its velocity is `(start - radiant).normalized()`, fixed for
## its whole life. That line lies in the plane through the radiant, the start point and ANY viewer,
## so from the crowd every streak runs along a great circle out of the radiant - the look of a real
## shower - and in 3D it is exactly radial from the rock (the critic's 2 deg test). No gravity, no
## droop, no drag. Starts are spread over 8-150 deg from the radiant (weighted to 15-60 deg) and
## staggered in time by the caller's schedule, so there is never a ring of streaks starting at once.
##
## ONE DRAW. A MultiMesh of CAPACITY instances with per-instance COLOR, drawn with the shipped
## `star_streak.gdshader` (it already reads COLOR and billboards each quad round its own +Y, which a
## MultiMesh instance transform provides exactly as a particle's does). No instance uniforms (item 55),
## no GPUParticles3D (heat item 1 found an unexplained GPU-particle cost), no new Shader. Only live
## instances are drawn: they are packed to the front of the buffer and `visible_instance_count` is
## set to that count, so an empty sky costs no instances at all.
##
## A STREAK IS TWO QUADS: a short warm head (warm white #fff1d6 or the rocket's gold #f2d28a) and a long
## lavender tail (#b9b0d6) behind it. The shader has no head/tail gradient of its own (its `along` term
## is symmetric), so the colour split is made with two instances rather than a new shader. The tail
## grows from nothing as the head travels (never pops in at full length) and the pair dims out over
## the last part of its life - additive light, so dimming is the meteor burning out, not a fade of a
## surface. Hero stars are the same pair, slower, longer and wider, in a friend's accent lifted to
## S <= 0.45 (HERO_LIFT).

const STREAK_SHADER_PATH := "res://src/rocket/star_streak.gdshader"
## Instances, not streaks: a streak is 2 instances, so this is 80 streaks alive at once at most.
const CAPACITY := 160

const WARM_WHITE := Color("#fff1d6")
const GOLD := Color("#f2d28a")
const LAVENDER := Color("#b9b0d6")
## §4: intensity 1.3-1.6.
const INTENSITY := 1.6
const CORE_WIDTH := 0.34
## How much of the accent's distance to white a hero star keeps (1.0 = pure accent). The shader adds
## `color * intensity` onto the sky, so the pixel at a hero's core is the accent lifted toward white;
## these keep every friend's accent under §4's S 0.45 at the core (checked in `hero_color`).
const HERO_S_MAX := 0.45
## A hero's tail keeps a little more of the accent than its core, so the colour reads along its length.
const HERO_TAIL_S := 0.58
const HERO_TAIL_GAIN := 0.62
const HERO_HEAD_GAIN := 0.85

## §4: the shell round the crowd, and the angle band from the radiant.
const SHELL_MIN := 60.0
const SHELL_MAX := 90.0
const THETA_MIN_DEG := 8.0
const THETA_MAX_DEG := 150.0
const THETA_CORE_DEG := Vector2(15.0, 60.0)
## Share of shell streaks drawn from the 15-60 deg core band (the rest from the whole 8-150 band).
const THETA_CORE_SHARE := 0.7
## Streaks start at least this far above the crowd's horizontal (the planet hides anything lower).
const MIN_ELEV_DEG := 6.0

## A normal streak: speed (m/s), life (s), longest tail (m), head length (m), widths (m).
const SPEED := Vector2(26.0, 40.0)
const LIFE := Vector2(0.65, 0.95)
const TAIL_MAX := Vector2(10.0, 16.0)
const HEAD_LEN := 2.2
const HEAD_W := 0.62
const TAIL_W := 0.34
## Hero stars: slow long quads (§4), crossing the faces frame.
const HERO_SPEED := 8.5
const HERO_LIFE := 3.0
const HERO_TAIL := 30.0
const HERO_HEAD_LEN := 3.6
const HERO_HEAD_W := 1.35
const HERO_TAIL_W := 0.8
## Brightness envelope: up over the first IN seconds, down over the last OUT share of the life.
const ENV_IN := 0.08
const ENV_OUT_SHARE := 0.45
## Stragglers after the shot (§2: every 8-12 s until the gift ends).
const STRAGGLER_GAP := Vector2(8.0, 12.0)
const MAX_STEP := 0.05
## Streaks queued or alive at once (the shot queues its whole shower up front); only CAPACITY instances
## are ever drawn.
const MAX_QUEUED := 600
## Instances always submitted, even with an empty sky (see `_rebuild`).
const KEEP_DRAWN := 2
## A chunk's streak builds its speed over this long (see `_travelled`).
const CHUNK_RAMP := 0.5

enum Kind { SHELL, CHUNK, HERO, STRAGGLER }

var _mm: MultiMesh
var _buf := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
## The crowd's eye point, its up, and the radiant (rock centre), all world space.
var _eye := Vector3.ZERO
var _up := Vector3.UP
var _radiant := Vector3.ZERO
var _t := 0.0
## Live and pending streaks, parallel arrays (a streak is pending while `_t < _t0`).
var _p0 := PackedVector3Array()
var _dir := PackedVector3Array()
var _t0 := PackedFloat32Array()
var _life := PackedFloat32Array()
var _speed := PackedFloat32Array()
var _tail := PackedFloat32Array()
var _head_len := PackedFloat32Array()
var _head_w := PackedFloat32Array()
var _tail_w := PackedFloat32Array()
var _head_col := PackedColorArray()
var _tail_col := PackedColorArray()
var _kind := PackedInt32Array()
var _ramp := PackedFloat32Array()
var _self_clock := false
var _stragglers := false
var _next_straggler := 0.0
var _launched := 0
var _log_starts: Array[Dictionary] = []


func _init() -> void:
	name = "StarShower"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	q.material = shared_material()
	_mm.mesh = q
	_mm.instance_count = CAPACITY
	_mm.visible_instance_count = 0
	_buf.resize(CAPACITY * 16)
	multimesh = _mm
	set_process(false)


## The one material every streak draws with, shared by every StarShower and by `warm_materials` /
## FinaleLaunch.warm_nodes for as long as this World scene lives (kept as metadata on /root/World, so it
## outlives the warm-up nodes but is freed with the scene - Engine metadata leaked it at exit). MEASURED
## (L2 probe, Compatibility, Mac): a shower built with a fresh material stalled 74-81 ms on its first
## drawn frame even after a warm-up shower had drawn - the warm-up's material, and with it the Shader,
## had been freed with its node; with the shared material that frame did not stall.
static func shared_material() -> ShaderMaterial:
	const KEY := "star_shower_material"
	var tree := Engine.get_main_loop() as SceneTree
	var world: Node = tree.root.get_node_or_null("World") if tree != null and tree.root != null else null
	if world == null:
		return make_material()
	if world.has_meta(KEY):
		var m: Variant = world.get_meta(KEY)
		if m is ShaderMaterial:
			return m
	var made := make_material()
	world.set_meta(KEY, made)
	return made


## A new streak material (the recipe; `shared_material` is what gets drawn).
static func make_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(STREAK_SHADER_PATH) as Shader
	m.set_shader_parameter("tint", Color(1.0, 1.0, 1.0, 1.0))
	m.set_shader_parameter("intensity", INTENSITY)
	m.set_shader_parameter("core_width", CORE_WIDTH)
	return m


## §7 warm-up list: every material this shower draws.
static func warm_materials() -> Array[Material]:
	return [shared_material()]


## A friend's accent lifted toward white until its saturation is at most HERO_S_MAX.
static func hero_color(accent: Color, s_max := HERO_S_MAX) -> Color:
	var c := accent
	for i in 40:
		if c.s <= s_max:
			break
		c = c.lerp(Color.WHITE, 0.04)
	return c


## Where the shower is. `eye`: the crowd's eye point; `up`: the planet's up there; `radiant`: the rock.
func setup(eye: Vector3, up: Vector3, radiant: Vector3, rng_seed: int) -> void:
	_eye = eye
	_up = up.normalized()
	_radiant = radiant
	_rng.seed = rng_seed
	# Instances are placed in world space (this node sits at the origin with no rotation), so the
	# engine's own AABB (from a 1 m quad) is useless: a fixed box round the whole shell.
	var r := SHELL_MAX + HERO_TAIL + 60.0 + eye.distance_to(radiant)
	custom_aabb = AABB(eye - Vector3(r, r, r), Vector3(r, r, r) * 2.0)


func radiant() -> Vector3:
	return _radiant


func clock() -> float:
	return _t


## Drives the shower from its owner's shot clock (FinaleLaunch). Deterministic in `t`.
func advance_to(t: float) -> void:
	_t = t
	_rebuild()


## Low-level: queues one streak. `dir` is normalised here; `t0` is on the shower clock.
func add_streak(p0: Vector3, dir: Vector3, t0: float, speed: float, life: float, tail: float,
		head_col: Color, tail_col: Color, kind: int, widths := Vector3(HEAD_LEN, HEAD_W, TAIL_W)) -> void:
	if _p0.size() >= MAX_QUEUED:
		return
	_p0.append(p0)
	_dir.append(dir.normalized())
	_t0.append(t0)
	_speed.append(speed)
	_life.append(life)
	_tail.append(tail)
	_head_len.append(widths.x)
	_head_w.append(widths.y)
	_tail_w.append(widths.z)
	_head_col.append(head_col)
	_tail_col.append(tail_col)
	_kind.append(kind)
	_ramp.append(CHUNK_RAMP if kind == Kind.CHUNK else 0.0)
	_launched += 1
	if _log_starts.size() < 400:
		_log_starts.append({"t0": t0, "p0": p0, "dir": dir.normalized(), "kind": kind,
			"theta": rad_to_deg((_radiant - _eye).angle_to(p0 - _eye))})


## A chunk's streak (§2 "streaks start from chunk_positions()"): from `centre + offset * scale` straight out
## along `offset` - the chunk's own radial line from the rock's centre, whatever the remnant's scale.
func add_chunk(centre: Vector3, offset: Vector3, scale_now: float, t0: float, gold: bool) -> void:
	var d := offset
	if d.length_squared() < 0.0001:
		d = _up
	add_streak(centre + offset * scale_now, d, t0, _rng.randf_range(SPEED.x, SPEED.y) * 0.8,
		_rng.randf_range(LIFE.x, LIFE.y) * 1.2, _rng.randf_range(TAIL_MAX.x, TAIL_MAX.y), GOLD if gold else WARM_WHITE,
		LAVENDER, Kind.CHUNK)


## One shell streak. `frame` (optional, `[Transform3D, vfov_deg, aspect]`) is where the camera will be
## at the streak's mid-life: with probability `in_frame` the start is re-drawn (up to 24 times) until
## the streak's midpoint lands inside that frame, so the waves are spent where somebody is looking.
func add_shell(t0: float, frame: Array = [], in_frame := 0.0, kind := Kind.SHELL, theta_band := Vector2.ZERO) -> void:
	var want_frame := frame.size() >= 3 and _rng.randf() < in_frame
	var best := Vector3.ZERO
	var tries := 24 if want_frame else 8
	for i in tries:
		var p := _shell_point(theta_band)
		if p == Vector3.ZERO:
			continue
		best = p
		if not want_frame:
			break
		var speed := (SPEED.x + SPEED.y) * 0.5
		var mid := p + (p - _radiant).normalized() * speed * (LIFE.x + LIFE.y) * 0.25
		if _in_frame(frame, mid, 0.85):
			break
	if best == Vector3.ZERO:
		return
	var gold := _rng.randf() < 0.3
	add_streak(best, best - _radiant, t0, _rng.randf_range(SPEED.x, SPEED.y), _rng.randf_range(LIFE.x, LIFE.y),
		_rng.randf_range(TAIL_MAX.x, TAIL_MAX.y), GOLD if gold else WARM_WHITE, LAVENDER, kind)


## A hero star in `accent`, whose midpoint lands inside `frame` (see add_shell), upper part preferred.
func add_hero(accent: Color, t0: float, frame: Array) -> void:
	# Dimmed so the additive sum does not clip to white over the sky and the accent still reads.
	var col := hero_color(accent, HERO_TAIL_S) * HERO_TAIL_GAIN
	var head := hero_color(accent, HERO_S_MAX) * HERO_HEAD_GAIN
	var best := Vector3.ZERO
	var best_score := -INF
	for i in 48:
		var p := _shell_point(Vector2(70.0, 140.0))
		if p == Vector3.ZERO:
			continue
		var mid := p + (p - _radiant).normalized() * HERO_SPEED * HERO_LIFE * 0.5
		var score := -1.0
		if frame.size() >= 3:
			var s := _frame_uv(frame, mid)
			if s.z > 0.0 and absf(s.x) < 0.8 and s.y > -0.1 and s.y < 0.85:
				# Upper-middle of the frame, over the faces, and away from its edges.
				score = 1.0 - absf(s.x) * 0.6 - absf(s.y - 0.45) * 0.8
		if score > best_score:
			best_score = score
			best = p
	if best == Vector3.ZERO:
		return
	add_streak(best, best - _radiant, t0, HERO_SPEED, HERO_LIFE, HERO_TAIL, head, col, Kind.HERO,
		Vector3(HERO_HEAD_LEN, HERO_HEAD_W, HERO_TAIL_W))


## Warm-up pose (FinaleLaunch.warm_nodes): one 2 cm streak at this node's own origin, drawn with the same
## instanced MultiMesh path as the real shower.
func warm_pose() -> void:
	var o := 0
	var b := Basis.from_scale(Vector3(0.02, 0.02, 0.02))
	_buf[o] = b.x.x
	_buf[o + 1] = b.y.x
	_buf[o + 2] = b.z.x
	_buf[o + 3] = 0.0
	_buf[o + 4] = b.x.y
	_buf[o + 5] = b.y.y
	_buf[o + 6] = b.z.y
	_buf[o + 7] = 0.0
	_buf[o + 8] = b.x.z
	_buf[o + 9] = b.y.z
	_buf[o + 10] = b.z.z
	_buf[o + 11] = 0.0
	_buf[o + 12] = 1.0
	_buf[o + 13] = 1.0
	_buf[o + 14] = 1.0
	_buf[o + 15] = 1.0
	RenderingServer.multimesh_set_buffer(_mm.get_rid(), _buf)
	_mm.visible_instance_count = 1
	# The same huge box as the real shower: Compatibility picks a shader specialization per object from
	# the lights its box touches, and a 2 cm box touches none of the lamps the shell's box does.
	custom_aabb = AABB(Vector3(-300, -300, -300), Vector3(600, 600, 600))


## After the shot: this node runs its own clock and sends a lone streak every 8-12 s until stopped.
func start_stragglers() -> void:
	_self_clock = true
	_stragglers = true
	_next_straggler = _t + _rng.randf_range(2.0, 4.0)
	set_process(true)


## Stops new stragglers; the ones already in the sky finish their flight, then the node goes idle.
func stop_stragglers() -> void:
	_stragglers = false


## Removes every streak at once (used under the skip's navy fade only).
func clear() -> void:
	_p0.clear()
	_dir.clear()
	_t0.clear()
	_life.clear()
	_speed.clear()
	_tail.clear()
	_head_len.clear()
	_head_w.clear()
	_tail_w.clear()
	_head_col.clear()
	_tail_col.clear()
	_kind.clear()
	_ramp.clear()
	_rebuild()


func pending_count() -> int:
	return _p0.size()


func launched_count() -> int:
	return _launched


func _process(delta: float) -> void:
	if not _self_clock:
		return
	_t += minf(delta, MAX_STEP)
	if _stragglers and _t >= _next_straggler:
		add_shell(_t, [], 0.0, Kind.STRAGGLER)
		_next_straggler = _t + _rng.randf_range(STRAGGLER_GAP.x, STRAGGLER_GAP.y)
	_rebuild()
	if not _stragglers and _p0.is_empty():
		set_process(false)


# ------------------------------------------------------------------------------------------ geometry
## A start point on the shell, `theta` from the radiant as seen from the crowd's eye, above the
## crowd's horizon. Vector3.ZERO if no draw landed above the horizon.
func _shell_point(theta_band := Vector2.ZERO) -> Vector3:
	var rd := (_radiant - _eye).normalized()
	var ref := _up if absf(rd.dot(_up)) < 0.95 else Vector3.RIGHT
	var u := rd.cross(ref).normalized()
	var w := u.cross(rd).normalized()
	for i in 16:
		var th: float
		if theta_band != Vector2.ZERO:
			th = _rng.randf_range(theta_band.x, theta_band.y)
		elif _rng.randf() < THETA_CORE_SHARE:
			th = _rng.randf_range(THETA_CORE_DEG.x, THETA_CORE_DEG.y)
		else:
			th = _rng.randf_range(THETA_MIN_DEG, THETA_MAX_DEG)
		var ph := _rng.randf_range(0.0, TAU)
		var t := deg_to_rad(th)
		var d := (rd * cos(t) + (u * cos(ph) + w * sin(ph)) * sin(t)).normalized()
		if rad_to_deg(asin(clampf(d.dot(_up), -1.0, 1.0))) < MIN_ELEV_DEG:
			continue
		return _eye + d * _rng.randf_range(SHELL_MIN, SHELL_MAX)
	return Vector3.ZERO


## `frame` = [Transform3D, vfov_deg, aspect]: the point's position in frame, x and y in -1..1 (y up),
## z > 0 when in front of the camera.
static func _frame_uv(frame: Array, p: Vector3) -> Vector3:
	var xf: Transform3D = frame[0]
	var local := xf.affine_inverse() * p
	if local.z >= -0.01:
		return Vector3(0.0, 0.0, -1.0)
	var ty := tan(deg_to_rad(float(frame[1]) * 0.5))
	var tx := ty * float(frame[2])
	return Vector3(local.x / (-local.z * tx), local.y / (-local.z * ty), 1.0)


static func _in_frame(frame: Array, p: Vector3, margin: float) -> bool:
	var s := _frame_uv(frame, p)
	return s.z > 0.0 and absf(s.x) < margin and absf(s.y) < margin


# ------------------------------------------------------------------------------------------ drawing
func _rebuild() -> void:
	var n := 0
	var i := 0
	while i < _p0.size():
		var age := _t - _t0[i]
		if age >= _life[i]:
			_remove(i)
			continue
		if age >= 0.0 and n + 2 <= CAPACITY:
			var k := smoothstep(0.0, ENV_IN, age) * (1.0 - smoothstep(_life[i] * (1.0 - ENV_OUT_SHARE), _life[i], age))
			var d := _dir[i]
			var travelled := _travelled(i, age)
			var head := _p0[i] + d * travelled
			var tail_len := minf(travelled, _tail[i])
			var hl := minf(_head_len[i], maxf(travelled, 0.05) + 0.4)
			_write(n, head - d * (hl * 0.35), d, hl, _head_w[i], Color(_head_col[i], k))
			n += 1
			if tail_len > 0.05:
				_write(n, head - d * (tail_len * 0.5), d, tail_len, _tail_w[i], Color(_tail_col[i], k * 0.85))
			else:
				_write(n, head, d, 0.0, 0.0, Color(0.0, 0.0, 0.0, 0.0))
			n += 1
		i += 1
	# Never fewer than KEEP_DRAWN instances (zero-width, zero-alpha when idle). MEASURED (L2 probe,
	# Compatibility, Mac): the frame where visible_instance_count first rose from 0 stalled 75-77 ms,
	# wherever that first streak was scheduled, and a separate warm-up shower drawn beforehand did not
	# prevent it; with the count never at 0, no stall at the first streak and none at creation.
	while n < KEEP_DRAWN:
		_write(n, _eye, _up, 0.0, 0.0, Color(0.0, 0.0, 0.0, 0.0))
		n += 1
	RenderingServer.multimesh_set_buffer(_mm.get_rid(), _buf)
	_mm.visible_instance_count = n


## Instance `slot`: a quad centred on `c`, its +Y along `d` with length `len`, +X width `w`.
func _write(slot: int, c: Vector3, d: Vector3, length: float, w: float, col: Color) -> void:
	var ref := _up if absf(d.dot(_up)) < 0.95 else Vector3.RIGHT
	var x := d.cross(ref).normalized() * w
	var y := d * length
	var z := x.cross(y).normalized()
	var o := slot * 16
	_buf[o] = x.x
	_buf[o + 1] = y.x
	_buf[o + 2] = z.x
	_buf[o + 3] = c.x
	_buf[o + 4] = x.y
	_buf[o + 5] = y.y
	_buf[o + 6] = z.y
	_buf[o + 7] = c.y
	_buf[o + 8] = x.z
	_buf[o + 9] = y.z
	_buf[o + 10] = z.z
	_buf[o + 11] = c.z
	_buf[o + 12] = col.r
	_buf[o + 13] = col.g
	_buf[o + 14] = col.b
	_buf[o + 15] = col.a


## Distance a streak's head has flown at `age`: constant speed, or for a chunk a speed that builds from
## zero over CHUNK_RAMP (the piece of rock catching light and taking off), still on its straight line.
func _travelled(i: int, age: float) -> float:
	var r := _ramp[i]
	if r <= 0.0:
		return _speed[i] * age
	if age < r:
		return _speed[i] * age * age / (2.0 * r)
	return _speed[i] * (age - r * 0.5)


func _remove(i: int) -> void:
	_p0.remove_at(i)
	_dir.remove_at(i)
	_t0.remove_at(i)
	_life.remove_at(i)
	_speed.remove_at(i)
	_tail.remove_at(i)
	_head_len.remove_at(i)
	_head_w.remove_at(i)
	_tail_w.remove_at(i)
	_head_col.remove_at(i)
	_tail_col.remove_at(i)
	_kind.remove_at(i)
	_ramp.remove_at(i)


# ------------------------------------------------------------------------------------------ measurement
## Every streak queued so far (capped at 400): start time, start point, direction, kind, and its angle
## from the radiant as seen from the crowd's eye. For the critic's not-fireworks check.
func debug_starts() -> Array[Dictionary]:
	return _log_starts


## Streaks alive right now whose head is inside `cam`'s view (and bright enough to read).
func on_screen_count(cam: Camera3D, vp: Vector2) -> int:
	var c := 0
	for i in _p0.size():
		var age := _t - _t0[i]
		if age < 0.0 or age >= _life[i] or _kind[i] == Kind.HERO:
			continue
		var k := smoothstep(0.0, ENV_IN, age) * (1.0 - smoothstep(_life[i] * (1.0 - ENV_OUT_SHARE), _life[i], age))
		if k < 0.35:
			continue
		var head := _p0[i] + _dir[i] * _travelled(i, age)
		if cam.is_position_behind(head):
			continue
		var s := cam.unproject_position(head)
		if s.x >= 0.0 and s.y >= 0.0 and s.x <= vp.x and s.y <= vp.y:
			c += 1
	return c


## Heroes alive right now and in `cam`'s view.
func heroes_on_screen(cam: Camera3D, vp: Vector2) -> int:
	var c := 0
	for i in _p0.size():
		var age := _t - _t0[i]
		if age < 0.0 or age >= _life[i] or _kind[i] != Kind.HERO:
			continue
		var head := _p0[i] + _dir[i] * _speed[i] * age
		if cam.is_position_behind(head):
			continue
		var s := cam.unproject_position(head)
		if s.x >= 0.0 and s.y >= 0.0 and s.x <= vp.x and s.y <= vp.y:
			c += 1
	return c
