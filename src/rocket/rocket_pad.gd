extends Node3D
## The rocket pad: how you leave the planet. Instanced by world.gd as /root/World/Rocket, it finds
## the Planet in group "planet" and plants itself on `planet.pad_transform()`.
##
## FINDING IT IS THE WHOLE POINT. The pad sits 9-16 m from the spawn point on a 13-26 m planet —
## over the horizon, and the spawn facing is 122 deg away from it — so a new player used to see no
## rocket, no mast and no beacon on any planet (rocket critic, ~/.astro_captures/spawn_*). Five cues
## now answer "how do I get off this planet?" on EVERY biome, not just the two that get a sand path
## from the ground shader:
##   1. a 7.6 m beacon mast with a halo billboard, tall enough to clear the horizon from spawn
##   2. a bobbing waypoint marker floating over the rocket
##   3. `PadCompass` — a cream HUD pip clamped to the screen edge pointing at the pad, with metres
##   4. a trail of stepping stones + glowing chevrons along the spawn->pad great circle (MultiMesh,
##      biome-coloured, built here so Zorp and Bolt get a cue too)
##   5. a one-off toast, offered through `HintChannel` so it is shown once ever, never over a
##      conversation, and retired the moment the player reaches the pad
##
## Everything on the deck is dropped onto the planet's sphere (RocketMeshLib.sag) so nothing floats
## at the rim; the deck carries a trimesh collider on the terrain layer so the astronaut walks up
## onto it.
##
## THE ROCKET IS NEVER OFF THE EDGE OF THE FRAME. Every camera in the flight - the launch framing
## that tips down to show the home planet shrinking, the blend out of the gameplay rig, the chase,
## the descent - runs its aim through `RocketJourney.flight_frame`, which clamps how far off the
## rocket the view axis may sit. Without it the launch tip reached 84 degrees and threw the rocket
## clean off the top for the last seconds of the climb; the shrinking planet then slid off the
## bottom and the journey handed the space scene three frames of empty starfield.
##
## LEAVING IS ONE CONTINUOUS JOURNEY (docs/STYLE_GUIDE.md R2.5). Interacting opens the destination
## card right here on the pad - the choice used to live in a separate map screen half way through
## the trip, which is exactly what made the flight read as two scenes instead of one move. Once a
## world is chosen the astronaut walks to the hatch, hops in, the engine lights, and the rocket
## CLIMBS: a dedicated flight camera takes over (seeded from the gameplay camera, so nothing pops),
## `Environment.set_space_blend()` ramps 0 -> 1 so the sky darkens into space, the home planet
## shrinks away below, and the rocket tips over toward the destination world hanging in the sky.
## At the top of the climb the frame is written into `RocketJourney` and the space scene picks it
## up mid-air - no fade, no cut you can see. Arriving is the same in reverse: the rocket comes in
## from space with the planet growing ahead and flies an arc down onto the pad.
##
## The whole thing is wrapped in EventBus.ui_modal_opened("cutscene") so the bag / decorate / pause
## hotkeys cannot fire during it, and `_end_cutscene` runs on every exit path including _exit_tree.
##
## A legacy short arrival (`SceneRouter.go_to_planet` with no journey record - the space map's Esc
## path, Director timelines) still plays the old hold-and-drop landing.

const PAD_R := 2.55
const DECK_Y := 0.10
const LIGHT_RING_R := 1.74
const LIGHT_COUNT := 4
const LIGHT_CYCLE := 1.5
const POST_R := 2.02
## Mast height. The old 3.35 m mast could not clear the horizon from the spawn point on any planet;
## 7.6 m does on all four (home r16: 19.6 m of combined horizon vs 11.5 m to walk; zorp/bolt r13:
## 17.3 vs 9.3; hub r26: 25.6 vs 15.8).
const MAST_TOP := 7.6
const PULSE_RANGE := 8.0
const HATCH_STAND_OFF := 1.35
const WALK_SECONDS := 1.35

# --------------------------------------------------------------------------- the continuous climb
## How long the climb from the pad to the edge of space takes. Long enough that the planet visibly
## shrinks rather than snapping away, short enough that it is not a cutscene you resent.
const CLIMB_SECONDS := 6.4
## Seconds the flight camera takes to blend out of the gameplay camera's framing. It is SEEDED with
## the gameplay camera's exact transform, so this is a blend of framing, not a cut.
const CLIMB_CAM_BLEND := 1.25
## Climb fraction over which `Environment.set_space_blend` goes 0 -> 1: the limb haze fades, the
## dome darkens to the deep-space navy and the stars come up to full.
const SPACE_BLEND_IN := Vector2(0.05, 0.78)
## How far the climb path leans toward the destination world. 0 = straight up.
const CLIMB_LEAN := 0.62
## Flight-camera framing at the very start of the climb, in metres. ABOVE the rocket and looking
## down past it, which is the framing that actually shows the planet shrinking: a camera trailing
## a rocket that is going straight up has the planet behind it, not in shot.
## The flank offset is deliberately small against the rise: looking almost straight down, the angle
## the rocket sits at off the camera axis tends to atan(side / up), and anything past ~20 deg pushes
## it off the top of the frame.
const LAUNCH_CAM_BACK := -0.5
const LAUNCH_CAM_UP := 12.0
const LAUNCH_CAM_SIDE := 3.8
## Look target during that first framing: below the rocket, so the ground fills the lower frame.
const LAUNCH_CAM_LEAD := -1.6
## How far BELOW the rocket the camera aims while the launch framing is held, as a fraction of the
## altitude (capped). This is what actually sells "our planet is getting smaller": without it the
## camera keeps the rocket centred and the world just slides off the bottom of the frame instead of
## shrinking into a ball in the middle of it.
const LAUNCH_LOOK_DOWN := 0.42
const LAUNCH_LOOK_DOWN_MAX := 120.0
## Climb fraction the launch framing is held for before the camera swings back behind the rocket.
## Held this long on purpose: this is the stretch where the home planet is in shot shrinking, and
## it is the whole point of the beat (R2.5).
const CLIMB_CAM_HOLD := 0.50
## Climb fraction by which the camera has reached the canonical seam framing (RocketJourney.CHASE_*)
## and holds it, so the handoff frame is deterministic.
const CLIMB_CAM_SETTLE := 0.88

# --------------------------------------------------------------------------- the arrival descent
## The whole arrival happens here, on the real planet, not on a stand-in globe: the cruise hands the
## rocket over on the destination's doorstep with the world a 14 deg disc ahead, and this is where
## it grows from there to standing on it. The first third is the hero beat - the lit face filling
## the frame with the rocket crossing it - which is why it is worth this much screen time.
const DESCENT_SECONDS := 7.4
## Descent fraction over which `set_space_blend` comes back 1 -> 0 and the sky becomes a sky again.
const SPACE_BLEND_OUT := Vector2(0.10, 0.62)
## The descent's own look-down, the mirror of the climb's: right after the cut the camera tips off
## the flight axis to put the world you are landing on in the middle of the frame, holds it there
## while it grows - this is the arrival hero beat - and levels back out for the touchdown. Without
## it the chase looks along a nearly tangential entry track and the planet sits off the edge.
const DESCENT_LOOK_DOWN := 0.42
const DESCENT_LOOK_DOWN_MAX := 120.0
## How far the descent arc bows toward the sunlit side (degrees of great-circle detour at its
## widest). The endpoints are fixed - the seam point and the pad - so this is the only freedom
## there is to keep the hero beat framed on a LIT face rather than on a night side.
const SUN_BOW_DEG := 22.0
## Camera framing at touchdown, in metres (the seam framing eases into this).
const LAND_CAM_BACK := 3.0
const LAND_CAM_UP := 3.2
const LAND_CAM_SIDE := 6.0
## The rocket's "in space" look, matching what space_travel.gd flies with: a dim plume (additive
## sprites stack to white against a starfield), tiny local light ranges, no smoke (no air). The
## climb crosses over to it as the sky does, so BOTH sides of the cut are already drawing the same
## rocket - and the descent crosses back as the atmosphere returns.
const SPACE_FLAME_INTENSITY := 0.30
const GROUND_FLAME_INTENSITY := 1.15
const SPACE_LIGHT_RANGE := 0.16
## Climb / descent fraction over which that crossover happens.
const SPACE_LOOK_IN := Vector2(0.30, 0.72)
const SPACE_LOOK_OUT := Vector2(0.18, 0.60)
## The flight camera never gets closer to the surface than this, so the last seconds of the descent
## do not put it inside a hill.
const CAM_GROUND_CLEAR := 2.6
## Blend back into the gameplay camera rig once the astronaut is out.
const HANDBACK_SECONDS := 0.8

# --------------------------------------------------------------------------- legacy short arrival
## Used only when there is no journey record (space map Esc, Director `go_to_planet` calls).
const RISE_SECONDS := 2.6
const RISE_HEIGHT := 34.0
const DESCEND_SECONDS := 2.4
const DESCEND_HEIGHT := 46.0
## The arrival banner is anchored centre-top for 0.55 + 2.5 + 0.4 s from the moment the planet
## loads. Holding the rocket high for this long means it is only ever a distant speck while the
## banner is up, instead of the banner sitting on the descending hull.
const ARRIVAL_HOLD := 1.8
## Seconds before the pad hint is offered to HintChannel, so it never lands on the arrival banner.
const HINT_DELAY := 3.2
## Distance at which the player has clearly found the pad (hint + compass retire).
const FOUND_RANGE := 7.0
## Height of the floating waypoint marker above the deck: clear of the 3.2 m rocket AND of the
## FLY sign's plate, which the marker used to hide behind on the approach.
const MARKER_Y := 5.40
## How far in front of the rocket (on the hatch side) the hidden astronaut is parked during the
## liftoff, so the follow camera frames the whole rocket instead of standing under the exhaust.
const LIFTOFF_CAM_OFFSET := 2.6
## How far the rocket eases off the deck during the ignition burn, before the real climb.
const IGNITION_LIFT := 1.45
const ROCKET_SCENE := preload("res://src/rocket/rocket_model.tscn")
const COMPASS_SCRIPT := preload("res://src/rocket/pad_compass.gd")
const PICKER_SCRIPT := preload("res://src/rocket/pad_destination_picker.gd")
const SPACE_SCENE := "res://src/rocket/space_travel.tscn"

# Deck tones. Clean warm greys, NOT muddied down: the blown-highlight budget is met by killing the
# deck's specular, dropping its shade_floor and cutting the pad lamps' energy (STYLE_GUIDE:
# "darkness must come from LIGHT and SHADOW, not from brown albedo").
const DECK_A := Color("#b6a886")
const DECK_B := Color("#a89876")
const DECK_MARK := Color("#6b5f47")
const DECK_CROSS := Color("#4a4234")
const STRIPE_YELLOW := Color("#bd9c4b")   # R2.6: was S 0.78, a loud ring on the deck.
const STRIPE_DARK := Color("#3c3730")
const POST_COLOR := Color("#7f90a6")
const POST_DARK := Color("#4a5568")
const SCREEN_COLOR := Color("#1a2333")
const SCREEN_PIXEL := Color("#77ccff")
const SIGN_CREAM := Color("#e6d8ae")
const SIGN_EDGE := Color("#c9ad74")
const SIGN_TEXT := Color("#6b5232")
const SIGN_POST := Color("#a9753f")
const MAST_BEACON := Color("#ff7a59")
const LIGHT_ON := Color("#ffd447")
const LIGHT_OFF := Color("#8a7a44")
const DECK_SHADE_FLOOR := 0.36

