class_name RocketJourney
extends RefCounted
## THE ONE CONTINUOUS ROCKET JOURNEY (docs/STYLE_GUIDE.md R2.5).
##
## Leaving a planet is no longer "climb -> fade to black -> a separate map screen". It is one move:
##
##   1. rocket_pad.gd    pick a destination on the pad, board, ignite, CLIMB. The camera goes with
##                       the rocket, `Environment.set_space_blend()` ramps 0 -> 1, so the home
##                       planet shrinks below and the sky darkens into space.
##   2. space_travel.gd  cruise across the system with the destination growing ahead, then the
##                       3 s hero orbit on its lit face, then a dive at the planet.
##   3. rocket_pad.gd    descend onto the growing destination with `set_space_blend()` back to 0,
##                       and land.
##
## Two `change_scene_to_file` calls still happen under the hood (1->2 and 2->3) because each planet
## is its own scene. THIS FILE IS WHAT MAKES THEM INVISIBLE. Godot cannot cross-fade two scenes, so
## instead both sides of each cut are made to render the SAME PICTURE on the seam frame:
##
##   * CAMERA-LOCAL BOOKKEEPING. Everything the sender can see is written down in the seam camera's
##     own frame - the direction and apparent size of the rocket, of the planet it is leaving or
##     approaching, and of every neighbouring world. The receiver rebuilds that arrangement in its
##     own coordinates, so all of it lands on the same pixels. Distances are stored divided by the
##     model scale, so the receiver may draw the rocket at any scale it likes and still match.
##   * THE SKY IS WORLD-ORIENTED, so it needs the camera's world BASIS to match, not just the
##     camera-local layout. `cam_basis` carries it. The space scene keeps its whole solar system
##     under one `SystemRoot` node and rotates that node so the seam camera ends up with exactly
##     this basis - the map geometry is untouched, the star field lines up. The star layers in
##     src/rocket/space_sky.gdshader are tuned to the same cell scales as src/shaders/sky.gdshader,
##     so the same view direction gives the same stars in both scenes.
##   * THE PAINTED SKY AND THE POST STACK. `sky` is a snapshot of every uniform the ground sky
##     shader was running at (gradient, milky way, sun, moons) and `env` is a copy of the planet's
##     whole Environment resource, colour-correction LUT included. The space scene starts from
##     them and eases into its own look over SETTLE_SECONDS, and eases back before the arrival cut.
##
## Everything here is static: the record has to outlive the scene that wrote it. `leg` is the only
## thing anyone tests, and each consumer clears it the moment it has read it, so a stale record can
## never put a normally-launched space map into journey mode.

## Angular RADIUS the planet being LEFT has when the departure cut happens (degrees). It sets how
## far the climb goes - home (R 16) has to reach 239 m for its limb to shrink this far - and by
## then the climb has also leaned over toward the destination, so the planet is behind the camera
## and out of frame. Nothing about it has to match on the far side; this is purely how small the
## world you are leaving gets before the sky takes over.
const CLIMB_SEAM_DEG := 3.6
## Angular RADIUS the DESTINATION has when the arrival cut happens. This one is in frame and has to
## match on both sides, so it is a compromise: big enough that the cruise reads as a real approach
## (2.3 deg -> 7 deg is a 3x growth), small enough that the real planet's trees are ~20 px specks on
## a 220 px ball and read as surface texture next to the map globe's painted land.
## The rest of the growth - 7 deg to standing on it - happens on the real planet.
const ARRIVE_SEAM_DEG := 7.0
## Every camera in the journey runs this FOV, on both sides of both cuts.
const FLIGHT_FOV := 46.0
## The scale space_travel.gd draws the rocket at. Kept here because the seam maths converts between
## the two scenes' rocket sizes.
const MAP_MODEL_SCALE := 0.46

## Chase-camera offsets in MODEL units (metres at model scale 1.0), so the rocket has the same
## on-screen size in both scenes: multiply by the local model scale to get scene units.
## These are space_travel.gd's CHASE_* divided by MAP_MODEL_SCALE - keep the two in step.
## A three-quarter REAR view: mostly behind, so the world you are flying at is in frame and
## visibly grows, but far enough off the axis that the camera is not looking up the exhaust.
const CHASE_BACK := 9.0
const CHASE_UP := 3.5
const CHASE_SIDE := 7.0
const CHASE_LEAD := 3.0

