class_name MeteorSteam
extends Node3D
## THE METEOR'S STEAM (builder METEOR3, docs/STORY_HOME_SPEC.md 9.6.6; the user: "can we add a bit of a steam
## haze to the planet. Also maybe some appearing and disappearing rising white dots. It's so clear all the time,
## doesn't feel intense enough"). Two of the three parts live here; the level does the third:
##   * RISING MOTES: DOT_COUNT soft white dots round the player that fade in, drift up with a little sway, and
##     fade out, then start again somewhere else. One MultiMesh, moved on the CPU (planet_safari.gd RULES FOR
##     CONTENT: no GPU particles), each quad turned to the camera here.
##   * THE HORIZON HAZE: a steam-coloured band where the sky meets the rock (meteor_steam.gdshader mode 1).
##   * (The level) the ground's distance haze: the Environment's depth fog, turned steam-coloured and thicker
##     for the survey and put back after (MeteorSurveyLevel._apply_haze).
## The cracks stay clear: their splits, pools and plumes are fog_disabled additive light, drawn over all of it.

const SHADER := preload("res://src/meteor_survey/meteor_steam.gdshader")
const DOT_COUNT := 96
## Where motes start: this far round the rock from the eye (m), mostly ahead of it.
const NEAR_M := 3.0
const FAR_M := 11.0
const RISE := Vector2(0.35, 0.8)     # m/s
const LIFE := Vector2(2.6, 5.5)      # s
const SIZE := Vector2(0.08, 0.17)    # m across
const PEAK_ALPHA := 0.8
const HAZE_RADIUS := 120.0
const STEAM := Color(0.70, 0.62, 0.64)

var rock: Planet
var level: PlanetSafari
var _mm: MultiMeshInstance3D
var _haze: MeshInstance3D
var _haze_mat: ShaderMaterial
var _dots: Array = []   # {base: Vector3 ground point, up, side, t, life, rise, size, sway}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "Steam"
	_rng.seed = 60928
	var dot_mat := ShaderMaterial.new()
	dot_mat.shader = SHADER
	dot_mat.set_shader_parameter("mode", 0)
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = q
	mm.instance_count = DOT_COUNT
	_mm = MultiMeshInstance3D.new()
	_mm.name = "Motes"
	_mm.multimesh = mm
	_mm.material_override = dot_mat
	_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The motes move every frame round the eye; a stale AABB would cull them.
	_mm.custom_aabb = AABB(Vector3.ONE * -60.0, Vector3.ONE * 120.0)
	add_child(_mm)
	for i in range(DOT_COUNT):
		mm.set_instance_color(i, Color(1, 1, 1, 0))
		_dots.append({"base": Vector3.ZERO, "up": Vector3.UP, "side": Vector3.RIGHT, "t": 0.0, "life": 0.0,
			"rise": 0.5, "size": 0.08, "sway": 0.0, "ready": false})
	_haze_mat = ShaderMaterial.new()
	_haze_mat.shader = SHADER
	_haze_mat.set_shader_parameter("mode", 1)
	_haze_mat.set_shader_parameter("steam", STEAM)
	_haze_mat.set_shader_parameter("amount", 0.6)
	_haze_mat.render_priority = -100
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 32
	s.rings = 16
	_haze = MeshInstance3D.new()
	_haze.name = "HorizonHaze"
	_haze.mesh = s
	_haze.material_override = _haze_mat
	_haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_haze.scale = Vector3.ONE * HAZE_RADIUS
	_haze.custom_aabb = AABB(Vector3.ONE * -1.0, Vector3.ONE * 2.0)
	add_child(_haze)


## Called by the level every frame (after the camera has moved), with the eye's camera.
func step(cam: Camera3D, delta: float) -> void:
	if cam == null or rock == null:
		return
	var eye := cam.global_position
	var up := rock.up_at(eye)
	_haze.global_position = eye
	_haze_mat.set_shader_parameter("up_dir", up)
	var mm := _mm.multimesh
	var cam_basis := cam.global_transform.basis
	var look := -cam_basis.z
	look = (look - up * look.dot(up))
	if look.length_squared() < 1e-4:
		look = cam_basis.y - up * cam_basis.y.dot(up)
	look = look.normalized()
	for i in range(DOT_COUNT):
		var d: Dictionary = _dots[i]
		d["t"] = float(d["t"]) + delta
		if not bool(d["ready"]) or float(d["t"]) >= float(d["life"]):
			_spawn(d, eye, up, look, not bool(d["ready"]))
		var t := float(d["t"])
		var life := float(d["life"])
		var k := clampf(t / life, 0.0, 1.0)
		var a := pow(sin(PI * k), 1.5) * PEAK_ALPHA
		var pos: Vector3 = d["base"] + (d["up"] as Vector3) * (float(d["rise"]) * t) + \
			(d["side"] as Vector3) * (0.18 * sin(t * 1.7 + float(d["sway"])))
		var sz := float(d["size"]) * (0.8 + 0.4 * k)
		mm.set_instance_transform(i, Transform3D(cam_basis.scaled(Vector3.ONE * sz), pos))
		mm.set_instance_color(i, Color(1, 1, 1, a))


func _spawn(d: Dictionary, eye: Vector3, up: Vector3, look: Vector3, first: bool) -> void:
	# Mostly ahead (within ~75 deg of where the eye looks), some anywhere, so turning round still finds a few.
	var yaw := _rng.randf_range(-1.3, 1.3) if _rng.randf() < 0.75 else _rng.randf_range(-PI, PI)
	var heading := look.rotated(up, yaw)
	var dist := lerpf(NEAR_M, FAR_M, sqrt(_rng.randf()))
	var here := rock.dir_of(eye)
	var ang := dist / maxf(rock.radius, 1.0)
	var dir := (here * cos(ang) + heading * sin(ang)).normalized()
	var base := rock.surface_point(dir)
	d["base"] = base + dir * _rng.randf_range(0.0, 0.3)
	d["up"] = dir
	d["side"] = heading.cross(dir).normalized()
	d["life"] = _rng.randf_range(LIFE.x, LIFE.y)
	# The first wave starts part-way through its life, so the air is already full when the fade lifts.
	d["t"] = _rng.randf_range(0.0, float(d["life"])) if first else 0.0
	d["rise"] = _rng.randf_range(RISE.x, RISE.y)
	d["size"] = _rng.randf_range(SIZE.x, SIZE.y)
	d["sway"] = _rng.randf_range(0.0, TAU)
	d["ready"] = true