## Ground-trail colours per biome, so Zorp and Bolt get a cue in their own palette.
const TRAIL_COLORS := {
	"meadow": [Color("#d9c795"), Color("#ff9a4d")],
	"plaza": [Color("#e0d5b9"), Color("#ffcc33")],
	"violet": [Color("#b6a4dc"), Color("#3ec6ff")],
	"chrome": [Color("#8fa3bf"), Color("#ff8a3d")],
	# Both values are ARRAYS of two colours (stone, chevron) - `_build_trail` does `pair[0]`/`pair[1]`
	# off a `: Array` assignment, so a bare Color here hard-errors on the pad the first time you land.
	"flats": [Color("#cfbb9c"), Color("#ff9a4d")],
	"chalk": [Color("#c8bfa8"), Color("#e0a45c")],
}
## Stepping stones every this many metres along the spawn->pad great circle.
const TRAIL_STEP_M := 2.0
const TRAIL_MAX := 12

## Set in a showcase when there is no PlanetData to read the id from.
@export var planet_id_override: String = ""

var planet: Planet
var rocket: RocketModel

var _pad_root: Node3D
var _sign_root: Node3D
var _sign_mat: ShaderMaterial
var _screen_mat: ShaderMaterial
var _light_mats: Array[ShaderMaterial] = []
var _light_nodes: Array[OmniLight3D] = []
var _mast_halo: MeshInstance3D
var _marker: Node3D
var _marker_mat: ShaderMaterial
var _compass: PadCompass
var _dust: GPUParticles3D
var _interactable: Interactable
var _player: Player
var _ground_r := 16.0
var _busy := false
var _cutscene := false
var _time := 0.0
var _flash := 0.0
var _anim_speed := 0.0
var _walk_from := Vector3.UP
var _walk_to := Vector3.UP
var _walk_player: Player
var _carry_player := false
var _hop_from := Vector3.ZERO
var _hop_to := Vector3.ZERO
var _hop_up := Vector3.UP
var _hop_arc := 0.35
var _hatch_dir_local := Vector3.FORWARD
var _found := false
var _marker_alpha := 0.0
## Counts down while an arrival cutscene is running. If it ever reaches zero the pad hands control
## back regardless — a half-finished landing must never leave the player stranded on a planet.
var _arrival_watchdog := 0.0

# --------------------------------------------------------------------------- journey state
## The flight camera. Owns the frame from ignition to touchdown; seeded from (and handed back to)
## the gameplay CameraRig so the player never sees a camera cut.
var _cam: Camera3D
var _rig_cam: Camera3D
var _picker: PadDestinationPicker
var _dest_id := ""
## Curve the climb / descent flies, as four world-space bezier points.
var _arc: PackedVector3Array = PackedVector3Array()
## Local "up" the flight camera rolls around (the planet normal under the rocket).
var _flight_up := Vector3.UP
## Which flank the flight camera rides on: chosen so it looks AWAY from the sun.
var _cam_side := 1.0
## Fixed world flank for the whole flight: the normal of the plane the arc is flown in. Deriving
## the flank from `forward x up` instead would be degenerate at liftoff (the rocket goes straight
## up, so the two are parallel) and would swing the camera round the rocket as it pitched over.
var _cam_flank := Vector3.RIGHT
## Set while the journey arrival is descending, so `_process` does not fight the tween.
var _journey_arrival := false
## The rocket's parked transform, local to the pad (where the descent has to end up).
var _rest_xf := Transform3D.IDENTITY
## Descent arc endpoints, as a direction + radius pair each.
var _desc_dir_a := Vector3.UP
var _desc_dir_b := Vector3.UP
var _desc_r_a := 100.0
var _desc_r_b := 16.0
var _desc_p1 := Vector3.ZERO
var _desc_p2 := Vector3.ZERO
## Where on the sphere the astronaut steps out (captured before the flight moves anything).
var _landed_dir := Vector3.UP
## Sunward detour applied to the descent arc (radians), and the direction it bows toward.
var _sun_bow := 0.0
var _sun_dir := Vector3.UP
## The rocket's nose direction on the seam frame, eased onto the descent's own tangent.
var _seam_nose := Vector3.UP
## The "up" the climb camera's chase rig finished on (the radial, squared up against the flight
## axis). Written into the journey record so the space scene starts from the same rig.
var _seam_up := Vector3.UP
## Difference between the seam camera and the local chase rule, faded out over the first second.
var _seam_err_pos := Vector3.ZERO
var _seam_err_rot := Basis.IDENTITY
var _seam_err := 0.0
## Whether the rocket is currently wearing its space look (see SPACE_FLAME_INTENSITY).
var _space_look := false
## The chase reference frame handed over by the space scene, blended onto this planet's own.
var _ref_up := Vector3.UP
var _ref_flank := Vector3.RIGHT
var _ref_blend := 1.0
## Cached environment node (looked up once; `_descent_step` runs every frame).
var _env: Node
var _env_looked_up := false


func _ready() -> void:
	planet = _find_planet()
	_pad_root = Node3D.new()
	_pad_root.name = "Pad"
	add_child(_pad_root)
	if planet != null:
		_pad_root.global_transform = planet.pad_transform()
		_ground_r = planet.height_at(planet.data.pad_dir.normalized())
	_build_deck()
	_build_lights()
	_build_post()
	_build_mast()
	_build_rocket()
	_build_sign()
	_build_hose()
	_build_dust()
	_build_marker()
	_build_interactable()
	_build_trail()
	_build_compass()
	if RocketJourney.pending("arrive") and RocketJourney.to_id == planet_id():
		_prepare_journey_arrival()
		call_deferred("_play_journey_arrival")
	elif _arriving():
		_prepare_arrival()
		call_deferred("_play_arrival")
	else:
		RocketJourney.clear()
	# The destination has now been built - world.gd spawns the NPCs and the buildings before it
	# spawns this pad - so whatever the launch prewarmed has been used and can be let go.
	RocketJourney.release_prewarm()


func _exit_tree() -> void:
	# Never leave the world in a state where the player cannot open a menu because a cutscene was
	# interrupted by a scene change / quit, and never leave the HUD believing a rocket is still on
	# its way down.
	_end_cutscene()
	if not RocketJourney.switching:
		GameState.set_flag("rocket_arriving", false)
		# An abandoned launch (quit to title mid-cutscene) must let go of its prewarm requests. Not
		# while `switching`, because that is the departure cut and those requests are for the arrival
		# still to come - collecting them there would move the stall back onto the frame we just paid
		# to make invisible.
		RocketJourney.release_prewarm()


func _process(delta: float) -> void:
	_time += delta
	_update_lights(delta)
	_update_sign()
	_update_marker(delta)
	_update_hint(delta)
	_update_arrival_watchdog(delta)
	if _walk_player != null and is_instance_valid(_walk_player):
		_walk_player.get_model().tick(delta, _anim_speed)


## Guaranteed re-enable. If anything interrupts `_play_arrival` mid-await — a killed tween, a
## freed player — the pad would otherwise stay `_busy` with a disabled Interactable and the player
## could never leave that planet again.
func _update_arrival_watchdog(delta: float) -> void:
	if _arrival_watchdog <= 0.0:
		return
	_arrival_watchdog -= delta
	if _arrival_watchdog <= 0.0 and _busy:
		push_warning("RocketPad: arrival sequence overran its budget — restoring control.")
		_finish_arrival(_find_player())


# ============================================================================= look-ups
func _find_planet() -> Planet:
	var p := get_tree().get_first_node_in_group("planet")
	if p == null:
		p = get_node_or_null("/root/World/Planet")
	return p as Planet


func _find_player() -> Player:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Player
	return _player


## Id of the planet this pad stands on.
func planet_id() -> String:
	if planet_id_override != "":
		return planet_id_override
	if planet != null and planet.data != null:
		return planet.data.id
	return GameState.current_planet_id


func _biome() -> String:
	if planet != null and planet.data != null:
		return planet.data.biome
	return "meadow"


func _arriving() -> bool:
	return GameState.previous_planet_id != "" and GameState.flag("spawn_at_pad")


## Deck height at flat distance `r` from the pad centre, following the planet's curvature.
func _deck_y(r: float) -> float:
	return DECK_Y - RocketMeshLib.sag(r, _ground_r)


# ============================================================================= build
func _build_deck() -> void:
	var deck_profile := PackedVector2Array([
		Vector2(0.0, _deck_y(0.0)), Vector2(1.20, _deck_y(1.20)), Vector2(1.95, _deck_y(1.95)),
		Vector2(2.30, _deck_y(2.30)), Vector2(PAD_R, _deck_y(PAD_R) - DECK_Y),
		Vector2(PAD_R + 0.10, _deck_y(PAD_R) - DECK_Y - 0.07),
	])
	var deck_mesh := RocketMeshLib.lathe(deck_profile, 40)
	# No specular, tiny rim, deep shade floor: a lit disc this big was the single biggest source of
	# blown highlights in every pad framing.
	var deck := RocketMeshLib.mi(deck_mesh,
		RocketModel.deep_toon(DECK_A, {"shade": 0.52, "rim": 0.05, "spec": 0.0, "softness": 0.42}, DECK_SHADE_FLOOR),
		_pad_root, Vector3.ZERO, "Deck")
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var body := StaticBody3D.new()
	body.name = "DeckBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	col.shape = deck_mesh.create_trimesh_shape()
	body.add_child(col)
	_pad_root.add_child(body)

	_inlay(0.02, 1.95, 36, PackedColorArray([DECK_B]), 0.004, "Inlay")
	# A real dark landing target under the rocket: without it the deck was one flat white value.
	_inlay(1.06, 1.30, 36, PackedColorArray([DECK_CROSS]), 0.008, "TargetRing")
	_inlay(1.30, 1.46, 36, PackedColorArray([DECK_MARK]), 0.008, "CentreRing")
	_inlay(2.02, 2.30, 28, PackedColorArray([STRIPE_YELLOW, STRIPE_DARK]), 0.007, "HazardStripe")


## Flat inlaid ring on the deck. The colours ride in the vertex stream, so every inlay shares one
## vertex-colour toon material (and one deep shade floor).
func _inlay(r_in: float, r_out: float, segments: int, colors: PackedColorArray, lift: float, node_name: String) -> void:
	var mesh := RocketMeshLib.striped_annulus(r_in, r_out, segments, colors, _ground_r)
	var mi := RocketMeshLib.mi(mesh, _vertex_toon(), _pad_root, Vector3(0.0, DECK_Y + lift, 0.0), node_name)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static var _vc_mat: ShaderMaterial


static func _vertex_toon() -> ShaderMaterial:
	if _vc_mat == null:
		_vc_mat = MaterialLib.toon_vertex_color({"shade": 0.5, "rim": 0.0, "spec": 0.0}).duplicate() as ShaderMaterial
		_vc_mat.set_shader_parameter("shade_floor", DECK_SHADE_FLOOR)
	return _vc_mat


func _build_lights() -> void:
	var metal := MaterialLib.metal(POST_COLOR)
	for i in LIGHT_COUNT:
		var a := TAU * (float(i) + 0.5) / float(LIGHT_COUNT)
		var root := Node3D.new()
		root.name = "PadLight%d" % i
		root.position = Vector3(cos(a) * LIGHT_RING_R, _deck_y(LIGHT_RING_R), sin(a) * LIGHT_RING_R)
		_pad_root.add_child(root)
		RocketMeshLib.mi(RocketMeshLib.cylinder(0.085, 0.115, 0.24, 10), metal, root, Vector3(0.0, 0.12, 0.0), "Post")
		var mat := MaterialLib.glow(LIGHT_ON, 1.0, LIGHT_OFF).duplicate() as ShaderMaterial
		mat.set_shader_parameter("emission_day_scale", 1.0)
		mat.set_shader_parameter("emission_cap", 3.0)
		_light_mats.append(mat)
		var lens := RocketMeshLib.mi(RocketMeshLib.sphere(0.10, 10, 5), mat, root, Vector3(0.0, 0.27, 0.0), "Lens")
		lens.scale = Vector3(1.0, 0.72, 1.0)
		var omni := OmniLight3D.new()
		omni.name = "Glow"
		omni.position = Vector3(0.0, 0.34, 0.0)
		omni.light_color = LIGHT_ON
		omni.omni_range = 1.8
		omni.light_energy = 0.0
		omni.shadow_enabled = false
		root.add_child(omni)
		_light_nodes.append(omni)