## How long the receiving scene takes to relax out of the matched seam arrangement into its own.
const SETTLE_SECONDS := 2.4
## Arrival approach: the descent starts this far round the sphere from the pad, toward the spawn
## point, so the landing is a sweeping arc over the ground you are about to walk on rather than a
## lift-shaft drop. Both scenes compute it from PlanetData alone, so they agree without talking.
const APPROACH_ARC_DEG := 34.0

# ----------------------------------------------------------------------------- the record
## "" (no journey) | "depart" (planet -> space) | "arrive" (space -> planet).
static var leg: String = ""
static var from_id: String = ""
static var to_id: String = ""

## World-space basis of the camera on the seam frame. The receiver reproduces it exactly.
static var cam_basis: Basis = Basis.IDENTITY
## Camera-local unit direction to the rocket, its distance divided by the sender's model scale, and
## its orthonormal camera-local basis.
static var rocket_dir: Vector3 = Vector3.FORWARD
static var rocket_dist_over_scale: float = 1.0
static var rocket_basis: Basis = Basis.IDENTITY
## Engine state, so the plume does not blink across the cut.
static var flame_scale: float = 1.0
static var engine_power: float = 1.0
## The two reference vectors the sender's chase rule was built on, in camera-local coordinates:
## `up_ref` is what "up" meant to it (the planet's radial, or the map's Y) and `flank` is the side
## the camera rides on. The receiver seeds its own chase rule with these and eases them onto its
## own over SETTLE_SECONDS, so the camera rule itself is continuous across the cut and there is no
## drift on the first frame - which is where an otherwise perfect seam falls apart.
static var up_ref: Vector3 = Vector3.UP
static var flank: Vector3 = Vector3.RIGHT

## Camera-local direction to the planet being left (depart) or approached (arrive) and its angular
## radius in radians.
static var focus_dir: Vector3 = Vector3.DOWN
static var focus_angle: float = 0.06

## Neighbouring worlds on the seam frame: [{"id": String, "dir": Vector3 (camera-local),
## "angle": float (angular radius, rad)}]. The space scene starts each globe at the position that
## reproduces this and eases it to its true orbit.
static var bodies: Array = []

## Snapshot of the ground sky shader's uniforms (see `capture_sky`).
static var sky: Dictionary = {}
## Copy of the planet scene's whole Environment (tonemap, glow, colour-correction LUT, adjustments).
static var env: Environment = null

## Set while a journey scene change is in flight, so `SceneRouter.is_busy()`-style guards elsewhere
## are not the only thing standing between the player and a double transition.
static var switching := false


## Wipes the record. Called by whoever consumes it and by any code path that abandons a journey.
static func clear() -> void:
	leg = ""
	from_id = ""
	to_id = ""
	bodies = []
	sky = {}
	env = null
	switching = false


## True when `expected` ("depart" / "arrive") is the pending leg.
static func pending(expected: String) -> bool:
	return leg == expected and from_id != "" and to_id != ""


# ----------------------------------------------------------------------------- geometry helpers
## Distance from a planet's CENTRE at which its limb subtends `CLIMB_SEAM_DEG` (where the climb ends).
static func seam_distance(planet_radius: float) -> float:
	return planet_radius / sin(deg_to_rad(CLIMB_SEAM_DEG))


## Distance from a planet's CENTRE at which its limb subtends `ARRIVE_SEAM_DEG` (where the cruise
## ends and the real planet takes over).
static func arrive_distance(planet_radius: float) -> float:
	return planet_radius / sin(deg_to_rad(ARRIVE_SEAM_DEG))


## Angular radius (radians) of a sphere of `radius` seen from `dist` away from its centre.
static func angular_radius(radius: float, dist: float) -> float:
	return asin(clampf(radius / maxf(dist, radius * 1.0001), 0.0, 1.0))


## Distance from the centre at which a sphere of `radius` subtends `angle`.
static func distance_for_angle(radius: float, angle: float) -> float:
	return radius / maxf(sin(clampf(angle, 0.0005, 1.5)), 0.0005)


