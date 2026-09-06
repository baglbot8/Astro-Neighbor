class_name PlanetRing
extends Node3D
## A flat, banded planetary ring (annulus mesh) around the planet, tilted, double sided.
## Purely decorative: no collision, no shadows.

const RING_SHADER := preload("res://src/shaders/ring.gdshader")
const SEGMENTS := 160

@export var inner_radius: float = 28.0
@export var outer_radius: float = 39.0
@export var tilt_deg: float = 35.0
@export var ring_color: Color = Color("#ffcf8a")
## Overall alpha of the band. High on purpose: a faint arc reads as a rendering bug, not a ring.
@export var opacity: float = 0.98

var _mat: ShaderMaterial

func _ready() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in SEGMENTS + 1:
		var a := float(i) / float(SEGMENTS) * TAU
		var c := cos(a)
		var s := sin(a)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, float(i) / float(SEGMENTS)))
		st.add_vertex(Vector3(c * inner_radius, 0.0, s * inner_radius))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, float(i) / float(SEGMENTS)))
		st.add_vertex(Vector3(c * outer_radius, 0.0, s * outer_radius))
	for i in SEGMENTS:
		var a := i * 2
		st.add_index(a)
		st.add_index(a + 2)
		st.add_index(a + 1)
		st.add_index(a + 1)
		st.add_index(a + 2)
		st.add_index(a + 3)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "RingMesh"
	mi.mesh = mesh
	_mat = ShaderMaterial.new()
	_mat.shader = RING_SHADER
	_mat.set_shader_parameter("ring_color", ring_color.lightened(0.06))
	_mat.set_shader_parameter("ring_shade", ring_color.darkened(0.32).lerp(Color("#8a6ab0"), 0.4))
	_mat.set_shader_parameter("opacity", opacity)
	_mat.set_shader_parameter("tonemap_white", 6.0)
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.extra_cull_margin = outer_radius
	add_child(mi)
	rotation = Vector3(deg_to_rad(tilt_deg), 0.0, deg_to_rad(8.0))

## Updates the lit side and night tint.
func update_lighting(sun_dir: Vector3, night: float) -> void:
	_mat.set_shader_parameter("sun_dir", sun_dir)
	_mat.set_shader_parameter("night", night)