func _build_post() -> void:
	var metal := MaterialLib.metal(POST_COLOR)
	var dark := MaterialLib.metal(POST_DARK, {"roughness": 0.4})
	var toward := _tangent_toward_spawn()
	var post_dir := toward.rotated(Vector3.UP, deg_to_rad(62.0))
	var root := Node3D.new()
	root.name = "ControlPost"
	root.position = post_dir * POST_R + Vector3(0.0, _deck_y(POST_R), 0.0)
	root.rotation.y = atan2(-toward.x, -toward.z)
	_pad_root.add_child(root)

	RocketMeshLib.mi(RocketMeshLib.cylinder(0.30, 0.36, 0.16, 16), dark, root, Vector3(0.0, 0.08, 0.0), "Base")
	RocketMeshLib.mi(RocketMeshLib.cylinder(0.20, 0.22, 1.06, 16), metal, root, Vector3(0.0, 0.69, 0.0), "Column")
	# Console head: a flat wedge with a screen, tilted toward the player.
	var head := Node3D.new()
	head.name = "Console"
	head.position = Vector3(0.0, 1.30, -0.06)
	head.rotation.x = deg_to_rad(24.0)
	root.add_child(head)
	var shell := RocketMeshLib.prism(RocketMeshLib.rounded_rect(0.62, 0.46, 0.09, 2), 0.075, 0.04)
	RocketMeshLib.mi(shell, RocketModel.deep_toon(Color("#c3cad6"), {"shade": 0.5, "spec": 0.06, "rim": 0.1}, 0.40),
		head, Vector3.ZERO, "Shell")
	_screen_mat = MaterialLib.glow(SCREEN_PIXEL, 1.1, SCREEN_COLOR).duplicate() as ShaderMaterial
	_screen_mat.set_shader_parameter("emission_day_scale", 0.85)
	_screen_mat.set_shader_parameter("emission_cap", 2.4)
	var screen := RocketMeshLib.prism(RocketMeshLib.rounded_rect(0.46, 0.30, 0.05, 2), 0.012, 0.006)
	RocketMeshLib.mi(screen, _screen_mat, head, Vector3(0.0, 0.02, -0.085), "Screen")


## The tall beacon mast, standing on the far rim of the deck (opposite the approach) so it crosses
## nothing: not the sign, not the rocket's face, not the walk-in. This is what pokes over the
## horizon from the spawn point.
func _build_mast() -> void:
	var metal := MaterialLib.metal(POST_COLOR)
	var dark := MaterialLib.metal(POST_DARK, {"roughness": 0.4})
	var toward := _tangent_toward_spawn()
	# Well off to one flank (the console is at +62 deg, this is at -118 deg): dead astern of the
	# rocket it read as a bare pole splitting every approach shot straight down the middle.
	var dir := toward.rotated(Vector3.UP, deg_to_rad(-118.0))
	var root := Node3D.new()
	root.name = "BeaconMast"
	root.position = dir * (PAD_R - 0.30) + Vector3(0.0, _deck_y(PAD_R - 0.30), 0.0)
	_pad_root.add_child(root)

	RocketMeshLib.mi(RocketMeshLib.cylinder(0.26, 0.34, 0.22, 12), dark, root, Vector3(0.0, 0.11, 0.0), "Foot")
	# Candy-striped landmark tower rather than a grey stick: cream column with warm bands, the same
	# read as an airfield beacon.
	var cream := RocketModel.deep_toon(Color("#dbd1ba"), {"shade": 0.5, "rim": 0.1, "spec": 0.04}, 0.38)
	RocketMeshLib.mi(RocketMeshLib.cylinder(0.085, 0.16, MAST_TOP - 0.5, 10), cream, root,
		Vector3(0.0, 0.22 + (MAST_TOP - 0.5) * 0.5, 0.0), "Mast")
	var band := RocketModel.deep_toon(MAST_BEACON, {"shade": 0.48, "rim": 0.12, "spec": 0.06}, 0.40)
	for i in 3:
		var y := 1.35 + 1.85 * float(i)
		var r: float = lerpf(0.155, 0.095, y / MAST_TOP)
		RocketMeshLib.mi(RocketMeshLib.lathe(PackedVector2Array([
			Vector2(r + 0.012, y - 0.28), Vector2(r + 0.012, y + 0.28)]), 10), band, root, Vector3.ZERO, "Band%d" % i)

	var beacon_mat := MaterialLib.glow(MAST_BEACON, 1.2, Color("#a34a34")).duplicate() as ShaderMaterial
	beacon_mat.set_shader_parameter("emission_day_scale", 1.0)
	beacon_mat.set_shader_parameter("emission_cap", 4.2)
	# Housing + lamp: a chunky lantern, readable as a shape and not just a bright dot. The cap and
	# roof are CREAM, not the near-black post metal: seen against the halo from any oblique angle
	# they were a black squiggle sitting on a pink disc (integration critic, capQ/try3_after.png).
	var lamp_shell := RocketModel.deep_toon(Color("#cfc4ab"), {"shade": 0.5, "rim": 0.14, "spec": 0.10}, 0.42)
	var lamp_trim := RocketModel.deep_toon(Color("#8e7f66"), {"shade": 0.5, "rim": 0.12, "spec": 0.08}, 0.40)
	RocketMeshLib.mi(RocketMeshLib.cylinder(0.34, 0.26, 0.12, 12), lamp_trim, root, Vector3(0.0, MAST_TOP - 0.32, 0.0), "LampCap")
	RocketMeshLib.mi(RocketMeshLib.cylinder(0.20, 0.30, 0.11, 12), lamp_shell, root, Vector3(0.0, MAST_TOP + 0.20, 0.0), "LampRoof")
	var beacon := RocketMeshLib.mi(RocketMeshLib.sphere(0.26, 12, 6), beacon_mat, root,
		Vector3(0.0, MAST_TOP - 0.05, 0.0), "MastBeacon")
	beacon.scale = Vector3(1.0, 0.86, 1.0)
	_light_mats.append(beacon_mat)
	var beacon_light := OmniLight3D.new()
	beacon_light.name = "MastBeaconLight"
	beacon_light.position = Vector3(0.0, MAST_TOP - 0.05, 0.0)
	beacon_light.light_color = MAST_BEACON
	beacon_light.omni_range = 4.0
	beacon_light.light_energy = 0.0
	beacon_light.shadow_enabled = false
	root.add_child(beacon_light)
	_light_nodes.append(beacon_light)

	# Soft halo billboard: this is the part that is still legible when the lamp itself is two pixels
	# tall on the far side of the planet.
	# `softness` is the radius the sprite stays at FULL brightness out to, so 0.62 painted a hard
	# 2.6 m salmon DISC with the lantern silhouetted on it. 0.18 keeps a small bright lamp and lets
	# the rest fall off as a glow, which is what a beacon looks like.
	var quad := QuadMesh.new()
	quad.size = Vector2(2.15, 2.15)
	quad.material = MaterialLib.glow_sprite(MAST_BEACON, 1.35, {"softness": 0.18, "core": 0.20,
		"points": 0.5, "blink": 0.45, "blink_speed": 2.6})
	_mast_halo = MeshInstance3D.new()
	_mast_halo.name = "BeaconHalo"
	_mast_halo.mesh = quad
	_mast_halo.position = Vector3(0.0, MAST_TOP - 0.05, 0.0)
	_mast_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_mast_halo)


## AC campsite-style gate on the approach path: two wooden posts with a plate slung between them,
## well ABOVE head height so the player walks under it and it never covers the rocket. The word
## reads on BOTH faces, so it is legible walking in from the spawn and again standing on the deck
## (the old single-sided sign was edge-on and unreadable from the pad). Nothing passes in front of
## the letters any more — the mast has moved to the opposite rim of the deck.
func _build_sign() -> void:
	var toward := _tangent_toward_spawn()
	_sign_root = Node3D.new()
	_sign_root.name = "FlySign"
	var r := PAD_R + 1.55
	_sign_root.position = toward * r + Vector3(0.0, _deck_y(r) - DECK_Y, 0.0)
	_sign_root.rotation.y = atan2(-toward.x, -toward.z)
	_pad_root.add_child(_sign_root)

	var wood := RocketModel.deep_toon(SIGN_POST, {"shade": 0.50, "rim": 0.12, "spec": 0.05}, 0.40)
	var wood_dark := RocketModel.deep_toon(Color("#7d5430"), {"shade": 0.5, "rim": 0.08, "spec": 0.0}, 0.38)
	for side: float in [-1.0, 1.0]:
		var x := 1.34 * side
		RocketMeshLib.mi(RocketMeshLib.cylinder(0.065, 0.09, 2.90, 8), wood, _sign_root,
			Vector3(x, 1.45, 0.0), "Post%d" % int(side))
		RocketMeshLib.mi(RocketMeshLib.cylinder(0.13, 0.16, 0.14, 8), wood_dark, _sign_root,
			Vector3(x, 0.07, 0.0), "PostFoot%d" % int(side))
		RocketMeshLib.mi(RocketMeshLib.sphere(0.085, 8, 4), wood_dark, _sign_root,
			Vector3(x, 2.92, 0.0), "PostCap%d" % int(side))
	# Cross beam the plate hangs from.
	var beam := RocketMeshLib.mi(RocketMeshLib.cylinder(0.05, 0.05, 2.76, 6), wood_dark, _sign_root,
		Vector3(0.0, 2.76, 0.0), "Beam")
	beam.rotation.z = deg_to_rad(90.0)

	var plate_root := Node3D.new()
	plate_root.name = "Plate"
	plate_root.position = Vector3(0.0, 2.36, 0.0)
	_sign_root.add_child(plate_root)
	var rim := RocketMeshLib.prism(RocketMeshLib.rounded_rect(1.24, 0.60, 0.16, 3), 0.040, 0.020)
	RocketMeshLib.mi(rim, RocketModel.deep_toon(SIGN_EDGE, {"shade": 0.46, "rim": 0.1, "spec": 0.0}, 0.40),
		plate_root, Vector3.ZERO, "Rim")
	_sign_mat = RocketModel.deep_toon(SIGN_CREAM, {"shade": 0.42, "rim": 0.10, "spec": 0.0,
		"emission": SIGN_CREAM, "emission_strength": 0.25}, 0.42)
	_sign_mat.set_shader_parameter("emission_day_scale", 1.0)
	_sign_mat.set_shader_parameter("emission_cap", 1.1)
	var plate := RocketMeshLib.prism(RocketMeshLib.rounded_rect(1.10, 0.48, 0.13, 3), 0.055, 0.026)
	RocketMeshLib.mi(plate, _sign_mat, plate_root, Vector3.ZERO, "Face")
	# Two hanger links up to the beam.
	for side: float in [-1.0, 1.0]:
		RocketMeshLib.mi(RocketMeshLib.cylinder(0.026, 0.026, 0.34, 5), wood_dark, plate_root,
			Vector3(0.48 * side, 0.42, 0.0), "Link%d" % int(side))
	# The word, on BOTH faces. AC signs are a clean word on a clean plate — the little orange
	# arrow that used to sit here landed on top of the "L" and read as a scratch; the direction cue
	# lives on the ground chevrons and the floating waypoint instead.
	for face in 2:
		var label := Label3D.new()
		label.name = "Text%d" % face
		label.text = "FLY"
		label.font = UIStyle.font()
		label.font_size = 110
		label.pixel_size = 0.0034
		label.modulate = SIGN_TEXT
		label.position = Vector3(0.0, 0.0, (-0.086 if face == 0 else 0.086))
		label.rotation.y = PI if face == 0 else 0.0
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		plate_root.add_child(label)


