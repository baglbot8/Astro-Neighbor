class_name DecoItem
extends Node3D
## Base class for every placeable decoration. Subclasses only implement `_build()` (and optionally
## `_animate()`); this class handles the shared plumbing:
##   * materials (vertex-colored toon / metal / glass / one shared emissive shader)
##   * the blocking StaticBody3D on layer 4, mask 0, sized to the footprint
##   * day/night response for lamp lights and ground glow pools
##   * a `_process` that only runs on items that actually animate
##
## DAY / NIGHT — emissive surfaces need NO GDScript at all. `deco_glow.gdshader` reads the
## `astro_night` global directly (docs/ARCHITECTURE.md 9.1), which is why there is no clock poll here
## any more. The only things still driven from script are OmniLight3D energies and the additive
## ground-glow quads, which cannot be shader-driven; they update on EventBus.time_of_day_changed
## (~1.25 real seconds apart) instead of per frame, so a garden of 37 decorations runs zero
## `_process` callbacks unless the items genuinely animate.
##
## Model convention: root Node3D, origin at the ground contact point, faces -Z, +Y up.
## Metadata read by DecorationManager / PlacementController: `footprint` (meters), `blocking` (bool).

const GLOW_SHADER := preload("res://src/decorations/deco_glow.gdshader")
const FLAG_SHADER := preload("res://src/decorations/flag_wave.gdshader")
## Name of the environment's night-intensity global shader parameter, when it declares one.
const NIGHT_PARAM := "astro_night"
## Global trim on decoration lamp lights so a garden full of them does not blow out the night.
const LIGHT_SCALE := 0.5

## Approximate radius in meters used for placement spacing and the collider. Set per item.
@export var footprint: float = 0.8
## When false the item never blocks the player (rugs, flower beds, pebbles).
@export var blocking: bool = true
## Collider height; 0 = derive from the visual bounds.
@export var collide_height: float = 0.0
## Collider radius; 0 = footprint * 0.8.
@export var collide_radius: float = 0.0

var _t: float = 0.0
var _animated: bool = false
var _ground_glows: Array[MeshInstance3D] = []
var _lights: Array[OmniLight3D] = []
var _light_energy: Array[float] = []
var _night: float = 0.0
var _ghost_mode: bool = false
var _body: StaticBody3D
var _contact_shadow: MeshInstance3D
var _rng := RandomNumberGenerator.new()

static var _glow_mat: ShaderMaterial
static var _sparkle_mat: StandardMaterial3D
static var _dot_tex: ImageTexture


func _ready() -> void:
	_rng.seed = hash(get_script().resource_path)
	_build()
	_make_collider()
	# AFTER _make_collider(): the blob is a MeshInstance3D and _visual_aabb() walks every mesh under
	# the item, so adding it first would flatten the derived collider out to the blob's radius.
	# DEFERRED, and it has to be: DecorationManager._spawn() calls add_child() — which runs this
	# _ready() — and only sets `transform` on the NEXT line, so global_transform is still identity
	# here. The contact shadow now measures the ground it is standing on, and measuring it at the
	# planet's centre with a world-space up axis gives a garbage fit. One idle frame later the
	# manager has placed the item and the transform is real.
	_add_contact_shadow.call_deferred()
	set_meta("footprint", footprint)
	set_meta("blocking", blocking)
	_night = night_factor()
	_apply_night()
	# Only items with real lamp lights or ground pools need the clock at all; emissive surfaces read
	# the astro_night global straight from deco_glow.gdshader.
	if not (_lights.is_empty() and _ground_glows.is_empty()):
		EventBus.time_of_day_changed.connect(_on_time_changed)
	set_process(_animated)


# ============================================================================================ hooks
## Build the meshes. Override in each item script.
func _build() -> void:
	pass


## Per-frame animation. Override in animated items and call `animate()` from `_build` to enable it.
func _animate(_time: float, _delta: float) -> void:
	pass


## Marks this item as animated so `_process` ticks `_animate`.
func animate() -> void:
	_animated = true


