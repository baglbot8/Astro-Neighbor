class_name TitleScreen
extends Node3D
## Animated title screen: a toon planet (res://src/planet/planet.tscn when it exists, else a built-in toon
## world) slowly turning under a starry procedural sky, a chunky rocket orbiting it with a sparkle trail,
## the outlined "ASTRO NEIGHBOR" logo bobbing, and New Game / Continue / Quit pills.
## Contract: the `--skip-title` user arg or an active Director starts the game immediately
## (continue if a save exists, else new game). showcase/ui_title.tscn sets demo_mode to disable that.

const PLANET_SCENE := "res://src/planet/planet.tscn"
const HOME_DATA := "res://src/planet/data/home.tres"
const SKY_SHADER := preload("res://src/ui/title/title_sky.gdshader")
const PLANET_RADIUS := 16.0
## The planet stays at the world origin, unrotated (planet shaders assume that, ARCHITECTURE §4);
## the camera rig orbits around it instead, which reads as the planet slowly turning.
const PLANET_CENTER := Vector3.ZERO
## Camera is pulled back and aimed higher than (and to the LEFT of) the planet's centre, so the globe
## sits low and to the RIGHT of the frame. The menu used to be stacked straight down the middle of
## the planet — three cream pills pasted across the meadow — so the aim point is offset to open a
## clear column on the left for it. Rotating with `_cam_pivot` keeps the framing stable.
const CAMERA_OFFSET := Vector3(0.0, 21.0, 84.0)
const CAMERA_TARGET := Vector3(-17.0, 19.0, 0.0)
const ORBIT_RADIUS := 23.0
const ORBIT_SPEED := 0.40
const CAMERA_ORBIT_SPEED := 0.07
const MENU_WIDTH := 300.0
## Menu column: pinned to the bottom-LEFT, clear of the globe (see CAMERA_TARGET).
const MENU_LEFT := 92.0
const MENU_BOTTOM := 96.0
## Logo block top and height; the tagline pill is pinned right under it.
const LOGO_TOP := 46.0
const LOGO_HEIGHT := 250.0
const TAGLINE_TOP := LOGO_TOP + 222.0

@export var demo_mode: bool = false

var _time := 0.0
var _camera: Camera3D
var _cam_pivot: Node3D
var _planet_pivot: Node3D
var _rocket: Node3D
var _flame: Node3D
var _orbit_angle := 0.6
var _orbit_u := Vector3.RIGHT
var _orbit_v := Vector3.FORWARD
var _ui: Control
var _logo: Control
var _logo_base_y := 0.0
var _buttons: Array[Button] = []
var _index := 0
var _repeat := UIFocus.NavRepeat.new()
var _cooldown := 0.5
var _starting := false
var _confirm: ConfirmPopup

func _ready() -> void:
	var auto_start := not demo_mode and (Director.is_active() or OS.get_cmdline_user_args().has("--skip-title"))
	if auto_start:
		_auto_start()
		return
	_build_world()
	_build_ui()
	UIStyle.play_music("title")

# ----------------------------------------------------------------------------- start paths
func _auto_start() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		GameState.reset_new_game()
	SceneRouter.start_game()

func _start_game() -> void:
	if _starting:
		return
	_starting = true
	UIStyle.play_confirm()
	var t := create_tween()
	t.tween_property(_ui, "modulate:a", 0.0, 0.35)
	SceneRouter.start_game()

func _new_game() -> void:
	if _starting:
		return
	if SaveManager.has_save():
		var ok: bool = await _confirm.ask("Start a brand new planet?\nYour saved game will be overwritten.", "Start over", "Keep it", -1, false)
		if not ok:
			_focus_current()
			return
		SaveManager.delete_save()
	GameState.reset_new_game()
	_start_game()

func _continue_game() -> void:
	if _starting:
		return
	if not SaveManager.load_game():
		GameState.reset_new_game()
	_start_game()

func _quit() -> void:
	UIStyle.play_cancel()
	get_tree().quit()