func _build_rocket() -> void:
	rocket = ROCKET_SCENE.instantiate() as RocketModel
	rocket.position = Vector3(0.0, DECK_Y, 0.0)
	var toward := _tangent_toward_spawn()
	rocket.rotation.y = atan2(-toward.x, -toward.z)
	_pad_root.add_child(rocket)
	_hatch_dir_local = toward
	# Where the descent has to end up, and what the legacy landing restores.
	_rest_xf = rocket.transform


func _build_hose() -> void:
	var post := _tangent_toward_spawn().rotated(Vector3.UP, deg_to_rad(62.0)) * POST_R
	var d := post.normalized()
	var a := post + Vector3(0.0, _deck_y(POST_R) + 0.32, 0.0)
	var b := d * 0.66 + Vector3(0.0, DECK_Y + 0.52, 0.0)
	var pts := RocketMeshLib.bezier_points(a, a - d * 0.55 + Vector3(0.0, -0.18, 0.0),
		b + d * 0.85 + Vector3(0.0, 0.34, 0.0), b, 12)
	RocketMeshLib.mi(RocketMeshLib.tube(pts, 0.062, 6),
		RocketModel.deep_toon(Color("#454f5c"), {"shade": 0.52, "spec": 0.16, "rim": 0.12}, 0.40),
		_pad_root, Vector3.ZERO, "FuelHose")
	var cuff := RocketMeshLib.mi(RocketMeshLib.cylinder(0.09, 0.09, 0.15, 10),
		MaterialLib.metal(Color("#b8983f")), _pad_root, b, "HoseCoupling")
	cuff.rotation.z = deg_to_rad(90.0)
	cuff.rotation.y = atan2(d.x, d.z)


func _build_dust() -> void:
	_dust = GPUParticles3D.new()
	_dust.name = "DustRing"
	_dust.amount = 56
	_dust.lifetime = 1.9
	_dust.one_shot = true
	_dust.explosiveness = 0.8
	_dust.local_coords = false
	_dust.emitting = false
	_dust.position = Vector3(0.0, DECK_Y + 0.05, 0.0)
	_dust.visibility_aabb = AABB(Vector3(-9.0, -3.0, -9.0), Vector3(18.0, 8.0, 18.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 1.35
	pm.emission_ring_inner_radius = 0.5
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0.0, 0.34, 0.0)
	pm.spread = 82.0
	pm.flatness = 0.82
	pm.initial_velocity_min = 3.4
	pm.initial_velocity_max = 6.4
	pm.gravity = Vector3.ZERO
	pm.damping_min = 1.6
	pm.damping_max = 2.8
	pm.scale_min = 0.9
	pm.scale_max = 1.7
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(0.4, 1.05))
	grow.add_point(Vector2(1.0, 1.35))
	var grow_t := CurveTexture.new()
	grow_t.curve = grow
	pm.scale_curve = grow_t
	# Warm mid-grey, fully opaque at the head. A near-white puff at 0.5 alpha simply did not exist
	# against the deck; this one has to be visibly darker than what it rolls across.
	var grad := Gradient.new()
	grad.set_color(0, Color(0.72, 0.66, 0.56, 0.0))
	grad.set_color(1, Color(0.50, 0.46, 0.42, 0.0))
	grad.add_point(0.07, Color(0.78, 0.72, 0.62, 1.0))
	grad.add_point(0.60, Color(0.60, 0.56, 0.50, 0.72))
	var grad_t := GradientTexture1D.new()
	grad_t.gradient = grad
	pm.color_ramp = grad_t
	_dust.process_material = pm
	var puff := QuadMesh.new()
	puff.size = Vector2(1.35, 1.35)
	puff.material = RocketModel.make_puff_material(Color("#a9997c"), Color("#5f5748"), 0.82, 0.95)
	_dust.draw_pass_1 = puff
	_pad_root.add_child(_dust)


## Bobbing waypoint marker floating over the rocket: a glowing ring with a down-arrow, the on-screen
## half of the "where is my rocket" answer. Fades in only when the player is far enough away that it
## is useful, so it never sits on top of the rocket you are standing next to.
func _build_marker() -> void:
	_marker = Node3D.new()
	_marker.name = "Waypoint"
	_marker.position = Vector3(0.0, DECK_Y + MARKER_Y, 0.0)
	_pad_root.add_child(_marker)
	_marker_mat = MaterialLib.glow(Color("#ffd447"), 2.6, Color("#e0a83a")).duplicate() as ShaderMaterial
	_marker_mat.set_shader_parameter("emission_day_scale", 1.0)
	_marker_mat.set_shader_parameter("emission_cap", 1.7)
	_marker_mat.set_shader_parameter("rim_strength", 0.22)
	# A faceted down-pointing gem rather than a flat arrow: it spins, and a flat arrow vanished
	# every time it turned edge-on to the camera. Bigger than it was, because the halo behind it
	# used to be the only thing you could see.
	var arrow := RocketMeshLib.lathe(PackedVector2Array([
		Vector2(0.0, -0.80), Vector2(0.26, -0.36), Vector2(0.44, -0.02),
		Vector2(0.34, 0.26), Vector2(0.0, 0.44)]), 6)
	var mi := RocketMeshLib.mi(arrow, _marker_mat, _marker, Vector3.ZERO, "Arrow")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A crisp amber band around the gem's widest point: a hard edge so the shape still reads when
	# the emissive core is blooming (STYLE_GUIDE: readable silhouette with structure, not a blob).
	var collar := RocketMeshLib.lathe(PackedVector2Array([
		Vector2(0.47, -0.09), Vector2(0.47, 0.03)]), 6)
	var band := RocketModel.deep_toon(Color("#c08a1f"), {"shade": 0.5, "rim": 0.16, "spec": 0.06}, 0.40)
	RocketMeshLib.mi(collar, band, _marker, Vector3.ZERO, "ArrowBand").cast_shadow = \
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# See the mast halo above for `softness`: at 0.72 this was a flat yellow disc with the gem
	# invisible inside it. A tight core and a long falloff makes it a glow AROUND a readable gem.
	var quad := QuadMesh.new()
	quad.size = Vector2(1.9, 1.9)
	quad.material = MaterialLib.glow_sprite(Color("#ffe27a"), 0.8, {"softness": 0.12, "core": 0.14, "points": 0.6})
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = quad
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker.add_child(halo)
	_marker.visible = false


func _build_interactable() -> void:
	_interactable = Interactable.new()
	_interactable.name = "Interactable"
	_interactable.prompt_text = "Fly"
	# Centred on the deck with a reach that covers the whole pad and a step beyond it: offset toward
	# the hatch with reach 3.0, the astronaut who had just been dropped 3.2 m off-centre by the
	# arrival spawn was standing *outside* its range with no prompt.
	_interactable.reach = 4.2
	_interactable.position = Vector3(0.0, DECK_Y + 0.8, 0.0)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.2
	shape.shape = sphere
	_interactable.add_child(shape)
	_pad_root.add_child(_interactable)
	_interactable.interacted.connect(_on_interacted)


## Stepping-stone + chevron trail from the spawn point to the pad, in the biome's own colours.
## Two MultiMeshes, so the whole trail is two draw calls. The ground shader only paints a sand path
## on the meadow and plaza biomes — this is what gives Zorp and Bolt a cue at all.
func _build_trail() -> void:
	if planet == null or planet.data == null:
		return
	var pad_dir := planet.data.pad_dir.normalized()
	var spawn_dir := planet.data.spawn_dir.normalized()
	var total := planet.surface_distance(pad_dir, spawn_dir)
	if total < 3.0:
		return
	var pair: Array = TRAIL_COLORS.get(_biome(), TRAIL_COLORS["meadow"])
	var root := Node3D.new()
	root.name = "Trail"
	add_child(root)

	var xforms: Array[Transform3D] = []
	var d := PAD_R + 0.9
	while d < total - 1.2 and xforms.size() < TRAIL_MAX:
		var dir := planet.step_dir(pad_dir, spawn_dir, d)
		var hint := planet.surface_point(pad_dir) - planet.surface_point(dir)
		var xf := planet.surface_transform(dir, hint)
		xf.origin += xf.basis.y * 0.015
		xforms.append(xf)
		d += TRAIL_STEP_M

	var stone_mm := MultiMesh.new()
	stone_mm.transform_format = MultiMesh.TRANSFORM_3D
	stone_mm.mesh = RocketMeshLib.cylinder(0.46, 0.50, 0.09, 12)
	stone_mm.instance_count = xforms.size()
	var chev_mm := MultiMesh.new()
	chev_mm.transform_format = MultiMesh.TRANSFORM_3D
	chev_mm.mesh = RocketMeshLib.prism(PackedVector2Array([
		Vector2(-0.24, 0.14), Vector2(0.00, 0.14), Vector2(0.00, 0.26), Vector2(0.30, 0.0),
		Vector2(0.00, -0.26), Vector2(0.00, -0.14), Vector2(-0.24, -0.14)]), 0.020, 0.008)
	chev_mm.instance_count = xforms.size()
	for i in xforms.size():
		var xf := xforms[i]
		var s := 1.0 - 0.035 * float(i)
		stone_mm.set_instance_transform(i, Transform3D(xf.basis.scaled(Vector3(s, 1.0, s)),
			xf.origin + xf.basis.y * 0.045))
		# The chevron lies flat on the stone pointing along -Z (the surface_transform forward, which
		# we aimed at the pad), so it is a literal "this way" arrow.
		# Local +X (the arrow tip) -> the pad direction (-Z of the surface transform), local +Z (the
		# extrusion) -> the surface normal, so the chevron lies flat and points home.
		var b := xf.basis
		var flat := Basis(-b.z, -b.x, b.y).scaled(Vector3.ONE * 0.92)
		chev_mm.set_instance_transform(i, Transform3D(flat, xf.origin + xf.basis.y * 0.10))

	var stones := MultiMeshInstance3D.new()
	stones.name = "Stones"
	stones.multimesh = stone_mm
	stones.material_override = RocketModel.deep_toon(pair[0] as Color,
		{"shade": 0.52, "rim": 0.08, "spec": 0.0}, 0.38)
	stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(stones)

	var chevs := MultiMeshInstance3D.new()
	chevs.name = "Chevrons"
	chevs.multimesh = chev_mm
	var cm := MaterialLib.glow(pair[1] as Color, 1.1, (pair[1] as Color).darkened(0.35)).duplicate() as ShaderMaterial
	cm.set_shader_parameter("emission_day_scale", 0.45)
	cm.set_shader_parameter("emission_cap", 2.0)
	chevs.material_override = cm
	chevs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(chevs)


func _build_compass() -> void:
	_compass = COMPASS_SCRIPT.new() as PadCompass
	_compass.name = "PadCompass"
	_compass.target = _pad_root.global_position + _pad_root.global_transform.basis.y * 1.6
	_compass.label_text = "Rocket"
	add_child(_compass)
	if _arriving():
		_compass.retire()
		_found = true


## Tangent direction (pad-local, XZ plane) pointing from the pad toward the planet's spawn point.
## The rocket's hatch, the sign and the boarding walk all face this way.
func _tangent_toward_spawn() -> Vector3:
	if planet == null or planet.data == null:
		return Vector3.FORWARD
	var pad_dir := planet.data.pad_dir.normalized()
	var spawn_dir := planet.data.spawn_dir.normalized()
	var t := spawn_dir - pad_dir * spawn_dir.dot(pad_dir)
	if t.length_squared() < 0.0001:
		return Vector3.FORWARD
	var local := _pad_root.global_transform.basis.inverse() * t.normalized()
	local.y = 0.0
	if local.length_squared() < 0.0001:
		return Vector3.FORWARD
	return local.normalized()