## Unit direction (planet frame) the arrival descent starts above: APPROACH_ARC_DEG round the
## sphere from the pad, toward the spawn point. Deterministic from PlanetData, so the space scene
## and the planet scene pick the same one without sharing anything but the .tres.
static func approach_dir(pad_dir: Vector3, spawn_dir: Vector3) -> Vector3:
	var p := pad_dir.normalized()
	var s := spawn_dir.normalized()
	var t := s - p * s.dot(p)
	if t.length_squared() < 1e-6:
		t = Vector3.RIGHT - p * p.dot(Vector3.RIGHT)
	if t.length_squared() < 1e-6:
		t = Vector3.FORWARD - p * p.dot(Vector3.FORWARD)
	t = t.normalized()
	var a := deg_to_rad(APPROACH_ARC_DEG)
	return (p * cos(a) + t * sin(a)).normalized()


## Orthonormal basis with -Z along `fwd` and +Y as close to `up_ref` as possible. Used instead of
## `Basis.looking_at` in the seam code so the degenerate case is explicit rather than an error.
static func look_basis(fwd: Vector3, up_ref: Vector3) -> Basis:
	var z := -fwd.normalized()
	var u := up_ref
	if absf(u.normalized().dot(z)) > 0.999:
		u = z.cross(Vector3.RIGHT)
		if u.length_squared() < 1e-6:
			u = z.cross(Vector3.FORWARD)
	var x := u.cross(z)
	if x.length_squared() < 1e-8:
		x = Vector3.RIGHT
	x = x.normalized()
	return Basis(x, z.cross(x).normalized(), z)


## THE ROCKET IS NEVER ALLOWED OFF THE EDGE OF THE FRAME. Furthest the flight camera's view axis
## may sit off the rocket, in degrees. The rocket is 3.2 m long and the camera rides ~12 m off it,
## so it covers about 7.6 deg; 13 deg + 7.6 deg = 20.6 deg still clears the 23 deg half-FOV at
## FLIGHT_FOV, with room for the plume.
const KEEP_IN_FRAME_DEG := 13.0


## Builds the flight camera's transform and CLAMPS its aim so `target` (the rocket) cannot leave
## the frame — the one rule the whole journey depends on and the one the integration critic caught
## us breaking. The climb deliberately tips the camera down off the flight axis so the home planet
## sits in the middle of the frame and visibly shrinks (R2.5); that tip reached 84 deg at 12 m,
## which threw the rocket clean off the top, and a few seconds later the shrinking planet slid off
## the bottom too and left three frames of nothing but stars. Now the tip runs until the rocket is
## `KEEP_IN_FRAME_DEG` off the view axis and stops there, so the planet still ends up low and large
## in frame and the rocket still ends up high in it — but on screen.
##
## Both journey scenes call this on the same (scale-invariant) angles, so the seam frame is
## identical on either side of the cut whether the clamp is engaged or not.
static func flight_frame(eye: Vector3, look: Vector3, target: Vector3, up_ref: Vector3) -> Transform3D:
	var view := look - eye
	var to_target := target - eye
	if view.length_squared() < 1e-10 or to_target.length_squared() < 1e-10:
		return Transform3D(look_basis(view if view.length_squared() > 1e-10 else Vector3.FORWARD, up_ref), eye)
	var v := view.normalized()
	var d := to_target.normalized()
	var limit := deg_to_rad(KEEP_IN_FRAME_DEG)
	var ang := acos(clampf(v.dot(d), -1.0, 1.0))
	if ang > limit:
		var axis := v.cross(d)
		if axis.length_squared() > 1e-12:
			v = v.rotated(axis.normalized(), ang - limit).normalized()
	return Transform3D(look_basis(v, up_ref), eye)


## `up_ref` squared up against the flight axis, blended in by `w`. The climb ends leaning
## CLIMB_LEAN toward the destination, so the local radial finishes only ~30 deg off the flight
## axis; fed to the chase rig raw, `up_ref * CHASE_UP` becomes mostly *forward* travel, the rig
## collapses and the rocket lands 28 deg below the view axis. `w` lets a caller keep the raw
## reference where it is well behaved (straight up off the pad, straight down onto it, where the
## radial IS the flight axis and squaring it up is undefined) and adopt the squared one where the
## canonical chase framing has to hold its shape.
static func square_up(up_ref: Vector3, fwd: Vector3, w: float) -> Vector3:
	if w <= 0.0:
		return up_ref.normalized()
	var f := fwd.normalized()
	var u := up_ref.normalized()
	var ortho := u - f * u.dot(f)
	if ortho.length_squared() < 0.02:
		return u
	return u.slerp(ortho.normalized(), clampf(w, 0.0, 1.0)).normalized()