# ----------------------------------------------------------------------------- 3D world
func _build_world() -> void:
	_cam_pivot = Node3D.new()
	_cam_pivot.name = "CameraPivot"
	add_child(_cam_pivot)
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.position = CAMERA_OFFSET
	_camera.fov = 42.0
	_camera.look_at_from_position(_camera.position, CAMERA_TARGET, Vector3.UP)
	_cam_pivot.add_child(_camera)
	_camera.current = true

	var env := WorldEnvironment.new()
	env.name = "Sky"
	env.environment = _make_environment()
	add_child(env)

	# The sun rides with the camera pivot so the lit side always faces the viewer.
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color("#fff4d6")
	sun.light_energy = 1.9
	sun.rotation_degrees = Vector3(-34.0, -38.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	sun.shadow_blur = 2.0
	_cam_pivot.add_child(sun)

	_planet_pivot = Node3D.new()
	_planet_pivot.name = "PlanetPivot"
	_planet_pivot.position = PLANET_CENTER
	add_child(_planet_pivot)
	if ResourceLoader.exists(PLANET_SCENE):
		var inst: Node = load(PLANET_SCENE).instantiate()
		inst.name = "Planet"
		# Preview the real home planet when its data exists; keep it collectible-free for the title.
		var data: PlanetData
		if ResourceLoader.exists(HOME_DATA):
			data = (load(HOME_DATA) as PlanetData).duplicate() as PlanetData
		else:
			data = PlanetData.new()
		data.radius = PLANET_RADIUS
		data.collectible_count = 0
		inst.set("data", data)
		_planet_pivot.add_child(inst)
	else:
		_build_fallback_planet()
	_build_moon()
	_build_rocket()
	_build_ambient_sparkles()
	var n := Vector3(0.28, 1.0, 0.32).normalized()
	_orbit_u = n.cross(Vector3.RIGHT).normalized()
	_orbit_v = n.cross(_orbit_u).normalized()

func _make_environment() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ShaderMaterial.new()
	mat.shader = SKY_SHADER
	sky.sky_material = mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	e.sky = sky
	# Post matched to the shipping space scenes (src/rocket/space_travel.gd) so the title reads as
	# the same universe: ACES at white 6.0, a dark navy ambient instead of the old bright blue one
	# (which only made sense under the banned royal-blue sky), and a TIGHT additive bloom so the
	# stars stay pinpoints. SOFTLIGHT glow at threshold 1.0 used to wash the whole dome pale.
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#3d4374")
	e.ambient_light_energy = 1.05
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.0
	e.tonemap_white = 6.0
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.04
	e.adjustment_saturation = 1.02
	# The start page builds its OWN Environment, so it does not inherit the world's low-power
	# profile. Glow is the expensive part and is what washed the dome pale on a phone.
	e.glow_enabled = not (Platform.is_compatibility_renderer() or Platform.is_mobile())
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	e.glow_hdr_threshold = 1.25
	e.glow_hdr_scale = 1.1
	e.glow_intensity = 0.6
	e.glow_strength = 1.0
	e.glow_bloom = 0.01
	e.set_glow_level(0, 0.0)
	e.set_glow_level(1, 0.8)
	e.set_glow_level(2, 1.0)
	e.set_glow_level(3, 0.6)
	e.set_glow_level(4, 0.28)
	e.set_glow_level(5, 0.08)
	e.set_glow_level(6, 0.0)
	return e

func _add_mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi

func _sphere(radius: float, segments: int = 24) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = segments
	s.rings = maxi(6, segments / 2)
	return s

func _build_fallback_planet() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grass := MaterialLib.toon(Color("#7ed957"), {"shade": 0.38})
	_add_mesh(_planet_pivot, _sphere(PLANET_RADIUS, 96), grass)
	var trunk := MaterialLib.toon(Color("#a8734b"))
	var leaf_a := MaterialLib.toon(Color("#3fb37f"))
	var leaf_b := MaterialLib.toon(Color("#9be8a8"))
	var rock := MaterialLib.toon(Color("#f2efe6"))
	var used: Array = []
	for i in 14:
		var dir := _random_dir(rng, used, 16.0)
		used.append(dir)
		var tree := Node3D.new()
		tree.transform = _surface_transform(dir)
		_planet_pivot.add_child(tree)
		var s := rng.randf_range(0.85, 1.25)
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.26 * s
		trunk_mesh.bottom_radius = 0.36 * s
		trunk_mesh.height = 1.5 * s
		_add_mesh(tree, trunk_mesh, trunk, Vector3(0.0, 0.75 * s, 0.0))
		_add_mesh(tree, _sphere(1.25 * s), leaf_a, Vector3(0.0, 2.2 * s, 0.0))
		_add_mesh(tree, _sphere(0.95 * s), leaf_a, Vector3(0.75 * s, 1.75 * s, 0.35 * s))
		_add_mesh(tree, _sphere(0.95 * s), leaf_a, Vector3(-0.65 * s, 1.85 * s, -0.4 * s))
		_add_mesh(tree, _sphere(0.7 * s), leaf_b, Vector3(0.2 * s, 2.85 * s, 0.1 * s))
	for i in 9:
		var dir := _random_dir(rng, used, 9.0)
		used.append(dir)
		var r := Node3D.new()
		r.transform = _surface_transform(dir)
		_planet_pivot.add_child(r)
		var s := rng.randf_range(0.6, 1.1)
		_add_mesh(r, _sphere(0.9), rock, Vector3(0.0, 0.25 * s, 0.0), Vector3(0.0, rng.randf_range(0.0, 360.0), 0.0), Vector3(1.2 * s, 0.7 * s, 1.0 * s))
	var petals := [Color("#ff6b9d"), Color("#ffd166"), Color("#ffffff"), Color("#6fc3ff")]
	for i in 40:
		var dir := _random_dir(rng, used, 4.0)
		var fl := Node3D.new()
		fl.transform = _surface_transform(dir)
		_planet_pivot.add_child(fl)
		var stem := CylinderMesh.new()
		stem.top_radius = 0.05
		stem.bottom_radius = 0.06
		stem.height = 0.5
		_add_mesh(fl, stem, leaf_a, Vector3(0.0, 0.25, 0.0))
		_add_mesh(fl, _sphere(0.2, 10), MaterialLib.toon(petals[i % petals.size()]), Vector3(0.0, 0.55, 0.0))

func _random_dir(rng: RandomNumberGenerator, avoid: Array, min_deg: float) -> Vector3:
	var min_dot := cos(deg_to_rad(min_deg))
	for attempt in 80:
		var v := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		if v.length_squared() < 0.01:
			continue
		v = v.normalized()
		var ok := true
		for a in avoid:
			if v.dot(a) > min_dot:
				ok = false
				break
		if ok:
			return v
	return Vector3.UP

func _surface_transform(dir: Vector3) -> Transform3D:
	var d := dir.normalized()
	var fwd := Vector3.FORWARD - d * Vector3.FORWARD.dot(d)
	if fwd.length_squared() < 0.001:
		fwd = Vector3.RIGHT - d * Vector3.RIGHT.dot(d)
	var basis := Basis.looking_at(fwd.normalized(), d)
	return Transform3D(basis, d * PLANET_RADIUS)

func _build_moon() -> void:
	var moon := Node3D.new()
	moon.name = "Moon"
	# Low and to the left so it never crowds the logo block.
	moon.position = Vector3(-41.0, 20.0, -46.0)
	_cam_pivot.add_child(moon)
	# Emission is deliberately low: under the new ACES/white-6 post (and the tight additive bloom)
	# the old 1.3 turned the moon into a featureless white blob with a huge halo.
	_add_mesh(moon, _sphere(4.2, 32), MaterialLib.glow(Color("#f2e6c4"), 0.42, Color("#e8d9ac")))
	var crater := MaterialLib.toon(Color("#e8d9a8"), {"shade": 0.5})
	_add_mesh(moon, _sphere(0.9, 12), crater, Vector3(1.6, 1.4, 3.6))
	_add_mesh(moon, _sphere(0.6, 12), crater, Vector3(-1.8, -0.4, 3.8))
	_add_mesh(moon, _sphere(0.5, 12), crater, Vector3(0.4, -2.2, 3.5))

func _build_rocket() -> void:
	_rocket = Node3D.new()
	_rocket.name = "Rocket"
	add_child(_rocket)
	var body := Node3D.new()
	body.scale = Vector3.ONE * 1.5
	_rocket.add_child(body)
	var white := MaterialLib.toon(Color("#f4f4f8"), {"spec": 0.35})
	var orange := MaterialLib.toon(Color("#ff7a59"))
	var metal := MaterialLib.metal(Color("#8fa3bf"))
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.62
	capsule.height = 3.0
	capsule.radial_segments = 24
	_add_mesh(body, capsule, white, Vector3.ZERO, Vector3(90.0, 0.0, 0.0))
	var nose := CylinderMesh.new()
	nose.top_radius = 0.0
	nose.bottom_radius = 0.62
	nose.height = 1.2
	nose.radial_segments = 24
	_add_mesh(body, nose, orange, Vector3(0.0, 0.0, -1.75), Vector3(-90.0, 0.0, 0.0))
	for i in 3:
		var a := deg_to_rad(90.0 + 120.0 * float(i))
		var fin := _add_mesh(body, _sphere(0.5, 16), orange, Vector3(cos(a) * 0.62, sin(a) * 0.62, 0.95), Vector3(0.0, 0.0, rad_to_deg(a)), Vector3(1.9, 0.18, 1.5))
		fin.rotation_degrees = Vector3(0.0, 0.0, rad_to_deg(a))
	for sx in [-1.0, 1.0]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.24
		ring.outer_radius = 0.36
		_add_mesh(body, ring, metal, Vector3(sx * 0.6, 0.0, -0.35), Vector3(0.0, 90.0, 0.0))
		_add_mesh(body, _sphere(0.27, 16), _glass_material(Color("#6fc3ff"), 0.75), Vector3(sx * 0.52, 0.0, -0.35))
	var nozzle := CylinderMesh.new()
	nozzle.top_radius = 0.34
	nozzle.bottom_radius = 0.5
	nozzle.height = 0.45
	_add_mesh(body, nozzle, metal, Vector3(0.0, 0.0, 1.6), Vector3(-90.0, 0.0, 0.0))
	_flame = Node3D.new()
	_flame.position = Vector3(0.0, 0.0, 1.8)
	body.add_child(_flame)
	var flame_outer := CylinderMesh.new()
	flame_outer.top_radius = 0.0
	flame_outer.bottom_radius = 0.42
	flame_outer.height = 1.5
	_add_mesh(_flame, flame_outer, MaterialLib.glow(Color("#ff9a3d"), 2.6), Vector3(0.0, 0.0, 0.75), Vector3(90.0, 0.0, 0.0))
	var flame_inner := CylinderMesh.new()
	flame_inner.top_radius = 0.0
	flame_inner.bottom_radius = 0.22
	flame_inner.height = 0.9
	_add_mesh(_flame, flame_inner, MaterialLib.glow(Color("#fff0b0"), 3.5), Vector3(0.0, 0.0, 0.45), Vector3(90.0, 0.0, 0.0))
	var trail := GPUParticles3D.new()
	trail.name = "Trail"
	trail.position = Vector3(0.0, 0.0, 2.0)
	trail.amount = 160
	trail.lifetime = 1.8
	trail.local_coords = false
	trail.randomness = 0.5
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.0, 1.0)
	pm.spread = 24.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.2
	pm.gravity = Vector3.ZERO
	pm.damping_min = 0.6
	pm.damping_max = 1.2
	pm.scale_min = 0.45
	pm.scale_max = 0.9
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var grad := Gradient.new()
	grad.set_color(0, Color("#fff6c8"))
	grad.set_color(1, Color(1.0, 0.85, 0.35, 0.0))
	grad.add_point(0.35, Color("#ffe27a"))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.3
	trail.process_material = pm
	trail.draw_pass_1 = _sparkle_quad()
	body.add_child(trail)