# ============================================================================= idle life
func _update_lights(delta: float) -> void:
	var step := fmod(_time / LIGHT_CYCLE, 1.0) * float(LIGHT_COUNT)
	for i in LIGHT_COUNT:
		var d := absf(step - float(i))
		d = minf(d, float(LIGHT_COUNT) - d)
		var on := clampf(1.0 - d, 0.0, 1.0)
		on = maxf(on * on, _flash)
		_light_mats[i].set_shader_parameter("emission_strength", 0.3 + 2.6 * on)
		_light_nodes[i].light_energy = 0.10 + 0.70 * on
	var mast := 0.5 + 0.5 * sin(_time * 3.1)
	mast = maxf(mast * mast, _flash)
	_light_mats[LIGHT_COUNT].set_shader_parameter("emission_strength", 0.55 + 3.4 * mast)
	_light_nodes[LIGHT_COUNT].light_energy = 0.2 + 1.2 * mast
	if _mast_halo != null:
		_mast_halo.scale = Vector3.ONE * (0.85 + 0.3 * mast)
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 1.6, 0.0)


func _update_sign() -> void:
	if _sign_root == null:
		return
	var p := _find_player()
	var near := 0.0
	if p != null and is_instance_valid(p) and p.visible:
		var d := p.global_position.distance_to(_sign_root.global_position)
		near = clampf(1.0 - (d - 2.0) / (PULSE_RANGE - 2.0), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_time * 3.4)
	_sign_root.scale = Vector3.ONE * (1.0 + 0.035 * near * pulse)
	_sign_mat.set_shader_parameter("emission_strength", 0.12 + 0.5 * near * pulse)
	_screen_mat.set_shader_parameter("emission_strength", 0.9 + 0.7 * pulse)


## Distance from the player to the pad centre (INF when there is no player yet).
func _player_distance() -> float:
	var p := _find_player()
	if p == null or not is_instance_valid(p) or not p.visible:
		return INF
	return p.global_position.distance_to(_pad_root.global_position)


func _update_marker(delta: float) -> void:
	if _marker == null:
		return
	var dist := _player_distance()
	if dist < FOUND_RANGE and not _found:
		_found = true
		if _compass != null:
			_compass.retire()
	var want := not _cutscene and dist > FOUND_RANGE and dist < INF
	_marker_alpha = move_toward(_marker_alpha, 1.0 if want else 0.0, delta * 2.2)
	_marker.visible = _marker_alpha > 0.01
	if _marker.visible:
		_marker.scale = Vector3.ONE * (_marker_alpha * (0.92 + 0.08 * sin(_time * 2.6)))
		_marker.position.y = DECK_Y + MARKER_Y + 0.22 * sin(_time * 1.8)
		_marker.rotation.y = _time * 0.9
		# Pulled down from 1.6-3.2: at that strength the gem clipped to a flat white blob and its
		# facets (and the whole point of using a solid, spinning shape) were lost.
		_marker_mat.set_shader_parameter("emission_strength",
			0.9 + 0.7 * _marker_alpha * (0.5 + 0.5 * sin(_time * 3.0)))


## Routed through HintChannel (src/onboarding/hint_channel.gd) rather than emitting a toast
## directly. The old version fired up to 3 times per planet visit, 20 s apart, with no check for
## an open dialogue - two separate critics caught it talking over Mayor Orbit's opening line on a
## brand new save, which is the first thing that happens in the game. The channel shows a hint
## once ever (persisted in GameState.flags), never during a dialogue, shop, bag, pause menu,
## cutscene or scene fade, and never two at once.
func _update_hint(_delta: float) -> void:
	if _cutscene or _busy or _found or _player_distance() < FOUND_RANGE:
		HintChannel.mark_acted("rocket_pad")
		return
	HintChannel.request("rocket_pad", "Follow the arrows to the rocket pad — press E to fly!",
		"star", HINT_DELAY)


# ============================================================================= cutscene gate
## Locks out every HUD hotkey (bag, decorate, pause) for the duration of a boarding / landing
## cutscene. Without this the player could open the bag mid-launch and the scene change would
## strand them in a menu-less space map with no way back but force-quit.
func _begin_cutscene() -> void:
	if _cutscene:
		return
	_cutscene = true
	EventBus.ui_modal_opened.emit("cutscene")


func _end_cutscene() -> void:
	if not _cutscene:
		return
	_cutscene = false
	EventBus.ui_modal_closed.emit("cutscene")


# ============================================================================= boarding
func _on_interacted(who: Node3D) -> void:
	if _busy or SceneRouter.is_busy() or RocketJourney.switching:
		return
	var p := who as Player
	if p == null:
		p = _find_player()
	if p == null:
		return
	_busy = true
	_open_picker(p)


## "Where to?" — the destination card, on the pad, before anything moves. The cutscene modal goes
## up with it so no hotkey can open a menu on top of it; cancelling takes the modal back down and
## re-arms the Interactable, so there is no way to be left standing on a pad you cannot use.
func _open_picker(p: Player) -> void:
	_begin_cutscene()
	_interactable.enabled = false
	EventBus.interact_prompt_changed.emit("")
	_picker = PICKER_SCRIPT.new() as PadDestinationPicker
	_picker.name = "DestinationPicker"
	_picker.setup(planet_id())
	add_child(_picker)
	_picker.chosen.connect(_on_destination_chosen.bind(p))
	_picker.cancelled.connect(_on_picker_cancelled)


func _on_picker_cancelled() -> void:
	_picker = null
	_interactable.enabled = true
	_busy = false
	_end_cutscene()


## Starts the journey straight away, skipping the destination card. Used by the climb-tuning
## showcase (`--launch=zorp`) and by test timelines that want a repeatable launch.
func launch_to(dest_id: String, who: Player = null) -> void:
	if _busy or RocketJourney.switching:
		return
	var p := who if who != null else _find_player()
	if p == null:
		return
	_busy = true
	_dest_id = dest_id
	_begin_cutscene()
	_launch(p)


func _on_destination_chosen(dest_id: String, p: Player) -> void:
	_picker = null
	_dest_id = dest_id
	if not is_instance_valid(p):
		p = _find_player()
	if p == null:
		_on_picker_cancelled()
		return
	_launch(p)