func _process(delta: float) -> void:
	_t += delta
	_animate(_t, delta)


## CONTACT SHADOW, Compatibility only. The browser/phone renderer has the sun's shadow pass switched
## off (`_no_cast_shadows` in src/world/environment.gd — it is what closes a 26-63 luma-code gap
## against the desktop reference, and the mechanism is written up there), so a decoration that used
## to sit in its own shadow now reads as hovering. The art review of that trade named the hub bench
## specifically, and named the astronaut as the counter-example: the player keeps a blob under its
## boots and does NOT float. So the decorations get the same blob, from the same shader.
## The cost is one draw call and two triangles per decoration — see the note on
## PlanetProps.contact_shadow_quad() for why that is affordable here and is NOT how the planet's
## scattered props do it. Null on Forward+, where nothing has changed.
##
## Half-extents go through PlanetProps.fit_blob() with this item's own ground contact transform, so
## an item on or beside a bank gets a smaller pool instead of one the ground cuts a hard line
## through; see the rule at PlanetProps.BLOB_MAX_SAG. planet_under() returns null in the decoration
## gallery, where the ground really is flat and the fit is a no-op by construction.
func _add_contact_shadow() -> void:
	# Deferred (see _ready), so re-check the things that could have changed in that one frame.
	if _ghost_mode or not is_inside_tree() or _contact_shadow != null:
		return
	# `footprint` is the CLEARANCE the placement grid keeps around this item, not its size, so it is
	# an upper bound only; the pool is sized off the item's own geometry. Same correction, and the
	# same reason, as PlanetProps._note_contact_shadow().
	var ab := _visual_aabb()
	var rx: float = minf(footprint, maxf(absf(ab.position.x), absf(ab.end.x)))
	var rz: float = minf(footprint, maxf(absf(ab.position.z), absf(ab.end.z)))
	_contact_shadow = PlanetProps.contact_shadow_quad(rx, rz,
		PlanetProps.planet_under(self), global_transform)
	if _contact_shadow != null:
		add_child(_contact_shadow)


## Turns this instance into an inert preview: lamp lights and ground pools stay off no matter what
## the clock does. PlacementController calls this on the ghost, which used to keep casting the item's
## real lamp light onto the grass under the hologram.
func set_ghost_mode(on: bool) -> void:
	_ghost_mode = on
	if on:
		if EventBus.time_of_day_changed.is_connected(_on_time_changed):
			EventBus.time_of_day_changed.disconnect(_on_time_changed)
		for l in _lights:
			l.light_energy = 0.0
			l.visible = false
		for g in _ground_glows:
			g.visible = false
		# A hologram is not standing anywhere yet; a contact shadow under it would say it is.
		if _contact_shadow != null:
			_contact_shadow.visible = false


# ============================================================================================ build helpers
## Adds a mesh with the standard chunky vertex-colored toon material.
func add_body(mesh: Mesh, part_name: String = "Body", parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, body_material(), part_name, parent)


## Adds a mesh with a metallic vertex-colored toon material (robots, dishes, pipes).
func add_metal(mesh: Mesh, part_name: String = "Metal", parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, metal_material(), part_name, parent)