# ----------------------------------------------------------------------------- writing the record
## Stores the rocket relative to the seam camera. `model_scale` is the scale the sender draws the
## model at, so the receiver can draw it at a different one and still match on screen.
## Records the sender's chase reference frame (world vectors in, camera-local out).
static func write_frame(cam: Transform3D, world_up_ref: Vector3, world_flank: Vector3) -> void:
	var inv := cam.basis.orthonormalized().inverse()
	up_ref = (inv * world_up_ref.normalized()).normalized()
	flank = (inv * world_flank.normalized()).normalized()


static func write_rocket(cam: Transform3D, rocket_xf: Transform3D, model_scale: float) -> void:
	var inv := cam.affine_inverse()
	var local := inv * rocket_xf
	var d := local.origin
	var dist := d.length()
	rocket_dir = d / dist if dist > 0.0001 else Vector3.FORWARD
	rocket_dist_over_scale = dist / maxf(model_scale, 0.0001)
	rocket_basis = local.basis.orthonormalized()


## Rebuilds the rocket transform for a receiver drawing the model at `model_scale`, given where the
## receiver has put its camera.
static func read_rocket(cam: Transform3D, model_scale: float) -> Transform3D:
	var dist := rocket_dist_over_scale * model_scale
	var origin := cam * (rocket_dir * dist)
	var basis := cam.basis.orthonormalized() * rocket_basis
	return Transform3D(basis.scaled(Vector3.ONE * model_scale), origin)


## Where a receiver must put its camera so that a sphere of `radius` centred at `centre` lands on
## the recorded `focus_dir` / `focus_angle`, given the camera basis it is going to use.
static func focus_camera_position(centre: Vector3, radius: float, basis: Basis) -> Vector3:
	return centre - (basis * focus_dir).normalized() * distance_for_angle(radius, focus_angle)


## Installs `path` as the current scene WITHOUT the one blank frame `change_scene_to_file` leaves.
##
## SceneTree's own change queues the swap and the engine draws one frame with no scene at all - a
## flash of the default clear colour right in the middle of a cut we are trying to hide. Doing it by
## hand (drop the old scene out of the tree, add the new one, let the old one free itself at the end
## of the frame) means the new scene's _ready has already run and its camera is already current when
## that same frame is drawn. Falls back to the engine's version if the scene will not load.
## `collect_prewarm` is for the ARRIVAL only: it makes the destination's NPC and building scenes
## resident before the new scene's `_ready` runs. It must stay false on the departure, where those
## same requests are still in flight and blocking on them would put the arrival's load cost onto
## the departure cut instead of removing it.
static func swap_scene(tree: SceneTree, path: String, collect_prewarm := false) -> void:
	var packed := take_prewarmed(path)
	if packed == null:
		packed = ResourceLoader.load(path) as PackedScene
	if collect_prewarm:
		hold_prewarm()
	if packed == null or tree == null:
		if tree != null:
			tree.change_scene_to_file(path)
		return
	var root := tree.root
	var old := tree.current_scene
	if old != null and old.get_parent() == root:
		root.remove_child(old)
		old.queue_free()
	var t0 := Time.get_ticks_usec()
	var inst := packed.instantiate()
	root.add_child(inst)
	tree.current_scene = inst
	# Opt-in seam timing for the perf rig (`-- --swaptime`). This is the number the whole prewarm
	# machinery above exists to move, so it is worth being able to read it without a code edit.
	if OS.get_cmdline_user_args().has("--swaptime"):
		print("SWAPTIME %-34s build=%.1f ms" % [path, (Time.get_ticks_usec() - t0) / 1000.0])