func _launch(p: Player) -> void:
	_begin_cutscene()
	# The destination is known ~16 s before we land on it and the flight is dead time for the loader,
	# so ask for everything the arrival is about to need NOW, on Godot's loader threads. See
	# `RocketJourney.prewarm_destination` for the measurements this is answering.
	RocketJourney.prewarm_destination(_dest_id)   # clears any stale requests first
	RocketJourney.prewarm_scene(SPACE_SCENE)
	_interactable.enabled = false
	if _compass != null:
		_compass.retire()
	EventBus.interact_prompt_changed.emit("")
	_freeze_player(p)

	# 1. walk to the hatch along the curved surface
	var stand := rocket.global_position + rocket.global_transform.basis.z * -HATCH_STAND_OFF
	await _walk_player_to(p, planet.dir_of(stand), WALK_SECONDS)

	# 2. door open, hop in, door shut
	rocket.open_hatch()
	AudioManager.play_sfx_at("door_open", rocket.global_position, -3.0)
	await get_tree().create_timer(0.45).timeout
	await _hop_into_hatch(p)
	rocket.close_hatch()
	# Stow the boarding ladder with the door. It used to fly the whole cruise hanging off the hull
	# with the exhaust licking it (integration critic, capB/b15_cut_d.png).
	rocket.set_ladder_deployed(false)
	AudioManager.play_sfx_at("door_close", rocket.global_position, -3.0)
	# Pull the camera back to a launch framing while the engine spools up.
	_carry_player = true
	_set_rocket_height(DECK_Y)
	await get_tree().create_timer(0.4).timeout

	# 3. ignition: flame grows, dust ring, decaying camera shake
	AudioManager.play_sfx_at("rocket_ignite", rocket.engine_point(), 1.0)
	AudioManager.start_loop("rocket_loop", -8.0, 0.5)
	rocket.set_engine(true, 1.0)
	rocket.set_flame_scale(0.05)
	_flash = 1.0
	_dust.restart()
	_dust.emitting = true
	var grow := create_tween().set_parallel(true)
	grow.tween_method(rocket.set_flame_scale, 0.05, 1.6, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Ease the rocket off the deck as the engine builds: on the pad the jet fires straight into the
	# deck, so without this lift the flame is hidden and the ignition reads as nothing happening.
	grow.tween_method(_set_rocket_height, DECK_Y, DECK_Y + IGNITION_LIFT, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_shake_camera(0.075, 1.7)
	await get_tree().create_timer(0.85).timeout

	# 4. THE CLIMB. One continuous move: the flight camera takes the frame, the sky darkens to
	#    space, the planet shrinks away below and the rocket leans over toward the destination.
	await _climb()


# ============================================================================= the climb
## Flies the rocket from the pad out to the seam altitude, ramping the sky into space as it goes,
## then writes the frame into RocketJourney and installs the space scene mid-air.
func _climb() -> void:
	var env := _find_environment()
	var up := _pad_up()
	_flight_up = up
	var start := rocket.global_position
	var seam_dist := RocketJourney.seam_distance(planet.radius)
	var dest := _destination_sky_dir(env, up)
	# End the climb leaning toward the destination world, so the last thing the camera looks at
	# before the cut is the place we are going.
	var end_dir := (up + dest * CLIMB_LEAN).normalized()
	var finish := end_dir * seam_dist
	_arc = PackedVector3Array([
		start,
		start + up * (seam_dist * 0.40),
		finish - dest * (seam_dist * 0.32),
		finish,
	])
	# The arc is flown in the plane spanned by the local up and the destination, so its normal is a
	# stable flank for the camera to ride all the way up.
	_cam_flank = up.cross(dest)
	if _cam_flank.length_squared() < 0.0005:
		_cam_flank = up.cross(Vector3.RIGHT)
	_cam_flank = _cam_flank.normalized()
	# Ride the side the sun is on, so the camera looks AWAY from the star for the whole climb and
	# the seam frame has no sun disc in it to mismatch across the cut.
	_cam_side = _sun_side(env)
	_take_camera()
	# The astronaut is parked (invisible) on the pad for the whole climb. The environment reads the
	# player for its local frame, so dragging them along the arc would swing the sky - and with it
	# the neighbouring worlds we are aiming at - as the rocket leaned over.
	_park_player()

	var t := create_tween()
	t.tween_method(_climb_step.bind(env), 0.0, 1.0, CLIMB_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	if not is_inside_tree():
		return
	_climb_step(1.0, env)
	_depart(env)


func _climb_step(k: float, env: Node) -> void:
	if rocket == null or not is_instance_valid(rocket):
		return
	var pos := _arc_point(k)
	var fwd := _arc_tangent(k)
	rocket.global_transform = Transform3D(_nose_basis(fwd, pos), pos)
	if env != null:
		env.call("set_space_blend", smoothstep(SPACE_BLEND_IN.x, SPACE_BLEND_IN.y, k))
	# The plume grows as the engine opens up, then eases back for the cruise the space scene picks up.
	rocket.set_flame_scale(lerpf(1.6, 1.15, smoothstep(0.0, 0.7, k)))
	_rocket_space_look(smoothstep(SPACE_LOOK_IN.x, SPACE_LOOK_IN.y, k))
	var s := smoothstep(CLIMB_CAM_HOLD, CLIMB_CAM_SETTLE, k)
	var alt := maxf(pos.length() - planet.radius, 0.0)
	# Off the pad the radial IS the flight axis, and the launch framing (camera above, looking back
	# down past the rocket at the shrinking world) depends on that. By the top of the climb the arc
	# has leaned CLIMB_LEAN toward the destination and the raw radial would collapse the chase rig,
	# so the reference is squared up against the flight axis over the same `s` that swings the
	# camera round behind. `_depart` records THIS vector, so the space scene inherits the same rig.
	_seam_up = RocketJourney.square_up(pos.normalized(), fwd, s)
	var frame := _chase_frame(pos, fwd, _seam_up,
		lerpf(LAUNCH_CAM_BACK, RocketJourney.CHASE_BACK, s),
		lerpf(LAUNCH_CAM_UP, RocketJourney.CHASE_UP, s),
		lerpf(LAUNCH_CAM_SIDE, RocketJourney.CHASE_SIDE, s),
		lerpf(LAUNCH_CAM_LEAD, RocketJourney.CHASE_LEAD, s),
		(1.0 - s) * minf(alt * LAUNCH_LOOK_DOWN, LAUNCH_LOOK_DOWN_MAX))
	_place_camera(frame, smoothstep(0.0, CLIMB_CAM_BLEND / maxf(CLIMB_SECONDS, 0.01), k))
	# `_place_camera` BLENDS out of the gameplay rig's framing, and a blend between two frames that
	# both hold the rocket does not have to hold it itself. Re-apply the clamp to the result, so the
	# rule is true on every frame of the climb and not just on the ones the chase rule authored.
	_hold_rocket_in_frame(pos)


## Hands the frame to the space scene. Everything the seam frame contains is written down in the
## camera's own coordinates (see journey_state.gd) and the scene is swapped with NO fade — the two
## scenes render the same picture, so there is nothing to cover up.
func _depart(env: Node) -> void:
	var cam_xf := _cam.global_transform
	RocketJourney.leg = "depart"
	RocketJourney.from_id = planet_id()
	RocketJourney.to_id = _dest_id
	RocketJourney.cam_basis = cam_xf.basis.orthonormalized()
	RocketJourney.write_rocket(cam_xf, rocket.global_transform, 1.0)
	RocketJourney.write_frame(cam_xf, _seam_up, _cam_flank * _cam_side)
	RocketJourney.flame_scale = 1.15
	RocketJourney.engine_power = 1.0
	var inv := cam_xf.basis.orthonormalized().inverse()
	# The planet we are leaving, so the space scene can put its globe on the same pixels.
	RocketJourney.focus_dir = (inv * (-cam_xf.origin).normalized()).normalized()
	RocketJourney.focus_angle = RocketJourney.angular_radius(planet.radius, cam_xf.origin.length())
	RocketJourney.bodies = _capture_sky_bodies(env, cam_xf)
	# The world we are LEAVING is not one of the sky bodies (you cannot see it in your own sky), so
	# without this its globe would be the one thing in the seam frame that did not land on the same
	# pixels. `_seed_globe_entry` treats it like any other neighbour and eases it onto its orbit.
	RocketJourney.bodies.append({
		"id": RocketJourney.from_id,
		"dir": RocketJourney.focus_dir,
		"angle": RocketJourney.focus_angle,
	})
	RocketJourney.capture_sky(cam_xf, get_viewport().get_world_3d())
	RocketJourney.switching = true

	GameState.previous_planet_id = RocketJourney.from_id
	EventBus.planet_leave_requested.emit(RocketJourney.from_id)
	EventBus.travel_started.emit(RocketJourney.from_id, RocketJourney.to_id)
	# The engine loop lives on the AudioManager autoload, so leaving it running carries the sound
	# across the cut as well as the picture. The space scene re-fades the same player.
	_end_cutscene()
	RocketJourney.swap_scene(get_tree(), SPACE_SCENE)


## Direction and apparent size of every neighbouring world on the seam frame, in camera-local
## coordinates. The space scene starts its globes here and eases them onto their real orbits.
func _capture_sky_bodies(env: Node, cam_xf: Transform3D) -> Array:
	var out: Array = []
	if env == null:
		return out
	var sky_bodies := env.get_node_or_null("SkyBodies") as SkyBodies
	if sky_bodies == null:
		return out
	var inv := cam_xf.basis.orthonormalized().inverse()
	for id in sky_bodies.visible_ids():
		var node := sky_bodies.get_node_or_null("Sky_" + id) as Node3D
		if node == null:
			continue
		var d := node.global_position - cam_xf.origin
		if d.length_squared() < 0.01:
			continue
		var entry := {
			"id": id,
			"dir": (inv * d.normalized()).normalized(),
			"angle": sky_bodies.angular_radius_of(id),
		}
		# Bolt's band reaches 3 planet radii and is the loudest thing on the seam frame after the
		# rocket itself. The sky hangs it at its own tilt; record that so the map globe can wear the
		# same one on the cut and roll back to the map's over the settle.
		var ring := node.get_node_or_null("Ring") as Node3D
		if ring != null:
			entry["ring_normal"] = (inv * ring.global_basis.y.normalized()).normalized()
		out.append(entry)
	return out


## Unit direction (world) from the pad toward the destination world hanging in the sky. Read off
## the live SkyBodies node so we fly at the object the player can actually see; if the environment
## has none (showcases without .tres files) we lean toward the horizon on the spawn side instead.
## ENVIRONMENT BUILDER: a public `get_sky_body_direction(id) -> Vector3` would let this stop
## reaching for the node by name.
func _destination_sky_dir(env: Node, up: Vector3) -> Vector3:
	if env != null and _dest_id != "":
		var sky_bodies := env.get_node_or_null("SkyBodies") as SkyBodies
		if sky_bodies != null:
			var node := sky_bodies.get_node_or_null("Sky_" + _dest_id) as Node3D
			if node != null:
				var cam := _rig_camera()
				var eye := cam.global_position if cam != null else rocket.global_position
				var d := node.global_position - eye
				if d.length_squared() > 0.01:
					return d.normalized()
	var fallback := _pad_root.global_transform.basis * _tangent_toward_spawn()
	fallback = fallback - up * fallback.dot(up)
	if fallback.length_squared() < 0.0001:
		fallback = up.cross(Vector3.RIGHT)
	return (fallback.normalized() * 0.94 - up * 0.34).normalized()


# ============================================================================= flight camera
## Creates the flight camera and seeds it with the gameplay camera's exact transform, so taking
## over the frame is invisible: frame N and frame N+1 are identical.
func _take_camera() -> void:
	if _cam != null and is_instance_valid(_cam):
		return
	_rig_cam = _rig_camera()
	_cam = Camera3D.new()
	_cam.name = "FlightCamera"
	_cam.fov = RocketJourney.FLIGHT_FOV
	_cam.near = 0.08
	# The seam is 250-580 m out depending on the planet, so the far plane has to clear it with room
	# for the sky bodies parked beyond.
	_cam.far = 4000.0
	# Its own attributes, with depth of field off: the environment's rig would defocus a planet
	# that is suddenly hundreds of metres away, and stars must stay pinpoints.
	var attr := CameraAttributesPractical.new()
	attr.auto_exposure_enabled = false
	attr.dof_blur_far_enabled = false
	attr.dof_blur_near_enabled = false
	_cam.attributes = attr
	add_child(_cam)
	if _rig_cam != null and is_instance_valid(_rig_cam):
		_cam.global_transform = _rig_cam.global_transform
		_cam.fov = _rig_cam.fov
	_cam.current = true


## Eases the flight camera's FOV onto the flight FOV while `w` runs 0 -> 1, and blends its
## transform from wherever it was seeded into `frame`.
func _place_camera(frame: Transform3D, w: float) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	var k := clampf(w, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	if k >= 0.999:
		_cam.global_transform = frame
		_cam.fov = RocketJourney.FLIGHT_FOV
		return
	var from := _cam.global_transform
	var q := from.basis.get_rotation_quaternion().slerp(frame.basis.get_rotation_quaternion(), k)
	_cam.global_transform = Transform3D(Basis(q), from.origin.lerp(frame.origin, k))
	_cam.fov = lerpf(_cam.fov, RocketJourney.FLIGHT_FOV, k)


## Re-aims the flight camera, wherever it currently is, so the rocket stays inside the frame.
func _hold_rocket_in_frame(target: Vector3) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	var xf := _cam.global_transform
	_cam.global_transform = RocketJourney.flight_frame(xf.origin, xf.origin - xf.basis.z * 10.0,
		target, xf.basis.y)


## The canonical chase framing: `back` behind the nose, `up` along the local radial, `side` out on
## the flank the sun is on, looking `lead` ahead of the rocket. journey_state.gd stores the same
## offsets in model units, so the space scene's chase camera lands on exactly the same pixels.
func _chase_frame(pos: Vector3, fwd: Vector3, up_ref: Vector3, back: float, rise: float,
		side_off: float, lead: float, look_down: float = 0.0) -> Transform3D:
	var side := _cam_flank * _cam_side
	if _ref_blend < 1.0:
		# Still crossing over from the reference frame the far side of the cut was using.
		var w := _ref_blend * _ref_blend * (3.0 - 2.0 * _ref_blend)
		up_ref = _ref_up.slerp(up_ref, w).normalized()
		side = _ref_flank.slerp(side, w).normalized()
	var eye := pos - fwd * back + up_ref * rise + side * side_off
	# Never inside the planet: a camera that dips below the surface on the last seconds of a
	# descent frames a wall of dirt.
	var min_r := planet.radius + CAM_GROUND_CLEAR
	if eye.length() < min_r:
		eye = eye.normalized() * min_r
	var look := pos + fwd * lead - up_ref * look_down
	# `flight_frame` is the shared aim rule: it clamps `look_down` (which reaches 120 m at a 12 m
	# camera distance) so the rocket can never be tipped out of the frame. The space scene applies
	# exactly the same clamp, so the seam matches whether it is engaged or not.
	return RocketJourney.flight_frame(eye, look, pos, up_ref)


## Blends the flight camera back into the gameplay rig and hands the frame over.
func _hand_camera_back() -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	var rig := _rig_camera()
	if rig == null:
		_drop_camera()
		return
	var t := create_tween()
	t.tween_method(func(k: float) -> void:
		if not is_instance_valid(_cam) or not is_instance_valid(rig):
			return
		var target := rig.global_transform
		var q := _cam.global_basis.get_rotation_quaternion().slerp(target.basis.get_rotation_quaternion(), k)
		_cam.global_transform = Transform3D(Basis(q), _cam.global_position.lerp(target.origin, k))
		_cam.fov = lerpf(_cam.fov, rig.fov, k),
		0.0, 1.0, HANDBACK_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	_drop_camera()


func _drop_camera() -> void:
	var rig := _rig_camera()
	if rig != null and is_instance_valid(rig):
		rig.current = true
	if _cam != null and is_instance_valid(_cam):
		_cam.current = false
		_cam.queue_free()
	_cam = null


func _rig_camera() -> Camera3D:
	var rig := get_node_or_null("/root/World/CameraRig")
	if rig == null:
		rig = get_tree().get_first_node_in_group("camera_rig")
	if rig != null and rig.has_method("get_camera"):
		return rig.get_camera() as Camera3D
	if _cam != null and is_instance_valid(_cam):
		return null
	return get_viewport().get_camera_3d()


# ============================================================================= flight geometry
func _arc_point(k: float) -> Vector3:
	return _arc[0].bezier_interpolate(_arc[1], _arc[2], _arc[3], clampf(k, 0.0, 1.0))


func _arc_tangent(k: float) -> Vector3:
	var a := _arc_point(clampf(k - 0.012, 0.0, 1.0))
	var b := _arc_point(clampf(k + 0.012, 0.0, 1.0))
	var d := b - a
	if d.length_squared() < 1e-8:
		return _flight_up
	return d.normalized()


## Basis for the rocket model, whose nose points along its local +Y. `up_hint` only fixes the roll.
func _nose_basis(fwd: Vector3, up_hint: Vector3) -> Basis:
	var nose := fwd.normalized()
	var ref := up_hint.normalized() if up_hint.length_squared() > 0.01 else Vector3.UP
	var right := nose.cross(ref)
	if right.length_squared() < 0.0005:
		right = nose.cross(Vector3.RIGHT)
	right = right.normalized()
	return Basis(right, nose, right.cross(nose).normalized())


func _pad_up() -> Vector3:
	if planet != null and planet.data != null:
		return planet.data.pad_dir.normalized()
	return _pad_root.global_transform.basis.y.normalized()


## +1 / -1: which way along `_cam_flank` to sit so the camera looks away from the sun. An eye
## offset TOWARDS the star is an eye looking AWAY from it.
func _sun_side(env: Node) -> float:
	var sun := Vector3.UP
	if env != null and env.has_method("get_sun_direction"):
		sun = env.call("get_sun_direction") as Vector3
	return 1.0 if _cam_flank.dot(sun) >= 0.0 else -1.0


## The environment node, by its documented path, then by duck-typing. Read-only to the rocket: the
## only thing asked of it is the public set_space_blend / get_sun_direction / get_sky_body_ids API.
func _find_environment() -> Node:
	if _env_looked_up:
		return _env
	_env_looked_up = true
	var n := get_node_or_null("/root/World/Environment")
	if n == null:
		for c in get_tree().root.get_children():
			n = c.get_node_or_null("Environment")
			if n != null:
				break
	_env = n if n != null and n.has_method("set_space_blend") else null
	return _env


## Parks the (hidden) astronaut on the pad for the flight. The environment derives its local frame
## from the player, so this keeps the sky - and the neighbouring worlds we are flying at - still.
## Crossfades the rocket between its planet look (0) and its space look (1).
func _rocket_space_look(t: float) -> void:
	if rocket == null or not is_instance_valid(rocket):
		return
	var k := clampf(t, 0.0, 1.0)
	rocket.set_flame_intensity(lerpf(GROUND_FLAME_INTENSITY, SPACE_FLAME_INTENSITY, k))
	rocket.set_light_range_scale(lerpf(1.0, SPACE_LIGHT_RANGE, k))
	var want := k > 0.5
	if want != _space_look:
		_space_look = want
		rocket.set_local_lights_enabled(not want)
		rocket.set_smoke_enabled(not want)


func _park_player() -> void:
	_carry_player = false
	if _walk_player == null or not is_instance_valid(_walk_player):
		return
	_walk_player.global_position = _pad_root.global_position + _pad_up() * 1.0
	_walk_player.visible = false


func _set_rocket_height(y: float) -> void:
	rocket.position.y = y
	if _carry_player and _walk_player != null and is_instance_valid(_walk_player):
		# The camera rig follows the player, so riding the (hidden) player up with the rocket turns
		# the liftoff into a tracking shot instead of leaving the camera on an empty pad. The anchor
		# sits LIFTOFF_CAM_OFFSET in front of the rocket so the camera ends up far enough back to
		# hold the whole 3.2 m rocket in frame.
		_walk_player.global_position = _pad_root.to_global(
			_hatch_dir_local * LIFTOFF_CAM_OFFSET + Vector3(0.0, y + 1.0, 0.0))


func _freeze_player(p: Player) -> void:
	_walk_player = p
	p.input_enabled = false
	p.set_physics_process(false)
	p.set_process(false)
	p.velocity = Vector3.ZERO
	_anim_speed = 0.0


func _thaw_player(p: Player) -> void:
	_walk_player = null
	_carry_player = false
	p.set_physics_process(true)
	p.set_process(true)
	p.input_enabled = true


func _walk_player_to(p: Player, target_dir: Vector3, duration: float) -> void:
	_walk_from = planet.dir_of(p.global_position)
	_walk_to = target_dir.normalized()
	p.get_model().set_state("walk")
	_anim_speed = 1.0
	var t := create_tween()
	t.tween_method(_walk_step, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	_anim_speed = 0.0
	p.get_model().set_state("idle")


func _walk_step(k: float) -> void:
	if _walk_player == null or not is_instance_valid(_walk_player):
		return
	var d := _walk_from.slerp(_walk_to, k).normalized()
	var ahead := _walk_from.slerp(_walk_to, minf(k + 0.06, 1.0)).normalized()
	var hint := ahead - d * ahead.dot(d)
	if hint.length_squared() < 1e-8:
		hint = -_walk_player.global_transform.basis.z
	var xf := planet.surface_transform(d, hint.normalized())
	xf.origin += xf.basis.y * 0.02
	_walk_player.global_transform = xf


func _hop_into_hatch(p: Player) -> void:
	var model := p.get_model()
	model.set_state("jump")
	_hop_from = p.global_position
	_hop_to = rocket.hatch_point()
	_hop_up = planet.up_at(_hop_from)
	_hop_arc = 0.35
	var t := create_tween().set_parallel(true)
	t.tween_method(_hop_step, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	t.tween_property(model, "scale", Vector3.ONE * 0.02, 0.46).set_delay(0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await t.finished
	p.visible = false
	model.scale = Vector3.ONE
	model.set_state("idle")


func _hop_step(k: float) -> void:
	if _walk_player == null or not is_instance_valid(_walk_player):
		return
	_walk_player.global_position = _hop_from.lerp(_hop_to, k) + _hop_up * sin(k * PI) * _hop_arc


# ============================================================================= journey arrival
## The second half of the continuous journey. Runs inside _ready, before the first frame is drawn:
## the flight camera is put back exactly where the space scene's camera was, and the rocket exactly
## where the space scene's rocket was (both read out of RocketJourney in camera-local coordinates),
## with the sky already at full space blend. The frame the space scene last rendered and the frame
## this scene renders first are the same picture.
func _prepare_journey_arrival() -> void:
	_busy = true
	_journey_arrival = true
	_begin_cutscene()
	GameState.set_flag("rocket_arriving", true)
	_arrival_watchdog = DESCENT_SECONDS + 10.0
	_interactable.enabled = false
	var p := _find_player()
	if p != null:
		# Where the astronaut will step out: world.gd already spawned them a few metres off the pad
		# centre, which is exactly where we want them, so remember it before anything else moves.
		_landed_dir = planet.dir_of(p.global_position)
		_freeze_player(p)
		p.global_transform = planet.surface_transform(_landed_dir,
			_pad_root.global_position - p.global_position)
		p.visible = false
	var env := _find_environment()
	if env != null:
		env.call("set_space_blend", 1.0)
		# The environment was added to the tree a moment ago and has not had an idle frame yet, so
		# its sky is still painted for the ground: the very frame the cut lands on would show the
		# limb haze and a warm gradient where there should be deep space. `refresh()` re-derives the
		# limb from THIS camera and re-applies the sky immediately. (It was added for exactly this
		# by the orchestrator - docs/OPEN_ISSUES.md #16 - replacing a `_process(0.0)` poke.)
		if env.has_method("refresh"):
			env.call("refresh")
		elif env.has_method("_process"):
			env.call("_process", 0.0)
	_flight_up = _pad_up()

	_take_camera()
	var basis := RocketJourney.cam_basis.orthonormalized()
	var eye := RocketJourney.focus_camera_position(Vector3.ZERO, planet.radius, basis)
	_cam.global_transform = Transform3D(basis, eye)
	_cam.fov = RocketJourney.FLIGHT_FOV
	rocket.global_transform = RocketJourney.read_rocket(_cam.global_transform, 1.0)
	_seam_nose = rocket.global_basis.y.normalized()
	_space_look = false
	_rocket_space_look(1.0)
	rocket.set_engine(true, RocketJourney.engine_power)
	rocket.set_flame_scale(RocketJourney.flame_scale)
	rocket.set_ladder_deployed(false)
	_carry_player = false
	_build_descent_arc()
	RocketJourney.clear()


## Waits out the scene-swap stall before letting the descent start moving.
##
## MEASURED: the frame that installs the destination scene costs 400-850 ms (world.gd's `_ready`),
## and the two frames after it cost 125 ms and 41 ms while the destination biome's materials compile
## their pipelines on first draw. The seam frame is a HELD picture - the space scene handed it over
## exactly - so paying those three frames while nothing is moving is invisible, whereas paying them
## over the first 0.2 s of the descent is the stutter the player reported. Capped, so a genuinely
## slow machine still flies rather than hanging on the pad forever.
const SEAM_STEADY_MS := 26.0
const SEAM_STEADY_FRAMES := 8

func _await_steady_frame() -> void:
	for i in SEAM_STEADY_FRAMES:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if get_process_delta_time() * 1000.0 <= SEAM_STEADY_MS:
			return


func _build_descent_arc() -> void:
	var a := rocket.global_position
	var b := _pad_root.global_transform * _rest_xf.origin
	_desc_dir_a = a.normalized()
	_desc_dir_b = b.normalized()
	_desc_r_a = a.length()
	_desc_r_b = b.length()
	# A bezier, not a plain slerp: it has to LEAVE along the heading the cruise handed over (or the
	# rocket's nose - and with it the whole chase framing - snaps through a right angle on the first
	# frame after the cut) and ARRIVE straight down onto the pad.
	var span := a.distance_to(b)
	# Leave along the heading the cruise handed over, leaned toward the pad so the arc always makes
	# progress even when the two differ.
	var out := (_seam_nose * 0.6 + (b - a).normalized() * 0.4).normalized()
	_desc_p1 = a + out * (span * 0.34)
	_desc_p2 = b + _desc_dir_b * (span * 0.32)
	# Bow the track toward the sun while it is up, so the hero beat - the first third, where the
	# planet fills the frame - is framed on a LIT face (QUALITY_BAR: the arrival is the hero shot).
	var env := _find_environment()
	_sun_bow = 0.0
	if env != null and env.has_method("get_sun_direction") and env.has_method("get_night_factor"):
		_sun_dir = (env.call("get_sun_direction") as Vector3).normalized()
		_sun_bow = deg_to_rad(SUN_BOW_DEG) * (1.0 - float(env.call("get_night_factor")))
	# The descent is flown in the plane through the seam point and the pad, so its normal is the
	# stable flank; the sign continues whichever side the seam camera is already on.
	_cam_flank = _desc_dir_a.cross(_desc_dir_b)
	if _cam_flank.length_squared() < 0.0005:
		_cam_flank = _desc_dir_a.cross(Vector3.RIGHT)
	_cam_flank = _cam_flank.normalized()
	_cam_side = signf((_cam.global_position - a).dot(_cam_flank))
	if _cam_side == 0.0:
		_cam_side = 1.0
	# The space scene's chase rule leaned on ITS up and flank; ours lean on the planet's radial and
	# the descent plane. Start from the ones it used and ease across, so the camera rule is
	# continuous rather than snapping to a new convention on the first frame after the cut.
	_ref_up = _cam.global_basis * RocketJourney.up_ref
	_ref_flank = _cam.global_basis * RocketJourney.flank
	_ref_blend = 0.0
	# The seam camera's roll comes from the space scene's map frame, not from this planet's radial,
	# so it will not be exactly what _chase_frame would build. Remember the difference and fade it
	# out over the first second: the seam frame is exact, and the drift is invisible.
	var frame := _descent_frame(0.0)
	_seam_err_pos = frame.basis.inverse() * (_cam.global_position - frame.origin)
	_seam_err_rot = frame.basis.orthonormalized().inverse() * _cam.global_basis.orthonormalized()
	_seam_err = 1.0


func _play_journey_arrival() -> void:
	var p := _find_player()
	if p == null:
		_finish_arrival(null)
		return
	AudioManager.start_loop("rocket_loop", -7.0, 0.3)
	# One clear frame first: the seam frame has to be drawn exactly as the space scene handed it
	# over, before anything starts moving - and then as many more as it takes for the frame clock to
	# come back to normal. See `_await_steady_frame`.
	await _await_steady_frame()
	if not is_inside_tree():
		return
	var t := create_tween()
	t.tween_method(_descent_step, 0.0, 1.0, DESCENT_SECONDS).set_trans(Tween.TRANS_SINE)
	await t.finished
	if not is_inside_tree():
		return
	_descent_step(1.0)

	AudioManager.play_sfx_at("rocket_land", rocket.global_position, 0.0)
	AudioManager.stop_loop("rocket_loop", 0.35)
	_dust.restart()
	_dust.emitting = true
	_flash = 1.0
	_shake_camera(0.05, 0.9)
	GameState.set_flag("rocket_arriving", false)
	var settle := create_tween()
	settle.tween_method(rocket.set_flame_scale, RocketJourney.flame_scale, 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	await settle.finished
	if not is_inside_tree():
		return
	rocket.set_engine(false)

	rocket.set_ladder_deployed(true)
	rocket.open_hatch()
	AudioManager.play_sfx_at("door_open", rocket.global_position, -3.0)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	await _pop_out(p, _landed_dir)
	rocket.close_hatch()
	AudioManager.play_sfx_at("door_close", rocket.global_position, -4.0)
	await _hand_camera_back()
	_finish_arrival(p)
	# Restored now that docs/OPEN_ISSUES.md #7 is fixed: player.gd force-clears a stuck emote past
	# its deadline, so a "happy" hop can no longer jam every future interact. It goes AFTER the
	# thaw and a beat later, though: a frozen player never ticks its model, and a thawed one spends
	# its first frames resolving the landing it just registered, which would overwrite the emote
	# state and leave the watchdog to clean it up on every single landing.
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(p) and is_inside_tree():
		p.play_emote("happy")


## Position on the descent arc: the direction slerps from the seam over to the pad while the radius
## comes down on a softer curve, so the planet grows steadily under you and the last second flares
## rather than slamming in.
func _descent_pos(k: float) -> Vector3:
	var c := clampf(k, 0.0, 1.0)
	var pos := (_desc_dir_a * _desc_r_a).bezier_interpolate(_desc_p1, _desc_p2,
		_desc_dir_b * _desc_r_b, c)
	if _sun_bow > 0.0001:
		# Bow the ground track toward the sun at its widest point. Both ends are pinned (sin 0 and
		# sin PI are 0), so the rocket still starts on the seam point and still lands on the pad,
		# but the middle of the approach - the hero beat, where the world fills the frame - passes
		# over LIT ground.
		var r := pos.length()
		var dir := pos / maxf(r, 0.001)
		var t := _sun_dir - dir * _sun_dir.dot(dir)
		if t.length_squared() > 1e-6:
			var w := _sun_bow * sin(PI * c)
			pos = (dir * cos(w) + t.normalized() * sin(w)).normalized() * r
	# Never let the arc clip through the world on its way round.
	var floor_r := _desc_r_b + 1.2
	if pos.length() < floor_r:
		pos = pos.normalized() * floor_r
	return pos


func _descent_step(k: float) -> void:
	if rocket == null or not is_instance_valid(rocket):
		return
	var pos := _descent_pos(k)
	var fwd := (_descent_pos(minf(k + 0.01, 1.0)) - _descent_pos(maxf(k - 0.01, 0.0)))
	if fwd.length_squared() < 1e-8:
		fwd = -pos.normalized()
	fwd = fwd.normalized()
	# Swing the nose upright for the touchdown, then settle onto the pad's own rest transform.
	var flare := smoothstep(0.72, 0.99, k)
	var nose := fwd.slerp(pos.normalized(), flare).normalized()
	# Ease off the attitude the cruise handed over rather than snapping onto the descent's own
	# tangent and roll reference: at the seam the rocket must be exactly what it was a frame ago.
	var w := _ref_blend * _ref_blend * (3.0 - 2.0 * _ref_blend)
	if w < 1.0:
		nose = _seam_nose.slerp(nose, w).normalized()
	var basis := _nose_basis(nose, _ref_up.slerp(pos.normalized(), w).normalized() * pos.length())
	var rest := _pad_root.global_transform * _rest_xf
	var land := smoothstep(0.94, 1.0, k)
	if land > 0.0:
		basis = basis.slerp(rest.basis.orthonormalized(), land)
		pos = pos.lerp(rest.origin, land)
	rocket.global_transform = Transform3D(basis, pos)

	var env := _find_environment()
	if env != null:
		env.call("set_space_blend", 1.0 - smoothstep(SPACE_BLEND_OUT.x, SPACE_BLEND_OUT.y, k))
	rocket.set_flame_scale(lerpf(RocketJourney.flame_scale, 0.55, smoothstep(0.55, 1.0, k)))
	_rocket_space_look(1.0 - smoothstep(SPACE_LOOK_OUT.x, SPACE_LOOK_OUT.y, k))

	_ref_blend = smoothstep(0.0, RocketJourney.SETTLE_SECONDS / maxf(DESCENT_SECONDS, 0.01), k)
	var frame := _descent_frame(k)
	_seam_err = maxf(1.0 - smoothstep(0.0, 1.2 / maxf(DESCENT_SECONDS, 0.01), k), 0.0)
	if _cam != null and is_instance_valid(_cam):
		_cam.global_transform = _apply_seam_offset(frame, _seam_err)


func _descent_frame(k: float) -> Transform3D:
	var pos := _descent_pos(k)
	var fwd := (_descent_pos(minf(k + 0.01, 1.0)) - _descent_pos(maxf(k - 0.01, 0.0)))
	if fwd.length_squared() < 1e-8:
		fwd = -pos.normalized()
	fwd = fwd.normalized()
	var s := smoothstep(0.22, 0.96, k)
	var alt := maxf(pos.length() - planet.radius, 0.0)
	var hold := smoothstep(0.03, 0.24, k) * (1.0 - smoothstep(0.52, 0.90, k))
	return _chase_frame(pos, fwd, pos.normalized(),
		lerpf(RocketJourney.CHASE_BACK, LAND_CAM_BACK, s),
		lerpf(RocketJourney.CHASE_UP, LAND_CAM_UP, s),
		lerpf(RocketJourney.CHASE_SIDE, LAND_CAM_SIDE, s),
		lerpf(RocketJourney.CHASE_LEAD, -1.4, s),
		minf(alt * DESCENT_LOOK_DOWN, DESCENT_LOOK_DOWN_MAX) * hold)


## Re-applies the (decaying) difference between the seam camera and what the local chase rule would
## have produced, so the first frame after the cut is pixel-exact and the correction is gone by the
## time anyone could see it move.
func _apply_seam_offset(frame: Transform3D, decay: float) -> Transform3D:
	if decay <= 0.001:
		return frame
	var b := frame.basis.orthonormalized()
	var q := Quaternion.IDENTITY.slerp(_seam_err_rot.get_rotation_quaternion(), decay)
	return Transform3D(b * Basis(q), frame.origin + b * (_seam_err_pos * decay))


# ============================================================================= legacy arrival
## Runs inside _ready (BEFORE world.gd emits planet_loaded and before the HUD exists): hide the
## astronaut, aim them (and therefore the camera) at the pad and put the rocket up in the sky before
## the first frame is drawn.
##
## `GameState.flag("rocket_arriving")` is set here and cleared at touchdown. It is a hook for the UI
## builder: while it is true the arrival banner should park in a corner instead of centre-top.
func _prepare_arrival() -> void:
	var p := _find_player()
	if p == null:
		return
	_busy = true
	_begin_cutscene()
	GameState.set_flag("rocket_arriving", true)
	_arrival_watchdog = ARRIVAL_HOLD + DESCEND_SECONDS + 6.0
	_interactable.enabled = false
	_freeze_player(p)
	p.global_transform = planet.surface_transform(planet.dir_of(p.global_position),
		_pad_root.global_position - p.global_position)
	p.visible = false
	rocket.position.y = DECK_Y + DESCEND_HEIGHT + 16.0
	rocket.set_engine(true, 1.0)
	rocket.set_flame_scale(0.9)
	rocket.set_ladder_deployed(false)


func _play_arrival() -> void:
	var p := _find_player()
	if p == null:
		_finish_arrival(null)
		return
	var landed_dir := planet.dir_of(p.global_position)

	AudioManager.start_loop("rocket_loop", -8.0, 0.4)
	# Hold high (a distant speck) while the planet-name banner plays out, drifting down so it still
	# reads as an approach, then make the real descent once the banner has gone.
	var approach := create_tween()
	approach.tween_method(_set_rocket_height, DECK_Y + DESCEND_HEIGHT + 16.0, DECK_Y + DESCEND_HEIGHT,
		ARRIVAL_HOLD).set_trans(Tween.TRANS_SINE)
	await approach.finished
	if not is_inside_tree():
		return
	var drop := create_tween()
	drop.tween_method(_set_rocket_height, DECK_Y + DESCEND_HEIGHT, DECK_Y, DESCEND_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await drop.finished
	if not is_inside_tree():
		return

	AudioManager.play_sfx_at("rocket_land", rocket.global_position, 0.0)
	AudioManager.stop_loop("rocket_loop", 0.35)
	_dust.restart()
	_dust.emitting = true
	_flash = 1.0
	_shake_camera(0.05, 0.9)
	GameState.set_flag("rocket_arriving", false)
	var settle := create_tween()
	settle.tween_method(rocket.set_flame_scale, 0.9, 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	await settle.finished
	rocket.set_engine(false)

	rocket.set_ladder_deployed(true)
	rocket.open_hatch()
	AudioManager.play_sfx_at("door_open", rocket.global_position, -3.0)
	await get_tree().create_timer(0.5).timeout
	await _pop_out(p, landed_dir)
	rocket.close_hatch()
	AudioManager.play_sfx_at("door_close", rocket.global_position, -4.0)
	# NOTE: no `p.play_emote("happy")` here. Playing an emote in the same frame the thawed player
	# registers a landing leaves Player._emote stuck forever: the landing handler overwrites the
	# model state with "land", which is not in AstronautModel.EMOTE_DURATIONS, so `emote_finished`
	# never fires and `Player._physics_process` refuses every `interact` from then on — the player
	# could never board the rocket again. Measured: emote="happy" model state="land" for 7+ s.
	# PLAYER BUILDER: see the report; the fix belongs in player.gd/_select_state.
	_finish_arrival(p)


## The one place the arrival hands control back. Called on every exit path — success, no player, or
## the node leaving the tree mid-animation — so `_interactable.enabled` and `_busy` can never be
## left in a state where the pad is un-interactable and the player is stranded on the planet.
func _finish_arrival(p: Player) -> void:
	if p != null and is_instance_valid(p):
		_thaw_player(p)
		p.visible = true
	elif _walk_player != null and is_instance_valid(_walk_player):
		_thaw_player(_walk_player)
	if _interactable != null:
		_interactable.enabled = true
	_busy = false
	_carry_player = false
	_journey_arrival = false
	_arrival_watchdog = 0.0
	_drop_camera()
	_end_cutscene()
	GameState.set_flag("rocket_arriving", false)
	GameState.set_flag("spawn_at_pad", false)


func _pop_out(p: Player, landed_dir: Vector3) -> void:
	var model := p.get_model()
	_hop_from = rocket.hatch_point()
	_hop_to = planet.surface_point(landed_dir) + landed_dir * 0.02
	_hop_up = landed_dir
	_hop_arc = 0.45
	p.global_transform = planet.surface_transform(landed_dir, _hop_to - _pad_root.global_position)
	p.global_position = _hop_from
	model.scale = Vector3.ONE * 0.02
	p.visible = true
	var t := create_tween().set_parallel(true)
	t.tween_method(_hop_step, 0.0, 1.0, 0.65).set_trans(Tween.TRANS_SINE)
	t.tween_property(model, "scale", Vector3.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	p.global_transform = planet.surface_transform(landed_dir, _hop_to - _pad_root.global_position)


# ============================================================================= camera shake
## Decaying noise on the active camera's lens offsets, restored to zero at the end.
func _shake_camera(strength: float, duration: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var t := create_tween()
	t.tween_method(_shake_step.bind(cam, strength), 1.0, 0.0, duration)
	t.tween_callback(func() -> void:
		if is_instance_valid(cam):
			cam.h_offset = 0.0
			cam.v_offset = 0.0)


func _shake_step(k: float, cam: Camera3D, strength: float) -> void:
	if not is_instance_valid(cam):
		return
	var decay := k * k
	var s := _time
	cam.h_offset = strength * decay * (sin(s * 41.0) * 0.6 + sin(s * 73.3 + 1.7) * 0.4)
	cam.v_offset = strength * decay * (sin(s * 37.5 + 0.9) * 0.6 + sin(s * 89.1) * 0.4)