## Glossy tinted glass for the portholes (local so the title never depends on MaterialLib.glass).
func _glass_material(tint: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.roughness = 0.08
	m.metallic = 0.2
	m.metallic_specular = 0.9
	m.rim_enabled = true
	m.rim = 0.6
	m.rim_tint = 0.3
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	return m

func _sparkle_quad(quad_size: float = 1.0) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(quad_size, quad_size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = make_sparkle_texture()
	m.disable_receive_shadows = true
	q.material = m
	return q

## 4-point sparkle with a soft glow, generated in code (no external assets).
static func make_sparkle_texture(px: int = 64) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	for y in px:
		for x in px:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / float(px) * 2.0 - Vector2.ONE
			var r := p.length()
			var glow := clampf(1.0 - r, 0.0, 1.0)
			glow *= glow
			var arm_x := clampf(1.0 - absf(p.y) * 7.0, 0.0, 1.0) * clampf(1.0 - absf(p.x), 0.0, 1.0)
			var arm_y := clampf(1.0 - absf(p.x) * 7.0, 0.0, 1.0) * clampf(1.0 - absf(p.y), 0.0, 1.0)
			var a := clampf(glow * 0.8 + maxf(arm_x, arm_y) * 1.3, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)

func _build_ambient_sparkles() -> void:
	var p := GPUParticles3D.new()
	p.name = "AmbientSparkles"
	p.position = Vector3(0.0, 13.5, 40.0)
	p.amount = 36
	p.lifetime = 7.0
	p.preprocess = 7.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(34.0, 20.0, 14.0)
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.12
	pm.scale_max = 0.3
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.5, 0.0))
	grad.set_color(1, Color(1.0, 0.9, 0.5, 0.0))
	grad.add_point(0.5, Color("#ffe27a"))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	p.draw_pass_1 = _sparkle_quad()
	_cam_pivot.add_child(p)

