extends Node3D
## CamFadeShaderCheck - run as a scene, windowed, once per renderer:
##   godot --path <copy> res://tests/director/cam_fade_shader_check.tscn --rendering-method gl_compatibility
##     --resolution 640x480 --always-on-top --position 100,100
## For every shader hooked with src/shaders/cam_fade.gdshaderinc (plus the three MaterialLib string
## rewrites of toon_soft / star), prints whether Shader.get_shader_uniform_list() lists `cam_fade`
## (what CameraRig._is_fade_hookable reads), whether the code carries the include, and the fraction
## of screen pixels left exactly at the background colour on a perspective quad at cam_fade 0 and 0.9.
## An opaque shader should go from ~0 to ~14/16 = 0.875 background. Shader compile errors, if any, are
## in the engine log above the CAMFADESHADER lines.

const SHADERS := [
	"res://src/shaders/toon_soft.gdshader",
	"res://src/shaders/planet_foliage.gdshader",
	"res://src/shaders/crystal.gdshader",
	"res://src/shaders/planet_glow_pulse.gdshader",
	"res://src/hub/hub_surface.gdshader",
	"res://src/decorations/deco_glow.gdshader",
	"res://src/rocket/rocket_flame.gdshader",
	"res://src/shaders/water.gdshader",
	"res://src/decorations/light_beam.gdshader",
	"res://src/player/blob_shadow.gdshader",
	"res://src/shaders/star.gdshader",
]
const BG := Color(1.0, 0.0, 1.0)

var _quad: MeshInstance3D


func _ready() -> void:
	print("CAMFADESHADER renderer compat=%s" % str(Platform.is_compatibility_renderer()))
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = BG
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 60.0
	cam.position = Vector3(0, 0, 1.2)
	add_child(cam)
	cam.current = true
	_quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(3.0, 3.0)
	_quad.mesh = qm
	add_child(_quad)
	_run.call_deferred()


func _run() -> void:
	var list: Array = []
	for p: String in SHADERS:
		list.append([p.get_file(), load(p) as Shader])
	var vc := MaterialLib.toon_vertex_color()
	list.append(["MaterialLib.toon_vertex_color", vc.shader])
	list.append(["MaterialLib.rocket_finish_shader", MaterialLib.rocket_finish_shader()])
	list.append(["MaterialLib.rocket_glint_shader", MaterialLib.rocket_glint_shader()])
	for item: Array in list:
		var nm: String = item[0]
		var sh: Shader = item[1]
		if sh == null:
			print("CAMFADESHADER %s shader=null" % nm)
			continue
		var listed := false
		for u: Dictionary in sh.get_shader_uniform_list():
			if str(u.get("name", "")) == "cam_fade":
				listed = true
		var mat := ShaderMaterial.new()
		mat.shader = sh
		_quad.material_override = mat
		# At the game's own 3D scale first (Platform sets 0.75 bilinear under Compatibility, so the
		# upscale blends kept and removed pixels), then at 1.0 where the pattern is read 1:1.
		var vp := get_viewport()
		var game_scale := vp.scaling_3d_scale
		var fr0 := await _bg_fraction(mat, 0.0)
		var fr9 := await _bg_fraction(mat, 0.9)
		vp.scaling_3d_scale = 1.0
		var fr9_native := await _bg_fraction(mat, 0.9)
		vp.scaling_3d_scale = game_scale
		print("CAMFADESHADER %s uniform_listed=%s code_has_include=%s code_has_discard_macro=%s bg_frac@scale%.2f cam_fade0=%.4f cam_fade0.9=%.4f bg_frac@scale1.00 cam_fade0.9=%.4f" % [
			nm, str(listed), str(sh.code.contains("cam_fade.gdshaderinc")), str(sh.code.contains("CAM_FADE_DISCARD")), game_scale, fr0, fr9, fr9_native])
	print("CAMFADESHADER done")
	get_tree().quit()


func _bg_fraction(mat: ShaderMaterial, v: float) -> float:
	mat.set_shader_parameter(&"cam_fade", v)
	for i in range(6):
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var w := img.get_width()
	var h := img.get_height()
	var n := 0
	var bg := 0
	for y in range(h / 4, h * 3 / 4, 3):
		for x in range(w / 4, w * 3 / 4, 3):
			var c := img.get_pixel(x, y)
			n += 1
			if absf(c.r - 1.0) < 0.02 and c.g < 0.02 and absf(c.b - 1.0) < 0.02:
				bg += 1
	return float(bg) / float(maxi(n, 1))
