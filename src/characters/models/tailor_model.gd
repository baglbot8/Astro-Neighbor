class_name TailorModel
extends CharacterModel
## Stella — the Suit-Up tailor (our Mabel). She is a fellow astronaut, so she reuses the player's
## AstronautModel through its public `apply_style` API (never its internals) and only adds the
## tailor's prop: a thin measuring tape looped around her shoulders.
##
## Implements the whole `CharacterModel` API so an NPC drives her exactly like every other
## neighbour. `pose()` is the one channel that cannot be forwarded — AstronautModel exposes no
## per-channel accessor — so it returns the base default and nothing in src/characters/ relies on it.

## R2.2 gave every astronaut an OPAQUE navy visor and no face, so Stella has none either — that is
## correct and intended. Everything that says "this is Stella and not the player" therefore has to
## live in the suit, the silhouette and the prop:
##   * a dusty-rose suit with a plum trouser block and a mauve jacket panel (three clear value
##     zones, AC colour blocking) against the player's white/indigo/blue,
##   * a rose-tinted visor pane, so her window reads plum where the player's reads blue,
##   * a soft work cap instead of the player's bare helmet,
##   * the measuring tape over her shoulders.
## R2.6: every one of these is a pastel. The first pass used #ffd9e4 (V 1.00), #ff5d8f (S 0.64
## V 1.00) and `hat_crown`, whose five emissive gems are the most saturated thing in the cast — a
## crown on a tailor was both loud and wrong, so it is a cap now.
const STYLE := {
	"name": "Stella",
	"suit_color": "#e6d2d4",
	"trouser_color": "#584a6b",
	"panel_color": "#b294a2",
	"accent_color": "#c4818d",
	"visor_tint": "#e39ab4",
	"skin_tone": "#f0c39a",
	"hair_color": "#4c3ba8",
	"backpack_id": "pack_basic",
	"hat_id": "hat_cap",
}
const TAPE := Color("#d8bd7c")
const TAPE_EDGE := Color("#a98b52")
## Shoulder height of the CURRENT AstronautModel: the pelvis sits at 0.325, the torso is 0.39 tall
## (so its top face is at 0.520) and the helmet starts at 0.68. 0.615 put the loop in the empty gap
## BETWEEN the torso and the helmet, where it was invisible from the front; 0.545 drapes it over the
## shoulders of the torso itself, which is where a tailor's tape actually sits.
const TAPE_Y := 0.545
## Y of the astronaut's pelvis node, so the tape can hang off it and inherit the body bob.
const PELVIS_Y := 0.325

var _astro: AstronautModel
var _tape: Node3D
var _tape_base_y: float = TAPE_Y - PELVIS_Y
var _t: float = 0.0


func _ready() -> void:
	_astro = AstronautModel.new()
	_astro.name = "Astronaut"
	_astro.follow_game_state = false
	_astro.style_override = STYLE
	add_child(_astro)
	_astro.footstep.connect(func(foot: int) -> void: footstep.emit(foot))
	_astro.emote_finished.connect(func(emote: String) -> void: emote_finished.emit(emote))
	scale = Vector3.ONE * body_scale
	_build_tape()


## Measuring tape looped over the shoulders, with tick marks and two hanging ends. It is parented to
## the astronaut's pelvis (not to the model root) so it rides the idle breathing bob and the walk
## waddle instead of hovering statically in front of a moving body.
func _build_tape() -> void:
	_tape = Node3D.new()
	_tape.name = "MeasuringTape"
	var host := _astro.find_child("Pelvis", true, false) as Node3D
	if host == null:
		host = _astro
		_tape_base_y = TAPE_Y
	_tape.position = Vector3(0.0, _tape_base_y, 0.02)
	host.add_child(_tape)
	# R2.6: the tape is cloth, so it is matte. It also sits a size up (the torso is 0.49 across) so
	# it actually drapes over the shoulders instead of hovering inside them.
	var m_tape := ChibiModel._toon(TAPE, ChibiModel._matte({"spec": 0.03, "rim": 0.03}))
	var m_tick := ChibiModel._toon(TAPE_EDGE, ChibiModel._matte({"spec": 0.0, "rim": 0.02}))
	var loop := ChibiModel.torus(0.248, 0.286, 28, 6)
	var ring := MeshInstance3D.new()
	ring.name = "Loop"
	ring.mesh = loop
	ring.material_override = m_tape
	ring.scale = Vector3(1.02, 0.42, 0.94)
	ring.rotation.x = 0.16
	_tape.add_child(ring)
	for i in 10:
		var a := TAU * float(i) / 10.0
		var tick := MeshInstance3D.new()
		tick.name = "Tick"
		tick.mesh = ChibiModel.rounded_box(Vector3(0.009, 0.006, 0.030), 0.003, 6)
		tick.material_override = m_tick
		tick.position = Vector3(cos(a) * 0.272, 0.004, sin(a) * 0.252)
		tick.rotation.y = -a
		_tape.add_child(tick)
	for sx: float in [-1.0, 1.0]:
		var tail := Node3D.new()
		tail.name = "Tail"
		tail.position = Vector3(0.115 * sx, -0.015, -0.225)
		tail.rotation = Vector3(0.22, 0.0, 0.30 * sx)
		_tape.add_child(tail)
		for j in 3:
			var seg := MeshInstance3D.new()
			seg.name = "Seg"
			seg.mesh = ChibiModel.rounded_box(Vector3(0.052, 0.062, 0.012), 0.006, 8)
			seg.material_override = m_tape if j % 2 == 0 else m_tick
			seg.position = Vector3(0.006 * j * sx, -0.058 * j, 0.004 * j)
			seg.rotation.z = 0.10 * j * sx
			tail.add_child(seg)


# ----------------------------------------------------------------------------- forwarded API
func set_state(new_state: String) -> void:
	if _astro:
		_astro.set_state(new_state)


func get_state() -> String:
	return _astro.get_state() if _astro else "idle"


func get_state_time() -> float:
	return _astro.get_state_time() if _astro else 0.0


func tick(delta: float, speed_factor: float) -> void:
	if _astro == null:
		return
	_astro.tick(delta * anim_time_scale, speed_factor)
	_t += delta * anim_time_scale
	if _tape:
		# the tape sways gently, always a beat behind her body
		_tape.rotation.z = 0.05 * sin(TAU * _t / 3.1)
		_tape.position.y = _tape_base_y + 0.006 * sin(TAU * _t / 2.0)


func emote_duration(emote: String) -> float:
	return AstronautModel.get_emote_duration(emote)


static func get_emote_duration(emote: String) -> float:
	return AstronautModel.get_emote_duration(emote)
