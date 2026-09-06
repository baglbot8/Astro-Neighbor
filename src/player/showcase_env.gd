class_name PlayerShowcaseEnv
extends RefCounted
## Minimal warm sky + sun for the player showcases (the real game environment is built by the
## environment builder in src/world/environment.tscn; this only exists so the showcases stand alone).


static func add_to(parent: Node) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color("#fff4d6")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 40.0
	sun.shadow_blur = 1.5
	sun.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	parent.add_child(sun)

	var we := WorldEnvironment.new()
	we.name = "Env"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#4fa8ff")
	sm.sky_horizon_color = Color("#bfe6ff")
	sm.ground_bottom_color = Color("#9fd4ff")
	sm.ground_horizon_color = Color("#bfe6ff")
	sm.sun_angle_max = 8.0
	sm.sun_curve = 0.2
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#cfe5ff")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 1.2
	env.fog_enabled = false
	we.environment = env
	parent.add_child(we)
