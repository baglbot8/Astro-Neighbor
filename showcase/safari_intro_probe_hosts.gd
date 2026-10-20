extends RefCounted
## PROBE-ONLY HOSTS for SafariIntro's generic entry (builder SINTRO, 2026-10-19; a test harness, not gameplay).
## The meteor survey and the cave are PlanetSafari subclasses with their own start flows; their owners will add the
## ONE hook line (safari_intro.gd, FOR A PLANET BUILDER). To prove that line works on them WITHOUT editing their
## files, these subclasses override only the start flow with a copy of it in which the old two "lift" lines are
## replaced by `if not await SafariIntro.lift(self, DATA): return`. Everything else is the real class. The DATA here
## is a STUB (a short scene-1 arc in the start frame's own metres), not the outing's real intro.

const STUB_METEOR := {
	"title": "The Meteor", "subtitle": "A survey stub",
	"scene1": {"local_path": [Vector3(6.0, 3.5, 2.0), Vector3(3.0, 3.0, 5.5), Vector3(-1.5, 2.6, 6.0)],
		"local_look_from": Vector3(0.0, 0.8, -3.0), "local_look_to": Vector3(0.0, 0.8, -4.0), "ease": "inout"},
	"total": 8.5, "cut": 3.9,
}
const STUB_CAVE := {
	"title": "The Crystal Cave", "subtitle": "A cave stub",
	"scene1": {"local_path": [Vector3(1.6, 1.6, 1.6), Vector3(0.0, 1.7, 2.4), Vector3(-1.6, 1.6, 1.6)],
		"local_look_from": Vector3(0.0, 0.9, -2.0), "local_look_to": Vector3(0.0, 0.9, -2.5), "ease": "inout",
		"local_spores_at": Vector3(0.0, 1.2, -1.5), "spore_cols": [Color("#7fd8c8")]},
	"total": 8.5, "cut": 3.9,
	"terrain_follow": false,
	"double_light": {"color": Color(1.0, 0.95, 0.85), "energy": 1.2, "range": 4.0},
	"swoop": {"r": [Vector3(0.0, 1.2, 0.0), Vector3(1.4, 1.6, 0.0), Vector3(3.0, 1.2, -0.7), Vector3(3.85, 0.0, 0.0)]},
}


class ProbeMeteor extends MeteorSurveyLevel:
	func _start() -> void:
		if player == null or rig == null:
			_restored = true
			_finish.call_deferred()
			return
		_saved_xform = player.global_transform
		_input_saved = player.input_enabled
		_move_locked_saved = player.is_move_locked()
		player.set_move_locked(true)
		phase = Phase.FADE_IN
		await layer.fade_to(1.0, FADE_SEC)
		if not is_instance_valid(player):
			return
		_enter_rock()
		await _warm_up()
		# THE ONE HOOK LINE (in place of `layer.show_awake_ui(true)` + `await layer.fade_to(0.0, FADE_SEC)`):
		# (A probe run may swap in other data: the data-validation cases.)
		if not await SafariIntro.lift(self, Engine.get_meta("sip_case_data", STUB_METEOR)):
			return
		hud.show_play(true)
		for l: String in START_LINES:
			hud.say(l if l != START_LINES[-1] or MobileUI.is_mobile() else START_LINE_HOVER_KEYS)
		_begin_attempt()


class ProbeCave extends CaveVisit:
	func _run() -> void:
		while EventBus.is_modal_open() or _dialogue_active():
			await get_tree().process_frame
		if planet == null or player == null or rig == null:
			_restored = true
			queue_free()
			return
		tips_on = false
		day = GameState.day_count
		is_night = false
		_saved_xform = player.global_transform
		player.set_move_locked(true)
		phase = Phase.FADE_IN
		await layer.fade_to(1.0, FADE_SEC)
		if not is_instance_valid(player):
			return
		_begin_behind_black()
		await _warm_up()
		# THE ONE HOOK LINE:
		if not await SafariIntro.lift(self, STUB_CAVE):
			return
		player.set_move_locked(false)
		phase = Phase.AWAKE
		elapsed = 0.0