# --------------------------------------------------------------------------------------- prewarming
## A scene change is a stall, and both of this journey's cuts land mid-flight where a stall is a
## visible freeze. Every other frame of the journey is a locked 16.67 ms; these two are the whole of
## the "freezing on approach" the player reported. MEASURED windowed (a `--write-movie` capture runs
## at a fixed delta and reports a perfectly smooth trip no matter how badly it hitches), with
## `-- --swaptime` and `src/rocket/journey_probe.gd`:
##
##   departure (world -> space)    92-97 ms  of which 61 ms was `ResourceLoader.load(space_travel.tscn)`
##   arrival   (space -> world)   377-854 ms of which 0.2-5 ms was the load: the rest is world.gd's
##                                `_ready`, and `showcase/rocket_loadcost.tscn` breaks that down on a
##                                warm cache as Planet 264 ms, player 18, HUD 11, this pad 25,
##                                environment 5, npcs/buildings 0-380 depending on the world.
##
## What a journey CAN fix from here is the load half: the destination is known the moment the player
## picks it on the pad, which is ~16 s of flight before the arrival, and the cruise is dead time.
## Everything world.gd is about to `load()` is therefore requested on Godot's loader threads as soon
## as the destination is chosen. RESULT: the departure cut went 92-97 ms -> 10-32 ms (it was almost
## all load), and the arrival went 854 -> 680-756 ms on the hub, whose four building scenes are the
## only destination with a load cost worth removing. Every other arrival was already load-free and
## did not move.
##
## THE REMAINING 400-750 ms IS NODE BUILDING ON THE MAIN THREAD INSIDE `_ready` - Planet's icosphere,
## displacement, colour bake and trimesh collider above all - and no amount of threaded LOADING can
## touch it. Fixing it needs `Planet` to gain a prebuilt-geometry cache the rocket can fill during
## the cruise; see the handover note in the rocket builder's report.
##
## Never blocks and never fails loudly: a request that has not finished by the time it is wanted is
## simply completed synchronously, which is exactly what would have happened without prewarming.
##
## Two buckets, and the difference matters. `_pending` is requests still on the loader threads.
## `_held` keeps a REFERENCE to each collected resource: `load_threaded_get` hands back a Ref, and
## dropping it lets Godot evict the resource from the cache again - which would undo the whole
## exercise between the departure and the arrival. `release_prewarm` lets go once the destination
## has actually been built.
static var _pending: PackedStringArray = PackedStringArray()
static var _held: Array[Resource] = []

## Fire threaded loads for every scene the destination planet is about to need.
static func prewarm_destination(dest_id: String) -> void:
	release_prewarm()
	_request("res://src/world/world.tscn")
	var data_path := "res://src/planet/data/%s.tres" % dest_id
	if not ResourceLoader.exists(data_path):
		return
	# Loaded straight, not threaded: it is a few hundred bytes and its contents are needed HERE to
	# know which npc and building scenes to ask for.
	var data := ResourceLoader.load(data_path) as PlanetData
	if data == null:
		return
	_held.append(data)
	# Build the destination's ground mesh and trimesh collider NOW, so `world.gd::_ready()` on the
	# other side of the arrival swap picks them up instead of generating them. Measured on Zorp:
	# a cold Planet build is 384 ms on the main thread and a prebuilt one is 91 ms - 76% of the
	# arrival hitch. This runs while the space scene is still showing its held seam frame, where a
	# stall is invisible by design (see `_await_steady_frame`), and it is idempotent.
	Planet.prebuild(data)
	for npc_id in data.npcs:
		_request("res://src/characters/npcs/%s.tscn" % npc_id)
	for bid in data.buildings:
		_request("res://src/hub/buildings/%s.tscn" % bid)


## Fire a threaded load for one scene (used for the space scene during the climb).
static func prewarm_scene(path: String) -> void:
	_request(path)


static func _request(path: String) -> void:
	if not ResourceLoader.exists(path) or _pending.has(path):
		return
	if ResourceLoader.load_threaded_request(path) == OK:
		_pending.append(path)


## Collects one prewarmed scene, waiting only if it somehow has not finished. Returns null when the
## path was never requested, so the caller falls back to a plain load.
static func take_prewarmed(path: String) -> PackedScene:
	var idx := _pending.find(path)
	if idx < 0:
		return null
	_pending.remove_at(idx)
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED:
		return null
	return ResourceLoader.load_threaded_get(path) as PackedScene