# ----------------------------------------------------------------------------- UI overlay
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	layer.layer = 5
	add_child(layer)
	_ui = Control.new()
	_ui.name = "Root"
	_ui.theme = UIStyle.theme()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)

	# logo
	_logo = Control.new()
	_logo.name = "Logo"
	_logo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_logo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_logo.offset_left = -420.0
	_logo.offset_right = 420.0
	_logo.offset_top = LOGO_TOP
	_logo.offset_bottom = LOGO_TOP + LOGO_HEIGHT
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_logo)
	_logo_base_y = _logo.offset_top
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -26)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.add_child(box)
	box.add_child(_logo_label("ASTRO", 112, UIStyle.YELLOW))
	box.add_child(_logo_label("NEIGHBOR", 86, UIStyle.CREAM))
	var star_a := StarIcon.new()
	star_a.icon_size = 44.0
	star_a.twinkle = true
	star_a.position = Vector2(640.0, 18.0)
	_logo.add_child(star_a)
	var star_b := StarIcon.new()
	star_b.icon_size = 30.0
	star_b.twinkle = true
	star_b.position = Vector2(150.0, 182.0)
	_logo.add_child(star_b)
	var star_c := StarIcon.new()
	star_c.icon_size = 22.0
	star_c.twinkle = true
	star_c.position = Vector2(700.0, 150.0)
	_logo.add_child(star_c)

	# tagline — tucked directly under the logo, above the planet's rim (it used to sit on the globe)
	var tag := PanelContainer.new()
	tag.name = "Tagline"
	tag.theme_type_variation = "HudPillSoft"
	tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tag.offset_top = TAGLINE_TOP
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(UIStyle.make_label("a cozy tiny-planet life sim", "Soft", HORIZONTAL_ALIGNMENT_CENTER))
	_ui.add_child(tag)

	# menu
	var menu := VBoxContainer.new()
	menu.name = "Menu"
	menu.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	menu.grow_horizontal = Control.GROW_DIRECTION_END
	menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu.offset_left = MENU_LEFT
	menu.offset_right = MENU_LEFT + MENU_WIDTH
	menu.offset_bottom = -MENU_BOTTOM
	menu.add_theme_constant_override("separation", 12)
	_ui.add_child(menu)
	var has_save := SaveManager.has_save()
	if has_save:
		_add_menu_button(menu, "Continue", _continue_game, "PillPrimary")
	_add_menu_button(menu, "New Game", _new_game, "Pill" if has_save else "PillPrimary")
	_add_menu_button(menu, "Quit", _quit, "Pill")

	# hints + version
	var hints := HBoxContainer.new()
	hints.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hints.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hints.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hints.offset_right = -24.0
	hints.offset_bottom = -20.0
	hints.add_theme_constant_override("separation", 18)
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(hints)
	for h in [["interact", "Select"], ["move_forward", "Navigate"]]:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 6)
		var g := KeyGlyph.new()
		if str(h[0]) == "move_forward":
			g.set_text("LS" if Input.get_connected_joypads().size() > 0 else "W/S")
		else:
			g.set_action(str(h[0]))
		g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pair.add_child(g)
		var l := UIStyle.make_label(str(h[1]), "Hint")
		l.add_theme_color_override("font_color", Color(UIStyle.CREAM, 0.85))
		pair.add_child(l)
		hints.add_child(pair)
	var version := UIStyle.make_label("Astro Neighbor · prototype", "Hint")
	version.add_theme_color_override("font_color", Color(UIStyle.CREAM, 0.6))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_left = 24.0
	version.offset_bottom = -22.0
	_ui.add_child(version)

	_confirm = ConfirmPopup.new()
	_confirm.name = "Confirm"
	_ui.add_child(_confirm)

	# entrance
	_ui.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_ui, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	_logo.pivot_offset = _logo.size * 0.5
	_logo.scale = Vector2(1.35, 1.35)
	var lt := create_tween()
	lt.tween_property(_logo, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in _buttons.size():
		var b := _buttons[i]
		b.modulate.a = 0.0
		var bt := create_tween()
		bt.tween_interval(0.35 + 0.1 * float(i))
		bt.tween_property(b, "modulate:a", 1.0, 0.3)
	_index = 0
	_focus_current()

func _logo_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ls := LabelSettings.new()
	ls.font = UIStyle.font()
	ls.font_size = font_size
	ls.font_color = color
	ls.outline_size = 18
	ls.outline_color = Color("#2b2352")
	ls.shadow_size = 6
	ls.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	ls.shadow_offset = Vector2(0.0, 8.0)
	l.label_settings = ls
	return l

func _add_menu_button(menu: VBoxContainer, text: String, cb: Callable, variation: String) -> void:
	var b := UIStyle.make_button(text, variation, MENU_WIDTH)
	b.pressed.connect(func() -> void: cb.call())
	b.focus_entered.connect(func() -> void: _index = _buttons.find(b))
	menu.add_child(b)
	_buttons.append(b)

func _focus_current() -> void:
	if _buttons.is_empty():
		return
	_index = clampi(_index, 0, _buttons.size() - 1)
	UIFocus.focus(_buttons[_index])

# ----------------------------------------------------------------------------- per-frame
func _process(delta: float) -> void:
	if _rocket == null:
		return
	_time += delta
	_cam_pivot.rotation.y = -_time * CAMERA_ORBIT_SPEED
	_orbit_angle += delta * ORBIT_SPEED
	var pos := PLANET_CENTER + (cos(_orbit_angle) * _orbit_u + sin(_orbit_angle) * _orbit_v) * ORBIT_RADIUS
	var tangent := (-sin(_orbit_angle) * _orbit_u + cos(_orbit_angle) * _orbit_v).normalized()
	var up := (pos - PLANET_CENTER).normalized()
	_rocket.global_position = pos
	_rocket.look_at(pos + tangent, up)
	_rocket.rotate_object_local(Vector3.FORWARD, sin(_time * 1.3) * 0.12)
	_flame.scale = Vector3(1.0, 1.0, 0.85 + 0.25 * sin(_time * 37.0) + 0.15 * sin(_time * 53.0))
	_camera.position = CAMERA_OFFSET + Vector3(sin(_time * 0.25) * 1.6, sin(_time * 0.4) * 0.8, 0.0)
	_camera.look_at(_cam_pivot.to_global(CAMERA_TARGET), Vector3.UP)
	if _logo != null:
		_logo.offset_top = _logo_base_y + sin(_time * 1.5) * 6.0
		_logo.offset_bottom = _logo.offset_top + LOGO_HEIGHT
		_logo.pivot_offset = _logo.size * 0.5
		_logo.rotation = sin(_time * 0.9) * 0.012
	# menu input
	if _starting or _confirm == null or _confirm.is_open():
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var step := _repeat.poll(delta)
	if step.y != 0 and not _buttons.is_empty():
		_index = UIFocus.list_move(_index, _buttons.size(), step.y)
		_focus_current()
	if UIFocus.accept_pressed() and not _buttons.is_empty():
		_buttons[_index].pressed.emit()

func _input(event: InputEvent) -> void:
	if _ui != null and not _starting:
		UIFocus.consume_nav_event(_ui, event)
