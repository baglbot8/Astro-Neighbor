class_name MeteorStreak
extends Node3D
## THE METEOR, FAR OFF (STORY_HOME_SPEC.md rulings 2.6/2.7). "The clue is a faint streak in the sky
## of every world - the meteor, far off... in the back of your photos." "The streak grows with
## parts, not time. Faint at 0 parts, clearer at 5. Visual only; nothing says how long is left."
##
## BUILT AND FED LIKE A SKY BODY (see sky_bodies.gd's header and its own per-frame `update_state`,
## which this copies the geometry convention from rather than importing - nobody in this build round
## owns sky_bodies.gd, and this streak does not drift or track a planet id the way a neighbouring
## world does). environment.gd instantiates one per Environment and calls `update_state` from
## `_apply()`, THE PER-FRAME SKY WRITE (CLAUDE.md: "environment.gd rewrites the sky every frame ...
## change the per-frame write" - a one-shot value here would be undone next frame exactly like the
## sky material's own uniforms are).
##
## SAME DIRECTION EVERYWHERE. One fixed azimuth-offset/elevation-fraction slot (AZ_OFFSET_DEG /
## ELEV_BAND_FRAC below), the same two numbers on every world and every safari - never a per-planet
## value - so the streak reads as one distant object seen from wherever you are standing, the way
## SkyBodies' own slots are the same table on every planet. Unlike a SkyBodies world it does not
## drift: a thing "far off" that is meant to go unnoticed until the Professor points it out should
## hold still, not wander the sky and draw the eye.
##
## LOOK. A soft flat streak - five cross-sections tapering to nothing at both ends via per-vertex
## alpha - unshaded, additive, no texture, no separate shader file (procedural, CLAUDE.md "Everything
## is procedural"). Pure white/cool-grey: it carries no hue of its own, so it cannot move the
## whole-frame saturation gates (STYLE_GUIDE R2.6) the way a tinted prop could. Alpha alone carries
## "faint" -> "clearer"; the gate in the builder's report is the number, not a look-alike claim.

## Azimuth OFFSET (deg) from the opening camera bearing (SkyBodies' az_origin convention) and
## elevation as a fraction of the visible sky band (SkyBodies' own SLOTS convention). -9 deg / 0.86
## sits high and just left of centre - clear of SkyBodies' six worlds (see sky_bodies.gd SLOTS,
## which never places anything at -9) and clear of the arrival banner's x 595-1160 window.
const AZ_OFFSET_DEG := -9.0
const ELEV_BAND_FRAC := 0.86
## Just past SkyBodies.BODY_DISTANCE (140.0), so a neighbouring world never draws in front of it.
const DISTANCE := 148.0
const LENGTH := 22.0
const WIDTH := 1.35
## Alpha at 0 parts / 5 parts. Never opaque - ruling 2.7 calls it "faint" even at its clearest, a
## thing you would only notice once the Professor names it.
const ALPHA_MIN := 0.045
const ALPHA_MAX := 0.26
const ROCKET_PARTS_MAX := 5.0
## Angle (deg) the streak's long axis is tilted off the local horizontal, around the view axis -
## a comet-style diagonal smear rather than a level bar.
const TILT_DEG := 32.0

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D

func _ready() -> void:
	_build()

func _build() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Streak"
	_mesh_instance.mesh = _make_mesh()
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.vertex_color_use_as_albedo = true
	_material.albedo_color = Color(1.0, 1.0, 1.0, ALPHA_MIN)
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.disable_receive_shadows = true
	_mesh_instance.material_override = _material
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_mesh_instance.extra_cull_margin = LENGTH
	_mesh_instance.visible = false
	add_child(_mesh_instance)

## A flat quad along local +X, tapering to nothing at both ends AND across the width via per-vertex
## alpha (5 cross-sections for a smooth taper, not a hard diamond). Lies in the local XY plane;
## `update_state` re-orients the whole node to face the camera every frame.
static func _make_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()
	var half_l := LENGTH * 0.5
	var half_w := WIDTH * 0.5
	var n := 5
	for i in range(n):
		var u: float = float(i) / float(n - 1)
		var x: float = lerpf(-half_l, half_l, u)
		var a: float = sin(u * PI)   # 0 at both ends, 1 at the middle
		verts.append(Vector3(x, -half_w, 0.0))
		colors.append(Color(1.0, 1.0, 1.0, a))
		verts.append(Vector3(x, half_w, 0.0))
		colors.append(Color(1.0, 1.0, 1.0, a))
	for i in range(n - 1):
		var a0 := i * 2
		idx.append(a0); idx.append(a0 + 1); idx.append(a0 + 2)
		idx.append(a0 + 1); idx.append(a0 + 3); idx.append(a0 + 2)
		idx.append(a0 + 2); idx.append(a0 + 1); idx.append(a0)
		idx.append(a0 + 2); idx.append(a0 + 3); idx.append(a0 + 1)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am

