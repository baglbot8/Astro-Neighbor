extends Node3D
## CamFadeShadowCheck (B4) - run as a scene, windowed, once per renderer:
##   godot --path <copy> res://tests/director/cam_fade_shadow_check.tscn --rendering-method gl_compatibility
##     --resolution 1280x720 --always-on-top --position 100,100
## A toon_soft box casts a directional shadow on a toon_soft ground, beside itself so the camera sees
## the shadow uncovered. Frames: caster hidden (no shadow), caster at cam_fade 0, caster at cam_fade 0.9.
## Shadow mask = ground pixels at least 0.04 darker with the caster than without it (caster pixels,
## which are red, excluded). Inside the mask it prints mean luminance at 0 and 0.9 and the share of mask
## pixels that went back to the no-shadow brightness at 0.9 (holes the dither punched in the shadow).
## Measured in the 3D pass at the renderer's game scale, then at scaling_3d_scale 1.0.

var _box: MeshInstance3D
var _mat: ShaderMaterial


func _ready() -> void:
	print("CAMFADESHADOW renderer compat=%s" % str(Platform.is_compatibility_renderer()))
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.1, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.4, 0.4)
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-35, -90, 0)
	add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0, 9, 6), Vector3(0, 0, 0))
	cam.current = true
	var toon := load("res://src/shaders/toon_soft.gdshader") as Shader
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	ground.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = toon
	gm.set_shader_parameter("albedo", Color(0.9, 0.9, 0.9))
	ground.material_override = gm
	add_child(ground)
	_box = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 2.0, 1.2)
	_box.mesh = bm
	_box.position = Vector3(-2.5, 1.0, 0)
	_mat = ShaderMaterial.new()
	_mat.shader = toon
	_mat.set_shader_parameter("albedo", Color(0.9, 0.1, 0.1))
	_box.material_override = _mat
	add_child(_box)
	_run.call_deferred()


func _run() -> void:
	var vp := get_viewport()
	for sc: float in [vp.scaling_3d_scale, 1.0]:
		vp.scaling_3d_scale = sc
		_box.visible = false
		_mat.set_shader_parameter(&"cam_fade", 0.0)
		var none := await _grab()
		_box.visible = true
		var s0 := await _grab()
		_mat.set_shader_parameter(&"cam_fade", 0.9)
		var s9 := await _grab()
		_mat.set_shader_parameter(&"cam_fade", 0.0)
		var n := 0
		var sum0 := 0.0
		var sum9 := 0.0
		var sumn := 0.0
		var holes := 0
		for y in range(0, none.get_height(), 2):
			for x in range(0, none.get_width(), 2):
				var cn := none.get_pixel(x, y)
				var c0 := s0.get_pixel(x, y)
				if c0.r > c0.g + 0.15:
					continue  # caster pixel
				var ln := cn.get_luminance()
				var l0 := c0.get_luminance()
				if ln - l0 < 0.04:
					continue
				var l9 := s9.get_pixel(x, y).get_luminance()
				n += 1
				sumn += ln
				sum0 += l0
				sum9 += l9
				if l9 > l0 + 0.5 * (ln - l0):
					holes += 1
		print("CAMFADESHADOW scale=%.2f shadow_mask_px=%d mean_lum no_caster=%.4f cam_fade0=%.4f cam_fade0.9=%.4f holes_at_0.9=%.2f%%" % [
			sc, n, sumn / maxi(n, 1), sum0 / maxi(n, 1), sum9 / maxi(n, 1), 100.0 * holes / maxi(n, 1)])
	print("CAMFADESHADOW done")
	get_tree().quit()


func _grab() -> Image:
	for i in range(8):
		await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