## Adds an emissive mesh; the tint comes from the baked vertex colors. `strength` is the night-time
## emission (it dims to ~22% by day). `pulse_speed` > 0 breathes (mode 0) or blinks (mode 1).
func add_glow(mesh: Mesh, strength: float = 2.4, part_name: String = "Glow", pulse_speed: float = 0.0, depth: float = 0.35, mode: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := _add(mesh, glow_material(), part_name, parent)
	mi.set_instance_shader_parameter("glow_strength", strength)
	mi.set_instance_shader_parameter("pulse_speed", pulse_speed)
	mi.set_instance_shader_parameter("pulse_depth", depth)
	mi.set_instance_shader_parameter("pulse_mode", mode)
	mi.set_instance_shader_parameter("phase", _rng.randf() * TAU)
	# Emissive bits are small and lit from within: keeping them out of the shadow pass saves a
	# noticeable slice of frame time and looks better (a lamp bulb should not shadow its own post).
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Adds a translucent glass mesh (domes, windows, water).
func add_glass(mesh: Mesh, tint: Color, alpha: float = 0.35, part_name: String = "Glass", parent: Node3D = null) -> MeshInstance3D:
	var mi := _add(mesh, MaterialLib.glass(tint, alpha), part_name, parent)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Adds a waving cloth mesh built with DecoKit.flag_panel.
func add_flag(mesh: Mesh, part_name: String = "Flag", amp: float = 0.11, speed: float = 2.4, parent: Node3D = null) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = FLAG_SHADER
	m.set_shader_parameter("albedo", Color.WHITE)
	m.set_shader_parameter("wave_amp", amp)
	m.set_shader_parameter("wave_speed", speed)
	return _add(mesh, m, part_name, parent)


## Adds a lamp light that costs nothing by day (energy scales with the night factor).
func add_light(pos: Vector3, color: Color, energy: float = 1.6, light_range: float = 6.0, parent: Node3D = null) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = "Lamp"
	l.position = pos
	l.light_color = color
	l.light_energy = 0.0
	l.omni_range = light_range * 0.85
	l.omni_attenuation = 2.0
	l.shadow_enabled = false
	l.light_specular = 0.2
	l.visible = false
	(parent if parent else self).add_child(l)
	_lights.append(l)
	_light_energy.append(energy)
	return l


## Adds a soft additive light pool on the ground under a lamp (fades in at night).
func add_ground_glow(radius: float, color: Color, alpha: float = 0.3, height: float = 0.04) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(radius * 2.0, radius * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	var mi := MeshInstance3D.new()
	mi.name = "GroundGlow"
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(color.r, color.g, color.b, 0.0)
	m.albedo_texture = soft_dot_texture()
	m.disable_receive_shadows = true
	mi.material_override = m
	mi.position.y = height
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("glow_alpha", alpha * 0.6)
	add_child(mi)
	_ground_glows.append(mi)
	return mi


## Small additive sparkle emitter (plasma fires, fountains, star projectors).
func add_particles(count: int, lifetime: float, pos: Vector3, color: Color, size: float = 0.12, velocity: float = 0.6, spread: float = 25.0, gravity: float = -0.4, radius: float = 0.15) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Particles"
	p.amount = maxi(1, count)
	p.lifetime = lifetime
	p.position = pos
	p.local_coords = false
	p.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius
	pm.direction = Vector3.UP
	pm.spread = spread
	pm.initial_velocity_min = velocity * 0.55
	pm.initial_velocity_max = velocity
	pm.gravity = Vector3(0.0, gravity, 0.0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var g := Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.0))
	g.add_point(0.22, color)
	g.set_color(g.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = sparkle_material()
	p.draw_pass_1 = q
	add_child(p)
	return p


## Empty pivot used by animated parts (dish yaw, arm wave, swing seat).
func pivot(part_name: String, pos: Vector3 = Vector3.ZERO, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = part_name
	n.position = pos
	(parent if parent else self).add_child(n)
	return n


func _add(mesh: Mesh, mat: Material, part_name: String, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	(parent if parent else self).add_child(mi)
	return mi


# ============================================================================================ materials
## Standard chunky decoration surface. `spec` is deliberately tiny and `spec_size` tight: at 0.18 /
## 60 the toon shader's fake specular painted a big soft white ellipse across every flat top face
## (supply-crate lid, dome-tent shell) that read as a stain at gameplay distance.
static func body_material() -> ShaderMaterial:
	return MaterialLib.toon_vertex_color({"rim": 0.16, "spec": 0.06, "spec_size": 220.0, "shade": 0.46})


static func metal_material() -> ShaderMaterial:
	return MaterialLib.toon_vertex_color({"metallic": 0.55, "roughness": 0.36, "spec": 0.45, "spec_size": 230.0, "rim": 0.42})


## One shared emissive material for every glowing decoration surface (per-instance intensity).
static func glow_material() -> ShaderMaterial:
	if _glow_mat == null:
		_glow_mat = ShaderMaterial.new()
		_glow_mat.shader = GLOW_SHADER
	return _glow_mat


static func sparkle_material() -> StandardMaterial3D:
	if _sparkle_mat == null:
		_sparkle_mat = StandardMaterial3D.new()
		_sparkle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_sparkle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_sparkle_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_sparkle_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_sparkle_mat.vertex_color_use_as_albedo = true
		_sparkle_mat.disable_receive_shadows = true
		_sparkle_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_sparkle_mat.albedo_texture = soft_dot_texture()
	return _sparkle_mat


## 64x64 soft radial dot used by sparkles and ground glow pools.
static func soft_dot_texture() -> ImageTexture:
	if _dot_tex:
		return _dot_tex
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(size * 0.5, size * 0.5)) / (size * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex


# ============================================================================================ collider
func _make_collider() -> void:
	var h := collide_height
	if h <= 0.0:
		var aabb := _visual_aabb()
		h = clampf(aabb.position.y + aabb.size.y, 0.3, 4.0)
	var r := collide_radius if collide_radius > 0.0 else footprint * 0.8
	_body = StaticBody3D.new()
	_body.name = "Blocker"
	# Layer 4 = "decoration". Non-blocking items keep the body (for tooling) but claim no layer.
	_body.collision_layer = (1 << 3) if blocking else 0
	_body.collision_mask = 0
	# A box (not a cylinder): Jolt only supports uniform scaling on round shapes, and the placement
	# pop / pick-up shrink squash the whole item non-uniformly.
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var side := maxf(r, 0.06) * 1.7
	shape.size = Vector3(side, maxf(h, 0.12), side)
	cs.shape = shape
	cs.position = Vector3(0.0, shape.size.y * 0.5, 0.0)
	_body.add_child(cs)
	add_child(_body)


func _visual_aabb() -> AABB:
	var out := AABB()
	var first := true
	var inv := global_transform.affine_inverse()
	for c in _all_meshes(self):
		var a: AABB = (inv * c.global_transform) * c.get_aabb()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out


func _all_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		if c is Node3D:
			out.append_array(_all_meshes(c))
	return out


# ============================================================================================ day / night
## 0 at midday, 1 deep at night, derived from the environment's clock (GameState.time_of_day).
## NOTE: RenderingServer.global_shader_parameter_get() is editor-only in Godot 4.7 (it pushes an
## error at runtime), so the `astro_night` global cannot be read back from gameplay code. We use the
## same clock that drives it instead; `has_night_global()` reports whether the environment declared it.
## Shaders must NOT use this — they read the `astro_night` global directly.
static func night_factor() -> float:
	return night_from_hour(GameState.time_of_day)


## True when the environment builder declared the `astro_night` global shader parameter.
static func has_night_global() -> bool:
	return ProjectSettings.has_setting("shader_globals/" + NIGHT_PARAM)


## Night curve: full night 20:30-04:30, full day 07:30-17:00, smooth ramps between.
static func night_from_hour(hour: float) -> float:
	var h := fposmod(hour, 24.0)
	if h < 4.5 or h >= 20.5:
		return 1.0
	if h < 7.5:
		return 1.0 - smoothstep(4.5, 7.5, h)
	if h < 17.0:
		return 0.0
	return smoothstep(17.0, 20.5, h)


func _on_time_changed(hour: float) -> void:
	var n := night_from_hour(hour)
	if absf(n - _night) < 0.002:
		return
	_night = n
	_apply_night()


func _apply_night() -> void:
	if _ghost_mode:
		return
	for i in _lights.size():
		var e: float = _light_energy[i] * _night * LIGHT_SCALE
		_lights[i].light_energy = e
		_lights[i].visible = e > 0.02
	for g in _ground_glows:
		var m := g.material_override as StandardMaterial3D
		if m:
			var a: float = float(g.get_meta("glow_alpha", 0.3)) * _night
			m.albedo_color = Color(m.albedo_color.r, m.albedo_color.g, m.albedo_color.b, a)
		g.visible = _night > 0.03