## Collects every outstanding request and KEEPS it alive. Call immediately before the destination
## world is instantiated: from here until `release_prewarm`, everything world.gd loads is a cache hit.
static func hold_prewarm() -> void:
	for path in _pending:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var res := ResourceLoader.load_threaded_get(path)
			if res != null:
				_held.append(res)
	_pending.clear()


## Lets go. Called once the destination planet has been built (or the journey abandoned) - a request
## that is never collected keeps the loader's reference alive for the rest of the process, which is
## what the "ObjectDB instances were leaked at exit" warning is telling you about.
static func release_prewarm() -> void:
	hold_prewarm()
	_held.clear()


## Snapshots the ground sky shader's uniforms and the planet's Environment, converting every world
## direction into `cam`'s frame so the space scene can reproduce the same picture from a completely
## different world orientation. Safe to call when there is no sky shader: it just records nothing.
static func capture_sky(cam: Transform3D, world: World3D) -> void:
	sky = {}
	env = null
	if world == null or world.environment == null:
		return
	var src := world.environment
	env = src.duplicate() as Environment
	var mat := src.sky.sky_material as ShaderMaterial if src.sky != null else null
	if mat == null:
		return
	var inv := cam.basis.orthonormalized().inverse()
	var names := ["zenith_color", "mid_color", "limb_color", "sun_color", "sun_glow_color",
		"milky_way_color", "moon_color", "moon_b_color", "star_brightness", "star_day",
		"star_density", "sun_disc_size", "moon_size", "moon_count", "night", "tonemap_white",
		"display_cap"]
	for n in names:
		var v: Variant = mat.get_shader_parameter(n)
		if v != null:
			sky[n] = v
	for n in ["sun_dir", "moon_dir_a", "moon_dir_b", "sky_up", "sky_east", "limb_dir"]:
		var v: Variant = mat.get_shader_parameter(n)
		if v != null:
			sky[n] = inv * (v as Vector3)


# ----------------------------------------------------------------------------- predicted sunlight
# DUPLICATED FROM src/world/environment.gd (the sun's arc constants and `_arc_dir`). The space scene
# has to know where the DESTINATION's sun will be before that planet exists, so the globe it is
# flying at wears the same terminator the real world is about to, and the sky can paint the sun disc
# in the right place on the seam frame. Everything here is a pure function of PlanetData + the
# clock, so it cannot drift silently at runtime - but if the environment builder retunes the arc,
# these five numbers have to follow. The failure mode is graceful: a slightly wrong terminator on
# one frame, not a broken flight. (src/world/sky_bodies.gd mirrors the map LAYOUT for the same
# reason and with the same caveat.) An `Environment.sun_direction_for(planet_id, hour)` helper
# would let this go away.
const SUN_RISE_HOUR := 5.6
const SUN_SET_HOUR := 19.8
const SUN_RISE_AZ_DEG := -45.0
const SUN_PEAK_AZ_DEG := -135.0
const SUN_PEAK_ELEV_DEG := 52.0
## How far off the pad world.gd steps the arriving astronaut (mirrors world.gd::_spawn_player).
const PAD_SPAWN_OFFSET_M := 3.2


## The local frame environment.gd will build on `data` for a player who has just landed at the pad:
## [up, east]. `up` is the spawn point's normal, `east` its parallel-transported reference tangent.
static func landing_frame(data: PlanetData) -> Array:
	var pad := data.pad_dir.normalized()
	var side := pad.cross(Vector3.UP)
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	var up := (pad + side.normalized() * (PAD_SPAWN_OFFSET_M / maxf(data.radius, 0.01))).normalized()
	var east := Vector3.RIGHT - up * up.dot(Vector3.RIGHT)
	if east.length_squared() < 0.001:
		east = Vector3.FORWARD - up * up.dot(Vector3.FORWARD)
	return [up, east.normalized()]