## Per-frame update from environment.gd's `_apply()` (see that file's per-frame sky write). `cam_pos`
## anchors the streak like a SkyBodies world (it never parallaxes); `up`/`east` are the player's
## local frame; `az_origin` is the opening camera bearing (deg, SkyBodies' convention); `limb_dir` /
## `limb_angle` / `band_top` are the same three the sky shader and SkyBodies read every frame;
## `parts` is `GameState.rocket_part_count()` (0..5, clamped).
func update_state(cam_pos: Vector3, up: Vector3, east: Vector3, az_origin: float, limb_dir: Vector3,
		limb_angle: float, band_top: float, parts: int) -> void:
	var t: float = clampf(float(parts) / ROCKET_PARTS_MAX, 0.0, 1.0)
	var alpha: float = lerpf(ALPHA_MIN, ALPHA_MAX, t)
	_material.albedo_color = Color(1.0, 1.0, 1.0, alpha)
	_mesh_instance.visible = true

	var band: float = clampf(band_top, 0.02, 1.2)
	var az: float = az_origin + AZ_OFFSET_DEG
	var elev := _elev_on_cone(az, limb_angle + band * ELEV_BAND_FRAC, up, east, limb_dir)
	var dir := _sky_dir(az, rad_to_deg(elev), up, east)
	global_position = cam_pos + dir * DISTANCE

	# Face the camera flat-on (a billboard), tilted TILT_DEG off the local horizontal so it reads as
	# a diagonal streak rather than a level bar.
	var to_cam := (cam_pos - global_position)
	if to_cam.length_squared() < 0.0001:
		return
	to_cam = to_cam.normalized()
	var ref_up := up if absf(up.dot(to_cam)) < 0.98 else east
	var flat_right := to_cam.cross(ref_up).normalized()
	var flat_up := flat_right.cross(to_cam).normalized()
	var tilt := deg_to_rad(TILT_DEG)
	var axis_x := flat_right * cos(tilt) + flat_up * sin(tilt)
	var axis_y := flat_up * cos(tilt) - flat_right * sin(tilt)
	basis = Basis(axis_x, axis_y, to_cam)

# ----------------------------------------------------------------------------- geometry
# Local copies of SkyBodies' two static sky-frame helpers (sky_bodies.gd `_elev_on_cone` /
# `_sky_dir`, unowned this round - kept identical rather than imported so this file has no
# dependency on it). Elevation (radians, above the local horizontal) of the direction at azimuth
# `az_deg` that sits exactly `cone` radians away from `limb_dir`.
static func _elev_on_cone(az_deg: float, cone: float, up: Vector3, east: Vector3, limb_dir: Vector3) -> float:
	var flat := east - up * up.dot(east)
	if flat.length_squared() < 0.0001:
		flat = Vector3.RIGHT - up * up.dot(Vector3.RIGHT)
	flat = flat.normalized().rotated(up, deg_to_rad(az_deg))
	var a := up.dot(limb_dir)
	var b := flat.dot(limb_dir)
	var r := sqrt(a * a + b * b)
	if r < 0.0001:
		return -0.25
	var phi := atan2(b, a)
	return PI - asin(clampf(cos(cone) / r, -1.0, 1.0)) - phi

## Unit direction at `az_deg` (from local east toward local north) and `elev_deg` above the local
## horizontal.
static func _sky_dir(az_deg: float, elev_deg: float, up: Vector3, east: Vector3) -> Vector3:
	var flat := east - up * up.dot(east)
	if flat.length_squared() < 0.0001:
		flat = Vector3.RIGHT - up * up.dot(Vector3.RIGHT)
	flat = flat.normalized().rotated(up, deg_to_rad(az_deg))
	var e := deg_to_rad(elev_deg)
	return (up * sin(e) + flat * cos(e)).normalized()
