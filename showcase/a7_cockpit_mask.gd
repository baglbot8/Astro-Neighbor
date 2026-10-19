extends "res://showcase/cockpit_intro.gd"
## A7 (STORY_FIT_REVIEW) target probe: the cockpit showcase's play mode, plus ONE frozen pair at the
## meteor beat's tau >= 5.8 (the showcase's own "meteor_t5_8" moment): the clock stopped
## (Engine.time_scale 0, so the beat's tau and the meteor hold still), the HUD hidden, a normal frame
## and then the meteor's Rock drawn unshaded magenta, so the rock's on-screen colour can be measured
## over a real pixel mask. Not shipped. Same flags as cockpit_intro.tscn (--mode=play --shots=<dir>).

var _a7_done := false


func _process(delta: float) -> void:
	super(delta)
	if _a7_done or _shots == "" or _cockpit == null or not is_instance_valid(_cockpit):
		return
	var st: Dictionary = _cockpit.debug_state()
	if str(st.get("phase", "")) == "METEOR" and float(st.get("tau", 0.0)) >= 5.8:
		_a7_done = true
		_a7_pair(float(st["tau"]))


func _a7_pair(tau: float) -> void:
	Engine.time_scale = 0.0
	var layers: Array = []
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if (n as CanvasLayer).visible:
			layers.append(n)
			(n as CanvasLayer).visible = false
	var meteor := _cockpit.get("_meteor") as Node3D
	var rock := meteor.get_node("Rock") as MeshInstance3D
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join("a7_cockpit_rock.png"))
	var keep := rock.material_override
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(1, 0, 1)
	rock.material_override = mm
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join("a7_cockpit_mask.png"))
	rock.material_override = keep
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join("a7_cockpit_rock_again.png"))
	print("A7 COCKPIT pair tau=%.2f layers_hidden=%d" % [tau, layers.size()])
	for n in layers:
		(n as CanvasLayer).visible = true
	Engine.time_scale = 1.0