## Normal of a ringed planet's ring plane, in that planet's world space.
## The tilt now comes from the world itself (`PlanetData.ring_tilt_deg`, 42.0 default = Bolt), the
## same field src/world/environment.gd and src/rocket/space_globe.gd build their rings from; only
## src/world/planet_ring.gd's fixed 8 deg roll is still duplicated here. Same reason and same
## caveat as the sun arc above: the space scene has to tilt the globe it is flying at to match the
## ring the real world is about to show, or Bolt's ring - which reaches 2.9 planet radii - swings
## through a quarter of the frame across the arrival cut. Grig's is at 86 deg, near edge-on, so a
## hardcoded 42 here would have swung his band by a full 44 degrees on arrival.
const RING_TILT_DEG := 42.0
const RING_ROLL_DEG := 8.0


static func ring_normal(data: PlanetData) -> Vector3:
	var tilt := RING_TILT_DEG if data == null else data.ring_tilt_deg
	return Basis.from_euler(Vector3(deg_to_rad(tilt), 0.0, deg_to_rad(RING_ROLL_DEG))) * Vector3.UP


## Unit vector pointing TOWARD the sun on `data` at `hour`, in that planet's world space.
static func predict_sun_dir(data: PlanetData, hour: float) -> Vector3:
	var frame := landing_frame(data)
	var up: Vector3 = frame[0]
	var east: Vector3 = frame[1]
	var theta := (fposmod(hour, 24.0) - SUN_RISE_HOUR) / (SUN_SET_HOUR - SUN_RISE_HOUR) * PI
	var rise := _lift(east.rotated(up, deg_to_rad(SUN_RISE_AZ_DEG)), 0.0, up, east)
	var peak := _lift(east.rotated(up, deg_to_rad(SUN_PEAK_AZ_DEG)), SUN_PEAK_ELEV_DEG, up, east)
	return (rise * cos(theta) + peak * sin(theta)).normalized()


static func _lift(dir: Vector3, elev_deg: float, up: Vector3, east: Vector3) -> Vector3:
	var flat := dir - up * up.dot(dir)
	if flat.length_squared() < 0.0001:
		flat = east
	flat = flat.normalized()
	var e := deg_to_rad(elev_deg)
	return (up * sin(e) + flat * cos(e)).normalized()


## Builds a plausible departure record without a planet scene, so `showcase/space_journey.tscn`
## (and any test that wants the cruise on its own) can exercise journey mode standalone. The
## arrangement is the canonical chase framing, built the same way rocket_pad.gd builds it.
static func synthesise(origin_id: String, dest_id: String) -> void:
	clear()
	leg = "depart"
	from_id = origin_id
	to_id = dest_id
	var nose := Vector3(0.0, 0.0, -1.0)
	var up_ref := Vector3.UP
	var flank := nose.cross(up_ref).normalized()
	var eye := -nose * CHASE_BACK + up_ref * CHASE_UP + flank * CHASE_SIDE
	var cam := Transform3D(look_basis(nose * CHASE_LEAD - eye, up_ref), eye)
	var right := nose.cross(up_ref).normalized()
	write_rocket(cam, Transform3D(Basis(right, nose, right.cross(nose).normalized()), Vector3.ZERO), 1.0)
	cam_basis = cam.basis.orthonormalized()
	flame_scale = 1.15
	engine_power = 1.0
	var inv := cam_basis.inverse()
	focus_dir = (inv * -up_ref).normalized()
	focus_angle = deg_to_rad(CLIMB_SEAM_DEG)
	# Every neighbour spread across the frame at plausible ground-sky sizes. FIVE slots, because six
	# worlds means five neighbours and R2.1 says the others are ALWAYS in the sky - a three-slot cap
	# here would drop two of them out of the seam frame and they would pop in on the space side.
	# The directions mirror src/world/sky_bodies.gd SLOTS (same azimuth spread, same height order),
	# so the synthesised departure frames the sky the way a real planet does.
	bodies = []
	var slots := [Vector3(-0.42, 0.10, -0.90), Vector3(0.06, 0.22, -0.97), Vector3(0.50, -0.06, -0.86),
		Vector3(0.29, 0.07, -0.95), Vector3(-0.24, -0.13, -0.96)]
	var ids := ["home", "zorp", "bolt", "hub", "fen", "grig"]
	var i := 0
	for id in ids:
		if id == origin_id or i >= slots.size():
			continue
		bodies.append({"id": id, "dir": (slots[i] as Vector3).normalized(), "angle": deg_to_rad(1.8)})
		i += 1
